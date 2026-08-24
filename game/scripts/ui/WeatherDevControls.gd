extends CanvasLayer
class_name WeatherDevControls

signal force_weather_requested(profile_id)
signal ambient_event_requested(kind)

var _service: WeatherService = null
var _status: Label = null

func _ready() -> void:
    layer = 28
    _build_ui()

func configure(service: WeatherService) -> bool:
    if service == null or not service.is_ready():
        return false
    _service = service
    _build_ui()
    present_weather(service.debug_snapshot())
    return true

func present_weather(snapshot: Dictionary) -> void:
    _build_ui()
    if _status == null:
        return
    var sample: Dictionary = snapshot.get("sample", {})
    _status.text = "DEV WEATHER  %s  rain %d%%  fog %d%%  wind %d%%" % [
        String(sample.get("weather_kind", "?" )).to_upper(),
        int(round(float(sample.get("precipitation", 0.0)) * 100.0)),
        int(round(float(sample.get("fog_density", 0.0)) * 100.0)),
        int(round(float(sample.get("wind_strength", 0.0)) * 100.0)),
    ]

func _build_ui() -> void:
    if _status != null:
        return
    var panel := PanelContainer.new()
    panel.position = Vector2(344, 8)
    panel.size = Vector2(288, 78)
    add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 2)
    panel.add_child(box)
    _status = Label.new()
    _status.text = "DEV WEATHER"
    _status.add_theme_font_size_override("font_size", 10)
    box.add_child(_status)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 2)
    box.add_child(row)
    _add_button(row, "CLR", &"clear")
    _add_button(row, "OVR", &"overcast")
    _add_button(row, "RAIN", &"rain")
    _add_button(row, "STM", &"storm")
    _add_button(row, "FOG", &"fog")
    var ambient := Button.new()
    ambient.text = "BLOW LEAF"
    ambient.focus_mode = Control.FOCUS_NONE
    ambient.custom_minimum_size = Vector2(86, 24)
    ambient.add_theme_font_size_override("font_size", 10)
    ambient.pressed.connect(func() -> void: ambient_event_requested.emit(&"leaf"))
    box.add_child(ambient)

func _add_button(parent: HBoxContainer, label: String, profile_id: StringName) -> void:
    var button := Button.new()
    button.text = label
    button.focus_mode = Control.FOCUS_NONE
    button.custom_minimum_size = Vector2(50, 24)
    button.add_theme_font_size_override("font_size", 9)
    button.pressed.connect(func() -> void: force_weather_requested.emit(profile_id))
    parent.add_child(button)
