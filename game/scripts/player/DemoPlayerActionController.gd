extends Node
class_name DemoPlayerActionController

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Stance = preload("res://scripts/simulation/actors/locomotion/ActorStance.gd")

## Thin semantic-intent -> existing canonical action-service coordinator.
## Destination, collision, facing, stance timing/mutation, and duration remain owned by existing systems.

signal action_resolved(intent: StringName, success: bool, reason: String, world_tick: int)
signal action_busy_changed(busy: bool)

const INPUT_COOLDOWN_MSEC: int = 120

var _movement: MovementActionService = null
var _kernel: TickKernel = null
var _actor_id: String = ""
var _stance_actions: ActorStanceActionService = null
var _locomotion: ActorLocomotionState = null
var _outcomes: Dictionary = {}
var _active_intent: StringName = &""
var _active_serial: int = 0
var _busy: bool = false
var _accept_input_after_msec: int = 0

func _init(
    movement_service: MovementActionService = null,
    tick_kernel: TickKernel = null,
    actor_id: String = "",
    stance_action_service: ActorStanceActionService = null,
    locomotion_state: ActorLocomotionState = null
) -> void:
    _movement = movement_service
    _kernel = tick_kernel
    _actor_id = actor_id.strip_edges()
    _stance_actions = stance_action_service
    _locomotion = locomotion_state
    if _movement != null:
        if not _movement.movement_committed.is_connected(_on_movement_committed):
            _movement.movement_committed.connect(_on_movement_committed)
        if not _movement.movement_failed.is_connected(_on_movement_failed):
            _movement.movement_failed.connect(_on_movement_failed)
    if _stance_actions != null:
        if not _stance_actions.stance_committed.is_connected(_on_stance_committed):
            _stance_actions.stance_committed.connect(_on_stance_committed)
        if not _stance_actions.stance_failed.is_connected(_on_stance_failed):
            _stance_actions.stance_failed.connect(_on_stance_failed)
    set_process(false)

func is_ready() -> bool:
    return _movement != null and _kernel != null and not _actor_id.is_empty()

func stance_ready() -> bool:
    return _stance_actions != null \
        and _stance_actions.is_ready() \
        and _locomotion != null \
        and _locomotion.has_actor(_actor_id)

func is_busy() -> bool:
    return _busy

func submit_intent(intent: StringName) -> void:
    if not is_ready() or not Intents.is_valid(intent):
        action_resolved.emit(intent, false, "input_not_ready", _current_tick())
        return
    if _kernel.is_hard_paused():
        action_resolved.emit(intent, false, "hard_paused", _kernel.world_tick())
        return
    # Browser and touch events can accumulate while a heavy action frame is being
    # resolved. Never turn that stale backlog into future movement.
    if _busy or Time.get_ticks_msec() < _accept_input_after_msec:
        return

    if intent == Intents.STANCE_TOGGLE:
        _submit_stance_toggle()
        return
    _submit_movement(intent)

func _submit_movement(intent: StringName) -> void:
    var result: MovementActionResult = null
    match intent:
        Intents.FORWARD:
            result = _movement.request_step_forward(_actor_id)
        Intents.BACKWARD:
            result = _movement.request_step_backward(_actor_id)
        Intents.RUN_FORWARD:
            result = _movement.request_run_forward(_actor_id)
        Intents.TURN_LEFT:
            result = _movement.request_turn_left(_actor_id)
        Intents.TURN_RIGHT:
            result = _movement.request_turn_right(_actor_id)

    if result == null or not result.is_accepted():
        var reason: String = "movement_rejected" if result == null else result.reason
        action_resolved.emit(intent, false, reason, _kernel.world_tick())
        return
    _resolve_accepted_action(intent, result.action_serial)

func _submit_stance_toggle() -> void:
    if not stance_ready():
        action_resolved.emit(Intents.STANCE_TOGGLE, false, "stance_not_ready", _kernel.world_tick())
        return
    var current: StringName = _locomotion.stance(_actor_id)
    var result: ActorStanceActionResult = null
    if current == Stance.STANDING:
        result = _stance_actions.request_crouch(_actor_id)
    elif current == Stance.CROUCHED:
        result = _stance_actions.request_stand(_actor_id)
    else:
        action_resolved.emit(Intents.STANCE_TOGGLE, false, "stance_unknown", _kernel.world_tick())
        return

    if result == null or not result.is_accepted():
        var reason: String = "stance_rejected" if result == null else result.reason
        action_resolved.emit(Intents.STANCE_TOGGLE, false, reason, _kernel.world_tick())
        return
    _resolve_accepted_action(Intents.STANCE_TOGGLE, result.action_serial)

func _resolve_accepted_action(intent: StringName, serial: int) -> void:
    _outcomes.erase(serial)
    if is_inside_tree():
        _active_intent = intent
        _active_serial = serial
        _set_busy(true)
        set_process(true)
        return

    # Focused headless contracts instantiate the controller outside a SceneTree.
    # Preserve their deterministic synchronous harness without using that blocking
    # path in the playable runtime.
    _kernel.run_until_stop()
    _finish_resolved_action(intent, serial)

func _process(_delta: float) -> void:
    if not _busy or _active_serial <= 0:
        set_process(false)
        return

    # One due-tick batch per rendered frame. This guarantees the browser a chance
    # to present current state and drain/drop input between simulation batches.
    _kernel.run_next_batch()
    if _outcomes.has(_active_serial):
        var intent: StringName = _active_intent
        var serial: int = _active_serial
        _active_intent = &""
        _active_serial = 0
        set_process(false)
        _finish_resolved_action(intent, serial)
        _accept_input_after_msec = Time.get_ticks_msec() + INPUT_COOLDOWN_MSEC
        _set_busy(false)
        return
    if _kernel.is_hard_paused() or _kernel.is_decision_paused():
        var stalled_intent: StringName = _active_intent
        var stalled_serial: int = _active_serial
        _active_intent = &""
        _active_serial = 0
        set_process(false)
        _outcomes.erase(stalled_serial)
        action_resolved.emit(stalled_intent, false, "action_unresolved", _kernel.world_tick())
        _accept_input_after_msec = Time.get_ticks_msec() + INPUT_COOLDOWN_MSEC
        _set_busy(false)

func _finish_resolved_action(intent: StringName, serial: int) -> void:
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

func _set_busy(value: bool) -> void:
    if value == _busy:
        return
    _busy = value
    action_busy_changed.emit(_busy)

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

func _on_stance_committed(
    actor_id: String,
    action_serial: int,
    _previous_stance: StringName,
    _new_stance: StringName,
    _version: int
) -> void:
    if actor_id != _actor_id:
        return
    _outcomes[action_serial] = {"success": true, "reason": ""}

func _on_stance_failed(
    actor_id: String,
    action_serial: int,
    _target_stance: StringName,
    reason: String
) -> void:
    if actor_id != _actor_id:
        return
    _outcomes[action_serial] = {"success": false, "reason": reason}

func _current_tick() -> int:
    return 0 if _kernel == null else _kernel.world_tick()
