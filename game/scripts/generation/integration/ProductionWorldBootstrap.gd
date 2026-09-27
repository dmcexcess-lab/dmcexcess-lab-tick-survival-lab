extends RefCounted
class_name ProductionWorldBootstrap

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const GlobalSeed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")
const GlobalRequestClass = preload("res://scripts/generation/world/GlobalWorldGenerationRequest.gd")
const GlobalProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const IslandPlannerClass = preload("res://scripts/generation/world/IslandWorldPlanner.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const AreaGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const AreaMaterializerClass = preload("res://scripts/generation/areas/AreaMaterializationCoordinator.gd")
const RuleInstallerClass = preload("res://scripts/generation/integration/GeneratedWorldRuleInstaller.gd")
const RegistryClass = preload("res://scripts/streaming/MaterializationRegistry.gd")
const AreaSourceClass = preload("res://scripts/streaming/AreaSiteMaterializationSource.gd")
const IslandSurfaceCatalogClass = preload("res://scripts/streaming/IslandSurfaceSourceCatalog.gd")
const IslandSurfaceSourceClass = preload("res://scripts/streaming/IslandSurfaceMaterializationSource.gd")
const MaterializationClass = preload("res://scripts/streaming/WorldMaterializationCoordinator.gd")
const StreamingGridClass = preload("res://scripts/streaming/StreamingRegionGrid.gd")
const StreamingClass = preload("res://scripts/streaming/WorldStreamingCoordinator.gd")
const StreamingFocusClass = preload("res://scripts/streaming/PlayerStreamingFocusAdapter.gd")

const WORLD_ID: String = "world.temperate.island"
const DEFAULT_TEST_SEED: int = 20001
const WORLD_BOUNDS: Rect2i = Rect2i(232, 1232, 1792, 1792)
const RENDER_WINDOW_SIZE: Vector2i = Vector2i(80, 96)
const CELL_PIXELS: float = 24.0
const PLAYER_ID: String = "actor.player"
const SURVIVOR: StringName = &"actor.survivor"
const STREAM_REGION_SIZE: Vector2i = Vector2i(128, 128)
const STREAM_ACTIVE_RADIUS: int = 0
const WORLD_SEED_OVERRIDE_ENV: String = "TICK_LAB_WORLD_SEED"
const LOOT_SOURCE_KIND: StringName = &"generated_area"

static var _global_plan: GeneratedGlobalWorldPlan = null
static var _spawn_area_plan: GeneratedAreaPlan = null
static var _spawn_site_id: String = ""
static var _registry: MaterializationRegistry = null
static var _streaming: WorldStreamingCoordinator = null
static var _streaming_focus: PlayerStreamingFocusAdapter = null
static var _active_seed: int = -1
static var _last_failure: String = ""

static func build(world: WorldState, mutations: WorldMutationService, collision_catalog: CollisionCatalog, traversal_policy: MovementTraversalPolicy, door_state: DoorStateStore, door_mutations: DoorStateMutationService, seed_override: int = -1) -> bool:
    _reset()
    if world == null or mutations == null or collision_catalog == null or traversal_policy == null or door_state == null or door_mutations == null:
        return _fail("bootstrap_dependencies_missing")
    var rules: Dictionary = RuleInstallerClass.new().install(collision_catalog, traversal_policy)
    if not bool(rules.get("ok", false)):
        return _fail("rule_installation_failed:%s" % String(rules.get("failure_reason", "unknown")))
    var world_seed: int = _choose_new_game_seed(seed_override)
    if world_seed <= 0:
        return _fail("invalid_world_seed")
    var request := GlobalRequestClass.new(WORLD_ID, world_seed, WORLD_BOUNDS, GlobalProfilesClass.TEMPERATE_ISLAND_REGION)
    var global_plan: GeneratedGlobalWorldPlan = IslandPlannerClass.new().generate(request)
    if global_plan == null:
        return _fail("global_plan_null")
    if not global_plan.is_generated():
        return _fail("global_generation:%s" % String(global_plan.failure_reason))
    var spawn: Dictionary = _resolve_spawn(global_plan)
    if not bool(spawn.get("ok", false)):
        return _fail(String(spawn.get("failure_reason", "spawn_unavailable")))
    var spawn_plan: GeneratedAreaPlan = spawn.get("plan") as GeneratedAreaPlan
    var player_start: Vector2i = spawn.get("player_start", Vector2i(-1, -1))
    var spawn_site_id: String = String(spawn.get("site_id", ""))
    if spawn_plan == null or not spawn_plan.is_generated() or player_start.x < 0 or spawn_site_id.is_empty():
        return _fail("spawn_resolution_invalid")

    var registry := RegistryClass.new()
    var area_source := AreaSourceClass.new(registry)
    var surface_catalog := IslandSurfaceCatalogClass.new(global_plan)
    if not surface_catalog.is_ready():
        return _fail("island_surface_catalog_failed")
    var surface_source := IslandSurfaceSourceClass.new(registry, surface_catalog)
    var materialization := MaterializationClass.new(world, mutations, door_state, door_mutations, registry, area_source, null, [surface_source])
    if not materialization.is_ready():
        return _fail("materialization_not_ready")
    var grid := StreamingGridClass.new(global_plan.bounds, STREAM_REGION_SIZE)
    var streaming := StreamingClass.new(global_plan, grid, materialization, null, STREAM_ACTIVE_RADIUS)
    if not streaming.is_ready():
        return _fail("streaming_not_ready")
    var initial: Dictionary = streaming.update_focus(player_start)
    if not bool(initial.get("ok", false)):
        return _fail("initial_streaming:%s" % String(initial.get("failure_reason", "unknown")))
    if mutations.create_entity(SURVIVOR, PLAYER_ID) != PLAYER_ID:
        return _fail("player_create_failed")
    if not mutations.set_placement(PLAYER_ID, Layers.Channel.ACTOR, player_start, Facing.Value.NORTH, Footprint.single_cell()):
        return _fail("player_placement_failed")
    var focus_adapter := StreamingFocusClass.new(world, streaming, PLAYER_ID)
    if not focus_adapter.is_ready() or not focus_adapter.sync_now():
        return _fail("streaming_focus_failed")

    _active_seed = world_seed
    _global_plan = global_plan
    _spawn_area_plan = spawn_plan
    _spawn_site_id = spawn_site_id
    _registry = registry
    _streaming = streaming
    _streaming_focus = focus_adapter
    print("PRODUCTION_WORLD_READY seed=%d spawn_site=%s sites=%d" % [world_seed, spawn_site_id, global_plan.area_sites.size()])
    return true

static func active_seed() -> int:
    return _active_seed

static func last_failure() -> String:
    return _last_failure

static func render_bounds() -> Rect2i:
    return _global_plan.bounds if _global_plan != null and _global_plan.is_generated() else WORLD_BOUNDS

static func initial_render_origin(world: WorldState) -> Vector2i:
    if world == null:
        return render_bounds().position
    var placement: WorldPlacement = world.placement(PLAYER_ID)
    if placement == null:
        return render_bounds().position
    return _window_origin_for_cell(placement.anchor)

static func global_plan() -> GeneratedGlobalWorldPlan:
    return _global_plan

static func spawn_area_plan() -> GeneratedAreaPlan:
    return _spawn_area_plan

static func generated_building_plans() -> Array[GeneratedBuildingPlan]:
    if _spawn_area_plan == null or not _spawn_area_plan.is_generated():
        return []
    return AreaMaterializerClass.new().generated_building_plans(_spawn_area_plan)

static func loot_source_key() -> String:
    return "generated.%s" % _spawn_site_id

static func loot_source_id() -> String:
    return _spawn_site_id

static func materialization_registry() -> MaterializationRegistry:
    return _registry

static func streaming_coordinator() -> WorldStreamingCoordinator:
    return _streaming

static func streaming_failure() -> String:
    return "" if _streaming_focus == null else _streaming_focus.last_failure()

static func _resolve_spawn(global_plan: GeneratedGlobalWorldPlan) -> Dictionary:
    if global_plan == null or not global_plan.is_generated() or global_plan.area_sites.is_empty():
        return {"ok": false, "failure_reason": "no_generated_area_sites"}
    var sites: Array[Dictionary] = global_plan.area_sites.duplicate(true)
    var world_center: Vector2i = global_plan.bounds.position + global_plan.bounds.size / 2
    sites.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var ar: Rect2i = a.get("bounds", Rect2i())
        var br: Rect2i = b.get("bounds", Rect2i())
        var ac: Vector2i = ar.position + ar.size / 2
        var bc: Vector2i = br.position + br.size / 2
        var ad: int = absi(ac.x - world_center.x) + absi(ac.y - world_center.y)
        var bd: int = absi(bc.x - world_center.x) + absi(bc.y - world_center.y)
        if ad == bd:
            return String(a.get("id", "")) < String(b.get("id", ""))
        return ad < bd
    )
    var last_reason: String = "no_spawnable_area"
    for site: Dictionary in sites:
        var site_id: String = String(site.get("id", ""))
        if site_id.is_empty():
            continue
        var projected: Dictionary = ProjectorClass.new().project_site(global_plan, site_id)
        if not bool(projected.get("ok", false)):
            last_reason = "spawn_projection_failed:%s" % site_id
            continue
        var area_request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
        if area_request == null or not area_request.is_valid():
            last_reason = "spawn_request_invalid:%s" % site_id
            continue
        var plan: GeneratedAreaPlan = AreaGeneratorClass.new().generate(area_request)
        if plan == null or not plan.is_generated():
            last_reason = "spawn_area_generation_failed:%s" % site_id
            continue
        var start: Vector2i = _player_start_for_plan(plan)
        if start.x < 0:
            last_reason = "spawn_cell_unavailable:%s" % site_id
            continue
        return {"ok": true, "site_id": site_id, "plan": plan, "player_start": start, "failure_reason": ""}
    return {"ok": false, "failure_reason": last_reason}

