extends RefCounted
class_name VehicleActionService

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRulesClass = preload("res://scripts/foundation/time/TickRules.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")

signal action_completed(actor_id, vehicle_id, action_serial, action_type, reason)
signal action_failed(actor_id, vehicle_id, action_serial, action_type, reason)
signal mounted_changed(actor_id, vehicle_id, mounted)

const COMMIT_PHASE := &"vehicle.commit"
const MOVE := &"vehicle.move"
const TURN_LEFT := &"vehicle.turn_left"
const TURN_RIGHT := &"vehicle.turn_right"
const REVERSE := &"vehicle.reverse"
const BRAKE := &"vehicle.brake"
const ENTER := &"vehicle.enter"
const EXIT := &"vehicle.exit"
const START := &"vehicle.start"
const HOTWIRE := &"vehicle.hotwire"
const REPAIR := &"vehicle.repair"
const MODIFY := &"vehicle.modify"
const REFUEL := &"vehicle.refuel"

var _world: WorldState
var _mutations: WorldMutationService
var _query: SpatialQueryService
var _overrides: CollisionOverrideState
var _kernel: TickKernel
var _skills: ActorSkillCheckService
var _conditions: ActorConditionService
var _inventory: InventoryContainmentState
var _inventory_mutations: InventoryContainmentMutationService
var _profiles: VehicleProfileCatalog
var _state: VehicleState
var _outcomes: Dictionary = {}

func _init(world: WorldState, mutations: WorldMutationService, query: SpatialQueryService, overrides: CollisionOverrideState, kernel: TickKernel, skills: ActorSkillCheckService, conditions: ActorConditionService, inventory: InventoryContainmentState, inventory_mutations: InventoryContainmentMutationService, profiles: VehicleProfileCatalog, state: VehicleState) -> void:
    _world = world
    _mutations = mutations
    _query = query
    _overrides = overrides
    _kernel = kernel
    _skills = skills
    _conditions = conditions
    _inventory = inventory
    _inventory_mutations = inventory_mutations
    _profiles = profiles
    _state = state
    if _kernel != null:
        _kernel.action_phase.connect(_on_action_phase)
        _kernel.action_finished.connect(_on_action_finished)

func is_ready() -> bool:
    return _world != null and _mutations != null and _query != null and _overrides != null and _kernel != null and _skills != null and _conditions != null and _inventory != null and _inventory_mutations != null and _profiles != null and _state != null

func vehicle_for_driver(actor_id: String) -> String:
    return _state.vehicle_for_driver(actor_id) if _state != null else ""

func is_mounted(actor_id: String) -> bool:
    return not vehicle_for_driver(actor_id).is_empty()

func request_enter_nearby(actor_id: String) -> Dictionary:
    if not _can_request(actor_id):
        return _reject("vehicle_not_ready")
    if is_mounted(actor_id):
        return _reject("already_mounted")
    var actor_place := _world.placement(actor_id)
    if actor_place == null:
        return _reject("actor_unplaced")
    var nearest: String = ""
    for cell: Vector2i in [actor_place.anchor, actor_place.anchor + Vector2i.UP, actor_place.anchor + Vector2i.RIGHT, actor_place.anchor + Vector2i.DOWN, actor_place.anchor + Vector2i.LEFT]:
        for entity_id: String in _world.entities_at(cell, Layers.Channel.OBJECT):
            if _state.has_vehicle(entity_id):
                nearest = entity_id
                break
        if not nearest.is_empty():
            break
    if nearest.is_empty():
        return _reject("no_vehicle_in_reach")
    return _begin(actor_id, nearest, ENTER, 4, {})

func request_exit(actor_id: String) -> Dictionary:
    var vehicle_id := vehicle_for_driver(actor_id)
    if vehicle_id.is_empty():
        return _reject("not_mounted")
    if bool(_state.record(vehicle_id).get("moving", false)):
        return _reject("vehicle_moving")
    return _begin(actor_id, vehicle_id, EXIT, 4, {})

func request_forward(actor_id: String) -> Dictionary:
    return _begin_motion(actor_id, MOVE, 0)

func request_turn_left(actor_id: String) -> Dictionary:
    return _begin_motion(actor_id, TURN_LEFT, -1)

func request_turn_right(actor_id: String) -> Dictionary:
    return _begin_motion(actor_id, TURN_RIGHT, 1)

