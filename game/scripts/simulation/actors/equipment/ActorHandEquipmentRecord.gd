extends RefCounted
class_name ActorHandEquipmentRecord

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")

## Immutable-style persistent actor equipment state. Legacy hand fields remain stable.

var actor_id: String = ""
var primary_item_id: String = ""
var secondary_item_id: String = ""
var back_item_id: String = ""
var head_item_id: String = ""
var torso_item_id: String = ""
var legs_item_id: String = ""
var feet_item_id: String = ""
var hands_item_id: String = ""
var version: int = 1

func _init(
    value_actor_id: String = "",
    value_primary_item_id: String = "",
    value_secondary_item_id: String = "",
    value_version: int = 1,
    value_back_item_id: String = "",
    value_head_item_id: String = "",
    value_torso_item_id: String = "",
    value_legs_item_id: String = "",
    value_feet_item_id: String = "",
    value_hands_item_id: String = ""
) -> void:
    actor_id = value_actor_id
    primary_item_id = value_primary_item_id
    secondary_item_id = value_secondary_item_id
    back_item_id = value_back_item_id
    head_item_id = value_head_item_id
    torso_item_id = value_torso_item_id
    legs_item_id = value_legs_item_id
    feet_item_id = value_feet_item_id
    hands_item_id = value_hands_item_id
    version = value_version

func is_valid() -> bool:
    if not EntityIdRules.is_valid(actor_id) or version < 1:
        return false
    var seen: Dictionary = {}
    for slot: int in Slots.ALL:
        var item_id := item_in_slot(slot)
        if not _item_id_is_valid_or_empty(item_id):
            return false
        if not item_id.is_empty():
            if seen.has(item_id):
                return false
            seen[item_id] = true
    return true

func item_in_slot(slot: int) -> String:
    match slot:
        Slots.Value.PRIMARY_RIGHT: return primary_item_id
        Slots.Value.SECONDARY_LEFT: return secondary_item_id
        Slots.Value.BACK: return back_item_id
        Slots.Value.HEAD: return head_item_id
        Slots.Value.TORSO: return torso_item_id
        Slots.Value.LEGS: return legs_item_id
        Slots.Value.FEET: return feet_item_id
        Slots.Value.HANDS: return hands_item_id
        _: return ""

func with_item(slot: int, item_id: String) -> ActorHandEquipmentRecord:
    var values := [primary_item_id, secondary_item_id, back_item_id, head_item_id, torso_item_id, legs_item_id, feet_item_id, hands_item_id]
    if slot < 0 or slot >= values.size():
        return null
    values[slot] = item_id
    return ActorHandEquipmentRecord.new(actor_id, values[0], values[1], version + 1, values[2], values[3], values[4], values[5], values[6], values[7])

func copy() -> ActorHandEquipmentRecord:
    return ActorHandEquipmentRecord.new(actor_id, primary_item_id, secondary_item_id, version, back_item_id, head_item_id, torso_item_id, legs_item_id, feet_item_id, hands_item_id)

func to_snapshot() -> Dictionary:
    return {
        "actor_id": actor_id,
        "primary_item_id": primary_item_id,
        "secondary_item_id": secondary_item_id,
        "back_item_id": back_item_id,
        "head_item_id": head_item_id,
        "torso_item_id": torso_item_id,
        "legs_item_id": legs_item_id,
        "feet_item_id": feet_item_id,
        "hands_item_id": hands_item_id,
        "version": version,
    }

static func from_snapshot(data: Dictionary) -> ActorHandEquipmentRecord:
    var record := ActorHandEquipmentRecord.new(
        String(data.get("actor_id", "")),
        String(data.get("primary_item_id", "")),
        String(data.get("secondary_item_id", "")),
        int(data.get("version", 0)),
        String(data.get("back_item_id", "")),
        String(data.get("head_item_id", "")),
        String(data.get("torso_item_id", "")),
        String(data.get("legs_item_id", "")),
        String(data.get("feet_item_id", "")),
        String(data.get("hands_item_id", ""))
    )
    return record if record.is_valid() else null

static func _item_id_is_valid_or_empty(item_id: String) -> bool:
    return item_id.is_empty() or EntityIdRules.is_valid(item_id)
