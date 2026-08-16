extends RefCounted
class_name RebootPrefabLibrary

const Art = preload("res://scripts/reboot/RebootArt.gd")

const SAVE_PATH := "user://reboot_prefabs.json"
const FORMAT_VERSION := 1
const MAX_WIDTH := 16
const MAX_HEIGHT := 14
const STAMP_MARGIN := 2
const MAX_CLEARED_VEGETATION := 8

const VEGETATION_TILES: Array[int] = [
    Art.P_TREE, Art.P_TREE_LARGE, Art.P_BUSH, Art.P_SCRUB,
    Art.P_TALL_GRASS, Art.P_WEEDS, Art.P_WILDFLOWERS,
]

const BAD_STAMP_GROUND: Array[int] = [
    Art.G_GRAVEL, Art.G_ASPHALT, Art.G_FIELD_ROWS,
    Art.G_ROAD_V, Art.G_ROAD_H, Art.G_ROAD_NE, Art.G_ROAD_ES,
    Art.G_ROAD_SW, Art.G_ROAD_WN, Art.G_ROAD_NES, Art.G_ROAD_ESW,
    Art.G_ROAD_NSW, Art.G_ROAD_NEW, Art.G_ROAD_CROSS,
    Art.G_ROAD_END_N, Art.G_ROAD_END_E, Art.G_ROAD_END_S, Art.G_ROAD_END_W,
]

static func empty_prefab(name_value: String = "New Prefab") -> Dictionary:
    return {
        "version": FORMAT_VERSION,
        "name": sanitize_name(name_value),
        "width": MAX_WIDTH,
        "height": MAX_HEIGHT,
        "ground": {},
        "walls": {},
        "doors": {},
        "door_axes": {},
        "windows": {},
        "props": {},
        "prop_blocks": {},
    }

static func editor_copy(prefab: Dictionary) -> Dictionary:
    var copy: Dictionary = prefab.duplicate(true)
    copy["version"] = FORMAT_VERSION
    copy["width"] = MAX_WIDTH
    copy["height"] = MAX_HEIGHT
    copy["name"] = sanitize_name(str(copy.get("name", "Prefab")))
    _ensure_layers(copy)
    return copy

static func sanitize_name(value: String) -> String:
    var cleaned := value.strip_edges()
    if cleaned.is_empty():
        return "Prefab"
    if cleaned.length() > 32:
        cleaned = cleaned.substr(0, 32)
    return cleaned

