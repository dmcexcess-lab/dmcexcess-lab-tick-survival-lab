extends "res://scripts/app/VehicleSimpleGameMain.gd"
class_name ProductionGameMain

const ProductionStore = preload("res://scripts/persistence/DurableSessionStore.gd")
const ResidentProjection = preload("res://scripts/simulation/population/PopulationResidentProjection.gd")

var _production_infected_records: Array[Dictionary] = []
var _production_active_ids: Array[String] = []
var _production_boundary_refreshes: int = 0
var _production_last_active_regions: Array[Vector2i] = []

func _boot_production_world() -> bool:
    if not super._boot_production_world():
        return false
    if _world_time == null or _weather == null or _ambient_daylight == null or _condition_service == null:
        return false

    var start_tick := maxi(0, survival_elapsed_tick())
    if not _world_time.configure_manual_clock(start_tick):
        return false
    if not _weather.configure_manual_clock(start_tick):
        return false
    if _hud == null or not _hud.configure_environment(_world_time, _weather):
        return false

    if not _cache_infected_records():
        return false
    if not _simple_turns.set_before_local_infected_turns(Callable(self, "_refresh_simulation_boundary")):
        return false
    return _refresh_simulation_boundary()

func _on_simple_turn_completed(turn_number: int, active_actor_count: int) -> void:
    super._on_simple_turn_completed(turn_number, active_actor_count)

    var target_tick := survival_elapsed_tick()
    if target_tick >= 0 and _world_time != null and _weather != null:
        if not _world_time.advance_to_tick(target_tick):
            push_error("ProductionGameMain: world time failed to advance to %d" % target_tick)
            return
        if not _weather.advance_to_tick(target_tick):
            push_error("ProductionGameMain: weather failed to advance to %d" % target_tick)
            return
        if _hud != null:
            _hud.refresh()
        _flush_pending_visual_state()

    _refresh_simulation_boundary()

func _cache_infected_records() -> bool:
    var global_plan: GeneratedGlobalWorldPlan = WorldBootstrapClass.global_plan()
    if global_plan == null or not global_plan.is_generated():
        return false
    var population_plan := {
        "ok": true,
        "settlements": global_plan.population_settlements.duplicate(true),
        "resident_population": global_plan.resident_population,
        "infected_population": global_plan.infected_population,
        "survivor_population": global_plan.survivor_population,
        "local_area_manifest": global_plan.local_area_manifest.duplicate(true),
    }
    _production_infected_records = ResidentProjection.new().infected_records(population_plan)
    return true

func _refresh_simulation_boundary() -> bool:
    if _simple_turns == null:
        return false
    var player: WorldPlacement = _world.placement(WorldBootstrapClass.PLAYER_ID)
    var streaming: WorldStreamingCoordinator = WorldBootstrapClass.streaming_coordinator()
    if player == null or streaming == null or not streaming.is_ready():
        return false

    var focus_result: Dictionary = streaming.update_focus(player.anchor)
    if not bool(focus_result.get("ok", false)):
        return false

    var active_regions: Array[Vector2i] = streaming.active_region_coords()
    var boundary_changed := active_regions != _production_last_active_regions
    if boundary_changed:
        _production_last_active_regions = active_regions.duplicate()
        _production_boundary_refreshes += 1

    var active: Dictionary = {}
    for actor_id: String in _simple_infected_ids:
        var placement: WorldPlacement = _world.placement(actor_id)
        if placement != null and streaming.is_cell_active(placement.anchor):
            active[actor_id] = true

    if boundary_changed:
        for record: Dictionary in _production_infected_records:
            var actor_id := String(record.get("resident_id", "")).strip_edges()
            var home_cell: Vector2i = record.get("home_cell", INVALID_CELL)
            if actor_id.is_empty() or home_cell == INVALID_CELL or not streaming.is_cell_active(home_cell):
                continue
            if _world.has_entity(actor_id):
                var existing: WorldPlacement = _world.placement(actor_id)
                if existing != null and not _simple_infected_ids.has(actor_id):
                    if not _ensure_simple_infected_state(actor_id):
                        return false
                    _simple_infected_ids.append(actor_id)
                if existing != null and streaming.is_cell_active(existing.anchor):
                    active[actor_id] = true
                continue
            if not _spatial_query.has_terrain(home_cell):
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
            active[actor_id] = true
        _simple_infected_ids.sort()

    _production_active_ids.clear()
    for actor_id: String in active.keys():
        _production_active_ids.append(actor_id)
    _production_active_ids.sort()
    _simple_turns.set_infected_actor_ids(_production_active_ids)
    return true

func active_infected_ids() -> Array[String]:
    return _production_active_ids.duplicate()

func known_infected_ids() -> Array[String]:
    return _simple_infected_ids.duplicate()

