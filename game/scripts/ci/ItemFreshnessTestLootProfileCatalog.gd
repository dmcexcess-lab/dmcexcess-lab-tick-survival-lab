extends LootContainerProfileCatalog
class_name ItemFreshnessTestLootProfileCatalog

## CI-only deterministic System-24 profile: one searchable shelf, one apple.
## Production loot probabilities remain untouched.

const PROFILE_ID: StringName = &"test.freshness.apple"

func catalog_version() -> int:
    return 1

func profile(profile_id: StringName) -> Dictionary:
    if profile_id != PROFILE_ID:
        return {}
    return {
        "version": 1,
        "search_ticks": 1,
        "draw_min": 1,
        "draw_max": 1,
        "entries": [{"semantic": &"item.food.apple", "weight": 1}],
    }

func profile_ids() -> Array[StringName]:
    return [PROFILE_ID]

func validate_items(items: LootItemCatalog) -> bool:
    return items != null and items.has_item(&"item.food.apple")

func classify(_archetype_id: StringName, _role_value: String, semantic_type: StringName) -> StringName:
    return PROFILE_ID if semantic_type == &"prop.retail_shelf" else &""
