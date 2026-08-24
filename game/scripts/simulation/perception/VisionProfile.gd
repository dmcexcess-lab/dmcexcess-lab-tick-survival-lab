extends RefCounted
class_name VisionProfile

const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

## Observer-facing visual-field parameters. Geometry is deterministic integer-cell math.

var max_range: int = 12
var near_awareness_radius: int = 1

func _init(configured_range: int = 12, configured_near_radius: int = 1) -> void:
    max_range = configured_range
    near_awareness_radius = configured_near_radius

func is_valid() -> bool:
    return max_range >= 1 and near_awareness_radius >= 0 and near_awareness_radius <= max_range

func copy() -> VisionProfile:
    return VisionProfile.new(max_range, near_awareness_radius)

func contains_offset(offset: Vector2i, facing: int) -> bool:
    if not is_valid() or not FacingRules.is_valid(facing):
        return false
    if offset == Vector2i.ZERO:
        return true

    var distance_squared: int = offset.x * offset.x + offset.y * offset.y
    if distance_squared > max_range * max_range:
        return false

    if maxi(abs(offset.x), abs(offset.y)) <= near_awareness_radius:
        return true

    var forward: int = 0
    var lateral: int = 0
    match facing:
        FacingRules.Value.NORTH:
            forward = -offset.y
            lateral = offset.x
        FacingRules.Value.EAST:
            forward = offset.x
            lateral = offset.y
        FacingRules.Value.SOUTH:
            forward = offset.y
            lateral = offset.x
        FacingRules.Value.WEST:
            forward = -offset.x
            lateral = offset.y
        _:
            return false

    if forward <= 0:
        return false
    return lateral * lateral <= 3 * forward * forward
