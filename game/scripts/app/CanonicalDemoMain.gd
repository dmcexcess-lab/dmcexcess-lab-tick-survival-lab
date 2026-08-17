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
const ArtCatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const FixtureClass = preload("res://scripts/demo/CanonicalDemoFixture.gd")
const ControllerClass = preload("res://scripts/player/DemoPlayerActionController.gd")

## Canonical demo bootstrap/composition only.
## Gameplay, map authoring, rendering, input mapping, and UI geometry live in focused owners.

@onready var _world_view: TacticalRendererStack = $WorldView
@onready var _keyboard: KeyboardInputAdapter = $KeyboardInput
@onready var _controls: DemoMovementControls = $Controls

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

    _controller = ControllerClass.new(
        _movement,
        _kernel,
        FixtureClass.PLAYER_ID
    )
    if not _controller.is_ready():
        return false

    _keyboard.action_intent.connect(Callable(_controller, "submit_intent"))
    _controls.action_intent.connect(Callable(_controller, "submit_intent"))
    _controller.action_resolved.connect(Callable(_controls, "present_action_result"))
    return true
