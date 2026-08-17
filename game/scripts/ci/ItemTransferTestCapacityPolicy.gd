extends "res://scripts/simulation/items/ItemAcquisitionCapacityPolicy.gd"
class_name ItemTransferTestCapacityPolicy

## CI-only permissive provider for testing System 12 mechanics independently
## from a concrete carry domain. Cross-system capacity behavior has its own smoke.

func is_ready() -> bool:
    return true

func evaluate(_actor_id: String, _item_id: String) -> Dictionary:
    return decision(Status.ALLOWED, 0, 2147483647, "")
