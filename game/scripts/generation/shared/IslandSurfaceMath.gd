extends RefCounted
class_name IslandSurfaceMath

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")

const LAND: StringName = &"land"
const SHORE: StringName = &"shore"
const OCEAN: StringName = &"ocean"

## Deterministic whole-world coastline classification shared by global planning and
## local materialization. The shape is one connected central island: coast wobble
## changes only the distance of each outer edge, so it cannot create inland ocean holes.
static func classify(
    world_bounds: Rect2i,
    world_seed: int,
    cell: Vector2i,
    ocean_margin: int,
    shore_width: int,
    coast_wobble: int,
    coast_scale: int = 96
) -> StringName:
    if not world_bounds.has_point(cell):
        return OCEAN
    var min_x: int = world_bounds.position.x
    var min_y: int = world_bounds.position.y
    var max_x: int = world_bounds.position.x + world_bounds.size.x - 1
    var max_y: int = world_bounds.position.y + world_bounds.size.y - 1
    var distances: Array[int] = [
        cell.y - min_y,
        max_x - cell.x,
        max_y - cell.y,
        cell.x - min_x,
    ]
    var side: int = 0
    var edge_distance: int = distances[0]
    for index in range(1, distances.size()):
        if distances[index] < edge_distance:
            edge_distance = distances[index]
            side = index

    var along: int = cell.x - min_x if side == 0 or side == 2 else cell.y - min_y
    var threshold: int = maxi(1, ocean_margin + _edge_wobble(world_seed, side, along, coast_wobble, coast_scale))
    if edge_distance < threshold:
        return OCEAN
    if edge_distance < threshold + maxi(1, shore_width):
        return SHORE
    return LAND

static func is_walkable_surface(kind: StringName) -> bool:
    return kind == LAND or kind == SHORE

static func shore_semantic(
    world_bounds: Rect2i,
    world_seed: int,
    cell: Vector2i,
    ocean_margin: int,
    shore_width: int,
    coast_wobble: int,
    coast_scale: int = 96
) -> StringName:
    var mask: int = 0
    if classify(world_bounds, world_seed, cell + Vector2i(0, -1), ocean_margin, shore_width, coast_wobble, coast_scale) == OCEAN:
        mask |= 1
    if classify(world_bounds, world_seed, cell + Vector2i(1, 0), ocean_margin, shore_width, coast_wobble, coast_scale) == OCEAN:
        mask |= 2
    if classify(world_bounds, world_seed, cell + Vector2i(0, 1), ocean_margin, shore_width, coast_wobble, coast_scale) == OCEAN:
        mask |= 4
    if classify(world_bounds, world_seed, cell + Vector2i(-1, 0), ocean_margin, shore_width, coast_wobble, coast_scale) == OCEAN:
        mask |= 8
    match mask:
        1: return &"ground.shore_n"
        2: return &"ground.shore_e"
        3: return &"ground.shore_ne"
        4: return &"ground.shore_s"
        6: return &"ground.shore_es"
        7: return &"ground.shore_nes"
        8: return &"ground.shore_w"
        9: return &"ground.shore_wn"
        11: return &"ground.shore_wne"
        12: return &"ground.shore_sw"
        13: return &"ground.shore_swn"
        14: return &"ground.shore_esw"
        15: return &"ground.shore_all"
    return &"ground.shore_sand"

static func rect_is_land(
    world_bounds: Rect2i,
    world_seed: int,
    rect: Rect2i,
    ocean_margin: int,
    shore_width: int,
    coast_wobble: int,
    coast_scale: int = 96
) -> bool:
    if rect.size.x <= 0 or rect.size.y <= 0:
        return false
    var max_cell: Vector2i = rect.position + rect.size - Vector2i.ONE
    var probes: Array[Vector2i] = [
        rect.position,
        Vector2i(max_cell.x, rect.position.y),
        Vector2i(rect.position.x, max_cell.y),
        max_cell,
        rect.position + Vector2i(rect.size.x / 2, rect.size.y / 2),
    ]
    for probe: Vector2i in probes:
        if classify(world_bounds, world_seed, probe, ocean_margin, shore_width, coast_wobble, coast_scale) != LAND:
            return false
    return true

static func _edge_wobble(seed: int, side: int, along: int, amplitude: int, scale: int) -> int:
    var safe_scale: int = maxi(8, scale)
    var safe_amplitude: int = maxi(0, amplitude)
    if safe_amplitude == 0:
        return 0
    var segment: int = floori(float(along) / float(safe_scale))
    var local: int = along - segment * safe_scale
    var t: float = clampf(float(local) / float(safe_scale), 0.0, 1.0)
    var smooth: float = t * t * (3.0 - 2.0 * t)
    var a: float = Seed.unit_2d(seed, segment, side, 7301) * 2.0 - 1.0
    var b: float = Seed.unit_2d(seed, segment + 1, side, 7301) * 2.0 - 1.0
    return roundi(lerpf(a, b, smooth) * float(safe_amplitude))
