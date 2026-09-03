extends RefCounted
class_name ActorConditionService

const StateClass = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const Rules = preload("res://scripts/foundation/time/TickRules.gd")

## System 34 authoritative mutation/runtime service. Condition drift and Fatigue
## recovery are analytic from WHEN; no frame/tick loop exists.

signal condition_changed(actor_id, reason)
signal fatigue_changed(actor_id, fatigue, reason)

const RUN_MAX_START_FATIGUE: int = 85
const SATIETY_EXERTION_PER_POINT: int = 80
const HYDRATION_EXERTION_PER_POINT: int = 40
const OVEREXERTION_RAW_PER_HP: int = 10 * StateClass.VALUE_SCALE
const STARVATION_HP_PER_HOUR: int = 3
const DEHYDRATION_HP_PER_HOUR: int = 8
const SLEEP_DEPRIVATION_HP_PER_HOUR: int = 1

var _state: ActorConditionState = null
var _health: ActorHealthState = null
var _kernel: TickKernel = null
var _time_profile: WorldTimeProfile = null
var _modifiers: ActorConditionModifierQuery = null
var _applying_condition_damage: bool = false

func _init(
    condition_state: ActorConditionState = null,
    health_state: ActorHealthState = null,
    kernel: TickKernel = null,
    time_profile: WorldTimeProfile = null,
    modifier_query: ActorConditionModifierQuery = null
) -> void:
    _state = condition_state
    _health = health_state
    _kernel = kernel
    _time_profile = time_profile
    _modifiers = modifier_query
    _connect_signals()

func is_ready() -> bool:
    return _state != null and _state.is_ready() and _health != null and _kernel != null \
        and _time_profile != null and _time_profile.is_valid() \
        and _modifiers != null and _modifiers.is_ready()

func has_actor(actor_id: String) -> bool:
    return is_ready() and _state.has_actor(actor_id) and _health.has_actor(actor_id)

func value(actor_id: String, channel: StringName) -> int:
    return _modifiers.value(actor_id, channel) if has_actor(actor_id) else -1

func values(actor_id: String) -> Dictionary:
    return _modifiers.current_values(actor_id) if has_actor(actor_id) else {}

func modifier_snapshot(actor_id: String) -> Dictionary:
    return _modifiers.modifier_snapshot(actor_id) if has_actor(actor_id) else {"ok": false, "reason": "condition_unclassified"}

func effective_max_health(actor_id: String) -> int:
    return -1 if not has_actor(actor_id) else _modifiers.effective_max_health(actor_id, _health.max_hp(actor_id))

func current_fatigue(actor_id: String) -> int:
    return -1 if not has_actor(actor_id) else _modifiers.fatigue_value(actor_id)

func can_start_run(actor_id: String) -> bool:
    var fatigue: int = current_fatigue(actor_id)
    return fatigue >= 0 and fatigue <= RUN_MAX_START_FATIGUE

func set_condition(actor_id: String, channel: StringName, value_points: int, reason: StringName = &"condition_set") -> bool:
    if not has_actor(actor_id) or channel not in StateClass.CHANNELS or value_points < 0 or value_points > 100:
        return false
    if not _settle_actor(actor_id, _kernel.world_tick(), &"pre_condition_set"):
        return false
    var record_value: Dictionary = _state.record(actor_id)
    var values_raw: Dictionary = record_value.get("values_raw", {}).duplicate(true)
    values_raw[String(channel)] = value_points * StateClass.VALUE_SCALE
    record_value["values_raw"] = values_raw
    if not _state._set_record(actor_id, record_value, reason):
        return false
    _clamp_health_to_effective_max(actor_id)
    condition_changed.emit(actor_id, reason)
    return true

func change_condition(actor_id: String, channel: StringName, delta_points: int, reason: StringName = &"condition_changed") -> bool:
    if not has_actor(actor_id) or channel not in StateClass.CHANNELS:
        return false
    if delta_points == 0:
        return true
    if not _settle_actor(actor_id, _kernel.world_tick(), &"pre_condition_change"):
        return false
    var record_value: Dictionary = _state.record(actor_id)
    var values_raw: Dictionary = record_value.get("values_raw", {}).duplicate(true)
    var key: String = String(channel)
    values_raw[key] = clampi(int(values_raw.get(key, 0)) + delta_points * StateClass.VALUE_SCALE, 0, StateClass.RAW_MAX)
    record_value["values_raw"] = values_raw
    if not _state._set_record(actor_id, record_value, reason):
        return false
    _clamp_health_to_effective_max(actor_id)
    condition_changed.emit(actor_id, reason)
    return true

