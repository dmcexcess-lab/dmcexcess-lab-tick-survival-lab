extends RefCounted
class_name ItemTransferActionResult

enum Status {
    ACCEPTED,
    NOT_READY,
    ACTOR_MISSING,
    ACTOR_UNPLACED,
    NOT_SURVIVOR,
    BUSY,
    ITEM_MISSING,
    NOT_ITEM,
    DISPOSITION_CONFLICT,
    SOURCE_MISMATCH,
    OUT_OF_REACH,
    HAND_STATE_UNKNOWN,
    INVALID_SLOT,
    HAND_OCCUPIED,
    CONTAINER_UNKNOWN,
    CONTAINER_INACCESSIBLE,
    CONTAINER_REJECTED,
    CARRY_LIMIT_EXCEEDED,
    TIMING_UNCLASSIFIED,
    CAPABILITY_UNKNOWN,
    CAPABILITY_BLOCKED,
    INVALID_DURATION,
    TIMING_REJECTED,
}

var status: int = Status.NOT_READY
var reason: String = ""
var action_type: StringName = &""
var action_serial: int = 0
var actor_id: String = ""
var item_id: String = ""
var duration_ticks: int = 0
var source_kind: StringName = &"unknown"
var destination_kind: StringName = &"unknown"
var destination_container_id: String = ""
var destination_slot: int = -1

func is_accepted() -> bool:
    return status == Status.ACCEPTED and action_serial > 0 and duration_ticks > 0
