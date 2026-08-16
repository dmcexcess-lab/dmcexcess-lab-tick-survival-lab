extends RefCounted
class_name RebootSiteGenerator

const Art = preload("res://scripts/reboot/RebootArt.gd")

const WIDTH := 64
const HEIGHT := 64
const MIN_ROOM_SIDE := 3
const ARCHETYPES: Array[String] = ["rural_road"]
const ROAD_VARIANTS: Array[String] = ["straight", "bend", "crossroads"]
const WALL_FIXTURE_TAGS: Array[String] = [
    "kitchen_sink", "stove", "fridge", "bath_sink", "toilet", "bathtub",
    "shower", "washer", "water_heater", "store_sink"
]
const RESIDENTIAL_KINDS: Array[String] = ["farmhouse", "country_house", "small_trailer", "double_wide"]
const COMMERCIAL_KINDS: Array[String] = ["gas_station", "corner_store"]
const ROAD_TILES: Array[int] = [
    Art.G_ROAD_V, Art.G_ROAD_H, Art.G_ROAD_NE, Art.G_ROAD_ES, Art.G_ROAD_SW,
    Art.G_ROAD_WN, Art.G_ROAD_NES, Art.G_ROAD_ESW, Art.G_ROAD_NSW,
    Art.G_ROAD_NEW, Art.G_ROAD_CROSS, Art.G_ROAD_END_N, Art.G_ROAD_END_E,
    Art.G_ROAD_END_S, Art.G_ROAD_END_W
]

static func generate(archetype: String, seed_value: int) -> Dictionary:
    var seed := maxi(1, seed_value)
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    var spec := _blank(seed)
    _generate_rural_road(spec, rng)
    _scatter_edge_nature(spec, rng)
    _normalize_door_geometry(spec)
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

    var road_variant := str(spec.get("road_variant", ""))
    if road_variant not in ROAD_VARIANTS:
        failures.append("invalid road variant")

    var properties: Array = spec.get("properties", [])
    if properties.size() != 5:
        failures.append("rural road should contain four residences and one roadside business")
    var residential_count := 0
    var commercial_count := 0
    var farm_count := 0
    var substantial_count := 0
    var manufactured_count := 0
    var commercial_property_id := ""
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
            commercial_property_id = str(property.get("id", ""))
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
    var business_sizes: Dictionary = {}
    for room_value in rooms:
        var room: Dictionary = room_value
        var function_name := str(room.get("function", ""))
        var rect: Rect2i = room.get("rect", Rect2i())
        function_counts[function_name] = int(function_counts.get(function_name, 0)) + 1
        if rect.size.x < MIN_ROOM_SIDE or rect.size.y < MIN_ROOM_SIDE:
            failures.append("room smaller than 3x3: %s %s" % [function_name, str(rect.size)])
            break
        if str(room.get("property_id", "")) == commercial_property_id:
            business_sizes[function_name] = rect.size
    if int(function_counts.get("living_room", 0)) + int(function_counts.get("trailer_living", 0)) < 4:
        failures.append("not every residence has readable living space")
    if int(function_counts.get("kitchen", 0)) < 4:
        failures.append("not every residence has a kitchen")
    if int(function_counts.get("bathroom", 0)) < 5:
        failures.append("residences and roadside business need bathrooms")
    if business_sizes.get("storefront", Vector2i.ZERO) != Vector2i(7, 7):
        failures.append("roadside business storefront must be 7x7")
    if business_sizes.get("stock_room", Vector2i.ZERO) != Vector2i(3, 3):
        failures.append("roadside business stock room must be 3x3")
    if business_sizes.get("manager_office", Vector2i.ZERO) != Vector2i(3, 3):
        failures.append("roadside business manager office must be 3x3")
    if business_sizes.get("bathroom", Vector2i.ZERO) != Vector2i(3, 3):
        failures.append("roadside business bathroom must be 3x3")

    var road_cells: Dictionary = spec.get("road_cells", {})
    if road_cells.size() < 60:
        failures.append("main road does not span the map")
    if road_variant == "crossroads" and int(spec.get("crossroad_x", -1)) < 0:
        failures.append("crossroads variant missing crossing road")
    var side_road_cells: Dictionary = spec.get("side_road_cells", {})
    if side_road_cells.size() < 16:
        failures.append("rural sample lacks dirt/gravel side-road presence")

    var walls: Dictionary = spec.get("walls", {})
    var doors: Dictionary = spec.get("doors", {})
    var windows: Dictionary = spec.get("windows", {})
    var door_axes: Dictionary = spec.get("door_axes", {})
    var props: Dictionary = spec.get("props", {})
    for door_cell_value in doors.keys():
        var door_cell: Vector2i = door_cell_value
        var axis := str(door_axes.get(door_cell, ""))
        if walls.has(door_cell) or windows.has(door_cell):
            failures.append("door overlaps wall/window at %s" % str(door_cell))
            break
        if axis not in ["h", "v"]:
            failures.append("door missing wall-axis metadata at %s" % str(door_cell))
            break
        var approach_a := door_cell + (Vector2i.UP if axis == "h" else Vector2i.LEFT)
        var approach_b := door_cell + (Vector2i.DOWN if axis == "h" else Vector2i.RIGHT)
        var wall_a := door_cell + (Vector2i.LEFT if axis == "h" else Vector2i.UP)
        var wall_b := door_cell + (Vector2i.RIGHT if axis == "h" else Vector2i.DOWN)
        if _structural_at(spec, approach_a) or _structural_at(spec, approach_b):
            failures.append("door has perpendicular wall geometry at %s" % str(door_cell))
            break
        if props.has(approach_a) or props.has(approach_b):
            failures.append("clutter occupies door approach at %s" % str(door_cell))
            break
        if not _structural_at(spec, wall_a) or not _structural_at(spec, wall_b):
            failures.append("door is not seated in one continuous wall at %s" % str(door_cell))
            break

    var fixture_tags: Dictionary = spec.get("fixture_tags", {})
    for cell_value in fixture_tags.keys():
        var cell: Vector2i = cell_value
        var tag := str(fixture_tags[cell])
        if tag in WALL_FIXTURE_TAGS and not _adjacent_to_wall_plane(spec, cell):
            failures.append("wall fixture floating in room: %s at %s" % [tag, str(cell)])
            break

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
        var tile := int(value)
        if tile in ROAD_TILES or tile in [Art.G_DIRT_ROAD_V, Art.G_GRAVEL, Art.G_ASPHALT]:
            roadish += 1
    if roadish > int(float(WIDTH * HEIGHT) * 0.13):
        failures.append("road/gravel dominates rural sample")

    return {"ok": failures.is_empty(), "failures": failures}

