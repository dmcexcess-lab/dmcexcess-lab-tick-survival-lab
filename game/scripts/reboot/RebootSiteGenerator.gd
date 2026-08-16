extends RefCounted
class_name RebootSiteGenerator

const Art = preload("res://scripts/reboot/RebootArt.gd")

const WIDTH := 64
const HEIGHT := 64
const ARCHETYPES: Array[String] = ["farmstead", "small_trailer", "double_wide", "country_house"]

static func generate(archetype: String, seed_value: int) -> Dictionary:
    var seed := maxi(1, seed_value)
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    var spec := _blank(seed, archetype)
    match archetype:
        "farmstead":
            _generate_farmstead(spec, rng)
        "small_trailer":
            _generate_small_trailer(spec, rng)
        "double_wide":
            _generate_double_wide(spec, rng)
        "country_house":
            _generate_country_house(spec, rng)
        _:
            spec["archetype"] = "farmstead"
            _generate_farmstead(spec, rng)
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
    if spec.get("buildings", []).is_empty():
        failures.append("no buildings")
    if spec.get("rooms", []).size() < 3:
        failures.append("too few functional rooms")

    var archetype := str(spec.get("archetype", ""))
    var room_names := _room_name_set(spec)
    var building_names := _building_kind_set(spec)
    match archetype:
        "farmstead":
            _require(building_names, "farmhouse", "farmhouse missing", failures)
            _require(building_names, "barn", "barn missing", failures)
            for room_name in ["living_room", "kitchen_dining", "primary_bedroom", "bedroom_2", "bathroom", "utility_laundry"]:
                _require(room_names, room_name, "farmhouse room missing: %s" % room_name, failures)
        "small_trailer":
            _require(building_names, "small_trailer", "small trailer missing", failures)
            for room_name in ["trailer_living_kitchen", "trailer_bathroom", "trailer_bedroom"]:
                _require(room_names, room_name, "trailer room missing: %s" % room_name, failures)
        "double_wide":
            _require(building_names, "double_wide", "double wide missing", failures)
            for room_name in ["doublewide_living", "doublewide_kitchen_dining", "doublewide_primary", "doublewide_bedroom_2", "doublewide_bathroom"]:
                _require(room_names, room_name, "double-wide room missing: %s" % room_name, failures)
        "country_house":
            _require(building_names, "country_house", "country house missing", failures)
            for room_name in ["living_room", "kitchen_dining", "primary_bedroom", "bathroom"]:
                _require(room_names, room_name, "country-house room missing: %s" % room_name, failures)
        _:
            failures.append("unknown archetype")

    var roadish := 0
    for value in ground:
        if value in [Art.G_ASPHALT, Art.G_DRIVEWAY_GRAVEL, Art.G_GRAVEL_DARK, Art.G_GRAVEL_LIGHT]:
            roadish += 1
    if roadish > int(float(WIDTH * HEIGHT) * 0.18):
        failures.append("road/gravel dominates site")

    return {"ok": failures.is_empty(), "failures": failures}

static func _blank(seed: int, archetype: String) -> Dictionary:
    var ground := PackedInt32Array()
    ground.resize(WIDTH * HEIGHT)
    ground.fill(Art.G_GRASS_LUSH)
    return {
        "version": 1,
        "seed": seed,
        "archetype": archetype,
        "width": WIDTH,
        "height": HEIGHT,
        "ground": ground,
        "walls": {},
        "doors": {},
        "windows": {},
        "props": {},
        "blocked": {},
        "rooms": [],
        "buildings": [],
        "spawn": Vector2i(8, 58),
        "title": "Rural Site",
    }

