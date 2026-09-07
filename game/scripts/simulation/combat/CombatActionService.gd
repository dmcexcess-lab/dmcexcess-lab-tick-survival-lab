extends RefCounted
class_name CombatActionService

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRulesClass = preload("res://scripts/foundation/time/TickRules.gd")
const InjuryClass = preload("res://scripts/simulation/actors/health/ActorInjuryRecord.gd")
const ProfileClass = preload("res://scripts/simulation/combat/CombatImpactProfile.gd")

signal attack_contact(attacker_id, action_serial, strike_cell, item_id)
signal attack_missed(attacker_id, action_serial, strike_cell)
signal impact_resolved(attacker_id, target_id, action_serial, strike_cell, damage, contact_mode)
signal shove_resolved(attacker_id, target_id, action_serial, displaced)

const STRIKE_PRIMARY: StringName = &"combat.strike_primary"
const STRIKE_SECONDARY: StringName = &"combat.strike_secondary"
const STRIKE_UNARMED: StringName = &"combat.strike_unarmed"
const SHOVE: StringName = &"combat.shove"
const ACTION_IDS: Array[StringName] = [STRIKE_PRIMARY, STRIKE_SECONDARY, STRIKE_UNARMED, SHOVE]
const CONTACT_PHASE: StringName = &"combat.contact"
const RESOLVE_EVENT: StringName = &"combat.resolve_impacts"
const RESOLVE_PRIORITY: int = 1000
const UNARMED_EFFECTIVE_MASS_GRAMS: int = 350

var _world: WorldState = null
var _mutations: WorldMutationService = null
var _spatial_query: SpatialQueryService = null
var _kernel: TickKernel = null
var _hands: ActorHandEquipmentState = null
var _health: ActorHealthState = null
var _condition: ActorConditionService = null
var _condition_modifiers: ActorConditionModifierQuery = null
var _physical_catalog: ItemPhysicalPropertyCatalog = null
var _impact_profiles: CombatImpactProfileCatalog = null
var _pending_by_tick: Dictionary = {}
var _resolution_scheduled: Dictionary = {}
var _contact_tick_by_serial: Dictionary = {}
var _fatigue_floor_by_serial: Dictionary = {}

func _init(
    world: WorldState = null,
    mutations: WorldMutationService = null,
    spatial_query: SpatialQueryService = null,
    kernel: TickKernel = null,
    hands: ActorHandEquipmentState = null,
    health: ActorHealthState = null,
    condition: ActorConditionService = null,
    condition_modifiers: ActorConditionModifierQuery = null,
    physical_catalog: ItemPhysicalPropertyCatalog = null,
    impact_profiles: CombatImpactProfileCatalog = null
) -> void:
    _world = world
    _mutations = mutations
    _spatial_query = spatial_query
    _kernel = kernel
    _hands = hands
    _health = health
    _condition = condition
    _condition_modifiers = condition_modifiers
    _physical_catalog = physical_catalog
    _impact_profiles = impact_profiles
    if _kernel != null:
        _kernel.action_phase.connect(_on_action_phase)
        _kernel.external_event_due.connect(_on_external_event)
        _kernel.action_finished.connect(_on_action_finished)
    if _health != null:
        _health.damage_applied.connect(_on_damage_applied)

func is_ready() -> bool:
    return _world != null and _mutations != null and _mutations.is_ready() \
        and _spatial_query != null and _spatial_query.is_ready() \
        and _kernel != null and _hands != null and _health != null \
        and _condition != null and _condition_modifiers != null \
        and _physical_catalog != null and _impact_profiles != null

