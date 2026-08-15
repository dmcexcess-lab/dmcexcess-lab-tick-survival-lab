extends RefCounted
class_name ProceduralRegionGenerator

const REGION_W := 64
const REGION_H := 64
const GENERATOR_VERSION := 4

const ROAD_N := 1
const ROAD_E := 2
const ROAD_S := 4
const ROAD_W := 8

const BIOMES := ["residential", "commercial", "downtown", "woods", "rural"]
const DEVELOPED_BIOMES := ["residential", "commercial", "downtown"]
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const ROAD_RANK := {"trail": 0, "local": 1, "secondary": 2, "arterial": 3}
const PARCEL_W := 10
const PARCEL_H := 11

static func generate(seed_value: int, width: int = REGION_W, height: int = REGION_H) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    width = maxi(width, 32)
    height = maxi(height, 32)

    var spec := {
        "width": width,
        "height": height,
        "seed": seed_value,
        "generator_version": GENERATOR_VERSION,
        "display_name": "Procedural Region",
        "default_ground": "grass",
        "ground_rects": [],
        "indoor_rects": [],
        "walls": [],
        "wall_themes": {},
        "obstacles": [],
        "glass": [],
        "window_themes": {},
        "doors": [],
        "door_themes": {},
        "barrels": [],
        "props": [],
        "lights": [],
        "player_spawn": Vector2i(width / 2, height / 2),
        "exit_cells": [],
        "biome_cells": {},
        "road_cells": {},
        "road_class_cells": {},
        "road_surface_cells": {},
        "road_links": {},
        "road_ports": {},
        "building_rects": [],
        "rooms": [],
        "parking_lots": [],
        "parking_cells": {},
    }

    var centers: Dictionary = _biome_centers(rng, width, height)
    _assign_biomes(spec, centers, seed_value)
    _carve_roads(spec, centers, rng)
    _add_road_shoulders(spec)
    _finalize_road_art(spec)
    _decorate_biomes(spec, rng)
    _clear_spawn(spec)
    return spec

static func biome_at(spec: Dictionary, cell: Vector2i) -> String:
    return str(spec.get("biome_cells", {}).get(cell, "rural"))

static func validate(spec: Dictionary) -> Dictionary:
    var failures: Array[String] = []
    var width: int = int(spec.get("width", 0))
    var height: int = int(spec.get("height", 0))
    if width < 32 or height < 32:
        failures.append("region too small")

    var spawn: Vector2i = spec.get("player_spawn", Vector2i(-1, -1))
    if not _inside(spec, spawn):
        failures.append("spawn outside region")
    if not spec.get("road_cells", {}).has(spawn):
        failures.append("spawn not on connected road network")

    var exits: Array = spec.get("exit_cells", [])
    if exits.size() != 4:
        failures.append("expected four edge road exits")
    for exit_value in exits:
        var exit_cell: Vector2i = exit_value
        if not spec.get("road_cells", {}).has(exit_cell):
            failures.append("exit not on road: %s" % str(exit_cell))
        elif not _road_reachable(spec, spawn, exit_cell):
            failures.append("exit disconnected from spawn: %s" % str(exit_cell))

    var road_cells: Dictionary = spec.get("road_cells", {})
    var road_links: Dictionary = spec.get("road_links", {})
    var road_surfaces: Dictionary = spec.get("road_surface_cells", {})
    if road_links.size() != road_cells.size():
        failures.append("road link metadata incomplete")
    if road_surfaces.size() != road_cells.size():
        failures.append("road surface metadata incomplete")

    for road_value in road_cells.keys():
        var road_cell: Vector2i = road_value
        if spec.get("walls", []).has(road_cell) or spec.get("obstacles", []).has(road_cell) or spec.get("glass", []).has(road_cell):
            failures.append("road physically blocked: %s" % str(road_cell))
            break
        for door_value in spec.get("doors", []):
            var door_entry: Array = door_value
            if door_entry[0] == road_cell:
                failures.append("road occupied by door: %s" % str(road_cell))
                break

    var counts := {}
    for biome in BIOMES:
        counts[biome] = 0
    for biome_value in spec.get("biome_cells", {}).values():
        var biome := str(biome_value)
        counts[biome] = int(counts.get(biome, 0)) + 1
    for biome in BIOMES:
        if int(counts.get(biome, 0)) < 24:
            failures.append("biome too small: %s" % biome)

    var buildings: Array = spec.get("building_rects", [])
    if buildings.is_empty():
        failures.append("no generated buildings")
    for building_value in buildings:
        var building: Array = building_value
        if int(building[2]) < 8 or int(building[3]) < 8:
            failures.append("generated building footprint too small: %s" % str(building))
            break
    var rooms: Array = spec.get("rooms", [])
    if rooms.size() < buildings.size() * 2:
        failures.append("generated buildings missing room subdivisions")
    var parking_cells: Dictionary = spec.get("parking_cells", {})
    for parking_value in parking_cells.keys():
        var parking_cell: Vector2i = parking_value
        for d in DIRS:
            if parking_cells.has(parking_cell + d):
                failures.append("parking stalls touch without spacing: %s" % str(parking_cell))
                break
        if not failures.is_empty() and failures.back().begins_with("parking stalls touch"):
            break

    return {"ok": failures.is_empty(), "failures": failures, "biome_counts": counts}

