extends RefCounted
class_name MiniRegionFocusPass

# Extraction destinations no longer need to behave like miniature versions of
# the entire world. The v4 generator still supplies the proven road skeleton and
# physical map schema, but this pass makes the whole raid read as its selected
# destination and guarantees room for deeper single-story interiors.

const RESIDENTIAL_SIZES: Array[Vector2i] = [Vector2i(14, 11), Vector2i(13, 10), Vector2i(12, 10)]
const COMMERCIAL_SIZES: Array[Vector2i] = [Vector2i(18, 12), Vector2i(16, 11), Vector2i(14, 10)]
const OFFICE_SIZES: Array[Vector2i] = [Vector2i(18, 12), Vector2i(16, 11), Vector2i(14, 10)]
const RURAL_SIZES: Array[Vector2i] = [Vector2i(13, 10), Vector2i(12, 9), Vector2i(11, 9)]
const WOODS_SIZES: Array[Vector2i] = [Vector2i(11, 9), Vector2i(10, 8)]

static func apply(spec: Dictionary, focus: String) -> void:
    _normalize_biome(spec, focus)
    match focus:
        "residential":
            _ensure_theme_count(spec, "house", 3, RESIDENTIAL_SIZES)
            _ensure_large_theme(spec, "house", Vector2i(12, 10), RESIDENTIAL_SIZES)
        "commercial":
            _ensure_theme_count(spec, "store", 2, COMMERCIAL_SIZES)
            _ensure_large_theme(spec, "store", Vector2i(14, 10), COMMERCIAL_SIZES)
        "rural":
            _ensure_theme_count(spec, "rural_wood", 2, RURAL_SIZES)
            _ensure_large_theme(spec, "rural_wood", Vector2i(11, 9), RURAL_SIZES)
        "woods":
            _ensure_theme_count(spec, "rural_wood", 1, WOODS_SIZES)
        "downtown":
            _ensure_theme_count(spec, "office", 1, OFFICE_SIZES)
            _ensure_theme_count(spec, "store", 1, COMMERCIAL_SIZES)
            _ensure_large_theme(spec, "office", Vector2i(14, 10), OFFICE_SIZES)
        _:
            _ensure_total_buildings(spec, 1, "house", RESIDENTIAL_SIZES)

static func _normalize_biome(spec: Dictionary, focus: String) -> void:
    if focus not in ["residential", "commercial", "downtown", "rural", "woods"]:
        return
    var biomes: Dictionary = spec.get("biome_cells", {})
    for p_value in biomes.keys():
        biomes[p_value] = focus
    spec["biome_cells"] = biomes
    spec["destination_focus"] = focus

static func _ensure_theme_count(spec: Dictionary, theme: String, wanted: int, sizes: Array[Vector2i]) -> void:
    var count := _theme_count(spec, theme)
    while count < wanted:
        var rect := _find_buildable_rect(spec, sizes)
        if rect.size.x <= 0:
            break
        _add_baseline_building(spec, rect, theme)
        count += 1

static func _ensure_large_theme(spec: Dictionary, theme: String, minimum: Vector2i, sizes: Array[Vector2i]) -> void:
    for building_value in spec.get("building_rects", []):
        var building: Array = building_value
        if building.size() < 5 or str(building[4]) != theme:
            continue
        if int(building[2]) >= minimum.x and int(building[3]) >= minimum.y:
            return
    var rect := _find_buildable_rect(spec, sizes)
    if rect.size.x > 0:
        _add_baseline_building(spec, rect, theme)

static func _ensure_total_buildings(spec: Dictionary, wanted: int, theme: String, sizes: Array[Vector2i]) -> void:
    while spec.get("building_rects", []).size() < wanted:
        var rect := _find_buildable_rect(spec, sizes)
        if rect.size.x <= 0:
            break
        _add_baseline_building(spec, rect, theme)

static func _theme_count(spec: Dictionary, theme: String) -> int:
    var count := 0
    for building_value in spec.get("building_rects", []):
        var building: Array = building_value
        if building.size() > 4 and str(building[4]) == theme:
            count += 1
    return count

