extends CanvasLayer
class_name CameraControls

signal zoom_in_requested
signal zoom_out_requested
signal recenter_requested

const ACTION_ZOOM_OUT: StringName = &"zoom_out"
const ACTION_RECENTER: StringName = &"recenter"
const ACTION_ZOOM_IN: StringName = &"zoom_in"
const ROW_Y: float = 500.0
const BUTTON_SIZE := Vector2(132, 52)
const SYNTHETIC_MOUSE_SUPPRESS_MS: int = 500

var _enabled: bool = true
var _center_button: Button = null
var _last_snapshot: Dictionary = {}
var _suppress_mouse_until_ms: int = 0

func _ready() -> void:
    layer = 22
    _build_controls()

func set_enabled(value: bool) -> void:
    _enabled = value
    _build_controls()
    if _center_button != null:
        _center_button.disabled = not value

func is_enabled() -> bool:
    return _enabled

func present_camera_state(snapshot: Dictionary) -> void:
    _last_snapshot = snapshot.duplicate(true)
    _build_controls()
    var mode_label: String = String(snapshot.get("mode_label", "FOLLOW PLAYER"))
    var short_mode: String = "FOLLOW" if mode_label == "FOLLOW PLAYER" else mode_label
    _center_button.text = "CENTER\n%s" % short_mode

func presentation_snapshot() -> Dictionary:
    return _last_snapshot.duplicate(true)

func dispatch_control_event(event: InputEvent, action: StringName, now_ms: int = -1) -> bool:
    if not _enabled or event == null or not _is_valid_action(action):
        return false
    var resolved_now: int = Time.get_ticks_msec() if now_ms < 0 else now_ms
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            return false
        _suppress_mouse_until_ms = resolved_now + SYNTHETIC_MOUSE_SUPPRESS_MS
        _emit_action(action)
        return true
    if event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.button_index != MOUSE_BUTTON_LEFT or mouse.pressed:
            return false
        if resolved_now <= _suppress_mouse_until_ms:
            return true
        _emit_action(action)
        return true
    return false

func _build_controls() -> void:
    if _center_button != null:
        return
    _center_button = _add_button("CENTER\nFOLLOW", Vector2(255, ROW_Y), ACTION_RECENTER)

func _add_button(text_value: String, position_value: Vector2, action: StringName) -> Button:
    var button := Button.new()
    button.text = text_value
    button.position = position_value
    button.size = BUTTON_SIZE
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 13)
    button.disabled = not _enabled
    button.gui_input.connect(_on_button_gui_input.bind(action))
    add_child(button)
    return button

func _on_button_gui_input(event: InputEvent, action: StringName) -> void:
    if dispatch_control_event(event, action):
        get_viewport().set_input_as_handled()

func _emit_action(action: StringName) -> void:
    match action:
        ACTION_ZOOM_OUT:
            zoom_out_requested.emit()
        ACTION_RECENTER:
            recenter_requested.emit()
        ACTION_ZOOM_IN:
            zoom_in_requested.emit()

func _is_valid_action(action: StringName) -> bool:
    return action == ACTION_ZOOM_OUT or action == ACTION_RECENTER or action == ACTION_ZOOM_IN
