extends GameMain
class_name TurnBasedGameMain

const SimpleTurnControllerClass = preload("res://scripts/player/SimpleTurnController.gd")
const TurnIntents = preload("res://scripts/input/PlayerActionIntent.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

const SIMPLE_INFECTED_COUNT := 12
const SIMPLE_INFECTED_SEARCH_RADIUS := 12
const INVALID_CELL := Vector2i(-999999, -999999)

var _simple_turns: SimpleTurnController = null
var _simple_infected_ids: Array[String] = []

func _boot_production_world() -> bool:
    if not super._boot_production_world():
        return false
    if not _hydrate_simple_local_infected():
        return false
    _simple_turns = SimpleTurnControllerClass.new(_world, _world_mutations, _spatial_query, WorldBootstrapClass.PLAYER_ID)
    _simple_turns.set_infected_actor_ids(_simple_infected_ids)
    add_child(_simple_turns)
    if not _simple_turns.is_ready():
        return false
    _simple_turns.action_resolved.connect(Callable(_hud, "present_action_result"))
    _simple_turns.action_busy_changed.connect(_on_player_action_busy_changed)
    _simple_turns.turn_completed.connect(_on_simple_turn_completed)
    return true

func _hydrate_simple_local_infected() -> bool:
    var player: WorldPlacement = _world.placement(WorldBootstrapClass.PLAYER_ID)
    if player == null:
        return false
    # Slice 1 materializes only a tiny active-neighborhood cohort. Population-
    # density spawning is an existing game feature to reconnect later; it must not
    # make the foundational turn loop scan or hydrate the persistent island.
    for index in range(SIMPLE_INFECTED_COUNT):
        var spawn_cell := _clear_actor_cell_near(player.anchor)
        if spawn_cell == INVALID_CELL:
            break
        var actor_id := "infected.local.%03d" % (index + 1)
        if _world.has_entity(actor_id):
            continue
        if _world_mutations.create_entity(&"actor.survivor", actor_id) != actor_id:
            continue
        if not _world_mutations.set_placement(actor_id, Layers.Channel.ACTOR, spawn_cell, Facing.Value.SOUTH, Footprint.single_cell()):
            _world_mutations.remove_entity(actor_id)
            continue
        _simple_infected_ids.append(actor_id)
    return not _simple_infected_ids.is_empty()

func _clear_actor_cell_near(origin: Vector2i) -> Vector2i:
    for radius in range(2, SIMPLE_INFECTED_SEARCH_RADIUS + 1):
        for y in range(-radius, radius + 1):
            for x in range(-radius, radius + 1):
                if absi(x) != radius and absi(y) != radius:
                    continue
                var cell := origin + Vector2i(x, y)
                if _spatial_query.has_terrain(cell) and _spatial_query.query_cell(cell, "", true).is_clear():
                    return cell
    return INVALID_CELL

func _route_player_intent(intent: StringName) -> void:
    if TurnIntents.is_movement(intent) and _simple_turns != null:
        _simple_turns.submit_intent(intent)
        return
    super._route_player_intent(intent)

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

func simple_turn_controller() -> SimpleTurnController:
    return _simple_turns
