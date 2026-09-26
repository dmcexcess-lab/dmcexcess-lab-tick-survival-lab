extends RefCounted
class_name ActiveInfectedCohortService

const StreamingPerceptionClass = preload("res://scripts/simulation/perception/StreamingObserverPerceptionService.gd")
const CohortBehaviorClass = preload("res://scripts/simulation/infected/CohortInfectedBehaviorService.gd")
const VisionProfileClass = preload("res://scripts/simulation/perception/VisionProfile.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const PerformanceTelemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")

## Streaming activation owner for a deliberately small cohort of already-hydrated
## resident-backed infected. Physical actor/state truth persists outside the active
## envelope; only expensive perception/hearing/behavior participation is suspended.
## No Node, Timer, per-frame loop, private cooldown, or alternate clock exists here.

signal active_members_changed(active_actor_ids)

var _world: WorldState = null
var _door_state: DoorStateStore = null
var _kernel: TickKernel = null
var _infected: InfectedState = null
var _memory: PerceptionMemoryStore = null
var _acquisition: VisualAcquisitionProvider = null
var _sound: SpatialSoundService = null
var _movement: MovementActionService = null
var _combat: CombatActionService = null
var _health: ActorHealthState = null
var _streaming: WorldStreamingCoordinator = null
var _player_id: String = ""

var _roster: Array[String] = []
var _roster_set: Dictionary = {}
var _active: Dictionary = {}
var _perceptions: Dictionary = {}
var _behaviors: Dictionary = {}
var _configured: bool = false
var _sync_guard: bool = false

var _activation_count: int = 0
var _deactivation_count: int = 0
var _sync_count: int = 0
var _sync_total_usec: int = 0
var _sync_max_usec: int = 0

func _init(
    world: WorldState = null,
    door_state: DoorStateStore = null,
    kernel: TickKernel = null,
    infected_state: InfectedState = null,
    memory_store: PerceptionMemoryStore = null,
    acquisition_provider: VisualAcquisitionProvider = null,
    sound: SpatialSoundService = null,
    movement: MovementActionService = null,
    combat: CombatActionService = null,
    health: ActorHealthState = null,
    streaming: WorldStreamingCoordinator = null,
    player_id: String = ""
) -> void:
    _world = world
    _door_state = door_state
    _kernel = kernel
    _infected = infected_state
    _memory = memory_store
    _acquisition = acquisition_provider
    _sound = sound
    _movement = movement
    _combat = combat
    _health = health
    _streaming = streaming
    _player_id = player_id.strip_edges()

func is_ready() -> bool:
    return _world != null and _door_state != null and _kernel != null and _infected != null \
        and _memory != null and _acquisition != null and _acquisition.is_ready() \
        and _sound != null and _sound.is_ready() and _movement != null and _movement.is_ready() \
        and _combat != null and _combat.is_ready() and _health != null and _health.is_ready() \
        and _streaming != null and _streaming.is_ready() and not _player_id.is_empty()

func configure(hydrated_members: Array[Dictionary]) -> bool:
    if _configured or not is_ready() or hydrated_members.is_empty():
        return false
    var ids: Array[String] = []
    for member: Dictionary in hydrated_members:
        var actor_id := String(member.get("actor_id", "")).strip_edges()
        if actor_id.is_empty() or ids.has(actor_id) or not _valid_living_infected(actor_id):
            return false
        ids.append(actor_id)
    ids.sort()
    _roster = ids
    for actor_id: String in _roster:
        _roster_set[actor_id] = true
    _connect_signals()
    _configured = true
    if not sync_active_now():
        return false
    return true

func is_configured() -> bool:
    return _configured

func roster_actor_ids() -> Array[String]:
    return _roster.duplicate()

func active_actor_ids() -> Array[String]:
    var result: Array[String] = []
    for actor_id: String in _roster:
        if _active.has(actor_id): result.append(actor_id)
    return result

func dormant_actor_ids() -> Array[String]:
    var result: Array[String] = []
    for actor_id: String in _roster:
        if not _active.has(actor_id): result.append(actor_id)
    return result

func is_actor_active(actor_id: String) -> bool:
    return _active.has(actor_id.strip_edges())

func perception_for_actor(actor_id: String) -> StreamingObserverPerceptionService:
    return _perceptions.get(actor_id.strip_edges(), null) as StreamingObserverPerceptionService

func behavior_for_actor(actor_id: String) -> CohortInfectedBehaviorService:
    return _behaviors.get(actor_id.strip_edges(), null) as CohortInfectedBehaviorService

