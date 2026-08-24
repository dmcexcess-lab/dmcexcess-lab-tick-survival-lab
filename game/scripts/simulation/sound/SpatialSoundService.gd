extends RefCounted
class_name SpatialSoundService

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const EmissionClass = preload("res://scripts/simulation/sound/SoundEmission.gd")
const ProfileCatalogClass = preload("res://scripts/simulation/sound/SoundEmissionProfileCatalog.gd")
const EnvironmentModifierClass = preload("res://scripts/simulation/sound/AcousticEnvironmentModifier.gd")
const ObservationClass = preload("res://scripts/simulation/sound/HeardSoundObservation.gd")

## System 26 coordinator: exact physical emission -> one acoustic field ->
## listener-specific uncertain observations. Consumers never need exact source truth.

signal sound_heard(listener_id, observation)
signal listener_observations_changed(listener_id)
signal emission_resolved(event_id, listeners_heard)

const FNV1A_OFFSET_BASIS: int = 2166136261
const FNV1A_PRIME: int = 16777619
const UINT32_MASK: int = 0xffffffff

var _world: WorldState = null
var _kernel: TickKernel = null
var _profiles: SoundEmissionProfileCatalog = null
var _propagation: AcousticPropagationQuery = null
var _hearing: HearingProfileProvider = null
var _observations: HeardSoundObservationStore = null
var _environment: AcousticEnvironmentModifier = null
var _next_event_serial: int = 1

func _init(
    world: WorldState = null,
    kernel: TickKernel = null,
    profiles: SoundEmissionProfileCatalog = null,
    propagation: AcousticPropagationQuery = null,
    hearing_provider: HearingProfileProvider = null,
    observation_store: HeardSoundObservationStore = null,
    environment_modifier: AcousticEnvironmentModifier = null
) -> void:
    _world = world
    _kernel = kernel
    _profiles = profiles if profiles != null else ProfileCatalogClass.new()
    _propagation = propagation
    _hearing = hearing_provider
    _observations = observation_store
    _environment = environment_modifier if environment_modifier != null else EnvironmentModifierClass.new()
    if _kernel != null:
        if not _kernel.world_tick_advanced.is_connected(_on_world_tick_advanced):
            _kernel.world_tick_advanced.connect(_on_world_tick_advanced)
        if not _kernel.timing_state_reset.is_connected(_on_timing_state_reset):
            _kernel.timing_state_reset.connect(_on_timing_state_reset)
    if _observations != null and not _observations.observations_changed.is_connected(_on_store_changed):
        _observations.observations_changed.connect(_on_store_changed)

func is_ready() -> bool:
    return _world != null \
        and _kernel != null \
        and _profiles != null and _profiles.is_valid() \
        and _propagation != null and _propagation.is_ready() \
        and _hearing != null and _hearing.is_ready() \
        and _observations != null \
        and _environment != null

func register_listener(actor_id: String) -> bool:
    var normalized: String = actor_id.strip_edges()
    if not is_ready() or normalized.is_empty() or not _world.has_entity(normalized) or not _world.has_placement(normalized):
        return false
    var placement: WorldPlacement = _world.placement(normalized)
    if placement == null or placement.channel != Layers.Channel.ACTOR or not Facing.is_valid(placement.facing):
        return false
    return _observations.enroll_listener(normalized)

func unregister_listener(actor_id: String) -> bool:
    if not is_ready():
        return false
    return _observations.remove_listener(actor_id)

func emit_sound(
    profile_id: StringName,
    origin_cell: Vector2i,
    source_entity_id: String = "",
    group_key: String = "",
    power_override: int = -1
) -> String:
    if not is_ready() or not _profiles.has_profile(profile_id) or not _world.has_terrain(origin_cell):
        return ""
    var power: int = power_override if power_override > 0 else _profiles.power(profile_id)
    if power <= 0:
        return ""
    var event_id: String = "sound.%d.%d" % [_kernel.world_tick(), _next_event_serial]
    _next_event_serial += 1
    var emission := EmissionClass.new(
        event_id,
        _kernel.world_tick(),
        origin_cell,
        profile_id,
        power,
        source_entity_id,
        group_key
    )
    if not emission.is_valid():
        return ""
    var field: Dictionary = _propagation.propagation_field(emission)
    if field.is_empty():
        return ""

    var heard_count: int = 0
    for listener_id: String in _observations.listener_ids():
        var observation: HeardSoundObservation = _resolve_listener(emission, field, listener_id)
        if observation == null:
            continue
        if _observations.upsert(observation):
            heard_count += 1
            sound_heard.emit(listener_id, observation.copy())
    emission_resolved.emit(event_id, heard_count)
    return event_id

