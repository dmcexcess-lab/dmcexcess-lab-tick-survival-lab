extends CanvasLayer
class_name WorldInteractionPanel

signal action_requested(target_id, action_id)
signal interaction_blocked_changed(blocked)

const PANEL_SIDE_MARGIN: float = 24.0
const PANEL_TOP_FRACTION: float = 0.18
const PANEL_MAX_WIDTH: float = 520.0
const PANEL_MIN_SCROLL_HEIGHT: float = 56.0
const PANEL_VERTICAL_RESERVED: float = 280.0
const ACTION_TOUCH_HEIGHT: float = 52.0
const CANCEL_TOUCH_HEIGHT: float = 52.0

var _panel: PanelContainer = null
var _title: Label = null
var _scroll: ScrollContainer = null
var _buttons: VBoxContainer = null
var _target_id: String = ""
var _target_ids: Array[String] = []
var _open: bool = false

func _ready() -> void:
    layer = 38
    _build_ui()
    var viewport: Viewport = get_viewport()
    if viewport != null:
        var callback := Callable(self, "_refresh_layout")
        if not viewport.size_changed.is_connected(callback):
            viewport.size_changed.connect(callback)

func is_open() -> bool:
    return _open

func open_for_target(target_id: String, title: String, offers: Array[InteractionOffer]) -> bool:
    var entry: Dictionary = {
        "target_id": target_id,
        "title": title,
        "offers": offers,
    }
    var entries: Array[Dictionary] = [entry]
    return open_for_targets(entries)

func open_for_targets(entries: Array[Dictionary]) -> bool:
    _build_ui()
    var valid_entries: Array[Dictionary] = []
    for entry: Dictionary in entries:
        var key: String = String(entry.get("target_id", "")).strip_edges()
        if key.is_empty():
            continue
        var filtered: Array[InteractionOffer] = []
        for offer_value: Variant in entry.get("offers", []):
            var offer: InteractionOffer = offer_value as InteractionOffer
            if offer != null and offer.target_entity_id == key:
                filtered.append(offer)
        if filtered.is_empty():
            continue
        valid_entries.append({
            "target_id": key,
            "title": String(entry.get("title", "INTERACT")),
            "offers": filtered,
        })
    if valid_entries.is_empty():
        close_panel()
        return false

    _clear_buttons()
    _target_ids.clear()
    for entry: Dictionary in valid_entries:
        _target_ids.append(String(entry.get("target_id", "")))
    _target_id = _target_ids[0] if _target_ids.size() == 1 else ""
    _title.text = String(valid_entries[0].get("title", "INTERACT")) if valid_entries.size() == 1 else "INTERACT"

    var show_target_headings: bool = valid_entries.size() > 1
    for entry: Dictionary in valid_entries:
        var key: String = String(entry.get("target_id", ""))
        if show_target_headings:
            _add_target_heading(String(entry.get("title", "INTERACT")))
        for offer_value: Variant in entry.get("offers", []):
            var offer: InteractionOffer = offer_value as InteractionOffer
            if offer != null:
                _add_action_button(key, offer)
    _add_cancel_button()

    _panel.visible = true
    _refresh_layout()
    if not _open:
        _open = true
        interaction_blocked_changed.emit(true)
    return true

func close_panel() -> void:
    if _panel != null:
        _panel.visible = false
    _clear_buttons()
    _target_id = ""
    _target_ids.clear()
    if _open:
        _open = false
        interaction_blocked_changed.emit(false)

func _choose(target_id: String, action_id: StringName) -> void:
    var target: String = target_id.strip_edges()
    close_panel()
    if not target.is_empty():
        action_requested.emit(target, action_id)

func _add_target_heading(text_value: String) -> void:
    var heading := Label.new()
    heading.text = text_value
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    heading.add_theme_font_size_override("font_size", 13)
    heading.custom_minimum_size = Vector2(0, 28)
    _buttons.add_child(heading)

func _add_action_button(target_id: String, offer: InteractionOffer) -> void:
    var button := Button.new()
    button.text = offer.label
    button.focus_mode = Control.FOCUS_NONE
    button.custom_minimum_size = Vector2(0, ACTION_TOUCH_HEIGHT)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size", 16)
    button.set_meta("world_target_id", target_id)
    button.set_meta("world_action_id", String(offer.action_id))
    button.pressed.connect(_choose.bind(target_id, offer.action_id))
    _buttons.add_child(button)

