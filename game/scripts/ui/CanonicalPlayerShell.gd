extends CanvasLayer
class_name CanonicalPlayerShell

## System 16 phone-first player shell.
## Owns inspector/menu presentation and hard-pause acquisition/restoration only.

signal interaction_blocked_changed(blocked: bool)

const MODAL_NONE: StringName = &""
const MODAL_STATS: StringName = &"stats"
const MODAL_INVENTORY: StringName = &"inventory"
const MODAL_MENU: StringName = &"menu"
const VIEW_SIZE := Vector2(640, 844)

var _kernel: TickKernel = null
var _stats_query: ActorStatsInspectorQuery = null
var _inventory_query: ActorInventoryInspectorQuery = null
var _actor_id: String = ""
var _active_modal: StringName = MODAL_NONE
var _pause_restore_captured: bool = false
var _pause_was_active: bool = false
var _overlay: ColorRect = null
var _title: Label = null
var _close_button: Button = null
var _body: VBoxContainer = null
var _last_lines: Array[String] = []
var _last_result: Dictionary = {}
var _leave_result: String = ""

func _ready() -> void:
    layer = 40
    _build_header_buttons()
    _build_modal_shell()

func configure(
    kernel: TickKernel,
    stats_query: ActorStatsInspectorQuery,
    inventory_query: ActorInventoryInspectorQuery,
    actor_id: String
) -> bool:
    if kernel == null or stats_query == null or inventory_query == null:
        return false
    if not stats_query.is_ready() or not inventory_query.is_ready():
        return false
    var normalized: String = actor_id.strip_edges()
    if normalized.is_empty():
        return false
    _kernel = kernel
    _stats_query = stats_query
    _inventory_query = inventory_query
    _actor_id = normalized
    return true

func is_configured() -> bool:
    return _kernel != null \
        and _stats_query != null \
        and _inventory_query != null \
        and not _actor_id.is_empty()

func active_modal() -> StringName:
    return _active_modal

func open_stats() -> void:
    if not is_configured():
        return
    _acquire_pause_if_needed()
    _active_modal = MODAL_STATS
    _show_overlay("SURVIVOR STATS", "CLOSE")
    _render_stats()

func open_inventory() -> void:
    if not is_configured():
        return
    _acquire_pause_if_needed()
    _active_modal = MODAL_INVENTORY
    _show_overlay("INVENTORY", "CLOSE")
    _render_inventory()

func open_menu() -> void:
    if not is_configured():
        return
    _acquire_pause_if_needed()
    _active_modal = MODAL_MENU
    _show_overlay("PAUSED", "RESUME")
    _render_menu()

func close_modal() -> void:
    if _active_modal == MODAL_NONE:
        return
    _active_modal = MODAL_NONE
    if _overlay != null:
        _overlay.visible = false
    _last_lines = []
    _last_result = {}
    if _pause_restore_captured and _kernel != null:
        _kernel.set_hard_paused(_pause_was_active)
    _pause_restore_captured = false
    interaction_blocked_changed.emit(false)

func presentation_snapshot() -> Dictionary:
    return {
        "configured": is_configured(),
        "active_modal": _active_modal,
        "hard_paused": false if _kernel == null else _kernel.is_hard_paused(),
        "pause_restore_captured": _pause_restore_captured,
        "pause_was_active": _pause_was_active,
        "lines": _last_lines.duplicate(),
        "result": _last_result.duplicate(true),
        "leave_result": _leave_result,
    }

func _acquire_pause_if_needed() -> void:
    if _active_modal != MODAL_NONE or _pause_restore_captured:
        return
    _pause_was_active = _kernel.is_hard_paused()
    _pause_restore_captured = true
    _kernel.set_hard_paused(true)
    interaction_blocked_changed.emit(true)

func _build_header_buttons() -> void:
    _add_header_button("STATS", Vector2(73, 16), Vector2(142, 42), Callable(self, "open_stats"))
    _add_header_button("INVENTORY", Vector2(229, 16), Vector2(182, 42), Callable(self, "open_inventory"))
    _add_header_button("MENU", Vector2(425, 16), Vector2(142, 42), Callable(self, "open_menu"))

func _add_header_button(text_value: String, position_value: Vector2, size_value: Vector2, callback: Callable) -> void:
    var button := Button.new()
    button.text = text_value
    button.position = position_value
    button.size = size_value
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 15)
    button.pressed.connect(callback)
    add_child(button)

