extends CanvasLayer
class_name WorldInteractionPanel

signal action_requested(target_id, action_id)
signal interaction_blocked_changed(blocked)

var _panel: PanelContainer = null
var _title: Label = null
var _buttons: VBoxContainer = null
var _target_id: String = ""
var _open: bool = false

func _ready() -> void:
    layer = 38
    _build_ui()

func is_open() -> bool:
    return _open

func open_for_target(target_id: String, title: String, offers: Array[InteractionOffer]) -> bool:
    _build_ui()
    var key: String = target_id.strip_edges()
    if key.is_empty() or offers.is_empty(): return false
    _target_id = key
    _title.text = title
    for child: Node in _buttons.get_children(): child.queue_free()
    for offer: InteractionOffer in offers:
        if offer == null or offer.target_entity_id != key: continue
        var button := Button.new()
        button.text = offer.label
        button.focus_mode = Control.FOCUS_NONE
        button.custom_minimum_size = Vector2(170, 28)
        button.set_meta("world_target_id", key)
        button.set_meta("world_action_id", String(offer.action_id))
        button.pressed.connect(_choose.bind(offer.action_id))
        _buttons.add_child(button)
    var cancel := Button.new()
    cancel.text = "CANCEL"
    cancel.focus_mode = Control.FOCUS_NONE
    cancel.custom_minimum_size = Vector2(170, 26)
    cancel.pressed.connect(close_panel)
    _buttons.add_child(cancel)
    _panel.visible = true
    if not _open:
        _open = true
        interaction_blocked_changed.emit(true)
    return true

func close_panel() -> void:
    if _panel != null: _panel.visible = false
    _target_id = ""
    if _open:
        _open = false
        interaction_blocked_changed.emit(false)

func _choose(action_id: StringName) -> void:
    var target: String = _target_id
    close_panel()
    if not target.is_empty(): action_requested.emit(target, action_id)

func _build_ui() -> void:
    if _panel != null: return
    _panel = PanelContainer.new()
    _panel.position = Vector2(350, 235)
    _panel.custom_minimum_size = Vector2(190, 80)
    _panel.visible = false
    add_child(_panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 3)
    _panel.add_child(box)
    _title = Label.new()
    _title.text = "INTERACT"
    _title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title.add_theme_font_size_override("font_size", 11)
    box.add_child(_title)
    _buttons = VBoxContainer.new()
    _buttons.add_theme_constant_override("separation", 2)
    box.add_child(_buttons)
