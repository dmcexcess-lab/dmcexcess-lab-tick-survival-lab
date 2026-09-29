extends FortificationGameMain
class_name UtilitySimpleGameMain

const GeneratorActions = preload("res://scripts/simulation/utilities/PortableGeneratorActionService.gd")
const UtilityRepairActions = preload("res://scripts/simulation/utilities/UtilityPowerRepairActionService.gd")
const UtilityConditions = preload("res://scripts/simulation/utilities/UtilityNetworkConditionStore.gd")
const UtilitySkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")

const GAS_CAN: StringName = &"item.automotive.gas_can"
const WRENCH: StringName = &"item.tool.adjustable_wrench"
const UTILITY_HAMMER: StringName = &"item.tool.hammer"
const METAL_SCRAP: StringName = &"item.material.scrap_metal"
const WOOD_PLANK: StringName = &"item.material.wood_plank"
const UTILITY_NAILS: StringName = &"item.material.nails_box"
const GENERATOR_REPAIR_DIFFICULTY := 2
const POWER_REPAIR_BASE_TICKS := 20

func _simple_contextual_action_supported(action_id: StringName) -> bool:
    if action_id in GeneratorActions.ACTION_IDS or action_id == UtilityRepairActions.ACTION_ID:
        return true
    return super._simple_contextual_action_supported(action_id)

