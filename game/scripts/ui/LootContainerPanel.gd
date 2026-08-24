extends CanvasLayer
class_name LootContainerPanel

## Phone-first System 24 container UI. It reads current truth and emits semantic
## TAKE/STORE requests; it never mutates WHAT or System 11 directly and does not use
## hard pause because item transfers must be able to spend WHEN ticks while open.

signal take_requested(container_id, item_id)
signal store_requested(container_id, item_id)
signal interaction_blocked_changed(blocked)

const VIEW_SIZE := Vector2(640, 844)

var _inspection: LootContainerInspectionQuery = null
var _inventory: ActorInventoryInspectorQuery = null
var _actor_id: String = ""
var _container_id: String = ""
var _overlay: ColorRect = null
var _title: Label = null
var _status: Label = null
var _body: VBoxContainer = null

func _ready() -> void:
    layer = 45
    _build_ui()

func configure(
    inspection_query: LootContainerInspectionQuery,
    inventory_query: ActorInventoryInspectorQuery,
    actor_id: String
) -> bool:
    var normalized: String = actor_id.strip_edges()
    if inspection_query == null or not inspection_query.is_ready() \
        or inventory_query == null or not inventory_query.is_ready() \
        or normalized.is_empty():
        return false
    _inspection = inspection_query
    _inventory = inventory_query
    _actor_id = normalized
    return true

func is_configured() -> bool:
    return _inspection != null and _inventory != null and not _actor_id.is_empty()

func is_open() -> bool:
    return _overlay != null and _overlay.visible and not _container_id.is_empty()

func open_container(container_id: String) -> void:
    if not is_configured():
        return
    var normalized: String = container_id.strip_edges()
    if normalized.is_empty():
        return
    var was_open: bool = is_open()
    _container_id = normalized
    if _overlay == null:
        _build_ui()
    _overlay.visible = true
    _status.text = ""
    refresh()
    if not was_open:
        interaction_blocked_changed.emit(true)

func close_panel() -> void:
    if not is_open():
        return
    _container_id = ""
    _overlay.visible = false
    _status.text = ""
    interaction_blocked_changed.emit(false)

func refresh(_ignored_container_id: String = "") -> void:
    if not is_open() or not is_configured():
        return
    _render()

func present_action_result(intent: StringName, success: bool, reason: String, world_tick: int) -> void:
    if not is_open():
        return
    var verb: String = String(intent).trim_prefix("loot.").to_upper()
    if success:
        _status.text = "%s complete • tick %d" % [verb, world_tick]
    else:
        _status.text = "%s failed: %s" % [verb, reason.replace("_", " ")]
    refresh()

func presentation_snapshot() -> Dictionary:
    return {
        "configured": is_configured(),
        "open": is_open(),
        "container_id": _container_id,
        "status": "" if _status == null else _status.text,
    }

func _build_ui() -> void:
    if _overlay != null:
        return
    _overlay = ColorRect.new()
    _overlay.position = Vector2.ZERO
    _overlay.size = VIEW_SIZE
    _overlay.color = Color(0.0, 0.0, 0.0, 0.88)
    _overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    _overlay.visible = false
    add_child(_overlay)

    var outer := MarginContainer.new()
    outer.position = Vector2(20, 68)
    outer.size = Vector2(600, 754)
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
    _title.text = "SCAVENGE"
    _title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _title.add_theme_font_size_override("font_size", 22)
    header.add_child(_title)

    var close_button := Button.new()
    close_button.text = "CLOSE"
    close_button.custom_minimum_size = Vector2(110, 46)
    close_button.focus_mode = Control.FOCUS_NONE
    close_button.pressed.connect(close_panel)
    header.add_child(close_button)

    _status = Label.new()
    _status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _status.add_theme_font_size_override("font_size", 13)
    root.add_child(_status)

    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root.add_child(scroll)

    _body = VBoxContainer.new()
    _body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _body.add_theme_constant_override("separation", 7)
    scroll.add_child(_body)

