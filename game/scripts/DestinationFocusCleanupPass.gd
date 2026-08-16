extends RefCounted
class_name DestinationFocusCleanupPass

# V4 intentionally mixed all five biome families into one stress map. Extraction
# raids have an explicit destination identity, so incompatible legacy structures
# are removed before the focus pass adds destination-appropriate large shells.

static func apply(spec: Dictionary, focus: String) -> void:
    if focus not in ["residential", "commercial", "downtown", "rural", "woods"]:
        return
    var allowed := _allowed_themes(focus)
    for building_value in spec.get("building_rects", []).duplicate():
        var building: Array = building_value
        if building.size() < 5:
            continue
        if str(building[4]) not in allowed:
            _remove_building(spec, building, _replacement_ground(focus))
    if focus not in ["commercial", "downtown"]:
        _remove_all_parking_lots(spec, _replacement_ground(focus))
    _remove_obvious_off_theme_props(spec, focus)
    spec["focus_cleanup_version"] = 1

static func validate(spec: Dictionary) -> Dictionary:
    var failures: Array[String] = []
    var focus := str(spec.get("region_focus", "mixed"))
    if focus not in ["residential", "commercial", "downtown", "rural", "woods"]:
        return {"ok": true, "failures": failures}
    var allowed := _allowed_themes(focus)
    for building_value in spec.get("building_rects", []):
        var building: Array = building_value
        if building.size() > 4 and str(building[4]) not in allowed:
            failures.append("off-focus building theme %s in %s raid" % [str(building[4]), focus])
            break
    if focus not in ["commercial", "downtown"] and not spec.get("parking_lots", []).is_empty():
        failures.append("non-commercial raid retained parking-lot parcel")
    if int(spec.get("focus_cleanup_version", 0)) != 1:
        failures.append("focus cleanup version missing")
    return {"ok": failures.is_empty(), "failures": failures}

static func _allowed_themes(focus: String) -> Array[String]:
    match focus:
        "residential": return ["house", "rural_wood"]
        "commercial": return ["store", "office"]
        "downtown": return ["office", "store", "industrial"]
        "rural": return ["rural_wood", "house"]
        "woods": return ["rural_wood"]
        _: return ["house", "store", "office", "industrial", "rural_wood"]

static func _replacement_ground(focus: String) -> String:
    match focus:
        "commercial": return "concrete_clean"
        "downtown": return "sidewalk"
        "woods": return "forest_floor"
        "rural": return "grass_dry"
        _: return "grass_lush"

static func _remove_building(spec: Dictionary, building: Array, replacement_ground: String) -> void:
    var rect := _array_rect(building)
    spec["building_rects"].erase(building)
    spec["ground_rects"].append([rect.position.x, rect.position.y, rect.size.x, rect.size.y, replacement_ground])

    var kept_indoor: Array = []
    for value in spec.get("indoor_rects", []):
        if not _rects_overlap(rect, _array_rect(value)):
            kept_indoor.append(value)
    spec["indoor_rects"] = kept_indoor

    var kept_rooms: Array = []
    for value in spec.get("rooms", []):
        if not _rects_overlap(rect, _array_rect(value)):
            kept_rooms.append(value)
    spec["rooms"] = kept_rooms

    _remove_cells_in_rect(spec, "walls", rect)
    _remove_cells_in_rect(spec, "glass", rect)
    _remove_cells_in_rect(spec, "obstacles", rect)
    _remove_dict_keys_in_rect(spec.get("wall_themes", {}), rect)
    _remove_dict_keys_in_rect(spec.get("window_themes", {}), rect)
    _remove_dict_keys_in_rect(spec.get("door_themes", {}), rect)

    var kept_doors: Array = []
    for door_value in spec.get("doors", []):
        var entry: Array = door_value
        if not rect.has_point(entry[0]):
            kept_doors.append(entry)
    spec["doors"] = kept_doors

    var kept_props: Array = []
    for prop_value in spec.get("props", []):
        var entry: Array = prop_value
        if not rect.has_point(entry[0]):
            kept_props.append(entry)
    spec["props"] = kept_props

    var kept_lights: Array = []
    for light_value in spec.get("lights", []):
        var entry: Array = light_value
        if not rect.has_point(entry[0]):
            kept_lights.append(entry)
    spec["lights"] = kept_lights

static func _remove_all_parking_lots(spec: Dictionary, replacement_ground: String) -> void:
    for lot_value in spec.get("parking_lots", []):
        var lot := _array_rect(lot_value)
        spec["ground_rects"].append([lot.position.x, lot.position.y, lot.size.x, lot.size.y, replacement_ground])
    spec["parking_lots"] = []
    spec["parking_cells"] = {}

static func _remove_obvious_off_theme_props(spec: Dictionary, focus: String) -> void:
    var banned: Array[String] = []
    if focus in ["commercial", "downtown"]:
        banned = ["crop_green", "crop_dry", "hay_bale", "compost_pile", "firewood", "picnic_table", "propane_tank"]
    elif focus == "woods":
        banned = ["parking_meter", "shopping_cart", "checkout", "freezer", "produce_bin"]
    if banned.is_empty():
        return
    var removed_cells: Dictionary = {}
    var kept_props: Array = []
    for prop_value in spec.get("props", []):
        var entry: Array = prop_value
        if str(entry[1]) in banned:
            removed_cells[entry[0]] = true
        else:
            kept_props.append(entry)
    spec["props"] = kept_props
    if removed_cells.is_empty():
        return
    var kept_obstacles: Array = []
    for p_value in spec.get("obstacles", []):
        if not removed_cells.has(p_value):
            kept_obstacles.append(p_value)
    spec["obstacles"] = kept_obstacles

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

static func _array_rect(value) -> Rect2i:
    var entry: Array = value
    return Rect2i(int(entry[0]), int(entry[1]), int(entry[2]), int(entry[3]))

static func _rects_overlap(a: Rect2i, b: Rect2i) -> bool:
    return a.position.x < b.end.x and a.end.x > b.position.x and a.position.y < b.end.y and a.end.y > b.position.y