func add_fatigue(actor_id: String, points: int, reason: StringName = &"fatigue_added") -> bool:
    return apply_exertion(actor_id, points, reason)

func relieve_fatigue(actor_id: String, points: int, reason: StringName = &"fatigue_relieved") -> bool:
    if not has_actor(actor_id) or points < 0:
        return false
    if points == 0:
        return true
    var now: int = _kernel.world_tick()
    var record_value: Dictionary = _state.record(actor_id)
    var current_raw: int = _modifiers.fatigue_raw_at(actor_id, now)
    record_value["fatigue_raw"] = maxi(0, current_raw - points * StateClass.VALUE_SCALE)
    record_value["fatigue_anchor_tick"] = now
    if not _state._set_record(actor_id, record_value, reason):
        return false
    fatigue_changed.emit(actor_id, current_fatigue(actor_id), reason)
    return true

func apply_exertion(actor_id: String, fatigue_cost: int, reason: StringName = &"physical_exertion") -> bool:
    if not has_actor(actor_id) or fatigue_cost < 0:
        return false
    if fatigue_cost == 0:
        return true
    var now: int = _kernel.world_tick()
    if not _settle_actor(actor_id, now, &"pre_exertion"):
        return false
    var record_value: Dictionary = _state.record(actor_id)
    var start_raw: int = int(record_value.get("fatigue_raw", 0))
    var added_raw: int = int(ceili(float(fatigue_cost * StateClass.VALUE_SCALE * _modifiers.fatigue_gain_multiplier_bp(actor_id)) / 10000.0))
    var overflow_raw: int = maxi(0, start_raw + added_raw - StateClass.RAW_MAX)
    record_value["fatigue_raw"] = mini(StateClass.RAW_MAX, start_raw + added_raw)
    record_value["fatigue_anchor_tick"] = now
    var exertion_points: int = int(ceili(float(added_raw) / float(StateClass.VALUE_SCALE)))

    var metabolic: int = int(record_value.get("metabolic_exertion_remainder", 0)) + exertion_points
    var hydration: int = int(record_value.get("hydration_exertion_remainder", 0)) + exertion_points
    var satiety_loss: int = metabolic / SATIETY_EXERTION_PER_POINT
    var hydration_loss: int = hydration / HYDRATION_EXERTION_PER_POINT
    record_value["metabolic_exertion_remainder"] = metabolic % SATIETY_EXERTION_PER_POINT
    record_value["hydration_exertion_remainder"] = hydration % HYDRATION_EXERTION_PER_POINT
    var overexertion: int = int(record_value.get("overexertion_remainder", 0)) + overflow_raw
    var overexertion_damage: int = overexertion / OVEREXERTION_RAW_PER_HP
    record_value["overexertion_remainder"] = overexertion % OVEREXERTION_RAW_PER_HP
    var values_raw: Dictionary = record_value.get("values_raw", {}).duplicate(true)
    if satiety_loss > 0:
        values_raw[String(StateClass.SATIETY)] = maxi(0, int(values_raw[String(StateClass.SATIETY)]) - satiety_loss * StateClass.VALUE_SCALE)
    if hydration_loss > 0:
        values_raw[String(StateClass.HYDRATION)] = maxi(0, int(values_raw[String(StateClass.HYDRATION)]) - hydration_loss * StateClass.VALUE_SCALE)
    record_value["values_raw"] = values_raw
    if not _state._set_record(actor_id, record_value, reason):
        return false
    if overexertion_damage > 0 and _health.current_hp(actor_id) > 0:
        _applying_condition_damage = true
        _health.apply_damage(actor_id, overexertion_damage)
        _applying_condition_damage = false
    _clamp_health_to_effective_max(actor_id)
    fatigue_changed.emit(actor_id, current_fatigue(actor_id), reason)
    if satiety_loss > 0 or hydration_loss > 0:
        condition_changed.emit(actor_id, reason)
    return true

func snapshot_state() -> Dictionary:
    return _state.snapshot() if is_ready() else {}

func restore_state(snapshot: Dictionary) -> bool:
    if not is_ready() or not _state.load_snapshot(snapshot):
        return false
    for actor_id: String in _state.actor_ids():
        if _health.has_actor(actor_id):
            _clamp_health_to_effective_max(actor_id)
    return true

