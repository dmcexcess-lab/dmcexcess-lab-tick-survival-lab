extends RefCounted
class_name SpatialModel

const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

## Pure geometry facade for the authoritative global tactical grid.
## No world-state, collision policy, rendering, generation, or timing lives here.

const CELL_METERS: float = 1.0

static func adjacent(cell: Vector2i, facing: int) -> Vector2i:
    if not FacingRules.is_valid(facing):
        push_error("SpatialModel.adjacent: invalid facing %d" % facing)
        return cell
    return cell + FacingRules.vector(facing)

static func forward(cell: Vector2i, facing: int) -> Vector2i:
    return adjacent(cell, facing)

static func behind(cell: Vector2i, facing: int) -> Vector2i:
    var opposite_facing: int = FacingRules.opposite(facing)
    if opposite_facing < 0:
        return cell
    return adjacent(cell, opposite_facing)

static func left_of(cell: Vector2i, facing: int) -> Vector2i:
    var left_facing: int = FacingRules.turn_left(facing)
    if left_facing < 0:
        return cell
    return adjacent(cell, left_facing)

static func right_of(cell: Vector2i, facing: int) -> Vector2i:
    var right_facing: int = FacingRules.turn_right(facing)
    if right_facing < 0:
        return cell
    return adjacent(cell, right_facing)

static func neighbors4(cell: Vector2i) -> Array[Vector2i]:
    return [
        adjacent(cell, FacingRules.Value.NORTH),
        adjacent(cell, FacingRules.Value.EAST),
        adjacent(cell, FacingRules.Value.SOUTH),
        adjacent(cell, FacingRules.Value.WEST),
    ]

static func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
    return absi(a.x - b.x) + absi(a.y - b.y)

static func are_cardinally_adjacent(a: Vector2i, b: Vector2i) -> bool:
    return manhattan_distance(a, b) == 1

static func footprint_cells(anchor: Vector2i, footprint: SpatialFootprint, facing: int) -> Array[Vector2i]:
    if footprint == null:
        return []
    return footprint.world_cells(anchor, facing)

static func overlaps(cells_a: Array, cells_b: Array) -> bool:
    var occupied: Dictionary = {}
    for value in cells_a:
        if typeof(value) == TYPE_VECTOR2I:
            occupied[value] = true
    for value in cells_b:
        if typeof(value) == TYPE_VECTOR2I and occupied.has(value):
            return true
    return false

static func bounds(cells: Array) -> Rect2i:
    var found: bool = false
    var min_x: int = 0
    var min_y: int = 0
    var max_x: int = 0
    var max_y: int = 0

    for value in cells:
        if typeof(value) != TYPE_VECTOR2I:
            continue
        var cell: Vector2i = value
        if not found:
            found = true
            min_x = cell.x
            min_y = cell.y
            max_x = cell.x
            max_y = cell.y
            continue
        min_x = mini(min_x, cell.x)
        min_y = mini(min_y, cell.y)
        max_x = maxi(max_x, cell.x)
        max_y = maxi(max_y, cell.y)

    if not found:
        return Rect2i()

    return Rect2i(
        Vector2i(min_x, min_y),
        Vector2i(max_x - min_x + 1, max_y - min_y + 1)
    )
