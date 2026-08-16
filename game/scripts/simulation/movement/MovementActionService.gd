extends RefCounted
class_name MovementActionService

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const PlacementClass = preload("res://scripts/foundation/world/WorldPlacement.gd")
const ResultClass = preload("res://scripts/simulation/movement/MovementActionResult.gd")
const PolicyDecisionClass = preload("res://scripts/simulation/movement/MovementPolicyDecision.gd")
const QueryResultClass = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")
const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRulesClass = preload("res://scripts/foundation/time/TickRules.gd")

## Canonical WHERE + WHAT + Collision + WHEN actor movement bridge.
## Input, rendering, AI, health, stance, pathfinding, etc. remain outside.

signal movement_committed(actor_id, action_serial, action_type, target_anchor, target_facing)
signal movement_failed(actor_id, action_serial, action_type, reason)

const STEP_FORWARD: StringName = &"movement.step_forward"
const STEP_BACKWARD: StringName = &"movement.step_backward"
const TURN_LEFT: StringName = &"movement.turn_left"
const TURN_RIGHT: StringName = &"movement.turn_right"
const COMMIT_PHASE: StringName = &"movement.commit"

var _world: WorldState = null
var _mutations: WorldMutationService = null
var _query: SpatialQueryService = null
var _kernel: TickKernel = null
var _policy: MovementTraversalPolicy = null

func _init(
    world_state: WorldState = null,
    mutation_service: WorldMutationService = null,
    spatial_query: SpatialQueryService = null,
    tick_kernel: TickKernel = null,
    traversal_policy: MovementTraversalPolicy = null
) -> void:
    _world = world_state
    _mutations = mutation_service
    _query = spatial_query
    _kernel = tick_kernel
    _policy = traversal_policy
    if _kernel != null and not _kernel.action_phase.is_connected(_on_action_phase):
        _kernel.action_phase.connect(_on_action_phase)

func is_ready() -> bool:
    return _world != null \
        and _mutations != null and _mutations.is_ready() \
        and _query != null and _query.is_ready() \
        and _kernel != null \
        and _policy != null

func request_step_forward(actor_id: String) -> MovementActionResult:
    return _request(actor_id, STEP_FORWARD)

func request_step_backward(actor_id: String) -> MovementActionResult:
    return _request(actor_id, STEP_BACKWARD)

func request_turn_left(actor_id: String) -> MovementActionResult:
    return _request(actor_id, TURN_LEFT)

func request_turn_right(actor_id: String) -> MovementActionResult:
    return _request(actor_id, TURN_RIGHT)