func sync_active_now() -> bool:
    if not _configured or not is_ready() or _sync_guard:
        return false
    var started: int = Time.get_ticks_usec()
    _sync_guard = true
    var ok: bool = true
    for actor_id: String in _roster:
        if not _sync_actor(actor_id):
            ok = false
            break
    _sync_guard = false
    if ok:
        _prepare_active_perception_bounds()
    _record_sync(Time.get_ticks_usec() - started)
    if ok:
        active_members_changed.emit(active_actor_ids())
    return ok

func metrics_snapshot() -> Dictionary:
    var evaluations: int = 0
    var evaluation_total_usec: int = 0
    var evaluation_max_usec: int = 0
    var intention_refresh_total_usec: int = 0
    var submission_total_usec: int = 0
    var submissions: int = 0
    for actor_id: String in _roster:
        var behavior: CohortInfectedBehaviorService = behavior_for_actor(actor_id)
        if behavior == null: continue
        evaluations += behavior.evaluation_count()
        evaluation_total_usec += behavior.evaluation_total_usec()
        evaluation_max_usec = maxi(evaluation_max_usec, behavior.evaluation_max_usec())
        intention_refresh_total_usec += behavior.intention_refresh_total_usec()
        submission_total_usec += behavior.submission_total_usec()
        submissions += behavior.action_submission_count()
    var result := {
        "roster_count": _roster.size(),
        "active_actor_count": active_actor_ids().size(),
        "dormant_actor_count": dormant_actor_ids().size(),
        "activation_count": _activation_count,
        "deactivation_count": _deactivation_count,
        "activation_sync_count": _sync_count,
        "activation_sync_total_usec": _sync_total_usec,
        "activation_sync_max_usec": _sync_max_usec,
        "behavior_evaluation_count": evaluations,
        "behavior_evaluation_total_usec": evaluation_total_usec,
        "behavior_evaluation_max_usec": evaluation_max_usec,
        "behavior_intention_refresh_total_usec": intention_refresh_total_usec,
        "behavior_submission_total_usec": submission_total_usec,
        "ordinary_action_submission_count": submissions,
    }
    PerformanceTelemetry.record_value(&"infected_cohort_roster", _roster.size())
    PerformanceTelemetry.record_value(&"infected_cohort_active", int(result["active_actor_count"]))
    PerformanceTelemetry.record_value(&"infected_cohort_behavior_evaluations", evaluations)
    PerformanceTelemetry.record_value(&"infected_cohort_action_submissions", submissions)
    return result

func _sync_actor(actor_id: String) -> bool:
    var should_be_active: bool = false
    if _valid_living_infected(actor_id):
        var placement: WorldPlacement = _world.placement(actor_id)
        should_be_active = placement != null and placement.channel == Layers.Channel.ACTOR and _streaming.is_cell_active(placement.anchor)
    if should_be_active:
        return true if _active.has(actor_id) else _activate(actor_id)
    if _active.has(actor_id):
        _deactivate(actor_id, &"stream_deactivated")
    return true

func _activate(actor_id: String) -> bool:
    var perception: StreamingObserverPerceptionService = perception_for_actor(actor_id)
    if perception == null:
        perception = StreamingPerceptionClass.new(
            _world,
            _door_state,
            _kernel,
            _memory,
            actor_id,
            VisionProfileClass.new(),
            _acquisition
        )
        if perception == null or not perception.is_ready():
            return false
        _perceptions[actor_id] = perception
    elif not perception.set_stream_active(true):
        return false

    if not _sound.register_listener(actor_id):
        perception.set_stream_active(false)
        return false

    var behavior: CohortInfectedBehaviorService = behavior_for_actor(actor_id)
    if behavior == null:
        behavior = CohortBehaviorClass.new(
            _world,
            _kernel,
            _infected,
            perception,
            _sound,
            _movement,
            _combat,
            _health,
            actor_id,
            _player_id
        )
        if behavior == null:
            _sound.unregister_listener(actor_id)
            perception.set_stream_active(false)
            return false
        _behaviors[actor_id] = behavior
    if not behavior.start():
        _sound.unregister_listener(actor_id)
        perception.set_stream_active(false)
        return false

    _active[actor_id] = true
    _activation_count += 1
    return true

