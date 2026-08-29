extends RefCounted
class_name EntityStore

## Internal persistent entity store. IDs are the keys; callers outside WHAT use WorldState reads.
## Semantic identity is indexed once on mutation so typed readers never need whole-world scans.

var _by_id: Dictionary = {}
var _ids_by_type: Dictionary = {}

func has(entity_id: String) -> bool:
    return _by_id.has(entity_id)

func insert(record: WorldEntityRecord) -> bool:
    if record == null or not record.is_valid() or has(record.id):
        return false
    var stored: WorldEntityRecord = record.copy()
    _by_id[stored.id] = stored
    var typed_ids: Dictionary = _ids_by_type.get(stored.semantic_type, {})
    typed_ids[stored.id] = true
    _ids_by_type[stored.semantic_type] = typed_ids
    return true

func remove(entity_id: String) -> WorldEntityRecord:
    if not has(entity_id):
        return null
    var record: WorldEntityRecord = _by_id[entity_id]
    _by_id.erase(entity_id)
    var typed_ids: Dictionary = _ids_by_type.get(record.semantic_type, {})
    typed_ids.erase(entity_id)
    if typed_ids.is_empty():
        _ids_by_type.erase(record.semantic_type)
    else:
        _ids_by_type[record.semantic_type] = typed_ids
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

func ids_of_type(semantic_type: StringName) -> Array[String]:
    var result: Array[String] = []
    var typed_ids: Dictionary = _ids_by_type.get(semantic_type, {})
    for value: Variant in typed_ids.keys():
        result.append(String(value))
    result.sort()
    return result

func clear() -> void:
    _by_id.clear()
    _ids_by_type.clear()

func snapshot_entries() -> Array:
    var entries: Array = []
    for entity_id: String in ids():
        var record: WorldEntityRecord = _by_id[entity_id]
        entries.append(record.to_snapshot())
    return entries
