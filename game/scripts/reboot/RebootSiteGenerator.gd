extends RefCounted
class_name RebootSiteGenerator

const Art = preload("res://scripts/reboot/RebootArt.gd")

const WIDTH := 64
const HEIGHT := 64
const ARCHETYPES: Array[String] = ["rural_road"]
const WALL_FIXTURE_TAGS: Array[String] = [
    "kitchen_sink", "stove", "fridge", "bath_sink", "toilet", "bathtub",
    "shower", "washer", "water_heater", "store_sink"
]
const RESIDENTIAL_KINDS: Array[String] = ["farmhouse", "country_house", "small_trailer", "double_wide"]
const COMMERCIAL_KINDS: Array[String] = ["gas_station", "corner_store"]

static func generate(archetype: String, seed_value: int) -> Dictionary:
    var seed := maxi(1, seed_value)
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    var spec := _blank(seed)
    _generate_rural_road(spec, rng)
    _scatter_edge_nature(spec, rng)
    _clear_all_door_approaches(spec)
    _clear_spawn(spec)
    return spec

static func validate(spec: Dictionary) -> Dictionary:
    var failures: Array[String] = []
    var width := int(spec.get("width", 0))
    var height := int(spec.get("height", 0))
    var ground: PackedInt32Array = spec.get("ground", PackedInt32Array())
    if width != WIDTH or height != HEIGHT:
        failures.append("wrong map size")
    if ground.size() != WIDTH * HEIGHT:
        failures.append("ground array size mismatch")

    var spawn: Vector2i = spec.get("spawn", Vector2i(-1, -1))
    if not _inside(spawn):
        failures.append("spawn outside map")
    if spec.get("blocked", {}).has(spawn):
        failures.append("spawn blocked")
    if str(spec.get("archetype", "")) != "rural_road":
        failures.append("wrong archetype")

    var properties: Array = spec.get("properties", [])
    if properties.size() != 5:
        failures.append("rural road should contain four residences and one roadside business")
    var residential_count := 0
    var commercial_count := 0
    var farm_count := 0
    var substantial_count := 0
    var manufactured_count := 0
    for property_value in properties:
        var property: Dictionary = property_value
        var kind := str(property.get("kind", ""))
        if kind in RESIDENTIAL_KINDS:
            residential_count += 1
            if kind == "farmhouse":
                farm_count += 1
            if kind in ["farmhouse", "country_house"]:
                substantial_count += 1
            if kind in ["small_trailer", "double_wide"]:
                manufactured_count += 1
        elif kind in COMMERCIAL_KINDS:
            commercial_count += 1
    if residential_count != 4:
        failures.append("rural road needs exactly four residences")
    if commercial_count != 1:
        failures.append("rural road needs exactly one gas station or corner store")
    if farm_count != 1:
        failures.append("rural road needs one farm complex")
    if substantial_count < 2:
        failures.append("rural road needs multiple substantial houses")
    if manufactured_count < 1 or manufactured_count > 2:
        failures.append("rural road needs one or two manufactured homes")

    var rooms: Array = spec.get("rooms", [])
    var function_counts: Dictionary = {}
    for room_value in rooms:
        var room: Dictionary = room_value
        var function_name := str(room.get("function", ""))
        function_counts[function_name] = int(function_counts.get(function_name, 0)) + 1
    if int(function_counts.get("living_room", 0)) + int(function_counts.get("trailer_living", 0)) < 4:
        failures.append("not every residence has readable living space")
    if int(function_counts.get("kitchen", 0)) < 4:
        failures.append("not every residence has a kitchen")
    if int(function_counts.get("bathroom", 0)) < 5:
        failures.append("residences and roadside business need bathrooms")
    if int(function_counts.get("storefront", 0)) != 1:
        failures.append("roadside business storefront missing")
    if int(function_counts.get("stock_room", 0)) != 1:
        failures.append("roadside business stock room missing")
    if int(function_counts.get("manager_office", 0)) != 1:
        failures.append("roadside business manager office missing")

    var road_cells: Dictionary = spec.get("road_cells", {})
    if road_cells.size() < 60:
        failures.append("two-lane main road does not span the map")
    var side_road_cells: Dictionary = spec.get("side_road_cells", {})
    if side_road_cells.size() < 16:
        failures.append("rural sample lacks dirt/gravel side-road presence")

    var walls: Dictionary = spec.get("walls", {})
    var doors: Dictionary = spec.get("doors", {})
    var windows: Dictionary = spec.get("windows", {})
    var found_door_clutter := false
    for door_cell_value in doors.keys():
        var door_cell: Vector2i = door_cell_value
        if walls.has(door_cell) or windows.has(door_cell):
            failures.append("door overlaps wall/window at %s" % str(door_cell))
            break
        var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
        for delta in directions:
            var neighbor: Vector2i = door_cell + delta
            if spec.get("props", {}).has(neighbor):
                failures.append("clutter occupies door approach at %s" % str(neighbor))
                found_door_clutter = true
                break
        if found_door_clutter:
            break

    var fixture_tags: Dictionary = spec.get("fixture_tags", {})
    for cell_value in fixture_tags.keys():
        var cell: Vector2i = cell_value
        var tag := str(fixture_tags[cell])
        if tag in WALL_FIXTURE_TAGS and not _adjacent_to_wall_plane(spec, cell):
            failures.append("wall fixture floating in room: %s at %s" % [tag, str(cell)])
            break

    var props: Dictionary = spec.get("props", {})
    var utility_poles := 0
    var stop_signs := 0
    var traffic_lights := 0
    var vegetation := 0
    for prop_value in props.values():
        var prop := int(prop_value)
        if prop == Art.P_UTILITY_POLE:
            utility_poles += 1
        elif prop == Art.P_STOP_SIGN:
            stop_signs += 1
        elif prop == Art.P_TRAFFIC_LIGHT:
            traffic_lights += 1
        if prop in [Art.P_TREE, Art.P_TREE_LARGE, Art.P_BUSH, Art.P_SCRUB, Art.P_TALL_GRASS, Art.P_WEEDS, Art.P_WILDFLOWERS]:
            vegetation += 1
    if utility_poles < 8:
        failures.append("not enough roadside utility poles")
    if stop_signs < 1 or stop_signs > 3:
        failures.append("rural road should have sparse stop signs")
    if traffic_lights > 0:
        failures.append("rural road should not have traffic lights")
    if vegetation < 40:
        failures.append("rural sample needs more grass/tree/bush clutter")

    var roadish := 0
    for value in ground:
        if value in [Art.G_ROAD_H, Art.G_DIRT_ROAD_V, Art.G_GRAVEL, Art.G_ASPHALT]:
            roadish += 1
    if roadish > int(float(WIDTH * HEIGHT) * 0.13):
        failures.append("road/gravel dominates rural sample")

    return {"ok": failures.is_empty(), "failures": failures}

