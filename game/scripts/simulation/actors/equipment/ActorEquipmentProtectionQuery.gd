extends RefCounted
class_name ActorEquipmentProtectionQuery

const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const Profiles = preload("res://scripts/simulation/actors/equipment/ActorEquipmentProfileCatalog.gd")

## Derived read-only equipment totals. Insulation remains thermal/comfort, not armor.

var _world: WorldState = null
var _equipment: ActorHandEquipmentState = null
var _profiles: ActorEquipmentProfileCatalog = null

func _init(world: WorldState = null, equipment: ActorHandEquipmentState = null, profiles: ActorEquipmentProfileCatalog = null) -> void:
    _world = world
    _equipment = equipment
    _profiles = profiles if profiles != null else Profiles.new()

func is_ready() -> bool:
    return _world != null and _equipment != null and _profiles != null

func query(actor_id: String) -> Dictionary:
    var result := {
        "known": false,
        "bite_cut_armor": 0,
        "blunt_ballistic_armor": 0,
        "water_resistance": 0,
        "insulation": 0,
        "equipped": [],
    }
    if not is_ready() or not _equipment.has_actor(actor_id):
        return result
    var equipped: Array = []
    for slot: int in Slots.ALL:
        var item_id := _equipment.item_in_slot(actor_id, slot)
        if item_id.is_empty():
            continue
        var entity := _world.entity(item_id)
        if entity == null:
            continue
        var values := _profiles.protection_weather_and_thermal(entity.semantic_type)
        for key: String in ["bite_cut_armor", "blunt_ballistic_armor", "water_resistance", "insulation"]:
            result[key] = int(result[key]) + int(values.get(key, 0))
        equipped.append({"slot": Slots.label(slot), "item_id": item_id, "semantic_type": entity.semantic_type, "values": values})
    for key: String in ["bite_cut_armor", "blunt_ballistic_armor", "water_resistance", "insulation"]:
        result[key] = mini(100, int(result[key]))
    result["equipped"] = equipped
    result["known"] = true
    return result

func query_thermal(actor_id: String) -> Dictionary:
    var result := query(actor_id)
    return {"known": bool(result.get("known", false)), "insulation": int(result.get("insulation", 0))}
