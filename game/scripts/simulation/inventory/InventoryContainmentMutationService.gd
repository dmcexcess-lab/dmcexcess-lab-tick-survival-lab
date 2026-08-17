extends RefCounted
class_name InventoryContainmentMutationService

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")
const RecordClass = preload("res://scripts/simulation/inventory/InventoryContainerRecord.gd")

## Validated normal write path for persistent direct-containment truth.
## This service owns no timing, hand equipment, transfer action, capacity, rendering, or UI behavior.

var _state: InventoryContainmentState = null
var _world: WorldState = null

func _init(containment_state: InventoryContainmentState = null, world_state: WorldState = null) -> void:
    _state = containment_state
    _world = world_state

func is_ready() -> bool:
    return _state != null and _world != null

func enroll_container(container_id: String) -> bool:
    if not is_ready() or not EntityIdRules.is_valid(container_id):
        return false
    if _state.has_container(container_id) or not _world.has_entity(container_id):
        return false
    var version: int = _state.revision() + 1
    return _state._insert_container(RecordClass.new(container_id, version))

func remove_container(container_id: String) -> bool:
    if _state == null or not EntityIdRules.is_valid(container_id):
        return false
    if not _state.has_container(container_id):
        return false
    if not _state.direct_contents(container_id).is_empty():
        return false
    return _state._remove_container(container_id) != null

func set_container(item_id: String, container_id: String) -> bool:
    if not is_ready():
        return false
    if not EntityIdRules.is_valid(item_id) or not EntityIdRules.is_valid(container_id):
        return false
    if item_id == container_id:
        return false
    if not _state.has_container(container_id) or not _world.has_entity(container_id):
        return false
    if not _is_valid_unplaced_world_item(item_id):
        return false
    return _state._set_container_relation(item_id, container_id)

func clear_container(item_id: String) -> bool:
    if _state == null or not EntityIdRules.is_valid(item_id):
        return false
    if not _state.is_contained(item_id):
        return false
    return _state._set_container_relation(item_id, "")

func _is_valid_unplaced_world_item(item_id: String) -> bool:
    if _world == null or not _world.has_entity(item_id) or _world.has_placement(item_id):
        return false
    var entity: WorldEntityRecord = _world.entity(item_id)
    if entity == null:
        return false
    var semantic: String = String(entity.semantic_type).strip_edges()
    return semantic.begins_with("item.") and semantic.length() > 5
