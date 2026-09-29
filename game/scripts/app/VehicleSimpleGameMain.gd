extends UtilitySimpleGameMain
class_name VehicleSimpleGameMain

const SimpleVehicleHeading = preload("res://scripts/simulation/vehicles/VehicleHeading.gd")
const SimpleVehicleProfiles = preload("res://scripts/simulation/vehicles/VehicleProfileCatalog.gd")
const SimpleSkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")

const CARGO_STORE: StringName = &"vehicle.cargo_store"
const CARGO_TAKE: StringName = &"vehicle.cargo_take"

func _boot_production_world() -> bool:
    if not super._boot_production_world():
        return false
    if _vehicle_actions == null or _vehicle_state == null or _vehicle_profiles == null or _vehicle_cargo == null or _vehicle_controls == null:
        return false

    return _vehicle_controls.configure_simple(Callable(self, "run_simple_vehicle_action"))

func _on_turn_intent(intent: StringName) -> void:
    if _vehicle_state != null and not _vehicle_state.vehicle_for_driver(WorldBootstrapClass.PLAYER_ID).is_empty():
        match intent:
            TurnIntents.FORWARD, TurnIntents.RUN_FORWARD:
                run_simple_vehicle_action(VehicleActionService.MOVE)
            TurnIntents.BACKWARD:
                run_simple_vehicle_action(VehicleActionService.REVERSE)
            TurnIntents.TURN_LEFT:
                run_simple_vehicle_action(VehicleActionService.TURN_LEFT)
            TurnIntents.TURN_RIGHT:
                run_simple_vehicle_action(VehicleActionService.TURN_RIGHT)
        return
    super._on_turn_intent(intent)

func _simple_contextual_action_supported(action_id: StringName) -> bool:
    if action_id in [VehicleActionService.REPAIR, VehicleActionService.MODIFY, VehicleActionService.REFUEL]:
        return true
    return super._simple_contextual_action_supported(action_id)

