extends RefCounted
class_name ItemTransferTimingDecision

enum Status {
    ALLOWED,
    ACTION_UNCLASSIFIED,
    ACTOR_UNCLASSIFIED,
    CAPABILITY_UNKNOWN,
    CAPABILITY_BLOCKED,
    INVALID_DURATION,
}

var status: int = Status.ACTION_UNCLASSIFIED
var duration_ticks: int = 0
var reason: String = ""

func is_allowed() -> bool:
    return status == Status.ALLOWED and duration_ticks > 0

static func allowed(duration: int) -> ItemTransferTimingDecision:
    var result := ItemTransferTimingDecision.new()
    result.status = Status.ALLOWED
    result.duration_ticks = duration
    return result

static func denied(denied_status: int, denied_reason: String) -> ItemTransferTimingDecision:
    var result := ItemTransferTimingDecision.new()
    result.status = denied_status
    result.reason = denied_reason
    return result