static func _biome_centers(rng: RandomNumberGenerator, width: int, height: int) -> Dictionary:
    var mid := Vector2i(width / 2, height / 2)
    return {
        "downtown": mid + Vector2i(rng.randi_range(-4, 4), rng.randi_range(-4, 4)),
        "commercial": mid + Vector2i(rng.randi_range(-14, 14), rng.randi_range(-14, 14)),
        "residential": Vector2i(rng.randi_range(10, width - 11), rng.randi_range(10, height - 11)),
        "rural": Vector2i(rng.randi_range(5, width - 6), rng.randi_range(5, height - 6)),
        "woods": Vector2i(rng.randi_range(4, width - 5), rng.randi_range(4, height - 5)),
    }

static func _assign_biomes(spec: Dictionary, centers: Dictionary, seed_value: int) -> void:
    var width: int = int(spec["width"])
    var height: int = int(spec["height"])
    var biome_map: Dictionary = spec["biome_cells"]
    var mid := Vector2(width * 0.5, height * 0.5)
    var max_radius := Vector2(width, height).length() * 0.5
    for y in range(1, height - 1):
        for x in range(1, width - 1):
            var p := Vector2i(x, y)
            var best := "rural"
            var best_score := INF
            for biome in BIOMES:
                var c: Vector2i = centers[biome]
                var distance := Vector2(p - c).length()
                var score := distance
                if biome == "downtown":
                    score *= 0.83
                elif biome == "commercial":
                    score *= 0.93
                elif biome == "woods":
                    score *= 1.02
                var radial := Vector2(p).distance_to(mid) / max_radius
                if biome == "woods":
                    score -= radial * 8.0
                elif biome == "rural":
                    score -= radial * 5.0
                elif biome == "downtown":
                    score += radial * 11.0
                score += _cell_noise(seed_value, p) * 3.5
                if score < best_score:
                    best_score = score
                    best = biome
            biome_map[p] = best

static func _carve_roads(spec: Dictionary, centers: Dictionary, rng: RandomNumberGenerator) -> void:
    var width: int = int(spec["width"])
    var height: int = int(spec["height"])
    var downtown: Vector2i = centers["downtown"]
    var arterial_x: int = clampi(downtown.x - 1, 4, width - 7)
    var arterial_y: int = clampi(downtown.y - 1, 4, height - 7)

    for biome in BIOMES:
        var center: Vector2i = centers[biome]
        if biome == "downtown":
            continue
        var dx: int = absi(center.x - (arterial_x + 1))
        var dy: int = absi(center.y - (arterial_y + 1))
        var ground_kind := "dirt" if biome in ["woods", "rural"] else "road"
        var road_class := "trail" if biome == "woods" else "secondary"
        var thickness: int = 1 if biome in ["woods", "rural", "residential"] else 2
        if dx <= dy:
            _road_h(spec, center.y, mini(center.x, arterial_x + 1), maxi(center.x, arterial_x + 1), thickness, ground_kind, road_class)
            _local_cross_street(spec, center, biome, true)
        else:
            _road_v(spec, center.x, mini(center.y, arterial_y + 1), maxi(center.y, arterial_y + 1), thickness, ground_kind, road_class)
            _local_cross_street(spec, center, biome, false)

    _road_h(spec, clampi(downtown.y + 5, 2, height - 3), maxi(2, downtown.x - 10), mini(width - 3, downtown.x + 10), 2, "road", "local")
    _road_v(spec, clampi(downtown.x + 6, 2, width - 3), maxi(2, downtown.y - 10), mini(height - 3, downtown.y + 10), 2, "road", "local")

    _road_h(spec, arterial_y, 1, width - 2, 3, "road", "arterial")
    _road_v(spec, arterial_x, 1, height - 2, 3, "road", "arterial")

    var center_x := arterial_x + 1
    var center_y := arterial_y + 1
    var north := Vector2i(center_x, 1)
    var south := Vector2i(center_x, height - 2)
    var west := Vector2i(1, center_y)
    var east := Vector2i(width - 2, center_y)
    spec["road_ports"] = {"north": north, "south": south, "west": west, "east": east}
    spec["exit_cells"] = [north, south, west, east]
    spec["player_spawn"] = Vector2i(center_x, center_y)

    if rng.randf() < 0.8:
        _safe_prop(spec, Vector2i(center_x + 3, center_y - 2), "stop_sign", false)

static func _local_cross_street(spec: Dictionary, center: Vector2i, biome: String, connector_was_horizontal: bool) -> void:
    var extent: int
    var thickness: int
    var ground_kind: String
    match biome:
        "commercial":
            extent = 8; thickness = 2; ground_kind = "road"
        "residential":
            extent = 7; thickness = 1; ground_kind = "road"
        "rural":
            extent = 6; thickness = 1; ground_kind = "dirt"
        "woods":
            extent = 5; thickness = 1; ground_kind = "dirt"
        _:
            extent = 6; thickness = 1; ground_kind = "road"
    var road_class := "trail" if biome == "woods" else "local"
    if connector_was_horizontal:
        _road_v(spec, center.x, maxi(2, center.y - extent), mini(int(spec["height"]) - 3, center.y + extent), thickness, ground_kind, road_class)
    else:
        _road_h(spec, center.y, maxi(2, center.x - extent), mini(int(spec["width"]) - 3, center.x + extent), thickness, ground_kind, road_class)

