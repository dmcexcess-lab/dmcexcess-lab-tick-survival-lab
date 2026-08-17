extends MovementPassageResolver
class_name DoorMovementPassageResolver

const QueryResult = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")

var _world: WorldState = null
var _state: DoorStateStore = null
var _transitions: DoorPhysicalTransitionService = null

func _init(
    world_state: WorldState = null,
    door_state: DoorStateStore = null,
    transition_service: DoorPhysicalTransitionService = null
) -> void:
    _world = world_state
    _state = door_state
    _transitions = transition_service

func is_ready() -> bool:
    return _world != null and _state != null and _transitions != null and _transitions.is_ready()

func can_resolve(actor_id: String, action_type: StringName, query_result: SpatialQueryResult) -> bool:
    if not is_ready() or actor_id.strip_edges().is_empty() or query_result == null:
        return false
    if query_result.status != QueryResult.Status.BLOCKED or query_result.blocking_entity_ids.size() != 1:
        return false
    if action_type != &"movement.step_forward" and action_type != &"movement.step_backward" and action_type != &"movement.run_forward":
        return false
    var door_id: String = query_result.blocking_entity_ids[0]
    if not _world.has_entity(door_id) or not _state.has_door(door_id):
        return false
    var entity: WorldEntityRecord = _world.entity(door_id)
    if entity == null or not String(entity.semantic_type).begins_with("door."):
        return false
    return _state.state(door_id) == DoorValue.CLOSED

func resolve(
    actor_id: String,
    _action_serial: int,
    action_type: StringName,
    query_result: SpatialQueryResult
) -> bool:
    if not can_resolve(actor_id, action_type, query_result):
        return false
    return _transitions.open_for_passage(actor_id, query_result.blocking_entity_ids[0], action_type)
