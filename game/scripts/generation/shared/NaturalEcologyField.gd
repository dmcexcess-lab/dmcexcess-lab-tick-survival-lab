extends RefCounted
class_name NaturalEcologyField

const Seed = preload("res://scripts/generation/areas/AreaSeed.gd")

## Pure world-space natural-dressing field shared by island surface and
## globally projected settlement areas. The caller still owns where natural
## props are allowed; this only answers what the common ecology field proposes
## at one global cell.
static func semantic_at(environment: Dictionary, world_seed: int, cell: Vector2i) -> StringName:
    var trees: Array = environment.get("tree_semantics", [])
    var shrubs: Array = environment.get("shrub_semantics", [])
    var rocks: Array = environment.get("rock_semantics", [])
    if trees.is_empty() or shrubs.is_empty() or rocks.is_empty():
        return &""

    var base_density: float = clampf(float(environment.get("natural_noise_density", 0.0105)), 0.0, 0.04)
    var patch_scale: int = maxi(8, int(environment.get("natural_noise_patch_scale", 22)))
    var sparse_multiplier: float = maxf(0.0, float(environment.get("natural_noise_sparse_multiplier", 0.20)))
    var dense_multiplier: float = maxf(sparse_multiplier, float(environment.get("natural_noise_dense_multiplier", 2.25)))

    var patch_noise: float = _value_noise_2d(world_seed, cell, patch_scale, 401)
    var local_density: float = minf(0.04, base_density * lerpf(sparse_multiplier, dense_multiplier, patch_noise))
    if Seed.unit_2d(world_seed, cell.x, cell.y, 503) >= local_density:
        return &""

    var family_noise: float = _value_noise_2d(world_seed, cell, patch_scale * 2, 607)
    var family: Array = trees
    if family_noise >= 0.78:
        family = rocks
    elif family_noise >= 0.43:
        family = shrubs
    if family.is_empty():
        return &""

    var index: int = Seed.hash_2d(world_seed, cell.x, cell.y, 811) % family.size()
    return StringName(family[index])

static func _value_noise_2d(seed: int, cell: Vector2i, scale: int, salt: int) -> float:
    var safe_scale: int = maxi(1, scale)
    var grid_x: int = floori(float(cell.x) / float(safe_scale))
    var grid_y: int = floori(float(cell.y) / float(safe_scale))
    var frac_x: float = float(cell.x - grid_x * safe_scale) / float(safe_scale)
    var frac_y: float = float(cell.y - grid_y * safe_scale) / float(safe_scale)
    var smooth_x: float = frac_x * frac_x * (3.0 - 2.0 * frac_x)
    var smooth_y: float = frac_y * frac_y * (3.0 - 2.0 * frac_y)

    var n00: float = Seed.unit_2d(seed, grid_x, grid_y, salt)
    var n10: float = Seed.unit_2d(seed, grid_x + 1, grid_y, salt)
    var n01: float = Seed.unit_2d(seed, grid_x, grid_y + 1, salt)
    var n11: float = Seed.unit_2d(seed, grid_x + 1, grid_y + 1, salt)
    var top: float = lerpf(n00, n10, smooth_x)
    var bottom: float = lerpf(n01, n11, smooth_x)
    return lerpf(top, bottom, smooth_y)
