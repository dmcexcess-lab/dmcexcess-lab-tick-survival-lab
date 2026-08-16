extends RefCounted
class_name EntityStore

## Internal persistent entity store. IDs are the keys; callers outside WHAT use WorldState reads.

var _by_id: Dictionary = {}

func has(entity_id: String) -> bool:
    return _by_id.has(entity_id)

func insert(record: WorldEntityRecord) -> bool:
    if record == null or not record.is_valid() or has(record.id):
        return false
    _by_id[record.id] = record.copy()
    return true

func remove(entity_id: String) -> WorldEntityRecord:
    if not has(entity_id):
        return null
    var record: WorldEntityRecord = _by_id[entity_id]
    _by_id.erase(entity_id)
    return record

func get_record(entity_id: String) -> WorldEntityRecord:
    if not has(entity_id):
        return null
    return _by_id[entity_id]

func ids() -> Array[String]:
    var result: Array[String] = []
    for value: Variant in _by_id.keys():
        result.append(String(value))
    result.sort()
    return result

func clear() -> void:
    _by_id.clear()

func snapshot_entries() -> Array:
    var entries: Array = []
    for entity_id: String in ids():
        var record: WorldEntityRecord = _by_id[entity_id]
        entries.append(record.to_snapshot())
    return entries
