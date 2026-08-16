extends RefCounted
class_name RebootSiteGenerator

const Art = preload("res://scripts/reboot/RebootArt.gd")

const WIDTH := 64
const HEIGHT := 64
const ARCHETYPES: Array[String] = ["rural_road"]
const WALL_FIXTURE_TAGS: Array[String] = [
    "kitchen_sink", "stove", "fridge", "bath_sink", "toilet", "bathtub",
    "shower", "washer", "dryer", "water_heater"
]

static func generate(archetype: String, seed_value: int) -> Dictionary:
    var seed := maxi(1, seed_value)
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    var spec := _blank(seed)
    _generate_rural_road(spec, rng)
    _scatter_edge_nature(spec, rng)
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
    if properties.size() < 4:
        failures.append("rural road needs four roadside properties")
    var property_kinds: Dictionary = {}
    var house_like := 0
    var manufactured := 0
    for property_value in properties:
        var property: Dictionary = property_value
        var kind := str(property.get("kind", ""))
        property_kinds[kind] = true
        if kind in ["farmhouse", "country_house"]:
            house_like += 1
        if kind in ["small_trailer", "double_wide"]:
            manufactured += 1
    if property_kinds.size() < 3:
        failures.append("rural road lacks property diversity")
    if house_like < 2:
        failures.append("rural road needs multiple substantial houses")
    if manufactured < 1:
        failures.append("rural road needs manufactured housing presence")

    var rooms: Array = spec.get("rooms", [])
    if rooms.size() < 15:
        failures.append("too few functional rooms across rural road")
    var function_counts: Dictionary = {}
    for room_value in rooms:
        var room: Dictionary = room_value
        var function_name := str(room.get("function", ""))
        function_counts[function_name] = int(function_counts.get(function_name, 0)) + 1
    if int(function_counts.get("living_room", 0)) + int(function_counts.get("trailer_living", 0)) < 4:
        failures.append("not every residence has readable living space")
    if int(function_counts.get("kitchen", 0)) < 4:
        failures.append("not every residence has a kitchen")
    if int(function_counts.get("bathroom", 0)) < 4:
        failures.append("not every residence has a bathroom")

    var roadish := 0
    var road_only := 0
    for value in ground:
        if value == Art.G_ROAD_H or value == Art.G_DIRT_ROAD_H:
            road_only += 1
            roadish += 1
        elif value == Art.G_DRIVEWAY or value == Art.G_GRAVEL:
            roadish += 1
    var map_cells := WIDTH * HEIGHT
    if road_only < int(float(map_cells) * 0.035):
        failures.append("rural road is not visually present")
    if roadish > int(float(map_cells) * 0.14):
        failures.append("road/gravel dominates rural sample")

    var fixture_tags: Dictionary = spec.get("fixture_tags", {})
    for cell_value in fixture_tags.keys():
        var cell: Vector2i = cell_value
        var tag := str(fixture_tags[cell])
        if tag in WALL_FIXTURE_TAGS and not _adjacent_to_wall(spec, cell):
            failures.append("wall fixture floating in room: %s at %s" % [tag, str(cell)])
            break

    return {"ok": failures.is_empty(), "failures": failures}

static func _blank(seed: int) -> Dictionary:
    var ground := PackedInt32Array()
    ground.resize(WIDTH * HEIGHT)
    ground.fill(Art.G_GRASS_LUSH)
    return {
        "version": 2,
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
        "spawn": Vector2i(4, 36),
        "title": "Rural Road",
    }

