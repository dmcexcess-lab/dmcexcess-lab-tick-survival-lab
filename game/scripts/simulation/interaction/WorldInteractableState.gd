extends RefCounted
class_name WorldInteractableState

## Sparse persistent state for player-modified world interactables.
## Door OPEN/CLOSED remains owned by DoorStateStore; this store owns only orthogonal
## security, fortification, window aperture, breakage and destruction truth.
## Unmodified exterior openings derive independent deterministic lock defaults from
## stable target identity; no house-level lock flag or key inventory exists.

signal state_changed(target_id, version, reason)
signal state_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1
const MAX_BOARDS: int = 3
const DOOR_LOCK_PERCENT: int = 55
const WINDOW_LOCK_PERCENT: int = 35

var _records: Dictionary = {}
var _revision: int = 0

func revision() -> int:
    return _revision

func has_record(target_id: String) -> bool:
    return _records.has(target_id.strip_edges())

func version(target_id: String) -> int:
    return int(_record(target_id).get("version", 0))

func is_locked(target_id: String) -> bool:
    return bool(_record(target_id).get("locked", false))

func is_broken(target_id: String) -> bool:
    return bool(_record(target_id).get("broken", false))

func board_count(target_id: String) -> int:
    return int(_record(target_id).get("board_count", 0))

func window_open(target_id: String) -> bool:
    return bool(_record(target_id).get("window_open", false))

func is_destroyed(target_id: String) -> bool:
    return bool(_record(target_id).get("destroyed", false))

func set_locked(target_id: String, value: bool, reason: StringName = &"lock_changed") -> bool:
    return _set_field(target_id, "locked", value, reason)

func set_broken(target_id: String, value: bool, reason: StringName = &"breakage_changed") -> bool:
    return _set_field(target_id, "broken", value, reason)

func set_board_count(target_id: String, value: int, reason: StringName = &"boards_changed") -> bool:
    if value < 0 or value > MAX_BOARDS:
        return false
    return _set_field(target_id, "board_count", value, reason)

func set_window_open(target_id: String, value: bool, reason: StringName = &"window_aperture_changed") -> bool:
    return _set_field(target_id, "window_open", value, reason)

func set_destroyed(target_id: String, value: bool, reason: StringName = &"destroyed_changed") -> bool:
    return _set_field(target_id, "destroyed", value, reason)

func record(target_id: String) -> Dictionary:
    return _record(target_id).duplicate(true)

func snapshot() -> Dictionary:
    var entries: Array[Dictionary] = []
    var ids: Array[String] = []
    for key: Variant in _records.keys():
        ids.append(String(key))
    ids.sort()
    for target_id: String in ids:
        entries.append((_records[target_id] as Dictionary).duplicate(true))
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "revision": _revision,
        "records": entries,
    }

func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var restored_revision: int = int(data.get("revision", -1))
    var values: Variant = data.get("records", [])
    if restored_revision < 0 or typeof(values) != TYPE_ARRAY:
        return false
    var restored: Dictionary = {}
    for value: Variant in values:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var entry: Dictionary = value
        var target_id: String = String(entry.get("target_id", "")).strip_edges()
        var board_count_value: int = int(entry.get("board_count", -1))
        var entry_version: int = int(entry.get("version", -1))
        if target_id.is_empty() or restored.has(target_id) \
            or board_count_value < 0 or board_count_value > MAX_BOARDS \
            or entry_version < 1 or entry_version > restored_revision:
            return false
        restored[target_id] = {
            "target_id": target_id,
            "locked": bool(entry.get("locked", _default_locked(target_id))),
            "broken": bool(entry.get("broken", false)),
            "board_count": board_count_value,
            "window_open": bool(entry.get("window_open", false)),
            "destroyed": bool(entry.get("destroyed", false)),
            "version": entry_version,
        }
    _records = restored
    _revision = restored_revision
    state_reset.emit()
    return true

func _record(target_id: String) -> Dictionary:
    var key: String = target_id.strip_edges()
    if key.is_empty() or not _records.has(key):
        return {
            "target_id": key,
            "locked": _default_locked(key),
            "broken": false,
            "board_count": 0,
            "window_open": false,
            "destroyed": false,
            "version": 0,
        }
    return _records[key]

func _default_locked(target_id: String) -> bool:
    var lowered := target_id.to_lower()
    var threshold := 0
    if lowered.begins_with("door"):
        threshold = DOOR_LOCK_PERCENT
    elif lowered.begins_with("window"):
        threshold = WINDOW_LOCK_PERCENT
    else:
        return false
    return _stable_percent(target_id) < threshold

func _stable_percent(value: String) -> int:
    var hash_value: int = 17
    for index: int in range(value.length()):
        hash_value = (hash_value * 31 + value.unicode_at(index)) % 1000003
    return posmod(hash_value, 100)

func _set_field(target_id: String, field: String, value: Variant, reason: StringName) -> bool:
    var key: String = target_id.strip_edges()
    if key.is_empty() or field.is_empty():
        return false
    var current: Dictionary = _record(key).duplicate(true)
    if current.get(field) == value:
        return true
    current[field] = value
    _revision += 1
    current["target_id"] = key
    current["version"] = _revision
    _records[key] = current
    state_changed.emit(key, _revision, reason)
    return true
