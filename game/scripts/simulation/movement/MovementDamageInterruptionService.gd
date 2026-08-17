extends RefCounted
class_name MovementDamageInterruptionService

## Stateless Health -> WHEN coordination for damage-interruptible movement.
## Health owns damage truth; WHEN owns interruption semantics; Movement owns action vocabulary.

const STEP_FORWARD: StringName = &"movement.step_forward"
const STEP_BACKWARD: StringName = &"movement.step_backward"
const RUN_FORWARD: StringName = &"movement.run_forward"
const TURN_LEFT: StringName = &"movement.turn_left"
const TURN_RIGHT: StringName = &"movement.turn_right"

var _health: ActorHealthState = null
var _kernel: TickKernel = null

func _init(health_state: ActorHealthState = null, tick_kernel: TickKernel = null) -> void:
    _health = health_state
    _kernel = tick_kernel
    if _health != null and not _health.damage_applied.is_connected(_on_damage_applied):
        _health.damage_applied.connect(_on_damage_applied)

func is_ready() -> bool:
    return _health != null and _kernel != null

func _on_damage_applied(
    actor_id: String,
    _amount: int,
    _previous_hp: int,
    _current_hp: int,
    _version: int
) -> void:
    if not is_ready():
        return
    var action: TimedAction = _kernel.active_action_for_actor(actor_id)
    if action == null or not _is_movement_action(action.action_type):
        return
    _kernel.interrupt_action(action.serial, "damage")

static func _is_movement_action(action_type: StringName) -> bool:
    return (
        action_type == STEP_FORWARD
        or action_type == STEP_BACKWARD
        or action_type == RUN_FORWARD
        or action_type == TURN_LEFT
        or action_type == TURN_RIGHT
    )
