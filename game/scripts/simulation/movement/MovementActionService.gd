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
signal forced_displacement_resolved(source_actor_id, target_actor_id, source_action_serial, displaced, reason, target_anchor)

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
const CANDIDATE_MOVEMENT: StringName = &"movement"
const CANDIDATE_FORCED: StringName = &"forced_displacement"
const SHOVE_ACTION: StringName = &"combat.shove"
const HOLD_ACTION: StringName = &"physical.hold"
const MAX_PRESSURE_PROPAGATION_DEPTH: int = 32
const MAX_PRESSURE_PROPAGATION_PASSES: int = 64

var _world: WorldState = null
var _mutations: WorldMutationService = null
var _query: SpatialQueryService = null
var _kernel: TickKernel = null
var _policy: MovementTraversalPolicy = null
var _physical_contest: MovementPhysicalContestProvider = null
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

func configure_physical_contest(provider: MovementPhysicalContestProvider) -> bool:
    if provider == null or not provider.is_ready():
        return false
    _physical_contest = provider
    return true

func physical_contest_score(actor_id: String, action_type: StringName) -> int:
    if _physical_contest == null or not _physical_contest.is_ready():
        return -1
    var result: Dictionary = _physical_contest.score(actor_id, action_type)
    if int(result.get("status", MovementPhysicalContestProvider.Status.UNKNOWN)) != MovementPhysicalContestProvider.Status.KNOWN:
        return -1
    return maxi(0, int(result.get("score", -1)))

func queue_forced_displacement(
    source_actor_id: String,
    target_actor_id: String,
    source_action_serial: int,
    direction: Vector2i,
    source_score: int,
    resistance_score: int
) -> bool:
    if not is_ready() or source_actor_id.strip_edges().is_empty() or target_actor_id.strip_edges().is_empty()         or source_action_serial <= 0 or source_score < 0 or resistance_score < 0:
        return false
    if direction not in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
        return false
    var current: WorldPlacement = _world.placement(target_actor_id)
    if current == null or current.channel != Layers.Channel.ACTOR:
        return false
    var target_anchor: Vector2i = current.anchor + direction
    var query_result: SpatialQueryResult = _query.query_entity_footprint(
        target_actor_id,
        target_anchor,
        current.facing,
        true
    )
    if query_result == null or query_result.status == QueryResultClass.Status.UNKNOWN:
        forced_displacement_resolved.emit(
            source_actor_id, target_actor_id, source_action_serial, false, "displacement_unknown", current.anchor
        )
        return true

    var candidate: Dictionary = {
        "kind": CANDIDATE_FORCED,
        "action": null,
        "actor_id": target_actor_id,
        "action_serial": source_action_serial,
        "stride_index": 0,
        "ready": true,
        "impact": false,
        "reason": "",
        "blocking_entity_ids": [],
        "target_cells": query_result.cells.duplicate(),
        "walk_terrain_ticks": 0,
        "current": current.copy(),
        "target_anchor": target_anchor,
        "target_facing": current.facing,
        "source_actor_id": source_actor_id,
        "source_action_serial": source_action_serial,
        "physical_score": source_score,
        "resistance_score": resistance_score,
        "resistance_consumed": -1,
        "linked_candidate_index": -1,
        "blocking_resistance_scores": {},
        "pressure_resistance_scores": _freeze_pressure_resistance_line(target_actor_id, direction, resistance_score),
        "pressure_depth": 0,
        "pressure_residual_sent": 0,
        "pressure_path": [source_actor_id, target_actor_id],
        "report_resolution": true,
    }
    if query_result.status == QueryResultClass.Status.BLOCKED:
        if _has_only_actor_blockers(query_result):
            candidate["blocking_entity_ids"] = query_result.blocking_entity_ids.duplicate()
            var blocker_resistance: Dictionary = {}
            for blocker_id: String in query_result.blocking_entity_ids:
                blocker_resistance[blocker_id] = physical_contest_score(blocker_id, HOLD_ACTION)
            candidate["blocking_resistance_scores"] = blocker_resistance
        else:
            candidate["ready"] = false
            candidate["reason"] = "displacement_blocked"
    elif query_result.status != QueryResultClass.Status.CLEAR:
        candidate["ready"] = false
        candidate["reason"] = "displacement_unknown"
    return _queue_timestamp_candidate(candidate)

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
    var deferred_actor_occupancy: bool = _is_walk_step(action_type) and _has_only_actor_blockers(query_result)
    if not deferred_actor_occupancy and not _apply_query_failure(result, query_result):
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
        payload,
        duration_ticks if _is_walk_step(action_type) else -1
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
        if not _is_walk_step(action.action_type) or not _has_only_actor_blockers(query_result):
            return _candidate_failure(candidate, "target_blocked")
        candidate["blocking_entity_ids"] = query_result.blocking_entity_ids.duplicate()
    elif query_result.status != QueryResultClass.Status.CLEAR:
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
    var action: TimedAction = candidate.get("action", null)
    if action == null:
        return false
    candidate["physical_score"] = physical_contest_score(action.actor_id, action.action_type)
    candidate["contact_force_sent"] = 0
    if _candidate_changes_anchor(candidate):
        var current: WorldPlacement = candidate.get("current", null)
        var target_anchor: Vector2i = candidate.get("target_anchor", Vector2i.ZERO)
        if current != null:
            var direction: Vector2i = target_anchor - current.anchor
            candidate["pressure_resistance_scores"] = _freeze_pressure_resistance_line(
                action.actor_id,
                direction,
                physical_contest_score(action.actor_id, HOLD_ACTION)
            )
            candidate["pressure_path"] = [action.actor_id]
    return _queue_timestamp_candidate(candidate)