static func _road_h(spec: Dictionary, y: int, x0: int, x1: int, thickness: int, ground_kind: String, road_class: String) -> void:
    if x1 < x0:
        return
    for yy in range(y, mini(y + thickness, int(spec["height"]) - 1)):
        _ground(spec, x0, yy, x1 - x0 + 1, 1, ground_kind)
        for x in range(x0, x1 + 1):
            var links := 0
            if x > x0: links = links | ROAD_W
            if x < x1: links = links | ROAD_E
            _mark_road(spec, Vector2i(x, yy), road_class, ground_kind, links)

static func _road_v(spec: Dictionary, x: int, y0: int, y1: int, thickness: int, ground_kind: String, road_class: String) -> void:
    if y1 < y0:
        return
    for xx in range(x, mini(x + thickness, int(spec["width"]) - 1)):
        _ground(spec, xx, y0, 1, y1 - y0 + 1, ground_kind)
        for y in range(y0, y1 + 1):
            var links := 0
            if y > y0: links = links | ROAD_N
            if y < y1: links = links | ROAD_S
            _mark_road(spec, Vector2i(xx, y), road_class, ground_kind, links)

static func _mark_road(spec: Dictionary, p: Vector2i, road_class: String, ground_kind: String, links: int) -> void:
    if not _inside(spec, p):
        return
    spec["road_cells"][p] = true
    var old_class := str(spec["road_class_cells"].get(p, ""))
    var old_rank := int(ROAD_RANK.get(old_class, -1))
    var new_rank := int(ROAD_RANK.get(road_class, 0))
    if old_class == "" or new_rank >= old_rank:
        spec["road_class_cells"][p] = road_class
        spec["road_surface_cells"][p] = ground_kind
    var old_links := int(spec["road_links"].get(p, 0))
    spec["road_links"][p] = old_links | links

static func _add_road_shoulders(spec: Dictionary) -> void:
    var road_cells: Dictionary = spec.get("road_cells", {})
    var sidewalk_sides: Dictionary = {}
    var rural_shoulders: Dictionary = {}
    for road_value in road_cells.keys():
        var road: Vector2i = road_value
        for d in DIRS:
            var p := road + d
            if not _inside(spec, p) or road_cells.has(p):
                continue
            var biome := biome_at(spec, p)
            if biome in DEVELOPED_BIOMES:
                var side_bit := 0
                if d == Vector2i.DOWN: side_bit = ROAD_N
                elif d == Vector2i.LEFT: side_bit = ROAD_E
                elif d == Vector2i.UP: side_bit = ROAD_S
                elif d == Vector2i.RIGHT: side_bit = ROAD_W
                sidewalk_sides[p] = int(sidewalk_sides.get(p, 0)) | side_bit
            elif biome == "rural":
                rural_shoulders[p] = true
    for p_value in sidewalk_sides.keys():
        var p: Vector2i = p_value
        var sides := int(sidewalk_sides[p])
        var kind := "sidewalk"
        if sides == ROAD_N: kind = "sidewalk_curb_n"
        elif sides == ROAD_E: kind = "sidewalk_curb_e"
        elif sides == ROAD_S: kind = "sidewalk_curb_s"
        elif sides == ROAD_W: kind = "sidewalk_curb_w"
        _ground(spec, p.x, p.y, 1, 1, kind)
    for p_value in rural_shoulders.keys():
        var p: Vector2i = p_value
        _ground(spec, p.x, p.y, 1, 1, "dirt")

static func _finalize_road_art(spec: Dictionary) -> void:
    for road_value in spec.get("road_cells", {}).keys():
        var p: Vector2i = road_value
        var surface := str(spec.get("road_surface_cells", {}).get(p, "road"))
        var kind := _road_art_kind(spec, p, surface)
        _ground(spec, p.x, p.y, 1, 1, kind)

