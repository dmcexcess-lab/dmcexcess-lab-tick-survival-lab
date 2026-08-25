extends "res://scripts/simulation/items/transfer/ItemContainerAccessPolicy.gd"
class_name LootWorldContainerAccessPolicy

const ReachClass = preload("res://scripts/simulation/interaction/WorldInteractionReachQuery.gd")

var _world: WorldState = null
var _loot_state: LootState = null
var _containment: InventoryContainmentState = null
var _reach: WorldInteractionReachQuery = null

func _init(
    world_state: WorldState = null,
    loot_state: LootState = null,
    containment_state: InventoryContainmentState = null,
    reach_query: WorldInteractionReachQuery = null
) -> void:
    _world = world_state
    _loot_state = loot_state
    _containment = containment_state
    _reach = reach_query if reach_query != null else ReachClass.new(_world)

func is_ready() -> bool:
    return _world != null and _loot_state != null and _containment != null \
        and _reach != null and _reach.is_ready()

func can_access(actor_id: String, container_id: String) -> bool:
    if not is_ready():
        return false
    if not _loot_state.has_container(container_id):
        return false
    if not _containment.has_container(container_id):
        return false
    return _reach.target_reachable(actor_id, container_id, ReachClass.CONTACT_FORWARD)
