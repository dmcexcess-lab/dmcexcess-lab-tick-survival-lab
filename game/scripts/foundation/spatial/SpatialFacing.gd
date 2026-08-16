extends RefCounted
class_name SpatialFacing

## Semantic four-way facing/direction rules for the authoritative world grid.
## No art, input, actor, generator, or world-state meaning belongs here.

enum Value {
    NORTH,
    EAST,
    SOUTH,
    WEST,
}

static func is_valid(facing: int) -> bool:
    return facing >= Value.NORTH and facing <= Value.WEST

static func vector(facing: int) -> Vector2i:
    match facing:
        Value.NORTH:
            return Vector2i(0, -1)
        Value.EAST:
            return Vector2i(1, 0)
        Value.SOUTH:
            return Vector2i(0, 1)
        Value.WEST:
            return Vector2i(-1, 0)
        _:
            push_error("SpatialFacing.vector: invalid facing %d" % facing)
            return Vector2i.ZERO

static func from_vector(direction: Vector2i) -> int:
    match direction:
        Vector2i(0, -1):
            return Value.NORTH
        Vector2i(1, 0):
            return Value.EAST
        Vector2i(0, 1):
            return Value.SOUTH
        Vector2i(-1, 0):
            return Value.WEST
        _:
            return -1

static func turn_right(facing: int) -> int:
    if not is_valid(facing):
        push_error("SpatialFacing.turn_right: invalid facing %d" % facing)
        return -1
    return (facing + 1) % 4

static func turn_left(facing: int) -> int:
    if not is_valid(facing):
        push_error("SpatialFacing.turn_left: invalid facing %d" % facing)
        return -1
    return (facing + 3) % 4

static func opposite(facing: int) -> int:
    if not is_valid(facing):
        push_error("SpatialFacing.opposite: invalid facing %d" % facing)
        return -1
    return (facing + 2) % 4

static func rotate_offset_from_north(offset: Vector2i, facing: int) -> Vector2i:
    match facing:
        Value.NORTH:
            return offset
        Value.EAST:
            return Vector2i(-offset.y, offset.x)
        Value.SOUTH:
            return Vector2i(-offset.x, -offset.y)
        Value.WEST:
            return Vector2i(offset.y, -offset.x)
        _:
            push_error("SpatialFacing.rotate_offset_from_north: invalid facing %d" % facing)
            return offset

static func label(facing: int) -> String:
    match facing:
        Value.NORTH:
            return "north"
        Value.EAST:
            return "east"
        Value.SOUTH:
            return "south"
        Value.WEST:
            return "west"
        _:
            return "invalid"
