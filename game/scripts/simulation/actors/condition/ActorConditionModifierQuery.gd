extends RefCounted
class_name ActorConditionModifierQuery

const StateClass = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")

## Read-only System 34 analytic condition + derived modifier query.
## No timer advances these values. Current truth is a function of persisted anchors and WHEN tick.

const TIER_GREEN: StringName = &"GREEN"
const TIER_NORMAL: StringName = &"NORMAL"
const TIER_YELLOW: StringName = &"YELLOW"
const TIER_ORANGE: StringName = &"ORANGE"
const TIER_RED: StringName = &"RED"

const GREEN_MIN: int = 80
const NORMAL_MIN: int = 45
const YELLOW_MIN: int = 30
const ORANGE_MIN: int = 15

# Fixed-point raw points lost per in-game day.
const DECAY_RAW_PER_DAY: Dictionary = {
    "satiety": 50000,
    "hydration": 75000,
    "rest": 40000,
    "engagement": 15000,
}
const NEUTRAL_RAW: int = 60000
const COMFORT_RECOVERY_RAW_PER_DAY: int = 18000
const CALM_RECOVERY_RAW_PER_DAY: int = 50000
const FATIGUE_RECOVERY_POINTS_PER_MINUTE: int = 12

# Potency in tenths: hunger 1.0, thirst 1.1, sleep 1.0, boredom .5, comfort .6, fear .8.
const POTENCY_TENTHS: Dictionary = {
    "satiety": 10,
    "hydration": 11,
    "rest": 10,
    "engagement": 5,
    "comfort": 6,
    "calm": 8,
}

var _state: ActorConditionState = null
var _time_profile: WorldTimeProfile = null
var _kernel: TickKernel = null

func _init(
    condition_state: ActorConditionState = null,
    time_profile: WorldTimeProfile = null,
    kernel: TickKernel = null
) -> void:
    _state = condition_state
    _time_profile = time_profile
    _kernel = kernel

func is_ready() -> bool:
    return _state != null and _state.is_ready() and _time_profile != null and _time_profile.is_valid() and _kernel != null

func has_actor(actor_id: String) -> bool:
    return is_ready() and _state.has_actor(actor_id)

func current_values(actor_id: String) -> Dictionary:
    if not is_ready():
        return {}
    var raw: Dictionary = raw_values_at(actor_id, _kernel.world_tick())
    if raw.is_empty():
        return {}
    var result: Dictionary = {}
    for channel: StringName in StateClass.CHANNELS:
        result[String(channel)] = clampi(int(raw.get(String(channel), 0)) / StateClass.VALUE_SCALE, 0, 100)
    return result

func raw_values_at(actor_id: String, world_tick: int) -> Dictionary:
    if not is_ready() or world_tick < 0 or not _state.has_actor(actor_id):
        return {}
    var record_value: Dictionary = _state.record(actor_id)
    var anchor_tick: int = int(record_value.get("anchor_tick", -1))
    if anchor_tick < 0 or world_tick < anchor_tick:
        return {}
    var source: Dictionary = record_value.get("values_raw", {})
    var result: Dictionary = {}
    for channel: StringName in StateClass.CHANNELS:
        var key: String = String(channel)
        var start_raw: int = int(source.get(key, -1))
        if start_raw < 0:
            return {}
        result[key] = _raw_value_at(key, start_raw, anchor_tick, world_tick)
    return result

func value(actor_id: String, channel: StringName) -> int:
    if channel not in StateClass.CHANNELS:
        return -1
    return int(current_values(actor_id).get(String(channel), -1))

func tier_for_value(value: int) -> StringName:
    if value < 0 or value > 100:
        return &""
    if value >= GREEN_MIN:
        return TIER_GREEN
    if value >= NORMAL_MIN:
        return TIER_NORMAL
    if value >= YELLOW_MIN:
        return TIER_YELLOW
    if value >= ORANGE_MIN:
        return TIER_ORANGE
    return TIER_RED

func tier(actor_id: String, channel: StringName) -> StringName:
    return tier_for_value(value(actor_id, channel))