func _queue_timestamp_candidate(candidate: Dictionary) -> bool:
    if candidate.is_empty() or _kernel == null:
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

    # Re-read every trajectory against one unchanged pre-resolution occupancy.
    # Physical scores were frozen when each consequence entered this timestamp.
    var eligible: Array[Dictionary] = []
    for candidate: Dictionary in candidates:
        var kind: StringName = StringName(candidate.get("kind", CANDIDATE_MOVEMENT))
        var actor_id: String = String(candidate.get("actor_id", ""))
        if actor_id.is_empty():
            continue

        if kind == CANDIDATE_MOVEMENT:
            var action: TimedAction = candidate.get("action", null)
            if action == null:
                continue
            var active: TimedAction = _kernel.active_action_for_actor(action.actor_id)
            if active == null or active.serial != action.serial:
                continue
        elif kind != CANDIDATE_FORCED:
            continue

        var current: WorldPlacement = _world.placement(actor_id)
        var expected_current: WorldPlacement = candidate.get("current", null)
        if current == null or expected_current == null or not current.equivalent(expected_current):
            candidate["ready"] = false
            candidate["reason"] = "origin_changed"
            eligible.append(candidate)
            continue

        if not bool(candidate.get("ready", false)):
            eligible.append(candidate)
            continue

        var target_anchor: Vector2i = candidate.get("target_anchor", Vector2i.ZERO)
        var target_facing: int = int(candidate.get("target_facing", -1))
        var query_result: SpatialQueryResult = _query.query_entity_footprint(
            actor_id,
            target_anchor,
            target_facing,
            true
        )
        if query_result == null or query_result.status == QueryResultClass.Status.UNKNOWN:
            candidate["ready"] = false
            candidate["reason"] = "displacement_unknown" if kind == CANDIDATE_FORCED else "target_unknown"
        elif query_result.status == QueryResultClass.Status.BLOCKED:
            if _has_only_actor_blockers(query_result) and _candidate_changes_anchor(candidate):
                candidate["blocking_entity_ids"] = query_result.blocking_entity_ids.duplicate()
                candidate["target_cells"] = query_result.cells.duplicate()
            else:
                candidate["ready"] = false
                if kind == CANDIDATE_MOVEMENT:
                    var movement_action: TimedAction = candidate.get("action", null)
                    if movement_action != null and movement_action.action_type == RUN_FORWARD:
                        candidate["impact"] = true
                        candidate["reason"] = "run_impact"
                        candidate["blocking_entity_ids"] = query_result.blocking_entity_ids.duplicate()
                    else:
                        candidate["reason"] = "target_blocked"
                else:
                    candidate["reason"] = "displacement_blocked"
        elif query_result.status != QueryResultClass.Status.CLEAR:
            candidate["ready"] = false
            candidate["reason"] = "displacement_unknown" if kind == CANDIDATE_FORCED else "target_unknown"
        else:
            candidate["blocking_entity_ids"] = []
            candidate["target_cells"] = query_result.cells.duplicate()
        eligible.append(candidate)

    _resolve_actor_trajectory_conflicts(eligible)
    _propagate_pressure_bounded(eligible)
    _finalize_forced_hold_resistance(eligible)

    # Opposite traversal of one physical edge cannot pass through. Ordinary
    # walks collide head-on; forced displacement also cannot phase through a
    # body coming the other way until later push-chain mechanics can propagate
    # that pressure further.
    for left_index: int in range(eligible.size()):
        var left: Dictionary = eligible[left_index]
        if not bool(left.get("ready", false)) or not _candidate_changes_anchor(left):
            continue
        for right_index: int in range(left_index + 1, eligible.size()):
            var right: Dictionary = eligible[right_index]
            if not bool(right.get("ready", false)) or not _candidate_changes_anchor(right):
                continue
            if not _candidates_cross_same_edge(left, right):
                continue
            _mark_timestamp_conflict(
                left,
                "displacement_edge_conflict" if StringName(left.get("kind", CANDIDATE_MOVEMENT)) == CANDIDATE_FORCED else "movement_edge_conflict"
            )
            _mark_timestamp_conflict(
                right,
                "displacement_edge_conflict" if StringName(right.get("kind", CANDIDATE_MOVEMENT)) == CANDIDATE_FORCED else "movement_edge_conflict"
            )

    # Exclusive destination claims compare the already-frozen physical scores.
    var claims_by_cell: Dictionary = {}
    for index: int in range(eligible.size()):
        var candidate: Dictionary = eligible[index]
        if not bool(candidate.get("ready", false)) or not _candidate_changes_anchor(candidate):
            continue
        for value: Variant in candidate.get("target_cells", []):
            if typeof(value) != TYPE_VECTOR2I:
                continue
            var cell: Vector2i = value
            var claimants: Array = claims_by_cell.get(cell, [])
            claimants.append(index)
            claims_by_cell[cell] = claimants

    var candidate_scores: Dictionary = {}
    for index: int in range(eligible.size()):
        var candidate: Dictionary = eligible[index]
        if bool(candidate.get("ready", false)) and _candidate_changes_anchor(candidate):
            candidate_scores[index] = _physical_contest_score(candidate)

    var contested_losses: Dictionary = {}
    var contested_ties: Dictionary = {}
    for value: Variant in claims_by_cell.values():
        var claimants: Array = value
        if claimants.size() < 2:
            continue
        var best_score: int = -1
        var winners: Array[int] = []
        var all_known: bool = true
        for index_value: Variant in claimants:
            var index: int = int(index_value)
            var score_value: int = int(candidate_scores.get(index, -1))
            if score_value < 0:
                all_known = false
                break
            if score_value > best_score:
                best_score = score_value
                winners = [index]
            elif score_value == best_score:
                winners.append(index)
        if not all_known or winners.size() != 1:
            for index_value: Variant in claimants:
                contested_ties[int(index_value)] = true
            continue
        var winner: int = winners[0]
        for index_value: Variant in claimants:
            var index: int = int(index_value)
            if index != winner:
                contested_losses[index] = true

    for index_value: Variant in contested_ties.keys():
        var index: int = int(index_value)
        if index >= 0 and index < eligible.size():
            _mark_timestamp_conflict(eligible[index], "target_contest_tied")
    for index_value: Variant in contested_losses.keys():
        var index: int = int(index_value)
        if index >= 0 and index < eligible.size() and bool(eligible[index].get("ready", false)):
            _mark_timestamp_conflict(eligible[index], "target_contest_lost")

    # A claimed occupied cell is available only if its incoming occupant has a
    # surviving trajectory that actually releases those cells. Propagate failed
    # releases to a fixed point.
    var changed: bool = true
    while changed:
        changed = false
        var moving_by_actor: Dictionary = {}
        for candidate: Dictionary in eligible:
            if bool(candidate.get("ready", false)) and _candidate_changes_anchor(candidate):
                moving_by_actor[String(candidate.get("actor_id", ""))] = candidate

        for candidate: Dictionary in eligible:
            if not bool(candidate.get("ready", false)) or not _candidate_changes_anchor(candidate):
                continue
            var target_cells: Array = candidate.get("target_cells", [])
            for blocker_value: Variant in candidate.get("blocking_entity_ids", []):
                var blocker_id: String = String(blocker_value)
                if not moving_by_actor.has(blocker_id):
                    _mark_timestamp_conflict(
                        candidate,
                        "displacement_blocked" if StringName(candidate.get("kind", CANDIDATE_MOVEMENT)) == CANDIDATE_FORCED else "target_blocked"
                    )
                    changed = true
                    break
                var blocker: Dictionary = moving_by_actor[blocker_id]
                if _candidate_final_cells_overlap(blocker, target_cells):
                    _mark_timestamp_conflict(
                        candidate,
                        "displacement_blocked" if StringName(candidate.get("kind", CANDIDATE_MOVEMENT)) == CANDIDATE_FORCED else "target_blocked"
                    )
                    changed = true
                    break

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

    for index: int in range(eligible.size()):
        var candidate: Dictionary = eligible[index]
        var kind: StringName = StringName(candidate.get("kind", CANDIDATE_MOVEMENT))
        if kind == CANDIDATE_FORCED:
            if bool(candidate.get("report_resolution", true)):
                var displaced: bool = _candidate_or_link_succeeded(eligible, index)
                _emit_forced_displacement(candidate, displaced)
            continue
        if bool(candidate.get("ready", false)):
            _emit_commit_success(candidate)
        elif bool(candidate.get("impact", false)):
            _emit_run_impact_failure(candidate)
        else:
            var action: TimedAction = candidate.get("action", null)
            if action != null:
                _fail_commit(action, String(candidate.get("reason", "movement_commit_failed")))

