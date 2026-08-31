extends ActorMobilityModifierProvider
class_name ActorConditionMobilityModifierProvider

## System 34 -> locomotion adapter. Input remains immediate; condition changes the
## authoritative action duration scale. Walking is never blocked by zero stamina.

var _condition: ActorConditionService = null
var _modifiers: ActorConditionModifierQuery = null

func _init(
    condition_service: ActorConditionService = null,
    modifier_query: ActorConditionModifierQuery = null
) -> void:
    super._init("system34.condition")
    _condition = condition_service
    _modifiers = modifier_query

func is_valid() -> bool:
    return super.is_valid() and _condition != null and _condition.is_ready() and _modifiers != null and _modifiers.is_ready()

func evaluate(actor_id: String, action_type: StringName) -> Dictionary:
    if not is_valid() or not _condition.has_actor(actor_id):
        return decision(Status.UNKNOWN, SCALE_ONE, "condition_unclassified")
    var action_text: String = String(action_type)
    if not action_text.begins_with("movement.") and not action_text.begins_with("stance."):
        return decision(Status.ALLOWED, SCALE_ONE)
    if action_text.contains("run") and not _condition.can_start_run(actor_id):
        return decision(Status.BLOCKED, SCALE_ONE, "stamina_exhausted")
    var speed_bp: int = _modifiers.speed_multiplier_bp(actor_id)
    if speed_bp <= 0:
        return decision(Status.UNKNOWN, SCALE_ONE, "condition_speed_invalid")
    var duration_scale_bp: int = maxi(1, int(ceili(float(SCALE_ONE * SCALE_ONE) / float(speed_bp))))
    return decision(Status.ALLOWED, duration_scale_bp)