func request_reverse(actor_id: String) -> Dictionary:
    return _begin_motion(actor_id, REVERSE, 0, 1)

func request_brake(actor_id: String) -> Dictionary:
    var vehicle_id := vehicle_for_driver(actor_id)
    if vehicle_id.is_empty():
        return _reject("not_mounted")
    var rec := _state.record(vehicle_id)
    if not bool(rec.get("moving", false)):
        return _reject("vehicle_already_stopped")
    if StringName(rec.get("kind", &"")) == VehicleProfileCatalog.SKATEBOARD:
        _state.mutate(vehicle_id, {"moving": false})
        return {"accepted": true, "instant": true, "action_serial": 0}
    return _begin(actor_id, vehicle_id, BRAKE, 2, {"distance": 2})

func request_start(actor_id: String) -> Dictionary:
    var vehicle_id := vehicle_for_driver(actor_id)
    if vehicle_id.is_empty():
        return _reject("not_mounted")
    var rec := _state.record(vehicle_id)
    var kind := StringName(rec.get("kind", &""))
    if not _profiles.is_motorized(kind):
        return _reject("vehicle_not_motorized")
    if bool(rec.get("powered", false)):
        return _reject("vehicle_already_started")
    if int(rec.get("propulsion", 0)) <= 0 or int(rec.get("electrical", 0)) <= 0:
        return _reject("vehicle_disabled")
    if int(rec.get("fuel", 0)) <= 0:
        return _reject("vehicle_out_of_fuel")
    if not bool(rec.get("key_in_ignition", false)) and not bool(rec.get("hotwired", false)):
        return _reject("ignition_requires_hotwire")
    return _begin(actor_id, vehicle_id, START, 3, {})

func request_hotwire(actor_id: String, vehicle_id: String = "") -> Dictionary:
    var target := vehicle_id
    if target.is_empty():
        target = _nearby_vehicle(actor_id)
    if target.is_empty() or not _state.has_vehicle(target):
        return _reject("no_vehicle_in_reach")
    var rec := _state.record(target)
    var kind := StringName(rec.get("kind", &""))
    if not _profiles.is_motorized(kind):
        return _reject("vehicle_not_motorized")
    if bool(rec.get("key_in_ignition", false)):
        return _reject("ignition_key_present")
    if bool(rec.get("hotwired", false)):
        return _reject("vehicle_already_hotwired")
    if not _has_semantic(actor_id, &"item.tool.screwdriver") or not _has_semantic(actor_id, &"item.junk.scrap_wire"):
        return _reject("hotwire_requires_screwdriver_and_wire")
    var difficulty := _profiles.hotwire_difficulty(kind)
    var skill := _skills.action_profile(actor_id, SkillCatalog.MECHANICAL, 12, difficulty)
    if not bool(skill.get("ok", false)):
        return _reject(String(skill.get("reason", "mechanical_unavailable")))
    return _begin(actor_id, target, HOTWIRE, int(skill.get("duration_ticks", 12)), {"difficulty": difficulty, "skill_level": int(skill.get("skill_level", -1))})

func request_repair(actor_id: String, vehicle_id: String = "") -> Dictionary:
    var target := vehicle_id if not vehicle_id.is_empty() else _nearby_vehicle(actor_id)
    if target.is_empty():
        return _reject("no_vehicle_in_reach")
    if not _has_semantic(actor_id, &"item.tool.adjustable_wrench"):
        return _reject("repair_requires_wrench")
    if not _has_any_semantic(actor_id, [&"item.crafting.metal_scrap", &"item.junk.rusted_fasteners", &"item.material.screws_box"]):
        return _reject("repair_requires_parts")
    var kind := StringName(_state.record(target).get("kind", &""))
    var difficulty := int(_profiles.profile(kind).get("repair_difficulty", 2))
    var skill := _skills.action_profile(actor_id, SkillCatalog.MECHANICAL, 16, difficulty)
    if not bool(skill.get("ok", false)):
        return _reject(String(skill.get("reason", "mechanical_unavailable")))
    return _begin(actor_id, target, REPAIR, int(skill.get("duration_ticks", 16)), {"difficulty": difficulty, "skill_level": int(skill.get("skill_level", -1))})

