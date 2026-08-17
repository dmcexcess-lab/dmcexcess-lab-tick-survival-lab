extends RefCounted
class_name ActorSkillCatalog

## 13C canonical v1 semantic survivor skill catalog and progression policy.

const COMBAT: StringName = &"combat"
const SCAVENGING: StringName = &"scavenging"
const SURVIVAL: StringName = &"survival"
const MEDICAL: StringName = &"medical"
const TECHNICAL: StringName = &"technical"
const SOCIAL: StringName = &"social"

const LEVEL_MIN: int = 0
const LEVEL_MAX: int = 10

static func skill_ids() -> Array[StringName]:
    return [COMBAT, SCAVENGING, SURVIVAL, MEDICAL, TECHNICAL, SOCIAL]

static func is_valid(skill_id: StringName) -> bool:
    return (
        skill_id == COMBAT
        or skill_id == SCAVENGING
        or skill_id == SURVIVAL
        or skill_id == MEDICAL
        or skill_id == TECHNICAL
        or skill_id == SOCIAL
    )

static func display_name(skill_id: StringName) -> String:
    if skill_id == COMBAT:
        return "Combat"
    if skill_id == SCAVENGING:
        return "Scavenging"
    if skill_id == SURVIVAL:
        return "Survival"
    if skill_id == MEDICAL:
        return "Medical"
    if skill_id == TECHNICAL:
        return "Technical"
    if skill_id == SOCIAL:
        return "Social"
    return ""

static func next_level_xp(level: int) -> int:
    if level < LEVEL_MIN or level >= LEVEL_MAX:
        return 0
    return 20 + level * 15

static func is_valid_level(level: int) -> bool:
    return level >= LEVEL_MIN and level <= LEVEL_MAX