static func _find_buildable_rect(spec: Dictionary, sizes: Array[Vector2i]) -> Rect2i:
    var width := int(spec.get("width", 64))
    var height := int(spec.get("height", 64))
    for wanted_size in sizes:
        for y in range(3, height - wanted_size.y - 2, 2):
            for x in range(3, width - wanted_size.x - 2, 2):
                var rect := Rect2i(x, y, wanted_size.x, wanted_size.y)
                if _rect_buildable(spec, rect) and _near_road(spec, rect, 6):
                    return rect
    # Last resort keeps the destination grammar intact even if frontage is a
    # little farther away on an unusually dense road seed.
    for wanted_size in sizes:
        for y in range(3, height - wanted_size.y - 2, 2):
            for x in range(3, width - wanted_size.x - 2, 2):
                var rect := Rect2i(x, y, wanted_size.x, wanted_size.y)
                if _rect_buildable(spec, rect):
                    return rect
    return Rect2i()

static func _rect_buildable(spec: Dictionary, rect: Rect2i) -> bool:
    var spawn: Vector2i = spec.get("player_spawn", Vector2i(-99, -99))
    if rect.grow(1).has_point(spawn):
        return false
    for building_value in spec.get("building_rects", []):
        if _rects_overlap(rect.grow(1), _array_rect(building_value)):
            return false
    for lot_value in spec.get("parking_lots", []):
        if _rects_overlap(rect.grow(1), _array_rect(lot_value)):
            return false
    for y in range(rect.position.y - 1, rect.end.y + 1):
        for x in range(rect.position.x - 1, rect.end.x + 1):
            var p := Vector2i(x, y)
            if spec.get("road_cells", {}).has(p):
                return false
            if spec.get("walls", []).has(p) or spec.get("glass", []).has(p):
                return false
            if _door_at(spec, p):
                return false
    return true

static func _near_road(spec: Dictionary, rect: Rect2i, max_distance: int) -> bool:
    for distance in range(1, max_distance + 1):
        for x in range(rect.position.x, rect.end.x):
            if spec.get("road_cells", {}).has(Vector2i(x, rect.position.y - distance)):
                return true
            if spec.get("road_cells", {}).has(Vector2i(x, rect.end.y - 1 + distance)):
                return true
        for y in range(rect.position.y, rect.end.y):
            if spec.get("road_cells", {}).has(Vector2i(rect.position.x - distance, y)):
                return true
            if spec.get("road_cells", {}).has(Vector2i(rect.end.x - 1 + distance, y)):
                return true
    return false

static func _add_baseline_building(spec: Dictionary, rect: Rect2i, theme: String) -> void:
    _clear_props(spec, rect.grow(1))
    var floor_kind := _floor_for_theme(theme)
    spec["ground_rects"].append([rect.position.x, rect.position.y, rect.size.x, rect.size.y, floor_kind])
    spec["indoor_rects"].append([rect.position.x, rect.position.y, rect.size.x, rect.size.y])
    spec["building_rects"].append([rect.position.x, rect.position.y, rect.size.x, rect.size.y, theme])

    for x in range(rect.position.x, rect.end.x):
        _wall(spec, Vector2i(x, rect.position.y), theme)
        _wall(spec, Vector2i(x, rect.end.y - 1), theme)
    for y in range(rect.position.y, rect.end.y):
        _wall(spec, Vector2i(rect.position.x, y), theme)
        _wall(spec, Vector2i(rect.end.x - 1, y), theme)

    var side := _nearest_road_side(spec, rect)
    var exterior_door := _wall_midpoint(rect, side)
    _add_door(spec, exterior_door, theme)
    _add_window(spec, _wall_offset(rect, side, 2), theme)
    _add_window(spec, _wall_offset(rect, side, rect.size.x - 3 if side in ["north", "south"] else rect.size.y - 3), theme)
    _add_window(spec, _wall_offset(rect, _side_clockwise(side), maxi(2, rect.size.y / 2)), theme)

    match theme:
        "store": _add_store_layout(spec, rect, exterior_door)
        "office": _add_office_layout(spec, rect, exterior_door)
        "industrial": _add_warehouse_layout(spec, rect, exterior_door)
        "house", "rural_wood": _add_house_layout(spec, rect, exterior_door)
        _: _add_simple_layout(spec, rect)

    var center := Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2)
    var light_kind := "warm" if theme in ["house", "rural_wood"] else ("fluorescent" if theme in ["store", "office"] else "security")
    spec["lights"].append([center, light_kind, true])
    if rect.size.x * rect.size.y >= 130:
        spec["lights"].append([Vector2i(rect.position.x + 2, rect.end.y - 3), light_kind, true])

