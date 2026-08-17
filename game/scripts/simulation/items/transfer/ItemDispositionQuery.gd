extends RefCounted
class_name ItemDispositionQuery

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const ResultClass = preload("res://scripts/simulation/items/transfer/ItemDispositionResult.gd")

var _world: WorldState = null
var _hands: ActorHandEquipmentState = null
var _containment: InventoryContainmentState = null

func _init(
    world_state: WorldState = null,
    hand_state: ActorHandEquipmentState = null,
    containment_state: InventoryContainmentState = null
) -> void:
    _world = world_state
    _hands = hand_state
    _containment = containment_state

func is_ready() -> bool:
    return _world != null and _hands != null and _containment != null

func query(item_id: String) -> ItemDispositionResult:
    var result := ResultClass.new()
    result.item_id = item_id.strip_edges()
    if not is_ready() or result.item_id.is_empty():
        result.status = ResultClass.Status.UNKNOWN
        result.reason = "disposition_not_ready" if not is_ready() else "item_missing"
        return result
    if not _world.has_entity(result.item_id):
        result.status = ResultClass.Status.UNKNOWN
        result.reason = "item_missing"
        return result

    var entity: WorldEntityRecord = _world.entity(result.item_id)
    if entity == null:
        result.status = ResultClass.Status.UNKNOWN
        result.reason = "item_missing"
        return result
    var semantic: String = String(entity.semantic_type).strip_edges()
    if not semantic.begins_with("item.") or semantic.length() <= 5:
        result.status = ResultClass.Status.UNKNOWN
        result.reason = "not_item"
        return result
    result.semantic_type = entity.semantic_type

    var placed: bool = _world.has_placement(result.item_id)
    var assignment: Dictionary = _hands.assignment_for_item(result.item_id)
    var held: bool = not assignment.is_empty()
    var contained: bool = _containment.is_contained(result.item_id)

    var truth_count: int = 0
    if placed:
        truth_count += 1
    if held:
        truth_count += 1
    if contained:
        truth_count += 1
    if truth_count > 1:
        result.status = ResultClass.Status.CONFLICT
        result.reason = "disposition_conflict"
        if placed:
            result.placement = _world.placement(result.item_id)
        if held:
            result.actor_id = String(assignment.get("actor_id", ""))
            result.slot = int(assignment.get("slot", -1))
        if contained:
            result.container_id = _containment.container_of(result.item_id)
        return result

    if placed:
        var placement: WorldPlacement = _world.placement(result.item_id)
        if placement == null:
            result.status = ResultClass.Status.UNKNOWN
            result.reason = "placement_missing"
            return result
        result.placement = placement
        if placement.channel != Layers.Channel.LOOSE_ITEM:
            result.status = ResultClass.Status.INVALID_PLACEMENT
            result.reason = "invalid_item_placement"
            return result
        result.status = ResultClass.Status.LOOSE_WORLD
        return result

    if held:
        result.status = ResultClass.Status.HAND
        result.actor_id = String(assignment.get("actor_id", ""))
        result.slot = int(assignment.get("slot", -1))
        return result

    if contained:
        result.status = ResultClass.Status.CONTAINED
        result.container_id = _containment.container_of(result.item_id)
        return result

    result.status = ResultClass.Status.UNCLAIMED
    return result
