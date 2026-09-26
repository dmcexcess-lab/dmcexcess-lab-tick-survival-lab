extends CanvasLayer
class_name SessionControls

signal save_requested
signal save_leave_requested

var _save_button: Button = null
var _leave_button: Button = null
var _status_label: Label = null

func _ready() -> void:
    layer = 90
    var panel := PanelContainer.new()
    panel.anchor_left = 1.0
    panel.anchor_right = 1.0
    panel.offset_left = -248.0
    panel.offset_right = -8.0
    panel.offset_top = 8.0
    panel.offset_bottom = 86.0
    add_child(panel)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 4)
    panel.add_child(column)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 6)
    column.add_child(row)

    _save_button = Button.new()
    _save_button.text = "SAVE"
    _save_button.focus_mode = Control.FOCUS_NONE
    _save_button.pressed.connect(func() -> void: save_requested.emit())
    row.add_child(_save_button)

    _leave_button = Button.new()
    _leave_button.text = "SAVE & MENU"
    _leave_button.focus_mode = Control.FOCUS_NONE
    _leave_button.pressed.connect(func() -> void: save_leave_requested.emit())
    row.add_child(_leave_button)

    _status_label = Label.new()
    _status_label.text = "AUTOSAVE ON"
    _status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(_status_label)

func set_actions_enabled(enabled: bool) -> void:
    if _save_button != null:
        _save_button.disabled = not enabled
    if _leave_button != null:
        _leave_button.disabled = not enabled

func set_status(message: String) -> void:
    if _status_label != null:
        _status_label.text = message
