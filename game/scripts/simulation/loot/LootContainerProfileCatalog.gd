extends RefCounted
class_name LootContainerProfileCatalog

## Candidate 001 searchable-container classification + deterministic weighted table data.
## Classification consumes only public building-plan archetype/role/semantic facts.

const CATALOG_VERSION: int = 1

var _profiles: Dictionary = {}

func _init() -> void:
    _build_profiles()

func catalog_version() -> int:
    return CATALOG_VERSION

func profile(profile_id: StringName) -> Dictionary:
    var key: String = String(profile_id)
    if not _profiles.has(key):
        return {}
    return (_profiles[key] as Dictionary).duplicate(true)

func profile_ids() -> Array[StringName]:
    var keys: Array[String] = []
    for key: Variant in _profiles.keys():
        keys.append(String(key))
    keys.sort()
    var result: Array[StringName] = []
    for key: String in keys:
        result.append(StringName(key))
    return result

func validate_items(items: LootItemCatalog) -> bool:
    if items == null:
        return false
    for profile_id: StringName in profile_ids():
        var value: Dictionary = profile(profile_id)
        if int(value.get("version", 0)) < 1 \
            or int(value.get("search_ticks", 0)) < 1 \
            or int(value.get("draw_min", -1)) < 0 \
            or int(value.get("draw_max", -1)) < int(value.get("draw_min", -1)):
            return false
        var total_weight: int = 0
        for entry_value: Variant in value.get("entries", []):
            if typeof(entry_value) != TYPE_DICTIONARY:
                return false
            var entry: Dictionary = entry_value
            var semantic: StringName = StringName(entry.get("semantic", &""))
            var weight: int = int(entry.get("weight", 0))
            if not items.has_item(semantic) or weight <= 0:
                return false
            total_weight += weight
        if total_weight <= 0:
            return false
    return true

func classify(archetype_id: StringName, role_value: String, semantic_type: StringName) -> StringName:
    var archetype: String = String(archetype_id)
    var role: String = role_value.strip_edges()
    var semantic: String = String(semantic_type)
    if archetype.is_empty() or role.is_empty() or semantic.is_empty():
        return &""

    if semantic == "prop.refrigerator_white":
        if archetype == "commercial.diner.rural_small":
            return &"commercial.diner.cold"
        if archetype in ["commercial.grocery.neighborhood", "commercial.convenience_store.small"]:
            return &"retail.cold"
        return &"household.fridge"

    if semantic == "prop.pantry":
        return &"kitchen.pantry"

    if semantic in ["prop.walkin_cooler", "prop.chest_freezer", "prop.produce_display"]:
        return &"retail.cold"

    if semantic == "prop.retail_shelf":
        match archetype:
            "commercial.convenience_store.small":
                return &"retail.convenience"
            "commercial.grocery.neighborhood":
                return &"retail.grocery"
            "commercial.pharmacy.small":
                return &"retail.pharmacy"
            "commercial.hardware_store.small":
                return &"retail.hardware"

    if semantic == "prop.medicine_cabinet":
        return &"medical.cabinet"

    if semantic == "prop.file_cabinet_tall":
        if archetype == "commercial.pharmacy.small" and role.contains("pharmacy"):
            return &"medical.stock"
        return &"office.files"

    if semantic == "prop.office_desk":
        return &"office.desk"

    if semantic == "prop.tool_cabinet":
        if archetype == "agricultural.barn.medium":
            return &"farming.storage"
        return &"tools.service"

    if semantic == "prop.warehouse_rack":
        if archetype == "commercial.diner.rural_small":
            return &"commercial.food.stock"
        if archetype in ["commercial.grocery.neighborhood", "commercial.convenience_store.small"]:
            return &"commercial.food.stock"
        if archetype == "commercial.pharmacy.small":
            return &"medical.stock"
        if archetype == "commercial.hardware_store.small":
            return &"retail.hardware"
        if archetype == "agricultural.barn.medium":
            return &"farming.storage"
        if role.contains("secure"):
            return &"industrial.secure"
        return &"industrial.stock"

    if semantic == "prop.pallet_stack":
        if archetype == "agricultural.barn.medium":
            return &"farming.storage"
        return &"industrial.stock"

    return &""

