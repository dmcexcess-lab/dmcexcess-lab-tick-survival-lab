extends RefCounted
class_name CraftingRecipeCatalog

const RecipeClass = preload("res://scripts/simulation/crafting/CraftingRecipe.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")

## Static Candidate-001 transformation vocabulary. Recipes describe real item semantics,
## concrete tools/materials, and the broad skill applied to them; current item identity
## and legality remain resolved by CraftingPlanQuery.

const CATALOG_VERSION: int = 2

var _recipes: Dictionary = {}

func _init() -> void:
    _add(RecipeClass.new(
        &"crafting.paper_bundle",
        "Bundle Paper / Cardboard",
        8,
        [
            RecipeClass.requirement(&"item.junk.stale_newspaper"),
            RecipeClass.requirement(&"item.junk.worn_cardboard"),
        ],
        [RecipeClass.requirement(&"item.office.scissors")],
        &"",
        [RecipeClass.requirement(&"item.crafting.paper_bundle")],
        SkillCatalog.SURVIVAL,
        1
    ))
    _add(RecipeClass.new(
        &"crafting.metal_scrap_bundle",
        "Sort Metal Scrap",
        12,
        [
            RecipeClass.requirement(&"item.junk.rusted_fasteners"),
            RecipeClass.requirement(&"item.junk.broken_screwdriver"),
        ],
        [RecipeClass.requirement(&"item.tool.hammer")],
        &"",
        [RecipeClass.requirement(&"item.crafting.metal_scrap_bundle")],
        SkillCatalog.MECHANICAL,
        2
    ))
    _add(RecipeClass.new(
        &"crafting.wire_salvage_bundle",
        "Strip Wire Salvage",
        10,
        [
            RecipeClass.requirement(&"item.junk.scrap_wire"),
            RecipeClass.requirement(&"item.junk.cracked_phone_charger"),
        ],
        [RecipeClass.requirement(&"item.tool.pliers")],
        &"",
        [RecipeClass.requirement(&"item.crafting.wire_salvage_bundle")],
        SkillCatalog.MECHANICAL,
        3
    ))
    _add(RecipeClass.new(
        &"crafting.patch_component_kit",
        "Make Patch Components",
        10,
        [
            RecipeClass.requirement(&"item.material.rag_bundle"),
            RecipeClass.requirement(&"item.material.duct_tape"),
        ],
        [RecipeClass.requirement(&"item.office.scissors")],
        &"",
        [RecipeClass.requirement(&"item.crafting.patch_component_kit")],
        SkillCatalog.SURVIVAL,
        2
    ))
    _add(RecipeClass.new(
        &"crafting.improvised_toolkit",
        "Assemble Improvised Toolkit",
        24,
        [
            RecipeClass.requirement(&"item.crafting.metal_scrap_bundle"),
            RecipeClass.requirement(&"item.crafting.wire_salvage_bundle"),
            RecipeClass.requirement(&"item.crafting.patch_component_kit"),
            RecipeClass.requirement(&"item.material.screws_box"),
        ],
        [
            RecipeClass.requirement(&"item.tool.hammer"),
            RecipeClass.requirement(&"item.tool.screwdriver"),
        ],
        &"crafting.workbench.general",
        [RecipeClass.requirement(&"item.crafting.improvised_toolkit")],
        SkillCatalog.MECHANICAL,
        5
    ))

func catalog_version() -> int:
    return CATALOG_VERSION

func has_recipe(recipe_id: StringName) -> bool:
    return _recipes.has(String(recipe_id))

func recipe(recipe_id: StringName) -> CraftingRecipe:
    var key: String = String(recipe_id)
    if not _recipes.has(key):
        return null
    return (_recipes[key] as CraftingRecipe).copy()

func recipe_ids() -> Array[StringName]:
    var keys: Array[String] = []
    for key: Variant in _recipes.keys():
        keys.append(String(key))
    keys.sort()
    var result: Array[StringName] = []
    for key: String in keys:
        result.append(StringName(key))
    return result

func _add(candidate: CraftingRecipe) -> void:
    if candidate == null or not candidate.is_valid():
        return
    var key: String = String(candidate.recipe_id)
    if _recipes.has(key):
        return
    _recipes[key] = candidate.copy()
