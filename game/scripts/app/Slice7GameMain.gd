extends "res://scripts/app/TurnBasedGameMain.gd"
class_name Slice7GameMain

## Temporary migration composition for Slice 7. This overrides only the five newly
## migrated domain actions; it is not a new execution framework and should fold back
## into TurnBasedGameMain when the rewrite reaches legacy demolition.

func run_simple_craft(recipe_id: StringName, workstation_id: String = "") -> Dictionary:
    if _simple_turns == null or not _simple_turns.has_control() or _crafting_plans == null or _crafting_recipes == null:
        return {"success": false, "reason": "crafting_unavailable"}
    var plan: Dictionary = _crafting_plans.query(WorldBootstrapClass.PLAYER_ID, recipe_id, workstation_id)
    if not bool(plan.get("ready", false)):
        return {"success": false, "reason": String(plan.get("reason", "crafting_blocked"))}
    var recipe: CraftingRecipe = _crafting_recipes.recipe(recipe_id)
    if recipe == null:
        return {"success": false, "reason": "recipe_unknown"}
    var skill_profile: Dictionary = _skill_checks.action_profile(WorldBootstrapClass.PLAYER_ID, recipe.skill_id, recipe.duration_ticks, recipe.skill_difficulty)
    if not bool(skill_profile.get("ok", false)):
        return {"success": false, "reason": String(skill_profile.get("reason", "skill_unavailable"))}
    var exact: Dictionary = _crafting_plans.validate_exact(WorldBootstrapClass.PLAYER_ID, recipe_id, int(plan.get("recipe_catalog_version", -1)), plan.get("consumed_item_ids", []), plan.get("tool_item_ids", []), workstation_id)
    if not bool(exact.get("ready", false)):
        return {"success": false, "reason": String(exact.get("reason", "crafting_plan_stale"))}
    var serial := _next_simple_action_serial()
    var skill: Dictionary = _skill_checks.resolve_attempt(WorldBootstrapClass.PLAYER_ID, recipe.skill_id, recipe.skill_difficulty, serial, recipe_id, int(skill_profile.get("skill_level", -1)))
    if not bool(skill.get("ok", false)):
        return {"success": false, "reason": String(skill.get("reason", "skill_check_unavailable"))}
    if not bool(skill.get("success", false)):
        _skill_checks.award_attempt_xp(WorldBootstrapClass.PLAYER_ID, recipe.skill_id, recipe.skill_difficulty, false)
        return {"success": false, "reason": "skill_check_failed"}

    var captures: Array[Dictionary] = []
    for value: Variant in exact.get("consumed_item_ids", []):
        var capture: Dictionary = _capture_personal_item(String(value))
        if capture.is_empty():
            return {"success": false, "reason": "input_disposition_stale"}
        captures.append(capture)
    var semantics: Array = exact.get("output_semantics", [])
    var output_ids: Array[String] = []
    for index in range(semantics.size()):
        var output_id := "craft.simple.%016d.%02d" % [serial, index]
        if _world.has_entity(output_id):
            return {"success": false, "reason": "output_identity_collision"}
        output_ids.append(output_id)
    if not _simple_turns._begin_direct_action(&"crafting.craft_recipe"):
        return {"success": false, "reason": "player_unavailable"}

    var removed: Array[Dictionary] = []
    for capture: Dictionary in captures:
        if not _remove_captured_item(capture):
            _restore_captured_items(removed)
            return _simple_turns._reject_direct_action(&"crafting.craft_recipe", "input_remove_failed")
        removed.append(capture)
    var created: Array[String] = []
    for index in range(output_ids.size()):
        var output_id := output_ids[index]
        if _world.create_entity(StringName(semantics[index]), output_id) != output_id:
            _rollback_created_items(created)
            _restore_captured_items(removed)
            return _simple_turns._reject_direct_action(&"crafting.craft_recipe", "output_create_failed")
        if not _inventory_mutations.set_container(output_id, WorldBootstrapClass.PLAYER_ID):
            _world.remove_entity(output_id)
            _rollback_created_items(created)
            _restore_captured_items(removed)
            return _simple_turns._reject_direct_action(&"crafting.craft_recipe", "output_containment_failed")
        created.append(output_id)
    if not _skill_checks.award_attempt_xp(WorldBootstrapClass.PLAYER_ID, recipe.skill_id, recipe.skill_difficulty, true):
        _rollback_created_items(created)
        _restore_captured_items(removed)
        return _simple_turns._reject_direct_action(&"crafting.craft_recipe", "skill_xp_commit_failed")

    var elapsed := _deliberate_elapsed(int(skill_profile.get("duration_ticks", recipe.duration_ticks)))
    _simple_elapsed_override_ticks = elapsed
    var result := _simple_turns._complete_direct_action(&"crafting.craft_recipe", "")
    result["elapsed_ticks"] = elapsed
    result["output_item_ids"] = created
    result["consumed_item_ids"] = exact.get("consumed_item_ids", []).duplicate()
    result["recipe_id"] = recipe_id
    return result

