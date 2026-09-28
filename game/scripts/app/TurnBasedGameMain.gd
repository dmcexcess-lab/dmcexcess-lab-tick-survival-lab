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
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")

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
    _simple_turns.action_resolved.connect(Callable(_hud, "present_action_result"))
    _simple_turns.action_busy_changed.connect(_on_player_action_busy_changed)
    _simple_turns.turn_completed.connect(_on_simple_turn_completed)
    if not _wire_simple_inventory_route() or not _wire_simple_contextual_route() or not _wire_simple_session_menu(): return false

    var legacy_submit := Callable(_controller, "submit_intent")
    if _keyboard.action_intent.is_connected(legacy_submit): _keyboard.action_intent.disconnect(legacy_submit)
    if _controls.action_intent.is_connected(legacy_submit): _controls.action_intent.disconnect(legacy_submit)
    _keyboard.action_intent.connect(_on_turn_intent)
    _controls.action_intent.connect(_on_turn_intent)
    _last_player_hp = _health_state.current_hp(WorldBootstrapClass.PLAYER_ID)
    return true

func _boot_simple_combat_state() -> bool:
    if _firearm_profiles == null or _firearm_state == null or not _firearm_state.is_ready() or _corpse_state == null or _death_transitions == null or not _death_transitions.is_ready(): return false
    _simple_firearm_profiles = _firearm_profiles; _simple_firearm_state = _firearm_state; _simple_corpse_state = _corpse_state
    var death_cb := Callable(self, "_on_simple_actor_died")
    if not _death_transitions.actor_died.is_connected(death_cb): _death_transitions.actor_died.connect(death_cb)
    return true

func _configure_simple_survival() -> bool:
    if _condition_state == null or _condition_service == null or _condition_modifiers == null or not _condition_service.is_ready() or not _condition_state.has_actor(WorldBootstrapClass.PLAYER_ID): return false
    var record := _condition_state.record(WorldBootstrapClass.PLAYER_ID)
    var start_tick := maxi(int(record.get("anchor_tick", 0)), int(record.get("fatigue_anchor_tick", 0)))
    if not _condition_service.configure_manual_clock(start_tick): return false
    _disable_legacy_condition_event_adapters(); return true

func _sync_survival_clock_from_state() -> bool:
    if _condition_state == null or _condition_service == null or not _condition_state.has_actor(WorldBootstrapClass.PLAYER_ID): return false
    var record := _condition_state.record(WorldBootstrapClass.PLAYER_ID)
    var anchor_tick := maxi(int(record.get("anchor_tick", 0)), int(record.get("fatigue_anchor_tick", 0)))
    if _condition_service.current_clock_tick() > anchor_tick: anchor_tick = _condition_service.current_clock_tick()
    return _condition_service.configure_manual_clock(anchor_tick)

func _disable_legacy_condition_event_adapters() -> void:
    if _condition_fear != null and _perception != null:
        var perception_cb := Callable(_condition_fear, "_on_perception_changed")
        if _perception.perception_changed.is_connected(perception_cb): _perception.perception_changed.disconnect(perception_cb)
    if _condition_injury_fear != null and _health_state != null:
        var injury_cb := Callable(_condition_injury_fear, "_on_damage_applied")
        if _health_state.damage_applied.is_connected(injury_cb): _health_state.damage_applied.disconnect(injury_cb)
    if _condition_heard_fear != null and _spatial_sound != null:
        var heard_cb := Callable(_condition_heard_fear, "_on_sound_heard")
        if _spatial_sound.sound_heard.is_connected(heard_cb): _spatial_sound.sound_heard.disconnect(heard_cb)
    if _fear_pressure != null: _fear_pressure._on_timing_state_reset()

func _wire_simple_session_menu() -> bool:
    if _shell == null: return false
    var save_cb := Callable(self, "_on_session_save_requested"); var save_menu_cb := Callable(self, "_on_shell_save_menu_requested")
    if not _shell.save_requested.is_connected(save_cb): _shell.save_requested.connect(save_cb)
    if not _shell.save_menu_requested.is_connected(save_menu_cb): _shell.save_menu_requested.connect(save_menu_cb)
    return true