func request_modify(actor_id: String, vehicle_id: String = "") -> Dictionary:
    var target := vehicle_id if not vehicle_id.is_empty() else _nearby_vehicle(actor_id)
    if target.is_empty():
        return _reject("no_vehicle_in_reach")
    var existing_mods: Array = _state.record(target).get("mods", [])
    if &"cargo_rack" in existing_mods:
        return _reject("cargo_rack_already_installed")
    if not _has_semantic(actor_id, &"item.tool.adjustable_wrench") or not _has_semantic(actor_id, &"item.automotive.cargo_rack"):
        return _reject("modify_requires_wrench_and_cargo_rack")
    var skill := _skills.action_profile(actor_id, SkillCatalog.MECHANICAL, 20, 4)
    if not bool(skill.get("ok", false)):
        return _reject(String(skill.get("reason", "mechanical_unavailable")))
    return _begin(actor_id, target, MODIFY, int(skill.get("duration_ticks", 20)), {"difficulty": 4, "skill_level": int(skill.get("skill_level", -1))})

func request_refuel(actor_id: String, vehicle_id: String = "") -> Dictionary:
    var target := vehicle_id if not vehicle_id.is_empty() else _nearby_vehicle(actor_id)
    if target.is_empty():
        return _reject("no_vehicle_in_reach")
    var kind := StringName(_state.record(target).get("kind", &""))
    if not _profiles.is_motorized(kind):
        return _reject("vehicle_not_motorized")
    if not _has_semantic(actor_id, &"item.automotive.gas_can"):
        return _reject("refuel_requires_gas_can")
    return _begin(actor_id, target, REFUEL, 8, {})

func _begin_motion(actor_id: String, action_type: StringName, heading_delta: int, distance_override: int = 0) -> Dictionary:
    var vehicle_id := vehicle_for_driver(actor_id)
    if vehicle_id.is_empty():
        return _reject("not_mounted")
    var rec := _state.record(vehicle_id)
    var kind := StringName(rec.get("kind", &""))
    if _profiles.is_motorized(kind) and not bool(rec.get("powered", false)):
        return _reject("vehicle_not_started")
    if _profiles.is_motorized(kind) and int(rec.get("fuel", 0)) < _profiles.fuel_per_move(kind):
        return _reject("vehicle_out_of_fuel")
    var start_heading := int(rec.get("heading", 0))
    var target_heading := VehicleHeading.normalize(start_heading + heading_delta)
    var distance := distance_override if distance_override > 0 else _profiles.movement_cells(kind)
    if kind == VehicleProfileCatalog.SKATEBOARD and heading_delta != 0:
        target_heading = VehicleHeading.completed_turn_heading(start_heading, heading_delta)
    elif heading_delta != 0:
        target_heading = VehicleHeading.completed_turn_heading(start_heading, heading_delta)
        distance = 3
    return _begin(actor_id, vehicle_id, action_type, 3, {"start_heading": start_heading, "heading": target_heading, "turn_direction": heading_delta, "distance": distance})

func _begin(actor_id: String, vehicle_id: String, action_type: StringName, duration: int, payload: Dictionary) -> Dictionary:
    if not _can_request(actor_id) or not _state.has_vehicle(vehicle_id):
        return _reject("vehicle_not_ready")
    var data := payload.duplicate(true)
    data["vehicle_id"] = vehicle_id
    var phases: Array[ActionPhase] = [PhaseClass.new(COMMIT_PHASE, maxi(1, duration))]
    var serial := _kernel.begin_action(actor_id, action_type, maxi(1, duration), TickRulesClass.InterruptionPolicy.CANCELABLE, phases, data)
    if serial <= 0:
        return _reject("vehicle_timing_rejected")
    return {"accepted": true, "reason": "", "action_serial": serial, "duration_ticks": duration, "vehicle_id": vehicle_id}

