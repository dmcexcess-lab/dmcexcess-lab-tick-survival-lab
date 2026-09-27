extends EnvironmentalPressureGameMain
class_name TurnBasedGameMain

const SimpleTurnControllerClass = preload("res://scripts/player/SimpleTurnController.gd")
const TurnIntents = preload("res://scripts/input/PlayerActionIntent.gd")

var _simple_turns: SimpleTurnController = null

func _boot_production_world() -> bool:
    if not super._boot_production_world():
        return false
    _simple_turns = SimpleTurnControllerClass.new(_world, _world_mutations, _spatial_query, WorldBootstrapClass.PLAYER_ID)
    var infected_ids: Array[String] = []
    for member: Dictionary in _infected_cohort_results:
        var actor_id := String(member.get("actor_id", ""))
        if not actor_id.is_empty():
            infected_ids.append(actor_id)
    _simple_turns.set_infected_actor_ids(infected_ids)
    add_child(_simple_turns)
    if not _simple_turns.is_ready():
        return false
    _simple_turns.action_resolved.connect(Callable(_hud, "present_action_result"))
    _simple_turns.action_busy_changed.connect(_on_player_action_busy_changed)
    _simple_turns.turn_completed.connect(_on_simple_turn_completed)
    return true

func _route_player_intent(intent: StringName) -> void:
    if TurnIntents.is_movement(intent) and _simple_turns != null and (_vehicle_controller == null or not _vehicle_controller.is_mounted()):
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
