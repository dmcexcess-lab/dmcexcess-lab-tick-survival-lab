extends RefCounted
class_name ActorSkillCatalog

## 13C canonical survivor skill catalog and shared progression policy.
## Broad skills are deliberate: concrete tools/materials define the physical action;
## the skill describes the survivor competence applied to that real action.

const AWARENESS: StringName = &"awareness"
const STEALTH: StringName = &"stealth"
const MECHANICAL: StringName = &"mechanical"
const SURVIVAL: StringName = &"survival"

const LEVEL_MIN: int = 0
const LEVEL_MAX: int = 10
const DIFFICULTY_MIN: int = 1
const DIFFICULTY_MAX: int = 10

static func skill_ids() -> Array[StringName]:
    return [AWARENESS, STEALTH, MECHANICAL, SURVIVAL]

static func is_valid(skill_id: StringName) -> bool:
    return (
        skill_id == AWARENESS
        or skill_id == STEALTH
        or skill_id == MECHANICAL
        or skill_id == SURVIVAL
    )

static func display_name(skill_id: StringName) -> String:
    if skill_id == AWARENESS:
        return "Awareness"
    if skill_id == STEALTH:
        return "Stealth"
    if skill_id == MECHANICAL:
        return "Mechanical"
    if skill_id == SURVIVAL:
        return "Survival"
    return ""

static func next_level_xp(level: int) -> int:
    if level < LEVEL_MIN or level >= LEVEL_MAX:
        return 0
    return 20 + level * 15

static func is_valid_level(level: int) -> bool:
    return level >= LEVEL_MIN and level <= LEVEL_MAX

static func is_valid_difficulty(difficulty: int) -> bool:
    return difficulty >= DIFFICULTY_MIN and difficulty <= DIFFICULTY_MAX
