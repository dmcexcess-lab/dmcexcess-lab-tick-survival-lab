extends CanvasLayer
class_name VehiclePlayerControls

const PANEL_POSITION := Vector2(8, 252)
const PANEL_SIZE := Vector2(624, 112)

var _controller: VehiclePlayerController
var _service: VehicleActionService
var _state: VehicleState
var _actor_id: String = ""
var _status: Label

func _ready() -> void:
    layer = 34
    _build_ui()

func configure(controller: VehiclePlayerController, service: VehicleActionService, state: VehicleState, actor_id: String) -> bool:
    if controller == null or not controller.is_ready() or service == null or not service.is_ready() or state == null or actor_id.strip_edges().is_empty():
        return false
    _controller = controller
    _service = service
    _state = state
    _actor_id = actor_id.strip_edges()
    _build_ui()
    if not _controller.action_resolved.is_connected(_on_action_resolved):
        _controller.action_resolved.connect(_on_action_resolved)
    if not _service.mounted_changed.is_connected(_on_mounted_changed):
        _service.mounted_changed.connect(_on_mounted_changed)
    _refresh_status()
    return true

func _build_ui() -> void:
    if _status != null:
        return
    var panel := PanelContainer.new()
    panel.name = "VehiclePanel"
    panel.position = PANEL_POSITION
    panel.size = PANEL_SIZE
    add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 2)
    panel.add_child(box)
    _status = Label.new()
    _status.text = "VEHICLE — on foot"
    _status.add_theme_font_size_override("font_size", 10)
    box.add_child(_status)
    var row1 := HBoxContainer.new()
    box.add_child(row1)
    _button(row1, "ENTER", Callable(self, "_enter"))
    _button(row1, "EXIT", Callable(self, "_exit"))
    _button(row1, "START", Callable(self, "_start"))
    _button(row1, "HOTWIRE", Callable(self, "_hotwire"))
    _button(row1, "BRAKE", Callable(self, "_brake"))
    var row2 := HBoxContainer.new()
    box.add_child(row2)
    _button(row2, "REPAIR", Callable(self, "_repair"))
    _button(row2, "ADD RACK", Callable(self, "_modify"))
    _button(row2, "REFUEL", Callable(self, "_refuel"))
    var hint := Label.new()
    hint.text = "Mounted: movement keys drive; left/right steer 30°; back/brake needs 2 cells."
    hint.add_theme_font_size_override("font_size", 9)
    box.add_child(hint)

func _button(parent: Control, text: String, callback: Callable) -> void:
    var button := Button.new()
    button.text = text
    button.focus_mode = Control.FOCUS_NONE
    button.custom_minimum_size = Vector2(78, 24)
    button.add_theme_font_size_override("font_size", 9)
    button.pressed.connect(callback)
    parent.add_child(button)

func _enter() -> void: if _controller != null: _controller.request_enter()
func _exit() -> void: if _controller != null: _controller.request_exit()
func _start() -> void: if _controller != null: _controller.request_start()
func _hotwire() -> void: if _controller != null: _controller.request_hotwire()
func _repair() -> void: if _controller != null: _controller.request_repair()
func _modify() -> void: if _controller != null: _controller.request_modify()
func _refuel() -> void: if _controller != null: _controller.request_refuel()
func _brake() -> void: if _controller != null: _controller.request_brake()

func _on_action_resolved(_intent: StringName, success: bool, reason: String, _world_tick: int) -> void:
    if success:
        _refresh_status()
    else:
        _status.text = "VEHICLE — %s" % reason.replace("_", " ")

func _on_mounted_changed(actor_id: String, _vehicle_id: String, _mounted: bool) -> void:
    if actor_id == _actor_id:
        _refresh_status()

func _refresh_status() -> void:
    if _service == null or _state == null:
        return
    var vehicle_id := _service.vehicle_for_driver(_actor_id)
    if vehicle_id.is_empty():
        _status.text = "VEHICLE — on foot; approach a vehicle and ENTER"
        return
    var rec := _state.record(vehicle_id)
    _status.text = "VEHICLE — %s | fuel %d | heading %d° | %s" % [
        String(rec.get("kind", &"vehicle")).to_upper(),
        int(rec.get("fuel", 0)),
        int(rec.get("heading", 0)) * 30,
        "moving" if bool(rec.get("moving", false)) else "stopped",
    ]