static func validate(prefab: Dictionary) -> Dictionary:
    var failures: Array[String] = []
    var width := int(prefab.get("width", 0))
    var height := int(prefab.get("height", 0))
    if width < 1 or height < 1 or width > MAX_WIDTH or height > MAX_HEIGHT:
        failures.append("prefab must fit inside %dx%d" % [MAX_WIDTH, MAX_HEIGHT])

    var name_value := sanitize_name(str(prefab.get("name", "")))
    if name_value.is_empty():
        failures.append("prefab needs a name")

    var used := _used_cells(prefab)
    if used.is_empty():
        failures.append("paint at least one tile")

    var layers: Array[String] = ["ground", "walls", "doors", "windows", "props"]
    for layer_name in layers:
        var layer: Dictionary = prefab.get(layer_name, {})
        for cell_value in layer.keys():
            var cell: Vector2i = cell_value
            if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
                failures.append("%s tile outside prefab at %s" % [layer_name, str(cell)])
                return {"ok": false, "failures": failures}

    var walls: Dictionary = prefab.get("walls", {})
    var doors: Dictionary = prefab.get("doors", {})
    var windows: Dictionary = prefab.get("windows", {})
    var props: Dictionary = prefab.get("props", {})
    var axes: Dictionary = prefab.get("door_axes", {})

    for cell_value in walls.keys():
        var cell: Vector2i = cell_value
        if doors.has(cell) or windows.has(cell) or props.has(cell):
            failures.append("wall shares a cell with another layer at %s" % str(cell))
            return {"ok": false, "failures": failures}
    for cell_value in windows.keys():
        var cell: Vector2i = cell_value
        if doors.has(cell) or props.has(cell):
            failures.append("window shares a cell with another layer at %s" % str(cell))
            return {"ok": false, "failures": failures}
    for cell_value in doors.keys():
        var door: Vector2i = cell_value
        if props.has(door):
            failures.append("door shares a cell with a prop at %s" % str(door))
            return {"ok": false, "failures": failures}
        var axis := str(axes.get(door, ""))
        if axis not in ["h", "v"]:
            failures.append("door needs H or V wall orientation at %s" % str(door))
            return {"ok": false, "failures": failures}
        var approach_a := door + (Vector2i.UP if axis == "h" else Vector2i.LEFT)
        var approach_b := door + (Vector2i.DOWN if axis == "h" else Vector2i.RIGHT)
        var wall_a := door + (Vector2i.LEFT if axis == "h" else Vector2i.UP)
        var wall_b := door + (Vector2i.RIGHT if axis == "h" else Vector2i.DOWN)
        if not _structural_at(prefab, wall_a) or not _structural_at(prefab, wall_b):
            failures.append("door must sit between two wall/window cells at %s" % str(door))
            return {"ok": false, "failures": failures}
        if _occupied_structure_or_prop(prefab, approach_a) or _occupied_structure_or_prop(prefab, approach_b):
            failures.append("door approach must stay clear at %s" % str(door))
            return {"ok": false, "failures": failures}

    return {"ok": failures.is_empty(), "failures": failures}

static func normalize_for_save(prefab: Dictionary) -> Dictionary:
    var source: Dictionary = prefab.duplicate(true)
    _ensure_layers(source)
    var used := _used_cells(source)
    if used.is_empty():
        return source

    var min_x := MAX_WIDTH
    var min_y := MAX_HEIGHT
    var max_x := 0
    var max_y := 0
    for cell_value in used.keys():
        var cell: Vector2i = cell_value
        min_x = mini(min_x, cell.x)
        min_y = mini(min_y, cell.y)
        max_x = maxi(max_x, cell.x)
        max_y = maxi(max_y, cell.y)
    var offset := Vector2i(min_x, min_y)
    var result := empty_prefab(str(source.get("name", "Prefab")))
    result["width"] = max_x - min_x + 1
    result["height"] = max_y - min_y + 1
    for layer_name in ["ground", "walls", "doors", "windows", "props", "door_axes", "prop_blocks"]:
        var source_layer: Dictionary = source.get(layer_name, {})
        var target_layer: Dictionary = result[layer_name]
        for cell_value in source_layer.keys():
            var cell: Vector2i = cell_value
            target_layer[cell - offset] = source_layer[cell]
    return result

static func load_all() -> Array:
    if not FileAccess.file_exists(SAVE_PATH):
        return []
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return []
    var decoded = JSON.parse_string(file.get_as_text())
    if typeof(decoded) != TYPE_DICTIONARY:
        return []
    var root: Dictionary = decoded
    var records: Array = root.get("prefabs", [])
    var result: Array = []
    for record_value in records:
        if typeof(record_value) != TYPE_DICTIONARY:
            continue
        var prefab := from_storage_record(record_value)
        var check := validate(prefab)
        if bool(check.get("ok", false)):
            result.append(prefab)
    return result

static func save_prefab(prefab: Dictionary) -> Dictionary:
    var normalized := normalize_for_save(prefab)
    normalized["name"] = sanitize_name(str(prefab.get("name", "Prefab")))
    var check := validate(normalized)
    if not bool(check.get("ok", false)):
        return {"ok": false, "message": _first_failure(check), "prefab": normalized}

    var prefabs := load_all()
    var replaced := false
    var wanted := str(normalized["name"]).to_lower()
    for i in range(prefabs.size()):
        var existing: Dictionary = prefabs[i]
        if str(existing.get("name", "")).to_lower() == wanted:
            prefabs[i] = normalized
            replaced = true
            break
    if not replaced:
        prefabs.append(normalized)
    if not _write_all(prefabs):
        return {"ok": false, "message": "could not write prefab library", "prefab": normalized}
    return {"ok": true, "message": "saved %s (%dx%d)" % [str(normalized["name"]), int(normalized["width"]), int(normalized["height"])], "prefab": normalized}