func _run_simple_contextual_action(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    if action_id in [VehicleActionService.REPAIR, VehicleActionService.MODIFY, VehicleActionService.REFUEL]:
        if actor_id.strip_edges() != WorldBootstrapClass.PLAYER_ID:
            return {"success": false, "reason": "vehicle_player_only"}
        return run_simple_vehicle_action(action_id, "", target_id)
    return super._run_simple_contextual_action(actor_id, target_id, action_id)

func run_simple_vehicle_action(action_id: StringName, item_id: String = "", target_id: String = "") -> Dictionary:
    if _simple_turns == null or not _simple_turns.has_control() or _vehicle_state == null or _vehicle_actions == null:
        return {"success": false, "reason": "vehicle_player_unavailable"}

    var plan := _simple_vehicle_plan(action_id, item_id, target_id)
    if not bool(plan.get("ok", false)):
        return {"success": false, "reason": String(plan.get("reason", "vehicle_action_unavailable")), "elapsed_ticks": 0}
    if not _simple_turns._begin_direct_action(action_id):
        return {"success": false, "reason": "player_unavailable", "elapsed_ticks": 0}

    var serial := _next_simple_action_serial()
    var result := _commit_simple_vehicle(action_id, plan, serial)
    var elapsed := maxi(1, int(plan.get("elapsed_ticks", survival_ticks_per_turn())))
    var vehicle_id := String(plan.get("vehicle_id", ""))

    if not bool(result.get("attempted", true)):
        return _simple_turns._reject_direct_action(action_id, String(result.get("reason", "vehicle_action_rejected")))

    var success := bool(result.get("success", false))
    var reason := String(result.get("reason", ""))
    if success:
        _vehicle_actions.action_completed.emit(WorldBootstrapClass.PLAYER_ID, vehicle_id, serial, action_id, "")
    else:
        _vehicle_actions.action_failed.emit(WorldBootstrapClass.PLAYER_ID, vehicle_id, serial, action_id, reason)

    _simple_elapsed_override_ticks = elapsed
    var completed := _simple_turns._complete_direct_action(action_id, reason)
    completed["success"] = success
    completed["reason"] = reason
    completed["elapsed_ticks"] = elapsed
    completed["vehicle_id"] = vehicle_id
    completed["action_id"] = action_id
    if not item_id.is_empty():
        completed["item_id"] = item_id
    return completed

func _simple_vehicle_plan(action_id: StringName, item_id: String, target_id: String) -> Dictionary:
    var actor := WorldBootstrapClass.PLAYER_ID
    if not _world.has_entity(actor):
        return {"ok": false, "reason": "vehicle_player_missing"}

    var mounted := _vehicle_state.vehicle_for_driver(actor)
    var target := target_id.strip_edges()
    if action_id == VehicleActionService.ENTER:
        if not mounted.is_empty():
            return {"ok": false, "reason": "already_mounted"}
        target = _vehicle_actions._nearby_vehicle(actor) if target.is_empty() else target
        if target.is_empty() or not _vehicle_state.has_vehicle(target):
            return {"ok": false, "reason": "no_vehicle_in_reach"}
        return {"ok": true, "vehicle_id": target, "elapsed_ticks": 4}

    var explicit_target := not target.is_empty()
    if action_id in [VehicleActionService.REPAIR, VehicleActionService.MODIFY, VehicleActionService.REFUEL] and target.is_empty():
        target = mounted if not mounted.is_empty() else _vehicle_actions._nearby_vehicle(actor)
    elif target.is_empty():
        target = mounted
    if target.is_empty() or not _vehicle_state.has_vehicle(target):
        return {"ok": false, "reason": "vehicle_not_ready"}
    if explicit_target and action_id in [VehicleActionService.REPAIR, VehicleActionService.MODIFY, VehicleActionService.REFUEL] \
        and not _interaction_reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD):
        return {"ok": false, "reason": "target_out_of_reach"}

    var rec := _vehicle_state.record(target)
    var kind := StringName(rec.get("kind", &""))

    match action_id:
        VehicleActionService.EXIT:
            if target != mounted:
                return {"ok": false, "reason": "not_mounted"}
            if bool(rec.get("moving", false)) and _vehicle_profiles.requires_stop_before_exit(kind):
                return {"ok": false, "reason": "vehicle_moving"}
            return {"ok": true, "vehicle_id": target, "elapsed_ticks": 4}
        VehicleActionService.START:
            if target != mounted:
                return {"ok": false, "reason": "not_mounted"}
            if not _vehicle_profiles.is_motorized(kind):
                return {"ok": false, "reason": "vehicle_not_motorized"}
            if bool(rec.get("powered", false)):
                return {"ok": false, "reason": "vehicle_already_started"}
            if int(rec.get("propulsion", 0)) <= 0 or int(rec.get("electrical", 0)) <= 0:
                return {"ok": false, "reason": "vehicle_disabled"}
            if int(rec.get("fuel", 0)) <= 0:
                return {"ok": false, "reason": "vehicle_out_of_fuel"}
            if not bool(rec.get("key_in_ignition", false)) and not bool(rec.get("hotwired", false)):
                return {"ok": false, "reason": "ignition_requires_hotwire"}
            return {"ok": true, "vehicle_id": target, "elapsed_ticks": 3}
        VehicleActionService.MOVE, VehicleActionService.TURN_LEFT, VehicleActionService.TURN_RIGHT, VehicleActionService.REVERSE, VehicleActionService.BRAKE:
            if target != mounted:
                return {"ok": false, "reason": "not_mounted"}
            if action_id == VehicleActionService.BRAKE:
                if not _vehicle_profiles.has_brake(kind):
                    return {"ok": false, "reason": "vehicle_has_no_brake"}
                if not bool(rec.get("moving", false)):
                    return {"ok": false, "reason": "vehicle_already_stopped"}
            elif action_id == VehicleActionService.REVERSE and bool(rec.get("moving", false)) and _vehicle_profiles.requires_stop_before_reverse(kind):
                return {"ok": false, "reason": "vehicle_brake_before_reverse"}
            elif _vehicle_profiles.is_motorized(kind):
                if not bool(rec.get("powered", false)):
                    return {"ok": false, "reason": "vehicle_not_started"}
                if int(rec.get("fuel", 0)) < _vehicle_profiles.fuel_per_move(kind):
                    return {"ok": false, "reason": "vehicle_out_of_fuel"}
            return {"ok": true, "vehicle_id": target, "elapsed_ticks": _vehicle_profiles.movement_ticks(kind)}
        VehicleActionService.HOTWIRE:
            if target != mounted:
                return {"ok": false, "reason": "not_mounted"}
            if not _vehicle_profiles.is_motorized(kind):
                return {"ok": false, "reason": "vehicle_not_motorized"}
            if bool(rec.get("key_in_ignition", false)):
                return {"ok": false, "reason": "ignition_key_present"}
            if bool(rec.get("hotwired", false)):
                return {"ok": false, "reason": "vehicle_already_hotwired"}
            if not _vehicle_actions._has_semantic(actor, &"item.tool.screwdriver") or not _vehicle_actions._has_semantic(actor, &"item.junk.scrap_wire"):
                return {"ok": false, "reason": "hotwire_requires_screwdriver_and_wire"}
            var hotwire_difficulty := _vehicle_profiles.hotwire_difficulty(kind)
            var hotwire_profile: Dictionary = _skill_checks.action_profile(actor, SimpleSkillCatalog.MECHANICAL, 12, hotwire_difficulty)
            if not bool(hotwire_profile.get("ok", false)):
                return {"ok": false, "reason": String(hotwire_profile.get("reason", "mechanical_unavailable"))}
            return {"ok": true, "vehicle_id": target, "elapsed_ticks": _deliberate_elapsed(int(hotwire_profile.get("duration_ticks", 12))), "difficulty": hotwire_difficulty, "skill_level": int(hotwire_profile.get("skill_level", -1))}
        VehicleActionService.REPAIR:
            if not _vehicle_actions._has_semantic(actor, &"item.tool.adjustable_wrench"):
                return {"ok": false, "reason": "repair_requires_wrench"}
            if not _vehicle_actions._has_any_semantic(actor, [&"item.crafting.metal_scrap", &"item.junk.rusted_fasteners", &"item.material.screws_box"]):
                return {"ok": false, "reason": "repair_requires_parts"}
            var repair_difficulty := int(_vehicle_profiles.profile(kind).get("repair_difficulty", 2))
            var repair_profile: Dictionary = _skill_checks.action_profile(actor, SimpleSkillCatalog.MECHANICAL, 16, repair_difficulty)
            if not bool(repair_profile.get("ok", false)):
                return {"ok": false, "reason": String(repair_profile.get("reason", "mechanical_unavailable"))}
            return {"ok": true, "vehicle_id": target, "elapsed_ticks": _deliberate_elapsed(int(repair_profile.get("duration_ticks", 16))), "difficulty": repair_difficulty, "skill_level": int(repair_profile.get("skill_level", -1))}
        VehicleActionService.MODIFY:
            if &"cargo_rack" in rec.get("mods", []):
                return {"ok": false, "reason": "cargo_rack_already_installed"}
            if not _vehicle_actions._has_semantic(actor, &"item.tool.adjustable_wrench") or not _vehicle_actions._has_semantic(actor, &"item.automotive.cargo_rack"):
                return {"ok": false, "reason": "modify_requires_wrench_and_cargo_rack"}
            var modify_profile: Dictionary = _skill_checks.action_profile(actor, SimpleSkillCatalog.MECHANICAL, 20, 4)
            if not bool(modify_profile.get("ok", false)):
                return {"ok": false, "reason": String(modify_profile.get("reason", "mechanical_unavailable"))}
            return {"ok": true, "vehicle_id": target, "elapsed_ticks": _deliberate_elapsed(int(modify_profile.get("duration_ticks", 20))), "difficulty": 4, "skill_level": int(modify_profile.get("skill_level", -1))}
        VehicleActionService.REFUEL:
            if not _vehicle_profiles.is_motorized(kind):
                return {"ok": false, "reason": "vehicle_not_motorized"}
            if not _vehicle_actions._has_semantic(actor, &"item.automotive.gas_can"):
                return {"ok": false, "reason": "refuel_requires_gas_can"}
            return {"ok": true, "vehicle_id": target, "elapsed_ticks": 8}
        CARGO_STORE:
            if target != mounted or item_id.is_empty() or not _vehicle_cargo.can_store(target, item_id) or not _inventory_state.contains_directly(actor, item_id):
                return {"ok": false, "reason": "vehicle_cargo_store_unavailable"}
            return {"ok": true, "vehicle_id": target, "elapsed_ticks": 2, "item_id": item_id}
        CARGO_TAKE:
            if target != mounted or item_id.is_empty() or not _inventory_state.contains_directly(target, item_id) or item_id in rec.get("installed_component_ids", []):
                return {"ok": false, "reason": "vehicle_cargo_take_unavailable"}
            return {"ok": true, "vehicle_id": target, "elapsed_ticks": 2, "item_id": item_id}
    return {"ok": false, "reason": "vehicle_action_unknown"}

