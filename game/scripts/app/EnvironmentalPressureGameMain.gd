extends CombatGameMain
class_name EnvironmentalPressureGameMain

const OpeningPressureClass = preload("res://scripts/simulation/interaction/ActorOpeningPressureActionService.gd")
const DurableSessionStoreClass = preload("res://scripts/persistence/DurableSessionStore.gd")

const STARTUP_SCENE_PATH: String = "res://main.tscn"
const AUTOSAVE_MIN_MSEC: int = 10000

@onready var _resolution_indicator: WorldResolutionIndicator = $ResolutionIndicator
@onready var _session_controls: SessionControls = get_node_or_null("SessionControls") as SessionControls

var _opening_pressure: ActorOpeningPressureActionService = null
var _session_store: DurableSessionStore = null
var _continue_session: Dictionary = {}
var _session_boot_ok: bool = false
var _session_boot_error: String = ""
var _restoring_session: bool = false
var _autosave_queued: bool = false
var _last_save_msec: int = 0

func configure_session_paths(primary_path: String, backup_path: String, temp_path: String) -> bool:
    if is_inside_tree() or primary_path.is_empty() or backup_path.is_empty() or temp_path.is_empty():
        return false
    _session_store = DurableSessionStoreClass.new(primary_path, backup_path, temp_path)
    return true

func configure_continue_session(session: Dictionary) -> bool:
    if is_inside_tree() or session.is_empty():
        return false
    _ensure_session_store()
    var validation: Dictionary = _session_store.validate_session(session)
    if not bool(validation.get("ok", false)):
        return false
    var seed: int = int(session.get("world_seed", 0))
    if not configure_world_seed_override(seed):
        return false
    _continue_session = session.duplicate(true)
    return true

func session_boot_ok() -> bool:
    return _session_boot_ok

func session_boot_error() -> String:
    return _session_boot_error

func session_storage_status() -> Dictionary:
    _ensure_session_store()
    return _session_store.storage_status()

func durable_session_snapshot() -> Dictionary:
    return _build_durable_session()

func save_durable_session(reason: StringName = &"manual") -> Dictionary:
    if not _session_boot_ok or _restoring_session or not canonical_boot_ok():
        return {"ok": false, "reason": "session_not_ready", "persistent": false}
    _ensure_session_store()
    var session: Dictionary = _build_durable_session()
    if session.is_empty():
        _set_session_status("SAVE FAILED — STATE UNAVAILABLE")
        return {"ok": false, "reason": "snapshot_failed", "persistent": OS.is_userfs_persistent()}
    var result: Dictionary = _session_store.save(session)
    if bool(result.get("ok", false)):
        _last_save_msec = Time.get_ticks_msec()
        if bool(result.get("persistent", true)):
            _set_session_status("SAVED")
        else:
            _set_session_status("SAVED — BROWSER STORAGE NOT PERSISTENT")
    else:
        _set_session_status("SAVE FAILED — %s" % String(result.get("reason", "storage_error")).to_upper())
    result["checkpoint_reason"] = String(reason)
    return result

func _ready() -> void:
    _session_boot_ok = false
    _session_boot_error = ""
    super._ready()
    if not canonical_boot_ok():
        _session_boot_error = "gameplay_boot_failed"
        return

    _ensure_session_store()
    _restoring_session = not _continue_session.is_empty()
    if _restoring_session and not _restore_durable_session(_continue_session):
        _restoring_session = false
        _session_boot_error = "save_restore_failed"
        push_error("EnvironmentalPressureGameMain: durable Continue restore failed")
        return
    _restoring_session = false

    _connect_session_lifecycle()
    _session_boot_ok = true
    var status: Dictionary = _session_store.storage_status()
    if not bool(status.get("writable", false)):
        _set_session_status("SAVING UNAVAILABLE — PROGRESS WILL NOT SURVIVE CLOSE")
        return

    var checkpoint_reason: StringName = &"continue_checkpoint" if not _continue_session.is_empty() else &"new_game_checkpoint"
    var result: Dictionary = save_durable_session(checkpoint_reason)
    if bool(result.get("ok", false)) and not bool(status.get("persistent", true)):
        _set_session_status("BROWSER STORAGE NOT PERSISTENT — KEEP THIS TAB OPEN")

func _notification(what: int) -> void:
    if not _session_boot_ok or _kernel == null:
        return
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        _kernel.set_hard_paused(true)
        save_durable_session(&"background_checkpoint")
    elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
        _kernel.set_hard_paused(false)
    elif what == NOTIFICATION_WM_CLOSE_REQUEST:
        _kernel.set_hard_paused(true)
        save_durable_session(&"close_checkpoint")

func _ensure_session_store() -> void:
    if _session_store == null:
        _session_store = DurableSessionStoreClass.new()

