extends RefCounted
class_name ActorInventoryInspectorQuery

## Read-only System 16 inventory/loadout inspection over WHAT + 09 + 11 + 13D/13E.
## It preserves stable item identity and never mutates possession state.

const MAX_DEPTH: int = 64
const MAX_ITEMS: int = 4096

var _world: WorldState = null
var _hands: ActorHandEquipmentState = null
var _inventory: InventoryContainmentState = null
var _weight_query: ItemWeightQuery = null
var _carry_query: ActorCarryQuery = null

func _init(
    world_state: WorldState = null,
    hand_state: ActorHandEquipmentState = null,
    inventory_state: InventoryContainmentState = null,
    weight_query: ItemWeightQuery = null,
    carry_query: ActorCarryQuery = null
) -> void:
    _world = world_state
    _hands = hand_state
    _inventory = inventory_state
    _weight_query = weight_query
    _carry_query = carry_query

func is_ready() -> bool:
    return _world != null \
        and _hands != null \
        and _inventory != null \
        and _weight_query != null \
        and _carry_query != null

func query(actor_id: String) -> Dictionary:
    var normalized: String = actor_id.strip_edges()
    if not is_ready() or normalized.is_empty():
        return _failure("inventory_query_not_ready")
    if not _world.has_entity(normalized):
        return _failure("actor_missing")
    var actor: WorldEntityRecord = _world.entity(normalized)
    if actor == null or String(actor.semantic_type) != "actor.survivor":
        return _failure("not_survivor")
    if not _hands.has_actor(normalized):
        return _failure("hands_unclassified")
    if not _inventory.has_container(normalized):
        return _failure("personal_container_unclassified")

    var visited: Dictionary = {}
    var count_ref: Array[int] = [0]
    var primary_id: String = _hands.primary_item(normalized)
    var secondary_id: String = _hands.secondary_item(normalized)
    var primary: Dictionary = _empty_hand("Right Hand", "primary_right")
    var secondary: Dictionary = _empty_hand("Left Hand", "secondary_left")
    if not primary_id.is_empty():
        primary = _hand_entry("Right Hand", "primary_right", primary_id, visited, count_ref)
    if not secondary_id.is_empty():
        secondary = _hand_entry("Left Hand", "secondary_left", secondary_id, visited, count_ref)

    var root_entries: Array = []
    for item_id: String in _inventory.direct_contents(normalized):
        root_entries.append(_item_entry(item_id, 0, visited, count_ref))

    return {
        "ok": true,
        "reason": "",
        "actor_id": normalized,
        "primary_hand": primary,
        "secondary_hand": secondary,
        "inventory": root_entries,
        "carry": _carry_query.query(normalized).duplicate(true),
    }

func _hand_entry(
    hand_label: String,
    slot_name: String,
    item_id: String,
    visited: Dictionary,
    count_ref: Array[int]
) -> Dictionary:
    var value: Dictionary = {
        "hand_label": hand_label,
        "slot": slot_name,
        "empty": false,
        "item": _item_entry(item_id, 0, visited, count_ref),
    }
    return value

static func _empty_hand(hand_label: String, slot_name: String) -> Dictionary:
    return {
        "hand_label": hand_label,
        "slot": slot_name,
        "empty": true,
        "item": {},
    }

func _item_entry(
    item_id: String,
    depth: int,
    visited: Dictionary,
    count_ref: Array[int]
) -> Dictionary:
    var base: Dictionary = {
        "item_id": item_id,
        "semantic_type": &"",
        "label": "Unknown Item",
        "valid": false,
        "reason": "",
        "weight_known": false,
        "weight_grams": 0,
        "children": [],
    }
    if item_id.is_empty():
        base["reason"] = "empty_item_id"
        return base
    if depth > MAX_DEPTH:
        base["reason"] = "containment_depth_limit"
        return base
    if visited.has(item_id):
        base["reason"] = "containment_cycle_or_duplicate"
        return base
    if count_ref[0] >= MAX_ITEMS:
        base["reason"] = "inventory_traversal_limit"
        return base

    visited[item_id] = true
    count_ref[0] += 1
    if not _world.has_entity(item_id):
        base["reason"] = "item_missing"
        return base
    var entity: WorldEntityRecord = _world.entity(item_id)
    if entity == null:
        base["reason"] = "item_missing"
        return base
    var semantic: String = String(entity.semantic_type).strip_edges()
    base["semantic_type"] = entity.semantic_type
    base["label"] = _item_label(semantic)
    if not semantic.begins_with("item.") or semantic.length() <= 5:
        base["reason"] = "not_item_entity"
        return base

    base["valid"] = true
    var weight: Dictionary = _weight_query.query(item_id)
    if int(weight.get("status", -1)) == ItemWeightQuery.Status.KNOWN:
        base["weight_known"] = true
        base["weight_grams"] = int(weight.get("weight_grams", 0))
    else:
        base["reason"] = String(weight.get("reason", "weight_unknown"))

    var children: Array = []
    if _inventory.has_container(item_id):
        for child_id: String in _inventory.direct_contents(item_id):
            children.append(_item_entry(child_id, depth + 1, visited, count_ref))
    base["children"] = children
    return base

static func _failure(reason: String) -> Dictionary:
    return {
        "ok": false,
        "reason": reason,
        "actor_id": "",
        "primary_hand": {},
        "secondary_hand": {},
        "inventory": [],
        "carry": {},
    }

static func _item_label(semantic_type: String) -> String:
    var value: String = semantic_type.strip_edges()
    if value.begins_with("item."):
        value = value.substr(5)
    value = value.replace("_", " ").replace(".", " ")
    if value.is_empty():
        return "Unknown Item"
    return value.capitalize()