func _resolve_actor_trajectory_conflicts(
    candidates: Array[Dictionary],
    only_actor_id: String = ""
) -> void:
    var by_actor: Dictionary = {}
    for index: int in range(candidates.size()):
        var candidate: Dictionary = candidates[index]
        if not bool(candidate.get("ready", false)) or not _candidate_changes_anchor(candidate):
            continue
        var actor_id: String = String(candidate.get("actor_id", ""))
        if not only_actor_id.is_empty() and actor_id != only_actor_id:
            continue
        var indexes: Array = by_actor.get(actor_id, [])
        indexes.append(index)
        by_actor[actor_id] = indexes

    for actor_id: String in _sorted_string_keys(by_actor):
        var indexes: Array = by_actor[actor_id]
        var movement_indexes: Array[int] = []
        var forced_indexes: Array[int] = []
        for index_value: Variant in indexes:
            var index: int = int(index_value)
            var candidate: Dictionary = candidates[index]
            if StringName(candidate.get("kind", CANDIDATE_MOVEMENT)) == CANDIDATE_FORCED:
                forced_indexes.append(index)
            else:
                movement_indexes.append(index)
        if forced_indexes.is_empty():
            continue
        if movement_indexes.size() > 1:
            for index: int in movement_indexes:
                _mark_timestamp_conflict(candidates[index], "trajectory_conflict")
            movement_indexes.clear()

        var force_right: int = 0
        var force_left: int = 0
        var force_down: int = 0
        var force_up: int = 0
        var unknown_force: bool = false
        var direction_by_index: Dictionary = {}
        for index: int in forced_indexes:
            var candidate: Dictionary = candidates[index]
            var score_value: int = _physical_contest_score(candidate)
            var direction: Vector2i = _forced_direction(candidate)
            if score_value < 0 or direction == Vector2i.ZERO:
                unknown_force = true
                break
            direction_by_index[index] = direction
            match direction:
                Vector2i.RIGHT:
                    force_right += score_value
                Vector2i.LEFT:
                    force_left += score_value
                Vector2i.DOWN:
                    force_down += score_value
                Vector2i.UP:
                    force_up += score_value

        if unknown_force:
            for index: int in forced_indexes:
                _mark_timestamp_conflict(candidates[index], "displacement_force_unknown")
            continue

        var net_x: int = force_right - force_left
        var net_y: int = force_down - force_up
        var abs_x: int = absi(net_x)
        var abs_y: int = absi(net_y)
        if (abs_x == 0 and abs_y == 0) or (abs_x > 0 and abs_x == abs_y):
            for index: int in forced_indexes:
                _mark_timestamp_conflict(candidates[index], "displacement_force_tied")
            continue

        var winning_direction: Vector2i = Vector2i.ZERO
        var net_force: int = 0
        if abs_x > abs_y:
            winning_direction = Vector2i.RIGHT if net_x > 0 else Vector2i.LEFT
            net_force = abs_x
        else:
            winning_direction = Vector2i.DOWN if net_y > 0 else Vector2i.UP
            net_force = abs_y

        var representative: int = -1
        for index: int in forced_indexes:
            if direction_by_index.get(index, Vector2i.ZERO) == winning_direction:
                representative = index
                break
        if representative < 0:
            for index: int in forced_indexes:
                _mark_timestamp_conflict(candidates[index], "displacement_force_tied")
            continue

        candidates[representative]["physical_score"] = net_force
        candidates[representative]["resistance_consumed"] = -1
        for index: int in forced_indexes:
            if index == representative:
                continue
            if direction_by_index.get(index, Vector2i.ZERO) == winning_direction:
                candidates[index]["ready"] = false
                candidates[index]["reason"] = "pressure_aggregated"
                candidates[index]["linked_candidate_index"] = representative
            else:
                _mark_timestamp_conflict(candidates[index], "displacement_force_lost")

        var forced: Dictionary = candidates[representative]
        if movement_indexes.is_empty():
            # Hold resistance is finalized after one-step pressure propagation so
            # an individually weak downstream shove can combine with transmitted
            # residual force before the outgoing trajectory is decided.
            continue

        var movement_index: int = movement_indexes[0]
        var movement: Dictionary = candidates[movement_index]
        var movement_score: int = _physical_contest_score(movement)
        if movement.get("target_anchor", Vector2i.ZERO) == forced.get("target_anchor", Vector2i.ZERO):
            movement["physical_score"] = maxi(0, movement_score) + net_force
            forced["ready"] = false
            forced["reason"] = "displacement_aligned"
            forced["linked_candidate_index"] = movement_index
            continue
        if movement_score < 0 or movement_score == net_force:
            _mark_timestamp_conflict(movement, "trajectory_contest_tied")
            _mark_timestamp_conflict(forced, "trajectory_contest_tied")
        elif net_force > movement_score:
            forced["resistance_consumed"] = movement_score
            _mark_timestamp_conflict(movement, "shoved")
        else:
            _mark_timestamp_conflict(forced, "target_trajectory_won")

