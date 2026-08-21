extends Node
class_name CanonicalDemoMain

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const CollisionCatalogClass = preload("res://scripts/simulation/collision/CollisionCatalog.gd")
const CollisionOverridesClass = preload("res://scripts/simulation/collision/CollisionOverrideState.gd")
const SpatialQueryClass = preload("res://scripts/simulation/collision/SpatialQueryService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const BaseTraversalPolicyClass = preload("res://scripts/simulation/movement/MovementTraversalPolicy.gd")
const MovementActionServiceClass = preload("res://scripts/simulation/movement/PassageAwareMovementActionService.gd")
const MovementDamageInterruptionClass = preload("res://scripts/simulation/movement/MovementDamageInterruptionService.gd")
const MovementExertionClass = preload("res://scripts/simulation/movement/MovementExertionService.gd")
const MovementRunImpactDamageClass = preload("res://scripts/simulation/movement/MovementRunImpactDamageService.gd")
const LocomotionStateClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionState.gd")
const LocomotionMutationClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionMutationService.gd")
const MovementCapabilityClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementCapabilityService.gd")
const ActorTraversalPolicyClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementTraversalPolicy.gd")
const StanceActionClass = preload("res://scripts/simulation/actors/locomotion/ActorStanceActionService.gd")
const HandStateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const HandMutationClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd")
const InventoryStateClass = preload("res://scripts/simulation/inventory/InventoryContainmentState.gd")
const InventoryMutationClass = preload("res://scripts/simulation/inventory/InventoryContainmentMutationService.gd")
const HealthStateClass = preload("res://scripts/simulation/actors/health/ActorHealthState.gd")
const NeedsStateClass = preload("res://scripts/simulation/actors/needs/ActorNeedsState.gd")
const NeedsMobilityProviderClass = preload("res://scripts/simulation/actors/needs/ActorNeedsMobilityModifierProvider.gd")
const SkillStateClass = preload("res://scripts/simulation/actors/skills/ActorSkillState.gd")
const PhysicalCatalogClass = preload("res://scripts/simulation/items/properties/ItemPhysicalPropertyCatalog.gd")
const WeightQueryClass = preload("res://scripts/simulation/items/properties/ItemWeightQuery.gd")
const CarryStateClass = preload("res://scripts/simulation/actors/carry/ActorCarryState.gd")
const CarryQueryClass = preload("res://scripts/simulation/actors/carry/ActorCarryQuery.gd")
const CarryMobilityProviderClass = preload("res://scripts/simulation/actors/carry/ActorCarryMobilityModifierProvider.gd")
const MoodletServiceClass = preload("res://scripts/simulation/actors/moodlets/ActorMoodletService.gd")
const StatusSummaryClass = preload("res://scripts/ui/ActorStatusSummaryQuery.gd")
const InspectionQueryClass = preload("res://scripts/ui/FacingInspectionQuery.gd")
const StatsInspectorClass = preload("res://scripts/ui/ActorStatsInspectorQuery.gd")
const InventoryInspectorClass = preload("res://scripts/ui/ActorInventoryInspectorQuery.gd")
const ArtCatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const DoorMutationClass = preload("res://scripts/simulation/doors/DoorStateMutationService.gd")
const DoorTransitionClass = preload("res://scripts/simulation/doors/DoorPhysicalTransitionService.gd")
const DoorPassageClass = preload("res://scripts/simulation/doors/DoorMovementPassageResolver.gd")
const DoorActionClass = preload("res://scripts/simulation/doors/DoorInteractionActionService.gd")
const DoorDamageInterruptionClass = preload("res://scripts/simulation/doors/DoorDamageInterruptionService.gd")
const FixtureClass = preload("res://scripts/demo/RuralCrossroadsCritiqueFixture.gd")
const ControllerClass = preload("res://scripts/player/DemoPlayerActionController.gd")
const DoorControllerClass = preload("res://scripts/player/DoorPlayerInteractionController.gd")

## Canonical demo bootstrap/composition only.

@onready var _world_view: TacticalRendererStack = $WorldView
@onready var _camera_controller: TacticalCameraController = $CameraRig
@onready var _camera: Camera2D = $CameraRig/Camera2D
@onready var _large_area_view: LargeAreaRenderWindowController = $LargeAreaView
@onready var _keyboard: KeyboardInputAdapter = $KeyboardInput
@onready var _door_pointer: DoorPointerInputAdapter = $DoorPointerInput
@onready var _camera_input: CameraInputAdapter = $CameraInput
@onready var _controls: DemoMovementControls = $Controls
@onready var _camera_controls: CameraControls = $CameraControls
@onready var _hud: CanonicalStatusHud = $Hud
@onready var _shell: CanonicalPlayerShell = $PlayerShell

var _world: WorldState = null
var _world_mutations: WorldMutationService = null
var _collision_catalog: CollisionCatalog = null
var _collision_overrides: CollisionOverrideState = null
var _spatial_query: SpatialQueryService = null
var _kernel: TickKernel = null
var _base_traversal: MovementTraversalPolicy = null
var _locomotion_state: ActorLocomotionState = null
var _locomotion_mutations: ActorLocomotionMutationService = null
var _movement_capability: ActorMovementCapabilityService = null
var _actor_traversal: ActorMovementTraversalPolicy = null
var _movement: MovementActionService = null
var _movement_damage_interrupt: MovementDamageInterruptionService = null
var _movement_exertion: MovementExertionService = null
var _movement_run_impact_damage: MovementRunImpactDamageService = null
var _stance_actions: ActorStanceActionService = null
var _hand_state: ActorHandEquipmentState = null
var _hand_mutations: ActorHandEquipmentMutationService = null
var _inventory_state: InventoryContainmentState = null
var _inventory_mutations: InventoryContainmentMutationService = null
var _health_state: ActorHealthState = null
var _needs_state: ActorNeedsState = null
var _skill_state: ActorSkillState = null
var _physical_catalog: ItemPhysicalPropertyCatalog = null
var _weight_query: ItemWeightQuery = null
var _carry_state: ActorCarryState = null
var _carry_query: ActorCarryQuery = null
var _moodlet_service: ActorMoodletService = null
var _status_summary: ActorStatusSummaryQuery = null
var _inspection_query: FacingInspectionQuery = null
var _stats_inspector: ActorStatsInspectorQuery = null
var _inventory_inspector: ActorInventoryInspectorQuery = null
var _art_catalog: ArtCatalog = null
var _door_state: DoorStateStore = null
var _door_mutations: DoorStateMutationService = null
var _door_transition: DoorPhysicalTransitionService = null
var _door_passage: DoorMovementPassageResolver = null
var _door_actions: DoorInteractionActionService = null
var _door_damage_interrupt: DoorDamageInterruptionService = null
var _controller: DemoPlayerActionController = null
var _door_controller: DoorPlayerInteractionController = null

func _ready() -> void:
    if not _boot_canonical_demo():
        push_error("CanonicalDemoMain: boot failed")
        print("CANONICAL_DEMO_BOOT_FAILED")
        return
    print("CANONICAL_DEMO_BOOT_OK")

func _boot_canonical_demo() -> bool:
    _world = WorldStateClass.new()
    _world_mutations = WorldMutationClass.new(_world)
    _collision_catalog = CollisionCatalogClass.new()
    _collision_overrides = CollisionOverridesClass.new()
    _base_traversal = BaseTraversalPolicyClass.new()
    _door_state = DoorStateClass.new()
    _door_mutations = DoorMutationClass.new(_door_state, _world)

    if not FixtureClass.build(
        _world,
        _world_mutations,
        _collision_catalog,
        _base_traversal,
        _door_state,
        _door_mutations
    ):
        return false

    _locomotion_state = LocomotionStateClass.new()
    _locomotion_mutations = LocomotionMutationClass.new(_locomotion_state)
    if not _locomotion_mutations.enroll(FixtureClass.PLAYER_ID):
        return false
    if not _boot_actor_status():
        return false

    _movement_capability = MovementCapabilityClass.new(_locomotion_state)
    if not _movement_capability.register_provider(NeedsMobilityProviderClass.new(_needs_state)):
        return false
    if not _movement_capability.register_provider(CarryMobilityProviderClass.new(_carry_query)):
        return false
    _actor_traversal = ActorTraversalPolicyClass.new(_base_traversal, _movement_capability)
    _spatial_query = SpatialQueryClass.new(_world, _collision_catalog, _collision_overrides)
    _kernel = TickKernelClass.new(FixtureClass.PLAYER_ID)

    _door_transition = DoorTransitionClass.new(_world, _door_state, _door_mutations, _collision_overrides)
    _door_passage = DoorPassageClass.new(_world, _door_state, _door_transition)
    if not _door_transition.is_ready() or not _door_passage.is_ready():
        return false

    _movement = MovementActionServiceClass.new(
        _world,
        _world_mutations,
        _spatial_query,
        _kernel,
        _actor_traversal,
        _door_passage
    )
    if not _movement.is_ready():
        return false

    _movement_damage_interrupt = MovementDamageInterruptionClass.new(_health_state, _kernel)
    _movement_exertion = MovementExertionClass.new(_movement, _needs_state, _carry_query)
    _movement_run_impact_damage = MovementRunImpactDamageClass.new(_movement, _health_state)
    if not _movement_damage_interrupt.is_ready() or not _movement_exertion.is_ready() or not _movement_run_impact_damage.is_ready():
        return false

    _stance_actions = StanceActionClass.new(_world, _locomotion_state, _locomotion_mutations, _kernel, _movement_capability)
    if not _stance_actions.is_ready():
        return false

    _door_actions = DoorActionClass.new(_world, _door_state, _kernel, _door_transition)
    _door_damage_interrupt = DoorDamageInterruptionClass.new(_health_state, _kernel)
    if not _door_actions.is_ready() or not _door_damage_interrupt.is_ready():
        return false

    _art_catalog = ArtCatalogClass.new()
    if not _world_view.configure(_world, _art_catalog, _door_state, FixtureClass.PLAYER_ID):
        return false

    var initial_render_origin: Vector2i = FixtureClass.initial_render_origin(_world)
    if not _large_area_view.configure(
        _world_view,
        _world_view,
        _door_pointer,
        FixtureClass.AREA_BOUNDS,
        FixtureClass.RENDER_WINDOW_SIZE,
        FixtureClass.CELL_PIXELS,
        initial_render_origin,
        Vector2.ZERO
    ):
        return false

    _camera_controller.presentation_changed.connect(Callable(_camera_controls, "present_camera_state"))
    _camera_input.zoom_in_requested.connect(Callable(_camera_controller, "zoom_in"))
    _camera_input.zoom_out_requested.connect(Callable(_camera_controller, "zoom_out"))
    _camera_input.pan_requested.connect(Callable(_camera_controller, "pan_screen_pixels"))
    _camera_input.recenter_requested.connect(Callable(_camera_controller, "recenter_player"))
    _camera_controls.zoom_in_requested.connect(Callable(_camera_controller, "zoom_in"))
    _camera_controls.zoom_out_requested.connect(Callable(_camera_controller, "zoom_out"))
    _camera_controls.recenter_requested.connect(Callable(_camera_controller, "recenter_player"))
    if not _camera_controller.configure(
        _world,
        _camera,
        _world_view,
        FixtureClass.PLAYER_ID,
        initial_render_origin,
        FixtureClass.CELL_PIXELS
    ):
        return false
    if not _large_area_view.attach_camera(_camera_controller):
        return false
    _camera_controls.present_camera_state(_camera_controller.presentation_snapshot())

    _status_summary = StatusSummaryClass.new(_health_state, _needs_state, _carry_query, _moodlet_service)
    _inspection_query = InspectionQueryClass.new(_world)
    if not _hud.configure(_kernel, _status_summary, _inspection_query, FixtureClass.PLAYER_ID):
        return false

    _stats_inspector = StatsInspectorClass.new(_status_summary, _health_state, _skill_state, _locomotion_state)
    _inventory_inspector = InventoryInspectorClass.new(_world, _hand_state, _inventory_state, _weight_query, _carry_query)
    if not _shell.configure(_kernel, _stats_inspector, _inventory_inspector, FixtureClass.PLAYER_ID):
        return false
    if not _controls.configure_stance(_locomotion_state, FixtureClass.PLAYER_ID):
        return false

    _controller = ControllerClass.new(_movement, _kernel, FixtureClass.PLAYER_ID, _stance_actions, _locomotion_state)
    _door_controller = DoorControllerClass.new(_world, _door_actions, _kernel, FixtureClass.PLAYER_ID)
    if not _controller.is_ready() or not _controller.stance_ready() or not _door_controller.is_ready():
        return false

    _keyboard.action_intent.connect(Callable(_controller, "submit_intent"))
    _controls.action_intent.connect(Callable(_controller, "submit_intent"))
    _door_pointer.world_cell_primary.connect(Callable(_door_controller, "submit_world_cell"))
    _controller.action_resolved.connect(Callable(_hud, "present_action_result"))
    _door_controller.action_resolved.connect(Callable(_hud, "present_action_result"))
    _shell.interaction_blocked_changed.connect(_on_interaction_blocked_changed)
    return true

func _boot_actor_status() -> bool:
    _hand_state = HandStateClass.new()
    _hand_mutations = HandMutationClass.new(_hand_state, _world)
    if not _hand_mutations.enroll_actor(FixtureClass.PLAYER_ID):
        return false
    _inventory_state = InventoryStateClass.new()
    _inventory_mutations = InventoryMutationClass.new(_inventory_state, _world)
    if not _inventory_mutations.enroll_container(FixtureClass.PLAYER_ID):
        return false
    _health_state = HealthStateClass.new(_world)
    if not _health_state.enroll_actor(FixtureClass.PLAYER_ID):
        return false
    _needs_state = NeedsStateClass.new(_world)
    if not _needs_state.enroll_actor(FixtureClass.PLAYER_ID):
        return false
    _skill_state = SkillStateClass.new(_world)
    if not _skill_state.enroll_actor(FixtureClass.PLAYER_ID):
        return false
    _physical_catalog = PhysicalCatalogClass.new()
    _weight_query = WeightQueryClass.new(_world, _physical_catalog)
    _carry_state = CarryStateClass.new(_world)
    if not _carry_state.enroll_actor(FixtureClass.PLAYER_ID):
        return false
    _carry_query = CarryQueryClass.new(_world, _hand_state, _inventory_state, _weight_query, _carry_state)
    _moodlet_service = MoodletServiceClass.new(_health_state, _needs_state, _carry_query)
    return true

func _on_interaction_blocked_changed(blocked: bool) -> void:
    _keyboard.set_enabled(not blocked)
    _controls.set_enabled(not blocked)
    _door_pointer.set_enabled(not blocked)
    _camera_input.set_enabled(not blocked)
    _camera_controls.set_enabled(not blocked)