func modifier_snapshot(actor_id: String) -> Dictionary:
    var values: Dictionary = current_values(actor_id)
    if values.is_empty():
        return {"ok": false, "reason": "condition_unclassified"}
    var weighted_tenths: int = 0
    var tiers: Dictionary = {}
    for channel: StringName in StateClass.CHANNELS:
        var key: String = String(channel)
        var channel_value: int = int(values.get(key, -1))
        var tier_value: StringName = tier_for_value(channel_value)
        tiers[key] = tier_value
        weighted_tenths += _tier_contribution(tier_value) * int(POTENCY_TENTHS.get(key, 0))

    var fatigue: int = fatigue_value(actor_id)
    if fatigue < 0:
        return {"ok": false, "reason": "fatigue_unclassified"}
    weighted_tenths += _fatigue_contribution(fatigue) * 10
    var health_bp: int = _derived_multiplier(weighted_tenths, 75, 6000, 10500)
    var speed_bp: int = _derived_multiplier(weighted_tenths, 80, 6500, 10500)
    var carry_bp: int = _derived_multiplier(weighted_tenths, 100, 6000, 10500)
    var damage_bp: int = _derived_multiplier(weighted_tenths, 100, 6500, 10500)
    var base_condition_tenths: int = _condition_weighted_tenths(values)
    var fatigue_recovery_bp: int = _derived_multiplier(base_condition_tenths, 150, 4000, 10500)
    var fatigue_gain_bp: int = clampi(20000 - fatigue_recovery_bp, 9500, 16000)
    return {
        "ok": true,
        "reason": "",
        "values": values,
        "tiers": tiers,
        "fatigue": fatigue,
        "weighted_condition_tenths": weighted_tenths,
        "health_multiplier_bp": health_bp,
        "fatigue_gain_multiplier_bp": fatigue_gain_bp,
        "fatigue_recovery_multiplier_bp": fatigue_recovery_bp,
        "speed_multiplier_bp": speed_bp,
        "carry_multiplier_bp": carry_bp,
        "melee_damage_multiplier_bp": damage_bp,
    }

func health_multiplier_bp(actor_id: String) -> int:
    return int(modifier_snapshot(actor_id).get("health_multiplier_bp", 10000))

func fatigue_gain_multiplier_bp(actor_id: String) -> int:
    var values: Dictionary = current_values(actor_id)
    return 10000 if values.is_empty() else clampi(20000 - _derived_multiplier(_condition_weighted_tenths(values), 150, 4000, 10500), 9500, 16000)

func fatigue_recovery_multiplier_bp(actor_id: String) -> int:
    var values: Dictionary = current_values(actor_id)
    return 10000 if values.is_empty() else _derived_multiplier(_condition_weighted_tenths(values), 150, 4000, 10500)

func speed_multiplier_bp(actor_id: String) -> int:
    return int(modifier_snapshot(actor_id).get("speed_multiplier_bp", 10000))

func carry_multiplier_bp(actor_id: String) -> int:
    return int(modifier_snapshot(actor_id).get("carry_multiplier_bp", 10000))

func melee_damage_multiplier_bp(actor_id: String) -> int:
    return int(modifier_snapshot(actor_id).get("melee_damage_multiplier_bp", 10000))

func effective_max_health(actor_id: String, base_max_hp: int) -> int:
    if base_max_hp < 1:
        return 0
    return maxi(1, int((base_max_hp * health_multiplier_bp(actor_id)) / 10000))

func fatigue_value(actor_id: String) -> int:
    var raw: int = fatigue_raw_at(actor_id, _kernel.world_tick()) if is_ready() else -1
    return -1 if raw < 0 else clampi(raw / StateClass.VALUE_SCALE, 0, 100)

func fatigue_raw_at(actor_id: String, world_tick: int) -> int:
    if not is_ready() or world_tick < 0 or not _state.has_actor(actor_id):
        return -1
    var record_value: Dictionary = _state.record(actor_id)
    var anchor_tick: int = int(record_value.get("fatigue_anchor_tick", -1))
    var start_raw: int = int(record_value.get("fatigue_raw", -1))
    if anchor_tick < 0 or start_raw < 0 or world_tick < anchor_tick:
        return -1
    var elapsed: int = world_tick - anchor_tick
    var numerator: int = elapsed * FATIGUE_RECOVERY_POINTS_PER_MINUTE * StateClass.VALUE_SCALE * fatigue_recovery_multiplier_bp(actor_id)
    var denominator: int = _time_profile.ticks_per_minute() * 10000
    var recovered_raw: int = 0 if denominator <= 0 else numerator / denominator
    return clampi(start_raw - recovered_raw, 0, StateClass.RAW_MAX)

