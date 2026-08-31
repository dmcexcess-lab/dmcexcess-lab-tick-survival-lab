extends RefCounted
class_name ActorConditionMoodletQuery

const StateClass = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const ModifierClass = preload("res://scripts/simulation/actors/condition/ActorConditionModifierQuery.gd")

## Derived System 34 presentation descriptors. Normal conditions produce no moodlet.
## These records never own condition truth and never apply gameplay penalties themselves.

const LABELS: Dictionary = {
    "satiety": {
        "GREEN": "Well Fed",
        "YELLOW": "Hungry",
        "ORANGE": "Famished",
        "RED": "Starving",
    },
    "hydration": {
        "GREEN": "Hydrated",
        "YELLOW": "Thirsty",
        "ORANGE": "Parched",
        "RED": "Dehydrated",
    },
    "rest": {
        "GREEN": "Rested",
        "YELLOW": "Tired",
        "ORANGE": "Exhausted",
        "RED": "Sleep-Deprived",
    },
    "engagement": {
        "GREEN": "Entertained",
        "YELLOW": "Bored",
        "ORANGE": "Restless",
        "RED": "Stir-Crazy",
    },
    "comfort": {
        "GREEN": "Comfortable",
        "YELLOW": "Uncomfortable",
        "ORANGE": "Miserable",
        "RED": "Wretched",
    },
    "calm": {
        "GREEN": "Calm",
        "YELLOW": "Uneasy",
        "ORANGE": "Afraid",
        "RED": "Terrified",
    },
}

var _modifiers: ActorConditionModifierQuery = null

func _init(modifier_query: ActorConditionModifierQuery = null) -> void:
    _modifiers = modifier_query

func is_ready() -> bool:
    return _modifiers != null and _modifiers.is_ready()

func moodlets_for(actor_id: String) -> Dictionary:
    if not is_ready() or not _modifiers.has_actor(actor_id):
        return {"ok": false, "reason": "condition_moodlets_unconfigured", "moodlets": []}
    var snapshot: Dictionary = _modifiers.modifier_snapshot(actor_id)
    if not bool(snapshot.get("ok", false)):
        return {"ok": false, "reason": String(snapshot.get("reason", "condition_unknown")), "moodlets": []}
    var values: Dictionary = snapshot.get("values", {})
    var tiers: Dictionary = snapshot.get("tiers", {})
    var result: Array = []
    for channel: StringName in StateClass.CHANNELS:
        var key: String = String(channel)
        var tier_value: StringName = StringName(tiers.get(key, &""))
        if tier_value == ModifierClass.TIER_NORMAL:
            continue
        var label_map: Dictionary = LABELS.get(key, {})
        var label: String = String(label_map.get(String(tier_value), ""))
        if label.is_empty():
            continue
        result.append({
            "moodlet_id": StringName("condition.%s.%s" % [key, String(tier_value).to_lower()]),
            "channel": channel,
            "label": label,
            "tier": tier_value,
            "value": int(values.get(key, -1)),
        })
    return {"ok": true, "reason": "", "moodlets": result}