func _request(actor_id: String, action_type: StringName) -> MovementActionResult:
    var result := ResultClass.new()
    result.action_type = action_type
    if not is_ready():
        result.status = ResultClass.Status.NOT_READY
        result.reason = "movement_not_ready"
        return result

    var normalized_actor: String = actor_id.strip_edges()
    if normalized_actor.is_empty() or not _world.has_entity(normalized_actor):
        result.status = ResultClass.Status.ACTOR_MISSING
        result.reason = "actor_missing"
        return result
    if not _world.has_placement(normalized_actor):
        result.status = ResultClass.Status.ACTOR_UNPLACED
        result.reason = "actor_unplaced"
        return result

    var current: WorldPlacement = _world.placement(normalized_actor)
    if current == null:
        result.status = ResultClass.Status.ACTOR_UNPLACED
        result.reason = "actor_unplaced"
        return result
    if current.channel != Layers.Channel.ACTOR:
        result.status = ResultClass.Status.NOT_ACTOR
        result.reason = "not_actor_placement"
        return result
    if _kernel.has_active_action(normalized_actor):
        result.status = ResultClass.Status.BUSY
        result.reason = "actor_busy"
        return result

    var target: Dictionary = _target_for(current, action_type)
    if target.is_empty():
        result.status = ResultClass.Status.NOT_READY
        result.reason = "invalid_movement_action"
        return result
    var target_anchor: Vector2i = target["anchor"]
    var target_facing: int = int(target["facing"])
    result.target_anchor = target_anchor
    result.target_facing = target_facing

    var query_result: SpatialQueryResult = _query.query_entity_footprint(
        normalized_actor,
        target_anchor,
        target_facing,
        true
    )
    if query_result.status == QueryResultClass.Status.UNKNOWN:
        result.status = ResultClass.Status.TARGET_UNKNOWN
        result.reason = "target_unknown"
        return result
    if query_result.status == QueryResultClass.Status.BLOCKED:
        result.status = ResultClass.Status.TARGET_BLOCKED
        result.reason = "target_blocked"
        return result
    if query_result.status != QueryResultClass.Status.CLEAR:
        result.status = ResultClass.Status.TARGET_UNKNOWN
        result.reason = "target_unknown"
        return result

    var policy_decision: MovementPolicyDecision = null
    if _is_step(action_type):
        policy_decision = _evaluate_step_policy(normalized_actor, action_type, query_result.cells)
    else:
        policy_decision = _policy.evaluate_turn(normalized_actor, action_type)

    if policy_decision == null:
        result.status = ResultClass.Status.NOT_READY
        result.reason = "movement_policy_not_ready"
        return result
    if not policy_decision.is_allowed():
        result.status = _result_status_for_policy(policy_decision.status)
        result.reason = _policy_reason(policy_decision)
        return result

    var duration_ticks: int = policy_decision.duration_ticks
    if duration_ticks < 1:
        result.status = ResultClass.Status.INVALID_DURATION
        result.reason = "invalid_duration"
        return result

    var phases: Array[ActionPhase] = [PhaseClass.new(COMMIT_PHASE, duration_ticks)]
    var payload: Dictionary = {
        "expected_placement": current.to_snapshot(),
        "target_anchor": [target_anchor.x, target_anchor.y],
        "target_facing": target_facing,
    }
    var action_serial: int = _kernel.begin_action(
        normalized_actor,
        action_type,
        duration_ticks,
        TickRulesClass.InterruptionPolicy.COMMITTED,
        phases,
        payload
    )
    if action_serial <= 0:
        result.status = ResultClass.Status.TIMING_REJECTED
        result.reason = "timing_rejected"
        return result

    result.status = ResultClass.Status.ACCEPTED
    result.action_serial = action_serial
    result.duration_ticks = duration_ticks
    result.reason = ""
    return result

func _on_action_phase(action: TimedAction, phase: ActionPhase) -> void:
    if action == null or phase == null:
        return
    if phase.phase_id != COMMIT_PHASE or not _is_movement_action(action.action_type):
        return
    _commit_action(action)

func _commit_action(action: TimedAction) -> void:
    if not is_ready():
        _fail_commit(action, "movement_not_ready")
        return

    var expected_value: Variant = action.payload.get("expected_placement", {})
    if typeof(expected_value) != TYPE_DICTIONARY:
        _fail_commit(action, "invalid_payload")
        return
    var expected: WorldPlacement = PlacementClass.from_snapshot(expected_value)
    if expected == null or expected.entity_id != action.actor_id or expected.channel != Layers.Channel.ACTOR:
        _fail_commit(action, "invalid_payload")
        return

    var current: WorldPlacement = _world.placement(action.actor_id)
    if current == null or not current.equivalent(expected):
        _fail_commit(action, "origin_changed")
        return

    var target_anchor_value: Variant = action.payload.get("target_anchor", [])
    if typeof(target_anchor_value) != TYPE_ARRAY or target_anchor_value.size() != 2:
        _fail_commit(action, "invalid_payload")
        return
    var target_anchor := Vector2i(int(target_anchor_value[0]), int(target_anchor_value[1]))
    var target_facing: int = int(action.payload.get("target_facing", -1))
    if not Facing.is_valid(target_facing):
        _fail_commit(action, "invalid_payload")
        return

    var canonical_target: Dictionary = _target_for(expected, action.action_type)
    if canonical_target.is_empty() \
        or canonical_target["anchor"] != target_anchor \
        or int(canonical_target["facing"]) != target_facing:
        _fail_commit(action, "invalid_payload")
        return

    var query_result: SpatialQueryResult = _query.query_entity_footprint(
        action.actor_id,
        target_anchor,
        target_facing,
        true
    )
    if query_result.status == QueryResultClass.Status.UNKNOWN:
        _fail_commit(action, "target_unknown")
        return
    if query_result.status == QueryResultClass.Status.BLOCKED:
        _fail_commit(action, "target_blocked")
        return
    if query_result.status != QueryResultClass.Status.CLEAR:
        _fail_commit(action, "target_unknown")
        return

    var policy_decision: MovementPolicyDecision = null
    if _is_step(action.action_type):
        policy_decision = _evaluate_step_policy(action.actor_id, action.action_type, query_result.cells)
    else:
        policy_decision = _policy.evaluate_turn(action.actor_id, action.action_type)

    if policy_decision == null:
        _fail_commit(action, "movement_policy_not_ready")
        return
    if not policy_decision.is_allowed():
        _fail_commit(action, _policy_reason(policy_decision))
        return

    if not _mutations.set_placement(
        action.actor_id,
        current.channel,
        target_anchor,
        target_facing,
        current.footprint,
        current.structure_axis
    ):
        _fail_commit(action, "placement_mutation_failed")
        return

    movement_committed.emit(
        action.actor_id,
        action.serial,
        action.action_type,
        target_anchor,
        target_facing
    )

