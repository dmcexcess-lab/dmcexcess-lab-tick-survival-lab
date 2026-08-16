extends RefCounted
class_name ActorStanceActionService

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const StanceRules = preload("res://scripts/simulation/actors/locomotion/ActorStance.gd")
const ResultClass = preload("res://scripts/simulation/actors/locomotion/ActorStanceActionResult.gd")
const CapabilityDecisionClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementCapabilityDecision.gd")
const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRulesClass = preload("res://scripts/foundation/time/TickRules.gd")

## Timed voluntary crouch/stand owner. It changes locomotion state only at commit.

signal stance_committed(actor_id, action_serial, previous_stance, new_stance, version)
signal stance_failed(actor_id, action_serial, target_stance, reason)

const CROUCH_ACTION: StringName = &"actor.stance.crouch"
const STAND_ACTION: StringName = &"actor.stance.stand"
const COMMIT_PHASE: StringName = &"actor.stance.commit"
const BASE_STANCE_TICKS: int = 4

var _world: WorldState = null
var _state: ActorLocomotionState = null
var _mutations: ActorLocomotionMutationService = null
var _kernel: TickKernel = null
var _capability: ActorMovementCapabilityService = null

func _init(
    world_state: WorldState = null,
    locomotion_state: ActorLocomotionState = null,
    mutation_service: ActorLocomotionMutationService = null,
    tick_kernel: TickKernel = null,
    capability_service: ActorMovementCapabilityService = null
) -> void:
    _world = world_state
    _state = locomotion_state
    _mutations = mutation_service
    _kernel = tick_kernel
    _capability = capability_service
    if _kernel != null and not _kernel.action_phase.is_connected(_on_action_phase):
        _kernel.action_phase.connect(_on_action_phase)

func is_ready() -> bool:
    return _world != null \
        and _state != null \
        and _mutations != null and _mutations.is_ready() \
        and _kernel != null \
        and _capability != null and _capability.is_ready()

func request_crouch(actor_id: String) -> ActorStanceActionResult:
    return _request(actor_id, StanceRules.CROUCHED, CROUCH_ACTION)

func request_stand(actor_id: String) -> ActorStanceActionResult:
    return _request(actor_id, StanceRules.STANDING, STAND_ACTION)

