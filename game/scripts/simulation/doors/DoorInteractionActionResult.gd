extends RefCounted
class_name DoorInteractionActionResult

enum Status {
    ACCEPTED,
    NOT_READY,
    ACTOR_MISSING,
    ACTOR_UNPLACED,
    DOOR_MISSING,
    DOOR_NOT_OPEN,
    OUT_OF_REACH,
    NOT_FACING_DOOR,
    DOORWAY_OCCUPIED,
    BUSY,
    TIMING_REJECTED,
}

var status: int = Status.NOT_READY
var reason: String = ""
var action_serial: int = 0
var duration_ticks: int = 0
var door_id: String = ""

func is_accepted() -> bool:
    return status == Status.ACCEPTED and action_serial > 0 and duration_ticks > 0
