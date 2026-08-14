extends RefCounted
class_name TacticalWeather

const CLEAR := "clear"
const RAIN := "rain"
const STORM := "storm"
const FOG := "fog"
const WIND := "wind"

const PROFILES := {
    CLEAR: {"precipitation": 0.0, "fog": 0.0, "wind": 0.12, "visibility": 1.0, "light": 1.0, "sound_mask": 0.0},
    RAIN: {"precipitation": 0.62, "fog": 0.10, "wind": 0.34, "visibility": 0.88, "light": 0.90, "sound_mask": 0.18},
    STORM: {"precipitation": 1.0, "fog": 0.18, "wind": 0.82, "visibility": 0.72, "light": 0.76, "sound_mask": 0.42},
    FOG: {"precipitation": 0.0, "fog": 0.82, "wind": 0.08, "visibility": 0.58, "light": 0.86, "sound_mask": 0.05},
    WIND: {"precipitation": 0.0, "fog": 0.04, "wind": 0.90, "visibility": 0.96, "light": 0.98, "sound_mask": 0.14},
}

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
