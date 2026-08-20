extends RefCounted
class_name BuildingArchetypePlacementDescriptor

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

var _archetype_id: StringName = &""
var _archetype_version: int = 0
var _canonical_size: Vector2i = Vector2i.ZERO
var _canonical_frontage: int = Facing.Value.NORTH
var _supported_orientations: Array[int] = []

func _init(
    p_archetype_id: StringName = &"",
    p_archetype_version: int = 0,
    p_canonical_size: Vector2i = Vector2i.ZERO,
    p_canonical_frontage: int = Facing.Value.NORTH,
    p_supported_orientations: Array[int] = []
) -> void:
    _archetype_id = p_archetype_id
    _archetype_version = p_archetype_version
    _canonical_size = p_canonical_size
    _canonical_frontage = p_canonical_frontage
    _supported_orientations = p_supported_orientations.duplicate()

func is_valid() -> bool:
    return not String(_archetype_id).is_empty() \
        and _archetype_version > 0 \
        and _canonical_size.x > 0 and _canonical_size.y > 0 \
        and Facing.is_valid(_canonical_frontage) \
        and not _supported_orientations.is_empty()

func archetype_id() -> StringName:
    return _archetype_id

func archetype_version() -> int:
    return _archetype_version

func canonical_size() -> Vector2i:
    return _canonical_size

func canonical_frontage() -> int:
    return _canonical_frontage

func supported_orientations() -> Array[int]:
    return _supported_orientations.duplicate()

func supports_orientation(orientation: int) -> bool:
    return _supported_orientations.has(orientation)

func required_size(orientation: int) -> Vector2i:
    if not supports_orientation(orientation):
        return Vector2i.ZERO
    if orientation == Facing.Value.EAST or orientation == Facing.Value.WEST:
        return Vector2i(_canonical_size.y, _canonical_size.x)
    return _canonical_size

func frontage_for_orientation(orientation: int) -> int:
    if not supports_orientation(orientation):
        return -1
    return (_canonical_frontage + orientation) % 4

func snapshot() -> Dictionary:
    return {
        "archetype_id": String(_archetype_id),
        "archetype_version": _archetype_version,
        "canonical_size": [_canonical_size.x, _canonical_size.y],
        "canonical_frontage": _canonical_frontage,
        "supported_orientations": _supported_orientations.duplicate(),
    }
