extends RefCounted
class_name DoorPhysicalTransitionService

const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")

## Coherent OPEN/CLOSED physical transition coordinator.
## Door State owns semantic truth; CollisionOverrideState owns sparse collision exceptions.

signal transition_resolved(actor_id, door_id, previous_state, new_state, cause, noise_class, cell)
signal transition_failed(actor_id, door_id, target_state, reason)

const CAUSE_WALK: StringName = &"walk_passage"
const CAUSE_RUN: StringName = &"run_passage"
const CAUSE_MANUAL_CLOSE: StringName = &"manual_close"
const NOISE_NORMAL: StringName = &"normal"
const NOISE_LOUD: StringName = &"loud"

var _world: WorldState = null
var _state: DoorStateStore = null
var _mutations: DoorStateMutationService = null
var _collision_overrides: CollisionOverrideState = null

func _init(
    world_state: WorldState = null,
    door_state: DoorStateStore = null,
    door_mutations: DoorStateMutationService = null,
    collision_overrides: CollisionOverrideState = null
) -> void:
    _world = world_state
    _state = door_state
    _mutations = door_mutations
    _collision_overrides = collision_overrides

func is_ready() -> bool:
    return _world != null and _state != null and _mutations != null and _mutations.is_ready() and _collision_overrides != null

func open_for_passage(actor_id: String, door_id: String, action_type: StringName) -> bool:
    var cause: StringName = CAUSE_RUN if action_type == &"movement.run_forward" else CAUSE_WALK
    var noise: StringName = NOISE_LOUD if cause == CAUSE_RUN else NOISE_NORMAL
    return _transition(actor_id, door_id, DoorValue.OPEN, cause, noise)

func close_manually(actor_id: String, door_id: String) -> bool:
    return _transition(actor_id, door_id, DoorValue.CLOSED, CAUSE_MANUAL_CLOSE, NOISE_NORMAL)

func _transition(
    actor_id: String,
    door_id: String,
    target_state: StringName,
    cause: StringName,
    noise_class: StringName
) -> bool:
    if not is_ready() or not _valid_world_door(door_id):
        transition_failed.emit(actor_id, door_id, target_state, "door_transition_not_ready")
        return false
    var previous: StringName = _state.state(door_id)
    if previous != DoorValue.OPEN and previous != DoorValue.CLOSED:
        transition_failed.emit(actor_id, door_id, target_state, "door_state_unknown")
        return false

    var had_override: bool = _collision_overrides.has_override(door_id)
    var previous_override: bool = _collision_overrides.blocks_movement(door_id) if had_override else false

    if previous != target_state and not _mutations.set_state(door_id, target_state):
        transition_failed.emit(actor_id, door_id, target_state, "door_state_mutation_failed")
        return false

    var collision_ok: bool = true
    if target_state == DoorValue.OPEN:
        collision_ok = _collision_overrides.set_override(door_id, false)
    else:
        if _collision_overrides.has_override(door_id):
            collision_ok = _collision_overrides.clear_override(door_id)

    if not collision_ok:
        if previous != target_state:
            _mutations.set_state(door_id, previous)
        if had_override:
            _collision_overrides.set_override(door_id, previous_override)
        elif _collision_overrides.has_override(door_id):
            _collision_overrides.clear_override(door_id)
        transition_failed.emit(actor_id, door_id, target_state, "collision_sync_failed")
        return false

    var cell := Vector2i.ZERO
    var placement: WorldPlacement = _world.placement(door_id)
    if placement != null:
        cell = placement.anchor
    transition_resolved.emit(actor_id, door_id, previous, target_state, cause, noise_class, cell)
    return true

func _valid_world_door(door_id: String) -> bool:
    if door_id.strip_edges().is_empty() or not _world.has_entity(door_id) or not _state.has_door(door_id):
        return false
    var entity: WorldEntityRecord = _world.entity(door_id)
    return entity != null and String(entity.semantic_type).begins_with("door.")
