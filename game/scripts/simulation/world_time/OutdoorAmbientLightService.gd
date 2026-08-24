extends RefCounted
class_name OutdoorAmbientLightService

## Deterministic baseline outdoor daylight derived from System 25 world time.
## Weather and local/artificial lighting remain separate future systems.

signal ambient_light_changed(level, phase, snapshot)

const PHASE_NIGHT: StringName = &"night"
const PHASE_DAWN: StringName = &"dawn"
const PHASE_DAY: StringName = &"day"
const PHASE_DUSK: StringName = &"dusk"

var _time: WorldTimeService = null
var _profile: DaylightProfile = null

func _init(world_time: WorldTimeService = null, daylight_profile: DaylightProfile = null) -> void:
    _time = world_time
    _profile = null if daylight_profile == null else daylight_profile.copy()
    _connect_time()

func is_ready() -> bool:
    return _time != null and _time.is_ready() and _profile != null and _profile.is_valid()

func daylight_profile() -> DaylightProfile:
    return null if _profile == null else _profile.copy()

func set_daylight_profile(profile: DaylightProfile) -> bool:
    if profile == null or not profile.is_valid():
        return false
    _profile = profile.copy()
    _emit_current()
    return true

func ambient_light_level() -> float:
    if not is_ready():
        return 0.0
    var current: Dictionary = _time.current_time()
    return level_for_second_of_day(int(current.get("second_of_day", -1)))

func current_phase() -> StringName:
    if not is_ready():
        return &""
    var current: Dictionary = _time.current_time()
    return phase_for_second_of_day(int(current.get("second_of_day", -1)))

func current_snapshot() -> Dictionary:
    if not is_ready():
        return {}
    var result: Dictionary = _time.current_time().duplicate(true)
    var second_of_day: int = int(result.get("second_of_day", -1))
    result["ambient_light_level"] = level_for_second_of_day(second_of_day)
    result["daylight_phase"] = phase_for_second_of_day(second_of_day)
    return result

func level_for_second_of_day(second_of_day: int) -> float:
    if _profile == null or not _profile.is_valid() \
        or second_of_day < 0 or second_of_day >= WorldTimeProfile.SECONDS_PER_DAY:
        return 0.0

    if second_of_day < _profile.dawn_start_second or second_of_day >= _profile.night_start_second:
        return _profile.night_level
    if second_of_day < _profile.day_start_second:
        var dawn_t: float = _normalized_interval(
            second_of_day,
            _profile.dawn_start_second,
            _profile.day_start_second
        )
        return lerpf(_profile.night_level, _profile.day_level, _smoothstep01(dawn_t))
    if second_of_day < _profile.dusk_start_second:
        return _profile.day_level

    var dusk_t: float = _normalized_interval(
        second_of_day,
        _profile.dusk_start_second,
        _profile.night_start_second
    )
    return lerpf(_profile.day_level, _profile.night_level, _smoothstep01(dusk_t))

func phase_for_second_of_day(second_of_day: int) -> StringName:
    if _profile == null or not _profile.is_valid() \
        or second_of_day < 0 or second_of_day >= WorldTimeProfile.SECONDS_PER_DAY:
        return &""
    if second_of_day < _profile.dawn_start_second or second_of_day >= _profile.night_start_second:
        return PHASE_NIGHT
    if second_of_day < _profile.day_start_second:
        return PHASE_DAWN
    if second_of_day < _profile.dusk_start_second:
        return PHASE_DAY
    return PHASE_DUSK

func _connect_time() -> void:
    if _time == null:
        return
    var callable := Callable(self, "_on_time_changed")
    if not _time.time_changed.is_connected(callable):
        _time.time_changed.connect(callable)

func _on_time_changed(_snapshot: Dictionary) -> void:
    _emit_current()

func _emit_current() -> void:
    if not is_ready():
        return
    var snapshot: Dictionary = current_snapshot()
    ambient_light_changed.emit(
        float(snapshot.get("ambient_light_level", 0.0)),
        StringName(snapshot.get("daylight_phase", &"")),
        snapshot
    )

static func _normalized_interval(value: int, start_value: int, end_value: int) -> float:
    if end_value <= start_value:
        return 0.0
    return clampf(float(value - start_value) / float(end_value - start_value), 0.0, 1.0)

static func _smoothstep01(value: float) -> float:
    var t: float = clampf(value, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)
