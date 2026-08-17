extends RefCounted
class_name ActorStatusSummaryQuery

## Read-only System 13 summary composer for compact HUD/inspection surfaces.
## Stores no actor truth and mutates no source domain.

var _health: ActorHealthState = null
var _needs: ActorNeedsState = null
var _carry_query: ActorCarryQuery = null
var _moodlets: ActorMoodletService = null

func _init(
    health_state: ActorHealthState = null,
    needs_state: ActorNeedsState = null,
    carry_query: ActorCarryQuery = null,
    moodlet_service: ActorMoodletService = null
) -> void:
    _health = health_state
    _needs = needs_state
    _carry_query = carry_query
    _moodlets = moodlet_service

func is_ready() -> bool:
    return _health != null and _needs != null and _carry_query != null and _moodlets != null

func query(actor_id: String) -> Dictionary:
    if not is_ready():
        return _failure("status_summary_unconfigured")
    if not _health.has_actor(actor_id):
        return _failure("health_unclassified")
    if not _needs.has_actor(actor_id):
        return _failure("needs_unclassified")

    var carry: Dictionary = _carry_query.query(actor_id)
    if int(carry.get("status", -1)) != ActorCarryQuery.Status.KNOWN:
        return _failure("carry_unclassified:%s" % String(carry.get("reason", "unknown")))

    var moodlet_result: Dictionary = _moodlets.moodlets_for(actor_id)
    if not bool(moodlet_result.get("ok", false)):
        return _failure("moodlets_unclassified:%s" % String(moodlet_result.get("reason", "unknown")))

    var moodlet_labels: Array[String] = []
    var moodlet_ids: Array[StringName] = []
    var raw_moodlets: Array = moodlet_result.get("moodlets", [])
    for value: Variant in raw_moodlets:
        if value is ActorMoodlet:
            var moodlet: ActorMoodlet = value
            moodlet_labels.append(moodlet.display_name)
            moodlet_ids.append(moodlet.moodlet_id)

    return {
        "ok": true,
        "reason": "",
        "current_hp": _health.current_hp(actor_id),
        "max_hp": _health.max_hp(actor_id),
        "fatigue": _needs.fatigue(actor_id),
        "hunger": _needs.hunger(actor_id),
        "thirst": _needs.thirst(actor_id),
        "sleep_pressure": _needs.sleep_pressure(actor_id),
        "carry_weight_grams": int(carry.get("weight_grams", 0)),
        "carry_capacity_grams": int(carry.get("capacity_grams", 0)),
        "load_ratio_bp": int(carry.get("load_ratio_bp", 0)),
        "moodlet_labels": moodlet_labels,
        "moodlet_ids": moodlet_ids,
    }

static func _failure(reason: String) -> Dictionary:
    return {
        "ok": false,
        "reason": reason,
        "current_hp": -1,
        "max_hp": -1,
        "fatigue": -1,
        "hunger": -1,
        "thirst": -1,
        "sleep_pressure": -1,
        "carry_weight_grams": -1,
        "carry_capacity_grams": -1,
        "load_ratio_bp": -1,
        "moodlet_labels": [],
        "moodlet_ids": [],
    }
