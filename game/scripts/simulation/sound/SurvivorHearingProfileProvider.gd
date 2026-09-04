extends HearingProfileProvider
class_name SurvivorHearingProfileProvider

## Read-only derived survivor hearing profile. System 26 owns no persistent
## perception stat. Live gameplay derives competence from Awareness and physical
## degradation from canonical System 34 Fatigue/rest. Legacy Needs/Survival inputs
## remain accepted only for historical focused fixtures.

const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")

const BASE_HEARING: int = 50
const SKILL_BONUS_PER_LEVEL: int = 4
const MAX_FATIGUE_PENALTY: int = 15
const MAX_SLEEP_PENALTY: int = 20

var _skills: ActorSkillState = null
var _needs: ActorNeedsState = null
var _condition: ActorConditionService = null

func _init(skills: ActorSkillState = null, needs: ActorNeedsState = null) -> void:
    _skills = skills
    _needs = needs

func configure_condition(condition_service: ActorConditionService) -> bool:
    if condition_service == null or not condition_service.is_ready():
        return false
    _condition = condition_service
    return true

func is_ready() -> bool:
    return _skills != null

func profile(actor_id: String) -> Dictionary:
    if not is_ready() or not _skills.has_actor(actor_id):
        return _neutral_profile()

    var using_canonical_condition: bool = _condition != null \
        and _condition.is_ready() \
        and _condition.has_actor(actor_id)
    var using_legacy_needs: bool = not using_canonical_condition \
        and _needs != null \
        and _needs.has_actor(actor_id)

    # Historical sound fixtures predate the four-skill closure and intentionally retain
    # their old Survival-based comparison. Production, including the brief pre-System-34
    # boot stage where no legacy Needs object exists, always uses Awareness.
    var skill_id: StringName = SkillCatalog.SURVIVAL if using_legacy_needs else SkillCatalog.AWARENESS
    var competence: int = maxi(0, _skills.level(actor_id, skill_id))
    var fatigue: int = 0
    var sleep_pressure: int = 0
    if using_canonical_condition:
        fatigue = clampi(_condition.current_fatigue(actor_id), 0, 100)
        var values: Dictionary = _condition.values(actor_id)
        sleep_pressure = clampi(100 - int(values.get("rest", 100)), 0, 100)
    elif using_legacy_needs:
        fatigue = clampi(_needs.fatigue(actor_id), 0, 100)
        sleep_pressure = clampi(_needs.sleep_pressure(actor_id), 0, 100)

    var fatigue_penalty: int = int(round(float(fatigue) * float(MAX_FATIGUE_PENALTY) / 100.0))
    var sleep_penalty: int = int(round(float(sleep_pressure) * float(MAX_SLEEP_PENALTY) / 100.0))
    var score: int = clampi(
        BASE_HEARING + competence * SKILL_BONUS_PER_LEVEL - fatigue_penalty - sleep_penalty,
        0,
        100
    )
    return {
        "hearing_score": score,
        "detection_threshold": _detection_threshold(score),
        "awareness_level": maxi(0, _skills.level(actor_id, SkillCatalog.AWARENESS)),
        "fatigue": fatigue,
        "sleep_pressure": sleep_pressure,
        "known": true,
        "canonical_condition": using_canonical_condition,
    }

func domain_level(actor_id: String, skill_id: StringName) -> int:
    if not is_ready() or not _skills.has_actor(actor_id):
        return 0
    var level: int = _skills.level(actor_id, skill_id)
    return maxi(0, level)

func _neutral_profile() -> Dictionary:
    return {
        "hearing_score": BASE_HEARING,
        "detection_threshold": _detection_threshold(BASE_HEARING),
        "awareness_level": 0,
        "fatigue": 0,
        "sleep_pressure": 0,
        "known": false,
        "canonical_condition": false,
    }

static func _detection_threshold(score: int) -> int:
    # score 0 -> 60 remaining-energy units required; score 100 -> 20.
    return 60 - int(round(float(clampi(score, 0, 100)) * 0.40))
