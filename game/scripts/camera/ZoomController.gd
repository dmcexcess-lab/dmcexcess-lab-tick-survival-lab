extends RefCounted
class_name ZoomController

const DEFAULT_LEVEL: int = 2
const PRESETS: Array[Dictionary] = [
    {"label": "VERY CLOSE", "scale": 1.75},
    {"label": "CLOSE", "scale": 1.35},
    {"label": "NORMAL", "scale": 1.0},
    {"label": "FAR", "scale": 0.75},
    {"label": "AREA", "scale": 0.5},
]

func level_count() -> int:
    return PRESETS.size()

func is_valid_level(level: int) -> bool:
    return level >= 0 and level < PRESETS.size()

func clamp_level(level: int) -> int:
    return clampi(level, 0, PRESETS.size() - 1)

func zoom_in(level: int) -> int:
    return maxi(0, clamp_level(level) - 1)

func zoom_out(level: int) -> int:
    return mini(PRESETS.size() - 1, clamp_level(level) + 1)

func label(level: int) -> String:
    if not is_valid_level(level):
        return "UNKNOWN"
    return String(PRESETS[level].get("label", "UNKNOWN"))

func scale(level: int) -> float:
    if not is_valid_level(level):
        return 1.0
    return float(PRESETS[level].get("scale", 1.0))

func zoom_vector(level: int) -> Vector2:
    var value: float = scale(level)
    return Vector2(value, value)

func snapshot() -> Array[Dictionary]:
    return PRESETS.duplicate(true)