func active_observations(listener_id: String) -> Array[HeardSoundObservation]:
    var result: Array[HeardSoundObservation] = []
    if not is_ready():
        return result
    return _observations.active_observations(listener_id, _kernel.world_tick())

func presentation_descriptors(listener_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for observation: HeardSoundObservation in active_observations(listener_id):
        result.append({
            "cell": observation.perceived_cell,
            "strength": observation.perceived_strength,
            "certainty": observation.certainty,
            "category": String(observation.recognized_category),
            "word": observation.display_word,
            "heard_tick": observation.heard_tick,
            "expiry_tick": observation.expiry_tick,
        })
    return result

func observation_snapshot() -> Dictionary:
    if _observations == null:
        return {}
    return _observations.snapshot()

func load_observation_snapshot(data: Dictionary) -> bool:
    if not is_ready() or not _observations.load_snapshot(data):
        return false
    for listener_id: String in _observations.listener_ids():
        listener_observations_changed.emit(listener_id)
    return true

func _resolve_listener(emission: SoundEmission, field: Dictionary, listener_id: String) -> HeardSoundObservation:
    if not _world.has_placement(listener_id):
        return null
    var listener: WorldPlacement = _world.placement(listener_id)
    if listener == null or listener.channel != Layers.Channel.ACTOR or not Facing.is_valid(listener.facing):
        return null
    var received_value: Variant = field.get(listener.anchor, null)
    if typeof(received_value) != TYPE_DICTIONARY:
        return null
    var received: Dictionary = received_value
    var remaining: int = int(received.get("remaining", 0))
    if remaining <= 0:
        return null
    var strength: float = clampf(float(remaining) / float(maxi(1, emission.acoustic_power)), 0.0, 1.0)
    var hearing_profile: Dictionary = _hearing.profile(listener_id)
    var self_generated: bool = not emission.source_entity_id.is_empty() and emission.source_entity_id == listener_id
    var detection_threshold: int = int(hearing_profile.get("detection_threshold", 40))
    detection_threshold += maxi(0, _environment.detection_threshold_addition(listener_id, emission.profile_id, listener.anchor))
    if not self_generated and remaining < detection_threshold:
        return null

    var perceived_cell: Vector2i = emission.origin_cell
    var certainty: float = 1.0
    if not self_generated and emission.origin_cell != listener.anchor:
        var localized: Dictionary = _localize(
            emission,
            listener,
            hearing_profile,
            strength,
            int(received.get("barrier_cost", 0))
        )
        perceived_cell = localized.get("cell", listener.anchor)
        certainty = float(localized.get("certainty", 0.0))

    var tier: int = 2 if self_generated else _recognition_tier(emission, listener_id, hearing_profile, strength)
    var word: String = _profiles.recognition_word(emission.profile_id, tier)
    var category: StringName = _profiles.category(emission.profile_id)
    var group_id: String = _opaque_group_id(listener_id, emission)
    var cue_id: String = "%s.%d" % [group_id, emission.emitted_tick]
    return ObservationClass.new(
        cue_id,
        listener_id,
        emission.emitted_tick,
        perceived_cell,
        strength,
        certainty,
        word,
        category,
        emission.emitted_tick + _profiles.cue_lifetime_ticks(emission.profile_id),
        group_id
    )

func _recognition_tier(emission: SoundEmission, listener_id: String, hearing_profile: Dictionary, strength: float) -> int:
    var hearing_score: int = int(hearing_profile.get("hearing_score", 50))
    var domain_skill: StringName = _profiles.domain_skill(emission.profile_id)
    var domain_level: int = _hearing.domain_level(listener_id, domain_skill) if not String(domain_skill).is_empty() else 0
    var score: float = float(hearing_score) * 0.50 + strength * 50.0 + float(domain_level) * 2.0
    var difficulty: int = _profiles.recognition_difficulty(emission.profile_id)
    if score >= float(difficulty + 25):
        return 2
    if score >= float(difficulty):
        return 1
    return 0

func _localize(
    emission: SoundEmission,
    listener: WorldPlacement,
    hearing_profile: Dictionary,
    strength: float,
    barrier_cost: int
) -> Dictionary:
    var true_delta: Vector2i = emission.origin_cell - listener.anchor
    if true_delta == Vector2i.ZERO:
        return {"cell": listener.anchor, "certainty": 1.0}
    var forward: Vector2i = Facing.vector(listener.facing)
    var right := Vector2i(-forward.y, forward.x)
    var true_forward: int = true_delta.dot(forward)
    var true_right: int = true_delta.dot(right)
    var hearing_score: int = int(hearing_profile.get("hearing_score", 50))
    var muffle: float = clampf(float(barrier_cost) / float(maxi(1, emission.acoustic_power)), 0.0, 1.0)
    var environment_adjustment: float = _environment.localization_quality_adjustment(listener.entity_id, emission.profile_id, listener.anchor)
    var quality: float = clampf(
        float(hearing_score) / 100.0 * 0.50 + strength * 0.50 - muffle * 0.20 + environment_adjustment,
        0.0,
        1.0
    )
    var max_angle_error_deg: float = lerpf(60.0, 8.0, quality)
    var max_range_error_fraction: float = lerpf(0.70, 0.10, quality)
    if true_delta.length_squared() <= 4 and strength >= 0.50:
        max_range_error_fraction = minf(max_range_error_fraction, 0.25)
        max_angle_error_deg = minf(max_angle_error_deg, 20.0)

    var seed_key: String = "%s|%s" % [emission.event_id, listener.entity_id]
    var angle_jitter: float = _signed_unit(seed_key, "angle") * deg_to_rad(max_angle_error_deg)
    var range_jitter: float = _signed_unit(seed_key, "range") * max_range_error_fraction
    var true_angle: float = atan2(float(true_right), float(true_forward))
    var true_distance: float = sqrt(float(true_delta.length_squared()))
    var estimated_distance: int = maxi(1, int(round(true_distance * (1.0 + range_jitter))))
    var estimated_angle: float = true_angle + angle_jitter
    var estimated_forward: int = int(round(cos(estimated_angle) * float(estimated_distance)))
    var estimated_right: int = int(round(sin(estimated_angle) * float(estimated_distance)))

    # Hard actor-relative sanity constraints. Stats may broaden an estimate, but
    # never move a true rear sound into front or swap a clear left/right side.
    if true_forward > 0:
        estimated_forward = maxi(1, estimated_forward)
    elif true_forward < 0:
        estimated_forward = mini(-1, estimated_forward)
    if true_right > 0:
        estimated_right = maxi(1, estimated_right)
    elif true_right < 0:
        estimated_right = mini(-1, estimated_right)

    var estimated_delta: Vector2i = forward * estimated_forward + right * estimated_right
    if estimated_delta == Vector2i.ZERO:
        estimated_delta = Vector2i(clampi(true_delta.x, -1, 1), clampi(true_delta.y, -1, 1))
        if estimated_delta == Vector2i.ZERO:
            estimated_delta = forward
    return {
        "cell": listener.anchor + estimated_delta,
        "certainty": quality,
    }

func _opaque_group_id(listener_id: String, emission: SoundEmission) -> String:
    var group_source: String = emission.group_key if not emission.group_key.is_empty() else emission.event_id
    var hash_value: int = _fnv1a("%s|%s|%s" % [listener_id, String(emission.profile_id), group_source])
    return "heard.%08x" % hash_value

static func _signed_unit(base: String, salt: String) -> float:
    var value: int = _fnv1a("%s|%s" % [base, salt])
    return float(value & 0xffff) / 32767.5 - 1.0

static func _fnv1a(value: String) -> int:
    var hash_value: int = FNV1A_OFFSET_BASIS
    for byte_value: int in value.to_utf8_buffer():
        hash_value = ((hash_value ^ byte_value) * FNV1A_PRIME) & UINT32_MASK
    return hash_value

func _on_world_tick_advanced(_previous_tick: int, new_tick: int) -> void:
    _observations.prune_expired(new_tick)

func _on_timing_state_reset() -> void:
    if _observations == null or _kernel == null:
        return
    _observations.prune_expired(_kernel.world_tick())
    for listener_id: String in _observations.listener_ids():
        listener_observations_changed.emit(listener_id)

func _on_store_changed(listener_id: String) -> void:
    listener_observations_changed.emit(listener_id)