static func _road_art_kind(spec: Dictionary, p: Vector2i, surface: String) -> String:
    var mask := int(spec.get("road_links", {}).get(p, 0))
    if surface == "dirt":
        var horizontal := (mask & (ROAD_E | ROAD_W)) != 0
        var vertical := (mask & (ROAD_N | ROAD_S)) != 0
        if horizontal and not vertical: return "dirt_road_h"
        if vertical and not horizontal: return "dirt_road_v"
        return "gravel"

    var road_class := str(spec.get("road_class_cells", {}).get(p, "local"))
    if road_class == "arterial":
        if mask == (ROAD_E | ROAD_W):
            var north_links := int(spec.get("road_links", {}).get(p + Vector2i.UP, 0))
            var south_links := int(spec.get("road_links", {}).get(p + Vector2i.DOWN, 0))
            if (north_links & (ROAD_E | ROAD_W)) != (ROAD_E | ROAD_W) or (south_links & (ROAD_E | ROAD_W)) != (ROAD_E | ROAD_W):
                return "road_plain"
        elif mask == (ROAD_N | ROAD_S):
            var east_links := int(spec.get("road_links", {}).get(p + Vector2i.RIGHT, 0))
            var west_links := int(spec.get("road_links", {}).get(p + Vector2i.LEFT, 0))
            if (east_links & (ROAD_N | ROAD_S)) != (ROAD_N | ROAD_S) or (west_links & (ROAD_N | ROAD_S)) != (ROAD_N | ROAD_S):
                return "road_plain"
        elif (mask & (ROAD_N | ROAD_S)) != 0 and (mask & (ROAD_E | ROAD_W)) != 0:
            return "road_plain"

    if mask == (ROAD_N | ROAD_S): return "road_v"
    if mask == (ROAD_E | ROAD_W): return "road_h"
    if mask == (ROAD_N | ROAD_E): return "road_ne"
    if mask == (ROAD_E | ROAD_S): return "road_es"
    if mask == (ROAD_S | ROAD_W): return "road_sw"
    if mask == (ROAD_W | ROAD_N): return "road_wn"
    if mask == (ROAD_N | ROAD_E | ROAD_S): return "road_t_nes"
    if mask == (ROAD_E | ROAD_S | ROAD_W): return "road_t_esw"
    if mask == (ROAD_S | ROAD_W | ROAD_N): return "road_t_swn"
    if mask == (ROAD_W | ROAD_N | ROAD_E): return "road_t_wne"
    if mask == (ROAD_N | ROAD_E | ROAD_S | ROAD_W): return "road_cross"
    if mask == ROAD_N: return "road_end_n"
    if mask == ROAD_E: return "road_end_e"
    if mask == ROAD_S: return "road_end_s"
    if mask == ROAD_W: return "road_end_w"
    return "road_plain"

