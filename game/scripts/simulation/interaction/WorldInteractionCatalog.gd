extends RefCounted
class_name WorldInteractionCatalog

## Explicit semantic capability table for practical world interaction. No renderer/art
## inference is used: generated WHAT semantics opt into concrete capabilities here.

const WATER_FIXTURES: Array[StringName] = [
    &"prop.kitchen_sink", &"prop.bathroom_vanity", &"prop.utility_sink",
]
const BEDS: Array[StringName] = [&"prop.bed_single", &"prop.bed_double"]
const CHAIRS: Array[StringName] = [&"prop.dining_chair", &"prop.armchair"]
const SOFAS: Array[StringName] = [&"prop.sofa"]
const COOKING_STOVES: Array[StringName] = [&"prop.stove_range"]

## First pass deliberately excludes current searchable-container semantics. Those need
## a later coordinated LootState/container teardown owner before deconstruction can be
## allowed without leaving orphaned search/containment truth.
const WOOD_DECONSTRUCT: Dictionary = {
    &"prop.bed_single": 2,
    &"prop.bed_double": 3,
    &"prop.dining_chair": 1,
    &"prop.armchair": 1,
    &"prop.sofa": 2,
    &"prop.breakfast_table": 2,
    &"prop.coffee_table": 1,
    &"prop.end_table": 1,
    &"prop.nightstand": 1,
    &"prop.wardrobe": 2,
    &"prop.bookshelf_tall": 2,
}

const METAL_DECONSTRUCT: Dictionary = {
    &"prop.stove_range": 2,
    &"prop.washer_front": 2,
    &"prop.dryer_front": 2,
}

const WOOD_PLANK: StringName = &"item.material.wood_plank"
const SCRAP_METAL: StringName = &"item.material.scrap_metal"

func is_door(semantic_type: StringName) -> bool:
    return String(semantic_type).begins_with("door.")

func is_window(semantic_type: StringName) -> bool:
    return String(semantic_type).begins_with("window.")

func is_water_fixture(semantic_type: StringName) -> bool:
    return WATER_FIXTURES.has(semantic_type)

func is_bed(semantic_type: StringName) -> bool:
    return BEDS.has(semantic_type)

func rest_surface(semantic_type: StringName) -> StringName:
    if BEDS.has(semantic_type):
        return &"bed"
    if SOFAS.has(semantic_type):
        return &"sofa"
    if CHAIRS.has(semantic_type):
        return &"chair"
    return &""

func is_cooking_stove(semantic_type: StringName) -> bool:
    return COOKING_STOVES.has(semantic_type)

func deconstruction_profile(semantic_type: StringName) -> Dictionary:
    if WOOD_DECONSTRUCT.has(semantic_type):
        return {
            "material_kind": &"wood",
            "tool_semantics": [&"item.tool.hammer", &"item.tool.crowbar"],
            "output_semantic": WOOD_PLANK,
            "output_count": int(WOOD_DECONSTRUCT[semantic_type]),
            "difficulty": 2,
            "base_duration_ticks": 14,
        }
    if METAL_DECONSTRUCT.has(semantic_type):
        return {
            "material_kind": &"metal",
            "tool_semantics": [&"item.tool.adjustable_wrench", &"item.tool.screwdriver"],
            "output_semantic": SCRAP_METAL,
            "output_count": int(METAL_DECONSTRUCT[semantic_type]),
            "difficulty": 3,
            "base_duration_ticks": 18,
        }
    return {}

func deconstructible(semantic_type: StringName) -> bool:
    return not deconstruction_profile(semantic_type).is_empty()
