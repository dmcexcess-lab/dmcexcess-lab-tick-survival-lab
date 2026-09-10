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
## Input, rendering, AI, health, needs, carry, stance, pathfinding, etc. remain outside.
## Same-WHEN successful movement phases are resolved as one deterministic occupancy batch.

signal movement_committed(actor_id, action_serial, action_type, target_anchor, target_facing)
signal movement_failed(actor_id, action_serial, action_type, reason)
signal run_stride_committed(actor_id, action_serial, stride_index, target_anchor, target_facing)
signal movement_exertion_resolved(actor_id, action_serial, action_type, stride_index, terrain_walk_ticks, impacted)
signal run_impact(actor_id, action_serial, stride_index, target_anchor, target_facing, blocking_entity_ids)

const STEP_FORWARD: StringName = &"movement.step_forward"
const STEP_BACKWARD: StringName = &"movement.step_backward"
const RUN_FORWARD: StringName = &"movement.run_forward"
const TURN_LEFT: StringName = &"movement.turn_left"
const TURN_RIGHT: StringName = &"movement.turn_right"
const COMMIT_PHASE: StringName = &"movement.commit"
const RUN_STRIDE_1_PHASE: StringName = &"movement.run_stride_1"
const RUN_STRIDE_2_PHASE: StringName = &"movement.run_stride_2"
const TIMESTAMP_BATCH_FLUSH_EVENT: StringName = &"movement.timestamp_batch_flush"
const TIMESTAMP_BATCH_FLUSH_OWNER: String = "when.movement.timestamp_batch"
const TIMESTAMP_BATCH_FLUSH_PRIORITY: int = 2147483647

var _world: WorldState = null
var _mutations: WorldMutationService = null
var _query: SpatialQueryService = null
var _kernel: TickKernel = null
var _policy: MovementTraversalPolicy = null
var _pending_commits: Array[Dictionary] = []
var _pending_flush_event_serial: int = 0

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
    if _kernel != null:
        if not _kernel.action_phase.is_connected(_on_action_phase):
            _kernel.action_phase.connect(_on_action_phase)
        if not _kernel.action_finished.is_connected(_on_action_finished):
            _kernel.action_finished.connect(_on_action_finished)
        if not _kernel.external_event_due.is_connected(_on_external_event_due):
            _kernel.external_event_due.connect(_on_external_event_due)
        if not _kernel.timing_state_reset.is_connected(_on_timing_state_reset):
            _kernel.timing_state_reset.connect(_on_timing_state_reset)

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

func request_run_forward(actor_id: String) -> MovementActionResult:
    return _request_run(actor_id)

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

    var current: WorldPlacement = _validated_actor_placement(actor_id, result)
    if current == null:
        return result
    var normalized_actor: String = actor_id.strip_edges()

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
    if not _apply_query_failure(result, query_result):
        return result

    var policy_decision: MovementPolicyDecision = null
    if _is_walk_step(action_type):
        policy_decision = _evaluate_step_policy(normalized_actor, action_type, query_result.cells)
    else:
        policy_decision = _policy.evaluate_turn(normalized_actor, action_type)

    if not _apply_policy_result(result, policy_decision):
        return result

    var duration_ticks: int = policy_decision.duration_ticks
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
        _interruption_policy(action_type),
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

