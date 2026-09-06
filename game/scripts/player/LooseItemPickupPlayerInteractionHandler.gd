extends RefCounted
class_name LooseItemPickupPlayerInteractionHandler

const Profiles = preload("res://scripts/simulation/actors/equipment/ActorEquipmentProfileCatalog.gd")

const ACTION_ID: StringName = &"item.pickup"

var _world: WorldState = null
var _transfer: ItemTransferActionService = null
var _hands: ActorHandEquipmentState = null
var _profiles: ActorEquipmentProfileCatalog = Profiles.new()

func _init(
    world: WorldState = null,
    transfer: ItemTransferActionService = null,
    hands: ActorHandEquipmentState = null
) -> void:
    _world = world
    _transfer = transfer
    _hands = hands

func is_ready() -> bool:
    return _world != null and _transfer != null and _transfer.is_ready() and _hands != null

func request_pickup(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    var actor: String = actor_id.strip_edges()
    var target: String = target_id.strip_edges()
    if not is_ready():
        return _rejected("pickup_input_not_ready")
    if action_id != ACTION_ID:
        return _rejected("pickup_action_unknown")
    if actor.is_empty() or target.is_empty() or not _world.has_entity(target):
        return _rejected("pickup_target_missing")
    var entity: WorldEntityRecord = _world.entity(target)
    if entity == null or not String(entity.semantic_type).begins_with("item."):
        return _rejected("pickup_target_not_item")

    var result: ItemTransferActionResult = null
    if entity.semantic_type == ActorEquipmentProfileCatalog.SKATEBOARD:
        for slot: int in _profiles.allowed_slots(entity.semantic_type):
            if _hands.item_in_slot(actor, slot).is_empty():
                result = _transfer.request_pickup_to_hand(actor, target, slot)
                break
        if result == null:
            return _rejected("skateboard_requires_free_hand_or_back")
    else:
        result = _transfer.request_pickup_to_container(actor, target, actor)
    return _normalize(result)

static func _normalize(result: ItemTransferActionResult) -> Dictionary:
    if result == null:
        return _rejected("pickup_transfer_missing")
    return {
        "accepted": result.is_accepted(),
        "action_serial": result.action_serial,
        "reason": "" if result.is_accepted() else result.reason,
    }

static func _rejected(reason: String) -> Dictionary:
    return {
        "accepted": false,
        "action_serial": 0,
        "reason": reason,
    }
