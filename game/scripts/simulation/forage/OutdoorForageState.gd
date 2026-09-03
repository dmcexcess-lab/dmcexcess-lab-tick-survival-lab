extends RefCounted
class_name OutdoorForageState

## Sparse persistent depletion truth for outdoor forage patches.
## Records are created only when a real forage request first touches a patch.
## No item entities exist here; successful recovery materializes them through WHAT.

const SNAPSHOT_SCHEMA_VERSION: int = 1

var _records: Dictionary = {}
var _revision: int = 0

func revision() -> int:
    return _revision

func has_patch(patch_key: String) -> bool:
    return _records.has(patch_key.strip_edges())

func patch_record(patch_key: String) -> Dictionary:
    var key: String = patch_key.strip_edges()
    if not _records.has(key):
        return {}
    return (_records[key] as Dictionary).duplicate(true)

func patch_keys() -> Array[String]:
    var result: Array[String] = []
    for value: Variant in _records.keys():
        result.append(String(value))
    result.sort()
    return result

func ensure_patch(patch_key: String, capacity: int, stick_weight: int, stone_weight: int) -> bool:
    var key: String = patch_key.strip_edges()
    if key.is_empty() or capacity < 1 or stick_weight < 0 or stone_weight < 0 or stick_weight + stone_weight < 1:
        return false
    if _records.has(key):
        return true
    _records[key] = {
        "capacity": capacity,
        "consumed": 0,
        "stick_weight": stick_weight,
        "stone_weight": stone_weight,
    }
    _revision += 1
    return true

func remaining(patch_key: String) -> int:
    var record: Dictionary = patch_record(patch_key)
    if record.is_empty():
        return 0
    return maxi(0, int(record.get("capacity", 0)) - int(record.get("consumed", 0)))

func next_opportunity_index(patch_key: String) -> int:
    var record: Dictionary = patch_record(patch_key)
    return -1 if record.is_empty() else int(record.get("consumed", -1))

func consume_expected(patch_key: String, opportunity_index: int) -> bool:
    var key: String = patch_key.strip_edges()
    if not _records.has(key):
        return false
    var record: Dictionary = _records[key]
    var consumed: int = int(record.get("consumed", -1))
    var capacity: int = int(record.get("capacity", 0))
    if opportunity_index != consumed or consumed < 0 or consumed >= capacity:
        return false
    record["consumed"] = consumed + 1
    _records[key] = record
    _revision += 1
    return true

## Bounded compensation only for a commit that has not escaped the forage service.
func restore_expected(patch_key: String, opportunity_index: int) -> bool:
    var key: String = patch_key.strip_edges()
    if not _records.has(key):
        return false
    var record: Dictionary = _records[key]
    var consumed: int = int(record.get("consumed", -1))
    if consumed != opportunity_index + 1:
        return false
    record["consumed"] = opportunity_index
    _records[key] = record
    _revision += 1
    return true

func snapshot() -> Dictionary:
    var entries: Array = []
    for key: String in patch_keys():
        var record: Dictionary = _records[key]
        entries.append({
            "patch_key": key,
            "capacity": int(record.get("capacity", 0)),
            "consumed": int(record.get("consumed", 0)),
            "stick_weight": int(record.get("stick_weight", 0)),
            "stone_weight": int(record.get("stone_weight", 0)),
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
    for value: Variant in records_value:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var entry: Dictionary = value
        var key: String = String(entry.get("patch_key", "")).strip_edges()
        var capacity: int = int(entry.get("capacity", 0))
        var consumed: int = int(entry.get("consumed", -1))
        var stick_weight: int = int(entry.get("stick_weight", -1))
        var stone_weight: int = int(entry.get("stone_weight", -1))
        if key.is_empty() or restored.has(key) or capacity < 1 or consumed < 0 or consumed > capacity:
            return false
        if stick_weight < 0 or stone_weight < 0 or stick_weight + stone_weight < 1:
            return false
        restored[key] = {
            "capacity": capacity,
            "consumed": consumed,
            "stick_weight": stick_weight,
            "stone_weight": stone_weight,
        }
    _records = restored
    _revision = restored_revision
    return true