func _settle_actor(actor_id: String, world_tick: int, reason: StringName) -> bool:
    if not has_actor(actor_id) or world_tick < 0:
        return false
    var record_value: Dictionary = _state.record(actor_id)
    var anchor_tick: int = int(record_value.get("anchor_tick", -1))
    if anchor_tick < 0 or world_tick < anchor_tick:
        return false
    if world_tick == anchor_tick:
        _clamp_health_to_effective_max(actor_id)
        return true

    var damage_numerator: int = int(record_value.get("need_damage_remainder", 0))
    damage_numerator += _modifiers.zero_ticks_between(record_value, StateClass.HYDRATION, anchor_tick, world_tick) * DEHYDRATION_HP_PER_HOUR
    damage_numerator += _modifiers.zero_ticks_between(record_value, StateClass.SATIETY, anchor_tick, world_tick) * STARVATION_HP_PER_HOUR
    damage_numerator += _modifiers.zero_ticks_between(record_value, StateClass.REST, anchor_tick, world_tick) * SLEEP_DEPRIVATION_HP_PER_HOUR
    var ticks_per_hour: int = _time_profile.ticks_per_hour()
    var hp_damage: int = damage_numerator / ticks_per_hour
    record_value["need_damage_remainder"] = damage_numerator % ticks_per_hour
    var raw_values: Dictionary = _modifiers.raw_values_at(actor_id, world_tick)
    if raw_values.is_empty():
        return false
    record_value["values_raw"] = raw_values
    record_value["anchor_tick"] = world_tick
    record_value["fatigue_raw"] = _modifiers.fatigue_raw_at(actor_id, world_tick)
    record_value["fatigue_anchor_tick"] = world_tick
    if not _state._set_record(actor_id, record_value, reason):
        return false
    if hp_damage > 0 and _health.current_hp(actor_id) > 0:
        _applying_condition_damage = true
        _health.apply_damage(actor_id, hp_damage)
        _applying_condition_damage = false
    _clamp_health_to_effective_max(actor_id)
    return true

func _clamp_health_to_effective_max(actor_id: String) -> void:
    if not _health.has_actor(actor_id):
        return
    var maximum: int = effective_max_health(actor_id)
    if maximum > 0 and _health.current_hp(actor_id) > maximum:
        _health.set_hp(actor_id, maximum)

func _connect_signals() -> void:
    if _kernel != null:
        for pair: Array in [
            [_kernel.decision_required, Callable(self, "_on_decision_required")],
            [_kernel.action_started, Callable(self, "_on_action_started")],
            [_kernel.action_finished, Callable(self, "_on_action_finished")],
        ]:
            var source: Signal = pair[0]
            var callable: Callable = pair[1]
            if not source.is_connected(callable):
                source.connect(callable)
    if _health != null:
        var damage_callable := Callable(self, "_on_damage_applied")
        if not _health.damage_applied.is_connected(damage_callable):
            _health.damage_applied.connect(damage_callable)

func _on_decision_required(actor_id: String, world_tick: int) -> void:
    if has_actor(actor_id):
        _settle_actor(actor_id, world_tick, &"decision_settle")
        fatigue_changed.emit(actor_id, current_fatigue(actor_id), &"decision_settle")
        condition_changed.emit(actor_id, &"decision_settle")

func _on_action_started(action: TimedAction) -> void:
    if action == null or not has_actor(action.actor_id) or not _is_physical_action(action.action_type):
        return
    var record_value: Dictionary = _state.record(action.actor_id)
    record_value["fatigue_raw"] = _modifiers.fatigue_raw_at(action.actor_id, action.start_tick)
    record_value["fatigue_anchor_tick"] = action.start_tick
    _state._set_record(action.actor_id, record_value, &"physical_action_started")

func _on_action_finished(action: TimedAction) -> void:
    if action == null or not has_actor(action.actor_id):
        return
    if _is_physical_action(action.action_type):
        var record_value: Dictionary = _state.record(action.actor_id)
        record_value["fatigue_anchor_tick"] = _kernel.world_tick()
        _state._set_record(action.actor_id, record_value, &"physical_action_finished")
        return
    if action.status != Rules.ActionStatus.COMPLETED:
        return
    var action_text: String = String(action.action_type)
    if action_text.begins_with("craft"):
        change_condition(action.actor_id, StateClass.ENGAGEMENT, 6, &"meaningful_crafting")
    elif action_text.contains("scavenge") or action_text.contains("loot"):
        change_condition(action.actor_id, StateClass.ENGAGEMENT, 4, &"meaningful_scavenging")

func _on_damage_applied(actor_id: String, amount: int, _previous_hp: int, _current_hp: int, _version: int) -> void:
    if _applying_condition_damage or not has_actor(actor_id) or amount <= 0:
        return
    change_condition(actor_id, StateClass.CALM, -mini(30, 5 + amount), &"injury_fear")

static func _is_physical_action(action_type: StringName) -> bool:
    var text: String = String(action_type)
    return text.begins_with("movement.") or text.begins_with("stance.") or text.contains("run")
