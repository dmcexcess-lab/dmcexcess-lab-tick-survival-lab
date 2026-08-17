extends RefCounted
class_name DoorStateValue

## Stable semantic vocabulary for persistent door openness.
## UNKNOWN is query-only and is never stored in a DoorStateRecord.

const OPEN: StringName = &"open"
const CLOSED: StringName = &"closed"
const UNKNOWN: StringName = &"unknown"

static func is_stored(value: StringName) -> bool:
    return value == OPEN or value == CLOSED

static func is_known(value: StringName) -> bool:
    return is_stored(value)