func _build_modal_shell() -> void:
    _overlay = ColorRect.new()
    _overlay.position = Vector2.ZERO
    _overlay.size = VIEW_SIZE
    _overlay.color = Color(0.0, 0.0, 0.0, 0.86)
    _overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    _overlay.visible = false
    add_child(_overlay)

    var outer := MarginContainer.new()
    outer.position = Vector2(24, 70)
    outer.size = Vector2(592, 744)
    outer.add_theme_constant_override("margin_left", 12)
    outer.add_theme_constant_override("margin_right", 12)
    outer.add_theme_constant_override("margin_top", 12)
    outer.add_theme_constant_override("margin_bottom", 12)
    _overlay.add_child(outer)

    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    outer.add_child(panel)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 8)
    panel.add_child(root)

    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 8)
    root.add_child(header)

    _title = Label.new()
    _title.text = "INSPECT"
    _title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _title.add_theme_font_size_override("font_size", 22)
    header.add_child(_title)

    _close_button = Button.new()
    _close_button.text = "CLOSE"
    _close_button.custom_minimum_size = Vector2(110, 46)
    _close_button.focus_mode = Control.FOCUS_NONE
    _close_button.pressed.connect(close_modal)
    header.add_child(_close_button)

    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root.add_child(scroll)

    _body = VBoxContainer.new()
    _body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _body.add_theme_constant_override("separation", 7)
    scroll.add_child(_body)

func _show_overlay(title_text: String, close_text: String) -> void:
    if _overlay == null:
        _build_modal_shell()
    _clear_body()
    _title.text = title_text
    _close_button.text = close_text
    _overlay.visible = true

func _render_stats() -> void:
    var result: Dictionary = _stats_query.query(_actor_id)
    _last_result = result.duplicate(true)
    _last_lines = []
    if not bool(result.get("ok", false)):
        _append_line("Stats unavailable: %s" % String(result.get("reason", "unknown")), 15)
        return

    var status: Dictionary = result.get("status", {})
    _append_heading("CONDITION")
    _append_line("Stance: %s" % String(result.get("stance_label", "Unknown")), 15)
    _append_line("HP %d / %d" % [int(status.get("current_hp", -1)), int(status.get("max_hp", -1))], 15)
    _append_line("Fatigue %d / 100" % int(status.get("fatigue", -1)), 14)
    _append_line("Hunger %d / 100" % int(status.get("hunger", -1)), 14)
    _append_line("Thirst %d / 100" % int(status.get("thirst", -1)), 14)
    _append_line("Sleep pressure %d / 100" % int(status.get("sleep_pressure", -1)), 14)
    _append_line(
        "Carry %s / %s kg" % [
            _kg_text(int(status.get("carry_weight_grams", -1))),
            _kg_text(int(status.get("carry_capacity_grams", -1))),
        ],
        14
    )
    var moods: Array = status.get("moodlet_labels", [])
    _append_line("Moodlets: %s" % ("None" if moods.is_empty() else _join_values(moods)), 14)

    _append_heading("INJURIES")
    var injuries: Array = result.get("injuries", [])
    if injuries.is_empty():
        _append_line("None", 14)
    else:
        for injury_value: Variant in injuries:
            var injury: Dictionary = injury_value
            var treatment: Array[String] = []
            if bool(injury.get("stabilized", false)):
                treatment.append("Stabilized")
            if bool(injury.get("treated", false)):
                treatment.append("Treated")
            var suffix: String = "" if treatment.is_empty() else " • %s" % ", ".join(treatment)
            _append_line(
                "%s — %s — %s%s" % [
                    String(injury.get("injury_label", "Unknown")),
                    String(injury.get("body_region_label", "Unknown")),
                    String(injury.get("severity_label", "Unknown")),
                    suffix,
                ],
                14
            )

    _append_heading("SKILLS")
    for skill_value: Variant in result.get("skills", []):
        var skill: Dictionary = skill_value
        var skill_text: String
        if bool(skill.get("max_level", false)):
            skill_text = "%s — Level %d • MAX" % [String(skill.get("label", "Unknown")), int(skill.get("level", -1))]
        else:
            skill_text = "%s — Level %d • %d/%d XP" % [
                String(skill.get("label", "Unknown")),
                int(skill.get("level", -1)),
                int(skill.get("xp", -1)),
                int(skill.get("next_level_xp", -1)),
            ]
        _append_line(skill_text, 14)

