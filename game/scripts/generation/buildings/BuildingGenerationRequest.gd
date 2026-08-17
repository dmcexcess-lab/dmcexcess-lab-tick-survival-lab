extends RefCounted
class_name BuildingGenerationRequest

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const EntityId = preload("res://scripts/foundation/world/WorldEntityId.gd")

var instance_id: String = ""
var archetype_id: StringName = &""
var seed: int = 0
var envelope: Rect2i = Rect2i()
var orientation: int = Facing.Value.NORTH
var frontage_side: int = Facing.Value.EAST

func _init(
    p_instance_id: String = "",
    p_archetype_id: StringName = &"",
    p_seed: int = 0,
    p_envelope: Rect2i = Rect2i(),
    p_orientation: int = Facing.Value.NORTH,
    p_frontage_side: int = Facing.Value.EAST
) -> void:
    instance_id = p_instance_id.strip_edges()
    archetype_id = p_archetype_id
    seed = p_seed
    envelope = p_envelope
    orientation = p_orientation
    frontage_side = p_frontage_side

func is_valid() -> bool:
    return EntityId.is_valid(instance_id) \
        and not String(archetype_id).strip_edges().is_empty() \
        and envelope.size.x > 0 and envelope.size.y > 0 \
        and Facing.is_valid(orientation) and Facing.is_valid(frontage_side)
