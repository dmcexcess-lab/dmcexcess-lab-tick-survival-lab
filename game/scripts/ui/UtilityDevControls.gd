extends CanvasLayer
class_name UtilityDevControls

## Small truthful DEV surface for human play of System 33. Buttons mutate the same
## persistent utility domain queried by lighting, water and refrigeration.

var _utilities: UtilityRuntimeState = null
var _power_service_id: String = ""
var _water_service_id: String = ""
var _refrigerator_id: String = ""
var _power_branch_id: String = ""
var _water_local_id: String = ""
var _status: Label = null
var _fridge_button: Button = null

func _ready() -> void:
    layer = 35
    _build_ui()
    _refresh()

func configure(
    utilities: UtilityRuntimeState,
    power_service_id: String,
    water_service_id: String,
    refrigerator_id: String = ""
) -> bool:
    if utilities == null or not utilities.is_ready():
        return false
    _utilities = utilities
    _power_service_id = power_service_id.strip_edges()
    _water_service_id = water_service_id.strip_edges()
    _refrigerator_id = refrigerator_id.strip_edges()
    _power_branch_id = _utilities.power_branch_component_id(_power_service_id)
    _water_local_id = _utilities.water_local_component_id(_water_service_id)
    if _power_branch_id.is_empty() or _water_local_id.is_empty():
        return false
    var refresh_power := Callable(self, "_on_power_changed")
    var refresh_water := Callable(self, "_on_water_changed")
    var refresh_appliance := Callable(self, "_on_appliances_changed")
    if not _utilities.power_changed.is_connected(refresh_power):
        _utilities.power_changed.connect(refresh_power)
    if not _utilities.water_changed.is_connected(refresh_water):
        _utilities.water_changed.connect(refresh_water)
    if not _utilities.appliances_changed.is_connected(refresh_appliance):
        _utilities.appliances_changed.connect(refresh_appliance)
    _build_ui()
    _refresh()
    return true

func _build_ui() -> void:
    if _status != null:
        return
    var panel := PanelContainer.new()
    panel.position = Vector2(344, 148)
    panel.size = Vector2(288, 100)
    add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 2)
    panel.add_child(box)
    _status = Label.new()
    _status.text = "DEV UTILITIES"
    _status.add_theme_font_size_override("font_size", 10)
    box.add_child(_status)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 3)
    box.add_child(row)
    var power_button := _make_button("LOCAL PWR", 82)
    power_button.pressed.connect(_toggle_power)
    row.add_child(power_button)
    var water_button := _make_button("LOCAL WATER", 88)
    water_button.pressed.connect(_toggle_water)
    row.add_child(water_button)
    _fridge_button = _make_button("FRIDGE", 70)
    _fridge_button.pressed.connect(_toggle_fridge)
    row.add_child(_fridge_button)

func _make_button(label: String, width: float) -> Button:
    var button := Button.new()
    button.text = label
    button.focus_mode = Control.FOCUS_NONE
    button.custom_minimum_size = Vector2(width, 28)
    button.add_theme_font_size_override("font_size", 9)
    return button

func _toggle_power() -> void:
    if _utilities == null or _power_branch_id.is_empty():
        return
    var next_state: StringName = UtilityRuntimeState.DAMAGED \
        if _utilities.power_service_available(_power_service_id) else UtilityRuntimeState.OPERATIONAL
    _utilities.set_power_component_state(_power_branch_id, next_state, &"dev_local_power_toggle")

func _toggle_water() -> void:
    if _utilities == null or _water_local_id.is_empty():
        return
    var next_state: StringName = UtilityRuntimeState.DAMAGED \
        if _utilities.water_service_available(_water_service_id) else UtilityRuntimeState.OPERATIONAL
    _utilities.set_water_component_state(_water_local_id, next_state, &"dev_local_water_toggle")

func _toggle_fridge() -> void:
    if _utilities == null or _refrigerator_id.is_empty():
        return
    var record: Dictionary = _utilities.appliance_record(_refrigerator_id)
    if record.is_empty():
        return
    _utilities.set_appliance_switched(
        _refrigerator_id,
        not bool(record.get("switched_on", false)),
        &"dev_refrigerator_toggle"
    )

func _refresh() -> void:
    if _status == null:
        return
    if _utilities == null or not _utilities.is_ready():
        _status.text = "DEV UTILITIES  not ready"
        if _fridge_button != null:
            _fridge_button.disabled = true
        return
    var power_text: String = "ON" if _utilities.power_service_available(_power_service_id) else "OFF"
    var water_text: String = "ON" if _utilities.water_service_available(_water_service_id) else "OFF"
    var fridge_text: String = "N/A"
    if not _refrigerator_id.is_empty():
        fridge_text = "COLD" if _utilities.cold_storage_available(_refrigerator_id) else "WARM"
    _status.text = "DEV UTIL  PWR %s  WATER %s  FRIDGE %s" % [power_text, water_text, fridge_text]
    if _fridge_button != null:
        _fridge_button.disabled = _refrigerator_id.is_empty()

func _on_power_changed(_revision: int, _reason: StringName) -> void:
    _refresh()

func _on_water_changed(_revision: int, _reason: StringName) -> void:
    _refresh()

func _on_appliances_changed(_revision: int, _reason: StringName) -> void:
    _refresh()
