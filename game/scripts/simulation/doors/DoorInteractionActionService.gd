extends RefCounted
class_name DoorInteractionActionService

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const ResultClass = preload("res://scripts/simulation/doors/DoorInteractionActionResult.gd")
const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRules = preload("res://scripts/foundation/time/TickRules.gd")
const PlacementClass = preload("res://scripts/foundation/world/WorldPlacement.gd")

signal close_committed(actor_id, action_serial, door_id)
signal close_failed(actor_id, action_serial, door_id, reason)

const CLOSE_ACTION: StringName = &"door.close"
const COMMIT_PHASE: StringName = &"door.close.commit"
const CLOSE_TICKS: int = 3

var _world: WorldState = null
var _state: DoorStateStore = null
var _kernel: TickKernel = null
var _transitions: DoorPhysicalTransitionService = null

func _init(
    world_state: WorldState = null,
    door_state: DoorStateStore = null,
    tick_kernel: TickKernel = null,
    transition_service: DoorPhysicalTransitionService = null
) -> void:
    _world = world_state
    _state = door_state
    _kernel = tick_kernel
    _transitions = transition_service
    if _kernel != null:
        if not _kernel.action_phase.is_connected(_on_action_phase):
            _kernel.action_phase.connect(_on_action_phase)
        if not _kernel.action_finished.is_connected(_on_action_finished):
            _kernel.action_finished.connect(_on_action_finished)

func is_ready() -> bool:
    return _world != null and _state != null and _kernel != null and _transitions != null and _transitions.is_ready()

func request_close(actor_id: String, door_id: String) -> DoorInteractionActionResult:
    var result := ResultClass.new()
    result.door_id = door_id
    if not is_ready():
        result.status = ResultClass.Status.NOT_READY
        result.reason = "door_action_not_ready"
        return result
    var actor: WorldPlacement = _actor_placement(actor_id)
    if actor == null:
        result.status = ResultClass.Status.ACTOR_UNPLACED if _world.has_entity(actor_id) else ResultClass.Status.ACTOR_MISSING
        result.reason = "actor_unplaced" if _world.has_entity(actor_id) else "actor_missing"
        return result
    if _kernel.has_active_action(actor_id):
        result.status = ResultClass.Status.BUSY
        result.reason = "actor_busy"
        return result
    var door: WorldPlacement = _door_placement(door_id)
    if door == null:
        result.status = ResultClass.Status.DOOR_MISSING
        result.reason = "door_missing"
        return result
    if _state.state(door_id) != DoorValue.OPEN:
        result.status = ResultClass.Status.DOOR_NOT_OPEN
        result.reason = "door_not_open"
        return result
    if not _is_adjacent(actor, door):
        result.status = ResultClass.Status.OUT_OF_REACH
        result.reason = "door_out_of_reach"
        return result
    if not _is_facing(actor, door):
        result.status = ResultClass.Status.NOT_FACING_DOOR
        result.reason = "not_facing_door"
        return result
    if _doorway_occupied(door):
        result.status = ResultClass.Status.DOORWAY_OCCUPIED
        result.reason = "doorway_occupied"
        return result

    var phases: Array[ActionPhase] = [PhaseClass.new(COMMIT_PHASE, CLOSE_TICKS)]
    var payload: Dictionary = {
        "door_id": door_id,
        "expected_door_version": _state.version(door_id),
        "expected_actor_placement": actor.to_snapshot(),
    }
    var serial: int = _kernel.begin_action(
        actor_id,
        CLOSE_ACTION,
        CLOSE_TICKS,
        TickRules.InterruptionPolicy.CANCELABLE,
        phases,
        payload
    )
    if serial <= 0:
        result.status = ResultClass.Status.TIMING_REJECTED
        result.reason = "timing_rejected"
        return result
    result.status = ResultClass.Status.ACCEPTED
    result.action_serial = serial
    result.duration_ticks = CLOSE_TICKS
    return result