func _request(
    actor_id: String,
    target_stance: StringName,
    action_type: StringName
) -> ActorStanceActionResult:
    var result := ResultClass.new()
    result.action_type = action_type
    result.target_stance = target_stance
    if not is_ready():
        result.status = ResultClass.Status.NOT_READY
        result.reason = "stance_service_not_ready"
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
    var placement: WorldPlacement = _world.placement(normalized_actor)
    if placement == null:
        result.status = ResultClass.Status.ACTOR_UNPLACED
        result.reason = "actor_unplaced"
        return result
    if placement.channel != Layers.Channel.ACTOR:
        result.status = ResultClass.Status.NOT_ACTOR
        result.reason = "not_actor_placement"
        return result
    if not _state.has_actor(normalized_actor):
        result.status = ResultClass.Status.ACTOR_UNCLASSIFIED
        result.reason = "actor_unclassified"
        return result
    if _kernel.has_active_action(normalized_actor):
        result.status = ResultClass.Status.BUSY
        result.reason = "actor_busy"
        return result

    var current: ActorLocomotionRecord = _state.record(normalized_actor)
    if current == null:
        result.status = ResultClass.Status.ACTOR_UNCLASSIFIED
        result.reason = "actor_unclassified"
        return result
    if current.stance == target_stance:
        result.status = ResultClass.Status.NO_CHANGE
        result.reason = "stance_unchanged"
        return result

    var capability_decision: ActorMovementCapabilityDecision = _capability.evaluate(
        normalized_actor,
        action_type,
        BASE_STANCE_TICKS
    )
    if capability_decision == null:
        result.status = ResultClass.Status.CAPABILITY_UNKNOWN
        result.reason = "capability_unknown"
        return result
    if not capability_decision.is_allowed():
        result.status = _result_status_for_capability(capability_decision.status)
        result.reason = _capability_reason(capability_decision)
        return result

    var duration_ticks: int = capability_decision.duration_ticks
    if duration_ticks < 1:
        result.status = ResultClass.Status.INVALID_DURATION
        result.reason = "invalid_duration"
        return result

    var phases: Array[ActionPhase] = [PhaseClass.new(COMMIT_PHASE, duration_ticks)]
    var payload: Dictionary = {
        "expected_version": current.version,
        "source_stance": String(current.stance),
        "target_stance": String(target_stance),
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
    return result

func _on_action_phase(action: TimedAction, phase: ActionPhase) -> void:
    if action == null or phase == null:
        return
    if phase.phase_id != COMMIT_PHASE or not _is_stance_action(action.action_type):
        return
    _commit_action(action)

func _commit_action(action: TimedAction) -> void:
    if not is_ready():
        _fail_commit(action, &"", "stance_service_not_ready")
        return
    if not _world.has_entity(action.actor_id):
        _fail_commit(action, _payload_target_stance(action), "actor_missing")
        return
    if not _world.has_placement(action.actor_id):
        _fail_commit(action, _payload_target_stance(action), "actor_unplaced")
        return
    var placement: WorldPlacement = _world.placement(action.actor_id)
    if placement == null or placement.channel != Layers.Channel.ACTOR:
        _fail_commit(action, _payload_target_stance(action), "not_actor_placement")
        return

    var current: ActorLocomotionRecord = _state.record(action.actor_id)
    if current == null:
        _fail_commit(action, _payload_target_stance(action), "actor_unclassified")
        return

    var expected_version: int = int(action.payload.get("expected_version", 0))
    var source_stance := StringName(String(action.payload.get("source_stance", "")))
    var target_stance := StringName(String(action.payload.get("target_stance", "")))
    if expected_version < 1 \
        or not StanceRules.is_valid(source_stance) \
        or not StanceRules.is_valid(target_stance) \
        or source_stance == target_stance:
        _fail_commit(action, target_stance, "invalid_payload")
        return
    if current.version != expected_version or current.stance != source_stance:
        _fail_commit(action, target_stance, "locomotion_state_changed")
        return

    var expected_action: StringName = CROUCH_ACTION if target_stance == StanceRules.CROUCHED else STAND_ACTION
    if action.action_type != expected_action:
        _fail_commit(action, target_stance, "invalid_payload")
        return

    var capability_decision: ActorMovementCapabilityDecision = _capability.evaluate(
        action.actor_id,
        action.action_type,
        BASE_STANCE_TICKS
    )
    if capability_decision == null or not capability_decision.is_allowed():
        _fail_commit(action, target_stance, _capability_reason(capability_decision))
        return

    if not _mutations.set_stance(action.actor_id, target_stance):
        _fail_commit(action, target_stance, "stance_mutation_failed")
        return

    var updated: ActorLocomotionRecord = _state.record(action.actor_id)
    if updated == null:
        _fail_commit(action, target_stance, "stance_mutation_failed")
        return
    stance_committed.emit(
        action.actor_id,
        action.serial,
        source_stance,
        target_stance,
        updated.version
    )

func _fail_commit(action: TimedAction, target_stance: StringName, reason: String) -> void:
    if action == null:
        return
    _kernel.fail_action(action.serial, reason)
    stance_failed.emit(action.actor_id, action.serial, target_stance, reason)

static func _result_status_for_capability(capability_status: int) -> int:
    match capability_status:
        CapabilityDecisionClass.Status.ACTOR_UNCLASSIFIED:
            return ResultClass.Status.ACTOR_UNCLASSIFIED
        CapabilityDecisionClass.Status.CAPABILITY_BLOCKED:
            return ResultClass.Status.CAPABILITY_BLOCKED
        CapabilityDecisionClass.Status.INVALID_DURATION:
            return ResultClass.Status.INVALID_DURATION
        _:
            return ResultClass.Status.CAPABILITY_UNKNOWN

static func _capability_reason(decision: ActorMovementCapabilityDecision) -> String:
    if decision == null:
        return "capability_unknown"
    if not decision.reason.is_empty():
        return decision.reason
    match decision.status:
        CapabilityDecisionClass.Status.ACTOR_UNCLASSIFIED:
            return "actor_unclassified"
        CapabilityDecisionClass.Status.CAPABILITY_BLOCKED:
            return "capability_blocked"
        CapabilityDecisionClass.Status.INVALID_DURATION:
            return "invalid_duration"
        _:
            return "capability_unknown"

static func _payload_target_stance(action: TimedAction) -> StringName:
    if action == null:
        return &""
    return StringName(String(action.payload.get("target_stance", "")))

static func _is_stance_action(action_type: StringName) -> bool:
    return action_type == CROUCH_ACTION or action_type == STAND_ACTION
