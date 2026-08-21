extends CanvasLayer
class_name CameraControls

signal zoom_in_requested
signal zoom_out_requested
signal recenter_requested

const ROW_Y: float = 500.0
const BUTTON_SIZE := Vector2(132, 52)
const SYNTHETIC_MOUSE_SUPPRESS_MS: int = 500

var _enabled: bool = true
var _zoom_out_button: Button = null
var _center_button: Button = null
var _zoom_in_button: Button = null
var _last_snapshot: Dictionary = {}
var _suppress_mouse_until_ms: int = 0

func _ready() -> void:
    layer = 22
    _build_controls()

func set_enabled(value: bool) -> void:
    _enabled = value
    _build_controls()
    _zoom_out_button.disabled = not value
    _center_button.disabled = not value
    _zoom_in_button.disabled = not value

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

func _build_controls() -> void:
    if _center_button != null:
        return
    _zoom_out_button = _add_button("ZOOM -", Vector2(82, ROW_Y), Callable(self, "_on_zoom_out"))
    _center_button = _add_button("CENTER\nFOLLOW", Vector2(255, ROW_Y), Callable(self, "_on_recenter"))
    _zoom_in_button = _add_button("ZOOM +", Vector2(426, ROW_Y), Callable(self, "_on_zoom_in"))

func _add_button(text_value: String, position_value: Vector2, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text_value
    button.position = position_value
    button.size = BUTTON_SIZE
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 13)
    button.disabled = not _enabled
    button.gui_input.connect(_on_button_gui_input.bind(callback))
    add_child(button)
    return button

func _on_button_gui_input(event: InputEvent, callback: Callable) -> void:
    if not _enabled:
        return
    var now_ms: int = Time.get_ticks_msec()
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            return
        _suppress_mouse_until_ms = now_ms + SYNTHETIC_MOUSE_SUPPRESS_MS
        callback.call()
        get_viewport().set_input_as_handled()
        return
    if event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.button_index != MOUSE_BUTTON_LEFT or mouse.pressed:
            return
        if now_ms <= _suppress_mouse_until_ms:
            get_viewport().set_input_as_handled()
            return
        callback.call()
        get_viewport().set_input_as_handled()

func _on_zoom_out() -> void:
    if _enabled:
        zoom_out_requested.emit()

func _on_recenter() -> void:
    if _enabled:
        recenter_requested.emit()

func _on_zoom_in() -> void:
    if _enabled:
        zoom_in_requested.emit()
