extends RefCounted
class_name LootPlayerInteractionController

signal action_resolved(intent, success, reason, world_tick)
signal container_opened(container_id)
signal container_changed(container_id)

const SEARCH_INTENT: StringName = &"loot.search"
const TAKE_INTENT: StringName = &"loot.take"
const STORE_INTENT: StringName = &"loot.store"

var _search: LootSearchActionService = null
var _transfer: ItemTransferActionService = null
var _inspection: LootContainerInspectionQuery = null
var _kernel: TickKernel = null
var _actor_id: String = ""
var _search_outcomes: Dictionary = {}
var _transfer_outcomes: Dictionary = {}

func _init(
    search_service: LootSearchActionService = null,
    transfer_service: ItemTransferActionService = null,
    inspection_query: LootContainerInspectionQuery = null,
    tick_kernel: TickKernel = null,
    actor_id: String = ""
) -> void:
    _search = search_service
    _transfer = transfer_service
    _inspection = inspection_query
    _kernel = tick_kernel
    _actor_id = actor_id.strip_edges()
    if _search != null:
        _search.search_completed.connect(_on_search_completed)
        _search.search_failed.connect(_on_search_failed)
        _search.search_canceled.connect(_on_search_canceled)
    if _transfer != null:
        _transfer.item_transfer_committed.connect(_on_transfer_committed)
        _transfer.item_transfer_failed.connect(_on_transfer_failed)
        _transfer.item_transfer_canceled.connect(_on_transfer_canceled)

func is_ready() -> bool:
    return _search != null and _search.is_ready() \
        and _transfer != null and _transfer.is_ready() \
        and _inspection != null and _inspection.is_ready() \
        and _kernel != null and not _actor_id.is_empty()

## Shares the generic world-cell pointer with door interaction. No searchable container
## at a clicked cell is a silent no-op so other world interaction controllers may own it.
func submit_world_cell(cell: Vector2i) -> void:
    if not is_ready():
        return
    var container_ids: Array[String] = _inspection.searchable_container_ids_at(cell)
    if container_ids.is_empty():
        return
    if container_ids.size() != 1:
        action_resolved.emit(SEARCH_INTENT, false, "ambiguous_loot_container", _tick())
        return
    var container_id: String = container_ids[0]
    var result: Dictionary = _search.request_search(_actor_id, container_id)
    if not bool(result.get("accepted", false)):
        action_resolved.emit(SEARCH_INTENT, false, String(result.get("reason", "search_rejected")), _tick())
        return
    var serial: int = int(result.get("action_serial", 0))
    _search_outcomes.erase(serial)
    _kernel.run_until_stop()
    var outcome: Dictionary = _search_outcomes.get(serial, {})
    if bool(outcome.get("success", false)):
        container_opened.emit(container_id)
        action_resolved.emit(SEARCH_INTENT, true, "", _tick())
    else:
        action_resolved.emit(SEARCH_INTENT, false, String(outcome.get("reason", "action_unresolved")), _tick())
    _search_outcomes.erase(serial)

func request_take(container_id: String, item_id: String) -> void:
    if not is_ready():
        action_resolved.emit(TAKE_INTENT, false, "loot_input_not_ready", _tick())
        return
    var result: ItemTransferActionResult = _transfer.request_transfer_container(
        _actor_id,
        item_id.strip_edges(),
        _actor_id
    )
    _run_transfer(TAKE_INTENT, container_id.strip_edges(), result)

func request_store(container_id: String, item_id: String) -> void:
    if not is_ready():
        action_resolved.emit(STORE_INTENT, false, "loot_input_not_ready", _tick())
        return
    var result: ItemTransferActionResult = _transfer.request_transfer_container(
        _actor_id,
        item_id.strip_edges(),
        container_id.strip_edges()
    )
    _run_transfer(STORE_INTENT, container_id.strip_edges(), result)

func _run_transfer(intent: StringName, container_id: String, result: ItemTransferActionResult) -> void:
    if result == null or not result.is_accepted():
        action_resolved.emit(intent, false, "transfer_rejected" if result == null else result.reason, _tick())
        return
    var serial: int = result.action_serial
    _transfer_outcomes.erase(serial)
    _kernel.run_until_stop()
    var outcome: Dictionary = _transfer_outcomes.get(serial, {})
    if bool(outcome.get("success", false)):
        container_changed.emit(container_id)
        action_resolved.emit(intent, true, "", _tick())
    else:
        action_resolved.emit(intent, false, String(outcome.get("reason", "action_unresolved")), _tick())
    _transfer_outcomes.erase(serial)

func _on_search_completed(actor_id: String, serial: int, _container_id: String, _contents: Array, _version: int) -> void:
    if actor_id == _actor_id:
        _search_outcomes[serial] = {"success": true, "reason": ""}

func _on_search_failed(actor_id: String, serial: int, _container_id: String, reason: String) -> void:
    if actor_id == _actor_id:
        _search_outcomes[serial] = {"success": false, "reason": reason}

func _on_search_canceled(actor_id: String, serial: int, _container_id: String, reason: String) -> void:
    if actor_id == _actor_id:
        _search_outcomes[serial] = {"success": false, "reason": reason}

func _on_transfer_committed(actor_id: String, serial: int, _action_type: StringName, _item_id: String, _source_kind: StringName, _destination_kind: StringName) -> void:
    if actor_id == _actor_id:
        _transfer_outcomes[serial] = {"success": true, "reason": ""}

func _on_transfer_failed(actor_id: String, serial: int, _action_type: StringName, _item_id: String, reason: String) -> void:
    if actor_id == _actor_id:
        _transfer_outcomes[serial] = {"success": false, "reason": reason}

func _on_transfer_canceled(actor_id: String, serial: int, _action_type: StringName, _item_id: String, reason: String) -> void:
    if actor_id == _actor_id:
        _transfer_outcomes[serial] = {"success": false, "reason": reason}

func _tick() -> int:
    return 0 if _kernel == null else _kernel.world_tick()
