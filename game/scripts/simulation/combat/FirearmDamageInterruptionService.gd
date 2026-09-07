extends RefCounted
class_name FirearmDamageInterruptionService

var _health: ActorHealthState = null
var _kernel: TickKernel = null

func _init(health: ActorHealthState = null, kernel: TickKernel = null) -> void:
    _health = health
    _kernel = kernel
    if _health != null: _health.damage_applied.connect(_on_damage_applied)

func is_ready() -> bool:
    return _health != null and _kernel != null

func _on_damage_applied(actor_id: String, amount: int, _previous_hp: int, _hp: int, _version: int) -> void:
    if amount <= 0 or not is_ready(): return
    var action := _kernel.active_action_for_actor(actor_id)
    if action == null or action.action_type not in FirearmActionService.ACTION_IDS: return
    _kernel.interrupt_action(action.serial, "damage_before_firearm_action_complete")