func _build_profiles() -> void:
    _add_profile(&"household.fridge", 1, 10, 0, 4, [
        _e(&"item.drink.water_bottle", 12), _e(&"item.drink.soda_can", 8),
        _e(&"item.drink.juice_bottle", 4), _e(&"item.food.apple", 7),
        _e(&"item.food.canned_soup", 3), _e(&"item.food.energy_bar", 2),
        _e(&"item.junk.empty_plastic_bottle", 5), _e(&"item.junk.food_wrapper", 4),
    ])
    _add_profile(&"kitchen.pantry", 1, 10, 0, 4, [
        _e(&"item.food.canned_beans", 10), _e(&"item.food.canned_soup", 10),
        _e(&"item.food.crackers", 7), _e(&"item.food.cereal_box", 6),
        _e(&"item.kitchen.can_opener", 3), _e(&"item.kitchen.matches_box", 3),
        _e(&"item.junk.empty_food_can", 5), _e(&"item.junk.food_wrapper", 6),
        _e(&"item.junk.broken_mug", 2),
    ])
    _add_profile(&"commercial.diner.cold", 1, 10, 1, 5, [
        _e(&"item.drink.water_bottle", 12), _e(&"item.drink.soda_can", 9),
        _e(&"item.drink.juice_bottle", 5), _e(&"item.food.apple", 6),
        _e(&"item.food.canned_soup", 4), _e(&"item.junk.empty_plastic_bottle", 2),
    ])
    _add_profile(&"commercial.food.stock", 1, 15, 1, 5, [
        _e(&"item.food.canned_beans", 12), _e(&"item.food.canned_soup", 12),
        _e(&"item.food.crackers", 8), _e(&"item.food.cereal_box", 7),
        _e(&"item.drink.water_bottle", 8), _e(&"item.material.rag_bundle", 2),
        _e(&"item.junk.worn_cardboard", 5), _e(&"item.junk.food_wrapper", 3),
    ])
    _add_profile(&"retail.convenience", 1, 12, 1, 4, [
        _e(&"item.drink.water_bottle", 10), _e(&"item.drink.soda_can", 12),
        _e(&"item.food.energy_bar", 10), _e(&"item.food.crackers", 5),
        _e(&"item.electrical.batteries_pack", 3), _e(&"item.tool.lighter", 3),
        _e(&"item.junk.food_wrapper", 5), _e(&"item.junk.empty_plastic_bottle", 3),
    ])
    _add_profile(&"retail.grocery", 1, 12, 2, 6, [
        _e(&"item.food.canned_beans", 10), _e(&"item.food.canned_soup", 10),
        _e(&"item.food.crackers", 8), _e(&"item.food.cereal_box", 8),
        _e(&"item.food.apple", 8), _e(&"item.drink.water_bottle", 8),
        _e(&"item.drink.juice_bottle", 5), _e(&"item.junk.food_wrapper", 3),
        _e(&"item.junk.worn_cardboard", 2),
    ])
    _add_profile(&"retail.cold", 1, 10, 1, 5, [
        _e(&"item.drink.water_bottle", 10), _e(&"item.drink.soda_can", 8),
        _e(&"item.drink.juice_bottle", 6), _e(&"item.food.apple", 8),
        _e(&"item.food.energy_bar", 3), _e(&"item.junk.empty_plastic_bottle", 2),
    ])
    _add_profile(&"retail.pharmacy", 1, 12, 1, 5, [
        _e(&"item.medical.bandage_roll", 10), _e(&"item.medical.gauze_pack", 8),
        _e(&"item.medical.disinfectant", 7), _e(&"item.medical.painkillers", 7),
        _e(&"item.sanitation.soap_bar", 4), _e(&"item.sanitation.bleach_bottle", 2),
        _e(&"item.electrical.batteries_pack", 2), _e(&"item.junk.empty_medicine_bottle", 3),
        _e(&"item.junk.medical_packaging", 3),
    ])
    _add_profile(&"medical.cabinet", 1, 8, 1, 4, [
        _e(&"item.medical.bandage_roll", 14), _e(&"item.medical.gauze_pack", 12),
        _e(&"item.medical.disinfectant", 10), _e(&"item.medical.painkillers", 7),
        _e(&"item.medical.antibiotics", 4), _e(&"item.medical.first_aid_kit", 2),
        _e(&"item.junk.empty_medicine_bottle", 2), _e(&"item.junk.medical_packaging", 2),
    ])
    _add_profile(&"medical.stock", 1, 15, 2, 6, [
        _e(&"item.medical.bandage_roll", 13), _e(&"item.medical.gauze_pack", 12),
        _e(&"item.medical.disinfectant", 10), _e(&"item.medical.painkillers", 8),
        _e(&"item.medical.antibiotics", 5), _e(&"item.medical.first_aid_kit", 3),
        _e(&"item.sanitation.soap_bar", 3), _e(&"item.junk.medical_packaging", 2),
    ])
    _add_profile(&"retail.hardware", 1, 12, 1, 5, [
        _e(&"item.tool.hammer", 7), _e(&"item.tool.screwdriver", 10),
        _e(&"item.tool.adjustable_wrench", 7), _e(&"item.tool.crowbar", 3),
        _e(&"item.material.duct_tape", 8), _e(&"item.material.nails_box", 9),
        _e(&"item.material.screws_box", 9), _e(&"item.electrical.batteries_pack", 3),
        _e(&"item.clothing.work_gloves", 3), _e(&"item.junk.broken_screwdriver", 2),
        _e(&"item.junk.rusted_fasteners", 3),
    ])
    _add_profile(&"tools.service", 1, 12, 1, 4, [
        _e(&"item.tool.hammer", 8), _e(&"item.tool.screwdriver", 10),
        _e(&"item.tool.adjustable_wrench", 8), _e(&"item.material.duct_tape", 7),
        _e(&"item.material.nails_box", 5), _e(&"item.material.screws_box", 5),
        _e(&"item.electrical.batteries_pack", 3), _e(&"item.junk.broken_screwdriver", 3),
        _e(&"item.junk.rusted_fasteners", 3),
    ])
    _add_profile(&"industrial.stock", 1, 15, 1, 5, [
        _e(&"item.material.duct_tape", 8), _e(&"item.material.nails_box", 8),
        _e(&"item.material.screws_box", 8), _e(&"item.material.rope_coil", 5),
        _e(&"item.tool.hammer", 5), _e(&"item.tool.adjustable_wrench", 5),
        _e(&"item.electrical.batteries_pack", 3), _e(&"item.industrial.work_light", 2),
        _e(&"item.junk.rusted_fasteners", 4), _e(&"item.junk.scrap_wire", 4),
        _e(&"item.junk.worn_cardboard", 4),
    ])
    _add_profile(&"industrial.secure", 1, 15, 2, 5, [
        _e(&"item.tool.crowbar", 5), _e(&"item.tool.adjustable_wrench", 8),
        _e(&"item.tool.hammer", 8), _e(&"item.material.duct_tape", 8),
        _e(&"item.material.rope_coil", 6), _e(&"item.electrical.batteries_pack", 5),
        _e(&"item.industrial.work_light", 4), _e(&"item.clothing.work_gloves", 4),
        _e(&"item.junk.scrap_wire", 2),
    ])
    _add_profile(&"farming.storage", 1, 12, 1, 4, [
        _e(&"item.farming.hand_trowel", 9), _e(&"item.farming.hand_pruners", 8),
        _e(&"item.farming.garden_hoe", 5), _e(&"item.farming.watering_can", 5),
        _e(&"item.farming.seed_packet", 12), _e(&"item.tool.hammer", 4),
        _e(&"item.material.rope_coil", 5), _e(&"item.junk.broken_plant_pot", 3),
        _e(&"item.junk.empty_seed_packet", 4),
    ])
    _add_profile(&"office.files", 1, 8, 0, 3, [
        _e(&"item.office.notebook", 5), _e(&"item.office.permanent_marker", 4),
        _e(&"item.electrical.batteries_pack", 2), _e(&"item.junk.old_receipts", 12),
        _e(&"item.junk.broken_pen", 8), _e(&"item.junk.worn_cardboard", 3),
    ])
    _add_profile(&"office.desk", 1, 8, 0, 3, [
        _e(&"item.office.notebook", 6), _e(&"item.office.permanent_marker", 5),
        _e(&"item.tool.flashlight", 1), _e(&"item.electrical.batteries_pack", 2),
        _e(&"item.junk.old_receipts", 10), _e(&"item.junk.broken_pen", 7),
        _e(&"item.junk.cracked_phone_charger", 2),
    ])

func _add_profile(
    profile_id: StringName,
    version: int,
    search_ticks: int,
    draw_min: int,
    draw_max: int,
    entries: Array[Dictionary]
) -> void:
    var key: String = String(profile_id)
    if key.is_empty() or version < 1 or search_ticks < 1 or draw_min < 0 or draw_max < draw_min or entries.is_empty() or _profiles.has(key):
        return
    _profiles[key] = {
        "id": profile_id,
        "version": version,
        "search_ticks": search_ticks,
        "draw_min": draw_min,
        "draw_max": draw_max,
        "entries": entries.duplicate(true),
    }

static func _e(semantic_type: StringName, weight: int) -> Dictionary:
    return {"semantic": semantic_type, "weight": weight}