func _render() -> void:
    _clear_body()
    var result: Dictionary = _inspection.query(_actor_id, _container_id)
    if not bool(result.get("ok", false)):
        _title.text = "SCAVENGE"
        _append_line("Container unavailable: %s" % String(result.get("reason", "unknown")).replace("_", " "), 15)
        return

    _title.text = String(result.get("container_label", "Container")).to_upper()
    var carry: Dictionary = result.get("carry", {})
    _append_line(
        "Carry %s kg / %s kg soft • %s kg hard" % [
            _kg(int(carry.get("weight_grams", -1))),
            _kg(int(carry.get("capacity_grams", -1))),
            _kg(int(carry.get("hard_limit_grams", -1))),
        ],
        13
    )
    _append_heading("CONTENTS")
    var contents: Array = result.get("items", [])
    if contents.is_empty():
        _append_line("Empty.", 15)
    else:
        for item_value: Variant in contents:
            var item: Dictionary = item_value
            _append_item_row(item, true)

    _append_heading("YOUR PACK")
    var inventory_result: Dictionary = _inventory.query(_actor_id)
    var personal: Array = inventory_result.get("inventory", []) if bool(inventory_result.get("ok", false)) else []
    if personal.is_empty():
        _append_line("No loose pack items to store.", 14)
    else:
        for item_value: Variant in personal:
            var item: Dictionary = item_value
            _append_personal_row(item)

func _append_item_row(item: Dictionary, can_take: bool) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    _body.add_child(row)

    var utility: String = String(item.get("utility_class", "")).to_upper()
    var family: String = String(item.get("family", "")).capitalize()
    var label_text: String = String(item.get("label", "Unknown Item"))
    var weight_text: String = _kg(int(item.get("weight_grams", -1))) if bool(item.get("weight_known", false)) else "?"
    var label := Label.new()
    label.text = "[%s • %s] %s — %s kg" % [utility, family, label_text, weight_text]
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", 14)
    row.add_child(label)

    if can_take:
        var item_id: String = String(item.get("item_id", ""))
        var button := Button.new()
        button.text = "TAKE"
        button.custom_minimum_size = Vector2(100, 48)
        button.focus_mode = Control.FOCUS_NONE
        button.disabled = item_id.is_empty() or not bool(item.get("valid", false))
        button.pressed.connect(func() -> void:
            take_requested.emit(_container_id, item_id)
        )
        row.add_child(button)

func _append_personal_row(item: Dictionary) -> void:
    var item_id: String = String(item.get("item_id", ""))
    var semantic: String = String(item.get("semantic_type", ""))
    var definition: Dictionary = _inspection._items.definition(StringName(semantic))
    var label_text: String = String(item.get("label", "Unknown Item"))
    var utility: String = String(definition.get("utility_class", "ITEM")).to_upper()
    var family: String = String(definition.get("family", "misc")).capitalize()
    var weight_text: String = _kg(int(item.get("weight_grams", -1))) if bool(item.get("weight_known", false)) else "?"

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    _body.add_child(row)
    var label := Label.new()
    label.text = "[%s • %s] %s — %s kg" % [utility, family, label_text, weight_text]
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", 14)
    row.add_child(label)

    var button := Button.new()
    button.text = "STORE"
    button.custom_minimum_size = Vector2(100, 48)
    button.focus_mode = Control.FOCUS_NONE
    button.disabled = item_id.is_empty() or not bool(item.get("valid", false))
    button.pressed.connect(func() -> void:
        store_requested.emit(_container_id, item_id)
    )
    row.add_child(button)

func _append_heading(text_value: String) -> void:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", 17)
    label.add_theme_constant_override("outline_size", 2)
    _body.add_child(label)

func _append_line(text_value: String, font_size: int) -> void:
    var label := Label.new()
    label.text = text_value
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", font_size)
    _body.add_child(label)

func _clear_body() -> void:
    if _body == null:
        return
    for child: Node in _body.get_children():
        _body.remove_child(child)
        child.free()

static func _kg(grams: int) -> String:
    if grams < 0:
        return "?"
    return "%.2f" % (float(grams) / 1000.0)