func _propagate_pressure_bounded(candidates: Array[Dictionary]) -> void:
    # Pressure is solved as bounded waves. Ordinary movement contact contributes
    # body force without requiring AI to choose a special crowd action. Newly
    # aggregated/aligned force sends only its unsent delta forward, preventing
    # repeated amplification while still allowing longer packed chains.
    var pass_index: int = 0
    while pass_index < MAX_PRESSURE_PROPAGATION_PASSES:
        pass_index += 1
        var initial_size: int = candidates.size()
        var affected_actors: Dictionary = {}
        var additions: Array[Dictionary] = []

        for index: int in range(initial_size):
            var candidate: Dictionary = candidates[index]
            if not bool(candidate.get("ready", false)) or not _candidate_changes_anchor(candidate):
                continue

            var kind: StringName = StringName(candidate.get("kind", CANDIDATE_MOVEMENT))
            if kind == CANDIDATE_MOVEMENT:
                var movement_delta: int = _movement_contact_force_delta(candidate)
                if movement_delta <= 0:
                    continue
                var movement_blockers: Array = candidate.get("blocking_entity_ids", [])
                if movement_blockers.size() != 1:
                    continue
                var blocker_id: String = String(movement_blockers[0])
                if blocker_id.is_empty():
                    continue
                var current: WorldPlacement = candidate.get("current", null)
                if current == null:
                    continue
                var direction: Vector2i = _candidate_direction(candidate)
                if direction == Vector2i.ZERO:
                    continue
                var pressure_path: Array = candidate.get("pressure_path", [String(candidate.get("actor_id", ""))]).duplicate()
                if blocker_id in pressure_path or pressure_path.size() >= MAX_PRESSURE_PROPAGATION_DEPTH + 1:
                    continue
                var blocker: WorldPlacement = _world.placement(blocker_id)
                if blocker == null or blocker.channel != Layers.Channel.ACTOR:
                    continue
                var frozen: Dictionary = candidate.get("pressure_resistance_scores", {})
                var blocker_resistance: int = int(frozen.get(blocker_id, -1))
                if blocker_resistance < 0:
                    continue
                candidate["contact_force_sent"] = int(candidate.get("contact_force_sent", 0)) + movement_delta
                var propagated: Dictionary = _forced_candidate_for_pressure(
                    candidate,
                    blocker,
                    direction,
                    movement_delta,
                    blocker_resistance
                )
                if propagated.is_empty():
                    continue
                additions.append(propagated)
                affected_actors[blocker_id] = true
                continue

            if kind != CANDIDATE_FORCED:
                continue
            var forced_delta: int = _forced_residual_delta(candidate)
            if forced_delta <= 0:
                continue
            var blockers: Array = candidate.get("blocking_entity_ids", [])
            if blockers.size() != 1:
                continue
            var blocker_id: String = String(blockers[0])
            var pressure_path: Array = candidate.get("pressure_path", []).duplicate()
            if blocker_id.is_empty() or blocker_id in pressure_path                 or int(candidate.get("pressure_depth", 0)) >= MAX_PRESSURE_PROPAGATION_DEPTH:
                continue
            var blocker: WorldPlacement = _world.placement(blocker_id)
            if blocker == null or blocker.channel != Layers.Channel.ACTOR:
                continue
            var frozen: Dictionary = candidate.get("pressure_resistance_scores", {})
            var blocker_resistance: int = int(frozen.get(blocker_id, -1))
            if blocker_resistance < 0:
                continue
            candidate["pressure_residual_sent"] = int(candidate.get("pressure_residual_sent", 0)) + forced_delta
            var direction: Vector2i = _forced_direction(candidate)
            var propagated: Dictionary = _forced_candidate_for_pressure(
                candidate,
                blocker,
                direction,
                forced_delta,
                blocker_resistance
            )
            if propagated.is_empty():
                continue
            additions.append(propagated)
            affected_actors[blocker_id] = true

        if additions.is_empty():
            return
        for addition: Dictionary in additions:
            candidates.append(addition)
        for actor_id: String in _sorted_string_keys(affected_actors):
            _resolve_actor_trajectory_conflicts(candidates, actor_id)

