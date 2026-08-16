extends RefCounted
class_name ActorLocomotionState

const RecordClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionRecord.gd")
const StanceRules = preload("res://scripts/simulation/actors/locomotion/ActorStance.gd")

## Authoritative locomotion-only state keyed by stable WHAT entity IDs.
## Normal writes go through ActorLocomotionMutationService.

signal record_enrolled(actor_id, stance, version)
signal record_removed(actor_id, stance, version)
signal stance_changed(actor_id, previous_stance, new_stance, version)
signal locomotion_state_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1

var _records: Dictionary = {}
var _revision: int = 0

func revision() -> int:
    return _revision

func has_actor(actor_id: String) -> bool:
    return _records.has(actor_id)

func actor_ids() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _records.keys():
        result.append(String(key))
    result.sort()
    return result

func record(actor_id: String) -> ActorLocomotionRecord:
    if not _records.has(actor_id):
        return null
    var value: ActorLocomotionRecord = _records[actor_id]
    return value.copy()

func stance(actor_id: String) -> StringName:
    if not _records.has(actor_id):
        return &""
    var value: ActorLocomotionRecord = _records[actor_id]
    return value.stance

func version(actor_id: String) -> int:
    if not _records.has(actor_id):
        return 0
    var value: ActorLocomotionRecord = _records[actor_id]
    return value.version

func snapshot() -> Dictionary:
    var entries: Array = []
    for actor_id: String in actor_ids():
        var value: ActorLocomotionRecord = _records[actor_id]
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
        var restored_record: ActorLocomotionRecord = RecordClass.from_snapshot(value)
        if restored_record == null or restored.has(restored_record.actor_id):
            return false
        restored[restored_record.actor_id] = restored_record

    _records = restored
    _revision = restored_revision
    locomotion_state_reset.emit()
    return true

# --- Locomotion-internal mutation surface. External systems use the mutation service. ---

func _insert_record(value: ActorLocomotionRecord) -> bool:
    if value == null or not value.is_valid() or _records.has(value.actor_id):
        return false
    var stored: ActorLocomotionRecord = value.copy()
    _records[stored.actor_id] = stored
    _revision += 1
    record_enrolled.emit(stored.actor_id, stored.stance, stored.version)
    return true

func _remove_record(actor_id: String) -> ActorLocomotionRecord:
    if not _records.has(actor_id):
        return null
    var previous: ActorLocomotionRecord = _records[actor_id]
    _records.erase(actor_id)
    _revision += 1
    record_removed.emit(previous.actor_id, previous.stance, previous.version)
    return previous.copy()

func _set_stance_record(actor_id: String, target_stance: StringName) -> bool:
    if not _records.has(actor_id) or not StanceRules.is_valid(target_stance):
        return false
    var previous: ActorLocomotionRecord = _records[actor_id]
    if previous.stance == target_stance:
        return false
    var updated := RecordClass.new(actor_id, target_stance, previous.version + 1)
    if not updated.is_valid():
        return false
    _records[actor_id] = updated
    _revision += 1
    stance_changed.emit(actor_id, previous.stance, updated.stance, updated.version)
    return true