func _add_cancel_button() -> void:
    var cancel := Button.new()
    cancel.text = "CANCEL"
    cancel.focus_mode = Control.FOCUS_NONE
    cancel.custom_minimum_size = Vector2(0, CANCEL_TOUCH_HEIGHT)
    cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cancel.add_theme_font_size_override("font_size", 16)
    cancel.pressed.connect(close_panel)
    _buttons.add_child(cancel)

func _clear_buttons() -> void:
    if _buttons == null:
        return
    for child: Node in _buttons.get_children():
        child.queue_free()

func _refresh_layout() -> void:
    if _panel == null or _scroll == null or _buttons == null:
        return
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return
    var available_width: float = maxf(120.0, viewport_size.x - PANEL_SIDE_MARGIN * 2.0)
    var panel_width: float = minf(PANEL_MAX_WIDTH, available_width)
    var available_scroll_height: float = maxf(
        PANEL_MIN_SCROLL_HEIGHT,
        viewport_size.y - PANEL_VERTICAL_RESERVED
    )
    var content_height: float = maxf(PANEL_MIN_SCROLL_HEIGHT, _buttons.get_combined_minimum_size().y)
    _scroll.custom_minimum_size = Vector2(0, minf(content_height, available_scroll_height))

    var minimum_size: Vector2 = _panel.get_combined_minimum_size()
    var panel_height: float = minf(minimum_size.y, maxf(80.0, viewport_size.y - PANEL_SIDE_MARGIN * 2.0))
    _panel.size = Vector2(panel_width, panel_height)
    _position_panel(viewport_size, _panel.size)
    # Container minimum sizes settle after children enter the layout queue. Clamp once
    # more on the deferred pass so the first visible frame cannot drift off-screen.
    call_deferred("_clamp_after_layout")

func _clamp_after_layout() -> void:
    if _panel == null or not _panel.visible:
        return
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return
    var max_size := Vector2(
        maxf(120.0, viewport_size.x - PANEL_SIDE_MARGIN * 2.0),
        maxf(80.0, viewport_size.y - PANEL_SIDE_MARGIN * 2.0)
    )
    var actual_size: Vector2 = _panel.size
    if actual_size.y > max_size.y:
        var overflow: float = actual_size.y - max_size.y
        _scroll.custom_minimum_size.y = maxf(PANEL_MIN_SCROLL_HEIGHT, _scroll.custom_minimum_size.y - overflow)
        _panel.reset_size()
        actual_size = _panel.size
    if actual_size.x > max_size.x:
        actual_size.x = max_size.x
        _panel.size.x = max_size.x
    _position_panel(viewport_size, actual_size)

func _position_panel(viewport_size: Vector2, panel_size: Vector2) -> void:
    var max_x: float = maxf(PANEL_SIDE_MARGIN, viewport_size.x - panel_size.x - PANEL_SIDE_MARGIN)
    var max_y: float = maxf(PANEL_SIDE_MARGIN, viewport_size.y - panel_size.y - PANEL_SIDE_MARGIN)
    var desired_x: float = (viewport_size.x - panel_size.x) * 0.5
    var desired_y: float = viewport_size.y * PANEL_TOP_FRACTION
    _panel.position = Vector2(
        minf(maxf(PANEL_SIDE_MARGIN, desired_x), max_x),
        minf(maxf(PANEL_SIDE_MARGIN, desired_y), max_y)
    )

func _build_ui() -> void:
    if _panel != null:
        return
    _panel = PanelContainer.new()
    _panel.name = "WorldInteractionPanelContainer"
    _panel.custom_minimum_size = Vector2(280, 80)
    _panel.visible = false
    add_child(_panel)

    var box := VBoxContainer.new()
    box.name = "WorldInteractionLayout"
    box.add_theme_constant_override("separation", 8)
    _panel.add_child(box)

    _title = Label.new()
    _title.name = "WorldInteractionTitle"
    _title.text = "INTERACT"
    _title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _title.add_theme_font_size_override("font_size", 16)
    _title.custom_minimum_size = Vector2(0, 28)
    box.add_child(_title)

    _scroll = ScrollContainer.new()
    _scroll.name = "WorldInteractionScroll"
    _scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    box.add_child(_scroll)

    _buttons = VBoxContainer.new()
    _buttons.name = "WorldInteractionButtons"
    _buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _buttons.add_theme_constant_override("separation", 6)
    _scroll.add_child(_buttons)
