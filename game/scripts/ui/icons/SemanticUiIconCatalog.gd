extends RefCounted
class_name SemanticUiIconCatalog

## System 31 presentation-only semantic icon catalog.
## Mechanics supply semantic keys; this catalog supplies cached UI art only.

const ATLAS_PATH: String = "res://assets/ui_icon_atlas.svg"
const CELL_PIXELS: int = 16
const COLUMNS: int = 16
const ROWS: int = 8
const ATLAS_SIZE := Vector2i(COLUMNS * CELL_PIXELS, ROWS * CELL_PIXELS)
const DRAW_SIZE := Vector2(32, 32)

const UNKNOWN_GLYPH_KEY: StringName = &"glyph.unknown_item"
const SHELL_STATS: StringName = &"ui.shell.stats"
const SHELL_INVENTORY: StringName = &"ui.shell.inventory"
const SHELL_MENU: StringName = &"ui.shell.menu"

const GLYPH_INDICES := {
    &"glyph.unknown_item": 0,
    &"glyph.shell.stats": 1,
    &"glyph.shell.inventory": 2,
    &"glyph.shell.menu": 3,
    &"glyph.drink.water_bottle": 4,
    &"glyph.drink.soda_can": 5,
    &"glyph.drink.juice_bottle": 6,
    &"glyph.food.canned": 7,
    &"glyph.food.crackers": 8,
    &"glyph.food.cereal_box": 9,
    &"glyph.food.energy_bar": 10,
    &"glyph.food.apple": 11,
    &"glyph.food.milk_carton": 12,
    &"glyph.food.raw_meat": 13,
    &"glyph.food.berries": 14,
    &"glyph.food.bread": 15,
    &"glyph.food.cheese": 16,
    &"glyph.kitchen.can_opener": 17,
    &"glyph.kitchen.knife": 18,
    &"glyph.kitchen.frying_pan": 19,
    &"glyph.kitchen.pot": 20,
    &"glyph.kitchen.matches": 21,
    &"glyph.medical.bandage": 22,
    &"glyph.medical.disinfectant": 23,
    &"glyph.medical.pills": 24,
    &"glyph.medical.first_aid_kit": 25,
    &"glyph.tool.hammer": 26,
    &"glyph.tool.screwdriver": 27,
    &"glyph.tool.wrench": 28,
    &"glyph.tool.crowbar": 29,
    &"glyph.tool.flashlight": 30,
    &"glyph.tool.lighter": 31,
    &"glyph.farming.trowel": 32,
    &"glyph.farming.pruners": 33,
    &"glyph.farming.hoe": 34,
    &"glyph.farming.watering_can": 35,
    &"glyph.farming.seed_packet": 36,
    &"glyph.material.duct_tape": 37,
    &"glyph.material.fastener_box": 38,
    &"glyph.material.rag_bundle": 39,
    &"glyph.material.rope": 40,
    &"glyph.electrical.battery_pack": 41,
    &"glyph.household.trash_bags": 42,
    &"glyph.sanitation.soap": 43,
    &"glyph.sanitation.cleaner": 44,
    &"glyph.office.notebook": 45,
    &"glyph.office.marker": 46,
    &"glyph.clothing.gloves": 47,
    &"glyph.outdoors.tarp": 48,
    &"glyph.automotive.jumper_cables": 49,
    &"glyph.industrial.work_light": 50,
    &"glyph.junk.empty_can": 51,
    &"glyph.junk.empty_bottle": 52,
    &"glyph.junk.broken_ceramic": 53,
    &"glyph.junk.paper_trash": 54,
    &"glyph.junk.empty_medicine_bottle": 55,
    &"glyph.junk.mask": 56,
    &"glyph.junk.broken_tool": 57,
    &"glyph.junk.rusted_fasteners": 58,
    &"glyph.junk.empty_seed_packet": 59,
    &"glyph.junk.dead_battery": 60,
    &"glyph.junk.broken_pen": 61,
    &"glyph.junk.scrap_wire": 62,
    &"glyph.junk.dirty_rag": 63,
    &"glyph.junk.cracked_charger": 64,
    &"glyph.junk.broken_toy": 65,
}