func _deactivate(actor_id: String, reason: StringName) -> void:
    var behavior: CohortInfectedBehaviorService = behavior_for_actor(actor_id)
    if behavior != null:
        behavior.deactivate(reason)
    _sound.unregister_listener(actor_id)
    var perception: StreamingObserverPerceptionService = perception_for_actor(actor_id)
    if perception != null:
        perception.set_stream_active(false)
    _active.erase(actor_id)
    _deactivation_count += 1

func _valid_living_infected(actor_id: String) -> bool:
    if not _infected.is_infected(actor_id) or not _health.has_actor(actor_id) or _health.current_hp(actor_id) <= 0:
        return false
    var placement: WorldPlacement = _world.placement(actor_id)
    return placement != null and placement.channel == Layers.Channel.ACTOR

func _connect_signals() -> void:
    var action_started := Callable(self, "_on_action_started")
    if not _kernel.action_started.is_connected(action_started):
        _kernel.action_started.connect(action_started)
    var stream_changed := Callable(self, "_on_active_regions_changed")
    if not _streaming.active_regions_changed.is_connected(stream_changed):
        _streaming.active_regions_changed.connect(stream_changed)
    var world_changed := Callable(self, "_on_world_changed")
    if not _world.changed.is_connected(world_changed):
        _world.changed.connect(world_changed)
    var hp_changed := Callable(self, "_on_hp_changed")
    if not _health.hp_changed.is_connected(hp_changed):
        _health.hp_changed.connect(hp_changed)

func _on_action_started(action: TimedAction) -> void:
    if action == null or action.actor_id != _player_id or _sync_guard:
        return
    _prepare_active_perception_bounds()

func _on_active_regions_changed(_activated, _deactivated) -> void:
    sync_active_now()

func _on_world_changed(change) -> void:
    if _sync_guard or change == null:
        return
    var actor_id := String(change.entity_id)
    if actor_id == _player_id:
        _prepare_active_perception_bounds()
        return
    if _roster_set.has(actor_id):
        var started: int = Time.get_ticks_usec()
        _sync_guard = true
        _sync_actor(actor_id)
        _sync_guard = false
        _prepare_active_perception_bounds()
        _record_sync(Time.get_ticks_usec() - started)

func _on_hp_changed(actor_id: String, _previous_hp: int, _current_hp: int, _max_hp: int, _version: int) -> void:
    if _sync_guard or not _roster_set.has(actor_id):
        return
    var started: int = Time.get_ticks_usec()
    _sync_guard = true
    _sync_actor(actor_id)
    _sync_guard = false
    _prepare_active_perception_bounds()
    _record_sync(Time.get_ticks_usec() - started)

func _prepare_active_perception_bounds() -> bool:
    if _acquisition == null or not _acquisition.is_ready():
        return false
    var combined: Rect2i = Rect2i()
    var has_bounds: bool = false
    var max_range: int = 0
    for actor_id: String in _roster:
        if not _active.has(actor_id):
            continue
        var perception: StreamingObserverPerceptionService = perception_for_actor(actor_id)
        var placement: WorldPlacement = _world.placement(actor_id)
        if perception == null or placement == null:
            continue
        var profile: VisionProfile = perception.profile()
        if profile == null or not profile.is_valid():
            continue
        max_range = maxi(max_range, profile.max_range)
        var required := Rect2i(
            placement.anchor - Vector2i(profile.max_range, profile.max_range),
            Vector2i(profile.max_range * 2 + 1, profile.max_range * 2 + 1)
        )
        combined = required if not has_bounds else combined.merge(required)
        has_bounds = true

    # Player perception uses the same default System-23 profile in production.
    # Including the player prevents the player observer and infected cohort from
    # ping-ponging the one physical-light field between separate envelopes.
    var player: WorldPlacement = _world.placement(_player_id)
    if player != null and max_range > 0:
        var player_required := Rect2i(
            player.anchor - Vector2i(max_range, max_range),
            Vector2i(max_range * 2 + 1, max_range * 2 + 1)
        )
        combined = player_required if not has_bounds else combined.merge(player_required)
        has_bounds = true

    return has_bounds and _acquisition.prepare_bounds(combined)

func _record_sync(elapsed_usec: int) -> void:
    var elapsed := maxi(elapsed_usec, 0)
    _sync_count += 1
    _sync_total_usec += elapsed
    _sync_max_usec = maxi(_sync_max_usec, elapsed)
    PerformanceTelemetry.record_timing(&"infected_cohort_activation_sync", elapsed)
    PerformanceTelemetry.record_value(&"infected_cohort_activation_syncs", _sync_count)