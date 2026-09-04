extends RefCounted
class_name VehicleConsequenceAdapter

const SoundProfiles = preload("res://scripts/simulation/sound/SoundEmissionProfileCatalog.gd")

var _world: WorldState
var _state: VehicleState
var _profiles: VehicleProfileCatalog
var _actions: VehicleActionService
var _sound: SpatialSoundService
var _health: ActorHealthState

func _init(world: WorldState, state: VehicleState, profiles: VehicleProfileCatalog, actions: VehicleActionService, sound: SpatialSoundService, health: ActorHealthState) -> void:
    _world = world
    _state = state
    _profiles = profiles
    _actions = actions
    _sound = sound
    _health = health
    if is_ready():
        if not _actions.action_completed.is_connected(_on_action_completed):
            _actions.action_completed.connect(_on_action_completed)
        if not _actions.action_failed.is_connected(_on_action_failed):
            _actions.action_failed.connect(_on_action_failed)

func is_ready() -> bool:
    return _world != null and _state != null and _profiles != null and _actions != null and _actions.is_ready() \
        and _sound != null and _sound.is_ready() and _health != null

func _on_action_completed(actor_id: String, vehicle_id: String, _serial: int, action_type: StringName, _reason: String) -> void:
    if not _state.has_vehicle(vehicle_id):
        return
    if action_type not in [VehicleActionService.MOVE, VehicleActionService.TURN_LEFT, VehicleActionService.TURN_RIGHT, VehicleActionService.REVERSE, VehicleActionService.BRAKE, VehicleActionService.START]:
        return
    var placement := _world.placement(vehicle_id)
    if placement == null:
        return
    var kind := StringName(_state.record(vehicle_id).get("kind", &""))
    var profile_id := _sound_profile(kind)
    if not String(profile_id).is_empty():
        _sound.emit_sound(profile_id, placement.anchor, vehicle_id, "vehicle:%s" % vehicle_id)

func _on_action_failed(actor_id: String, vehicle_id: String, _serial: int, _action_type: StringName, reason: String) -> void:
    if reason != "vehicle_collision" or not _state.has_vehicle(vehicle_id):
        return
    var placement := _world.placement(vehicle_id)
    if placement != null:
        _sound.emit_sound(SoundProfiles.VEHICLE_IMPACT, placement.anchor, vehicle_id, "vehicle.impact:%s" % vehicle_id)
    if not _health.has_actor(actor_id):
        return
    var kind := StringName(_state.record(vehicle_id).get("kind", &""))
    var damage: int = 4
    match kind:
        VehicleProfileCatalog.BICYCLE:
            damage = 7
        VehicleProfileCatalog.MOTORCYCLE:
            damage = 10
        VehicleProfileCatalog.CAR:
            damage = 5
        VehicleProfileCatalog.TRUCK:
            damage = 6
        VehicleProfileCatalog.SKATEBOARD:
            damage = 3
    _health.apply_damage(actor_id, damage)

func _sound_profile(kind: StringName) -> StringName:
    match kind:
        VehicleProfileCatalog.SKATEBOARD:
            return SoundProfiles.VEHICLE_SKATEBOARD
        VehicleProfileCatalog.BICYCLE:
            return SoundProfiles.VEHICLE_BICYCLE
        VehicleProfileCatalog.MOTORCYCLE:
            return SoundProfiles.VEHICLE_MOTORCYCLE
        VehicleProfileCatalog.CAR:
            return SoundProfiles.VEHICLE_CAR
        VehicleProfileCatalog.TRUCK:
            return SoundProfiles.VEHICLE_TRUCK
        _:
            return &""
