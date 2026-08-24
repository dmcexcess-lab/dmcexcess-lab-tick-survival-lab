extends RefCounted
class_name WeatherService

const ProfileClass = preload("res://scripts/simulation/weather/WeatherProfile.gd")
const StateClass = preload("res://scripts/simulation/weather/WeatherState.gd")

signal weather_changed(snapshot)
signal weather_transition_completed(previous_profile, arrived_profile, world_tick)

const OWNER_KEY: String = "system28.weather"
const EVENT_TRANSITION: StringName = &"weather.transition.complete"
const QUANTIZATION_BANDS: int = 12
const SNAPSHOT_SCHEMA_VERSION: int = 1

var _kernel: TickKernel = null
var _profiles: Dictionary = {}
var _state: WeatherState = null
var _scenario_seed: int = 28028

func _init(
    tick_kernel: TickKernel = null,
    scenario_seed: int = 28028,
    initial_profile_id: StringName = &"clear"
) -> void:
    _kernel = tick_kernel
    _scenario_seed = scenario_seed
    _profiles = ProfileClass.candidate001_catalog()
    _state = StateClass.new()
    _connect_kernel()
    if _kernel != null and _profile(initial_profile_id) != null:
        _initialize(initial_profile_id)

func is_ready() -> bool:
    return _kernel != null and _state != null and _profile(_state.current_profile_id) != null and _profile(_state.target_profile_id) != null

func current_sample(world_tick: int = -1) -> Dictionary:
    if not is_ready():
        return {}
    var tick: int = _kernel.world_tick() if world_tick < 0 else world_tick
    tick = maxi(tick, _state.transition_start_tick)
    var current: WeatherProfile = _profile(_state.current_profile_id)
    var target: WeatherProfile = _profile(_state.target_profile_id)
    var duration: int = maxi(1, _state.transition_end_tick - _state.transition_start_tick)
    var t: float = clampf(float(tick - _state.transition_start_tick) / float(duration), 0.0, 1.0)
    var direction: Vector2 = current.wind_direction.lerp(target.wind_direction, t)
    if direction.length_squared() <= 0.0001:
        direction = Vector2.RIGHT
    else:
        direction = direction.normalized()
    return {
        "world_tick": tick,
        "weather_kind": String(current.kind if t < 0.5 else target.kind),
        "current_profile_id": String(current.profile_id),
        "target_profile_id": String(target.profile_id),
        "transition_progress": t,
        "precipitation": lerpf(current.precipitation, target.precipitation, t),
        "cloud_cover": lerpf(current.cloud_cover, target.cloud_cover, t),
        "fog_density": lerpf(current.fog_density, target.fog_density, t),
        "wind_direction": direction,
        "wind_strength": lerpf(current.wind_strength, target.wind_strength, t),
        "wetness": wetness_at(tick),
        "environment_revision": _state.environment_revision,
        "transition_serial": _state.transition_serial,
    }

func presentation_descriptor() -> Dictionary:
    var sample: Dictionary = current_sample()
    if sample.is_empty():
        return sample
    sample["presentation_seed"] = _stable_mix(_scenario_seed, _state.transition_serial, String(_state.current_profile_id))
    sample["precipitation_band"] = _band(float(sample["precipitation"]))
    sample["fog_band"] = _band(float(sample["fog_density"]))
    sample["wind_band"] = _band(float(sample["wind_strength"]))
    return sample

func wetness_at(world_tick: int = -1) -> float:
    if not is_ready():
        return 0.0
    var tick: int = _kernel.world_tick() if world_tick < 0 else world_tick
    if tick <= _state.wetness_anchor_tick:
        return _state.wetness_anchor
    var current: WeatherProfile = _profile(_state.current_profile_id)
    var target: WeatherProfile = _profile(_state.target_profile_id)
    var duration: int = maxi(1, _state.transition_end_tick - _state.transition_start_tick)
    var elapsed: int = mini(tick - _state.wetness_anchor_tick, duration)
    var end_t: float = clampf(float(tick - _state.transition_start_tick) / float(duration), 0.0, 1.0)
    var start_rate: float = current.net_wetness_rate()
    var end_rate: float = lerpf(start_rate, target.net_wetness_rate(), end_t)
    var delta: float = float(elapsed) * (start_rate + end_rate) * 0.5
    return clampf(_state.wetness_anchor + delta, 0.0, 1.0)