func _render_inventory() -> void:
    var result: Dictionary = _inventory_query.query(_actor_id)
    _last_result = result.duplicate(true)
    _last_lines = []
    if not bool(result.get("ok", false)):
        _append_line("Inventory unavailable: %s" % String(result.get("reason", "unknown")), 15)
        return

    _append_heading("HANDS / LOADOUT")
    _append_line(_format_hand(result.get("primary_hand", {})), 14)
    _append_line(_format_hand(result.get("secondary_hand", {})), 14)

    _append_heading("CARRIED INVENTORY")
    var entries: Array = result.get("inventory", [])
    if entries.is_empty():
        _append_line("Empty", 14)
    else:
        for entry_value: Variant in entries:
            _append_inventory_entry(entry_value, 0)

    _append_heading("CARRY")
    var carry: Dictionary = result.get("carry", {})
    if String(carry.get("reason", "")).is_empty() and int(carry.get("capacity_grams", 0)) > 0:
        _append_line(
            "%s / %s kg" % [
                _kg_text(int(carry.get("weight_grams", -1))),
                _kg_text(int(carry.get("capacity_grams", -1))),
            ],
            14
        )
    else:
        _append_line("Unknown — %s" % String(carry.get("reason", "unclassified")), 14)

func _render_menu() -> void:
    _last_result = {"ok": true}
    _last_lines = []
    _append_line("Simulation hard-paused.", 16)
    _append_line("Resume returns to the exact pause state that existed before this shell opened.", 13)
    var leave_button := Button.new()
    leave_button.text = "LEAVE GAME"
    leave_button.custom_minimum_size = Vector2(0, 54)
    leave_button.focus_mode = Control.FOCUS_NONE
    leave_button.pressed.connect(_leave_game)
    _body.add_child(leave_button)
    _last_lines.append("LEAVE GAME")

func _format_hand(value: Variant) -> String:
    if typeof(value) != TYPE_DICTIONARY:
        return "Unknown Hand: Invalid"
    var hand: Dictionary = value
    var label: String = String(hand.get("hand_label", "Hand"))
    if bool(hand.get("empty", true)):
        return "%s: Empty" % label
    var item: Dictionary = hand.get("item", {})
    return "%s: %s" % [label, _item_text(item)]

func _append_inventory_entry(value: Variant, depth: int) -> void:
    if typeof(value) != TYPE_DICTIONARY:
        _append_line("%sInvalid inventory entry" % _indent(depth), 13)
        return
    var entry: Dictionary = value
    _append_line("%s%s" % [_indent(depth), _item_text(entry)], 13)
    for child_value: Variant in entry.get("children", []):
        _append_inventory_entry(child_value, depth + 1)

func _item_text(item: Dictionary) -> String:
    var label: String = String(item.get("label", "Unknown Item"))
    var item_id: String = String(item.get("item_id", ""))
    if not bool(item.get("valid", false)):
        return "%s [%s] — INVALID: %s" % [label, item_id, String(item.get("reason", "unknown"))]
    var weight_text: String = "Weight: Unknown"
    if bool(item.get("weight_known", false)):
        weight_text = "Weight: %s kg" % _kg_text(int(item.get("weight_grams", -1)))
    return "%s [%s] — %s" % [label, item_id, weight_text]

func _append_heading(text_value: String) -> void:
    var separator := HSeparator.new()
    separator.custom_minimum_size = Vector2(0, 6)
    _body.add_child(separator)
    _append_line(text_value, 18)

func _append_line(text_value: String, font_size: int) -> void:
    var label := Label.new()
    label.text = text_value
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override("font_size", font_size)
    _body.add_child(label)
    _last_lines.append(text_value)

func _clear_body() -> void:
    if _body == null:
        return
    for child: Node in _body.get_children():
        _body.remove_child(child)
        child.queue_free()

func _leave_game() -> void:
    _leave_result = "requested"
    if OS.has_feature("web"):
        var result: Variant = JavaScriptBridge.eval("window.location.assign('https://www.google.com/'); 'google';", true)
        _leave_result = "web:%s" % String(result)
        return
    _leave_result = "native:quit"
    get_tree().quit()

static func _kg_text(grams: int) -> String:
    if grams < 0:
        return "?"
    return "%.1f" % (float(grams) / 1000.0)

static func _join_values(values: Array) -> String:
    var parts := PackedStringArray()
    for value: Variant in values:
        parts.append(String(value))
    return ", ".join(parts)

static func _indent(depth: int) -> String:
    var result: String = ""
    for _index in range(maxi(0, depth)):
        result += "  "
    return result
