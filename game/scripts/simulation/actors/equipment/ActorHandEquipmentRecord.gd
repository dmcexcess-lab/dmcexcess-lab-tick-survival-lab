extends RefCounted
class_name ActorHandEquipmentRecord

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")

## Immutable-style persistent two-hand equipment state for one stable survivor ID.

var actor_id: String = ""
var primary_item_id: String = ""
var secondary_item_id: String = ""
var version: int = 1

func _init(
    value_actor_id: String = "",
    value_primary_item_id: String = "",
    value_secondary_item_id: String = "",
    value_version: int = 1
) -> void:
    actor_id = value_actor_id
    primary_item_id = value_primary_item_id
    secondary_item_id = value_secondary_item_id
    version = value_version

func is_valid() -> bool:
    if not EntityIdRules.is_valid(actor_id) or version < 1:
        return false
    if not _item_id_is_valid_or_empty(primary_item_id):
        return false
    if not _item_id_is_valid_or_empty(secondary_item_id):
        return false
    if not primary_item_id.is_empty() and primary_item_id == secondary_item_id:
        return false
    return true

func item_in_slot(slot: int) -> String:
    match slot:
        Slots.Value.PRIMARY_RIGHT:
            return primary_item_id
        Slots.Value.SECONDARY_LEFT:
            return secondary_item_id
        _:
            return ""

func copy() -> ActorHandEquipmentRecord:
    return ActorHandEquipmentRecord.new(actor_id, primary_item_id, secondary_item_id, version)

func to_snapshot() -> Dictionary:
    return {
        "actor_id": actor_id,
        "primary_item_id": primary_item_id,
        "secondary_item_id": secondary_item_id,
        "version": version,
    }

static func from_snapshot(data: Dictionary) -> ActorHandEquipmentRecord:
    var record := ActorHandEquipmentRecord.new(
        String(data.get("actor_id", "")),
        String(data.get("primary_item_id", "")),
        String(data.get("secondary_item_id", "")),
        int(data.get("version", 0))
    )
    if not record.is_valid():
        return null
    return record

static func _item_id_is_valid_or_empty(item_id: String) -> bool:
    return item_id.is_empty() or EntityIdRules.is_valid(item_id)