func _movement_contact_force_delta(candidate: Dictionary) -> int:
    var score_value: int = _physical_contest_score(candidate)
    var sent: int = int(candidate.get("contact_force_sent", 0))
    return maxi(0, score_value - sent)

func _forced_residual_delta(candidate: Dictionary) -> int:
    var force_value: int = _physical_contest_score(candidate)
    var consumed: int = int(candidate.get("resistance_consumed", -1))
    if consumed < 0:
        consumed = int(candidate.get("resistance_score", -1))
    var residual: int = maxi(0, force_value - maxi(0, consumed))
    var sent: int = int(candidate.get("pressure_residual_sent", 0))
    return maxi(0, residual - sent)

func _forced_candidate_for_pressure(
    source_candidate: Dictionary,
    current: WorldPlacement,
    direction: Vector2i,
    source_score: int,
    resistance_score: int
) -> Dictionary:
    var target_anchor: Vector2i = current.anchor + direction
    var query_result: SpatialQueryResult = _query.query_entity_footprint(
        current.entity_id,
        target_anchor,
        current.facing,
        true
    )
    if query_result == null or query_result.status == QueryResultClass.Status.UNKNOWN:
        return {}

    var propagated: Dictionary = {
        "kind": CANDIDATE_FORCED,
        "action": null,
        "actor_id": current.entity_id,
        "action_serial": int(source_candidate.get("action_serial", 0)),
        "stride_index": 0,
        "ready": true,
        "impact": false,
        "reason": "",
        "blocking_entity_ids": [],
        "target_cells": query_result.cells.duplicate(),
        "walk_terrain_ticks": 0,
        "current": current.copy(),
        "target_anchor": target_anchor,
        "target_facing": current.facing,
        "source_actor_id": String(source_candidate.get("source_actor_id", "")),
        "source_action_serial": int(source_candidate.get("source_action_serial", 0)),
        "physical_score": source_score,
        "resistance_score": resistance_score,
        "resistance_consumed": -1,
        "linked_candidate_index": -1,
        "blocking_resistance_scores": {},
        "pressure_resistance_scores": source_candidate.get("pressure_resistance_scores", {}).duplicate(true),
        "pressure_depth": int(source_candidate.get("pressure_depth", 0)) + 1,
        "pressure_residual_sent": 0,
        "pressure_path": _extended_pressure_path(source_candidate, current.entity_id),
        "report_resolution": false,
    }

    if query_result.status == QueryResultClass.Status.BLOCKED:
        if _has_only_actor_blockers(query_result):
            propagated["blocking_entity_ids"] = query_result.blocking_entity_ids.duplicate()
        else:
            propagated["ready"] = false
            propagated["reason"] = "pressure_blocked_static"
    elif query_result.status != QueryResultClass.Status.CLEAR:
        propagated["ready"] = false
        propagated["reason"] = "displacement_unknown"
    return propagated

