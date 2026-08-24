extends "res://scripts/simulation/sound/AcousticEnvironmentModifier.gd"
class_name WeatherAcousticEnvironmentModifier

## System 28 -> System 26 neutral background-masking adapter. Rain/wind do not
## become fake repeated sound emissions and do not rewrite propagation geometry.

var _weather = null

func _init(weather_service = null) -> void:
    _weather = weather_service

func is_ready() -> bool:
    return _weather != null and _weather.has_method("current_sample")

func propagation_cost_addition(
    _profile_id: StringName,
    _from_cell: Vector2i,
    _to_cell: Vector2i
) -> int:
    return 0

func detection_threshold_addition(
    _listener_id: String,
    _profile_id: StringName,
    _listener_cell: Vector2i
) -> int:
    var sample: Dictionary = _sample()
    if sample.is_empty():
        return 0
    var precipitation: float = clampf(float(sample.get("precipitation", 0.0)), 0.0, 1.0)
    var wind_strength: float = clampf(float(sample.get("wind_strength", 0.0)), 0.0, 1.0)
    return maxi(0, int(round(precipitation * 14.0 + wind_strength * 5.0)))

func localization_quality_adjustment(
    _listener_id: String,
    _profile_id: StringName,
    _listener_cell: Vector2i
) -> float:
    var sample: Dictionary = _sample()
    if sample.is_empty():
        return 0.0
    var precipitation: float = clampf(float(sample.get("precipitation", 0.0)), 0.0, 1.0)
    var wind_strength: float = clampf(float(sample.get("wind_strength", 0.0)), 0.0, 1.0)
    return -clampf(precipitation * 0.18 + wind_strength * 0.12, 0.0, 0.35)

func debug_snapshot() -> Dictionary:
    var sample: Dictionary = _sample()
    return {
        "ready": is_ready(),
        "weather_kind": String(sample.get("weather_kind", "")),
        "precipitation": float(sample.get("precipitation", 0.0)),
        "wind_strength": float(sample.get("wind_strength", 0.0)),
        "detection_threshold_addition": detection_threshold_addition("", &"", Vector2i.ZERO),
        "localization_quality_adjustment": localization_quality_adjustment("", &"", Vector2i.ZERO),
    }

func _sample() -> Dictionary:
    if not is_ready():
        return {}
    return _weather.current_sample()
