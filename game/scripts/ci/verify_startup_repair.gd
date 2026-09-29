extends SceneTree

const StartupPath := "res://main.tscn"

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
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