func _finalize_forced_hold_resistance(candidates: Array[Dictionary]) -> void:
    for candidate: Dictionary in candidates:
        if StringName(candidate.get("kind", CANDIDATE_MOVEMENT)) != CANDIDATE_FORCED             or not bool(candidate.get("ready", false)):
            continue
        if int(candidate.get("resistance_consumed", -1)) >= 0:
            continue
        var force_value: int = _physical_contest_score(candidate)
        var resistance: int = int(candidate.get("resistance_score", -1))
        if resistance < 0 or force_value <= resistance:
            _mark_timestamp_conflict(
                candidate,
                "displacement_force_tied" if force_value == resistance else "displacement_resisted"
            )

static func _forced_direction(candidate: Dictionary) -> Vector2i:
    var current: WorldPlacement = candidate.get("current", null)
    if current == null:
        return Vector2i.ZERO
    var target_anchor: Vector2i = candidate.get("target_anchor", current.anchor)
    var direction: Vector2i = target_anchor - current.anchor
    if direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
        return direction
    return Vector2i.ZERO

func _candidate_or_link_succeeded(candidates: Array[Dictionary], start_index: int) -> bool:
    var index: int = start_index
    var visited: Dictionary = {}
    while index >= 0 and index < candidates.size() and not visited.has(index):
        visited[index] = true
        var candidate: Dictionary = candidates[index]
        if bool(candidate.get("ready", false)):
            return true
        index = int(candidate.get("linked_candidate_index", -1))
    return false

