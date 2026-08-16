extends RefCounted
class_name DestinationInteriorPass

# StreetscapePass decides what family a building is. This pass owns the next
# level down: functional room purpose and fixture density inside the selected
# extraction destination. It deliberately stays generation-only.

const DETAIL_VERSION := 1

static func apply(spec: Dictionary, _seed_value: int, focus: String) -> void:
    for building_value in spec.get("building_rects", []).duplicate():
        var building: Array = building_value
        if building.size() < 6:
            continue
        var kind := str(building[5])
        var rect := _array_rect(building)
        if kind == "mansion":
            _deep_mansion(spec, rect)
        elif kind == "duplex":
            _deep_duplex(spec, rect)
        elif kind.begins_with("strip_mall"):
            _deep_strip_mall(spec, rect, kind)
        elif kind == "trailer":
            _deep_trailer(spec, rect)
    spec["interior_detail_version"] = DETAIL_VERSION
    spec["destination_focus"] = focus

static func validate(spec: Dictionary) -> Dictionary:
    var failures: Array[String] = []
    if int(spec.get("interior_detail_version", 0)) != DETAIL_VERSION:
        failures.append("destination interior detail version missing")
    var focus := str(spec.get("region_focus", "mixed"))
    if focus in ["residential", "commercial", "downtown", "rural", "woods"]:
        for biome_value in spec.get("biome_cells", {}).values():
            if str(biome_value) != focus:
                failures.append("mixed biome leaked into focused raid: %s" % str(biome_value))
                break
    if focus == "commercial":
        if not _has_room_containing(spec, "stockroom"):
            failures.append("commercial raid missing back stockroom")
        if not _has_room_containing(spec, "manager_office"):
            failures.append("commercial raid missing manager office")
    elif focus == "downtown":
        if not _has_room_containing(spec, "manager_office"):
            failures.append("downtown raid missing manager office")
        if not _has_room_containing(spec, "office") and not _has_room_containing(spec, "reception"):
            failures.append("downtown raid missing office interior")
    elif focus == "residential":
        for wanted in ["living", "kitchen", "bedroom", "bath"]:
            if not _has_room_containing(spec, wanted):
                failures.append("residential raid missing %s room" % wanted)
    return {"ok": failures.is_empty(), "failures": failures}

static func _deep_mansion(spec: Dictionary, rect: Rect2i) -> void:
    _reset_interior(spec, rect)
    var split_x := rect.position.x + rect.size.x / 2
    var split_y := rect.position.y + rect.size.y / 2
    _interior_wall_v(spec, split_x, rect.position.y + 1, rect.end.y - 2, rect.position.y + 3)
    _interior_wall_h(spec, split_y, rect.position.x + 1, split_x - 1, rect.position.x + 3)
    _interior_wall_h(spec, split_y, split_x + 1, rect.end.x - 2, split_x + 2)

    _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, split_x - rect.position.x - 1, split_y - rect.position.y - 1), "mansion_living_room", "wood_parquet")
    _room(spec, Rect2i(rect.position.x + 1, split_y + 1, split_x - rect.position.x - 1, rect.end.y - split_y - 2), "mansion_kitchen", "tile_white")
    _room(spec, Rect2i(split_x + 1, rect.position.y + 1, rect.end.x - split_x - 2, split_y - rect.position.y - 1), "mansion_bedroom_primary", "carpet_beige")

    var rear_right := Rect2i(split_x + 1, split_y + 1, rect.end.x - split_x - 2, rect.end.y - split_y - 2)
    if rear_right.size.x >= 5:
        var bath_split := rear_right.end.x - 3
        _interior_wall_v(spec, bath_split, rear_right.position.y, rear_right.end.y - 1, rear_right.position.y + 1)
        _room(spec, Rect2i(rear_right.position.x, rear_right.position.y, bath_split - rear_right.position.x, rear_right.size.y), "mansion_bedroom_secondary", "carpet_blue")
        _room(spec, Rect2i(bath_split + 1, rear_right.position.y, rear_right.end.x - bath_split - 1, rear_right.size.y), "mansion_bathroom", "tile_mosaic")
    else:
        _room(spec, rear_right, "mansion_bathroom", "tile_mosaic")

    var exterior_door := _first_boundary_door(spec, rect)
    _safe_prop(spec, Vector2i(rect.position.x + 2, rect.position.y + 2), "sofa", true, exterior_door)
    _safe_prop(spec, Vector2i(rect.position.x + 3, rect.position.y + 2), "tv_flat", false, exterior_door)
    _safe_prop(spec, Vector2i(rect.position.x + 2, rect.end.y - 2), "stove_range", true, exterior_door)
    _safe_prop(spec, Vector2i(rect.position.x + 3, rect.end.y - 2), "refrigerator_white", true, exterior_door)
    _safe_prop(spec, Vector2i(rect.end.x - 2, rect.position.y + 2), "bed_double", true, exterior_door)
    _safe_prop(spec, Vector2i(rect.end.x - 2, rect.end.y - 2), "toilet_modern", true, exterior_door)
    _safe_prop(spec, Vector2i(rect.end.x - 3, rect.end.y - 2), "bathroom_vanity", true, exterior_door)

