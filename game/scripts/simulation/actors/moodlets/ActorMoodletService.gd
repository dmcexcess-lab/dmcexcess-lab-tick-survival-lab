extends RefCounted
class_name ActorMoodletService

const MoodletClass = preload("res://scripts/simulation/actors/moodlets/ActorMoodlet.gd")

## 13F derived moodlets. No ordinary moodlet state is persisted or mutated.

var _health: ActorHealthState = null
var _needs: ActorNeedsState = null
var _carry_query: ActorCarryQuery = null

func _init(
    health_state: ActorHealthState = null,
    needs_state: ActorNeedsState = null,
    carry_query: ActorCarryQuery = null
) -> void:
    _health = health_state
    _needs = needs_state
    _carry_query = carry_query

func moodlets_for(actor_id: String) -> Dictionary:
    if _health == null or _needs == null or _carry_query == null:
        return result(false, "moodlet_service_unconfigured", [])
    if not _health.has_actor(actor_id):
        return result(false, "health_unclassified", [])
    if not _needs.has_actor(actor_id):
        return result(false, "needs_unclassified", [])
    var carry: Dictionary = _carry_query.query(actor_id)
    if int(carry.get("status", -1)) != ActorCarryQuery.Status.KNOWN:
        return result(false, "carry_unclassified:%s" % String(carry.get("reason", "unknown")), [])

    var moodlets: Array[ActorMoodlet] = []
    _append_health_moodlet(moodlets, actor_id)
    _append_fatigue_moodlet(moodlets, actor_id)
    _append_hunger_moodlet(moodlets, actor_id)
    _append_thirst_moodlet(moodlets, actor_id)
    _append_sleep_moodlet(moodlets, actor_id)
    _append_carry_moodlet(moodlets, carry)
    if _needs.fatigue(actor_id) <= 10 and _needs.sleep_pressure(actor_id) <= 10:
        moodlets.append(MoodletClass.new(&"well_rested", "Well Rested", MoodletClass.Severity.POSITIVE, 10))

    moodlets.sort_custom(_comes_before)
    var copies: Array[ActorMoodlet] = []
    for moodlet: ActorMoodlet in moodlets:
        copies.append(moodlet.copy())
    return result(true, "", copies)

static func result(ok: bool, reason: String, moodlets: Array) -> Dictionary:
    return {
        "ok": ok,
        "reason": reason,
        "moodlets": moodlets.duplicate(),
    }

func _append_health_moodlet(target: Array[ActorMoodlet], actor_id: String) -> void:
    var current: int = _health.current_hp(actor_id)
    var maximum: int = _health.max_hp(actor_id)
    if current == 0:
        target.append(MoodletClass.new(&"no_vitality", "No Vitality", MoodletClass.Severity.CRITICAL, 120))
        return
    if maximum > 0 and current * 100 <= maximum * 25:
        target.append(MoodletClass.new(&"badly_injured", "Badly Injured", MoodletClass.Severity.CRITICAL, 110))
        return
    if maximum > 0 and current < maximum:
        target.append(MoodletClass.new(&"injured", "Injured", MoodletClass.Severity.WARNING, 60))

func _append_fatigue_moodlet(target: Array[ActorMoodlet], actor_id: String) -> void:
    var current: int = _needs.fatigue(actor_id)
    if current >= 80:
        target.append(MoodletClass.new(&"exhausted", "Exhausted", MoodletClass.Severity.CRITICAL, 103))
    elif current >= 50:
        target.append(MoodletClass.new(&"tired", "Tired", MoodletClass.Severity.WARNING, 56))

func _append_hunger_moodlet(target: Array[ActorMoodlet], actor_id: String) -> void:
    var current: int = _needs.hunger(actor_id)
    if current >= 85:
        target.append(MoodletClass.new(&"starving", "Starving", MoodletClass.Severity.CRITICAL, 105))
    elif current >= 55:
        target.append(MoodletClass.new(&"hungry", "Hungry", MoodletClass.Severity.WARNING, 58))

func _append_thirst_moodlet(target: Array[ActorMoodlet], actor_id: String) -> void:
    var current: int = _needs.thirst(actor_id)
    if current >= 80:
        target.append(MoodletClass.new(&"dehydrated", "Dehydrated", MoodletClass.Severity.CRITICAL, 104))
    elif current >= 50:
        target.append(MoodletClass.new(&"thirsty", "Thirsty", MoodletClass.Severity.WARNING, 57))

func _append_sleep_moodlet(target: Array[ActorMoodlet], actor_id: String) -> void:
    var current: int = _needs.sleep_pressure(actor_id)
    if current >= 80:
        target.append(MoodletClass.new(&"sleep_deprived", "Sleep Deprived", MoodletClass.Severity.CRITICAL, 102))
    elif current >= 50:
        target.append(MoodletClass.new(&"sleepy", "Sleepy", MoodletClass.Severity.WARNING, 55))

func _append_carry_moodlet(target: Array[ActorMoodlet], carry: Dictionary) -> void:
    var ratio_bp: int = int(carry.get("load_ratio_bp", 0))
    if ratio_bp > 10000:
        target.append(MoodletClass.new(&"overburdened", "Overburdened", MoodletClass.Severity.CRITICAL, 101))
    elif ratio_bp >= 7500:
        target.append(MoodletClass.new(&"heavy_load", "Heavy Load", MoodletClass.Severity.NOTICE, 25))

static func _comes_before(a: ActorMoodlet, b: ActorMoodlet) -> bool:
    if a.priority != b.priority:
        return a.priority > b.priority
    return String(a.moodlet_id) < String(b.moodlet_id)
