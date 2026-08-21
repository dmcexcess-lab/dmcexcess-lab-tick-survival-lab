extends RefCounted
class_name GlobalWorldGenerationRequest

var world_id: String = ""
var seed: int = 0
var bounds: Rect2i = Rect2i()
var profile_id: StringName = &""

func _init(
    p_world_id: String = "",
    p_seed: int = 0,
    p_bounds: Rect2i = Rect2i(),
    p_profile_id: StringName = &""
) -> void:
    world_id = p_world_id.strip_edges()
    seed = p_seed
    bounds = p_bounds
    profile_id = p_profile_id

func is_valid() -> bool:
    if world_id.is_empty() or world_id.contains(" "):
        return false
    if bounds.size.x <= 0 or bounds.size.y <= 0:
        return false
    if String(profile_id).strip_edges().is_empty():
        return false
    return true