func _on_action_phase(action: TimedAction, phase: ActionPhase) -> void:
    if action == null or phase == null or phase.phase_id != COMMIT_PHASE or not String(action.action_type).begins_with("vehicle."):
        return
    var vehicle_id := String(action.payload.get("vehicle_id", ""))
    var ok: bool = false
    var reason: String = "vehicle_action_failed"
    match action.action_type:
        ENTER:
            ok = _commit_enter(action.actor_id, vehicle_id)
            reason = "enter_failed"
        EXIT:
            ok = _commit_exit(action.actor_id, vehicle_id)
            reason = "exit_failed"
        MOVE, TURN_LEFT, TURN_RIGHT, REVERSE, BRAKE:
            var result := _commit_motion(action.actor_id, vehicle_id, action)
            ok = bool(result.get("ok", false))
            reason = String(result.get("reason", "movement_blocked"))
        START:
            ok = _state.mutate(vehicle_id, {"powered": true})
            reason = "start_failed"
        HOTWIRE:
            var result := _commit_skill_action(action, vehicle_id, HOTWIRE)
            ok = bool(result.get("ok", false))
            reason = String(result.get("reason", "hotwire_failed"))
        REPAIR:
            var result := _commit_skill_action(action, vehicle_id, REPAIR)
            ok = bool(result.get("ok", false))
            reason = String(result.get("reason", "repair_failed"))
        MODIFY:
            var result := _commit_skill_action(action, vehicle_id, MODIFY)
            ok = bool(result.get("ok", false))
            reason = String(result.get("reason", "modify_failed"))
        REFUEL:
            ok = _commit_refuel(action.actor_id, vehicle_id)
            reason = "refuel_failed"
    _outcomes[action.serial] = {"success": ok, "reason": "" if ok else reason, "vehicle_id": vehicle_id}

func _on_action_finished(action: TimedAction) -> void:
    if action == null or not String(action.action_type).begins_with("vehicle."):
        return
    var outcome: Dictionary = _outcomes.get(action.serial, {})
    var vehicle_id := String(action.payload.get("vehicle_id", ""))
    if action.status == TickRulesClass.ActionStatus.COMPLETED and bool(outcome.get("success", false)):
        action_completed.emit(action.actor_id, vehicle_id, action.serial, action.action_type, "")
    else:
        action_failed.emit(action.actor_id, vehicle_id, action.serial, action.action_type, String(outcome.get("reason", action.reason)))
    _outcomes.erase(action.serial)

func _commit_enter(actor_id: String, vehicle_id: String) -> bool:
    var vehicle_place := _world.placement(vehicle_id)
    var actor_place := _world.placement(actor_id)
    if vehicle_place == null or actor_place == null:
        return false
    if not _state.set_driver(vehicle_id, actor_id):
        return false
    _overrides.set_override(actor_id, false)
    _mutations.set_placement(actor_id, Layers.Channel.ACTOR, vehicle_place.anchor, Facing.Value.NORTH, Footprint.single_cell())
    mounted_changed.emit(actor_id, vehicle_id, true)
    return true

func _commit_exit(actor_id: String, vehicle_id: String) -> bool:
    var vehicle_place := _world.placement(vehicle_id)
    if vehicle_place == null:
        return false
    for delta: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
        var target := vehicle_place.anchor + delta
        var check := _query.query_cell(target, actor_id, true)
        if check != null and check.is_clear():
            if not _mutations.set_placement(actor_id, Layers.Channel.ACTOR, target, Facing.Value.NORTH, Footprint.single_cell()):
                continue
            _overrides.clear_override(actor_id)
            _state.clear_driver(vehicle_id)
            mounted_changed.emit(actor_id, vehicle_id, false)
            return true
    return false

