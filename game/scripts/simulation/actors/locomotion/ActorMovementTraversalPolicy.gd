extends "res://scripts/simulation/movement/MovementTraversalPolicy.gd"
class_name ActorMovementTraversalPolicy

const PolicyDecisionClass = preload("res://scripts/simulation/movement/MovementPolicyDecision.gd")
const CapabilityDecisionClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementCapabilityDecision.gd")

## MovementTraversalPolicy adapter that adds actor capability after base terrain/timing policy.
## It does not own terrain, collision, actor condition domains, or WHEN.

const RUN_FORWARD: StringName = &"movement.run_forward"

var _base_policy: MovementTraversalPolicy = null
var _capability: ActorMovementCapabilityService = null

func _init(
    base_policy: MovementTraversalPolicy = null,
    capability_service: ActorMovementCapabilityService = null
) -> void:
    super()
    _base_policy = base_policy
    _capability = capability_service

func is_ready() -> bool:
    return _base_policy != null and _capability != null and _capability.is_ready()

func evaluate_step(actor_id: String, action_type: StringName, terrain_types: Array) -> MovementPolicyDecision:
    if not is_ready():
        return PolicyDecisionClass.denied(
            PolicyDecisionClass.Status.CAPABILITY_UNKNOWN,
            "actor_movement_policy_not_ready"
        )
    var base_decision: MovementPolicyDecision = _base_policy.evaluate_step(
        actor_id,
        action_type,
        terrain_types
    )
    if base_decision == null or not base_decision.is_allowed():
        return base_decision
    return _apply_capability(actor_id, action_type, base_decision.duration_ticks)

func evaluate_run_stride(actor_id: String, terrain_types: Array) -> MovementPolicyDecision:
    if not is_ready():
        return PolicyDecisionClass.denied(
            PolicyDecisionClass.Status.CAPABILITY_UNKNOWN,
            "actor_movement_policy_not_ready"
        )
    var base_decision: MovementPolicyDecision = _base_policy.evaluate_run_stride(
        actor_id,
        terrain_types
    )
    if base_decision == null or not base_decision.is_allowed():
        return base_decision
    return _apply_capability(actor_id, RUN_FORWARD, base_decision.duration_ticks)

func terrain_walk_ticks(actor_id: String, terrain_types: Array) -> int:
    if not is_ready():
        return 0
    return _base_policy.terrain_walk_ticks(actor_id, terrain_types)

func evaluate_turn(actor_id: String, action_type: StringName) -> MovementPolicyDecision:
    if not is_ready():
        return PolicyDecisionClass.denied(
            PolicyDecisionClass.Status.CAPABILITY_UNKNOWN,
            "actor_movement_policy_not_ready"
        )
    var base_decision: MovementPolicyDecision = _base_policy.evaluate_turn(actor_id, action_type)
    if base_decision == null or not base_decision.is_allowed():
        return base_decision
    return _apply_capability(actor_id, action_type, base_decision.duration_ticks)

func _apply_capability(
    actor_id: String,
    action_type: StringName,
    base_duration_ticks: int
) -> MovementPolicyDecision:
    var capability_decision: ActorMovementCapabilityDecision = _capability.evaluate(
        actor_id,
        action_type,
        base_duration_ticks
    )
    if capability_decision == null:
        return PolicyDecisionClass.denied(
            PolicyDecisionClass.Status.CAPABILITY_UNKNOWN,
            "capability_unknown"
        )

    match capability_decision.status:
        CapabilityDecisionClass.Status.ALLOWED:
            return PolicyDecisionClass.allowed(capability_decision.duration_ticks)
        CapabilityDecisionClass.Status.ACTOR_UNCLASSIFIED:
            return PolicyDecisionClass.denied(
                PolicyDecisionClass.Status.ACTOR_UNCLASSIFIED,
                capability_decision.reason
            )
        CapabilityDecisionClass.Status.CAPABILITY_BLOCKED:
            return PolicyDecisionClass.denied(
                PolicyDecisionClass.Status.CAPABILITY_BLOCKED,
                capability_decision.reason
            )
        CapabilityDecisionClass.Status.INVALID_DURATION:
            return PolicyDecisionClass.denied(
                PolicyDecisionClass.Status.INVALID_DURATION,
                capability_decision.reason
            )
        _:
            return PolicyDecisionClass.denied(
                PolicyDecisionClass.Status.CAPABILITY_UNKNOWN,
                capability_decision.reason
            )
