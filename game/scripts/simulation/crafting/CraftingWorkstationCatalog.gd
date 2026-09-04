extends RefCounted
class_name CraftingWorkstationCatalog

## Explicit world-object capability catalog. Capability is never inferred from art,
## collision, semantic substrings, building purpose, or proximity.

const CATALOG_VERSION: int = 2
const GENERAL_WORKBENCH: StringName = &"crafting.workbench.general"
const COOKING_STOVE: StringName = &"crafting.cooking.stove"

const SEMANTIC_CAPABILITIES := {
    &"prop.workbench_heavy": [GENERAL_WORKBENCH],
    &"prop.stove_range": [COOKING_STOVE],
}

func catalog_version() -> int:
    return CATALOG_VERSION

func capabilities_for_semantic(semantic_type: StringName) -> Array[StringName]:
    var result: Array[StringName] = []
    if not SEMANTIC_CAPABILITIES.has(semantic_type): return result
    for value: Variant in SEMANTIC_CAPABILITIES[semantic_type]: result.append(StringName(value))
    return result

func supports(semantic_type: StringName, capability: StringName) -> bool:
    if String(capability).strip_edges().is_empty(): return false
    return capabilities_for_semantic(semantic_type).has(capability)

static func display_label(capability: StringName) -> String:
    match capability:
        GENERAL_WORKBENCH:
            return "General Workbench"
        COOKING_STOVE:
            return "Cooking Stove"
        _:
            return "Workstation"

func known_semantics() -> Array[StringName]:
    var keys: Array[String] = []
    for key: Variant in SEMANTIC_CAPABILITIES.keys(): keys.append(String(key))
    keys.sort()
    var result: Array[StringName] = []
    for key: String in keys: result.append(StringName(key))
    return result
