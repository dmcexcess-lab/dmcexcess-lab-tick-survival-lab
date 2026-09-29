extends EnvironmentalPressureGameMain
class_name TurnBasedGameMain

const SimpleTurnControllerClass = preload("res://scripts/player/SimpleTurnController.gd")
const ResidentProjectionClass = preload("res://scripts/simulation/population/PopulationResidentProjection.gd")
const TurnIntents = preload("res://scripts/input/PlayerActionIntent.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const PerceptionFearRules = preload("res://scripts/simulation/actors/condition/ConditionPerceptionFearAdapter.gd")
const InjuryFearRules = preload("res://scripts/simulation/actors/condition/ConditionInjuryFearAdapter.gd")
const MovementExertionRules = preload("res://scripts/simulation/actors/condition/MovementConditionExertionService.gd")
const SustainmentOffers = preload("res://scripts/simulation/interaction/SustainmentInteractionOfferProvider.gd")
const WorldActions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const RepairActions = preload("res://scripts/simulation/interaction/WorldObjectRepairActionService.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const Injury = preload("res://scripts/simulation/actors/health/ActorInjuryRecord.gd")

const RESIDENT_SPAWN_SEARCH_RADIUS := 8
const INVALID_CELL := Vector2i(-999999, -999999)
const SURVIVAL_SECONDS_PER_TURN := 1

var _simple_turns: SimpleTurnController = null
var _simple_infected_ids: Array[String] = []
var _simple_firearm_profiles: FirearmProfileCatalog = null
var _simple_firearm_state: FirearmState = null
var _simple_corpse_state: CorpseState = null
var _simple_fear_bands: Dictionary = {}
var _simple_visible_threats: Dictionary = {}
var _simple_threat_free_since_tick: int = -1
var _last_player_hp: int = -1
var _simple_elapsed_override_ticks: int = -1
var _simple_action_serial: int = 1

func _ready() -> void:
    super._ready()
    if session_boot_ok():
        _sync_survival_clock_from_state()
        _last_player_hp = _health_state.current_hp(WorldBootstrapClass.PLAYER_ID) if _health_state != null else -1
        if _hud != null: _hud.refresh()

func _boot_production_world() -> bool:
    if not super._boot_production_world(): return false
    if not _boot_simple_combat_state() or not _configure_simple_survival() or not _hydrate_procedural_local_infected(): return false
    _simple_turns = SimpleTurnControllerClass.new(_world, _collision_catalog, _collision_overrides, WorldBootstrapClass.PLAYER_ID, _health_state, _hand_state, _inventory_state, _physical_catalog, _simple_firearm_profiles, _simple_firearm_state, _inventory_mutations, _hand_mutations, _carry_acquisition, _loot_state)
    _simple_turns.set_infected_actor_ids(_simple_infected_ids)
    add_child(_simple_turns)
    if not _simple_turns.is_ready(): return false
    _simple_turns.action_resolved.connect(Callable(_hud, "present_action_result")); _simple_turns.action_busy_changed.connect(_on_player_action_busy_changed); _simple_turns.turn_completed.connect(_on_simple_turn_completed)
    if not _wire_simple_inventory_route() or not _wire_simple_contextual_route() or not _wire_simple_session_menu() or not _wire_simple_slice7_route(): return false
    if not _keyboard.action_intent.is_connected(_on_turn_intent): _keyboard.action_intent.connect(_on_turn_intent)
    if not _controls.action_intent.is_connected(_on_turn_intent): _controls.action_intent.connect(_on_turn_intent)
    _last_player_hp = _health_state.current_hp(WorldBootstrapClass.PLAYER_ID); return true

func _boot_simple_combat_state() -> bool:
    if _firearm_profiles == null or _firearm_state == null or not _firearm_state.is_ready() or _corpse_state == null or _death_transitions == null or not _death_transitions.is_ready(): return false
    _simple_firearm_profiles = _firearm_profiles; _simple_firearm_state = _firearm_state; _simple_corpse_state = _corpse_state
    var death_cb := Callable(self, "_on_simple_actor_died"); if not _death_transitions.actor_died.is_connected(death_cb): _death_transitions.actor_died.connect(death_cb)
    return true
func _configure_simple_survival() -> bool:
    if _condition_state == null or _condition_service == null or _condition_modifiers == null or not _condition_service.is_ready() or not _condition_state.has_actor(WorldBootstrapClass.PLAYER_ID): return false
    var record := _condition_state.record(WorldBootstrapClass.PLAYER_ID); var start_tick := maxi(int(record.get("anchor_tick", 0)), int(record.get("fatigue_anchor_tick", 0)))
    if not _condition_service.configure_manual_clock(start_tick): return false
    _disable_legacy_condition_event_adapters(); return true
func _sync_survival_clock_from_state() -> bool:
    if _condition_state == null or _condition_service == null or not _condition_state.has_actor(WorldBootstrapClass.PLAYER_ID): return false
    var record := _condition_state.record(WorldBootstrapClass.PLAYER_ID); var anchor_tick := maxi(int(record.get("anchor_tick", 0)), int(record.get("fatigue_anchor_tick", 0)))
    if _condition_service.current_clock_tick() > anchor_tick: anchor_tick = _condition_service.current_clock_tick()
    return _condition_service.configure_manual_clock(anchor_tick)
func _disable_legacy_condition_event_adapters() -> void:
    if _condition_fear != null and _perception != null:
        var cb := Callable(_condition_fear, "_on_perception_changed"); if _perception.perception_changed.is_connected(cb): _perception.perception_changed.disconnect(cb)
    if _condition_injury_fear != null and _health_state != null:
        var cb := Callable(_condition_injury_fear, "_on_damage_applied"); if _health_state.damage_applied.is_connected(cb): _health_state.damage_applied.disconnect(cb)
    if _condition_heard_fear != null and _spatial_sound != null:
        var cb := Callable(_condition_heard_fear, "_on_sound_heard"); if _spatial_sound.sound_heard.is_connected(cb): _spatial_sound.sound_heard.disconnect(cb)
    if _fear_pressure != null: _fear_pressure._on_timing_state_reset()
func _wire_simple_session_menu() -> bool:
    if _shell == null: return false
    var save_cb := Callable(self, "_on_session_save_requested"); var save_menu_cb := Callable(self, "_on_shell_save_menu_requested")
    if not _shell.save_requested.is_connected(save_cb): _shell.save_requested.connect(save_cb)
    if not _shell.save_menu_requested.is_connected(save_menu_cb): _shell.save_menu_requested.connect(save_menu_cb)
    return true
func _on_shell_save_menu_requested() -> void:
    _set_session_status("SAVING..."); var result := save_durable_session(&"save_and_menu"); if not bool(result.get("ok", false)): return
    if _shell != null and _shell.active_modal() != _shell.MODAL_NONE: _shell.close_modal()
    get_tree().change_scene_to_file(STARTUP_SCENE_PATH)
func save_menu_destination() -> String: return STARTUP_SCENE_PATH
func _set_session_status(message: String) -> void:
    if _shell != null: _shell.present_session_status(message)
    super._set_session_status(message)
func save_durable_session(reason: StringName = &"manual") -> Dictionary:
    if _condition_service != null and _condition_state != null and _condition_state.has_actor(WorldBootstrapClass.PLAYER_ID):
        var record := _condition_state.record(WorldBootstrapClass.PLAYER_ID); var anchor_tick := maxi(int(record.get("anchor_tick", 0)), int(record.get("fatigue_anchor_tick", 0)))
        if _condition_service.current_clock_tick() < anchor_tick: _condition_service.configure_manual_clock(anchor_tick)
        _condition_service.settle_manual_clock(WorldBootstrapClass.PLAYER_ID, &"durable_save_settle")
    return super.save_durable_session(reason)
func survival_elapsed_tick() -> int: return -1 if _condition_service == null else _condition_service.current_clock_tick()
func survival_ticks_per_turn() -> int: return 1 if _world_time_profile == null or not _world_time_profile.is_valid() else maxi(1, _world_time_profile.ticks_per_second * SURVIVAL_SECONDS_PER_TURN)

func _wire_simple_inventory_route() -> bool:
    if _simple_turns == null or _loot_panel == null or _loot_inspection == null or _shell == null: return false
    if not _door_pointer.world_cell_primary.is_connected(_on_simple_world_cell): _door_pointer.world_cell_primary.connect(_on_simple_world_cell)
    if not _loot_panel.take_requested.is_connected(_on_simple_loot_take): _loot_panel.take_requested.connect(_on_simple_loot_take)
    if not _loot_panel.store_requested.is_connected(_on_simple_loot_store): _loot_panel.store_requested.connect(_on_simple_loot_store)
    _simple_turns.action_resolved.connect(Callable(_loot_panel, "present_action_result"))
    _simple_turns.loot_container_opened.connect(Callable(_loot_panel, "open_container"))
    _simple_turns.loot_container_changed.connect(Callable(_loot_panel, "refresh"))
    return _shell.configure_simple_inventory_turns(_simple_turns)

func _wire_simple_contextual_route() -> bool:
    if _simple_turns == null or _interaction_affordances == null or _world_interaction_panel == null or _shell == null: return false
    if _door_pointer.world_cell_primary.is_connected(_on_simple_world_cell): _door_pointer.world_cell_primary.disconnect(_on_simple_world_cell)
    if not _door_pointer.world_cell_primary.is_connected(_on_simple_contextual_world_cell): _door_pointer.world_cell_primary.connect(_on_simple_contextual_world_cell)
    if not _world_interaction_panel.action_requested.is_connected(_on_simple_contextual_action_requested): _world_interaction_panel.action_requested.connect(_on_simple_contextual_action_requested)
    return _shell.has_method("configure_simple_contextual_consume") and bool(_shell.call("configure_simple_contextual_consume", Callable(self, "run_simple_inventory_consumption")))

func _wire_simple_slice7_route() -> bool:
    if _crafting_panel == null or _shell == null or _first_aid_actions == null: return false
    if not _crafting_panel.craft_requested.is_connected(_on_simple_craft_requested): _crafting_panel.craft_requested.connect(_on_simple_craft_requested)
    return _shell.has_method("configure_simple_first_aid") and bool(_shell.call("configure_simple_first_aid", Callable(self, "run_simple_first_aid")))
func simple_contextual_panel() -> WorldInteractionPanel: return _world_interaction_panel
func simple_contextual_affordances() -> InteractionAffordanceQuery: return _interaction_affordances

func _on_simple_world_cell(cell: Vector2i) -> void:
    if _simple_turns == null or not _simple_turns.has_control(): return
    var containers := _loot_inspection.searchable_container_ids_at(cell); if containers.size() == 1: _simple_turns.search_loot_container(containers[0]); return
    if not containers.is_empty(): return
    var loose_items: Array[String] = []
    for entity_id: String in _world.entities_at(cell, Layers.Channel.LOOSE_ITEM):
        var entity := _world.entity(entity_id); if entity != null and String(entity.semantic_type).begins_with("item."): loose_items.append(entity_id)
    loose_items.sort(); if loose_items.size() == 1: _simple_turns.pickup_loose_item(loose_items[0])
func _on_simple_contextual_world_cell(cell: Vector2i) -> void:
    if _simple_turns == null or not _simple_turns.has_control() or _interaction_affordances == null: return
    var target_ids: Dictionary = {}
    for channel: int in [Layers.Channel.LOOSE_ITEM, Layers.Channel.OBJECT, Layers.Channel.STRUCTURE, Layers.Channel.ACTOR]:
        for entity_id: String in _world.entities_at(cell, channel): if entity_id != WorldBootstrapClass.PLAYER_ID: target_ids[entity_id] = true
    var entries: Array[Dictionary] = []
    for target_id: String in target_ids.keys():
        var offers: Array[InteractionOffer] = []
        for offer: InteractionOffer in _interaction_affordances.offers(): if offer.target_entity_id == target_id and offer.target_cells.has(cell) and _simple_contextual_action_supported(offer.action_id): offers.append(offer.copy())
        if offers.is_empty(): continue
        var entity := _world.entity(target_id); var title := "INTERACT" if entity == null else String(entity.semantic_type).replace("prop.", "").replace("_", " ").to_upper(); entries.append({"target_id": target_id, "title": title, "offers": offers})
    if entries.is_empty(): _world_interaction_panel.close_panel(); return
    _world_interaction_panel.open_for_targets(entries)
func _simple_contextual_action_supported(action_id: StringName) -> bool: return action_id in [WorldActions.DOOR_OPEN, WorldActions.DOOR_CLOSE, WorldActions.WINDOW_OPEN, WorldActions.WINDOW_CLOSE, WorldActions.OBJECT_DECONSTRUCT, RepairActions.ACTION_ID, SustainmentOffers.DRINK_FROM_FIXTURE, SustainmentOffers.REST_ON_FURNITURE, SustainmentOffers.SLEEP_IN_BED, LootOffersClass.SEARCH_ACTION_ID, LooseItemPickupOffersClass.ACTION_ID, CraftingOffersClass.ACTION_ID]
func _on_simple_contextual_action_requested(target_id: String, action_id: StringName) -> void:
    if action_id == LootOffersClass.SEARCH_ACTION_ID: _simple_turns.search_loot_container(target_id); return
    if action_id == LooseItemPickupOffersClass.ACTION_ID: _simple_turns.pickup_loose_item(target_id); return
    if action_id == CraftingOffersClass.ACTION_ID: _request_target_crafting(WorldBootstrapClass.PLAYER_ID, target_id, action_id); return
    run_simple_contextual_action(WorldBootstrapClass.PLAYER_ID, target_id, action_id)
func run_simple_contextual_action(actor_id: String, target_id: String, action_id: StringName) -> Dictionary: return _run_simple_contextual_action(actor_id, target_id, action_id)
func _run_simple_contextual_action(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    var actor := actor_id.strip_edges(); var target := target_id.strip_edges()
    if actor != WorldBootstrapClass.PLAYER_ID or target.is_empty() or not _world.has_entity(target) or _simple_turns == null or not _simple_turns.has_control(): return {"success": false, "reason": "context_target_unavailable"}
    if not _interaction_reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD): return {"success": false, "reason": "context_target_out_of_reach"}
    var entity := _world.entity(target); if entity == null: return {"success": false, "reason": "context_target_missing"}
    if action_id == WorldActions.OBJECT_DECONSTRUCT: return run_simple_deconstruct(target)
    if action_id == RepairActions.ACTION_ID: return run_simple_repair(target)
    var elapsed := survival_ticks_per_turn(); var valid := false
    if action_id == WorldActions.DOOR_OPEN: valid = _world_interaction_catalog.is_door(entity.semantic_type) and not _world_interaction_state.is_locked(target) and _world_interaction_state.board_count(target) == 0 and not _world_interaction_state.is_broken(target)
    elif action_id == WorldActions.DOOR_CLOSE: valid = _world_interaction_catalog.is_door(entity.semantic_type) and not _world_interaction_state.is_broken(target)
    elif action_id in [WorldActions.WINDOW_OPEN, WorldActions.WINDOW_CLOSE]: valid = _world_interaction_catalog.is_window(entity.semantic_type) and not _world_interaction_state.is_locked(target) and _world_interaction_state.board_count(target) == 0 and not _world_interaction_state.is_broken(target)
    elif action_id == SustainmentOffers.DRINK_FROM_FIXTURE: valid = _potable_target_available(actor, target); elapsed = 10
    elif action_id == SustainmentOffers.REST_ON_FURNITURE: valid = not String(_rest_target_surface(actor, target)).is_empty(); elapsed = _world_time_profile.ticks_per_hour()
    elif action_id == SustainmentOffers.SLEEP_IN_BED: valid = _rest_target_surface(actor, target) == &"bed"; elapsed = _world_time_profile.ticks_per_hour() * 8
    if not valid: return {"success": false, "reason": "context_action_unavailable"}
    if not _simple_turns._begin_direct_action(action_id): return {"success": false, "reason": "player_unavailable"}
    var committed := false
    if action_id == WorldActions.DOOR_OPEN: committed = _door_transition.open_manually(actor, target)
    elif action_id == WorldActions.DOOR_CLOSE: committed = _door_transition.close_manually(actor, target)
    elif action_id == WorldActions.WINDOW_OPEN: committed = _world_interaction_state.set_window_open(target, true, &"simple_window_open")
    elif action_id == WorldActions.WINDOW_CLOSE: committed = _world_interaction_state.set_window_open(target, false, &"simple_window_close")
    elif action_id == SustainmentOffers.DRINK_FROM_FIXTURE: committed = _condition_service.change_condition(actor, ConditionStateClass.HYDRATION, 28, &"potable_water_drunk")
    elif action_id == SustainmentOffers.REST_ON_FURNITURE:
        committed = _condition_service.change_condition(actor, ConditionStateClass.REST, 16, &"rested") and _condition_service.relieve_fatigue(actor, 35, &"rested"); if committed: _apply_simple_surface_comfort(actor, _rest_target_surface(actor, target), false)
    elif action_id == SustainmentOffers.SLEEP_IN_BED:
        committed = _condition_service.change_condition(actor, ConditionStateClass.REST, 72, &"slept") and _condition_service.relieve_fatigue(actor, 100, &"slept"); if committed: _apply_simple_surface_comfort(actor, &"bed", true)
    if not committed: return _simple_turns._reject_direct_action(action_id, "context_mutation_failed")
    _simple_elapsed_override_ticks = elapsed; var result := _simple_turns._complete_direct_action(action_id, ""); result["elapsed_ticks"] = elapsed; result["target_id"] = target; result["action_id"] = action_id; return result

func run_simple_inventory_consumption(item_id: String) -> Dictionary:
    var item := item_id.strip_edges()
    if item.is_empty() or _simple_turns == null or not _simple_turns.has_control() or _sustainment_actions == null: return {"success": false, "reason": "item_action_unavailable"}
    var offer: Dictionary = _sustainment_actions.consumption_offer(WorldBootstrapClass.PLAYER_ID, item)
    if not bool(offer.get("available", false)) or not _world.has_entity(item): return {"success": false, "reason": String(offer.get("reason", "item_not_consumable"))}
    var entity := _world.entity(item); var profile := _sustainment_profiles.profile(entity.semantic_type) if entity != null else {}; if entity == null or profile.is_empty(): return {"success": false, "reason": "item_profile_missing"}
    var capture := _capture_personal_item(item); if capture.is_empty() or not _simple_turns._begin_direct_action(StringName("condition.%s" % String(profile.get("action_kind", "consume")))): return {"success": false, "reason": "player_unavailable"}
    if not _detach_personal_item(capture) or not _world.remove_entity(item): _restore_personal_item(capture); return _simple_turns._reject_direct_action(&"condition.consume", "item_removal_failed")
    if _freshness_mutations.has_record(item): _freshness_mutations.remove_item(item)
    _condition_service.change_condition(WorldBootstrapClass.PLAYER_ID, ConditionStateClass.SATIETY, int(profile.get("satiety_gain", 0)), &"food_consumed"); _condition_service.change_condition(WorldBootstrapClass.PLAYER_ID, ConditionStateClass.HYDRATION, int(profile.get("hydration_gain", 0)), &"drink_consumed"); _condition_service.change_condition(WorldBootstrapClass.PLAYER_ID, ConditionStateClass.ENGAGEMENT, int(profile.get("engagement_gain", 0)), &"meal_enjoyed")
    var elapsed := maxi(1, int(profile.get("duration_ticks", survival_ticks_per_turn()))); _simple_elapsed_override_ticks = elapsed; var intent := StringName("condition.%s" % String(profile.get("action_kind", "consume"))); var result := _simple_turns._complete_direct_action(intent, ""); result["elapsed_ticks"] = elapsed; result["item_id"] = item; return result

func _on_simple_craft_requested(recipe_id: StringName, workstation_id: String) -> void:
    var result := run_simple_craft(recipe_id, workstation_id); if _crafting_panel != null: _crafting_panel.present_action_result(recipe_id, bool(result.get("success", false)), String(result.get("reason", "")), survival_elapsed_tick(), workstation_id)
func run_simple_craft(recipe_id: StringName, workstation_id: String = "") -> Dictionary:
    if _simple_turns == null or not _simple_turns.has_control() or _crafting_plans == null or _crafting_recipes == null: return {"success": false, "reason": "crafting_unavailable"}
    var plan: Dictionary = _crafting_plans.query(WorldBootstrapClass.PLAYER_ID, recipe_id, workstation_id); if not bool(plan.get("ready", false)): return {"success": false, "reason": String(plan.get("reason", "crafting_blocked"))}
    var recipe: CraftingRecipe = _crafting_recipes.recipe(recipe_id); if recipe == null: return {"success": false, "reason": "recipe_unknown"}
    var skill_profile := _skill_checks.action_profile(WorldBootstrapClass.PLAYER_ID, recipe.skill_id, recipe.duration_ticks, recipe.skill_difficulty); if not bool(skill_profile.get("ok", false)): return {"success": false, "reason": String(skill_profile.get("reason", "skill_unavailable"))}
    var exact := _crafting_plans.validate_exact(WorldBootstrapClass.PLAYER_ID, recipe_id, int(plan.get("recipe_catalog_version", -1)), plan.get("consumed_item_ids", []), plan.get("tool_item_ids", []), workstation_id); if not bool(exact.get("ready", false)): return {"success": false, "reason": String(exact.get("reason", "crafting_plan_stale"))}
    var serial := _next_simple_action_serial(); var skill := _skill_checks.resolve_attempt(WorldBootstrapClass.PLAYER_ID, recipe.skill_id, recipe.skill_difficulty, serial, recipe_id, int(skill_profile.get("skill_level", -1))); if not bool(skill.get("ok", false)): return {"success": false, "reason": String(skill.get("reason", "skill_check_unavailable"))}
    var elapsed := _deliberate_elapsed(int(skill_profile.get("duration_ticks", recipe.duration_ticks)))
    if not bool(skill.get("success", false)): _skill_checks.award_attempt_xp(WorldBootstrapClass.PLAYER_ID, recipe.skill_id, recipe.skill_difficulty, false); return {"success": false, "reason": "skill_check_failed", "elapsed_ticks": 0}
    var captures: Array[Dictionary] = []
    for value: Variant in exact.get("consumed_item_ids", []):
        var capture := _capture_personal_item(String(value)); if capture.is_empty(): return {"success": false, "reason": "input_disposition_stale"}; captures.append(capture)
    var outputs: Array[String] = []
    for index in range(exact.get("output_semantics", []).size()):
        var output_id := "craft.simple.%016d.%02d" % [serial, index]; if _world.has_entity(output_id): return {"success": false, "reason": "output_identity_collision"}; outputs.append(output_id)
    if not _simple_turns._begin_direct_action(&"crafting.craft_recipe"): return {"success": false, "reason": "player_unavailable"}
    var removed: Array[Dictionary] = []
    for capture: Dictionary in captures:
        if not _remove_captured_item(capture): _restore_captured_items(removed); return _simple_turns._reject_direct_action(&"crafting.craft_recipe", "input_remove_failed")
        removed.append(capture)
    var created: Array[String] = []; var semantics: Array = exact.get("output_semantics", [])
    for index in range(outputs.size()):
        var output_id := outputs[index]
        if _world.create_entity(StringName(semantics[index]), output_id) != output_id or not _inventory_mutations.set_container(output_id, WorldBootstrapClass.PLAYER_ID): _rollback_created_items(created); _restore_captured_items(removed); return _simple_turns._reject_direct_action(&"crafting.craft_recipe", "output_commit_failed")
        created.append(output_id)
    if not _skill_checks.award_attempt_xp(WorldBootstrapClass.PLAYER_ID, recipe.skill_id, recipe.skill_difficulty, true): _rollback_created_items(created); _restore_captured_items(removed); return _simple_turns._reject_direct_action(&"crafting.craft_recipe", "skill_xp_commit_failed")
    _simple_elapsed_override_ticks = elapsed; var result := _simple_turns._complete_direct_action(&"crafting.craft_recipe", ""); result["elapsed_ticks"] = elapsed; result["output_item_ids"] = created; result["consumed_item_ids"] = exact.get("consumed_item_ids", []).duplicate(); result["recipe_id"] = recipe_id; return result

func run_simple_first_aid(item_id: String, injury_id: String) -> Dictionary:
    if _simple_turns == null or not _simple_turns.has_control() or _first_aid_actions == null: return {"success": false, "reason": "first_aid_unavailable"}
    var chosen: Dictionary = {}; for offer: Dictionary in _first_aid_actions.treatment_offers(WorldBootstrapClass.PLAYER_ID, item_id): if String(offer.get("injury_id", "")) == injury_id: chosen = offer; break
    var wound: ActorInjuryRecord = _health_state.injury(WorldBootstrapClass.PLAYER_ID, injury_id); if chosen.is_empty() or wound == null: return {"success": false, "reason": "treatment_unavailable"}
    var captures: Array[Dictionary] = []; for value: Variant in chosen.get("resource_item_ids", []): var capture := _capture_personal_item(String(value)); if capture.is_empty(): return {"success": false, "reason": "treatment_resource_changed"}; captures.append(capture)
    var serial := _next_simple_action_serial(); var difficulty := int(chosen.get("skill_difficulty", 1)); var skill := _skill_checks.resolve_attempt(WorldBootstrapClass.PLAYER_ID, SkillCatalog.SURVIVAL, difficulty, serial, &"health.first_aid", int(chosen.get("skill_level", -1))); if not bool(skill.get("ok", false)): return {"success": false, "reason": "skill_check_unavailable"}
    if not _simple_turns._begin_direct_action(&"health.first_aid"): return {"success": false, "reason": "player_unavailable"}
    var removed: Array[Dictionary] = []
    for capture: Dictionary in captures:
        if not _remove_captured_item(capture): _restore_captured_items(removed); return _simple_turns._reject_direct_action(&"health.first_aid", "treatment_resource_commit_failed")
        removed.append(capture)
    var skill_success := bool(skill.get("success", false)); var next_severity := wound.severity; if skill_success and String(chosen.get("mode", "")) == "kit": next_severity = maxi(Injury.Severity.MINOR, wound.severity - 1)
    if not _health_state.set_injury_state(WorldBootstrapClass.PLAYER_ID, injury_id, next_severity, true, wound.treated or skill_success): _restore_captured_items(removed); return _simple_turns._reject_direct_action(&"health.first_aid", "injury_commit_failed")
    if not _skill_checks.award_attempt_xp(WorldBootstrapClass.PLAYER_ID, SkillCatalog.SURVIVAL, difficulty, skill_success): _health_state.set_injury_state(WorldBootstrapClass.PLAYER_ID, injury_id, wound.severity, wound.stabilized, wound.treated); _restore_captured_items(removed); return _simple_turns._reject_direct_action(&"health.first_aid", "skill_xp_commit_failed")
    var elapsed := maxi(1, int(chosen.get("duration_ticks", survival_ticks_per_turn()))); _simple_elapsed_override_ticks = elapsed; var result := _simple_turns._complete_direct_action(&"health.first_aid", ""); result["elapsed_ticks"] = elapsed; result["treated"] = wound.treated or skill_success; result["stabilized"] = true; result["severity"] = next_severity; return result

func run_simple_repair(target_id: String) -> Dictionary:
    var target := target_id.strip_edges(); var actor := WorldBootstrapClass.PLAYER_ID
    if target.is_empty() or not _world.has_entity(target) or _simple_turns == null or not _simple_turns.has_control(): return {"success": false, "reason": "repair_target_unavailable"}
    if not _interaction_reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD): return {"success": false, "reason": "target_out_of_reach"}
    var entity := _world.entity(target); var profile := _world_interaction_catalog.repair_profile(entity.semantic_type) if entity != null else {}; if profile.is_empty() or not _world_interaction_state.is_broken(target): return {"success": false, "reason": "target_not_repairable"}
    var tool := _find_carried_any(profile.get("tool_semantics", []), {}); if tool.is_empty(): return {"success": false, "reason": "repair_tool_required"}
    var used := {tool: true}; var materials: Array[String] = []
    for semantic: Variant in profile.get("material_semantics", []): var item := _find_carried_any([semantic], used); if item.is_empty(): return {"success": false, "reason": "repair_material_required"}; used[item] = true; materials.append(item)
    var skill_profile := _skill_checks.action_profile(actor, SkillCatalog.MECHANICAL, int(profile.get("base_duration_ticks", 16)), int(profile.get("difficulty", 3))); if not bool(skill_profile.get("ok", false)): return {"success": false, "reason": "mechanical_skill_unavailable"}
    var serial := _next_simple_action_serial(); var skill := _skill_checks.resolve_attempt(actor, SkillCatalog.MECHANICAL, int(profile.get("difficulty", 3)), serial, StringName("world.repair|%s" % target), int(skill_profile.get("skill_level", -1))); if not bool(skill.get("ok", false)) or not bool(skill.get("success", false)): return {"success": false, "reason": "mechanical_skill_check_failed"}
    var captures: Array[Dictionary] = []; for item: String in materials: captures.append(_capture_personal_item(item)); for capture: Dictionary in captures: if capture.is_empty(): return {"success": false, "reason": "repair_material_changed"}
    if not _simple_turns._begin_direct_action(RepairActions.ACTION_ID): return {"success": false, "reason": "player_unavailable"}
    var previous_door := _door_state.state(target); if previous_door == DoorValue.OPEN and not _door_transition.close_manually(actor, target): return _simple_turns._reject_direct_action(RepairActions.ACTION_ID, "door_close_failed")
    if not _world_interaction_state.set_broken(target, false, &"simple_door_repaired"): return _simple_turns._reject_direct_action(RepairActions.ACTION_ID, "repair_state_failed")
    var removed: Array[Dictionary] = []
    for capture: Dictionary in captures:
        if not _remove_captured_item(capture): _world_interaction_state.set_broken(target, true, &"repair_rollback"); _restore_captured_items(removed); return _simple_turns._reject_direct_action(RepairActions.ACTION_ID, "repair_material_commit_failed")
        removed.append(capture)
    _skill_checks.award_attempt_xp(actor, SkillCatalog.MECHANICAL, int(profile.get("difficulty", 3)), true); var elapsed := _deliberate_elapsed(int(skill_profile.get("duration_ticks", 1))); _simple_elapsed_override_ticks = elapsed; var result := _simple_turns._complete_direct_action(RepairActions.ACTION_ID, ""); result["elapsed_ticks"] = elapsed; result["target_id"] = target; return result

func run_simple_deconstruct(target_id: String) -> Dictionary:
    var target := target_id.strip_edges(); var actor := WorldBootstrapClass.PLAYER_ID
    if target.is_empty() or not _world.has_entity(target) or _simple_turns == null or not _simple_turns.has_control(): return {"success": false, "reason": "deconstruct_target_unavailable"}
    if not _interaction_reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD): return {"success": false, "reason": "target_out_of_reach"}
    var entity := _world.entity(target); var placement := _world.placement(target); var profile := _world_interaction_catalog.deconstruction_profile(entity.semantic_type) if entity != null else {}; if profile.is_empty() or placement == null or placement.channel != Layers.Channel.OBJECT or _inventory_state.has_container(target): return {"success": false, "reason": "object_not_deconstructible"}
    var tool := _find_carried_any(profile.get("tool_semantics", []), {}); if tool.is_empty(): return {"success": false, "reason": "deconstruction_tool_required"}
    var difficulty := int(profile.get("difficulty", 2)); var skill_profile := _skill_checks.action_profile(actor, SkillCatalog.MECHANICAL, int(profile.get("base_duration_ticks", 16)), difficulty); if not bool(skill_profile.get("ok", false)): return {"success": false, "reason": "mechanical_skill_unavailable"}
    var serial := _next_simple_action_serial(); var skill := _skill_checks.resolve_attempt(actor, SkillCatalog.MECHANICAL, difficulty, serial, StringName("world.deconstruct|%s" % target), int(skill_profile.get("skill_level", -1))); if not bool(skill.get("ok", false)) or not bool(skill.get("success", false)): return {"success": false, "reason": "mechanical_skill_check_failed"}
    var output_semantic := StringName(profile.get("output_semantic", &"")); var count := int(profile.get("output_count", 0)); if count < 1: return {"success": false, "reason": "deconstruction_profile_invalid"}
    if not _simple_turns._begin_direct_action(WorldActions.OBJECT_DECONSTRUCT): return {"success": false, "reason": "player_unavailable"}
    var created: Array[String] = []
    for index in range(count):
        var item_id := "deconstruct.simple.%016d.%02d" % [serial, index]
        if _world.create_entity(output_semantic, item_id) != item_id: _rollback_created_items(created); return _simple_turns._reject_direct_action(WorldActions.OBJECT_DECONSTRUCT, "salvage_create_failed")
        var capacity := _carry_acquisition.evaluate(actor, item_id); var stored := int(capacity.get("status", -1)) == 0 and _inventory_mutations.set_container(item_id, actor)
        if not stored and not _world.set_placement(item_id, Layers.Channel.LOOSE_ITEM, _world.placement(actor).anchor, Facing.Value.SOUTH, Footprint.single_cell()): _world.remove_entity(item_id); _rollback_created_items(created); return _simple_turns._reject_direct_action(WorldActions.OBJECT_DECONSTRUCT, "salvage_place_failed")
        created.append(item_id)
    if not _world_interaction_state.set_destroyed(target, true, &"simple_object_deconstructed") or not _world.remove_entity(target): _world_interaction_state.set_destroyed(target, false, &"deconstruct_rollback"); _rollback_created_items(created); return _simple_turns._reject_direct_action(WorldActions.OBJECT_DECONSTRUCT, "deconstruct_commit_failed")
    _skill_checks.award_attempt_xp(actor, SkillCatalog.MECHANICAL, difficulty, true); var elapsed := _deliberate_elapsed(int(skill_profile.get("duration_ticks", 1))); _simple_elapsed_override_ticks = elapsed; var result := _simple_turns._complete_direct_action(WorldActions.OBJECT_DECONSTRUCT, ""); result["elapsed_ticks"] = elapsed; result["target_id"] = target; result["output_item_ids"] = created; return result