static func _deep_duplex(spec: Dictionary, rect: Rect2i) -> void:
    _reset_interior(spec, rect)
    var front_side := _nearest_road_side(spec, rect)
    if front_side in ["north", "south"]:
        var split_x := rect.position.x + rect.size.x / 2
        for y in range(rect.position.y + 1, rect.end.y - 1):
            _wall(spec, Vector2i(split_x, y), "interior")
        var unit_split_y := rect.position.y + rect.size.y / 2
        _interior_wall_h(spec, unit_split_y, rect.position.x + 1, split_x - 1, rect.position.x + 2)
        _interior_wall_h(spec, unit_split_y, split_x + 1, rect.end.x - 2, split_x + 2)
        _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, split_x - rect.position.x - 1, unit_split_y - rect.position.y - 1), "duplex_a_living_kitchen", "laminate_light")
        _room(spec, Rect2i(rect.position.x + 1, unit_split_y + 1, split_x - rect.position.x - 1, rect.end.y - unit_split_y - 2), "duplex_a_bed_bath", "carpet_beige")
        _room(spec, Rect2i(split_x + 1, rect.position.y + 1, rect.end.x - split_x - 2, unit_split_y - rect.position.y - 1), "duplex_b_living_kitchen", "laminate_light")
        _room(spec, Rect2i(split_x + 1, unit_split_y + 1, rect.end.x - split_x - 2, rect.end.y - unit_split_y - 2), "duplex_b_bed_bath", "carpet_beige")
        _safe_prop(spec, Vector2i(rect.position.x + 2, rect.position.y + 2), "stove_range", true)
        _safe_prop(spec, Vector2i(split_x + 2, rect.position.y + 2), "stove_range", true)
        _safe_prop(spec, Vector2i(rect.position.x + 2, rect.end.y - 2), "bed_single", true)
        _safe_prop(spec, Vector2i(rect.end.x - 2, rect.end.y - 2), "bed_single", true)
    else:
        var split_y := rect.position.y + rect.size.y / 2
        for x in range(rect.position.x + 1, rect.end.x - 1):
            _wall(spec, Vector2i(x, split_y), "interior")
        var unit_split_x := rect.position.x + rect.size.x / 2
        _interior_wall_v(spec, unit_split_x, rect.position.y + 1, split_y - 1, rect.position.y + 2)
        _interior_wall_v(spec, unit_split_x, split_y + 1, rect.end.y - 2, split_y + 2)
        _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, unit_split_x - rect.position.x - 1, split_y - rect.position.y - 1), "duplex_a_living_kitchen", "laminate_light")
        _room(spec, Rect2i(unit_split_x + 1, rect.position.y + 1, rect.end.x - unit_split_x - 2, split_y - rect.position.y - 1), "duplex_a_bed_bath", "carpet_beige")
        _room(spec, Rect2i(rect.position.x + 1, split_y + 1, unit_split_x - rect.position.x - 1, rect.end.y - split_y - 2), "duplex_b_living_kitchen", "laminate_light")
        _room(spec, Rect2i(unit_split_x + 1, split_y + 1, rect.end.x - unit_split_x - 2, rect.end.y - split_y - 2), "duplex_b_bed_bath", "carpet_beige")

