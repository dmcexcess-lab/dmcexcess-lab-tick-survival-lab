extends RefCounted
class_name ItemAcquisitionCapacityPolicy

## Narrow read-only policy seam for actions that add a physical item subtree
## to an actor's personal possession. Concrete capacity domains decide legality.

enum Status {
    ALLOWED,
    BLOCKED,
    UNKNOWN,
}

func is_ready() -> bool:
    return false

func evaluate(_actor_id: String, _item_id: String) -> Dictionary:
    return decision(Status.UNKNOWN, 0, 0, "capacity_policy_unconfigured")

static func decision(
    status: int,
    projected_weight_grams: int = 0,
    hard_limit_grams: int = 0,
    reason: String = ""
) -> Dictionary:
    return {
        "status": status,
        "projected_weight_grams": projected_weight_grams,
        "hard_limit_grams": hard_limit_grams,
        "reason": reason,
    }

static func is_valid_status(value: int) -> bool:
    return value >= Status.ALLOWED and value <= Status.UNKNOWN
