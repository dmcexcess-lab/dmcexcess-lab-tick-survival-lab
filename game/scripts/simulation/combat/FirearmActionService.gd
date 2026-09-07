extends RefCounted
class_name FirearmActionService

const Rules = preload("res://scripts/foundation/time/TickRules.gd")
const Phase = preload("res://scripts/foundation/time/ActionPhase.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const Injury = preload("res://scripts/simulation/actors/health/ActorInjuryRecord.gd")

const FIRE_SNAP: StringName = &"combat.fire_snap"
const FIRE_AIMED: StringName = &"combat.fire_aimed"
const RELOAD: StringName = &"combat.reload"
const ACTION_IDS: Array[StringName] = [FIRE_SNAP, FIRE_AIMED, RELOAD]
const DISCHARGE_PHASE: StringName = &"combat.discharge"
const RELOAD_EJECT: StringName = &"combat.reload_eject"
const RELOAD_INSERT: StringName = &"combat.reload_insert"
const RELOAD_CHAMBER: StringName = &"combat.reload_chamber"

signal firearm_discharged(actor_id, action_serial, firearm_id, round_id, cell, power)
signal firearm_impact(actor_id, target_id, action_serial, cell, damage)
signal reload_progress(actor_id, action_serial, phase_id, firearm_id, magazine_id)

var _world: WorldState
var _world_mutations: WorldMutationService
var _spatial: SpatialQueryService
var _kernel: TickKernel
var _hands: ActorHandEquipmentState
var _health: ActorHealthState
var _inventory: InventoryContainmentState
var _inventory_mutations: InventoryContainmentMutationService
var _profiles: FirearmProfileCatalog
var _state: FirearmState

func _init(world=null, world_mutations=null, spatial=null, kernel=null, hands=null, health=null, inventory=null, inventory_mutations=null, profiles=null, state=null) -> void:
    _world=world; _world_mutations=world_mutations; _spatial=spatial; _kernel=kernel; _hands=hands; _health=health
    _inventory=inventory; _inventory_mutations=inventory_mutations; _profiles=profiles; _state=state
    if _kernel != null: _kernel.action_phase.connect(_on_action_phase)

func is_ready() -> bool:
    return _world != null and _world_mutations != null and _spatial != null and _kernel != null and _hands != null and _health != null and _inventory != null and _inventory_mutations != null and _profiles != null and _state != null and _state.is_ready()

func request_forward(actor_id: String) -> Dictionary:
    var firearm_id := _equipped_firearm(actor_id)
    if firearm_id.is_empty(): return {"accepted": false, "reason": "no_firearm"}
    if _state.chamber_round(firearm_id).is_empty(): return request_reload(actor_id)
    return request_fire(actor_id, FIRE_SNAP)

func request_fire(actor_id: String, action_id: StringName = FIRE_SNAP) -> Dictionary:
    if not is_ready() or not _actor_can_act(actor_id): return {"accepted": false, "reason": "actor_cannot_act"}
    if action_id != FIRE_SNAP and action_id != FIRE_AIMED: return {"accepted": false, "reason": "invalid_fire_action"}
    var firearm_id := _equipped_firearm(actor_id)
    if firearm_id.is_empty() or not _state.ensure_firearm(firearm_id): return {"accepted": false, "reason": "no_firearm"}
    var round_id := _state.chamber_round(firearm_id)
    if round_id.is_empty(): return {"accepted": false, "reason": "empty_chamber"}
    var placement := _world.placement(actor_id)
    if placement == null: return {"accepted": false, "reason": "no_placement"}
    var aimed := action_id == FIRE_AIMED
    var discharge_tick := 5 if aimed else 2
    var duration := 7 if aimed else 4
    var serial := _kernel.begin_action(actor_id, action_id, duration, Rules.InterruptionPolicy.COMMITTED, [Phase.new(DISCHARGE_PHASE, discharge_tick)], {
        "firearm_id": firearm_id, "round_id": round_id, "facing": placement.facing, "aimed": aimed
    })
    return {"accepted": serial > 0, "action_serial": serial, "reason": "" if serial > 0 else "when_rejected"}

func request_reload(actor_id: String) -> Dictionary:
    if not is_ready() or not _actor_can_act(actor_id): return {"accepted": false, "reason": "actor_cannot_act"}
    var firearm_id := _equipped_firearm(actor_id)
    if firearm_id.is_empty() or not _state.ensure_firearm(firearm_id): return {"accepted": false, "reason": "no_firearm"}
    var current_mag := _state.inserted_magazine(firearm_id)
    var candidate := _find_compatible_magazine(actor_id, firearm_id, current_mag)
    var phases: Array = []
    var offset := 0
    if not current_mag.is_empty() and not candidate.is_empty(): offset += 2; phases.append(Phase.new(RELOAD_EJECT, offset))
    if not candidate.is_empty(): offset += 3; phases.append(Phase.new(RELOAD_INSERT, offset))
    if _state.chamber_round(firearm_id).is_empty(): offset += 3; phases.append(Phase.new(RELOAD_CHAMBER, offset))
    if phases.is_empty(): return {"accepted": false, "reason": "nothing_to_reload"}
    var serial := _kernel.begin_action(actor_id, RELOAD, offset + 1, Rules.InterruptionPolicy.RESUMABLE, phases, {
        "firearm_id": firearm_id, "magazine_id": candidate, "original_magazine_id": current_mag
    })
    return {"accepted": serial > 0, "action_serial": serial, "reason": "" if serial > 0 else "when_rejected"}

func resume_reload(action_serial: int) -> bool:
    var action := _kernel.resumable_action(action_serial)
    return action != null and action.action_type == RELOAD and _kernel.resume_action(action_serial)

func _on_action_phase(action: TimedAction, phase: ActionPhase) -> void:
    if action == null or phase == null: return
    if action.action_type == FIRE_SNAP or action.action_type == FIRE_AIMED:
        if phase.phase_id == DISCHARGE_PHASE: _resolve_discharge(action)
        return
    if action.action_type != RELOAD: return
    var firearm_id := String(action.payload.get("firearm_id", ""))
    if _equipped_firearm(action.actor_id) != firearm_id:
        _kernel.fail_action(action.serial, "firearm_no_longer_held"); return
    var magazine_id := String(action.payload.get("magazine_id", ""))
    match phase.phase_id:
        RELOAD_EJECT:
            if not _state.eject_magazine(firearm_id, action.actor_id): _kernel.fail_action(action.serial, "reload_eject_failed"); return
        RELOAD_INSERT:
            if magazine_id.is_empty() or not _inventory.contains_directly(action.actor_id, magazine_id) or not _state.insert_magazine(firearm_id, magazine_id): _kernel.fail_action(action.serial, "reload_insert_failed"); return
        RELOAD_CHAMBER:
            if _state.chamber_round(firearm_id).is_empty() and _state.chamber_from_magazine(firearm_id).is_empty(): _kernel.fail_action(action.serial, "reload_chamber_failed"); return
        _:
            return
    reload_progress.emit(action.actor_id, action.serial, phase.phase_id, firearm_id, magazine_id)

func _resolve_discharge(action: TimedAction) -> void:
    var firearm_id := String(action.payload.get("firearm_id", ""))
    var round_id := String(action.payload.get("round_id", ""))
    if _equipped_firearm(action.actor_id) != firearm_id or _state.chamber_round(firearm_id) != round_id:
        _kernel.fail_action(action.serial, "firearm_state_changed"); return
    var firearm := _world.entity(firearm_id)
    var placement := _world.placement(action.actor_id)
    if firearm == null or placement == null: _kernel.fail_action(action.serial, "firearm_discharge_invalid"); return
    var aimed := bool(action.payload.get("aimed", false))
    var max_range := _profiles.max_range_cells(firearm.semantic_type) if aimed else _profiles.snap_range_cells(firearm.semantic_type)
    var direction := Facing.vector(int(action.payload.get("facing", placement.facing)))
    var hit_id := ""
    var hit_cell := placement.anchor + direction * max_range
    for distance in range(1, max_range + 1):
        var cell := placement.anchor + direction * distance
        if not _spatial.has_terrain(cell): hit_cell = cell; break
        var actors := _spatial.entities_at(cell, Layers.Channel.ACTOR)
        for candidate: String in actors:
            if candidate != action.actor_id and _health.has_actor(candidate) and _health.current_hp(candidate) > 0:
                hit_id = candidate; hit_cell = cell; break
        if not hit_id.is_empty(): break
        var query := _spatial.query_cell(cell, action.actor_id, true)
        if query.status != 0:
            hit_cell = cell; break
    var consumed := _state.release_chambered_round(firearm_id)
    if consumed != round_id or not _world_mutations.remove_entity(round_id): _kernel.fail_action(action.serial, "round_consumption_failed"); return
    _state.cycle_next_round(firearm_id)
    var power := _profiles.gunshot_power(firearm.semantic_type)
    firearm_discharged.emit(action.actor_id, action.serial, firearm_id, round_id, placement.anchor, power)
    if hit_id.is_empty(): return
    var damage := _profiles.impact_damage(firearm.semantic_type)
    _health.apply_damage(hit_id, damage)
    _health.add_injury(hit_id, &"gunshot", Injury.TORSO, Injury.Severity.CRITICAL)
    firearm_impact.emit(action.actor_id, hit_id, action.serial, hit_cell, damage)

func _actor_can_act(actor_id: String) -> bool:
    return _health.has_actor(actor_id) and _health.current_hp(actor_id) > 0 and _hands.has_actor(actor_id) and not _kernel.has_active_action(actor_id)

func _equipped_firearm(actor_id: String) -> String:
    if not _hands.has_actor(actor_id): return ""
    for item_id: String in [_hands.primary_item(actor_id), _hands.secondary_item(actor_id)]:
        if item_id.is_empty(): continue
        var entity := _world.entity(item_id)
        if entity != null and _profiles.has_firearm(entity.semantic_type): return item_id
    return ""

func _find_compatible_magazine(actor_id: String, firearm_id: String, excluded: String) -> String:
    var firearm := _world.entity(firearm_id)
    if firearm == null: return ""
    var required := _profiles.magazine_type(firearm.semantic_type)
    for item_id: String in _inventory.direct_contents(actor_id):
        if item_id == excluded: continue
        var item := _world.entity(item_id)
        if item != null and item.semantic_type == required and _state.ensure_magazine(item_id) and not _inventory.direct_contents(item_id).is_empty(): return item_id
    return ""
