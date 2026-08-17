extends RefCounted
class_name ActorHandEquipmentMutationService

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")
const RecordClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentRecord.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")

## Validated normal write path for persistent survivor hand assignments.
## This is mechanic state only: no inventory transfer, timing, combat, rendering, or UI side effects.

var _state: ActorHandEquipmentState = null
var _world: WorldState = null

func _init(hand_state: ActorHandEquipmentState = null, world_state: WorldState = null) -> void:
    _state = hand_state
    _world = world_state

func is_ready() -> bool:
    return _state != null and _world != null

func enroll_actor(actor_id: String) -> bool:
    if not is_ready() or not EntityIdRules.is_valid(actor_id):
        return false
    if _state.has_actor(actor_id) or not _is_valid_world_survivor(actor_id):
        return false
    var version: int = _state.revision() + 1
    return _state._insert_record(RecordClass.new(actor_id, "", "", version))

func remove_actor(actor_id: String) -> bool:
    if _state == null or not _state.has_actor(actor_id):
        return false
    return _state._remove_record(actor_id) != null

func set_item(actor_id: String, slot: int, item_id: String) -> bool:
    if not is_ready() or not EntityIdRules.is_valid(actor_id) or not Slots.is_valid(slot):
        return false
    if item_id.is_empty() or not EntityIdRules.is_valid(item_id):
        return false
    if not _state.has_actor(actor_id) or not _is_valid_world_survivor(actor_id):
        return false
    if not _is_valid_unplaced_world_item(item_id):
        return false

    var assignment: Dictionary = _state.assignment_for_item(item_id)
    if not assignment.is_empty():
        var assigned_actor: String = String(assignment.get("actor_id", ""))
        var assigned_slot: int = int(assignment.get("slot", -1))
        if assigned_actor != actor_id or assigned_slot != slot:
            return false

    return _state._set_item_record(actor_id, slot, item_id)

func clear_slot(actor_id: String, slot: int) -> bool:
    if _state == null or not EntityIdRules.is_valid(actor_id) or not Slots.is_valid(slot):
        return false
    if not _state.has_actor(actor_id):
        return false
    return _state._set_item_record(actor_id, slot, "")

func _is_valid_world_survivor(actor_id: String) -> bool:
    if _world == null or not _world.has_entity(actor_id):
        return false
    var entity: WorldEntityRecord = _world.entity(actor_id)
    return entity != null and String(entity.semantic_type).strip_edges() == "actor.survivor"

func _is_valid_unplaced_world_item(item_id: String) -> bool:
    if _world == null or not _world.has_entity(item_id) or _world.has_placement(item_id):
        return false
    var entity: WorldEntityRecord = _world.entity(item_id)
    if entity == null:
        return false
    var semantic: String = String(entity.semantic_type).strip_edges()
    return semantic.begins_with("item.") and semantic.length() > 5
