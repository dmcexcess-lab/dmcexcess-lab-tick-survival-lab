extends RefCounted
class_name StreetscapePass

const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const SPECIAL_KINDS := ["trailer", "mansion", "duplex", "strip_mall_2", "strip_mall_3"]

static func apply(spec: Dictionary, seed_value: int, focus: String) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value * 97 + 41041
    _annotate_building_kinds(spec)
    _specialize_existing_buildings(spec, rng, focus)
    _convert_orphan_parking_to_strip_malls(spec, rng)
    _dress_streets(spec, rng)
    _sanitize_triple_door_runs(spec)
    _annotate_building_kinds(spec)

static func validate(spec: Dictionary) -> Dictionary:
    var failures: Array[String] = []
    if not _has_prop_kind(spec, "traffic_light"):
        failures.append("no generated traffic light")
    if not _has_prop_kind(spec, "stop_sign"):
        failures.append("no generated stop sign")
    if _has_triple_door_run(spec):
        failures.append("three or more adjacent doors")
    for lot_value in spec.get("parking_lots", []):
        var lot := _array_rect(lot_value)
        if not _rect_has_building(spec, lot):
            failures.append("parking lot without destination: %s" % str(lot))
            break
    for building_value in spec.get("building_rects", []):
        var building: Array = building_value
        if building.size() < 6 or str(building[5]) == "":
            failures.append("building missing family metadata")
            break
    return {"ok": failures.is_empty(), "failures": failures}

static func _annotate_building_kinds(spec: Dictionary) -> void:
    var buildings: Array = spec.get("building_rects", [])
    for i in range(buildings.size()):
        var building: Array = buildings[i]
        if building.size() >= 6:
            continue
        var theme := str(building[4]) if building.size() > 4 else "house"
        var kind := "house"
        match theme:
            "store": kind = "standalone_store"
            "office": kind = "office"
            "industrial": kind = "warehouse"
            "rural_wood": kind = "farmhouse"
            _: kind = "house"
        building.append(kind)
        buildings[i] = building
    spec["building_rects"] = buildings

static func _specialize_existing_buildings(spec: Dictionary, rng: RandomNumberGenerator, focus: String) -> void:
    match focus:
        "residential":
            _replace_first(spec, ["house"], "mansion", rng)
            _replace_first(spec, ["house"], "duplex", rng)
            _replace_first(spec, ["house", "rural_wood"], "trailer", rng)
        "commercial":
            _replace_first(spec, ["store"], "strip_mall_3", rng)
            _replace_first(spec, ["store"], "strip_mall_2", rng)
        "rural":
            _replace_first(spec, ["rural_wood", "house"], "trailer", rng)
            _replace_first(spec, ["rural_wood", "house"], "mansion", rng)
        "downtown":
            _replace_first(spec, ["store"], "strip_mall_3", rng)
            _replace_first(spec, ["house"], "duplex", rng)
        "woods":
            _replace_first(spec, ["rural_wood", "house"], "trailer", rng)
        _:
            _replace_first(spec, ["store"], "strip_mall_3", rng)
            _replace_first(spec, ["house"], "mansion", rng)
            _replace_first(spec, ["house"], "duplex", rng)
            _replace_first(spec, ["rural_wood", "house"], "trailer", rng)

static func _replace_first(spec: Dictionary, themes: Array[String], kind: String, rng: RandomNumberGenerator) -> bool:
    var buildings: Array = spec.get("building_rects", [])
    for building_value in buildings.duplicate():
        var building: Array = building_value
        if building.size() < 5 or str(building[4]) not in themes:
            continue
        var old_kind := str(building[5]) if building.size() > 5 else ""
        if old_kind in SPECIAL_KINDS:
            continue
        var rect := _array_rect(building)
        var front_side := _nearest_road_side(spec, rect)
        _remove_building(spec, building)
        match kind:
            "trailer": _add_trailer(spec, rect, front_side, rng)
            "mansion": _add_mansion(spec, rect, front_side, rng)
            "duplex": _add_duplex(spec, rect, front_side, rng)
            "strip_mall_2": _add_strip_mall(spec, rect, front_side, 2, rng)
            "strip_mall_3": _add_strip_mall(spec, rect, front_side, 3, rng)
        return true
    return false

