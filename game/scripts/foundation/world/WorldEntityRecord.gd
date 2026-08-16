extends RefCounted
class_name WorldEntityRecord

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")

## Foundation-level persistent entity identity.
## Mechanic-specific durable state lives in later typed systems keyed by this ID.

var id: String = ""
var semantic_type: StringName = &""

func _init(entity_id: String = "", entity_type: StringName = &"") -> void:
    id = entity_id
    semantic_type = entity_type

func is_valid() -> bool:
    return EntityIdRules.is_valid(id) and not String(semantic_type).strip_edges().is_empty()

func copy() -> WorldEntityRecord:
    return WorldEntityRecord.new(id, semantic_type)

func to_snapshot() -> Dictionary:
    return {
        "id": id,
        "semantic_type": String(semantic_type),
    }

static func from_snapshot(data: Dictionary) -> WorldEntityRecord:
    var record := WorldEntityRecord.new(
        String(data.get("id", "")),
        StringName(String(data.get("semantic_type", "")))
    )
    if not record.is_valid():
        return null
    return record
