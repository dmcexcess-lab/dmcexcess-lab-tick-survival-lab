extends InteractionOfferProvider
class_name WorldInteractionOfferProvider

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const Actions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")

const CATEGORY: StringName = &"world"
const PRIORITY: int = 110

var _world: WorldState = null
var _reach: WorldInteractionReachQuery = null
var _doors: DoorStateStore = null
var _state: WorldInteractableState = null
var _catalog: WorldInteractionCatalog = null

func _init(
    world: WorldState = null,
    reach: WorldInteractionReachQuery = null,
    doors: DoorStateStore = null,
    state: WorldInteractableState = null,
    catalog: WorldInteractionCatalog = null
) -> void:
    _world = world
    _reach = reach
    _doors = doors
    _state = state
    _catalog = catalog
    if _state != null:
        var callback := Callable(self, "_on_state_changed")
        if not _state.state_changed.is_connected(callback):
            _state.state_changed.connect(callback)
    if _doors != null:
        var door_callback := Callable(self, "_on_door_changed")
        if not _doors.door_state_changed.is_connected(door_callback):
            _doors.door_state_changed.connect(door_callback)

func is_ready() -> bool:
    return _world != null and _reach != null and _reach.is_ready() and _doors != null and _state != null and _catalog != null

func offers_for_actor(actor_id: String, candidate_target_ids: Array[String]) -> Array[InteractionOffer]:
    var result: Array[InteractionOffer] = []
    if not is_ready(): return result
    var ordered: Array[String] = candidate_target_ids.duplicate()
    ordered.sort()
    for target_id: String in ordered:
        if not _world.has_entity(target_id) or _state.is_destroyed(target_id): continue
        var entity: WorldEntityRecord = _world.entity(target_id)
        var placement: WorldPlacement = _world.placement(target_id)
        if entity == null or placement == null or placement.channel not in [Layers.Channel.OBJECT, Layers.Channel.STRUCTURE]: continue
        if not _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD): continue
        var semantic: StringName = entity.semantic_type
        if _catalog.is_door(semantic) and _doors.has_door(target_id):
            _append_door(result, actor_id, target_id, placement)
        elif _catalog.is_window(semantic):
            _append_window(result, actor_id, target_id, placement)
        elif _catalog.deconstructible(semantic):
            _append(result, actor_id, target_id, placement, Actions.OBJECT_DECONSTRUCT, "DECONSTRUCT", PRIORITY - 15)
    return result

func _append_door(result: Array[InteractionOffer], actor_id: String, target_id: String, placement: WorldPlacement) -> void:
    var broken: bool = _state.is_broken(target_id)
    var boards: int = _state.board_count(target_id)
    var locked: bool = _state.is_locked(target_id)
    var door_state: StringName = _doors.state(target_id)
    if broken:
        return
    if boards > 0:
        _append(result, actor_id, target_id, placement, Actions.OPENING_UNBOARD, "REMOVE BOARD", PRIORITY + 8)
        _append(result, actor_id, target_id, placement, Actions.OPENING_BREAK, "BREAK", PRIORITY)
        return
    if door_state == DoorValue.OPEN:
        _append(result, actor_id, target_id, placement, Actions.DOOR_CLOSE, "CLOSE", PRIORITY + 10)
        _append(result, actor_id, target_id, placement, Actions.OPENING_BREAK, "BREAK", PRIORITY - 5)
        return
    if locked:
        _append(result, actor_id, target_id, placement, Actions.DOOR_UNLOCK, "UNLOCK", PRIORITY + 10)
    else:
        _append(result, actor_id, target_id, placement, Actions.DOOR_OPEN, "OPEN", PRIORITY + 10)
        _append(result, actor_id, target_id, placement, Actions.DOOR_LOCK, "LOCK", PRIORITY)
    _append(result, actor_id, target_id, placement, Actions.OPENING_BOARD, "BOARD", PRIORITY - 2)
    _append(result, actor_id, target_id, placement, Actions.OPENING_BREAK, "BREAK", PRIORITY - 5)

func _append_window(result: Array[InteractionOffer], actor_id: String, target_id: String, placement: WorldPlacement) -> void:
    var broken: bool = _state.is_broken(target_id)
    var boards: int = _state.board_count(target_id)
    var locked: bool = _state.is_locked(target_id)
    var opened: bool = _state.window_open(target_id)
    if boards > 0:
        _append(result, actor_id, target_id, placement, Actions.OPENING_UNBOARD, "REMOVE BOARD", PRIORITY + 8)
        _append(result, actor_id, target_id, placement, Actions.OPENING_BREAK, "BREAK", PRIORITY)
        return
    if broken:
        _append(result, actor_id, target_id, placement, Actions.WINDOW_CLIMB, "CLIMB THROUGH", PRIORITY + 12)
        return
    if opened:
        _append(result, actor_id, target_id, placement, Actions.WINDOW_CLIMB, "CLIMB THROUGH", PRIORITY + 12)
        _append(result, actor_id, target_id, placement, Actions.WINDOW_CLOSE, "CLOSE", PRIORITY + 6)
        _append(result, actor_id, target_id, placement, Actions.OPENING_BREAK, "BREAK", PRIORITY - 5)
        return
    if locked:
        _append(result, actor_id, target_id, placement, Actions.WINDOW_UNLOCK, "UNLOCK", PRIORITY + 10)
    else:
        _append(result, actor_id, target_id, placement, Actions.WINDOW_OPEN, "OPEN", PRIORITY + 10)
        _append(result, actor_id, target_id, placement, Actions.WINDOW_LOCK, "LOCK", PRIORITY)
    _append(result, actor_id, target_id, placement, Actions.OPENING_BOARD, "BOARD", PRIORITY - 2)
    _append(result, actor_id, target_id, placement, Actions.OPENING_BREAK, "BREAK", PRIORITY - 5)

func _append(result: Array[InteractionOffer], actor_id: String, target_id: String, placement: WorldPlacement, action_id: StringName, label: String, priority: int) -> void:
    result.append(InteractionOffer.new(
        actor_id,
        target_id,
        action_id,
        label,
        WorldInteractionReachQuery.CONTACT_FORWARD,
        placement.world_cells(),
        priority,
        CATEGORY,
        true
    ))

func _on_state_changed(_target_id: String, _version: int, reason: StringName) -> void:
    availability_changed.emit(reason)

func _on_door_changed(_door_id: String, _previous: StringName, _new: StringName, _version: int) -> void:
    availability_changed.emit(&"door_state_changed")
