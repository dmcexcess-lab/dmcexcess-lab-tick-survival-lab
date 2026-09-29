extends Slice12GameMain
class_name Slice13GameMain

const Slice13Store = preload("res://scripts/persistence/DurableSessionStore.gd")

const RETIRED_RUNTIME_OWNER_KEYS: Array[String] = [
    "kernel",
    "perception_memory",
    "combat_runtime",
]

func _build_durable_session() -> Dictionary:
    _sync_refrigeration_clocks()
    var session := super._build_durable_session()
    if session.is_empty():
        return session
    var owners_value: Variant = session.get("owners", {})
    if typeof(owners_value) != TYPE_DICTIONARY:
        return {}
    var owners: Dictionary = Dictionary(owners_value).duplicate(true)
    for key: String in RETIRED_RUNTIME_OWNER_KEYS:
        owners.erase(key)
    if not owners.has("world_time") or typeof(owners["world_time"]) != TYPE_DICTIONARY:
        return {}
    owners["refrigeration"] = _slice13_refrigeration_snapshot()
    if Dictionary(owners["refrigeration"]).is_empty():
        return {}
    session["schema_version"] = Slice13Store.SESSION_SCHEMA_VERSION
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

    # Durable truth first. Runtime controllers/caches are intentionally not restored.
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

    # Canonical time is restored from schema 2 directly. Current schema 1 saves
    # migrate from the already-restored survival clock, as established in Slice 11.
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
        if not _restore_slice13_refrigeration(owners["refrigeration"]):
            return false
    elif not _migrate_legacy_refrigeration():
        return false

    if not _rebuild_slice13_runtime_state():
        return false
    return true

func _restored_condition_anchor_tick() -> int:
    if _condition_state == null or not _condition_state.has_actor(WorldBootstrapClass.PLAYER_ID):
        return 0
    var record: Dictionary = _condition_state.record(WorldBootstrapClass.PLAYER_ID)
    return maxi(0, maxi(int(record.get("anchor_tick", 0)), int(record.get("fatigue_anchor_tick", 0))))

func _slice13_refrigeration_snapshot() -> Dictionary:
    var providers: Array[Dictionary] = []
    for refrigerator_id: String in _sorted_refrigerator_ids():
        if not _refrigeration_providers.has(refrigerator_id):
            continue
        var provider: UtilityRefrigerationEnvironmentProvider = _refrigeration_providers[refrigerator_id]
        var snapshot: Dictionary = provider.snapshot()
        if snapshot.is_empty():
            return {}
        providers.append(snapshot)
    return {
        "schema_version": 1,
        "providers": providers,
    }

func _restore_slice13_refrigeration(data: Dictionary) -> bool:
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

func _rebuild_slice13_runtime_state() -> bool:
    # Perception memory, streaming membership and the local infected roster are
    # reconstructable runtime state, not durable truth.
    if _perception_memory != null:
        for observer_id: String in _perception_memory.observer_ids():
            _perception_memory.clear_observer(observer_id)

    _simple_infected_ids.clear()
    for record: Dictionary in _slice12_infected_records:
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

    _slice12_last_active_regions.clear()
    _slice12_active_ids.clear()
    var empty_active_ids: Array[String] = []
    _simple_turns.set_infected_actor_ids(empty_active_ids)
    if not _refresh_slice12_simulation_boundary():
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

func slice13_runtime_owner_keys() -> Array[String]:
    return RETIRED_RUNTIME_OWNER_KEYS.duplicate()