static func _decorate_biomes(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    var width: int = int(spec["width"])
    var height: int = int(spec["height"])
    for y in range(2, height - PARCEL_H, PARCEL_H):
        for x in range(2, width - PARCEL_W, PARCEL_W):
            var anchor := Vector2i(x, y)
            var parcel := Rect2i(anchor, Vector2i(PARCEL_W, PARCEL_H))
            if _parcel_hits_road(spec, parcel):
                continue
            var biome := biome_at(spec, anchor + Vector2i(PARCEL_W / 2, PARCEL_H / 2))
            var road_distance := _parcel_road_distance(spec, parcel)
            match biome:
                "residential":
                    if road_distance <= 3 and rng.randf() < 0.86:
                        _place_house(spec, anchor, rng)
                    else:
                        _place_residential_yard(spec, anchor, rng)
                "commercial":
                    if road_distance <= 3 and rng.randf() < 0.80:
                        _place_shop(spec, anchor, rng)
                    elif road_distance <= 4:
                        _place_commercial_lot(spec, anchor, rng)
                "downtown":
                    if road_distance <= 3 and rng.randf() < 0.94:
                        _place_downtown(spec, anchor, rng)
                "woods":
                    _place_woods(spec, anchor, rng)
                "rural":
                    _place_rural(spec, anchor, rng, road_distance)

static func _place_house(spec: Dictionary, a: Vector2i, rng: RandomNumberGenerator) -> void:
    _ground(spec, a.x, a.y, PARCEL_W, PARCEL_H, "grass")
    var rect := Rect2i(a.x, a.y + 1, 9, 8)
    _building(spec, rect, "hardwood_h" if rng.randf() < 0.5 else "hardwood_v", "house", rng)
    _safe_prop(spec, Vector2i(a.x + 1, a.y + 6), "mailbox", false)
    if rng.randf() < 0.65:
        _safe_prop(spec, Vector2i(a.x + 5, a.y + 6), "trash_can", false)
    if rng.randf() < 0.55:
        _safe_prop(spec, Vector2i(a.x + 6, a.y + 1), "hedge", false)
    if rng.randf() < 0.35:
        _safe_prop(spec, Vector2i(a.x + 6, a.y + 4), "flower_bed", false)

static func _place_residential_yard(spec: Dictionary, a: Vector2i, rng: RandomNumberGenerator) -> void:
    _ground(spec, a.x, a.y, PARCEL_W, PARCEL_H, "grass")
    if rng.randf() < 0.55:
        _safe_prop(spec, Vector2i(a.x + 2, a.y + 3), "tree", true)
    if rng.randf() < 0.7:
        _safe_prop(spec, Vector2i(a.x + 5, a.y + 4), "hedge", false)
    if rng.randf() < 0.35:
        _safe_prop(spec, Vector2i(a.x + 4, a.y + 2), "flower_bed", false)

static func _place_shop(spec: Dictionary, a: Vector2i, rng: RandomNumberGenerator) -> void:
    var parcel := Rect2i(a, Vector2i(PARCEL_W, PARCEL_H))
    _parking_lot(spec, parcel, true)
    _building(spec, Rect2i(a.x, a.y + 1, 9, 8), "shop_floor", "store", rng)
    if rng.randf() < 0.7:
        _safe_prop(spec, Vector2i(a.x + 8, a.y + 9), "shopping_cart", false)
    if rng.randf() < 0.55:
        _safe_prop(spec, Vector2i(a.x + 9, a.y + 9), "bollard", true)

static func _place_commercial_lot(spec: Dictionary, a: Vector2i, rng: RandomNumberGenerator) -> void:
    var parcel := Rect2i(a, Vector2i(PARCEL_W, PARCEL_H))
    _parking_lot(spec, parcel, false)
    if rng.randf() < 0.65:
        _safe_prop(spec, Vector2i(a.x + 8, a.y + 5), "bench", true)
    if rng.randf() < 0.45:
        _safe_prop(spec, Vector2i(a.x + 8, a.y + 8), "planter", true)
    if rng.randf() < 0.35:
        _safe_prop(spec, Vector2i(a.x + 9, a.y + 1), "parking_meter", false)

static func _parking_lot(spec: Dictionary, rect: Rect2i, storefront_row_only: bool) -> void:
    _ground(spec, rect.position.x, rect.position.y, rect.size.x, rect.size.y, "asphalt_patch")
    spec["parking_lots"].append([rect.position.x, rect.position.y, rect.size.x, rect.size.y])
    var rows: Array[int] = [rect.end.y - 1] if storefront_row_only else [rect.position.y + 2, rect.position.y + 7]
    for y in rows:
        for x in range(rect.position.x + 1, rect.end.x - 1, 2):
            _parking_stall(spec, Vector2i(x, y))

static func _parking_stall(spec: Dictionary, p: Vector2i) -> void:
    if not _inside(spec, p) or spec.get("road_cells", {}).has(p):
        return
    var parking_cells: Dictionary = spec["parking_cells"]
    for d in DIRS:
        if parking_cells.has(p + d):
            return
    parking_cells[p] = true
    _ground(spec, p.x, p.y, 1, 1, "parking")

static func _place_downtown(spec: Dictionary, a: Vector2i, rng: RandomNumberGenerator) -> void:
    _ground(spec, a.x, a.y, PARCEL_W, PARCEL_H, "sidewalk")
    var building_theme := "office" if rng.randf() < 0.62 else "industrial"
    var floor_kind := "office_carpet" if building_theme == "office" else "warehouse_floor"
    _building(spec, Rect2i(a.x, a.y, 10, 10), floor_kind, building_theme, rng)
    if rng.randf() < 0.45:
        _safe_prop(spec, Vector2i(a.x + 1, a.y + 6), "hydrant", false)
    if rng.randf() < 0.55:
        var lamp_cell := Vector2i(a.x + 5, a.y + 6)
        _safe_prop(spec, lamp_cell, "streetlight", true)
        if not spec.get("road_cells", {}).has(lamp_cell):
            spec["lights"].append([lamp_cell, "security", true])

static func _place_woods(spec: Dictionary, a: Vector2i, rng: RandomNumberGenerator) -> void:
    _ground(spec, a.x, a.y, PARCEL_W, PARCEL_H, "grass")
    for yy in range(a.y, a.y + PARCEL_H):
        for xx in range(a.x, a.x + PARCEL_W):
            var p := Vector2i(xx, yy)
            if rng.randf() < 0.105:
                _safe_prop(spec, p, "tree", true)
            elif rng.randf() < 0.12:
                _safe_prop(spec, p, "bush", false)
    if rng.randf() < 0.55:
        _ground(spec, a.x, a.y + PARCEL_H / 2, PARCEL_W, 1, "dirt")
    if rng.randf() < 0.22:
        _safe_prop(spec, Vector2i(a.x + 5, a.y + 5), "firewood", false)

static func _place_rural(spec: Dictionary, a: Vector2i, rng: RandomNumberGenerator, road_distance: int) -> void:
    var ground_kind := "field_rows" if rng.randf() < 0.36 else ("dirt" if rng.randf() < 0.48 else "grass")
    _ground(spec, a.x, a.y, PARCEL_W, PARCEL_H, ground_kind)
    if road_distance <= 4 and rng.randf() < 0.38:
        _building(spec, Rect2i(a.x, a.y + 1, 9, 8), "hardwood_v", "rural_wood", rng)
        _safe_prop(spec, Vector2i(a.x + 1, a.y + 6), "mailbox", false)
        if rng.randf() < 0.4:
            _safe_prop(spec, Vector2i(a.x + 6, a.y + 5), "propane_tank", false)
    else:
        if rng.randf() < 0.58:
            for i in range(3):
                _safe_prop(spec, Vector2i(a.x + 1 + i * 2, a.y + 5), "fence", true)
        if rng.randf() < 0.5:
            _safe_prop(spec, Vector2i(a.x + 5, a.y + 2), "tree", true)
        if rng.randf() < 0.34:
            _safe_prop(spec, Vector2i(a.x + 2, a.y + 2), "shed", true)
        elif rng.randf() < 0.4:
            _safe_prop(spec, Vector2i(a.x + 2, a.y + 2), "firewood", false)

static func _building(spec: Dictionary, rect: Rect2i, floor_kind: String, theme: String, rng: RandomNumberGenerator) -> void:
    _ground(spec, rect.position.x, rect.position.y, rect.size.x, rect.size.y, floor_kind)
    spec["indoor_rects"].append([rect.position.x, rect.position.y, rect.size.x, rect.size.y])
    spec["building_rects"].append([rect.position.x, rect.position.y, rect.size.x, rect.size.y, theme])
    for x in range(rect.position.x, rect.end.x):
        _wall(spec, Vector2i(x, rect.position.y), theme)
        _wall(spec, Vector2i(x, rect.end.y - 1), theme)
    for y in range(rect.position.y, rect.end.y):
        _wall(spec, Vector2i(rect.position.x, y), theme)
        _wall(spec, Vector2i(rect.end.x - 1, y), theme)

    var front_side := _nearest_road_side(spec, rect)
    var door := _wall_midpoint(rect, front_side)
    _cut_wall(spec, door)
    spec["doors"].append([door, false])
    spec["door_themes"][door] = _opening_theme(theme)

    var front_window := _wall_offset(rect, front_side, 1)
    if front_window != door:
        _add_window(spec, front_window, _opening_theme(theme))
    var side_name := "west" if front_side in ["north", "south"] else "north"
    var side_window := _wall_offset(rect, side_name, 1)
    if side_window != door:
        _add_window(spec, side_window, _opening_theme(theme))

    var light := Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2)
    var light_kind := "warm" if theme in ["house", "rural_wood"] else ("fluorescent" if theme in ["store", "office"] else "security")
    if rng.randf() < 0.82:
        spec["lights"].append([light, light_kind, true])

    _add_room_layout(spec, rect, theme)
    _ensure_entry_path(spec, rect, door, theme)
    _decorate_interior(spec, rect, theme, door, rng)
    if rng.randf() < 0.42:
        _safe_prop(spec, Vector2i(rect.end.x, rect.position.y + rect.size.y / 2), "exterior_ac", false, door)

