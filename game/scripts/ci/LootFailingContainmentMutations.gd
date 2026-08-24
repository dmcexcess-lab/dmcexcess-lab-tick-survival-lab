extends "res://scripts/simulation/inventory/InventoryContainmentMutationService.gd"
class_name LootFailingContainmentMutations

## CI-only deterministic fault injector used to prove System 24 rollback after
## mutation has already begun. Production never imports this class.

var _fail_on_set_call: int = -1
var _set_calls: int = 0

func _init(
    containment_state: InventoryContainmentState = null,
    world_state: WorldState = null,
    fail_on_set_call: int = -1
) -> void:
    super(containment_state, world_state)
    _fail_on_set_call = fail_on_set_call

func set_container(item_id: String, container_id: String) -> bool:
    _set_calls += 1
    if _set_calls == _fail_on_set_call:
        return false
    return super.set_container(item_id, container_id)
