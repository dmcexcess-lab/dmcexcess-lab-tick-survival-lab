extends CanvasLayer
class_name VehiclePlayerControls

const PANEL_POSITION := Vector2(8, 252)
const PANEL_SIZE := Vector2(624, 158)

var _controller: VehiclePlayerController
var _service: VehicleActionService
var _state: VehicleState
var _cargo: VehicleCargoService
var _inventory: InventoryContainmentState
var _actor_id: String = ""
var _panel: PanelContainer = null
var _status: Label
var _actor_items: OptionButton
var _cargo_items: OptionButton
var _cargo_status: Label
var _movement_controls: PlayerMovementControls = null

func _ready() -> void:
    layer = 34
    _build_ui()

func configure(
    controller: VehiclePlayerController,
    service: VehicleActionService,
    state: VehicleState,
    cargo: VehicleCargoService,
    inventory: InventoryContainmentState,
    actor_id: String
) -> bool:
    if controller == null or not controller.is_ready() or service == null or not service.is_ready() \
        or state == null or cargo == null or not cargo.is_ready() or inventory == null \
        or actor_id.strip_edges().is_empty():
        return false
    _controller = controller
    _service = service
    _state = state
    _cargo = cargo
    _inventory = inventory
    _actor_id = actor_id.strip_edges()
    _build_ui()
    var parent_node := get_parent()
    if parent_node != null:
        _movement_controls = parent_node.get_node_or_null("PlayerControls") as PlayerMovementControls
    if _movement_controls != null and not _movement_controls.enter_vehicle_requested.is_connected(_enter):
        _movement_controls.enter_vehicle_requested.connect(_enter)
    if not _controller.action_resolved.is_connected(_on_action_resolved):
        _controller.action_resolved.connect(_on_action_resolved)
    if not _service.mounted_changed.is_connected(_on_mounted_changed):
        _service.mounted_changed.connect(_on_mounted_changed)
    if not _inventory.item_containment_changed.is_connected(_on_item_containment_changed):
        _inventory.item_containment_changed.connect(_on_item_containment_changed)
    _refresh_all()
    return true

func _build_ui() -> void:
    if _status != null:
        return
    _panel = PanelContainer.new()
    _panel.name = "VehiclePanel"
    _panel.position = PANEL_POSITION
    _panel.size = PANEL_SIZE
    _panel.visible = false
    add_child(_panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 2)
    _panel.add_child(box)
    _status = Label.new()
    _status.text = "VEHICLE"
    _status.add_theme_font_size_override("font_size", 10)
    box.add_child(_status)

    var row1 := HBoxContainer.new()
    box.add_child(row1)
    _button(row1, "EXIT", Callable(self, "_exit"))
    _button(row1, "START", Callable(self, "_start"))
    _button(row1, "HOTWIRE", Callable(self, "_hotwire"))
    _button(row1, "BRAKE", Callable(self, "_brake"))
    _button(row1, "REVERSE", Callable(self, "_reverse"))

    var row2 := HBoxContainer.new()
    box.add_child(row2)
    _button(row2, "REPAIR", Callable(self, "_repair"))
    _button(row2, "ADD RACK", Callable(self, "_modify"))
    _button(row2, "REFUEL", Callable(self, "_refuel"))

    var cargo_row := HBoxContainer.new()
    cargo_row.add_theme_constant_override("separation", 4)
    box.add_child(cargo_row)
    _actor_items = OptionButton.new()
    _actor_items.name = "ActorCargoSource"
    _actor_items.custom_minimum_size = Vector2(188, 24)
    _actor_items.add_theme_font_size_override("font_size", 9)
    cargo_row.add_child(_actor_items)
    _button(cargo_row, "STORE →", Callable(self, "_store_selected"))
    _cargo_items = OptionButton.new()
    _cargo_items.name = "VehicleCargoSource"
    _cargo_items.custom_minimum_size = Vector2(188, 24)
    _cargo_items.add_theme_font_size_override("font_size", 9)
    cargo_row.add_child(_cargo_items)
    _button(cargo_row, "← TAKE", Callable(self, "_take_selected"))

    _cargo_status = Label.new()
    _cargo_status.text = "CARGO"
    _cargo_status.add_theme_font_size_override("font_size", 9)
    box.add_child(_cargo_status)

    var hint := Label.new()
    hint.text = "Mounted: forward drives; back reverses 1 cell; left/right turn 90° across 3 squares; BRAKE stops over 2 cells."
    hint.add_theme_font_size_override("font_size", 9)
    box.add_child(hint)

func _button(parent: Control, text: String, callback: Callable) -> void:
    var button := Button.new()
    button.name = "%sButton" % text.to_pascal_case().replace(" ", "")
    button.text = text
    button.focus_mode = Control.FOCUS_NONE
    button.custom_minimum_size = Vector2(78, 24)
    button.add_theme_font_size_override("font_size", 9)
    button.pressed.connect(callback)
    parent.add_child(button)

func _enter() -> void:
    if _controller != null:
        _controller.request_enter()

