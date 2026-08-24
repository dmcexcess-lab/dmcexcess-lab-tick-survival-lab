extends RefCounted
class_name ActionSoundEmitterAdapter

const Profiles = preload("res://scripts/simulation/sound/SoundEmissionProfileCatalog.gd")

## Narrow adapter from already-committed physical Movement/Door events into
## System 26 emissions. Source systems remain sound-agnostic.

var _movement: MovementActionService = null
var _door_transitions: DoorPhysicalTransitionService = null
var _sound: SpatialSoundService = null

func _init(
    movement: MovementActionService = null,
    door_transitions: DoorPhysicalTransitionService = null,
    sound_service: SpatialSoundService = null
) -> void:
    _movement = movement
    _door_transitions = door_transitions
    _sound = sound_service
    if _movement != null:
        if not _movement.movement_committed.is_connected(_on_movement_committed):
            _movement.movement_committed.connect(_on_movement_committed)
        if not _movement.run_stride_committed.is_connected(_on_run_stride_committed):
            _movement.run_stride_committed.connect(_on_run_stride_committed)
    if _door_transitions != null and not _door_transitions.transition_resolved.is_connected(_on_door_transition_resolved):
        _door_transitions.transition_resolved.connect(_on_door_transition_resolved)

func is_ready() -> bool:
    return _movement != null and _door_transitions != null and _sound != null and _sound.is_ready()

func _on_movement_committed(
    actor_id: String,
    _action_serial: int,
    action_type: StringName,
    target_anchor: Vector2i,
    _target_facing: int
) -> void:
    if _sound == null:
        return
    if action_type != MovementActionService.STEP_FORWARD and action_type != MovementActionService.STEP_BACKWARD:
        return
    _sound.emit_sound(
        Profiles.WALK_STEP,
        target_anchor,
        actor_id,
        "footsteps:%s" % actor_id
    )

func _on_run_stride_committed(
    actor_id: String,
    _action_serial: int,
    _stride_index: int,
    target_anchor: Vector2i,
    _target_facing: int
) -> void:
    if _sound == null:
        return
    _sound.emit_sound(
        Profiles.RUN_STRIDE,
        target_anchor,
        actor_id,
        "footsteps:%s" % actor_id
    )

func _on_door_transition_resolved(
    actor_id: String,
    door_id: String,
    _previous_state: StringName,
    _new_state: StringName,
    _cause: StringName,
    noise_class: StringName,
    cell: Vector2i
) -> void:
    if _sound == null:
        return
    var profile_id: StringName = Profiles.DOOR_LOUD if noise_class == DoorPhysicalTransitionService.NOISE_LOUD else Profiles.DOOR_NORMAL
    _sound.emit_sound(
        profile_id,
        cell,
        actor_id,
        "door:%s" % door_id
    )
