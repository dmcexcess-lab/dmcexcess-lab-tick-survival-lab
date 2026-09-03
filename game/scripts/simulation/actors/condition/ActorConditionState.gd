extends RefCounted
class_name ActorConditionState

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")

## Sparse persistent condition anchors. Fatigue is the one short-term exertion
## pressure (0 rested -> 100 exhausted); Rest is longer-term sleep condition.

signal actor_enrolled(actor_id, version)
signal actor_removed(actor_id, version)
signal condition_record_changed(actor_id, version, reason)
signal condition_reset

const SNAPSHOT_SCHEMA_VERSION: int = 2
const LEGACY_SCHEMA_VERSION: int = 1
const VALUE_SCALE: int = 1000
const VALUE_MAX: int = 100
const RAW_MAX: int = VALUE_MAX * VALUE_SCALE
const START_VALUE: int = 60
const START_RAW: int = START_VALUE * VALUE_SCALE
const START_FATIGUE_RAW: int = 0

const SATIETY: StringName = &"satiety"
const HYDRATION: StringName = &"hydration"
const REST: StringName = &"rest"
const ENGAGEMENT: StringName = &"engagement"
const COMFORT: StringName = &"comfort"
const CALM: StringName = &"calm"
const CHANNELS: Array[StringName] = [SATIETY, HYDRATION, REST, ENGAGEMENT, COMFORT, CALM]

var _world: WorldState = null
var _records: Dictionary = {}
var _revision: int = 0

func _init(world_state: WorldState = null) -> void:
    _world = world_state

func is_ready() -> bool:
    return _world != null

func revision() -> int:
    return _revision

func has_actor(actor_id: String) -> bool:
    return _records.has(actor_id.strip_edges())

func actor_ids() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _records.keys():
        result.append(String(key))
    result.sort()
    return result

func version(actor_id: String) -> int:
    return int((_records.get(actor_id.strip_edges(), {}) as Dictionary).get("version", 0))

func record(actor_id: String) -> Dictionary:
    var key: String = actor_id.strip_edges()
    return {} if not _records.has(key) else (_records[key] as Dictionary).duplicate(true)

func enroll_actor(actor_id: String, world_tick: int = 0) -> bool:
    var key: String = actor_id.strip_edges()
    if not is_ready() or not EntityIdRules.is_valid(key) or world_tick < 0 \
        or _records.has(key) or not _is_valid_world_survivor(key):
        return false
    var values: Dictionary = {}
    for channel: StringName in CHANNELS:
        values[String(channel)] = START_RAW
    var next_version: int = _revision + 1
    _records[key] = {
        "actor_id": key,
        "anchor_tick": world_tick,
        "values_raw": values,
        "fatigue_raw": START_FATIGUE_RAW,
        "fatigue_anchor_tick": world_tick,
        "need_damage_remainder": 0,
        "metabolic_exertion_remainder": 0,
        "hydration_exertion_remainder": 0,
        "overexertion_remainder": 0,
        "version": next_version,
    }
    _revision += 1
    actor_enrolled.emit(key, next_version)
    return true

func remove_actor(actor_id: String) -> bool:
    var key: String = actor_id.strip_edges()
    if not _records.has(key):
        return false
    var previous: Dictionary = _records[key]
    _records.erase(key)
    _revision += 1
    actor_removed.emit(key, int(previous.get("version", 0)))
    return true

func _set_record(actor_id: String, value: Dictionary, reason: StringName = &"condition_changed") -> bool:
    var key: String = actor_id.strip_edges()
    if not _records.has(key) or not _record_valid(key, value):
        return false
    var current: Dictionary = _records[key]
    var normalized: Dictionary = value.duplicate(true)
    normalized["actor_id"] = key
    if _record_equivalent(current, normalized):
        return true
    var next_version: int = int(current.get("version", 0)) + 1
    normalized["version"] = next_version
    _records[key] = normalized
    _revision += 1
    condition_record_changed.emit(key, next_version, reason)
    return true

