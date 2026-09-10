extends MovementActionService
class_name PassageAwareMovementActionService

const ResultRules = preload("res://scripts/simulation/movement/MovementActionResult.gd")
const QueryRules = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")
const PhaseRules = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRulesLocal = preload("res://scripts/foundation/time/TickRules.gd")

## Optional extension of canonical MovementActionService that delegates known
## blocked passages through a generic MovementPassageResolver. No door dependency.
## Passage state may resolve at the movement phase, but actor occupancy still commits
## through the base service's same-WHEN deterministic placement batch.

var _passage_resolver: MovementPassageResolver = null

func _init(
    world_state: WorldState = null,
    mutation_service: WorldMutationService = null,
    spatial_query: SpatialQueryService = null,
    tick_kernel: TickKernel = null,
    traversal_policy: MovementTraversalPolicy = null,
    passage_resolver: MovementPassageResolver = null
) -> void:
    _passage_resolver = passage_resolver
    super(world_state, mutation_service, spatial_query, tick_kernel, traversal_policy)

func passage_ready() -> bool:
    return _passage_resolver != null and _passage_resolver.is_ready()

func request_step_forward(actor_id: String) -> MovementActionResult:
    return _request_walk_with_passage(actor_id, STEP_FORWARD)

func request_step_backward(actor_id: String) -> MovementActionResult:
    return _request_walk_with_passage(actor_id, STEP_BACKWARD)

func _request_walk_with_passage(actor_id: String, action_type: StringName) -> MovementActionResult:
    if not passage_ready():
        return super.request_step_forward(actor_id) if action_type == STEP_FORWARD else super.request_step_backward(actor_id)

    var probe := ResultRules.new()
    probe.action_type = action_type
    if not is_ready():
        probe.status = ResultRules.Status.NOT_READY
        probe.reason = "movement_not_ready"
        return probe
    var current: WorldPlacement = _validated_actor_placement(actor_id, probe)
    if current == null:
        return probe
    var normalized_actor: String = actor_id.strip_edges()
    var target: Dictionary = _target_for(current, action_type)
    if target.is_empty():
        probe.status = ResultRules.Status.NOT_READY
        probe.reason = "invalid_movement_action"
        return probe
    var target_anchor: Vector2i = target["anchor"]
    var target_facing: int = int(target["facing"])
    probe.target_anchor = target_anchor
    probe.target_facing = target_facing

    var query_result: SpatialQueryResult = _query.query_entity_footprint(normalized_actor, target_anchor, target_facing, true)
    if query_result == null or query_result.status == QueryRules.Status.UNKNOWN:
        probe.status = ResultRules.Status.TARGET_UNKNOWN
        probe.reason = "target_unknown"
        return probe
    if query_result.status == QueryRules.Status.CLEAR:
        return super.request_step_forward(actor_id) if action_type == STEP_FORWARD else super.request_step_backward(actor_id)
    if query_result.status != QueryRules.Status.BLOCKED or not _passage_resolver.can_resolve(normalized_actor, action_type, query_result):
        probe.status = ResultRules.Status.TARGET_BLOCKED
        probe.reason = "target_blocked"
        return probe

    var policy_decision: MovementPolicyDecision = _evaluate_step_policy(normalized_actor, action_type, query_result.cells)
    if not _apply_policy_result(probe, policy_decision):
        return probe
    var duration_ticks: int = policy_decision.duration_ticks
    var blockers: Array[String] = query_result.blocking_entity_ids.duplicate()
    blockers.sort()
    var phases: Array[ActionPhase] = [PhaseRules.new(COMMIT_PHASE, duration_ticks)]
    var payload: Dictionary = {
        "expected_placement": current.to_snapshot(),
        "target_anchor": [target_anchor.x, target_anchor.y],
        "target_facing": target_facing,
        "passage_blockers": blockers,
    }
    var serial: int = _kernel.begin_action(
        normalized_actor,
        action_type,
        duration_ticks,
        TickRulesLocal.InterruptionPolicy.CANCELABLE,
        phases,
        payload
    )
    if serial <= 0:
        probe.status = ResultRules.Status.TIMING_REJECTED
        probe.reason = "timing_rejected"
        return probe
    probe.status = ResultRules.Status.ACCEPTED
    probe.action_serial = serial
    probe.duration_ticks = duration_ticks
    probe.reason = ""
    return probe

func _prepare_standard_action(action: TimedAction) -> Dictionary:
    var candidate: Dictionary = super._prepare_standard_action(action)
    if action == null or not _is_walk_step(action.action_type) or not action.payload.has("passage_blockers"):
        return candidate
    if bool(candidate.get("ready", false)) or String(candidate.get("reason", "")) != "target_blocked":
        return candidate
    if not passage_ready():
        return _candidate_failure(candidate, "movement_not_ready")

    var target_anchor: Vector2i = _anchor_from_payload(action.payload, "target_anchor")
    var target_facing: int = int(action.payload.get("target_facing", -1))
    var query_result: SpatialQueryResult = _query.query_entity_footprint(
        action.actor_id,
        target_anchor,
        target_facing,
        true
    )
    if query_result == null or query_result.status == QueryRules.Status.UNKNOWN:
        return _candidate_failure(candidate, "target_unknown")
    if query_result.status != QueryRules.Status.BLOCKED:
        return super._prepare_standard_action(action)

    var expected_blockers: Array = action.payload.get("passage_blockers", [])
    var current_blockers: Array[String] = query_result.blocking_entity_ids.duplicate()
    current_blockers.sort()
    if expected_blockers != current_blockers:
        return _candidate_failure(candidate, "passage_changed")
    if not _passage_resolver.resolve(action.actor_id, action.serial, action.action_type, query_result):
        return _candidate_failure(candidate, "passage_resolution_failed")

    return super._prepare_standard_action(action)

func _prepare_run_stride(action: TimedAction, stride_index: int) -> Dictionary:
    var candidate: Dictionary = super._prepare_run_stride(action, stride_index)
    if action == null or not passage_ready() or not bool(candidate.get("impact", false)):
        return candidate

    var target_anchor: Vector2i = candidate.get("target_anchor", Vector2i.ZERO)
    var target_facing: int = int(candidate.get("target_facing", -1))
    var query_result: SpatialQueryResult = _query.query_entity_footprint(
        action.actor_id,
        target_anchor,
        target_facing,
        true
    )
    if query_result == null or query_result.status != QueryRules.Status.BLOCKED:
        return candidate
    if not _passage_resolver.can_resolve(action.actor_id, action.action_type, query_result):
        return candidate
    if not _passage_resolver.resolve(action.actor_id, action.serial, action.action_type, query_result):
        return candidate

    return super._prepare_run_stride(action, stride_index)
