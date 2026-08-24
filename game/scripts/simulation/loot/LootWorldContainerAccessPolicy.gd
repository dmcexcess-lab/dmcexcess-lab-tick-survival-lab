extends "res://scripts/simulation/items/transfer/ItemContainerAccessPolicy.gd"
class_name LootWorldContainerAccessPolicy

const Reach = preload("res://scripts/simulation/loot/LootInteractionReach.gd")

var _world: WorldState = null
var _loot_state: LootState = null
var _containment: InventoryContainmentState = null

func _init(
    world_state: WorldState = null,
    loot_state: LootState = null,
    containment_state: InventoryContainmentState = null
) -> void:
    _world = world_state
    _loot_state = loot_state
    _containment = containment_state

func is_ready() -> bool:
    return _world != null and _loot_state != null and _containment != null

func can_access(actor_id: String, container_id: String) -> bool:
    if not is_ready():
        return false
    if not _loot_state.has_container(container_id):
        return false
    if not _containment.has_container(container_id):
        return false
    return Reach.is_reachable(_world, actor_id, container_id)
