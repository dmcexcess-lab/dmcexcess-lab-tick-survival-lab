extends RefCounted
class_name SoundEmissionProfileCatalog

## Candidate 001 source acoustic/recognition vocabulary. Budgets are gameplay
## acoustic units, deliberately not calibrated decibels. Player-facing labels
## prefer readable onomatopoeia once the listener recognizes the sound well
## enough; vague tiers stay deliberately broad rather than guessing.

const WALK_STEP: StringName = &"movement.walk_step"
const RUN_STRIDE: StringName = &"movement.run_stride"
const DOOR_NORMAL: StringName = &"door.normal"
const DOOR_LOUD: StringName = &"door.loud"
const TEST_IMPACT: StringName = &"test.impact"

const DOMAIN_SURVIVAL: StringName = &"survival"
const DOMAIN_TECHNICAL: StringName = &"technical"
const DOMAIN_COMBAT: StringName = &"combat"

const _PROFILES := {
    "movement.walk_step": {
        "power": 120,
        "category": "movement",
        "unknown_word": "NOISE",
        "broad_word": "*scuff*",
        "specific_word": "*step step*",
        "recognition_difficulty": 48,
        "domain_skill": "survival",
        "cue_lifetime_ticks": 30,
    },
    "movement.run_stride": {
        "power": 200,
        "category": "movement",
        "unknown_word": "NOISE",
        "broad_word": "*thump thump*",
        "specific_word": "*step step step*",
        "recognition_difficulty": 38,
        "domain_skill": "survival",
        "cue_lifetime_ticks": 35,
    },
    "door.normal": {
        "power": 180,
        "category": "impact",
        "unknown_word": "NOISE",
        "broad_word": "*thunk*",
        "specific_word": "*creak*",
        "recognition_difficulty": 45,
        "domain_skill": "survival",
        "cue_lifetime_ticks": 35,
    },
    "door.loud": {
        "power": 240,
        "category": "impact",
        "unknown_word": "NOISE",
        "broad_word": "*BANG*",
        "specific_word": "*SLAM*",
        "recognition_difficulty": 35,
        "domain_skill": "survival",
        "cue_lifetime_ticks": 40,
    },
    "test.impact": {
        "power": 320,
        "category": "impact",
        "unknown_word": "NOISE",
        "broad_word": "*thud*",
        "specific_word": "*THUD*",
        "recognition_difficulty": 40,
        "domain_skill": "survival",
        "cue_lifetime_ticks": 35,
    },
}

func has_profile(profile_id: StringName) -> bool:
    return _PROFILES.has(String(profile_id))

func profile(profile_id: StringName) -> Dictionary:
    var key: String = String(profile_id)
    if not _PROFILES.has(key):
        return {}
    return (_PROFILES[key] as Dictionary).duplicate(true)

func power(profile_id: StringName) -> int:
    return int(profile(profile_id).get("power", 0))

func category(profile_id: StringName) -> StringName:
    return StringName(String(profile(profile_id).get("category", "")))

func cue_lifetime_ticks(profile_id: StringName) -> int:
    return int(profile(profile_id).get("cue_lifetime_ticks", 0))

func recognition_word(profile_id: StringName, tier: int) -> String:
    var data: Dictionary = profile(profile_id)
    if data.is_empty():
        return ""
    if tier >= 2:
        return String(data.get("specific_word", "NOISE"))
    if tier == 1:
        return String(data.get("broad_word", "NOISE"))
    return String(data.get("unknown_word", "NOISE"))

func recognition_difficulty(profile_id: StringName) -> int:
    return int(profile(profile_id).get("recognition_difficulty", 100))

func domain_skill(profile_id: StringName) -> StringName:
    return StringName(String(profile(profile_id).get("domain_skill", "")))

func profile_ids() -> Array[StringName]:
    var result: Array[StringName] = []
    for key: Variant in _PROFILES.keys():
        result.append(StringName(String(key)))
    result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
    return result

func is_valid() -> bool:
    for profile_id: StringName in profile_ids():
        var data: Dictionary = profile(profile_id)
        if int(data.get("power", 0)) <= 0:
            return false
        if String(data.get("category", "")).strip_edges().is_empty():
            return false
        if String(data.get("unknown_word", "")).strip_edges().is_empty():
            return false
        if String(data.get("broad_word", "")).strip_edges().is_empty():
            return false
        if String(data.get("specific_word", "")).strip_edges().is_empty():
            return false
        if int(data.get("cue_lifetime_ticks", 0)) <= 0:
            return false
    return true