static func _blank(seed: int) -> Dictionary:
    var ground := PackedInt32Array()
    ground.resize(WIDTH * HEIGHT)
    ground.fill(Art.G_GRASS)
    return {
        "version": 4,
        "seed": seed,
        "archetype": "rural_road",
        "width": WIDTH,
        "height": HEIGHT,
        "ground": ground,
        "walls": {},
        "doors": {},
        "door_axes": {},
        "door_clear": {},
        "windows": {},
        "props": {},
        "blocked": {},
        "fixture_tags": {},
        "rooms": [],
        "buildings": [],
        "properties": [],
        "road_cells": {},
        "side_road_cells": {},
        "road_y_by_x": {},
        "road_variant": "straight",
        "crossroad_x": -1,
        "power_links": [],
        "spawn": Vector2i(4, 36),
        "main_road_y": 31,
        "title": "Rural Road",
    }

static func _generate_rural_road(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    var base_y := rng.randi_range(30, 32)
    var variant := ROAD_VARIANTS[rng.randi_range(0, ROAD_VARIANTS.size() - 1)]
    spec["road_variant"] = variant
    spec["main_road_y"] = base_y

    match variant:
        "bend":
            _lay_bending_main_road(spec, rng, base_y)
        "crossroads":
            _lay_straight_main_road(spec, base_y)
            _lay_crossroad(spec, 23)
        _:
            _lay_straight_main_road(spec, base_y)

    _finalize_main_road_tiles(spec)
    _paint_road_shoulders(spec)

    var min_road_y := HEIGHT
    var max_road_y := 0
    for y_value in spec["road_y_by_x"].values():
        var y := int(y_value)
        min_road_y = mini(min_road_y, y)
        max_road_y = maxi(max_road_y, y)

    var north_end := min_road_y - 4
    var north_height := maxi(18, north_end - 2)
    var south_y := max_road_y + 4
    var south_height := maxi(18, HEIGHT - south_y - 2)
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
    if rng.randf() < 0.30:
        residential_pool[1] = "double_wide" if residential_pool[2] == "small_trailer" else "small_trailer"
    _shuffle_strings(residential_pool, rng)
    var pool_index := 0

    for i in range(lots.size()):
        var lot: Dictionary = lots[i]
        if i == business_index:
            var business_kind := "gas_station" if rng.randf() < 0.55 else "corner_store"
            _build_business_property(spec, rng, lot, business_kind)
        elif i == farm_index:
            _build_residential_property(spec, rng, lot, "farmhouse")
        else:
            _build_residential_property(spec, rng, lot, residential_pool[pool_index])
            pool_index += 1

    _add_roadside_utilities(spec, rng)
    _add_sparse_stop_signs(spec, rng)
    var spawn_y := _road_y_at_x(spec, 4) + 2
    spec["spawn"] = Vector2i(4, clampi(spawn_y, 1, HEIGHT - 2))

static func _lay_straight_main_road(spec: Dictionary, y: int) -> void:
    for x in range(WIDTH):
        var p := Vector2i(x, y)
        spec["road_cells"][p] = true
        spec["road_y_by_x"][x] = y

static func _lay_bending_main_road(spec: Dictionary, rng: RandomNumberGenerator, base_y: int) -> void:
    var direction := -1 if rng.randf() < 0.5 else 1
    var x1 := rng.randi_range(20, 25)
    var x2 := rng.randi_range(38, 43)
    var y0 := base_y
    var y1 := base_y + direction * 2
    var y2 := base_y + direction * 4

    for x in range(0, x1 + 1):
        spec["road_cells"][Vector2i(x, y0)] = true
        spec["road_y_by_x"][x] = y0
    for y in range(mini(y0, y1), maxi(y0, y1) + 1):
        spec["road_cells"][Vector2i(x1, y)] = true
    for x in range(x1, x2 + 1):
        spec["road_cells"][Vector2i(x, y1)] = true
        spec["road_y_by_x"][x] = y1
    for y in range(mini(y1, y2), maxi(y1, y2) + 1):
        spec["road_cells"][Vector2i(x2, y)] = true
    for x in range(x2, WIDTH):
        spec["road_cells"][Vector2i(x, y2)] = true
        spec["road_y_by_x"][x] = y2

static func _lay_crossroad(spec: Dictionary, cross_x: int) -> void:
    spec["crossroad_x"] = cross_x
    for y in range(HEIGHT):
        spec["road_cells"][Vector2i(cross_x, y)] = true

static func _finalize_main_road_tiles(spec: Dictionary) -> void:
    var road_cells: Dictionary = spec["road_cells"]
    for p_value in road_cells.keys():
        var p: Vector2i = p_value
        _set_ground(spec, p, _road_tile_for(spec, p))

static func _road_tile_for(spec: Dictionary, p: Vector2i) -> int:
    var road_cells: Dictionary = spec["road_cells"]
    var n := road_cells.has(p + Vector2i.UP)
    var e := road_cells.has(p + Vector2i.RIGHT)
    var s := road_cells.has(p + Vector2i.DOWN)
    var w := road_cells.has(p + Vector2i.LEFT)
    if n and e and s and w:
        return Art.G_ROAD_CROSS
    if n and e and s:
        return Art.G_ROAD_NES
    if e and s and w:
        return Art.G_ROAD_ESW
    if n and s and w:
        return Art.G_ROAD_NSW
    if n and e and w:
        return Art.G_ROAD_NEW
    if n and s:
        return Art.G_ROAD_V
    if e and w:
        return Art.G_ROAD_H
    if n and e:
        return Art.G_ROAD_NE
    if e and s:
        return Art.G_ROAD_ES
    if s and w:
        return Art.G_ROAD_SW
    if w and n:
        return Art.G_ROAD_WN
    if n:
        return Art.G_ROAD_END_N
    if e:
        return Art.G_ROAD_END_E
    if s:
        return Art.G_ROAD_END_S
    if w:
        return Art.G_ROAD_END_W
    return Art.G_ROAD_H

static func _paint_road_shoulders(spec: Dictionary) -> void:
    var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
    var road_cells: Dictionary = spec["road_cells"]
    for p_value in road_cells.keys():
        var p: Vector2i = p_value
        for delta in directions:
            var q := p + delta
            if not _inside(q) or road_cells.has(q):
                continue
            if _ground_at(spec, q) == Art.G_GRASS:
                _set_ground(spec, q, Art.G_DIRT)

static func _build_residential_property(spec: Dictionary, rng: RandomNumberGenerator, lot: Dictionary, kind: String) -> void:
    var lot_rect: Rect2i = lot["rect"]
    var property_id := str(lot["id"])
    var front_south := bool(lot["front_south"])
    var size := _building_size(kind)
    var building_rect := _place_building_in_lot(spec, rng, lot_rect, size, front_south)

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
    _connector_to_road(spec, front_door, front_south, road_tile)
    _mailbox_for_connector(spec, front_door.x, front_south)
    _residential_back_features(spec, rng, lot_rect, building_rect, kind, front_south, property_id)
    _scatter_property_nature(spec, rng, lot_rect, building_rect, 9, 14)

    spec["properties"].append({
        "id":property_id,
        "kind":kind,
        "lot":lot_rect,
        "building_rect":building_rect,
        "front_south":front_south,
        "front_door":front_door,
        "commercial":false,
    })

static func _build_business_property(spec: Dictionary, rng: RandomNumberGenerator, lot: Dictionary, kind: String) -> void:
    var lot_rect: Rect2i = lot["rect"]
    var property_id := str(lot["id"])
    var front_south := bool(lot["front_south"])
    var size := Vector2i(13, 13)
    var rect := _place_building_in_lot(spec, rng, lot_rect, size, front_south)
    var door := _roadside_store(spec, rect, front_south, property_id, kind)

    _connector_to_road(spec, door, front_south, Art.G_GRAVEL)
    if kind == "gas_station":
        _gas_station_forecourt(spec, rect, door, front_south)
    else:
        _corner_store_frontage(spec, rect, door, front_south)
    _scatter_property_nature(spec, rng, lot_rect, rect, 6, 10)

    spec["properties"].append({
        "id":property_id,
        "kind":kind,
        "lot":lot_rect,
        "building_rect":rect,
        "front_south":front_south,
        "front_door":door,
        "commercial":true,
    })

static func _place_building_in_lot(spec: Dictionary, rng: RandomNumberGenerator, lot: Rect2i, size: Vector2i, front_south: bool) -> Rect2i:
    var min_x := lot.position.x + 1
    var max_x := maxi(min_x, lot.end.x - size.x - 1)
    var center_x := clampi(lot.position.x + int((lot.size.x - size.x) / 2) + rng.randi_range(-1, 1), min_x, max_x)
    var y: int
    if front_south:
        y = lot.end.y - size.y - 2
    else:
        y = lot.position.y + 2
    var offsets: Array[int] = [0, -2, 2, -4, 4, -6, 6]
    for offset in offsets:
        var x := clampi(center_x + offset, min_x, max_x)
        var candidate := Rect2i(x, y, size.x, size.y)
        if not _rect_near_main_road(spec, candidate, 1):
            return candidate
    return Rect2i(center_x, y, size.x, size.y)

static func _rect_near_main_road(spec: Dictionary, rect: Rect2i, margin: int) -> bool:
    var test := Rect2i(rect.position - Vector2i(margin, margin), rect.size + Vector2i(margin * 2, margin * 2))
    for p_value in spec["road_cells"].keys():
        var p: Vector2i = p_value
        if test.has_point(p):
            return true
    return false

static func _building_size(kind: String) -> Vector2i:
    match kind:
        "farmhouse":
            return Vector2i(15, 13)
        "country_house":
            return Vector2i(14, 13)
        "double_wide":
            return Vector2i(15, 10)
        _:
            return Vector2i(9, 14)

static func _farmhouse(spec: Dictionary, rect: Rect2i, front_south: bool, property_id: String) -> Vector2i:
    _shell(spec, rect, "farmhouse", property_id, Art.G_WOOD, Art.S_WALL_HOUSE)
    var x := rect.position.x
    var y := rect.position.y
    var right := rect.end.x - 1
    var bottom := rect.end.y - 1
    var split_x := x + 8
    var left_split := y + 6
    var utility_x := x + 4
    var right_split_a := y + 4
    var right_split_b := y + 8

    _partition_v(spec, split_x, y + 1, bottom - 1, [y + 3, y + 6, y + 10])
    _partition_h(spec, left_split, x + 1, split_x - 1, [x + 6])
    _partition_v(spec, utility_x, left_split + 1, bottom - 1, [y + 9])
    _partition_h(spec, right_split_a, split_x + 1, right - 1, [split_x + 3])
    _partition_h(spec, right_split_b, split_x + 1, right - 1, [split_x + 3])

    var living := Rect2i(x + 1, y + 1, 7, 5)
    var kitchen := Rect2i(x + 1, left_split + 1, 3, 5)
    var utility := Rect2i(utility_x + 1, left_split + 1, 3, 5)
    var primary := Rect2i(split_x + 1, y + 1, 5, 3)
    var bedroom := Rect2i(split_x + 1, right_split_a + 1, 5, 3)
    var bathroom := Rect2i(split_x + 1, right_split_b + 1, 5, 3)

    _room(spec, living, property_id, "living_room", Art.G_WOOD)
    _room(spec, kitchen, property_id, "kitchen", Art.G_TILE)
    _room(spec, utility, property_id, "utility", Art.G_LINOLEUM)
    _room(spec, primary, property_id, "primary_bedroom", Art.G_CARPET)
    _room(spec, bedroom, property_id, "bedroom", Art.G_CARPET)
    _room(spec, bathroom, property_id, "bathroom", Art.G_TILE)

    var door := _front_door(rect, front_south)
    _door(spec, door, Art.S_DOOR_CLOSED, "h")
    _add_house_windows(spec, rect, front_south, door)
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
    var left_split := y + 6
    var right_split_a := y + 4
    var right_split_b := y + 8

    _partition_v(spec, split_x, y + 1, bottom - 1, [y + 3, y + 6, y + 10])
    _partition_h(spec, left_split, x + 1, split_x - 1, [x + 4])
    _partition_h(spec, right_split_a, split_x + 1, right - 1, [split_x + 3])
    _partition_h(spec, right_split_b, split_x + 1, right - 1, [split_x + 3])

    var living := Rect2i(x + 1, y + 1, 6, 5)
    var kitchen := Rect2i(x + 1, left_split + 1, 6, 5)
    var primary := Rect2i(split_x + 1, y + 1, 5, 3)
    var bedroom := Rect2i(split_x + 1, right_split_a + 1, 5, 3)
    var bathroom := Rect2i(split_x + 1, right_split_b + 1, 5, 3)

    _room(spec, living, property_id, "living_room", Art.G_WOOD)
    _room(spec, kitchen, property_id, "kitchen", Art.G_TILE)
    _room(spec, primary, property_id, "primary_bedroom", Art.G_CARPET)
    _room(spec, bedroom, property_id, "bedroom", Art.G_CARPET)
    _room(spec, bathroom, property_id, "bathroom", Art.G_TILE)

    var door := _front_door(rect, front_south)
    _door(spec, door, Art.S_DOOR_CLOSED, "h")
    _add_house_windows(spec, rect, front_south, door)
    _furnish_living(spec, living)
    _furnish_kitchen(spec, kitchen)
    _furnish_bedroom(spec, primary)
    _furnish_bedroom(spec, bedroom)
    _furnish_bathroom(spec, bathroom)
    return door

static func _double_wide(spec: Dictionary, rect: Rect2i, front_south: bool, property_id: String) -> Vector2i:
    _shell(spec, rect, "double_wide", property_id, Art.G_LINOLEUM, Art.S_WALL_HOUSE)
    var x := rect.position.x
    var y := rect.position.y
    var right := rect.end.x - 1
    var bottom := rect.end.y - 1
    var horizontal_split := y + 5
    var top_split := x + 8
    var lower_split_a := x + 5
    var lower_split_b := x + 10

    _partition_h(spec, horizontal_split, x + 1, right - 1, [x + 3, x + 7, x + 12])
    _partition_v(spec, top_split, y + 1, horizontal_split - 1, [y + 3])
    _partition_v(spec, lower_split_a, horizontal_split + 1, bottom - 1, [y + 7])
    _partition_v(spec, lower_split_b, horizontal_split + 1, bottom - 1, [y + 7])

    var living := Rect2i(x + 1, y + 1, 7, 4)
    var primary := Rect2i(top_split + 1, y + 1, 5, 4)
    var kitchen := Rect2i(x + 1, horizontal_split + 1, 4, 3)
    var bathroom := Rect2i(lower_split_a + 1, horizontal_split + 1, 4, 3)
    var bedroom := Rect2i(lower_split_b + 1, horizontal_split + 1, 3, 3)

    _room(spec, living, property_id, "living_room", Art.G_LINOLEUM)
    _room(spec, primary, property_id, "primary_bedroom", Art.G_CARPET)
    _room(spec, kitchen, property_id, "kitchen", Art.G_TILE)
    _room(spec, bathroom, property_id, "bathroom", Art.G_TILE)
    _room(spec, bedroom, property_id, "bedroom", Art.G_CARPET)

    var door := _front_door(rect, front_south)
    _door(spec, door, Art.S_DOOR_CLOSED, "h")
    _add_house_windows(spec, rect, front_south, door)
    _furnish_living(spec, living)
    _furnish_kitchen(spec, kitchen)
    _furnish_bathroom(spec, bathroom)
    _furnish_bedroom(spec, primary)
    _furnish_bedroom(spec, bedroom)
    return door

static func _small_trailer(spec: Dictionary, rect: Rect2i, front_south: bool, property_id: String) -> Vector2i:
    _shell(spec, rect, "small_trailer", property_id, Art.G_LINOLEUM, Art.S_WALL_HOUSE)
    var x := rect.position.x
    var y := rect.position.y
    var right := rect.end.x - 1
    var bottom := rect.end.y - 1
    var split_a := y + 5
    var split_b := y + 9
    var divider_x := x + 4

    _partition_h(spec, split_a, x + 1, right - 1, [x + 4])
    _partition_h(spec, split_b, x + 1, right - 1, [x + 4])
    _partition_v(spec, divider_x, split_b + 1, bottom - 1, [y + 11])

    var living := Rect2i(x + 1, y + 1, 7, 4)
    var kitchen := Rect2i(x + 1, split_a + 1, 7, 3)
    var bathroom := Rect2i(x + 1, split_b + 1, 3, 3)
    var bedroom := Rect2i(divider_x + 1, split_b + 1, 3, 3)

    _room(spec, living, property_id, "trailer_living", Art.G_LINOLEUM)
    _room(spec, kitchen, property_id, "kitchen", Art.G_TILE)
    _room(spec, bathroom, property_id, "bathroom", Art.G_TILE)
    _room(spec, bedroom, property_id, "primary_bedroom", Art.G_CARPET)

    var door := _front_door(rect, front_south)
    _door(spec, door, Art.S_DOOR_CLOSED, "h")
    _add_house_windows(spec, rect, front_south, door)
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

    _partition_v(spec, service_wall_x, y + 1, bottom - 1, [y + 2, y + 6, y + 10])
    _partition_h(spec, y + 4, x + 1, service_wall_x - 1, [])
    _partition_h(spec, y + 8, x + 1, service_wall_x - 1, [])

    var storefront: Rect2i
    var rear_service: Rect2i
    if front_south:
        storefront = Rect2i(x + 5, y + 5, 7, 7)
        rear_service = Rect2i(x + 5, y + 1, 7, 3)
        _partition_h(spec, y + 4, x + 5, x + 11, [x + 8])
    else:
        storefront = Rect2i(x + 5, y + 1, 7, 7)
        rear_service = Rect2i(x + 5, y + 9, 7, 3)
        _partition_h(spec, y + 8, x + 5, x + 11, [x + 8])

    var stock := Rect2i(x + 1, y + 1, 3, 3)
    var office := Rect2i(x + 1, y + 5, 3, 3)
    var bathroom := Rect2i(x + 1, y + 9, 3, 3)

    _room(spec, storefront, property_id, "storefront", Art.G_TILE)
    _room(spec, rear_service, property_id, "rear_service", Art.G_CONCRETE)
    _room(spec, stock, property_id, "stock_room", Art.G_CONCRETE)
    _room(spec, office, property_id, "manager_office", Art.G_CARPET)
    _room(spec, bathroom, property_id, "bathroom", Art.G_TILE)

    var door := _front_door(rect, front_south, x + 8)
    _door(spec, door, Art.S_DOOR_CLOSED, "h")
    _storefront_windows(spec, rect, front_south, door)
    _furnish_storefront(spec, storefront, kind)
    _furnish_stock_room(spec, stock)
    _furnish_office(spec, office)
    _furnish_bathroom(spec, bathroom)
    _furnish_rear_service(spec, rear_service)
    return door

static func _furnish_living(spec: Dictionary, room: Rect2i) -> void:
    _fixture(spec, _wall_cell(room, "right", 1), Art.P_TV, "tv", true)
    _fixture(spec, _wall_cell(room, "left", mini(2, room.size.y - 1)), Art.P_SOFA, "sofa", true)
    if room.size.x >= 5 and room.size.y >= 4:
        _fixture(spec, Vector2i(room.position.x + int(room.size.x / 2), room.position.y + int(room.size.y / 2)), Art.P_TABLE, "coffee_table", true)

static func _furnish_kitchen(spec: Dictionary, room: Rect2i) -> void:
    _fixture(spec, _wall_cell(room, "left", 0), Art.P_STOVE, "stove", true)
    _fixture(spec, _wall_cell(room, "left", 1), Art.P_SINK, "kitchen_sink", true)
    _fixture(spec, _wall_cell(room, "right", 0), Art.P_FRIDGE, "fridge", true)
    if room.size.x >= 5 and room.size.y >= 4:
        _fixture(spec, Vector2i(room.position.x + int(room.size.x / 2), room.position.y + int(room.size.y / 2)), Art.P_TABLE, "dining_table", true)

static func _furnish_bedroom(spec: Dictionary, room: Rect2i) -> void:
    _fixture(spec, _wall_cell(room, "top", 1), Art.P_BED, "bed", true)
    _fixture(spec, _wall_cell(room, "right", room.size.y - 1), Art.P_DRESSER, "dresser", true)

static func _furnish_bathroom(spec: Dictionary, room: Rect2i) -> void:
    _fixture(spec, _wall_cell(room, "left", 0), Art.P_TOILET, "toilet", true)
    _fixture(spec, _wall_cell(room, "left", 1), Art.P_SINK, "bath_sink", true)
    _fixture(spec, _wall_cell(room, "right", 0), Art.P_BATHTUB, "bathtub", true)

static func _furnish_utility(spec: Dictionary, room: Rect2i) -> void:
    _fixture(spec, _wall_cell(room, "left", 0), Art.P_WASHER, "washer", true)
    _fixture(spec, _wall_cell(room, "right", 0), Art.P_WATER_HEATER, "water_heater", true)

static func _furnish_storefront(spec: Dictionary, room: Rect2i, kind: String) -> void:
    _fixture(spec, _wall_cell(room, "left", 1), Art.P_COUNTER, "checkout_counter", true)
    _fixture(spec, _wall_cell(room, "right", 1), Art.P_STORE_SHELF, "retail_shelf", true)
    _fixture(spec, _wall_cell(room, "right", 3), Art.P_STORE_SHELF, "retail_shelf", true)
    _fixture(spec, _wall_cell(room, "top", 3), Art.P_ICE_BOX if kind == "gas_station" else Art.P_VENDING, "cold_case", true)
    _fixture(spec, Vector2i(room.position.x + 3, room.position.y + 3), Art.P_STORE_SHELF, "retail_island", true)

static func _furnish_stock_room(spec: Dictionary, room: Rect2i) -> void:
    _fixture(spec, _wall_cell(room, "left", 0), Art.P_CRATE, "stock_crate", true)
    _fixture(spec, _wall_cell(room, "right", 0), Art.P_PALLET, "stock_pallet", true)

static func _furnish_office(spec: Dictionary, room: Rect2i) -> void:
    _fixture(spec, _wall_cell(room, "top", 1), Art.P_DESK, "manager_desk", true)
    _fixture(spec, _wall_cell(room, "bottom", 1), Art.P_CHAIR, "manager_chair", true)

static func _furnish_rear_service(spec: Dictionary, room: Rect2i) -> void:
    _fixture(spec, _wall_cell(room, "left", 1), Art.P_CRATE, "service_crate", true)
    _fixture(spec, _wall_cell(room, "right", 1), Art.P_TRASH_CAN, "service_trash", true)

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
    if _rect_near_main_road(spec, rect, 0):
        return
    _shell(spec, rect, "barn", property_id, Art.G_CONCRETE, Art.S_WALL_INDUSTRIAL)
    var room := Rect2i(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, rect.size.y - 2)
    _room(spec, room, property_id, "barn_storage", Art.G_CONCRETE)
    var door := Vector2i(rect.position.x + int(rect.size.x / 2), rect.end.y - 1)
    _door(spec, door, Art.S_DOOR_CLOSED, "h")
    _fixture(spec, _wall_cell(room, "left", 1), Art.P_WORKBENCH, "workbench", true)

static func _shed(spec: Dictionary, rect: Rect2i, property_id: String) -> void:
    if rect.size.x < 5 or rect.size.y < 5 or _rect_near_main_road(spec, rect, 0):
        return
    _shell(spec, rect, "shed", property_id, Art.G_CONCRETE, Art.S_WALL_HOUSE)
    var room := Rect2i(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, rect.size.y - 2)
    _room(spec, room, property_id, "shed_storage", Art.G_CONCRETE)
    var door := Vector2i(rect.position.x + int(rect.size.x / 2), rect.end.y - 1)
    _door(spec, door, Art.S_DOOR_CLOSED, "h")
    _fixture(spec, _wall_cell(room, "left", 1), Art.P_TOOL_CABINET, "tool_cabinet", true)

static func _gas_station_forecourt(spec: Dictionary, rect: Rect2i, door: Vector2i, front_south: bool) -> void:
    var road_y := _road_y_at_x(spec, door.x)
    var top := rect.end.y if front_south else road_y + 1
    var bottom := road_y if front_south else rect.position.y
    var y0 := mini(top, bottom)
    var height := maxi(2, abs(bottom - top))
    var pad_rect := Rect2i(clampi(door.x - 4, 1, WIDTH - 10), y0, 9, height)
    _ground_rect(spec, pad_rect, Art.G_ASPHALT)
    var pump_y := road_y - 2 if front_south else road_y + 2
    _prop(spec, Vector2i(door.x - 2, pump_y), Art.P_GAS_PUMP, true)
    _prop(spec, Vector2i(door.x + 2, pump_y), Art.P_GAS_PUMP, true)
    _prop(spec, Vector2i(clampi(door.x + 5, 1, WIDTH - 2), pump_y), Art.P_GAS_SIGN, false)

static func _corner_store_frontage(spec: Dictionary, rect: Rect2i, door: Vector2i, front_south: bool) -> void:
    var y := rect.end.y if front_south else rect.position.y - 1
    _ground_rect(spec, Rect2i(rect.position.x + 2, y, rect.size.x - 4, 1), Art.G_CONCRETE)
    _prop(spec, Vector2i(rect.position.x + 2, y), Art.P_TRASH_CAN, true)
    _prop(spec, Vector2i(rect.end.x - 3, y), Art.P_VENDING, true)

static func _connector_to_road(spec: Dictionary, door: Vector2i, front_south: bool, tile: int) -> void:
    var road_y := _road_y_at_x(spec, door.x)
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

static func _mailbox_for_connector(spec: Dictionary, drive_x: int, front_south: bool) -> void:
    var road_y := _road_y_at_x(spec, drive_x)
    var y := road_y - 2 if front_south else road_y + 2
    _prop(spec, Vector2i(clampi(drive_x + 1, 1, WIDTH - 2), y), Art.P_MAILBOX, false)

static func _add_roadside_utilities(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    var pole_cells: Array[Vector2i] = []
    var x := rng.randi_range(3, 5)
    while x <= WIDTH - 4:
        if int(spec.get("crossroad_x", -1)) >= 0 and abs(x - int(spec["crossroad_x"])) <= 1:
            x += 2
        var road_y := _road_y_at_x(spec, x)
        var p := Vector2i(x, road_y - 2)
        if spec["road_cells"].has(p) or spec["side_road_cells"].has(p) or spec["props"].has(p):
            p = Vector2i(x, road_y + 2)
        if not spec["road_cells"].has(p) and not spec["side_road_cells"].has(p):
            _prop(spec, p, Art.P_UTILITY_POLE, true)
            if int(spec["props"].get(p, -1)) == Art.P_UTILITY_POLE:
                pole_cells.append(p)
        x += rng.randi_range(5, 7)
    for i in range(1, pole_cells.size()):
        spec["power_links"].append({"a":pole_cells[i - 1], "b":pole_cells[i]})

static func _add_sparse_stop_signs(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    var signs_added := 0
    if str(spec.get("road_variant", "")) == "crossroads":
        var cross_x := int(spec.get("crossroad_x", 23))
        var road_y := _road_y_at_x(spec, cross_x)
        for p in [Vector2i(cross_x - 1, road_y - 2), Vector2i(cross_x + 1, road_y + 2)]:
            _prop(spec, p, Art.P_STOP_SIGN, false)
            if int(spec["props"].get(p, -1)) == Art.P_STOP_SIGN:
                signs_added += 1

    var connector_xs: Array[int] = []
    var seen_x: Dictionary = {}
    for cell_value in spec["side_road_cells"].keys():
        var cell: Vector2i = cell_value
        if not seen_x.has(cell.x):
            seen_x[cell.x] = true
            connector_xs.append(cell.x)
    _shuffle_ints(connector_xs, rng)
    for connector_x in connector_xs:
        if signs_added >= 2:
            break
        var road_y := _road_y_at_x(spec, connector_x)
        var sign := Vector2i(clampi(connector_x - 1, 1, WIDTH - 2), road_y - 2)
        if spec["props"].has(sign):
            sign = Vector2i(clampi(connector_x + 1, 1, WIDTH - 2), road_y + 2)
        _prop(spec, sign, Art.P_STOP_SIGN, false)
        if int(spec["props"].get(sign, -1)) == Art.P_STOP_SIGN:
            signs_added += 1

    if signs_added == 0:
        var fallback_y := _road_y_at_x(spec, 8)
        _prop(spec, Vector2i(8, clampi(fallback_y - 2, 1, HEIGHT - 2)), Art.P_STOP_SIGN, false)

static func _scatter_property_nature(spec: Dictionary, rng: RandomNumberGenerator, lot: Rect2i, building: Rect2i, min_count: int, max_count: int) -> void:
    var count := rng.randi_range(min_count, max_count)
    for i in range(count):
        var p := Vector2i(
            rng.randi_range(lot.position.x + 1, lot.end.x - 2),
            rng.randi_range(lot.position.y + 1, lot.end.y - 2)
        )
        if _near_main_road(spec, p, 2):
            continue
        if building.grow(1).has_point(p):
            continue
        if not _free_for_prop(spec, p):
            continue
        var roll := rng.randf()
        if roll < 0.26:
            _prop(spec, p, Art.P_TREE if rng.randf() < 0.65 else Art.P_TREE_LARGE, true)
        elif roll < 0.52:
            _prop(spec, p, Art.P_BUSH, false)
        elif roll < 0.73:
            _prop(spec, p, Art.P_SCRUB, false)
        elif roll < 0.91:
            _prop(spec, p, Art.P_TALL_GRASS if rng.randf() < 0.5 else Art.P_WEEDS, false)
        else:
            _prop(spec, p, Art.P_WILDFLOWERS, false)

static func _scatter_edge_nature(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    for i in range(48):
        var side := rng.randi_range(0, 3)
        var p: Vector2i
        match side:
            0:
                p = Vector2i(rng.randi_range(0, WIDTH - 1), rng.randi_range(0, 5))
            1:
                p = Vector2i(rng.randi_range(WIDTH - 6, WIDTH - 1), rng.randi_range(0, HEIGHT - 1))
            2:
                p = Vector2i(rng.randi_range(0, WIDTH - 1), rng.randi_range(HEIGHT - 6, HEIGHT - 1))
            _:
                p = Vector2i(rng.randi_range(0, 5), rng.randi_range(0, HEIGHT - 1))
        if _free_for_prop(spec, p):
            var tile := Art.P_TREE if i % 3 == 0 else (Art.P_BUSH if i % 3 == 1 else Art.P_SCRUB)
            _prop(spec, p, tile, i % 3 == 0)

static func _front_door(rect: Rect2i, front_south: bool, preferred_x: int = -1) -> Vector2i:
    var x := preferred_x if preferred_x >= rect.position.x + 1 and preferred_x <= rect.end.x - 2 else rect.position.x + int(rect.size.x / 2)
    return Vector2i(x, rect.end.y - 1 if front_south else rect.position.y)

static func _add_house_windows(spec: Dictionary, rect: Rect2i, front_south: bool, door: Vector2i) -> void:
    var y := rect.end.y - 1 if front_south else rect.position.y
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
    if rect.size.x < MIN_ROOM_SIDE or rect.size.y < MIN_ROOM_SIDE:
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
            _door(spec, Vector2i(x, y), Art.S_DOOR_CLOSED, "v")
        else:
            _wall(spec, Vector2i(x, y), Art.S_WALL_LIGHT)

static func _partition_h(spec: Dictionary, y: int, x0: int, x1: int, door_xs: Array) -> void:
    for x in range(x0, x1 + 1):
        if x in door_xs:
            _door(spec, Vector2i(x, y), Art.S_DOOR_CLOSED, "h")
        else:
            _wall(spec, Vector2i(x, y), Art.S_WALL_LIGHT)

static func _wall(spec: Dictionary, p: Vector2i, tile: int) -> void:
    if not _inside(p):
        return
    if spec["doors"].has(p) or spec["door_clear"].has(p):
        return
    spec["windows"].erase(p)
    spec["walls"][p] = tile
    spec["blocked"][p] = true

static func _door(spec: Dictionary, p: Vector2i, tile: int, axis: String) -> void:
    if not _inside(p):
        return
    spec["walls"].erase(p)
    spec["windows"].erase(p)
    spec["props"].erase(p)
    spec["fixture_tags"].erase(p)
    spec["blocked"].erase(p)
    spec["doors"][p] = tile
    spec["door_axes"][p] = axis
    spec["door_clear"][p] = true
    var approaches: Array[Vector2i] = [p + Vector2i.UP, p + Vector2i.DOWN] if axis == "h" else [p + Vector2i.LEFT, p + Vector2i.RIGHT]
    for q in approaches:
        if not _inside(q):
            continue
        spec["door_clear"][q] = true
        spec["walls"].erase(q)
        spec["windows"].erase(q)
        spec["props"].erase(q)
        spec["fixture_tags"].erase(q)
        spec["blocked"].erase(q)

static func _window(spec: Dictionary, p: Vector2i, tile: int) -> void:
    if not _inside(p) or spec["door_clear"].has(p):
        return
    spec["walls"].erase(p)
    spec["doors"].erase(p)
    spec["door_axes"].erase(p)
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
    if spec["door_clear"].has(p):
        return false
    if spec["walls"].has(p) or spec["doors"].has(p) or spec["windows"].has(p) or spec["props"].has(p):
        return false
    return true

static func _normalize_door_geometry(spec: Dictionary) -> void:
    for door_value in spec["doors"].keys():
        var door: Vector2i = door_value
        var axis := str(spec["door_axes"].get(door, "h"))
        spec["walls"].erase(door)
        spec["windows"].erase(door)
        spec["props"].erase(door)
        spec["fixture_tags"].erase(door)
        spec["blocked"].erase(door)
        var approaches: Array[Vector2i] = [door + Vector2i.UP, door + Vector2i.DOWN] if axis == "h" else [door + Vector2i.LEFT, door + Vector2i.RIGHT]
        for p in approaches:
            if not _inside(p):
                continue
            spec["door_clear"][p] = true
            spec["walls"].erase(p)
            spec["windows"].erase(p)
            spec["props"].erase(p)
            spec["fixture_tags"].erase(p)
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
    var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
    for delta in directions:
        if _structural_at(spec, p + delta):
            return true
    return false

static func _structural_at(spec: Dictionary, p: Vector2i) -> bool:
    return spec.get("walls", {}).has(p) or spec.get("windows", {}).has(p)

static func _road_y_at_x(spec: Dictionary, x: int) -> int:
    return int(spec.get("road_y_by_x", {}).get(clampi(x, 0, WIDTH - 1), int(spec.get("main_road_y", 31))))

static func _near_main_road(spec: Dictionary, p: Vector2i, distance: int) -> bool:
    for dy in range(-distance, distance + 1):
        for dx in range(-distance, distance + 1):
            if abs(dx) + abs(dy) > distance:
                continue
            if spec["road_cells"].has(p + Vector2i(dx, dy)):
                return true
    return false

static func _ground_rect(spec: Dictionary, rect: Rect2i, tile: int) -> void:
    var clipped := rect.intersection(Rect2i(0, 0, WIDTH, HEIGHT))
    var ground: PackedInt32Array = spec["ground"]
    for y in range(clipped.position.y, clipped.end.y):
        for x in range(clipped.position.x, clipped.end.x):
            ground[y * WIDTH + x] = tile

static func _set_ground(spec: Dictionary, p: Vector2i, tile: int) -> void:
    if not _inside(p):
        return
    var ground: PackedInt32Array = spec["ground"]
    ground[p.y * WIDTH + p.x] = tile

static func _ground_at(spec: Dictionary, p: Vector2i) -> int:
    if not _inside(p):
        return -1
    var ground: PackedInt32Array = spec["ground"]
    return int(ground[p.y * WIDTH + p.x])

static func _free_for_prop(spec: Dictionary, p: Vector2i) -> bool:
    if not _can_place_prop(spec, p):
        return false
    if spec["road_cells"].has(p) or spec["side_road_cells"].has(p):
        return false
    var tile := _ground_at(spec, p)
    return tile not in [Art.G_GRAVEL, Art.G_ASPHALT]

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

static func _shuffle_ints(values: Array[int], rng: RandomNumberGenerator) -> void:
    for i in range(values.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var temp := values[i]
        values[i] = values[j]
        values[j] = temp

static func _inside(p: Vector2i) -> bool:
    return p.x >= 0 and p.y >= 0 and p.x < WIDTH and p.y < HEIGHT
