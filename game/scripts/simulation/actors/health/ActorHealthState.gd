extends RefCounted
class_name ActorHealthState

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")
const InjuryClass = preload("res://scripts/simulation/actors/health/ActorInjuryRecord.gd")

## 13A authoritative survivor health/injury state.
## HP/injury mutations are explicit; death/corpse transition belongs downstream.

signal actor_enrolled(actor_id, version)
signal actor_removed(actor_id, version)
signal hp_changed(actor_id, previous_hp, current_hp, max_hp, version)
signal damage_applied(actor_id, amount, previous_hp, current_hp, version)
signal max_hp_changed(actor_id, previous_max_hp, current_max_hp, current_hp, version)
signal injury_added(actor_id, injury_id, version)
signal injury_changed(actor_id, injury_id, version)
signal injury_removed(actor_id, injury_id, version)
signal health_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1
const DEFAULT_MAX_HP: int = 100

var _world: WorldState = null
var _records: Dictionary = {}
var _revision: int = 0
var _next_injury_serial: int = 1

func _init(world_state: WorldState = null) -> void:
    _world = world_state

func is_ready() -> bool:
    return _world != null

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

func current_hp(actor_id: String) -> int:
    if not _records.has(actor_id):
        return -1
    var record: Dictionary = _records[actor_id]
    return int(record.get("current_hp", -1))

func max_hp(actor_id: String) -> int:
    if not _records.has(actor_id):
        return -1
    var record: Dictionary = _records[actor_id]
    return int(record.get("max_hp", -1))

func hp_percent(actor_id: String) -> int:
    var maximum: int = max_hp(actor_id)
    var current: int = current_hp(actor_id)
    if maximum < 1 or current < 0:
        return -1
    return clampi(int((current * 100) / maximum), 0, 100)

func injuries(actor_id: String) -> Array[ActorInjuryRecord]:
    var result: Array[ActorInjuryRecord] = []
    if not _records.has(actor_id):
        return result
    var record: Dictionary = _records[actor_id]
    var injury_map: Dictionary = record.get("injuries", {})
    var ids: Array[String] = []
    for key: Variant in injury_map.keys():
        ids.append(String(key))
    ids.sort()
    for injury_id: String in ids:
        var value: ActorInjuryRecord = injury_map[injury_id]
        result.append(value.copy())
    return result

func injury(actor_id: String, injury_id: String) -> ActorInjuryRecord:
    if not _records.has(actor_id):
        return null
    var record: Dictionary = _records[actor_id]
    var injury_map: Dictionary = record.get("injuries", {})
    if not injury_map.has(injury_id):
        return null
    var value: ActorInjuryRecord = injury_map[injury_id]
    return value.copy()

