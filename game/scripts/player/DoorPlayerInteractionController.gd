extends RefCounted
class_name DoorPlayerInteractionController

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")

signal action_resolved(intent: StringName, success: bool, reason: String, world_tick: int)

var _world: WorldState = null
var _actions: DoorInteractionActionService = null
var _kernel: TickKernel = null
var _actor_id: String = ""
var _outcomes: Dictionary = {}

func _init(
    world_state: WorldState = null,
    action_service: DoorInteractionActionService = null,
    tick_kernel: TickKernel = null,
    actor_id: String = ""
) -> void:
    _world = world_state
    _actions = action_service
    _kernel = tick_kernel
    _actor_id = actor_id.strip_edges()
    if _actions != null:
        if not _actions.close_committed.is_connected(_on_close_committed):
            _actions.close_committed.connect(_on_close_committed)
        if not _actions.close_failed.is_connected(_on_close_failed):
            _actions.close_failed.connect(_on_close_failed)

func is_ready() -> bool:
    return _world != null and _actions != null and _actions.is_ready() and _kernel != null and not _actor_id.is_empty()

func submit_world_cell(cell: Vector2i) -> void:
    if not is_ready():
        action_resolved.emit(Intents.DOOR_CLOSE, false, "door_input_not_ready", _tick())
        return
    if _kernel.is_hard_paused():
        action_resolved.emit(Intents.DOOR_CLOSE, false, "hard_paused", _tick())
        return
    var door_ids: Array[String] = []
    for entity_id: String in _world.entities_at(cell, Layers.Channel.STRUCTURE):
        var entity: WorldEntityRecord = _world.entity(entity_id)
        if entity != null and String(entity.semantic_type).begins_with("door."):
            door_ids.append(entity_id)
    door_ids.sort()
    if door_ids.size() != 1:
        return
    var result: DoorInteractionActionResult = _actions.request_close(_actor_id, door_ids[0])
    if result == null or not result.is_accepted():
        action_resolved.emit(Intents.DOOR_CLOSE, false, "door_close_rejected" if result == null else result.reason, _tick())
        return
    _outcomes.erase(result.action_serial)
    _kernel.run_until_stop()
    var outcome: Dictionary = _outcomes.get(result.action_serial, {})
    if outcome.is_empty():
        action_resolved.emit(Intents.DOOR_CLOSE, false, "action_unresolved", _tick())
    else:
        action_resolved.emit(Intents.DOOR_CLOSE, bool(outcome.get("success", false)), String(outcome.get("reason", "")), _tick())
    _outcomes.erase(result.action_serial)

func _on_close_committed(actor_id: String, serial: int, _door_id: String) -> void:
    if actor_id == _actor_id:
        _outcomes[serial] = {"success": true, "reason": ""}

func _on_close_failed(actor_id: String, serial: int, _door_id: String, reason: String) -> void:
    if actor_id == _actor_id:
        _outcomes[serial] = {"success": false, "reason": reason}

func _tick() -> int:
    return 0 if _kernel == null else _kernel.world_tick()
