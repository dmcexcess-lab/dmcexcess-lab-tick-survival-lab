extends RefCounted
class_name ActorSkillCheckService

const Catalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")

## Shared bounded action-boundary competence contract.
## This service owns no timers, items, targets, or alternate truth. Action owners supply
## their real physical requirements, then ask this service only for competence effects.

var _skills: ActorSkillState = null

func _init(skill_state: ActorSkillState = null) -> void:
    _skills = skill_state

func is_ready() -> bool:
    return _skills != null

func action_profile(actor_id: String, skill_id: StringName, base_duration_ticks: int, difficulty: int) -> Dictionary:
    if not is_ready() or base_duration_ticks < 1 or not Catalog.is_valid(skill_id) or not Catalog.is_valid_difficulty(difficulty):
        return _failure("skill_profile_invalid")
    var skill_level: int = _skills.level(actor_id, skill_id)
    if not Catalog.is_valid_level(skill_level):
        return _failure("skill_actor_unclassified")
    var duration_percent: int = clampi(140 + difficulty * 6 - skill_level * 7, 60, 180)
    var duration_ticks: int = maxi(1, ceili(float(base_duration_ticks * duration_percent) / 100.0))
    return {
        "ok": true,
        "reason": "",
        "skill_id": skill_id,
        "skill_level": skill_level,
        "difficulty": difficulty,
        "base_duration_ticks": base_duration_ticks,
        "duration_ticks": duration_ticks,
        "duration_percent": duration_percent,
        "success_chance_percent": _success_chance(skill_level, difficulty),
        "effectiveness_percent": _effectiveness(skill_level, difficulty),
    }

func resolve_attempt(
    actor_id: String,
    skill_id: StringName,
    difficulty: int,
    action_serial: int,
    context_key: StringName,
    captured_level: int = -1
) -> Dictionary:
    if not is_ready() or action_serial < 1 or String(context_key).is_empty() \
        or not Catalog.is_valid(skill_id) or not Catalog.is_valid_difficulty(difficulty):
        return _failure("skill_attempt_invalid")
    if not _skills.has_actor(actor_id):
        return _failure("skill_actor_unclassified")
    var skill_level: int = _skills.level(actor_id, skill_id) if captured_level < 0 else captured_level
    if not Catalog.is_valid_level(skill_level):
        return _failure("skill_level_invalid")
    var chance: int = _success_chance(skill_level, difficulty)
    var roll: int = _stable_roll(actor_id, skill_id, difficulty, action_serial, context_key)
    var succeeded: bool = roll <= chance
    var effectiveness: int = _effectiveness(skill_level, difficulty)
    if not succeeded:
        effectiveness = maxi(25, effectiveness - 25)
    return {
        "ok": true,
        "reason": "",
        "skill_id": skill_id,
        "skill_level": skill_level,
        "difficulty": difficulty,
        "roll": roll,
        "success_chance_percent": chance,
        "success": succeeded,
        "effectiveness_percent": effectiveness,
    }

func award_attempt_xp(actor_id: String, skill_id: StringName, difficulty: int, succeeded: bool) -> bool:
    if not is_ready() or not Catalog.is_valid(skill_id) or not Catalog.is_valid_difficulty(difficulty):
        return false
    if not _skills.has_actor(actor_id):
        return false
    var amount: int = 2 + difficulty * 2 if succeeded else 1 + difficulty
    return _skills.award_xp(actor_id, skill_id, amount)

static func _success_chance(skill_level: int, difficulty: int) -> int:
    return clampi(75 + skill_level * 7 - difficulty * 6, 20, 100)

static func _effectiveness(skill_level: int, difficulty: int) -> int:
    return clampi(65 + skill_level * 6 - difficulty * 3, 35, 125)

static func _stable_roll(actor_id: String, skill_id: StringName, difficulty: int, action_serial: int, context_key: StringName) -> int:
    var text: String = "%s|%s|%d|%d|%s" % [actor_id, String(skill_id), difficulty, action_serial, String(context_key)]
    var value: int = 17
    for index in range(text.length()):
        value = int((value * 131 + text.unicode_at(index)) % 2147483647)
    return int(value % 100) + 1

static func _failure(reason: String) -> Dictionary:
    return {
        "ok": false,
        "reason": reason,
        "skill_id": &"",
        "skill_level": -1,
        "difficulty": 0,
        "success": false,
    }