static func _remove_building(spec: Dictionary, building: Array) -> void:
    var rect := _array_rect(building)
    spec["building_rects"].erase(building)
    _ground(spec, rect.position.x, rect.position.y, rect.size.x, rect.size.y, "grass")

    var indoor_kept: Array = []
    for value in spec.get("indoor_rects", []):
        var r := _array_rect(value)
        if not _rects_overlap(rect, r):
            indoor_kept.append(value)
    spec["indoor_rects"] = indoor_kept

    var room_kept: Array = []
    for value in spec.get("rooms", []):
        var r := _array_rect(value)
        if not _rects_overlap(rect, r):
            room_kept.append(value)
    spec["rooms"] = room_kept

    _remove_cells_in_rect(spec, "walls", rect)
    _remove_cells_in_rect(spec, "glass", rect)
    _remove_cells_in_rect(spec, "obstacles", rect)
    _remove_dict_keys_in_rect(spec.get("wall_themes", {}), rect)
    _remove_dict_keys_in_rect(spec.get("window_themes", {}), rect)
    _remove_dict_keys_in_rect(spec.get("door_themes", {}), rect)

    var door_kept: Array = []
    for door_value in spec.get("doors", []):
        var entry: Array = door_value
        if not rect.has_point(entry[0]):
            door_kept.append(entry)
    spec["doors"] = door_kept

    var prop_kept: Array = []
    for prop_value in spec.get("props", []):
        var entry: Array = prop_value
        if not rect.has_point(entry[0]):
            prop_kept.append(entry)
    spec["props"] = prop_kept

    var light_kept: Array = []
    for light_value in spec.get("lights", []):
        var entry: Array = light_value
        if not rect.has_point(entry[0]):
            light_kept.append(entry)
    spec["lights"] = light_kept

static func _add_trailer(spec: Dictionary, old_rect: Rect2i, front_side: String, rng: RandomNumberGenerator) -> void:
    var rect := Rect2i(old_rect.position.x, old_rect.position.y + 1, old_rect.size.x, mini(5, old_rect.size.y - 1))
    if rect.size.y < 5:
        rect = old_rect
    _shell(spec, rect, "laminate_light", "rural_wood", "trailer")
    var door := _wall_midpoint(rect, front_side)
    _add_door(spec, door, "rural_wood")
    _add_window(spec, _wall_offset(rect, front_side, 1), "rural_wood")
    _add_window(spec, _wall_offset(rect, _side_clockwise(front_side), 2), "rural_wood")
    var split_x := rect.position.x + maxi(3, rect.size.x - 4)
    if split_x < rect.end.x - 1:
        _interior_wall_v(spec, split_x, rect.position.y + 1, rect.end.y - 2, rect.position.y + 2)
        _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, split_x - rect.position.x - 1, rect.size.y - 2), "trailer_living_kitchen", "linoleum_green")
        _room(spec, Rect2i(split_x + 1, rect.position.y + 1, rect.end.x - split_x - 2, rect.size.y - 2), "trailer_bed_bath", "carpet_beige")
    _safe_prop(spec, Vector2i(rect.position.x + 1, rect.position.y + 1), "stove_range", true, door)
    _safe_prop(spec, Vector2i(rect.position.x + 2, rect.position.y + 1), "refrigerator_white", true, door)
    _safe_prop(spec, Vector2i(rect.end.x - 2, rect.end.y - 2), "bed_single", true, door)
    if rng.randf() < 0.7:
        _safe_prop(spec, Vector2i(rect.end.x - 2, rect.position.y + 1), "toilet_modern", true, door)

