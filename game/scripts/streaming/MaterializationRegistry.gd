extends RefCounted
class_name MaterializationRegistry

const RecordClass = preload("res://scripts/streaming/MaterializationRecord.gd")

const SNAPSHOT_SCHEMA_VERSION: int = 1

var _records: Dictionary = {}
var _revision: int = 0

func revision() -> int:
    return _revision

func has_source(source_key: String) -> bool:
    return _records.has(source_key)

func record(source_key: String) -> MaterializationRecord:
    if not _records.has(source_key):
        return null
    var value: MaterializationRecord = _records[source_key]
    return value.copy()

func source_keys() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _records.keys():
        result.append(String(key))
    result.sort()
    return result

func mark_materialized(value: MaterializationRecord) -> bool:
    if value == null or not value.is_valid() or _records.has(value.source_key):
        return false
    _records[value.source_key] = value.copy()
    _revision += 1
    return true

func snapshot() -> Dictionary:
    var entries: Array = []
    for source_key: String in source_keys():
        var value: MaterializationRecord = _records[source_key]
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
    var entries: Array = records_value
    for entry_value: Variant in entries:
        if typeof(entry_value) != TYPE_DICTIONARY:
            return false
        var value: MaterializationRecord = RecordClass.from_snapshot(entry_value)
        if value == null or restored.has(value.source_key):
            return false
        restored[value.source_key] = value.copy()
    if restored_revision < restored.size():
        return false

    _records = restored
    _revision = restored_revision
    return true
