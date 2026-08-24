extends RefCounted
class_name HearingProfileProvider

## Neutral listener-hearing contract. Species/traits/stats adapters may replace
## this provider without changing propagation or observation semantics.

func is_ready() -> bool:
    return true

func profile(_actor_id: String) -> Dictionary:
    return {
        "hearing_score": 50,
        "detection_threshold": 40,
        "known": false,
    }

func domain_level(_actor_id: String, _skill_id: StringName) -> int:
    return 0
