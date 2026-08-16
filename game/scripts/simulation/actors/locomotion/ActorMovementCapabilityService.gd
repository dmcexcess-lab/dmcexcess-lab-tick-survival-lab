extends RefCounted
class_name ActorMovementCapabilityService

const StanceRules = preload("res://scripts/simulation/actors/locomotion/ActorStance.gd")
const DecisionClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementCapabilityDecision.gd")
const ProviderClass = preload("res://scripts/simulation/actors/locomotion/ActorMobilityModifierProvider.gd")

## Composes locomotion stance plus deterministic read-only modifier providers.
## It never imports health, needs, inventory, equipment, skill, sound or perception state.

const SCALE_ONE: int = 10000
const STANDING_STEP_SCALE: int = 10000
const CROUCHED_STEP_SCALE: int = 14000
const STANDING_TURN_SCALE: int = 10000
const CROUCHED_TURN_SCALE: int = 10000
const STANCE_ACTION_SCALE: int = 10000

const STEP_FORWARD: StringName = &"movement.step_forward"
const STEP_BACKWARD: StringName = &"movement.step_backward"
const TURN_LEFT: StringName = &"movement.turn_left"
const TURN_RIGHT: StringName = &"movement.turn_right"
const RUN_FORWARD: StringName = &"movement.run_forward"
const CROUCH_ACTION: StringName = &"actor.stance.crouch"
const STAND_ACTION: StringName = &"actor.stance.stand"

var _state: ActorLocomotionState = null
var _providers: Dictionary = {}
var _provider_order: Array[String] = []

func _init(locomotion_state: ActorLocomotionState = null) -> void:
    _state = locomotion_state

func is_ready() -> bool:
    return _state != null

func register_provider(provider: ActorMobilityModifierProvider) -> bool:
    if provider == null or not provider.is_valid():
        return false
    var key: String = provider.provider_id()
    if _providers.has(key):
        return false
    _providers[key] = provider
    _provider_order.append(key)
    _provider_order.sort()
    return true

func remove_provider(provider_id: String) -> bool:
    var key: String = provider_id.strip_edges()
    if key.is_empty() or not _providers.has(key):
        return false
    _providers.erase(key)
    _provider_order.erase(key)
    return true

func provider_ids() -> Array[String]:
    return _provider_order.duplicate()

func evaluate(actor_id: String, action_type: StringName, base_duration_ticks: int) -> ActorMovementCapabilityDecision:
    if _state == null or not _state.has_actor(actor_id):
        return DecisionClass.denied(
            DecisionClass.Status.ACTOR_UNCLASSIFIED,
            "actor_unclassified"
        )
    if base_duration_ticks < 1:
        return DecisionClass.denied(
            DecisionClass.Status.INVALID_DURATION,
            "invalid_duration",
            _state.stance(actor_id)
        )

    var actor_stance: StringName = _state.stance(actor_id)
    if not StanceRules.is_valid(actor_stance):
        return DecisionClass.denied(
            DecisionClass.Status.CAPABILITY_UNKNOWN,
            "stance_unclassified",
            actor_stance
        )

    var stance_scale: int = _stance_scale(actor_stance, action_type)
    if stance_scale == 0:
        return DecisionClass.denied(
            DecisionClass.Status.CAPABILITY_BLOCKED,
            "stance_blocks_action",
            actor_stance
        )
    if stance_scale < 0:
        return DecisionClass.denied(
            DecisionClass.Status.CAPABILITY_UNKNOWN,
            "movement_action_unclassified",
            actor_stance
        )

    var combined_scale: int = stance_scale
    var first_unknown_reason: String = ""

    for provider_id: String in _provider_order:
        var provider: ActorMobilityModifierProvider = _providers[provider_id]
        var provider_result: Dictionary = provider.evaluate(actor_id, action_type)
        var provider_status: int = int(provider_result.get("status", -1))
        if not ProviderClass.is_valid_status(provider_status):
            if first_unknown_reason.is_empty():
                first_unknown_reason = "provider_invalid_result:%s" % provider_id
            continue

        if provider_status == ProviderClass.Status.BLOCKED:
            var blocked_reason: String = String(provider_result.get("reason", "")).strip_edges()
            if blocked_reason.is_empty():
                blocked_reason = "capability_blocked:%s" % provider_id
            return DecisionClass.denied(
                DecisionClass.Status.CAPABILITY_BLOCKED,
                blocked_reason,
                actor_stance
            )

        if provider_status == ProviderClass.Status.UNKNOWN:
            if first_unknown_reason.is_empty():
                first_unknown_reason = String(provider_result.get("reason", "")).strip_edges()
                if first_unknown_reason.is_empty():
                    first_unknown_reason = "capability_unknown:%s" % provider_id
            continue

        combined_scale += int(provider_result.get("duration_adjustment_bp", 0))

    if not first_unknown_reason.is_empty():
        return DecisionClass.denied(
            DecisionClass.Status.CAPABILITY_UNKNOWN,
            first_unknown_reason,
            actor_stance
        )

    if combined_scale <= 0:
        return DecisionClass.denied(
            DecisionClass.Status.INVALID_DURATION,
            "invalid_duration_scale",
            actor_stance
        )

    var resolved_duration: int = _ceil_scaled(base_duration_ticks, combined_scale)
    if resolved_duration < 1:
        return DecisionClass.denied(
            DecisionClass.Status.INVALID_DURATION,
            "invalid_duration",
            actor_stance
        )
    return DecisionClass.permitted(resolved_duration, actor_stance)

static func _stance_scale(actor_stance: StringName, action_type: StringName) -> int:
    if action_type == STEP_FORWARD or action_type == STEP_BACKWARD:
        return CROUCHED_STEP_SCALE if actor_stance == StanceRules.CROUCHED else STANDING_STEP_SCALE
    if action_type == TURN_LEFT or action_type == TURN_RIGHT:
        return CROUCHED_TURN_SCALE if actor_stance == StanceRules.CROUCHED else STANDING_TURN_SCALE
    if action_type == CROUCH_ACTION or action_type == STAND_ACTION:
        return STANCE_ACTION_SCALE
    if action_type == RUN_FORWARD:
        if actor_stance == StanceRules.CROUCHED:
            return 0
        return STANDING_STEP_SCALE
    return -1

static func _ceil_scaled(base_duration_ticks: int, scale_bp: int) -> int:
    if base_duration_ticks < 1 or scale_bp <= 0:
        return 0
    var product: int = base_duration_ticks * scale_bp
    var quotient: int = product / SCALE_ONE
    if product % SCALE_ONE != 0:
        quotient += 1
    return maxi(1, quotient)
