extends RefCounted
class_name VehicleWorldSeeder

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

var _world: WorldState
var _mutations: WorldMutationService
var _query: SpatialQueryService
var _collisions: CollisionCatalog
var _inventory_mutations: InventoryContainmentMutationService
var _profiles: VehicleProfileCatalog
var _state: VehicleState
var _seed: int

func _init(world: WorldState, mutations: WorldMutationService, query: SpatialQueryService, collisions: CollisionCatalog, inventory_mutations: InventoryContainmentMutationService, profiles: VehicleProfileCatalog, state: VehicleState, world_seed: int) -> void:
    _world = world
    _mutations = mutations
    _query = query
    _collisions = collisions
    _inventory_mutations = inventory_mutations
    _profiles = profiles
    _state = state
    _seed = world_seed

func seed_near(actor_id: String, radius: int = 42) -> int:
    if _world == null or _mutations == null or _query == null or _collisions == null or _inventory_mutations == null or _profiles == null or _state == null:
        return 0
    var actor_placement := _world.placement(actor_id)
    if actor_placement == null:
        return 0
    for kind: StringName in _profiles.kinds():
        _collisions.register(_profiles.semantic_type(kind), true)
    var candidates: Array[Vector2i] = []
    var center := actor_placement.anchor
    for y in range(center.y - radius, center.y + radius + 1):
        for x in range(center.x - radius, center.x + radius + 1):
            var cell := Vector2i(x, y)
            if not _world.has_terrain(cell):
                continue
            var terrain := String(_world.terrain_at(cell)).to_lower()
            if "road" in terrain or "driveway" in terrain or "parking" in terrain or "pavement" in terrain:
                candidates.append(cell)
    candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        var ha := _stable_hash(a)
        var hb := _stable_hash(b)
        return ha < hb if ha != hb else (a.y < b.y or (a.y == b.y and a.x < b.x))
    )
    var made: int = 0
    var cursor: int = 0
    for kind: StringName in _profiles.kinds():
        while cursor < candidates.size():
            var anchor: Vector2i = candidates[cursor]
            cursor += 1
            if anchor.distance_to(center) < 6.0:
                continue
            var heading := posmod(_stable_hash(anchor), 4) * 3
            var cardinal_facing := VehicleHeading.cardinal_facing(heading)
            var footprint := _profiles.footprint(kind)
            var check := _query.query_footprint(anchor, cardinal_facing, footprint, "", true)
            if check == null or not check.is_clear():
                continue
            var vehicle_id := "vehicle:%d:%s:%d:%d" % [_seed, String(kind), anchor.x, anchor.y]
            if _world.has_entity(vehicle_id):
                break
            if _mutations.create_entity(_profiles.semantic_type(kind), vehicle_id).is_empty():
                continue
            if not _mutations.set_placement(vehicle_id, Layers.Channel.OBJECT, anchor, cardinal_facing, footprint):
                _mutations.remove_entity(vehicle_id)
                continue
            if not _inventory_mutations.enroll_container(vehicle_id):
                _mutations.remove_entity(vehicle_id)
                continue
            var key_item_id: String = ""
            if _profiles.is_motorized(kind):
                key_item_id = "%s:key" % vehicle_id
                if _mutations.create_entity(VehicleItemCatalog.VEHICLE_KEY, key_item_id) != key_item_id:
                    _inventory_mutations.remove_container(vehicle_id)
                    _mutations.remove_entity(vehicle_id)
                    continue
                var key_cell := anchor + Vector2i(2, 0)
                _mutations.set_placement(key_item_id, Layers.Channel.LOOSE_ITEM, key_cell, Facing.Value.NORTH, SpatialFootprint.single_cell())
            var max_fuel := _profiles.max_fuel(kind)
            var fuel := 0 if max_fuel <= 0 else maxi(1, max_fuel / 2 + posmod(_stable_hash(anchor + Vector2i(3, 7)), maxi(1, max_fuel / 2)))
            var locked := _profiles.is_motorized(kind) and posmod(_stable_hash(anchor), 100) < 70
            if not _state.create_vehicle(vehicle_id, kind, fuel, locked, heading, key_item_id):
                if not key_item_id.is_empty():
                    _mutations.remove_entity(key_item_id)
                _inventory_mutations.remove_container(vehicle_id)
                _mutations.remove_entity(vehicle_id)
                continue
            _seed_vehicle_supplies(vehicle_id, kind, anchor)
            made += 1
            break
    return made

func _seed_vehicle_supplies(vehicle_id: String, kind: StringName, anchor: Vector2i) -> void:
    var supplies: Array[StringName] = []
    if kind == VehicleProfileCatalog.CAR or kind == VehicleProfileCatalog.TRUCK:
        if posmod(_stable_hash(anchor + Vector2i(11, 2)), 100) < 55:
            supplies.append(VehicleItemCatalog.GAS_CAN)
        if posmod(_stable_hash(anchor + Vector2i(5, 17)), 100) < 35:
            supplies.append(VehicleItemCatalog.CARGO_RACK)
        if posmod(_stable_hash(anchor + Vector2i(7, 23)), 100) < 30:
            supplies.append(VehicleItemCatalog.SPARE_WHEEL)
    elif kind == VehicleProfileCatalog.MOTORCYCLE and posmod(_stable_hash(anchor + Vector2i(13, 3)), 100) < 30:
        supplies.append(VehicleItemCatalog.GAS_CAN)
    for index: int in range(supplies.size()):
        var item_id := "%s:supply:%d" % [vehicle_id, index]
        if _mutations.create_entity(supplies[index], item_id) != item_id:
            continue
        if not _inventory_mutations.set_container(item_id, vehicle_id):
            _mutations.remove_entity(item_id)

func _stable_hash(cell: Vector2i) -> int:
    var value: int = _seed * 1103515245 + cell.x * 73856093 + cell.y * 19349663
    return absi(value ^ (value >> 13))