func _on_shell_save_menu_requested() -> void:
    _set_session_status("SAVING...")
    var result := save_durable_session(&"save_and_menu")
    if not bool(result.get("ok", false)): return
    if _shell != null and _shell.active_modal() != _shell.MODAL_NONE: _shell.close_modal()
    get_tree().change_scene_to_file(STARTUP_SCENE_PATH)
func save_menu_destination() -> String: return STARTUP_SCENE_PATH
func _set_session_status(message: String) -> void:
    if _shell != null: _shell.present_session_status(message)
    super._set_session_status(message)

func save_durable_session(reason: StringName = &"manual") -> Dictionary:
    if _condition_service != null and _condition_state != null and _condition_state.has_actor(WorldBootstrapClass.PLAYER_ID):
        var record := _condition_state.record(WorldBootstrapClass.PLAYER_ID)
        var anchor_tick := maxi(int(record.get("anchor_tick", 0)), int(record.get("fatigue_anchor_tick", 0)))
        if _condition_service.current_clock_tick() < anchor_tick: _condition_service.configure_manual_clock(anchor_tick)
        _condition_service.settle_manual_clock(WorldBootstrapClass.PLAYER_ID, &"durable_save_settle")
    return super.save_durable_session(reason)
func survival_elapsed_tick() -> int: return -1 if _condition_service == null else _condition_service.current_clock_tick()
func survival_ticks_per_turn() -> int:
    if _world_time_profile == null or not _world_time_profile.is_valid(): return 1
    return maxi(1, _world_time_profile.ticks_per_second * SURVIVAL_SECONDS_PER_TURN)

func _wire_simple_inventory_route() -> bool:
    if _simple_turns == null or _loot_panel == null or _loot_inspection == null or _shell == null: return false
    if _loot_controller != null:
        var legacy_pointer := Callable(_loot_controller, "submit_world_cell")
        if _door_pointer.world_cell_primary.is_connected(legacy_pointer): _door_pointer.world_cell_primary.disconnect(legacy_pointer)
        var legacy_take := Callable(_loot_controller, "request_take")
        if _loot_panel.take_requested.is_connected(legacy_take): _loot_panel.take_requested.disconnect(legacy_take)
        var legacy_store := Callable(_loot_controller, "request_store")
        if _loot_panel.store_requested.is_connected(legacy_store): _loot_panel.store_requested.disconnect(legacy_store)
        var legacy_hud := Callable(_hud, "present_action_result")
        if _loot_controller.action_resolved.is_connected(legacy_hud): _loot_controller.action_resolved.disconnect(legacy_hud)
        var legacy_panel_result := Callable(_loot_panel, "present_action_result")
        if _loot_controller.action_resolved.is_connected(legacy_panel_result): _loot_controller.action_resolved.disconnect(legacy_panel_result)
        var legacy_open := Callable(_loot_panel, "open_container")
        if _loot_controller.container_opened.is_connected(legacy_open): _loot_controller.container_opened.disconnect(legacy_open)
        var legacy_refresh := Callable(_loot_panel, "refresh")
        if _loot_controller.container_changed.is_connected(legacy_refresh): _loot_controller.container_changed.disconnect(legacy_refresh)
    _door_pointer.world_cell_primary.connect(_on_simple_world_cell)
    _loot_panel.take_requested.connect(_on_simple_loot_take); _loot_panel.store_requested.connect(_on_simple_loot_store)
    _simple_turns.action_resolved.connect(Callable(_loot_panel, "present_action_result"))
    _simple_turns.loot_container_opened.connect(Callable(_loot_panel, "open_container")); _simple_turns.loot_container_changed.connect(Callable(_loot_panel, "refresh"))
    return _shell.configure_simple_inventory_turns(_simple_turns)

