extends SceneTree

const TITLE_SCENE_PATH: String = "res://main.tscn"
const GAMEPLAY_SCENE_PATH: String = "res://gameplay.tscn"
const MAX_TRANSITION_FRAMES: int = 1200

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var title: Node = _instantiate_title()
    if title == null:
        _finish()
        return

    var first_game: Node = await _start_game(title, "first")
    if first_game == null:
        _finish()
        return
    var second_title: Node = await _leave_game(first_game)
    if second_title == null:
        _finish()
        return
    var second_game: Node = await _start_game(second_title, "second")
    _check(second_game != null, "second production session boots after returning to title")
    if second_game != null:
        _check(second_game != first_game, "second session owns a fresh gameplay tree")
        _check(second_game.get("_world") != null and second_game.get("_kernel") != null, "second session owns fresh authoritative services")
    _finish()

func _instantiate_title() -> Node:
    var packed: PackedScene = load(TITLE_SCENE_PATH)
    _check(packed != null, "production title scene loads")
    if packed == null:
        return null
    var title: Node = packed.instantiate()
    root.add_child(title)
    current_scene = title
    return title

func _start_game(title: Node, ordinal: String) -> Node:
    await process_frame
    var button: Button = _find_button(title, "NEW GAME")
    _check(button != null, "%s title exposes NEW GAME" % ordinal)
    if button == null:
        return null
    button.pressed.emit()
    for _frame: int in range(MAX_TRANSITION_FRAMES):
        await process_frame
        var candidate: Node = current_scene
        if candidate == null or candidate.scene_file_path != GAMEPLAY_SCENE_PATH:
            continue
        if candidate.get("_world") != null and candidate.get("_kernel") != null and candidate.get("_shell") != null:
            _check(not is_instance_valid(title), "%s title tree is retired after its signal completes" % ordinal)
            return candidate
    _check(false, "%s NEW GAME transition completes" % ordinal)
    return null

func _leave_game(game: Node) -> Node:
    var shell: CanonicalPlayerShell = game.get("_shell") as CanonicalPlayerShell
    _check(shell != null and shell.is_configured(), "first session shell is configured")
    if shell == null:
        return null
    shell.open_menu()
    var leave_button: Button = _find_button(shell, "LEAVE GAME")
    _check(leave_button != null, "first session exposes LEAVE GAME")
    if leave_button == null:
        return null
    leave_button.pressed.emit()
    for _frame: int in range(120):
        await process_frame
        var candidate: Node = current_scene
        if candidate != null and candidate.scene_file_path == TITLE_SCENE_PATH:
            _check(not is_instance_valid(game), "first gameplay tree is retired before the next session")
            return candidate
    _check(false, "LEAVE GAME returns to production title")
    return null

func _find_button(node: Node, text_value: String) -> Button:
    var button := node as Button
    if button != null and button.text == text_value:
        return button
    for child: Node in node.get_children():
        var found: Button = _find_button(child, text_value)
        if found != null:
            return found
    return null

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("PROMPT_REPEATED_SESSION_LIFECYCLE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PROMPT_REPEATED_SESSION_LIFECYCLE_FAIL: %s" % failure)
    quit(1)
