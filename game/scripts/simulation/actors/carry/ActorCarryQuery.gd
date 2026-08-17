extends RefCounted
class_name ActorCarryQuery

## 13E read-only derived carry query over 09 Hands + 11 Containment + 13D weight.

enum Status {
    KNOWN,
    UNKNOWN,
    INVALID,
}

const MAX_TRAVERSED_ITEMS: int = 4096

var _world: WorldState = null
var _hands: ActorHandEquipmentState = null
var _inventory: InventoryContainmentState = null
var _weight_query: ItemWeightQuery = null
var _carry_state: ActorCarryState = null

func _init(
    world_state: WorldState = null,
    hand_state: ActorHandEquipmentState = null,
    inventory_state: InventoryContainmentState = null,
    weight_query: ItemWeightQuery = null,
    carry_state: ActorCarryState = null
) -> void:
    _world = world_state
    _hands = hand_state
    _inventory = inventory_state
    _weight_query = weight_query
    _carry_state = carry_state

func query(actor_id: String) -> Dictionary:
    if _world == null or _hands == null or _inventory == null or _weight_query == null or _carry_state == null:
        return result(Status.UNKNOWN, 0, 0, 0, [], "carry_query_unconfigured")
    if not _world.has_entity(actor_id):
        return result(Status.UNKNOWN, 0, 0, 0, [], "actor_missing")
    var entity: WorldEntityRecord = _world.entity(actor_id)
    if entity == null or String(entity.semantic_type).strip_edges() != "actor.survivor":
        return result(Status.INVALID, 0, 0, 0, [], "not_survivor")
    if not _carry_state.has_actor(actor_id):
        return result(Status.UNKNOWN, 0, 0, 0, [], "carry_state_unclassified")
    if not _hands.has_actor(actor_id):
        return result(Status.UNKNOWN, 0, _carry_state.capacity_grams(actor_id), 0, [], "hands_unclassified")
    if not _inventory.has_container(actor_id):
        return result(Status.UNKNOWN, 0, _carry_state.capacity_grams(actor_id), 0, [], "personal_container_unclassified")

    var capacity: int = _carry_state.capacity_grams(actor_id)
    if capacity <= 0:
        return result(Status.INVALID, 0, capacity, 0, [], "capacity_invalid")

    var stack: Array[String] = []
    var primary: String = _hands.primary_item(actor_id)
    var secondary: String = _hands.secondary_item(actor_id)
    if not primary.is_empty():
        stack.append(primary)
    if not secondary.is_empty():
        stack.append(secondary)
    for item_id: String in _inventory.direct_contents(actor_id):
        stack.append(item_id)

    var visited: Dictionary = {}
    var counted: Array[String] = []
    var total_weight: int = 0

    while not stack.is_empty():
        var item_id: String = stack.pop_back()
        if visited.has(item_id):
            continue
        visited[item_id] = true
        if visited.size() > MAX_TRAVERSED_ITEMS:
            return result(Status.INVALID, 0, capacity, 0, counted, "carry_traversal_limit")

        var weight_result: Dictionary = _weight_query.query(item_id)
        var weight_status: int = int(weight_result.get("status", -1))
        if weight_status == ItemWeightQuery.Status.UNKNOWN:
            return result(Status.UNKNOWN, 0, capacity, 0, counted, "item_weight_unknown:%s" % item_id)
        if weight_status != ItemWeightQuery.Status.KNOWN:
            return result(Status.INVALID, 0, capacity, 0, counted, "item_weight_invalid:%s" % item_id)
        var item_weight: int = int(weight_result.get("weight_grams", 0))
        if item_weight <= 0:
            return result(Status.INVALID, 0, capacity, 0, counted, "item_weight_nonpositive:%s" % item_id)

        total_weight += item_weight
        counted.append(item_id)

        if _inventory.has_container(item_id):
            for child_id: String in _inventory.direct_contents(item_id):
                stack.append(child_id)

    counted.sort()
    var ratio_bp: int = int((total_weight * 10000) / capacity)
    return result(Status.KNOWN, total_weight, capacity, ratio_bp, counted, "")

static func result(
    status: int,
    weight_grams: int,
    capacity_grams: int,
    load_ratio_bp: int,
    item_ids: Array,
    reason: String
) -> Dictionary:
    return {
        "status": status,
        "weight_grams": weight_grams,
        "capacity_grams": capacity_grams,
        "load_ratio_bp": load_ratio_bp,
        "item_ids": item_ids.duplicate(),
        "reason": reason,
    }
