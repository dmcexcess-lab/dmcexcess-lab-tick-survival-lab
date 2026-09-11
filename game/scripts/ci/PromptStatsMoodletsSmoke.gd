extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const MAX_STARTUP_FRAMES: int = 1200

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://main.tscn")
    _check(packed != null, "production title scene loads")
    if packed == null:
        _finish()
        return
    var title: Node = packed.instantiate()
    root.add_child(title)
    current_scene = title
    await process_frame
    var new_game: Button = _find_button(title, "NEW GAME")
    _check(new_game != null, "production NEW GAME button exists")
    if new_game == null:
        _finish()
        return
    new_game.pressed.emit()

    var gameplay: Node = null
    for _frame: int in range(MAX_STARTUP_FRAMES):
        await process_frame
        if current_scene != null and current_scene.scene_file_path == "res://gameplay.tscn":
            gameplay = current_scene
            if bool(gameplay.get("_condition_service") != null) and bool(gameplay.get("_status_summary") != null):
                break

    _check(gameplay != null, "production gameplay boots")
    if gameplay == null:
        _finish()
        return

    var shell: CanonicalPlayerShell = gameplay.get_node_or_null("PlayerShell") as CanonicalPlayerShell
    var hud: CanonicalStatusHud = gameplay.get_node_or_null("Hud") as CanonicalStatusHud
    var status: ActorStatusSummaryQuery = gameplay.get("_status_summary") as ActorStatusSummaryQuery
    var condition: ActorConditionService = gameplay.get("_condition_service") as ActorConditionService
    _check(shell != null and shell.is_configured(), "production stats shell is configured")
    _check(hud != null and hud.is_configured(), "production status HUD is configured")
    _check(status != null and status.system34_ready(), "System 34 status summary is configured")
    _check(condition != null and condition.is_ready(), "System 34 condition service is configured")
    if shell == null or hud == null or status == null or condition == null:
        _finish()
        return

    var initial: Dictionary = status.query(Fixture.PLAYER_ID)
    _check(bool(initial.get("ok", false)) and bool(initial.get("system34", false)), "initial status query uses live System 34")
    _check(int(initial.get("satiety", -1)) >= 0 and int(initial.get("hydration", -1)) >= 0 and int(initial.get("rest", -1)) >= 0, "initial condition values are valid")

    shell.open_stats()
    var initial_stats: Dictionary = shell.presentation_snapshot()
    var initial_lines: Array = initial_stats.get("lines", [])
    _check(String(initial_stats.get("active_modal", "")) == "stats", "STATS modal opens")
    _check(bool((initial_stats.get("result", {}) as Dictionary).get("ok", false)), "STATS query succeeds")
    _check(_contains_prefix(initial_lines, "HP "), "STATS renders HP")
    _check(_contains_prefix(initial_lines, "Hunger "), "STATS renders condition values")
    shell.close_modal()

    _check(condition.set_condition(Fixture.PLAYER_ID, &"satiety", 29, &"prompt_stats_moodlet_test"), "test pressure can be applied through authoritative condition service")
    await process_frame
    hud.refresh()
    var pressured: Dictionary = status.query(Fixture.PLAYER_ID)
    var labels: Array = pressured.get("moodlet_labels", [])
    _check("Famished" in labels or "Hungry" in labels, "condition query produces a hunger moodlet")
    var hud_snapshot: Dictionary = hud.presentation_snapshot()
    var hud_status: Dictionary = hud_snapshot.get("status", {})
    _check(not (hud_status.get("moodlet_descriptors", []) as Array).is_empty(), "HUD receives moodlet descriptors")

    shell.open_stats()
    var pressured_stats: Dictionary = shell.presentation_snapshot()
    var pressured_lines: Array = pressured_stats.get("lines", [])
    _check(_contains_text(pressured_lines, "Moodlets:"), "STATS renders moodlet row")
    _check(_contains_text(pressured_lines, "Famished") or _contains_text(pressured_lines, "Hungry"), "STATS renders the active hunger moodlet")
    shell.close_modal()

    print("PROMPT_STATS_MOODLETS_STATE %s" % JSON.stringify({
        "initial": initial,
        "pressured": pressured,
        "initial_stats_lines": initial_lines,
        "pressured_stats_lines": pressured_lines,
        "hud": hud_snapshot,
    }))
    _finish()

func _find_button(node: Node, text_value: String) -> Button:
    var button := node as Button
    if button != null and button.text == text_value:
        return button
    for child: Node in node.get_children():
        var found: Button = _find_button(child, text_value)
        if found != null:
            return found
    return null

func _contains_prefix(values: Array, prefix: String) -> bool:
    for value: Variant in values:
        if String(value).begins_with(prefix):
            return true
    return false

func _contains_text(values: Array, text_value: String) -> bool:
    for value: Variant in values:
        if String(value).contains(text_value):
            return true
    return false

func _check(condition_value: bool, message: String) -> void:
    if not condition_value:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("PROMPT_STATS_MOODLETS_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PROMPT_STATS_MOODLETS_FAIL: %s" % failure)
    quit(1)