static func _add_mansion(spec: Dictionary, rect: Rect2i, front_side: String, rng: RandomNumberGenerator) -> void:
    _shell(spec, rect, "wood_parquet", "house", "mansion")
    var door := _wall_midpoint(rect, front_side)
    _add_door(spec, door, "house")
    _add_window(spec, _wall_offset(rect, front_side, 1), "house")
    _add_window(spec, _wall_offset(rect, front_side, rect.size.x - 2 if front_side in ["north", "south"] else rect.size.y - 2), "house")
    var split_x := rect.position.x + rect.size.x / 2
    var split_y := rect.position.y + rect.size.y / 2
    _interior_wall_v(spec, split_x, rect.position.y + 1, rect.end.y - 2, rect.position.y + 2)
    _interior_wall_h(spec, split_y, rect.position.x + 1, rect.end.x - 2, rect.position.x + 2)
    _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, split_x - rect.position.x - 1, split_y - rect.position.y - 1), "mansion_living", "wood_parquet")
    _room(spec, Rect2i(split_x + 1, rect.position.y + 1, rect.end.x - split_x - 2, split_y - rect.position.y - 1), "mansion_kitchen", "tile_white")
    _room(spec, Rect2i(rect.position.x + 1, split_y + 1, split_x - rect.position.x - 1, rect.end.y - split_y - 2), "mansion_bedroom", "carpet_beige")
    _room(spec, Rect2i(split_x + 1, split_y + 1, rect.end.x - split_x - 2, rect.end.y - split_y - 2), "mansion_bath", "tile_mosaic")
    _safe_prop(spec, Vector2i(rect.position.x + 1, rect.position.y + 1), "sofa", true, door)
    _safe_prop(spec, Vector2i(rect.position.x + 2, rect.position.y + 1), "tv_flat", false, door)
    _safe_prop(spec, Vector2i(rect.end.x - 2, rect.position.y + 1), "stove_range", true, door)
    _safe_prop(spec, Vector2i(rect.position.x + 1, rect.end.y - 2), "bed_double", true, door)
    _safe_prop(spec, Vector2i(rect.end.x - 2, rect.end.y - 2), "bathroom_vanity", true, door)
    if rng.randf() < 0.8:
        _safe_prop(spec, Vector2i(rect.position.x, rect.end.y), "hedge", false)

static func _add_duplex(spec: Dictionary, rect: Rect2i, front_side: String, _rng: RandomNumberGenerator) -> void:
    _shell(spec, rect, "laminate_dark", "house", "duplex")
    if front_side in ["north", "south"]:
        var split_x := rect.position.x + rect.size.x / 2
        for y in range(rect.position.y + 1, rect.end.y - 1):
            _wall(spec, Vector2i(split_x, y), "interior")
        var d1 := _wall_point(rect, front_side, 2)
        var d2 := _wall_point(rect, front_side, rect.size.x - 3)
        _add_door(spec, d1, "house")
        _add_door(spec, d2, "house")
        _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, split_x - rect.position.x - 1, rect.size.y - 2), "duplex_a", "laminate_light")
        _room(spec, Rect2i(split_x + 1, rect.position.y + 1, rect.end.x - split_x - 2, rect.size.y - 2), "duplex_b", "laminate_light")
        _safe_prop(spec, Vector2i(rect.position.x + 1, rect.position.y + 1), "stove_range", true, d1)
        _safe_prop(spec, Vector2i(rect.end.x - 2, rect.position.y + 1), "stove_range", true, d2)
    else:
        var split_y := rect.position.y + rect.size.y / 2
        for x in range(rect.position.x + 1, rect.end.x - 1):
            _wall(spec, Vector2i(x, split_y), "interior")
        var d1 := _wall_point(rect, front_side, 2)
        var d2 := _wall_point(rect, front_side, rect.size.y - 3)
        _add_door(spec, d1, "house")
        _add_door(spec, d2, "house")
        _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, split_y - rect.position.y - 1), "duplex_a", "laminate_light")
        _room(spec, Rect2i(rect.position.x + 1, split_y + 1, rect.size.x - 2, rect.end.y - split_y - 2), "duplex_b", "laminate_light")

