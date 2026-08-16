extends RefCounted
class_name MovementActionResult

## Immutable-style semantic result for a movement request.

enum Status {
    ACCEPTED,
    NOT_READY,
    ACTOR_MISSING,
    ACTOR_UNPLACED,
    NOT_ACTOR,
    BUSY,
    TARGET_BLOCKED,
    TARGET_UNKNOWN,
    TERRAIN_UNCLASSIFIED,
    TERRAIN_BLOCKED,
    INVALID_DURATION,
    TIMING_REJECTED,
}

var status: int = Status.NOT_READY
var action_serial: int = 0
var action_type: StringName = &""
var duration_ticks: int = 0
var target_anchor: Vector2i = Vector2i.ZERO
var target_facing: int = -1
var reason: String = ""

func is_accepted() -> bool:
    return status == Status.ACCEPTED and action_serial > 0

func copy() -> MovementActionResult:
    var result := MovementActionResult.new()
    result.status = status
    result.action_serial = action_serial
    result.action_type = action_type
    result.duration_ticks = duration_ticks
    result.target_anchor = target_anchor
    result.target_facing = target_facing
    result.reason = reason
    return result