static func delete_prefab(name_value: String) -> bool:
    var prefabs := load_all()
    var wanted := name_value.to_lower()
    var kept: Array = []
    for prefab_value in prefabs:
        var prefab: Dictionary = prefab_value
        if str(prefab.get("name", "")).to_lower() != wanted:
            kept.append(prefab)
    return _write_all(kept)

static func to_storage_record(prefab: Dictionary) -> Dictionary:
    var normalized := normalize_for_save(prefab)
    return {
        "version": FORMAT_VERSION,
        "name": sanitize_name(str(normalized.get("name", "Prefab"))),
        "width": int(normalized.get("width", 1)),
        "height": int(normalized.get("height", 1)),
        "ground": _encode_layer(normalized.get("ground", {}), false),
        "walls": _encode_layer(normalized.get("walls", {}), false),
        "doors": _encode_doors(normalized),
        "windows": _encode_layer(normalized.get("windows", {}), false),
        "props": _encode_props(normalized),
    }

static func from_storage_record(record: Dictionary) -> Dictionary:
    var prefab := empty_prefab(str(record.get("name", "Prefab")))
    prefab["width"] = clampi(int(record.get("width", 1)), 1, MAX_WIDTH)
    prefab["height"] = clampi(int(record.get("height", 1)), 1, MAX_HEIGHT)
    prefab["ground"] = _decode_layer(record.get("ground", []))
    prefab["walls"] = _decode_layer(record.get("walls", []))
    prefab["windows"] = _decode_layer(record.get("windows", []))
    _decode_doors(record.get("doors", []), prefab)
    _decode_props(record.get("props", []), prefab)
    return prefab

static func cell_reserved_by_door(prefab: Dictionary, cell: Vector2i) -> bool:
    var doors: Dictionary = prefab.get("doors", {})
    var axes: Dictionary = prefab.get("door_axes", {})
    for door_value in doors.keys():
        var door: Vector2i = door_value
        if cell == door:
            return true
        var axis := str(axes.get(door, "h"))
        if axis == "h" and cell in [door + Vector2i.UP, door + Vector2i.DOWN]:
            return true
        if axis == "v" and cell in [door + Vector2i.LEFT, door + Vector2i.RIGHT]:
            return true
    return false

static func try_stamp_random(spec: Dictionary, prefabs: Array, seed_value: int) -> Dictionary:
    var valid: Array = []
    for prefab_value in prefabs:
        if typeof(prefab_value) != TYPE_DICTIONARY:
            continue
        var prefab: Dictionary = prefab_value
        var check := validate(prefab)
        if bool(check.get("ok", false)):
            valid.append(normalize_for_save(prefab))
    if valid.is_empty():
        return {"stamped": false, "reason": "no valid saved prefabs"}

    var rng := RandomNumberGenerator.new()
    rng.seed = maxi(1, seed_value ^ 0x5A17C3)
    var first := posmod(seed_value, valid.size())
    for offset in range(valid.size()):
        var prefab: Dictionary = valid[(first + offset) % valid.size()]
        var candidates := _stamp_candidates(spec, prefab)
        if candidates.is_empty():
            continue
        var origin: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
        _stamp(spec, prefab, origin)
        return {"stamped": true, "name": str(prefab.get("name", "Prefab")), "origin": origin, "size": Vector2i(int(prefab["width"]), int(prefab["height"]))}
    return {"stamped": false, "reason": "no safe prefab footprint in this seed"}