static func _deep_strip_mall(spec: Dictionary, rect: Rect2i, kind: String) -> void:
    _reset_interior(spec, rect)
    var units := 3 if kind.ends_with("3") else 2
    var front_side := _nearest_road_side(spec, rect)
    if front_side in ["north", "south"]:
        for unit in range(1, units):
            var split_x := rect.position.x + int(round(float(rect.size.x) * float(unit) / float(units)))
            for y in range(rect.position.y + 1, rect.end.y - 1):
                _wall(spec, Vector2i(split_x, y), "interior")
        for unit in range(units):
            var start_x := rect.position.x + int(round(float(rect.size.x) * float(unit) / float(units)))
            var end_x := rect.position.x + int(round(float(rect.size.x) * float(unit + 1) / float(units)))
            var back_y := rect.end.y - 4 if front_side == "north" else rect.position.y + 3
            for x in range(start_x + 1, end_x):
                _wall(spec, Vector2i(x, back_y), "interior")
            _add_door(spec, Vector2i(clampi((start_x + end_x) / 2, start_x + 1, end_x - 1), back_y), "interior")
            if front_side == "north":
                _room(spec, Rect2i(start_x + 1, rect.position.y + 1, maxi(1, end_x - start_x - 1), maxi(1, back_y - rect.position.y - 1)), "strip_unit_%d_sales" % (unit + 1), "shop_floor")
                _room(spec, Rect2i(start_x + 1, back_y + 1, maxi(1, end_x - start_x - 1), maxi(1, rect.end.y - back_y - 2)), "manager_office" if unit == 0 else "strip_unit_%d_stockroom" % (unit + 1), "office_carpet" if unit == 0 else "warehouse_floor")
            else:
                _room(spec, Rect2i(start_x + 1, back_y + 1, maxi(1, end_x - start_x - 1), maxi(1, rect.end.y - back_y - 2)), "strip_unit_%d_sales" % (unit + 1), "shop_floor")
                _room(spec, Rect2i(start_x + 1, rect.position.y + 1, maxi(1, end_x - start_x - 1), maxi(1, back_y - rect.position.y - 1)), "manager_office" if unit == 0 else "strip_unit_%d_stockroom" % (unit + 1), "office_carpet" if unit == 0 else "warehouse_floor")
            _safe_prop(spec, Vector2i(start_x + 2, rect.position.y + 2), "checkout", true)
            if unit == 0:
                _safe_prop(spec, Vector2i(start_x + 2, rect.end.y - 2), "desk", true)
            else:
                _safe_prop(spec, Vector2i(start_x + 2, rect.end.y - 2), "pallet_rack", true)
    else:
        for unit in range(1, units):
            var split_y := rect.position.y + int(round(float(rect.size.y) * float(unit) / float(units)))
            for x in range(rect.position.x + 1, rect.end.x - 1):
                _wall(spec, Vector2i(x, split_y), "interior")
        for unit in range(units):
            var start_y := rect.position.y + int(round(float(rect.size.y) * float(unit) / float(units)))
            var end_y := rect.position.y + int(round(float(rect.size.y) * float(unit + 1) / float(units)))
            var back_x := rect.end.x - 4 if front_side == "west" else rect.position.x + 3
            for y in range(start_y + 1, end_y):
                _wall(spec, Vector2i(back_x, y), "interior")
            _add_door(spec, Vector2i(back_x, clampi((start_y + end_y) / 2, start_y + 1, end_y - 1)), "interior")
            if front_side == "west":
                _room(spec, Rect2i(rect.position.x + 1, start_y + 1, maxi(1, back_x - rect.position.x - 1), maxi(1, end_y - start_y - 1)), "strip_unit_%d_sales" % (unit + 1), "shop_floor")
                _room(spec, Rect2i(back_x + 1, start_y + 1, maxi(1, rect.end.x - back_x - 2), maxi(1, end_y - start_y - 1)), "manager_office" if unit == 0 else "strip_unit_%d_stockroom" % (unit + 1), "office_carpet" if unit == 0 else "warehouse_floor")
            else:
                _room(spec, Rect2i(back_x + 1, start_y + 1, maxi(1, rect.end.x - back_x - 2), maxi(1, end_y - start_y - 1)), "strip_unit_%d_sales" % (unit + 1), "shop_floor")
                _room(spec, Rect2i(rect.position.x + 1, start_y + 1, maxi(1, back_x - rect.position.x - 1), maxi(1, end_y - start_y - 1)), "manager_office" if unit == 0 else "strip_unit_%d_stockroom" % (unit + 1), "office_carpet" if unit == 0 else "warehouse_floor")

static func _deep_trailer(spec: Dictionary, rect: Rect2i) -> void:
    _reset_interior(spec, rect)
    var split_x := rect.position.x + maxi(3, rect.size.x - 4)
    if split_x >= rect.end.x - 1:
        return
    _interior_wall_v(spec, split_x, rect.position.y + 1, rect.end.y - 2, rect.position.y + 2)
    _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, split_x - rect.position.x - 1, rect.size.y - 2), "trailer_living_kitchen", "linoleum_green")
    _room(spec, Rect2i(split_x + 1, rect.position.y + 1, rect.end.x - split_x - 2, rect.size.y - 2), "trailer_bed_bath", "carpet_beige")
    _safe_prop(spec, Vector2i(rect.position.x + 2, rect.position.y + 1), "stove_range", true)
    _safe_prop(spec, Vector2i(rect.end.x - 2, rect.end.y - 2), "bed_single", true)