static func _floor_for_theme(theme: String) -> String:
    match theme:
        "store": return "shop_floor"
        "office": return "office_carpet"
        "industrial": return "warehouse_floor"
        "house": return "hardwood_h"
        "rural_wood": return "wood"
        _: return "concrete_clean"

static func _add_house_layout(spec: Dictionary, rect: Rect2i, door: Vector2i) -> void:
    if rect.size.x < 10 or rect.size.y < 8:
        _add_simple_layout(spec, rect)
        return
    var split_x := rect.position.x + rect.size.x / 2
    var split_y := rect.position.y + rect.size.y / 2
    _interior_wall_v(spec, split_x, rect.position.y + 1, rect.end.y - 2, rect.position.y + 3)
    _interior_wall_h(spec, split_y, rect.position.x + 1, split_x - 1, rect.position.x + 3)
    _interior_wall_h(spec, split_y, split_x + 1, rect.end.x - 2, split_x + 2)
    _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, split_x - rect.position.x - 1, split_y - rect.position.y - 1), "living_room", "hardwood_h")
    _room(spec, Rect2i(rect.position.x + 1, split_y + 1, split_x - rect.position.x - 1, rect.end.y - split_y - 2), "kitchen", "tile_white")
    _room(spec, Rect2i(split_x + 1, rect.position.y + 1, rect.end.x - split_x - 2, split_y - rect.position.y - 1), "bedroom_primary", "carpet_beige")
    _room(spec, Rect2i(split_x + 1, split_y + 1, rect.end.x - split_x - 2, rect.end.y - split_y - 2), "bathroom", "tile_mosaic")
    _safe_prop(spec, Vector2i(rect.position.x + 2, rect.position.y + 2), "sofa", true, door)
    _safe_prop(spec, Vector2i(rect.position.x + 3, rect.position.y + 2), "tv_flat", false, door)
    _safe_prop(spec, Vector2i(rect.position.x + 2, rect.end.y - 2), "stove_range", true, door)
    _safe_prop(spec, Vector2i(rect.position.x + 3, rect.end.y - 2), "refrigerator_white", true, door)
    _safe_prop(spec, Vector2i(rect.end.x - 2, rect.position.y + 2), "bed_double", true, door)
    _safe_prop(spec, Vector2i(rect.end.x - 2, rect.end.y - 2), "toilet_modern", true, door)
    _safe_prop(spec, Vector2i(rect.end.x - 3, rect.end.y - 2), "bathroom_vanity", true, door)

static func _add_store_layout(spec: Dictionary, rect: Rect2i, door: Vector2i) -> void:
    if rect.size.x < 12 or rect.size.y < 9:
        _add_simple_layout(spec, rect)
        return
    var split_y := rect.end.y - 4
    _interior_wall_h(spec, split_y, rect.position.x + 1, rect.end.x - 2, rect.position.x + rect.size.x / 2)
    var office_split := rect.position.x + 4
    _interior_wall_v(spec, office_split, split_y + 1, rect.end.y - 2, split_y + 2)
    _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, split_y - rect.position.y - 1), "sales_floor", "shop_floor")
    _room(spec, Rect2i(rect.position.x + 1, split_y + 1, office_split - rect.position.x - 1, rect.end.y - split_y - 2), "manager_office", "office_carpet")
    _room(spec, Rect2i(office_split + 1, split_y + 1, rect.end.x - office_split - 2, rect.end.y - split_y - 2), "stockroom", "warehouse_floor")
    _safe_prop(spec, Vector2i(rect.position.x + 2, rect.position.y + 2), "checkout", true, door)
    _safe_prop(spec, Vector2i(rect.position.x + 4, rect.position.y + 3), "store_shelf", true, door)
    _safe_prop(spec, Vector2i(rect.end.x - 3, rect.position.y + 2), "freezer", true, door)
    _safe_prop(spec, Vector2i(rect.position.x + 2, rect.end.y - 2), "desk", true, door)
    _safe_prop(spec, Vector2i(rect.position.x + 3, rect.end.y - 2), "filing_cabinet", true, door)
    _safe_prop(spec, Vector2i(rect.end.x - 3, rect.end.y - 2), "pallet_rack", true, door)
    _safe_prop(spec, Vector2i(rect.end.x - 2, rect.end.y - 2), "cardboard", false, door)

