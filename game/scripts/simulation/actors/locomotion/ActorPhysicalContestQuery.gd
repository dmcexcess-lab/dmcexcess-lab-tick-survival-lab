extends MovementPhysicalContestProvider
class_name ActorPhysicalContestQuery

const StanceRules = preload("res://scripts/simulation/actors/locomotion/ActorStance.gd")
const CarryQueryClass = preload("res://scripts/simulation/actors/carry/ActorCarryQuery.gd")

const SCALE_ONE: int = 10000
const STEP_FORWARD_BP: int = 10000
const STEP_BACKWARD_BP: int = 9000
const RUN_FORWARD_BP: int = 12500
const SHOVE_BP: int = 12500
const HOLD_BP: int = 10000
const CROUCHED_BP: int = 8500
const STANDING_BP: int = 10000

var _carry: ActorCarryQuery = null
var _health: ActorHealthState = null
var _locomotion: ActorLocomotionState = null

func _init(
    carry_query: ActorCarryQuery = null,
    health_state: ActorHealthState = null,
    locomotion_state: ActorLocomotionState = null
) -> void:
    _carry = carry_query
    _health = health_state
    _locomotion = locomotion_state

func is_ready() -> bool:
    return _carry != null and _health != null and _locomotion != null

func score(actor_id: String, action_type: StringName) -> Dictionary:
    if not is_ready() or actor_id.strip_edges().is_empty():
        return result(Status.UNKNOWN, 0, "physical_contest_not_ready")
    if not _health.has_actor(actor_id) or not _locomotion.has_actor(actor_id):
        return result(Status.UNKNOWN, 0, "actor_physical_state_unclassified")

    var carry: Dictionary = _carry.query(actor_id)
    if int(carry.get("status", -1)) != CarryQueryClass.Status.KNOWN:
        return result(Status.UNKNOWN, 0, String(carry.get("reason", "carry_unknown")))

    var capacity_grams: int = int(carry.get("capacity_grams", 0))
    var load_ratio_bp: int = maxi(0, int(carry.get("load_ratio_bp", 0)))
    var hp: int = _health.current_hp(actor_id)
    var max_hp: int = _health.max_hp(actor_id)
    if capacity_grams <= 0 or hp <= 0 or max_hp <= 0:
        return result(Status.UNKNOWN, 0, "physical_stat_invalid")

    var stance: StringName = _locomotion.stance(actor_id)
    var stance_bp: int = STANDING_BP
    if stance == StanceRules.CROUCHED:
        stance_bp = CROUCHED_BP
    elif stance != StanceRules.STANDING:
        return result(Status.UNKNOWN, 0, "stance_unclassified")

    var action_bp: int = _action_force_bp(action_type)
    if action_bp <= 0:
        return result(Status.UNKNOWN, 0, "contest_action_unclassified")

    # Existing canonical stats only:
    # - condition-adjusted carry capacity is the actor's available physical capacity;
    # - load reduces usable force smoothly rather than inventing a binary encumbrance rule;
    # - current HP scales present physical effectiveness;
    # - stance and movement intent affect leverage/momentum.
    var load_denominator: int = SCALE_ONE + load_ratio_bp
    var load_adjusted: int = maxi(1, int((capacity_grams * SCALE_ONE) / load_denominator))
    var hp_bp: int = clampi(int((hp * SCALE_ONE) / max_hp), 1, SCALE_ONE)
    var score_value: int = load_adjusted
    score_value = maxi(1, int((score_value * hp_bp) / SCALE_ONE))
    score_value = maxi(1, int((score_value * stance_bp) / SCALE_ONE))
    score_value = maxi(1, int((score_value * action_bp) / SCALE_ONE))
    return result(Status.KNOWN, score_value, "")

static func _action_force_bp(action_type: StringName) -> int:
    match action_type:
        &"movement.step_forward":
            return STEP_FORWARD_BP
        &"movement.step_backward":
            return STEP_BACKWARD_BP
        &"movement.run_forward":
            return RUN_FORWARD_BP
        &"combat.shove":
            return SHOVE_BP
        &"physical.hold":
            return HOLD_BP
        _:
            return 0
