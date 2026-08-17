extends "res://scripts/simulation/actors/locomotion/ActorMobilityModifierProvider.gd"
class_name ActorCarryMobilityModifierProvider

## Read-only 13E -> 03 seam. Recovers golden Tick encumbrance timing pressure.

const STEP_FORWARD: StringName = &"movement.step_forward"
const STEP_BACKWARD: StringName = &"movement.step_backward"
const TURN_LEFT: StringName = &"movement.turn_left"
const TURN_RIGHT: StringName = &"movement.turn_right"
const RUN_FORWARD: StringName = &"movement.run_forward"
const CROUCH_ACTION: StringName = &"actor.stance.crouch"
const STAND_ACTION: StringName = &"actor.stance.stand"

var _carry_query: ActorCarryQuery = null

func _init(carry_query: ActorCarryQuery = null) -> void:
    super("actor_carry")
    _carry_query = carry_query

func evaluate(actor_id: String, action_type: StringName) -> Dictionary:
    if not _is_locomotion_action(action_type):
        return decision(Status.ALLOWED, 0, "")
    if _carry_query == null:
        return decision(Status.UNKNOWN, 0, "carry_query_unconfigured")
    var carry: Dictionary = _carry_query.query(actor_id)
    var carry_status: int = int(carry.get("status", -1))
    if carry_status == ActorCarryQuery.Status.UNKNOWN:
        return decision(Status.UNKNOWN, 0, String(carry.get("reason", "carry_unknown")))
    if carry_status != ActorCarryQuery.Status.KNOWN:
        return decision(Status.UNKNOWN, 0, String(carry.get("reason", "carry_invalid")))
    var load_ratio_bp: int = maxi(0, int(carry.get("load_ratio_bp", 0)))
    var adjustment_bp: int = int((load_ratio_bp * 75) / 100)
    return decision(Status.ALLOWED, adjustment_bp, "")

static func _is_locomotion_action(action_type: StringName) -> bool:
    return (
        action_type == STEP_FORWARD
        or action_type == STEP_BACKWARD
        or action_type == TURN_LEFT
        or action_type == TURN_RIGHT
        or action_type == RUN_FORWARD
        or action_type == CROUCH_ACTION
        or action_type == STAND_ACTION
    )
