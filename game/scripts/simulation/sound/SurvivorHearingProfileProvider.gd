extends HearingProfileProvider
class_name SurvivorHearingProfileProvider

## Read-only derived survivor hearing profile. System 26 owns no persistent
## perception stat; Skills/Needs remain authoritative.

const BASE_HEARING: int = 50
const SURVIVAL_BONUS_PER_LEVEL: int = 4
const MAX_FATIGUE_PENALTY: int = 15
const MAX_SLEEP_PENALTY: int = 20

var _skills: ActorSkillState = null
var _needs: ActorNeedsState = null

func _init(skills: ActorSkillState = null, needs: ActorNeedsState = null) -> void:
    _skills = skills
    _needs = needs

func is_ready() -> bool:
    return _skills != null and _needs != null

func profile(actor_id: String) -> Dictionary:
    if not is_ready() or not _skills.has_actor(actor_id) or not _needs.has_actor(actor_id):
        return _neutral_profile()
    var survival: int = maxi(0, _skills.level(actor_id, &"survival"))
    var fatigue: int = clampi(_needs.fatigue(actor_id), 0, 100)
    var sleep_pressure: int = clampi(_needs.sleep_pressure(actor_id), 0, 100)
    var fatigue_penalty: int = int(round(float(fatigue) * float(MAX_FATIGUE_PENALTY) / 100.0))
    var sleep_penalty: int = int(round(float(sleep_pressure) * float(MAX_SLEEP_PENALTY) / 100.0))
    var score: int = clampi(
        BASE_HEARING + survival * SURVIVAL_BONUS_PER_LEVEL - fatigue_penalty - sleep_penalty,
        0,
        100
    )
    return {
        "hearing_score": score,
        "detection_threshold": _detection_threshold(score),
        "survival_level": survival,
        "fatigue": fatigue,
        "sleep_pressure": sleep_pressure,
        "known": true,
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
        "survival_level": 0,
        "fatigue": 0,
        "sleep_pressure": 0,
        "known": false,
    }

static func _detection_threshold(score: int) -> int:
    # score 0 -> 60 remaining-energy units required; score 100 -> 20.
    return 60 - int(round(float(clampi(score, 0, 100)) * 0.40))