func _commit_simple_vehicle(action_id: StringName, plan: Dictionary, serial: int) -> Dictionary:
    var actor := WorldBootstrapClass.PLAYER_ID
    var vehicle_id := String(plan.get("vehicle_id", ""))
    match action_id:
        VehicleActionService.ENTER:
            return {"success": _vehicle_actions._commit_enter(actor, vehicle_id), "reason": "enter_failed"}
        VehicleActionService.EXIT:
            return {"success": _vehicle_actions._commit_exit(actor, vehicle_id), "reason": "exit_failed"}
        VehicleActionService.MOVE, VehicleActionService.TURN_LEFT, VehicleActionService.TURN_RIGHT, VehicleActionService.REVERSE, VehicleActionService.BRAKE:
            return _commit_simple_vehicle_motion(actor, vehicle_id, action_id)
        VehicleActionService.START:
            return {"success": _vehicle_state.mutate(vehicle_id, {"powered": true}), "reason": "start_failed"}
        VehicleActionService.HOTWIRE:
            return _commit_simple_vehicle_skill(actor, vehicle_id, action_id, plan, serial)
        VehicleActionService.REPAIR:
            return _commit_simple_vehicle_skill(actor, vehicle_id, action_id, plan, serial)
        VehicleActionService.MODIFY:
            return _commit_simple_vehicle_skill(actor, vehicle_id, action_id, plan, serial)
        VehicleActionService.REFUEL:
            return {"success": _vehicle_actions._commit_refuel(actor, vehicle_id), "reason": "refuel_failed"}
        CARGO_STORE:
            return {"success": _vehicle_cargo.store_from_actor(actor, vehicle_id, String(plan.get("item_id", ""))), "reason": "vehicle_cargo_store_failed"}
        CARGO_TAKE:
            return {"success": _vehicle_cargo.take_to_actor(actor, vehicle_id, String(plan.get("item_id", ""))), "reason": "vehicle_cargo_take_failed"}
    return {"success": false, "reason": "vehicle_action_unknown", "attempted": false}