func _capture_personal_item(item_id: String) -> Dictionary:
    if item_id.is_empty() or not _world.has_entity(item_id): return {}
    var entity := _world.entity(item_id); if entity == null: return {}
    var assignment := _hand_state.assignment_for_item(item_id)
    if not assignment.is_empty() and String(assignment.get("actor_id", "")) == WorldBootstrapClass.PLAYER_ID: return {"item_id": item_id, "semantic": entity.semantic_type, "kind": "hand", "slot": int(assignment.get("slot", -1)), "container": ""}
    var current := item_id; var visited: Dictionary = {}
    while _inventory_state.is_contained(current) and not visited.has(current):
        visited[current] = true; var container := _inventory_state.container_of(current)
        if container == WorldBootstrapClass.PLAYER_ID: return {"item_id": item_id, "semantic": entity.semantic_type, "kind": "container", "slot": -1, "container": _inventory_state.container_of(item_id)}
        current = container
    return {}
func _detach_personal_item(capture: Dictionary) -> bool: return _hand_mutations.clear_slot(WorldBootstrapClass.PLAYER_ID, int(capture.get("slot", -1))) if String(capture.get("kind", "")) == "hand" else _inventory_mutations.clear_container(String(capture.get("item_id", "")))
func _restore_personal_item(capture: Dictionary) -> bool:
    var item := String(capture.get("item_id", "")); if not _world.has_entity(item): _world.create_entity(StringName(capture.get("semantic", &"")), item)
    return _hand_mutations.set_item(WorldBootstrapClass.PLAYER_ID, int(capture.get("slot", -1)), item) if String(capture.get("kind", "")) == "hand" else _inventory_mutations.set_container(item, String(capture.get("container", "")))
