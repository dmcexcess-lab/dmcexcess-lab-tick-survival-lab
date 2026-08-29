extends Node
class_name CanonicalDemoMain

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const CollisionCatalogClass = preload("res://scripts/simulation/collision/CollisionCatalog.gd")
const CollisionOverridesClass = preload("res://scripts/simulation/collision/CollisionOverrideState.gd")
const SpatialQueryClass = preload("res://scripts/simulation/collision/SpatialQueryService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const WorldTimeProfileClass = preload("res://scripts/simulation/world_time/WorldTimeProfile.gd")
const WorldTimeServiceClass = preload("res://scripts/simulation/world_time/WorldTimeService.gd")
const DaylightProfileClass = preload("res://scripts/simulation/world_time/DaylightProfile.gd")
const OutdoorAmbientLightServiceClass = preload("res://scripts/simulation/world_time/OutdoorAmbientLightService.gd")
const PhysicalLightingClass = preload("res://scripts/simulation/lighting/PhysicalLightingService.gd")
const LightingAcquisitionClass = preload("res://scripts/simulation/lighting/IlluminationVisualAcquisitionProvider.gd")
const DemoLightingSourceClass = preload("res://scripts/demo/DemoLightingSourceAdapter.gd")
const WeatherServiceClass = preload("res://scripts/simulation/weather/WeatherService.gd")
const SkyExposureClass = preload("res://scripts/simulation/weather/SkyExposureQuery.gd")
const WeatherOpticsClass = preload("res://scripts/simulation/weather/WeatherAtmosphericOpticsAdapter.gd")
const WeatherAcousticClass = preload("res://scripts/simulation/weather/WeatherAcousticEnvironmentModifier.gd")
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
const FreshProfileCatalogClass = preload("res://scripts/simulation/items/freshness/ItemFreshnessProfileCatalog.gd")
const FreshStateClass = preload("res://scripts/simulation/items/freshness/ItemFreshnessState.gd")
const FreshAmbientClass = preload("res://scripts/simulation/items/freshness/AmbientSpoilageEnvironmentProvider.gd")
const FreshMutationClass = preload("res://scripts/simulation/items/freshness/ItemFreshnessMutationService.gd")
const FreshQueryClass = preload("res://scripts/simulation/items/freshness/ItemFreshnessQuery.gd")
const CarryStateClass = preload("res://scripts/simulation/actors/carry/ActorCarryState.gd")
const CarryQueryClass = preload("res://scripts/simulation/actors/carry/ActorCarryQuery.gd")
const CarryMobilityProviderClass = preload("res://scripts/simulation/actors/carry/ActorCarryMobilityModifierProvider.gd")
const CarryAcquisitionClass = preload("res://scripts/simulation/actors/carry/ActorCarryAcquisitionPolicy.gd")
const MoodletServiceClass = preload("res://scripts/simulation/actors/moodlets/ActorMoodletService.gd")
const ItemTransferActionTypes = preload("res://scripts/simulation/items/transfer/ItemTransferActionType.gd")
const ItemTransferTimingClass = preload("res://scripts/simulation/items/transfer/ItemTransferTimingPolicy.gd")
const PolicyTransferClass = preload("res://scripts/simulation/items/transfer/PolicyAwareItemTransferActionService.gd")
const LootItemCatalogClass = preload("res://scripts/simulation/loot/LootItemCatalog.gd")
const LootContainerCatalogClass = preload("res://scripts/simulation/loot/LootContainerProfileCatalog.gd")
const LootStateClass = preload("res://scripts/simulation/loot/LootState.gd")
const LootInitializerClass = preload("res://scripts/simulation/loot/LootSourceInitializer.gd")
const LootAccessClass = preload("res://scripts/simulation/loot/LootWorldContainerAccessPolicy.gd")
const LootSearchClass = preload("res://scripts/simulation/loot/LootSearchActionService.gd")
const LootInspectionClass = preload("res://scripts/simulation/loot/LootContainerInspectionQuery.gd")
const InteractionReachClass = preload("res://scripts/simulation/interaction/WorldInteractionReachQuery.gd")
const InteractionAffordanceClass = preload("res://scripts/simulation/interaction/InteractionAffordanceQuery.gd")
const LootInteractionOfferProviderClass = preload("res://scripts/simulation/loot/LootSearchInteractionOfferProvider.gd")
const SoundProfilesClass = preload("res://scripts/simulation/sound/SoundEmissionProfileCatalog.gd")
const AcousticMaterialsClass = preload("res://scripts/simulation/sound/AcousticMaterialCatalog.gd")
const AcousticPropagationClass = preload("res://scripts/simulation/sound/AcousticPropagationQuery.gd")
const HearingProfileClass = preload("res://scripts/simulation/sound/SurvivorHearingProfileProvider.gd")
const HeardSoundStoreClass = preload("res://scripts/simulation/sound/HeardSoundObservationStore.gd")
const SpatialSoundClass = preload("res://scripts/simulation/sound/SpatialSoundService.gd")
const ActionSoundEmitterClass = preload("res://scripts/simulation/sound/ActionSoundEmitterAdapter.gd")
const StatusSummaryClass = preload("res://scripts/ui/ActorStatusSummaryQuery.gd")
const InspectionQueryClass = preload("res://scripts/ui/FacingInspectionQuery.gd")
const StatsInspectorClass = preload("res://scripts/ui/ActorStatsInspectorQuery.gd")
const InventoryInspectorClass = preload("res://scripts/ui/ActorInventoryInspectorQuery.gd")
const SemanticUiIconCatalogClass = preload("res://scripts/ui/icons/SemanticUiIconCatalog.gd")
const ArtCatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const DoorMutationClass = preload("res://scripts/simulation/doors/DoorStateMutationService.gd")
const DoorTransitionClass = preload("res://scripts/simulation/doors/DoorPhysicalTransitionService.gd")
const DoorPassageClass = preload("res://scripts/simulation/doors/DoorMovementPassageResolver.gd")
const DoorActionClass = preload("res://scripts/simulation/doors/DoorInteractionActionService.gd")
const DoorDamageInterruptionClass = preload("res://scripts/simulation/doors/DoorDamageInterruptionService.gd")
const VisionProfileClass = preload("res://scripts/simulation/perception/VisionProfile.gd")
const PerceptionMemoryClass = preload("res://scripts/simulation/perception/PerceptionMemoryStore.gd")
const ObserverPerceptionClass = preload("res://scripts/simulation/perception/ObserverPerceptionService.gd")
const FixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const ControllerClass = preload("res://scripts/player/DemoPlayerActionController.gd")
const DoorControllerClass = preload("res://scripts/player/DoorPlayerInteractionController.gd")
const LootControllerClass = preload("res://scripts/player/LootPlayerInteractionController.gd")

## Canonical demo bootstrap/composition only.

const LIVE_ITEM_TRANSFER_TICKS: int = 5

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
@onready var _loot_panel: LootContainerPanel = $LootPanel
@onready var _weather_controls: WeatherDevControls = $WeatherControls

var _world: WorldState = null
var _world_mutations: WorldMutationService = null
var _collision_catalog: CollisionCatalog = null
var _collision_overrides: CollisionOverrideState = null
var _spatial_query: SpatialQueryService = null
var _kernel: TickKernel = null
var _world_time_profile: WorldTimeProfile = null
var _world_time: WorldTimeService = null
var _ambient_daylight: OutdoorAmbientLightService = null
var _physical_lighting: PhysicalLightingService = null
var _demo_lighting_sources: DemoLightingSourceAdapter = null
var _weather: WeatherService = null
var _sky_exposure: SkyExposureQuery = null
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
var _freshness_profiles: ItemFreshnessProfileCatalog = null
var _freshness_state: ItemFreshnessState = null
var _freshness_ambient: AmbientSpoilageEnvironmentProvider = null
var _freshness_mutations: ItemFreshnessMutationService = null
var _freshness_query: ItemFreshnessQuery = null
var _carry_state: ActorCarryState = null
var _carry_query: ActorCarryQuery = null
var _carry_acquisition: ItemAcquisitionCapacityPolicy = null
var _moodlet_service: ActorMoodletService = null
var _loot_items: LootItemCatalog = null
var _loot_profiles: LootContainerProfileCatalog = null
var _loot_state: LootState = null
var _loot_initializer: LootSourceInitializer = null
var _loot_access: ItemContainerAccessPolicy = null
var _item_transfer_timing: ItemTransferTimingPolicy = null
var _item_transfer: ItemTransferActionService = null
var _loot_search: LootSearchActionService = null
var _loot_inspection: LootContainerInspectionQuery = null
var _interaction_reach: WorldInteractionReachQuery = null
var _loot_interaction_offers: LootSearchInteractionOfferProvider = null
var _interaction_affordances: InteractionAffordanceQuery = null
var _sound_profiles: SoundEmissionProfileCatalog = null
var _acoustic_materials: AcousticMaterialCatalog = null
var _acoustic_propagation: AcousticPropagationQuery = null
var _hearing_profile: SurvivorHearingProfileProvider = null
var _heard_sounds: HeardSoundObservationStore = null
var _spatial_sound: SpatialSoundService = null
var _action_sound_emitters: ActionSoundEmitterAdapter = null
var _status_summary: ActorStatusSummaryQuery = null
var _inspection_query: FacingInspectionQuery = null
var _stats_inspector: ActorStatsInspectorQuery = null
var _inventory_inspector: ActorInventoryInspectorQuery = null
var _ui_icons: SemanticUiIconCatalog = null
var _art_catalog: ArtCatalog = null
var _door_state: DoorStateStore = null
var _door_mutations: DoorStateMutationService = null
var _door_transition: DoorPhysicalTransitionService = null
var _door_passage: DoorMovementPassageResolver = null
var _door_actions: DoorInteractionActionService = null
var _door_damage_interrupt: DoorDamageInterruptionService = null
var _perception_memory: PerceptionMemoryStore = null
var _perception: ObserverPerceptionService = null
var _controller: DemoPlayerActionController = null
var _door_controller: DoorPlayerInteractionController = null
var _loot_controller: LootPlayerInteractionController = null
var _shell_blocks_interaction: bool = false
var _loot_blocks_interaction: bool = false
var _action_blocks_interaction: bool = false

func _ready() -> void:
    if not _boot_canonical_demo():
        push_error("CanonicalDemoMain: boot failed")
        print("CANONICAL_DEMO_BOOT_FAILED")
        return
    print("CANONICAL_DEMO_BOOT_OK")

func _boot_canonical_demo() -> bool:
    _world = WorldStateClass.new()
    _world_mutations = WorldMutationClass.new(_world)
    _world_time_profile = WorldTimeProfileClass.new()
    if not _world_time_profile.is_valid():
        return false
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
    if not _initialize_fixture_loot():
        return false

    _movement_capability = MovementCapabilityClass.new(_locomotion_state)
    if not _movement_capability.register_provider(NeedsMobilityProviderClass.new(_needs_state)):
        return false
    if not _movement_capability.register_provider(CarryMobilityProviderClass.new(_carry_query)):
        return false
    _actor_traversal = ActorTraversalPolicyClass.new(_base_traversal, _movement_capability)
    _spatial_query = SpatialQueryClass.new(_world, _collision_catalog, _collision_overrides)
    _kernel = TickKernelClass.new(FixtureClass.PLAYER_ID)
    if not _boot_world_time():
        return false
    if not _boot_item_freshness_query():
        return false
    if not _boot_physical_lighting():
        return false
    if not _boot_weather():
        return false

    if not _boot_item_transfer_and_loot_actions():
        return false

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

    _perception_memory = PerceptionMemoryClass.new()
    _perception = ObserverPerceptionClass.new(
        _world,
        _door_state,
        _kernel,
        _perception_memory,
        FixtureClass.PLAYER_ID,
        VisionProfileClass.new()
    )
    if not _perception.is_ready():
        return false
    if not _boot_spatial_sound():
        return false

    _art_catalog = ArtCatalogClass.new()
    if not _world_view.configure(_world, _art_catalog, _door_state, FixtureClass.PLAYER_ID):
        return false
    if not _world_view.configure_physical_lighting(_physical_lighting, _world, _door_state):
        return false
    if not _world_view.configure_weather(_weather, _sky_exposure):
        return false
    if not _perception.set_acquisition_provider(LightingAcquisitionClass.new(_physical_lighting)):
        return false
    if not _boot_interaction_affordances():
        return false
    if not _world_view.configure_interaction_affordances(_interaction_affordances):
        return false
    if not _world_view.configure_perception(
        _perception,
        _perception_memory,
        _art_catalog,
        FixtureClass.PLAYER_ID
    ):
        return false
    if not _world_view.set_perception_ambient_light_level(_ambient_daylight.ambient_light_level()):
        return false
    if not _sync_player_sound_cues():
        return false
    _ambient_daylight.ambient_light_changed.connect(_on_ambient_light_changed)

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
    _camera_controller.presentation_changed.connect(Callable(_world_view, "set_camera_presentation"))
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
    _inventory_inspector = InventoryInspectorClass.new(_world, _hand_state, _inventory_state, _weight_query, _carry_query, _freshness_query)
    _ui_icons = SemanticUiIconCatalogClass.new()
    if not _ui_icons.is_ready():
        return false
    if not _shell.configure(_kernel, _stats_inspector, _inventory_inspector, FixtureClass.PLAYER_ID, _ui_icons):
        return false
    if not _loot_panel.configure(_loot_inspection, _inventory_inspector, FixtureClass.PLAYER_ID, _ui_icons):
        return false
    if not _controls.configure_stance(_locomotion_state, FixtureClass.PLAYER_ID):
        return false
    if not _weather_controls.configure(_weather):
        return false

    _controller = ControllerClass.new(_movement, _kernel, FixtureClass.PLAYER_ID, _stance_actions, _locomotion_state)
    _door_controller = DoorControllerClass.new(_world, _door_actions, _kernel, FixtureClass.PLAYER_ID)
    _loot_controller = LootControllerClass.new(
        _loot_search,
        _item_transfer,
        _loot_inspection,
        _kernel,
        FixtureClass.PLAYER_ID
    )
    if not _controller.is_ready() or not _controller.stance_ready() \
        or not _door_controller.is_ready() or not _loot_controller.is_ready():
        return false
    add_child(_controller)

    _keyboard.action_intent.connect(Callable(_controller, "submit_intent"))
    _controls.action_intent.connect(Callable(_controller, "submit_intent"))
    _door_pointer.world_cell_primary.connect(Callable(_door_controller, "submit_world_cell"))
    _door_pointer.world_cell_primary.connect(Callable(_loot_controller, "submit_world_cell"))
    _controller.action_resolved.connect(Callable(_hud, "present_action_result"))
    _controller.action_busy_changed.connect(_on_player_action_busy_changed)
    _door_controller.action_resolved.connect(Callable(_hud, "present_action_result"))
    _loot_controller.action_resolved.connect(Callable(_hud, "present_action_result"))
    _loot_controller.action_resolved.connect(Callable(_loot_panel, "present_action_result"))
    _loot_controller.container_opened.connect(Callable(_loot_panel, "open_container"))
    _loot_controller.container_changed.connect(Callable(_loot_panel, "refresh"))
    _loot_panel.take_requested.connect(Callable(_loot_controller, "request_take"))
    _loot_panel.store_requested.connect(Callable(_loot_controller, "request_store"))
    _shell.interaction_blocked_changed.connect(_on_shell_interaction_blocked_changed)
    _loot_panel.interaction_blocked_changed.connect(_on_loot_interaction_blocked_changed)
    _weather_controls.force_weather_requested.connect(_on_dev_weather_force_requested)
    _weather_controls.ambient_event_requested.connect(_on_dev_weather_ambient_requested)
    _weather.weather_changed.connect(_on_weather_changed)
    _weather_controls.present_weather(_weather.debug_snapshot())
    _refresh_interaction_enabled()
    return true

func _boot_world_time() -> bool:
    var daylight_profile := DaylightProfileClass.new()
    if _world_time_profile == null or not _world_time_profile.is_valid() or not daylight_profile.is_valid():
        return false
    _world_time = WorldTimeServiceClass.new(_kernel, _world_time_profile)
    _ambient_daylight = OutdoorAmbientLightServiceClass.new(_world_time, daylight_profile)
    return _world_time.is_ready() and _ambient_daylight.is_ready()

func _boot_item_freshness_query() -> bool:
    if _freshness_state == null or _freshness_profiles == null or _freshness_ambient == null:
        return false
    var providers: Array[SpoilageEnvironmentProvider] = [_freshness_ambient]
    _freshness_query = FreshQueryClass.new(_world, _freshness_state, _freshness_profiles, _kernel, providers)
    return _freshness_query.is_ready()

func _boot_physical_lighting() -> bool:
    _physical_lighting = PhysicalLightingClass.new(_world, _door_state, _ambient_daylight)
    _demo_lighting_sources = DemoLightingSourceClass.new(_world, FixtureClass.PLAYER_ID)
    if not _demo_lighting_sources.is_ready():
        return false
    if not _physical_lighting.set_emitters(_demo_lighting_sources.emitters()):
        return false
    _demo_lighting_sources.emitters_changed.connect(_on_demo_lighting_emitters_changed)
    return true

func _boot_weather() -> bool:
    # Canonical island remains a DEV critique composition, so begin in RAIN for
    # immediate Weather inspection. DEV controls can force every implemented profile.
    _weather = WeatherServiceClass.new(_kernel, 28028, &"rain")
    _sky_exposure = SkyExposureClass.new(_world)
    if not _weather.is_ready() or not _sky_exposure.is_ready():
        return false
    return _physical_lighting.set_atmosphere(WeatherOpticsClass.current_optics(_weather))

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

    _loot_items = LootItemCatalogClass.new()
    _loot_profiles = LootContainerCatalogClass.new()
    if not _loot_profiles.validate_items(_loot_items):
        return false
    _physical_catalog = PhysicalCatalogClass.new()
    if not _loot_items.register_physical_profiles(_physical_catalog):
        return false
    _weight_query = WeightQueryClass.new(_world, _physical_catalog)

    _freshness_profiles = FreshProfileCatalogClass.new(_world_time_profile)
    _freshness_state = FreshStateClass.new()
    _freshness_ambient = FreshAmbientClass.new()
    var freshness_providers: Array[SpoilageEnvironmentProvider] = [_freshness_ambient]
    _freshness_mutations = FreshMutationClass.new(_world, _freshness_state, _freshness_profiles, freshness_providers)
    if not _freshness_mutations.is_ready():
        return false

    _carry_state = CarryStateClass.new(_world)
    if not _carry_state.enroll_actor(FixtureClass.PLAYER_ID):
        return false
    _carry_query = CarryQueryClass.new(_world, _hand_state, _inventory_state, _weight_query, _carry_state)
    _carry_acquisition = CarryAcquisitionClass.new(_carry_query)
    if not _carry_acquisition.is_ready():
        return false
    _moodlet_service = MoodletServiceClass.new(_health_state, _needs_state, _carry_query)
    return true

func _initialize_fixture_loot() -> bool:
    _loot_state = LootStateClass.new()
    _loot_initializer = LootInitializerClass.new(
        _world,
        _world_mutations,
        _inventory_state,
        _inventory_mutations,
        _loot_state,
        _loot_items,
        _loot_profiles,
        _physical_catalog,
        _freshness_mutations
    )
    if not _loot_initializer.is_ready():
        return false
    var building_plans: Array[GeneratedBuildingPlan] = FixtureClass.generated_building_plans()
    if building_plans.is_empty():
        return false
    var result: Dictionary = _loot_initializer.initialize_source(
        FixtureClass.LOOT_SOURCE_KEY,
        FixtureClass.LOOT_SOURCE_KIND,
        FixtureClass.LOOT_SOURCE_ID,
        building_plans
    )
    if not bool(result.get("ok", false)):
        push_error("CanonicalDemoMain: loot initialization failed: %s" % String(result.get("reason", "unknown")))
        return false
    return true

func _boot_item_transfer_and_loot_actions() -> bool:
    _item_transfer_timing = ItemTransferTimingClass.new()
    for action_type: StringName in ItemTransferActionTypes.ALL:
        if not _item_transfer_timing.register_duration(action_type, LIVE_ITEM_TRANSFER_TICKS):
            return false

    _interaction_reach = InteractionReachClass.new(_world)
    if not _interaction_reach.is_ready():
        return false
    _loot_access = LootAccessClass.new(_world, _loot_state, _inventory_state, _interaction_reach)
    _item_transfer = PolicyTransferClass.new(
        _world,
        _world_mutations,
        _hand_state,
        _hand_mutations,
        _inventory_state,
        _inventory_mutations,
        _kernel,
        _item_transfer_timing,
        null,
        _carry_acquisition,
        _loot_access
    )
    _loot_search = LootSearchClass.new(
        _world,
        _inventory_state,
        _loot_state,
        _loot_profiles,
        _kernel,
        _interaction_reach
    )
    _loot_inspection = LootInspectionClass.new(
        _world,
        _inventory_state,
        _loot_state,
        _loot_items,
        _loot_profiles,
        _weight_query,
        _carry_query,
        _freshness_query
    )
    return _item_transfer.is_ready() and _loot_search.is_ready() and _loot_inspection.is_ready()

func _boot_interaction_affordances() -> bool:
    if _interaction_reach == null or not _interaction_reach.is_ready() or _perception == null or not _perception.is_ready():
        return false
    _loot_interaction_offers = LootInteractionOfferProviderClass.new(
        _world,
        _inventory_state,
        _loot_state,
        _loot_profiles,
        _interaction_reach
    )
    _interaction_affordances = InteractionAffordanceClass.new(
        _world,
        _interaction_reach,
        _perception,
        FixtureClass.PLAYER_ID
    )
    if not _loot_interaction_offers.is_ready() or not _interaction_affordances.is_ready():
        return false
    return _interaction_affordances.register_provider(_loot_interaction_offers)

func _boot_spatial_sound() -> bool:
    _sound_profiles = SoundProfilesClass.new()
    _acoustic_materials = AcousticMaterialsClass.new()
    var weather_environment := WeatherAcousticClass.new(_weather)
    if not weather_environment.is_ready():
        return false
    _acoustic_propagation = AcousticPropagationClass.new(
        _world,
        _door_state,
        _acoustic_materials,
        weather_environment
    )
    _hearing_profile = HearingProfileClass.new(_skill_state, _needs_state)
    _heard_sounds = HeardSoundStoreClass.new()
    _spatial_sound = SpatialSoundClass.new(
        _world,
        _kernel,
        _sound_profiles,
        _acoustic_propagation,
        _hearing_profile,
        _heard_sounds,
        weather_environment
    )
    if not _spatial_sound.is_ready() or not _spatial_sound.register_listener(FixtureClass.PLAYER_ID):
        return false
    _action_sound_emitters = ActionSoundEmitterClass.new(_movement, _door_transition, _spatial_sound)
    if not _action_sound_emitters.is_ready():
        return false
    _spatial_sound.listener_observations_changed.connect(_on_sound_observations_changed)
    _spatial_sound.listener_decision_unpaused.connect(_on_sound_listener_decision_unpaused)
    return true

func _sync_player_sound_cues() -> bool:
    if _spatial_sound == null:
        return false
    return _world_view.set_auditory_cues(_spatial_sound.presentation_descriptors(FixtureClass.PLAYER_ID))

func _on_ambient_light_changed(level: float, _phase: StringName, _snapshot: Dictionary) -> void:
    _world_view.set_perception_ambient_light_level(level)
    _world_view.refresh_physical_lighting(&"ambient_light_changed")
    if _perception != null:
        _perception.recompute(&"ambient_light_changed")

func _on_demo_lighting_emitters_changed(values: Array) -> void:
    if _physical_lighting != null:
        _physical_lighting.set_emitters(values)
        call_deferred("_flush_demo_lighting_change")

func _flush_demo_lighting_change() -> void:
    if _physical_lighting == null:
        return
    _world_view.refresh_physical_lighting(&"demo_emitters_changed")

func _on_weather_changed(snapshot: Dictionary) -> void:
    if _weather_controls != null:
        _weather_controls.present_weather(snapshot)
    if _weather == null or _physical_lighting == null:
        return
    if not _physical_lighting.set_atmosphere(WeatherOpticsClass.current_optics(_weather)):
        return
    _world_view.refresh_physical_lighting(&"weather_environment_changed")
    if _perception != null:
        _perception.recompute(&"weather_environment_changed")

func _on_dev_weather_force_requested(profile_id: StringName) -> void:
    if _weather != null:
        _weather.force_profile(profile_id)

func _on_dev_weather_ambient_requested(kind: StringName) -> void:
    _world_view.force_weather_ambient_event(kind)

func _on_sound_observations_changed(listener_id: String) -> void:
    if listener_id == FixtureClass.PLAYER_ID:
        _sync_player_sound_cues()

func _on_sound_listener_decision_unpaused(listener_id: String) -> void:
    if listener_id == FixtureClass.PLAYER_ID:
        _world_view.notify_observer_decision_unpaused()

func _on_shell_interaction_blocked_changed(blocked: bool) -> void:
    _shell_blocks_interaction = blocked
    _refresh_interaction_enabled()

func _on_loot_interaction_blocked_changed(blocked: bool) -> void:
    _loot_blocks_interaction = blocked
    _refresh_interaction_enabled()

func _on_player_action_busy_changed(blocked: bool) -> void:
    _action_blocks_interaction = blocked
    _refresh_interaction_enabled()

func _refresh_interaction_enabled() -> void:
    var enabled: bool = not _shell_blocks_interaction \
        and not _loot_blocks_interaction \
        and not _action_blocks_interaction
    _keyboard.set_enabled(enabled)
    _controls.set_enabled(enabled)
    _door_pointer.set_enabled(enabled)
    _camera_input.set_enabled(enabled)
    _camera_controls.set_enabled(enabled)
