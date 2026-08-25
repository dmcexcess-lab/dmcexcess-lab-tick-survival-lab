extends RefCounted
class_name LootItemCatalog

## Semantic loot-definition content. Classification is type-level data, never mutable
## per-item state. Every loot item has exactly one top-level utility class, one primary
## family, optional secondary tags, a readable label, and real 13D weight.

const CATALOG_VERSION: int = 2
const USABLE: StringName = &"USABLE"
const JUNK: StringName = &"JUNK"

var _definitions: Dictionary = {}

func _init() -> void:
    _build_candidate_001()

func catalog_version() -> int:
    return CATALOG_VERSION

func has_item(semantic_type: StringName) -> bool:
    return _definitions.has(String(semantic_type))

func definition(semantic_type: StringName) -> Dictionary:
    var key: String = String(semantic_type)
    if not _definitions.has(key):
        return {}
    return (_definitions[key] as Dictionary).duplicate(true)

func semantic_types() -> Array[StringName]:
    var keys: Array[String] = []
    for key: Variant in _definitions.keys():
        keys.append(String(key))
    keys.sort()
    var result: Array[StringName] = []
    for key: String in keys:
        result.append(StringName(key))
    return result

func weight_grams(semantic_type: StringName) -> int:
    return int(definition(semantic_type).get("weight_grams", -1))

func utility_class(semantic_type: StringName) -> StringName:
    return StringName(definition(semantic_type).get("utility_class", &""))

func family(semantic_type: StringName) -> StringName:
    return StringName(definition(semantic_type).get("family", &""))

func register_physical_profiles(catalog: ItemPhysicalPropertyCatalog) -> bool:
    if catalog == null:
        return false
    for semantic_type: StringName in semantic_types():
        var weight: int = weight_grams(semantic_type)
        if weight <= 0:
            return false
        if catalog.has_profile(semantic_type):
            if catalog.weight_grams(semantic_type) != weight:
                return false
        elif not catalog.register_profile(semantic_type, weight):
            return false
    return true

func _add(
    semantic_type: StringName,
    label: String,
    utility: StringName,
    family_value: StringName,
    weight: int,
    tags: Array[StringName] = []
) -> void:
    var key: String = String(semantic_type)
    if key.is_empty() or not key.begins_with("item.") or label.strip_edges().is_empty():
        return
    if utility != USABLE and utility != JUNK:
        return
    if String(family_value).is_empty() or weight <= 0 or _definitions.has(key):
        return
    _definitions[key] = {
        "semantic_type": semantic_type,
        "label": label,
        "utility_class": utility,
        "family": family_value,
        "tags": tags.duplicate(),
        "weight_grams": weight,
    }