func _request_run(actor_id: String) -> MovementActionResult:
    var result := ResultClass.new()
    result.action_type = RUN_FORWARD
    if not is_ready():
        result.status = ResultClass.Status.NOT_READY
        result.reason = "movement_not_ready"
        return result

    var current: WorldPlacement = _validated_actor_placement(actor_id, result)
    if current == null:
        return result
    var normalized_actor: String = actor_id.strip_edges()
    var forward: Vector2i = Facing.vector(current.facing)
    var stride_1_anchor: Vector2i = current.anchor + forward
    var stride_2_anchor: Vector2i = stride_1_anchor + forward
    result.target_anchor = stride_2_anchor
    result.target_facing = current.facing

    var stride_1_query: SpatialQueryResult = _query.query_entity_footprint(
        normalized_actor,
        stride_1_anchor,
        current.facing,
        true
    )
    if not _apply_run_request_query(result, stride_1_query):
        return result
    var stride_2_query: SpatialQueryResult = _query.query_entity_footprint(
        normalized_actor,
        stride_2_anchor,
        current.facing,
        true
    )
    if not _apply_run_request_query(result, stride_2_query):
        return result

    var stride_1_terrain_types: Array[StringName] = _terrain_types(stride_1_query.cells)
    var stride_2_terrain_types: Array[StringName] = _terrain_types(stride_2_query.cells)
    if stride_1_terrain_types.is_empty() or stride_2_terrain_types.is_empty():
        result.status = ResultClass.Status.TERRAIN_UNCLASSIFIED
        result.reason = "terrain_unclassified"
        return result

    var stride_1_policy: MovementPolicyDecision = _policy.evaluate_run_stride(
        normalized_actor,
        stride_1_terrain_types
    )
    if not _apply_policy_result(result, stride_1_policy):
        return result
    var stride_2_policy: MovementPolicyDecision = _policy.evaluate_run_stride(
        normalized_actor,
        stride_2_terrain_types
    )
    if not _apply_policy_result(result, stride_2_policy):
        return result

    var stride_1_walk_ticks: int = _policy.terrain_walk_ticks(normalized_actor, stride_1_terrain_types)
    var stride_2_walk_ticks: int = _policy.terrain_walk_ticks(normalized_actor, stride_2_terrain_types)
    var stride_1_ticks: int = stride_1_policy.duration_ticks
    var stride_2_ticks: int = stride_2_policy.duration_ticks
    var duration_ticks: int = stride_1_ticks + stride_2_ticks
    if stride_1_walk_ticks < 1 or stride_2_walk_ticks < 1 or stride_1_ticks < 1 or stride_2_ticks < 1 or duration_ticks < 2:
        result.status = ResultClass.Status.INVALID_DURATION
        result.reason = "invalid_duration"
        return result

    var phases: Array[ActionPhase] = [
        PhaseClass.new(RUN_STRIDE_1_PHASE, stride_1_ticks),
        PhaseClass.new(RUN_STRIDE_2_PHASE, duration_ticks),
    ]
    var payload: Dictionary = {
        "expected_placement": current.to_snapshot(),
        "target_facing": current.facing,
        "stride_1_anchor": [stride_1_anchor.x, stride_1_anchor.y],
        "stride_2_anchor": [stride_2_anchor.x, stride_2_anchor.y],
        "stride_1_terrain": _terrain_snapshot(stride_1_query.cells),
        "stride_2_terrain": _terrain_snapshot(stride_2_query.cells),
        "stride_1_ticks": stride_1_ticks,
        "stride_2_ticks": stride_2_ticks,
        "stride_1_walk_ticks": stride_1_walk_ticks,
        "stride_2_walk_ticks": stride_2_walk_ticks,
    }
    var action_serial: int = _kernel.begin_action(
        normalized_actor,
        RUN_FORWARD,
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

func _validated_actor_placement(actor_id: String, result: MovementActionResult) -> WorldPlacement:
    var normalized_actor: String = actor_id.strip_edges()
    if normalized_actor.is_empty() or not _world.has_entity(normalized_actor):
        result.status = ResultClass.Status.ACTOR_MISSING
        result.reason = "actor_missing"
        return null
    if not _world.has_placement(normalized_actor):
        result.status = ResultClass.Status.ACTOR_UNPLACED
        result.reason = "actor_unplaced"
        return null
    var current: WorldPlacement = _world.placement(normalized_actor)
    if current == null:
        result.status = ResultClass.Status.ACTOR_UNPLACED
        result.reason = "actor_unplaced"
        return null
    if current.channel != Layers.Channel.ACTOR:
        result.status = ResultClass.Status.NOT_ACTOR
        result.reason = "not_actor_placement"
        return null
    if _kernel.has_active_action(normalized_actor):
        result.status = ResultClass.Status.BUSY
        result.reason = "actor_busy"
        return null
    return current

func _apply_query_failure(result: MovementActionResult, query_result: SpatialQueryResult) -> bool:
    if query_result == null or query_result.status == QueryResultClass.Status.UNKNOWN:
        result.status = ResultClass.Status.TARGET_UNKNOWN
        result.reason = "target_unknown"
        return false
    if query_result.status == QueryResultClass.Status.BLOCKED:
        result.status = ResultClass.Status.TARGET_BLOCKED
        result.reason = "target_blocked"
        return false
    if query_result.status != QueryResultClass.Status.CLEAR:
        result.status = ResultClass.Status.TARGET_UNKNOWN
        result.reason = "target_unknown"
        return false
    return true

func _apply_run_request_query(result: MovementActionResult, query_result: SpatialQueryResult) -> bool:
    if query_result == null or query_result.status == QueryResultClass.Status.UNKNOWN:
        result.status = ResultClass.Status.TARGET_UNKNOWN
        result.reason = "target_unknown"
        return false
    if query_result.status != QueryResultClass.Status.CLEAR and query_result.status != QueryResultClass.Status.BLOCKED:
        result.status = ResultClass.Status.TARGET_UNKNOWN
        result.reason = "target_unknown"
        return false
    return true

func _apply_policy_result(result: MovementActionResult, decision: MovementPolicyDecision) -> bool:
    if decision == null:
        result.status = ResultClass.Status.NOT_READY
        result.reason = "movement_policy_not_ready"
        return false
    if not decision.is_allowed():
        result.status = _result_status_for_policy(decision.status)
        result.reason = _policy_reason(decision)
        return false
    if decision.duration_ticks < 1:
        result.status = ResultClass.Status.INVALID_DURATION
        result.reason = "invalid_duration"
        return false
    return true

func _on_action_phase(action: TimedAction, phase: ActionPhase) -> void:
    if action == null or phase == null:
        return

    var candidate: Dictionary = {}
    if action.action_type == RUN_FORWARD:
        if phase.phase_id == RUN_STRIDE_1_PHASE:
            candidate = _prepare_run_stride(action, 1)
        elif phase.phase_id == RUN_STRIDE_2_PHASE:
            candidate = _prepare_run_stride(action, 2)
        else:
            return
    elif phase.phase_id == COMMIT_PHASE and _is_standard_movement_action(action.action_type):
        candidate = _prepare_standard_action(action)
    else:
        return

    if candidate.is_empty():
        return
    if bool(candidate.get("ready", false)):
        if not _queue_timestamp_commit(candidate):
            _fail_commit(action, "movement_batch_schedule_failed")
        return
    if bool(candidate.get("impact", false)):
        _emit_run_impact_failure(candidate)
        return
    _fail_commit(action, String(candidate.get("reason", "movement_commit_failed")))

func _on_external_event_due(event: ScheduledEvent) -> void:
    if event == null or event.event_type != TIMESTAMP_BATCH_FLUSH_EVENT:
        return
    if _pending_flush_event_serial > 0 and event.serial != _pending_flush_event_serial:
        return
    _pending_flush_event_serial = 0
    _flush_timestamp_commits()

func _on_timing_state_reset() -> void:
    _pending_commits.clear()
    _pending_flush_event_serial = 0

func _on_action_finished(action: TimedAction) -> void:
    if action == null or not _is_movement_action(action.action_type):
        return
    _remove_pending_action(action.serial)
    if action.status == TickRulesClass.ActionStatus.CANCELED or action.status == TickRulesClass.ActionStatus.INTERRUPTED:
        movement_failed.emit(
            action.actor_id,
            action.serial,
            action.action_type,
            action.reason if not action.reason.is_empty() else "movement_interrupted"
        )

func _prepare_standard_action(action: TimedAction) -> Dictionary:
    var candidate: Dictionary = _candidate_base(action, 0)
    if not is_ready():
        return _candidate_failure(candidate, "movement_not_ready")

    var expected: WorldPlacement = _expected_origin(action)
    if expected == null:
        return _candidate_failure(candidate, "invalid_payload")
    var current: WorldPlacement = _world.placement(action.actor_id)
    if current == null or not current.equivalent(expected):
        return _candidate_failure(candidate, "origin_changed")

    var target_anchor_value: Variant = action.payload.get("target_anchor", [])
    if typeof(target_anchor_value) != TYPE_ARRAY or target_anchor_value.size() != 2:
        return _candidate_failure(candidate, "invalid_payload")
    var target_anchor := Vector2i(int(target_anchor_value[0]), int(target_anchor_value[1]))
    var target_facing: int = int(action.payload.get("target_facing", -1))
    if not Facing.is_valid(target_facing):
        return _candidate_failure(candidate, "invalid_payload")

    var canonical_target: Dictionary = _target_for(expected, action.action_type)
    if canonical_target.is_empty() \
        or canonical_target["anchor"] != target_anchor \
        or int(canonical_target["facing"]) != target_facing:
        return _candidate_failure(candidate, "invalid_payload")

    var query_result: SpatialQueryResult = _query.query_entity_footprint(
        action.actor_id,
        target_anchor,
        target_facing,
        true
    )
    if query_result == null or query_result.status == QueryResultClass.Status.UNKNOWN:
        return _candidate_failure(candidate, "target_unknown")
    if query_result.status == QueryResultClass.Status.BLOCKED:
        return _candidate_failure(candidate, "target_blocked")
    if query_result.status != QueryResultClass.Status.CLEAR:
        return _candidate_failure(candidate, "target_unknown")

    var policy_decision: MovementPolicyDecision = null
    var walk_terrain_ticks: int = 0
    if _is_walk_step(action.action_type):
        var terrain_types: Array[StringName] = _terrain_types(query_result.cells)
        if terrain_types.is_empty():
            return _candidate_failure(candidate, "terrain_unclassified")
        policy_decision = _policy.evaluate_step(action.actor_id, action.action_type, terrain_types)
        walk_terrain_ticks = _policy.terrain_walk_ticks(action.actor_id, terrain_types)
    else:
        policy_decision = _policy.evaluate_turn(action.actor_id, action.action_type)
    if policy_decision == null:
        return _candidate_failure(candidate, "movement_policy_not_ready")
    if not policy_decision.is_allowed():
        return _candidate_failure(candidate, _policy_reason(policy_decision))
    if _is_walk_step(action.action_type) and walk_terrain_ticks < 1:
        return _candidate_failure(candidate, "invalid_duration")

    candidate["ready"] = true
    candidate["current"] = current.copy()
    candidate["target_anchor"] = target_anchor
    candidate["target_facing"] = target_facing
    candidate["target_cells"] = query_result.cells.duplicate()
    candidate["walk_terrain_ticks"] = walk_terrain_ticks
    return candidate

func _prepare_run_stride(action: TimedAction, stride_index: int) -> Dictionary:
    var candidate: Dictionary = _candidate_base(action, stride_index)
    if not is_ready() or stride_index < 1 or stride_index > 2:
        return _candidate_failure(
            candidate,
            "movement_not_ready" if not is_ready() else "invalid_payload"
        )

    var origin: WorldPlacement = _expected_origin(action)
    if origin == null:
        return _candidate_failure(candidate, "invalid_payload")
    var target_facing: int = int(action.payload.get("target_facing", -1))
    if not Facing.is_valid(target_facing) or target_facing != origin.facing:
        return _candidate_failure(candidate, "invalid_payload")

    var stride_1_anchor: Vector2i = _anchor_from_payload(action.payload, "stride_1_anchor")
    var stride_2_anchor: Vector2i = _anchor_from_payload(action.payload, "stride_2_anchor")
    var forward: Vector2i = Facing.vector(origin.facing)
    if stride_1_anchor != origin.anchor + forward or stride_2_anchor != stride_1_anchor + forward:
        return _candidate_failure(candidate, "invalid_payload")

    var expected_current: WorldPlacement = origin.copy()
    expected_current.anchor = origin.anchor if stride_index == 1 else stride_1_anchor
    var target_anchor: Vector2i = stride_1_anchor if stride_index == 1 else stride_2_anchor
    var current: WorldPlacement = _world.placement(action.actor_id)
    if current == null or not current.equivalent(expected_current):
        return _candidate_failure(candidate, "origin_changed")

    var query_result: SpatialQueryResult = _query.query_entity_footprint(
        action.actor_id,
        target_anchor,
        target_facing,
        true
    )
    if query_result == null or query_result.status == QueryResultClass.Status.UNKNOWN:
        return _candidate_failure(candidate, "target_unknown")

    var terrain_key: String = "stride_%d_terrain" % stride_index
    var stored_terrain: Variant = action.payload.get(terrain_key, [])
    if typeof(stored_terrain) != TYPE_ARRAY or _terrain_snapshot(query_result.cells) != stored_terrain:
        return _candidate_failure(candidate, "terrain_changed")
    var walk_ticks: int = int(action.payload.get("stride_%d_walk_ticks" % stride_index, 0))
    if walk_ticks < 1:
        return _candidate_failure(candidate, "invalid_payload")

    candidate["current"] = current.copy()
    candidate["target_anchor"] = target_anchor
    candidate["target_facing"] = target_facing
    candidate["target_cells"] = query_result.cells.duplicate()
    candidate["walk_terrain_ticks"] = walk_ticks

    if query_result.status == QueryResultClass.Status.BLOCKED:
        candidate["impact"] = true
        candidate["reason"] = "run_impact"
        candidate["blocking_entity_ids"] = query_result.blocking_entity_ids.duplicate()
        return candidate
    if query_result.status != QueryResultClass.Status.CLEAR:
        return _candidate_failure(candidate, "target_unknown")

    candidate["ready"] = true
    return candidate

func _queue_timestamp_commit(candidate: Dictionary) -> bool:
    if candidate.is_empty() or not bool(candidate.get("ready", false)) or _kernel == null:
        return false
    if _pending_flush_event_serial <= 0:
        _pending_flush_event_serial = _kernel.schedule_event(
            _kernel.world_tick(),
            TIMESTAMP_BATCH_FLUSH_OWNER,
            TIMESTAMP_BATCH_FLUSH_EVENT,
            "",
            {},
            TIMESTAMP_BATCH_FLUSH_PRIORITY
        )
        if _pending_flush_event_serial <= 0:
            _pending_flush_event_serial = 0
            return false
    _pending_commits.append(candidate)
    return true

func _flush_timestamp_commits() -> void:
    if _pending_commits.is_empty():
        return

    var candidates: Array[Dictionary] = []
    for pending: Dictionary in _pending_commits:
        candidates.append(pending)
    _pending_commits.clear()
    candidates.sort_custom(_candidate_less)

    var eligible: Array[Dictionary] = []
    for candidate: Dictionary in candidates:
        var action: TimedAction = candidate.get("action", null)
        if action == null:
            continue
        var active: TimedAction = _kernel.active_action_for_actor(action.actor_id)
        if active == null or active.serial != action.serial:
            continue

        var current: WorldPlacement = _world.placement(action.actor_id)
        var expected_current: WorldPlacement = candidate.get("current", null)
        if current == null or expected_current == null or not current.equivalent(expected_current):
            candidate["ready"] = false
            candidate["reason"] = "origin_changed"
            eligible.append(candidate)
            continue

        var target_anchor: Vector2i = candidate.get("target_anchor", Vector2i.ZERO)
        var target_facing: int = int(candidate.get("target_facing", -1))
        var query_result: SpatialQueryResult = _query.query_entity_footprint(
            action.actor_id,
            target_anchor,
            target_facing,
            true
        )
        if query_result == null or query_result.status == QueryResultClass.Status.UNKNOWN:
            candidate["ready"] = false
            candidate["reason"] = "target_unknown"
        elif query_result.status == QueryResultClass.Status.BLOCKED:
            candidate["ready"] = false
            if action.action_type == RUN_FORWARD:
                candidate["impact"] = true
                candidate["reason"] = "run_impact"
                candidate["blocking_entity_ids"] = query_result.blocking_entity_ids.duplicate()
            else:
                candidate["reason"] = "target_blocked"
        elif query_result.status != QueryResultClass.Status.CLEAR:
            candidate["ready"] = false
            candidate["reason"] = "target_unknown"
        else:
            candidate["target_cells"] = query_result.cells.duplicate()
        eligible.append(candidate)

    var claims: Dictionary = {}
    for candidate: Dictionary in eligible:
        if not bool(candidate.get("ready", false)):
            continue
        var blocking_claimants: Dictionary = {}
        var target_cells: Array = candidate.get("target_cells", [])
        for value: Variant in target_cells:
            if typeof(value) != TYPE_VECTOR2I:
                continue
            var cell: Vector2i = value
            if claims.has(cell):
                blocking_claimants[String(claims[cell])] = true
        if not blocking_claimants.is_empty():
            candidate["ready"] = false
            var action: TimedAction = candidate.get("action", null)
            if action != null and action.action_type == RUN_FORWARD:
                candidate["impact"] = true
                candidate["reason"] = "run_impact"
                candidate["blocking_entity_ids"] = _sorted_string_keys(blocking_claimants)
            else:
                candidate["reason"] = "target_blocked"
            continue

        var actor_id: String = String(candidate.get("actor_id", ""))
        for value: Variant in target_cells:
            if typeof(value) == TYPE_VECTOR2I:
                claims[value] = actor_id

    var placement_batch: Array = []
    for candidate: Dictionary in eligible:
        if not bool(candidate.get("ready", false)):
            continue
        var current: WorldPlacement = candidate.get("current", null)
        if current == null:
            candidate["ready"] = false
            candidate["reason"] = "placement_mutation_failed"
            continue
        placement_batch.append(PlacementClass.new(
            String(candidate.get("actor_id", "")),
            current.channel,
            candidate.get("target_anchor", current.anchor),
            int(candidate.get("target_facing", current.facing)),
            current.footprint,
            current.structure_axis
        ))

    if not placement_batch.is_empty() and not _mutations.set_placements_batch(placement_batch):
        for candidate: Dictionary in eligible:
            if bool(candidate.get("ready", false)):
                candidate["ready"] = false
                candidate["reason"] = "placement_mutation_failed"

    for candidate: Dictionary in eligible:
        if bool(candidate.get("ready", false)):
            _emit_commit_success(candidate)
        elif bool(candidate.get("impact", false)):
            _emit_run_impact_failure(candidate)
        else:
            var action: TimedAction = candidate.get("action", null)
            if action != null:
                _fail_commit(action, String(candidate.get("reason", "movement_commit_failed")))

func _emit_commit_success(candidate: Dictionary) -> void:
    var action: TimedAction = candidate.get("action", null)
    if action == null:
        return
    var target_anchor: Vector2i = candidate.get("target_anchor", Vector2i.ZERO)
    var target_facing: int = int(candidate.get("target_facing", -1))
    var walk_ticks: int = int(candidate.get("walk_terrain_ticks", 0))
    var stride_index: int = int(candidate.get("stride_index", 0))

    if action.action_type == RUN_FORWARD:
        run_stride_committed.emit(
            action.actor_id,
            action.serial,
            stride_index,
            target_anchor,
            target_facing
        )
        movement_exertion_resolved.emit(
            action.actor_id,
            action.serial,
            RUN_FORWARD,
            stride_index,
            walk_ticks,
            false
        )
        if stride_index == 2:
            movement_committed.emit(
                action.actor_id,
                action.serial,
                action.action_type,
                target_anchor,
                target_facing
            )
        return

    if _is_walk_step(action.action_type):
        movement_exertion_resolved.emit(
            action.actor_id,
            action.serial,
            action.action_type,
            1,
            walk_ticks,
            false
        )
    movement_committed.emit(
        action.actor_id,
        action.serial,
        action.action_type,
        target_anchor,
        target_facing
    )

func _emit_run_impact_failure(candidate: Dictionary) -> void:
    var action: TimedAction = candidate.get("action", null)
    if action == null:
        return
    var stride_index: int = int(candidate.get("stride_index", 0))
    var target_anchor: Vector2i = candidate.get("target_anchor", Vector2i.ZERO)
    var target_facing: int = int(candidate.get("target_facing", -1))
    var walk_ticks: int = int(candidate.get("walk_terrain_ticks", 0))
    var blocking_entity_ids: Array = candidate.get("blocking_entity_ids", [])
    movement_exertion_resolved.emit(
        action.actor_id,
        action.serial,
        RUN_FORWARD,
        stride_index,
        walk_ticks,
        true
    )
    run_impact.emit(
        action.actor_id,
        action.serial,
        stride_index,
        target_anchor,
        target_facing,
        blocking_entity_ids.duplicate()
    )
    _fail_commit(action, "run_impact")

func _candidate_base(action: TimedAction, stride_index: int) -> Dictionary:
    return {
        "action": action.copy() if action != null else null,
        "actor_id": action.actor_id if action != null else "",
        "action_serial": action.serial if action != null else 0,
        "stride_index": stride_index,
        "ready": false,
        "impact": false,
        "reason": "",
        "blocking_entity_ids": [],
        "target_cells": [],
        "walk_terrain_ticks": 0,
    }

static func _candidate_failure(candidate: Dictionary, reason: String) -> Dictionary:
    candidate["ready"] = false
    candidate["impact"] = false
    candidate["reason"] = reason
    return candidate

func _remove_pending_action(action_serial: int) -> void:
    for index in range(_pending_commits.size() - 1, -1, -1):
        if int(_pending_commits[index].get("action_serial", 0)) == action_serial:
            _pending_commits.remove_at(index)

func _expected_origin(action: TimedAction) -> WorldPlacement:
    var expected_value: Variant = action.payload.get("expected_placement", {})
    if typeof(expected_value) != TYPE_DICTIONARY:
        return null
    var expected: WorldPlacement = PlacementClass.from_snapshot(expected_value)
    if expected == null or expected.entity_id != action.actor_id or expected.channel != Layers.Channel.ACTOR:
        return null
    return expected

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
    var terrain_types: Array[StringName] = _terrain_types(cells)
    if terrain_types.is_empty():
        return PolicyDecisionClass.denied(
            PolicyDecisionClass.Status.TERRAIN_UNCLASSIFIED,
            "terrain_unclassified"
        )
    return _policy.evaluate_step(actor_id, action_type, terrain_types)

func _terrain_types(cells: Array[Vector2i]) -> Array[StringName]:
    var terrain_types: Array[StringName] = []
    for cell: Vector2i in cells:
        if not _query.has_terrain(cell):
            return []
        terrain_types.append(_query.terrain_at(cell))
    return terrain_types

func _terrain_snapshot(cells: Array[Vector2i]) -> Array:
    var ordered: Array[Vector2i] = []
    for cell: Vector2i in cells:
        ordered.append(cell)
    ordered.sort_custom(_cell_less)
    var snapshot: Array = []
    for cell: Vector2i in ordered:
        if not _query.has_terrain(cell):
            return []
        snapshot.append([cell.x, cell.y, String(_query.terrain_at(cell))])
    return snapshot

static func _anchor_from_payload(payload: Dictionary, key: String) -> Vector2i:
    var value: Variant = payload.get(key, [])
    if typeof(value) != TYPE_ARRAY or value.size() != 2:
        return Vector2i(2147483647, 2147483647)
    return Vector2i(int(value[0]), int(value[1]))

static func _interruption_policy(action_type: StringName) -> int:
    if _is_walk_step(action_type):
        return TickRulesClass.InterruptionPolicy.CANCELABLE
    return TickRulesClass.InterruptionPolicy.COMMITTED

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

static func _is_walk_step(action_type: StringName) -> bool:
    return action_type == STEP_FORWARD or action_type == STEP_BACKWARD

static func _is_standard_movement_action(action_type: StringName) -> bool:
    return _is_walk_step(action_type) or action_type == TURN_LEFT or action_type == TURN_RIGHT

static func _is_movement_action(action_type: StringName) -> bool:
    return _is_standard_movement_action(action_type) or action_type == RUN_FORWARD

static func _candidate_less(a: Dictionary, b: Dictionary) -> bool:
    var actor_a: String = String(a.get("actor_id", ""))
    var actor_b: String = String(b.get("actor_id", ""))
    if actor_a != actor_b:
        return actor_a < actor_b
    var serial_a: int = int(a.get("action_serial", 0))
    var serial_b: int = int(b.get("action_serial", 0))
    if serial_a != serial_b:
        return serial_a < serial_b
    return int(a.get("stride_index", 0)) < int(b.get("stride_index", 0))

static func _sorted_string_keys(values: Dictionary) -> Array[String]:
    var result: Array[String] = []
    for key: Variant in values.keys():
        result.append(String(key))
    result.sort()
    return result

static func _cell_less(a: Vector2i, b: Vector2i) -> bool:
    if a.y == b.y:
        return a.x < b.x
    return a.y < b.y
