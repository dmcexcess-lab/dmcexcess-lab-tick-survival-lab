extends RefCounted
class_name ItemFreshnessState

signal freshness_changed(item_id, version)
signal freshness_removed(item_id, previous_version)
signal freshness_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1

var _revision: int = 0
var _records: Dictionary = {}

func revision() -> int:
    return _revision

func has_item(item_id: String) -> bool:
    return _records.has(item_id.strip_edges())

func item_ids() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _records.keys():
        result.append(String(key))
    result.sort()
    return result

func record(item_id: String) -> ItemFreshnessRecord:
    var key: String = item_id.strip_edges()
    if not _records.has(key):
        return null
    return (_records[key] as ItemFreshnessRecord).copy()

func snapshot() -> Dictionary:
    var records_out: Array = []
    for item_id: String in item_ids():
        records_out.append((_records[item_id] as ItemFreshnessRecord).to_dictionary())
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "revision": _revision,
        "records": records_out,
    }

func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var candidate_revision: int = int(data.get("revision", -1))
    if candidate_revision < 0:
        return false
    var candidate: Dictionary = {}
    var raw_records: Variant = data.get("records", [])
    if typeof(raw_records) != TYPE_ARRAY:
        return false
    for raw: Variant in raw_records:
        if typeof(raw) != TYPE_DICTIONARY:
            return false
        var record_value: ItemFreshnessRecord = ItemFreshnessRecord.from_dictionary(raw as Dictionary)
        if record_value == null or record_value.version > candidate_revision or candidate.has(record_value.item_id):
            return false
        candidate[record_value.item_id] = record_value
    _revision = candidate_revision
    _records = candidate
    freshness_reset.emit()
    return true

func _set_record(record_value: ItemFreshnessRecord) -> bool:
    if record_value == null or not record_value.is_valid():
        return false
    _revision += 1
    var stored: ItemFreshnessRecord = record_value.copy()
    stored.version = _revision
    _records[stored.item_id] = stored
    freshness_changed.emit(stored.item_id, stored.version)
    return true

func _remove_record(item_id: String) -> bool:
    var key: String = item_id.strip_edges()
    if not _records.has(key):
        return false
    var previous: ItemFreshnessRecord = _records[key]
    _revision += 1
    _records.erase(key)
    freshness_removed.emit(key, previous.version)
    return true
