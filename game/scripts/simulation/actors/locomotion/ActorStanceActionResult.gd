extends RefCounted
class_name ActorStanceActionResult

enum Status {
    ACCEPTED,
    NO_CHANGE,
    NOT_READY,
    ACTOR_MISSING,
    ACTOR_UNPLACED,
    NOT_ACTOR,
    ACTOR_UNCLASSIFIED,
    BUSY,
    CAPABILITY_UNKNOWN,
    CAPABILITY_BLOCKED,
    INVALID_DURATION,
    TIMING_REJECTED,
}

var status: int = Status.NOT_READY
var action_serial: int = 0
var action_type: StringName = &""
var target_stance: StringName = &""
var duration_ticks: int = 0
var reason: String = ""

func is_accepted() -> bool:
    return status == Status.ACCEPTED and action_serial > 0

func copy() -> ActorStanceActionResult:
    var result := ActorStanceActionResult.new()
    result.status = status
    result.action_serial = action_serial
    result.action_type = action_type
    result.target_stance = target_stance
    result.duration_ticks = duration_ticks
    result.reason = reason
    return result
