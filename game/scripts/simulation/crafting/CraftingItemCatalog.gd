extends RefCounted
class_name CraftingItemCatalog

## System 32 definitions for item semantics that enter the world through Crafting.
## These are not virgin-loot definitions; System 24 remains the owner of untouched loot.

const CATALOG_VERSION: int = 3

var _definitions: Dictionary = {}

func _init() -> void:
    _add(&"item.crafting.paper_bundle", "Paper / Cardboard Bundle", 220)
    _add(&"item.crafting.metal_scrap_bundle", "Metal Scrap Bundle", 400)
    _add(&"item.crafting.wire_salvage_bundle", "Wire / Electrical Salvage", 200)
    _add(&"item.crafting.patch_component_kit", "Patch Component Kit", 500)
    _add(&"item.crafting.improvised_toolkit", "Improvised Crafting Toolkit", 1000)
    _add(&"item.crafting.sharpened_stake", "Sharpened Wooden Stake", 520)
    _add(&"item.crafting.stone_hammer", "Improvised Stone Hammer", 1100)
    _add(&"item.crafting.paper_tinder_bundle", "Paper Tinder Bundle", 220)
    _add(&"item.crafting.heated_soup", "Heated Soup", 300)
    _add(&"item.crafting.heated_beans", "Heated Beans", 300)

func catalog_version() -> int:
    return CATALOG_VERSION

func has_item(semantic_type: StringName) -> bool:
    return _definitions.has(String(semantic_type))

func definition(semantic_type: StringName) -> Dictionary:
    var key: String = String(semantic_type)
    if not _definitions.has(key): return {}
    return (_definitions[key] as Dictionary).duplicate(true)

func semantic_types() -> Array[StringName]:
    var keys: Array[String] = []
    for key: Variant in _definitions.keys(): keys.append(String(key))
    keys.sort()
    var result: Array[StringName] = []
    for key: String in keys: result.append(StringName(key))
    return result

func label(semantic_type: StringName) -> String:
    return String(definition(semantic_type).get("label", "Unknown Crafted Item"))

func weight_grams(semantic_type: StringName) -> int:
    return int(definition(semantic_type).get("weight_grams", -1))

func register_physical_profiles(catalog: ItemPhysicalPropertyCatalog) -> bool:
    if catalog == null: return false
    for semantic_type: StringName in semantic_types():
        var weight: int = weight_grams(semantic_type)
        if weight <= 0: return false
        if catalog.has_profile(semantic_type):
            if catalog.weight_grams(semantic_type) != weight: return false
        elif not catalog.register_profile(semantic_type, weight): return false
    return true

func _add(semantic_type: StringName, label_value: String, weight: int) -> void:
    var key: String = String(semantic_type)
    if key.is_empty() or not key.begins_with("item.") or label_value.strip_edges().is_empty() or weight <= 0: return
    if _definitions.has(key): return
    _definitions[key] = {"semantic_type": semantic_type, "label": label_value.strip_edges(), "weight_grams": weight}
