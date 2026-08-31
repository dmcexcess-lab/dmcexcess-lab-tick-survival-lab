extends RefCounted
class_name ActorStatusSummaryQuery

## Read-only compact HUD/inspection composer.
## Historical System-13 inputs remain available for legacy fixtures. Live System 34 may be
## injected additively; presentation then reads real Health/Stamina and six condition channels.

var _health: ActorHealthState = null
var _needs: ActorNeedsState = null
var _carry_query: ActorCarryQuery = null
var _moodlets: ActorMoodletService = null
var _condition: ActorConditionService = null
var _condition_modifiers: ActorConditionModifierQuery = null
var _condition_moodlets: ActorConditionMoodletQuery = null

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

func configure_condition(
    condition_service: ActorConditionService,
    modifier_query: ActorConditionModifierQuery,
    moodlet_query: ActorConditionMoodletQuery
) -> bool:
    if condition_service == null or not condition_service.is_ready() \
        or modifier_query == null or not modifier_query.is_ready() \
        or moodlet_query == null or not moodlet_query.is_ready():
        return false
    _condition = condition_service
    _condition_modifiers = modifier_query
    _condition_moodlets = moodlet_query
    return true

func is_ready() -> bool:
    return _health != null and _needs != null and _carry_query != null and _moodlets != null

func system34_ready() -> bool:
    return _condition != null and _condition.is_ready() \
        and _condition_modifiers != null and _condition_modifiers.is_ready() \
        and _condition_moodlets != null and _condition_moodlets.is_ready()

func query(actor_id: String) -> Dictionary:
    if not is_ready():
        return _failure("status_summary_unconfigured")
    if system34_ready():
        return _query_system34(actor_id)
    return _query_legacy(actor_id)

func _query_system34(actor_id: String) -> Dictionary:
    if not _health.has_actor(actor_id) or not _condition.has_actor(actor_id):
        return _failure("condition_unclassified")
    var carry: Dictionary = _carry_query.query(actor_id)
    if int(carry.get("status", -1)) != ActorCarryQuery.Status.KNOWN:
        return _failure("carry_unclassified:%s" % String(carry.get("reason", "unknown")))
    var moodlet_result: Dictionary = _condition_moodlets.moodlets_for(actor_id)
    if not bool(moodlet_result.get("ok", false)):
        return _failure("moodlets_unclassified:%s" % String(moodlet_result.get("reason", "unknown")))
    var values: Dictionary = _condition.values(actor_id)
    var modifiers: Dictionary = _condition.modifier_snapshot(actor_id)
    var raw_moodlets: Array = moodlet_result.get("moodlets", [])
    var moodlet_labels: Array[String] = []
    var moodlet_ids: Array[StringName] = []
    var moodlet_tiers: Array[StringName] = []
    var moodlet_descriptors: Array = []
    for value: Variant in raw_moodlets:
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var moodlet: Dictionary = value
        moodlet_labels.append(String(moodlet.get("label", "")))
        moodlet_ids.append(StringName(moodlet.get("moodlet_id", &"")))
        moodlet_tiers.append(StringName(moodlet.get("tier", &"")))
        moodlet_descriptors.append(moodlet.duplicate(true))

    var stamina: int = _condition.current_stamina(actor_id)
    var stamina_max: int = _condition.effective_max_stamina(actor_id)
    var stamina_pressure: int = 0
    if stamina_max > 0:
        stamina_pressure = clampi(100 - int((stamina * 100) / stamina_max), 0, 100)
    return {
        "ok": true,
        "reason": "",
        "system34": true,
        "current_hp": _health.current_hp(actor_id),
        "max_hp": _condition.effective_max_health(actor_id),
        "base_max_hp": _health.max_hp(actor_id),
        "stamina": stamina,
        "stamina_max": stamina_max,
        "satiety": int(values.get("satiety", -1)),
        "hydration": int(values.get("hydration", -1)),
        "rest": int(values.get("rest", -1)),
        "engagement": int(values.get("engagement", -1)),
        "comfort": int(values.get("comfort", -1)),
        "calm": int(values.get("calm", -1)),
        # Compatibility reads for old inspector text; System 34 truth is the positive channels above.
        "fatigue": stamina_pressure,
        "hunger": 100 - int(values.get("satiety", 0)),
        "thirst": 100 - int(values.get("hydration", 0)),
        "sleep_pressure": 100 - int(values.get("rest", 0)),
        "carry_weight_grams": int(carry.get("weight_grams", 0)),
        "carry_capacity_grams": int(carry.get("capacity_grams", 0)),
        "load_ratio_bp": int(carry.get("load_ratio_bp", 0)),
        "moodlet_labels": moodlet_labels,
        "moodlet_ids": moodlet_ids,
        "moodlet_tiers": moodlet_tiers,
        "moodlet_descriptors": moodlet_descriptors,
        "condition_modifiers": modifiers.duplicate(true),
    }

func _query_legacy(actor_id: String) -> Dictionary:
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
        "system34": false,
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
        "system34": false,
        "current_hp": -1,
        "max_hp": -1,
        "stamina": -1,
        "stamina_max": -1,
        "satiety": -1,
        "hydration": -1,
        "rest": -1,
        "engagement": -1,
        "comfort": -1,
        "calm": -1,
        "fatigue": -1,
        "hunger": -1,
        "thirst": -1,
        "sleep_pressure": -1,
        "carry_weight_grams": -1,
        "carry_capacity_grams": -1,
        "load_ratio_bp": -1,
        "moodlet_labels": [],
        "moodlet_ids": [],
        "moodlet_tiers": [],
        "moodlet_descriptors": [],
        "condition_modifiers": {},
    }
