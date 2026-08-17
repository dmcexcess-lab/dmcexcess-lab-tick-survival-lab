extends RefCounted
class_name DoorStateMutationService

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")
const RecordClass = preload("res://scripts/simulation/doors/DoorStateRecord.gd")
const StateRules = preload("res://scripts/simulation/doors/DoorStateValue.gd")

## Validated normal write path for persistent door OPEN/CLOSED state.
## This is mechanic state only: no timing, collision, rendering, or interaction side effects.

var _state: DoorStateStore = null
var _world: WorldState = null

func _init(door_state: DoorStateStore = null, world_state: WorldState = null) -> void:
    _state = door_state
    _world = world_state

func is_ready() -> bool:
    return _state != null and _world != null

func enroll(door_id: String, initial_state: StringName) -> bool:
    if not is_ready() or not EntityIdRules.is_valid(door_id):
        return false
    if not StateRules.is_stored(initial_state) or _state.has_door(door_id):
        return false
    if not _is_valid_world_door(door_id):
        return false
    var version: int = _state.revision() + 1
    return _state._insert_record(RecordClass.new(door_id, initial_state, version))

func remove(door_id: String) -> bool:
    if _state == null or not _state.has_door(door_id):
        return false
    return _state._remove_record(door_id) != null

func set_state(door_id: String, target_state: StringName) -> bool:
    if not is_ready() or not EntityIdRules.is_valid(door_id):
        return false
    if not StateRules.is_stored(target_state) or not _state.has_door(door_id):
        return false
    if not _is_valid_world_door(door_id):
        return false
    return _state._set_state_record(door_id, target_state)

func _is_valid_world_door(door_id: String) -> bool:
    if _world == null or not _world.has_entity(door_id):
        return false
    var entity: WorldEntityRecord = _world.entity(door_id)
    if entity == null:
        return false
    var semantic: String = String(entity.semantic_type).strip_edges()
    return semantic.begins_with("door.") and semantic.length() > 5