func _remove_captured_item(capture: Dictionary) -> bool:
    if not _detach_personal_item(capture): return false
    if _world.remove_entity(String(capture.get("item_id", ""))): return true
    _restore_personal_item(capture); return false
func _restore_captured_items(captures: Array[Dictionary]) -> void:
    for capture: Dictionary in captures: _restore_personal_item(capture)
func _rollback_created_items(ids: Array[String]) -> void:
    for index in range(ids.size() - 1, -1, -1):
        var item := ids[index]; if _inventory_state.is_contained(item): _inventory_mutations.clear_container(item)
        if _world.has_entity(item): _world.remove_entity(item)
func _find_carried_any(semantics: Array, excluded: Dictionary) -> String:
    var allowed: Dictionary = {}; for value: Variant in semantics: allowed[String(value)] = true
    var carry := _carry_query.query(WorldBootstrapClass.PLAYER_ID); var ids: Array[String] = []; for value: Variant in carry.get("item_ids", []): ids.append(String(value)); ids.sort()
    for item: String in ids:
        if excluded.has(item) or not _world.has_entity(item): continue
        var entity := _world.entity(item); if entity != null and allowed.has(String(entity.semantic_type)): return item
    return ""
func _deliberate_elapsed(base_ticks: int) -> int:
    var duration := maxi(1, base_ticks); if _condition_modifiers != null and _condition_modifiers.is_ready() and _condition_modifiers.has_actor(WorldBootstrapClass.PLAYER_ID): duration = maxi(1, int(ceili(float(duration * _condition_modifiers.deliberate_action_duration_multiplier_bp(WorldBootstrapClass.PLAYER_ID)) / 10000.0)))
    return duration