func _wire_simple_contextual_route() -> bool:
    if _simple_turns == null or _interaction_affordances == null or _world_interaction_panel == null or _world_interaction_controller == null or _shell == null: return false
    var legacy_world_pointer := Callable(_world_interaction_controller, "submit_world_cell")
    if _door_pointer.world_cell_primary.is_connected(legacy_world_pointer): _door_pointer.world_cell_primary.disconnect(legacy_world_pointer)
    if _door_pointer.world_cell_primary.is_connected(_on_simple_world_cell): _door_pointer.world_cell_primary.disconnect(_on_simple_world_cell)
    var legacy_panel_action := Callable(_world_interaction_controller, "_on_action_requested")
    if _world_interaction_panel.action_requested.is_connected(legacy_panel_action): _world_interaction_panel.action_requested.disconnect(legacy_panel_action)
    _door_pointer.world_cell_primary.connect(_on_simple_contextual_world_cell)
    _world_interaction_panel.action_requested.connect(_on_simple_contextual_action_requested)
    if not _shell.has_method("configure_simple_contextual_consume"): return false
    return bool(_shell.call("configure_simple_contextual_consume", Callable(self, "run_simple_inventory_consumption")))

func simple_contextual_panel() -> WorldInteractionPanel: return _world_interaction_panel
func simple_contextual_affordances() -> InteractionAffordanceQuery: return _interaction_affordances

func _on_simple_world_cell(cell: Vector2i) -> void:
    if _simple_turns == null or not _simple_turns.has_control(): return
    var containers := _loot_inspection.searchable_container_ids_at(cell)
    if containers.size() == 1: _simple_turns.search_loot_container(containers[0]); return
    if not containers.is_empty(): return
    var loose_items: Array[String] = []
    for entity_id: String in _world.entities_at(cell, Layers.Channel.LOOSE_ITEM):
        var entity := _world.entity(entity_id)
        if entity != null and String(entity.semantic_type).begins_with("item."): loose_items.append(entity_id)
    loose_items.sort()
    if loose_items.size() == 1: _simple_turns.pickup_loose_item(loose_items[0])

func _on_simple_contextual_world_cell(cell: Vector2i) -> void:
    if _simple_turns == null or not _simple_turns.has_control() or _interaction_affordances == null: return
    var target_ids: Dictionary = {}
    for channel: int in [Layers.Channel.LOOSE_ITEM, Layers.Channel.OBJECT, Layers.Channel.STRUCTURE, Layers.Channel.ACTOR]:
        for entity_id: String in _world.entities_at(cell, channel):
            if entity_id != WorldBootstrapClass.PLAYER_ID: target_ids[entity_id] = true
    var entries: Array[Dictionary] = []
    for target_id: String in target_ids.keys():
        var target_offers: Array[InteractionOffer] = []
        for offer: InteractionOffer in _interaction_affordances.offers():
            if offer.target_entity_id == target_id and offer.target_cells.has(cell) and _simple_contextual_action_supported(offer.action_id): target_offers.append(offer.copy())
        if target_offers.is_empty(): continue
        var entity := _world.entity(target_id)
        var title := "INTERACT" if entity == null else String(entity.semantic_type).replace("prop.", "").replace("_", " ").to_upper()
        entries.append({"target_id": target_id, "title": title, "offers": target_offers})
    if entries.is_empty(): _world_interaction_panel.close_panel(); return
    _world_interaction_panel.open_for_targets(entries)

func _simple_contextual_action_supported(action_id: StringName) -> bool:
    return action_id in [WorldActions.DOOR_OPEN, WorldActions.DOOR_CLOSE, WorldActions.WINDOW_OPEN, WorldActions.WINDOW_CLOSE, SustainmentOffers.DRINK_FROM_FIXTURE, SustainmentOffers.REST_ON_FURNITURE, SustainmentOffers.SLEEP_IN_BED, LootOffersClass.SEARCH_ACTION_ID, LooseItemPickupOffersClass.ACTION_ID, CraftingOffersClass.ACTION_ID]

