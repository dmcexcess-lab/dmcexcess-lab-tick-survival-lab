extends System34GameMain
class_name VehicleGameMain

const VehicleProfilesClass = preload("res://scripts/simulation/vehicles/VehicleProfileCatalog.gd")
const VehicleStateClass = preload("res://scripts/simulation/vehicles/VehicleState.gd")
const VehicleSeederClass = preload("res://scripts/simulation/vehicles/VehicleWorldSeeder.gd")
const VehicleActionsClass = preload("res://scripts/simulation/vehicles/VehicleActionService.gd")
const VehicleCargoClass = preload("res://scripts/simulation/vehicles/VehicleCargoService.gd")
const VehicleConsequencesClass = preload("res://scripts/simulation/vehicles/VehicleConsequenceAdapter.gd")
const VehicleLightingClass = preload("res://scripts/simulation/vehicles/VehicleLightingSourceAdapter.gd")
const VehicleItems = preload("res://scripts/simulation/vehicles/VehicleItemCatalog.gd")
const VehicleControllerClass = preload("res://scripts/player/VehiclePlayerController.gd")
const VehicleControlsClass = preload("res://scripts/ui/VehiclePlayerControls.gd")

var _vehicle_profiles: VehicleProfileCatalog = null
var _vehicle_state: VehicleState = null
var _vehicle_seeder: VehicleWorldSeeder = null
var _vehicle_actions: VehicleActionService = null
var _vehicle_cargo: VehicleCargoService = null
var _vehicle_consequences: VehicleConsequenceAdapter = null
var _vehicle_lighting: VehicleLightingSourceAdapter = null
var _vehicle_controller: VehiclePlayerController = null
var _vehicle_controls: VehiclePlayerControls = null

func _boot_canonical_demo() -> bool:
    if not super._boot_canonical_demo():
        return false
    return _boot_system36()

func _boot_system36() -> bool:
    if _world == null or _world_mutations == null or _spatial_query == null or _collision_catalog == null \
        or _collision_overrides == null or _kernel == null or _skill_checks == null or _condition_service == null \
        or _inventory_state == null or _inventory_mutations == null or _weight_query == null or _physical_catalog == null \
        or _spatial_sound == null or _health_state == null or _utility_lighting == null or _physical_lighting == null:
        return false
    _vehicle_profiles = VehicleProfilesClass.new()
    _vehicle_state = VehicleStateClass.new()
    if not VehicleItems.register_physical_profiles(_physical_catalog):
        return false
    _vehicle_seeder = VehicleSeederClass.new(
        _world,
        _world_mutations,
        _spatial_query,
        _collision_catalog,
        _inventory_mutations,
        _vehicle_profiles,
        _vehicle_state,
        FixtureClass.active_seed()
    )
    var seeded := _vehicle_seeder.seed_near(FixtureClass.PLAYER_ID)
    if seeded < 1:
        push_error("VehicleGameMain: no plausible parked vehicle locations were generated near the playable start")
        return false
    _vehicle_actions = VehicleActionsClass.new(
        _world,
        _world_mutations,
        _spatial_query,
        _collision_overrides,
        _kernel,
        _skill_checks,
        _condition_service,
        _inventory_state,
        _inventory_mutations,
        _vehicle_profiles,
        _vehicle_state
    )
    if not _vehicle_actions.is_ready():
        return false
    _vehicle_cargo = VehicleCargoClass.new(
        _world,
        _vehicle_state,
        _vehicle_profiles,
        _inventory_state,
        _inventory_mutations,
        _weight_query
    )
    if not _vehicle_cargo.is_ready():
        return false

    _vehicle_consequences = VehicleConsequencesClass.new(
        _world,
        _vehicle_state,
        _vehicle_profiles,
        _vehicle_actions,
        _spatial_sound,
        _health_state
    )
    if not _vehicle_consequences.is_ready():
        return false

    _vehicle_lighting = VehicleLightingClass.new(_world, _vehicle_state, _vehicle_profiles)
    if not _vehicle_lighting.is_ready() or not _wire_vehicle_lighting():
        return false

    _vehicle_controller = VehicleControllerClass.new(_vehicle_actions, _kernel, FixtureClass.PLAYER_ID)
    add_child(_vehicle_controller)
    if not _vehicle_controller.is_ready():
        return false

    var base_callable := Callable(_controller, "submit_intent")
    if _keyboard.action_intent.is_connected(base_callable):
        _keyboard.action_intent.disconnect(base_callable)
    if _controls.action_intent.is_connected(base_callable):
        _controls.action_intent.disconnect(base_callable)
    _keyboard.action_intent.connect(_route_player_intent)
    _controls.action_intent.connect(_route_player_intent)
    _vehicle_controller.action_resolved.connect(Callable(_hud, "present_action_result"))
    _vehicle_controller.action_busy_changed.connect(_on_player_action_busy_changed)

    if not _world_view.configure_vehicles(_world, _vehicle_state, _vehicle_profiles):
        return false
    _vehicle_controls = VehicleControlsClass.new()
    add_child(_vehicle_controls)
    if not _vehicle_controls.configure(
        _vehicle_controller,
        _vehicle_actions,
        _vehicle_state,
        _vehicle_cargo,
        _inventory_state,
        FixtureClass.PLAYER_ID
    ):
        return false
    return true

func _route_player_intent(intent: StringName) -> void:
    if _vehicle_controller != null and _vehicle_controller.is_mounted():
        _vehicle_controller.submit_intent(intent)
    elif _controller != null:
        _controller.submit_intent(intent)

func _wire_vehicle_lighting() -> bool:
    if _vehicle_lighting == null or _utility_lighting == null or _physical_lighting == null:
        return false
    var inherited_callable := Callable(self, "_on_demo_lighting_emitters_changed")
    if _utility_lighting.emitters_changed.is_connected(inherited_callable):
        _utility_lighting.emitters_changed.disconnect(inherited_callable)
    var combined_callable := Callable(self, "_on_vehicle_lighting_inputs_changed")
    if not _utility_lighting.emitters_changed.is_connected(combined_callable):
        _utility_lighting.emitters_changed.connect(combined_callable)
    if not _vehicle_lighting.emitters_changed.is_connected(combined_callable):
        _vehicle_lighting.emitters_changed.connect(combined_callable)
    return _sync_vehicle_lighting_emitters()

func _sync_vehicle_lighting_emitters() -> bool:
    if _utility_lighting == null or _vehicle_lighting == null or _physical_lighting == null:
        return false
    var combined: Array[LightEmitter] = []
    for emitter: LightEmitter in _utility_lighting.emitters():
        combined.append(emitter)
    for emitter: LightEmitter in _vehicle_lighting.emitters():
        combined.append(emitter)
    return _physical_lighting.set_emitters(combined)

func _on_vehicle_lighting_inputs_changed(_emitters: Array) -> void:
    if not _sync_vehicle_lighting_emitters():
        return
    _lighting_refresh_pending = true
    call_deferred("_flush_pending_visual_state")
