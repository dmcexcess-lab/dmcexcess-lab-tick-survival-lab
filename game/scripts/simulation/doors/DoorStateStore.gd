extends RefCounted
class_name DoorStateStore

const RecordClass = preload("res://scripts/simulation/doors/DoorStateRecord.gd")
const StateRules = preload("res://scripts/simulation/doors/DoorStateValue.gd")

## Authoritative persistent OPEN/CLOSED state keyed by stable WHAT door IDs.
## Normal writes go through DoorStateMutationService.

signal door_enrolled(door_id, state, version)
signal door_removed(door_id, previous_state, version)
signal door_state_changed(door_id, previous_state, new_state, version)
signal door_state_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1

var _records: Dictionary = {}
var _revision: int = 0

func revision() -> int:
    return _revision

func has_door(door_id: String) -> bool:
    return _records.has(door_id)

func door_ids() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _records.keys():
        result.append(String(key))
    result.sort()
    return result

func record(door_id: String) -> DoorStateRecord:
    if not _records.has(door_id):
        return null
    var value: DoorStateRecord = _records[door_id]
    return value.copy()

func state(door_id: String) -> StringName:
    if not _records.has(door_id):
        return StateRules.UNKNOWN
    var value: DoorStateRecord = _records[door_id]
    return value.state

func version(door_id: String) -> int:
    if not _records.has(door_id):
        return 0
    var value: DoorStateRecord = _records[door_id]
    return value.version

func snapshot() -> Dictionary:
    var entries: Array = []
    for door_id: String in door_ids():
        var value: DoorStateRecord = _records[door_id]
        entries.append(value.to_snapshot())
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "revision": _revision,
        "records": entries,
    }

func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var restored_revision: int = int(data.get("revision", -1))
    if restored_revision < 0:
        return false
    var records_value: Variant = data.get("records", [])
    if typeof(records_value) != TYPE_ARRAY:
        return false

    var restored: Dictionary = {}
    for value: Variant in records_value:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var restored_record: DoorStateRecord = RecordClass.from_snapshot(value)
        if restored_record == null or restored.has(restored_record.door_id):
            return false
        if restored_record.version > restored_revision:
            return false
        restored[restored_record.door_id] = restored_record

    if not restored.is_empty() and restored_revision < 1:
        return false

    _records = restored
    _revision = restored_revision
    door_state_reset.emit()
    return true

# --- Door-state-internal mutation surface. External systems use the mutation service. ---

func _insert_record(value: DoorStateRecord) -> bool:
    if value == null or not value.is_valid() or _records.has(value.door_id):
        return false
    var stored: DoorStateRecord = value.copy()
    _records[stored.door_id] = stored
    _revision += 1
    door_enrolled.emit(stored.door_id, stored.state, stored.version)
    return true

func _remove_record(door_id: String) -> DoorStateRecord:
    if not _records.has(door_id):
        return null
    var previous: DoorStateRecord = _records[door_id]
    _records.erase(door_id)
    _revision += 1
    door_removed.emit(previous.door_id, previous.state, previous.version)
    return previous.copy()

func _set_state_record(door_id: String, target_state: StringName) -> bool:
    if not _records.has(door_id) or not StateRules.is_stored(target_state):
        return false
    var previous: DoorStateRecord = _records[door_id]
    if previous.state == target_state:
        return true
    var updated := RecordClass.new(door_id, target_state, previous.version + 1)
    if not updated.is_valid():
        return false
    _records[door_id] = updated
    _revision += 1
    door_state_changed.emit(door_id, previous.state, updated.state, updated.version)
    return true
