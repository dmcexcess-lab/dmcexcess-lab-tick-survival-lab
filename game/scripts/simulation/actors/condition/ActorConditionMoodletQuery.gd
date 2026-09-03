extends RefCounted
class_name ActorConditionMoodletQuery

const StateClass = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const ModifierClass = preload("res://scripts/simulation/actors/condition/ActorConditionModifierQuery.gd")

## One live derived moodlet composition. It reports real pressures/consequences from
## condition, fatigue, health, and carry; normal/positive meters do not become clutter.

const LABELS: Dictionary = {
    "satiety": {"YELLOW": "Hungry", "ORANGE": "Famished", "RED": "Starving"},
    "hydration": {"YELLOW": "Thirsty", "ORANGE": "Parched", "RED": "Dehydrated"},
    "rest": {"YELLOW": "Tired", "ORANGE": "Exhausted", "RED": "Sleep-Deprived"},
    "engagement": {"YELLOW": "Bored", "ORANGE": "Restless", "RED": "Stir-Crazy"},
    "comfort": {"YELLOW": "Uncomfortable", "ORANGE": "Miserable", "RED": "Wretched"},
    "calm": {"YELLOW": "Uneasy", "ORANGE": "Afraid", "RED": "Terrified"},
}

const TIER_PRIORITY: Dictionary = {"YELLOW": 30, "ORANGE": 60, "RED": 90}

var _modifiers: ActorConditionModifierQuery = null
var _health: ActorHealthState = null
var _carry: ActorCarryQuery = null

func _init(
    modifier_query: ActorConditionModifierQuery = null,
    health_state: ActorHealthState = null,
    carry_query: ActorCarryQuery = null
) -> void:
    _modifiers = modifier_query
    _health = health_state
    _carry = carry_query

func is_ready() -> bool:
    return _modifiers != null and _modifiers.is_ready() and _health != null and _carry != null

func moodlets_for(actor_id: String) -> Dictionary:
    if not is_ready() or not _modifiers.has_actor(actor_id) or not _health.has_actor(actor_id):
        return {"ok": false, "reason": "condition_moodlets_unconfigured", "moodlets": []}
    var snapshot: Dictionary = _modifiers.modifier_snapshot(actor_id)
    if not bool(snapshot.get("ok", false)):
        return {"ok": false, "reason": String(snapshot.get("reason", "condition_unknown")), "moodlets": []}
    var carry_result: Dictionary = _carry.query(actor_id)
    if int(carry_result.get("status", -1)) != ActorCarryQuery.Status.KNOWN:
        return {"ok": false, "reason": "carry_unclassified", "moodlets": []}

    var values: Dictionary = snapshot.get("values", {})
    var tiers: Dictionary = snapshot.get("tiers", {})
    var result: Array[Dictionary] = []
    for channel: StringName in StateClass.CHANNELS:
        var key: String = String(channel)
        var tier_value: StringName = StringName(tiers.get(key, &""))
        if tier_value == ModifierClass.TIER_NORMAL or tier_value == ModifierClass.TIER_GREEN:
            continue
        var label: String = String((LABELS.get(key, {}) as Dictionary).get(String(tier_value), ""))
        if not label.is_empty():
            result.append(_descriptor(
                StringName("condition.%s.%s" % [key, String(tier_value).to_lower()]),
                channel,
                label,
                tier_value,
                int(values.get(key, -1)),
                int(TIER_PRIORITY.get(String(tier_value), 0))
            ))

    _append_fatigue(result, int(snapshot.get("fatigue", -1)))
    _append_health(result, actor_id)
    _append_carry(result, carry_result)
    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if int(a.get("priority", 0)) != int(b.get("priority", 0)):
            return int(a.get("priority", 0)) > int(b.get("priority", 0))
        return String(a.get("moodlet_id", "")) < String(b.get("moodlet_id", ""))
    )
    return {"ok": true, "reason": "", "moodlets": result}

func _append_fatigue(target: Array[Dictionary], fatigue: int) -> void:
    if fatigue >= 90:
        target.append(_descriptor(&"condition.fatigue.spent", &"fatigue", "Spent", &"RED", fatigue, 105))
    elif fatigue >= 70:
        target.append(_descriptor(&"condition.fatigue.exhausted", &"fatigue", "Physically Exhausted", &"ORANGE", fatigue, 75))
    elif fatigue >= 35:
        target.append(_descriptor(&"condition.fatigue.winded", &"fatigue", "Winded", &"YELLOW", fatigue, 40))

func _append_health(target: Array[Dictionary], actor_id: String) -> void:
    var current: int = _health.current_hp(actor_id)
    var maximum: int = _health.max_hp(actor_id)
    if current <= 0:
        target.append(_descriptor(&"health.no_vitality", &"health", "No Vitality", &"RED", current, 130))
    elif maximum > 0 and current * 100 <= maximum * 25:
        target.append(_descriptor(&"health.badly_injured", &"health", "Badly Injured", &"RED", current, 120))
    elif maximum > 0 and current < maximum:
        target.append(_descriptor(&"health.injured", &"health", "Injured", &"ORANGE", current, 70))

func _append_carry(target: Array[Dictionary], carry: Dictionary) -> void:
    var ratio_bp: int = int(carry.get("load_ratio_bp", 0))
    if ratio_bp > 10000:
        target.append(_descriptor(&"carry.overburdened", &"carry", "Overburdened", &"RED", ratio_bp / 100, 110))
    elif ratio_bp >= 7500:
        target.append(_descriptor(&"carry.heavy_load", &"carry", "Heavy Load", &"YELLOW", ratio_bp / 100, 35))

static func _descriptor(
    moodlet_id: StringName,
    source: StringName,
    label: String,
    tier: StringName,
    value: int,
    priority: int
) -> Dictionary:
    return {
        "moodlet_id": moodlet_id,
        "channel": source,
        "label": label,
        "tier": tier,
        "value": value,
        "priority": priority,
    }