static func _opening_theme(theme: String) -> String:
    if theme == "store": return "storefront"
    if theme == "industrial": return "warehouse"
    return theme

static func _decorate_interior(spec: Dictionary, rect: Rect2i, theme: String, door: Vector2i, rng: RandomNumberGenerator) -> void:
    var center := Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2)
    match theme:
        "house", "rural_wood":
            _safe_prop(spec, center, "rug", false)
            _safe_prop(spec, Vector2i(rect.position.x + 1, rect.position.y + 1), "stove", true, door)
            if rng.randf() < 0.72:
                _safe_prop(spec, Vector2i(rect.end.x - 2, rect.position.y + 1), "dresser", true, door)
            elif rng.randf() < 0.6:
                _safe_prop(spec, Vector2i(rect.end.x - 2, rect.position.y + 1), "armchair", true, door)
        "store":
            _safe_prop(spec, Vector2i(rect.position.x + 1, rect.position.y + 1), "checkout", true, door)
            if rect.size.x >= 6:
                _safe_prop(spec, Vector2i(rect.end.x - 2, rect.position.y + 1), "freezer", true, door)
            if rng.randf() < 0.55:
                _safe_prop(spec, Vector2i(rect.end.x - 2, rect.end.y - 2), "cardboard", false)
        "office":
            _safe_prop(spec, Vector2i(rect.position.x + 1, rect.position.y + 1), "desk", true, door)
            _safe_prop(spec, Vector2i(rect.position.x + 2, rect.position.y + 1), "computer", false, door)
            if rng.randf() < 0.7:
                _safe_prop(spec, Vector2i(rect.end.x - 2, rect.position.y + 1), "filing_cabinet", true, door)
            if rng.randf() < 0.45:
                _safe_prop(spec, Vector2i(rect.end.x - 2, rect.end.y - 2), "planter", true, door)
        _:
            _safe_prop(spec, Vector2i(rect.position.x + 1, rect.position.y + 1), "workbench", true, door)
            if rng.randf() < 0.65:
                _safe_prop(spec, Vector2i(rect.end.x - 2, rect.position.y + 1), "locker", true, door)
            if rng.randf() < 0.45:
                _safe_prop(spec, Vector2i(rect.end.x - 2, rect.end.y - 2), "tool_chest", true, door)