static func _generate_farmstead(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    spec["title"] = "Farmstead"
    _ground_rect(spec, Rect2i(2, 8, 13, 37), Art.G_FIELD_GREEN if rng.randf() < 0.55 else Art.G_FIELD_DRY)
    _ground_rect(spec, Rect2i(48, 7, 13, 34), Art.G_FIELD_DRY if rng.randf() < 0.55 else Art.G_FIELD_GREEN)
    _ground_rect(spec, Rect2i(0, 57, 26, 4), Art.G_DIRT_LIGHT)
    _ground_rect(spec, Rect2i(25, 32, 3, 28), Art.G_DRIVEWAY_GRAVEL)

    var house := Rect2i(17 + rng.randi_range(0, 2), 14 + rng.randi_range(0, 1), 24, 18)
    _farmhouse(spec, house)
    _ground_rect(spec, Rect2i(house.position.x + 4, house.end.y, 8, 2), Art.G_PATIO)

    var barn := Rect2i(46, 15, 13, 12)
    _barn(spec, barn)
    var shed := Rect2i(47, 33, 8, 7)
    _shed(spec, shed)

    _fence_rect(spec, Rect2i(1, 7, 15, 40), 3)
    _fence_rect(spec, Rect2i(47, 6, 15, 37), 3)
    _prop(spec, Vector2i(9, 54), Art.P_MAILBOX, false)
    _prop(spec, Vector2i(29, 37), Art.P_UTILITY_POLE, true)
    _prop(spec, Vector2i(43, 33), Art.P_COMPOST, false)
    _prop(spec, Vector2i(44, 35), Art.P_HAY_BALE, true)
    _prop(spec, Vector2i(57, 31), Art.P_HAY_BALE, true)
    _prop(spec, Vector2i(45, 39), Art.P_BRUSH_PILE, false)
    spec["spawn"] = Vector2i(8, 58)

static func _generate_small_trailer(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    spec["title"] = "Trailer Homestead"
    _ground_rect(spec, Rect2i(0, 55, 29, 4), Art.G_DIRT_LIGHT)
    _ground_rect(spec, Rect2i(20, 31, 3, 27), Art.G_DRIVEWAY_GRAVEL)
    _ground_rect(spec, Rect2i(16, 15, 20, 28), Art.G_GRASS_WEEDY)
    var trailer := Rect2i(22, 18, 7, 19)
    _small_trailer(spec, trailer)
    _ground_rect(spec, Rect2i(19, 36, 13, 4), Art.G_GRAVEL_LIGHT)
    _shed(spec, Rect2i(37, 23, 7, 7))
    _prop(spec, Vector2i(17, 34), Art.P_UTILITY_BOX, true)
    _prop(spec, Vector2i(31, 34), Art.P_WATER_HEATER, true)
    _prop(spec, Vector2i(34, 38), Art.P_BRANCH_PILE, false)
    _prop(spec, Vector2i(39, 34), Art.P_TOOL_CABINET, true)
    _prop(spec, Vector2i(14, 29), Art.P_STUMP, true)
    _prop(spec, Vector2i(13, 31), Art.P_WEEDS, false)
    _prop(spec, Vector2i(10, 53), Art.P_MAILBOX, false)
    for i in range(9):
        var p := Vector2i(rng.randi_range(7, 49), rng.randi_range(9, 48))
        if not _inside_building(spec, p):
            _prop(spec, p, Art.P_WEEDS if i % 2 == 0 else Art.P_TALL_GRASS, false)
    spec["spawn"] = Vector2i(8, 56)

static func _generate_double_wide(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    spec["title"] = "Double-Wide Property"
    _ground_rect(spec, Rect2i(0, 56, 31, 4), Art.G_DIRT_LIGHT)
    _ground_rect(spec, Rect2i(27, 35, 4, 24), Art.G_DRIVEWAY_GRAVEL)
    _ground_rect(spec, Rect2i(17, 15, 30, 31), Art.G_GRASS_DRY)
    var home := Rect2i(20 + rng.randi_range(0, 2), 17, 15, 17)
    _double_wide(spec, home)
    _ground_rect(spec, Rect2i(home.position.x + 3, home.end.y, 9, 3), Art.G_PATIO)
    _shed(spec, Rect2i(43, 27, 8, 7))
    _prop(spec, Vector2i(17, 32), Art.P_UTILITY_BOX, true)
    _prop(spec, Vector2i(38, 31), Art.P_WATER_HEATER, true)
    _prop(spec, Vector2i(47, 38), Art.P_FALLEN_LOG, true)
    _prop(spec, Vector2i(15, 40), Art.P_GARDEN, false)
    _prop(spec, Vector2i(13, 52), Art.P_MAILBOX, false)
    _fence_line(spec, Vector2i(14, 13), Vector2i(14, 45), 3)
    _fence_line(spec, Vector2i(53, 13), Vector2i(53, 45), 3)
    spec["spawn"] = Vector2i(10, 57)

static func _generate_country_house(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    spec["title"] = "Country House"
    _ground_rect(spec, Rect2i(0, 57, 24, 4), Art.G_DIRT_LIGHT)
    _ground_rect(spec, Rect2i(22, 34, 3, 27), Art.G_DRIVEWAY_GRAVEL)
    var house := Rect2i(18 + rng.randi_range(0, 2), 17, 20, 16)
    _country_house(spec, house)
    _ground_rect(spec, Rect2i(house.position.x + 3, house.end.y, 9, 2), Art.G_PATIO)
    _shed(spec, Rect2i(44, 21, 8, 7))
    _ground_rect(spec, Rect2i(44, 35, 12, 12), Art.G_FIELD_GREEN)
    _fence_rect(spec, Rect2i(43, 34, 14, 14), 3)
    _prop(spec, Vector2i(11, 54), Art.P_MAILBOX, false)
    _prop(spec, Vector2i(40, 32), Art.P_GARDEN, false)
    _prop(spec, Vector2i(41, 38), Art.P_COMPOST, false)
    _prop(spec, Vector2i(54, 51), Art.P_HAY_BALE, true)
    _prop(spec, Vector2i(13, 21), Art.P_TREE_LARGE, true)
    _prop(spec, Vector2i(12, 25), Art.P_BUSH, false)
    spec["spawn"] = Vector2i(8, 58)

static func _farmhouse(spec: Dictionary, rect: Rect2i) -> void:
    _shell(spec, rect, "farmhouse", Art.G_LAMINATE_LIGHT, Art.S_WALL_PANELING)
    var x := rect.position.x
    var y := rect.position.y
    var right := rect.end.x - 1
    var bottom := rect.end.y - 1
    var split_x := x + 12
    var split_y_left := y + 8
    var split_y_right_a := y + 7
    var split_y_right_b := y + 12
    _partition_v(spec, split_x, y + 1, bottom - 1, [y + 4, y + 11, y + 14])
    _partition_h(spec, split_y_left, x + 1, split_x - 1, [x + 6])
    _partition_h(spec, split_y_right_a, split_x + 1, right - 1, [split_x + 5])
    _partition_h(spec, split_y_right_b, split_x + 1, right - 1, [split_x + 4])
    var utility_split := split_x + 6
    _partition_v(spec, utility_split, split_y_right_b + 1, bottom - 1, [bottom - 2])

    _room(spec, Rect2i(x + 1, y + 1, 11, 7), "living_room", Art.G_WOOD_PARQUET)
    _room(spec, Rect2i(x + 1, split_y_left + 1, 11, bottom - split_y_left - 1), "kitchen_dining", Art.G_TILE_WHITE)
    _room(spec, Rect2i(split_x + 1, y + 1, right - split_x - 1, 6), "primary_bedroom", Art.G_CARPET_BEIGE)
    _room(spec, Rect2i(split_x + 1, split_y_right_a + 1, right - split_x - 1, 4), "bedroom_2", Art.G_CARPET_BEIGE)
    _room(spec, Rect2i(split_x + 1, split_y_right_b + 1, 5, bottom - split_y_right_b - 1), "bathroom", Art.G_TILE_MOSAIC)
    _room(spec, Rect2i(utility_split + 1, split_y_right_b + 1, right - utility_split - 1, bottom - split_y_right_b - 1), "utility_laundry", Art.G_LINOLEUM_GREEN)

    _door(spec, Vector2i(x + 6, bottom), Art.S_SCREEN_DOOR)
    _door(spec, Vector2i(right, y + 10), Art.S_SCREEN_DOOR)
    for p in [Vector2i(x + 3, y), Vector2i(x + 8, y), Vector2i(right, y + 3), Vector2i(right, y + 9), Vector2i(x, y + 4), Vector2i(x, y + 12)]:
        _window(spec, p)

    _prop(spec, Vector2i(x + 3, y + 3), Art.P_SOFA, true)
    _prop(spec, Vector2i(x + 8, y + 2), Art.P_TV, false)
    _prop(spec, Vector2i(x + 6, y + 4), Art.P_COFFEE_TABLE, true)
    _prop(spec, Vector2i(x + 2, y + 10), Art.P_STOVE, true)
    _prop(spec, Vector2i(x + 3, y + 10), Art.P_COUNTER, true)
    _prop(spec, Vector2i(x + 4, y + 10), Art.P_KITCHEN_SINK, true)
    _prop(spec, Vector2i(x + 9, y + 10), Art.P_FRIDGE, true)
    _prop(spec, Vector2i(x + 6, y + 13), Art.P_BREAKFAST_TABLE, true)
    _prop(spec, Vector2i(split_x + 3, y + 3), Art.P_BED_DOUBLE, true)
    _prop(spec, Vector2i(right - 2, y + 3), Art.P_DRESSER, true)
    _prop(spec, Vector2i(split_x + 3, y + 9), Art.P_BED_SINGLE, true)
    _prop(spec, Vector2i(split_x + 2, bottom - 2), Art.P_TOILET, true)
    _prop(spec, Vector2i(split_x + 4, bottom - 2), Art.P_BATH_VANITY, true)
    _prop(spec, Vector2i(utility_split + 1, bottom - 2), Art.P_WASHER, true)
    _prop(spec, Vector2i(utility_split + 2, bottom - 2), Art.P_DRYER, true)

static func _country_house(spec: Dictionary, rect: Rect2i) -> void:
    _shell(spec, rect, "country_house", Art.G_LAMINATE_DARK, Art.S_WALL_PANELING)
    var x := rect.position.x
    var y := rect.position.y
    var right := rect.end.x - 1
    var bottom := rect.end.y - 1
    var split_x := x + 10
    var split_y := y + 8
    _partition_v(spec, split_x, y + 1, bottom - 1, [y + 4, y + 11])
    _partition_h(spec, split_y, x + 1, split_x - 1, [x + 5])
    _partition_h(spec, y + 7, split_x + 1, right - 1, [split_x + 4])
    _partition_h(spec, y + 11, split_x + 1, right - 1, [split_x + 4])
    _room(spec, Rect2i(x + 1, y + 1, 9, 7), "living_room", Art.G_WOOD_PARQUET)
    _room(spec, Rect2i(x + 1, split_y + 1, 9, bottom - split_y - 1), "kitchen_dining", Art.G_TILE_WHITE)
    _room(spec, Rect2i(split_x + 1, y + 1, right - split_x - 1, 6), "primary_bedroom", Art.G_CARPET_BEIGE)
    _room(spec, Rect2i(split_x + 1, y + 8, right - split_x - 1, 3), "bedroom_2", Art.G_CARPET_BEIGE)
    _room(spec, Rect2i(split_x + 1, y + 12, right - split_x - 1, bottom - y - 12), "bathroom", Art.G_TILE_MOSAIC)
    _door(spec, Vector2i(x + 5, bottom), Art.S_SCREEN_DOOR)
    for p in [Vector2i(x + 3, y), Vector2i(x + 7, y), Vector2i(right, y + 4), Vector2i(x, y + 5)]:
        _window(spec, p)
    _prop(spec, Vector2i(x + 3, y + 3), Art.P_SOFA, true)
    _prop(spec, Vector2i(x + 7, y + 2), Art.P_TV, false)
    _prop(spec, Vector2i(x + 2, y + 11), Art.P_STOVE, true)
    _prop(spec, Vector2i(x + 3, y + 11), Art.P_KITCHEN_SINK, true)
    _prop(spec, Vector2i(x + 8, y + 11), Art.P_FRIDGE, true)
    _prop(spec, Vector2i(split_x + 3, y + 3), Art.P_BED_DOUBLE, true)
    _prop(spec, Vector2i(split_x + 2, bottom - 2), Art.P_TOILET, true)
    _prop(spec, Vector2i(right - 2, bottom - 2), Art.P_BATHTUB, true)

static func _small_trailer(spec: Dictionary, rect: Rect2i) -> void:
    _shell(spec, rect, "small_trailer", Art.G_LAMINATE_LIGHT, Art.S_WALL_PANELING)
    var x := rect.position.x
    var y := rect.position.y
    var right := rect.end.x - 1
    var bottom := rect.end.y - 1
    var bath_y := y + 8
    var bed_y := y + 12
    _partition_h(spec, bath_y, x + 1, right - 1, [x + 3])
    _partition_h(spec, bed_y, x + 1, right - 1, [x + 3])
    _room(spec, Rect2i(x + 1, y + 1, rect.size.x - 2, 7), "trailer_living_kitchen", Art.G_LINOLEUM_GREEN)
    _room(spec, Rect2i(x + 1, bath_y + 1, rect.size.x - 2, 3), "trailer_bathroom", Art.G_TILE_WHITE)
    _room(spec, Rect2i(x + 1, bed_y + 1, rect.size.x - 2, bottom - bed_y - 1), "trailer_bedroom", Art.G_CARPET_BEIGE)
    _door(spec, Vector2i(x, y + 4), Art.S_SCREEN_DOOR)
    _window(spec, Vector2i(right, y + 3))
    _window(spec, Vector2i(right, bottom - 3))
    _prop(spec, Vector2i(x + 2, y + 2), Art.P_SOFA, true)
    _prop(spec, Vector2i(x + 4, y + 2), Art.P_TV_OLD, false)
    _prop(spec, Vector2i(x + 2, y + 6), Art.P_STOVE, true)
    _prop(spec, Vector2i(x + 3, y + 6), Art.P_KITCHEN_SINK, true)
    _prop(spec, Vector2i(x + 4, y + 6), Art.P_FRIDGE, true)
    _prop(spec, Vector2i(x + 2, bath_y + 2), Art.P_TOILET, true)
    _prop(spec, Vector2i(x + 4, bath_y + 2), Art.P_SHOWER, true)
    _prop(spec, Vector2i(x + 3, bottom - 2), Art.P_BED_SINGLE, true)

static func _double_wide(spec: Dictionary, rect: Rect2i) -> void:
    _shell(spec, rect, "double_wide", Art.G_LAMINATE_LIGHT, Art.S_WALL_PANELING)
    var x := rect.position.x
    var y := rect.position.y
    var right := rect.end.x - 1
    var bottom := rect.end.y - 1
    var split_x := x + 7
    var split_y := y + 8
    _partition_v(spec, split_x, y + 1, bottom - 1, [y + 4, y + 12])
    _partition_h(spec, split_y, x + 1, split_x - 1, [x + 4])
    _partition_h(spec, y + 7, split_x + 1, right - 1, [split_x + 3])
    _partition_h(spec, y + 12, split_x + 1, right - 1, [split_x + 3])
    _room(spec, Rect2i(x + 1, y + 1, 6, 7), "doublewide_living", Art.G_LAMINATE_DARK)
    _room(spec, Rect2i(x + 1, split_y + 1, 6, bottom - split_y - 1), "doublewide_kitchen_dining", Art.G_TILE_WHITE)
    _room(spec, Rect2i(split_x + 1, y + 1, right - split_x - 1, 6), "doublewide_primary", Art.G_CARPET_BEIGE)
    _room(spec, Rect2i(split_x + 1, y + 8, right - split_x - 1, 4), "doublewide_bedroom_2", Art.G_CARPET_BEIGE)
    _room(spec, Rect2i(split_x + 1, y + 13, right - split_x - 1, bottom - y - 13), "doublewide_bathroom", Art.G_TILE_MOSAIC)
    _door(spec, Vector2i(x + 3, bottom), Art.S_SCREEN_DOOR)
    _door(spec, Vector2i(right, y + 9), Art.S_SCREEN_DOOR)
    for p in [Vector2i(x + 2, y), Vector2i(x + 5, y), Vector2i(right, y + 3), Vector2i(right, bottom - 3)]:
        _window(spec, p)
    _prop(spec, Vector2i(x + 2, y + 3), Art.P_SOFA, true)
    _prop(spec, Vector2i(x + 5, y + 2), Art.P_TV, false)
    _prop(spec, Vector2i(x + 2, y + 11), Art.P_STOVE, true)
    _prop(spec, Vector2i(x + 3, y + 11), Art.P_KITCHEN_SINK, true)
    _prop(spec, Vector2i(x + 5, y + 11), Art.P_FRIDGE, true)
    _prop(spec, Vector2i(split_x + 3, y + 3), Art.P_BED_DOUBLE, true)
    _prop(spec, Vector2i(split_x + 3, y + 10), Art.P_BED_SINGLE, true)
    _prop(spec, Vector2i(split_x + 2, bottom - 2), Art.P_TOILET, true)
    _prop(spec, Vector2i(right - 2, bottom - 2), Art.P_BATH_VANITY, true)

static func _barn(spec: Dictionary, rect: Rect2i) -> void:
    _shell(spec, rect, "barn", Art.G_GARAGE, Art.S_WALL_RED_BRICK)
    _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, rect.size.y - 2), "barn_floor", Art.G_GARAGE)
    _door(spec, Vector2i(rect.position.x + rect.size.x / 2, rect.end.y - 1), Art.S_DOOR_REINFORCED)
    _prop(spec, Vector2i(rect.position.x + 2, rect.position.y + 2), Art.P_HAY_BALE, true)
    _prop(spec, Vector2i(rect.position.x + 4, rect.position.y + 2), Art.P_HAY_BALE, true)
    _prop(spec, Vector2i(rect.end.x - 3, rect.position.y + 2), Art.P_WORKBENCH, true)
    _prop(spec, Vector2i(rect.end.x - 3, rect.end.y - 3), Art.P_TOOL_CABINET, true)

static func _shed(spec: Dictionary, rect: Rect2i) -> void:
    _shell(spec, rect, "shed", Art.G_GARAGE, Art.S_WALL_PANELING)
    _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, rect.size.y - 2), "shed_storage", Art.G_GARAGE)
    _door(spec, Vector2i(rect.position.x + rect.size.x / 2, rect.end.y - 1), Art.S_DOOR)
    _prop(spec, Vector2i(rect.position.x + 2, rect.position.y + 2), Art.P_WORKBENCH, true)
    _prop(spec, Vector2i(rect.end.x - 3, rect.position.y + 2), Art.P_TOOL_CABINET, true)

