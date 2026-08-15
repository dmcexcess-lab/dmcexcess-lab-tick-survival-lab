extends RefCounted
class_name TacticalPerception

const Lighting = preload("res://scripts/TacticalLighting.gd")
const MapGen = preload("res://scripts/TacticalMapGenerator.gd")
const Weather = preload("res://scripts/TacticalWeather.gd")

const OPAQUE_PROPS := ["dumpster", "car", "store_shelf", "fridge", "crate", "forklift", "machine", "ice_box", "scrub", "tree", "bookshelf", "cabinet", "freezer", "filing_cabinet", "pallet_rack", "locker", "water_heater", "hedge", "shed"]
const FLASHLIGHT_PROFILE := {"light": "cone", "light_range": 8.0, "light_strength": 1.0, "light_spread": 0.48}
const LIGHTING_RADIUS := 13

static func map_width(spec: Dictionary) -> int:
    return int(spec.get("width", MapGen.BOARD_W))

static func map_height(spec: Dictionary) -> int:
    return int(spec.get("height", MapGen.BOARD_H))

static func theme_for_cell(spec: Dictionary, environment_id: String, cell: Vector2i) -> String:
    if environment_id != "procedural_region":
        return MapGen.theme_name(environment_id)
    var biome := str(spec.get("biome_cells", {}).get(cell, "rural"))
    match biome:
        "residential": return "house"
        "commercial": return "store"
        "downtown": return "industrial"
        "woods": return "wash"
        "rural": return "house"
        _: return "alley"

