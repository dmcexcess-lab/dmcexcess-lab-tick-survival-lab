extends SceneTree

const OverlayClass = preload("res://scripts/render/PerceptionOverlayRenderer.gd")
const DemoCycleClass = preload("res://scripts/demo/DemoAmbientLightCycle.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_memory_luminance_input()
    _test_demo_daylight_curve()

    if _failures.is_empty():
        print("PERCEPTION_AMBIENT_MEMORY_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("PERCEPTION_AMBIENT_MEMORY_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_memory_luminance_input() -> void:
    var overlay := OverlayClass.new()
    _check(is_equal_approx(overlay.ambient_light_level(), 1.0), "ambient overlay defaults to full daylight input")
    _check(is_equal_approx(overlay.memory_luminance(), 0.30), "day remembered luminance preserves Candidate001 30 percent")

    _check(overlay.set_ambient_light_level(0.5), "dusk ambient input accepted")
    _check(is_equal_approx(overlay.memory_luminance(), 0.20), "half ambient produces 20 percent remembered luminance")

    _check(overlay.set_ambient_light_level(0.0), "night ambient input accepted")
    _check(is_equal_approx(overlay.memory_luminance(), 0.10), "night remembered world remains faintly legible at 10 percent")

    _check(overlay.set_ambient_light_level(-1.0), "low ambient input clamps")
    _check(is_equal_approx(overlay.ambient_light_level(), 0.0), "low ambient clamps to zero")
    _check(overlay.set_ambient_light_level(2.0), "high ambient input clamps")
    _check(is_equal_approx(overlay.ambient_light_level(), 1.0), "high ambient clamps to one")

func _test_demo_daylight_curve() -> void:
    _check(is_equal_approx(DemoCycleClass.ambient_light_for_phase(0.10), 0.0), "deep night phase is dark")
    _check(is_equal_approx(DemoCycleClass.ambient_light_for_phase(0.20), 0.0), "dawn begins dark")
    _check(is_equal_approx(DemoCycleClass.ambient_light_for_phase(0.25), 0.5), "dawn midpoint is half light")
    _check(is_equal_approx(DemoCycleClass.ambient_light_for_phase(0.30), 1.0), "day begins at full ambient light")
    _check(is_equal_approx(DemoCycleClass.ambient_light_for_phase(0.50), 1.0), "midday phase remains full light")
    _check(is_equal_approx(DemoCycleClass.ambient_light_for_phase(0.75), 0.5), "dusk midpoint is half light")
    _check(is_equal_approx(DemoCycleClass.ambient_light_for_phase(0.80), 0.0), "night begins dark")

    var initial: float = DemoCycleClass.ambient_light_for_tick(0)
    var repeated: float = DemoCycleClass.ambient_light_for_tick(DemoCycleClass.CYCLE_TICKS)
    _check(is_equal_approx(initial, 1.0), "playable demo begins in daylight")
    _check(is_equal_approx(initial, repeated), "demo ambient cycle repeats deterministically")

func _check(condition: bool, description: String) -> void:
    if not condition:
        _failures.append(description)
