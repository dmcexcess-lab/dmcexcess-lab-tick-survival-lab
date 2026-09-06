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
        _check(controls.control_surface_visible() and controls.visible, "walking controls are visible while unmounted")

    _check(not _has_script(game, "ConditionPlayerControls.gd"), "legacy Survival panel is not instantiated")
    _check(not _has_script(game, "ForagePlayerControls.gd"), "legacy Forage panel is not instantiated")
    _check(game.find_child("PerformanceDev", true, false) == null, "player-visible Dev panel is not instantiated")

    _check(game.find_child("VehiclePanel", true, false) == null, "mounted controls are not presented as a separate vehicle panel")
    var vehicle_surface := game.find_child("VehicleControlSurface", true, false) as Control
    _check(vehicle_surface != null, "replacement mounted driving surface exists")
    if vehicle_surface != null:
        var vehicle_controls := vehicle_surface.get_parent() as VehiclePlayerControls
        _check(vehicle_controls != null, "vehicle controls own the replacement surface")
        _check(not vehicle_surface.visible, "driving surface is hidden while on foot")
        _check(vehicle_controls != null and not vehicle_controls.visible, "vehicle CanvasLayer is hidden while on foot")
        _check(vehicle_surface.find_child("EnterButton", true, false) == null, "driving surface does not duplicate ENTER")
        for button_name: String in ["TurnLButton", "ForwardButton", "TurnRButton", "BrakeButton", "ReverseButton", "BackButton"]:
            var movement_button := vehicle_surface.find_child(button_name, true, false) as Button
            _check(movement_button != null, "mounted replacement includes %s" % button_name)
            _check(movement_button != null and movement_button.position.y >= 638.0, "%s occupies the walking-control footprint" % button_name)
            _check(movement_button != null and movement_button.pressed.get_connections().size() > 0, "%s is wired" % button_name)
        for button_name: String in [
            "ExitButton", "StartButton", "HotwireButton", "RepairButton", "AddRackButton", "RefuelButton",
            "StoreCargoButton", "TakeCargoButton",
        ]:
            var action_button := vehicle_surface.find_child(button_name, true, false) as Button
            _check(action_button != null, "mounted replacement preserves %s" % button_name)
            _check(action_button != null and action_button.position.y >= 638.0, "%s stays in the bottom replacement footprint" % button_name)
        if vehicle_controls != null and controls != null:
            vehicle_controls.call("_set_mounted_presentation", true)
            _check(vehicle_controls.visible and vehicle_surface.visible, "driving controls replace the walking surface when mounted")
            _check(not controls.visible and not controls.control_surface_visible(), "walking controls are removed from view when mounted")
            vehicle_controls.call("_set_mounted_presentation", false)
            _check(not vehicle_controls.visible and not vehicle_surface.visible, "driving controls disappear after dismount")
            _check(controls.visible and controls.control_surface_visible(), "walking controls return after dismount")

    var camera_controls := game.get_node_or_null("CameraControls") as CameraControls
    _check(camera_controls != null, "camera controls exist")
    if camera_controls != null:
        _check(not _has_button_text(camera_controls, "ZOOM -"), "ZOOM - button is removed")
        _check(not _has_button_text(camera_controls, "ZOOM +"), "ZOOM + button is removed")
        _check(_has_button_prefix(camera_controls, "CENTER"), "CENTER camera action remains available")
        var center_button := camera_controls.get_node_or_null("CenterButton") as Button
        var map_button := camera_controls.get_node_or_null("MapButton") as Button
        var forward_button := _find_button_prefix(controls, "FORWARD") if controls != null else null
        _check(center_button != null, "CENTER button has a stable production identity")
        _check(map_button != null and map_button.text == "MAP", "MAP button is adjacent to camera controls")
        _check(center_button != null and map_button != null and is_equal_approx(center_button.position.y, map_button.position.y), "CENTER and MAP share one row")
        _check(center_button != null and map_button != null and map_button.position.x > center_button.position.x, "MAP sits immediately to the right of CENTER")
        if center_button != null and forward_button != null:
            var vertical_gap: float = forward_button.position.y - (center_button.position.y + center_button.size.y)
            _check(vertical_gap >= 0.0 and vertical_gap <= 20.0, "CENTER row is dropped close to FORWARD without overlap")
        var island_map: IslandMapView = camera_controls.map_view()
        _check(island_map != null and island_map.is_configured(), "production scene configures the canonical island map")
        _check(island_map != null and island_map.map_bounds().size.x > 0 and island_map.map_bounds().size.y > 0, "island map owns generated world bounds")
        _check(island_map != null and island_map.has_player_marker(), "island map resolves the canonical player placement")
        _check(camera_controls.set_map_open(true), "MAP opens from the production camera control surface")
        _check(camera_controls.map_is_open() and island_map.visible, "island map overlay becomes visible")
        _check(camera_controls.layer > 22, "open island map is raised above the ordinary HUD")
        _check(island_map.surface_texture_size() == Vector2i(256, 256), "island map materializes deterministic generated-island surface pixels")
        _check(camera_controls.set_map_open(false), "island map closes cleanly")
        _check(not camera_controls.map_is_open() and not island_map.visible and camera_controls.layer == 22, "closing MAP restores ordinary camera-control presentation")

    var hud := game.get_node_or_null("Hud")
    _check(hud != null, "canonical HUD exists")
    if hud != null:
        _check(hud.get_node_or_null("HealthBar") == null, "health progress bar is removed")
        _check(hud.get_node_or_null("FatigueBar") == null, "stamina/fatigue progress bar is removed")
        var looking_panel := hud.get_node_or_null("LookingAtPanel") as Control
        _check(looking_panel != null, "Looking at panel exists")
        _check(looking_panel != null and looking_panel.position.y >= 58.0 and looking_panel.position.y < 100.0, "Looking at panel sits directly below the top menu buttons")
        var looking_label := _find_label_prefix(hud, "Looking at:")
        _check(looking_label != null and looking_label.position.y < 120.0, "Looking at text is presented at the top of the screen")

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

func _has_button_text(root: Node, text_value: String) -> bool:
    for node: Node in root.find_children("*", "Button", true, false):
        var button := node as Button
        if button != null and button.text == text_value:
            return true
    return false

func _has_button_prefix(root: Node, prefix: String) -> bool:
    return _find_button_prefix(root, prefix) != null

func _find_button_prefix(root: Node, prefix: String) -> Button:
    if root == null:
        return null
    for node: Node in root.find_children("*", "Button", true, false):
        var button := node as Button
        if button != null and button.text.begins_with(prefix):
            return button
    return null

func _find_label_prefix(root: Node, prefix: String) -> Label:
    for node: Node in root.find_children("*", "Label", true, false):
        var label := node as Label
        if label != null and label.text.begins_with(prefix):
            return label
    return null

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
