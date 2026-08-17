extends RefCounted
class_name ActorSkillState

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")
const Catalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")

## 13C authoritative base survivor skill level + XP progression.

signal actor_enrolled(actor_id, version)
signal actor_removed(actor_id, version)
signal skill_changed(actor_id, skill_id, level, xp, version)
signal skill_level_gained(actor_id, skill_id, previous_level, new_level, version)
signal skills_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1

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

func skill_ids() -> Array[StringName]:
    return Catalog.skill_ids()

func display_name(skill_id: StringName) -> String:
    return Catalog.display_name(skill_id)

func version(actor_id: String) -> int:
    if not _records.has(actor_id):
        return 0
    var record: Dictionary = _records[actor_id]
    return int(record.get("version", 0))

func level(actor_id: String, skill_id: StringName) -> int:
    if not _records.has(actor_id) or not Catalog.is_valid(skill_id):
        return -1
    var record: Dictionary = _records[actor_id]
    var levels: Dictionary = record.get("levels", {})
    return int(levels.get(String(skill_id), 0))

func xp(actor_id: String, skill_id: StringName) -> int:
    if not _records.has(actor_id) or not Catalog.is_valid(skill_id):
        return -1
    var record: Dictionary = _records[actor_id]
    var values: Dictionary = record.get("xp", {})
    return int(values.get(String(skill_id), 0))

func next_level_xp(actor_id: String, skill_id: StringName) -> int:
    var current_level: int = level(actor_id, skill_id)
    if current_level < 0:
        return -1
    return Catalog.next_level_xp(current_level)

func record(actor_id: String) -> Dictionary:
    if not _records.has(actor_id):
        return {}
    return (_records[actor_id] as Dictionary).duplicate(true)

func enroll_actor(actor_id: String) -> bool:
    if _world == null or not EntityIdRules.is_valid(actor_id) or _records.has(actor_id):
        return false
    if not _is_valid_world_survivor(actor_id):
        return false
    var levels: Dictionary = {}
    var xp_values: Dictionary = {}
    for skill_id: StringName in Catalog.skill_ids():
        levels[String(skill_id)] = 0
        xp_values[String(skill_id)] = 0
    var next_version: int = _revision + 1
    _records[actor_id] = {
        "levels": levels,
        "xp": xp_values,
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

func set_skill(actor_id: String, skill_id: StringName, new_level: int, new_xp: int = 0) -> bool:
    if not _records.has(actor_id) or not Catalog.is_valid(skill_id) or not Catalog.is_valid_level(new_level):
        return false
    if not _is_normalized_xp(new_level, new_xp):
        return false
    var previous_level: int = level(actor_id, skill_id)
    var previous_xp: int = xp(actor_id, skill_id)
    if previous_level == new_level and previous_xp == new_xp:
        return true
    var record: Dictionary = _records[actor_id]
    var levels: Dictionary = (record.get("levels", {}) as Dictionary).duplicate()
    var xp_values: Dictionary = (record.get("xp", {}) as Dictionary).duplicate()
    levels[String(skill_id)] = new_level
    xp_values[String(skill_id)] = new_xp
    var next_version: int = int(record.get("version", 0)) + 1
    record["levels"] = levels
    record["xp"] = xp_values
    record["version"] = next_version
    _records[actor_id] = record
    _revision += 1
    skill_changed.emit(actor_id, skill_id, new_level, new_xp, next_version)
    if new_level > previous_level:
        skill_level_gained.emit(actor_id, skill_id, previous_level, new_level, next_version)
    return true

func award_xp(actor_id: String, skill_id: StringName, amount: int) -> bool:
    if amount <= 0 or not _records.has(actor_id) or not Catalog.is_valid(skill_id):
        return false
    var current_level: int = level(actor_id, skill_id)
    var current_xp: int = xp(actor_id, skill_id)
    if current_level == Catalog.LEVEL_MAX:
        return true
    var next_level: int = current_level
    var next_xp: int = current_xp + amount
    while next_level < Catalog.LEVEL_MAX:
        var threshold: int = Catalog.next_level_xp(next_level)
        if next_xp < threshold:
            break
        next_xp -= threshold
        next_level += 1
        if next_level == Catalog.LEVEL_MAX:
            next_xp = 0
            break
    return set_skill(actor_id, skill_id, next_level, next_xp)

func snapshot() -> Dictionary:
    var entries: Array = []
    for actor_id: String in actor_ids():
        var record_value: Dictionary = _records[actor_id]
        var skills: Array = []
        for skill_id: StringName in Catalog.skill_ids():
            skills.append({
                "skill_id": String(skill_id),
                "level": level(actor_id, skill_id),
                "xp": xp(actor_id, skill_id),
            })
        entries.append({
            "actor_id": actor_id,
            "version": int(record_value.get("version", 0)),
            "skills": skills,
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
        var skills_value: Variant = entry.get("skills", [])
        if not EntityIdRules.is_valid(actor_id) or restored.has(actor_id):
            return false
        if actor_version < 1 or actor_version > restored_revision or typeof(skills_value) != TYPE_ARRAY:
            return false
        var levels: Dictionary = {}
        var xp_values: Dictionary = {}
        for skill_value: Variant in skills_value:
            if typeof(skill_value) != TYPE_DICTIONARY:
                return false
            var skill_entry: Dictionary = skill_value
            var skill_id := StringName(String(skill_entry.get("skill_id", "")))
            var candidate_level: int = int(skill_entry.get("level", -1))
            var candidate_xp: int = int(skill_entry.get("xp", -1))
            var key: String = String(skill_id)
            if not Catalog.is_valid(skill_id) or levels.has(key):
                return false
            if not Catalog.is_valid_level(candidate_level) or not _is_normalized_xp(candidate_level, candidate_xp):
                return false
            levels[key] = candidate_level
            xp_values[key] = candidate_xp
        if levels.size() != Catalog.skill_ids().size():
            return false
        restored[actor_id] = {
            "levels": levels,
            "xp": xp_values,
            "version": actor_version,
        }
    if not restored.is_empty() and restored_revision < 1:
        return false
    _records = restored
    _revision = restored_revision
    skills_reset.emit()
    return true

static func _is_normalized_xp(skill_level: int, skill_xp: int) -> bool:
    if skill_xp < 0 or not Catalog.is_valid_level(skill_level):
        return false
    if skill_level == Catalog.LEVEL_MAX:
        return skill_xp == 0
    return skill_xp < Catalog.next_level_xp(skill_level)

func _is_valid_world_survivor(actor_id: String) -> bool:
    if _world == null or not _world.has_entity(actor_id):
        return false
    var entity: WorldEntityRecord = _world.entity(actor_id)
    return entity != null and String(entity.semantic_type).strip_edges() == "actor.survivor"
