extends RefCounted
class_name CollisionOverrideState

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")

## Sparse durable collision exceptions keyed by stable WHAT entity ID.
## Only entities whose current blocking fact overrides type defaults need entries.

signal changed(entity_id)
signal state_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1

var _overrides: Dictionary = {}
var _revision: int = 0

func revision() -> int:
    return _revision

func has_override(entity_id: String) -> bool:
    return _overrides.has(entity_id)

func blocks_movement(entity_id: String) -> bool:
    return bool(_overrides.get(entity_id, false))

func entity_ids() -> Array[String]:
    var result: Array[String] = []
    for value: Variant in _overrides.keys():
        result.append(String(value))
    result.sort()
    return result

func set_override(entity_id: String, blocks_movement_value: bool) -> bool:
    if not EntityIdRules.is_valid(entity_id):
        return false
    if _overrides.has(entity_id) and bool(_overrides[entity_id]) == blocks_movement_value:
        return true
    _overrides[entity_id] = blocks_movement_value
    _revision += 1
    changed.emit(entity_id)
    return true

func clear_override(entity_id: String) -> bool:
    if not _overrides.has(entity_id):
        return false
    _overrides.erase(entity_id)
    _revision += 1
    changed.emit(entity_id)
    return true

func clear_all() -> void:
    if _overrides.is_empty():
        return
    _overrides.clear()
    _revision += 1
    state_reset.emit()

func snapshot() -> Dictionary:
    var entries: Array = []
    for entity_id: String in entity_ids():
        entries.append({
            "entity_id": entity_id,
            "blocks_movement": bool(_overrides[entity_id]),
        })
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "revision": _revision,
        "overrides": entries,
    }

func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var restored_revision: int = int(data.get("revision", -1))
    if restored_revision < 0:
        return false
    var values: Variant = data.get("overrides", [])
    if typeof(values) != TYPE_ARRAY:
        return false

    var restored: Dictionary = {}
    for value: Variant in values:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var entry: Dictionary = value
        var entity_id: String = String(entry.get("entity_id", ""))
        if not EntityIdRules.is_valid(entity_id) or restored.has(entity_id):
            return false
        if not entry.has("blocks_movement") or typeof(entry["blocks_movement"]) != TYPE_BOOL:
            return false
        restored[entity_id] = bool(entry["blocks_movement"])

    _overrides = restored
    _revision = restored_revision
    state_reset.emit()
    return true
