extends RefCounted
class_name ActorNeedsState

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")

## 13B authoritative coarse survivor Needs / Rest pressure values.

signal actor_enrolled(actor_id, version)
signal actor_removed(actor_id, version)
signal need_changed(actor_id, need_id, previous_value, current_value, version)
signal needs_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1
const MIN_VALUE: int = 0
const MAX_VALUE: int = 100

const FATIGUE: StringName = &"fatigue"
const HUNGER: StringName = &"hunger"
const THIRST: StringName = &"thirst"
const SLEEP_PRESSURE: StringName = &"sleep_pressure"

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

func need_ids() -> Array[StringName]:
    return [FATIGUE, HUNGER, THIRST, SLEEP_PRESSURE]

func has_need(need_id: StringName) -> bool:
    return need_id == FATIGUE or need_id == HUNGER or need_id == THIRST or need_id == SLEEP_PRESSURE

func value(actor_id: String, need_id: StringName) -> int:
    if not _records.has(actor_id) or not has_need(need_id):
        return -1
    var record: Dictionary = _records[actor_id]
    return int(record.get(String(need_id), -1))

func fatigue(actor_id: String) -> int:
    return value(actor_id, FATIGUE)

func hunger(actor_id: String) -> int:
    return value(actor_id, HUNGER)

func thirst(actor_id: String) -> int:
    return value(actor_id, THIRST)

func sleep_pressure(actor_id: String) -> int:
    return value(actor_id, SLEEP_PRESSURE)

func record(actor_id: String) -> Dictionary:
    if not _records.has(actor_id):
        return {}
    return (_records[actor_id] as Dictionary).duplicate(true)

func enroll_actor(actor_id: String) -> bool:
    if _world == null or not EntityIdRules.is_valid(actor_id) or _records.has(actor_id):
        return false
    if not _is_valid_world_survivor(actor_id):
        return false
    var next_version: int = _revision + 1
    _records[actor_id] = {
        "fatigue": 0,
        "hunger": 0,
        "thirst": 0,
        "sleep_pressure": 0,
        "version": next_version,
    }
    _revision += 1
    actor_enrolled.emit(actor_id, next_version)
    return true

func remove_actor(actor_id: String) -> bool:
    if not _records.has(actor_id):
        return false
    var previous: Dictionary = _records[actor_id]
    _records.erase(actor_id)
    _revision += 1
    actor_removed.emit(actor_id, int(previous.get("version", 0)))
    return true

func set_need(actor_id: String, need_id: StringName, new_value: int) -> bool:
    if not _records.has(actor_id) or not has_need(need_id):
        return false
    if new_value < MIN_VALUE or new_value > MAX_VALUE:
        return false
    var record: Dictionary = _records[actor_id]
    var key: String = String(need_id)
    var previous: int = int(record.get(key, -1))
    if previous == new_value:
        return true
    var next_version: int = int(record.get("version", 0)) + 1
    record[key] = new_value
    record["version"] = next_version
    _records[actor_id] = record
    _revision += 1
    need_changed.emit(actor_id, need_id, previous, new_value, next_version)
    return true

func change_need(actor_id: String, need_id: StringName, delta: int) -> bool:
    if delta == 0 or not _records.has(actor_id) or not has_need(need_id):
        return false
    var previous: int = value(actor_id, need_id)
    return set_need(actor_id, need_id, clampi(previous + delta, MIN_VALUE, MAX_VALUE))

func set_all(actor_id: String, fatigue_value: int, hunger_value: int, thirst_value: int, sleep_value: int) -> bool:
    if not _records.has(actor_id):
        return false
    for candidate: int in [fatigue_value, hunger_value, thirst_value, sleep_value]:
        if candidate < MIN_VALUE or candidate > MAX_VALUE:
            return false
    var record: Dictionary = _records[actor_id]
    if (
        int(record.get("fatigue", -1)) == fatigue_value
        and int(record.get("hunger", -1)) == hunger_value
        and int(record.get("thirst", -1)) == thirst_value
        and int(record.get("sleep_pressure", -1)) == sleep_value
    ):
        return true
    var previous_values: Dictionary = record.duplicate(true)
    var next_version: int = int(record.get("version", 0)) + 1
    record["fatigue"] = fatigue_value
    record["hunger"] = hunger_value
    record["thirst"] = thirst_value
    record["sleep_pressure"] = sleep_value
    record["version"] = next_version
    _records[actor_id] = record
    _revision += 1
    for need_id: StringName in need_ids():
        var key: String = String(need_id)
        var previous: int = int(previous_values.get(key, -1))
        var current: int = int(record.get(key, -1))
        if previous != current:
            need_changed.emit(actor_id, need_id, previous, current, next_version)
    return true

func snapshot() -> Dictionary:
    var entries: Array = []
    for actor_id: String in actor_ids():
        var stored: Dictionary = _records[actor_id]
        entries.append({
            "actor_id": actor_id,
            "fatigue": int(stored.get("fatigue", 0)),
            "hunger": int(stored.get("hunger", 0)),
            "thirst": int(stored.get("thirst", 0)),
            "sleep_pressure": int(stored.get("sleep_pressure", 0)),
            "version": int(stored.get("version", 0)),
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
        var actor_version: int = int(entry.get("version", -1))
        if not EntityIdRules.is_valid(actor_id) or restored.has(actor_id):
            return false
        if actor_version < 1 or actor_version > restored_revision:
            return false
        var next_record: Dictionary = {"version": actor_version}
        for need_id: StringName in need_ids():
            var key: String = String(need_id)
            var candidate: int = int(entry.get(key, -1))
            if candidate < MIN_VALUE or candidate > MAX_VALUE:
                return false
            next_record[key] = candidate
        restored[actor_id] = next_record
    if not restored.is_empty() and restored_revision < 1:
        return false
    _records = restored
    _revision = restored_revision
    needs_reset.emit()
    return true

func _is_valid_world_survivor(actor_id: String) -> bool:
    if _world == null or not _world.has_entity(actor_id):
        return false
    var entity: WorldEntityRecord = _world.entity(actor_id)
    return entity != null and String(entity.semantic_type).strip_edges() == "actor.survivor"
