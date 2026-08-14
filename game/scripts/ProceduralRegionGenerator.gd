extends RefCounted
class_name ProceduralRegionGenerator

const REGION_W := 64
const REGION_H := 64

const BIOMES := ["residential", "commercial", "downtown", "woods", "rural"]
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

static func generate(seed_value: int, width: int = REGION_W, height: int = REGION_H) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    width = maxi(width, 32)
    height = maxi(height, 32)

    var spec := {
        "width": width,
        "height": height,
        "seed": seed_value,
        "display_name": "Procedural Region",
        "default_ground": "grass",
        "ground_rects": [],
        "indoor_rects": [],
        "walls": [],
        "obstacles": [],
        "glass": [],
        "doors": [],
        "barrels": [],
        "props": [],
        "lights": [],
        "player_spawn": Vector2i(width / 2, height / 2),
        "exit_cells": [],
        "biome_cells": {},
        "road_cells": {},
    }

    var centers := _biome_centers(rng, width, height)
    _assign_biomes(spec, centers, seed_value)
    _carve_roads(spec, centers, rng)
    _decorate_biomes(spec, rng)
    _place_edge_exits(spec)
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
    if spec.get("exit_cells", []).size() < 4:
        failures.append("missing edge exits")
    var counts := {}
    for biome in BIOMES:
        counts[biome] = 0
    for biome_value in spec.get("biome_cells", {}).values():
        var biome := str(biome_value)
        counts[biome] = int(counts.get(biome, 0)) + 1
    for biome in BIOMES:
        if int(counts.get(biome, 0)) < 24:
            failures.append("biome too small: %s" % biome)
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
    var map: Dictionary = spec["biome_cells"]
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
            map[p] = best

static func _carve_roads(spec: Dictionary, centers: Dictionary, rng: RandomNumberGenerator) -> void:
    var width: int = int(spec["width"])
    var height: int = int(spec["height"])
    var downtown: Vector2i = centers["downtown"]
    var road_cells: Dictionary = spec["road_cells"]

    _road_h(spec, clampi(downtown.y, 4, height - 5), 1, width - 2, 3)
    _road_v(spec, clampi(downtown.x, 4, width - 5), 1, height - 2, 3)

    for x in range(10, width - 8, 12):
        if rng.randf() < 0.82:
            _road_v(spec, x, 2, height - 3, 2)
    for y in range(10, height - 8, 12):
        if rng.randf() < 0.82:
            _road_h(spec, y, 2, width - 3, 2)

    for p in road_cells.keys():
        spec["biome_cells"][p] = _road_context_biome(spec, p)

static func _road_context_biome(spec: Dictionary, p: Vector2i) -> String:
    for d in DIRS:
        var n := p + d * 2
        var biome := str(spec.get("biome_cells", {}).get(n, ""))
        if biome != "":
            return biome
    return "commercial"

static func _road_h(spec: Dictionary, y: int, x0: int, x1: int, thickness: int) -> void:
    for yy in range(y, mini(y + thickness, int(spec["height"]) - 1)):
        _ground(spec, x0, yy, x1 - x0 + 1, 1, "road")
        for x in range(x0, x1 + 1):
            spec["road_cells"][Vector2i(x, yy)] = true

static func _road_v(spec: Dictionary, x: int, y0: int, y1: int, thickness: int) -> void:
    for xx in range(x, mini(x + thickness, int(spec["width"]) - 1)):
        _ground(spec, xx, y0, 1, y1 - y0 + 1, "road")
        for y in range(y0, y1 + 1):
            spec["road_cells"][Vector2i(xx, y)] = true

static func _decorate_biomes(spec: Dictionary, rng: RandomNumberGenerator) -> void:
    var width: int = int(spec["width"])
    var height: int = int(spec["height"])
    for y in range(4, height - 8, 8):
        for x in range(4, width - 8, 8):
            var anchor := Vector2i(x, y)
            if _parcel_hits_road(spec, Rect2i(anchor, Vector2i(7, 7))):
                continue
            var biome := biome_at(spec, anchor + Vector2i(3, 3))
            match biome:
                "residential":
                    if rng.randf() < 0.78: _place_house(spec, anchor, rng)
                "commercial":
                    if rng.randf() < 0.72: _place_shop(spec, anchor, rng)
                "downtown":
                    if rng.randf() < 0.88: _place_downtown(spec, anchor, rng)
                "woods":
                    _place_woods(spec, anchor, rng)
                "rural":
                    _place_rural(spec, anchor, rng)

static func _place_house(spec: Dictionary, a: Vector2i, rng: RandomNumberGenerator) -> void:
    _ground(spec, a.x, a.y, 7, 7, "grass")
    var x := a.x + 1
    var y := a.y + 1
    var w := 5
    var h := 4
    _building(spec, Rect2i(x, y, w, h), "wood", "house", rng)
    if rng.randf() < 0.45:
        _prop(spec, Vector2i(a.x + 6, a.y + 5), "trash")

static func _place_shop(spec: Dictionary, a: Vector2i, rng: RandomNumberGenerator) -> void:
    _ground(spec, a.x, a.y, 7, 7, "concrete")
    _building(spec, Rect2i(a.x + 1, a.y + 1, 6, 4), "tile", "store", rng)
    if rng.randf() < 0.55:
        _prop(spec, Vector2i(a.x + 2, a.y + 6), "shopping_cart")

