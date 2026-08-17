extends RefCounted
class_name DoorDamageInterruptionService

const CLOSE_ACTION: StringName = &"door.close"

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
    if action != null and action.action_type == CLOSE_ACTION:
        _kernel.interrupt_action(action.serial, "damage")