func _next_simple_action_serial() -> int: var serial := _simple_action_serial; _simple_action_serial += 1; return serial
func _apply_simple_surface_comfort(actor_id: String, surface: StringName, full_sleep: bool) -> void:
    if surface == &"bed": _condition_service.change_condition(actor_id, ConditionStateClass.COMFORT, 15 if full_sleep else 6, &"comfortable_rest")
    elif surface == &"sofa": _condition_service.change_condition(actor_id, ConditionStateClass.COMFORT, -2 if full_sleep else 5, &"sofa_rest")
    elif surface == &"chair": _condition_service.change_condition(actor_id, ConditionStateClass.COMFORT, -6 if full_sleep else 3, &"chair_rest")
    else: _condition_service.change_condition(actor_id, ConditionStateClass.COMFORT, -10 if full_sleep else -4, &"rough_rest")
func _on_simple_loot_take(container_id: String, item_id: String) -> void: if _simple_turns != null: _simple_turns.take_loot_item(container_id, item_id)
func _on_simple_loot_store(container_id: String, item_id: String) -> void: if _simple_turns != null: _simple_turns.store_loot_item(container_id, item_id)
func _hydrate_procedural_local_infected() -> bool:
    var player: WorldPlacement = _world.placement(WorldBootstrapClass.PLAYER_ID); var global_plan: GeneratedGlobalWorldPlan = WorldBootstrapClass.global_plan(); if player == null or global_plan == null or not global_plan.is_generated(): return false
    var population_plan := {"ok": true, "settlements": global_plan.population_settlements.duplicate(true), "resident_population": global_plan.resident_population, "infected_population": global_plan.infected_population, "survivor_population": global_plan.survivor_population, "local_area_manifest": global_plan.local_area_manifest.duplicate(true)}; var records: Array[Dictionary] = ResidentProjectionClass.new().infected_near(population_plan, "", player.anchor)
    for record: Dictionary in records:
        var actor_id := String(record.get("resident_id", "")).strip_edges(); var home_cell: Vector2i = record.get("home_cell", INVALID_CELL); if actor_id.is_empty() or home_cell == INVALID_CELL or not _spatial_query.has_terrain(home_cell): continue
        if _world.has_entity(actor_id):
            var existing := _world.placement(actor_id); if existing != null and not _simple_infected_ids.has(actor_id):
                if not _ensure_simple_infected_state(actor_id): return false
                _simple_infected_ids.append(actor_id)
            continue
        var spawn_cell := _clear_actor_cell_near_home(home_cell); if spawn_cell == INVALID_CELL: continue
        if _world.create_entity(&"actor.survivor", actor_id) != actor_id: continue
        if not _world.set_placement(actor_id, Layers.Channel.ACTOR, spawn_cell, Facing.Value.SOUTH, Footprint.single_cell()): _world.remove_entity(actor_id); continue
        if not _ensure_simple_infected_state(actor_id): _world.remove_entity(actor_id); return false
        _simple_infected_ids.append(actor_id)
    # An empty local infected set is a valid procedural outcome. The active set is
    # bounded and may legitimately contain nobody at the player's starting cell;
    # requiring at least one infected turned that ordinary world state into a
    # generic gameplay_boot_failed startup failure.
    _simple_infected_ids.sort()
    return true