func force_profile(profile_id: StringName) -> bool:
    # Explicit DEV/testing seam. Production climate logic uses scheduled transitions.
    var profile: WeatherProfile = _profile(profile_id)
    if _kernel == null or profile == null:
        return false
    var tick: int = _kernel.world_tick()
    var current_wetness: float = wetness_at(tick) if is_ready() else 0.0
    if _state.scheduled_event_serial > 0:
        _kernel.cancel_event(_state.scheduled_event_serial)
    _state.current_profile_id = profile.profile_id
    _state.target_profile_id = profile.profile_id
    _state.transition_start_tick = tick
    _state.transition_end_tick = tick + 1
    _state.wetness_anchor = current_wetness
    _state.wetness_anchor_tick = tick
    _state.transition_serial += 1
    _state.environment_revision += 1
    if not _plan_next_transition(profile.profile_id):
        return false
    _publish_quantized_if_needed(true)
    weather_changed.emit(debug_snapshot())
    return true

func environment_revision() -> int:
    return 0 if _state == null else _state.environment_revision

func snapshot() -> Dictionary:
    if not is_ready():
        return {}
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "scenario_seed": _scenario_seed,
        "state": _state.to_snapshot(),
    }

func load_snapshot(data: Dictionary) -> bool:
    if _kernel == null or int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var state_value: Variant = data.get("state", {})
    if typeof(state_value) != TYPE_DICTIONARY:
        return false
    var restored: WeatherState = StateClass.from_snapshot(state_value, _kernel.world_tick())
    if restored == null or _profile(restored.current_profile_id) == null or _profile(restored.target_profile_id) == null:
        return false
    _scenario_seed = int(data.get("scenario_seed", _scenario_seed))
    _state = restored
    weather_changed.emit(debug_snapshot())
    return true

func debug_snapshot() -> Dictionary:
    if not is_ready():
        return {"ready": false}
    var sample: Dictionary = current_sample()
    return {
        "ready": true,
        "scenario_seed": _scenario_seed,
        "world_tick": _kernel.world_tick(),
        "current_profile_id": String(_state.current_profile_id),
        "target_profile_id": String(_state.target_profile_id),
        "transition_start_tick": _state.transition_start_tick,
        "transition_end_tick": _state.transition_end_tick,
        "transition_serial": _state.transition_serial,
        "scheduled_event_serial": _state.scheduled_event_serial,
        "environment_revision": _state.environment_revision,
        "quantized_signature": _state.quantized_signature,
        "sample": sample,
    }

func _initialize(initial_profile_id: StringName) -> void:
    var tick: int = _kernel.world_tick()
    _state.current_profile_id = initial_profile_id
    _state.target_profile_id = initial_profile_id
    _state.transition_start_tick = tick
    _state.transition_end_tick = tick + 1
    _state.wetness_anchor = 0.0
    _state.wetness_anchor_tick = tick
    _state.environment_revision = 1
    _state.transition_serial = 0
    _plan_next_transition(initial_profile_id)
    _publish_quantized_if_needed(true)