func _run_simple_contextual_action(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    if action_id in GeneratorActions.ACTION_IDS:
        return _run_simple_generator(actor_id, target_id, action_id)
    if action_id == UtilityRepairActions.ACTION_ID:
        return _run_simple_power_repair(actor_id, target_id)
    return super._run_simple_contextual_action(actor_id, target_id, action_id)

func _run_simple_generator(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    var actor := actor_id.strip_edges()
    var target := target_id.strip_edges()
    if actor != WorldBootstrapClass.PLAYER_ID or _simple_turns == null or not _simple_turns.has_control() or not _world.has_entity(target) or _portable_generators == null or not _portable_generators.has_generator(target):
        return {"success": false, "reason": "generator_target_unavailable"}
    if not _interaction_reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD):
        return {"success": false, "reason": "target_out_of_reach"}
    var state: Dictionary = _portable_generators.record(target)
    if action_id == GeneratorActions.INSPECT:
        return {"success": true, "reason": "", "elapsed_ticks": 0, "target_id": target, "state": state}
    var elapsed := 1
    var consumed := ""
    var repair_skill: Dictionary = {}
    match action_id:
        GeneratorActions.REFUEL:
            if not _portable_generators.can_refuel(target): return {"success": false, "reason": "generator_refuel_unavailable"}
            consumed = _find_carried_any([GAS_CAN], {})
            if consumed.is_empty(): return {"success": false, "reason": "generator_refuel_requires_gas_can"}
            elapsed = 6
        GeneratorActions.START:
            if not _portable_generators.can_start(target): return {"success": false, "reason": "generator_start_unavailable"}
            elapsed = 4
        GeneratorActions.STOP:
            if not bool(state.get("running", false)): return {"success": false, "reason": "generator_not_running"}
            elapsed = 2
        GeneratorActions.REPAIR:
            if not _portable_generators.can_repair(target): return {"success": false, "reason": "generator_repair_unavailable"}
            if _find_carried_any([WRENCH], {}).is_empty(): return {"success": false, "reason": "generator_repair_requires_wrench"}
            consumed = _find_carried_any([METAL_SCRAP], {})
            if consumed.is_empty(): return {"success": false, "reason": "generator_repair_requires_metal_scrap"}
            repair_skill = _skill_checks.action_profile(actor, UtilitySkillCatalog.MECHANICAL, 16, GENERATOR_REPAIR_DIFFICULTY)
            if not bool(repair_skill.get("ok", false)) or int(repair_skill.get("skill_level", -1)) < GENERATOR_REPAIR_DIFFICULTY: return {"success": false, "reason": "insufficient_mechanical_skill"}
            elapsed = _deliberate_elapsed(int(repair_skill.get("duration_ticks", 16)))
        _:
            return {"success": false, "reason": "generator_action_unknown"}
    var serial := _next_simple_action_serial()
    if action_id == GeneratorActions.REPAIR:
        var attempt: Dictionary = _skill_checks.resolve_attempt(actor, UtilitySkillCatalog.MECHANICAL, GENERATOR_REPAIR_DIFFICULTY, serial, StringName("utility.generator_repair|%s" % target), int(repair_skill.get("skill_level", -1)))
        if not bool(attempt.get("ok", false)): return {"success": false, "reason": "mechanical_skill_unavailable"}
        if not bool(attempt.get("success", false)):
            _skill_checks.award_attempt_xp(actor, UtilitySkillCatalog.MECHANICAL, GENERATOR_REPAIR_DIFFICULTY, false)
            return _complete_failed_utility(action_id, elapsed, "mechanical_skill_check_failed")
    var capture: Dictionary = _capture_personal_item(consumed) if not consumed.is_empty() else {}
    if not consumed.is_empty() and capture.is_empty(): return {"success": false, "reason": "required_item_no_longer_carried"}
    if not _simple_turns._begin_direct_action(action_id): return {"success": false, "reason": "player_unavailable"}
    var before := _portable_generators.snapshot()
    var changed := false
    match action_id:
        GeneratorActions.REFUEL: changed = _portable_generators.refuel(target, survival_elapsed_tick())
        GeneratorActions.START: changed = _portable_generators.start(target, survival_elapsed_tick())
        GeneratorActions.STOP: changed = _portable_generators.stop(target, survival_elapsed_tick())
        GeneratorActions.REPAIR: changed = _portable_generators.repair(target, survival_elapsed_tick())
    if not changed: return _simple_turns._reject_direct_action(action_id, "generator_state_commit_failed")
    if not consumed.is_empty() and not _remove_captured_item(capture):
        _portable_generators.restore_snapshot(before)
        return _simple_turns._reject_direct_action(action_id, "generator_material_commit_failed")
    if action_id == GeneratorActions.REPAIR: _skill_checks.award_attempt_xp(actor, UtilitySkillCatalog.MECHANICAL, GENERATOR_REPAIR_DIFFICULTY, true)
    _simple_elapsed_override_ticks = maxi(1, elapsed)
    var result := _simple_turns._complete_direct_action(action_id, "")
    result["elapsed_ticks"] = maxi(1, elapsed); result["target_id"] = target
    if not consumed.is_empty(): result["consumed_item_id"] = consumed
    return result

func _run_simple_power_repair(actor_id: String, target_id: String) -> Dictionary:
    var actor := actor_id.strip_edges(); var target := target_id.strip_edges()
    if actor != WorldBootstrapClass.PLAYER_ID or _power_network == null or not _world.has_entity(target): return {"success": false, "reason": "utility_repair_target_missing"}
    if not _interaction_reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD): return {"success": false, "reason": "target_out_of_reach"}
    var asset: Dictionary = _power_network.asset_record(target)
    if asset.is_empty() or StringName(asset.get("kind", &"")) != UtilityConditions.DISTRIBUTION_SUPPORT or not bool(asset.get("failed", false)): return {"success": false, "reason": "utility_asset_not_failed"}
    var requirements := _power_network.repair_requirements(target); var material_units := int(requirements.get("material_units", -1)); var difficulty := int(requirements.get("mechanical_skill", -1))
    if material_units < 1 or difficulty < 0: return {"success": false, "reason": "utility_repair_profile_invalid"}
    if _find_carried_any([UTILITY_HAMMER], {}).is_empty(): return {"success": false, "reason": "repair_tool_required"}
    var used := {}; var captures: Array[Dictionary] = []
    for _i in range(material_units):
        var plank := _find_carried_any([WOOD_PLANK], used); if plank.is_empty(): return {"success": false, "reason": "repair_material_required"}
        used[plank] = true; var capture := _capture_personal_item(plank); if capture.is_empty(): return {"success": false, "reason": "repair_material_changed"}; captures.append(capture)
    var nails := _find_carried_any([UTILITY_NAILS], used); if nails.is_empty(): return {"success": false, "reason": "repair_fasteners_required"}
    var nails_capture := _capture_personal_item(nails); if nails_capture.is_empty(): return {"success": false, "reason": "repair_fasteners_changed"}; captures.append(nails_capture)
    var profile: Dictionary = _skill_checks.action_profile(actor, UtilitySkillCatalog.MECHANICAL, POWER_REPAIR_BASE_TICKS, difficulty)
    if not bool(profile.get("ok", false)) or int(profile.get("skill_level", -1)) < difficulty: return {"success": false, "reason": "insufficient_mechanical_skill"}
    var serial := _next_simple_action_serial(); var attempt := _skill_checks.resolve_attempt(actor, UtilitySkillCatalog.MECHANICAL, difficulty, serial, StringName("utility.power_repair|%s" % target), int(profile.get("skill_level", -1)))
    if not bool(attempt.get("ok", false)): return {"success": false, "reason": "mechanical_skill_unavailable"}
    var elapsed := _deliberate_elapsed(int(profile.get("duration_ticks", POWER_REPAIR_BASE_TICKS)))
    if not bool(attempt.get("success", false)):
        _skill_checks.award_attempt_xp(actor, UtilitySkillCatalog.MECHANICAL, difficulty, false)
        return _complete_failed_utility(UtilityRepairActions.ACTION_ID, elapsed, "mechanical_skill_check_failed")
    if not _simple_turns._begin_direct_action(UtilityRepairActions.ACTION_ID): return {"success": false, "reason": "player_unavailable"}
    var before := _power_network.snapshot(); var owner := _power_network.repair_asset(target, int(profile.get("skill_level", -1)), material_units)
    if not bool(owner.get("ok", false)): return _simple_turns._reject_direct_action(UtilityRepairActions.ACTION_ID, String(owner.get("reason", "utility_owner_repair_failed")))
    var removed: Array[Dictionary] = []
    for capture: Dictionary in captures:
        if not _remove_captured_item(capture):
            _power_network.restore_snapshot(before); _restore_captured_items(removed)
            return _simple_turns._reject_direct_action(UtilityRepairActions.ACTION_ID, "utility_repair_material_commit_failed")
        removed.append(capture)
    _skill_checks.award_attempt_xp(actor, UtilitySkillCatalog.MECHANICAL, difficulty, true)
    _simple_elapsed_override_ticks = elapsed
    var result := _simple_turns._complete_direct_action(UtilityRepairActions.ACTION_ID, "")
    result["elapsed_ticks"] = elapsed; result["target_id"] = target; result["consumed_item_ids"] = captures.map(func(c): return String(c.get("item_id", "")))
    return result

func _complete_failed_utility(action_id: StringName, elapsed: int, reason: String) -> Dictionary:
    if not _simple_turns._begin_direct_action(action_id): return {"success": false, "reason": "player_unavailable"}
    _simple_elapsed_override_ticks = maxi(1, elapsed)
    var result := _simple_turns._complete_direct_action(action_id, reason); result["success"] = false; result["reason"] = reason; result["elapsed_ticks"] = maxi(1, elapsed); return result

func slice9_utility_verification() -> Dictionary:
    if _utilities == null or _power_network == null or _portable_generators == null or _simple_turns == null: return {"ok": false, "reason": "utility_runtime_missing"}
    var utility_snapshot := _utilities.snapshot(); var power_snapshot := _power_network.snapshot(); var generator_snapshot := _portable_generators.snapshot()
    if utility_snapshot.is_empty() or power_snapshot.is_empty() or generator_snapshot.is_empty(): return {"ok": false, "reason": "utility_snapshot_missing"}
    if not _utilities.restore_snapshot(utility_snapshot) or not _power_network.restore_snapshot(power_snapshot) or not _portable_generators.restore_snapshot(generator_snapshot): return {"ok": false, "reason": "utility_restore_failed"}
    return {"ok": true, "reason": ""}
