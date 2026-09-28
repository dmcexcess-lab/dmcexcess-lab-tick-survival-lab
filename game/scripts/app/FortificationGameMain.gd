extends Slice7GameMain
class_name FortificationGameMain

## Narrow production composition for existing-opening fortification. BOARD/REMOVE BOARD
## use the already-authoritative opening, item, skill and simple-turn owners directly.
## This is migration composition only; no build/job/scheduling framework lives here.

const FortifyActions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const FortifySkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const FortifyDoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const FortifyLayers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const FortifyFacing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const FortifyFootprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")

const HAMMER: StringName = &"item.tool.hammer"
const CROWBAR: StringName = &"item.tool.crowbar"
const NAILS: StringName = &"item.material.nails_box"
const PLANK: StringName = &"item.material.wood_plank"
const BOARD_BASE_TICKS := 12
const UNBOARD_BASE_TICKS := 10
const BOARD_DIFFICULTY := 2
const UNBOARD_DIFFICULTY := 1

func _simple_contextual_action_supported(action_id: StringName) -> bool:
    if action_id in [FortifyActions.OPENING_BOARD, FortifyActions.OPENING_UNBOARD]:
        return true
    return super._simple_contextual_action_supported(action_id)

func _run_simple_contextual_action(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    if action_id in [FortifyActions.OPENING_BOARD, FortifyActions.OPENING_UNBOARD]:
        if actor_id.strip_edges() != WorldBootstrapClass.PLAYER_ID:
            return {"success": false, "reason": "fortification_player_only"}
        return run_simple_fortification(target_id, action_id)
    return super._run_simple_contextual_action(actor_id, target_id, action_id)

func run_simple_fortification(target_id: String, action_id: StringName) -> Dictionary:
    var target := target_id.strip_edges()
    var actor := WorldBootstrapClass.PLAYER_ID
    if action_id not in [FortifyActions.OPENING_BOARD, FortifyActions.OPENING_UNBOARD]:
        return {"success": false, "reason": "fortification_action_unknown"}
    if target.is_empty() or not _world.has_entity(target) or _simple_turns == null or not _simple_turns.has_control():
        return {"success": false, "reason": "fortification_target_unavailable"}
    if not _interaction_reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD):
        return {"success": false, "reason": "target_out_of_reach"}
    var entity := _world.entity(target)
    if entity == null or _world_interaction_state.is_destroyed(target):
        return {"success": false, "reason": "fortification_target_unavailable"}
    var is_door := _world_interaction_catalog.is_door(entity.semantic_type) and _door_state.has_door(target)
    var is_window := _world_interaction_catalog.is_window(entity.semantic_type)
    if not is_door and not is_window:
        return {"success": false, "reason": "opening_required"}
    if _world_interaction_state.is_broken(target):
        return {"success": false, "reason": "opening_broken"}

    var boards := _world_interaction_state.board_count(target)
    if action_id == FortifyActions.OPENING_BOARD:
        if boards >= WorldInteractableState.MAX_BOARDS:
            return {"success": false, "reason": "opening_fully_boarded"}
        if is_door and _door_state.state(target) != FortifyDoorValue.CLOSED:
            return {"success": false, "reason": "close_door_before_boarding"}
        if is_window and _world_interaction_state.window_open(target):
            return {"success": false, "reason": "close_window_before_boarding"}
        return _run_simple_board(target)
    if boards <= 0:
        return {"success": false, "reason": "opening_not_boarded"}
    return _run_simple_unboard(target)