func request_action(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    if action_id == SHOVE:
        return _begin_shove(actor_id, target_id)
    if action_id in [STRIKE_PRIMARY, STRIKE_SECONDARY, STRIKE_UNARMED]:
        return _begin_strike(actor_id, target_id, action_id)
    return _rejected("unsupported_combat_action")

func request_forward(actor_id: String) -> Dictionary:
    if not _actor_can_act(actor_id):
        return _rejected("combat_actor_unavailable")
    for action_id: StringName in [STRIKE_PRIMARY, STRIKE_SECONDARY, STRIKE_UNARMED]:
        if _strike_quote(actor_id, action_id).get("available", false):
            return _begin_strike(actor_id, "", action_id)
    return _rejected("no_striking_hand_available")

func action_offers_for_target(actor_id: String, target_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not _target_is_in_forward_contact(actor_id, target_id):
        return result
    for action_id: StringName in [STRIKE_PRIMARY, STRIKE_SECONDARY, STRIKE_UNARMED]:
        var quote: Dictionary = _strike_quote(actor_id, action_id)
        if bool(quote.get("available", false)):
            result.append(quote)
    result.append({
        "available": true,
        "action_id": SHOVE,
        "duration_ticks": 6,
        "contact_ticks": 3,
        "policy": TickRulesClass.InterruptionPolicy.COMMITTED,
        "label": "SHOVE · 6t · COMMITTED",
    })
    return result

func _begin_strike(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    if not _actor_can_act(actor_id):
        return _rejected("combat_actor_unavailable")
    if not target_id.is_empty() and not _target_is_in_forward_contact(actor_id, target_id):
        return _rejected("target_not_in_forward_contact")
    var quote: Dictionary = _strike_quote(actor_id, action_id)
    if not bool(quote.get("available", false)):
        return _rejected(String(quote.get("reason", "strike_unavailable")))
    var placement: WorldPlacement = _world.placement(actor_id)
    var strike_cell: Vector2i = placement.anchor + Facing.vector(placement.facing)
    var contact_ticks: int = int(quote.get("contact_ticks", 0))
    var duration_ticks: int = int(quote.get("duration_ticks", 0))
    var payload: Dictionary = {
        "kind": "strike",
        "intended_target": target_id,
        "item_id": String(quote.get("item_id", "")),
        "slot": int(quote.get("slot", -1)),
        "weight_grams": int(quote.get("weight_grams", UNARMED_EFFECTIVE_MASS_GRAMS)),
        "contact_mode": String(quote.get("contact_mode", "blunt")),
        "rigidity_bp": int(quote.get("rigidity_bp", 10000)),
        "leverage_bp": int(quote.get("leverage_bp", 10000)),
        "contact_transfer_bp": int(quote.get("contact_transfer_bp", 10000)),
        "latched_facing": placement.facing,
        "request_strike_cell": [strike_cell.x, strike_cell.y],
    }
    var serial: int = _kernel.begin_action(
        actor_id,
        action_id,
        duration_ticks,
        int(quote.get("policy", TickRulesClass.InterruptionPolicy.CANCELABLE)),
        [PhaseClass.new(CONTACT_PHASE, contact_ticks)],
        payload
    )
    if serial <= 0:
        return _rejected("combat_timing_rejected")
    _contact_tick_by_serial[serial] = _kernel.world_tick() + contact_ticks
    _apply_and_latch_exertion(actor_id, serial, int(quote.get("fatigue_cost", 1)), &"combat_strike")
    return {"accepted": true, "action_serial": serial, "reason": "", "duration_ticks": duration_ticks}

func _begin_shove(actor_id: String, target_id: String) -> Dictionary:
    if not _actor_can_act(actor_id) or not _target_is_in_forward_contact(actor_id, target_id):
        return _rejected("shove_target_unavailable")
    var placement: WorldPlacement = _world.placement(actor_id)
    var strike_cell: Vector2i = placement.anchor + Facing.vector(placement.facing)
    var serial: int = _kernel.begin_action(
        actor_id,
        SHOVE,
        6,
        TickRulesClass.InterruptionPolicy.COMMITTED,
        [PhaseClass.new(CONTACT_PHASE, 3)],
        {
            "kind": "shove",
            "intended_target": target_id,
            "item_id": "",
            "slot": -1,
            "latched_facing": placement.facing,
            "request_strike_cell": [strike_cell.x, strike_cell.y],
        }
    )
    if serial <= 0:
        return _rejected("combat_timing_rejected")
    _contact_tick_by_serial[serial] = _kernel.world_tick() + 3
    _apply_and_latch_exertion(actor_id, serial, 2, &"combat_shove")
    return {"accepted": true, "action_serial": serial, "reason": "", "duration_ticks": 6}

func _apply_and_latch_exertion(actor_id: String, serial: int, cost: int, reason: StringName) -> void:
    if not _condition.has_actor(actor_id):
        return
    if _condition.apply_exertion(actor_id, cost, reason):
        _fatigue_floor_by_serial[serial] = _condition.current_fatigue(actor_id)

func _strike_quote(actor_id: String, action_id: StringName) -> Dictionary:
    if not is_ready() or not _hands.has_actor(actor_id):
        return {"available": false, "reason": "hand_state_unavailable"}
    if action_id == STRIKE_UNARMED:
        if not _hands.primary_item(actor_id).is_empty() and not _hands.secondary_item(actor_id).is_empty():
            return {"available": false, "reason": "no_empty_hand"}
        return _quote_from_profile(action_id, "", -1, UNARMED_EFFECTIVE_MASS_GRAMS, _impact_profiles.unarmed_profile(), "FIST")
    var slot: int = Slots.Value.PRIMARY_RIGHT if action_id == STRIKE_PRIMARY else Slots.Value.SECONDARY_LEFT
    var item_id: String = _hands.item_in_slot(actor_id, slot)
    if item_id.is_empty() or not _world.has_entity(item_id):
        return {"available": false, "reason": "hand_empty"}
    var entity: WorldEntityRecord = _world.entity(item_id)
    if entity == null:
        return {"available": false, "reason": "item_missing"}
    var weight: int = _physical_catalog.weight_grams(entity.semantic_type)
    if weight <= 0:
        return {"available": false, "reason": "item_mass_unclassified"}
    var profile: CombatImpactProfile = _impact_profiles.profile_for_item(entity.semantic_type, weight)
    if profile == null or not profile.is_valid():
        return {"available": false, "reason": "item_impact_unclassified"}
    var side: String = "R" if slot == Slots.Value.PRIMARY_RIGHT else "L"
    return _quote_from_profile(action_id, item_id, slot, weight, profile, "%s [%s]" % [_item_label(entity.semantic_type), side])

func _quote_from_profile(action_id: StringName, item_id: String, slot: int, weight: int, profile: CombatImpactProfile, display: String) -> Dictionary:
    if profile == null or not profile.is_valid():
        return {"available": false, "reason": "impact_profile_invalid"}
    var weight_ticks: int = maxi(1, ceili(float(weight) / 800.0))
    var handling_penalty: int = maxi(0, ceili(float(10000 - mini(10000, profile.balance_bp)) / 2500.0))
    var contact_ticks: int = clampi(2 + weight_ticks + handling_penalty, 3, 8)
    var duration_ticks: int = contact_ticks + 3 + maxi(0, ceili(float(weight) / 1400.0))
    var policy: int = TickRulesClass.InterruptionPolicy.COMMITTED if weight >= 900 else TickRulesClass.InterruptionPolicy.CANCELABLE
    var policy_label: String = "COMMITTED" if policy == TickRulesClass.InterruptionPolicy.COMMITTED else "INTERRUPTIBLE"
    return {
        "available": true,
        "action_id": action_id,
        "item_id": item_id,
        "slot": slot,
        "weight_grams": weight,
        "contact_mode": String(profile.contact_mode),
        "rigidity_bp": profile.rigidity_bp,
        "leverage_bp": profile.leverage_bp,
        "contact_transfer_bp": profile.contact_transfer_bp,
        "contact_ticks": contact_ticks,
        "duration_ticks": duration_ticks,
        "fatigue_cost": 1 + maxi(1, ceili(float(weight) / 900.0)),
        "policy": policy,
        "label": "STRIKE — %s · %dt · %s" % [display, duration_ticks, policy_label],
    }

func _on_action_phase(action: TimedAction, phase: ActionPhase) -> void:
    if action == null or phase == null or phase.phase_id != CONTACT_PHASE or action.action_type not in ACTION_IDS:
        return
    var placement: WorldPlacement = _world.placement(action.actor_id)
    if placement == null or placement.channel != Layers.Channel.ACTOR:
        _kernel.fail_action(action.serial, "attacker_unplaced")
        return
    var expected_facing: int = int(action.payload.get("latched_facing", -1))
    if placement.facing != expected_facing:
        _kernel.fail_action(action.serial, "attacker_facing_changed")
        return
    var item_id: String = String(action.payload.get("item_id", ""))
    var slot: int = int(action.payload.get("slot", -1))
    if slot >= 0 and (_hands.item_in_slot(action.actor_id, slot) != item_id or not _world.has_entity(item_id)):
        _kernel.fail_action(action.serial, "striking_item_changed")
        return
    if action.action_type == STRIKE_UNARMED and not _hands.primary_item(action.actor_id).is_empty() and not _hands.secondary_item(action.actor_id).is_empty():
        _kernel.fail_action(action.serial, "striking_hand_filled")
        return
    var strike_cell: Vector2i = placement.anchor + Facing.vector(expected_facing)
    var intent: Dictionary = action.payload.duplicate(true)
    intent["attacker_id"] = action.actor_id
    intent["action_serial"] = action.serial
    intent["strike_cell"] = [strike_cell.x, strike_cell.y]
    intent["tick"] = _kernel.world_tick()
    if not _pending_by_tick.has(_kernel.world_tick()):
        _pending_by_tick[_kernel.world_tick()] = []
    var pending: Array = _pending_by_tick[_kernel.world_tick()]
    pending.append(intent)
    _pending_by_tick[_kernel.world_tick()] = pending
    attack_contact.emit(action.actor_id, action.serial, strike_cell, item_id)
    if not _resolution_scheduled.has(_kernel.world_tick()):
        var event_serial: int = _kernel.schedule_event(
            _kernel.world_tick(), "combat", RESOLVE_EVENT, "", {"tick": _kernel.world_tick()}, RESOLVE_PRIORITY
        )
        if event_serial <= 0:
            _kernel.fail_action(action.serial, "impact_resolution_schedule_failed")
            return
        _resolution_scheduled[_kernel.world_tick()] = event_serial

func _on_external_event(event: ScheduledEvent) -> void:
    if event == null or event.event_type != RESOLVE_EVENT:
        return
    var tick: int = int(event.payload.get("tick", -1))
    _resolution_scheduled.erase(tick)
    var value: Variant = _pending_by_tick.get(tick, [])
    _pending_by_tick.erase(tick)
    if typeof(value) != TYPE_ARRAY:
        return
    var intents: Array = value
    intents.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var aa: String = String(a.get("attacker_id", ""))
        var ba: String = String(b.get("attacker_id", ""))
        if aa != ba: return aa < ba
        return int(a.get("action_serial", 0)) < int(b.get("action_serial", 0))
    )
    var actor_snapshot: Dictionary = _actor_snapshot_for_intents(intents)
    var resolved: Array[Dictionary] = []
    for intent_value: Variant in intents:
        if typeof(intent_value) != TYPE_DICTIONARY:
            continue
        var intent: Dictionary = intent_value
        var cell := _cell_from_payload(intent.get("strike_cell", []))
        var target_id: String = _choose_target(intent, actor_snapshot.get(cell, []))
        resolved.append({"intent": intent, "target_id": target_id, "cell": cell})
    for resolution: Dictionary in resolved:
        _apply_resolution(resolution)

func _actor_snapshot_for_intents(intents: Array) -> Dictionary:
    var cells: Dictionary = {}
    for intent_value: Variant in intents:
        if typeof(intent_value) != TYPE_DICTIONARY:
            continue
        var cell := _cell_from_payload((intent_value as Dictionary).get("strike_cell", []))
        cells[cell] = true
    var result: Dictionary = {}
    for value: Variant in cells.keys():
        var cell: Vector2i = value
        var ids: Array[String] = []
        for actor_id: String in _world.entities_at(cell, Layers.Channel.ACTOR):
            if _health.has_actor(actor_id) and _health.current_hp(actor_id) > 0:
                ids.append(actor_id)
        ids.sort()
        result[cell] = ids
    return result

func _choose_target(intent: Dictionary, candidates_value: Variant) -> String:
    var candidates: Array = candidates_value if typeof(candidates_value) == TYPE_ARRAY else []
    var attacker: String = String(intent.get("attacker_id", ""))
    var intended: String = String(intent.get("intended_target", ""))
    if not intended.is_empty() and intended != attacker and candidates.has(intended):
        return intended
    for value: Variant in candidates:
        var candidate: String = String(value)
        if candidate != attacker:
            return candidate
    return ""

func _apply_resolution(resolution: Dictionary) -> void:
    var intent: Dictionary = resolution.get("intent", {})
    var attacker: String = String(intent.get("attacker_id", ""))
    var serial: int = int(intent.get("action_serial", 0))
    var target: String = String(resolution.get("target_id", ""))
    var cell: Vector2i = resolution.get("cell", Vector2i.ZERO)
    if target.is_empty():
        attack_missed.emit(attacker, serial, cell)
        return
    if String(intent.get("kind", "")) == "shove":
        var displaced: bool = _resolve_shove(attacker, target)
        shove_resolved.emit(attacker, target, serial, displaced)
        impact_resolved.emit(attacker, target, serial, cell, 0, &"blunt")
        return
    var damage: int = _derived_damage(attacker, intent)
    if damage <= 0 or not _health.apply_damage(target, damage):
        attack_missed.emit(attacker, serial, cell)
        return
    var contact_mode := StringName(String(intent.get("contact_mode", "blunt")))
    _health.add_injury(target, _injury_type(contact_mode), _body_region(attacker, target, serial), _severity_for_damage(damage))
    impact_resolved.emit(attacker, target, serial, cell, damage, contact_mode)

func _derived_damage(attacker_id: String, intent: Dictionary) -> int:
    var mass: int = maxi(1, int(intent.get("weight_grams", UNARMED_EFFECTIVE_MASS_GRAMS)))
    var value: int = maxi(1, ceili(float(mass) / 180.0))
    value = maxi(1, int(round(float(value * int(intent.get("rigidity_bp", 10000))) / 10000.0)))
    value = maxi(1, int(round(float(value * int(intent.get("leverage_bp", 10000))) / 10000.0)))
    value = maxi(1, int(round(float(value * int(intent.get("contact_transfer_bp", 10000))) / 10000.0)))
    var body_bp: int = _condition_modifiers.melee_damage_multiplier_bp(attacker_id) if _condition_modifiers.has_actor(attacker_id) else 10000
    return clampi(maxi(1, int(round(float(value * body_bp) / 10000.0))), 1, 25)

func _resolve_shove(attacker_id: String, target_id: String) -> bool:
    var attacker: WorldPlacement = _world.placement(attacker_id)
    var target: WorldPlacement = _world.placement(target_id)
    if attacker == null or target == null:
        return false
    var destination: Vector2i = target.anchor + Facing.vector(attacker.facing)
    var query: SpatialQueryResult = _spatial_query.query_entity_footprint(target_id, destination, target.facing, true)
    if query == null or not query.is_clear():
        return false
    if not _mutations.set_placement(target_id, Layers.Channel.ACTOR, destination, target.facing, target.footprint):
        return false
    var active: TimedAction = _kernel.active_action_for_actor(target_id)
    if active != null:
        _kernel.interrupt_action(active.serial, "shoved")
    return true

func _on_damage_applied(actor_id: String, _amount: int, _previous_hp: int, _current_hp: int, _version: int) -> void:
    var active: TimedAction = _kernel.active_action_for_actor(actor_id) if _kernel != null else null
    if active == null or not String(active.action_type).begins_with("combat."):
        return
    var contact_tick: int = int(_contact_tick_by_serial.get(active.serial, -1))
    if contact_tick >= 0 and _kernel.world_tick() < contact_tick:
        _kernel.interrupt_action(active.serial, "damage")

func _on_action_finished(action: TimedAction) -> void:
    if action == null:
        return
    _contact_tick_by_serial.erase(action.serial)
    if _fatigue_floor_by_serial.has(action.serial) and _condition.has_actor(action.actor_id):
        var floor_value: int = int(_fatigue_floor_by_serial[action.serial])
        var current: int = _condition.current_fatigue(action.actor_id)
        if current >= 0 and current < floor_value:
            _condition.apply_exertion(action.actor_id, floor_value - current, &"combat_action_no_recovery")
    _fatigue_floor_by_serial.erase(action.serial)

func _actor_can_act(actor_id: String) -> bool:
    if not is_ready() or actor_id.strip_edges().is_empty() or not _health.has_actor(actor_id) or _health.current_hp(actor_id) <= 0:
        return false
    var entity: WorldEntityRecord = _world.entity(actor_id)
    var placement: WorldPlacement = _world.placement(actor_id)
    return entity != null and String(entity.semantic_type).begins_with("actor.") \
        and placement != null and placement.channel == Layers.Channel.ACTOR and Facing.is_valid(placement.facing) \
        and _hands.has_actor(actor_id) and not _kernel.has_active_action(actor_id)

func _target_is_in_forward_contact(actor_id: String, target_id: String) -> bool:
    if not _actor_can_act(actor_id) or target_id.is_empty() or target_id == actor_id \
        or not _health.has_actor(target_id) or _health.current_hp(target_id) <= 0:
        return false
    var actor: WorldPlacement = _world.placement(actor_id)
    var target: WorldPlacement = _world.placement(target_id)
    if target == null or target.channel != Layers.Channel.ACTOR:
        return false
    var strike_cell: Vector2i = actor.anchor + Facing.vector(actor.facing)
    return strike_cell in target.world_cells()

static func _severity_for_damage(damage: int) -> int:
    if damage >= 10: return InjuryClass.Severity.CRITICAL
    if damage >= 5: return InjuryClass.Severity.SERIOUS
    return InjuryClass.Severity.MINOR

static func _injury_type(mode: StringName) -> StringName:
    if mode == ProfileClass.POINT: return &"puncture"
    if mode == ProfileClass.EDGE: return &"laceration"
    return &"blunt_trauma"

static func _body_region(attacker: String, target: String, serial: int) -> StringName:
    var regions: Array[StringName] = InjuryClass.regions()
    var seed: int = serial * 16777619
    for text: String in [attacker, target]:
        for index: int in range(text.length()):
            seed = int((seed ^ text.unicode_at(index)) * 16777619) & 0x7fffffff
    return regions[seed % regions.size()]

static func _cell_from_payload(value: Variant) -> Vector2i:
    if typeof(value) == TYPE_ARRAY and value.size() == 2:
        return Vector2i(int(value[0]), int(value[1]))
    return Vector2i(2147483647, 2147483647)

static func _item_label(semantic_type: StringName) -> String:
    var text: String = String(semantic_type)
    if text.begins_with("item."):
        text = text.trim_prefix("item.")
    var parts: PackedStringArray = text.split(".")
    text = parts[parts.size() - 1] if not parts.is_empty() else text
    return text.replace("_", " ").to_upper()

static func _rejected(reason: String) -> Dictionary:
    return {"accepted": false, "action_serial": 0, "reason": reason}