static func _stamp_candidates(spec: Dictionary, prefab: Dictionary) -> Array:
    var result: Array = []
    var width := int(prefab.get("width", 1))
    var height := int(prefab.get("height", 1))
    var map_w := int(spec.get("width", 0))
    var map_h := int(spec.get("height", 0))
    for y in range(STAMP_MARGIN, map_h - height - STAMP_MARGIN + 1):
        for x in range(STAMP_MARGIN, map_w - width - STAMP_MARGIN + 1):
            var origin := Vector2i(x, y)
            if _can_stamp(spec, prefab, origin):
                result.append(origin)
    return result

static func _can_stamp(spec: Dictionary, prefab: Dictionary, origin: Vector2i) -> bool:
    var width := int(prefab.get("width", 1))
    var height := int(prefab.get("height", 1))
    var footprint := Rect2i(origin, Vector2i(width, height))
    var spawn: Vector2i = spec.get("spawn", Vector2i(-100, -100))
    var expanded := Rect2i(footprint.position - Vector2i(2, 2), footprint.size + Vector2i(4, 4))
    if expanded.has_point(spawn):
        return false

    for building_value in spec.get("buildings", []):
        var building: Dictionary = building_value
        var rect: Rect2i = building.get("rect", Rect2i())
        var padded := Rect2i(rect.position - Vector2i(2, 2), rect.size + Vector2i(4, 4))
        if padded.intersects(footprint):
            return false

    var road_cells: Dictionary = spec.get("road_cells", {})
    var side_road_cells: Dictionary = spec.get("side_road_cells", {})
    var walls: Dictionary = spec.get("walls", {})
    var doors: Dictionary = spec.get("doors", {})
    var windows: Dictionary = spec.get("windows", {})
    var props: Dictionary = spec.get("props", {})
    var ground: PackedInt32Array = spec.get("ground", PackedInt32Array())
    var map_w := int(spec.get("width", 0))
    var vegetation_to_clear := 0

    for y in range(footprint.position.y, footprint.end.y):
        for x in range(footprint.position.x, footprint.end.x):
            var cell := Vector2i(x, y)
            if road_cells.has(cell) or side_road_cells.has(cell):
                return false
            if walls.has(cell) or doors.has(cell) or windows.has(cell):
                return false
            if ground.size() > cell.y * map_w + cell.x and int(ground[cell.y * map_w + cell.x]) in BAD_STAMP_GROUND:
                return false
            if props.has(cell):
                if int(props[cell]) not in VEGETATION_TILES:
                    return false
                vegetation_to_clear += 1
                if vegetation_to_clear > MAX_CLEARED_VEGETATION:
                    return false

    var clearance := _door_clearance_world(prefab, origin)
    for clear_value in clearance.keys():
        var cell: Vector2i = clear_value
        if cell.x < 0 or cell.y < 0 or cell.x >= int(spec.get("width", 0)) or cell.y >= int(spec.get("height", 0)):
            return false
        if road_cells.has(cell) or side_road_cells.has(cell) or walls.has(cell) or doors.has(cell) or windows.has(cell):
            return false
        if props.has(cell) and int(props[cell]) not in VEGETATION_TILES:
            return false
    return true

