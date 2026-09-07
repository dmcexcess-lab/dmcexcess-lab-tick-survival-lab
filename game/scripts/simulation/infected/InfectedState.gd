extends RefCounted
class_name InfectedState

## Infection is persistent state on a human actor identity, not a parallel zombie entity class.

signal infected_hydrated(actor_id, resident_record)

var _records: Dictionary = {}

func is_infected(actor_id: String) -> bool:
    return _records.has(actor_id)

func resident_record(actor_id: String) -> Dictionary:
    return {} if not _records.has(actor_id) else Dictionary(_records[actor_id]).duplicate(true)

func record_hydration(actor_id: String, resident_record_value: Dictionary) -> bool:
    if actor_id.is_empty() or _records.has(actor_id): return false
    if String(resident_record_value.get("resident_id", "")) != actor_id or not bool(resident_record_value.get("infected", false)): return false
    var building_id := String(resident_record_value.get("building_id", ""))
    var ordinal := int(resident_record_value.get("resident_ordinal", 0))
    if building_id.is_empty() or ordinal < 1: return false
    _records[actor_id] = resident_record_value.duplicate(true)
    infected_hydrated.emit(actor_id, resident_record(actor_id))
    return true

func actor_ids() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _records.keys(): result.append(String(key))
    result.sort()
    return result

func snapshot() -> Dictionary:
    return {"records": _records.duplicate(true)}
