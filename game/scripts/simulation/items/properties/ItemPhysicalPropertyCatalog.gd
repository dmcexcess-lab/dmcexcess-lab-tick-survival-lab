extends RefCounted
class_name ItemPhysicalPropertyCatalog

const ProfileClass = preload("res://scripts/simulation/items/properties/ItemPhysicalProfile.gd")

## 13D explicit semantic-type physical-property catalog.
## Missing classification is intentionally not interpreted as zero weight.

signal profile_registered(semantic_type, weight_grams)
signal profile_removed(semantic_type)

var _profiles: Dictionary = {}
var _revision: int = 0

func revision() -> int:
    return _revision

func has_profile(semantic_type: StringName) -> bool:
    return _profiles.has(String(semantic_type))

func semantic_types() -> Array[StringName]:
    var keys: Array[String] = []
    for key: Variant in _profiles.keys():
        keys.append(String(key))
    keys.sort()
    var result: Array[StringName] = []
    for key: String in keys:
        result.append(StringName(key))
    return result

func profile(semantic_type: StringName) -> ItemPhysicalProfile:
    var key: String = String(semantic_type)
    if not _profiles.has(key):
        return null
    var value: ItemPhysicalProfile = _profiles[key]
    return value.copy()

func weight_grams(semantic_type: StringName) -> int:
    var value: ItemPhysicalProfile = profile(semantic_type)
    return -1 if value == null else value.weight_grams

func register_profile(semantic_type: StringName, weight_grams_value: int) -> bool:
    var candidate := ProfileClass.new(semantic_type, weight_grams_value)
    var key: String = String(semantic_type)
    if not candidate.is_valid() or _profiles.has(key):
        return false
    _profiles[key] = candidate
    _revision += 1
    profile_registered.emit(semantic_type, weight_grams_value)
    return true

func remove_profile(semantic_type: StringName) -> bool:
    var key: String = String(semantic_type)
    if not _profiles.has(key):
        return false
    _profiles.erase(key)
    _revision += 1
    profile_removed.emit(semantic_type)
    return true
