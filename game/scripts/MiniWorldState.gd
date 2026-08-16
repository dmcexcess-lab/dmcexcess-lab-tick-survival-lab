extends RefCounted
class_name MiniWorldState

const WORLD_W := 5
const WORLD_H := 5
const CENTER := Vector2i(2, 2)
const REGION_KINDS := ["residential", "commercial", "downtown", "rural", "woods"]

var world_seed: int = 0
var current_region: Vector2i = CENTER
var regions: Dictionary = {}

func reset(seed_value: int) -> void:
    world_seed = maxi(1, seed_value)
    current_region = CENTER
    regions.clear()
    _generate_regions()

func _generate_regions() -> void:
    for y in range(WORLD_H):
        for x in range(WORLD_W):
            var p := Vector2i(x, y)
            var kind := _kind_for(p)
            regions[p] = {
                "coord": p,
                "kind": kind,
                "seed": _region_seed(p),
                "name": _region_name(kind, p),
            }

    # Keep every world readable and diverse while the other 20 cells still vary
    # from the seed. These are identities, not authored maps.
    _force_kind(CENTER, "downtown")
    _force_kind(Vector2i(3, 2), "commercial")
    _force_kind(Vector2i(1, 2), "residential")
    _force_kind(Vector2i(0, 0), "woods")
    _force_kind(Vector2i(4, 4), "rural")

func _force_kind(p: Vector2i, kind: String) -> void:
    if not regions.has(p):
        return
    var entry: Dictionary = regions[p]
    entry["kind"] = kind
    entry["name"] = _region_name(kind, p)
    regions[p] = entry

func _kind_for(p: Vector2i) -> String:
    if p == CENTER:
        return "downtown"
    var manhattan := absi(p.x - CENTER.x) + absi(p.y - CENTER.y)
    var roll := _hash01(p, 17)
    if manhattan <= 1:
        return "commercial" if roll < 0.48 else "residential"
    if manhattan <= 2:
        if roll < 0.50:
            return "residential"
        if roll < 0.72:
            return "commercial"
        return "rural"
    if roll < 0.48:
        return "woods"
    if roll < 0.82:
        return "rural"
    return "residential"

func _region_seed(p: Vector2i) -> int:
    var mixed: int = world_seed * 1103515245 + (p.x + 11) * 374761393 + (p.y + 23) * 668265263
    mixed = mixed ^ (mixed >> 13)
    return 1 + posmod(mixed, 2147483000)

func _hash01(p: Vector2i, salt: int) -> float:
    var n: int = world_seed * 1442695041 + p.x * 374761393 + p.y * 668265263 + salt * 1274126177
    n = n ^ (n >> 13)
    return float(posmod(n, 10000)) / 10000.0

func _region_name(kind: String, p: Vector2i) -> String:
    var suffix := "%d-%d" % [p.x + 1, p.y + 1]
    match kind:
        "downtown": return "Downtown %s" % suffix
        "commercial": return "Commercial Strip %s" % suffix
        "residential": return "Neighborhood %s" % suffix
        "woods": return "Woodland %s" % suffix
        "rural": return "Rural Edge %s" % suffix
        _: return "District %s" % suffix

func inside(p: Vector2i) -> bool:
    return p.x >= 0 and p.y >= 0 and p.x < WORLD_W and p.y < WORLD_H

func can_move(dir: Vector2i) -> bool:
    return inside(current_region + dir)

func move_region(dir: Vector2i) -> bool:
    var target := current_region + dir
    if not inside(target):
        return false
    current_region = target
    return true

func current_kind() -> String:
    return kind_at(current_region)

func current_seed() -> int:
    return seed_at(current_region)

func current_name() -> String:
    return name_at(current_region)

func kind_at(p: Vector2i) -> String:
    var entry: Dictionary = regions.get(p, {})
    return str(entry.get("kind", "rural"))

func seed_at(p: Vector2i) -> int:
    var entry: Dictionary = regions.get(p, {})
    return int(entry.get("seed", 1))

func name_at(p: Vector2i) -> String:
    var entry: Dictionary = regions.get(p, {})
    return str(entry.get("name", "Unknown District"))
