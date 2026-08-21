extends CanvasLayer
class_name CameraControls

signal zoom_in_requested
signal zoom_out_requested
signal recenter_requested

const ROW_Y: float = 500.0
const BUTTON_SIZE := Vector2(132, 52)

var _enabled: bool = true
var _zoom_out_button: Button = null
var _center_button: Button = null
var _zoom_in_button: Button = null
var _last_snapshot: Dictionary = {}

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
    var zoom_label: String = String(snapshot.get("zoom_label", "NORMAL"))
    var level: int = int(snapshot.get("zoom_level", 2)) + 1
    var count: int = int(snapshot.get("zoom_level_count", 5))
    _center_button.text = "CENTER\n%s %d/%d" % [zoom_label, level, count]

func presentation_snapshot() -> Dictionary:
    return _last_snapshot.duplicate(true)

func _build_controls() -> void:
    if _center_button != null:
        return
    _zoom_out_button = _add_button("ZOOM -", Vector2(82, ROW_Y), Callable(self, "_on_zoom_out"))
    _center_button = _add_button("CENTER\nNORMAL 3/5", Vector2(255, ROW_Y), Callable(self, "_on_recenter"))
    _zoom_in_button = _add_button("ZOOM +", Vector2(426, ROW_Y), Callable(self, "_on_zoom_in"))

func _add_button(text_value: String, position_value: Vector2, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text_value
    button.position = position_value
    button.size = BUTTON_SIZE
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 13)
    button.disabled = not _enabled
    button.pressed.connect(callback)
    add_child(button)
    return button

func _on_zoom_out() -> void:
    if _enabled:
        zoom_out_requested.emit()

func _on_recenter() -> void:
    if _enabled:
        recenter_requested.emit()

func _on_zoom_in() -> void:
    if _enabled:
        zoom_in_requested.emit()