func _fail_commit(action: TimedAction, reason: String) -> void:
    if action == null:
        return
    _kernel.fail_action(action.serial, reason)
    movement_failed.emit(action.actor_id, action.serial, action.action_type, reason)

func _evaluate_step_policy(
    actor_id: String,
    action_type: StringName,
    cells: Array[Vector2i]
) -> MovementPolicyDecision:
    var terrain_types: Array[StringName] = []
    for cell: Vector2i in cells:
        if not _query.has_terrain(cell):
            return PolicyDecisionClass.denied(
                PolicyDecisionClass.Status.TERRAIN_UNCLASSIFIED,
                "terrain_unclassified"
            )
        terrain_types.append(_query.terrain_at(cell))
    return _policy.evaluate_step(actor_id, action_type, terrain_types)

static func _result_status_for_policy(policy_status: int) -> int:
    match policy_status:
        PolicyDecisionClass.Status.TERRAIN_UNCLASSIFIED:
            return ResultClass.Status.TERRAIN_UNCLASSIFIED
        PolicyDecisionClass.Status.TERRAIN_BLOCKED:
            return ResultClass.Status.TERRAIN_BLOCKED
        PolicyDecisionClass.Status.ACTOR_UNCLASSIFIED:
            return ResultClass.Status.ACTOR_UNCLASSIFIED
        PolicyDecisionClass.Status.CAPABILITY_UNKNOWN:
            return ResultClass.Status.CAPABILITY_UNKNOWN
        PolicyDecisionClass.Status.CAPABILITY_BLOCKED:
            return ResultClass.Status.CAPABILITY_BLOCKED
        PolicyDecisionClass.Status.INVALID_DURATION:
            return ResultClass.Status.INVALID_DURATION
        _:
            return ResultClass.Status.NOT_READY

static func _policy_reason(decision: MovementPolicyDecision) -> String:
    if decision == null:
        return "movement_policy_not_ready"
    if not decision.reason.is_empty():
        return decision.reason
    match decision.status:
        PolicyDecisionClass.Status.TERRAIN_UNCLASSIFIED:
            return "terrain_unclassified"
        PolicyDecisionClass.Status.TERRAIN_BLOCKED:
            return "terrain_blocked"
        PolicyDecisionClass.Status.ACTOR_UNCLASSIFIED:
            return "actor_unclassified"
        PolicyDecisionClass.Status.CAPABILITY_UNKNOWN:
            return "capability_unknown"
        PolicyDecisionClass.Status.CAPABILITY_BLOCKED:
            return "capability_blocked"
        PolicyDecisionClass.Status.INVALID_DURATION:
            return "invalid_duration"
        _:
            return "movement_policy_rejected"

static func _target_for(current: WorldPlacement, action_type: StringName) -> Dictionary:
    if current == null or not Facing.is_valid(current.facing):
        return {}
    match action_type:
        STEP_FORWARD:
            return {
                "anchor": current.anchor + Facing.vector(current.facing),
                "facing": current.facing,
            }
        STEP_BACKWARD:
            return {
                "anchor": current.anchor + Facing.vector(Facing.opposite(current.facing)),
                "facing": current.facing,
            }
        TURN_LEFT:
            return {
                "anchor": current.anchor,
                "facing": Facing.turn_left(current.facing),
            }
        TURN_RIGHT:
            return {
                "anchor": current.anchor,
                "facing": Facing.turn_right(current.facing),
            }
        _:
            return {}

static func _is_step(action_type: StringName) -> bool:
    return action_type == STEP_FORWARD or action_type == STEP_BACKWARD

static func _is_movement_action(action_type: StringName) -> bool:
    return _is_step(action_type) or action_type == TURN_LEFT or action_type == TURN_RIGHT