func _connect_session_lifecycle() -> void:
    if _session_controls != null:
        var save_cb := Callable(self, "_on_session_save_requested")
        var leave_cb := Callable(self, "_on_session_save_leave_requested")
        if not _session_controls.save_requested.is_connected(save_cb):
            _session_controls.save_requested.connect(save_cb)
        if not _session_controls.save_leave_requested.is_connected(leave_cb):
            _session_controls.save_leave_requested.connect(leave_cb)

    if _kernel != null:
        var decision_cb := Callable(self, "_on_session_decision_required")
        if not _kernel.decision_required.is_connected(decision_cb):
            _kernel.decision_required.connect(decision_cb)

    var streaming: WorldStreamingCoordinator = FixtureClass.streaming_coordinator()
    if streaming != null:
        var region_cb := Callable(self, "_on_session_regions_changed")
        if not streaming.active_regions_changed.is_connected(region_cb):
            streaming.active_regions_changed.connect(region_cb)

func _on_session_save_requested() -> void:
    save_durable_session(&"manual")

func _on_session_save_leave_requested() -> void:
    if _session_controls != null:
        _session_controls.set_actions_enabled(false)
    var result: Dictionary = save_durable_session(&"save_and_menu")
    if not bool(result.get("ok", false)):
        if _session_controls != null:
            _session_controls.set_actions_enabled(true)
        return
    get_tree().change_scene_to_file(STARTUP_SCENE_PATH)

func _on_session_decision_required(_actor_id: String, _world_tick: int) -> void:
    if Time.get_ticks_msec() - _last_save_msec >= AUTOSAVE_MIN_MSEC:
        _queue_session_autosave(&"decision_checkpoint")

func _on_session_regions_changed(_activated: Variant, _deactivated: Variant) -> void:
    _queue_session_autosave(&"region_checkpoint")

func _queue_session_autosave(reason: StringName) -> void:
    if _autosave_queued or not _session_boot_ok or _restoring_session:
        return
    _autosave_queued = true
    call_deferred("_perform_session_autosave", reason)

func _perform_session_autosave(reason: StringName) -> void:
    _autosave_queued = false
    if _session_boot_ok and not _restoring_session:
        save_durable_session(reason)

func _set_session_status(message: String) -> void:
    if _session_controls != null:
        _session_controls.set_status(message)

func _build_durable_session() -> Dictionary:
    var registry: MaterializationRegistry = FixtureClass.materialization_registry()
    if not canonical_boot_ok() or registry == null or FixtureClass.active_seed() <= 0         or _world == null or _kernel == null or _combat_actions == null:
        return {}
    return {
        "schema_version": DurableSessionStoreClass.SESSION_SCHEMA_VERSION,
        "world_seed": FixtureClass.active_seed(),
        "saved_unix_time": int(Time.get_unix_time_from_system()),
        "owners": {
            "world": _world.snapshot(),
            "materialization_registry": registry.snapshot(),
            "kernel": _kernel.snapshot(),
            "collision_overrides": _collision_overrides.snapshot(),
            "doors": _door_state.snapshot(),
            "locomotion": _locomotion_state.snapshot(),
            "hands": _hand_state.snapshot(),
            "inventory": _inventory_state.snapshot(),
            "health": _health_state.snapshot(),
            "skills": _skill_state.snapshot(),
            "freshness": _freshness_state.snapshot(),
            "carry": _carry_state.snapshot(),
            "loot": _loot_state.snapshot(),
            "perception_memory": _perception_memory.snapshot(),
            "forage": _forage_state.snapshot(),
            "conditions": _condition_state.snapshot(),
            "utilities": _utilities.snapshot(),
            "power_network": _power_network.snapshot(),
            "flashlight": _flashlight_state.snapshot(),
            "portable_generators": _portable_generators.snapshot(),
            "vehicles": _vehicle_state.snapshot(),
            "world_interactions": _world_interaction_state.snapshot(),
            "firearms": _firearm_state.snapshot(),
            "corpses": _corpse_state.snapshot(),
            "infected": _infected_state.snapshot(),
            "combat_runtime": _combat_actions.runtime_snapshot(),
            "weather": _weather.snapshot(),
        },
    }

