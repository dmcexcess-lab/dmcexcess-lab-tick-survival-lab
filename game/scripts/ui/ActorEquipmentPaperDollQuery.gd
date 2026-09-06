extends RefCounted
class_name ActorEquipmentPaperDollQuery

const ProjectionClass = preload("res://scripts/simulation/actors/equipment/ActorEquipmentProjection.gd")
const ProtectionClass = preload("res://scripts/simulation/actors/equipment/ActorEquipmentProtectionQuery.gd")
const Profiles = preload("res://scripts/simulation/actors/equipment/ActorEquipmentProfileCatalog.gd")

## Player-facing read model only. Equipment ownership stays in ActorHandEquipmentState.

var _projection: ActorEquipmentProjection = null
var _protection: ActorEquipmentProtectionQuery = null

func _init(
    world: WorldState = null,
    equipment: ActorHandEquipmentState = null,
    profiles: ActorEquipmentProfileCatalog = null
) -> void:
    var actual_profiles := profiles if profiles != null else Profiles.new()
    _projection = ProjectionClass.new(world, equipment, actual_profiles)
    _protection = ProtectionClass.new(world, equipment, actual_profiles)

func is_ready() -> bool:
    return _projection != null and _projection.is_ready() and _protection != null and _protection.is_ready()

func query(actor_id: String) -> Dictionary:
    var projected := _projection.query(actor_id)
    if not bool(projected.get("known", false)):
        return {"known": false, "actor_id": actor_id, "slots": [], "protection": _protection.query(actor_id) if _protection != null else {}}
    return {
        "known": true,
        "actor_id": actor_id,
        "slots": Array(projected.get("slots", [])).duplicate(true),
        "protection": _protection.query(actor_id),
    }