static func _add_room_layout(spec: Dictionary, rect: Rect2i, theme: String) -> void:
    match theme:
        "house", "rural_wood":
            var split_x := rect.position.x + 4
            _interior_wall_v(spec, split_x, rect.position.y + 1, rect.end.y - 2, theme, rect.position.y + 3)
            _interior_wall_h(spec, rect.position.y + 4, split_x + 1, rect.end.x - 2, theme, split_x + 2)
            _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, 3, rect.size.y - 2), "living_kitchen", "laminate_light")
            _room(spec, Rect2i(split_x + 1, rect.position.y + 1, rect.end.x - split_x - 2, 3), "bedroom", "carpet_beige")
            _room(spec, Rect2i(split_x + 1, rect.position.y + 5, rect.end.x - split_x - 2, rect.end.y - rect.position.y - 6), "bathroom", "tile_white")
        "store":
            var split_y := rect.position.y + 4
            _interior_wall_h(spec, split_y, rect.position.x + 1, rect.end.x - 2, theme, rect.position.x + 4)
            _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, 3), "sales_floor", "shop_floor")
            _room(spec, Rect2i(rect.position.x + 1, split_y + 1, rect.size.x - 2, rect.end.y - split_y - 2), "stockroom", "warehouse_floor")
        "office":
            var split_x := rect.position.x + 4
            var split_y := rect.position.y + 5
            _interior_wall_v(spec, split_x, rect.position.y + 1, rect.end.y - 2, theme, rect.position.y + 3)
            _interior_wall_h(spec, split_y, rect.position.x + 1, split_x - 1, theme, rect.position.x + 2)
            _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, split_x - rect.position.x - 1, split_y - rect.position.y - 1), "office_front", "office_carpet")
            _room(spec, Rect2i(rect.position.x + 1, split_y + 1, split_x - rect.position.x - 1, rect.end.y - split_y - 2), "office_back", "office_carpet")
            _room(spec, Rect2i(split_x + 1, rect.position.y + 1, rect.end.x - split_x - 2, rect.size.y - 2), "office_side", "carpet_blue")
        _:
            var split_x := rect.position.x + 3
            _interior_wall_v(spec, split_x, rect.position.y + 1, rect.end.y - 2, theme, rect.position.y + 4)
            _room(spec, Rect2i(rect.position.x + 1, rect.position.y + 1, split_x - rect.position.x - 1, rect.size.y - 2), "utility_room", "concrete_clean")
            _room(spec, Rect2i(split_x + 1, rect.position.y + 1, rect.end.x - split_x - 2, rect.size.y - 2), "warehouse", "warehouse_floor")

static func _room(spec: Dictionary, rect: Rect2i, room_kind: String, floor_kind: String) -> void:
    if rect.size.x <= 0 or rect.size.y <= 0:
        return
    spec["rooms"].append([rect.position.x, rect.position.y, rect.size.x, rect.size.y, room_kind])
    _ground(spec, rect.position.x, rect.position.y, rect.size.x, rect.size.y, floor_kind)

static func _interior_wall_v(spec: Dictionary, x: int, y0: int, y1: int, theme: String, door_y: int) -> void:
    for y in range(y0, y1 + 1):
        _wall(spec, Vector2i(x, y), "interior")
    _add_interior_door(spec, Vector2i(x, door_y), theme)

static func _interior_wall_h(spec: Dictionary, y: int, x0: int, x1: int, theme: String, door_x: int) -> void:
    for x in range(x0, x1 + 1):
        _wall(spec, Vector2i(x, y), "interior")
    _add_interior_door(spec, Vector2i(door_x, y), theme)

static func _add_interior_door(spec: Dictionary, p: Vector2i, theme: String) -> void:
    _cut_wall(spec, p)
    for door_value in spec["doors"]:
        var entry: Array = door_value
        if entry[0] == p:
            return
    spec["doors"].append([p, false])
    spec["door_themes"][p] = _opening_theme(theme)

static func _ensure_entry_path(spec: Dictionary, rect: Rect2i, exterior_door: Vector2i, theme: String) -> void:
    var inward := exterior_door
    if exterior_door.y == rect.position.y:
        inward += Vector2i.DOWN
    elif exterior_door.y == rect.end.y - 1:
        inward += Vector2i.UP
    elif exterior_door.x == rect.position.x:
        inward += Vector2i.RIGHT
    elif exterior_door.x == rect.end.x - 1:
        inward += Vector2i.LEFT
    if spec["walls"].has(inward):
        _add_interior_door(spec, inward, theme)

static func _nearest_road_side(spec: Dictionary, rect: Rect2i) -> String:
    var best_side := "south"
    var best_distance := 999
    for side in ["north", "south", "west", "east"]:
        var distance := _side_road_distance(spec, rect, side, 6)
        if distance < best_distance:
            best_distance = distance
            best_side = side
    return best_side

static func _side_road_distance(spec: Dictionary, rect: Rect2i, side: String, max_search: int) -> int:
    for distance in range(1, max_search + 1):
        if side in ["north", "south"]:
            var y := rect.position.y - distance if side == "north" else rect.end.y - 1 + distance
            for x in range(rect.position.x, rect.end.x):
                if spec.get("road_cells", {}).has(Vector2i(x, y)):
                    return distance
        else:
            var x := rect.position.x - distance if side == "west" else rect.end.x - 1 + distance
            for y in range(rect.position.y, rect.end.y):
                if spec.get("road_cells", {}).has(Vector2i(x, y)):
                    return distance
    return 999

static func _wall_midpoint(rect: Rect2i, side: String) -> Vector2i:
    if side == "north":
        return Vector2i(rect.position.x + rect.size.x / 2, rect.position.y)
    if side == "south":
        return Vector2i(rect.position.x + rect.size.x / 2, rect.end.y - 1)
    if side == "west":
        return Vector2i(rect.position.x, rect.position.y + rect.size.y / 2)
    return Vector2i(rect.end.x - 1, rect.position.y + rect.size.y / 2)

static func _wall_offset(rect: Rect2i, side: String, offset: int) -> Vector2i:
    if side == "north":
        return Vector2i(clampi(rect.position.x + offset, rect.position.x + 1, rect.end.x - 2), rect.position.y)
    if side == "south":
        return Vector2i(clampi(rect.position.x + offset, rect.position.x + 1, rect.end.x - 2), rect.end.y - 1)
    if side == "west":
        return Vector2i(rect.position.x, clampi(rect.position.y + offset, rect.position.y + 1, rect.end.y - 2))
    return Vector2i(rect.end.x - 1, clampi(rect.position.y + offset, rect.position.y + 1, rect.end.y - 2))