func boundary_refresh_count() -> int:
    return _production_boundary_refreshes

func cell_active(cell: Vector2i) -> bool:
    var streaming: WorldStreamingCoordinator = WorldBootstrapClass.streaming_coordinator()
    return streaming != null and streaming.is_cell_active(cell)

# Compatibility method names for current tests/consumers while the migration class
# names disappear from production.
func slice12_active_infected_ids() -> Array[String]:
    return active_infected_ids()

func slice12_known_infected_ids() -> Array[String]:
    return known_infected_ids()

func slice12_boundary_refresh_count() -> int:
    return boundary_refresh_count()

func slice12_cell_active(cell: Vector2i) -> bool:
    return cell_active(cell)

func _build_durable_session() -> Dictionary:
    _sync_refrigeration_clocks()
    var session := super._build_durable_session()
    if session.is_empty() or _world_time == null or not _world_time.is_ready():
        return {}
    var owners_value: Variant = session.get("owners", {})
    if typeof(owners_value) != TYPE_DICTIONARY:
        return {}
    var owners: Dictionary = Dictionary(owners_value).duplicate(true)
    owners["world_time"] = _world_time.snapshot()
    owners["refrigeration"] = _refrigeration_snapshot()
    if Dictionary(owners["world_time"]).is_empty() or Dictionary(owners["refrigeration"]).is_empty():
        return {}
    session["schema_version"] = ProductionStore.SESSION_SCHEMA_VERSION
    session["owners"] = owners
    return session

func _restore_durable_session(session: Dictionary) -> bool:
    var validation: Dictionary = _session_store.validate_session(session)
    if not bool(validation.get("ok", false)) or int(session.get("world_seed", 0)) != WorldBootstrapClass.active_seed():
        return false
    var owners_value: Variant = session.get("owners", {})
    if typeof(owners_value) != TYPE_DICTIONARY:
        return false
    var owners: Dictionary = owners_value
    var registry: MaterializationRegistry = WorldBootstrapClass.materialization_registry()
    if registry == null:
        return false

    if not registry.load_snapshot(owners["materialization_registry"]): return false
    if not _world.load_snapshot(owners["world"]): return false
    if not _collision_overrides.load_snapshot(owners["collision_overrides"]): return false
    if not _door_state.load_snapshot(owners["doors"]): return false
    if not _locomotion_state.load_snapshot(owners["locomotion"]): return false
    if not _hand_state.load_snapshot(owners["hands"]): return false
    if not _inventory_state.load_snapshot(owners["inventory"]): return false
    if not _health_state.load_snapshot(owners["health"]): return false
    if not _skill_state.load_snapshot(owners["skills"]): return false
    if not _freshness_state.load_snapshot(owners["freshness"]): return false
    if not _carry_state.load_snapshot(owners["carry"]): return false
    if not _loot_state.load_snapshot(owners["loot"]): return false
    if not _forage_state.load_snapshot(owners["forage"]): return false
    if not _condition_service.restore_state(owners["conditions"]): return false
    if not _utilities.restore_snapshot(owners["utilities"]): return false
    if not _power_network.restore_snapshot(owners["power_network"]): return false
    if not _flashlight_state.load_snapshot(owners["flashlight"]): return false
    if not _portable_generators.restore_snapshot(owners["portable_generators"]): return false
    if not _vehicle_state.load_snapshot(owners["vehicles"]): return false
    if not _world_interaction_state.load_snapshot(owners["world_interactions"]): return false
    if not _firearm_state.load_snapshot(owners["firearms"]): return false
    if not _corpse_state.load_snapshot(owners["corpses"]): return false
    if not _infected_state.load_snapshot(owners["infected"]): return false

    var restored_time_tick := _restored_condition_anchor_tick()
    if owners.has("world_time") and typeof(owners["world_time"]) == TYPE_DICTIONARY:
        if not _world_time.load_snapshot(owners["world_time"]):
            return false
        restored_time_tick = _world_time.world_tick()
    elif not _world_time.configure_manual_clock(restored_time_tick):
        return false
    if not _condition_service.configure_manual_clock(restored_time_tick):
        return false

    if not _weather.configure_manual_clock(_world_time.world_tick()):
        return false
    if not _weather.load_snapshot(owners["weather"]):
        return false
    if not _weather.advance_to_tick(_world_time.world_tick()):
        return false

    if owners.has("refrigeration") and typeof(owners["refrigeration"]) == TYPE_DICTIONARY:
        if not _restore_refrigeration(owners["refrigeration"]):
            return false
    elif not _migrate_legacy_refrigeration():
        return false

    return _rebuild_runtime_state()