func run_simple_first_aid(item_id: String, injury_id: String) -> Dictionary:
    if _simple_turns == null or not _simple_turns.has_control() or _first_aid_actions == null:
        return {"success": false, "reason": "first_aid_unavailable"}
    var chosen: Dictionary = {}
    for offer: Dictionary in _first_aid_actions.treatment_offers(WorldBootstrapClass.PLAYER_ID, item_id):
        if String(offer.get("injury_id", "")) == injury_id:
            chosen = offer
            break
    var wound: ActorInjuryRecord = _health_state.injury(WorldBootstrapClass.PLAYER_ID, injury_id)
    if chosen.is_empty() or wound == null:
        return {"success": false, "reason": "treatment_unavailable"}
    var captures: Array[Dictionary] = []
    for value: Variant in chosen.get("resource_item_ids", []):
        var capture: Dictionary = _capture_personal_item(String(value))
        if capture.is_empty():
            return {"success": false, "reason": "treatment_resource_changed"}
        captures.append(capture)
    var serial := _next_simple_action_serial()
    var difficulty := int(chosen.get("skill_difficulty", 1))
    var skill: Dictionary = _skill_checks.resolve_attempt(WorldBootstrapClass.PLAYER_ID, SkillCatalog.SURVIVAL, difficulty, serial, &"health.first_aid", int(chosen.get("skill_level", -1)))
    if not bool(skill.get("ok", false)):
        return {"success": false, "reason": "skill_check_unavailable"}
    if not _simple_turns._begin_direct_action(&"health.first_aid"):
        return {"success": false, "reason": "player_unavailable"}
    var removed: Array[Dictionary] = []
    for capture: Dictionary in captures:
        if not _remove_captured_item(capture):
            _restore_captured_items(removed)
            return _simple_turns._reject_direct_action(&"health.first_aid", "treatment_resource_commit_failed")
        removed.append(capture)
    var skill_success := bool(skill.get("success", false))
    var next_severity := wound.severity
    if skill_success and String(chosen.get("mode", "")) == "kit":
        next_severity = maxi(Injury.Severity.MINOR, wound.severity - 1)
    if not _health_state.set_injury_state(WorldBootstrapClass.PLAYER_ID, injury_id, next_severity, true, wound.treated or skill_success):
        _restore_captured_items(removed)
        return _simple_turns._reject_direct_action(&"health.first_aid", "injury_commit_failed")
    if not _skill_checks.award_attempt_xp(WorldBootstrapClass.PLAYER_ID, SkillCatalog.SURVIVAL, difficulty, skill_success):
        _health_state.set_injury_state(WorldBootstrapClass.PLAYER_ID, injury_id, wound.severity, wound.stabilized, wound.treated)
        _restore_captured_items(removed)
        return _simple_turns._reject_direct_action(&"health.first_aid", "skill_xp_commit_failed")
    var elapsed := maxi(1, int(chosen.get("duration_ticks", survival_ticks_per_turn())))
    _simple_elapsed_override_ticks = elapsed
    var result := _simple_turns._complete_direct_action(&"health.first_aid", "")
    result["elapsed_ticks"] = elapsed
    result["treated"] = wound.treated or skill_success
    result["stabilized"] = true
    result["severity"] = next_severity
    return result