const SEMANTIC_TO_GLYPH := {
    &"ui.shell.stats": &"glyph.shell.stats",
    &"ui.shell.inventory": &"glyph.shell.inventory",
    &"ui.shell.menu": &"glyph.shell.menu",

    &"item.drink.water_bottle": &"glyph.drink.water_bottle",
    &"item.drink.soda_can": &"glyph.drink.soda_can",
    &"item.drink.juice_bottle": &"glyph.drink.juice_bottle",
    &"item.food.canned_beans": &"glyph.food.canned",
    &"item.food.canned_soup": &"glyph.food.canned",
    &"item.food.crackers": &"glyph.food.crackers",
    &"item.food.cereal_box": &"glyph.food.cereal_box",
    &"item.food.energy_bar": &"glyph.food.energy_bar",
    &"item.food.apple": &"glyph.food.apple",
    &"item.food.milk_carton": &"glyph.food.milk_carton",
    &"item.food.raw_meat_package": &"glyph.food.raw_meat",
    &"item.food.fresh_berries": &"glyph.food.berries",
    &"item.food.bread_loaf": &"glyph.food.bread",
    &"item.food.cheese_block": &"glyph.food.cheese",

    &"item.kitchen.can_opener": &"glyph.kitchen.can_opener",
    &"item.kitchen.kitchen_knife": &"glyph.kitchen.knife",
    &"item.kitchen.frying_pan": &"glyph.kitchen.frying_pan",
    &"item.kitchen.cooking_pot": &"glyph.kitchen.pot",
    &"item.kitchen.matches_box": &"glyph.kitchen.matches",

    &"item.medical.bandage_roll": &"glyph.medical.bandage",
    &"item.medical.gauze_pack": &"glyph.medical.bandage",
    &"item.medical.disinfectant": &"glyph.medical.disinfectant",
    &"item.medical.painkillers": &"glyph.medical.pills",
    &"item.medical.antibiotics": &"glyph.medical.pills",
    &"item.medical.first_aid_kit": &"glyph.medical.first_aid_kit",

    &"item.tool.hammer": &"glyph.tool.hammer",
    &"item.tool.screwdriver": &"glyph.tool.screwdriver",
    &"item.tool.adjustable_wrench": &"glyph.tool.wrench",
    &"item.tool.crowbar": &"glyph.tool.crowbar",
    &"item.tool.flashlight": &"glyph.tool.flashlight",
    &"item.tool.lighter": &"glyph.tool.lighter",

    &"item.farming.hand_trowel": &"glyph.farming.trowel",
    &"item.farming.hand_pruners": &"glyph.farming.pruners",
    &"item.farming.garden_hoe": &"glyph.farming.hoe",
    &"item.farming.watering_can": &"glyph.farming.watering_can",
    &"item.farming.seed_packet": &"glyph.farming.seed_packet",

    &"item.material.duct_tape": &"glyph.material.duct_tape",
    &"item.material.nails_box": &"glyph.material.fastener_box",
    &"item.material.screws_box": &"glyph.material.fastener_box",
    &"item.material.rag_bundle": &"glyph.material.rag_bundle",
    &"item.material.rope_coil": &"glyph.material.rope",

    &"item.electrical.batteries_pack": &"glyph.electrical.battery_pack",
    &"item.household.trash_bags_roll": &"glyph.household.trash_bags",
    &"item.sanitation.soap_bar": &"glyph.sanitation.soap",
    &"item.sanitation.bleach_bottle": &"glyph.sanitation.cleaner",

    &"item.office.notebook": &"glyph.office.notebook",
    &"item.office.permanent_marker": &"glyph.office.marker",
    &"item.clothing.work_gloves": &"glyph.clothing.gloves",
    &"item.outdoors.tarp": &"glyph.outdoors.tarp",
    &"item.automotive.jumper_cables": &"glyph.automotive.jumper_cables",
    &"item.industrial.work_light": &"glyph.industrial.work_light",

    &"item.junk.empty_food_can": &"glyph.junk.empty_can",
    &"item.junk.empty_plastic_bottle": &"glyph.junk.empty_bottle",
    &"item.junk.broken_mug": &"glyph.junk.broken_ceramic",
    &"item.junk.food_wrapper": &"glyph.junk.paper_trash",
    &"item.junk.empty_medicine_bottle": &"glyph.junk.empty_medicine_bottle",
    &"item.junk.medical_packaging": &"glyph.junk.paper_trash",
    &"item.junk.disposable_mask": &"glyph.junk.mask",
    &"item.junk.broken_screwdriver": &"glyph.junk.broken_tool",
    &"item.junk.rusted_fasteners": &"glyph.junk.rusted_fasteners",
    &"item.junk.broken_plant_pot": &"glyph.junk.broken_ceramic",
    &"item.junk.empty_seed_packet": &"glyph.junk.empty_seed_packet",
    &"item.junk.dead_batteries_pack": &"glyph.junk.dead_battery",
    &"item.junk.old_receipts": &"glyph.junk.paper_trash",
    &"item.junk.broken_pen": &"glyph.junk.broken_pen",
    &"item.junk.scrap_wire": &"glyph.junk.scrap_wire",
    &"item.junk.dirty_rag": &"glyph.junk.dirty_rag",
    &"item.junk.cracked_phone_charger": &"glyph.junk.cracked_charger",
    &"item.junk.broken_toy": &"glyph.junk.broken_toy",
    &"item.junk.empty_cleaner_bottle": &"glyph.junk.empty_bottle",
    &"item.junk.worn_cardboard": &"glyph.junk.paper_trash",
}

