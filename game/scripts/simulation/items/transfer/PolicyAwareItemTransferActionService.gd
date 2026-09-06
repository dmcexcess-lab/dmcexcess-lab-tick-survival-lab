extends "res://scripts/simulation/items/transfer/ItemTransferActionService.gd"
class_name PolicyAwareItemTransferActionService

const ActionTypesClass = preload("res://scripts/simulation/items/transfer/ItemTransferActionType.gd")
const DispositionResultClass = preload("res://scripts/simulation/items/transfer/ItemDispositionResult.gd")
const TransferResultClass = preload("res://scripts/simulation/items/transfer/ItemTransferActionResult.gd")
const SKATEBOARD_SEMANTIC := &"item.vehicle.skateboard"

## Policy-aware transfer service. External containers preserve the base transfer contract,
## while oversized skateboard items are explicitly barred from personal/backpack containment.

var _external_access_policy: ItemContainerAccessPolicy = null

func _init(world_state: WorldState = null, world_mutation_service: WorldMutationService = null, hand_state: ActorHandEquipmentState = null, hand_mutation_service: ActorHandEquipmentMutationService = null, containment_state: InventoryContainmentState = null, containment_mutation_service: InventoryContainmentMutationService = null, tick_kernel: TickKernel = null, timing_policy: ItemTransferTimingPolicy = null, disposition_query: ItemDispositionQuery = null, capacity_policy: ItemAcquisitionCapacityPolicy = null, external_access_policy: ItemContainerAccessPolicy = null) -> void:
    super(world_state, world_mutation_service, hand_state, hand_mutation_service, containment_state, containment_mutation_service, tick_kernel, timing_policy, disposition_query, capacity_policy)
    _external_access_policy = external_access_policy

func is_ready() -> bool:
    if not super.is_ready(): return false
    return _external_access_policy == null or _external_access_policy.is_ready()

func request_pickup_to_container(actor_id: String, item_id: String, destination_container_id: String) -> ItemTransferActionResult:
    if _blocks_personal_skateboard(actor_id, item_id, destination_container_id):
        return _skateboard_container_rejection(ActionTypesClass.WORLD_TO_CONTAINER, actor_id, item_id)
    return super.request_pickup_to_container(actor_id, item_id, destination_container_id)

func request_unequip_to_container(actor_id: String, slot: int, destination_container_id: String) -> ItemTransferActionResult:
    var item_id := _hands.item_in_slot(actor_id, slot) if _hands != null else ""
    if _blocks_personal_skateboard(actor_id, item_id, destination_container_id):
        return _skateboard_container_rejection(ActionTypesClass.HAND_TO_CONTAINER, actor_id, item_id)
    return super.request_unequip_to_container(actor_id, slot, destination_container_id)

func request_transfer_container(actor_id: String, item_id: String, destination_container_id: String) -> ItemTransferActionResult:
    if _blocks_personal_skateboard(actor_id, item_id, destination_container_id):
        return _skateboard_container_rejection(ActionTypesClass.CONTAINER_TO_CONTAINER, actor_id, item_id)
    return super.request_transfer_container(actor_id, item_id, destination_container_id)

func _blocks_personal_skateboard(actor_id: String, item_id: String, destination_container_id: String) -> bool:
    if item_id.is_empty() or destination_container_id.is_empty() or not _base_personal_access(actor_id, destination_container_id): return false
    var entity := _world.entity(item_id) if _world != null else null
    return entity != null and entity.semantic_type == SKATEBOARD_SEMANTIC

func _skateboard_container_rejection(action_type: StringName, actor_id: String, item_id: String) -> ItemTransferActionResult:
    var result := _new_result(action_type, actor_id, item_id)
    return _reject(result, TransferResultClass.Status.CONTAINER_REJECTED, "skateboard_requires_hand_or_back")

func _is_personal_container_accessible(actor_id: String, container_id: String) -> bool:
    if super._is_personal_container_accessible(actor_id, container_id): return true
    return _external_access_policy != null and _external_access_policy.is_ready() and _external_access_policy.can_access(actor_id, container_id)

func _begin_transfer(result: ItemTransferActionResult, actor_placement: WorldPlacement, source: ItemDispositionResult, extra_payload: Dictionary) -> ItemTransferActionResult:
    if source != null and source.status == DispositionResultClass.Status.CONTAINED and _request_adds_personal_mass(result.action_type, result.actor_id, source.container_id, extra_payload):
        if not _validate_capacity_for_acquisition(result): return result
    return super._begin_transfer(result, actor_placement, source, extra_payload)

func _perform_commit(action: TimedAction, actor_placement: WorldPlacement) -> void:
    if action == null: return
    var payload: Dictionary = action.payload
    if not _payload_adds_personal_mass(action.action_type, action.actor_id, payload):
        super._perform_commit(action, actor_placement)
        return
    var item_id := String(payload.get("item_id", ""))
    var capacity := _capacity_policy.evaluate(action.actor_id, item_id)
    if not _capacity_allows(capacity):
        _fail_action(action, _capacity_reason(capacity))
        return
    if action.action_type == ActionTypesClass.CONTAINER_TO_CONTAINER:
        super._perform_commit(action, actor_placement)
        return
    if action.action_type != ActionTypesClass.CONTAINER_TO_HAND:
        super._perform_commit(action, actor_placement)
        return
    if not _remove_source(action.action_type, payload, item_id):
        _fail_action(action, "source_mutation_failed")
        return
    capacity = _capacity_policy.evaluate(action.actor_id, item_id)
    if not _capacity_allows(capacity):
        var compensated_capacity := _restore_source(payload, item_id)
        if compensated_capacity: _fail_action(action, _capacity_reason(capacity))
        else:
            _append_diagnostic(action, item_id, "critical_consistency_failure", true)
            _fail_action(action, "critical_consistency_failure")
        return
    if not _add_destination(action.action_type, payload, item_id, actor_placement, action.actor_id):
        var compensated := _restore_source(payload, item_id)
        if compensated:
            _append_diagnostic(action, item_id, "destination_mutation_failed_compensated", false)
            _fail_action(action, "destination_mutation_failed_compensated")
        else:
            _append_diagnostic(action, item_id, "critical_consistency_failure", true)
            _fail_action(action, "critical_consistency_failure")
        return
    _emit_commit(action)

func _request_adds_personal_mass(action_type: StringName, actor_id: String, source_container_id: String, extra_payload: Dictionary) -> bool:
    if _base_personal_access(actor_id, source_container_id): return false
    match action_type:
        ActionTypesClass.CONTAINER_TO_HAND: return true
        ActionTypesClass.CONTAINER_TO_CONTAINER: return _base_personal_access(actor_id, String(extra_payload.get("destination_container_id", "")))
        _: return false

func _payload_adds_personal_mass(action_type: StringName, actor_id: String, payload: Dictionary) -> bool:
    var source_container_id := String(payload.get("source_container_id", ""))
    if source_container_id.is_empty() or _base_personal_access(actor_id, source_container_id): return false
    match action_type:
        ActionTypesClass.CONTAINER_TO_HAND: return true
        ActionTypesClass.CONTAINER_TO_CONTAINER: return _base_personal_access(actor_id, String(payload.get("destination_container_id", "")))
        _: return false

func _base_personal_access(actor_id: String, container_id: String) -> bool:
    if container_id.is_empty(): return false
    return super._is_personal_container_accessible(actor_id, container_id)
