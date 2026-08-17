extends RefCounted
class_name ItemWeightQuery

## Read-only 13D query: stable WHAT item ID -> semantic profile weight.

enum Status {
    KNOWN,
    UNKNOWN,
    INVALID,
}

var _world: WorldState = null
var _catalog: ItemPhysicalPropertyCatalog = null

func _init(world_state: WorldState = null, catalog: ItemPhysicalPropertyCatalog = null) -> void:
    _world = world_state
    _catalog = catalog

func query(item_id: String) -> Dictionary:
    if _world == null or _catalog == null:
        return result(Status.UNKNOWN, 0, &"", "weight_query_unconfigured")
    if not _world.has_entity(item_id):
        return result(Status.UNKNOWN, 0, &"", "item_missing")
    var entity: WorldEntityRecord = _world.entity(item_id)
    if entity == null:
        return result(Status.UNKNOWN, 0, &"", "item_missing")
    var semantic: String = String(entity.semantic_type).strip_edges()
    if not semantic.begins_with("item.") or semantic.length() <= 5:
        return result(Status.INVALID, 0, entity.semantic_type, "not_item_entity")
    var profile: ItemPhysicalProfile = _catalog.profile(entity.semantic_type)
    if profile == null:
        return result(Status.UNKNOWN, 0, entity.semantic_type, "weight_unclassified")
    if not profile.is_valid():
        return result(Status.INVALID, 0, entity.semantic_type, "weight_profile_invalid")
    return result(Status.KNOWN, profile.weight_grams, entity.semantic_type, "")

static func result(status: int, weight_grams: int, semantic_type: StringName, reason: String) -> Dictionary:
    return {
        "status": status,
        "weight_grams": weight_grams,
        "semantic_type": semantic_type,
        "reason": reason,
    }