static func _shell(spec: Dictionary, rect: Rect2i, kind: String, floor_index: int, wall_index: int) -> void:
    _ground_rect(spec, rect, floor_index)
    spec["buildings"].append({"kind": kind, "rect": rect})
    for x in range(rect.position.x, rect.end.x):
        _wall(spec, Vector2i(x, rect.position.y), wall_index)
        _wall(spec, Vector2i(x, rect.end.y - 1), wall_index)
    for y in range(rect.position.y, rect.end.y):
        _wall(spec, Vector2i(rect.position.x, y), wall_index)
        _wall(spec, Vector2i(rect.end.x - 1, y), wall_index)

static func _room(spec: Dictionary, rect: Rect2i, name: String, floor_index: int) -> void:
    if rect.size.x <= 0 or rect.size.y <= 0:
        return
    _ground_rect(spec, rect, floor_index)
    spec["rooms"].append({"name": name, "rect": rect})

static func _partition_v(spec: Dictionary, x: int, y0: int, y1: int, door_ys: Array) -> void:
    for y in range(y0, y1 + 1):
        _wall(spec, Vector2i(x, y), Art.S_WALL_PLASTER)
    for door_y in door_ys:
        _door(spec, Vector2i(x, int(door_y)), Art.S_DOOR)

static func _partition_h(spec: Dictionary, y: int, x0: int, x1: int, door_xs: Array) -> void:
    for x in range(x0, x1 + 1):
        _wall(spec, Vector2i(x, y), Art.S_WALL_PLASTER)
    for door_x in door_xs:
        _door(spec, Vector2i(int(door_x), y), Art.S_DOOR)

