extends RefCounted
class_name ActorCarryState

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")

## 13E persistent survivor carrying-capacity configuration.
## Current carried weight and the derived absolute ceiling are deliberately not stored here.

signal actor_enrolled(actor_id, capacity_grams, version)
signal actor_removed(actor_id, version)
signal capacity_changed(actor_id, previous_capacity_grams, current_capacity_grams, version)
signal carry_state_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1
const DEFAULT_CAPACITY_GRAMS: int = 18000
const HARD_LIMIT_MULTIPLIER: int = 2

var _world: WorldState = null
var _records: Dictionary = {}
var _revision: int = 0

func _init(world_state: WorldState = null) -> void:
    _world = world_state

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

func version(actor_id: String) -> int:
    if not _records.has(actor_id):
        return 0
    var record: Dictionary = _records[actor_id]
    return int(record.get("version", 0))

func capacity_grams(actor_id: String) -> int:
    if not _records.has(actor_id):
        return -1
    var record: Dictionary = _records[actor_id]
    return int(record.get("capacity_grams", -1))

func hard_limit_grams(actor_id: String) -> int:
    var capacity: int = capacity_grams(actor_id)
    if capacity <= 0:
        return -1
    return capacity * HARD_LIMIT_MULTIPLIER

func enroll_actor(actor_id: String, initial_capacity_grams: int = DEFAULT_CAPACITY_GRAMS) -> bool:
    if _world == null or not EntityIdRules.is_valid(actor_id) or initial_capacity_grams <= 0:
        return false
    if _records.has(actor_id) or not _is_valid_world_survivor(actor_id):
        return false
    var next_version: int = _revision + 1
    _records[actor_id] = {
        "capacity_grams": initial_capacity_grams,
        "version": next_version,
    }
    _revision += 1
    actor_enrolled.emit(actor_id, initial_capacity_grams, next_version)
    return true

func remove_actor(actor_id: String) -> bool:
    if not _records.has(actor_id):
        return false
    var previous: Dictionary = _records[actor_id]
    _records.erase(actor_id)
    _revision += 1
    actor_removed.emit(actor_id, int(previous.get("version", 0)))
    return true

func set_capacity_grams(actor_id: String, new_capacity_grams: int) -> bool:
    if new_capacity_grams <= 0 or not _records.has(actor_id):
        return false
    var record: Dictionary = _records[actor_id]
    var previous: int = int(record.get("capacity_grams", -1))
    if previous == new_capacity_grams:
        return true
    var next_version: int = int(record.get("version", 0)) + 1
    record["capacity_grams"] = new_capacity_grams
    record["version"] = next_version
    _records[actor_id] = record
    _revision += 1
    capacity_changed.emit(actor_id, previous, new_capacity_grams, next_version)
    return true

func snapshot() -> Dictionary:
    var entries: Array = []
    for actor_id: String in actor_ids():
        var record: Dictionary = _records[actor_id]
        entries.append({
            "actor_id": actor_id,
            "capacity_grams": int(record.get("capacity_grams", 0)),
            "version": int(record.get("version", 0)),
        })
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "revision": _revision,
        "records": entries,
    }

func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var restored_revision: int = int(data.get("revision", -1))
    var records_value: Variant = data.get("records", [])
    if restored_revision < 0 or typeof(records_value) != TYPE_ARRAY:
        return false
    var restored: Dictionary = {}
    for entry_value: Variant in records_value:
        if typeof(entry_value) != TYPE_DICTIONARY:
            return false
        var entry: Dictionary = entry_value
        var actor_id: String = String(entry.get("actor_id", ""))
        var capacity: int = int(entry.get("capacity_grams", 0))
        var actor_version: int = int(entry.get("version", -1))
        if not EntityIdRules.is_valid(actor_id) or restored.has(actor_id):
            return false
        if capacity <= 0 or actor_version < 1 or actor_version > restored_revision:
            return false
        restored[actor_id] = {"capacity_grams": capacity, "version": actor_version}
    if not restored.is_empty() and restored_revision < 1:
        return false
    _records = restored
    _revision = restored_revision
    carry_state_reset.emit()
    return true

func _is_valid_world_survivor(actor_id: String) -> bool:
    if _world == null or not _world.has_entity(actor_id):
        return false
    var entity: WorldEntityRecord = _world.entity(actor_id)
    return entity != null and String(entity.semantic_type).strip_edges() == "actor.survivor"
