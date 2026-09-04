extends RefCounted
class_name VehicleLightingSourceAdapter

const EmitterClass = preload("res://scripts/simulation/lighting/LightEmitter.gd")
const EmitterProfileClass = preload("res://scripts/simulation/lighting/LightEmitterProfile.gd")

signal emitters_changed(emitters)

var _world: WorldState
var _state: VehicleState
var _profiles: VehicleProfileCatalog
var _signature: String = ""

func _init(world: WorldState, state: VehicleState, profiles: VehicleProfileCatalog) -> void:
    _world = world
    _state = state
    _profiles = profiles
    if is_ready():
        _signature = _current_signature()
        if not _state.changed.is_connected(_on_vehicle_changed):
            _state.changed.connect(_on_vehicle_changed)
        if not _state.state_reset.is_connected(_on_state_reset):
            _state.state_reset.connect(_on_state_reset)
        if not _world.changed.is_connected(_on_world_changed):
            _world.changed.connect(_on_world_changed)

func is_ready() -> bool:
    return _world != null and _state != null and _profiles != null

func emitters() -> Array[LightEmitter]:
    var result: Array[LightEmitter] = []
    if not is_ready():
        return result
    for vehicle_id: String in _state.vehicle_ids():
        var rec := _state.record(vehicle_id)
        var kind := StringName(rec.get("kind", &""))
        if not _profiles.is_motorized(kind) or not bool(rec.get("powered", false)) or int(rec.get("electrical", 0)) <= 0:
            continue
        var placement := _world.placement(vehicle_id)
        if placement == null:
            continue
        result.append(EmitterClass.new(
            "vehicle.headlights:%s" % vehicle_id,
            placement.anchor,
            VehicleHeading.cardinal_facing(int(rec.get("heading", 0))),
            _headlight_profile(),
            true,
            int(rec.get("version", 1))
        ))
    return result

func _headlight_profile() -> LightEmitterProfile:
    return EmitterProfileClass.new(
        &"light.vehicle_headlights.system36",
        EmitterProfileClass.Shape.CONE,
        16,
        1.05,
        Color(1.0, 0.96, 0.82),
        1.12,
        28.0,
        0.08,
        1.0
    )

func _current_signature() -> String:
    var parts: PackedStringArray = []
    for emitter: LightEmitter in emitters():
        parts.append(emitter.signature())
    return "||".join(parts)

func _emit_if_changed() -> void:
    var next := _current_signature()
    if next == _signature:
        return
    _signature = next
    emitters_changed.emit(emitters())

func _on_vehicle_changed(_vehicle_id: String, _revision: int) -> void:
    _emit_if_changed()

func _on_state_reset(_revision: int) -> void:
    _emit_if_changed()

func _on_world_changed(change: WorldChange) -> void:
    if change != null and _state.has_vehicle(change.entity_id):
        _emit_if_changed()
