extends Slice12GameMain
class_name Slice13GameMain

const Slice13Store = preload("res://scripts/persistence/DurableSessionStore.gd")

const RETIRED_RUNTIME_OWNER_KEYS: Array[String] = [
    "kernel",
    "perception_memory",
    "combat_runtime",
]

func _build_durable_session() -> Dictionary:
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
    var restored_time_tick := survival_elapsed_tick()
    if owners.has("world_time") and typeof(owners["world_time"]) == TYPE_DICTIONARY:
        if not _world_time.load_snapshot(owners["world_time"]):
            return false
        restored_time_tick = _world_time.world_tick()
    elif not _world_time.configure_manual_clock(maxi(0, restored_time_tick)):
        return false

    if not _weather.configure_manual_clock(_world_time.world_tick()):
        return false
    if not _weather.load_snapshot(owners["weather"]):
        return false
    if not _weather.advance_to_tick(_world_time.world_tick()):
        return false

    if not _rebuild_slice13_runtime_state():
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
