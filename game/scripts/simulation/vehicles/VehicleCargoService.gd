extends RefCounted
class_name VehicleCargoService

var _world: WorldState
var _state: VehicleState
var _profiles: VehicleProfileCatalog
var _inventory: InventoryContainmentState
var _inventory_mutations: InventoryContainmentMutationService
var _weights: ItemWeightQuery

func _init(world: WorldState, state: VehicleState, profiles: VehicleProfileCatalog, inventory: InventoryContainmentState, inventory_mutations: InventoryContainmentMutationService, weights: ItemWeightQuery) -> void:
    _world = world
    _state = state
    _profiles = profiles
    _inventory = inventory
    _inventory_mutations = inventory_mutations
    _weights = weights

func is_ready() -> bool:
    return _world != null and _state != null and _profiles != null and _inventory != null and _inventory_mutations != null and _weights != null

func cargo_item_ids(vehicle_id: String) -> Array[String]:
    return _inventory.direct_contents(vehicle_id) if is_ready() and _state.has_vehicle(vehicle_id) else []

func used_grams(vehicle_id: String) -> int:
    var total: int = 0
    for item_id: String in cargo_item_ids(vehicle_id):
        var grams := _weights.item_weight_grams(item_id)
        if grams > 0:
            total += grams
    return total

func capacity_grams(vehicle_id: String) -> int:
    if not is_ready() or not _state.has_vehicle(vehicle_id):
        return 0
    var rec := _state.record(vehicle_id)
    var capacity := _profiles.cargo_grams(StringName(rec.get("kind", &"")))
    if &"cargo_rack" in rec.get("mods", []):
        capacity += 12000
    return capacity

func can_store(vehicle_id: String, item_id: String) -> bool:
    if not is_ready() or not _state.has_vehicle(vehicle_id) or not _world.has_entity(item_id):
        return false
    var grams := _weights.item_weight_grams(item_id)
    return grams > 0 and used_grams(vehicle_id) + grams <= capacity_grams(vehicle_id)

func store_from_actor(actor_id: String, vehicle_id: String, item_id: String) -> bool:
    if not can_store(vehicle_id, item_id) or not _inventory.contains_directly(actor_id, item_id):
        return false
    if not _inventory_mutations.clear_container(item_id):
        return false
    if _inventory_mutations.set_container(item_id, vehicle_id):
        return true
    _inventory_mutations.set_container(item_id, actor_id)
    return false

func take_to_actor(actor_id: String, vehicle_id: String, item_id: String) -> bool:
    if not is_ready() or not _inventory.contains_directly(vehicle_id, item_id):
        return false
    if not _inventory_mutations.clear_container(item_id):
        return false
    if _inventory_mutations.set_container(item_id, actor_id):
        return true
    _inventory_mutations.set_container(item_id, vehicle_id)
    return false
