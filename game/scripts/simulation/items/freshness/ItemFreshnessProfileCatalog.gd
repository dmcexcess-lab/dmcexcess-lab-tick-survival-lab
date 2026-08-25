extends RefCounted
class_name ItemFreshnessProfileCatalog

## Sparse semantic perishable catalog. Human-facing lifetimes are converted once
## through System 25's scenario WorldTimeProfile; runtime aging is integer ticks.

const CATALOG_VERSION: int = 1

var _profiles: Dictionary = {}

func _init(time_profile: WorldTimeProfile = null) -> void:
    if time_profile != null and time_profile.is_valid():
        _build_candidate_001(time_profile)

func catalog_version() -> int:
    return CATALOG_VERSION

func has_profile(semantic_type: StringName) -> bool:
    return _profiles.has(String(semantic_type))

func profile(semantic_type: StringName) -> ItemFreshnessProfile:
    var key: String = String(semantic_type)
    if not _profiles.has(key):
        return null
    return (_profiles[key] as ItemFreshnessProfile).copy()

func semantic_types() -> Array[StringName]:
    var keys: Array[String] = []
    for key: Variant in _profiles.keys():
        keys.append(String(key))
    keys.sort()
    var result: Array[StringName] = []
    for key: String in keys:
        result.append(StringName(key))
    return result

func register_profile(profile_value: ItemFreshnessProfile) -> bool:
    if profile_value == null or not profile_value.is_valid():
        return false
    var key: String = String(profile_value.semantic_type)
    if _profiles.has(key):
        return false
    _profiles[key] = profile_value.copy()
    return true

func _build_candidate_001(time_profile: WorldTimeProfile) -> void:
    var h: int = time_profile.ticks_per_hour()
    register_profile(ItemFreshnessProfile.new(&"item.food.milk_carton", 12 * h, 200, 1))
    register_profile(ItemFreshnessProfile.new(&"item.food.raw_meat_package", 12 * h, 200, 1))
    register_profile(ItemFreshnessProfile.new(&"item.food.fresh_berries", 24 * h, 200, 1))
    register_profile(ItemFreshnessProfile.new(&"item.food.bread_loaf", 72 * h, 200, 1))
    register_profile(ItemFreshnessProfile.new(&"item.food.apple", 120 * h, 200, 1))
    register_profile(ItemFreshnessProfile.new(&"item.food.cheese_block", 168 * h, 200, 1))
