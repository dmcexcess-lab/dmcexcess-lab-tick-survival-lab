extends RefCounted
class_name CollisionProfile

## Type-level hard movement collision fact.
## Art, vision, interaction, terrain traversal and action timing do not belong here.

var semantic_type: StringName = &""
var blocks_movement: bool = false

func _init(profile_type: StringName = &"", profile_blocks_movement: bool = false) -> void:
    semantic_type = profile_type
    blocks_movement = profile_blocks_movement

func is_valid() -> bool:
    return not String(semantic_type).strip_edges().is_empty()

func copy() -> CollisionProfile:
    return CollisionProfile.new(semantic_type, blocks_movement)
