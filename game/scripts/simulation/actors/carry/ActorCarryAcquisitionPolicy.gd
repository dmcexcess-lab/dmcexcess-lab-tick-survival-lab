extends "res://scripts/simulation/items/ItemAcquisitionCapacityPolicy.gd"
class_name ActorCarryAcquisitionPolicy

## 13E admission policy for adding a loose item subtree to personal possession.
## Soft capacity remains the encumbrance threshold; the hard ceiling is 2x capacity.

var _carry_query: ActorCarryQuery = null

func _init(carry_query: ActorCarryQuery = null) -> void:
    _carry_query = carry_query

func is_ready() -> bool:
    return _carry_query != null

func evaluate(actor_id: String, item_id: String) -> Dictionary:
    if _carry_query == null:
        return decision(Status.UNKNOWN, 0, 0, "carry_query_unconfigured")

    var carry: Dictionary = _carry_query.query(actor_id)
    if int(carry.get("status", -1)) != ActorCarryQuery.Status.KNOWN:
        return decision(
            Status.UNKNOWN,
            0,
            int(carry.get("hard_limit_grams", 0)),
            String(carry.get("reason", "carry_unknown"))
        )

    var incoming: Dictionary = _carry_query.query_item_tree(item_id)
    if int(incoming.get("status", -1)) != ActorCarryQuery.Status.KNOWN:
        return decision(
            Status.UNKNOWN,
            int(carry.get("weight_grams", 0)),
            int(carry.get("hard_limit_grams", 0)),
            String(incoming.get("reason", "incoming_weight_unknown"))
        )

    var carried_ids: Array = carry.get("item_ids", [])
    for incoming_id: Variant in incoming.get("item_ids", []):
        if carried_ids.has(String(incoming_id)):
            return decision(
                Status.UNKNOWN,
                int(carry.get("weight_grams", 0)),
                int(carry.get("hard_limit_grams", 0)),
                "incoming_item_already_counted:%s" % String(incoming_id)
            )

    var current_weight: int = int(carry.get("weight_grams", 0))
    var incoming_weight: int = int(incoming.get("weight_grams", 0))
    var hard_limit: int = int(carry.get("hard_limit_grams", 0))
    if current_weight < 0 or incoming_weight <= 0 or hard_limit <= 0:
        return decision(Status.UNKNOWN, current_weight, hard_limit, "carry_capacity_invalid")

    var projected: int = current_weight + incoming_weight
    if projected > hard_limit:
        return decision(Status.BLOCKED, projected, hard_limit, "absolute_carry_limit_exceeded")
    return decision(Status.ALLOWED, projected, hard_limit, "")