func _commit_motion(actor_id: String, vehicle_id: String, action: TimedAction) -> Dictionary:
    var rec := _state.record(vehicle_id)
    var kind := StringName(rec.get("kind", &""))
    var heading := int(action.payload.get("heading", rec.get("heading", 0)))
    var distance := int(action.payload.get("distance", 2 if action.action_type == BRAKE else _profiles.movement_cells(kind)))
    var placement := _world.placement(vehicle_id)
    if placement == null:
        return {"ok": false, "reason": "vehicle_unplaced"}
    var is_true_vehicle_turn := action.action_type in [TURN_LEFT, TURN_RIGHT] and kind != VehicleProfileCatalog.SKATEBOARD
    var turn_direction := int(action.payload.get("turn_direction", 0))
    var start_heading := int(action.payload.get("start_heading", rec.get("heading", 0)))
    var path := VehicleHeading.turn_path(start_heading, turn_direction) if is_true_vehicle_turn else (VehicleHeading.reverse_path(heading, distance) if action.action_type == REVERSE else VehicleHeading.forward_path(heading, distance))
    var current_anchor := placement.anchor
    var facing := VehicleHeading.cardinal_facing(heading)
    for step_index: int in range(path.size()):
        var relative: Vector2i = path[step_index]
        var step_facing := VehicleHeading.cardinal_facing(VehicleHeading.normalize(start_heading + turn_direction * (step_index + 1))) if is_true_vehicle_turn else facing
        var target := placement.anchor + relative
        if kind == VehicleProfileCatalog.SKATEBOARD and not _skateboard_surface_ok(target, placement.footprint, step_facing):
            _state.mutate(vehicle_id, {"moving": false})
            return {"ok": false, "reason": "skateboard_requires_smooth_surface"}
        var check := _query.query_footprint(target, step_facing, placement.footprint, vehicle_id, true)
        if check == null or not check.is_clear():
            _state.mutate(vehicle_id, {"moving": false, "body": int(rec.get("body", 100)) - 8})
            return {"ok": false, "reason": "vehicle_collision"}
        current_anchor = target
    if not _mutations.set_placement(vehicle_id, Layers.Channel.OBJECT, current_anchor, facing, placement.footprint):
        return {"ok": false, "reason": "vehicle_move_commit_failed"}
    if not _mutations.set_placement(actor_id, Layers.Channel.ACTOR, current_anchor, facing, Footprint.single_cell()):
        return {"ok": false, "reason": "vehicle_driver_move_commit_failed"}
    var patch := {"heading": heading, "moving": action.action_type not in [BRAKE, REVERSE]}
    if _profiles.is_motorized(kind) and action.action_type != BRAKE:
        patch["fuel"] = maxi(0, int(rec.get("fuel", 0)) - _profiles.fuel_per_move(kind))
    if not _state.mutate(vehicle_id, patch):
        return {"ok": false, "reason": "vehicle_state_commit_failed"}
    if kind == VehicleProfileCatalog.BICYCLE:
        if not _conditions.add_fatigue(actor_id, int(_profiles.profile(kind).get("fatigue_per_move", 1)), &"bicycle_propulsion"):
            return {"ok": false, "reason": "bicycle_fatigue_commit_failed"}
    return {"ok": true, "reason": ""}

func _commit_skill_action(action: TimedAction, vehicle_id: String, kind: StringName) -> Dictionary:
    var difficulty := int(action.payload.get("difficulty", 2))
    var result := _skills.resolve_attempt(action.actor_id, SkillCatalog.MECHANICAL, difficulty, action.serial, StringName("%s|%s" % [String(kind), vehicle_id]), int(action.payload.get("skill_level", -1)))
    if not bool(result.get("ok", false)):
        return {"ok": false, "reason": String(result.get("reason", "mechanical_unavailable"))}
    var success := bool(result.get("success", false))
    if not _skills.award_attempt_xp(action.actor_id, SkillCatalog.MECHANICAL, difficulty, success):
        return {"ok": false, "reason": "mechanical_xp_failed"}
    if not success:
        if kind == HOTWIRE:
            var rec := _state.record(vehicle_id)
            _state.mutate(vehicle_id, {"electrical": int(rec.get("electrical", 100)) - 5})
        return {"ok": false, "reason": "mechanical_check_failed"}
    if kind == HOTWIRE:
        if not _consume_one_semantic(action.actor_id, &"item.junk.scrap_wire"):
            return {"ok": false, "reason": "hotwire_wire_commit_failed"}
        return {"ok": _state.mutate(vehicle_id, {"hotwired": true}), "reason": "hotwire_commit_failed"}
    if kind == REPAIR:
        var rec := _state.record(vehicle_id)
        var gain := maxi(8, int(result.get("effectiveness_percent", 65)) / 4)
        if not _consume_one_of(action.actor_id, [&"item.crafting.metal_scrap", &"item.junk.rusted_fasteners", &"item.material.screws_box"]):
            return {"ok": false, "reason": "repair_parts_commit_failed"}
        return {"ok": _state.mutate(vehicle_id, {"body": int(rec.get("body", 0)) + gain, "propulsion": int(rec.get("propulsion", 0)) + gain, "wheels": int(rec.get("wheels", 0)) + gain, "electrical": int(rec.get("electrical", 0)) + gain}), "reason": "repair_commit_failed"}
    if kind == MODIFY:
        return _install_cargo_rack(action.actor_id, vehicle_id)
    return {"ok": false, "reason": "skill_action_unknown"}

