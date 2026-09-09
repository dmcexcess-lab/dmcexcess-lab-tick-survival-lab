extends RefCounted
class_name SurvivorNpcState

## Social/hostility role overlay for resident-backed human actors. Physical actor,
## Health, inventory, skills, needs, movement and combat remain owned elsewhere.

signal role_changed(actor_id, previous_role, new_role)
signal survivor_removed(actor_id, reason)

const NEUTRAL: StringName = &"survivor.neutral"
const FOLLOWER: StringName = &"survivor.follower"
const RAIDER: StringName = &"survivor.raider"
const ROLES: Array[StringName] = [NEUTRAL, FOLLOWER, RAIDER]

var _records: Dictionary = {}
var _roles: Dictionary = {}

func record_hydration(actor_id: String, resident_record_value: Dictionary, role: StringName = NEUTRAL) -> bool:
    var key := actor_id.strip_edges()
    if key.is_empty() or _records.has(key) or role not in ROLES:
        return false
    if String(resident_record_value.get("resident_id", "")) != key or bool(resident_record_value.get("infected", true)):
        return false
    if String(resident_record_value.get("building_id", "")).is_empty() or int(resident_record_value.get("resident_ordinal", 0)) < 1:
        return false
    _records[key] = resident_record_value.duplicate(true)
    _roles[key] = role
    return true

func has_actor(actor_id: String) -> bool:
    return _records.has(actor_id.strip_edges())

func resident_record(actor_id: String) -> Dictionary:
    var key := actor_id.strip_edges()
    return {} if not _records.has(key) else Dictionary(_records[key]).duplicate(true)

func role(actor_id: String) -> StringName:
    return StringName(String(_roles.get(actor_id.strip_edges(), "")))

func set_role(actor_id: String, new_role: StringName) -> bool:
    var key := actor_id.strip_edges()
    if not _records.has(key) or new_role not in ROLES:
        return false
    var previous := role(key)
    if previous == new_role:
        return true
    _roles[key] = new_role
    role_changed.emit(key, previous, new_role)
    return true

func remove_actor(actor_id: String, reason: StringName = &"removed") -> bool:
    var key := actor_id.strip_edges()
    if not _records.has(key):
        return false
    _records.erase(key)
    _roles.erase(key)
    survivor_removed.emit(key, reason)
    return true

func actor_ids() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _records.keys():
        result.append(String(key))
    result.sort()
    return result

func actor_ids_for_role(role_id: StringName) -> Array[String]:
    var result: Array[String] = []
    for actor_id: String in actor_ids():
        if role(actor_id) == role_id:
            result.append(actor_id)
    return result

func snapshot() -> Dictionary:
    var entries: Array[Dictionary] = []
    for actor_id: String in actor_ids():
        entries.append({
            "actor_id": actor_id,
            "role": String(role(actor_id)),
            "resident_record": resident_record(actor_id),
        })
    return {"records": entries}
