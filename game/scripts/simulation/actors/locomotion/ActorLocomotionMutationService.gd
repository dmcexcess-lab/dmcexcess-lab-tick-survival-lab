extends RefCounted
class_name ActorLocomotionMutationService

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")
const StanceRules = preload("res://scripts/simulation/actors/locomotion/ActorStance.gd")
const RecordClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionRecord.gd")

## Validated normal write path for locomotion-only actor state.

var _state: ActorLocomotionState = null

func _init(locomotion_state: ActorLocomotionState = null) -> void:
    _state = locomotion_state

func is_ready() -> bool:
    return _state != null

func enroll(actor_id: String, initial_stance: StringName = StanceRules.STANDING) -> bool:
    if _state == null or not EntityIdRules.is_valid(actor_id):
        return false
    if not StanceRules.is_valid(initial_stance) or _state.has_actor(actor_id):
        return false
    return _state._insert_record(RecordClass.new(actor_id, initial_stance, _state.revision() + 1))

func remove(actor_id: String) -> bool:
    if _state == null or not _state.has_actor(actor_id):
        return false
    return _state._remove_record(actor_id) != null

func set_stance(actor_id: String, target_stance: StringName) -> bool:
    if _state == null or not EntityIdRules.is_valid(actor_id):
        return false
    if not StanceRules.is_valid(target_stance):
        return false
    return _state._set_stance_record(actor_id, target_stance)