func _on_simple_contextual_action_requested(target_id: String, action_id: StringName) -> void:
    if action_id == LootOffersClass.SEARCH_ACTION_ID:
        _simple_turns.search_loot_container(target_id); return
    if action_id == LooseItemPickupOffersClass.ACTION_ID:
        _simple_turns.pickup_loose_item(target_id); return
    if action_id == CraftingOffersClass.ACTION_ID:
        _request_target_crafting(WorldBootstrapClass.PLAYER_ID, target_id, action_id); return
    run_simple_contextual_action(WorldBootstrapClass.PLAYER_ID, target_id, action_id)

func run_simple_contextual_action(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    return _run_simple_contextual_action(actor_id, target_id, action_id)

func _run_simple_contextual_action(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    var actor := actor_id.strip_edges(); var target := target_id.strip_edges()
    if actor != WorldBootstrapClass.PLAYER_ID or target.is_empty() or not _world.has_entity(target) or _simple_turns == null or not _simple_turns.has_control(): return {"success": false, "reason": "context_target_unavailable"}
    if not _interaction_reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD): return {"success": false, "reason": "context_target_out_of_reach"}
    var entity := _world.entity(target)
    if entity == null: return {"success": false, "reason": "context_target_missing"}
    var elapsed := survival_ticks_per_turn()
    var valid := false
    if action_id == WorldActions.DOOR_OPEN:
        valid = _world_interaction_catalog.is_door(entity.semantic_type) and not _world_interaction_state.is_locked(target) and _world_interaction_state.board_count(target) == 0 and not _world_interaction_state.is_broken(target)
    elif action_id == WorldActions.DOOR_CLOSE:
        valid = _world_interaction_catalog.is_door(entity.semantic_type) and not _world_interaction_state.is_broken(target)
    elif action_id in [WorldActions.WINDOW_OPEN, WorldActions.WINDOW_CLOSE]:
        valid = _world_interaction_catalog.is_window(entity.semantic_type) and not _world_interaction_state.is_locked(target) and _world_interaction_state.board_count(target) == 0 and not _world_interaction_state.is_broken(target)
    elif action_id == SustainmentOffers.DRINK_FROM_FIXTURE:
        valid = _potable_target_available(actor, target); elapsed = 10
    elif action_id == SustainmentOffers.REST_ON_FURNITURE:
        valid = not String(_rest_target_surface(actor, target)).is_empty(); elapsed = _world_time_profile.ticks_per_hour()
    elif action_id == SustainmentOffers.SLEEP_IN_BED:
        valid = _rest_target_surface(actor, target) == &"bed"; elapsed = _world_time_profile.ticks_per_hour() * 8
    if not valid: return {"success": false, "reason": "context_action_unavailable"}
    if not _simple_turns._begin_direct_action(action_id): return {"success": false, "reason": "player_unavailable"}
    var committed := false
    if action_id == WorldActions.DOOR_OPEN: committed = _door_transition.open_manually(actor, target)
    elif action_id == WorldActions.DOOR_CLOSE: committed = _door_transition.close_manually(actor, target)
    elif action_id == WorldActions.WINDOW_OPEN: committed = _world_interaction_state.set_window_open(target, true, &"simple_window_open")
    elif action_id == WorldActions.WINDOW_CLOSE: committed = _world_interaction_state.set_window_open(target, false, &"simple_window_close")
    elif action_id == SustainmentOffers.DRINK_FROM_FIXTURE: committed = _condition_service.change_condition(actor, ConditionStateClass.HYDRATION, 28, &"potable_water_drunk")
    elif action_id == SustainmentOffers.REST_ON_FURNITURE:
        committed = _condition_service.change_condition(actor, ConditionStateClass.REST, 16, &"rested") and _condition_service.relieve_fatigue(actor, 35, &"rested")
        if committed: _apply_simple_surface_comfort(actor, _rest_target_surface(actor, target), false)
    elif action_id == SustainmentOffers.SLEEP_IN_BED:
        committed = _condition_service.change_condition(actor, ConditionStateClass.REST, 72, &"slept") and _condition_service.relieve_fatigue(actor, 100, &"slept")
        if committed: _apply_simple_surface_comfort(actor, &"bed", true)
    if not committed: return _simple_turns._reject_direct_action(action_id, "context_mutation_failed")
    _simple_elapsed_override_ticks = elapsed
    var result := _simple_turns._complete_direct_action(action_id, "")
    result["elapsed_ticks"] = elapsed; result["target_id"] = target; result["action_id"] = action_id
    return result

func run_simple_inventory_consumption(item_id: String) -> Dictionary:
    var item := item_id.strip_edges()
    if item.is_empty() or _simple_turns == null or not _simple_turns.has_control() or _sustainment_actions == null: return {"success": false, "reason": "item_action_unavailable"}
    var offer: Dictionary = _sustainment_actions.consumption_offer(WorldBootstrapClass.PLAYER_ID, item)
    if not bool(offer.get("available", false)) or not _world.has_entity(item): return {"success": false, "reason": String(offer.get("reason", "item_not_consumable"))}
    var entity := _world.entity(item); var profile := _sustainment_profiles.profile(entity.semantic_type) if entity != null else {}
    if entity == null or profile.is_empty(): return {"success": false, "reason": "item_profile_missing"}
    var assignment: Dictionary = _hand_state.assignment_for_item(item)
    var source_container := _inventory_state.container_of(item)
    if not _simple_turns._begin_direct_action(StringName("condition.%s" % String(profile.get("action_kind", "consume")))): return {"success": false, "reason": "player_unavailable"}
    if not assignment.is_empty():
        if String(assignment.get("actor_id", "")) != WorldBootstrapClass.PLAYER_ID or not _hand_mutations.clear_slot(WorldBootstrapClass.PLAYER_ID, int(assignment.get("slot", -1))): return _simple_turns._reject_direct_action(&"condition.consume", "item_release_failed")
    elif source_container.is_empty() or not _inventory_mutations.clear_container(item): return _simple_turns._reject_direct_action(&"condition.consume", "item_release_failed")
    if _freshness_mutations.has_record(item): _freshness_mutations.remove_item(item)
    if not _world.remove_entity(item): return _simple_turns._reject_direct_action(&"condition.consume", "item_removal_failed")
    _condition_service.change_condition(WorldBootstrapClass.PLAYER_ID, ConditionStateClass.SATIETY, int(profile.get("satiety_gain", 0)), &"food_consumed")
    _condition_service.change_condition(WorldBootstrapClass.PLAYER_ID, ConditionStateClass.HYDRATION, int(profile.get("hydration_gain", 0)), &"drink_consumed")
    _condition_service.change_condition(WorldBootstrapClass.PLAYER_ID, ConditionStateClass.ENGAGEMENT, int(profile.get("engagement_gain", 0)), &"meal_enjoyed")
    var elapsed := maxi(1, int(profile.get("duration_ticks", survival_ticks_per_turn())))
    _simple_elapsed_override_ticks = elapsed
    var intent := StringName("condition.%s" % String(profile.get("action_kind", "consume")))
    var result := _simple_turns._complete_direct_action(intent, "")
    result["elapsed_ticks"] = elapsed; result["item_id"] = item
    return result

func _apply_simple_surface_comfort(actor_id: String, surface: StringName, full_sleep: bool) -> void:
    if surface == &"bed": _condition_service.change_condition(actor_id, ConditionStateClass.COMFORT, 15 if full_sleep else 6, &"comfortable_rest")
    elif surface == &"sofa": _condition_service.change_condition(actor_id, ConditionStateClass.COMFORT, -2 if full_sleep else 5, &"sofa_rest")
    elif surface == &"chair": _condition_service.change_condition(actor_id, ConditionStateClass.COMFORT, -6 if full_sleep else 3, &"chair_rest")
    else: _condition_service.change_condition(actor_id, ConditionStateClass.COMFORT, -10 if full_sleep else -4, &"rough_rest")

func _on_simple_loot_take(container_id: String, item_id: String) -> void:
    if _simple_turns != null: _simple_turns.take_loot_item(container_id, item_id)
func _on_simple_loot_store(container_id: String, item_id: String) -> void:
    if _simple_turns != null: _simple_turns.store_loot_item(container_id, item_id)

func _hydrate_procedural_local_infected() -> bool:
    var player: WorldPlacement = _world.placement(WorldBootstrapClass.PLAYER_ID); var global_plan: GeneratedGlobalWorldPlan = WorldBootstrapClass.global_plan()
    if player == null or global_plan == null or not global_plan.is_generated(): return false
    var population_plan := {"ok": true, "settlements": global_plan.population_settlements.duplicate(true), "resident_population": global_plan.resident_population, "infected_population": global_plan.infected_population, "survivor_population": global_plan.survivor_population, "local_area_manifest": global_plan.local_area_manifest.duplicate(true)}
    var records: Array[Dictionary] = ResidentProjectionClass.new().infected_near(population_plan, "", player.anchor)
    for record: Dictionary in records:
        var actor_id := String(record.get("resident_id", "")).strip_edges(); var home_cell: Vector2i = record.get("home_cell", INVALID_CELL)
        if actor_id.is_empty() or home_cell == INVALID_CELL or not _spatial_query.has_terrain(home_cell): continue
        if _world.has_entity(actor_id):
            var existing := _world.placement(actor_id)
            if existing != null and not _simple_infected_ids.has(actor_id):
                if not _ensure_simple_infected_state(actor_id): return false
                _simple_infected_ids.append(actor_id)
            continue
        var spawn_cell := _clear_actor_cell_near_home(home_cell)
        if spawn_cell == INVALID_CELL: continue
        if _world.create_entity(&"actor.survivor", actor_id) != actor_id: continue
        if not _world.set_placement(actor_id, Layers.Channel.ACTOR, spawn_cell, Facing.Value.SOUTH, Footprint.single_cell()): _world.remove_entity(actor_id); continue
        if not _ensure_simple_infected_state(actor_id): _world.remove_entity(actor_id); return false
        _simple_infected_ids.append(actor_id)
    _simple_infected_ids.sort(); return not _simple_infected_ids.is_empty()
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
                var cell := origin + Vector2i(x, y)
                if _spatial_query.has_terrain(cell) and _spatial_query.query_cell(cell, "", true).is_clear(): return cell
    return INVALID_CELL

func _on_turn_intent(intent: StringName) -> void:
    if _simple_turns != null and (TurnIntents.is_movement(intent) or intent == TurnIntents.COMBAT_FORWARD): _simple_turns.submit_intent(intent)
func _on_simple_turn_completed(_turn_number: int, _active_actor_count: int) -> void:
    var player := _world.placement(WorldBootstrapClass.PLAYER_ID)
    if player == null: return
    var streaming := WorldBootstrapClass.streaming_coordinator()
    if streaming != null: streaming.update_focus(player.anchor)
    if _perception != null: _perception.recompute(&"simple_turn")
    var elapsed := _simple_elapsed_override_ticks if _simple_elapsed_override_ticks > 0 else survival_ticks_per_turn()
    _simple_elapsed_override_ticks = -1
    _advance_simple_survival(elapsed)
    if _hud != null: _hud.refresh()
    _flush_pending_visual_state()
func _advance_simple_survival(elapsed_ticks: int) -> void:
    if _condition_service == null or not _condition_service.has_actor(WorldBootstrapClass.PLAYER_ID): return
    if not _condition_service.advance_elapsed_ticks(WorldBootstrapClass.PLAYER_ID, maxi(1, elapsed_ticks), &"simple_turn_elapsed"): return
    var intent := _simple_turns.last_completed_intent() if _simple_turns != null else &""
    if intent == TurnIntents.RUN_FORWARD: _condition_service.apply_exertion(WorldBootstrapClass.PLAYER_ID, MovementExertionRules.RUN_BASE_FATIGUE_COST, &"movement_exertion")
    _apply_simple_fear_pressure()

func _apply_simple_fear_pressure() -> void:
    if _condition_service == null or _perception == null: return
    var player := _world.placement(WorldBootstrapClass.PLAYER_ID)
    if player == null: return
    var current_visible: Dictionary = {}; var worsened: Array[Dictionary] = []
    for actor_id: String in _simple_infected_ids:
        var placement := _world.placement(actor_id)
        if placement == null or not _health_state.has_actor(actor_id) or _health_state.current_hp(actor_id) <= 0: continue
        var distance := _chebyshev(player.anchor, placement.anchor)
        if distance > SimpleTurnController.ACTIVE_RADIUS or not _perception.is_visible(placement.anchor): continue
        current_visible[actor_id] = true
        var band := PerceptionFearRules._band_for_distance(distance); var previous := int(_simple_fear_bands.get(actor_id, 0))
        if band > previous:
            worsened.append({"actor_id": actor_id, "pressure": int(PerceptionFearRules.BAND_PRESSURE.get(band, 0)) - int(PerceptionFearRules.BAND_PRESSURE.get(previous, 0))}); _simple_fear_bands[actor_id] = band
    var now := survival_elapsed_tick()
    if current_visible.is_empty():
        if not _simple_visible_threats.is_empty() and _simple_threat_free_since_tick < 0: _simple_threat_free_since_tick = now
        if _simple_threat_free_since_tick >= 0 and now - _simple_threat_free_since_tick >= _world_time_profile.ticks_per_minute() * PerceptionFearRules.ENCOUNTER_RESET_MINUTES: _simple_fear_bands.clear(); _simple_threat_free_since_tick = -1
    else: _simple_threat_free_since_tick = -1
    _simple_visible_threats = current_visible
    worsened.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var pa := int(a.get("pressure", 0)); var pb := int(b.get("pressure", 0)); return pa > pb if pa != pb else String(a.get("actor_id", "")) < String(b.get("actor_id", "")))
    var pressure := 0
    for index in range(worsened.size()):
        var weight_bp := PerceptionFearRules.DIMINISHING_BP[mini(index, PerceptionFearRules.DIMINISHING_BP.size() - 1)]; pressure += int(ceili(float(int(worsened[index].get("pressure", 0)) * weight_bp) / 10000.0))
    var current_hp := _health_state.current_hp(WorldBootstrapClass.PLAYER_ID)
    if _last_player_hp >= 0 and current_hp < _last_player_hp: pressure += InjuryFearRules.pressure_for_damage(_last_player_hp - current_hp)
    _last_player_hp = current_hp; pressure = mini(ActorFearPressureService.MAX_PRESSURE_PER_TICK, maxi(0, pressure))
    if pressure > 0: _condition_service.change_condition(WorldBootstrapClass.PLAYER_ID, ConditionStateClass.CALM, -pressure, &"simple_turn_fear_pressure")
static func _chebyshev(a: Vector2i, b: Vector2i) -> int:
    var delta := a - b; return maxi(absi(delta.x), absi(delta.y))
func _on_simple_actor_died(actor_id: String, _corpse_id: String) -> void:
    if actor_id == WorldBootstrapClass.PLAYER_ID and _shell != null: _shell.call_deferred("open_death")
func simple_turn_controller() -> SimpleTurnController: return _simple_turns
func simple_infected_actor_ids() -> Array[String]: return _simple_infected_ids.duplicate()
func combat_health_state() -> ActorHealthState: return _health_state
func combat_corpse_state() -> CorpseState: return _simple_corpse_state
func combat_firearm_state() -> FirearmState: return _simple_firearm_state
