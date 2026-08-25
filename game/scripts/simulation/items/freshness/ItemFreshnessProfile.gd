extends RefCounted
class_name ItemFreshnessProfile

## Type-level freshness definition. Runtime aging remains integer tick arithmetic.

var semantic_type: StringName = &""
var ambient_lifetime_ticks: int = 0
var virgin_initial_age_max_permille: int = 0
var profile_version: int = 1

func _init(
    semantic_type_value: StringName = &"",
    ambient_lifetime_ticks_value: int = 0,
    virgin_initial_age_max_permille_value: int = 0,
    profile_version_value: int = 1
) -> void:
    semantic_type = semantic_type_value
    ambient_lifetime_ticks = ambient_lifetime_ticks_value
    virgin_initial_age_max_permille = virgin_initial_age_max_permille_value
    profile_version = profile_version_value

func is_valid() -> bool:
    var semantic: String = String(semantic_type)
    return semantic.begins_with("item.") and semantic.length() > 5 \
        and ambient_lifetime_ticks > 0 \
        and virgin_initial_age_max_permille >= 0 \
        and virgin_initial_age_max_permille <= 1000 \
        and profile_version > 0

func copy() -> ItemFreshnessProfile:
    return ItemFreshnessProfile.new(
        semantic_type,
        ambient_lifetime_ticks,
        virgin_initial_age_max_permille,
        profile_version
    )
