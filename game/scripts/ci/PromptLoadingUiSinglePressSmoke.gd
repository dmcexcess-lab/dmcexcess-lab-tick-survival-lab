extends SceneTree

const StartupScene = preload("res://main.tscn")
const CameraControlsClass = preload("res://scripts/ui/CameraControls.gd")

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _verify_loading_ellipsis()
    await _verify_map_single_press()
    _finish()

func _verify_loading_ellipsis() -> void:
    var menu: Node = StartupScene.instantiate()
    _check(menu != null, "startup menu instantiates")
    if menu == null:
        return
    root.add_child(menu)
    current_scene = menu
    var label: Label = menu.get_node_or_null("Center/MenuPanel/Menu/StatusLabel") as Label
    _check(label != null, "startup status label exists under the loading bar")
    if label != null:
        menu.call("_set_status", "Loading verification", true)
        var frames: Array[String] = [label.text]
        menu.call("_advance_loading_indicator", 0.32)
        frames.append(label.text)
        menu.call("_advance_loading_indicator", 0.32)
        frames.append(label.text)
        menu.call("_advance_loading_indicator", 0.32)
        frames.append(label.text)
        print("PROMPT_LOADING_DOT_FRAMES=%s" % str(frames))
        _check(frames.size() == 4, "loading indicator produced four observed frames")
        _check(frames[0] == "Loading verification.", "loading indicator begins with one dot")
        _check(frames[1] == "Loading verification..", "loading indicator advances to two dots")
        _check(frames[2] == "Loading verification...", "loading indicator advances to three dots")
        _check(frames[3] == "Loading verification.", "loading indicator loops without changing the status words")
    current_scene = null
    menu.free()

func _verify_map_single_press() -> void:
    var controls: CameraControls = CameraControlsClass.new()
    root.add_child(controls)
    await process_frame

    var plan := GeneratedGlobalWorldPlan.new()
    plan.world_id = "prompt-single-press"
    plan.seed = 1
    plan.bounds = Rect2i(Vector2i.ZERO, Vector2i(256, 256))
    plan.profile_id = GlobalWorldProfileCatalog.TEMPERATE_ISLAND_REGION
    plan.profile_version = 9
    plan.geography_cells = [{"id": "g"}]
    plan.settlements = [{"id": "s", "kind": &"smalltown", "center": Vector2i(128, 128)}]
    plan.road_segments = [{"road_id": "r", "start": Vector2i(0, 128), "end": Vector2i(255, 128)}]
    plan.power_nodes = [{"id": "p"}]
    plan.power_segments = [{"id": "ps"}]
    plan.water_services = [{"id": "w"}]

    var world := WorldState.new()
    _check(controls.configure_map(plan, world, "player"), "map configures for focused input verification")

    var mouse_press := InputEventMouseButton.new()
    mouse_press.button_index = MOUSE_BUTTON_LEFT
    mouse_press.pressed = true
    var mouse_release := InputEventMouseButton.new()
    mouse_release.button_index = MOUSE_BUTTON_LEFT
    mouse_release.pressed = false

    _check(controls.dispatch_control_event(mouse_press, &"map", 1000), "MAP handles the first mouse press")
    _check(controls.map_is_open(), "MAP opens on the first mouse press")
    _check(controls.dispatch_control_event(mouse_release, &"map", 1010), "MAP consumes the matching mouse release")
    _check(controls.map_is_open(), "mouse release does not toggle MAP closed")

    _check(controls.set_map_open(false), "MAP can be reset closed between input modes")

    var touch_press := InputEventScreenTouch.new()
    touch_press.pressed = true
    var touch_release := InputEventScreenTouch.new()
    touch_release.pressed = false
    _check(controls.dispatch_control_event(touch_press, &"map", 2000), "MAP handles the first touch press")
    _check(controls.map_is_open(), "MAP opens on the first touch press")
    _check(controls.dispatch_control_event(touch_release, &"map", 2010), "MAP consumes the matching touch release")
    _check(controls.map_is_open(), "touch release does not toggle MAP closed")

    var synthetic_mouse_press := InputEventMouseButton.new()
    synthetic_mouse_press.button_index = MOUSE_BUTTON_LEFT
    synthetic_mouse_press.pressed = true
    _check(controls.dispatch_control_event(synthetic_mouse_press, &"map", 2020), "synthetic mouse press is consumed after touch")
    _check(controls.map_is_open(), "synthetic mouse press cannot double-toggle the touch-opened MAP")

    controls.free()

func _finish() -> void:
    if failures.is_empty():
        print("PROMPT_LOADING_UI_SINGLE_PRESS_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PROMPT_LOADING_UI_SINGLE_PRESS_SMOKE_FAIL: %s" % failure)
    quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
