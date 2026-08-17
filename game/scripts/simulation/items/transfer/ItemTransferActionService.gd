extends RefCounted
class_name ItemTransferActionService

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const PlacementClass = preload("res://scripts/foundation/world/WorldPlacement.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const ActionTypes = preload("res://scripts/simulation/items/transfer/ItemTransferActionType.gd")
const DispositionClass = preload("res://scripts/simulation/items/transfer/ItemDispositionResult.gd")
const DispositionQueryClass = preload("res://scripts/simulation/items/transfer/ItemDispositionQuery.gd")
const TimingDecisionClass = preload("res://scripts/simulation/items/transfer/ItemTransferTimingDecision.gd")
const ResultClass = preload("res://scripts/simulation/items/transfer/ItemTransferActionResult.gd")
const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRulesClass = preload("res://scripts/foundation/time/TickRules.gd")

signal item_transfer_committed(actor_id, action_serial, action_type, item_id, source_kind, destination_kind)
signal item_transfer_failed(actor_id, action_serial, action_type, item_id, reason)
signal item_transfer_canceled(actor_id, action_serial, action_type, item_id, reason)

const COMMIT_PHASE: StringName = &"item_transfer.commit"
const DIAGNOSTIC_LIMIT: int = 64
const ANCESTRY_LIMIT: int = 128

var _world: WorldState = null
var _world_mutations: WorldMutationService = null
var _hands: ActorHandEquipmentState = null
var _hand_mutations: ActorHandEquipmentMutationService = null
var _containment: InventoryContainmentState = null
var _containment_mutations: InventoryContainmentMutationService = null
var _kernel: TickKernel = null
var _policy: ItemTransferTimingPolicy = null
var _disposition: ItemDispositionQuery = null
var _diagnostics: Array[Dictionary] = []

func _init(
    world_state: WorldState = null,
    world_mutation_service: WorldMutationService = null,
    hand_state: ActorHandEquipmentState = null,
    hand_mutation_service: ActorHandEquipmentMutationService = null,
    containment_state: InventoryContainmentState = null,
    containment_mutation_service: InventoryContainmentMutationService = null,
    tick_kernel: TickKernel = null,
    timing_policy: ItemTransferTimingPolicy = null,
    disposition_query: ItemDispositionQuery = null
) -> void:
    _world = world_state
    _world_mutations = world_mutation_service
    _hands = hand_state
    _hand_mutations = hand_mutation_service
    _containment = containment_state
    _containment_mutations = containment_mutation_service
    _kernel = tick_kernel
    _policy = timing_policy
    _disposition = disposition_query
    if _disposition == null and _world != null and _hands != null and _containment != null:
        _disposition = DispositionQueryClass.new(_world, _hands, _containment)
    if _kernel != null:
        if not _kernel.action_phase.is_connected(_on_action_phase):
            _kernel.action_phase.connect(_on_action_phase)
        if not _kernel.action_finished.is_connected(_on_action_finished):
            _kernel.action_finished.connect(_on_action_finished)

func is_ready() -> bool:
    return _world != null \
        and _world_mutations != null and _world_mutations.is_ready() \
        and _hands != null \
        and _hand_mutations != null and _hand_mutations.is_ready() \
        and _containment != null \
        and _containment_mutations != null and _containment_mutations.is_ready() \
        and _kernel != null \
        and _policy != null \
        and _disposition != null and _disposition.is_ready()

func recent_diagnostics() -> Array[Dictionary]:
    return _diagnostics.duplicate(true)

func request_pickup_to_container(
    actor_id: String,
    item_id: String,
    destination_container_id: String
) -> ItemTransferActionResult:
    var result: ItemTransferActionResult = _new_result(ActionTypes.WORLD_TO_CONTAINER, actor_id, item_id)
    var actor_placement: WorldPlacement = _validate_actor(result)
    if actor_placement == null:
        return result
    var source: ItemDispositionResult = _disposition.query(result.item_id)
    if not _require_source(result, source, DispositionClass.Status.LOOSE_WORLD):
        return result
    if not _loose_item_reachable(actor_placement, source.placement):
        return _reject(result, ResultClass.Status.OUT_OF_REACH, "out_of_reach")
    if not _validate_destination_container(result, result.actor_id, destination_container_id):
        return result
    var extra: Dictionary = {
        "destination_container_id": destination_container_id,
        "destination_container_version": _containment.container_version(destination_container_id),
    }
    return _begin_transfer(result, actor_placement, source, extra)

func request_pickup_to_hand(actor_id: String, item_id: String, slot: int) -> ItemTransferActionResult:
    var result: ItemTransferActionResult = _new_result(ActionTypes.WORLD_TO_HAND, actor_id, item_id)
    result.destination_slot = slot
    var actor_placement: WorldPlacement = _validate_actor(result)
    if actor_placement == null:
        return result
    var source: ItemDispositionResult = _disposition.query(result.item_id)
    if not _require_source(result, source, DispositionClass.Status.LOOSE_WORLD):
        return result
    if not _loose_item_reachable(actor_placement, source.placement):
        return _reject(result, ResultClass.Status.OUT_OF_REACH, "out_of_reach")
    if not _validate_target_hand(result, result.actor_id, slot):
        return result
    var extra: Dictionary = {
        "destination_slot": slot,
        "expected_hand_version": _hands.version(result.actor_id),
    }
    return _begin_transfer(result, actor_placement, source, extra)

func request_drop_from_container(actor_id: String, item_id: String) -> ItemTransferActionResult:
    var result: ItemTransferActionResult = _new_result(ActionTypes.CONTAINER_TO_WORLD, actor_id, item_id)
    var actor_placement: WorldPlacement = _validate_actor(result)
    if actor_placement == null:
        return result
    var source: ItemDispositionResult = _disposition.query(result.item_id)
    if not _require_source(result, source, DispositionClass.Status.CONTAINED):
        return result
    if not _validate_source_container_access(result, result.actor_id, source.container_id):
        return result
    var extra: Dictionary = {
        "source_container_id": source.container_id,
        "source_container_version": _containment.container_version(source.container_id),
    }
    return _begin_transfer(result, actor_placement, source, extra)

func request_drop_from_hand(actor_id: String, slot: int) -> ItemTransferActionResult:
    var result: ItemTransferActionResult = _new_result(ActionTypes.HAND_TO_WORLD, actor_id, "")
    var actor_placement: WorldPlacement = _validate_actor(result)
    if actor_placement == null:
        return result
    if not _hands.has_actor(result.actor_id):
        return _reject(result, ResultClass.Status.HAND_STATE_UNKNOWN, "hand_state_unknown")
    if not Slots.is_valid(slot):
        return _reject(result, ResultClass.Status.INVALID_SLOT, "invalid_slot")
    var item_id: String = _hands.item_in_slot(result.actor_id, slot)
    if item_id.is_empty():
        return _reject(result, ResultClass.Status.SOURCE_MISMATCH, "hand_empty")
    result.item_id = item_id
    var source: ItemDispositionResult = _disposition.query(item_id)
    if not _require_source(result, source, DispositionClass.Status.HAND):
        return result
    if source.actor_id != result.actor_id or source.slot != slot:
        return _reject(result, ResultClass.Status.SOURCE_MISMATCH, "hand_source_mismatch")
    var extra: Dictionary = {
        "source_actor_id": result.actor_id,
        "source_slot": slot,
        "expected_hand_version": _hands.version(result.actor_id),
    }
    return _begin_transfer(result, actor_placement, source, extra)

func request_equip_from_container(actor_id: String, item_id: String, slot: int) -> ItemTransferActionResult:
    var result: ItemTransferActionResult = _new_result(ActionTypes.CONTAINER_TO_HAND, actor_id, item_id)
    result.destination_slot = slot
    var actor_placement: WorldPlacement = _validate_actor(result)
    if actor_placement == null:
        return result
    var source: ItemDispositionResult = _disposition.query(result.item_id)
    if not _require_source(result, source, DispositionClass.Status.CONTAINED):
        return result
    if not _validate_source_container_access(result, result.actor_id, source.container_id):
        return result
    if not _validate_target_hand(result, result.actor_id, slot):
        return result
    var extra: Dictionary = {
        "source_container_id": source.container_id,
        "source_container_version": _containment.container_version(source.container_id),
        "destination_slot": slot,
        "expected_hand_version": _hands.version(result.actor_id),
    }
    return _begin_transfer(result, actor_placement, source, extra)

func request_unequip_to_container(
    actor_id: String,
    slot: int,
    destination_container_id: String
) -> ItemTransferActionResult:
    var result: ItemTransferActionResult = _new_result(ActionTypes.HAND_TO_CONTAINER, actor_id, "")
    result.destination_slot = slot
    var actor_placement: WorldPlacement = _validate_actor(result)
    if actor_placement == null:
        return result
    if not _hands.has_actor(result.actor_id):
        return _reject(result, ResultClass.Status.HAND_STATE_UNKNOWN, "hand_state_unknown")
    if not Slots.is_valid(slot):
        return _reject(result, ResultClass.Status.INVALID_SLOT, "invalid_slot")
    var item_id: String = _hands.item_in_slot(result.actor_id, slot)
    if item_id.is_empty():
        return _reject(result, ResultClass.Status.SOURCE_MISMATCH, "hand_empty")
    result.item_id = item_id
    var source: ItemDispositionResult = _disposition.query(item_id)
    if not _require_source(result, source, DispositionClass.Status.HAND):
        return result
    if source.actor_id != result.actor_id or source.slot != slot:
        return _reject(result, ResultClass.Status.SOURCE_MISMATCH, "hand_source_mismatch")
    if not _validate_destination_container(result, result.actor_id, destination_container_id):
        return result
    var extra: Dictionary = {
        "source_actor_id": result.actor_id,
        "source_slot": slot,
        "expected_hand_version": _hands.version(result.actor_id),
        "destination_container_id": destination_container_id,
        "destination_container_version": _containment.container_version(destination_container_id),
    }
    return _begin_transfer(result, actor_placement, source, extra)

func request_transfer_container(
    actor_id: String,
    item_id: String,
    destination_container_id: String
) -> ItemTransferActionResult:
    var result: ItemTransferActionResult = _new_result(ActionTypes.CONTAINER_TO_CONTAINER, actor_id, item_id)
    var actor_placement: WorldPlacement = _validate_actor(result)
    if actor_placement == null:
        return result
    var source: ItemDispositionResult = _disposition.query(result.item_id)
    if not _require_source(result, source, DispositionClass.Status.CONTAINED):
        return result
    if not _validate_source_container_access(result, result.actor_id, source.container_id):
        return result
    if source.container_id == destination_container_id:
        return _reject(result, ResultClass.Status.SOURCE_MISMATCH, "same_container")
    if not _validate_destination_container(result, result.actor_id, destination_container_id):
        return result
    if _would_create_cycle(result.item_id, destination_container_id):
        return _reject(result, ResultClass.Status.CONTAINER_REJECTED, "containment_cycle")
    var extra: Dictionary = {
        "source_container_id": source.container_id,
        "source_container_version": _containment.container_version(source.container_id),
        "destination_container_id": destination_container_id,
        "destination_container_version": _containment.container_version(destination_container_id),
    }
    return _begin_transfer(result, actor_placement, source, extra)

func _new_result(action_type: StringName, actor_id: String, item_id: String) -> ItemTransferActionResult:
    var result := ResultClass.new()
    result.action_type = action_type
    result.actor_id = actor_id.strip_edges()
    result.item_id = item_id.strip_edges()
    result.source_kind = ActionTypes.source_kind(action_type)
    result.destination_kind = ActionTypes.destination_kind(action_type)
    return result

func _validate_actor(result: ItemTransferActionResult) -> WorldPlacement:
    if not is_ready():
        _reject(result, ResultClass.Status.NOT_READY, "item_transfer_not_ready")
        return null
    if result.actor_id.is_empty() or not _world.has_entity(result.actor_id):
        _reject(result, ResultClass.Status.ACTOR_MISSING, "actor_missing")
        return null
    var entity: WorldEntityRecord = _world.entity(result.actor_id)
    if entity == null or String(entity.semantic_type).strip_edges() != "actor.survivor":
        _reject(result, ResultClass.Status.NOT_SURVIVOR, "not_survivor")
        return null
    if not _world.has_placement(result.actor_id):
        _reject(result, ResultClass.Status.ACTOR_UNPLACED, "actor_unplaced")
        return null
    var placement: WorldPlacement = _world.placement(result.actor_id)
    if placement == null or placement.channel != Layers.Channel.ACTOR:
        _reject(result, ResultClass.Status.ACTOR_UNPLACED, "actor_unplaced")
        return null
    if _kernel.has_active_action(result.actor_id):
        _reject(result, ResultClass.Status.BUSY, "actor_busy")
        return null
    return placement

func _require_source(
    result: ItemTransferActionResult,
    source: ItemDispositionResult,
    expected_status: int
) -> bool:
    if source == null:
        _reject(result, ResultClass.Status.ITEM_MISSING, "item_missing")
        return false
    if source.status == DispositionClass.Status.UNKNOWN:
        if source.reason == "not_item":
            _reject(result, ResultClass.Status.NOT_ITEM, source.reason)
        else:
            _reject(result, ResultClass.Status.ITEM_MISSING, source.reason)
        return false
    if source.status == DispositionClass.Status.CONFLICT:
        _reject(result, ResultClass.Status.DISPOSITION_CONFLICT, source.reason)
        return false
    if source.status == DispositionClass.Status.INVALID_PLACEMENT:
        _reject(result, ResultClass.Status.SOURCE_MISMATCH, source.reason)
        return false
    if source.status != expected_status:
        _reject(result, ResultClass.Status.SOURCE_MISMATCH, "source_mismatch")
        return false
    return true

func _validate_target_hand(result: ItemTransferActionResult, actor_id: String, slot: int) -> bool:
    if not _hands.has_actor(actor_id):
        _reject(result, ResultClass.Status.HAND_STATE_UNKNOWN, "hand_state_unknown")
        return false
    if not Slots.is_valid(slot):
        _reject(result, ResultClass.Status.INVALID_SLOT, "invalid_slot")
        return false
    if not _hands.item_in_slot(actor_id, slot).is_empty():
        _reject(result, ResultClass.Status.HAND_OCCUPIED, "hand_occupied")
        return false
    return true

func _validate_destination_container(
    result: ItemTransferActionResult,
    actor_id: String,
    container_id: String
) -> bool:
    result.destination_container_id = container_id
    if not _containment.has_container(container_id) or not _world.has_entity(container_id):
        _reject(result, ResultClass.Status.CONTAINER_UNKNOWN, "container_unknown")
        return false
    if not _is_personal_container_accessible(actor_id, container_id):
        _reject(result, ResultClass.Status.CONTAINER_INACCESSIBLE, "container_inaccessible")
        return false
    return true

func _validate_source_container_access(
    result: ItemTransferActionResult,
    actor_id: String,
    container_id: String
) -> bool:
    if not _containment.has_container(container_id) or not _world.has_entity(container_id):
        _reject(result, ResultClass.Status.CONTAINER_UNKNOWN, "container_unknown")
        return false
    if not _is_personal_container_accessible(actor_id, container_id):
        _reject(result, ResultClass.Status.CONTAINER_INACCESSIBLE, "container_inaccessible")
        return false
    return true

func _begin_transfer(
    result: ItemTransferActionResult,
    actor_placement: WorldPlacement,
    source: ItemDispositionResult,
    extra_payload: Dictionary
) -> ItemTransferActionResult:
    var timing: ItemTransferTimingDecision = _policy.evaluate(result.actor_id, result.action_type)
    if timing == null or not timing.is_allowed():
        return _reject_for_timing(result, timing)

    var payload: Dictionary = {
        "actor_placement": actor_placement.to_snapshot(),
        "item_id": result.item_id,
        "item_semantic_type": String(source.semantic_type),
        "expected_source_status": source.status,
        "source_kind": String(result.source_kind),
        "destination_kind": String(result.destination_kind),
    }
    if source.status == DispositionClass.Status.LOOSE_WORLD and source.placement != null:
        payload["source_placement"] = source.placement.to_snapshot()
    if source.status == DispositionClass.Status.HAND:
        payload["source_actor_id"] = source.actor_id
        payload["source_slot"] = source.slot
    if source.status == DispositionClass.Status.CONTAINED:
        payload["source_container_id"] = source.container_id
    for key: Variant in extra_payload.keys():
        payload[key] = extra_payload[key]

    var phases: Array[ActionPhase] = [PhaseClass.new(COMMIT_PHASE, timing.duration_ticks)]
    var action_serial: int = _kernel.begin_action(
        result.actor_id,
        result.action_type,
        timing.duration_ticks,
        TickRulesClass.InterruptionPolicy.CANCELABLE,
        phases,
        payload
    )
    if action_serial <= 0:
        return _reject(result, ResultClass.Status.TIMING_REJECTED, "timing_rejected")

    result.status = ResultClass.Status.ACCEPTED
    result.reason = ""
    result.action_serial = action_serial
    result.duration_ticks = timing.duration_ticks
    return result

func _reject_for_timing(
    result: ItemTransferActionResult,
    timing: ItemTransferTimingDecision
) -> ItemTransferActionResult:
    if timing == null:
        return _reject(result, ResultClass.Status.TIMING_UNCLASSIFIED, "timing_unclassified")
    match timing.status:
        TimingDecisionClass.Status.ACTION_UNCLASSIFIED:
            return _reject(result, ResultClass.Status.TIMING_UNCLASSIFIED, _timing_reason(timing))
        TimingDecisionClass.Status.ACTOR_UNCLASSIFIED, TimingDecisionClass.Status.CAPABILITY_UNKNOWN:
            return _reject(result, ResultClass.Status.CAPABILITY_UNKNOWN, _timing_reason(timing))
        TimingDecisionClass.Status.CAPABILITY_BLOCKED:
            return _reject(result, ResultClass.Status.CAPABILITY_BLOCKED, _timing_reason(timing))
        TimingDecisionClass.Status.INVALID_DURATION:
            return _reject(result, ResultClass.Status.INVALID_DURATION, _timing_reason(timing))
        _:
            return _reject(result, ResultClass.Status.TIMING_UNCLASSIFIED, _timing_reason(timing))

func _reject(result: ItemTransferActionResult, status: int, reason: String) -> ItemTransferActionResult:
    result.status = status
    result.reason = reason
    return result

func _on_action_phase(action: TimedAction, phase: ActionPhase) -> void:
    if action == null or phase == null:
        return
    if phase.phase_id != COMMIT_PHASE or not ActionTypes.is_valid(action.action_type):
        return
    _commit_action(action)

func _on_action_finished(action: TimedAction) -> void:
    if action == null or not ActionTypes.is_valid(action.action_type):
        return
    var item_id: String = String(action.payload.get("item_id", ""))
    if action.status == TickRulesClass.ActionStatus.CANCELED:
        item_transfer_canceled.emit(
            action.actor_id,
            action.serial,
            action.action_type,
            item_id,
            action.reason
        )
    elif action.status == TickRulesClass.ActionStatus.FAILED:
        item_transfer_failed.emit(
            action.actor_id,
            action.serial,
            action.action_type,
            item_id,
            action.reason
        )

func _commit_action(action: TimedAction) -> void:
    if not is_ready():
        _fail_action(action, "item_transfer_not_ready")
        return

    var payload: Dictionary = action.payload
    var expected_actor_value: Variant = payload.get("actor_placement", {})
    if typeof(expected_actor_value) != TYPE_DICTIONARY:
        _fail_action(action, "invalid_payload")
        return
    var expected_actor: WorldPlacement = PlacementClass.from_snapshot(expected_actor_value)
    if expected_actor == null or expected_actor.entity_id != action.actor_id or expected_actor.channel != Layers.Channel.ACTOR:
        _fail_action(action, "invalid_payload")
        return

    if not _world.has_entity(action.actor_id):
        _fail_action(action, "actor_missing")
        return
    var actor_entity: WorldEntityRecord = _world.entity(action.actor_id)
    if actor_entity == null or String(actor_entity.semantic_type).strip_edges() != "actor.survivor":
        _fail_action(action, "not_survivor")
        return
    var current_actor: WorldPlacement = _world.placement(action.actor_id)
    if current_actor == null or not current_actor.equivalent(expected_actor):
        _fail_action(action, "actor_placement_changed")
        return

    var item_id: String = String(payload.get("item_id", ""))
    var expected_semantic: String = String(payload.get("item_semantic_type", ""))
    if item_id.is_empty() or expected_semantic.is_empty() or not _world.has_entity(item_id):
        _fail_action(action, "item_missing")
        return
    var item_entity: WorldEntityRecord = _world.entity(item_id)
    if item_entity == null or String(item_entity.semantic_type) != expected_semantic:
        _fail_action(action, "item_identity_changed")
        return

    var current_source: ItemDispositionResult = _disposition.query(item_id)
    if not _commit_source_matches(payload, current_source):
        _fail_action(action, "source_changed")
        return

    if current_source.status == DispositionClass.Status.LOOSE_WORLD:
        if current_source.placement == null or not _loose_item_reachable(current_actor, current_source.placement):
            _fail_action(action, "out_of_reach")
            return

    if payload.has("expected_hand_version"):
        if not _hands.has_actor(action.actor_id):
            _fail_action(action, "hand_state_unknown")
            return
        if _hands.version(action.actor_id) != int(payload.get("expected_hand_version", -1)):
            _fail_action(action, "hand_version_changed")
            return

    if current_source.status == DispositionClass.Status.HAND:
        var source_slot: int = int(payload.get("source_slot", -1))
        if not Slots.is_valid(source_slot) \
            or _hands.item_in_slot(action.actor_id, source_slot) != item_id:
            _fail_action(action, "hand_source_changed")
            return

    var source_container_id: String = String(payload.get("source_container_id", ""))
    if not source_container_id.is_empty():
        if not _containment.has_container(source_container_id) \
            or not _world.has_entity(source_container_id) \
            or _containment.container_of(item_id) != source_container_id:
            _fail_action(action, "source_container_changed")
            return
        if payload.has("source_container_version") \
            and _containment.container_version(source_container_id) != int(payload.get("source_container_version", -1)):
            _fail_action(action, "source_container_version_changed")
            return
        if not _is_personal_container_accessible(action.actor_id, source_container_id):
            _fail_action(action, "source_container_inaccessible")
            return

    var destination_container_id: String = String(payload.get("destination_container_id", ""))
    if not destination_container_id.is_empty():
        if not _containment.has_container(destination_container_id) or not _world.has_entity(destination_container_id):
            _fail_action(action, "destination_container_unknown")
            return
        if payload.has("destination_container_version") \
            and _containment.container_version(destination_container_id) != int(payload.get("destination_container_version", -1)):
            _fail_action(action, "destination_container_version_changed")
            return
        if not _is_personal_container_accessible(action.actor_id, destination_container_id):
            _fail_action(action, "destination_container_inaccessible")
            return

    var destination_slot: int = int(payload.get("destination_slot", -1))
    if ActionTypes.destination_kind(action.action_type) == &"hand":
        if not _hands.has_actor(action.actor_id) or not Slots.is_valid(destination_slot):
            _fail_action(action, "destination_hand_invalid")
            return
        if not _hands.item_in_slot(action.actor_id, destination_slot).is_empty():
            _fail_action(action, "hand_occupied")
            return

    if action.action_type == ActionTypes.CONTAINER_TO_CONTAINER:
        if source_container_id == destination_container_id or _would_create_cycle(item_id, destination_container_id):
            _fail_action(action, "containment_rejected")
            return

    var timing: ItemTransferTimingDecision = _policy.evaluate(action.actor_id, action.action_type)
    if timing == null or not timing.is_allowed():
        _fail_action(action, _timing_reason(timing))
        return

    _perform_commit(action, current_actor)

func _commit_source_matches(payload: Dictionary, current: ItemDispositionResult) -> bool:
    if current == null:
        return false
    var expected_status: int = int(payload.get("expected_source_status", -1))
    if current.status != expected_status:
        return false
    match expected_status:
        DispositionClass.Status.LOOSE_WORLD:
            var expected_value: Variant = payload.get("source_placement", {})
            if typeof(expected_value) != TYPE_DICTIONARY or current.placement == null:
                return false
            var expected_placement: WorldPlacement = PlacementClass.from_snapshot(expected_value)
            return expected_placement != null and current.placement.equivalent(expected_placement)
        DispositionClass.Status.HAND:
            return current.actor_id == String(payload.get("source_actor_id", "")) \
                and current.slot == int(payload.get("source_slot", -1))
        DispositionClass.Status.CONTAINED:
            return current.container_id == String(payload.get("source_container_id", ""))
        _:
            return false

func _perform_commit(action: TimedAction, actor_placement: WorldPlacement) -> void:
    var payload: Dictionary = action.payload
    var item_id: String = String(payload.get("item_id", ""))

    if action.action_type == ActionTypes.CONTAINER_TO_CONTAINER:
        if not _containment_mutations.set_container(
            item_id,
            String(payload.get("destination_container_id", ""))
        ):
            _fail_action(action, "destination_mutation_failed")
            return
        _emit_commit(action)
        return

    if not _remove_source(action.action_type, payload, item_id):
        _fail_action(action, "source_mutation_failed")
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

func _remove_source(action_type: StringName, payload: Dictionary, item_id: String) -> bool:
    match ActionTypes.source_kind(action_type):
        &"world":
            return _world_mutations.unplace_entity(item_id)
        &"container":
            return _containment_mutations.clear_container(item_id)
        &"hand":
            return _hand_mutations.clear_slot(
                String(payload.get("source_actor_id", "")),
                int(payload.get("source_slot", -1))
            )
        _:
            return false

func _add_destination(
    action_type: StringName,
    payload: Dictionary,
    item_id: String,
    actor_placement: WorldPlacement,
    actor_id: String
) -> bool:
    # Source-removal signals may run reentrant callbacks. Recheck the destination
    # immediately before the second mutation so low-level permissive APIs cannot
    # overwrite a newly occupied/stale destination.
    match ActionTypes.destination_kind(action_type):
        &"world":
            var current_actor: WorldPlacement = _world.placement(actor_id)
            if current_actor == null or not current_actor.equivalent(actor_placement):
                return false
            return _world_mutations.set_placement(
                item_id,
                Layers.Channel.LOOSE_ITEM,
                actor_placement.anchor,
                actor_placement.facing,
                Footprint.single_cell(),
                PlacementClass.NO_STRUCTURE_AXIS
            )
        &"container":
            var container_id: String = String(payload.get("destination_container_id", ""))
            if not _containment.has_container(container_id) or not _world.has_entity(container_id):
                return false
            if payload.has("destination_container_version") \
                and _containment.container_version(container_id) != int(payload.get("destination_container_version", -1)):
                return false
            if not _is_personal_container_accessible(actor_id, container_id):
                return false
            return _containment_mutations.set_container(item_id, container_id)
        &"hand":
            var slot: int = int(payload.get("destination_slot", -1))
            if not _hands.has_actor(actor_id) or not Slots.is_valid(slot):
                return false
            if not _hands.item_in_slot(actor_id, slot).is_empty():
                return false
            return _hand_mutations.set_item(actor_id, slot, item_id)
        _:
            return false

func _restore_source(payload: Dictionary, item_id: String) -> bool:
    var source_kind: String = String(payload.get("source_kind", ""))
    match source_kind:
        "world":
            var value: Variant = payload.get("source_placement", {})
            if typeof(value) != TYPE_DICTIONARY:
                return false
            var placement: WorldPlacement = PlacementClass.from_snapshot(value)
            if placement == null:
                return false
            return _world_mutations.set_placement(
                item_id,
                placement.channel,
                placement.anchor,
                placement.facing,
                placement.footprint,
                placement.structure_axis
            )
        "container":
            return _containment_mutations.set_container(
                item_id,
                String(payload.get("source_container_id", ""))
            )
        "hand":
            return _hand_mutations.set_item(
                String(payload.get("source_actor_id", "")),
                int(payload.get("source_slot", -1)),
                item_id
            )
        _:
            return false

func _emit_commit(action: TimedAction) -> void:
    item_transfer_committed.emit(
        action.actor_id,
        action.serial,
        action.action_type,
        String(action.payload.get("item_id", "")),
        ActionTypes.source_kind(action.action_type),
        ActionTypes.destination_kind(action.action_type)
    )

func _fail_action(action: TimedAction, reason: String) -> void:
    if action == null:
        return
    if not _kernel.fail_action(action.serial, reason):
        _append_diagnostic(action, String(action.payload.get("item_id", "")), "failed_to_mark_action_failed", true)

func _is_personal_container_accessible(actor_id: String, container_id: String) -> bool:
    if not _containment.has_container(container_id) or not _world.has_entity(container_id):
        return false
    if container_id == actor_id:
        return true

    var current: String = container_id
    var visited: Dictionary = {}
    for _i: int in range(ANCESTRY_LIMIT):
        if current.is_empty() or visited.has(current):
            return false
        visited[current] = true
        if current == actor_id:
            return _world.has_entity(actor_id)
        if not _world.has_entity(current):
            return false

        var assignment: Dictionary = _hands.assignment_for_item(current)
        var parent: String = _containment.container_of(current)
        if not assignment.is_empty() and parent.is_empty():
            return String(assignment.get("actor_id", "")) == actor_id
        if parent.is_empty():
            return false
        current = parent
    return false

func _would_create_cycle(item_id: String, destination_container_id: String) -> bool:
    if item_id == destination_container_id:
        return true
    var current: String = destination_container_id
    var visited: Dictionary = {}
    for _i: int in range(ANCESTRY_LIMIT):
        if current.is_empty():
            return false
        if current == item_id or visited.has(current):
            return true
        visited[current] = true
        current = _containment.container_of(current)
    return true

func _loose_item_reachable(actor_placement: WorldPlacement, item_placement: WorldPlacement) -> bool:
    if actor_placement == null or item_placement == null:
        return false
    if item_placement.channel != Layers.Channel.LOOSE_ITEM or not Facing.is_valid(actor_placement.facing):
        return false
    var reachable: Dictionary = {}
    var facing_vector: Vector2i = Facing.vector(actor_placement.facing)
    for cell: Vector2i in actor_placement.world_cells():
        reachable[cell] = true
        reachable[cell + facing_vector] = true
    for cell: Vector2i in item_placement.world_cells():
        if reachable.has(cell):
            return true
    return false

func _append_diagnostic(action: TimedAction, item_id: String, reason: String, critical: bool) -> void:
    _diagnostics.append({
        "tick": _kernel.world_tick() if _kernel != null else -1,
        "action_serial": action.serial if action != null else 0,
        "actor_id": action.actor_id if action != null else "",
        "item_id": item_id,
        "reason": reason,
        "critical": critical,
    })
    while _diagnostics.size() > DIAGNOSTIC_LIMIT:
        _diagnostics.pop_front()

static func _timing_reason(timing: ItemTransferTimingDecision) -> String:
    if timing == null:
        return "timing_unclassified"
    if not timing.reason.is_empty():
        return timing.reason
    match timing.status:
        TimingDecisionClass.Status.ACTION_UNCLASSIFIED:
            return "timing_unclassified"
        TimingDecisionClass.Status.ACTOR_UNCLASSIFIED:
            return "actor_unclassified"
        TimingDecisionClass.Status.CAPABILITY_UNKNOWN:
            return "capability_unknown"
        TimingDecisionClass.Status.CAPABILITY_BLOCKED:
            return "capability_blocked"
        TimingDecisionClass.Status.INVALID_DURATION:
            return "invalid_duration"
        _:
            return "timing_rejected"