func run_simple_repair(target_id: String) -> Dictionary:
    var target := target_id.strip_edges()
    var actor := WorldBootstrapClass.PLAYER_ID
    if target.is_empty() or not _world.has_entity(target) or _simple_turns == null or not _simple_turns.has_control():
        return {"success": false, "reason": "repair_target_unavailable"}
    if not _interaction_reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD):
        return {"success": false, "reason": "target_out_of_reach"}
    var entity := _world.entity(target)
    var profile: Dictionary = _world_interaction_catalog.repair_profile(entity.semantic_type) if entity != null else {}
    if profile.is_empty() or not _world_interaction_state.is_broken(target):
        return {"success": false, "reason": "target_not_repairable"}
    var tool := _find_carried_any(profile.get("tool_semantics", []), {})
    if tool.is_empty():
        return {"success": false, "reason": "repair_tool_required"}
    var used := {tool: true}
    var materials: Array[String] = []
    for semantic: Variant in profile.get("material_semantics", []):
        var item := _find_carried_any([semantic], used)
        if item.is_empty():
            return {"success": false, "reason": "repair_material_required"}
        used[item] = true
        materials.append(item)
    var skill_profile: Dictionary = _skill_checks.action_profile(actor, SkillCatalog.MECHANICAL, int(profile.get("base_duration_ticks", 16)), int(profile.get("difficulty", 3)))
    if not bool(skill_profile.get("ok", false)):
        return {"success": false, "reason": "mechanical_skill_unavailable"}
    var serial := _next_simple_action_serial()
    var skill: Dictionary = _skill_checks.resolve_attempt(actor, SkillCatalog.MECHANICAL, int(profile.get("difficulty", 3)), serial, StringName("world.repair|%s" % target), int(skill_profile.get("skill_level", -1)))
    if not bool(skill.get("ok", false)) or not bool(skill.get("success", false)):
        return {"success": false, "reason": "mechanical_skill_check_failed"}
    var captures: Array[Dictionary] = []
    for item: String in materials:
        var capture := _capture_personal_item(item)
        if capture.is_empty():
            return {"success": false, "reason": "repair_material_changed"}
        captures.append(capture)
    if not _simple_turns._begin_direct_action(RepairActions.ACTION_ID):
        return {"success": false, "reason": "player_unavailable"}
    if _door_state.state(target) == DoorValue.OPEN and not _door_transition.close_manually(actor, target):
        return _simple_turns._reject_direct_action(RepairActions.ACTION_ID, "door_close_failed")
    if not _world_interaction_state.set_broken(target, false, &"simple_door_repaired"):
        return _simple_turns._reject_direct_action(RepairActions.ACTION_ID, "repair_state_failed")
    var removed: Array[Dictionary] = []
    for capture: Dictionary in captures:
        if not _remove_captured_item(capture):
            _world_interaction_state.set_broken(target, true, &"repair_rollback")
            _restore_captured_items(removed)
            return _simple_turns._reject_direct_action(RepairActions.ACTION_ID, "repair_material_commit_failed")
        removed.append(capture)
    _skill_checks.award_attempt_xp(actor, SkillCatalog.MECHANICAL, int(profile.get("difficulty", 3)), true)
    var elapsed := _deliberate_elapsed(int(skill_profile.get("duration_ticks", 1)))
    _simple_elapsed_override_ticks = elapsed
    var result := _simple_turns._complete_direct_action(RepairActions.ACTION_ID, "")
    result["elapsed_ticks"] = elapsed
    result["target_id"] = target
    return result