func _ensure_simple_infected_state(actor_id: String) -> bool:
    if not _hand_state.has_actor(actor_id) and not _hand_mutations.enroll_actor(actor_id): return false
    if not _inventory_state.has_container(actor_id) and not _inventory_mutations.enroll_container(actor_id): return false
    if not _health_state.has_actor(actor_id) and not _health_state.enroll_actor(actor_id): return false
    return true
func _clear_actor_cell_near_home(origin: Vector2i) -> Vector2i:
    for radius in range(0, RESIDENT_SPAWN_SEARCH_RADIUS + 1):
        for y in range(-radius, radius + 1):
            for x in range(-radius, radius + 1):
                if radius > 0 and absi(x) != radius and absi(y) != radius: continue
                var cell := origin + Vector2i(x, y); if _spatial_query.has_terrain(cell) and _spatial_query.query_cell(cell, "", true).is_clear(): return cell
    return INVALID_CELL
func _on_turn_intent(intent: StringName) -> void: if _simple_turns != null and (TurnIntents.is_movement(intent) or intent == TurnIntents.COMBAT_FORWARD): _simple_turns.submit_intent(intent)
func _on_simple_turn_completed(_turn_number: int, _active_actor_count: int) -> void:
    var player := _world.placement(WorldBootstrapClass.PLAYER_ID); if player == null: return
    var streaming := WorldBootstrapClass.streaming_coordinator(); if streaming != null: streaming.update_focus(player.anchor)
    if _perception != null: _perception.recompute(&"simple_turn")
    var elapsed := _simple_elapsed_override_ticks if _simple_elapsed_override_ticks > 0 else survival_ticks_per_turn(); _simple_elapsed_override_ticks = -1; _advance_simple_survival(elapsed)
    if _hud != null: _hud.refresh()
    _flush_pending_visual_state()
