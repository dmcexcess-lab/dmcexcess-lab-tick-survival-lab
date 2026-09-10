extends SceneTree

const MainScene = preload("res://main.tscn")
const FixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

const MAX_PRELOAD_FRAMES: int = 900
const MAX_GAME_BOOT_FRAMES: int = 900

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var menu: Node = MainScene.instantiate()
    _check(menu != null, "main scene instantiates")
    if menu == null:
        _finish()
        return

    root.add_child(menu)
    current_scene = menu
    await process_frame

    _check(menu.name == "StartupMenu", "main scene is the lightweight startup menu")
    _check(root.get_node_or_null("TickSurvivalGame") == null, "gameplay root is absent before NEW GAME")
    _check(FixtureClass.active_seed() < 0, "world generation has not started while menu is open")

    var new_game: Button = menu.get_node_or_null("Center/MenuPanel/Menu/NewGameButton") as Button
    var continue_game: Button = menu.get_node_or_null("Center/MenuPanel/Menu/ContinueButton") as Button
    var status: Label = menu.get_node_or_null("Center/MenuPanel/Menu/StatusLabel") as Label
    _check(new_game != null, "NEW GAME button exists")
    _check(continue_game != null, "CONTINUE button exists")
    _check(continue_game != null and continue_game.disabled, "CONTINUE is truthfully disabled until persistence exists")
    _check(status != null and not status.text.is_empty(), "startup loading status is visible")

    var preload_frames: int = 0
    while preload_frames < MAX_PRELOAD_FRAMES and menu.is_inside_tree() and not bool(menu.call("gameplay_resource_ready")):
        preload_frames += 1
        await process_frame

    _check(menu.is_inside_tree(), "menu remains current while gameplay resources preload")
    _check(bool(menu.call("gameplay_resource_ready")), "gameplay scene resources preload from the menu")
    _check(FixtureClass.active_seed() < 0, "resource preload does not prematurely create world truth")

    if new_game == null or not menu.is_inside_tree():
        _finish()
        return

    new_game.pressed.emit()
    await process_frame
    _check(bool(menu.call("is_launching_game")), "NEW GAME enters explicit loading state before world boot")

    var boot_frames: int = 0
    while boot_frames < MAX_GAME_BOOT_FRAMES and (current_scene == null or current_scene.name != "TickSurvivalGame"):
        boot_frames += 1
        await process_frame

    _check(current_scene != null and current_scene.name == "TickSurvivalGame", "NEW GAME hands off to the production gameplay scene")
    _check(FixtureClass.active_seed() > 0, "world generation occurs only after NEW GAME")
    _check(FixtureClass.global_plan() != null and FixtureClass.global_plan().is_generated(), "generated island plan survives startup handoff")

    _finish()

func _finish() -> void:
    if failures.is_empty():
        print("PROMPT_STARTUP_LOADING_SPLIT_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PROMPT_STARTUP_LOADING_SPLIT_SMOKE_FAIL: %s" % failure)
    quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
