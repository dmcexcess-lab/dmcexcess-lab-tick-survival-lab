extends RefCounted
class_name DemoPlayerActionController

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")

## Thin semantic-intent -> canonical Movement/WHEN coordinator.
## Destination, collision, facing, and duration remain owned by existing systems.

signal action_resolved(intent: StringName, success: bool, reason: String, world_tick: int)

var _movement: MovementActionService = null
var _kernel: TickKernel = null
var _actor_id: String = ""
var _outcomes: Dictionary = {}

func _init(
    movement_service: MovementActionService = null,
    tick_kernel: TickKernel = null,
    actor_id: String = ""
) -> void:
    _movement = movement_service
    _kernel = tick_kernel
    _actor_id = actor_id.strip_edges()
    if _movement != null:
        if not _movement.movement_committed.is_connected(_on_movement_committed):
            _movement.movement_committed.connect(_on_movement_committed)
        if not _movement.movement_failed.is_connected(_on_movement_failed):
            _movement.movement_failed.connect(_on_movement_failed)

func is_ready() -> bool:
    return _movement != null and _kernel != null and not _actor_id.is_empty()

func submit_intent(intent: StringName) -> void:
    if not is_ready() or not Intents.is_valid(intent):
        action_resolved.emit(intent, false, "input_not_ready", _current_tick())
        return
    if _kernel.is_hard_paused():
        action_resolved.emit(intent, false, "hard_paused", _kernel.world_tick())
        return

    var result: MovementActionResult = null
    match intent:
        Intents.FORWARD:
            result = _movement.request_step_forward(_actor_id)
        Intents.BACKWARD:
            result = _movement.request_step_backward(_actor_id)
        Intents.TURN_LEFT:
            result = _movement.request_turn_left(_actor_id)
        Intents.TURN_RIGHT:
            result = _movement.request_turn_right(_actor_id)

    if result == null or not result.is_accepted():
        var reason: String = "movement_rejected" if result == null else result.reason
        action_resolved.emit(intent, false, reason, _kernel.world_tick())
        return

    var serial: int = result.action_serial
    _outcomes.erase(serial)
    _kernel.run_until_stop()

    var outcome: Dictionary = _outcomes.get(serial, {})
    if outcome.is_empty():
        action_resolved.emit(intent, false, "action_unresolved", _kernel.world_tick())
        return
    action_resolved.emit(
        intent,
        bool(outcome.get("success", false)),
        String(outcome.get("reason", "")),
        _kernel.world_tick()
    )
    _outcomes.erase(serial)

func _on_movement_committed(
    actor_id: String,
    action_serial: int,
    _action_type: StringName,
    _target_anchor: Vector2i,
    _target_facing: int
) -> void:
    if actor_id != _actor_id:
        return
    _outcomes[action_serial] = {"success": true, "reason": ""}

func _on_movement_failed(
    actor_id: String,
    action_serial: int,
    _action_type: StringName,
    reason: String
) -> void:
    if actor_id != _actor_id:
        return
    _outcomes[action_serial] = {"success": false, "reason": reason}

func _current_tick() -> int:
    return 0 if _kernel == null else _kernel.world_tick()
