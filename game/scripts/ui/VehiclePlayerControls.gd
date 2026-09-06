extends CanvasLayer
class_name VehiclePlayerControls

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")

const VIEW_SIZE := Vector2(640, 844)
const BUTTON_SIZE := Vector2(132, 36)
const CARGO_BUTTON_SIZE := Vector2(76, 28)

var _controller: VehiclePlayerController
var _service: VehicleActionService
var _state: VehicleState
var _cargo: VehicleCargoService
var _inventory: InventoryContainmentState
var _actor_id: String = ""
var _surface: Control = null
var _status: Label
var _actor_items: OptionButton
var _cargo_items: OptionButton
var _cargo_status: Label
var _movement_controls: PlayerMovementControls = null

func _ready() -> void:
    layer = 34
    visible = false
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
        _movement_controls = parent_node.get_node_or_null("Controls") as PlayerMovementControls
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
    if _surface != null:
        return
    _surface = Control.new()
    _surface.name = "VehicleControlSurface"
    _surface.position = Vector2.ZERO
    _surface.size = VIEW_SIZE
    _surface.visible = false
    _surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_surface)

    _status = Label.new()
    _status.name = "VehicleStatus"
    _status.position = Vector2(70, 604)
    _status.size = Vector2(500, 16)
    _status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _status.add_theme_font_size_override("font_size", 10)
    _status.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _surface.add_child(_status)

    _cargo_status = Label.new()
    _cargo_status.name = "CargoStatus"
    _cargo_status.position = Vector2(70, 620)
    _cargo_status.size = Vector2(500, 16)
    _cargo_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _cargo_status.add_theme_font_size_override("font_size", 9)
    _cargo_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _surface.add_child(_cargo_status)

    _button_at("TURN L", "TurnLButton", Vector2(82, 638), Callable(self, "_turn_left"))
    _button_at("FORWARD", "ForwardButton", Vector2(255, 638), Callable(self, "_forward"))
    _button_at("TURN R", "TurnRButton", Vector2(426, 638), Callable(self, "_turn_right"))

    _button_at("BRAKE", "BrakeButton", Vector2(82, 680), Callable(self, "_brake"))
    _button_at("REVERSE", "ReverseButton", Vector2(255, 680), Callable(self, "_reverse"))
    _button_at("BACK", "BackButton", Vector2(426, 680), Callable(self, "_backward"))

    _button_at("EXIT", "ExitButton", Vector2(82, 722), Callable(self, "_exit"))
    _button_at("START", "StartButton", Vector2(255, 722), Callable(self, "_start"))
    _button_at("HOTWIRE", "HotwireButton", Vector2(426, 722), Callable(self, "_hotwire"))

    _button_at("REPAIR", "RepairButton", Vector2(82, 764), Callable(self, "_repair"))
    _button_at("ADD RACK", "AddRackButton", Vector2(255, 764), Callable(self, "_modify"))
    _button_at("REFUEL", "RefuelButton", Vector2(426, 764), Callable(self, "_refuel"))

    _actor_items = OptionButton.new()
    _actor_items.name = "ActorCargoSource"
    _actor_items.position = Vector2(34, 806)
    _actor_items.size = Vector2(168, 28)
    _actor_items.add_theme_font_size_override("font_size", 9)
    _surface.add_child(_actor_items)

    var store_button := Button.new()
    store_button.name = "StoreCargoButton"
    store_button.text = "STORE →"
    store_button.position = Vector2(206, 806)
    store_button.size = CARGO_BUTTON_SIZE
    store_button.focus_mode = Control.FOCUS_NONE
    store_button.add_theme_font_size_override("font_size", 9)
    store_button.pressed.connect(_store_selected)
    _surface.add_child(store_button)

    _cargo_items = OptionButton.new()
    _cargo_items.name = "VehicleCargoSource"
    _cargo_items.position = Vector2(286, 806)
    _cargo_items.size = Vector2(168, 28)
    _cargo_items.add_theme_font_size_override("font_size", 9)
    _surface.add_child(_cargo_items)

    var take_button := Button.new()
    take_button.name = "TakeCargoButton"
    take_button.text = "← TAKE"
    take_button.position = Vector2(458, 806)
    take_button.size = CARGO_BUTTON_SIZE
    take_button.focus_mode = Control.FOCUS_NONE
    take_button.add_theme_font_size_override("font_size", 9)
    take_button.pressed.connect(_take_selected)
    _surface.add_child(take_button)

func _button_at(text: String, node_name: String, position_value: Vector2, callback: Callable) -> Button:
    var button := Button.new()
    button.name = node_name
    button.text = text
    button.position = position_value
    button.size = BUTTON_SIZE
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 11)
    button.pressed.connect(callback)
    _surface.add_child(button)
    return button

func _forward() -> void:
    _submit_drive_intent(Intents.FORWARD)

func _turn_left() -> void:
    _submit_drive_intent(Intents.TURN_LEFT)

func _turn_right() -> void:
    _submit_drive_intent(Intents.TURN_RIGHT)

func _backward() -> void:
    _submit_drive_intent(Intents.BACKWARD)

func _submit_drive_intent(intent: StringName) -> void:
    if _controller != null:
        _controller.submit_intent(intent)

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
    elif _surface != null and _surface.visible:
        _status.text = "VEHICLE — %s" % reason.replace("_", " ")

func _on_mounted_changed(actor_id: String, _vehicle_id: String, mounted: bool) -> void:
    if actor_id != _actor_id:
        return
    _set_mounted_presentation(mounted)
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
    if _service == null or _state == null or _surface == null:
        return
    var vehicle_id := _service.vehicle_for_driver(_actor_id)
    var mounted := not vehicle_id.is_empty()
    _set_mounted_presentation(mounted)
    if not mounted:
        return
    var rec := _state.record(vehicle_id)
    _status.text = "VEHICLE — %s | fuel %d | heading %d° | %s" % [
        String(rec.get("kind", &"vehicle")).to_upper(),
        int(rec.get("fuel", 0)),
        int(rec.get("heading", 0)) * 30,
        "moving" if bool(rec.get("moving", false)) else "stopped",
    ]

func _set_mounted_presentation(mounted: bool) -> void:
    visible = mounted
    if _surface != null:
        _surface.visible = mounted
    if _movement_controls != null:
        _movement_controls.set_control_surface_visible(not mounted)

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
