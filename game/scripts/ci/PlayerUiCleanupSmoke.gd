extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://main.tscn")
    _check(packed != null, "main scene loads")
    if packed == null:
        _finish()
        return
    var game := packed.instantiate()
    get_root().add_child(game)
    await process_frame

    var controls := game.get_node_or_null("Controls") as PlayerMovementControls
    _check(controls != null, "on-foot control strip exists")
    if controls != null:
        var forage := controls.get_node_or_null("ForageButton") as Button
        var enter_vehicle := controls.get_node_or_null("EnterVehicleButton") as Button
        _check(forage != null and forage.text == "FORAGE", "FORAGE is on the bottom on-foot strip")
        _check(enter_vehicle != null and enter_vehicle.text == "ENTER VEHICLE", "ENTER VEHICLE is on the bottom on-foot strip")
        _check(forage != null and forage.position.y >= 600.0, "FORAGE remains in the bottom control zone")
        _check(enter_vehicle != null and enter_vehicle.position.y >= 600.0, "ENTER VEHICLE remains in the bottom control zone")
        _check(controls.forage_requested.get_connections().size() > 0, "FORAGE bottom action is wired to production gameplay")
        _check(controls.enter_vehicle_requested.get_connections().size() > 0, "ENTER VEHICLE bottom action is wired to production gameplay")
        _check(controls.control_surface_visible() and controls.visible, "on-foot movement surface is visible while unmounted")

    _check(not _has_script(game, "ConditionPlayerControls.gd"), "legacy Survival panel is not instantiated")
    _check(not _has_script(game, "ForagePlayerControls.gd"), "legacy Forage panel is not instantiated")
    _check(game.find_child("PerformanceDev", true, false) == null, "player-visible Dev panel is not instantiated")

    var vehicle_panel := game.find_child("VehiclePanel", true, false) as Control
    _check(vehicle_panel != null, "mounted vehicle controls still exist")
    if vehicle_panel != null:
        var vehicle_controls := vehicle_panel.get_parent() as VehiclePlayerControls
        _check(vehicle_controls != null, "vehicle controls own the mounted bottom surface")
        _check(not vehicle_panel.visible, "vehicle control surface is hidden while on foot")
        _check(vehicle_controls != null and not vehicle_controls.visible, "vehicle CanvasLayer is hidden while on foot")
        _check(vehicle_panel.position.y >= 600.0, "vehicle controls occupy the bottom control zone")
        _check(vehicle_panel.find_child("EnterButton", true, false) == null, "vehicle controls do not duplicate ENTER")
        for button_name: String in ["TurnLButton", "ForwardButton", "TurnRButton", "BackButton"]:
            var movement_button := vehicle_panel.find_child(button_name, true, false) as Button
            _check(movement_button != null, "mounted vehicle surface includes %s" % button_name)
            _check(movement_button != null and movement_button.pressed.get_connections().size() > 0, "%s is wired" % button_name)
        for button_name: String in [
            "ExitButton", "StartButton", "HotwireButton", "BrakeButton", "ReverseButton",
            "RepairButton", "AddRackButton", "RefuelButton", "Store→Button", "←TakeButton",
        ]:
            _check(vehicle_panel.find_child(button_name, true, false) != null, "mounted vehicle surface preserves %s" % button_name)
        if vehicle_controls != null and controls != null:
            vehicle_controls.call("_set_mounted_presentation", true)
            _check(vehicle_controls.visible and vehicle_panel.visible, "vehicle surface appears when mounted")
            _check(not controls.visible and not controls.control_surface_visible(), "player movement surface hides when mounted")
            vehicle_controls.call("_set_mounted_presentation", false)
            _check(not vehicle_controls.visible and not vehicle_panel.visible, "vehicle surface hides after dismount")
            _check(controls.visible and controls.control_surface_visible(), "player movement surface returns after dismount")

    var hud := game.get_node_or_null("Hud")
    _check(hud != null, "canonical HUD exists")
    if hud != null:
        var health := hud.get_node_or_null("HealthBar") as ProgressBar
        var fatigue := hud.get_node_or_null("FatigueBar") as ProgressBar
        _check(health != null and health.position.y < 100.0, "health bar is at the top of the screen")
        _check(fatigue != null and fatigue.position.y < 100.0, "fatigue/stamina bar is at the top of the screen")

    game.queue_free()
    await process_frame
    _finish()

func _has_script(root: Node, suffix: String) -> bool:
    var nodes: Array[Node] = [root]
    nodes.append_array(root.find_children("*", "", true, false))
    for node: Node in nodes:
        var script: Script = node.get_script() as Script
        if script != null and String(script.resource_path).ends_with(suffix):
            return true
    return false

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("PLAYER_UI_CLEANUP_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PLAYER_UI_CLEANUP_SMOKE_FAIL: %s" % failure)
    quit(1)
