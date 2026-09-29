extends VehicleSimpleGameMain
class_name Slice11GameMain

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
    return true

func _on_simple_turn_completed(turn_number: int, active_actor_count: int) -> void:
    super._on_simple_turn_completed(turn_number, active_actor_count)
    var target_tick := survival_elapsed_tick()
    if target_tick < 0 or _world_time == null or _weather == null:
        return
    if not _world_time.advance_to_tick(target_tick):
        push_error("Slice11GameMain: world time failed to advance to %d" % target_tick)
        return
    if not _weather.advance_to_tick(target_tick):
        push_error("Slice11GameMain: weather failed to advance to %d" % target_tick)
        return
    if _hud != null:
        _hud.refresh()
    _flush_pending_visual_state()

func _build_durable_session() -> Dictionary:
    var session := super._build_durable_session()
    if session.is_empty() or _world_time == null or not _world_time.is_ready():
        return session
    var owners: Dictionary = session.get("owners", {})
    owners["world_time"] = _world_time.snapshot()
    session["owners"] = owners
    return session

func _restore_durable_session(session: Dictionary) -> bool:
    if not super._restore_durable_session(session):
        return false
    var owners: Dictionary = session.get("owners", {})
    var target_tick := survival_elapsed_tick()
    if owners.has("world_time") and typeof(owners["world_time"]) == TYPE_DICTIONARY:
        if not _world_time.load_snapshot(owners["world_time"]):
            return false
        target_tick = _world_time.world_tick()
    else:
        if not _world_time.configure_manual_clock(maxi(0, target_tick)):
            return false
    if not _weather.configure_manual_clock(_world_time.world_tick()):
        return false
    if owners.has("weather") and typeof(owners["weather"]) == TYPE_DICTIONARY:
        if not _weather.load_snapshot(owners["weather"]):
            return false
    if not _weather.advance_to_tick(_world_time.world_tick()):
        return false
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
