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
    _check(hud.visible and hud.layer > 0, "HUD CanvasLayer is visible")
    _verify_hud_labels_visible(hud, "initial HUD")

    shell.open_stats()
    await process_frame
    var initial_stats: Dictionary = shell.presentation_snapshot()
    var initial_lines: Array = initial_stats.get("lines", [])
    _check(String(initial_stats.get("active_modal", "")) == "stats", "STATS modal opens")
    _check(bool((initial_stats.get("result", {}) as Dictionary).get("ok", false)), "STATS query succeeds")
    _check(_contains_text(initial_lines, "Health "), "STATS renders health")
    _check(_contains_text(initial_lines, "Fed "), "STATS renders condition values")
    _verify_stats_modal_visible(shell)
    shell.close_modal()

    _check(condition.set_condition(Fixture.PLAYER_ID, &"satiety", 29, &"prompt_stats_moodlet_test"), "test pressure can be applied through authoritative condition service")
    await process_frame
    hud.refresh()
    await process_frame
    var pressured: Dictionary = status.query(Fixture.PLAYER_ID)
    var labels: Array = pressured.get("moodlet_labels", [])
    _check("Famished" in labels or "Hungry" in labels, "condition query produces a hunger moodlet")
    var hud_snapshot: Dictionary = hud.presentation_snapshot()
    var hud_status: Dictionary = hud_snapshot.get("status", {})
    _check(not (hud_status.get("moodlet_descriptors", []) as Array).is_empty(), "HUD receives moodlet descriptors")
    _verify_hud_labels_visible(hud, "pressured HUD")
    _verify_moodlet_row_visible(hud)

    shell.open_stats()
    await process_frame
    var pressured_stats: Dictionary = shell.presentation_snapshot()
    var pressured_lines: Array = pressured_stats.get("lines", [])
    _check(_contains_text(pressured_lines, "Moodlets:"), "STATS renders moodlet row")
    _check(_contains_text(pressured_lines, "Famished") or _contains_text(pressured_lines, "Hungry"), "STATS renders the active hunger moodlet")
    _verify_stats_modal_visible(shell)
    shell.close_modal()

    print("PROMPT_STATS_MOODLETS_STATE %s" % JSON.stringify({
        "viewport": [root.size.x, root.size.y],
        "hud_layer": hud.layer,
        "shell_layer": shell.layer,
        "initial": initial,
        "pressured": pressured,
        "initial_stats_lines": initial_lines,
        "pressured_stats_lines": pressured_lines,
        "hud": hud_snapshot,
        "hud_visibility": _hud_visibility_snapshot(hud),
        "shell_visibility": _shell_visibility_snapshot(shell),
    }))
    _finish()

func _verify_hud_labels_visible(hud: CanonicalStatusHud, context: String) -> void:
    var values: Variant = hud.get("_labels")
    _check(typeof(values) == TYPE_ARRAY, "%s exposes label collection" % context)
    if typeof(values) != TYPE_ARRAY:
        return
    var labels: Array = values
    _check(labels.size() >= 5, "%s has five status lines" % context)
    for index: int in range(labels.size()):
        var label: Label = labels[index] as Label
        _check(label != null, "%s label %d exists" % [context, index])
        if label == null:
            continue
        _check(label.is_visible_in_tree(), "%s label %d is visible in tree" % [context, index])
        _check(label.size.x > 0.0 and label.size.y > 0.0, "%s label %d has drawable size" % [context, index])
        _check(_control_intersects_viewport(label), "%s label %d intersects viewport" % [context, index])

func _verify_moodlet_row_visible(hud: CanonicalStatusHud) -> void:
    var row: HBoxContainer = hud.get("_moodlet_row") as HBoxContainer
    _check(row != null, "moodlet row exists")
    if row == null:
        return
    _check(row.is_visible_in_tree(), "moodlet row is visible in tree")
    _check(_control_intersects_viewport(row), "moodlet row intersects viewport")
    _check(row.get_child_count() > 0, "moodlet row has rendered chip children")
    var visible_text: bool = false
    for child: Node in row.get_children():
        var label: Label = child as Label
        if label != null and label.is_visible_in_tree() and not label.text.strip_edges().is_empty():
            visible_text = true
            break
    _check(visible_text, "moodlet row has visible text")

func _verify_stats_modal_visible(shell: CanonicalPlayerShell) -> void:
    var overlay: ColorRect = shell.get("_overlay") as ColorRect
    var body: VBoxContainer = shell.get("_body") as VBoxContainer
    _check(shell.visible and shell.layer > 0, "PlayerShell CanvasLayer is visible")
    _check(overlay != null and overlay.is_visible_in_tree(), "STATS overlay is visible in tree")
    _check(body != null and body.is_visible_in_tree(), "STATS body is visible in tree")
    if body != null:
        _check(body.get_child_count() > 0, "STATS body has rendered controls")
        _check(_node_has_visible_label(body), "STATS body has visible label text")

func _node_has_visible_label(node: Node) -> bool:
    var label: Label = node as Label
    if label != null and label.is_visible_in_tree() and not label.text.strip_edges().is_empty():
        return true
    for child: Node in node.get_children():
        if _node_has_visible_label(child):
            return true
    return false

func _control_intersects_viewport(control: Control) -> bool:
    var rect := Rect2(control.global_position, control.size)
    return rect.intersects(Rect2(Vector2.ZERO, root.size))

func _hud_visibility_snapshot(hud: CanonicalStatusHud) -> Dictionary:
    var result: Dictionary = {"visible": hud.visible, "layer": hud.layer, "labels": [], "moodlets": {}}
    var labels: Variant = hud.get("_labels")
    if typeof(labels) == TYPE_ARRAY:
        for value: Variant in labels:
            var label: Label = value as Label
            if label == null:
                continue
            (result["labels"] as Array).append({
                "text": label.text,
                "visible": label.is_visible_in_tree(),
                "position": [label.global_position.x, label.global_position.y],
                "size": [label.size.x, label.size.y],
            })
    var row: HBoxContainer = hud.get("_moodlet_row") as HBoxContainer
    if row != null:
        result["moodlets"] = {
            "visible": row.is_visible_in_tree(),
            "position": [row.global_position.x, row.global_position.y],
            "size": [row.size.x, row.size.y],
            "children": row.get_child_count(),
        }
    return result

func _shell_visibility_snapshot(shell: CanonicalPlayerShell) -> Dictionary:
    var overlay: ColorRect = shell.get("_overlay") as ColorRect
    var body: VBoxContainer = shell.get("_body") as VBoxContainer
    return {
        "visible": shell.visible,
        "layer": shell.layer,
        "overlay_visible": false if overlay == null else overlay.is_visible_in_tree(),
        "body_visible": false if body == null else body.is_visible_in_tree(),
        "body_children": 0 if body == null else body.get_child_count(),
    }

func _find_button(node: Node, text_value: String) -> Button:
    var button := node as Button
    if button != null and button.text == text_value:
        return button
    for child: Node in node.get_children():
        var found: Button = _find_button(child, text_value)
        if found != null:
            return found
    return null

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
