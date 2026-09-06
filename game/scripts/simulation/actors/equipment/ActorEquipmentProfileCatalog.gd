extends RefCounted
class_name ActorEquipmentProfileCatalog

const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")

## Semantic equipment rules and physical protection/climate values.
## Armor contributions and wind/water resistance use a 0..100 scale.
## Insulation is an additive warmth rating consumed by temperature simulation/UI.

const SKATEBOARD := &"item.vehicle.skateboard"

const PROFILES: Dictionary = {
    &"item.vehicle.skateboard": {"slots": [Slots.Value.PRIMARY_RIGHT, Slots.Value.SECONDARY_LEFT, Slots.Value.BACK], "armor_blunt": 0, "armor_cut": 0, "armor_bite": 0, "insulation": 0, "wind_resistance": 0, "water_resistance": 0, "visual": &"skateboard"},
    &"item.clothing.baseball_cap": {"slots": [Slots.Value.HEAD], "armor_blunt": 1, "armor_cut": 1, "armor_bite": 0, "insulation": 2, "wind_resistance": 2, "water_resistance": 1, "visual": &"baseball_cap"},
    &"item.clothing.beanie": {"slots": [Slots.Value.HEAD], "armor_blunt": 1, "armor_cut": 1, "armor_bite": 0, "insulation": 8, "wind_resistance": 5, "water_resistance": 2, "visual": &"beanie"},
    &"item.clothing.t_shirt": {"slots": [Slots.Value.TORSO], "armor_blunt": 1, "armor_cut": 1, "armor_bite": 1, "insulation": 3, "wind_resistance": 1, "water_resistance": 0, "visual": &"t_shirt"},
    &"item.clothing.hoodie": {"slots": [Slots.Value.TORSO], "armor_blunt": 3, "armor_cut": 2, "armor_bite": 2, "insulation": 12, "wind_resistance": 8, "water_resistance": 4, "visual": &"hoodie"},
    &"item.clothing.work_jacket": {"slots": [Slots.Value.TORSO], "armor_blunt": 7, "armor_cut": 8, "armor_bite": 5, "insulation": 16, "wind_resistance": 18, "water_resistance": 10, "visual": &"work_jacket"},
    &"item.clothing.jeans": {"slots": [Slots.Value.LEGS], "armor_blunt": 3, "armor_cut": 4, "armor_bite": 2, "insulation": 7, "wind_resistance": 5, "water_resistance": 2, "visual": &"jeans"},
    &"item.clothing.cargo_pants": {"slots": [Slots.Value.LEGS], "armor_blunt": 4, "armor_cut": 5, "armor_bite": 3, "insulation": 8, "wind_resistance": 7, "water_resistance": 4, "visual": &"cargo_pants"},
    &"item.clothing.sneakers": {"slots": [Slots.Value.FEET], "armor_blunt": 2, "armor_cut": 2, "armor_bite": 1, "insulation": 4, "wind_resistance": 2, "water_resistance": 1, "visual": &"sneakers"},
    &"item.clothing.work_boots": {"slots": [Slots.Value.FEET], "armor_blunt": 7, "armor_cut": 6, "armor_bite": 3, "insulation": 9, "wind_resistance": 6, "water_resistance": 12, "visual": &"work_boots"},
    &"item.clothing.work_gloves": {"slots": [Slots.Value.HANDS], "armor_blunt": 4, "armor_cut": 6, "armor_bite": 2, "insulation": 5, "wind_resistance": 3, "water_resistance": 2, "visual": &"work_gloves"},
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

func armor_and_climate(semantic_type: StringName) -> Dictionary:
    var value := profile(semantic_type)
    return {
        "armor_blunt": int(value.get("armor_blunt", 0)), "armor_cut": int(value.get("armor_cut", 0)), "armor_bite": int(value.get("armor_bite", 0)),
        "insulation": int(value.get("insulation", 0)), "wind_resistance": int(value.get("wind_resistance", 0)), "water_resistance": int(value.get("water_resistance", 0)),
    }