func _exit() -> void:
    if _controller != null:
        _controller.request_exit()

func _start() -> void:
    if _controller != null:
        _controller.request_start()

func _hotwire() -> void:
    if _controller != null:
        _controller.request_hotwire()

func _repair() -> void:
    if _controller != null:
        _controller.request_repair()

func _modify() -> void:
    if _controller != null:
        _controller.request_modify()

func _refuel() -> void:
    if _controller != null:
        _controller.request_refuel()

func _brake() -> void:
    if _controller != null:
        _controller.request_brake()

func _reverse() -> void:
    if _controller != null:
        _controller.request_reverse()

func _store_selected() -> void:
    if _cargo == null or _actor_items == null or _actor_items.item_count < 1:
        return
    var vehicle_id := _service.vehicle_for_driver(_actor_id)
    var item_id := _selected_metadata(_actor_items)
    if vehicle_id.is_empty() or item_id.is_empty():
        return
    if not _cargo.store_from_actor(_actor_id, vehicle_id, item_id):
        _cargo_status.text = "CARGO — cannot store selected item"
        return
    _refresh_cargo()

func _take_selected() -> void:
    if _cargo == null or _cargo_items == null or _cargo_items.item_count < 1:
        return
    var vehicle_id := _service.vehicle_for_driver(_actor_id)
    var item_id := _selected_metadata(_cargo_items)
    if vehicle_id.is_empty() or item_id.is_empty():
        return
    if not _cargo.take_to_actor(_actor_id, vehicle_id, item_id):
        _cargo_status.text = "CARGO — cannot take selected item"
        return
    _refresh_cargo()

func _on_action_resolved(_intent: StringName, success: bool, reason: String, _world_tick: int) -> void:
    if success:
        _refresh_all()
    elif _panel != null and _panel.visible:
        _status.text = "VEHICLE — %s" % reason.replace("_", " ")

func _on_mounted_changed(actor_id: String, _vehicle_id: String, mounted: bool) -> void:
    if actor_id != _actor_id:
        return
    if _movement_controls != null:
        _movement_controls.set_on_foot_actions_visible(not mounted)
    _refresh_all()

func _on_item_containment_changed(_item_id: String, previous_container_id: String, new_container_id: String) -> void:
    if _service == null:
        return
    var vehicle_id := _service.vehicle_for_driver(_actor_id)
    if previous_container_id == _actor_id or new_container_id == _actor_id \
        or (not vehicle_id.is_empty() and (previous_container_id == vehicle_id or new_container_id == vehicle_id)):
        _refresh_cargo()

func _refresh_all() -> void:
    _refresh_status()
    _refresh_cargo()

func _refresh_status() -> void:
    if _service == null or _state == null or _panel == null:
        return
    var vehicle_id := _service.vehicle_for_driver(_actor_id)
    var mounted := not vehicle_id.is_empty()
    _panel.visible = mounted
    if _movement_controls != null:
        _movement_controls.set_on_foot_actions_visible(not mounted)
    if not mounted:
        return
    var rec := _state.record(vehicle_id)
    _status.text = "VEHICLE — %s | fuel %d | heading %d° | %s" % [
        String(rec.get("kind", &"vehicle")).to_upper(),
        int(rec.get("fuel", 0)),
        int(rec.get("heading", 0)) * 30,
        "moving" if bool(rec.get("moving", false)) else "stopped",
    ]

func _refresh_cargo() -> void:
    if _actor_items == null or _cargo_items == null or _cargo_status == null:
        return
    _actor_items.clear()
    _cargo_items.clear()
    if _service == null or _cargo == null or _inventory == null:
        _cargo_status.text = "CARGO — unavailable"
        return
    var vehicle_id := _service.vehicle_for_driver(_actor_id)
    if vehicle_id.is_empty():
        _cargo_status.text = "CARGO"
        return
    for item_id: String in _inventory.direct_contents(_actor_id):
        _add_item(_actor_items, item_id)
    for item_id: String in _cargo.cargo_item_ids(vehicle_id):
        _add_item(_cargo_items, item_id)
    _cargo_status.text = "CARGO — %.1f / %.1f kg" % [
        float(_cargo.used_grams(vehicle_id)) / 1000.0,
        float(_cargo.capacity_grams(vehicle_id)) / 1000.0,
    ]

func _add_item(menu: OptionButton, item_id: String) -> void:
    var index := menu.item_count
    menu.add_item(_display_item_id(item_id))
    menu.set_item_metadata(index, item_id)

static func _selected_metadata(menu: OptionButton) -> String:
    if menu == null or menu.item_count < 1 or menu.selected < 0:
        return ""
    return String(menu.get_item_metadata(menu.selected))

static func _display_item_id(item_id: String) -> String:
    var text := item_id
    var colon_index := text.rfind(":")
    if colon_index >= 0 and colon_index + 1 < text.length():
        text = text.substr(colon_index + 1)
    var dot_index := text.rfind(".")
    if dot_index >= 0 and dot_index + 1 < text.length():
        text = text.substr(dot_index + 1)
    return text.replace("_", " ")