static func _reset_interior(spec: Dictionary, rect: Rect2i) -> void:
    var kept_rooms: Array = []
    for room_value in spec.get("rooms", []):
        var room_rect := _array_rect(room_value)
        if not _rects_overlap(rect, room_rect):
            kept_rooms.append(room_value)
    spec["rooms"] = kept_rooms

    var kept_walls: Array = []
    for p_value in spec.get("walls", []):
        var p: Vector2i = p_value
        if not _strictly_inside(rect, p):
            kept_walls.append(p)
        else:
            spec.get("wall_themes", {}).erase(p)
    spec["walls"] = kept_walls

    var kept_doors: Array = []
    for door_value in spec.get("doors", []):
        var entry: Array = door_value
        var p: Vector2i = entry[0]
        if not _strictly_inside(rect, p):
            kept_doors.append(entry)
        else:
            spec.get("door_themes", {}).erase(p)
    spec["doors"] = kept_doors

    var kept_props: Array = []
    for prop_value in spec.get("props", []):
        var entry: Array = prop_value
        if not _strictly_inside(rect, entry[0]):
            kept_props.append(entry)
    spec["props"] = kept_props

    var kept_obstacles: Array = []
    for p_value in spec.get("obstacles", []):
        if not _strictly_inside(rect, p_value):
            kept_obstacles.append(p_value)
    spec["obstacles"] = kept_obstacles

static func _room(spec: Dictionary, rect: Rect2i, kind: String, floor_kind: String) -> void:
    if rect.size.x <= 0 or rect.size.y <= 0:
        return
    spec["rooms"].append([rect.position.x, rect.position.y, rect.size.x, rect.size.y, kind])
    spec["ground_rects"].append([rect.position.x, rect.position.y, rect.size.x, rect.size.y, floor_kind])

static func _interior_wall_v(spec: Dictionary, x: int, y0: int, y1: int, door_y: int) -> void:
    for y in range(y0, y1 + 1):
        _wall(spec, Vector2i(x, y), "interior")
    _add_door(spec, Vector2i(x, door_y), "interior")

static func _interior_wall_h(spec: Dictionary, y: int, x0: int, x1: int, door_x: int) -> void:
    for x in range(x0, x1 + 1):
        _wall(spec, Vector2i(x, y), "interior")
    _add_door(spec, Vector2i(door_x, y), "interior")

static func _wall(spec: Dictionary, p: Vector2i, theme: String) -> void:
    if not _inside(spec, p) or spec.get("road_cells", {}).has(p):
        return
    if not spec["walls"].has(p):
        spec["walls"].append(p)
    spec["wall_themes"][p] = theme

static func _add_door(spec: Dictionary, p: Vector2i, theme: String) -> void:
    while spec["walls"].has(p):
        spec["walls"].erase(p)
    spec.get("wall_themes", {}).erase(p)
    for door_value in spec.get("doors", []):
        var entry: Array = door_value
        if entry[0] == p:
            return
    spec["doors"].append([p, false])
    spec["door_themes"][p] = theme

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
    for door_value in spec.get("doors", []):
        var entry: Array = door_value
        if entry[0] == p:
            return false
    for prop_value in spec.get("props", []):
        var entry: Array = prop_value
        if entry[0] == p:
            return false
    return true

static func _first_boundary_door(spec: Dictionary, rect: Rect2i) -> Vector2i:
    for door_value in spec.get("doors", []):
        var entry: Array = door_value
        var p: Vector2i = entry[0]
        if rect.has_point(p) and not _strictly_inside(rect, p):
            return p
    return Vector2i(-999, -999)

static func _nearest_road_side(spec: Dictionary, rect: Rect2i) -> String:
    var best_side := "south"
    var best_distance := 999
    for side in ["north", "south", "west", "east"]:
        for distance in range(1, 9):
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

static func _has_room_containing(spec: Dictionary, text: String) -> bool:
    for room_value in spec.get("rooms", []):
        var entry: Array = room_value
        if entry.size() > 4 and str(entry[4]).contains(text):
            return true
    return false

static func _strictly_inside(rect: Rect2i, p: Vector2i) -> bool:
    return p.x > rect.position.x and p.y > rect.position.y and p.x < rect.end.x - 1 and p.y < rect.end.y - 1

static func _inside(spec: Dictionary, p: Vector2i) -> bool:
    return p.x >= 1 and p.y >= 1 and p.x < int(spec.get("width", 64)) - 1 and p.y < int(spec.get("height", 64)) - 1

static func _array_rect(value) -> Rect2i:
    var entry: Array = value
    return Rect2i(int(entry[0]), int(entry[1]), int(entry[2]), int(entry[3]))

static func _rects_overlap(a: Rect2i, b: Rect2i) -> bool:
    return a.position.x < b.end.x and a.end.x > b.position.x and a.position.y < b.end.y and a.end.y > b.position.y