static func _wall(spec: Dictionary, p: Vector2i, surface_index: int) -> void:
    if not _inside(p):
        return
    spec["doors"].erase(p)
    spec["windows"].erase(p)
    spec["walls"][p] = surface_index
    spec["blocked"][p] = true

static func _door(spec: Dictionary, p: Vector2i, surface_index: int) -> void:
    if not _inside(p):
        return
    spec["walls"].erase(p)
    spec["windows"].erase(p)
    spec["blocked"].erase(p)
    spec["doors"][p] = surface_index

static func _window(spec: Dictionary, p: Vector2i) -> void:
    if not _inside(p):
        return
    spec["walls"].erase(p)
    spec["doors"].erase(p)
    spec["windows"][p] = Art.S_WINDOW_GLASS
    spec["blocked"][p] = true

static func _prop(spec: Dictionary, p: Vector2i, prop_index: int, blocking: bool) -> void:
    if not _inside(p):
        return
    if spec["walls"].has(p) or spec["doors"].has(p) or spec["windows"].has(p) or spec["props"].has(p):
        return
    spec["props"][p] = prop_index
    if blocking:
        spec["blocked"][p] = true

static func _ground_rect(spec: Dictionary, rect: Rect2i, surface_index: int) -> void:
    var clipped := rect.intersection(Rect2i(0, 0, WIDTH, HEIGHT))
    for y in range(clipped.position.y, clipped.end.y):
        for x in range(clipped.position.x, clipped.end.x):
            _set_ground(spec, Vector2i(x, y), surface_index)

