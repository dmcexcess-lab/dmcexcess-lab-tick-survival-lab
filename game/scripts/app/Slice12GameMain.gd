extends Slice11GameMain
class_name Slice12GameMain

const Slice12ResidentProjection = preload("res://scripts/simulation/population/PopulationResidentProjection.gd")

var _slice12_infected_records: Array[Dictionary] = []
var _slice12_active_ids: Array[String] = []
var _slice12_boundary_refreshes: int = 0
var _slice12_last_active_regions: Array[Vector2i] = []

func _boot_production_world() -> bool:
    if not super._boot_production_world():
        return false
    if not _cache_slice12_infected_records():
        return false
    if not _simple_turns.set_before_local_infected_turns(Callable(self, "_refresh_slice12_simulation_boundary")):
        return false
    return _refresh_slice12_simulation_boundary()

func _cache_slice12_infected_records() -> bool:
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
    _slice12_infected_records = Slice12ResidentProjection.new().infected_records(population_plan)
    return true

func _refresh_slice12_simulation_boundary() -> bool:
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
    var boundary_changed := active_regions != _slice12_last_active_regions
    if boundary_changed:
        _slice12_last_active_regions = active_regions.duplicate()
        _slice12_boundary_refreshes += 1

    var active: Dictionary = {}

    # Persisted infected that moved into the active streamed neighborhood become
    # eligible again. Persisted infected outside it stay untouched and dormant.
    for actor_id: String in _simple_infected_ids:
        var placement: WorldPlacement = _world.placement(actor_id)
        if placement != null and streaming.is_cell_active(placement.anchor):
            active[actor_id] = true

    # Virgin resident records are projected once, then only records whose home is
    # currently active are considered for hydration. This avoids whole-world work
    # on ordinary player actions.
    if boundary_changed:
        for record: Dictionary in _slice12_infected_records:
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

    _slice12_active_ids.clear()
    for actor_id: String in active.keys():
        _slice12_active_ids.append(actor_id)
    _slice12_active_ids.sort()
    _simple_turns.set_infected_actor_ids(_slice12_active_ids)
    return true

func _on_simple_turn_completed(turn_number: int, active_actor_count: int) -> void:
    super._on_simple_turn_completed(turn_number, active_actor_count)
    _refresh_slice12_simulation_boundary()

func slice12_active_infected_ids() -> Array[String]:
    return _slice12_active_ids.duplicate()

func slice12_known_infected_ids() -> Array[String]:
    return _simple_infected_ids.duplicate()

func slice12_boundary_refresh_count() -> int:
    return _slice12_boundary_refreshes

func slice12_cell_active(cell: Vector2i) -> bool:
    var streaming: WorldStreamingCoordinator = WorldBootstrapClass.streaming_coordinator()
    return streaming != null and streaming.is_cell_active(cell)
