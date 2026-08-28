extends SemanticUiIconCatalog
class_name CraftingSemanticUiIconCatalog

## Phase-2 additive System-31 presentation adapter. The existing semantic icon catalog
## remains authoritative for Phase-1 vocabulary; this narrow extension deliberately maps
## the System-32 output/shell semantics onto already-authored low-resolution glyphs.

const SHELL_CRAFT: StringName = &"ui.shell.craft"

const EXTRA_SEMANTIC_TO_GLYPH := {
    SHELL_CRAFT: &"glyph.tool.hammer",
    &"item.crafting.paper_bundle": &"glyph.junk.paper_trash",
    &"item.crafting.metal_scrap_bundle": &"glyph.junk.rusted_fasteners",
    &"item.crafting.wire_salvage_bundle": &"glyph.junk.scrap_wire",
    &"item.crafting.patch_component_kit": &"glyph.material.duct_tape",
    &"item.crafting.improvised_toolkit": &"glyph.tool.hammer",
}

func is_ready() -> bool:
    if not super.is_ready():
        return false
    for semantic: Variant in EXTRA_SEMANTIC_TO_GLYPH.keys():
        if region_for(StringName(semantic)).size != Vector2i(CELL_PIXELS, CELL_PIXELS):
            return false
    return true

func has_icon(semantic_key: StringName) -> bool:
    if EXTRA_SEMANTIC_TO_GLYPH.has(semantic_key):
        return GLYPH_INDICES.has(StringName(EXTRA_SEMANTIC_TO_GLYPH[semantic_key]))
    return super.has_icon(semantic_key)

func icon_key(semantic_key: StringName) -> StringName:
    if EXTRA_SEMANTIC_TO_GLYPH.has(semantic_key):
        var glyph := StringName(EXTRA_SEMANTIC_TO_GLYPH[semantic_key])
        return glyph if GLYPH_INDICES.has(glyph) else UNKNOWN_GLYPH_KEY
    return super.icon_key(semantic_key)

func known_semantics() -> Array[StringName]:
    var result: Array[StringName] = super.known_semantics()
    for semantic: Variant in EXTRA_SEMANTIC_TO_GLYPH.keys():
        var semantic_key := StringName(semantic)
        if not result.has(semantic_key):
            result.append(semantic_key)
    result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
    return result

func diagnostic_reason(semantic_key: StringName) -> String:
    if EXTRA_SEMANTIC_TO_GLYPH.has(semantic_key):
        var glyph := StringName(EXTRA_SEMANTIC_TO_GLYPH[semantic_key])
        return "" if GLYPH_INDICES.has(glyph) else "icon_glyph_unmapped"
    return super.diagnostic_reason(semantic_key)
