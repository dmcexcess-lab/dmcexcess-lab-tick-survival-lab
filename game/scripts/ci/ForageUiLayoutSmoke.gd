extends SceneTree

const ConditionControlsClass = preload("res://scripts/ui/ConditionPlayerControls.gd")
const WeatherControlsClass = preload("res://scripts/ui/WeatherDevControls.gd")
const ForageControlsClass = preload("res://scripts/ui/ForagePlayerControls.gd")
const UtilityControlsClass = preload("res://scripts/ui/UtilityDevControls.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var survival := ConditionControlsClass.new()
    var weather := WeatherControlsClass.new()
    var forage := ForageControlsClass.new()
    var utilities := UtilityControlsClass.new()
    root.add_child(survival)
    root.add_child(weather)
    root.add_child(forage)
    root.add_child(utilities)

    var survival_rect: Rect2 = _panel_rect(survival)
    var weather_rect: Rect2 = _panel_rect(weather)
    var forage_rect: Rect2 = _panel_rect(forage)
    var utility_rect: Rect2 = _panel_rect(utilities)

    _check(survival_rect == Rect2(Vector2(8, 66), Vector2(326, 78)), "survival panel keeps canonical upper-left slot")
    _check(weather_rect == Rect2(Vector2(344, 66), Vector2(288, 78)), "weather panel keeps canonical upper-right slot")
    _check(forage_rect == Rect2(ForageControlsClass.PANEL_POSITION, ForageControlsClass.PANEL_SIZE), "forage panel uses its canonical lower-left slot")
    _check(utility_rect == Rect2(Vector2(344, 148), Vector2(288, 100)), "utility panel keeps canonical lower-right slot")

    _check(not forage_rect.intersects(weather_rect), "forage is not obscured by Weather DEV controls")
    _check(not forage_rect.intersects(survival_rect), "forage is clear of Survival controls")
    _check(not forage_rect.intersects(utility_rect), "forage is clear of Utility DEV controls")
    _check(not weather_rect.intersects(survival_rect), "top-row player and Weather DEV controls remain separate")

    survival.queue_free()
    weather.queue_free()
    forage.queue_free()
    utilities.queue_free()

    if failures.is_empty():
        print("FORAGE_UI_LAYOUT_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("FORAGE_UI_LAYOUT_SMOKE_FAIL: %s" % failure)
    quit(1)

func _panel_rect(layer: CanvasLayer) -> Rect2:
    for child: Node in layer.get_children():
        if child is PanelContainer:
            var panel := child as PanelContainer
            return Rect2(panel.position, panel.size)
    return Rect2()

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