static func _place_downtown(spec: Dictionary, a: Vector2i, rng: RandomNumberGenerator) -> void:
    _ground(spec, a.x, a.y, 7, 7, "sidewalk")
    _building(spec, Rect2i(a.x, a.y, 7, 6), "tile", "industrial", rng)
    if rng.randf() < 0.35:
        _prop(spec, Vector2i(a.x + 3, a.y + 6), "vending")

static func _place_woods(spec: Dictionary, a: Vector2i, rng: RandomNumberGenerator) -> void:
    _ground(spec, a.x, a.y, 7, 7, "grass")
    for yy in range(a.y, a.y + 7):
        for xx in range(a.x, a.x + 7):
            var p := Vector2i(xx, yy)
            if rng.randf() < 0.16:
                _obstacle(spec, p, "scrub")
    if rng.randf() < 0.5:
        _ground(spec, a.x, a.y + 3, 7, 1, "dirt")

static func _place_rural(spec: Dictionary, a: Vector2i, rng: RandomNumberGenerator) -> void:
    _ground(spec, a.x, a.y, 7, 7, "dirt" if rng.randf() < 0.62 else "grass")
    if rng.randf() < 0.33:
        _building(spec, Rect2i(a.x + 1, a.y + 1, 5, 4), "wood", "house", rng)
    else:
        for i in range(4):
            if rng.randf() < 0.7:
                _prop(spec, Vector2i(a.x + 1 + i, a.y + 5), "crate")

static func _building(spec: Dictionary, rect: Rect2i, floor_kind: String, _theme: String, rng: RandomNumberGenerator) -> void:
    _ground(spec, rect.position.x, rect.position.y, rect.size.x, rect.size.y, floor_kind)
    spec["indoor_rects"].append([rect.position.x, rect.position.y, rect.size.x, rect.size.y])
    for x in range(rect.position.x, rect.end.x):
        _wall(spec, Vector2i(x, rect.position.y))
        _wall(spec, Vector2i(x, rect.end.y - 1))
    for y in range(rect.position.y, rect.end.y):
        _wall(spec, Vector2i(rect.position.x, y))
        _wall(spec, Vector2i(rect.end.x - 1, y))
    var door := Vector2i(rect.position.x + rect.size.x / 2, rect.end.y - 1)
    _cut_wall(spec, door)
    spec["doors"].append([door, false])
    if rect.size.x >= 5:
        var window := Vector2i(rect.position.x + 1, rect.position.y)
        _cut_wall(spec, window)
        spec["glass"].append(window)
    if rng.randf() < 0.72:
        var light := Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2)
        spec["lights"].append([light, "fluorescent", true])

static func _parcel_hits_road(spec: Dictionary, rect: Rect2i) -> bool:
    for y in range(rect.position.y, rect.end.y):
        for x in range(rect.position.x, rect.end.x):
            if spec.get("road_cells", {}).has(Vector2i(x, y)):
                return true
    return false

static func _place_edge_exits(spec: Dictionary) -> void:
    var w: int = int(spec["width"])
    var h: int = int(spec["height"])
    var exits := [Vector2i(w / 2, 1), Vector2i(w / 2, h - 2), Vector2i(1, h / 2), Vector2i(w - 2, h / 2)]
    spec["exit_cells"] = exits
    for p in exits:
        _clear_cell(spec, p)
        _ground(spec, p.x, p.y, 1, 1, "road")

static func _clear_spawn(spec: Dictionary) -> void:
    var spawn: Vector2i = spec["player_spawn"]
    _clear_cell(spec, spawn)
    _ground(spec, spawn.x - 1, spawn.y - 1, 3, 3, "road")
    for yy in range(spawn.y - 1, spawn.y + 2):
        for xx in range(spawn.x - 1, spawn.x + 2):
            spec["road_cells"][Vector2i(xx, yy)] = true

static func _clear_cell(spec: Dictionary, p: Vector2i) -> void:
    while spec["walls"].has(p): spec["walls"].erase(p)
    while spec["obstacles"].has(p): spec["obstacles"].erase(p)
    while spec["glass"].has(p): spec["glass"].erase(p)
    for i in range(spec["doors"].size() - 1, -1, -1):
        if spec["doors"][i][0] == p: spec["doors"].remove_at(i)
    for i in range(spec["props"].size() - 1, -1, -1):
        if spec["props"][i][0] == p: spec["props"].remove_at(i)

static func _ground(spec: Dictionary, x: int, y: int, w: int, h: int, kind: String) -> void:
    spec["ground_rects"].append([x, y, w, h, kind])

static func _wall(spec: Dictionary, p: Vector2i) -> void:
    if _inside(spec, p) and not spec["walls"].has(p): spec["walls"].append(p)

static func _cut_wall(spec: Dictionary, p: Vector2i) -> void:
    while spec["walls"].has(p): spec["walls"].erase(p)

static func _obstacle(spec: Dictionary, p: Vector2i, kind: String) -> void:
    if not _inside(spec, p): return
    if not spec["obstacles"].has(p): spec["obstacles"].append(p)
    _prop(spec, p, kind)

static func _prop(spec: Dictionary, p: Vector2i, kind: String) -> void:
    if _inside(spec, p): spec["props"].append([p, kind])

static func _inside(spec: Dictionary, p: Vector2i) -> bool:
    return p.x >= 1 and p.y >= 1 and p.x < int(spec["width"]) - 1 and p.y < int(spec["height"]) - 1

static func _cell_noise(seed_value: int, p: Vector2i) -> float:
    var n: int = p.x * 374761393 + p.y * 668265263 + seed_value * 1442695041
    n = (n ^ (n >> 13)) * 1274126177
    n = n ^ (n >> 16)
    return float(posmod(n, 10000)) / 10000.0 - 0.5