func _restored_condition_anchor_tick() -> int:
    if _condition_state == null or not _condition_state.has_actor(WorldBootstrapClass.PLAYER_ID):
        return 0
    var record: Dictionary = _condition_state.record(WorldBootstrapClass.PLAYER_ID)
    return maxi(0, maxi(int(record.get("anchor_tick", 0)), int(record.get("fatigue_anchor_tick", 0))))

func _refrigeration_snapshot() -> Dictionary:
    var providers: Array[Dictionary] = []
    for refrigerator_id: String in _sorted_refrigerator_ids():
        if not _refrigeration_providers.has(refrigerator_id):
            continue
        var provider: UtilityRefrigerationEnvironmentProvider = _refrigeration_providers[refrigerator_id]
        var snapshot: Dictionary = provider.snapshot()
        if snapshot.is_empty():
            return {}
        providers.append(snapshot)
    return {"schema_version": 1, "providers": providers}

func _restore_refrigeration(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != 1:
        return false
    var values: Variant = data.get("providers", [])
    if typeof(values) != TYPE_ARRAY:
        return false
    var restored: Dictionary = {}
    for raw: Variant in values:
        if typeof(raw) != TYPE_DICTIONARY:
            return false
        var row: Dictionary = raw
        var refrigerator_id := String(row.get("appliance_id", "")).strip_edges()
        if refrigerator_id.is_empty() or restored.has(refrigerator_id) or not _refrigeration_providers.has(refrigerator_id):
            return false
        var provider: UtilityRefrigerationEnvironmentProvider = _refrigeration_providers[refrigerator_id]
        if not provider.restore_snapshot(row):
            return false
        restored[refrigerator_id] = true
    for refrigerator_id: String in _sorted_refrigerator_ids():
        if not restored.has(refrigerator_id):
            return false
    return true

func _migrate_legacy_refrigeration() -> bool:
    var restored_tick := _world_time.world_tick()
    for refrigerator_id: String in _sorted_refrigerator_ids():
        if not _refrigeration_providers.has(refrigerator_id):
            continue
        var provider: UtilityRefrigerationEnvironmentProvider = _refrigeration_providers[refrigerator_id]
        var context_id := provider.context_id()
        var minimum_exposure := 0
        for item_id: String in _freshness_state.item_ids():
            var record: ItemFreshnessRecord = _freshness_state.record(item_id)
            if record != null and record.exposure_context_id == context_id:
                minimum_exposure = maxi(minimum_exposure, record.exposure_anchor_ticks)
        var migrated := provider.snapshot()
        if migrated.is_empty():
            return false
        migrated["anchor_world_tick"] = restored_tick
        migrated["saved_exposure_milliticks"] = minimum_exposure * 1000
        if not provider.restore_snapshot(migrated):
            return false
    return true

func _rebuild_runtime_state() -> bool:
    if _perception_memory != null:
        for observer_id: String in _perception_memory.observer_ids():
            _perception_memory.clear_observer(observer_id)

    _simple_infected_ids.clear()
    for record: Dictionary in _production_infected_records:
        var actor_id := String(record.get("resident_id", "")).strip_edges()
        if actor_id.is_empty() or not _world.has_entity(actor_id) or not _health_state.has_actor(actor_id):
            continue
        if not _simple_infected_ids.has(actor_id):
            _simple_infected_ids.append(actor_id)
    if _infected_state != null:
        for actor_id: String in _infected_state.actor_ids():
            if _world.has_entity(actor_id) and _health_state.has_actor(actor_id) and not _simple_infected_ids.has(actor_id):
                _simple_infected_ids.append(actor_id)
    _simple_infected_ids.sort()

    var player: WorldPlacement = _world.placement(WorldBootstrapClass.PLAYER_ID)
    var streaming: WorldStreamingCoordinator = WorldBootstrapClass.streaming_coordinator()
    if player == null or streaming == null or not bool(streaming.update_focus(player.anchor).get("ok", false)):
        return false

    _production_last_active_regions.clear()
    _production_active_ids.clear()
    var empty_active_ids: Array[String] = []
    _simple_turns.set_infected_actor_ids(empty_active_ids)
    if not _refresh_simulation_boundary():
        return false

    if _perception != null:
        _perception.recompute(&"durable_restore_rebuild")
    if not _sync_vehicle_lighting_emitters():
        return false
    _sync_refrigeration_clocks()
    if _hud != null:
        _hud.configure_environment(_world_time, _weather)
        _hud.refresh()
    _flush_pending_visual_state()
    return true

func canonical_world_time_snapshot() -> Dictionary:
    return {} if _world_time == null else _world_time.current_time()

func canonical_daylight_snapshot() -> Dictionary:
    return {} if _ambient_daylight == null else _ambient_daylight.current_snapshot()

func canonical_weather_snapshot() -> Dictionary:
    return {} if _weather == null else _weather.debug_snapshot()