static func indoor_cells(spec: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for entry_value in spec.get("indoor_rects", []):
        var entry: Array = entry_value
        for y in range(int(entry[1]), int(entry[1]) + int(entry[3])):
            for x in range(int(entry[0]), int(entry[0]) + int(entry[2])):
                result[Vector2i(x, y)] = true
    return result

static func opaque_cells(spec: Dictionary) -> Dictionary:
    var opaque: Dictionary = {}
    var prop_by_cell: Dictionary = {}
    for entry_value in spec.get("props", []):
        var entry: Array = entry_value
        prop_by_cell[entry[0]] = str(entry[1])
        if OPAQUE_PROPS.has(str(entry[1])):
            opaque[entry[0]] = true
    for p_value in spec.get("obstacles", []):
        var p: Vector2i = p_value
        if not prop_by_cell.has(p):
            opaque[p] = true
    return opaque

static func make_sources(spec: Dictionary) -> Array:
    var sources: Array = []
    for entry_value in spec.get("lights", []):
        var entry: Array = entry_value
        if entry.size() < 2:
            continue
        var requires_power: bool = bool(entry[2]) if entry.size() >= 3 else true
        sources.append(Lighting.make_source(entry[0], str(entry[1]), sources.size(), requires_power))
    return sources

static func calculate_lighting(spec: Dictionary, world, environment_id: String, time_of_day: String, power_on: bool, player_cell: Vector2i, facing: Vector2i, flashlight_on: bool, weather_state: Dictionary = {}) -> Dictionary:
    var indoors: Dictionary = indoor_cells(spec)
    var opaque: Dictionary = opaque_cells(spec)
    var sources: Array = make_sources(spec)
    var levels: Dictionary = {}
    var tints: Dictionary = {}
    var weather_light: float = Weather.light_multiplier(weather_state) if not weather_state.is_empty() else 1.0
    var width := map_width(spec)
    var height := map_height(spec)
    var min_x := maxi(0, player_cell.x - LIGHTING_RADIUS)
    var max_x := mini(width - 1, player_cell.x + LIGHTING_RADIUS)
    var min_y := maxi(0, player_cell.y - LIGHTING_RADIUS)
    var max_y := mini(height - 1, player_cell.y + LIGHTING_RADIUS)
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            var cell := Vector2i(x, y)
            var cell_theme := theme_for_cell(spec, environment_id, cell)
            var level: float = Lighting.ambient_level(cell_theme, time_of_day, indoors.has(cell))
            if not indoors.has(cell):
                level *= weather_light
            var strongest := 0.0
            var tint_hex := ""
            for source_value in sources:
                var source: Dictionary = source_value
                if not Lighting.source_active(source, power_on):
                    continue
                var source_pos: Vector2i = source.get("pos", Vector2i(-99, -99))
                if Vector2(source_pos - cell).length() > float(source.get("radius", 6.0)) + 1.0:
                    continue
                if not line_clear(source_pos, cell, spec, world, opaque):
                    continue
                var contribution: float = Lighting.radial_contribution(cell, source)
                level = maxf(level, contribution)
                if contribution > strongest:
                    strongest = contribution
                    tint_hex = str(source.get("color", "ffffff"))
            var daylight_factor := 1.0 if time_of_day == "day" else (0.58 if time_of_day == "dawn" else (0.46 if time_of_day == "dusk" else 0.0))
            if daylight_factor > 0.0 and indoors.has(cell):
                for window_value in spec.get("glass", []):
                    var window_pos: Vector2i = window_value
                    if Vector2(window_pos - cell).length() > 5.5:
                        continue
                    if not line_clear(window_pos, cell, spec, world, opaque):
                        continue
                    var daylight: float = Lighting.window_daylight_contribution(window_pos, cell) * weather_light * daylight_factor
                    level = maxf(level, daylight)
                    if daylight > strongest:
                        strongest = daylight
                        tint_hex = "fff1c5"
            if flashlight_on and line_clear(player_cell, cell, spec, world, opaque):
                var player_level: float = Lighting.item_contribution(player_cell, facing, cell, FLASHLIGHT_PROFILE)
                level = maxf(level, player_level)
                if player_level > strongest:
                    strongest = player_level
                    tint_hex = "edf5d6"
            levels[cell] = clampf(level, 0.0, 1.0)
            if tint_hex != "":
                tints[cell] = tint_hex
    return {"levels": levels, "tints": tints, "indoors": indoors, "sources": sources, "opaque": opaque}

static func calculate_visibility(player_cell: Vector2i, facing: Vector2i, levels: Dictionary, spec: Dictionary, world, opaque: Dictionary, memory: Dictionary, max_range: int = 7, weather_state: Dictionary = {}) -> Dictionary:
    var visible: Dictionary = {}
    var updated_memory: Dictionary = memory.duplicate(true)
    var effective_range: int = max_range
    if not weather_state.is_empty():
        effective_range = maxi(2, int(round(float(max_range) * Weather.visibility_multiplier(weather_state))))
    var width := map_width(spec)
    var height := map_height(spec)
    var min_x := maxi(0, player_cell.x - effective_range)
    var max_x := mini(width - 1, player_cell.x + effective_range)
    var min_y := maxi(0, player_cell.y - effective_range)
    var max_y := mini(height - 1, player_cell.y + effective_range)
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            var p := Vector2i(x, y)
            var dist: int = absi(player_cell.x - p.x) + absi(player_cell.y - p.y)
            if p == player_cell or dist <= 1:
                visible[p] = true
                updated_memory[p] = true
                continue
            if dist > effective_range:
                continue
            if not in_cone(player_cell, facing, p, effective_range, 0.14):
                continue
            if not line_clear(player_cell, p, spec, world, opaque):
                continue
            if Lighting.visible_at_distance(float(levels.get(p, 0.0)), dist, effective_range):
                visible[p] = true
                updated_memory[p] = true
    return {"visible": visible, "memory": updated_memory, "range": effective_range}

static func line_clear(a: Vector2i, b: Vector2i, spec: Dictionary, world, opaque: Dictionary) -> bool:
    if a == b:
        return true
    var x0: int = a.x
    var y0: int = a.y
    var x1: int = b.x
    var y1: int = b.y
    var dx: int = absi(x1 - x0)
    var sx: int = 1 if x0 < x1 else -1
    var dy: int = -absi(y1 - y0)
    var sy: int = 1 if y0 < y1 else -1
    var err: int = dx + dy

    while x0 != x1 or y0 != y1:
        var old_x := x0
        var old_y := y0
        var e2: int = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy

        if x0 != old_x and y0 != old_y:
            var side_a := Vector2i(x0, old_y)
            var side_b := Vector2i(old_x, y0)
            if _blocks_vision(side_a, spec, world, opaque) and _blocks_vision(side_b, spec, world, opaque):
                return false

        var p := Vector2i(x0, y0)
        if p != b and _blocks_vision(p, spec, world, opaque):
            return false
    return true

static func _blocks_vision(p: Vector2i, spec: Dictionary, world, opaque: Dictionary) -> bool:
    return spec.get("walls", []).has(p) or opaque.has(p) or (world.is_door(p) and not world.is_door_open(p))

static func in_cone(origin: Vector2i, facing: Vector2i, p: Vector2i, max_range: int, min_dot: float) -> bool:
    var diff := Vector2(p - origin)
    if diff.length() == 0.0:
        return true
    var manhattan: int = absi(origin.x - p.x) + absi(origin.y - p.y)
    if manhattan > max_range:
        return false
    return Vector2(facing).normalized().dot(diff.normalized()) >= min_dot
