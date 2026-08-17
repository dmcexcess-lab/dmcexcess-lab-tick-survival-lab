extends RefCounted
class_name ActorStatsInspectorQuery

const InjuryRecordClass = preload("res://scripts/simulation/actors/health/ActorInjuryRecord.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")

## Read-only System 16 detailed actor-status composer.
## Owns no actor state and performs no mutations.

var _summary: ActorStatusSummaryQuery = null
var _health: ActorHealthState = null
var _skills: ActorSkillState = null
var _locomotion: ActorLocomotionState = null

func _init(
    summary_query: ActorStatusSummaryQuery = null,
    health_state: ActorHealthState = null,
    skill_state: ActorSkillState = null,
    locomotion_state: ActorLocomotionState = null
) -> void:
    _summary = summary_query
    _health = health_state
    _skills = skill_state
    _locomotion = locomotion_state

func is_ready() -> bool:
    return _summary != null \
        and _summary.is_ready() \
        and _health != null \
        and _skills != null \
        and _locomotion != null

func query(actor_id: String) -> Dictionary:
    var normalized: String = actor_id.strip_edges()
    if not is_ready() or normalized.is_empty():
        return _failure("stats_query_not_ready")
    if not _health.has_actor(normalized):
        return _failure("health_unclassified")
    if not _skills.has_actor(normalized):
        return _failure("skills_unclassified")
    if not _locomotion.has_actor(normalized):
        return _failure("locomotion_unclassified")

    var summary: Dictionary = _summary.query(normalized)
    if not bool(summary.get("ok", false)):
        return _failure("status_summary_unknown:%s" % String(summary.get("reason", "unknown")))

    var stance: StringName = _locomotion.stance(normalized)
    if String(stance).is_empty():
        return _failure("stance_unknown")

    var injury_entries: Array = []
    for injury: ActorInjuryRecord in _health.injuries(normalized):
        injury_entries.append({
            "injury_id": injury.injury_id,
            "injury_type": injury.injury_type,
            "injury_label": _humanize(String(injury.injury_type)),
            "body_region": injury.body_region,
            "body_region_label": _humanize(String(injury.body_region)),
            "severity": injury.severity,
            "severity_label": _severity_label(injury.severity),
            "stabilized": injury.stabilized,
            "treated": injury.treated,
        })

    var skill_entries: Array = []
    for skill_id: StringName in _skills.skill_ids():
        var level: int = _skills.level(normalized, skill_id)
        var xp: int = _skills.xp(normalized, skill_id)
        if level < SkillCatalog.LEVEL_MIN or xp < 0:
            return _failure("skill_state_invalid:%s" % String(skill_id))
        skill_entries.append({
            "skill_id": skill_id,
            "label": _skills.display_name(skill_id),
            "level": level,
            "xp": xp,
            "next_level_xp": _skills.next_level_xp(normalized, skill_id),
            "max_level": level >= SkillCatalog.LEVEL_MAX,
        })

    return {
        "ok": true,
        "reason": "",
        "actor_id": normalized,
        "stance": stance,
        "stance_label": _humanize(String(stance)),
        "status": summary.duplicate(true),
        "injuries": injury_entries,
        "skills": skill_entries,
    }

static func _failure(reason: String) -> Dictionary:
    return {
        "ok": false,
        "reason": reason,
        "actor_id": "",
        "stance": &"",
        "stance_label": "Unknown",
        "status": {},
        "injuries": [],
        "skills": [],
    }

static func _severity_label(value: int) -> String:
    match value:
        InjuryRecordClass.Severity.MINOR:
            return "Minor"
        InjuryRecordClass.Severity.SERIOUS:
            return "Serious"
        InjuryRecordClass.Severity.CRITICAL:
            return "Critical"
        _:
            return "Unknown"

static func _humanize(value: String) -> String:
    var text: String = value.strip_edges().replace("_", " ").replace(".", " ")
    if text.is_empty():
        return "Unknown"
    return text.capitalize()