func _run_simple_board(target: String) -> Dictionary:
    var actor := WorldBootstrapClass.PLAYER_ID
    var hammer := _find_carried_any([HAMMER], {})
    if hammer.is_empty():
        return {"success": false, "reason": "hammer_required"}
    var used := {hammer: true}
    var plank := _find_carried_any([PLANK], used)
    if plank.is_empty():
        return {"success": false, "reason": "wood_plank_required"}
    used[plank] = true
    var nails := _find_carried_any([NAILS], used)
    if nails.is_empty():
        return {"success": false, "reason": "nails_required"}

    var skill_profile: Dictionary = _skill_checks.action_profile(actor, FortifySkillCatalog.MECHANICAL, BOARD_BASE_TICKS, BOARD_DIFFICULTY)
    if not bool(skill_profile.get("ok", false)):
        return {"success": false, "reason": String(skill_profile.get("reason", "mechanical_skill_unavailable"))}
    var serial := _next_simple_action_serial()
    var skill: Dictionary = _skill_checks.resolve_attempt(actor, FortifySkillCatalog.MECHANICAL, BOARD_DIFFICULTY, serial, StringName("opening.board|%s" % target), int(skill_profile.get("skill_level", -1)))
    if not bool(skill.get("ok", false)):
        return {"success": false, "reason": String(skill.get("reason", "mechanical_skill_unavailable"))}
    if not bool(skill.get("success", false)):
        _skill_checks.award_attempt_xp(actor, FortifySkillCatalog.MECHANICAL, BOARD_DIFFICULTY, false)
        return _complete_failed_fortification(FortifyActions.OPENING_BOARD, _deliberate_elapsed(int(skill_profile.get("duration_ticks", BOARD_BASE_TICKS))), "mechanical_skill_check_failed")

    var plank_capture := _capture_personal_item(plank)
    var nails_capture := _capture_personal_item(nails)
    if plank_capture.is_empty() or nails_capture.is_empty():
        return {"success": false, "reason": "boarding_material_changed"}
    if not _simple_turns._begin_direct_action(FortifyActions.OPENING_BOARD):
        return {"success": false, "reason": "player_unavailable"}
    var before := _world_interaction_state.board_count(target)
    if not _world_interaction_state.set_board_count(target, before + 1, &"opening_boarded"):
        return _simple_turns._reject_direct_action(FortifyActions.OPENING_BOARD, "boarding_state_failed")
    var removed: Array[Dictionary] = []
    for capture: Dictionary in [plank_capture, nails_capture]:
        if not _remove_captured_item(capture):
            _world_interaction_state.set_board_count(target, before, &"boarding_rollback")
            _restore_captured_items(removed)
            return _simple_turns._reject_direct_action(FortifyActions.OPENING_BOARD, "boarding_material_commit_failed")
        removed.append(capture)
    if not _skill_checks.award_attempt_xp(actor, FortifySkillCatalog.MECHANICAL, BOARD_DIFFICULTY, true):
        _world_interaction_state.set_board_count(target, before, &"boarding_rollback")
        _restore_captured_items(removed)
        return _simple_turns._reject_direct_action(FortifyActions.OPENING_BOARD, "mechanical_xp_commit_failed")
    var elapsed := _deliberate_elapsed(int(skill_profile.get("duration_ticks", BOARD_BASE_TICKS)))
    _simple_elapsed_override_ticks = elapsed
    var result := _simple_turns._complete_direct_action(FortifyActions.OPENING_BOARD, "")
    result["elapsed_ticks"] = elapsed
    result["target_id"] = target
    result["board_count"] = before + 1
    result["consumed_item_ids"] = [plank, nails]
    return result

