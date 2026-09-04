extends RefCounted
class_name VehicleHeading

## Twelve semantic headings at 30-degree increments. WHAT remains cardinal;
## this typed vehicle state owns the finer driving heading.

const COUNT: int = 12
const STEP_DEGREES: float = 30.0

static func normalize(value: int) -> int:
    return posmod(value, COUNT)

static func turn_left(value: int) -> int:
    return normalize(value - 1)

static func turn_right(value: int) -> int:
    return normalize(value + 1)

static func completed_turn_heading(value: int, direction: int) -> int:
    return normalize(value + clampi(direction, -1, 1) * 3)

static func turn_path(value: int, direction: int) -> Array[Vector2i]:
    var turn_direction := clampi(direction, -1, 1)
    if turn_direction == 0:
        return []
    var result: Array[Vector2i] = []
    var current := Vector2i.ZERO
    for step: int in range(1, 4):
        var step_heading := normalize(value + turn_direction * step)
        current += _heading_cardinal_step(step_heading)
        result.append(current)
    return result

static func degrees(value: int) -> float:
    return float(normalize(value)) * STEP_DEGREES

static func forward_path(value: int, distance: int = 3) -> Array[Vector2i]:
    var heading: int = normalize(value)
    var count: int = maxi(1, distance)
    var result: Array[Vector2i] = []
    var angle: float = deg_to_rad(-90.0 + degrees(heading))
    var dx: float = cos(angle)
    var dy: float = sin(angle)
    var previous := Vector2i.ZERO
    for step: int in range(1, count + 1):
        var point := Vector2i(roundi(dx * float(step)), roundi(dy * float(step)))
        if point == previous:
            point = previous + _dominant_cardinal(dx, dy)
        result.append(point)
        previous = point
    return result

static func reverse_path(value: int, distance: int = 1) -> Array[Vector2i]:
    return forward_path(normalize(value + int(COUNT / 2)), distance)

static func cardinal_facing(value: int) -> int:
    # SpatialFacing: NORTH=0, EAST=1, SOUTH=2, WEST=3.
    return int(round(float(normalize(value)) / 3.0)) % 4

static func _dominant_cardinal(dx: float, dy: float) -> Vector2i:
    if absf(dx) >= absf(dy):
        return Vector2i(1 if dx >= 0.0 else -1, 0)
    return Vector2i(0, 1 if dy >= 0.0 else -1)

static func _heading_cardinal_step(value: int) -> Vector2i:
    var angle := deg_to_rad(-90.0 + degrees(value))
    return _dominant_cardinal(cos(angle), sin(angle))