## Used by System 34 lethal physical-need pressure. Mutations settle before re-anchoring,
## so this exactly counts time spent at zero inside the current anchor interval.
func zero_ticks_between(record_value: Dictionary, channel: StringName, from_tick: int, to_tick: int) -> int:
    var key: String = String(channel)
    if not DECAY_RAW_PER_DAY.has(key) or from_tick < 0 or to_tick <= from_tick:
        return 0
    var anchor_tick: int = int(record_value.get("anchor_tick", -1))
    var values: Dictionary = record_value.get("values_raw", {})
    var start_raw: int = int(values.get(key, -1))
    if anchor_tick < 0 or start_raw < 0 or from_tick < anchor_tick:
        return 0
    var rate: int = int(DECAY_RAW_PER_DAY[key])
    if rate <= 0:
        return 0
    var ticks_per_day: int = _time_profile.ticks_per_day()
    var ticks_until_zero: int = 0
    if start_raw > 0:
        ticks_until_zero = int(ceili(float(start_raw * ticks_per_day) / float(rate)))
    var zero_start: int = anchor_tick + ticks_until_zero
    var effective_start: int = maxi(from_tick, zero_start)
    return maxi(0, to_tick - effective_start)

func _raw_value_at(channel: String, start_raw: int, anchor_tick: int, world_tick: int) -> int:
    var elapsed: int = maxi(0, world_tick - anchor_tick)
    var ticks_per_day: int = _time_profile.ticks_per_day()
    if DECAY_RAW_PER_DAY.has(channel):
        var loss: int = int((elapsed * int(DECAY_RAW_PER_DAY[channel])) / ticks_per_day)
        return clampi(start_raw - loss, 0, StateClass.RAW_MAX)
    var recovery_rate: int = COMFORT_RECOVERY_RAW_PER_DAY if channel == "comfort" else CALM_RECOVERY_RAW_PER_DAY
    var shift: int = int((elapsed * recovery_rate) / ticks_per_day)
    if start_raw < NEUTRAL_RAW:
        return mini(NEUTRAL_RAW, start_raw + shift)
    if start_raw > NEUTRAL_RAW:
        return maxi(NEUTRAL_RAW, start_raw - shift)
    return start_raw

static func _tier_contribution(tier_value: StringName) -> int:
    match tier_value:
        TIER_GREEN:
            return 1
        TIER_NORMAL:
            return 0
        TIER_YELLOW:
            return -2
        TIER_ORANGE:
            return -5
        TIER_RED:
            return -10
        _:
            return 0

static func _fatigue_contribution(fatigue: int) -> int:
    if fatigue >= 90:
        return -10
    if fatigue >= 75:
        return -6
    if fatigue >= 50:
        return -3
    if fatigue >= 25:
        return -1
    return 0

static func _condition_weighted_tenths(values: Dictionary) -> int:
    var result: int = 0
    for channel: StringName in StateClass.CHANNELS:
        var key: String = String(channel)
        var value: int = int(values.get(key, -1))
        if value < 0:
            continue
        var contribution: int = 0
        if value >= GREEN_MIN:
            contribution = 1
        elif value < ORANGE_MIN:
            contribution = -10
        elif value < YELLOW_MIN:
            contribution = -5
        elif value < NORMAL_MIN:
            contribution = -2
        result += contribution * int(POTENCY_TENTHS.get(key, 0))
    return result

static func _derived_multiplier(weighted_tenths: int, sensitivity_percent_x100: int, min_bp: int, max_bp: int) -> int:
    # weighted_tenths * sensitivity / 10 produces basis-point adjustment.
    var adjustment_bp: int = int((weighted_tenths * sensitivity_percent_x100) / 10)
    return clampi(10000 + adjustment_bp, min_bp, max_bp)