func _run_simple_unboard(target: String) -> Dictionary:
    var actor := WorldBootstrapClass.PLAYER_ID
    var tool := _find_carried_any([CROWBAR, HAMMER], {})
    if tool.is_empty():
        return {"success": false, "reason": "hammer_or_crowbar_required"}
    var skill_profile: Dictionary = _skill_checks.action_profile(actor, FortifySkillCatalog.MECHANICAL, UNBOARD_BASE_TICKS, UNBOARD_DIFFICULTY)
    if not bool(skill_profile.get("ok", false)):
        return {"success": false, "reason": String(skill_profile.get("reason", "mechanical_skill_unavailable"))}
    var serial := _next_simple_action_serial()
    var skill: Dictionary = _skill_checks.resolve_attempt(actor, FortifySkillCatalog.MECHANICAL, UNBOARD_DIFFICULTY, serial, StringName("opening.remove_board|%s" % target), int(skill_profile.get("skill_level", -1)))
    if not bool(skill.get("ok", false)):
        return {"success": false, "reason": String(skill.get("reason", "mechanical_skill_unavailable"))}
    if not bool(skill.get("success", false)):
        _skill_checks.award_attempt_xp(actor, FortifySkillCatalog.MECHANICAL, UNBOARD_DIFFICULTY, false)
        return _complete_failed_fortification(FortifyActions.OPENING_UNBOARD, _deliberate_elapsed(int(skill_profile.get("duration_ticks", UNBOARD_BASE_TICKS))), "mechanical_skill_check_failed")

    if not _simple_turns._begin_direct_action(FortifyActions.OPENING_UNBOARD):
        return {"success": false, "reason": "player_unavailable"}
    var before := _world_interaction_state.board_count(target)
    if before <= 0 or not _world_interaction_state.set_board_count(target, before - 1, &"board_removed"):
        return _simple_turns._reject_direct_action(FortifyActions.OPENING_UNBOARD, "unboard_state_failed")
    var recovered := "unboard.simple.%016d" % serial
    if _world.create_entity(PLANK, recovered) != recovered:
        _world_interaction_state.set_board_count(target, before, &"unboard_rollback")
        return _simple_turns._reject_direct_action(FortifyActions.OPENING_UNBOARD, "recovered_plank_create_failed")
    var capacity: Dictionary = _carry_acquisition.evaluate(actor, recovered)
    var stored := int(capacity.get("status", -1)) == 0 and _inventory_mutations.set_container(recovered, actor)
    if not stored:
        var actor_placement := _world.placement(actor)
        if actor_placement == null or not _world.set_placement(recovered, FortifyLayers.Channel.LOOSE_ITEM, actor_placement.anchor, FortifyFacing.Value.SOUTH, FortifyFootprint.single_cell()):
            _world.remove_entity(recovered)
            _world_interaction_state.set_board_count(target, before, &"unboard_rollback")
            return _simple_turns._reject_direct_action(FortifyActions.OPENING_UNBOARD, "recovered_plank_place_failed")
    if not _skill_checks.award_attempt_xp(actor, FortifySkillCatalog.MECHANICAL, UNBOARD_DIFFICULTY, true):
        if _inventory_state.is_contained(recovered):
            _inventory_mutations.clear_container(recovered)
        if _world.has_entity(recovered):
            _world.remove_entity(recovered)
        _world_interaction_state.set_board_count(target, before, &"unboard_rollback")
        return _simple_turns._reject_direct_action(FortifyActions.OPENING_UNBOARD, "mechanical_xp_commit_failed")
    var elapsed := _deliberate_elapsed(int(skill_profile.get("duration_ticks", UNBOARD_BASE_TICKS)))
    _simple_elapsed_override_ticks = elapsed
    var result := _simple_turns._complete_direct_action(FortifyActions.OPENING_UNBOARD, "")
    result["elapsed_ticks"] = elapsed
    result["target_id"] = target
    result["board_count"] = before - 1
    result["recovered_item_id"] = recovered
    return result

func _complete_failed_fortification(action_id: StringName, elapsed: int, reason: String) -> Dictionary:
    if not _simple_turns._begin_direct_action(action_id):
        return {"success": false, "reason": "player_unavailable"}
    _simple_elapsed_override_ticks = maxi(1, elapsed)
    var completed := _simple_turns._complete_direct_action(action_id, reason)
    completed["success"] = false
    completed["reason"] = reason
    completed["elapsed_ticks"] = maxi(1, elapsed)
    return completed
