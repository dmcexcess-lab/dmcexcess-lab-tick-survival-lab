extends SceneTree

const GlobalFixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const GlobalPlannerClass = preload("res://scripts/generation/world/GlobalWorldPlanner.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const LocalGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const LocalFixtureClass = preload("res://scripts/demo/RuralCrossroadsPlanFixture.gd")
const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const DoorMutationClass = preload("res://scripts/simulation/doors/DoorStateMutationService.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const GridClass = preload("res://scripts/streaming/StreamingRegionGrid.gd")
const RegistryClass = preload("res://scripts/streaming/MaterializationRegistry.gd")
const SourceClass = preload("res://scripts/streaming/AreaSiteMaterializationSource.gd")
const MaterializationClass = preload("res://scripts/streaming/WorldMaterializationCoordinator.gd")
const StreamingClass = preload("res://scripts/streaming/WorldStreamingCoordinator.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var planner: GlobalWorldPlanner = GlobalPlannerClass.new()
    var global_plan: GeneratedGlobalWorldPlan = planner.generate(GlobalFixtureClass.request())
    _check(global_plan != null and global_plan.is_generated(), "current System 00D v7 world generates before streaming")
    if global_plan == null or not global_plan.is_generated():
        _finish()
        return

    _test_upstream_regressions(planner, global_plan)
    _test_region_grid(global_plan)
    _test_streaming_and_materialization(global_plan)
    _test_empty_region(global_plan)
    _finish()

func _test_upstream_regressions(planner: GlobalWorldPlanner, global_plan: GeneratedGlobalWorldPlan) -> void:
    _check(global_plan.profile_version == 7, "00F consumes temperate.rural.region v7 without changing it")
    var replay: GeneratedGlobalWorldPlan = planner.generate(GlobalFixtureClass.request(GlobalFixtureClass.SEED))
    _check(replay.is_generated() and replay.signature() == global_plan.signature(), "00F leaves the deterministic System 00D signature unchanged")

    var projector: System20AreaRequestProjector = ProjectorClass.new()
    var generator: LocalAreaGenerator = LocalGeneratorClass.new()
    var projected: Dictionary = projector.project_site(global_plan, GlobalFixtureClass.CENTRAL_SITE_ID)
    var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
    var baseline_request: AreaGenerationRequest = LocalFixtureClass.request(LocalFixtureClass.SEED)
    _check(bool(projected.get("ok", false)) and request != null, "Crossroads still projects through the public System 20 seam")
    if request != null:
        var projected_plan: GeneratedAreaPlan = generator.generate(request)
        var baseline_plan: GeneratedAreaPlan = generator.generate(baseline_request)
        _check(projected_plan.is_generated() and baseline_plan.is_generated(), "Crossroads protected plans still generate")
        if projected_plan.is_generated() and baseline_plan.is_generated():
            _check(projected_plan.signature() == baseline_plan.signature(), "Crossroads Candidate 006 semantic signature remains exact")

func _test_region_grid(global_plan: GeneratedGlobalWorldPlan) -> void:
    var grid: StreamingRegionGrid = GridClass.new(global_plan.bounds, Vector2i(256, 256))
    _check(grid.is_valid(), "default technical grid is valid")
    _check(grid.grid_size() == Vector2i(7, 7), "1792x1792 fixture maps to a technical 7x7 grid")
    _check(grid.region_coord_for_cell(global_plan.bounds.position) == Vector2i(0, 0), "world origin maps to technical region 0,0")
    var world_last: Vector2i = global_plan.bounds.position + global_plan.bounds.size - Vector2i.ONE
    _check(grid.region_coord_for_cell(world_last) == Vector2i(6, 6), "world final cell maps to technical region 6,6")
    var first_boundary: Vector2i = global_plan.bounds.position + Vector2i(256, 0)
    _check(grid.region_coord_for_cell(first_boundary - Vector2i(1, 0)) == Vector2i(0, 0), "cell before an interior stream boundary stays in prior region")
    _check(grid.region_coord_for_cell(first_boundary) == Vector2i(1, 0), "interior stream boundary starts next technical region")
    _check(grid.region_coord_for_cell(global_plan.bounds.position - Vector2i.ONE) == StreamingRegionGrid.INVALID_COORD, "out-of-world cells are rejected rather than clamped")
    _check(grid.regions_around(Vector2i(0, 0), 1).size() == 4, "radius-one edge neighborhood clips to four regions")
    _check(grid.regions_around(Vector2i(3, 3), 1).size() == 9, "radius-one interior neighborhood contains nine regions")

    var synthetic := GridClass.new(Rect2i(-300, 700, 600, 530), Vector2i(256, 256))
    _check(synthetic.is_valid() and synthetic.grid_size() == Vector2i(3, 3), "technical grid supports negative/non-zero origins and clipped edges")
    _check(synthetic.region_bounds(Vector2i(2, 2)) == Rect2i(212, 1212, 88, 18), "final synthetic region is clipped to supplied world bounds")

func _test_streaming_and_materialization(global_plan: GeneratedGlobalWorldPlan) -> void:
    var world: WorldState = WorldStateClass.new()
    var mutations: WorldMutationService = WorldMutationClass.new(world)
    var doors: DoorStateStore = DoorStateClass.new()
    var door_mutations: DoorStateMutationService = DoorMutationClass.new(doors, world)
    var registry: MaterializationRegistry = RegistryClass.new()
    var source: AreaSiteMaterializationSource = SourceClass.new(registry)
    var materialization: WorldMaterializationCoordinator = MaterializationClass.new(
        world, mutations, doors, door_mutations, registry, source
    )
    var grid: StreamingRegionGrid = GridClass.new(global_plan.bounds, Vector2i(256, 256))
    var streaming: WorldStreamingCoordinator = StreamingClass.new(global_plan, grid, materialization, source, 1)

    _check(source.is_ready() and materialization.is_ready() and streaming.is_ready(), "00F collaborators are independently ready")
    _check(bool(source.validate_source_bounds(global_plan).get("ok", false)), "all five full-ground materialization source bounds are non-overlapping")

    var site_ids: Array[String] = _site_ids(global_plan)
    _check(site_ids.size() == 5, "all five current System 00D area sites remain logical materialization sources")
    var source_keys: Array[String] = []
    for site_id: String in site_ids:
        var key: String = source.source_key_for_site(site_id)
        _check(not key.is_empty(), "%s has a stable logical source key" % site_id)
        source_keys.append(key)
    var unique_keys: Dictionary = {}
    for key: String in source_keys:
        unique_keys[key] = true
    _check(unique_keys.size() == 5, "logical source identity is independent and unique")

    var alternate_grid: StreamingRegionGrid = GridClass.new(global_plan.bounds, Vector2i(320, 320))
    _check(alternate_grid.is_valid() and alternate_grid.grid_size() != grid.grid_size(), "technical region size is replaceable configuration")
    _check(source.source_key_for_site(GlobalFixtureClass.CENTRAL_SITE_ID) == source_keys[site_ids.find(GlobalFixtureClass.CENTRAL_SITE_ID)], "changing technical grid geometry cannot change logical source identity")

    var projector: System20AreaRequestProjector = ProjectorClass.new()
    var generator: LocalAreaGenerator = LocalGeneratorClass.new()
    var baseline_projection: Dictionary = projector.project_site(global_plan, GlobalFixtureClass.CENTRAL_SITE_ID)
    var baseline_request: AreaGenerationRequest = baseline_projection.get("request") as AreaGenerationRequest
    var baseline_plan: GeneratedAreaPlan = generator.generate(baseline_request) if baseline_request != null else null
    _check(baseline_plan != null and baseline_plan.is_generated(), "Crossroads baseline plan available for materialization provenance")

    var crossroads_site: Dictionary = _site_by_id(global_plan, GlobalFixtureClass.CENTRAL_SITE_ID)
    var crossroads_center: Vector2i = _rect_center(crossroads_site.get("bounds", Rect2i()))
    var first_focus: Dictionary = streaming.update_focus(crossroads_center)
    _check(bool(first_focus.get("ok", false)), "focus near Crossroads triggers real on-demand materialization")
    var crossroads_key: String = source.source_key_for_site(GlobalFixtureClass.CENTRAL_SITE_ID)
    _check(registry.has_source(crossroads_key), "Crossroads source is registered only after successful materialization")
    _check(world.has_terrain(crossroads_center), "Crossroads full logical site exists in authoritative WHAT")

    var crossroads_record: MaterializationRecord = registry.record(crossroads_key)
    _check(crossroads_record != null and crossroads_record.is_valid(), "Crossroads has a valid materialization provenance record")
    if crossroads_record != null and baseline_plan != null and baseline_plan.is_generated():
        _check(crossroads_record.area_profile_id == baseline_plan.area_profile_id and crossroads_record.area_profile_version == baseline_plan.area_profile_version, "registry records Crossroads area profile version")
        _check(crossroads_record.environment_profile_id == baseline_plan.environment_profile_id and crossroads_record.environment_profile_version == baseline_plan.environment_profile_version, "registry records environment profile version")
        _check(crossroads_record.plan_signature == baseline_plan.signature(), "registry records the deterministic generated-area signature")
        _check(crossroads_record.world_revision_after > 0 and crossroads_record.world_revision_after <= world.revision(), "registry records a valid WHAT revision after materialization")
        _check(crossroads_record.door_revision_after > 0 and crossroads_record.door_revision_after <= doors.revision(), "registry records a valid Door State revision after materialization")

    var repeat_world_revision: int = world.revision()
    var repeat_door_revision: int = doors.revision()
    var repeat_registry_revision: int = registry.revision()
    var repeat_focus: Dictionary = streaming.update_focus(crossroads_center)
    _check(bool(repeat_focus.get("ok", false)), "repeating the same focus succeeds")
    _check(world.revision() == repeat_world_revision and doors.revision() == repeat_door_revision and registry.revision() == repeat_registry_revision, "repeated focus does not regenerate or mutate persistent state")

    var crossroads_door_id: String = _primary_door_id(baseline_plan)
    _check(not crossroads_door_id.is_empty() and doors.has_door(crossroads_door_id), "real generated Crossroads primary door is enrolled")
    _check(door_mutations.set_state(crossroads_door_id, DoorValue.OPEN), "test can mutate a real Crossroads door to OPEN")
    _check(doors.state(crossroads_door_id) == DoorValue.OPEN, "Crossroads door mutation is persistent state")

    var away_cell: Vector2i = global_plan.bounds.position
    var away_focus: Dictionary = streaming.update_focus(away_cell)
    _check(bool(away_focus.get("ok", false)), "focus can move away from Crossroads")
    _check(not streaming.is_cell_active(crossroads_center), "Crossroads technical region deactivates when focus moves away")
    _check(world.has_entity(crossroads_door_id) and doors.state(crossroads_door_id) == DoorValue.OPEN, "deactivation neither deletes the door nor resets its state")

    var before_return_world: int = world.revision()
    var before_return_doors: int = doors.revision()
    var before_return_registry: int = registry.revision()
    var return_focus: Dictionary = streaming.update_focus(crossroads_center)
    _check(bool(return_focus.get("ok", false)), "Crossroads can be revisited")
    _check(doors.state(crossroads_door_id) == DoorValue.OPEN, "revisit preserves the player-mutated OPEN door state")
    _check(world.revision() == before_return_world and doors.revision() == before_return_doors and registry.revision() == before_return_registry, "revisit performs no regeneration writes")

    _test_atomic_collision_rollback(global_plan, world, mutations, doors, registry, source, materialization)

    for site_id: String in site_ids:
        var site: Dictionary = _site_by_id(global_plan, site_id)
        var focus_result: Dictionary = streaming.update_focus(_rect_center(site.get("bounds", Rect2i())))
        _check(bool(focus_result.get("ok", false)), "%s can be materialized/activated into the shared authoritative world" % site_id)
    _check(registry.source_keys().size() == 5, "all five current logical sites coexist in one Materialization Registry")
    for site_id: String in site_ids:
        _check(registry.has_source(source.source_key_for_site(site_id)), "%s remains recorded after multi-site streaming" % site_id)

    var all_world_revision: int = world.revision()
    var all_door_revision: int = doors.revision()
    var all_registry_revision: int = registry.revision()
    var all_again: Dictionary = materialization.ensure_area_sites(global_plan, site_ids)
    _check(bool(all_again.get("ok", false)), "ensuring all five already-materialized sites succeeds")
    _check((all_again.get("newly_materialized", []) as Array).is_empty() and (all_again.get("already_materialized", []) as Array).size() == 5, "all repeated ensures are classified as already materialized")
    _check(world.revision() == all_world_revision and doors.revision() == all_door_revision and registry.revision() == all_registry_revision, "repeated five-site ensure leaves WHAT/Door/registry revisions unchanged")

    var registry_snapshot: Dictionary = registry.snapshot()
    var restored_registry: MaterializationRegistry = RegistryClass.new()
    _check(restored_registry.load_snapshot(registry_snapshot), "Materialization Registry snapshot restores atomically")
    _check(restored_registry.snapshot() == registry_snapshot, "Materialization Registry round-trips deterministically")

    var active_before: Array[Vector2i] = streaming.active_region_coords()
    var focus_before: Vector2i = streaming.focus_cell()
    var invalid_world_snapshot: Dictionary = world.snapshot()
    var invalid_door_snapshot: Dictionary = doors.snapshot()
    var invalid_registry_snapshot: Dictionary = registry.snapshot()
    var invalid_focus: Dictionary = streaming.update_focus(global_plan.bounds.position - Vector2i.ONE)
    _check(not bool(invalid_focus.get("ok", false)), "focus outside world bounds fails explicitly")
    _check(streaming.focus_cell() == focus_before and streaming.active_region_coords() == active_before, "failed focus leaves active streaming state unchanged")
    _check(world.snapshot() == invalid_world_snapshot and doors.snapshot() == invalid_door_snapshot and registry.snapshot() == invalid_registry_snapshot, "failed focus leaves all persistent state unchanged")

func _test_atomic_collision_rollback(
    global_plan: GeneratedGlobalWorldPlan,
    world: WorldState,
    mutations: WorldMutationService,
    doors: DoorStateStore,
    registry: MaterializationRegistry,
    source: AreaSiteMaterializationSource,
    materialization: WorldMaterializationCoordinator
) -> void:
    var future_site_id: String = ""
    for site_id: String in _site_ids(global_plan):
        if not registry.has_source(source.source_key_for_site(site_id)):
            future_site_id = site_id
            break
    _check(not future_site_id.is_empty(), "a virgin future site exists for rollback test")
    if future_site_id.is_empty():
        return

    var prepared: Dictionary = source.prepare(global_plan, future_site_id)
    _check(bool(prepared.get("ok", false)), "virgin future site can be prepared without persistent writes")
    var plan: GeneratedAreaPlan = prepared.get("plan") as GeneratedAreaPlan
    if plan == null or not plan.is_generated() or plan.outdoor_props.is_empty():
        _check(false, "future site exposes a deterministic entity ID for collision test")
        return
    var collision_id: String = String(plan.outdoor_props[0].get("id", ""))
    _check(not collision_id.is_empty(), "future-site collision ID is available")
    if collision_id.is_empty():
        return
    _check(mutations.create_entity(&"prop.test_streaming_collision", collision_id) == collision_id, "preexisting entity collision is installed deliberately")

    var world_before: Dictionary = world.snapshot()
    var doors_before: Dictionary = doors.snapshot()
    var registry_before: Dictionary = registry.snapshot()
    var failed: Dictionary = materialization.ensure_area_site(global_plan, future_site_id)
    _check(not bool(failed.get("ok", false)), "stable-ID collision fails future-site materialization")
    _check(world.snapshot() == world_before, "failed materialization restores WHAT exactly")
    _check(doors.snapshot() == doors_before, "failed materialization restores Door State exactly")
    _check(registry.snapshot() == registry_before, "failed materialization restores registry exactly")
    _check(not registry.has_source(source.source_key_for_site(future_site_id)), "failed source is never falsely marked materialized")
    _check(mutations.remove_entity(collision_id), "deliberate collision entity is removed after rollback proof")

func _test_empty_region(global_plan: GeneratedGlobalWorldPlan) -> void:
    var world: WorldState = WorldStateClass.new()
    var mutations: WorldMutationService = WorldMutationClass.new(world)
    var doors: DoorStateStore = DoorStateClass.new()
    var door_mutations: DoorStateMutationService = DoorMutationClass.new(doors, world)
    var registry: MaterializationRegistry = RegistryClass.new()
    var source: AreaSiteMaterializationSource = SourceClass.new(registry)
    var materialization: WorldMaterializationCoordinator = MaterializationClass.new(world, mutations, doors, door_mutations, registry, source)
    var grid: StreamingRegionGrid = GridClass.new(global_plan.bounds, Vector2i(256, 256))
    var streaming: WorldStreamingCoordinator = StreamingClass.new(global_plan, grid, materialization, source, 0)

    var empty_coord: Vector2i = StreamingRegionGrid.INVALID_COORD
    for y in range(grid.grid_size().y):
        for x in range(grid.grid_size().x):
            var coord := Vector2i(x, y)
            var one_bounds: Array[Rect2i] = [grid.region_bounds(coord)]
            if source.site_ids_intersecting(global_plan, one_bounds).is_empty():
                empty_coord = coord
                break
        if empty_coord != StreamingRegionGrid.INVALID_COORD:
            break
    _check(empty_coord != StreamingRegionGrid.INVALID_COORD, "current global fixture contains a technical region with no local materialization source")
    if empty_coord == StreamingRegionGrid.INVALID_COORD:
        return

    var before_world: Dictionary = world.snapshot()
    var before_doors: Dictionary = doors.snapshot()
    var before_registry: Dictionary = registry.snapshot()
    var bounds: Rect2i = grid.region_bounds(empty_coord)
    var result: Dictionary = streaming.update_focus(bounds.position)
    _check(bool(result.get("ok", false)), "source-free technical region is a valid active region")
    _check(streaming.active_region_coords() == [empty_coord], "radius-zero streaming activates exactly the source-free technical region")
    _check(world.snapshot() == before_world and doors.snapshot() == before_doors and registry.snapshot() == before_registry, "source-free region creates no fake countryside terrain/entities or registry facts")

func _primary_door_id(plan: GeneratedAreaPlan) -> String:
    if plan == null or plan.building_requests.is_empty():
        return ""
    var request: BuildingGenerationRequest = plan.building_requests[0]
    return "%s.door.exterior.primary" % request.instance_id

func _site_ids(global_plan: GeneratedGlobalWorldPlan) -> Array[String]:
    var result: Array[String] = []
    for site: Dictionary in global_plan.area_sites:
        result.append(String(site.get("id", "")))
    result.sort()
    return result

func _site_by_id(global_plan: GeneratedGlobalWorldPlan, site_id: String) -> Dictionary:
    for site: Dictionary in global_plan.area_sites:
        if String(site.get("id", "")) == site_id:
            return site
    return {}

func _rect_center(rect: Rect2i) -> Vector2i:
    return rect.position + Vector2i(rect.size.x / 2, rect.size.y / 2)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("STREAMING_MATERIALIZATION_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("STREAMING_MATERIALIZATION_SMOKE_FAIL: %s" % failure)
    quit(1)