static func _set_ground(spec: Dictionary, p: Vector2i, surface_index: int) -> void:
    if not _inside(p):
        return
    var ground: PackedInt32Array = spec["ground"]
    ground[p.y * WIDTH + p.x] = surface_index

static func _fence_rect(spec: Dictionary, rect: Rect2i, spacing: int) -> void:
    for x in range(rect.position.x, rect.end.x, spacing):
        _prop(spec, Vector2i(x, rect.position.y), Art.P_WOOD_FENCE, true)
        _prop(spec, Vector2i(x, rect.end.y - 1), Art.P_WOOD_FENCE, true)
    for y in range(rect.position.y, rect.end.y, spacing):
        _prop(spec, Vector2i(rect.position.x, y), Art.P_WOOD_FENCE, true)
        _prop(spec, Vector2i(rect.end.x - 1, y), Art.P_WOOD_FENCE, true)

static func _fence_line(spec: Dictionary, a: Vector2i, b: Vector2i, spacing: int) -> void:
    if a.x == b.x:
        var y0 := mini(a.y, b.y)
        var y1 := maxi(a.y, b.y)
        for y in range(y0, y1 + 1, spacing):
            _prop(spec, Vector2i(a.x, y), Art.P_WOOD_FENCE, true)
    elif a.y == b.y:
        var x0 := mini(a.x, b.x)
        var x1 := maxi(a.x, b.x)
        for x in range(x0, x1 + 1, spacing):
            _prop(spec, Vector2i(x, a.y), Art.P_WOOD_FENCE, true)

