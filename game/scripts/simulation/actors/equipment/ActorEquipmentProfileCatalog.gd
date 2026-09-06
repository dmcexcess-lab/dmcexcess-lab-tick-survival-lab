extends RefCounted
class_name ActorEquipmentProfileCatalog

const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")

## Semantic equipment rules and physical protection/climate values.
## Armor values are percentage-point contributions on a 0..100 aggregate scale.
## Insulation is an abstract warmth contribution; wind/water resistance are 0..100.

const SKATEBOARD := &"item.vehicle.skateboard"

const PROFILES: Dictionary = {
    &"item.vehicle.skateboard": {
        "slots": [Slots.Value.PRIMARY_RIGHT, Slots.Value.SECONDARY_LEFT, Slots.Value.BACK],
        "armor_blunt": 0, "armor_cut": 0, "armor_bite": 0,
        "insulation": 0, "wind_resistance": 0, "water_resistance": 0,
        "visual": &"skateboard",
    },
    &"item.apparel.baseball_cap": {
        "slots": [Slots.Value.HEAD],
        "armor_blunt": 1, "armor_cut": 1, "armor_bite": 0,
        "insulation": 2, "wind_resistance": 2, "water_resistance": 1,
        "visual": &"baseball_cap",
    },
    &"item.household.beanie": {
        "slots": [Slots.Value.HEAD],
        "armor_blunt": 1, "armor_cut": 1, "armor_bite": 0,
        "insulation": 8, "wind_resistance": 5, "water_resistance": 2,
        "visual": &"beanie",
    },
    &"item.apparel.t_shirt": {
        "slots": [Slots.Value.TORSO],
        "armor_blunt": 1, "armor_cut": 1, "armor_bite": 1,
        "insulation": 3, "wind_resistance": 1, "water_resistance": 0,
        "visual": &"t_shirt",
    },
    &"item.apparel.hoodie": {
        "slots": [Slots.Value.TORSO],
        "armor_blunt": 3, "armor_cut": 2, "armor_bite": 2,
        "insulation": 12, "wind_resistance": 8, "water_resistance": 4,
        "visual": &"hoodie",
    },
    &"item.apparel.work_jacket": {
        "slots": [Slots.Value.TORSO],
        "armor_blunt": 7, "armor_cut": 8, "armor_bite": 5,
        "insulation": 16, "wind_resistance": 18, "water_resistance": 10,
        "visual": &"work_jacket",
    },
    &"item.apparel.jeans": {
        "slots": [Slots.Value.LEGS],
        "armor_blunt": 3, "armor_cut": 4, "armor_bite": 2,
        "insulation": 7, "wind_resistance": 5, "water_resistance": 2,
        "visual": &"jeans",
    },
    &"item.apparel.cargo_pants": {
        "slots": [Slots.Value.LEGS],
        "armor_blunt": 4, "armor_cut": 5, "armor_bite": 3,
        "insulation": 8, "wind_resistance": 7, "water_resistance": 4,
        "visual": &"cargo_pants",
    },
    &"item.apparel.sneakers": {
        "slots": [Slots.Value.FEET],
        "armor_blunt": 2, "armor_cut": 2, "armor_bite": 1,
        "insulation": 4, "wind_resistance": 2, "water_resistance": 1,
        "visual": &"sneakers",
    },
    &"item.apparel.work_boots": {
        "slots": [Slots.Value.FEET],
        "armor_blunt": 7, "armor_cut": 6, "armor_bite": 3,
        "insulation": 9, "wind_resistance": 6, "water_resistance": 12,
        "visual": &"work_boots",
    },
    &"item.household.work_gloves": {
        "slots": [Slots.Value.HANDS],
        "armor_blunt": 4, "armor_cut": 6, "armor_bite": 2,
        "insulation": 5, "wind_resistance": 3, "water_resistance": 2,
        "visual": &"work_gloves",
    },
}

func profile(semantic_type: StringName) -> Dictionary:
    if not PROFILES.has(semantic_type):
        return {}
    return Dictionary(PROFILES[semantic_type]).duplicate(true)

func has_profile(semantic_type: StringName) -> bool:
    return PROFILES.has(semantic_type)

func allowed_slots(semantic_type: StringName) -> Array[int]:
    var result: Array[int] = []
    if PROFILES.has(semantic_type):
        for slot: Variant in Dictionary(PROFILES[semantic_type]).get("slots", []):
            result.append(int(slot))
        return result
    # Ordinary item semantics remain hand-equippable unless explicitly profiled.
    if String(semantic_type).begins_with("item."):
        result.assign([Slots.Value.PRIMARY_RIGHT, Slots.Value.SECONDARY_LEFT])
    return result

func is_allowed(semantic_type: StringName, slot: int) -> bool:
    return slot in allowed_slots(semantic_type)

func is_wearable(semantic_type: StringName) -> bool:
    for slot: int in allowed_slots(semantic_type):
        if Slots.is_worn(slot):
            return true
    return false

func armor_and_climate(semantic_type: StringName) -> Dictionary:
    var value := profile(semantic_type)
    return {
        "armor_blunt": int(value.get("armor_blunt", 0)),
        "armor_cut": int(value.get("armor_cut", 0)),
        "armor_bite": int(value.get("armor_bite", 0)),
        "insulation": int(value.get("insulation", 0)),
        "wind_resistance": int(value.get("wind_resistance", 0)),
        "water_resistance": int(value.get("water_resistance", 0)),
    }
