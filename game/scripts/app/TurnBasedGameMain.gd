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

# Utilities are not migrated yet, but later gameplay boot layers already consume
# their logical power/water truth. Keep that plain state and omit the legacy
# tick-driven physical-wire/appliance runtime from Slice 1 startup.
func _boot_utility_runtime() -> bool:
    var plan: GeneratedGlobalWorldPlan = WorldBootstrapClass.global_plan()
    if plan == null or not plan.is_generated():
        return false
    _local_power_topology = PowerTopologyPlannerClass.new().plan(plan)
    if not bool(_local_power_topology.get("ok", false)):
        return false
    _utilities = UtilityStateClass.new(_local_power_topology)
    if not _utilities.initialize_from_plan(plan):
        return false
    var player: WorldPlacement = _world.placement(WorldBootstrapClass.PLAYER_ID)
    if player == null:
        return false
    _central_power_service_id = _utilities.power_service_for_cell(player.anchor)
    _central_water_service_id = _utilities.water_service_for_cell(player.anchor)
    return not _central_power_service_id.is_empty() and not _central_water_service_id.is_empty()

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