static func _scatter_edge_nature(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    for i in range(68):
        var side := rng.randi_range(0, 3)
        var p := Vector2i.ZERO
        match side:
            0: p = Vector2i(rng.randi_range(2, WIDTH - 3), rng.randi_range(2, 8))
            1: p = Vector2i(rng.randi_range(WIDTH - 9, WIDTH - 3), rng.randi_range(2, HEIGHT - 3))
            2: p = Vector2i(rng.randi_range(2, WIDTH - 3), rng.randi_range(46, HEIGHT - 3))
            _: p = Vector2i(rng.randi_range(2, 8), rng.randi_range(2, HEIGHT - 3))
        if _inside_building(spec, p):
            continue
        var roll := rng.randf()
        if roll < 0.42:
            _prop(spec, p, Art.P_TREE_LARGE if rng.randf() < 0.35 else Art.P_TREE_SMALL, true)
        elif roll < 0.66:
            _prop(spec, p, Art.P_BUSH, false)
        elif roll < 0.84:
            _prop(spec, p, Art.P_TALL_GRASS, false)
        else:
            _prop(spec, p, Art.P_ROCK, true)

static func _clear_spawn(spec: Dictionary) -> void:
    var spawn: Vector2i = spec["spawn"]
    spec["walls"].erase(spawn)
    spec["doors"].erase(spawn)
    spec["windows"].erase(spawn)
    spec["props"].erase(spawn)
    spec["blocked"].erase(spawn)

static func _inside_building(spec: Dictionary, p: Vector2i) -> bool:
    for value in spec.get("buildings", []):
        var building: Dictionary = value
        var rect: Rect2i = building.get("rect", Rect2i())
        if rect.has_point(p):
            return true
    return false

static func _room_name_set(spec: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for value in spec.get("rooms", []):
        var room: Dictionary = value
        result[str(room.get("name", ""))] = true
    return result

static func _building_kind_set(spec: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for value in spec.get("buildings", []):
        var building: Dictionary = value
        result[str(building.get("kind", ""))] = true
    return result

static func _require(values: Dictionary, key: String, failure: String, failures: Array[String]) -> void:
    if not values.has(key):
        failures.append(failure)

static func _inside(p: Vector2i) -> bool:
    return p.x >= 0 and p.y >= 0 and p.x < WIDTH and p.y < HEIGHT
