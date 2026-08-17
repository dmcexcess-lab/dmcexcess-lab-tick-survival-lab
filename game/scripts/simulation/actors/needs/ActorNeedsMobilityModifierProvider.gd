extends "res://scripts/simulation/actors/locomotion/ActorMobilityModifierProvider.gd"
class_name ActorNeedsMobilityModifierProvider

## Read-only 13B -> 03 seam. Recovers golden Tick fatigue timing pressure.

const STEP_FORWARD: StringName = &"movement.step_forward"
const STEP_BACKWARD: StringName = &"movement.step_backward"
const TURN_LEFT: StringName = &"movement.turn_left"
const TURN_RIGHT: StringName = &"movement.turn_right"
const RUN_FORWARD: StringName = &"movement.run_forward"
const CROUCH_ACTION: StringName = &"actor.stance.crouch"
const STAND_ACTION: StringName = &"actor.stance.stand"

var _needs: ActorNeedsState = null

func _init(needs_state: ActorNeedsState = null) -> void:
    super("actor_needs")
    _needs = needs_state

func evaluate(actor_id: String, action_type: StringName) -> Dictionary:
    if not _is_locomotion_action(action_type):
        return decision(Status.ALLOWED, 0, "")
    if _needs == null or not _needs.has_actor(actor_id):
        return decision(Status.UNKNOWN, 0, "needs_unclassified")
    var fatigue_value: int = _needs.fatigue(actor_id)
    if fatigue_value < 0:
        return decision(Status.UNKNOWN, 0, "fatigue_unclassified")
    return decision(Status.ALLOWED, fatigue_value * 65, "")

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