func _emit_forced_displacement(candidate: Dictionary, displaced: bool) -> void:
    var target_id: String = String(candidate.get("actor_id", ""))
    var source_id: String = String(candidate.get("source_actor_id", ""))
    var source_serial: int = int(candidate.get("source_action_serial", 0))
    var target_anchor: Vector2i = candidate.get("target_anchor", Vector2i.ZERO)
    var reason: String = "" if displaced else String(candidate.get("reason", "displacement_failed"))
    if displaced:
        var active: TimedAction = _kernel.active_action_for_actor(target_id)
        if active != null:
            _kernel.interrupt_action(active.serial, "shoved")
    forced_displacement_resolved.emit(source_id, target_id, source_serial, displaced, reason, target_anchor)

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

func _freeze_pressure_resistance_line(
    source_actor_id: String,
    direction: Vector2i,
    source_resistance: int = -1
) -> Dictionary:
    var result: Dictionary = {}
    if source_actor_id.strip_edges().is_empty()         or direction not in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
        return result

    var current_id: String = source_actor_id
    var visited: Dictionary = {}
    var depth: int = 0
    while depth <= MAX_PRESSURE_PROPAGATION_DEPTH:
        if current_id.is_empty() or visited.has(current_id):
            break
        visited[current_id] = true
        var resistance: int = source_resistance if depth == 0 and source_resistance >= 0             else physical_contest_score(current_id, HOLD_ACTION)
        if resistance < 0:
            break
        result[current_id] = resistance

        var placement: WorldPlacement = _world.placement(current_id)
        if placement == null or placement.channel != Layers.Channel.ACTOR:
            break
        var query_result: SpatialQueryResult = _query.query_entity_footprint(
            current_id,
            placement.anchor + direction,
            placement.facing,
            true
        )
        if query_result == null or not _has_only_actor_blockers(query_result)             or query_result.blocking_entity_ids.size() != 1:
            break
        current_id = String(query_result.blocking_entity_ids[0])
        depth += 1
    return result

