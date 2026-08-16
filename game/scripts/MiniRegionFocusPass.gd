extends RefCounted
class_name MiniRegionFocusPass

# The v4 generator was designed as one mixed stress region and may legitimately
# produce zero buildings (or none of a requested theme) for arbitrary seeds.
# In the mini-world, a macro cell has an explicit identity, so prepare enough
# ordinary single-story shells for StreetscapePass to specialize deterministically.

static func apply(spec: Dictionary, focus: String) -> void:
    match focus:
        "residential":
            _ensure_theme_count(spec, "house", 3)
        "commercial":
            _ensure_theme_count(spec, "store", 2)
        "rural":
            _ensure_theme_count(spec, "rural_wood", 2)
        "woods":
            _ensure_theme_count(spec, "rural_wood", 1)
        "downtown":
            _ensure_theme_count(spec, "store", 1)
            _ensure_theme_count(spec, "house", 1)
        _:
            _ensure_total_buildings(spec, 1, "house")

static func _ensure_theme_count(spec: Dictionary, theme: String, wanted: int) -> void:
    var count := _theme_count(spec, theme)
    while count < wanted:
        var rect := _find_buildable_rect(spec)
        if rect.size.x <= 0:
            break
        _add_baseline_building(spec, rect, theme)
        count += 1

static func _ensure_total_buildings(spec: Dictionary, wanted: int, theme: String) -> void:
    while spec.get("building_rects", []).size() < wanted:
        var rect := _find_buildable_rect(spec)
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

static func _find_buildable_rect(spec: Dictionary) -> Rect2i:
    var width := int(spec.get("width", 64))
    var height := int(spec.get("height", 64))
    # 9x8 matches the useful v4 house/store scale and leaves enough interior
    # room for the later trailer/mansion/duplex/strip-mall grammars.
    for y in range(3, height - 10, 2):
        for x in range(3, width - 11, 2):
            var rect := Rect2i(x, y, 9, 8)
            if _rect_buildable(spec, rect) and _near_road(spec, rect, 5):
                return rect
    # Last resort: still prefer coherent empty ground even if frontage is a
    # little farther away; the nearest-road entrance rule remains deterministic.
    for y in range(3, height - 10, 2):
        for x in range(3, width - 11, 2):
            var rect := Rect2i(x, y, 9, 8)
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
    var floor_kind := "shop_floor" if theme == "store" else ("hardwood_h" if theme == "house" else "wood")
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

    # Two-room baseline keeps the v4 subdivision invariant intact. The v5
    # streetscape pass usually replaces these shells with richer family layouts.
    var split_x := rect.position.x + rect.size.x / 2
    for y in range(rect.position.y + 1, rect.end.y - 1):
        _wall(spec, Vector2i(split_x, y), "interior")
    var inner_door := Vector2i(split_x, rect.position.y + 3)
    _add_door(spec, inner_door, "interior")
    spec["rooms"].append([rect.position.x + 1, rect.position.y + 1, split_x - rect.position.x - 1, rect.size.y - 2, "front_room"])
    spec["rooms"].append([split_x + 1, rect.position.y + 1, rect.end.x - split_x - 2, rect.size.y - 2, "back_room"])

    var window_a := _wall_offset(rect, side, 2)
    var window_b := _wall_offset(rect, side, rect.size.x - 3 if side in ["north", "south"] else rect.size.y - 3)
    _add_window(spec, window_a, theme)
    _add_window(spec, window_b, theme)

    var light_pos := Vector2i(rect.position.x + 2, rect.position.y + 2)
    spec["lights"].append([light_pos, "fluorescent" if theme == "store" else "warm", true])

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

static func _nearest_road_side(spec: Dictionary, rect: Rect2i) -> String:
    var best_side := "south"
    var best_distance := 999
    for side in ["north", "south", "west", "east"]:
        for distance in range(1, 8):
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
