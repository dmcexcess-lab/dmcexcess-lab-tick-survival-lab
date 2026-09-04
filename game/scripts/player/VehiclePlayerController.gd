extends Node
class_name VehiclePlayerController

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")

signal action_resolved(intent, success, reason, world_tick)
signal action_busy_changed(busy)

var _service: VehicleActionService
var _kernel: TickKernel
var _actor_id: String
var _busy: bool = false
var _active_serial: int = 0
var _active_intent: StringName = &""
var _outcomes: Dictionary = {}

func _init(service: VehicleActionService, kernel: TickKernel, actor_id: String) -> void:
    _service = service
    _kernel = kernel
    _actor_id = actor_id
    if _service != null:
        _service.action_completed.connect(_on_action_completed)
        _service.action_failed.connect(_on_action_failed)
    set_process(false)

func is_ready() -> bool:
    return _service != null and _service.is_ready() and _kernel != null and not _actor_id.is_empty()

func is_mounted() -> bool:
    return is_ready() and _service.is_mounted(_actor_id)

func is_busy() -> bool:
    return _busy

func submit_intent(intent: StringName) -> void:
    if not is_ready() or not is_mounted() or _busy or not _kernel.is_decision_paused():
        return
    var result: Dictionary = {}
    match intent:
        Intents.FORWARD, Intents.RUN_FORWARD:
            result = _service.request_forward(_actor_id)
        Intents.BACKWARD:
            result = _service.request_brake(_actor_id)
        Intents.TURN_LEFT:
            result = _service.request_turn_left(_actor_id)
        Intents.TURN_RIGHT:
            result = _service.request_turn_right(_actor_id)
        _:
            return
    _resolve_requested(intent, result)

func request_enter() -> void:
    _resolve_requested(&"vehicle.enter", _service.request_enter_nearby(_actor_id))

func request_exit() -> void:
    _resolve_requested(&"vehicle.exit", _service.request_exit(_actor_id))

func request_start() -> void:
    _resolve_requested(&"vehicle.start", _service.request_start(_actor_id))

func request_hotwire() -> void:
    _resolve_requested(&"vehicle.hotwire", _service.request_hotwire(_actor_id))

func request_repair() -> void:
    _resolve_requested(&"vehicle.repair", _service.request_repair(_actor_id))

func request_modify() -> void:
    _resolve_requested(&"vehicle.modify", _service.request_modify(_actor_id))

func request_refuel() -> void:
    _resolve_requested(&"vehicle.refuel", _service.request_refuel(_actor_id))

func request_brake() -> void:
    _resolve_requested(&"vehicle.brake", _service.request_brake(_actor_id))

func _resolve_requested(intent: StringName, result: Dictionary) -> void:
    if not is_ready() or _busy:
        return
    if not bool(result.get("accepted", false)):
        action_resolved.emit(intent, false, String(result.get("reason", "vehicle_rejected")), _kernel.world_tick())
        return
    if bool(result.get("instant", false)):
        action_resolved.emit(intent, true, "", _kernel.world_tick())
        return
    var serial := int(result.get("action_serial", 0))
    if serial <= 0:
        action_resolved.emit(intent, false, "vehicle_action_invalid", _kernel.world_tick())
        return
    _active_serial = serial
    _active_intent = intent
    _set_busy(true)
    if is_inside_tree():
        set_process(true)
    else:
        _kernel.run_until_stop()
        _finish_if_ready()

func _process(_delta: float) -> void:
    if not _busy:
        set_process(false)
        return
    _kernel.run_next_batch()
    _finish_if_ready()

func _finish_if_ready() -> void:
    if not _busy or not _outcomes.has(_active_serial) or not _kernel.is_decision_paused():
        return
    var outcome: Dictionary = _outcomes.get(_active_serial, {})
    action_resolved.emit(_active_intent, bool(outcome.get("success", false)), String(outcome.get("reason", "")), _kernel.world_tick())
    _outcomes.erase(_active_serial)
    _active_serial = 0
    _active_intent = &""
    set_process(false)
    _set_busy(false)

func _set_busy(value: bool) -> void:
    if _busy == value:
        return
    _busy = value
    action_busy_changed.emit(value)

func _on_action_completed(actor_id: String, _vehicle_id: String, serial: int, _action_type: StringName, reason: String) -> void:
    if actor_id == _actor_id:
        _outcomes[serial] = {"success": true, "reason": reason}

func _on_action_failed(actor_id: String, _vehicle_id: String, serial: int, _action_type: StringName, reason: String) -> void:
    if actor_id == _actor_id:
        _outcomes[serial] = {"success": false, "reason": reason}