static func _blank(seed: int) -> Dictionary:
    var ground := PackedInt32Array()
    ground.resize(WIDTH * HEIGHT)
    ground.fill(Art.G_GRASS)
    return {
        "version": 3,
        "seed": seed,
        "archetype": "rural_road",
        "width": WIDTH,
        "height": HEIGHT,
        "ground": ground,
        "walls": {},
        "doors": {},
        "windows": {},
        "props": {},
        "blocked": {},
        "fixture_tags": {},
        "rooms": [],
        "buildings": [],
        "properties": [],
        "road_cells": {},
        "side_road_cells": {},
        "power_links": [],
        "spawn": Vector2i(4, 36),
        "main_road_y": 31,
        "title": "Rural Road",
    }

static func _generate_rural_road(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    var road_y := rng.randi_range(30, 32)
    spec["main_road_y"] = road_y
    _ground_rect(spec, Rect2i(0, road_y, WIDTH, 1), Art.G_ROAD_H)
    _ground_rect(spec, Rect2i(0, road_y - 1, WIDTH, 1), Art.G_DIRT)
    _ground_rect(spec, Rect2i(0, road_y + 1, WIDTH, 1), Art.G_DIRT)
    for x in range(WIDTH):
        spec["road_cells"][Vector2i(x, road_y)] = true

    var north_height := road_y - 5
    var south_y := road_y + 4
    var south_height := HEIGHT - south_y - 2
    var lots: Array[Dictionary] = [
        {"id":"north_west", "rect":Rect2i(1, 2, 19, north_height), "front_south":true},
        {"id":"north_center", "rect":Rect2i(22, 2, 19, north_height), "front_south":true},
        {"id":"north_east", "rect":Rect2i(43, 2, 20, north_height), "front_south":true},
        {"id":"south_west", "rect":Rect2i(2, south_y, 28, south_height), "front_south":false},
        {"id":"south_east", "rect":Rect2i(34, south_y, 28, south_height), "front_south":false},
    ]

    var business_index := rng.randi_range(0, 2)
    var farm_index := 3 if rng.randf() < 0.5 else 4
    var residential_pool: Array[String] = ["country_house", "country_house"]
    residential_pool.append("small_trailer" if rng.randf() < 0.55 else "double_wide")
    if rng.randf() < 0.28:
        residential_pool[1] = "double_wide" if residential_pool[2] == "small_trailer" else "small_trailer"
    _shuffle_strings(residential_pool, rng)
    var pool_index := 0

    for i in range(lots.size()):
        var lot: Dictionary = lots[i]
        if i == business_index:
            var business_kind := "gas_station" if rng.randf() < 0.55 else "corner_store"
            _build_business_property(spec, rng, lot, business_kind, road_y)
        elif i == farm_index:
            _build_residential_property(spec, rng, lot, "farmhouse", road_y)
        else:
            _build_residential_property(spec, rng, lot, residential_pool[pool_index], road_y)
            pool_index += 1

    _add_roadside_utilities(spec, rng, road_y)
    _add_sparse_stop_signs(spec, rng, road_y)
    spec["spawn"] = Vector2i(4, road_y + 2)

static func _build_residential_property(spec: Dictionary, rng: RandomNumberGenerator, lot: Dictionary, kind: String, road_y: int) -> void:
    var lot_rect: Rect2i = lot["rect"]
    var property_id := str(lot["id"])
    var front_south := bool(lot["front_south"])
    var size := _building_size(kind)
    var min_x := lot_rect.position.x + 2
    var max_x := lot_rect.end.x - size.x - 2
    var house_x := clampi(lot_rect.position.x + int((lot_rect.size.x - size.x) / 2) + rng.randi_range(-1, 1), min_x, maxi(min_x, max_x))
    var house_y: int
    if front_south:
        house_y = lot_rect.end.y - size.y - rng.randi_range(2, 4)
    else:
        house_y = lot_rect.position.y + rng.randi_range(2, 4)
    var building_rect := Rect2i(house_x, house_y, size.x, size.y)

    var front_door: Vector2i
    match kind:
        "farmhouse":
            front_door = _farmhouse(spec, building_rect, front_south, property_id)
        "country_house":
            front_door = _country_house(spec, building_rect, front_south, property_id)
        "double_wide":
            front_door = _double_wide(spec, building_rect, front_south, property_id)
        _:
            kind = "small_trailer"
            front_door = _small_trailer(spec, building_rect, front_south, property_id)

    var road_tile := Art.G_GRAVEL if kind in ["farmhouse", "country_house", "double_wide"] else Art.G_DIRT_ROAD_V
    _connector_to_road(spec, front_door, front_south, road_y, road_tile)
    _mailbox_for_connector(spec, front_door.x, front_south, road_y)
    _residential_back_features(spec, rng, lot_rect, building_rect, kind, front_south, property_id)
    _scatter_property_nature(spec, rng, lot_rect, building_rect, road_y, 8, 12)

    spec["properties"].append({
        "id":property_id,
        "kind":kind,
        "lot":lot_rect,
        "building_rect":building_rect,
        "front_south":front_south,
        "front_door":front_door,
        "commercial":false,
    })

static func _build_business_property(spec: Dictionary, rng: RandomNumberGenerator, lot: Dictionary, kind: String, road_y: int) -> void:
    var lot_rect: Rect2i = lot["rect"]
    var property_id := str(lot["id"])
    var front_south := bool(lot["front_south"])
    var size := Vector2i(13, 11)
    var building_x := lot_rect.position.x + int((lot_rect.size.x - size.x) / 2)
    var building_y: int
    if front_south:
        building_y = lot_rect.end.y - size.y - 2
    else:
        building_y = lot_rect.position.y + 2
    var rect := Rect2i(building_x, building_y, size.x, size.y)
    var door := _roadside_store(spec, rect, front_south, property_id, kind)

    _connector_to_road(spec, door, front_south, road_y, Art.G_GRAVEL)
    if kind == "gas_station":
        _gas_station_forecourt(spec, rect, door, front_south, road_y)
    else:
        _corner_store_frontage(spec, rect, door, front_south)
    _scatter_property_nature(spec, rng, lot_rect, rect, road_y, 5, 8)

    spec["properties"].append({
        "id":property_id,
        "kind":kind,
        "lot":lot_rect,
        "building_rect":rect,
        "front_south":front_south,
        "front_door":door,
        "commercial":true,
    })

static func _building_size(kind: String) -> Vector2i:
    match kind:
        "farmhouse":
            return Vector2i(15, 12)
        "country_house":
            return Vector2i(13, 11)
        "double_wide":
            return Vector2i(13, 10)
        _:
            return Vector2i(8, 11)

static func _farmhouse(spec: Dictionary, rect: Rect2i, front_south: bool, property_id: String) -> Vector2i:
    _shell(spec, rect, "farmhouse", property_id, Art.G_WOOD, Art.S_WALL_HOUSE)
    var x := rect.position.x
    var y := rect.position.y
    var right := rect.end.x - 1
    var bottom := rect.end.y - 1
    var split_x := x + 8
    var left_split := y + 6
    var right_split_a := y + 4
    var right_split_b := y + 8
    var utility_x := x + 4

    _partition_v(spec, split_x, y + 1, bottom - 1, [y + 3, y + 7])
    _partition_h(spec, left_split, x + 1, split_x - 1, [x + 3, x + 6])
    _partition_v(spec, utility_x, left_split + 1, bottom - 1, [bottom - 2])
    _partition_h(spec, right_split_a, split_x + 1, right - 1, [split_x + 3])
    _partition_h(spec, right_split_b, split_x + 1, right - 1, [split_x + 3])

    var living := Rect2i(x + 1, y + 1, 7, 5)
    var kitchen := Rect2i(x + 1, left_split + 1, 3, bottom - left_split - 1)
    var utility := Rect2i(utility_x + 1, left_split + 1, 3, bottom - left_split - 1)
    var primary := Rect2i(split_x + 1, y + 1, right - split_x - 1, 3)
    var bedroom := Rect2i(split_x + 1, right_split_a + 1, right - split_x - 1, 3)
    var bathroom := Rect2i(split_x + 1, right_split_b + 1, right - split_x - 1, bottom - right_split_b - 1)

    _room(spec, living, property_id, "living_room", Art.G_WOOD)
    _room(spec, kitchen, property_id, "kitchen", Art.G_TILE)
    _room(spec, utility, property_id, "utility", Art.G_LINOLEUM)
    _room(spec, primary, property_id, "primary_bedroom", Art.G_CARPET)
    _room(spec, bedroom, property_id, "bedroom", Art.G_CARPET)
    _room(spec, bathroom, property_id, "bathroom", Art.G_TILE)

    var door := _front_door(rect, front_south)
    _door(spec, door, Art.S_DOOR_CLOSED)
    _add_house_windows(spec, rect, front_south)
    _furnish_living(spec, living)
    _furnish_kitchen(spec, kitchen)
    _furnish_utility(spec, utility)
    _furnish_bedroom(spec, primary)
    _furnish_bedroom(spec, bedroom)
    _furnish_bathroom(spec, bathroom)
    return door

static func _country_house(spec: Dictionary, rect: Rect2i, front_south: bool, property_id: String) -> Vector2i:
    _shell(spec, rect, "country_house", property_id, Art.G_WOOD, Art.S_WALL_HOUSE)
    var x := rect.position.x
    var y := rect.position.y
    var right := rect.end.x - 1
    var bottom := rect.end.y - 1
    var split_x := x + 7
    var left_split := y + 5
    var right_split_a := y + 4
    var right_split_b := y + 7

    _partition_v(spec, split_x, y + 1, bottom - 1, [y + 3, y + 7])
    _partition_h(spec, left_split, x + 1, split_x - 1, [x + 3])
    _partition_h(spec, right_split_a, split_x + 1, right - 1, [split_x + 2])
    _partition_h(spec, right_split_b, split_x + 1, right - 1, [split_x + 2])

    var living := Rect2i(x + 1, y + 1, 6, 4)
    var kitchen := Rect2i(x + 1, left_split + 1, 6, bottom - left_split - 1)
    var primary := Rect2i(split_x + 1, y + 1, right - split_x - 1, 3)
    var bedroom := Rect2i(split_x + 1, right_split_a + 1, right - split_x - 1, 2)
    var bathroom := Rect2i(split_x + 1, right_split_b + 1, right - split_x - 1, bottom - right_split_b - 1)

    _room(spec, living, property_id, "living_room", Art.G_WOOD)
    _room(spec, kitchen, property_id, "kitchen", Art.G_TILE)
    _room(spec, primary, property_id, "primary_bedroom", Art.G_CARPET)
    _room(spec, bedroom, property_id, "bedroom", Art.G_CARPET)
    _room(spec, bathroom, property_id, "bathroom", Art.G_TILE)

    var door := _front_door(rect, front_south)
    _door(spec, door, Art.S_DOOR_CLOSED)
    _add_house_windows(spec, rect, front_south)
    _furnish_living(spec, living)
    _furnish_kitchen(spec, kitchen)
    _furnish_bedroom(spec, primary)
    _furnish_bedroom(spec, bedroom)
    _furnish_bathroom(spec, bathroom)
    return door

static func _double_wide(spec: Dictionary, rect: Rect2i, front_south: bool, property_id: String) -> Vector2i:
    _shell(spec, rect, "double_wide", property_id, Art.G_WOOD, Art.S_WALL_HOUSE)
    var x := rect.position.x
    var y := rect.position.y
    var right := rect.end.x - 1
    var bottom := rect.end.y - 1
    var split_x := x + 6
    var left_split := y + 5
    var right_split_a := y + 3
    var right_split_b := y + 6

    _partition_v(spec, split_x, y + 1, bottom - 1, [y + 2, y + 6])
    _partition_h(spec, left_split, x + 1, split_x - 1, [x + 3])
    _partition_h(spec, right_split_a, split_x + 1, right - 1, [split_x + 3])
    _partition_h(spec, right_split_b, split_x + 1, right - 1, [split_x + 3])

    var living := Rect2i(x + 1, y + 1, 5, 4)
    var kitchen := Rect2i(x + 1, left_split + 1, 5, bottom - left_split - 1)
    var primary := Rect2i(split_x + 1, y + 1, right - split_x - 1, 2)
    var bedroom := Rect2i(split_x + 1, right_split_a + 1, right - split_x - 1, 2)
    var bathroom := Rect2i(split_x + 1, right_split_b + 1, right - split_x - 1, bottom - right_split_b - 1)

    _room(spec, living, property_id, "living_room", Art.G_WOOD)
    _room(spec, kitchen, property_id, "kitchen", Art.G_TILE)
    _room(spec, primary, property_id, "primary_bedroom", Art.G_CARPET)
    _room(spec, bedroom, property_id, "bedroom", Art.G_CARPET)
    _room(spec, bathroom, property_id, "bathroom", Art.G_TILE)

    var door := _front_door(rect, front_south)
    _door(spec, door, Art.S_DOOR_CLOSED)
    _add_house_windows(spec, rect, front_south)
    _furnish_living(spec, living)
    _furnish_kitchen(spec, kitchen)
    _furnish_bedroom(spec, primary)
    _furnish_bedroom(spec, bedroom)
    _furnish_bathroom(spec, bathroom)
    return door

static func _small_trailer(spec: Dictionary, rect: Rect2i, front_south: bool, property_id: String) -> Vector2i:
    _shell(spec, rect, "small_trailer", property_id, Art.G_LINOLEUM, Art.S_WALL_HOUSE)
    var x := rect.position.x
    var y := rect.position.y
    var right := rect.end.x - 1
    var bottom := rect.end.y - 1
    var split_a := y + 4
    var split_b := y + 7
    _partition_h(spec, split_a, x + 1, right - 1, [x + 3])
    _partition_h(spec, split_b, x + 1, right - 1, [x + 3])
    var divider_x := x + 4
    _partition_v(spec, divider_x, split_b + 1, bottom - 1, [bottom - 2])

    var living := Rect2i(x + 1, y + 1, rect.size.x - 2, 3)
    var kitchen := Rect2i(x + 1, split_a + 1, rect.size.x - 2, 2)
    var bathroom := Rect2i(x + 1, split_b + 1, 3, bottom - split_b - 1)
    var bedroom := Rect2i(divider_x + 1, split_b + 1, right - divider_x - 1, bottom - split_b - 1)

    _room(spec, living, property_id, "trailer_living", Art.G_LINOLEUM)
    _room(spec, kitchen, property_id, "kitchen", Art.G_TILE)
    _room(spec, bathroom, property_id, "bathroom", Art.G_TILE)
    _room(spec, bedroom, property_id, "primary_bedroom", Art.G_CARPET)

    var door := _front_door(rect, front_south)
    _door(spec, door, Art.S_DOOR_CLOSED)
    _add_house_windows(spec, rect, front_south)
    _furnish_living(spec, living)
    _furnish_kitchen(spec, kitchen)
    _furnish_bathroom(spec, bathroom)
    _furnish_bedroom(spec, bedroom)
    return door

static func _roadside_store(spec: Dictionary, rect: Rect2i, front_south: bool, property_id: String, kind: String) -> Vector2i:
    var wall_tile := Art.S_WALL_LIGHT if kind == "gas_station" else Art.S_WALL_STORE
    _shell(spec, rect, kind, property_id, Art.G_TILE, wall_tile)
    var x := rect.position.x
    var y := rect.position.y
    var bottom := rect.end.y - 1
    var service_wall_x := x + 4

    var storefront_y := y + 1 if not front_south else y + 3
    var storefront := Rect2i(service_wall_x + 1, storefront_y, 7, 7)
    var stock := Rect2i(x + 1, y + 1, 3, 3)
    var office := Rect2i(x + 1, y + 5, 3, 1)
    var bathroom := Rect2i(x + 1, y + 7, 2, 2)

    _partition_v(spec, service_wall_x, y + 1, bottom - 1, [y + 3, y + 5, y + 8])
    _partition_h(spec, y + 4, x + 1, service_wall_x - 1, [x + 2])
    _partition_h(spec, y + 6, x + 1, service_wall_x - 1, [x + 2])

    _room(spec, storefront, property_id, "storefront", Art.G_TILE)
    _room(spec, stock, property_id, "stock_room", Art.G_CONCRETE)
    _room(spec, office, property_id, "manager_office", Art.G_CARPET)
    _room(spec, bathroom, property_id, "bathroom", Art.G_TILE)

    var door := _front_door(rect, front_south, service_wall_x + 4)
    _door(spec, door, Art.S_DOOR_CLOSED)
    _storefront_windows(spec, rect, front_south, door)
    _furnish_storefront(spec, storefront, kind)
    _furnish_stock_room(spec, stock)
    _furnish_office(spec, office)
    _furnish_bathroom(spec, bathroom)
    return door

static func _furnish_living(spec: Dictionary, room: Rect2i) -> void:
    if room.size.x < 3 or room.size.y < 2:
        return
    _fixture(spec, _wall_cell(room, "right", 1), Art.P_TV, "tv", true)
    var sofa := Vector2i(room.position.x + 1, room.position.y + mini(2, room.size.y - 1))
    _fixture(spec, sofa, Art.P_SOFA, "sofa", true)
    if room.size.x >= 5 and room.size.y >= 4:
        _fixture(spec, Vector2i(room.position.x + 3, room.position.y + 2), Art.P_TABLE, "coffee_table", true)

static func _furnish_kitchen(spec: Dictionary, room: Rect2i) -> void:
    if room.size.x < 2 or room.size.y < 2:
        return
    _fixture(spec, _wall_cell(room, "left", 0), Art.P_STOVE, "stove", true)
    _fixture(spec, _wall_cell(room, "left", 1), Art.P_SINK, "kitchen_sink", true)
    _fixture(spec, _wall_cell(room, "right", 0), Art.P_FRIDGE, "fridge", true)
    if room.size.x >= 4 and room.size.y >= 3:
        _fixture(spec, Vector2i(room.position.x + int(room.size.x / 2), room.position.y + int(room.size.y / 2)), Art.P_TABLE, "dining_table", true)

static func _furnish_bedroom(spec: Dictionary, room: Rect2i) -> void:
    if room.size.x < 2 or room.size.y < 2:
        return
    _fixture(spec, _wall_cell(room, "top", 1), Art.P_BED, "bed", true)
    if room.size.x >= 3:
        _fixture(spec, _wall_cell(room, "right", room.size.y - 1), Art.P_DRESSER, "dresser", true)

static func _furnish_bathroom(spec: Dictionary, room: Rect2i) -> void:
    if room.size.x < 2 or room.size.y < 1:
        return
    _fixture(spec, _wall_cell(room, "left", 0), Art.P_TOILET, "toilet", true)
    if room.size.y >= 2:
        _fixture(spec, _wall_cell(room, "left", 1), Art.P_SINK, "bath_sink", true)
    if room.size.x >= 3 and room.size.y >= 2:
        _fixture(spec, _wall_cell(room, "right", 0), Art.P_BATHTUB, "bathtub", true)

static func _furnish_utility(spec: Dictionary, room: Rect2i) -> void:
    if room.size.x < 2 or room.size.y < 2:
        return
    _fixture(spec, _wall_cell(room, "left", 0), Art.P_WASHER, "washer", true)
    _fixture(spec, _wall_cell(room, "right", 0), Art.P_WATER_HEATER, "water_heater", true)

static func _furnish_storefront(spec: Dictionary, room: Rect2i, kind: String) -> void:
    _fixture(spec, _wall_cell(room, "left", 1), Art.P_COUNTER, "checkout_counter", true)
    _fixture(spec, _wall_cell(room, "right", 1), Art.P_STORE_SHELF, "retail_shelf", true)
    _fixture(spec, _wall_cell(room, "right", 3), Art.P_STORE_SHELF, "retail_shelf", true)
    _fixture(spec, _wall_cell(room, "top", 3), Art.P_ICE_BOX if kind == "gas_station" else Art.P_VENDING, "cold_case", true)
    if room.size.x >= 7 and room.size.y >= 7:
        _fixture(spec, Vector2i(room.position.x + 3, room.position.y + 3), Art.P_STORE_SHELF, "retail_island", true)

static func _furnish_stock_room(spec: Dictionary, room: Rect2i) -> void:
    _fixture(spec, _wall_cell(room, "left", 0), Art.P_CRATE, "stock_crate", true)
    _fixture(spec, _wall_cell(room, "right", 0), Art.P_PALLET, "stock_pallet", true)

static func _furnish_office(spec: Dictionary, room: Rect2i) -> void:
    if room.size.x >= 2:
        _fixture(spec, _wall_cell(room, "top", 1), Art.P_DESK, "manager_desk", true)

static func _residential_back_features(spec: Dictionary, rng: RandomNumberGenerator, lot: Rect2i, house: Rect2i, kind: String, front_south: bool, property_id: String) -> void:
    var rear_y := lot.position.y + 1 if front_south else lot.end.y - 7
    match kind:
        "farmhouse":
            var barn := Rect2i(lot.position.x + 1, rear_y, 7, 6)
            _barn(spec, barn, property_id)
            var shed_x := lot.end.x - 6
            _shed(spec, Rect2i(shed_x, rear_y, 5, 5), property_id)
            var field_y := lot.position.y + 1 if front_south else house.end.y + 1
            var field_h := house.position.y - field_y - 1 if front_south else lot.end.y - field_y - 1
            if field_h >= 4:
                _ground_rect(spec, Rect2i(lot.position.x + 9, field_y, maxi(4, lot.size.x - 11), field_h), Art.G_FIELD_ROWS)
        "country_house":
            _shed(spec, Rect2i(lot.end.x - 6, rear_y, 5, 5), property_id)
            _prop(spec, Vector2i(lot.position.x + 3, rear_y + 2), Art.P_FIREWOOD, false)
        "double_wide":
            _shed(spec, Rect2i(lot.end.x - 6, rear_y, 5, 5), property_id)
            _prop(spec, Vector2i(lot.position.x + 3, rear_y + 1), Art.P_PROPANE_TANK, true)
            _prop(spec, Vector2i(lot.position.x + 5, rear_y + 3), Art.P_TIRE_PILE, true)
        _:
            _prop(spec, Vector2i(lot.position.x + 3, rear_y + 1), Art.P_PROPANE_TANK, true)
            _prop(spec, Vector2i(lot.position.x + 5, rear_y + 2), Art.P_TRASH_CAN, true)
            _prop(spec, Vector2i(lot.position.x + 7, rear_y + 3), Art.P_CARDBOARD, false)

    if rng.randf() < 0.45:
        _fence_line(spec, Vector2i(lot.position.x + 1, lot.position.y + 1), Vector2i(lot.position.x + 1, lot.end.y - 2))

static func _barn(spec: Dictionary, rect: Rect2i, property_id: String) -> void:
    _shell(spec, rect, "barn", property_id, Art.G_CONCRETE, Art.S_WALL_INDUSTRIAL)
    var room := Rect2i(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, rect.size.y - 2)
    _room(spec, room, property_id, "barn_storage", Art.G_CONCRETE)
    _door(spec, Vector2i(rect.position.x + int(rect.size.x / 2), rect.end.y - 1), Art.S_DOOR_CLOSED)
    _fixture(spec, _wall_cell(room, "left", 1), Art.P_WORKBENCH, "workbench", true)

static func _shed(spec: Dictionary, rect: Rect2i, property_id: String) -> void:
    if rect.size.x < 4 or rect.size.y < 4:
        return
    _shell(spec, rect, "shed", property_id, Art.G_CONCRETE, Art.S_WALL_HOUSE)
    var room := Rect2i(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, rect.size.y - 2)
    _room(spec, room, property_id, "shed_storage", Art.G_CONCRETE)
    _door(spec, Vector2i(rect.position.x + int(rect.size.x / 2), rect.end.y - 1), Art.S_DOOR_CLOSED)
    _fixture(spec, _wall_cell(room, "left", 1), Art.P_TOOL_CABINET, "tool_cabinet", true)

static func _gas_station_forecourt(spec: Dictionary, rect: Rect2i, door: Vector2i, front_south: bool, road_y: int) -> void:
    var pad_y: int
    if front_south:
        pad_y = rect.end.y
    else:
        pad_y = road_y + 2
    var top := mini(pad_y, road_y - 1 if front_south else rect.position.y - 3)
    var bottom := maxi(pad_y + 3, road_y if front_south else rect.position.y)
    var pad_rect := Rect2i(clampi(door.x - 4, 1, WIDTH - 9), top, 9, maxi(2, bottom - top))
    _ground_rect(spec, pad_rect, Art.G_ASPHALT)
    var pump_y := road_y - 3 if front_south else road_y + 3
    _prop(spec, Vector2i(door.x - 2, pump_y), Art.P_GAS_PUMP, true)
    _prop(spec, Vector2i(door.x + 2, pump_y), Art.P_GAS_PUMP, true)
    _prop(spec, Vector2i(clampi(door.x + 5, 1, WIDTH - 2), road_y - 2 if front_south else road_y + 2), Art.P_GAS_SIGN, false)

static func _corner_store_frontage(spec: Dictionary, rect: Rect2i, door: Vector2i, front_south: bool) -> void:
    var y := rect.end.y if front_south else rect.position.y - 1
    _ground_rect(spec, Rect2i(rect.position.x + 2, y, rect.size.x - 4, 1), Art.G_CONCRETE)
    _prop(spec, Vector2i(rect.position.x + 2, y), Art.P_TRASH_CAN, true)
    _prop(spec, Vector2i(rect.end.x - 3, y), Art.P_VENDING, true)

static func _connector_to_road(spec: Dictionary, door: Vector2i, front_south: bool, road_y: int, tile: int) -> void:
    var y0: int
    var y1: int
    if front_south:
        y0 = door.y + 1
        y1 = road_y - 1
    else:
        y0 = road_y + 1
        y1 = door.y - 1
    if y1 < y0:
        return
    _ground_rect(spec, Rect2i(door.x, y0, 1, y1 - y0 + 1), tile)
    for y in range(y0, y1 + 1):
        spec["side_road_cells"][Vector2i(door.x, y)] = true

static func _mailbox_for_connector(spec: Dictionary, drive_x: int, front_south: bool, road_y: int) -> void:
    var y := road_y - 2 if front_south else road_y + 2
    _prop(spec, Vector2i(clampi(drive_x + 1, 1, WIDTH - 2), y), Art.P_MAILBOX, false)

static func _add_roadside_utilities(spec: Dictionary, rng: RandomNumberGenerator, road_y: int) -> void:
    var pole_cells: Array[Vector2i] = []
    var x := rng.randi_range(3, 5)
    while x <= WIDTH - 4:
        var p := Vector2i(x, road_y - 2)
        if spec["side_road_cells"].has(p) or spec["props"].has(p):
            p = Vector2i(x, road_y + 2)
        _prop(spec, p, Art.P_UTILITY_POLE, true)
        if int(spec["props"].get(p, -1)) == Art.P_UTILITY_POLE:
            pole_cells.append(p)
        x += rng.randi_range(5, 7)
    for i in range(1, pole_cells.size()):
        spec["power_links"].append({"a":pole_cells[i - 1], "b":pole_cells[i]})

static func _add_sparse_stop_signs(spec: Dictionary, rng: RandomNumberGenerator, road_y: int) -> void:
    var connectors: Array[Vector2i] = []
    var seen_x: Dictionary = {}
    for cell_value in spec["side_road_cells"].keys():
        var cell: Vector2i = cell_value
        if seen_x.has(cell.x):
            continue
        seen_x[cell.x] = true
        connectors.append(cell)
    _shuffle_vectors(connectors, rng)
    var count := mini(2, connectors.size())
    for i in range(count):
        var connector := connectors[i]
        var sign_y := road_y - 2 if connector.y < road_y else road_y + 2
        var sign := Vector2i(clampi(connector.x - 1, 1, WIDTH - 2), sign_y)
        if spec["props"].has(sign):
            sign.x = clampi(connector.x + 1, 1, WIDTH - 2)
        _prop(spec, sign, Art.P_STOP_SIGN, false)

static func _scatter_property_nature(spec: Dictionary, rng: RandomNumberGenerator, lot: Rect2i, building: Rect2i, road_y: int, min_count: int, max_count: int) -> void:
    var count := rng.randi_range(min_count, max_count)
    for i in range(count):
        var p := Vector2i(
            rng.randi_range(lot.position.x + 1, lot.end.x - 2),
            rng.randi_range(lot.position.y + 1, lot.end.y - 2)
        )
        if p.y >= road_y - 2 and p.y <= road_y + 2:
            continue
        if building.grow(1).has_point(p):
            continue
        if not _free_for_prop(spec, p):
            continue
        var roll := rng.randf()
        if roll < 0.24:
            _prop(spec, p, Art.P_TREE if rng.randf() < 0.65 else Art.P_TREE_LARGE, true)
        elif roll < 0.50:
            _prop(spec, p, Art.P_BUSH, false)
        elif roll < 0.72:
            _prop(spec, p, Art.P_SCRUB, false)
        elif roll < 0.90:
            _prop(spec, p, Art.P_TALL_GRASS if rng.randf() < 0.5 else Art.P_WEEDS, false)
        else:
            _prop(spec, p, Art.P_WILDFLOWERS, false)

static func _scatter_edge_nature(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    for i in range(38):
        var side := rng.randi_range(0, 3)
        var p: Vector2i
        match side:
            0:
                p = Vector2i(rng.randi_range(0, WIDTH - 1), rng.randi_range(0, 4))
            1:
                p = Vector2i(rng.randi_range(WIDTH - 5, WIDTH - 1), rng.randi_range(0, HEIGHT - 1))
            2:
                p = Vector2i(rng.randi_range(0, WIDTH - 1), rng.randi_range(HEIGHT - 5, HEIGHT - 1))
            _:
                p = Vector2i(rng.randi_range(0, 4), rng.randi_range(0, HEIGHT - 1))
        if _free_for_prop(spec, p):
            var tile := Art.P_TREE if i % 3 == 0 else (Art.P_BUSH if i % 3 == 1 else Art.P_SCRUB)
            _prop(spec, p, tile, i % 3 == 0)

static func _front_door(rect: Rect2i, front_south: bool, preferred_x: int = -1) -> Vector2i:
    var x := preferred_x if preferred_x >= rect.position.x + 1 and preferred_x <= rect.end.x - 2 else rect.position.x + int(rect.size.x / 2)
    return Vector2i(x, rect.end.y - 1 if front_south else rect.position.y)

static func _add_house_windows(spec: Dictionary, rect: Rect2i, front_south: bool) -> void:
    var y := rect.end.y - 1 if front_south else rect.position.y
    var door := _front_door(rect, front_south)
    for x in [rect.position.x + 2, rect.end.x - 3]:
        var p := Vector2i(x, y)
        if p != door:
            _window(spec, p, Art.S_WINDOW)
    var side_y := rect.position.y + int(rect.size.y / 2)
    _window(spec, Vector2i(rect.position.x, side_y), Art.S_WINDOW)
    _window(spec, Vector2i(rect.end.x - 1, side_y), Art.S_WINDOW)

static func _storefront_windows(spec: Dictionary, rect: Rect2i, front_south: bool, door: Vector2i) -> void:
    var y := rect.end.y - 1 if front_south else rect.position.y
    for offset in [-3, -2, 2, 3]:
        var p := Vector2i(clampi(door.x + offset, rect.position.x + 1, rect.end.x - 2), y)
        if p != door:
            _window(spec, p, Art.S_WINDOW)

static func _shell(spec: Dictionary, rect: Rect2i, kind: String, property_id: String, floor_index: int, wall_index: int) -> void:
    _ground_rect(spec, rect, floor_index)
    spec["buildings"].append({"kind":kind, "property_id":property_id, "rect":rect})
    for x in range(rect.position.x, rect.end.x):
        _wall(spec, Vector2i(x, rect.position.y), wall_index)
        _wall(spec, Vector2i(x, rect.end.y - 1), wall_index)
    for y in range(rect.position.y, rect.end.y):
        _wall(spec, Vector2i(rect.position.x, y), wall_index)
        _wall(spec, Vector2i(rect.end.x - 1, y), wall_index)

static func _room(spec: Dictionary, rect: Rect2i, property_id: String, function_name: String, floor_index: int) -> void:
    if rect.size.x <= 0 or rect.size.y <= 0:
        return
    _ground_rect(spec, rect, floor_index)
    spec["rooms"].append({
        "name":"%s_%s" % [property_id, function_name],
        "property_id":property_id,
        "function":function_name,
        "rect":rect,
    })

static func _partition_v(spec: Dictionary, x: int, y0: int, y1: int, door_ys: Array) -> void:
    for y in range(y0, y1 + 1):
        if y in door_ys:
            _door(spec, Vector2i(x, y), Art.S_DOOR_CLOSED)
        else:
            _wall(spec, Vector2i(x, y), Art.S_WALL_LIGHT)

static func _partition_h(spec: Dictionary, y: int, x0: int, x1: int, door_xs: Array) -> void:
    for x in range(x0, x1 + 1):
        if x in door_xs:
            _door(spec, Vector2i(x, y), Art.S_DOOR_CLOSED)
        else:
            _wall(spec, Vector2i(x, y), Art.S_WALL_LIGHT)

static func _wall(spec: Dictionary, p: Vector2i, tile: int) -> void:
    if not _inside(p):
        return
    spec["doors"].erase(p)
    spec["windows"].erase(p)
    spec["walls"][p] = tile
    spec["blocked"][p] = true

static func _door(spec: Dictionary, p: Vector2i, tile: int) -> void:
    if not _inside(p):
        return
    spec["walls"].erase(p)
    spec["windows"].erase(p)
    spec["props"].erase(p)
    spec["fixture_tags"].erase(p)
    spec["blocked"].erase(p)
    spec["doors"][p] = tile

static func _window(spec: Dictionary, p: Vector2i, tile: int) -> void:
    if not _inside(p):
        return
    spec["walls"].erase(p)
    spec["doors"].erase(p)
    spec["windows"][p] = tile
    spec["blocked"][p] = true

static func _fixture(spec: Dictionary, p: Vector2i, tile: int, tag: String, blocks: bool) -> void:
    if not _can_place_prop(spec, p):
        return
    spec["props"][p] = tile
    spec["fixture_tags"][p] = tag
    if blocks:
        spec["blocked"][p] = true

static func _prop(spec: Dictionary, p: Vector2i, tile: int, blocks: bool) -> void:
    if not _can_place_prop(spec, p):
        return
    spec["props"][p] = tile
    if blocks:
        spec["blocked"][p] = true

static func _can_place_prop(spec: Dictionary, p: Vector2i) -> bool:
    if not _inside(p):
        return false
    if spec["walls"].has(p) or spec["doors"].has(p) or spec["windows"].has(p) or spec["props"].has(p):
        return false
    if _is_door_approach(spec, p):
        return false
    return true

static func _is_door_approach(spec: Dictionary, p: Vector2i) -> bool:
    var doors: Dictionary = spec.get("doors", {})
    if doors.has(p):
        return true
    return doors.has(p + Vector2i.UP) or doors.has(p + Vector2i.RIGHT) or doors.has(p + Vector2i.DOWN) or doors.has(p + Vector2i.LEFT)

static func _clear_all_door_approaches(spec: Dictionary) -> void:
    var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
    for door_value in spec["doors"].keys():
        var door: Vector2i = door_value
        for delta in directions:
            var p: Vector2i = door + delta
            if spec["props"].has(p):
                spec["props"].erase(p)
                spec["fixture_tags"].erase(p)
                if not spec["walls"].has(p) and not spec["windows"].has(p):
                    spec["blocked"].erase(p)

static func _fence_line(spec: Dictionary, a: Vector2i, b: Vector2i) -> void:
    if a.x == b.x:
        for y in range(mini(a.y, b.y), maxi(a.y, b.y) + 1):
            _prop(spec, Vector2i(a.x, y), Art.P_FENCE, true)
    elif a.y == b.y:
        for x in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
            _prop(spec, Vector2i(x, a.y), Art.P_FENCE, true)

static func _wall_cell(room: Rect2i, side: String, offset: int) -> Vector2i:
    match side:
        "right":
            return Vector2i(room.end.x - 1, clampi(room.position.y + offset, room.position.y, room.end.y - 1))
        "top":
            return Vector2i(clampi(room.position.x + offset, room.position.x, room.end.x - 1), room.position.y)
        "bottom":
            return Vector2i(clampi(room.position.x + offset, room.position.x, room.end.x - 1), room.end.y - 1)
        _:
            return Vector2i(room.position.x, clampi(room.position.y + offset, room.position.y, room.end.y - 1))

static func _adjacent_to_wall_plane(spec: Dictionary, p: Vector2i) -> bool:
    var walls: Dictionary = spec.get("walls", {})
    var windows: Dictionary = spec.get("windows", {})
    var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
    for delta in directions:
        var neighbor: Vector2i = p + delta
        if walls.has(neighbor) or windows.has(neighbor):
            return true
    return false

static func _ground_rect(spec: Dictionary, rect: Rect2i, tile: int) -> void:
    var clipped := rect.intersection(Rect2i(0, 0, WIDTH, HEIGHT))
    var ground: PackedInt32Array = spec["ground"]
    for y in range(clipped.position.y, clipped.end.y):
        for x in range(clipped.position.x, clipped.end.x):
            ground[y * WIDTH + x] = tile

static func _free_for_prop(spec: Dictionary, p: Vector2i) -> bool:
    if not _can_place_prop(spec, p):
        return false
    var ground: PackedInt32Array = spec["ground"]
    var tile := int(ground[p.y * WIDTH + p.x])
    return tile not in [Art.G_ROAD_H, Art.G_DIRT_ROAD_V, Art.G_GRAVEL, Art.G_ASPHALT]

static func _clear_spawn(spec: Dictionary) -> void:
    var spawn: Vector2i = spec["spawn"]
    for y in range(spawn.y - 1, spawn.y + 2):
        for x in range(spawn.x - 1, spawn.x + 2):
            var p := Vector2i(x, y)
            if not _inside(p):
                continue
            spec["props"].erase(p)
            spec["fixture_tags"].erase(p)
            if not spec["walls"].has(p) and not spec["windows"].has(p):
                spec["blocked"].erase(p)

static func _shuffle_strings(values: Array[String], rng: RandomNumberGenerator) -> void:
    for i in range(values.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var temp := values[i]
        values[i] = values[j]
        values[j] = temp

static func _shuffle_vectors(values: Array[Vector2i], rng: RandomNumberGenerator) -> void:
    for i in range(values.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var temp: Vector2i = values[i]
        values[i] = values[j]
        values[j] = temp

static func _inside(p: Vector2i) -> bool:
    return p.x >= 0 and p.y >= 0 and p.x < WIDTH and p.y < HEIGHT
