extends SceneTree

const IconCatalogClass = preload("res://scripts/ui/icons/CraftingSemanticUiIconCatalog.gd")
const LootItemCatalogClass = preload("res://scripts/simulation/loot/LootItemCatalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var icons := IconCatalogClass.new()
    var loot := LootItemCatalogClass.new()

    _check(icons.is_ready(), "current semantic icon catalog loads the atlas and validates mappings")
    _check(loot.semantic_types().size() == 108, "current loot catalog exposes the expected 108 semantics")
    _check(icons.known_semantics().size() == 120, "current icon catalog explicitly maps Phase-1, primitive resource, crafting output, apparel, and shell semantics")

    for shell_key: StringName in [IconCatalogClass.SHELL_STATS, IconCatalogClass.SHELL_INVENTORY, IconCatalogClass.SHELL_MENU, IconCatalogClass.SHELL_CRAFT]:
        _check(icons.has_icon(shell_key), "shell icon is explicitly mapped: %s" % String(shell_key))
        _check(icons.diagnostic_reason(shell_key).is_empty(), "shell icon has no diagnostic: %s" % String(shell_key))
        _check(_region_valid(icons.region_for(shell_key)), "shell icon region is inside the atlas: %s" % String(shell_key))
        _check(icons.texture_for(shell_key) != null, "shell icon texture resolves: %s" % String(shell_key))

    for semantic: StringName in loot.semantic_types():
        _check(icons.has_icon(semantic), "current loot semantic has explicit icon mapping: %s" % String(semantic))
        _check(icons.diagnostic_reason(semantic).is_empty(), "mapped loot semantic has no diagnostic: %s" % String(semantic))
        _check(_region_valid(icons.region_for(semantic)), "mapped loot semantic region is inside the atlas: %s" % String(semantic))
        _check(icons.texture_for(semantic) != null, "mapped loot semantic texture resolves: %s" % String(semantic))

    for primitive_semantic: StringName in [&"item.outdoors.sturdy_stick", &"item.outdoors.smooth_stone", &"item.junk.old_magazine"]:
        _check(icons.has_icon(primitive_semantic), "primitive Survival resource has an explicit icon mapping: %s" % String(primitive_semantic))
    for crafted_semantic: StringName in [&"item.crafting.sharpened_stake", &"item.crafting.stone_hammer", &"item.crafting.paper_tinder_bundle"]:
        _check(icons.has_icon(crafted_semantic), "primitive crafted output has an explicit icon mapping: %s" % String(crafted_semantic))
    for apparel_semantic: StringName in [&"item.clothing.baseball_cap", &"item.clothing.t_shirt", &"item.clothing.hoodie", &"item.clothing.work_jacket", &"item.clothing.jeans", &"item.clothing.cargo_pants", &"item.clothing.sneakers", &"item.clothing.work_boots"]:
        _check(icons.has_icon(apparel_semantic), "new apparel semantic has an explicit icon mapping: %s" % String(apparel_semantic))

    _check(icons.icon_key(&"item.food.canned_beans") == icons.icon_key(&"item.food.canned_soup"), "canned foods intentionally share one explicit glyph")
    _check(icons.icon_key(&"item.material.nails_box") == icons.icon_key(&"item.material.screws_box"), "fastener boxes intentionally share one explicit glyph")
    _check(icons.icon_key(&"item.drink.water_bottle") != icons.icon_key(&"item.drink.soda_can"), "distinct drink shapes do not collapse through a family fallback")

    var unknown: StringName = &"item.future.unmapped_test"
    _check(not icons.has_icon(unknown), "unknown future semantic is not falsely reported as covered")
    _check(icons.icon_key(unknown) == IconCatalogClass.UNKNOWN_GLYPH_KEY, "unknown future semantic resolves to the explicit unknown glyph")
    _check(icons.diagnostic_reason(unknown) == "semantic_icon_unmapped", "unknown future semantic exposes an honest diagnostic")
    _check(icons.texture_for(unknown) != null, "unknown future semantic still has a visible fallback texture")

    var before_cache: int = icons.cached_texture_count()
    var first: Texture2D = icons.texture_for(&"item.tool.hammer")
    var after_first: int = icons.cached_texture_count()
    var second: Texture2D = icons.texture_for(&"item.tool.hammer")
    _check(first != null and first == second, "repeated requests reuse the same cached AtlasTexture")
    _check(after_first >= before_cache and icons.cached_texture_count() == after_first, "repeated glyph lookup does not grow the texture cache")

    if failures.is_empty():
        print("SEMANTIC_UI_ICONS_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("SEMANTIC_UI_ICONS_SMOKE_FAIL: %s" % failure)
    quit(1)

func _region_valid(region: Rect2i) -> bool:
    return region.size == Vector2i(IconCatalogClass.CELL_PIXELS, IconCatalogClass.CELL_PIXELS) \
        and region.position.x >= 0 and region.position.y >= 0 \
        and region.end.x <= IconCatalogClass.ATLAS_SIZE.x \
        and region.end.y <= IconCatalogClass.ATLAS_SIZE.y

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