var _atlas: Texture2D = null
var _texture_cache: Dictionary = {}

func _init() -> void:
    var loaded: Resource = load(ATLAS_PATH)
    if loaded is Texture2D:
        _atlas = loaded as Texture2D

func is_ready() -> bool:
    return _atlas != null and _mapping_contract_valid()

func has_icon(semantic_key: StringName) -> bool:
    if not SEMANTIC_TO_GLYPH.has(semantic_key):
        return false
    return GLYPH_INDICES.has(StringName(SEMANTIC_TO_GLYPH[semantic_key]))

func icon_key(semantic_key: StringName) -> StringName:
    if not SEMANTIC_TO_GLYPH.has(semantic_key):
        return UNKNOWN_GLYPH_KEY
    var glyph: StringName = StringName(SEMANTIC_TO_GLYPH[semantic_key])
    if not GLYPH_INDICES.has(glyph):
        return UNKNOWN_GLYPH_KEY
    return glyph

func texture_for(semantic_key: StringName) -> Texture2D:
    if _atlas == null:
        return null
    var glyph: StringName = icon_key(semantic_key)
    var cache_key: String = String(glyph)
    if _texture_cache.has(cache_key):
        return _texture_cache[cache_key] as Texture2D
    var region: Rect2i = _region_for_glyph(glyph)
    if region.size != Vector2i(CELL_PIXELS, CELL_PIXELS):
        return null
    var texture := AtlasTexture.new()
    texture.atlas = _atlas
    texture.region = Rect2(Vector2(region.position), Vector2(region.size))
    texture.filter_clip = true
    _texture_cache[cache_key] = texture
    return texture

func region_for(semantic_key: StringName) -> Rect2i:
    return _region_for_glyph(icon_key(semantic_key))

func known_semantics() -> Array[StringName]:
    var values: Array[String] = []
    for key: Variant in SEMANTIC_TO_GLYPH.keys():
        values.append(String(key))
    values.sort()
    var result: Array[StringName] = []
    for value: String in values:
        result.append(StringName(value))
    return result

func diagnostic_reason(semantic_key: StringName) -> String:
    if String(semantic_key).is_empty():
        return "semantic_key_empty"
    if not SEMANTIC_TO_GLYPH.has(semantic_key):
        return "semantic_icon_unmapped"
    var glyph: StringName = StringName(SEMANTIC_TO_GLYPH[semantic_key])
    if not GLYPH_INDICES.has(glyph):
        return "icon_glyph_unmapped"
    if _atlas == null:
        return "icon_atlas_unavailable"
    return ""

func cached_texture_count() -> int:
    return _texture_cache.size()

func _region_for_glyph(glyph: StringName) -> Rect2i:
    if not GLYPH_INDICES.has(glyph):
        return Rect2i()
    var index: int = int(GLYPH_INDICES[glyph])
    if index < 0 or index >= COLUMNS * ROWS:
        return Rect2i()
    var x: int = (index % COLUMNS) * CELL_PIXELS
    var y: int = (index / COLUMNS) * CELL_PIXELS
    return Rect2i(x, y, CELL_PIXELS, CELL_PIXELS)

func _mapping_contract_valid() -> bool:
    if not GLYPH_INDICES.has(UNKNOWN_GLYPH_KEY):
        return false
    for semantic: Variant in SEMANTIC_TO_GLYPH.keys():
        var glyph: StringName = StringName(SEMANTIC_TO_GLYPH[semantic])
        if not GLYPH_INDICES.has(glyph):
            return false
        var region: Rect2i = _region_for_glyph(glyph)
        if region.size != Vector2i(CELL_PIXELS, CELL_PIXELS):
            return false
        if region.position.x < 0 or region.position.y < 0 \
            or region.end.x > ATLAS_SIZE.x or region.end.y > ATLAS_SIZE.y:
            return false
    return true