static func _add_office_layout(spec: Dictionary, rect: Rect2i, door: Vector2i) -> void:
    if rect.size.x < 12 or rect.size.y < 9:
        _add_simple_layout(spec, rect)
        return
    var left_split := rect.position.x + 5
    var top_split := rect.position.y + 4
    var bottom_split := rect.end.y - 4
    _interior_wall_v(spec, left_split, rect.position.y + 1, rect.end.y - 2, rect.position.y + 2)
    _interior_wall_h(spec, top_split, rect.position.x + 1, left_split - 1, rect.position.x + 2)
    _interior_wall_h(spec, bottom_split, rect.position.x + 1, left_split - 1, rect.position.x + 2)
    _interior_wall_h(spec, bottom_split, left_split + 1, rect.end.x - 2, left_split + 3)
    _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, left_split - rect.position.x - 1, top_split - rect.position.y - 1), "reception", "office_carpet")
    _room(spec, Rect2i(rect.position.x + 1, top_split + 1, left_split - rect.position.x - 1, bottom_split - top_split - 1), "manager_office", "carpet_blue")
    _room(spec, Rect2i(rect.position.x + 1, bottom_split + 1, left_split - rect.position.x - 1, rect.end.y - bottom_split - 2), "storage", "concrete_clean")
    _room(spec, Rect2i(left_split + 1, rect.position.y + 1, rect.end.x - left_split - 2, bottom_split - rect.position.y - 1), "open_office", "office_carpet")
    _room(spec, Rect2i(left_split + 1, bottom_split + 1, rect.end.x - left_split - 2, rect.end.y - bottom_split - 2), "meeting_room", "carpet_blue")
    _safe_prop(spec, Vector2i(rect.position.x + 2, rect.position.y + 2), "desk", true, door)
    _safe_prop(spec, Vector2i(rect.position.x + 3, rect.position.y + 2), "computer", false, door)
    _safe_prop(spec, Vector2i(rect.position.x + 2, top_split + 2), "filing_cabinet", true, door)
    _safe_prop(spec, Vector2i(left_split + 2, rect.position.y + 2), "cubicle", true, door)
    _safe_prop(spec, Vector2i(left_split + 4, rect.position.y + 2), "office_desk", true, door)
    _safe_prop(spec, Vector2i(left_split + 2, bottom_split + 1), "dining_table", true, door)

static func _add_warehouse_layout(spec: Dictionary, rect: Rect2i, door: Vector2i) -> void:
    var split_x := rect.position.x + mini(5, maxi(3, rect.size.x / 3))
    _interior_wall_v(spec, split_x, rect.position.y + 1, rect.end.y - 2, rect.position.y + 3)
    _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, split_x - rect.position.x - 1, rect.size.y - 2), "warehouse_office", "concrete_clean")
    _room(spec, Rect2i(split_x + 1, rect.position.y + 1, rect.end.x - split_x - 2, rect.size.y - 2), "warehouse_floor", "warehouse_floor")
    _safe_prop(spec, Vector2i(rect.position.x + 2, rect.position.y + 2), "workbench", true, door)
    _safe_prop(spec, Vector2i(split_x + 2, rect.position.y + 2), "pallet_rack", true, door)
    _safe_prop(spec, Vector2i(rect.end.x - 2, rect.end.y - 2), "tool_chest", true, door)

static func _add_simple_layout(spec: Dictionary, rect: Rect2i) -> void:
    var split_x := rect.position.x + rect.size.x / 2
    _interior_wall_v(spec, split_x, rect.position.y + 1, rect.end.y - 2, rect.position.y + 3)
    _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, split_x - rect.position.x - 1, rect.size.y - 2), "front_room", _floor_for_theme("house"))
    _room(spec, Rect2i(split_x + 1, rect.position.y + 1, rect.end.x - split_x - 2, rect.size.y - 2), "back_room", _floor_for_theme("house"))

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
    if spec.get("road_cells", {}).has(p):
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

