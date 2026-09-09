extends SceneTree

var failures: int = 0

func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error(message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var camera := CameraControls.new()
    var controls := VehiclePlayerControls.new()
    root.add_child(camera)
    root.add_child(controls)
    controls.call("_set_mounted_presentation", true)
    await process_frame
    var surface: Control = controls.get("_surface")
    var status: Label = surface.get_node("VehicleStatus")
    var cargo: Label = surface.get_node("CargoStatus")
    status.text = "VEHICLE — MOTORCYCLE | fuel 1400 | heading 270° | moving"
    cargo.text = "CARGO — 12.0 / 12.0 kg"
    await process_frame
    var center: Button = camera.get_node("CenterButton")
    var map: Button = camera.get_node("MapButton")
    for label: Label in [status, cargo]:
        for button: Button in [center, map]:
            check(not label.get_global_rect().intersects(button.get_global_rect()), "status must not overlap camera controls")
        check(label.size.y >= label.get_minimum_size().y, "status font fits its row")
        check(Rect2(Vector2.ZERO, VehiclePlayerControls.VIEW_SIZE).encloses(label.get_global_rect()), "status remains within viewport")
    check(not status.get_global_rect().intersects(cargo.get_global_rect()), "status rows remain separate")
    var interactive: Array[Control] = [center, map]
    for child: Node in surface.get_children():
        if child is BaseButton:
            interactive.append(child)
    for i: int in range(interactive.size()):
        var button: Control = interactive[i]
        check(Rect2(Vector2.ZERO, VehiclePlayerControls.VIEW_SIZE).encloses(button.get_global_rect()), "button fits viewport")
        for j: int in range(i + 1, interactive.size()):
            check(not button.get_global_rect().intersects(interactive[j].get_global_rect()), "interactive controls do not overlap")
    check(surface.get_node("StoreCargoButton").text == "STORE", "store label needs no arrow glyph")
    check(surface.get_node("TakeCargoButton").text == "TAKE", "take label needs no arrow glyph")
    controls.call("_set_mounted_presentation", false)
    check(not controls.visible and not surface.visible, "dismount hides vehicle surface")
    camera.queue_free()
    controls.queue_free()
    await process_frame
    print("PROMPT_VEHICLE_CONTROLS_SMOKE: PASS" if failures == 0 else "PROMPT_VEHICLE_CONTROLS_SMOKE: FAIL")
    quit(0 if failures == 0 else 1)
