extends GameMain
class_name TurnBasedGameMain

const SimpleTurnControllerClass = preload("res://scripts/player/SimpleTurnController.gd")
const ResidentProjectionClass = preload("res://scripts/simulation/population/PopulationResidentProjection.gd")
const TurnIntents = preload("res://scripts/input/PlayerActionIntent.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const FirearmProfilesClass = preload("res://scripts/simulation/combat/FirearmProfileCatalog.gd")
const FirearmStateClass = preload("res://scripts/simulation/combat/FirearmState.gd")
const CorpseStateClass = preload("res://scripts/simulation/combat/CorpseState.gd")
const DeathTransitionsClass = preload("res://scripts/simulation/combat/ActorDeathTransitionService.gd")

const RESIDENT_SPAWN_SEARCH_RADIUS := 8
const INVALID_CELL := Vector2i(-999999, -999999)

var _simple_turns: SimpleTurnController = null
var _simple_infected_ids: Array[String] = []
var _simple_firearm_profiles: FirearmProfileCatalog = null
var _simple_firearm_state: FirearmState = null
var _simple_corpse_state: CorpseState = null
var _simple_death_transitions: ActorDeathTransitionService = null

func _boot_production_world() -> bool:
    if not super._boot_production_world():
        return false
    if not _boot_simple_combat_state():
        return false
    if not _hydrate_procedural_local_infected():
        return false
    _simple_turns = SimpleTurnControllerClass.new(
        _world,
        _collision_catalog,
        _collision_overrides,
        WorldBootstrapClass.PLAYER_ID,
        _health_state,
        _hand_state,
        _inventory_state,
        _physical_catalog,
        _simple_firearm_profiles,
        _simple_firearm_state,
        _inventory_mutations,
        _hand_mutations,
        _carry_acquisition,
        _loot_state
    )
    _simple_turns.set_infected_actor_ids(_simple_infected_ids)
    add_child(_simple_turns)
    if not _simple_turns.is_ready():
        return false
    _simple_turns.action_resolved.connect(Callable(_hud, "present_action_result"))
    _simple_turns.action_busy_changed.connect(_on_player_action_busy_changed)
    _simple_turns.turn_completed.connect(_on_simple_turn_completed)
    if not _wire_simple_inventory_route():
        return false

    var legacy_submit := Callable(_controller, "submit_intent")
    if _keyboard.action_intent.is_connected(legacy_submit):
        _keyboard.action_intent.disconnect(legacy_submit)
    if _controls.action_intent.is_connected(legacy_submit):
        _controls.action_intent.disconnect(legacy_submit)
    _keyboard.action_intent.connect(_on_turn_intent)
    _controls.action_intent.connect(_on_turn_intent)
    return true

func _wire_simple_inventory_route() -> bool:
    if _simple_turns == null or _loot_panel == null or _loot_inspection == null or _shell == null:
        return false

    if _loot_controller != null:
        var legacy_pointer := Callable(_loot_controller, "submit_world_cell")
        if _door_pointer.world_cell_primary.is_connected(legacy_pointer):
            _door_pointer.world_cell_primary.disconnect(legacy_pointer)
        var legacy_take := Callable(_loot_controller, "request_take")
        if _loot_panel.take_requested.is_connected(legacy_take):
            _loot_panel.take_requested.disconnect(legacy_take)
        var legacy_store := Callable(_loot_controller, "request_store")
        if _loot_panel.store_requested.is_connected(legacy_store):
            _loot_panel.store_requested.disconnect(legacy_store)
        var legacy_hud := Callable(_hud, "present_action_result")
        if _loot_controller.action_resolved.is_connected(legacy_hud):
            _loot_controller.action_resolved.disconnect(legacy_hud)
        var legacy_panel_result := Callable(_loot_panel, "present_action_result")
        if _loot_controller.action_resolved.is_connected(legacy_panel_result):
            _loot_controller.action_resolved.disconnect(legacy_panel_result)
        var legacy_open := Callable(_loot_panel, "open_container")
        if _loot_controller.container_opened.is_connected(legacy_open):
            _loot_controller.container_opened.disconnect(legacy_open)
        var legacy_refresh := Callable(_loot_panel, "refresh")
        if _loot_controller.container_changed.is_connected(legacy_refresh):
            _loot_controller.container_changed.disconnect(legacy_refresh)

    _door_pointer.world_cell_primary.connect(_on_simple_world_cell)
    _loot_panel.take_requested.connect(_on_simple_loot_take)
    _loot_panel.store_requested.connect(_on_simple_loot_store)
    _simple_turns.action_resolved.connect(Callable(_loot_panel, "present_action_result"))
    _simple_turns.loot_container_opened.connect(Callable(_loot_panel, "open_container"))
    _simple_turns.loot_container_changed.connect(Callable(_loot_panel, "refresh"))
    return _shell.configure_simple_inventory_turns(_simple_turns)

func _on_simple_world_cell(cell: Vector2i) -> void:
    if _simple_turns == null or not _simple_turns.has_control():
        return
    var containers := _loot_inspection.searchable_container_ids_at(cell)
    if containers.size() == 1:
        _simple_turns.search_loot_container(containers[0])
        return
    if not containers.is_empty():
        return
    var loose_items: Array[String] = []
    for entity_id: String in _world.entities_at(cell, Layers.Channel.LOOSE_ITEM):
        var entity := _world.entity(entity_id)
        if entity != null and String(entity.semantic_type).begins_with("item."):
            loose_items.append(entity_id)
    loose_items.sort()
    if loose_items.size() == 1:
        _simple_turns.pickup_loose_item(loose_items[0])

func _on_simple_loot_take(container_id: String, item_id: String) -> void:
    if _simple_turns != null:
        _simple_turns.take_loot_item(container_id, item_id)

func _on_simple_loot_store(container_id: String, item_id: String) -> void:
    if _simple_turns != null:
        _simple_turns.store_loot_item(container_id, item_id)

func _boot_simple_combat_state() -> bool:
    if _world == null or _health_state == null or _hand_state == null or _hand_mutations == null \
        or _inventory_state == null or _inventory_mutations == null or _physical_catalog == null \
        or _collision_catalog == null:
        return false
    _simple_firearm_profiles = FirearmProfilesClass.new()
    if not _simple_firearm_profiles.register_physical_profiles(_physical_catalog):
        return false
    _simple_firearm_state = FirearmStateClass.new(
        _world,
        _inventory_state,
        _inventory_mutations,
        _simple_firearm_profiles
    )
    if not _simple_firearm_state.is_ready():
        return false
    _simple_corpse_state = CorpseStateClass.new()
    if not _collision_catalog.register(DeathTransitionsClass.CORPSE_SEMANTIC, false):
        return false
    _simple_death_transitions = DeathTransitionsClass.new(
        _world,
        _health_state,
        _hand_state,
        _hand_mutations,
        _inventory_state,
        _inventory_mutations,
        _simple_corpse_state
    )
    if not _simple_death_transitions.is_ready():
        return false
    _simple_death_transitions.actor_died.connect(_on_simple_actor_died)
    return true

func _hydrate_procedural_local_infected() -> bool:
    var player: WorldPlacement = _world.placement(WorldBootstrapClass.PLAYER_ID)
    var global_plan: GeneratedGlobalWorldPlan = WorldBootstrapClass.global_plan()
    if player == null or global_plan == null or not global_plan.is_generated():
        return false

    var population_plan := {
        "ok": true,
        "settlements": global_plan.population_settlements.duplicate(true),
        "resident_population": global_plan.resident_population,
        "infected_population": global_plan.infected_population,
        "survivor_population": global_plan.survivor_population,
        "local_area_manifest": global_plan.local_area_manifest.duplicate(true),
    }
    var records: Array[Dictionary] = ResidentProjectionClass.new().infected_near(population_plan, "", player.anchor)
    for record: Dictionary in records:
        var actor_id := String(record.get("resident_id", "")).strip_edges()
        var home_cell: Vector2i = record.get("home_cell", INVALID_CELL)
        if actor_id.is_empty() or home_cell == INVALID_CELL or not _spatial_query.has_terrain(home_cell):
            continue
        if _world.has_entity(actor_id):
            var existing := _world.placement(actor_id)
            if existing != null and not _simple_infected_ids.has(actor_id):
                if not _ensure_simple_infected_state(actor_id):
                    return false
                _simple_infected_ids.append(actor_id)
            continue
        var spawn_cell := _clear_actor_cell_near_home(home_cell)
        if spawn_cell == INVALID_CELL:
            continue
        if _world.create_entity(&"actor.survivor", actor_id) != actor_id:
            continue
        if not _world.set_placement(actor_id, Layers.Channel.ACTOR, spawn_cell, Facing.Value.SOUTH, Footprint.single_cell()):
            _world.remove_entity(actor_id)
            continue
        if not _ensure_simple_infected_state(actor_id):
            _world.remove_entity(actor_id)
            return false
        _simple_infected_ids.append(actor_id)
    _simple_infected_ids.sort()
    return not _simple_infected_ids.is_empty()

func _ensure_simple_infected_state(actor_id: String) -> bool:
    if not _hand_state.has_actor(actor_id) and not _hand_mutations.enroll_actor(actor_id):
        return false
    if not _inventory_state.has_container(actor_id) and not _inventory_mutations.enroll_container(actor_id):
        return false
    if not _health_state.has_actor(actor_id) and not _health_state.enroll_actor(actor_id):
        return false
    return true

func _clear_actor_cell_near_home(origin: Vector2i) -> Vector2i:
    for radius in range(0, RESIDENT_SPAWN_SEARCH_RADIUS + 1):
        for y in range(-radius, radius + 1):
            for x in range(-radius, radius + 1):
                if radius > 0 and absi(x) != radius and absi(y) != radius:
                    continue
                var cell := origin + Vector2i(x, y)
                if _spatial_query.has_terrain(cell) and _spatial_query.query_cell(cell, "", true).is_clear():
                    return cell
    return INVALID_CELL

func _on_turn_intent(intent: StringName) -> void:
    if _simple_turns == null:
        return
    if TurnIntents.is_movement(intent) or intent == TurnIntents.COMBAT_FORWARD:
        _simple_turns.submit_intent(intent)

func _on_simple_turn_completed(_turn_number: int, _active_actor_count: int) -> void:
    var player := _world.placement(WorldBootstrapClass.PLAYER_ID)
    if player == null:
        return
    var streaming := WorldBootstrapClass.streaming_coordinator()
    if streaming != null:
        streaming.update_focus(player.anchor)
    if _perception != null:
        _perception.recompute(&"simple_turn")
    _flush_pending_visual_state()

func _on_simple_actor_died(actor_id: String, _corpse_id: String) -> void:
    if actor_id != WorldBootstrapClass.PLAYER_ID or _shell == null:
        return
    _shell.call_deferred("open_death")

func simple_turn_controller() -> SimpleTurnController:
    return _simple_turns

func simple_infected_actor_ids() -> Array[String]:
    return _simple_infected_ids.duplicate()

func combat_health_state() -> ActorHealthState:
    return _health_state

func combat_corpse_state() -> CorpseState:
    return _simple_corpse_state

func combat_firearm_state() -> FirearmState:
    return _simple_firearm_state