static func _stamp(spec: Dictionary, prefab: Dictionary, origin: Vector2i) -> void:
    var width := int(prefab.get("width", 1))
    var height := int(prefab.get("height", 1))
    var footprint := Rect2i(origin, Vector2i(width, height))
    var props: Dictionary = spec.get("props", {})
    var blocked: Dictionary = spec.get("blocked", {})
    var fixture_tags: Dictionary = spec.get("fixture_tags", {})

    for y in range(footprint.position.y, footprint.end.y):
        for x in range(footprint.position.x, footprint.end.x):
            var cell := Vector2i(x, y)
            if props.has(cell) and int(props[cell]) in VEGETATION_TILES:
                props.erase(cell)
                fixture_tags.erase(cell)
                if not spec.get("walls", {}).has(cell) and not spec.get("windows", {}).has(cell):
                    blocked.erase(cell)

    var map_w := int(spec.get("width", 0))
    var ground_array: PackedInt32Array = spec.get("ground", PackedInt32Array())
    var ground: Dictionary = prefab.get("ground", {})
    for local_value in ground.keys():
        var local: Vector2i = local_value
        var world := origin + local
        ground_array[world.y * map_w + world.x] = int(ground[local])

    var walls: Dictionary = prefab.get("walls", {})
    for local_value in walls.keys():
        var local: Vector2i = local_value
        var world := origin + local
        spec["walls"][world] = int(walls[local])
        spec["windows"].erase(world)
        spec["doors"].erase(world)
        spec["props"].erase(world)
        spec["blocked"][world] = true

    var windows: Dictionary = prefab.get("windows", {})
    for local_value in windows.keys():
        var local: Vector2i = local_value
        var world := origin + local
        spec["walls"].erase(world)
        spec["doors"].erase(world)
        spec["props"].erase(world)
        spec["windows"][world] = int(windows[local])
        spec["blocked"][world] = true

    var doors: Dictionary = prefab.get("doors", {})
    var axes: Dictionary = prefab.get("door_axes", {})
    for local_value in doors.keys():
        var local: Vector2i = local_value
        var world := origin + local
        var axis := str(axes.get(local, "h"))
        spec["walls"].erase(world)
        spec["windows"].erase(world)
        spec["props"].erase(world)
        spec["blocked"].erase(world)
        spec["doors"][world] = int(doors[local])
        spec["door_axes"][world] = axis
        spec["door_clear"][world] = true
        var approaches: Array[Vector2i] = [world + (Vector2i.UP if axis == "h" else Vector2i.LEFT), world + (Vector2i.DOWN if axis == "h" else Vector2i.RIGHT)]
        for clear_cell in approaches:
            spec["door_clear"][clear_cell] = true
            if spec["props"].has(clear_cell) and int(spec["props"][clear_cell]) in VEGETATION_TILES:
                spec["props"].erase(clear_cell)
            spec["fixture_tags"].erase(clear_cell)
            spec["blocked"].erase(clear_cell)

    var prefab_props: Dictionary = prefab.get("props", {})
    var prop_blocks: Dictionary = prefab.get("prop_blocks", {})
    for local_value in prefab_props.keys():
        var local: Vector2i = local_value
        var world := origin + local
        spec["props"][world] = int(prefab_props[local])
        if bool(prop_blocks.get(local, true)):
            spec["blocked"][world] = true
        else:
            spec["blocked"].erase(world)

    spec["buildings"].append({"kind":"user_prefab", "property_id":"", "rect":footprint, "prefab_name":str(prefab.get("name", "Prefab"))})
    if not spec.has("user_prefabs_used"):
        spec["user_prefabs_used"] = []
    spec["user_prefabs_used"].append({"name":str(prefab.get("name", "Prefab")), "origin":origin, "size":Vector2i(width, height)})
    spec["prefab_pass_version"] = FORMAT_VERSION

static func _door_clearance_world(prefab: Dictionary, origin: Vector2i) -> Dictionary:
    var result: Dictionary = {}
    var doors: Dictionary = prefab.get("doors", {})
    var axes: Dictionary = prefab.get("door_axes", {})
    for local_value in doors.keys():
        var local: Vector2i = local_value
        var world := origin + local
        var axis := str(axes.get(local, "h"))
        result[world] = true
        result[world + (Vector2i.UP if axis == "h" else Vector2i.LEFT)] = true
        result[world + (Vector2i.DOWN if axis == "h" else Vector2i.RIGHT)] = true
    return result

static func _write_all(prefabs: Array) -> bool:
    var records: Array = []
    for prefab_value in prefabs:
        if typeof(prefab_value) == TYPE_DICTIONARY:
            records.append(to_storage_record(prefab_value))
    var root := {"version": FORMAT_VERSION, "prefabs": records}
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(root, "  "))
    file.flush()
    return true