func _plan_next_transition(source_profile_id: StringName) -> bool:
    var source: WeatherProfile = _profile(source_profile_id)
    if source == null:
        return false
    var candidates: Array[StringName] = ProfileClass.transition_candidates(source.kind)
    if candidates.is_empty():
        return false
    var choice_seed: int = _stable_mix(_scenario_seed, _state.transition_serial + 1, String(source.profile_id))
    var target_id: StringName = candidates[posmod(choice_seed, candidates.size())]
    var target: WeatherProfile = _profile(target_id)
    if target == null:
        return false
    var span: int = maxi(1, source.max_duration_ticks - source.min_duration_ticks + 1)
    var duration: int = source.min_duration_ticks + posmod(_stable_mix(choice_seed, 17, String(target_id)), span)
    var tick: int = _kernel.world_tick()
    _state.current_profile_id = source.profile_id
    _state.target_profile_id = target.profile_id
    _state.transition_start_tick = tick
    _state.transition_end_tick = tick + duration
    _state.wetness_anchor_tick = tick
    var event_serial: int = _kernel.schedule_event(
        _state.transition_end_tick,
        OWNER_KEY,
        EVENT_TRANSITION,
        "weather",
        {"transition_serial": _state.transition_serial + 1}
    )
    if event_serial <= 0:
        return false
    _state.scheduled_event_serial = event_serial
    return true

func _connect_kernel() -> void:
    if _kernel == null:
        return
    var due := Callable(self, "_on_external_event_due")
    if not _kernel.external_event_due.is_connected(due):
        _kernel.external_event_due.connect(due)
    var advanced := Callable(self, "_on_world_tick_advanced")
    if not _kernel.world_tick_advanced.is_connected(advanced):
        _kernel.world_tick_advanced.connect(advanced)

func _on_external_event_due(event: ScheduledEvent) -> void:
    if event == null or event.owner_key != OWNER_KEY or event.event_type != EVENT_TRANSITION:
        return
    if _state == null or event.serial != _state.scheduled_event_serial:
        return
    var tick: int = event.due_tick
    var previous: StringName = _state.current_profile_id
    var arrived: StringName = _state.target_profile_id
    var arrived_wetness: float = wetness_at(tick)
    _state.current_profile_id = arrived
    _state.target_profile_id = arrived
    _state.wetness_anchor = arrived_wetness
    _state.wetness_anchor_tick = tick
    _state.transition_start_tick = tick
    _state.transition_end_tick = tick + 1
    _state.transition_serial += 1
    _state.environment_revision += 1
    _state.scheduled_event_serial = 0
    if not _plan_next_transition(arrived):
        return
    _publish_quantized_if_needed(true)
    weather_transition_completed.emit(previous, arrived, tick)
    weather_changed.emit(debug_snapshot())

func _on_world_tick_advanced(_previous_tick: int, _new_tick: int) -> void:
    _publish_quantized_if_needed(false)

func _publish_quantized_if_needed(force: bool) -> void:
    if not is_ready():
        return
    var sample: Dictionary = current_sample()
    var direction: Vector2 = sample.get("wind_direction", Vector2.RIGHT)
    var signature := "%s:%d:%d:%d:%d:%d:%d" % [
        String(sample.get("weather_kind", "")),
        _band(float(sample.get("precipitation", 0.0))),
        _band(float(sample.get("cloud_cover", 0.0))),
        _band(float(sample.get("fog_density", 0.0))),
        _band(float(sample.get("wind_strength", 0.0))),
        int(signf(direction.x)),
        _band(float(sample.get("wetness", 0.0))),
    ]
    if not force and signature == _state.quantized_signature:
        return
    if not _state.quantized_signature.is_empty() and signature != _state.quantized_signature:
        _state.environment_revision += 1
    _state.quantized_signature = signature
    if not force:
        weather_changed.emit(debug_snapshot())

func _profile(profile_id: StringName) -> WeatherProfile:
    if not _profiles.has(profile_id):
        return null
    var value: Variant = _profiles[profile_id]
    return value if value is WeatherProfile else null

static func _band(value: float) -> int:
    return clampi(int(round(clampf(value, 0.0, 1.0) * float(QUANTIZATION_BANDS - 1))), 0, QUANTIZATION_BANDS - 1)

static func _stable_mix(seed: int, serial: int, text: String) -> int:
    var value: int = (seed ^ (serial * 1103515245)) & 0x7fffffff
    var bytes: PackedByteArray = text.to_utf8_buffer()
    for byte_value: int in bytes:
        value = int((value * 1664525 + byte_value + 1013904223) & 0x7fffffff)
    return value