static func _add_strip_mall(spec: Dictionary, rect: Rect2i, front_side: String, units: int, _rng: RandomNumberGenerator) -> void:
    units = clampi(units, 2, 3)
    _remove_parking_cells_in_rect(spec, rect)
    _shell(spec, rect, "shop_floor", "store", "strip_mall_%d" % units)
    if front_side in ["north", "south"]:
        for unit in range(1, units):
            var split_x := rect.position.x + int(round(float(rect.size.x) * float(unit) / float(units)))
            for y in range(rect.position.y + 1, rect.end.y - 1):
                _wall(spec, Vector2i(split_x, y), "interior")
        for unit in range(units):
            var start_x := rect.position.x + int(round(float(rect.size.x) * float(unit) / float(units)))
            var end_x := rect.position.x + int(round(float(rect.size.x) * float(unit + 1) / float(units)))
            var door_x := clampi((start_x + end_x) / 2, rect.position.x + 1, rect.end.x - 2)
            var door := Vector2i(door_x, rect.position.y if front_side == "north" else rect.end.y - 1)
            _add_door(spec, door, "storefront")
            _room(spec, Rect2i(start_x + 1, rect.position.y + 1, maxi(1, end_x - start_x - 1), rect.size.y - 2), "strip_unit_%d" % (unit + 1), "shop_floor")
            _safe_prop(spec, Vector2i(clampi(door_x, rect.position.x + 1, rect.end.x - 2), rect.position.y + 1), "checkout", true, door)
    else:
        for unit in range(1, units):
            var split_y := rect.position.y + int(round(float(rect.size.y) * float(unit) / float(units)))
            for x in range(rect.position.x + 1, rect.end.x - 1):
                _wall(spec, Vector2i(x, split_y), "interior")
        for unit in range(units):
            var start_y := rect.position.y + int(round(float(rect.size.y) * float(unit) / float(units)))
            var end_y := rect.position.y + int(round(float(rect.size.y) * float(unit + 1) / float(units)))
            var door_y := clampi((start_y + end_y) / 2, rect.position.y + 1, rect.end.y - 2)
            var door := Vector2i(rect.position.x if front_side == "west" else rect.end.x - 1, door_y)
            _add_door(spec, door, "storefront")
            _room(spec, Rect2i(rect.position.x + 1, start_y + 1, rect.size.x - 2, maxi(1, end_y - start_y - 1)), "strip_unit_%d" % (unit + 1), "shop_floor")
            _safe_prop(spec, Vector2i(rect.position.x + 1, clampi(door_y, rect.position.y + 1, rect.end.y - 2)), "checkout", true, door)
    _add_strip_windows(spec, rect, front_side)

static func _add_strip_windows(spec: Dictionary, rect: Rect2i, front_side: String) -> void:
    var steps := rect.size.x if front_side in ["north", "south"] else rect.size.y
    for offset in range(1, steps - 1):
        if offset % 3 != 0:
            var p := _wall_point(rect, front_side, offset)
            if not _door_at(spec, p):
                _add_window(spec, p, "storefront")