func _commit_simple_vehicle_motion(actor_id: String, vehicle_id: String, action_id: StringName) -> Dictionary:
    var rec := _vehicle_state.record(vehicle_id)
    var kind := StringName(rec.get("kind", &""))
    var placement := _world.placement(vehicle_id)
    if placement == null:
        return {"success": false, "reason": "vehicle_unplaced"}

    var start_heading := int(rec.get("heading", 0))
    var heading := start_heading
    var distance := _vehicle_profiles.movement_cells(kind)
    var turn_direction := 0
    var pivot_in_place := false

    if action_id == VehicleActionService.TURN_LEFT:
        turn_direction = -1
    elif action_id == VehicleActionService.TURN_RIGHT:
        turn_direction = 1
    elif action_id == VehicleActionService.REVERSE:
        distance = 1
    elif action_id == VehicleActionService.BRAKE:
        distance = 2

    if kind == SimpleVehicleProfiles.SKATEBOARD and turn_direction != 0:
        heading = SimpleVehicleHeading.completed_turn_heading(start_heading, turn_direction)
        distance = 0
        pivot_in_place = true
    elif turn_direction != 0:
        heading = SimpleVehicleHeading.completed_turn_heading(start_heading, turn_direction)
        distance = 3

    var path: Array[Vector2i] = []
    var true_turn := turn_direction != 0 and kind != SimpleVehicleProfiles.SKATEBOARD
    if not pivot_in_place:
        if true_turn:
            path = SimpleVehicleHeading.turn_path(start_heading, turn_direction)
        elif action_id == VehicleActionService.REVERSE:
            path = SimpleVehicleHeading.reverse_path(heading, distance)
        else:
            path = SimpleVehicleHeading.forward_path(heading, distance)

    var current_anchor := placement.anchor
    var facing := SimpleVehicleHeading.cardinal_facing(heading)
    for step_index: int in range(path.size()):
        var relative: Vector2i = path[step_index]
        var step_facing := SimpleVehicleHeading.cardinal_facing(SimpleVehicleHeading.normalize(start_heading + turn_direction * (step_index + 1))) if true_turn else facing
        var target := placement.anchor + relative
        if kind == SimpleVehicleProfiles.SKATEBOARD and not _vehicle_actions._skateboard_surface_ok(target, placement.footprint, step_facing):
            _vehicle_state.mutate(vehicle_id, {"moving": false})
            return {"success": false, "reason": "skateboard_requires_smooth_surface"}
        var check := _spatial_query.query_footprint(target, step_facing, placement.footprint, vehicle_id, true)
        if check == null or not check.is_clear():
            _vehicle_state.mutate(vehicle_id, {"moving": false, "body": int(rec.get("body", 100)) - 8})
            return {"success": false, "reason": "vehicle_collision"}
        current_anchor = target

    var original_anchor := placement.anchor
    var original_facing := placement.facing
    if not _world_mutations.set_placement(vehicle_id, Layers.Channel.OBJECT, current_anchor, facing, placement.footprint):
        return {"success": false, "reason": "vehicle_move_commit_failed"}
    if not _world_mutations.set_placement(actor_id, Layers.Channel.ACTOR, current_anchor, facing, Footprint.single_cell()):
        _world_mutations.set_placement(vehicle_id, Layers.Channel.OBJECT, original_anchor, original_facing, placement.footprint)
        return {"success": false, "reason": "vehicle_driver_move_commit_failed"}

    var next_moving := action_id not in [VehicleActionService.BRAKE, VehicleActionService.REVERSE]
    if pivot_in_place:
        next_moving = bool(rec.get("moving", false))
    var patch := {"heading": heading, "moving": next_moving}
    if _vehicle_profiles.is_motorized(kind) and action_id != VehicleActionService.BRAKE:
        patch["fuel"] = maxi(0, int(rec.get("fuel", 0)) - _vehicle_profiles.fuel_per_move(kind))
    if not _vehicle_state.mutate(vehicle_id, patch):
        _world_mutations.set_placement(vehicle_id, Layers.Channel.OBJECT, original_anchor, original_facing, placement.footprint)
        _world_mutations.set_placement(actor_id, Layers.Channel.ACTOR, original_anchor, original_facing, Footprint.single_cell())
        return {"success": false, "reason": "vehicle_state_commit_failed"}
    if kind == SimpleVehicleProfiles.BICYCLE and not _condition_service.add_fatigue(actor_id, int(_vehicle_profiles.profile(kind).get("fatigue_per_move", 1)), &"bicycle_propulsion"):
        return {"success": false, "reason": "bicycle_fatigue_commit_failed"}
    return {"success": true, "reason": ""}

