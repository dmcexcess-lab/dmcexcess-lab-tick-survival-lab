extends SceneTree

const OverlayClass = preload("res://scripts/render/PerceptionOverlayRenderer.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_memory_luminance_input()

    if _failures.is_empty():
        print("PERCEPTION_AMBIENT_MEMORY_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("PERCEPTION_AMBIENT_MEMORY_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_memory_luminance_input() -> void:
    var overlay := OverlayClass.new()
    _check(OverlayClass.TRUE_FOG_COLOR == Color.BLACK, "true unexplored fog remains black")
    _check(is_equal_approx(overlay.ambient_light_level(), 1.0), "perception ambient input defaults to full daylight")
    _check(is_equal_approx(overlay.memory_luminance(), 0.30), "day remembered luminance preserves Candidate001 30 percent")

    _check(overlay.set_ambient_light_level(0.5), "mid ambient input accepted")
    _check(is_equal_approx(overlay.memory_luminance(), 0.20), "half ambient produces 20 percent remembered luminance")

    _check(overlay.set_ambient_light_level(0.0), "night ambient input accepted")
    _check(is_equal_approx(overlay.memory_luminance(), 0.10), "night remembered world remains faintly legible at 10 percent")
    _check(OverlayClass.TRUE_FOG_COLOR == Color.BLACK, "ambient changes never brighten true fog")

    _check(overlay.set_ambient_light_level(-1.0), "low ambient input clamps")
    _check(is_equal_approx(overlay.ambient_light_level(), 0.0), "low ambient clamps to zero")
    _check(overlay.set_ambient_light_level(2.0), "high ambient input clamps")
    _check(is_equal_approx(overlay.ambient_light_level(), 1.0), "high ambient clamps to one")

func _check(condition: bool, description: String) -> void:
    if not condition:
        _failures.append(description)