static func _convert_orphan_parking_to_strip_malls(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    for lot_value in spec.get("parking_lots", []).duplicate():
        var lot := _array_rect(lot_value)
        if _rect_has_building(spec, lot):
            continue
        var front_side := _nearest_road_side(spec, lot)
        var rect: Rect2i
        if front_side == "north":
            rect = Rect2i(lot.position.x, lot.end.y - 5, mini(9, lot.size.x), 5)
        elif front_side == "south":
            rect = Rect2i(lot.position.x, lot.position.y, mini(9, lot.size.x), 5)
        elif front_side == "west":
            rect = Rect2i(lot.end.x - 5, lot.position.y, 5, mini(9, lot.size.y))
        else:
            rect = Rect2i(lot.position.x, lot.position.y, 5, mini(9, lot.size.y))
        _clear_props_in_rect(spec, rect)
        _add_strip_mall(spec, rect, front_side, 3 if rng.randf() < 0.62 else 2, rng)

static func _dress_streets(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    var spawn: Vector2i = spec.get("player_spawn", Vector2i(32, 32))
    _place_roadside_prop(spec, spawn, "traffic_light", 0)
    _place_roadside_prop(spec, spawn, "traffic_light", 3)
    _place_roadside_prop(spec, spawn, "stop_sign", 6)
    _place_roadside_prop(spec, spawn, "street_name_sign", 9)

    var used: Array[Vector2i] = [spawn]
    var placed_stops := 0
    var placed_lights := 0
    for road_value in spec.get("road_cells", {}).keys():
        var p: Vector2i = road_value
        var mask := int(spec.get("road_links", {}).get(p, 0))
        if _bit_count(mask) < 3 or _near_any(p, used, 7):
            continue
        var road_class := str(spec.get("road_class_cells", {}).get(p, "local"))
        var biome := str(spec.get("biome_cells", {}).get(p, "rural"))
        if road_class in ["arterial", "secondary"] and biome in ["commercial", "downtown"] and placed_lights < 4:
            if _place_roadside_prop(spec, p, "traffic_light", placed_lights + 13):
                placed_lights += 1
                used.append(p)
                continue
        if road_class != "trail" and biome != "woods" and placed_stops < 6:
            if _place_roadside_prop(spec, p, "stop_sign", placed_stops + 23):
                _place_roadside_prop(spec, p, "street_name_sign", placed_stops + 31)
                placed_stops += 1
                used.append(p)

    var streetlights := 0
    var utility_poles := 0
    for road_value in spec.get("road_cells", {}).keys():
        var p: Vector2i = road_value
        var road_class := str(spec.get("road_class_cells", {}).get(p, "local"))
        var biome := str(spec.get("biome_cells", {}).get(p, "rural"))
        if road_class == "arterial" and biome in ["residential", "commercial", "downtown"] and posmod(p.x + p.y * 3, 13) == 0 and streetlights < 8:
            if _place_roadside_prop(spec, p, "streetlight", streetlights + 51):
                streetlights += 1
        elif biome in ["rural", "woods"] and posmod(p.x * 3 + p.y, 17) == 0 and utility_poles < 5:
            if _place_roadside_prop(spec, p, "utility_pole_wood", utility_poles + 71):
                utility_poles += 1

    if rng.randf() < 0.85:
        _place_roadside_prop(spec, spawn + Vector2i(5, 0), "hydrant", 88)

static func _place_roadside_prop(spec: Dictionary, center: Vector2i, kind: String, rotate: int) -> bool:
    var offsets: Array[Vector2i] = [
        Vector2i(-2, -2), Vector2i(2, -2), Vector2i(2, 2), Vector2i(-2, 2),
        Vector2i(-3, -2), Vector2i(3, -2), Vector2i(3, 2), Vector2i(-3, 2),
        Vector2i(-2, -3), Vector2i(2, -3), Vector2i(2, 3), Vector2i(-2, 3),
    ]
    for i in range(offsets.size()):
        var offset := offsets[posmod(i + rotate, offsets.size())]
        var p := center + offset
        if _cell_clear_for_prop(spec, p):
            _safe_prop(spec, p, kind, false)
            return true
    return false

static func _sanitize_triple_door_runs(spec: Dictionary) -> void:
    var door_positions: Dictionary = {}
    for door_value in spec.get("doors", []):
        var entry: Array = door_value
        door_positions[entry[0]] = true
    var remove: Dictionary = {}
    for p_value in door_positions.keys():
        var p: Vector2i = p_value
        if door_positions.has(p + Vector2i.LEFT) and door_positions.has(p + Vector2i.RIGHT):
            remove[p] = true
        if door_positions.has(p + Vector2i.UP) and door_positions.has(p + Vector2i.DOWN):
            remove[p] = true
    for p_value in remove.keys():
        var p: Vector2i = p_value
        _remove_door(spec, p)
        _wall(spec, p, _nearby_wall_theme(spec, p))

static func _remove_door(spec: Dictionary, p: Vector2i) -> void:
    var kept: Array = []
    for door_value in spec.get("doors", []):
        var entry: Array = door_value
        if entry[0] != p:
            kept.append(entry)
    spec["doors"] = kept
    spec.get("door_themes", {}).erase(p)

static func _nearby_wall_theme(spec: Dictionary, p: Vector2i) -> String:
    var themes: Dictionary = spec.get("wall_themes", {})
    for d in DIRS:
        if themes.has(p + d):
            return str(themes[p + d])
    return "interior"

static func _has_triple_door_run(spec: Dictionary) -> bool:
    var positions: Dictionary = {}
    for door_value in spec.get("doors", []):
        var entry: Array = door_value
        positions[entry[0]] = true
    for p_value in positions.keys():
        var p: Vector2i = p_value
        if positions.has(p + Vector2i.LEFT) and positions.has(p + Vector2i.RIGHT):
            return true
        if positions.has(p + Vector2i.UP) and positions.has(p + Vector2i.DOWN):
            return true
    return false

static func _shell(spec: Dictionary, rect: Rect2i, floor_kind: String, theme: String, kind: String) -> void:
    _ground(spec, rect.position.x, rect.position.y, rect.size.x, rect.size.y, floor_kind)
    spec["indoor_rects"].append([rect.position.x, rect.position.y, rect.size.x, rect.size.y])
    spec["building_rects"].append([rect.position.x, rect.position.y, rect.size.x, rect.size.y, theme, kind])
    for x in range(rect.position.x, rect.end.x):
        _wall(spec, Vector2i(x, rect.position.y), theme)
        _wall(spec, Vector2i(x, rect.end.y - 1), theme)
    for y in range(rect.position.y, rect.end.y):
        _wall(spec, Vector2i(rect.position.x, y), theme)
        _wall(spec, Vector2i(rect.end.x - 1, y), theme)
    var light := Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2)
    var light_kind := "warm" if theme in ["house", "rural_wood"] else "fluorescent"
    spec["lights"].append([light, light_kind, true])

static func _interior_wall_v(spec: Dictionary, x: int, y0: int, y1: int, door_y: int) -> void:
    for y in range(y0, y1 + 1):
        _wall(spec, Vector2i(x, y), "interior")
    _add_door(spec, Vector2i(x, door_y), "interior")

static func _interior_wall_h(spec: Dictionary, y: int, x0: int, x1: int, door_x: int) -> void:
    for x in range(x0, x1 + 1):
        _wall(spec, Vector2i(x, y), "interior")
    _add_door(spec, Vector2i(door_x, y), "interior")

static func _room(spec: Dictionary, rect: Rect2i, kind: String, floor_kind: String) -> void:
    if rect.size.x <= 0 or rect.size.y <= 0:
        return
    spec["rooms"].append([rect.position.x, rect.position.y, rect.size.x, rect.size.y, kind])
    _ground(spec, rect.position.x, rect.position.y, rect.size.x, rect.size.y, floor_kind)

static func _wall(spec: Dictionary, p: Vector2i, theme: String) -> void:
    if not _inside(spec, p) or spec.get("road_cells", {}).has(p):
        return
    if not spec["walls"].has(p):
        spec["walls"].append(p)
    spec["wall_themes"][p] = theme

static func _cut_wall(spec: Dictionary, p: Vector2i) -> void:
    while spec["walls"].has(p):
        spec["walls"].erase(p)
    spec.get("wall_themes", {}).erase(p)

static func _add_door(spec: Dictionary, p: Vector2i, theme: String) -> void:
    _cut_wall(spec, p)
    if _door_at(spec, p):
        return
    spec["doors"].append([p, false])
    spec["door_themes"][p] = theme

static func _door_at(spec: Dictionary, p: Vector2i) -> bool:
    for door_value in spec.get("doors", []):
        var entry: Array = door_value
        if entry[0] == p:
            return true
    return false

static func _add_window(spec: Dictionary, p: Vector2i, theme: String) -> void:
    if _door_at(spec, p):
        return
    _cut_wall(spec, p)
    if not spec["glass"].has(p):
        spec["glass"].append(p)
    spec["window_themes"][p] = theme

static func _safe_prop(spec: Dictionary, p: Vector2i, kind: String, blocking: bool, keep_clear: Vector2i = Vector2i(-999, -999)) -> void:
    if p == keep_clear or not _cell_clear_for_prop(spec, p):
        return
    if blocking and not spec["obstacles"].has(p):
        spec["obstacles"].append(p)
    spec["props"].append([p, kind])

static func _cell_clear_for_prop(spec: Dictionary, p: Vector2i) -> bool:
    if not _inside(spec, p) or spec.get("road_cells", {}).has(p):
        return false
    if spec.get("walls", []).has(p) or spec.get("glass", []).has(p):
        return false
    if _door_at(spec, p):
        return false
    for prop_value in spec.get("props", []):
        var entry: Array = prop_value
        if entry[0] == p:
            return false
    return true

static func _ground(spec: Dictionary, x: int, y: int, w: int, h: int, kind: String) -> void:
    if w <= 0 or h <= 0:
        return
    spec["ground_rects"].append([x, y, w, h, kind])

static func _array_rect(value) -> Rect2i:
    var entry: Array = value
    return Rect2i(int(entry[0]), int(entry[1]), int(entry[2]), int(entry[3]))

static func _rects_overlap(a: Rect2i, b: Rect2i) -> bool:
    return a.position.x < b.end.x and a.end.x > b.position.x and a.position.y < b.end.y and a.end.y > b.position.y

static func _rect_has_building(spec: Dictionary, rect: Rect2i) -> bool:
    for building_value in spec.get("building_rects", []):
        if _rects_overlap(rect, _array_rect(building_value)):
            return true
    return false

static func _remove_cells_in_rect(spec: Dictionary, key: String, rect: Rect2i) -> void:
    var kept: Array = []
    for value in spec.get(key, []):
        if not rect.has_point(value):
            kept.append(value)
    spec[key] = kept

static func _remove_dict_keys_in_rect(data: Dictionary, rect: Rect2i) -> void:
    for p_value in data.keys().duplicate():
        var p: Vector2i = p_value
        if rect.has_point(p):
            data.erase(p)

static func _clear_props_in_rect(spec: Dictionary, rect: Rect2i) -> void:
    var kept: Array = []
    for prop_value in spec.get("props", []):
        var entry: Array = prop_value
        if not rect.has_point(entry[0]):
            kept.append(entry)
    spec["props"] = kept
    _remove_cells_in_rect(spec, "obstacles", rect)

static func _remove_parking_cells_in_rect(spec: Dictionary, rect: Rect2i) -> void:
    var parking: Dictionary = spec.get("parking_cells", {})
    for p_value in parking.keys().duplicate():
        var p: Vector2i = p_value
        if rect.has_point(p):
            parking.erase(p)

static func _nearest_road_side(spec: Dictionary, rect: Rect2i) -> String:
    var best_side := "south"
    var best_distance := 999
    for side in ["north", "south", "west", "east"]:
        for distance in range(1, 7):
            var hit := false
            if side in ["north", "south"]:
                var y := rect.position.y - distance if side == "north" else rect.end.y - 1 + distance
                for x in range(rect.position.x, rect.end.x):
                    if spec.get("road_cells", {}).has(Vector2i(x, y)):
                        hit = true
                        break
            else:
                var x := rect.position.x - distance if side == "west" else rect.end.x - 1 + distance
                for y in range(rect.position.y, rect.end.y):
                    if spec.get("road_cells", {}).has(Vector2i(x, y)):
                        hit = true
                        break
            if hit:
                if distance < best_distance:
                    best_distance = distance
                    best_side = side
                break
    return best_side

static func _wall_midpoint(rect: Rect2i, side: String) -> Vector2i:
    if side == "north": return Vector2i(rect.position.x + rect.size.x / 2, rect.position.y)
    if side == "south": return Vector2i(rect.position.x + rect.size.x / 2, rect.end.y - 1)
    if side == "west": return Vector2i(rect.position.x, rect.position.y + rect.size.y / 2)
    return Vector2i(rect.end.x - 1, rect.position.y + rect.size.y / 2)

static func _wall_point(rect: Rect2i, side: String, offset: int) -> Vector2i:
    if side == "north": return Vector2i(clampi(rect.position.x + offset, rect.position.x + 1, rect.end.x - 2), rect.position.y)
    if side == "south": return Vector2i(clampi(rect.position.x + offset, rect.position.x + 1, rect.end.x - 2), rect.end.y - 1)
    if side == "west": return Vector2i(rect.position.x, clampi(rect.position.y + offset, rect.position.y + 1, rect.end.y - 2))
    return Vector2i(rect.end.x - 1, clampi(rect.position.y + offset, rect.position.y + 1, rect.end.y - 2))

static func _wall_offset(rect: Rect2i, side: String, offset: int) -> Vector2i:
    return _wall_point(rect, side, offset)

static func _side_clockwise(side: String) -> String:
    if side == "north": return "east"
    if side == "east": return "south"
    if side == "south": return "west"
    return "north"

static func _inside(spec: Dictionary, p: Vector2i) -> bool:
    return p.x >= 1 and p.y >= 1 and p.x < int(spec["width"]) - 1 and p.y < int(spec["height"]) - 1

static func _has_prop_kind(spec: Dictionary, kind: String) -> bool:
    for prop_value in spec.get("props", []):
        var entry: Array = prop_value
        if str(entry[1]) == kind:
            return true
    return false

static func _bit_count(mask: int) -> int:
    var count := 0
    for bit in [1, 2, 4, 8]:
        if (mask & bit) != 0:
            count += 1
    return count

static func _near_any(p: Vector2i, used: Array[Vector2i], distance: int) -> bool:
    for other in used:
        if absi(p.x - other.x) + absi(p.y - other.y) < distance:
            return true
    return false
