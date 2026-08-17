extends Node
class_name CanonicalDemoMain

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const CollisionCatalogClass = preload("res://scripts/simulation/collision/CollisionCatalog.gd")
const CollisionOverridesClass = preload("res://scripts/simulation/collision/CollisionOverrideState.gd")
const SpatialQueryClass = preload("res://scripts/simulation/collision/SpatialQueryService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const BaseTraversalPolicyClass = preload("res://scripts/simulation/movement/MovementTraversalPolicy.gd")
const MovementActionServiceClass = preload("res://scripts/simulation/movement/MovementActionService.gd")
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
const SkillStateClass = preload("res://scripts/simulation/actors/skills/ActorSkillState.gd")
const PhysicalCatalogClass = preload("res://scripts/simulation/items/properties/ItemPhysicalPropertyCatalog.gd")
const WeightQueryClass = preload("res://scripts/simulation/items/properties/ItemWeightQuery.gd")
const CarryStateClass = preload("res://scripts/simulation/actors/carry/ActorCarryState.gd")
const CarryQueryClass = preload("res://scripts/simulation/actors/carry/ActorCarryQuery.gd")
const MoodletServiceClass = preload("res://scripts/simulation/actors/moodlets/ActorMoodletService.gd")
const StatusSummaryClass = preload("res://scripts/ui/ActorStatusSummaryQuery.gd")
const InspectionQueryClass = preload("res://scripts/ui/FacingInspectionQuery.gd")
const StatsInspectorClass = preload("res://scripts/ui/ActorStatsInspectorQuery.gd")
const InventoryInspectorClass = preload("res://scripts/ui/ActorInventoryInspectorQuery.gd")
const ArtCatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const FixtureClass = preload("res://scripts/demo/CanonicalDemoFixture.gd")
const ControllerClass = preload("res://scripts/player/DemoPlayerActionController.gd")

## Canonical demo bootstrap/composition only.
## Gameplay, map authoring, rendering, input mapping, and UI geometry live in focused owners.

@onready var _world_view: TacticalRendererStack = $WorldView
@onready var _keyboard: KeyboardInputAdapter = $KeyboardInput
@onready var _controls: DemoMovementControls = $Controls
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
var _controller: DemoPlayerActionController = null

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

    if not FixtureClass.build(
        _world,
        _world_mutations,
        _collision_catalog,
        _base_traversal
    ):
        return false

    _locomotion_state = LocomotionStateClass.new()
    _locomotion_mutations = LocomotionMutationClass.new(_locomotion_state)
    if not _locomotion_mutations.enroll(FixtureClass.PLAYER_ID):
        return false

    if not _boot_actor_status():
        return false

    _movement_capability = MovementCapabilityClass.new(_locomotion_state)
    _actor_traversal = ActorTraversalPolicyClass.new(_base_traversal, _movement_capability)
    _spatial_query = SpatialQueryClass.new(
        _world,
        _collision_catalog,
        _collision_overrides
    )
    _kernel = TickKernelClass.new(FixtureClass.PLAYER_ID)
    _movement = MovementActionServiceClass.new(
        _world,
        _world_mutations,
        _spatial_query,
        _kernel,
        _actor_traversal
    )
    if not _movement.is_ready():
        return false

    _stance_actions = StanceActionClass.new(
        _world,
        _locomotion_state,
        _locomotion_mutations,
        _kernel,
        _movement_capability
    )
    if not _stance_actions.is_ready():
        return false

    _art_catalog = ArtCatalogClass.new()
    _door_state = DoorStateClass.new()
    if not _world_view.configure(
        _world,
        _art_catalog,
        _door_state,
        FixtureClass.PLAYER_ID
    ):
        return false
    if not _world_view.set_visible_window(
        FixtureClass.MAP_ORIGIN,
        FixtureClass.MAP_SIZE,
        38.0
    ):
        return false

    _status_summary = StatusSummaryClass.new(
        _health_state,
        _needs_state,
        _carry_query,
        _moodlet_service
    )
    _inspection_query = InspectionQueryClass.new(_world)
    if not _hud.configure(
        _kernel,
        _status_summary,
        _inspection_query,
        FixtureClass.PLAYER_ID
    ):
        return false

    _stats_inspector = StatsInspectorClass.new(
        _status_summary,
        _health_state,
        _skill_state,
        _locomotion_state
    )
    _inventory_inspector = InventoryInspectorClass.new(
        _world,
        _hand_state,
        _inventory_state,
        _weight_query,
        _carry_query
    )
    if not _shell.configure(
        _kernel,
        _stats_inspector,
        _inventory_inspector,
        FixtureClass.PLAYER_ID
    ):
        return false
    if not _controls.configure_stance(_locomotion_state, FixtureClass.PLAYER_ID):
        return false

    _controller = ControllerClass.new(
        _movement,
        _kernel,
        FixtureClass.PLAYER_ID,
        _stance_actions,
        _locomotion_state
    )
    if not _controller.is_ready() or not _controller.stance_ready():
        return false

    _keyboard.action_intent.connect(Callable(_controller, "submit_intent"))
    _controls.action_intent.connect(Callable(_controller, "submit_intent"))
    _controller.action_resolved.connect(Callable(_hud, "present_action_result"))
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

    _carry_query = CarryQueryClass.new(
        _world,
        _hand_state,
        _inventory_state,
        _weight_query,
        _carry_state
    )
    _moodlet_service = MoodletServiceClass.new(
        _health_state,
        _needs_state,
        _carry_query
    )
    return true

func _on_interaction_blocked_changed(blocked: bool) -> void:
    _keyboard.set_enabled(not blocked)
    _controls.set_enabled(not blocked)
