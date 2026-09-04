extends RefCounted
class_name FlashlightItemState

## Persistent per-item switch truth for real flashlight entities.
## Equipment/placement are owned elsewhere; this owner only remembers whether an exact
## flashlight item is switched on so stowing/equipping never fabricates or loses that state.

signal switched_changed(item_id: String, switched_on: bool, version: int)
signal item_removed(item_id: String, version: int)
signal state_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1

var _revision: int = 0
var _records: Dictionary = {}

func revision() -> int:
    return _revision

func has_item(item_id: String) -> bool:
    return _records.has(item_id.strip_edges())

func is_switched_on(item_id: String) -> bool:
    var key: String = item_id.strip_edges()
    if key.is_empty() or not _records.has(key):
        return false
    var record: Dictionary = _records[key]
    return bool(record.get("switched_on", false))

func set_switched_on(item_id: String, switched_on: bool) -> bool:
    var key: String = item_id.strip_edges()
    if key.is_empty():
        return false
    if _records.has(key) and bool((_records[key] as Dictionary).get("switched_on", false)) == switched_on:
        return true
    _revision += 1
    _records[key] = {
        "switched_on": switched_on,
        "version": _revision,
    }
    switched_changed.emit(key, switched_on, _revision)
    return true

func remove_item(item_id: String) -> bool:
    var key: String = item_id.strip_edges()
    if key.is_empty() or not _records.has(key):
        return false
    _records.erase(key)
    _revision += 1
    item_removed.emit(key, _revision)
    return true

func snapshot() -> Dictionary:
    var ids: Array[String] = []
    for value: Variant in _records.keys():
        ids.append(String(value))
    ids.sort()
    var records: Array[Dictionary] = []
    for item_id: String in ids:
        var record: Dictionary = _records[item_id]
        records.append({
            "item_id": item_id,
            "switched_on": bool(record.get("switched_on", false)),
            "version": int(record.get("version", 0)),
        })
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "revision": _revision,
        "records": records,
    }

func load_snapshot(value: Dictionary) -> bool:
    if int(value.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var next_records: Dictionary = {}
    for record_value: Variant in value.get("records", []):
        if typeof(record_value) != TYPE_DICTIONARY:
            return false
        var record: Dictionary = record_value
        var item_id: String = String(record.get("item_id", "")).strip_edges()
        if item_id.is_empty() or next_records.has(item_id):
            return false
        next_records[item_id] = {
            "switched_on": bool(record.get("switched_on", false)),
            "version": maxi(0, int(record.get("version", 0))),
        }
    _records = next_records
    _revision = maxi(0, int(value.get("revision", 0)))
    state_reset.emit()
    return true