func snapshot() -> Dictionary:
    var entries: Array = []
    for actor_id: String in actor_ids():
        entries.append((_records[actor_id] as Dictionary).duplicate(true))
    return {"schema_version": SNAPSHOT_SCHEMA_VERSION, "revision": _revision, "records": entries}

func load_snapshot(data: Dictionary) -> bool:
    var schema: int = int(data.get("schema_version", -1))
    if schema != SNAPSHOT_SCHEMA_VERSION and schema != LEGACY_SCHEMA_VERSION:
        return false
    var restored_revision: int = int(data.get("revision", -1))
    var records_value: Variant = data.get("records", [])
    if restored_revision < 0 or typeof(records_value) != TYPE_ARRAY:
        return false
    var restored: Dictionary = {}
    for value: Variant in records_value:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var record_value: Dictionary = (value as Dictionary).duplicate(true)
        if schema == LEGACY_SCHEMA_VERSION:
            record_value = _migrate_legacy_record(record_value)
        var actor_id: String = String(record_value.get("actor_id", "")).strip_edges()
        if restored.has(actor_id) or not _record_valid(actor_id, record_value):
            return false
        var actor_version: int = int(record_value.get("version", 0))
        if actor_version < 1 or actor_version > restored_revision:
            return false
        restored[actor_id] = record_value
    if not restored.is_empty() and restored_revision < 1:
        return false
    _records = restored
    _revision = restored_revision
    condition_reset.emit()
    return true

func _record_valid(actor_id: String, value: Dictionary) -> bool:
    if actor_id.is_empty() or not EntityIdRules.is_valid(actor_id) \
        or String(value.get("actor_id", actor_id)).strip_edges() != actor_id:
        return false
    if int(value.get("anchor_tick", -1)) < 0 or int(value.get("fatigue_anchor_tick", -1)) < 0:
        return false
    var values_value: Variant = value.get("values_raw", {})
    if typeof(values_value) != TYPE_DICTIONARY:
        return false
    var values: Dictionary = values_value
    for channel: StringName in CHANNELS:
        var raw: int = int(values.get(String(channel), -1))
        if raw < 0 or raw > RAW_MAX:
            return false
    var fatigue_raw: int = int(value.get("fatigue_raw", -1))
    if fatigue_raw < 0 or fatigue_raw > RAW_MAX:
        return false
    for remainder: String in [
        "need_damage_remainder", "metabolic_exertion_remainder",
        "hydration_exertion_remainder", "overexertion_remainder",
    ]:
        if int(value.get(remainder, -1)) < 0:
            return false
    return int(value.get("version", 1)) >= 1

static func _migrate_legacy_record(record_value: Dictionary) -> Dictionary:
    var migrated: Dictionary = record_value.duplicate(true)
    var remaining_stamina: int = clampi(int(migrated.get("stamina_raw", RAW_MAX)), 0, RAW_MAX)
    migrated["fatigue_raw"] = RAW_MAX - remaining_stamina
    migrated["fatigue_anchor_tick"] = int(migrated.get("stamina_anchor_tick", migrated.get("anchor_tick", 0)))
    migrated["metabolic_exertion_remainder"] = int(migrated.get("metabolic_stamina_remainder", 0))
    migrated["hydration_exertion_remainder"] = int(migrated.get("hydration_stamina_remainder", 0))
    migrated["overexertion_remainder"] = 0
    for old_key: String in ["stamina_raw", "stamina_anchor_tick", "metabolic_stamina_remainder", "hydration_stamina_remainder"]:
        migrated.erase(old_key)
    return migrated

static func _record_equivalent(a: Dictionary, b: Dictionary) -> bool:
    var left: Dictionary = a.duplicate(true)
    var right: Dictionary = b.duplicate(true)
    left.erase("version")
    right.erase("version")
    return left == right

func _is_valid_world_survivor(actor_id: String) -> bool:
    if _world == null or not _world.has_entity(actor_id):
        return false
    var entity: WorldEntityRecord = _world.entity(actor_id)
    return entity != null and String(entity.semantic_type).strip_edges() == "actor.survivor"
