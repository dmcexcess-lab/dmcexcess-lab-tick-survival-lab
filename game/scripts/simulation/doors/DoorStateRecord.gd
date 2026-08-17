extends RefCounted
class_name DoorStateRecord

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")
const StateRules = preload("res://scripts/simulation/doors/DoorStateValue.gd")

## Immutable-style persistent OPEN/CLOSED state for one stable door entity ID.

var door_id: String = ""
var state: StringName = StateRules.UNKNOWN
var version: int = 1

func _init(
    value_door_id: String = "",
    value_state: StringName = StateRules.UNKNOWN,
    value_version: int = 1
) -> void:
    door_id = value_door_id
    state = value_state
    version = value_version

func is_valid() -> bool:
    return EntityIdRules.is_valid(door_id) and StateRules.is_stored(state) and version >= 1

func copy() -> DoorStateRecord:
    return DoorStateRecord.new(door_id, state, version)

func to_snapshot() -> Dictionary:
    return {
        "door_id": door_id,
        "state": String(state),
        "version": version,
    }

static func from_snapshot(data: Dictionary) -> DoorStateRecord:
    var record := DoorStateRecord.new(
        String(data.get("door_id", "")),
        StringName(String(data.get("state", ""))),
        int(data.get("version", 0))
    )
    if not record.is_valid():
        return null
    return record
