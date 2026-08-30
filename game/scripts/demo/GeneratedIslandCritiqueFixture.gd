extends RefCounted
class_name GeneratedIslandCritiqueFixture

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const GlobalFixture = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const GlobalSeed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")
const GlobalRequestClass = preload("res://scripts/generation/world/GlobalWorldGenerationRequest.gd")
const GlobalProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const IslandPlannerClass = preload("res://scripts/generation/world/IslandWorldPlanner.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const AreaGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const AreaMaterializerClass = preload("res://scripts/generation/areas/AreaMaterializationCoordinator.gd")
const RuleInstallerClass = preload("res://scripts/demo/GeneratedWorldRuleInstaller.gd")
const RegistryClass = preload("res://scripts/streaming/MaterializationRegistry.gd")
const AreaSourceClass = preload("res://scripts/streaming/AreaSiteMaterializationSource.gd")
const IslandSurfaceCatalogClass = preload("res://scripts/streaming/IslandSurfaceSourceCatalog.gd")
const IslandSurfaceSourceClass = preload("res://scripts/streaming/IslandSurfaceMaterializationSource.gd")
const WatercourseCatalogClass = preload("res://scripts/streaming/WatercourseSourceCatalog.gd")
const WatercourseSourceClass = preload("res://scripts/streaming/WatercourseMaterializationSource.gd")
const MaterializationClass = preload("res://scripts/streaming/WorldMaterializationCoordinator.gd")
const StreamingGridClass = preload("res://scripts/streaming/StreamingRegionGrid.gd")
const StreamingClass = preload("res://scripts/streaming/WorldStreamingCoordinator.gd")
const StreamingFocusClass = preload("res://scripts/streaming/PlayerStreamingFocusAdapter.gd")

const AREA_BOUNDS: Rect2i = Rect2i(232, 1232, 1792, 1792)
const RENDER_WINDOW_SIZE: Vector2i = Vector2i(80, 96)
const CELL_PIXELS: float = 24.0
const PLAYER_ID: String = "actor.player.demo"
const SURVIVOR: StringName = &"actor.survivor"
const CENTRAL_SITE_ID: String = "area.rural.crossroads.001"
const DINER_ARCHETYPE: StringName = &"commercial.diner.rural_small"
const STREAM_REGION_SIZE: Vector2i = Vector2i(128, 128)
const STREAM_ACTIVE_RADIUS: int = 1
const WORLD_SEED_OVERRIDE_ENV: String = "TICK_LAB_WORLD_SEED"
const MAX_WORLD_SEED_ATTEMPTS: int = 128

# Keep the current System-24 DEV source identity for the spawn-area loot bridge.
const LOOT_SOURCE_KEY: String = "dev.rural_crossroads"
const LOOT_SOURCE_KIND: StringName = &"dev_area"
const LOOT_SOURCE_ID: String = "rural_crossroads"

static var _global_plan: GeneratedGlobalWorldPlan = null
static var _central_area_plan: GeneratedAreaPlan = null
static var _registry: MaterializationRegistry = null
static var _streaming: WorldStreamingCoordinator = null
static var _streaming_focus: PlayerStreamingFocusAdapter = null
static var _active_seed: int = -1

static func generate_global_plan(seed: int = GlobalFixture.SEED) -> GeneratedGlobalWorldPlan:
    var requested_seed: int = seed & GlobalSeed.HASH_MASK
    if requested_seed <= 0:
        requested_seed = 1
    var candidate_seed: int = requested_seed
    var last_failure: String = "unknown"
    for attempt: int in range(MAX_WORLD_SEED_ATTEMPTS):
        var request := GlobalRequestClass.new(
            GlobalFixture.WORLD_ID,
            candidate_seed,
            AREA_BOUNDS,
            GlobalProfilesClass.TEMPERATE_ISLAND_REGION
        )
        var plan: GeneratedGlobalWorldPlan = IslandPlannerClass.new().generate(request)
        if plan != null and plan.is_generated():
            if candidate_seed != requested_seed:
                print("PLAYABLE_ISLAND_SEED_REROLL requested=%d resolved=%d attempts=%d" % [requested_seed, candidate_seed, attempt + 1])
            return plan
        if plan == null:
            last_failure = "null_plan"
        else:
            last_failure = String(plan.failure_reason)
            if last_failure.is_empty():
                last_failure = "invalid_plan"
        candidate_seed = _next_world_seed(candidate_seed)
    push_error(
        "GeneratedIslandCritiqueFixture: exhausted %d world-seed attempts from %d; last_failure=%s"
        % [MAX_WORLD_SEED_ATTEMPTS, requested_seed, last_failure]
    )
    return null

static func generate_plan(seed: int = GlobalFixture.SEED) -> GeneratedAreaPlan:
    var global_plan: GeneratedGlobalWorldPlan = generate_global_plan(seed)
    if global_plan == null or not global_plan.is_generated():
        return null
    return _central_plan(global_plan)

static func generated_building_plans(seed: int = -1) -> Array[GeneratedBuildingPlan]:
    if seed < 0 and _central_area_plan != null and _central_area_plan.is_generated():
        return AreaMaterializerClass.new().generated_building_plans(_central_area_plan)
    var effective_seed: int = GlobalFixture.SEED if seed < 0 else seed
    var plan: GeneratedAreaPlan = generate_plan(effective_seed)
    if plan == null or not plan.is_generated():
        return []
    return AreaMaterializerClass.new().generated_building_plans(plan)

static func build(
    world: WorldState,
    mutations: WorldMutationService,
    collision_catalog: CollisionCatalog,
    traversal_policy: MovementTraversalPolicy,
    door_state: DoorStateStore,
    door_mutations: DoorStateMutationService,
    seed_override: int = -1
) -> bool:
    _global_plan = null
    _central_area_plan = null
    _registry = null
    _streaming = null
    _streaming_focus = null
    _active_seed = -1
    if world == null or mutations == null or collision_catalog == null or traversal_policy == null or door_state == null or door_mutations == null:
        return false

    var rules: Dictionary = RuleInstallerClass.new().install(collision_catalog, traversal_policy)
    if not bool(rules.get("ok", false)):
        push_error("GeneratedIslandCritiqueFixture: rule installation failed: %s" % String(rules.get("failure_reason", "unknown")))
        return false

    var world_seed: int = _choose_new_game_seed(seed_override)
    if world_seed <= 0:
        push_error("GeneratedIslandCritiqueFixture: invalid new-game seed")
        return false
    var global_plan: GeneratedGlobalWorldPlan = generate_global_plan(world_seed)
    if global_plan == null or not global_plan.is_generated():
        push_error("GeneratedIslandCritiqueFixture: global island generation failed after seed rerolls from %d" % world_seed)
        return false
    world_seed = global_plan.seed
    if world_seed <= 0:
        push_error("GeneratedIslandCritiqueFixture: resolved global island plan has invalid seed")
        return false
    var central_plan: GeneratedAreaPlan = _central_plan(global_plan)
    if central_plan == null or not central_plan.is_generated():
        push_error("GeneratedIslandCritiqueFixture: central area generation failed for seed %d" % world_seed)
        return false
    var player_start: Vector2i = player_start_for_plan(central_plan)
    if player_start.x < 0:
        return false

    var registry := RegistryClass.new()
    var area_source := AreaSourceClass.new(registry)
    var surface_catalog := IslandSurfaceCatalogClass.new(global_plan)
    var water_catalog := WatercourseCatalogClass.new(global_plan)
    if not surface_catalog.is_ready() or not water_catalog.is_ready():
        push_error("GeneratedIslandCritiqueFixture: island source catalogs failed")
        return false
    var surface_source := IslandSurfaceSourceClass.new(registry, surface_catalog)
    var water_source := WatercourseSourceClass.new(registry, water_catalog)
    var materialization := MaterializationClass.new(
        world,
        mutations,
        door_state,
        door_mutations,
        registry,
        area_source,
        null,
        [surface_source, water_source]
    )
    if not materialization.is_ready():
        return false
    var grid := StreamingGridClass.new(global_plan.bounds, STREAM_REGION_SIZE)
    var streaming := StreamingClass.new(global_plan, grid, materialization, null, STREAM_ACTIVE_RADIUS)
    if not streaming.is_ready():
        return false
    var initial: Dictionary = streaming.update_focus(player_start)
    if not bool(initial.get("ok", false)):
        push_error("GeneratedIslandCritiqueFixture: initial streaming failed: %s" % String(initial.get("failure_reason", "unknown")))
        return false

    if mutations.create_entity(SURVIVOR, PLAYER_ID) != PLAYER_ID:
        return false
    if not mutations.set_placement(
        PLAYER_ID,
        Layers.Channel.ACTOR,
        player_start,
        Facing.Value.NORTH,
        Footprint.single_cell()
    ):
        return false

    var focus_adapter := StreamingFocusClass.new(world, streaming, PLAYER_ID)
    if not focus_adapter.is_ready() or not focus_adapter.sync_now():
        return false

    _active_seed = world_seed
    _global_plan = global_plan
    _central_area_plan = central_plan
    _registry = registry
    _streaming = streaming
    _streaming_focus = focus_adapter
    print("PLAYABLE_ISLAND_WORLD_READY seed=%d sites=%d stream_region=%s" % [world_seed, global_plan.area_sites.size(), STREAM_REGION_SIZE])
    return true

static func active_seed() -> int:
    return _active_seed

static func initial_render_origin(world: WorldState) -> Vector2i:
    if world == null:
        return AREA_BOUNDS.position
    var placement: WorldPlacement = world.placement(PLAYER_ID)
    if placement == null:
        return AREA_BOUNDS.position
    return _window_origin_for_cell(placement.anchor)

static func global_plan() -> GeneratedGlobalWorldPlan:
    return _global_plan

static func materialization_registry() -> MaterializationRegistry:
    return _registry

static func streaming_coordinator() -> WorldStreamingCoordinator:
    return _streaming

static func streaming_failure() -> String:
    return "" if _streaming_focus == null else _streaming_focus.last_failure()

static func player_start_for_plan(plan: GeneratedAreaPlan) -> Vector2i:
    var center: Vector2i = _central_intersection_cell(plan)
    if center.x < 0:
        return Vector2i(-1, -1)
    var candidates: Array[Vector2i] = [
        center + Vector2i(0, 4),
        center + Vector2i(4, 0),
        center + Vector2i(0, -4),
        center + Vector2i(-4, 0),
    ]
    for candidate: Vector2i in candidates:
        if plan.bounds.has_point(candidate) \
            and _cell_in_inherited_road(plan, candidate) \
            and not _outdoor_prop_at(plan, candidate):
            return candidate
    if plan.bounds.has_point(center) and _cell_in_inherited_road(plan, center) and not _outdoor_prop_at(plan, center):
        return center
    return Vector2i(-1, -1)

static func diner_door_id(plan: GeneratedAreaPlan) -> String:
    var parcel: Dictionary = _diner_parcel(plan)
    var instance_id: String = String(parcel.get("building_instance_id", ""))
    return "" if instance_id.is_empty() else "%s.door.exterior.primary" % instance_id

static func diner_frontage_for_plan(plan: GeneratedAreaPlan) -> int:
    return int(_diner_parcel(plan).get("frontage_side", -1))

static func _choose_new_game_seed(seed_override: int) -> int:
    if seed_override > 0:
        return seed_override & GlobalSeed.HASH_MASK
    var environment_override: String = OS.get_environment(WORLD_SEED_OVERRIDE_ENV).strip_edges()
    if environment_override.is_valid_int():
        var parsed: int = int(environment_override) & GlobalSeed.HASH_MASK
        if parsed > 0:
            return parsed
    # CI/headless runs need deterministic reproducibility. Interactive browser/desktop
    # launches intentionally choose a fresh seed once, then the whole generation stack
    # remains deterministic from that one authoritative new-game seed.
    if DisplayServer.get_name() == "headless":
        return GlobalFixture.SEED
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    return rng.randi_range(1, GlobalSeed.HASH_MASK)

static func _next_world_seed(seed: int) -> int:
    if seed >= GlobalSeed.HASH_MASK:
        return 1
    return seed + 1

static func _central_plan(global_plan: GeneratedGlobalWorldPlan) -> GeneratedAreaPlan:
    var projected: Dictionary = ProjectorClass.new().project_site(global_plan, CENTRAL_SITE_ID)
    if not bool(projected.get("ok", false)):
        return null
    var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
    if request == null or not request.is_valid():
        return null
    return AreaGeneratorClass.new().generate(request)

static func _central_intersection_cell(plan: GeneratedAreaPlan) -> Vector2i:
    if plan == null or not plan.is_generated() or plan.intersections.is_empty():
        return Vector2i(-1, -1)
    var expected: Vector2i = plan.bounds.position + Vector2i(plan.bounds.size.x / 2, plan.bounds.size.y / 2)
    var best: Vector2i = Vector2i(-1, -1)
    var best_distance: int = 2147483647
    for intersection: Dictionary in plan.intersections:
        var cell: Vector2i = intersection.get("cell", Vector2i(-1, -1))
        if not plan.bounds.has_point(cell):
            continue
        var distance: int = absi(cell.x - expected.x) + absi(cell.y - expected.y)
        if distance < best_distance:
            best = cell
            best_distance = distance
    return best

static func _cell_in_inherited_road(plan: GeneratedAreaPlan, cell: Vector2i) -> bool:
    for road: Dictionary in plan.roads:
        if not bool(road.get("inherited", false)):
            continue
        for value: Variant in road.get("corridor_cells", []):
            if typeof(value) == TYPE_VECTOR2I and value == cell:
                return true
    return false

static func _outdoor_prop_at(plan: GeneratedAreaPlan, cell: Vector2i) -> bool:
    for prop: Dictionary in plan.outdoor_props:
        if prop.get("cell", Vector2i(-1, -1)) == cell:
            return true
    return false

static func _diner_parcel(plan: GeneratedAreaPlan) -> Dictionary:
    if plan == null:
        return {}
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("building_archetype_id", &"")) == DINER_ARCHETYPE:
            return parcel
    return {}

static func _window_origin_for_cell(cell: Vector2i) -> Vector2i:
    var desired := cell - Vector2i(RENDER_WINDOW_SIZE.x / 2, RENDER_WINDOW_SIZE.y / 2)
    var max_origin := AREA_BOUNDS.position + AREA_BOUNDS.size - RENDER_WINDOW_SIZE
    return Vector2i(
        clampi(desired.x, AREA_BOUNDS.position.x, max_origin.x),
        clampi(desired.y, AREA_BOUNDS.position.y, max_origin.y)
    )