static func _generate_rural_road(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    spec["title"] = "Rural Road"

    # Broad ground variation first; the site remains one rural biome.
    _ground_rect(spec, Rect2i(0, 0, WIDTH, HEIGHT), Art.G_GRASS_LUSH if rng.randf() < 0.62 else Art.G_GRASS_DRY)
    for i in range(7):
        var patch := Rect2i(
            rng.randi_range(0, WIDTH - 12),
            rng.randi_range(0, HEIGHT - 10),
            rng.randi_range(6, 13),
            rng.randi_range(5, 10)
        )
        _ground_rect(spec, patch, Art.G_GRASS_WEEDY if i % 2 == 0 else Art.G_GRASS_DRY)

    # One road is the spine. It serves the properties instead of becoming the map.
    var road_y := rng.randi_range(29, 32)
    _ground_rect(spec, Rect2i(0, road_y, WIDTH, 3), Art.G_ROAD_H)
    _ground_rect(spec, Rect2i(0, road_y - 1, WIDTH, 1), Art.G_DIRT_LIGHT)
    _ground_rect(spec, Rect2i(0, road_y + 3, WIDTH, 1), Art.G_DIRT_LIGHT)
    for y in range(road_y, road_y + 3):
        for x in range(WIDTH):
            spec["road_cells"][Vector2i(x, y)] = true

    var north_h := road_y - 5
    var south_y := road_y + 5
    var south_h := HEIGHT - south_y - 2
    var lots: Array[Dictionary] = [
        {"id":"north_west", "rect":Rect2i(2, 2, 28, north_h), "front_south":true},
        {"id":"north_east", "rect":Rect2i(34, 2, 28, north_h), "front_south":true},
        {"id":"south_west", "rect":Rect2i(2, south_y, 28, south_h), "front_south":false},
        {"id":"south_east", "rect":Rect2i(34, south_y, 28, south_h), "front_south":false},
    ]

    var manufactured := "small_trailer" if rng.randf() < 0.48 else "double_wide"
    var extra_pool: Array[String] = ["country_house", "country_house", "farmhouse", "double_wide", "small_trailer"]
    var kinds: Array[String] = ["country_house", "farmhouse", manufactured, extra_pool[rng.randi_range(0, extra_pool.size() - 1)]]
    _shuffle_strings(kinds, rng)

    for i in range(lots.size()):
        _build_property(spec, rng, lots[i], kinds[i], road_y)

    # Sparse roadside infrastructure makes the road read as inhabited without urbanizing it.
    var pole_x := rng.randi_range(5, 9)
    while pole_x < WIDTH - 3:
        var pole_y := road_y - 2 if rng.randf() < 0.65 else road_y + 4
        _prop(spec, Vector2i(pole_x, pole_y), Art.P_UTILITY_POLE, true)
        pole_x += rng.randi_range(12, 16)

    spec["spawn"] = Vector2i(4, road_y + 4)

static func _build_property(spec: Dictionary, rng: RandomNumberGenerator, lot: Dictionary, kind: String, road_y: int) -> void:
    var lot_rect: Rect2i = lot["rect"]
    var property_id := str(lot["id"])
    var front_south := bool(lot["front_south"])

    var grass_choice := Art.G_GRASS_DRY if rng.randf() < 0.42 else Art.G_GRASS_LUSH
    _ground_rect(spec, lot_rect, grass_choice)

    var size := _building_size(kind, rng)
    var width := size.x
    var height := size.y
    var min_x := lot_rect.position.x + 4
    var max_x := lot_rect.end.x - width - 4
    var house_x := mini(max_x, maxi(min_x, lot_rect.position.x + (lot_rect.size.x - width) / 2 + rng.randi_range(-2, 2)))
    var house_y: int
    if front_south:
        house_y = lot_rect.end.y - height - rng.randi_range(3, 5)
    else:
        house_y = lot_rect.position.y + rng.randi_range(3, 5)
    var building_rect := Rect2i(house_x, house_y, width, height)

    var front_door: Vector2i
    match kind:
        "farmhouse":
            front_door = _farmhouse(spec, building_rect, front_south, property_id)
        "country_house":
            front_door = _country_house(spec, building_rect, front_south, property_id)
        "double_wide":
            front_door = _double_wide(spec, building_rect, front_south, property_id)
        _:
            front_door = _small_trailer(spec, building_rect, front_south, property_id)
            kind = "small_trailer"

    _driveway_to_road(spec, front_door, front_south, road_y)
    _mailbox_for_drive(spec, front_door.x, front_south, road_y)
    _property_back_features(spec, rng, lot_rect, building_rect, kind, front_south, property_id)
    _scatter_property_nature(spec, rng, lot_rect, building_rect, road_y)

    spec["properties"].append({
        "id": property_id,
        "kind": kind,
        "lot": lot_rect,
        "building_rect": building_rect,
        "front_south": front_south,
        "front_door": front_door,
    })

static func _building_size(kind: String, rng: RandomNumberGenerator) -> Vector2i:
    match kind:
        "farmhouse":
            return Vector2i(rng.randi_range(15, 17), rng.randi_range(12, 13))
        "country_house":
            return Vector2i(rng.randi_range(14, 16), 12)
        "double_wide":
            return Vector2i(rng.randi_range(13, 15), 11)
        _:
            return Vector2i(rng.randi_range(8, 9), 12)

static func _farmhouse(spec: Dictionary, rect: Rect2i, front_south: bool, property_id: String) -> Vector2i:
    _shell(spec, rect, "farmhouse", property_id, Art.G_WOOD, Art.S_WALL_RURAL)
    var x := rect.position.x
    var y := rect.position.y
    var right := rect.end.x - 1
    var bottom := rect.end.y - 1
    var split_x := x + int(rect.size.x * 0.56)
    var left_split := y + 6
    var right_split_a := y + 4
    var right_split_b := y + 8

    _partition_v(spec, split_x, y + 1, bottom - 1, [y + 3, y + 7, bottom - 2])
    _partition_h(spec, left_split, x + 1, split_x - 1, [x + 4])
    _partition_h(spec, right_split_a, split_x + 1, right - 1, [split_x + 3])
    _partition_h(spec, right_split_b, split_x + 1, right - 1, [split_x + 3])

    var utility_x := x + 5
    _partition_v(spec, utility_x, left_split + 1, bottom - 1, [bottom - 2])

    var living := Rect2i(x + 1, y + 1, split_x - x - 1, left_split - y - 1)
    var kitchen := Rect2i(x + 1, left_split + 1, utility_x - x - 1, bottom - left_split - 1)
    var utility := Rect2i(utility_x + 1, left_split + 1, split_x - utility_x - 1, bottom - left_split - 1)
    var primary := Rect2i(split_x + 1, y + 1, right - split_x - 1, right_split_a - y - 1)
    var bedroom := Rect2i(split_x + 1, right_split_a + 1, right - split_x - 1, right_split_b - right_split_a - 1)
    var bathroom := Rect2i(split_x + 1, right_split_b + 1, right - split_x - 1, bottom - right_split_b - 1)

    _room(spec, living, property_id, "living_room", Art.G_WOOD_ALT)
    _room(spec, kitchen, property_id, "kitchen", Art.G_KITCHEN)
    _room(spec, utility, property_id, "utility", Art.G_UTILITY)
    _room(spec, primary, property_id, "primary_bedroom", Art.G_CARPET)
    _room(spec, bedroom, property_id, "bedroom", Art.G_CARPET)
    _room(spec, bathroom, property_id, "bathroom", Art.G_BATHROOM)

    var door := _front_door(rect, front_south)
    _door(spec, door, Art.S_DOOR_HOUSE)
    _add_house_windows(spec, rect, front_south)
    _furnish_living(spec, living)
    _furnish_kitchen(spec, kitchen)
    _furnish_bedroom(spec, primary, true)
    _furnish_bedroom(spec, bedroom, false)
    _furnish_bathroom(spec, bathroom)
    _furnish_utility(spec, utility)
    return door

static func _country_house(spec: Dictionary, rect: Rect2i, front_south: bool, property_id: String) -> Vector2i:
    _shell(spec, rect, "country_house", property_id, Art.G_WOOD, Art.S_WALL_HOUSE)
    var x := rect.position.x
    var y := rect.position.y
    var right := rect.end.x - 1
    var bottom := rect.end.y - 1
    var split_x := x + int(rect.size.x * 0.56)
    var left_split := y + 6
    var right_split_a := y + 4
    var right_split_b := y + 8

    _partition_v(spec, split_x, y + 1, bottom - 1, [y + 3, y + 7])
    _partition_h(spec, left_split, x + 1, split_x - 1, [x + 4])
    _partition_h(spec, right_split_a, split_x + 1, right - 1, [split_x + 3])
    _partition_h(spec, right_split_b, split_x + 1, right - 1, [split_x + 3])

    var living := Rect2i(x + 1, y + 1, split_x - x - 1, left_split - y - 1)
    var kitchen := Rect2i(x + 1, left_split + 1, split_x - x - 1, bottom - left_split - 1)
    var primary := Rect2i(split_x + 1, y + 1, right - split_x - 1, right_split_a - y - 1)
    var bedroom := Rect2i(split_x + 1, right_split_a + 1, right - split_x - 1, right_split_b - right_split_a - 1)
    var bathroom := Rect2i(split_x + 1, right_split_b + 1, right - split_x - 1, bottom - right_split_b - 1)

    _room(spec, living, property_id, "living_room", Art.G_WOOD_ALT)
    _room(spec, kitchen, property_id, "kitchen", Art.G_KITCHEN)
    _room(spec, primary, property_id, "primary_bedroom", Art.G_CARPET)
    _room(spec, bedroom, property_id, "bedroom", Art.G_CARPET)
    _room(spec, bathroom, property_id, "bathroom", Art.G_BATHROOM)

    var door := _front_door(rect, front_south)
    _door(spec, door, Art.S_DOOR_HOUSE)
    _add_house_windows(spec, rect, front_south)
    _furnish_living(spec, living)
    _furnish_kitchen(spec, kitchen)
    _furnish_bedroom(spec, primary, true)
    _furnish_bedroom(spec, bedroom, false)
    _furnish_bathroom(spec, bathroom)
    return door

static func _double_wide(spec: Dictionary, rect: Rect2i, front_south: bool, property_id: String) -> Vector2i:
    _shell(spec, rect, "double_wide", property_id, Art.G_WOOD, Art.S_WALL_RURAL)
    var x := rect.position.x
    var y := rect.position.y
    var right := rect.end.x - 1
    var bottom := rect.end.y - 1
    var split_x := x + int(rect.size.x * 0.52)
    var left_split := y + 5
    var right_split_a := y + 4
    var right_split_b := y + 7

    _partition_v(spec, split_x, y + 1, bottom - 1, [y + 3, y + 7])
    _partition_h(spec, left_split, x + 1, split_x - 1, [x + 3])
    _partition_h(spec, right_split_a, split_x + 1, right - 1, [split_x + 3])
    _partition_h(spec, right_split_b, split_x + 1, right - 1, [split_x + 3])

    var living := Rect2i(x + 1, y + 1, split_x - x - 1, left_split - y - 1)
    var kitchen := Rect2i(x + 1, left_split + 1, split_x - x - 1, bottom - left_split - 1)
    var primary := Rect2i(split_x + 1, y + 1, right - split_x - 1, right_split_a - y - 1)
    var bedroom := Rect2i(split_x + 1, right_split_a + 1, right - split_x - 1, right_split_b - right_split_a - 1)
    var bathroom := Rect2i(split_x + 1, right_split_b + 1, right - split_x - 1, bottom - right_split_b - 1)

    _room(spec, living, property_id, "living_room", Art.G_WOOD_ALT)
    _room(spec, kitchen, property_id, "kitchen", Art.G_KITCHEN)
    _room(spec, primary, property_id, "primary_bedroom", Art.G_CARPET)
    _room(spec, bedroom, property_id, "bedroom", Art.G_CARPET)
    _room(spec, bathroom, property_id, "bathroom", Art.G_BATHROOM)

    var door := _front_door(rect, front_south)
    _door(spec, door, Art.S_DOOR_HOUSE)
    _add_house_windows(spec, rect, front_south)
    _furnish_living(spec, living)
    _furnish_kitchen(spec, kitchen)
    _furnish_bedroom(spec, primary, true)
    _furnish_bedroom(spec, bedroom, false)
    _furnish_bathroom(spec, bathroom)
    return door

static func _small_trailer(spec: Dictionary, rect: Rect2i, front_south: bool, property_id: String) -> Vector2i:
    _shell(spec, rect, "small_trailer", property_id, Art.G_WOOD, Art.S_WALL_RURAL)
    var x := rect.position.x
    var y := rect.position.y
    var right := rect.end.x - 1
    var bottom := rect.end.y - 1
    var split_a := y + 5
    var split_b := y + 8
    _partition_h(spec, split_a, x + 1, right - 1, [x + int(rect.size.x / 2)])
    _partition_h(spec, split_b, x + 1, right - 1, [x + int(rect.size.x / 2)])

    var living := Rect2i(x + 1, y + 1, rect.size.x - 2, split_a - y - 1)
    var kitchen := Rect2i(x + 1, split_a + 1, rect.size.x - 2, split_b - split_a - 1)
    var bathroom := Rect2i(x + 1, split_b + 1, 3, bottom - split_b - 1)
    var bedroom := Rect2i(x + 5, split_b + 1, right - x - 5, bottom - split_b - 1)
    if bedroom.size.x < 2:
        bedroom = Rect2i(x + 4, split_b + 1, right - x - 4, bottom - split_b - 1)

    _room(spec, living, property_id, "trailer_living", Art.G_WOOD_ALT)
    _room(spec, kitchen, property_id, "kitchen", Art.G_KITCHEN)
    _room(spec, bathroom, property_id, "bathroom", Art.G_BATHROOM)
    _room(spec, bedroom, property_id, "primary_bedroom", Art.G_CARPET)

    # A short divider separates bath from the rear sleeping space.
    var divider_x := bathroom.end.x
    _partition_v(spec, divider_x, split_b + 1, bottom - 1, [bottom - 2])

    var door := _front_door(rect, front_south)
    _door(spec, door, Art.S_DOOR_HOUSE)
    _add_house_windows(spec, rect, front_south)
    _furnish_living(spec, living)
    _furnish_kitchen(spec, kitchen)
    _furnish_bathroom(spec, bathroom)
    _furnish_bedroom(spec, bedroom, false)
    return door

static func _property_back_features(spec: Dictionary, rng: RandomNumberGenerator, lot: Rect2i, house: Rect2i, kind: String, front_south: bool, property_id: String) -> void:
    var back_y: int
    if front_south:
        back_y = lot.position.y + 1
    else:
        back_y = lot.end.y - 7

    match kind:
        "farmhouse":
            var field_y := lot.position.y + 1 if front_south else house.end.y + 1
            var field_h := house.position.y - field_y - 1 if front_south else lot.end.y - field_y - 1
            if field_h >= 4:
                _ground_rect(spec, Rect2i(lot.position.x + 10, field_y, lot.size.x - 12, field_h), Art.G_FIELD_ROWS)
            var barn := Rect2i(lot.position.x + 1, back_y, 7, 6)
            _barn(spec, barn, property_id)
            _prop(spec, Vector2i(barn.end.x + 1, barn.position.y + 2), Art.P_HAY_BALE, true)
            _prop(spec, Vector2i(barn.end.x + 2, barn.position.y + 3), Art.P_COMPOST, false)
        "country_house":
            var shed_y := lot.position.y + 1 if front_south else lot.end.y - 6
            _shed(spec, Rect2i(lot.end.x - 7, shed_y, 6, 5), property_id)
            _prop(spec, Vector2i(lot.position.x + 3, shed_y + 2), Art.P_GARDEN, false)
            _prop(spec, Vector2i(lot.position.x + 5, shed_y + 3), Art.P_COMPOST, false)
        "double_wide":
            var shed_y_dw := lot.position.y + 1 if front_south else lot.end.y - 6
            _shed(spec, Rect2i(lot.end.x - 7, shed_y_dw, 6, 5), property_id)
            _prop(spec, Vector2i(lot.position.x + 3, shed_y_dw + 1), Art.P_TIRE_PILE, true)
            _prop(spec, Vector2i(lot.position.x + 4, shed_y_dw + 3), Art.P_FIREWOOD, false)
        _:
            var shed_y_tr := lot.position.y + 1 if front_south else lot.end.y - 6
            _shed(spec, Rect2i(lot.end.x - 6, shed_y_tr, 5, 5), property_id)
            _prop(spec, Vector2i(lot.position.x + 3, shed_y_tr + 1), Art.P_TRASH_CAN, true)
            _prop(spec, Vector2i(lot.position.x + 4, shed_y_tr + 3), Art.P_CARDBOARD, false)

    if rng.randf() < 0.52:
        var fence_x := lot.position.x + 1
        _fence_line(spec, Vector2i(fence_x, lot.position.y + 1), Vector2i(fence_x, lot.end.y - 2))

static func _barn(spec: Dictionary, rect: Rect2i, property_id: String) -> void:
    _shell(spec, rect, "barn", property_id, Art.G_UTILITY, Art.S_WALL_BARN)
    var room := Rect2i(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, rect.size.y - 2)
    _room(spec, room, property_id, "barn_storage", Art.G_UTILITY)
    var door := Vector2i(rect.position.x + rect.size.x / 2, rect.end.y - 1)
    _door(spec, door, Art.S_DOOR_SERVICE)
    _fixture(spec, _wall_cell(room, "left", 1), Art.P_WORKBENCH, "workbench", true)
    _fixture(spec, _wall_cell(room, "right", 1), Art.P_TOOL_CABINET, "tool_cabinet", true)

static func _shed(spec: Dictionary, rect: Rect2i, property_id: String) -> void:
    if rect.size.x < 4 or rect.size.y < 4:
        return
    _shell(spec, rect, "shed", property_id, Art.G_UTILITY, Art.S_WALL_RURAL)
    var room := Rect2i(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, rect.size.y - 2)
    _room(spec, room, property_id, "shed_storage", Art.G_UTILITY)
    _door(spec, Vector2i(rect.position.x + rect.size.x / 2, rect.end.y - 1), Art.S_DOOR_SERVICE)
    _fixture(spec, _wall_cell(room, "left", 1), Art.P_TOOL_CABINET, "tool_cabinet", true)

static func _furnish_living(spec: Dictionary, room: Rect2i) -> void:
    if room.size.x < 3 or room.size.y < 3:
        return
    var tv := _wall_cell(room, "right", 1)
    _fixture(spec, tv, Art.P_TV, "tv", true)
    var sofa := Vector2i(maxi(room.position.x, tv.x - 2), mini(room.end.y - 1, tv.y + 1))
    _fixture(spec, sofa, Art.P_SOFA, "sofa", true)
    if room.size.x >= 5 and room.size.y >= 4:
        var table := Vector2i(maxi(room.position.x + 1, tv.x - 1), mini(room.end.y - 1, tv.y + 2))
        _fixture(spec, table, Art.P_COFFEE_TABLE, "coffee_table", true)

static func _furnish_kitchen(spec: Dictionary, room: Rect2i) -> void:
    if room.size.x < 3 or room.size.y < 2:
        return
    # Fixed kitchen fixtures intentionally hug a wall instead of floating in the room.
    _fixture(spec, _wall_cell(room, "left", 0), Art.P_STOVE, "stove", true)
    if room.size.y >= 3:
        _fixture(spec, _wall_cell(room, "left", 1), Art.P_KITCHEN_SINK, "kitchen_sink", true)
    if room.size.y >= 4:
        _fixture(spec, _wall_cell(room, "left", 2), Art.P_COUNTER, "counter", true)
    _fixture(spec, _wall_cell(room, "right", 0), Art.P_FRIDGE, "fridge", true)
    if room.size.x >= 5 and room.size.y >= 3:
        var table := Vector2i(room.position.x + int(room.size.x / 2), room.position.y + int(room.size.y / 2))
        _fixture(spec, table, Art.P_DINING_TABLE, "dining_table", true)

static func _furnish_bedroom(spec: Dictionary, room: Rect2i, double_bed: bool) -> void:
    if room.size.x < 2 or room.size.y < 2:
        return
    _fixture(spec, _wall_cell(room, "top", 1), Art.P_BED_DOUBLE if double_bed else Art.P_BED_SINGLE, "bed", true)
    if room.size.x >= 3:
        _fixture(spec, _wall_cell(room, "right", room.size.y - 1), Art.P_DRESSER, "dresser", true)

static func _furnish_bathroom(spec: Dictionary, room: Rect2i) -> void:
    if room.size.x < 2 or room.size.y < 2:
        return
    _fixture(spec, _wall_cell(room, "left", 0), Art.P_TOILET, "toilet", true)
    _fixture(spec, _wall_cell(room, "right", 0), Art.P_BATH_VANITY, "bath_sink", true)
    if room.size.x >= 3:
        _fixture(spec, _wall_cell(room, "bottom", 1), Art.P_BATHTUB, "bathtub", true)

static func _furnish_utility(spec: Dictionary, room: Rect2i) -> void:
    if room.size.x < 2 or room.size.y < 2:
        return
    _fixture(spec, _wall_cell(room, "left", 0), Art.P_WASHER, "washer", true)
    _fixture(spec, _wall_cell(room, "right", 0), Art.P_DRYER, "dryer", true)
    if room.size.y >= 3:
        _fixture(spec, _wall_cell(room, "right", 1), Art.P_WATER_HEATER, "water_heater", true)

static func _front_door(rect: Rect2i, front_south: bool) -> Vector2i:
    var door_x := rect.position.x + int(rect.size.x / 2)
    return Vector2i(door_x, rect.end.y - 1 if front_south else rect.position.y)

static func _add_house_windows(spec: Dictionary, rect: Rect2i, front_south: bool) -> void:
    var top := rect.position.y
    var bottom := rect.end.y - 1
    var left := rect.position.x
    var right := rect.end.x - 1
    _window(spec, Vector2i(left + 3, top), Art.S_WINDOW_HOUSE)
    _window(spec, Vector2i(right - 3, top), Art.S_WINDOW_HOUSE)
    _window(spec, Vector2i(left + 3, bottom), Art.S_WINDOW_HOUSE)
    _window(spec, Vector2i(right - 3, bottom), Art.S_WINDOW_HOUSE)
    _window(spec, Vector2i(left, top + 3), Art.S_WINDOW_HOUSE)
    _window(spec, Vector2i(right, top + 3), Art.S_WINDOW_HOUSE)
    if front_south:
        _window(spec, Vector2i(left, bottom - 3), Art.S_WINDOW_HOUSE)
    else:
        _window(spec, Vector2i(right, bottom - 3), Art.S_WINDOW_HOUSE)

static func _driveway_to_road(spec: Dictionary, door: Vector2i, front_south: bool, road_y: int) -> void:
    var start_y: int
    var height: int
    if front_south:
        start_y = door.y + 1
        height = road_y - start_y
    else:
        start_y = road_y + 3
        height = door.y - start_y
    if height <= 0:
        return
    _ground_rect(spec, Rect2i(door.x - 1, start_y, 2, height), Art.G_DRIVEWAY)

static func _mailbox_for_drive(spec: Dictionary, drive_x: int, front_south: bool, road_y: int) -> void:
    var y := road_y - 2 if front_south else road_y + 4
    var p := Vector2i(clampi(drive_x + 2, 1, WIDTH - 2), y)
    _prop(spec, p, Art.P_MAILBOX, false)

static func _scatter_property_nature(spec: Dictionary, rng: RandomNumberGenerator, lot: Rect2i, house: Rect2i, road_y: int) -> void:
    var count := rng.randi_range(8, 14)
    for i in range(count):
        var p := Vector2i(
            rng.randi_range(lot.position.x + 1, lot.end.x - 2),
            rng.randi_range(lot.position.y + 1, lot.end.y - 2)
        )
        if p.y >= road_y - 2 and p.y <= road_y + 4:
            continue
        if house.grow(2).has_point(p):
            continue
        if not _free_for_prop(spec, p):
            continue
        var roll := rng.randf()
        if roll < 0.28:
            _prop(spec, p, Art.P_TREE_LARGE if rng.randf() < 0.55 else Art.P_TREE_SMALL, true)
        elif roll < 0.55:
            _prop(spec, p, Art.P_BUSH, false)
        elif roll < 0.82:
            _prop(spec, p, Art.P_TALL_GRASS if rng.randf() < 0.5 else Art.P_WEEDS, false)
        else:
            _prop(spec, p, Art.P_WILDFLOWERS, false)

static func _scatter_edge_nature(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    for i in range(32):
        var side := rng.randi_range(0, 3)
        var p: Vector2i
        match side:
            0:
                p = Vector2i(rng.randi_range(0, WIDTH - 1), rng.randi_range(0, 3))
            1:
                p = Vector2i(rng.randi_range(WIDTH - 4, WIDTH - 1), rng.randi_range(0, HEIGHT - 1))
            2:
                p = Vector2i(rng.randi_range(0, WIDTH - 1), rng.randi_range(HEIGHT - 4, HEIGHT - 1))
            _:
                p = Vector2i(rng.randi_range(0, 3), rng.randi_range(0, HEIGHT - 1))
        if _free_for_prop(spec, p):
            _prop(spec, p, Art.P_TREE_SMALL if i % 3 != 0 else Art.P_BUSH, i % 3 != 0)

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
            _door(spec, Vector2i(x, y), Art.S_DOOR_HOUSE)
        else:
            _wall(spec, Vector2i(x, y), Art.S_WALL_INTERIOR)

static func _partition_h(spec: Dictionary, y: int, x0: int, x1: int, door_xs: Array) -> void:
    for x in range(x0, x1 + 1):
        if x in door_xs:
            _door(spec, Vector2i(x, y), Art.S_DOOR_HOUSE)
        else:
            _wall(spec, Vector2i(x, y), Art.S_WALL_INTERIOR)

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
    if not _inside(p) or spec["walls"].has(p) or spec["doors"].has(p) or spec["windows"].has(p) or spec["props"].has(p):
        return
    spec["props"][p] = tile
    spec["fixture_tags"][p] = tag
    if blocks:
        spec["blocked"][p] = true

static func _prop(spec: Dictionary, p: Vector2i, tile: int, blocks: bool) -> void:
    if not _inside(p) or spec["walls"].has(p) or spec["doors"].has(p) or spec["windows"].has(p) or spec["props"].has(p):
        return
    spec["props"][p] = tile
    if blocks:
        spec["blocked"][p] = true

static func _fence_line(spec: Dictionary, a: Vector2i, b: Vector2i) -> void:
    if a.x == b.x:
        for y in range(mini(a.y, b.y), maxi(a.y, b.y) + 1):
            _prop(spec, Vector2i(a.x, y), Art.P_WOOD_FENCE, true)
    elif a.y == b.y:
        for x in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
            _prop(spec, Vector2i(x, a.y), Art.P_WOOD_FENCE, true)

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

static func _adjacent_to_wall(spec: Dictionary, p: Vector2i) -> bool:
    var walls: Dictionary = spec.get("walls", {})
    return walls.has(p + Vector2i.UP) or walls.has(p + Vector2i.RIGHT) or walls.has(p + Vector2i.DOWN) or walls.has(p + Vector2i.LEFT)

static func _ground_rect(spec: Dictionary, rect: Rect2i, tile: int) -> void:
    var clipped := rect.intersection(Rect2i(0, 0, WIDTH, HEIGHT))
    var ground: PackedInt32Array = spec["ground"]
    for y in range(clipped.position.y, clipped.end.y):
        for x in range(clipped.position.x, clipped.end.x):
            ground[y * WIDTH + x] = tile

static func _free_for_prop(spec: Dictionary, p: Vector2i) -> bool:
    if not _inside(p):
        return false
    if spec["walls"].has(p) or spec["doors"].has(p) or spec["windows"].has(p) or spec["props"].has(p):
        return false
    var ground: PackedInt32Array = spec["ground"]
    var tile := int(ground[p.y * WIDTH + p.x])
    return tile not in [Art.G_ROAD_H, Art.G_DIRT_ROAD_H, Art.G_DRIVEWAY]

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

static func _inside(p: Vector2i) -> bool:
    return p.x >= 0 and p.y >= 0 and p.x < WIDTH and p.y < HEIGHT