func _on_action_phase(action: TimedAction, phase: ActionPhase) -> void:
    if action == null or phase == null or action.action_type != CLOSE_ACTION or phase.phase_id != COMMIT_PHASE:
        return
    _commit(action)

func _on_action_finished(action: TimedAction) -> void:
    if action == null or action.action_type != CLOSE_ACTION:
        return
    if action.status == TickRules.ActionStatus.CANCELED or action.status == TickRules.ActionStatus.INTERRUPTED:
        close_failed.emit(action.actor_id, action.serial, String(action.payload.get("door_id", "")), action.reason if not action.reason.is_empty() else "door_close_interrupted")

func _commit(action: TimedAction) -> void:
    var door_id: String = String(action.payload.get("door_id", ""))
    var expected_actor_value: Variant = action.payload.get("expected_actor_placement", {})
    var expected_actor: WorldPlacement = PlacementClass.from_snapshot(expected_actor_value) if typeof(expected_actor_value) == TYPE_DICTIONARY else null
    var actor: WorldPlacement = _actor_placement(action.actor_id)
    var door: WorldPlacement = _door_placement(door_id)
    if expected_actor == null or actor == null or door == null:
        _fail(action, door_id, "interaction_state_changed")
        return
    if not actor.equivalent(expected_actor):
        _fail(action, door_id, "actor_placement_changed")
        return
    if _state.state(door_id) != DoorValue.OPEN or _state.version(door_id) != int(action.payload.get("expected_door_version", 0)):
        _fail(action, door_id, "door_state_changed")
        return
    if not _is_adjacent(actor, door):
        _fail(action, door_id, "door_out_of_reach")
        return
    if not _is_facing(actor, door):
        _fail(action, door_id, "not_facing_door")
        return
    if _doorway_occupied(door):
        _fail(action, door_id, "doorway_occupied")
        return
    if not _transitions.close_manually(action.actor_id, door_id):
        _fail(action, door_id, "door_transition_failed")
        return
    close_committed.emit(action.actor_id, action.serial, door_id)

func _fail(action: TimedAction, door_id: String, reason: String) -> void:
    _kernel.fail_action(action.serial, reason)
    close_failed.emit(action.actor_id, action.serial, door_id, reason)

func _actor_placement(actor_id: String) -> WorldPlacement:
    if actor_id.strip_edges().is_empty() or not _world.has_entity(actor_id) or not _world.has_placement(actor_id):
        return null
    var placement: WorldPlacement = _world.placement(actor_id)
    if placement == null or placement.channel != Layers.Channel.ACTOR:
        return null
    return placement

func _door_placement(door_id: String) -> WorldPlacement:
    if door_id.strip_edges().is_empty() or not _world.has_entity(door_id) or not _world.has_placement(door_id) or not _state.has_door(door_id):
        return null
    var entity: WorldEntityRecord = _world.entity(door_id)
    var placement: WorldPlacement = _world.placement(door_id)
    if entity == null or placement == null or placement.channel != Layers.Channel.STRUCTURE or not String(entity.semantic_type).begins_with("door."):
        return null
    return placement

func _is_adjacent(actor: WorldPlacement, door: WorldPlacement) -> bool:
    for actor_cell: Vector2i in actor.world_cells():
        for door_cell: Vector2i in door.world_cells():
            var delta: Vector2i = door_cell - actor_cell
            if absi(delta.x) + absi(delta.y) == 1:
                return true
    return false

func _is_facing(actor: WorldPlacement, door: WorldPlacement) -> bool:
    if not Facing.is_valid(actor.facing):
        return false
    var forward: Vector2i = Facing.vector(actor.facing)
    for actor_cell: Vector2i in actor.world_cells():
        if actor_cell + forward in door.world_cells():
            return true
    return false

func _doorway_occupied(door: WorldPlacement) -> bool:
    for cell: Vector2i in door.world_cells():
        if not _world.entities_at(cell, Layers.Channel.ACTOR).is_empty():
            return true
    return false
