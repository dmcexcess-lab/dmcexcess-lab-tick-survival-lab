extends RefCounted
class_name TacticalWeather

const CLEAR := "clear"
const RAIN := "rain"
const STORM := "storm"
const FOG := "fog"
const WIND := "wind"

const PROFILES := {
    CLEAR: {"precipitation": 0.0, "fog": 0.0, "wind": 0.12, "visibility": 1.0, "light": 1.0, "sound_mask": 0.0, "temp_offset_f": 0.0},
    RAIN: {"precipitation": 0.62, "fog": 0.10, "wind": 0.34, "visibility": 0.88, "light": 0.90, "sound_mask": 0.18, "temp_offset_f": -4.0},
    STORM: {"precipitation": 1.0, "fog": 0.18, "wind": 0.82, "visibility": 0.72, "light": 0.76, "sound_mask": 0.42, "temp_offset_f": -7.0},
    FOG: {"precipitation": 0.0, "fog": 0.82, "wind": 0.08, "visibility": 0.58, "light": 0.86, "sound_mask": 0.05, "temp_offset_f": -2.0},
    WIND: {"precipitation": 0.0, "fog": 0.04, "wind": 0.90, "visibility": 0.96, "light": 0.98, "sound_mask": 0.14, "temp_offset_f": -1.0},
}

# Moderate-island placeholder climate. This is deliberately not a weather-pattern
# simulation; it only gives current conditions a deterministic temperature hook.
const MONTH_BASE_F := [41.0, 44.0, 50.0, 58.0, 66.0, 74.0, 79.0, 78.0, 72.0, 62.0, 52.0, 44.0]

static func make_state(kind: String = CLEAR, direction: Vector2 = Vector2.RIGHT) -> Dictionary:
    var selected: String = kind if PROFILES.has(kind) else CLEAR
    var state: Dictionary = PROFILES[selected].duplicate(true)
    state["kind"] = selected
    state["wind_direction"] = direction.normalized() if direction.length() > 0.0 else Vector2.RIGHT
    return state

static func visibility_multiplier(state: Dictionary) -> float:
    return clampf(float(state.get("visibility", 1.0)), 0.25, 1.0)

static func light_multiplier(state: Dictionary) -> float:
    return clampf(float(state.get("light", 1.0)), 0.25, 1.0)

static func sound_mask(state: Dictionary) -> float:
    return clampf(float(state.get("sound_mask", 0.0)), 0.0, 0.9)

static func precipitation(state: Dictionary) -> float:
    return clampf(float(state.get("precipitation", 0.0)), 0.0, 1.0)

static func fog_density(state: Dictionary) -> float:
    return clampf(float(state.get("fog", 0.0)), 0.0, 1.0)

static func wind_strength(state: Dictionary) -> float:
    return clampf(float(state.get("wind", 0.0)), 0.0, 1.0)

static func wind_direction(state: Dictionary) -> Vector2:
    var direction: Vector2 = state.get("wind_direction", Vector2.RIGHT)
    return direction.normalized() if direction.length() > 0.0 else Vector2.RIGHT

static func wind_mph(state: Dictionary) -> float:
    return 2.0 + wind_strength(state) * 30.0

static func outside_temperature_f(month: int, day: int, minute_of_day: int, state: Dictionary) -> float:
    var month_index: int = clampi(month, 1, 12) - 1
    var base: float = MONTH_BASE_F[month_index]
    var hour: float = float(posmod(minute_of_day, 1440)) / 60.0
    # Coolest near 05:00, warmest near 15:00; small date wobble prevents every
    # day of a month from being numerically identical without simulating patterns.
    var diurnal: float = sin((hour - 9.0) / 24.0 * TAU) * 8.0
    var date_wobble: float = sin(float(clampi(day, 1, 31)) * 0.73) * 1.5
    return base + diurnal + date_wobble + float(state.get("temp_offset_f", 0.0))

static func indoor_temperature_f(outside_f: float) -> float:
    # Placeholder thermal buffering only. HVAC/building simulation comes later.
    return 69.0 + (outside_f - 69.0) * 0.32
