extends RefCounted
class_name SurvivorSustainmentProfileCatalog

## System 34 food/drink effects for real item semantics. Raw perishables remain absent
## until cooking preserves freshness state; first stove recipes prepare canned foods.

var _profiles: Dictionary = {}

func _init() -> void:
    _add(&"item.drink.water_bottle", &"drink", 0, 35, 0, 10)
    _add(&"item.drink.soda_can", &"drink", 0, 20, 2, 10)
    _add(&"item.drink.juice_bottle", &"drink", 5, 30, 1, 12)
    _add(&"item.drink.sports_drink", &"drink", 0, 40, 1, 10)
    _add(&"item.food.canned_beans", &"eat", 28, 2, 1, 24)
    _add(&"item.food.canned_soup", &"eat", 22, 8, 1, 22)
    _add(&"item.food.crackers", &"eat", 14, -2, 0, 18)
    _add(&"item.food.cereal_box", &"eat", 24, -2, 1, 24)
    _add(&"item.food.energy_bar", &"eat", 16, -1, 1, 12)
    _add(&"item.food.apple", &"eat", 12, 5, 1, 12)
    _add(&"item.food.milk_carton", &"drink", 8, 18, 1, 12)
    _add(&"item.food.fresh_berries", &"eat", 10, 5, 1, 12)
    _add(&"item.food.bread_loaf", &"eat", 20, -1, 1, 22)
    _add(&"item.food.cheese_block", &"eat", 18, -2, 1, 20)
    _add(&"item.food.banana", &"eat", 12, 4, 1, 12)
    _add(&"item.food.carrot_bag", &"eat", 14, 4, 0, 18)
    _add(&"item.food.yogurt_cup", &"eat", 10, 4, 1, 12)
    _add(&"item.food.peanut_butter_jar", &"eat", 24, -3, 1, 22)
    _add(&"item.crafting.heated_soup", &"eat", 28, 10, 3, 18)
    _add(&"item.crafting.heated_beans", &"eat", 34, 3, 3, 20)

func has_profile(semantic_type: StringName) -> bool:
    return _profiles.has(String(semantic_type))

func profile(semantic_type: StringName) -> Dictionary:
    var key: String = String(semantic_type)
    if not _profiles.has(key): return {}
    return (_profiles[key] as Dictionary).duplicate(true)

func semantic_types() -> Array[StringName]:
    var keys: Array[String] = []
    for key: Variant in _profiles.keys(): keys.append(String(key))
    keys.sort()
    var result: Array[StringName] = []
    for key: String in keys: result.append(StringName(key))
    return result

func _add(semantic_type: StringName, action_kind: StringName, satiety_gain: int, hydration_gain: int, engagement_gain: int, duration_ticks: int) -> void:
    var key: String = String(semantic_type)
    if key.is_empty() or action_kind not in [&"eat", &"drink"] or duration_ticks < 1: return
    _profiles[key] = {
        "semantic_type": semantic_type, "action_kind": action_kind,
        "satiety_gain": satiety_gain, "hydration_gain": hydration_gain,
        "engagement_gain": engagement_gain, "duration_ticks": duration_ticks,
    }