func enroll_actor(actor_id: String, initial_max_hp: int = DEFAULT_MAX_HP) -> bool:
    if not is_ready() or not EntityIdRules.is_valid(actor_id) or initial_max_hp < 1:
        return false
    if _records.has(actor_id) or not _is_valid_world_survivor(actor_id):
        return false
    var next_version: int = _revision + 1
    _records[actor_id] = {
        "current_hp": initial_max_hp,
        "max_hp": initial_max_hp,
        "version": next_version,
        "injuries": {},
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

func set_hp(actor_id: String, value: int) -> bool:
    if not _records.has(actor_id):
        return false
    var record: Dictionary = _records[actor_id]
    var maximum: int = int(record.get("max_hp", 0))
    if value < 0 or value > maximum:
        return false
    var previous_hp: int = int(record.get("current_hp", -1))
    if previous_hp == value:
        return true
    var next_version: int = int(record.get("version", 0)) + 1
    record["current_hp"] = value
    record["version"] = next_version
    _records[actor_id] = record
    _revision += 1
    hp_changed.emit(actor_id, previous_hp, value, maximum, next_version)
    return true

func apply_damage(actor_id: String, amount: int) -> bool:
    if amount <= 0 or not _records.has(actor_id):
        return false
    var previous_hp: int = current_hp(actor_id)
    var target_hp: int = maxi(0, previous_hp - amount)
    if target_hp == previous_hp:
        return true
    if not set_hp(actor_id, target_hp):
        return false
    damage_applied.emit(
        actor_id,
        previous_hp - target_hp,
        previous_hp,
        target_hp,
        version(actor_id)
    )
    return true

func heal(actor_id: String, amount: int) -> bool:
    if amount <= 0 or not _records.has(actor_id):
        return false
    return set_hp(actor_id, mini(max_hp(actor_id), current_hp(actor_id) + amount))

func set_max_hp(actor_id: String, value: int) -> bool:
    if value < 1 or not _records.has(actor_id):
        return false
    var record: Dictionary = _records[actor_id]
    var previous_max: int = int(record.get("max_hp", 0))
    var previous_hp: int = int(record.get("current_hp", 0))
    var next_hp: int = mini(previous_hp, value)
    if previous_max == value and previous_hp == next_hp:
        return true
    var next_version: int = int(record.get("version", 0)) + 1
    record["max_hp"] = value
    record["current_hp"] = next_hp
    record["version"] = next_version
    _records[actor_id] = record
    _revision += 1
    max_hp_changed.emit(actor_id, previous_max, value, next_hp, next_version)
    if previous_hp != next_hp:
        hp_changed.emit(actor_id, previous_hp, next_hp, value, next_version)
    return true

func add_injury(actor_id: String, injury_type: StringName, body_region: StringName, severity: int) -> String:
    if not _records.has(actor_id):
        return ""
    var candidate_id: String = "injury_%08d" % _next_injury_serial
    var value := InjuryClass.new(candidate_id, injury_type, body_region, severity, false, false)
    if not value.is_valid():
        return ""
    var record: Dictionary = _records[actor_id]
    var injury_map: Dictionary = record.get("injuries", {}).duplicate()
    injury_map[candidate_id] = value
    var next_version: int = int(record.get("version", 0)) + 1
    record["injuries"] = injury_map
    record["version"] = next_version
    _records[actor_id] = record
    _next_injury_serial += 1
    _revision += 1
    injury_added.emit(actor_id, candidate_id, next_version)
    return candidate_id

func set_injury_state(
    actor_id: String,
    injury_id: String,
    severity: int,
    stabilized: bool,
    treated: bool
) -> bool:
    if not _records.has(actor_id) or not InjuryClass.is_valid_severity(severity):
        return false
    var record: Dictionary = _records[actor_id]
    var injury_map: Dictionary = record.get("injuries", {})
    if not injury_map.has(injury_id):
        return false
    var previous: ActorInjuryRecord = injury_map[injury_id]
    if previous.severity == severity and previous.stabilized == stabilized and previous.treated == treated:
        return true
    var updated := InjuryClass.new(
        previous.injury_id,
        previous.injury_type,
        previous.body_region,
        severity,
        stabilized,
        treated
    )
    if not updated.is_valid():
        return false
    var next_injuries: Dictionary = injury_map.duplicate()
    next_injuries[injury_id] = updated
    var next_version: int = int(record.get("version", 0)) + 1
    record["injuries"] = next_injuries
    record["version"] = next_version
    _records[actor_id] = record
    _revision += 1
    injury_changed.emit(actor_id, injury_id, next_version)
    return true

func remove_injury(actor_id: String, injury_id: String) -> bool:
    if not _records.has(actor_id):
        return false
    var record: Dictionary = _records[actor_id]
    var injury_map: Dictionary = record.get("injuries", {})
    if not injury_map.has(injury_id):
        return false
    var next_injuries: Dictionary = injury_map.duplicate()
    next_injuries.erase(injury_id)
    var next_version: int = int(record.get("version", 0)) + 1
    record["injuries"] = next_injuries
    record["version"] = next_version
    _records[actor_id] = record
    _revision += 1
    injury_removed.emit(actor_id, injury_id, next_version)
    return true

func snapshot() -> Dictionary:
    var entries: Array = []
    for actor_id: String in actor_ids():
        var record: Dictionary = _records[actor_id]
        var injury_entries: Array = []
        for value: ActorInjuryRecord in injuries(actor_id):
            injury_entries.append(value.to_snapshot())
        entries.append({
            "actor_id": actor_id,
            "current_hp": int(record.get("current_hp", 0)),
            "max_hp": int(record.get("max_hp", 0)),
            "version": int(record.get("version", 0)),
            "injuries": injury_entries,
        })
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "revision": _revision,
        "next_injury_serial": _next_injury_serial,
        "records": entries,
    }

func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var restored_revision: int = int(data.get("revision", -1))
    var restored_serial: int = int(data.get("next_injury_serial", -1))
    var records_value: Variant = data.get("records", [])
    if restored_revision < 0 or restored_serial < 1 or typeof(records_value) != TYPE_ARRAY:
        return false

    var restored_records: Dictionary = {}
    for entry_value: Variant in records_value:
        if typeof(entry_value) != TYPE_DICTIONARY:
            return false
        var entry: Dictionary = entry_value
        var actor_id: String = String(entry.get("actor_id", ""))
        var current: int = int(entry.get("current_hp", -1))
        var maximum: int = int(entry.get("max_hp", -1))
        var actor_version: int = int(entry.get("version", -1))
        var injuries_value: Variant = entry.get("injuries", [])
        if not EntityIdRules.is_valid(actor_id) or restored_records.has(actor_id):
            return false
        if maximum < 1 or current < 0 or current > maximum or actor_version < 1 or actor_version > restored_revision:
            return false
        if typeof(injuries_value) != TYPE_ARRAY:
            return false
        var injury_map: Dictionary = {}
        for injury_value: Variant in injuries_value:
            if typeof(injury_value) != TYPE_DICTIONARY:
                return false
            var restored_injury: ActorInjuryRecord = InjuryClass.from_snapshot(injury_value)
            if restored_injury == null or injury_map.has(restored_injury.injury_id):
                return false
            injury_map[restored_injury.injury_id] = restored_injury
        restored_records[actor_id] = {
            "current_hp": current,
            "max_hp": maximum,
            "version": actor_version,
            "injuries": injury_map,
        }

    if not restored_records.is_empty() and restored_revision < 1:
        return false
    _records = restored_records
    _revision = restored_revision
    _next_injury_serial = restored_serial
    health_reset.emit()
    return true

func _is_valid_world_survivor(actor_id: String) -> bool:
    if _world == null or not _world.has_entity(actor_id):
        return false
    var entity: WorldEntityRecord = _world.entity(actor_id)
    return entity != null and String(entity.semantic_type).strip_edges() == "actor.survivor"