func _install_cargo_rack(actor_id: String, vehicle_id: String) -> Dictionary:
    var rack_id := _find_semantic_item(actor_id, &"item.automotive.cargo_rack")
    if rack_id.is_empty():
        return {"ok": false, "reason": "cargo_rack_missing_at_commit"}
    if not _inventory_mutations.clear_container(rack_id):
        return {"ok": false, "reason": "cargo_rack_detach_failed"}
    if not _inventory_mutations.set_container(rack_id, vehicle_id):
        _inventory_mutations.set_container(rack_id, actor_id)
        return {"ok": false, "reason": "cargo_rack_install_containment_failed"}
    var rec := _state.record(vehicle_id)
    var mods: Array = rec.get("mods", []).duplicate()
    var installed: Array = rec.get("installed_component_ids", []).duplicate()
    if &"cargo_rack" not in mods:
        mods.append(&"cargo_rack")
    if rack_id not in installed:
        installed.append(rack_id)
    if _state.mutate(vehicle_id, {"mods": mods, "installed_component_ids": installed}):
        return {"ok": true, "reason": ""}
    _inventory_mutations.clear_container(rack_id)
    _inventory_mutations.set_container(rack_id, actor_id)
    return {"ok": false, "reason": "modify_commit_failed"}

func _commit_refuel(actor_id: String, vehicle_id: String) -> bool:
    var rec := _state.record(vehicle_id)
    var kind := StringName(rec.get("kind", &""))
    if not _consume_one_semantic(actor_id, &"item.automotive.gas_can"):
        return false
    return _state.mutate(vehicle_id, {"fuel": _profiles.max_fuel(kind)})

func _can_request(actor_id: String) -> bool:
    return is_ready() and not actor_id.strip_edges().is_empty() and _world.has_entity(actor_id) and not _kernel.is_hard_paused() and not _kernel.has_active_action(actor_id)

func _nearby_vehicle(actor_id: String) -> String:
    var place := _world.placement(actor_id)
    if place == null:
        return ""
    for cell: Vector2i in [place.anchor, place.anchor + Vector2i.UP, place.anchor + Vector2i.RIGHT, place.anchor + Vector2i.DOWN, place.anchor + Vector2i.LEFT]:
        for entity_id: String in _world.entities_at(cell, Layers.Channel.OBJECT):
            if _state.has_vehicle(entity_id):
                return entity_id
    return ""

func _has_semantic(actor_id: String, semantic: StringName) -> bool:
    return not _find_semantic_item(actor_id, semantic).is_empty()

func _find_semantic_item(actor_id: String, semantic: StringName) -> String:
    for item_id: String in _inventory.direct_contents(actor_id):
        var entity := _world.entity(item_id)
        if entity != null and entity.semantic_type == semantic:
            return item_id
    return ""

func _has_any_semantic(actor_id: String, semantics: Array) -> bool:
    for semantic: Variant in semantics:
        if _has_semantic(actor_id, StringName(semantic)):
            return true
    return false

func _consume_one_of(actor_id: String, semantics: Array) -> bool:
    for semantic: Variant in semantics:
        if _consume_one_semantic(actor_id, StringName(semantic)):
            return true
    return false

func _consume_one_semantic(actor_id: String, semantic: StringName) -> bool:
    var item_id := _find_semantic_item(actor_id, semantic)
    if item_id.is_empty():
        return false
    if not _inventory_mutations.clear_container(item_id):
        return false
    if _mutations.remove_entity(item_id):
        return true
    _inventory_mutations.set_container(item_id, actor_id)
    return false

func _skateboard_surface_ok(anchor: Vector2i, footprint: SpatialFootprint, facing: int) -> bool:
    for cell: Vector2i in footprint.world_cells(anchor, facing):
        if not _world.has_terrain(cell):
            return false
        var terrain := String(_world.terrain_at(cell)).to_lower()
        var smooth := terrain.contains("road") or terrain.contains("pavement") or terrain.contains("parking") \
            or terrain.contains("driveway") or terrain.contains("sidewalk") or terrain.contains("asphalt") \
            or terrain.contains("concrete")
        if not smooth:
            return false
    return true

static func _reject(reason: String) -> Dictionary:
    return {"accepted": false, "reason": reason, "action_serial": 0}
