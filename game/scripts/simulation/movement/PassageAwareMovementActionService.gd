extends MovementActionService
class_name PassageAwareMovementActionService

const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const LayersRules = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const PlacementRules = preload("res://scripts/foundation/world/WorldPlacement.gd")
const ResultRules = preload("res://scripts/simulation/movement/MovementActionResult.gd")
const QueryRules = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")
const PhaseRules = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRulesLocal = preload("res://scripts/foundation/time/TickRules.gd")

## Optional extension of canonical MovementActionService that delegates known
## blocked passages through a generic MovementPassageResolver. No door dependency.

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

func _commit_standard_action(action: TimedAction) -> void:
    if action == null or not _is_walk_step(action.action_type) or not action.payload.has("passage_blockers"):
        super._commit_standard_action(action)
        return
    if not is_ready() or not passage_ready():
        _fail_commit(action, "movement_not_ready")
        return
    var expected: WorldPlacement = _expected_origin(action)
    if expected == null:
        _fail_commit(action, "invalid_payload")
        return
    var current: WorldPlacement = _world.placement(action.actor_id)
    if current == null or not current.equivalent(expected):
        _fail_commit(action, "origin_changed")
        return
    var target_anchor: Vector2i = _anchor_from_payload(action.payload, "target_anchor")
    var target_facing: int = int(action.payload.get("target_facing", -1))
    if not FacingRules.is_valid(target_facing):
        _fail_commit(action, "invalid_payload")
        return
    var canonical_target: Dictionary = _target_for(expected, action.action_type)
    if canonical_target.is_empty() or canonical_target["anchor"] != target_anchor or int(canonical_target["facing"]) != target_facing:
        _fail_commit(action, "invalid_payload")
        return

    var query_result: SpatialQueryResult = _query.query_entity_footprint(action.actor_id, target_anchor, target_facing, true)
    if query_result == null or query_result.status == QueryRules.Status.UNKNOWN:
        _fail_commit(action, "target_unknown")
        return
    if query_result.status == QueryRules.Status.BLOCKED:
        var expected_blockers: Array = action.payload.get("passage_blockers", [])
        var current_blockers: Array[String] = query_result.blocking_entity_ids.duplicate()
        current_blockers.sort()
        if expected_blockers != current_blockers:
            _fail_commit(action, "passage_changed")
            return
        if not _passage_resolver.resolve(action.actor_id, action.serial, action.action_type, query_result):
            _fail_commit(action, "passage_resolution_failed")
            return
        query_result = _query.query_entity_footprint(action.actor_id, target_anchor, target_facing, true)
    if query_result == null or query_result.status != QueryRules.Status.CLEAR:
        _fail_commit(action, "target_blocked" if query_result != null and query_result.status == QueryRules.Status.BLOCKED else "target_unknown")
        return

    var terrain_types: Array[StringName] = _terrain_types(query_result.cells)
    if terrain_types.is_empty():
        _fail_commit(action, "terrain_unclassified")
        return
    var policy_decision: MovementPolicyDecision = _policy.evaluate_step(action.actor_id, action.action_type, terrain_types)
    var walk_ticks: int = _policy.terrain_walk_ticks(action.actor_id, terrain_types)
    if policy_decision == null or not policy_decision.is_allowed() or walk_ticks < 1:
        _fail_commit(action, _policy_reason(policy_decision))
        return
    if not _mutations.set_placement(action.actor_id, current.channel, target_anchor, target_facing, current.footprint, current.structure_axis):
        _fail_commit(action, "placement_mutation_failed")
        return
    movement_exertion_resolved.emit(action.actor_id, action.serial, action.action_type, 1, walk_ticks, false)
    movement_committed.emit(action.actor_id, action.serial, action.action_type, target_anchor, target_facing)

func _commit_run_stride(action: TimedAction, stride_index: int) -> void:
    if not passage_ready():
        super._commit_run_stride(action, stride_index)
        return
    if not is_ready() or stride_index < 1 or stride_index > 2:
        _fail_commit(action, "movement_not_ready" if not is_ready() else "invalid_payload")
        return
    var origin: WorldPlacement = _expected_origin(action)
    if origin == null:
        _fail_commit(action, "invalid_payload")
        return
    var target_facing: int = int(action.payload.get("target_facing", -1))
    if not FacingRules.is_valid(target_facing) or target_facing != origin.facing:
        _fail_commit(action, "invalid_payload")
        return
    var stride_1_anchor: Vector2i = _anchor_from_payload(action.payload, "stride_1_anchor")
    var stride_2_anchor: Vector2i = _anchor_from_payload(action.payload, "stride_2_anchor")
    var forward: Vector2i = FacingRules.vector(origin.facing)
    if stride_1_anchor != origin.anchor + forward or stride_2_anchor != stride_1_anchor + forward:
        _fail_commit(action, "invalid_payload")
        return
    var expected_current: WorldPlacement = origin.copy()
    expected_current.anchor = origin.anchor if stride_index == 1 else stride_1_anchor
    var target_anchor: Vector2i = stride_1_anchor if stride_index == 1 else stride_2_anchor
    var current: WorldPlacement = _world.placement(action.actor_id)
    if current == null or not current.equivalent(expected_current):
        _fail_commit(action, "origin_changed")
        return

    var query_result: SpatialQueryResult = _query.query_entity_footprint(action.actor_id, target_anchor, target_facing, true)
    if query_result == null or query_result.status == QueryRules.Status.UNKNOWN:
        _fail_commit(action, "target_unknown")
        return
    var terrain_key: String = "stride_%d_terrain" % stride_index
    var stored_terrain: Variant = action.payload.get(terrain_key, [])
    if typeof(stored_terrain) != TYPE_ARRAY or _terrain_snapshot(query_result.cells) != stored_terrain:
        _fail_commit(action, "terrain_changed")
        return
    var walk_ticks: int = int(action.payload.get("stride_%d_walk_ticks" % stride_index, 0))
    if walk_ticks < 1:
        _fail_commit(action, "invalid_payload")
        return

    if query_result.status == QueryRules.Status.BLOCKED and _passage_resolver.can_resolve(action.actor_id, action.action_type, query_result):
        if _passage_resolver.resolve(action.actor_id, action.serial, action.action_type, query_result):
            query_result = _query.query_entity_footprint(action.actor_id, target_anchor, target_facing, true)
    if query_result != null and query_result.status == QueryRules.Status.BLOCKED:
        movement_exertion_resolved.emit(action.actor_id, action.serial, RUN_FORWARD, stride_index, walk_ticks, true)
        run_impact.emit(action.actor_id, action.serial, stride_index, target_anchor, target_facing, query_result.blocking_entity_ids.duplicate())
        _fail_commit(action, "run_impact")
        return
    if query_result == null or query_result.status != QueryRules.Status.CLEAR:
        _fail_commit(action, "target_unknown")
        return
    if not _mutations.set_placement(action.actor_id, current.channel, target_anchor, target_facing, current.footprint, current.structure_axis):
        _fail_commit(action, "placement_mutation_failed")
        return
    run_stride_committed.emit(action.actor_id, action.serial, stride_index, target_anchor, target_facing)
    movement_exertion_resolved.emit(action.actor_id, action.serial, RUN_FORWARD, stride_index, walk_ticks, false)
    if stride_index == 2:
        movement_committed.emit(action.actor_id, action.serial, action.action_type, target_anchor, target_facing)