func _commit_simple_vehicle_skill(actor_id: String, vehicle_id: String, action_id: StringName, plan: Dictionary, serial: int) -> Dictionary:
    var difficulty := int(plan.get("difficulty", 2))
    var attempt: Dictionary = _skill_checks.resolve_attempt(actor_id, SimpleSkillCatalog.MECHANICAL, difficulty, serial, StringName("%s|%s" % [String(action_id), vehicle_id]), int(plan.get("skill_level", -1)))
    if not bool(attempt.get("ok", false)):
        return {"success": false, "reason": String(attempt.get("reason", "mechanical_unavailable"))}
    var success := bool(attempt.get("success", false))
    if not _skill_checks.award_attempt_xp(actor_id, SimpleSkillCatalog.MECHANICAL, difficulty, success):
        return {"success": false, "reason": "mechanical_xp_failed"}
    if not success:
        if action_id == VehicleActionService.HOTWIRE:
            var failed_rec := _vehicle_state.record(vehicle_id)
            _vehicle_state.mutate(vehicle_id, {"electrical": int(failed_rec.get("electrical", 100)) - 5})
        return {"success": false, "reason": "mechanical_check_failed"}

    if action_id == VehicleActionService.HOTWIRE:
        if not _vehicle_actions._consume_one_semantic(actor_id, &"item.junk.scrap_wire"):
            return {"success": false, "reason": "hotwire_wire_commit_failed"}
        return {"success": _vehicle_state.mutate(vehicle_id, {"hotwired": true}), "reason": "hotwire_commit_failed"}
    if action_id == VehicleActionService.REPAIR:
        var rec := _vehicle_state.record(vehicle_id)
        var gain := maxi(8, int(attempt.get("effectiveness_percent", 65)) / 4)
        if not _vehicle_actions._consume_one_of(actor_id, [&"item.crafting.metal_scrap", &"item.junk.rusted_fasteners", &"item.material.screws_box"]):
            return {"success": false, "reason": "repair_parts_commit_failed"}
        return {"success": _vehicle_state.mutate(vehicle_id, {"body": int(rec.get("body", 0)) + gain, "propulsion": int(rec.get("propulsion", 0)) + gain, "wheels": int(rec.get("wheels", 0)) + gain, "electrical": int(rec.get("electrical", 0)) + gain}), "reason": "repair_commit_failed"}
    if action_id == VehicleActionService.MODIFY:
        return _vehicle_actions._install_cargo_rack(actor_id, vehicle_id)
    return {"success": false, "reason": "vehicle_skill_action_unknown"}
