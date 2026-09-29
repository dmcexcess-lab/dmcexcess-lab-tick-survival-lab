extends SceneTree

const StartupPath := "res://main.tscn"

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    for script_path: String in [
        "res://scripts/app/GameMain.gd",
        "res://scripts/app/CraftingGameMain.gd",
        "res://scripts/app/UtilityGameMain.gd",
        "res://scripts/app/System34GameMain.gd",
        "res://scripts/app/VehicleGameMain.gd",
        "res://scripts/app/CombatGameMain.gd",
        "res://scripts/app/EnvironmentalPressureGameMain.gd",
        "res://scripts/app/TurnBasedGameMain.gd",
        "res://scripts/app/Slice7GameMain.gd",
        "res://scripts/app/FortificationGameMain.gd",
        "res://scripts/app/UtilitySimpleGameMain.gd",
        "res://scripts/app/VehicleSimpleGameMain.gd",
        "res://scripts/app/ProductionGameMain.gd",
    ]:
        var script_resource := load(script_path)
        _check(script_resource != null, "fresh script load succeeds: %s" % script_path)
        if script_resource == null:
            _finish()
            return

    var packed := load(StartupPath) as PackedScene
    _check(packed != null, "main.tscn loads")
    if packed == null:
        _finish()
        return
    var menu := packed.instantiate()
    _check(menu != null, "startup menu instantiates")
    if menu == null:
        _finish()
        return

    root.add_child(menu)
    current_scene = menu
    await process_frame
    await process_frame

    _check(menu.has_method("_launch_game"), "startup menu exposes launch path")
    if not menu.has_method("_launch_game"):
        _finish()
        return

    menu.call("_launch_game", {})
    var game: Node = null
    for _i in range(240):
        await process_frame
        if current_scene != null and current_scene != menu:
            game = current_scene
            break
        if menu == null or not is_instance_valid(menu):
            game = current_scene
            break

    _check(game != null, "NEW GAME transitions from main.tscn to gameplay.tscn")
    if game != null:
        _check(String(game.get_script().resource_path) == "res://scripts/app/ProductionGameMain.gd", "live startup reaches ProductionGameMain")
        _check(game.has_method("session_boot_ok") and bool(game.call("session_boot_ok")), "live startup gameplay boot succeeds")
        if game.has_method("session_boot_error"):
            _check(String(game.call("session_boot_error")).is_empty(), "live startup reports no boot error: %s" % String(game.call("session_boot_error")))

    _finish()

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    failures.append(message)
    push_error("STARTUP_FAIL: %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("STARTUP_BOOT_OK")
        quit(0)
    quit(1)
