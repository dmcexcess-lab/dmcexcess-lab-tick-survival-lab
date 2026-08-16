extends RefCounted
class_name MovementPolicyDecision

## Typed result from a Movement traversal/timing policy.
## Movement owns collision/commit semantics; policies own traversal/capability timing decisions.

enum Status {
    ALLOWED,
    TERRAIN_UNCLASSIFIED,
    TERRAIN_BLOCKED,
    ACTOR_UNCLASSIFIED,
    CAPABILITY_UNKNOWN,
    CAPABILITY_BLOCKED,
    INVALID_DURATION,
}

var status: int = Status.INVALID_DURATION
var duration_ticks: int = 0
var reason: String = ""

func is_allowed() -> bool:
    return status == Status.ALLOWED and duration_ticks > 0

func copy() -> MovementPolicyDecision:
    var result := MovementPolicyDecision.new()
    result.status = status
    result.duration_ticks = duration_ticks
    result.reason = reason
    return result

static func allowed(duration: int) -> MovementPolicyDecision:
    var result := MovementPolicyDecision.new()
    if duration < 1:
        result.status = Status.INVALID_DURATION
        result.reason = "invalid_duration"
        return result
    result.status = Status.ALLOWED
    result.duration_ticks = duration
    return result

static func denied(denied_status: int, denied_reason: String) -> MovementPolicyDecision:
    var result := MovementPolicyDecision.new()
    if denied_status == Status.ALLOWED:
        result.status = Status.INVALID_DURATION
        result.reason = "invalid_policy_status"
        return result
    result.status = denied_status
    result.reason = denied_reason
    return result