static func _extended_pressure_path(source_candidate: Dictionary, actor_id: String) -> Array:
    var result: Array = source_candidate.get("pressure_path", []).duplicate()
    if not actor_id.is_empty() and actor_id not in result:
        result.append(actor_id)
    return result

static func _candidate_direction(candidate: Dictionary) -> Vector2i:
    var current: WorldPlacement = candidate.get("current", null)
    if current == null:
        return Vector2i.ZERO
    var target_anchor: Vector2i = candidate.get("target_anchor", current.anchor)
    var direction: Vector2i = target_anchor - current.anchor
    if direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
        return direction
    return Vector2i.ZERO

func _physical_contest_score(candidate: Dictionary) -> int:
    return int(candidate.get("physical_score", -1))

func _has_only_actor_blockers(query_result: SpatialQueryResult) -> bool:
    if query_result == null or query_result.status != QueryResultClass.Status.BLOCKED         or query_result.blocking_entity_ids.is_empty()         or not query_result.missing_terrain_cells.is_empty()         or not query_result.unclassified_entity_ids.is_empty():
        return false
    for blocker_id: String in query_result.blocking_entity_ids:
        var placement: WorldPlacement = _world.placement(blocker_id)
        if placement == null or placement.channel != Layers.Channel.ACTOR:
            return false
    return true

static func _candidate_changes_anchor(candidate: Dictionary) -> bool:
    var current: WorldPlacement = candidate.get("current", null)
    if current == null:
        return false
    return candidate.get("target_anchor", current.anchor) != current.anchor

static func _candidates_cross_same_edge(left: Dictionary, right: Dictionary) -> bool:
    var left_current: WorldPlacement = left.get("current", null)
    var right_current: WorldPlacement = right.get("current", null)
    if left_current == null or right_current == null:
        return false
    var left_target: Vector2i = left.get("target_anchor", left_current.anchor)
    var right_target: Vector2i = right.get("target_anchor", right_current.anchor)
    return left_target == right_current.anchor and right_target == left_current.anchor

static func _candidate_final_cells_overlap(candidate: Dictionary, cells: Array) -> bool:
    var current: WorldPlacement = candidate.get("current", null)
    if current == null or current.footprint == null:
        return true
    var target_anchor: Vector2i = candidate.get("target_anchor", current.anchor)
    var target_facing: int = int(candidate.get("target_facing", current.facing))
    var final_cells: Array[Vector2i] = current.footprint.world_cells(target_anchor, target_facing)
    for cell_value: Variant in cells:
        if typeof(cell_value) == TYPE_VECTOR2I and cell_value in final_cells:
            return true
    return false

func _mark_timestamp_conflict(candidate: Dictionary, reason: String) -> void:
    candidate["ready"] = false
    var action: TimedAction = candidate.get("action", null)
    if action != null and action.action_type == RUN_FORWARD:
        candidate["impact"] = true
        candidate["reason"] = "run_impact"
    else:
        candidate["impact"] = false
        candidate["reason"] = reason

func _candidate_base(action: TimedAction, stride_index: int) -> Dictionary:
    return {
        "kind": CANDIDATE_MOVEMENT,
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
        "physical_score": -1,
        "resistance_score": -1,
        "resistance_consumed": -1,
        "linked_candidate_index": -1,
        "blocking_resistance_scores": {},
        "pressure_resistance_scores": {},
        "pressure_depth": 0,
        "pressure_residual_sent": 0,
        "pressure_path": [],
        "contact_force_sent": 0,
        "report_resolution": true,
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
