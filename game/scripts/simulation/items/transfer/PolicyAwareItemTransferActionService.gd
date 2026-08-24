extends "res://scripts/simulation/items/transfer/ItemTransferActionService.gd"
class_name PolicyAwareItemTransferActionService

const ActionTypesClass = preload("res://scripts/simulation/items/transfer/ItemTransferActionType.gd")
const DispositionResultClass = preload("res://scripts/simulation/items/transfer/ItemDispositionResult.gd")

## Additive System 12 implementation that preserves canonical personal-container access
## and optionally admits an external container policy. The base service remains unchanged
## and therefore retains its exact historical behavior when no policy-aware service is used.
##
## External-container acquisition also extends the existing carry-ceiling checks to the
## transitions that can newly add mass to personal possession:
## external container -> hand and external container -> personal container.

var _external_access_policy: ItemContainerAccessPolicy = null

func _init(
    world_state: WorldState = null,
    world_mutation_service: WorldMutationService = null,
    hand_state: ActorHandEquipmentState = null,
    hand_mutation_service: ActorHandEquipmentMutationService = null,
    containment_state: InventoryContainmentState = null,
    containment_mutation_service: InventoryContainmentMutationService = null,
    tick_kernel: TickKernel = null,
    timing_policy: ItemTransferTimingPolicy = null,
    disposition_query: ItemDispositionQuery = null,
    capacity_policy: ItemAcquisitionCapacityPolicy = null,
    external_access_policy: ItemContainerAccessPolicy = null
) -> void:
    super(
        world_state,
        world_mutation_service,
        hand_state,
        hand_mutation_service,
        containment_state,
        containment_mutation_service,
        tick_kernel,
        timing_policy,
        disposition_query,
        capacity_policy
    )
    _external_access_policy = external_access_policy

func is_ready() -> bool:
    if not super.is_ready():
        return false
    return _external_access_policy == null or _external_access_policy.is_ready()

## The base service intentionally names this helper around its original personal-only
## contract. Overriding it is the narrowest way to make all request-time, commit-time,
## and post-source-removal destination checks share one external access decision.
func _is_personal_container_accessible(actor_id: String, container_id: String) -> bool:
    if super._is_personal_container_accessible(actor_id, container_id):
        return true
    return _external_access_policy != null \
        and _external_access_policy.is_ready() \
        and _external_access_policy.can_access(actor_id, container_id)

func _begin_transfer(
    result: ItemTransferActionResult,
    actor_placement: WorldPlacement,
    source: ItemDispositionResult,
    extra_payload: Dictionary
) -> ItemTransferActionResult:
    ## The base service already checks capacity for loose-world acquisition. This adds
    ## the two newly meaningful external-container acquisition paths before any ticks
    ## are scheduled.
    if source != null \
        and source.status == DispositionResultClass.Status.CONTAINED \
        and _request_adds_personal_mass(result.action_type, result.actor_id, source.container_id, extra_payload):
        if not _validate_capacity_for_acquisition(result):
            return result
    return super._begin_transfer(result, actor_placement, source, extra_payload)

func _perform_commit(action: TimedAction, actor_placement: WorldPlacement) -> void:
    if action == null:
        return
    var payload: Dictionary = action.payload
    if not _payload_adds_personal_mass(action.action_type, action.actor_id, payload):
        super._perform_commit(action, actor_placement)
        return

    var item_id: String = String(payload.get("item_id", ""))
    var capacity: Dictionary = _capacity_policy.evaluate(action.actor_id, item_id)
    if not _capacity_allows(capacity):
        _fail_action(action, _capacity_reason(capacity))
        return

    ## Container -> container is one atomic System 11 relation mutation. There is no
    ## externally visible source-removal gap, so the immediate pre-commit check above
    ## is sufficient and the inherited commit path remains authoritative.
    if action.action_type == ActionTypesClass.CONTAINER_TO_CONTAINER:
        super._perform_commit(action, actor_placement)
        return

    ## Container -> hand is a two-mutation path. Preserve System 12's existing
    ## reentrant hardening by checking capacity again after source removal and using
    ## the same compensation/critical-consistency behavior as the base service.
    if action.action_type != ActionTypesClass.CONTAINER_TO_HAND:
        super._perform_commit(action, actor_placement)
        return

    if not _remove_source(action.action_type, payload, item_id):
        _fail_action(action, "source_mutation_failed")
        return

    capacity = _capacity_policy.evaluate(action.actor_id, item_id)
    if not _capacity_allows(capacity):
        var compensated_capacity: bool = _restore_source(payload, item_id)
        if compensated_capacity:
            _fail_action(action, _capacity_reason(capacity))
        else:
            _append_diagnostic(action, item_id, "critical_consistency_failure", true)
            _fail_action(action, "critical_consistency_failure")
        return

    if not _add_destination(action.action_type, payload, item_id, actor_placement, action.actor_id):
        var compensated: bool = _restore_source(payload, item_id)
        if compensated:
            _append_diagnostic(action, item_id, "destination_mutation_failed_compensated", false)
            _fail_action(action, "destination_mutation_failed_compensated")
        else:
            _append_diagnostic(action, item_id, "critical_consistency_failure", true)
            _fail_action(action, "critical_consistency_failure")
        return

    _emit_commit(action)

func _request_adds_personal_mass(
    action_type: StringName,
    actor_id: String,
    source_container_id: String,
    extra_payload: Dictionary
) -> bool:
    if _base_personal_access(actor_id, source_container_id):
        return false
    match action_type:
        ActionTypesClass.CONTAINER_TO_HAND:
            return true
        ActionTypesClass.CONTAINER_TO_CONTAINER:
            return _base_personal_access(
                actor_id,
                String(extra_payload.get("destination_container_id", ""))
            )
        _:
            return false

func _payload_adds_personal_mass(
    action_type: StringName,
    actor_id: String,
    payload: Dictionary
) -> bool:
    var source_container_id: String = String(payload.get("source_container_id", ""))
    if source_container_id.is_empty() or _base_personal_access(actor_id, source_container_id):
        return false
    match action_type:
        ActionTypesClass.CONTAINER_TO_HAND:
            return true
        ActionTypesClass.CONTAINER_TO_CONTAINER:
            return _base_personal_access(
                actor_id,
                String(payload.get("destination_container_id", ""))
            )
        _:
            return false

func _base_personal_access(actor_id: String, container_id: String) -> bool:
    if container_id.is_empty():
        return false
    return super._is_personal_container_accessible(actor_id, container_id)
