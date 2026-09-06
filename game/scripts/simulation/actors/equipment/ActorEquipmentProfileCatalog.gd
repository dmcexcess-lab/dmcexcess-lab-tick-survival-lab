extends RefCounted
class_name ActorEquipmentProfileCatalog

const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")

## Semantic equipment rules and physical protection/weather values.
## bite_cut_armor, blunt_ballistic_armor, and water_resistance use a 0..100 scale.

const SKATEBOARD := &"item.vehicle.skateboard"

const PROFILES: Dictionary = {
    &"item.vehicle.skateboard": {"slots": [Slots.Value.PRIMARY_RIGHT, Slots.Value.SECONDARY_LEFT, Slots.Value.BACK], "bite_cut_armor": 0, "blunt_ballistic_armor": 0, "water_resistance": 0, "visual": &"skateboard"},
    &"item.clothing.baseball_cap": {"slots": [Slots.Value.HEAD], "bite_cut_armor": 1, "blunt_ballistic_armor": 1, "water_resistance": 1, "visual": &"baseball_cap"},
    &"item.clothing.beanie": {"slots": [Slots.Value.HEAD], "bite_cut_armor": 1, "blunt_ballistic_armor": 1, "water_resistance": 2, "visual": &"beanie"},
    &"item.clothing.t_shirt": {"slots": [Slots.Value.TORSO], "bite_cut_armor": 1, "blunt_ballistic_armor": 1, "water_resistance": 0, "visual": &"t_shirt"},
    &"item.clothing.hoodie": {"slots": [Slots.Value.TORSO], "bite_cut_armor": 2, "blunt_ballistic_armor": 3, "water_resistance": 4, "visual": &"hoodie"},
    &"item.clothing.work_jacket": {"slots": [Slots.Value.TORSO], "bite_cut_armor": 8, "blunt_ballistic_armor": 7, "water_resistance": 10, "visual": &"work_jacket"},
    &"item.clothing.jeans": {"slots": [Slots.Value.LEGS], "bite_cut_armor": 4, "blunt_ballistic_armor": 3, "water_resistance": 2, "visual": &"jeans"},
    &"item.clothing.cargo_pants": {"slots": [Slots.Value.LEGS], "bite_cut_armor": 5, "blunt_ballistic_armor": 4, "water_resistance": 4, "visual": &"cargo_pants"},
    &"item.clothing.sneakers": {"slots": [Slots.Value.FEET], "bite_cut_armor": 2, "blunt_ballistic_armor": 2, "water_resistance": 1, "visual": &"sneakers"},
    &"item.clothing.work_boots": {"slots": [Slots.Value.FEET], "bite_cut_armor": 6, "blunt_ballistic_armor": 7, "water_resistance": 12, "visual": &"work_boots"},
    &"item.clothing.work_gloves": {"slots": [Slots.Value.HANDS], "bite_cut_armor": 6, "blunt_ballistic_armor": 4, "water_resistance": 2, "visual": &"work_gloves"},
}

func profile(semantic_type: StringName) -> Dictionary:
    if not PROFILES.has(semantic_type): return {}
    return Dictionary(PROFILES[semantic_type]).duplicate(true)
func has_profile(semantic_type: StringName) -> bool: return PROFILES.has(semantic_type)

func allowed_slots(semantic_type: StringName) -> Array[int]:
    var result: Array[int] = []
    if PROFILES.has(semantic_type):
        for slot: Variant in Dictionary(PROFILES[semantic_type]).get("slots", []): result.append(int(slot))
        return result
    if String(semantic_type).begins_with("item."): result.assign([Slots.Value.PRIMARY_RIGHT, Slots.Value.SECONDARY_LEFT])
    return result

func is_allowed(semantic_type: StringName, slot: int) -> bool: return slot in allowed_slots(semantic_type)
func is_wearable(semantic_type: StringName) -> bool:
    for slot: int in allowed_slots(semantic_type):
        if Slots.is_worn(slot): return true
    return false

func protection_and_weather(semantic_type: StringName) -> Dictionary:
    var value := profile(semantic_type)
    return {
        "bite_cut_armor": int(value.get("bite_cut_armor", 0)),
        "blunt_ballistic_armor": int(value.get("blunt_ballistic_armor", 0)),
        "water_resistance": int(value.get("water_resistance", 0)),
    }
