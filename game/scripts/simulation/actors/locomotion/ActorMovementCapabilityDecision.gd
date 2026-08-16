extends RefCounted
class_name ActorMovementCapabilityDecision

enum Status {
    ALLOWED,
    ACTOR_UNCLASSIFIED,
    CAPABILITY_UNKNOWN,
    CAPABILITY_BLOCKED,
    INVALID_DURATION,
}

var status: int = Status.CAPABILITY_UNKNOWN
var allowed: bool = false
var duration_ticks: int = 0
var reason: String = ""
var stance: StringName = &""

func is_allowed() -> bool:
    return status == Status.ALLOWED and allowed and duration_ticks > 0

func copy() -> ActorMovementCapabilityDecision:
    var result := ActorMovementCapabilityDecision.new()
    result.status = status
    result.allowed = allowed
    result.duration_ticks = duration_ticks
    result.reason = reason
    result.stance = stance
    return result

static func permitted(duration: int, actor_stance: StringName) -> ActorMovementCapabilityDecision:
    var result := ActorMovementCapabilityDecision.new()
    result.stance = actor_stance
    if duration < 1:
        result.status = Status.INVALID_DURATION
        result.reason = "invalid_duration"
        return result
    result.status = Status.ALLOWED
    result.allowed = true
    result.duration_ticks = duration
    return result

static func denied(
    denied_status: int,
    denied_reason: String,
    actor_stance: StringName = &""
) -> ActorMovementCapabilityDecision:
    var result := ActorMovementCapabilityDecision.new()
    result.status = denied_status
    result.reason = denied_reason
    result.stance = actor_stance
    return result
