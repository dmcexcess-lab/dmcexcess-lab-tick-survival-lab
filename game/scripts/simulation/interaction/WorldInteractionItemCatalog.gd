extends RefCounted
class_name WorldInteractionItemCatalog

## Real materials created by world deconstruction rather than virgin loot generation.

const DEFINITIONS := {
    &"item.material.wood_plank": {"label": "Reclaimed Wood Plank", "weight_grams": 2200},
    &"item.material.scrap_metal": {"label": "Reclaimed Scrap Metal", "weight_grams": 1800},
}

static func register_physical_profiles(catalog: ItemPhysicalPropertyCatalog) -> bool:
    if catalog == null: return false
    for semantic: Variant in DEFINITIONS.keys():
        var semantic_type: StringName = semantic
        var weight: int = int((DEFINITIONS[semantic_type] as Dictionary).get("weight_grams", 0))
        if weight <= 0: return false
        if catalog.has_profile(semantic_type):
            if catalog.weight_grams(semantic_type) != weight: return false
        elif not catalog.register_profile(semantic_type, weight):
            return false
    return true

static func label(semantic_type: StringName) -> String:
    return String((DEFINITIONS.get(semantic_type, {}) as Dictionary).get("label", String(semantic_type)))