static func _encode_layer(layer: Dictionary, _unused: bool) -> Array:
    var result: Array = []
    for cell_value in layer.keys():
        var cell: Vector2i = cell_value
        result.append([cell.x, cell.y, int(layer[cell])])
    return result

static func _encode_doors(prefab: Dictionary) -> Array:
    var result: Array = []
    var doors: Dictionary = prefab.get("doors", {})
    var axes: Dictionary = prefab.get("door_axes", {})
    for cell_value in doors.keys():
        var cell: Vector2i = cell_value
        result.append([cell.x, cell.y, int(doors[cell]), str(axes.get(cell, "h"))])
    return result

static func _encode_props(prefab: Dictionary) -> Array:
    var result: Array = []
    var props: Dictionary = prefab.get("props", {})
    var blocks: Dictionary = prefab.get("prop_blocks", {})
    for cell_value in props.keys():
        var cell: Vector2i = cell_value
        result.append([cell.x, cell.y, int(props[cell]), bool(blocks.get(cell, true))])
    return result

static func _decode_layer(entries_value) -> Dictionary:
    var result: Dictionary = {}
    if typeof(entries_value) != TYPE_ARRAY:
        return result
    var entries: Array = entries_value
    for entry_value in entries:
        if typeof(entry_value) != TYPE_ARRAY:
            continue
        var entry: Array = entry_value
        if entry.size() < 3:
            continue
        result[Vector2i(int(entry[0]), int(entry[1]))] = int(entry[2])
    return result

static func _decode_doors(entries_value, prefab: Dictionary) -> void:
    if typeof(entries_value) != TYPE_ARRAY:
        return
    var entries: Array = entries_value
    for entry_value in entries:
        if typeof(entry_value) != TYPE_ARRAY:
            continue
        var entry: Array = entry_value
        if entry.size() < 4:
            continue
        var cell := Vector2i(int(entry[0]), int(entry[1]))
        prefab["doors"][cell] = int(entry[2])
        prefab["door_axes"][cell] = str(entry[3])

static func _decode_props(entries_value, prefab: Dictionary) -> void:
    if typeof(entries_value) != TYPE_ARRAY:
        return
    var entries: Array = entries_value
    for entry_value in entries:
        if typeof(entry_value) != TYPE_ARRAY:
            continue
        var entry: Array = entry_value
        if entry.size() < 3:
            continue
        var cell := Vector2i(int(entry[0]), int(entry[1]))
        prefab["props"][cell] = int(entry[2])
        prefab["prop_blocks"][cell] = bool(entry[3]) if entry.size() > 3 else true

static func _used_cells(prefab: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for layer_name in ["ground", "walls", "doors", "windows", "props"]:
        var layer: Dictionary = prefab.get(layer_name, {})
        for cell_value in layer.keys():
            result[cell_value] = true
    return result

static func _ensure_layers(prefab: Dictionary) -> void:
    for layer_name in ["ground", "walls", "doors", "door_axes", "windows", "props", "prop_blocks"]:
        if not prefab.has(layer_name) or typeof(prefab[layer_name]) != TYPE_DICTIONARY:
            prefab[layer_name] = {}

static func _structural_at(prefab: Dictionary, cell: Vector2i) -> bool:
    return prefab.get("walls", {}).has(cell) or prefab.get("windows", {}).has(cell)

static func _occupied_structure_or_prop(prefab: Dictionary, cell: Vector2i) -> bool:
    return prefab.get("walls", {}).has(cell) or prefab.get("windows", {}).has(cell) or prefab.get("doors", {}).has(cell) or prefab.get("props", {}).has(cell)

static func _first_failure(check: Dictionary) -> String:
    var failures: Array = check.get("failures", [])
    if failures.is_empty():
        return "invalid prefab"
    return str(failures[0])