static func _add_window(spec: Dictionary, p: Vector2i, theme: String = "") -> void:
    _cut_wall(spec, p)
    if not spec["glass"].has(p):
        spec["glass"].append(p)
    if theme != "":
        spec["window_themes"][p] = theme

static func _parcel_hits_road(spec: Dictionary, rect: Rect2i) -> bool:
    for y in range(rect.position.y, rect.end.y):
        for x in range(rect.position.x, rect.end.x):
            if spec.get("road_cells", {}).has(Vector2i(x, y)):
                return true
    return false

static func _parcel_road_distance(spec: Dictionary, rect: Rect2i) -> int:
    var best := 999
    for road_value in spec.get("road_cells", {}).keys():
        var p: Vector2i = road_value
        var dx: int = maxi(rect.position.x - p.x, maxi(0, p.x - (rect.end.x - 1)))
        var dy: int = maxi(rect.position.y - p.y, maxi(0, p.y - (rect.end.y - 1)))
        best = mini(best, dx + dy)
        if best <= 1:
            return best
    return best

static func _road_reachable(spec: Dictionary, start: Vector2i, goal: Vector2i) -> bool:
    if start == goal:
        return true
    var roads: Dictionary = spec.get("road_cells", {})
    if not roads.has(start) or not roads.has(goal):
        return false
    var seen: Dictionary = {start: true}
    var queue: Array[Vector2i] = [start]
    while not queue.is_empty():
        var p: Vector2i = queue.pop_front()
        for d in DIRS:
            var n := p + d
            if not roads.has(n) or seen.has(n):
                continue
            if n == goal:
                return true
            seen[n] = true
            queue.append(n)
    return false

static func _clear_spawn(spec: Dictionary) -> void:
    var spawn: Vector2i = spec["player_spawn"]
    _clear_cell(spec, spawn)

static func _clear_cell(spec: Dictionary, p: Vector2i) -> void:
    while spec["walls"].has(p):
        spec["walls"].erase(p)
    spec.get("wall_themes", {}).erase(p)
    while spec["obstacles"].has(p):
        spec["obstacles"].erase(p)
    while spec["glass"].has(p):
        spec["glass"].erase(p)
    spec.get("window_themes", {}).erase(p)
    for i in range(spec["doors"].size() - 1, -1, -1):
        if spec["doors"][i][0] == p:
            spec["doors"].remove_at(i)
    spec.get("door_themes", {}).erase(p)
    for i in range(spec["props"].size() - 1, -1, -1):
        if spec["props"][i][0] == p:
            spec["props"].remove_at(i)
    for i in range(spec["lights"].size() - 1, -1, -1):
        if spec["lights"][i][0] == p:
            spec["lights"].remove_at(i)

static func _ground(spec: Dictionary, x: int, y: int, w: int, h: int, kind: String) -> void:
    spec["ground_rects"].append([x, y, w, h, kind])

static func _wall(spec: Dictionary, p: Vector2i, theme: String = "alley") -> void:
    if _inside(spec, p) and not spec["walls"].has(p):
        spec["walls"].append(p)
        spec["wall_themes"][p] = theme

static func _cut_wall(spec: Dictionary, p: Vector2i) -> void:
    while spec["walls"].has(p):
        spec["walls"].erase(p)
    spec.get("wall_themes", {}).erase(p)

static func _obstacle(spec: Dictionary, p: Vector2i, kind: String) -> void:
    if not _inside(spec, p) or spec.get("road_cells", {}).has(p):
        return
    if spec["walls"].has(p) or spec["glass"].has(p):
        return
    if not spec["obstacles"].has(p):
        spec["obstacles"].append(p)
    _prop(spec, p, kind)

static func _prop(spec: Dictionary, p: Vector2i, kind: String) -> void:
    if not _inside(spec, p):
        return
    for entry_value in spec["props"]:
        var entry: Array = entry_value
        if entry[0] == p:
            return
    spec["props"].append([p, kind])

static func _safe_prop(spec: Dictionary, p: Vector2i, kind: String, blocking: bool, keep_clear: Vector2i = Vector2i(-999, -999)) -> void:
    if p == keep_clear or not _inside(spec, p) or spec.get("road_cells", {}).has(p):
        return
    if spec["walls"].has(p) or spec["glass"].has(p):
        return
    for door_value in spec["doors"]:
        var entry: Array = door_value
        if entry[0] == p:
            return
    if blocking:
        _obstacle(spec, p, kind)
    else:
        _prop(spec, p, kind)

static func _inside(spec: Dictionary, p: Vector2i) -> bool:
    return p.x >= 1 and p.y >= 1 and p.x < int(spec["width"]) - 1 and p.y < int(spec["height"]) - 1

static func _cell_noise(seed_value: int, p: Vector2i) -> float:
    var n: int = p.x * 374761393 + p.y * 668265263 + seed_value * 1442695041
    n = (n ^ (n >> 13)) * 1274126177
    n = n ^ (n >> 16)
    return float(posmod(n, 10000)) / 10000.0 - 0.5