func run_simple_deconstruct(target_id: String) -> Dictionary:
    var target := target_id.strip_edges()
    var actor := WorldBootstrapClass.PLAYER_ID
    if target.is_empty() or not _world.has_entity(target) or _simple_turns == null or not _simple_turns.has_control():
        return {"success": false, "reason": "deconstruct_target_unavailable"}
    if not _interaction_reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD):
        return {"success": false, "reason": "target_out_of_reach"}
    var entity := _world.entity(target)
    var placement := _world.placement(target)
    var profile: Dictionary = _world_interaction_catalog.deconstruction_profile(entity.semantic_type) if entity != null else {}
    if profile.is_empty() or placement == null or placement.channel != Layers.Channel.OBJECT or _inventory_state.has_container(target):
        return {"success": false, "reason": "object_not_deconstructible"}
    var tool := _find_carried_any(profile.get("tool_semantics", []), {})
    if tool.is_empty():
        return {"success": false, "reason": "deconstruction_tool_required"}
    var difficulty := int(profile.get("difficulty", 2))
    var skill_profile: Dictionary = _skill_checks.action_profile(actor, SkillCatalog.MECHANICAL, int(profile.get("base_duration_ticks", 16)), difficulty)
    if not bool(skill_profile.get("ok", false)):
        return {"success": false, "reason": "mechanical_skill_unavailable"}
    var serial := _next_simple_action_serial()
    var skill: Dictionary = _skill_checks.resolve_attempt(actor, SkillCatalog.MECHANICAL, difficulty, serial, StringName("world.deconstruct|%s" % target), int(skill_profile.get("skill_level", -1)))
    if not bool(skill.get("ok", false)) or not bool(skill.get("success", false)):
        return {"success": false, "reason": "mechanical_skill_check_failed"}
    var output_semantic := StringName(profile.get("output_semantic", &""))
    var count := int(profile.get("output_count", 0))
    if count < 1:
        return {"success": false, "reason": "deconstruction_profile_invalid"}
    if not _simple_turns._begin_direct_action(WorldActions.OBJECT_DECONSTRUCT):
        return {"success": false, "reason": "player_unavailable"}
    var created: Array[String] = []
    for index in range(count):
        var item_id := "deconstruct.simple.%016d.%02d" % [serial, index]
        if _world.create_entity(output_semantic, item_id) != item_id:
            _rollback_created_items(created)
            return _simple_turns._reject_direct_action(WorldActions.OBJECT_DECONSTRUCT, "salvage_create_failed")
        var capacity: Dictionary = _carry_acquisition.evaluate(actor, item_id)
        var stored := int(capacity.get("status", -1)) == 0 and _inventory_mutations.set_container(item_id, actor)
        if not stored:
            if not _world.set_placement(item_id, Layers.Channel.LOOSE_ITEM, _world.placement(actor).anchor, Facing.Value.SOUTH, Footprint.single_cell()):
                _world.remove_entity(item_id)
                _rollback_created_items(created)
                return _simple_turns._reject_direct_action(WorldActions.OBJECT_DECONSTRUCT, "salvage_place_failed")
        created.append(item_id)
    if not _world_interaction_state.set_destroyed(target, true, &"simple_object_deconstructed") or not _world.remove_entity(target):
        _world_interaction_state.set_destroyed(target, false, &"deconstruct_rollback")
        _rollback_created_items(created)
        return _simple_turns._reject_direct_action(WorldActions.OBJECT_DECONSTRUCT, "deconstruct_commit_failed")
    _skill_checks.award_attempt_xp(actor, SkillCatalog.MECHANICAL, difficulty, true)
    var elapsed := _deliberate_elapsed(int(skill_profile.get("duration_ticks", 1)))
    _simple_elapsed_override_ticks = elapsed
    var result := _simple_turns._complete_direct_action(WorldActions.OBJECT_DECONSTRUCT, "")
    result["elapsed_ticks"] = elapsed
    result["target_id"] = target
    result["output_item_ids"] = created
    return result