static func _add_window(spec: Dictionary, p: Vector2i, theme: String) -> void:
    if _door_at(spec, p):
        return
    _cut_wall(spec, p)
    if not spec["glass"].has(p):
        spec["glass"].append(p)
    spec["window_themes"][p] = theme

static func _door_at(spec: Dictionary, p: Vector2i) -> bool:
    for door_value in spec.get("doors", []):
        var entry: Array = door_value
        if entry[0] == p:
            return true
    return false

static func _safe_prop(spec: Dictionary, p: Vector2i, kind: String, blocking: bool, keep_clear: Vector2i = Vector2i(-999, -999)) -> void:
    if p == keep_clear or not _cell_clear_for_prop(spec, p):
        return
    if blocking and not spec["obstacles"].has(p):
        spec["obstacles"].append(p)
    spec["props"].append([p, kind])

static func _cell_clear_for_prop(spec: Dictionary, p: Vector2i) -> bool:
    if p.x < 1 or p.y < 1 or p.x >= int(spec.get("width", 64)) - 1 or p.y >= int(spec.get("height", 64)) - 1:
        return false
    if spec.get("road_cells", {}).has(p) or spec.get("walls", []).has(p) or spec.get("glass", []).has(p):
        return false
    if _door_at(spec, p):
        return false
    for prop_value in spec.get("props", []):
        var entry: Array = prop_value
        if entry[0] == p:
            return false
    return true

static func _nearest_road_side(spec: Dictionary, rect: Rect2i) -> String:
    var best_side := "south"
    var best_distance := 999
    for side in ["north", "south", "west", "east"]:
        for distance in range(1, 9):
            var found := false
            if side in ["north", "south"]:
                var y := rect.position.y - distance if side == "north" else rect.end.y - 1 + distance
                for x in range(rect.position.x, rect.end.x):
                    if spec.get("road_cells", {}).has(Vector2i(x, y)):
                        found = true
                        break
            else:
                var x := rect.position.x - distance if side == "west" else rect.end.x - 1 + distance
                for y in range(rect.position.y, rect.end.y):
                    if spec.get("road_cells", {}).has(Vector2i(x, y)):
                        found = true
                        break
            if found:
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

static func _wall_offset(rect: Rect2i, side: String, offset: int) -> Vector2i:
    if side == "north": return Vector2i(clampi(rect.position.x + offset, rect.position.x + 1, rect.end.x - 2), rect.position.y)
    if side == "south": return Vector2i(clampi(rect.position.x + offset, rect.position.x + 1, rect.end.x - 2), rect.end.y - 1)
    if side == "west": return Vector2i(rect.position.x, clampi(rect.position.y + offset, rect.position.y + 1, rect.end.y - 2))
    return Vector2i(rect.end.x - 1, clampi(rect.position.y + offset, rect.position.y + 1, rect.end.y - 2))

static func _side_clockwise(side: String) -> String:
    if side == "north": return "east"
    if side == "east": return "south"
    if side == "south": return "west"
    return "north"

static func _clear_props(spec: Dictionary, rect: Rect2i) -> void:
    var kept_props: Array = []
    for prop_value in spec.get("props", []):
        var entry: Array = prop_value
        if not rect.has_point(entry[0]):
            kept_props.append(entry)
    spec["props"] = kept_props
    var kept_obstacles: Array = []
    for p_value in spec.get("obstacles", []):
        if not rect.has_point(p_value):
            kept_obstacles.append(p_value)
    spec["obstacles"] = kept_obstacles

static func _array_rect(value) -> Rect2i:
    var entry: Array = value
    return Rect2i(int(entry[0]), int(entry[1]), int(entry[2]), int(entry[3]))

static func _rects_overlap(a: Rect2i, b: Rect2i) -> bool:
    return a.position.x < b.end.x and a.end.x > b.position.x and a.position.y < b.end.y and a.end.y > b.position.y
