extends RefCounted
class_name CollisionCatalog

const ProfileClass = preload("res://scripts/simulation/collision/CollisionProfile.gd")

## Explicit physics registry: semantic entity type -> hard movement collision profile.
## This is shared configuration, not per-world save state.

var _profiles: Dictionary = {}

func register(semantic_type: StringName, blocks_movement: bool) -> bool:
    var profile := ProfileClass.new(semantic_type, blocks_movement)
    return register_profile(profile)

func register_profile(profile: CollisionProfile) -> bool:
    if profile == null or not profile.is_valid():
        return false
    _profiles[profile.semantic_type] = profile.copy()
    return true

func remove(semantic_type: StringName) -> bool:
    if not _profiles.has(semantic_type):
        return false
    _profiles.erase(semantic_type)
    return true

func clear() -> void:
    _profiles.clear()

func has_profile(semantic_type: StringName) -> bool:
    return _profiles.has(semantic_type)

func profile_for(semantic_type: StringName) -> CollisionProfile:
    if not _profiles.has(semantic_type):
        return null
    var profile: CollisionProfile = _profiles[semantic_type]
    return profile.copy()

func semantic_types() -> Array[StringName]:
    var result: Array[StringName] = []
    for value: Variant in _profiles.keys():
        result.append(StringName(value))
    result.sort()
    return result
