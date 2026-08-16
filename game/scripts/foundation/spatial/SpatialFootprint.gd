extends RefCounted
class_name SpatialFootprint

const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

## Immutable-style occupied-cell mask relative to a stable anchor.
## The stored offsets describe canonical NORTH orientation.

var _offsets: Array[Vector2i] = [Vector2i.ZERO]

func _init(offsets: Array = []) -> void:
    if offsets.is_empty():
        return

    var unique: Array[Vector2i] = []
    var seen: Dictionary = {}
    for value in offsets:
        if typeof(value) != TYPE_VECTOR2I:
            continue
        var offset: Vector2i = value
        if seen.has(offset):
            continue
        seen[offset] = true
        unique.append(offset)

    if not unique.is_empty():
        _offsets = unique

static func single_cell() -> SpatialFootprint:
    return SpatialFootprint.new([Vector2i.ZERO])

static func rectangle(width: int, height: int) -> SpatialFootprint:
    var safe_width: int = maxi(1, width)
    var safe_height: int = maxi(1, height)
    var offsets: Array[Vector2i] = []
    for y: int in range(safe_height):
        for x: int in range(safe_width):
            offsets.append(Vector2i(x, y))
    return SpatialFootprint.new(offsets)

func offsets() -> Array[Vector2i]:
    return _offsets.duplicate()

func cell_count() -> int:
    return _offsets.size()

func contains_relative(offset: Vector2i) -> bool:
    return offset in _offsets

func rotated_offsets(facing: int) -> Array[Vector2i]:
    if not FacingRules.is_valid(facing):
        push_error("SpatialFootprint.rotated_offsets: invalid facing %d" % facing)
        return []

    var result: Array[Vector2i] = []
    for offset: Vector2i in _offsets:
        result.append(FacingRules.rotate_offset_from_north(offset, facing))
    return result

func world_cells(anchor: Vector2i, facing: int) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for offset: Vector2i in rotated_offsets(facing):
        result.append(anchor + offset)
    return result