func _advance_simple_survival(elapsed_ticks: int) -> void:
    if _condition_service == null or not _condition_service.has_actor(WorldBootstrapClass.PLAYER_ID): return
    if not _condition_service.advance_elapsed_ticks(WorldBootstrapClass.PLAYER_ID, maxi(1, elapsed_ticks), &"simple_turn_elapsed"): return
    var intent := _simple_turns.last_completed_intent() if _simple_turns != null else &""; if intent == TurnIntents.RUN_FORWARD: _condition_service.apply_exertion(WorldBootstrapClass.PLAYER_ID, MovementExertionRules.RUN_BASE_FATIGUE_COST, &"movement_exertion")
    _apply_simple_fear_pressure()
func _apply_simple_fear_pressure() -> void:
    if _condition_service == null or _perception == null: return
    var player := _world.placement(WorldBootstrapClass.PLAYER_ID); if player == null: return
    var current_visible: Dictionary = {}; var worsened: Array[Dictionary] = []
    for actor_id: String in _simple_infected_ids:
        var placement := _world.placement(actor_id); if placement == null or not _health_state.has_actor(actor_id) or _health_state.current_hp(actor_id) <= 0: continue
        var distance := _chebyshev(player.anchor, placement.anchor); if distance > SimpleTurnController.ACTIVE_RADIUS or not _perception.is_visible(placement.anchor): continue
        current_visible[actor_id] = true; var band := PerceptionFearRules._band_for_distance(distance); var previous := int(_simple_fear_bands.get(actor_id, 0)); if band > previous: worsened.append({"actor_id": actor_id, "pressure": int(PerceptionFearRules.BAND_PRESSURE.get(band, 0)) - int(PerceptionFearRules.BAND_PRESSURE.get(previous, 0))}); _simple_fear_bands[actor_id] = band
    var now := survival_elapsed_tick()
    if current_visible.is_empty():
        if not _simple_visible_threats.is_empty() and _simple_threat_free_since_tick < 0: _simple_threat_free_since_tick = now
        if _simple_threat_free_since_tick >= 0 and now - _simple_threat_free_since_tick >= _world_time_profile.ticks_per_minute() * PerceptionFearRules.ENCOUNTER_RESET_MINUTES: _simple_fear_bands.clear(); _simple_threat_free_since_tick = -1
    else: _simple_threat_free_since_tick = -1
    _simple_visible_threats = current_visible; worsened.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: var pa := int(a.get("pressure", 0)); var pb := int(b.get("pressure", 0)); return pa > pb if pa != pb else String(a.get("actor_id", "")) < String(b.get("actor_id", "")))
    var pressure := 0
    for index in range(worsened.size()): var weight_bp := PerceptionFearRules.DIMINISHING_BP[mini(index, PerceptionFearRules.DIMINISHING_BP.size() - 1)]; pressure += int(ceili(float(int(worsened[index].get("pressure", 0)) * weight_bp) / 10000.0))
    var current_hp := _health_state.current_hp(WorldBootstrapClass.PLAYER_ID); if _last_player_hp >= 0 and current_hp < _last_player_hp: pressure += InjuryFearRules.pressure_for_damage(_last_player_hp - current_hp)
    _last_player_hp = current_hp; pressure = mini(ActorFearPressureService.MAX_PRESSURE_PER_TICK, maxi(0, pressure)); if pressure > 0: _condition_service.change_condition(WorldBootstrapClass.PLAYER_ID, ConditionStateClass.CALM, -pressure, &"simple_turn_fear_pressure")
static func _chebyshev(a: Vector2i, b: Vector2i) -> int: var delta := a - b; return maxi(absi(delta.x), absi(delta.y))
func _on_simple_actor_died(actor_id: String, _corpse_id: String) -> void: if actor_id == WorldBootstrapClass.PLAYER_ID and _shell != null: _shell.call_deferred("open_death")
func simple_turn_controller() -> SimpleTurnController: return _simple_turns
func simple_infected_actor_ids() -> Array[String]: return _simple_infected_ids.duplicate()
func combat_health_state() -> ActorHealthState: return _health_state
func combat_corpse_state() -> CorpseState: return _simple_corpse_state
func combat_firearm_state() -> FirearmState: return _simple_firearm_state