func _restore_durable_session(session: Dictionary) -> bool:
    var validation: Dictionary = _session_store.validate_session(session)
    if not bool(validation.get("ok", false)) or int(session.get("world_seed", 0)) != FixtureClass.active_seed():
        return false
    var owners: Dictionary = session.get("owners", {})
    var registry: MaterializationRegistry = FixtureClass.materialization_registry()
    if registry == null:
        return false

    if not registry.load_snapshot(owners["materialization_registry"]):
        return false
    if not _world.load_snapshot(owners["world"]):
        return false
    if not _collision_overrides.load_snapshot(owners["collision_overrides"]):
        return false
    if not _door_state.load_snapshot(owners["doors"]):
        return false

    var kernel_snapshot: Dictionary = Dictionary(owners["kernel"]).duplicate(true)
    # Hard pause is application lifecycle state, not a way to erase a committed action.
    kernel_snapshot["hard_paused"] = false
    if not _kernel.load_snapshot(kernel_snapshot):
        return false

    if not _locomotion_state.load_snapshot(owners["locomotion"]):
        return false
    if not _hand_state.load_snapshot(owners["hands"]):
        return false
    if not _inventory_state.load_snapshot(owners["inventory"]):
        return false
    if not _health_state.load_snapshot(owners["health"]):
        return false
    if not _skill_state.load_snapshot(owners["skills"]):
        return false
    if not _freshness_state.load_snapshot(owners["freshness"]):
        return false
    if not _carry_state.load_snapshot(owners["carry"]):
        return false
    if not _loot_state.load_snapshot(owners["loot"]):
        return false
    if not _perception_memory.load_snapshot(owners["perception_memory"]):
        return false
    if not _forage_state.load_snapshot(owners["forage"]):
        return false
    if not _condition_service.restore_state(owners["conditions"]):
        return false
    if not _utilities.restore_snapshot(owners["utilities"]):
        return false
    if not _power_network.restore_snapshot(owners["power_network"]):
        return false
    if not _flashlight_state.load_snapshot(owners["flashlight"]):
        return false
    if not _portable_generators.restore_snapshot(owners["portable_generators"]):
        return false
    if not _vehicle_state.load_snapshot(owners["vehicles"]):
        return false
    if not _world_interaction_state.load_snapshot(owners["world_interactions"]):
        return false
    if not _firearm_state.load_snapshot(owners["firearms"]):
        return false
    if not _corpse_state.load_snapshot(owners["corpses"]):
        return false
    if not _infected_state.load_snapshot(owners["infected"]):
        return false
    if not _combat_actions.load_runtime_snapshot(owners["combat_runtime"]):
        return false
    if not _weather.load_snapshot(owners["weather"]):
        return false

    var placement: WorldPlacement = _world.placement(FixtureClass.PLAYER_ID)
    var streaming: WorldStreamingCoordinator = FixtureClass.streaming_coordinator()
    if placement == null or streaming == null or not bool(streaming.update_focus(placement.anchor).get("ok", false)):
        return false
    if _infected_cohort != null and not _infected_cohort.sync_active_now():
        return false
    if not _sync_vehicle_lighting_emitters():
        return false
    _sync_refrigeration_clocks()
    if not _sync_infected_opening_pressure():
        return false
    _flush_pending_visual_state()
    return true

func _boot_canonical_demo() -> bool:
    if not super._boot_canonical_demo():
        return false
    if not _boot_system39_environmental_pressure():
        return false
    return _boot_world_resolution_indicator()

func _boot_system39_environmental_pressure() -> bool:
    if _world == null or _world_interaction_state == null or _door_state == null \
        or _door_transition == null or _interaction_reach == null or _spatial_query == null \
        or _kernel == null or _world_interaction_catalog == null or _world_interaction_actions == null \
        or _spatial_sound == null or _infected_cohort == null:
        return false

    _opening_pressure = OpeningPressureClass.new(
        _world,
        _world_interaction_state,
        _door_state,
        _door_transition,
        _interaction_reach,
        _spatial_query,
        _kernel,
        _world_interaction_catalog,
        _world_interaction_actions,
        _spatial_sound
    )
    if _opening_pressure == null or not _opening_pressure.is_ready():
        return false
    var callback := Callable(self, "_on_infected_active_members_changed")
    if not _infected_cohort.active_members_changed.is_connected(callback):
        _infected_cohort.active_members_changed.connect(callback)
    return _sync_infected_opening_pressure()

func _sync_infected_opening_pressure() -> bool:
    for actor_id: String in _infected_cohort.roster_actor_ids():
        var behavior: CohortInfectedBehaviorService = _infected_cohort.behavior_for_actor(actor_id)
        if behavior == null:
            continue
        if behavior.opening_pressure_service() == null and not behavior.configure_opening_pressure(_opening_pressure):
            return false
    return true

func _on_infected_active_members_changed(_active_actor_ids: Array[String]) -> void:
    if not _sync_infected_opening_pressure():
        push_error("EnvironmentalPressureGameMain: failed to configure opening pressure for activated infected")

func _boot_world_resolution_indicator() -> bool:
    var streaming: WorldStreamingCoordinator = FixtureClass.streaming_coordinator()
    if _resolution_indicator == null or _kernel == null or _infected_cohort == null or streaming == null:
        return false
    return _resolution_indicator.configure(_kernel, _infected_cohort, streaming)

func opening_pressure_service() -> ActorOpeningPressureActionService:
    return _opening_pressure

func world_resolution_indicator() -> WorldResolutionIndicator:
    return _resolution_indicator