static func _player_start_for_plan(plan: GeneratedAreaPlan) -> Vector2i:
    if plan == null or not plan.is_generated():
        return Vector2i(-1, -1)
    var expected: Vector2i = plan.bounds.position + plan.bounds.size / 2
    var candidates: Array[Vector2i] = []
    for road: Dictionary in plan.roads:
        for value: Variant in road.get("corridor_cells", []):
            if typeof(value) == TYPE_VECTOR2I:
                var cell: Vector2i = value
                if plan.bounds.has_point(cell) and not _outdoor_prop_at(plan, cell):
                    candidates.append(cell)
    if candidates.is_empty():
        return Vector2i(-1, -1)
    candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        var ad: int = absi(a.x - expected.x) + absi(a.y - expected.y)
        var bd: int = absi(b.x - expected.x) + absi(b.y - expected.y)
        if ad == bd:
            return a.y < b.y if a.x == b.x else a.x < b.x
        return ad < bd
    )
    return candidates[0]

static func _outdoor_prop_at(plan: GeneratedAreaPlan, cell: Vector2i) -> bool:
    for prop: Dictionary in plan.outdoor_props:
        if prop.get("cell", Vector2i(-1, -1)) == cell:
            return true
    return false

static func _choose_new_game_seed(seed_override: int) -> int:
    if seed_override > 0:
        return seed_override & GlobalSeed.HASH_MASK
    var environment_override: String = OS.get_environment(WORLD_SEED_OVERRIDE_ENV).strip_edges()
    if environment_override.is_valid_int():
        var parsed: int = int(environment_override) & GlobalSeed.HASH_MASK
        if parsed > 0:
            return parsed
    if DisplayServer.get_name() == "headless":
        return DEFAULT_TEST_SEED
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    return rng.randi_range(1, GlobalSeed.HASH_MASK)

static func _window_origin_for_cell(cell: Vector2i) -> Vector2i:
    var desired := cell - Vector2i(RENDER_WINDOW_SIZE.x / 2, RENDER_WINDOW_SIZE.y / 2)
    var bounds: Rect2i = render_bounds()
    var max_origin := bounds.position + bounds.size - RENDER_WINDOW_SIZE
    return Vector2i(clampi(desired.x, bounds.position.x, max_origin.x), clampi(desired.y, bounds.position.y, max_origin.y))

static func _reset() -> void:
    _global_plan = null
    _spawn_area_plan = null
    _spawn_site_id = ""
    _registry = null
    _streaming = null
    _streaming_focus = null
    _active_seed = -1
    _last_failure = ""

static func _fail(reason: String) -> bool:
    _last_failure = reason
    push_error("ProductionWorldBootstrap: %s" % reason)
    return false
