extends RefCounted
class_name SpatialStructureGeometry

const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

## Geometry-only rules for structure cells.
## WHAT/generation/construction decide what structures actually exist.

enum Axis {
    HORIZONTAL,
    VERTICAL,
}

static func is_valid_axis(axis: int) -> bool:
    return axis == Axis.HORIZONTAL or axis == Axis.VERTICAL

static func approach_directions(axis: int) -> Array[int]:
    if axis == Axis.HORIZONTAL:
        return [FacingRules.Value.NORTH, FacingRules.Value.SOUTH]
    if axis == Axis.VERTICAL:
        return [FacingRules.Value.EAST, FacingRules.Value.WEST]
    push_error("SpatialStructureGeometry.approach_directions: invalid axis %d" % axis)
    return []

static func continuity_directions(axis: int) -> Array[int]:
    if axis == Axis.HORIZONTAL:
        return [FacingRules.Value.EAST, FacingRules.Value.WEST]
    if axis == Axis.VERTICAL:
        return [FacingRules.Value.NORTH, FacingRules.Value.SOUTH]
    push_error("SpatialStructureGeometry.continuity_directions: invalid axis %d" % axis)
    return []

static func approach_cells(cell: Vector2i, axis: int) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for facing: int in approach_directions(axis):
        result.append(cell + FacingRules.vector(facing))
    return result

static func continuity_cells(cell: Vector2i, axis: int) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for facing: int in continuity_directions(axis):
        result.append(cell + FacingRules.vector(facing))
    return result

static func label(axis: int) -> String:
    if axis == Axis.HORIZONTAL:
        return "horizontal"
    if axis == Axis.VERTICAL:
        return "vertical"
    return "invalid"
