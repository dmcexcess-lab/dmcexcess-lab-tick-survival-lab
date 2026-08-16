extends RefCounted
class_name ActorLocomotionRecord

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")
const StanceRules = preload("res://scripts/simulation/actors/locomotion/ActorStance.gd")

var actor_id: String = ""
var stance: StringName = StanceRules.STANDING
var version: int = 1

func _init(
    value_actor_id: String = "",
    value_stance: StringName = StanceRules.STANDING,
    value_version: int = 1
) -> void:
    actor_id = value_actor_id
    stance = value_stance
    version = value_version

func is_valid() -> bool:
    return EntityIdRules.is_valid(actor_id) and StanceRules.is_valid(stance) and version >= 1

func copy() -> ActorLocomotionRecord:
    return ActorLocomotionRecord.new(actor_id, stance, version)

func to_snapshot() -> Dictionary:
    return {
        "actor_id": actor_id,
        "stance": String(stance),
        "version": version,
    }

static func from_snapshot(data: Dictionary) -> ActorLocomotionRecord:
    var actor_value: String = String(data.get("actor_id", ""))
    var stance_value := StringName(String(data.get("stance", "")))
    var version_value: int = int(data.get("version", 0))
    var record := ActorLocomotionRecord.new(actor_value, stance_value, version_value)
    if not record.is_valid():
        return null
    return record