func _build_candidate_001() -> void:
    # Food / drink.
    _add(&"item.drink.water_bottle", "Water Bottle", USABLE, &"drink", 550, [&"hydration"])
    _add(&"item.drink.soda_can", "Soda Can", USABLE, &"drink", 370)
    _add(&"item.drink.juice_bottle", "Juice Bottle", USABLE, &"drink", 1100)
    _add(&"item.food.canned_beans", "Canned Beans", USABLE, &"food", 420, [&"canned"])
    _add(&"item.food.canned_soup", "Canned Soup", USABLE, &"food", 450, [&"canned"])
    _add(&"item.food.crackers", "Crackers", USABLE, &"food", 250)
    _add(&"item.food.cereal_box", "Cereal Box", USABLE, &"food", 500)
    _add(&"item.food.energy_bar", "Energy Bar", USABLE, &"food", 70)
    _add(&"item.food.apple", "Apple", USABLE, &"food", 180, [&"fresh_food"])
    _add(&"item.food.milk_carton", "Milk Carton", USABLE, &"food", 1050, [&"fresh_food", &"dairy"])
    _add(&"item.food.raw_meat_package", "Raw Meat Package", USABLE, &"food", 650, [&"fresh_food", &"raw"])
    _add(&"item.food.fresh_berries", "Fresh Berries", USABLE, &"food", 250, [&"fresh_food", &"produce"])
    _add(&"item.food.bread_loaf", "Bread Loaf", USABLE, &"food", 500, [&"fresh_food"])
    _add(&"item.food.cheese_block", "Cheese Block", USABLE, &"food", 450, [&"fresh_food", &"dairy"])

    # Kitchen.
    _add(&"item.kitchen.can_opener", "Can Opener", USABLE, &"kitchen", 120, [&"hand_tool"])
    _add(&"item.kitchen.kitchen_knife", "Kitchen Knife", USABLE, &"kitchen", 250, [&"blade"])
    _add(&"item.kitchen.frying_pan", "Frying Pan", USABLE, &"kitchen", 900)
    _add(&"item.kitchen.cooking_pot", "Cooking Pot", USABLE, &"kitchen", 1200)
    _add(&"item.kitchen.matches_box", "Box of Matches", USABLE, &"kitchen", 40, [&"fire_starting"])

    # Medical.
    _add(&"item.medical.bandage_roll", "Bandage Roll", USABLE, &"medical", 60, [&"first_aid"])
    _add(&"item.medical.gauze_pack", "Gauze Pack", USABLE, &"medical", 100, [&"first_aid"])
    _add(&"item.medical.disinfectant", "Disinfectant", USABLE, &"medical", 300, [&"first_aid"])
    _add(&"item.medical.painkillers", "Painkillers", USABLE, &"medical", 50)
    _add(&"item.medical.antibiotics", "Antibiotics", USABLE, &"medical", 40)
    _add(&"item.medical.first_aid_kit", "First Aid Kit", USABLE, &"medical", 700, [&"first_aid"])

    # Tools.
    _add(&"item.tool.hammer", "Hammer", USABLE, &"tools", 900, [&"hand_tool"])
    _add(&"item.tool.screwdriver", "Screwdriver", USABLE, &"tools", 180, [&"hand_tool"])
    _add(&"item.tool.adjustable_wrench", "Adjustable Wrench", USABLE, &"tools", 600, [&"hand_tool"])
    _add(&"item.tool.crowbar", "Crowbar", USABLE, &"tools", 2200, [&"hand_tool"])
    _add(&"item.tool.flashlight", "Flashlight", USABLE, &"tools", 250, [&"electronic"])
    _add(&"item.tool.lighter", "Lighter", USABLE, &"tools", 40, [&"fire_starting"])

    # Farming / rural.
    _add(&"item.farming.hand_trowel", "Hand Trowel", USABLE, &"farming", 350, [&"garden_tool"])
    _add(&"item.farming.hand_pruners", "Hand Pruners", USABLE, &"farming", 280, [&"garden_tool"])
    _add(&"item.farming.garden_hoe", "Garden Hoe", USABLE, &"farming", 1400, [&"garden_tool"])
    _add(&"item.farming.watering_can", "Watering Can", USABLE, &"farming", 700, [&"garden_tool"])
    _add(&"item.farming.seed_packet", "Seed Packet", USABLE, &"farming", 30)

    # Construction / material.
    _add(&"item.material.duct_tape", "Duct Tape", USABLE, &"construction", 250)
    _add(&"item.material.nails_box", "Box of Nails", USABLE, &"construction", 500, [&"fastener"])
    _add(&"item.material.screws_box", "Box of Screws", USABLE, &"construction", 450, [&"fastener"])
    _add(&"item.material.rag_bundle", "Rag Bundle", USABLE, &"construction", 300)
    _add(&"item.material.rope_coil", "Rope Coil", USABLE, &"construction", 1200)

    # Electrical / household / sanitation.
    _add(&"item.electrical.batteries_pack", "Battery Pack", USABLE, &"electrical", 180, [&"electronic"])
    _add(&"item.household.trash_bags_roll", "Trash Bag Roll", USABLE, &"household", 250)
    _add(&"item.sanitation.soap_bar", "Bar of Soap", USABLE, &"sanitation", 120, [&"cleaning"])
    _add(&"item.sanitation.bleach_bottle", "Bleach Bottle", USABLE, &"sanitation", 1200, [&"cleaning"])

    # Small first-pass families whose consuming systems arrive later.
    _add(&"item.office.notebook", "Notebook", USABLE, &"office", 250, [&"paper"])
    _add(&"item.office.permanent_marker", "Permanent Marker", USABLE, &"office", 25)
    _add(&"item.clothing.work_gloves", "Work Gloves", USABLE, &"clothing", 180)
    _add(&"item.outdoors.tarp", "Tarp", USABLE, &"outdoors", 1200)
    _add(&"item.automotive.jumper_cables", "Jumper Cables", USABLE, &"automotive", 1200)
    _add(&"item.industrial.work_light", "Portable Work Light", USABLE, &"industrial", 1500, [&"electronic"])

    # Junk remains physical, persistent loot with real weight.
    _add(&"item.junk.empty_food_can", "Empty Food Can", JUNK, &"kitchen", 35)
    _add(&"item.junk.empty_plastic_bottle", "Empty Plastic Bottle", JUNK, &"kitchen", 25)
    _add(&"item.junk.broken_mug", "Broken Mug", JUNK, &"kitchen", 180)
    _add(&"item.junk.food_wrapper", "Food Wrapper", JUNK, &"kitchen", 10)
    _add(&"item.junk.empty_medicine_bottle", "Empty Medicine Bottle", JUNK, &"medical", 20)
    _add(&"item.junk.medical_packaging", "Medical Packaging", JUNK, &"medical", 15)
    _add(&"item.junk.disposable_mask", "Used Disposable Mask", JUNK, &"medical", 5)
    _add(&"item.junk.broken_screwdriver", "Broken Screwdriver", JUNK, &"tools", 160)
    _add(&"item.junk.rusted_fasteners", "Rusted Fasteners", JUNK, &"construction", 300, [&"fastener"])
    _add(&"item.junk.broken_plant_pot", "Broken Plant Pot", JUNK, &"farming", 500)
    _add(&"item.junk.empty_seed_packet", "Empty Seed Packet", JUNK, &"farming", 10, [&"paper"])
    _add(&"item.junk.dead_batteries_pack", "Dead Battery Pack", JUNK, &"electrical", 160, [&"electronic"])
    _add(&"item.junk.old_receipts", "Old Receipts", JUNK, &"office", 20, [&"paper"])
    _add(&"item.junk.broken_pen", "Broken Pen", JUNK, &"office", 10)
    _add(&"item.junk.scrap_wire", "Scrap Wire", JUNK, &"electrical", 150)
    _add(&"item.junk.dirty_rag", "Dirty Rag", JUNK, &"sanitation", 100, [&"cleaning"])
    _add(&"item.junk.cracked_phone_charger", "Cracked Phone Charger", JUNK, &"electrical", 90, [&"electronic"])
    _add(&"item.junk.broken_toy", "Broken Toy", JUNK, &"recreational", 200)
    _add(&"item.junk.empty_cleaner_bottle", "Empty Cleaner Bottle", JUNK, &"sanitation", 80, [&"cleaning"])
    _add(&"item.junk.worn_cardboard", "Worn Cardboard", JUNK, &"misc", 100)
