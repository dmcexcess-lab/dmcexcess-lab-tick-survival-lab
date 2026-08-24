extends RefCounted
class_name WeatherProfile

const KIND_CLEAR: StringName = &"clear"
const KIND_OVERCAST: StringName = &"overcast"
const KIND_RAIN: StringName = &"rain"
const KIND_STORM: StringName = &"storm"
const KIND_FOG: StringName = &"fog"

var profile_id: StringName = &""
var kind: StringName = &""
var precipitation: float = 0.0
var cloud_cover: float = 0.0
var fog_density: float = 0.0
var wind_direction: Vector2 = Vector2.RIGHT
var wind_strength: float = 0.0
var wetting_per_tick: float = 0.0
var drying_per_tick: float = 0.0
var min_duration_ticks: int = 1
var max_duration_ticks: int = 1

func _init(
    id: StringName = &"",
    weather_kind: StringName = &"",
    precipitation_value: float = 0.0,
    cloud_value: float = 0.0,
    fog_value: float = 0.0,
    wind_dir: Vector2 = Vector2.RIGHT,
    wind_value: float = 0.0,
    wetting_rate: float = 0.0,
    drying_rate: float = 0.0,
    min_ticks: int = 1,
    max_ticks: int = 1
) -> void:
    profile_id = id
    kind = weather_kind
    precipitation = clampf(precipitation_value, 0.0, 1.0)
    cloud_cover = clampf(cloud_value, 0.0, 1.0)
    fog_density = clampf(fog_value, 0.0, 1.0)
    wind_direction = Vector2.RIGHT if wind_dir.length_squared() <= 0.0001 else wind_dir.normalized()
    wind_strength = clampf(wind_value, 0.0, 1.0)
    wetting_per_tick = maxf(0.0, wetting_rate)
    drying_per_tick = maxf(0.0, drying_rate)
    min_duration_ticks = maxi(1, min_ticks)
    max_duration_ticks = maxi(min_duration_ticks, max_ticks)

func is_valid() -> bool:
    return (
        not String(profile_id).is_empty()
        and not String(kind).is_empty()
        and precipitation >= 0.0 and precipitation <= 1.0
        and cloud_cover >= 0.0 and cloud_cover <= 1.0
        and fog_density >= 0.0 and fog_density <= 1.0
        and wind_strength >= 0.0 and wind_strength <= 1.0
        and wind_direction.length_squared() > 0.0001
        and wetting_per_tick >= 0.0
        and drying_per_tick >= 0.0
        and min_duration_ticks >= 1
        and max_duration_ticks >= min_duration_ticks
    )

func copy() -> WeatherProfile:
    return WeatherProfile.new(
        profile_id,
        kind,
        precipitation,
        cloud_cover,
        fog_density,
        wind_direction,
        wind_strength,
        wetting_per_tick,
        drying_per_tick,
        min_duration_ticks,
        max_duration_ticks
    )

func net_wetness_rate() -> float:
    return wetting_per_tick - drying_per_tick

static func candidate001_catalog() -> Dictionary:
    # Candidate durations are intentionally long enough to create weather, not roulette.
    # 5 WHEN ticks ~= 1 simulation second under System 25 Candidate 001.
    return {
        KIND_CLEAR: WeatherProfile.new(KIND_CLEAR, KIND_CLEAR, 0.0, 0.14, 0.02, Vector2(1.0, 0.15), 0.14, 0.0, 0.000010, 9000, 18000),
        KIND_OVERCAST: WeatherProfile.new(KIND_OVERCAST, KIND_OVERCAST, 0.0, 0.86, 0.08, Vector2(1.0, 0.28), 0.28, 0.0, 0.000004, 7000, 15000),
        KIND_RAIN: WeatherProfile.new(KIND_RAIN, KIND_RAIN, 0.56, 0.95, 0.14, Vector2(1.0, 0.52), 0.46, 0.000030, 0.0, 7000, 14000),
        KIND_STORM: WeatherProfile.new(KIND_STORM, KIND_STORM, 1.0, 1.0, 0.24, Vector2(1.0, 0.72), 0.90, 0.000060, 0.0, 5000, 10000),
        KIND_FOG: WeatherProfile.new(KIND_FOG, KIND_FOG, 0.0, 0.58, 0.82, Vector2(1.0, 0.08), 0.08, 0.0, 0.000003, 6000, 12000),
    }

static func transition_candidates(kind: StringName) -> Array[StringName]:
    match kind:
        KIND_CLEAR:
            return [KIND_CLEAR, KIND_OVERCAST, KIND_FOG]
        KIND_OVERCAST:
            return [KIND_CLEAR, KIND_RAIN, KIND_FOG]
        KIND_RAIN:
            return [KIND_OVERCAST, KIND_RAIN, KIND_STORM]
        KIND_STORM:
            return [KIND_RAIN, KIND_OVERCAST]
        KIND_FOG:
            return [KIND_CLEAR, KIND_OVERCAST]
        _:
            return [KIND_CLEAR]
