extends RefCounted
class_name InventoryContainerRecord

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")

## Immutable-style persistent containment capability state for one stable container ID.

var container_id: String = ""
var version: int = 1

func _init(value_container_id: String = "", value_version: int = 1) -> void:
    container_id = value_container_id
    version = value_version

func is_valid() -> bool:
    return EntityIdRules.is_valid(container_id) and version >= 1

func copy() -> InventoryContainerRecord:
    return InventoryContainerRecord.new(container_id, version)

func to_snapshot() -> Dictionary:
    return {
        "container_id": container_id,
        "version": version,
    }

static func from_snapshot(data: Dictionary) -> InventoryContainerRecord:
    var record := InventoryContainerRecord.new(
        String(data.get("container_id", "")),
        int(data.get("version", 0))
    )
    if not record.is_valid():
        return null
    return record
