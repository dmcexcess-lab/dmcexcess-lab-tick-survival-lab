extends SceneTree

const GlobalFixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const GlobalPlannerClass = preload("res://scripts/generation/world/GlobalWorldPlanner.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const GeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const DoorMutationClass = preload("res://scripts/simulation/doors/DoorStateMutationService.gd")
const GridClass = preload("res://scripts/streaming/StreamingRegionGrid.gd")
const RegistryClass = preload("res://scripts/streaming/MaterializationRegistry.gd")
const AreaSourceClass = preload("res://scripts/streaming/AreaSiteMaterializationSource.gd")
const CatalogClass = preload("res://scripts/streaming/CountrysideSourceCatalog.gd")
const CountrysideSourceClass = preload("res://scripts/streaming/CountrysideMaterializationSource.gd")
const MaterializationClass = preload("res://scripts/streaming/WorldMaterializationCoordinator.gd")
const StreamingClass = preload("res://scripts/streaming/WorldStreamingCoordinator.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var planner: GlobalWorldPlanner = GlobalPlannerClass.new()
    var global_plan: GeneratedGlobalWorldPlan = planner.generate(GlobalFixtureClass.request())
    _check(global_plan != null and global_plan.is_generated(), "System 00D v6 world generates before countryside source catalog")
    if global_plan == null or not global_plan.is_generated():
        _finish()
        return

    var replay: GeneratedGlobalWorldPlan = planner.generate(GlobalFixtureClass.request())
    _check(replay.is_generated() and replay.signature() == global_plan.signature(), "System 00D v6 signature remains exact")

    var catalog: CountrysideSourceCatalog = CatalogClass.new(global_plan)
    _check(catalog.is_ready(), "countryside logical source catalog builds from current global planning truth")
    if not catalog.is_ready():
        push_error("COUNTRYSIDE_CATALOG_FAILURE: %s" % catalog.failure_reason())
        _finish()
        return

    _test_catalog(global_plan, catalog)
    _test_source_preparation(global_plan, catalog)
    _test_mixed_registry(global_plan, catalog)
    _test_revisit_persistence(global_plan, catalog)
    _test_mixed_collision_rollback(global_plan, catalog)
    _test_river_gap(global_plan, catalog)
    _finish()

func _test_catalog(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog) -> void:
    _check(catalog.catalog_version() == 1, "countryside source catalog is explicitly version 1")
    _check(catalog.context_bounds() == global_plan.bounds, "current broad rural-open context covers canonical global bounds")
    _check(bool(catalog.validate_source_bounds(global_plan).get("ok", false)), "catalog source bounds/coverage validate against the real global plan")

    var replay: CountrysideSourceCatalog = CatalogClass.new(global_plan)
    _check(replay.is_ready() and replay.source_keys() == catalog.source_keys(), "same global plan reproduces identical countryside source keys")
    _check(catalog.source_keys().size() == catalog.source_ids().size() and catalog.source_keys().size() > global_plan.geography_cells.size(), "fragmented countryside sources are unique and retain dry land around exclusions")

    var grid256: StreamingRegionGrid = GridClass.new(global_plan.bounds, Vector2i(256, 256))
    var grid320: StreamingRegionGrid = GridClass.new(global_plan.bounds, Vector2i(320, 320))
    _check(grid256.is_valid() and grid320.is_valid() and grid256.grid_size() != grid320.grid_size(), "technical stream grid remains independently replaceable")
    _check(replay.source_keys() == catalog.source_keys(), "technical stream-grid size cannot change countryside logical source identity")

    var seen: Dictionary = {}
    for source: Dictionary in catalog.sources():
        var source_id: String = String(source.get("source_id", ""))
        var source_key: String = String(source.get("source_key", ""))
        var parent_id: String = String(source.get("parent_geography_id", ""))
        var bounds: Rect2i = source.get("bounds", Rect2i())
        _check(not source_id.is_empty() and source_id.begins_with("rural.open.v1."), "source ID carries the v1 logical catalog identity")
        _check(source_key == "system20_rural_open:%s" % source_id, "source key is kind + stable logical source ID")
        _check(not seen.has(source_key), "countryside source key is unique: %s" % source_key)
        seen[source_key] = true
        var parent: Dictionary = _geography_by_id(global_plan, parent_id)
        _check(not parent.is_empty() and _rect_inside(parent.get("rect", Rect2i()), bounds), "source stays inside one parent System 00D geography cell")
        for site: Dictionary in global_plan.area_sites:
            _check(not _overlap(bounds, site.get("bounds", Rect2i())), "countryside source never overlaps settlement ownership")
        for river_rect: Rect2i in catalog.river_exclusion_rects():
            _check(not _overlap(bounds, river_rect), "countryside source never overlaps unsupported river corridor")

    _check(_exact_dry_coverage(catalog), "every non-settlement/non-river rural-open cell belongs to exactly one countryside source")
    _check(_dry_land_beside_river_exists(global_plan, catalog), "dry land immediately beside the river remains source-owned")

func _test_source_preparation(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog) -> void:
    var registry: MaterializationRegistry = RegistryClass.new()
    var countryside: CountrysideMaterializationSource = CountrysideSourceClass.new(registry, catalog)
    _check(countryside.is_ready(), "countryside source adapter is independently ready")

    var roadless: Dictionary = _find_source(global_plan, catalog, false, false)
    var roadside: Dictionary = _find_source(global_plan, catalog, true, false)
    _check(not roadless.is_empty(), "catalog contains ordinary roadless countryside")
    _check(not roadside.is_empty(), "catalog contains roadside countryside")

    if not roadless.is_empty():
        var prepared: Dictionary = countryside.prepare(global_plan, String(roadless.get("source_id", "")))
        _check(bool(prepared.get("ok", false)), "roadless countryside prepares through real System 20C")
        var plan: GeneratedAreaPlan = prepared.get("plan") as GeneratedAreaPlan
        _check(plan != null and plan.is_generated() and plan.roads.is_empty(), "roadless source remains genuinely roadless after local generation")

    if not roadside.is_empty():
        var prepared_road: Dictionary = countryside.prepare(global_plan, String(roadside.get("source_id", "")))
        _check(bool(prepared_road.get("ok", false)), "roadside countryside prepares through real System 20C")
        var road_plan: GeneratedAreaPlan = prepared_road.get("plan") as GeneratedAreaPlan
        _check(road_plan != null and road_plan.is_generated() and not road_plan.roads.is_empty(), "roadside source preserves inherited regional road truth")

func _test_mixed_registry(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog) -> void:
    var stack: Dictionary = _stack(global_plan, catalog)
    var materialization: WorldMaterializationCoordinator = stack.get("materialization") as WorldMaterializationCoordinator
    var registry: MaterializationRegistry = stack.get("registry") as MaterializationRegistry
    _check(materialization != null and materialization.is_ready(), "mixed-source materialization coordinator is ready")
    if materialization == null or not materialization.is_ready():
        return

    var area_source: AreaSiteMaterializationSource = stack.get("area_source") as AreaSiteMaterializationSource
    var countryside: CountrysideMaterializationSource = stack.get("countryside") as CountrysideMaterializationSource
    var handles: Array[Dictionary] = []
    for site: Dictionary in global_plan.area_sites:
        handles.append(area_source.source_handle_for_site(global_plan, String(site.get("id", ""))))
    var rural: Dictionary = _small_source(catalog)
    _check(not rural.is_empty(), "one bounded countryside source is available for mixed registry test")
    if not rural.is_empty():
        handles.append(countryside.source_handle_for_id(String(rural.get("source_id", ""))))

    var result: Dictionary = materialization.ensure_sources(global_plan, handles)
    _check(bool(result.get("ok", false)), "all five settlement sources and countryside commit in one atomic mixed-source batch")
    _check(_registry_kind_count(registry, AreaSiteMaterializationSource.SOURCE_KIND) == 5, "all five settlement source records coexist with countryside")
    _check(_registry_kind_count(registry, CountrysideSourceCatalog.SOURCE_KIND) >= 1, "countryside provenance coexists in MaterializationRegistry schema v1")
    _check(MaterializationRegistry.SNAPSHOT_SCHEMA_VERSION == 1, "second source kind does not require a registry schema bump")

    var snapshot: Dictionary = registry.snapshot()
    var restored: MaterializationRegistry = RegistryClass.new()
    _check(restored.load_snapshot(snapshot) and restored.snapshot() == snapshot, "mixed settlement/countryside registry snapshot restores deterministically")

func _test_revisit_persistence(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog) -> void:
    var candidate: Dictionary = _find_source(global_plan, catalog, false, true)
    _check(not candidate.is_empty(), "a dry countryside source with a real natural prop exists for persistence test")
    if candidate.is_empty():
        return

    var source_id: String = String(candidate.get("source_id", ""))
    var stack: Dictionary = _stack(global_plan, catalog)
    var world: WorldState = stack.get("world") as WorldState
    var mutations: WorldMutationService = stack.get("mutations") as WorldMutationService
    var registry: MaterializationRegistry = stack.get("registry") as MaterializationRegistry
    var countryside: CountrysideMaterializationSource = stack.get("countryside") as CountrysideMaterializationSource
    var streaming: WorldStreamingCoordinator = _streaming_for_stack(global_plan, stack, 0)
    _check(streaming != null and streaming.is_ready(), "radius-zero test streaming composition is ready without changing default policy")
    if streaming == null or not streaming.is_ready():
        return

    var prepared: Dictionary = countryside.prepare(global_plan, source_id)
    var plan: GeneratedAreaPlan = prepared.get("plan") as GeneratedAreaPlan
    _check(bool(prepared.get("ok", false)) and plan != null and plan.is_generated(), "persistence source can be prepared before first materialization")
    if plan == null or not plan.is_generated() or plan.outdoor_props.is_empty():
        return
    var prop_id: String = String(plan.outdoor_props[0].get("id", ""))
    var source_bounds: Rect2i = candidate.get("bounds", Rect2i())
    var focus: Vector2i = _rect_center(source_bounds)

    var first: Dictionary = streaming.update_focus(focus)
    _check(bool(first.get("ok", false)), "ordinary countryside focus materializes nearby logical countryside sources")
    var source_key: String = String(candidate.get("source_key", ""))
    _check(registry.has_source(source_key), "focused countryside logical source receives persistent provenance")
    _check(world.has_terrain(focus), "focused countryside becomes real WHAT terrain")
    _check(world.has_entity(prop_id), "real generated countryside natural prop materializes")
    _check(mutations.remove_entity(prop_id), "test removes one real countryside natural prop as a persistent world mutation")
    _check(not world.has_entity(prop_id), "removed countryside prop is absent from current WHAT")

    var away: Vector2i = _far_cell(global_plan.bounds, focus)
    var away_result: Dictionary = streaming.update_focus(away)
    _check(bool(away_result.get("ok", false)), "technical focus can deactivate the mutated countryside region")
    _check(not streaming.is_cell_active(focus), "mutated countryside technical region is inactive")

    var world_before_return: int = world.revision()
    var registry_before_return: int = registry.revision()
    var doors: DoorStateStore = stack.get("doors") as DoorStateStore
    var door_before_return: int = doors.revision()
    var returned: Dictionary = streaming.update_focus(focus)
    _check(bool(returned.get("ok", false)), "mutated countryside can be revisited")
    _check(not world.has_entity(prop_id), "revisit does not regenerate the removed countryside prop")
    _check(world.revision() == world_before_return and registry.revision() == registry_before_return and doors.revision() == door_before_return, "countryside revisit performs zero persistent regeneration writes")

func _test_mixed_collision_rollback(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog) -> void:
    var candidate: Dictionary = _find_source(global_plan, catalog, false, true)
    _check(not candidate.is_empty(), "virgin countryside collision source exists")
    if candidate.is_empty():
        return

    var stack: Dictionary = _stack(global_plan, catalog)
    var world: WorldState = stack.get("world") as WorldState
    var mutations: WorldMutationService = stack.get("mutations") as WorldMutationService
    var doors: DoorStateStore = stack.get("doors") as DoorStateStore
    var registry: MaterializationRegistry = stack.get("registry") as MaterializationRegistry
    var area_source: AreaSiteMaterializationSource = stack.get("area_source") as AreaSiteMaterializationSource
    var countryside: CountrysideMaterializationSource = stack.get("countryside") as CountrysideMaterializationSource
    var materialization: WorldMaterializationCoordinator = stack.get("materialization") as WorldMaterializationCoordinator

    var rural_id: String = String(candidate.get("source_id", ""))
    var prepared: Dictionary = countryside.prepare(global_plan, rural_id)
    var rural_plan: GeneratedAreaPlan = prepared.get("plan") as GeneratedAreaPlan
    _check(bool(prepared.get("ok", false)) and rural_plan != null and not rural_plan.outdoor_props.is_empty(), "virgin countryside exposes deterministic entity identity for collision rollback")
    if rural_plan == null or rural_plan.outdoor_props.is_empty():
        return
    var collision_id: String = String(rural_plan.outdoor_props[0].get("id", ""))
    _check(mutations.create_entity(&"prop.test_countryside_collision", collision_id) == collision_id, "deliberate preexisting countryside entity-ID collision is installed")

    var site: Dictionary = global_plan.area_sites[0]
    var handles: Array[Dictionary] = [
        area_source.source_handle_for_site(global_plan, String(site.get("id", ""))),
        countryside.source_handle_for_id(rural_id),
    ]
    var world_before: Dictionary = world.snapshot()
    var doors_before: Dictionary = doors.snapshot()
    var registry_before: Dictionary = registry.snapshot()
    var failed: Dictionary = materialization.ensure_sources(global_plan, handles)
    _check(not bool(failed.get("ok", false)), "one countryside ID collision fails the entire mixed source batch")
    _check(world.snapshot() == world_before, "failed mixed batch restores WHAT exactly")
    _check(doors.snapshot() == doors_before, "failed mixed batch restores Door State exactly")
    _check(registry.snapshot() == registry_before, "failed mixed batch restores Materialization Registry exactly")

func _test_river_gap(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog) -> void:
    _check(not global_plan.river_segments.is_empty(), "canonical world has a real river for unsupported-gap test")
    if global_plan.river_segments.is_empty():
        return
    var river: Dictionary = global_plan.river_segments[global_plan.river_segments.size() / 2]
    var start: Vector2i = river.get("start", Vector2i.ZERO)
    var finish: Vector2i = river.get("end", Vector2i.ZERO)
    var river_cell := Vector2i((start.x + finish.x) / 2, (start.y + finish.y) / 2)
    if not global_plan.bounds.has_point(river_cell):
        return

    var stack: Dictionary = _stack(global_plan, catalog)
    var world: WorldState = stack.get("world") as WorldState
    var streaming: WorldStreamingCoordinator = _streaming_for_stack(global_plan, stack, 0)
    var result: Dictionary = streaming.update_focus(river_cell)
    _check(bool(result.get("ok", false)), "focus near unsupported river may materialize surrounding dry countryside")
    _check(not world.has_terrain(river_cell), "known river corridor cell remains honestly unmaterialized instead of becoming grass/road")
    _check(catalog.descriptor_for_cell(river_cell).is_empty(), "unsupported river cell has no countryside logical source")

func _stack(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog) -> Dictionary:
    var world: WorldState = WorldStateClass.new()
    var mutations: WorldMutationService = WorldMutationClass.new(world)
    var doors: DoorStateStore = DoorStateClass.new()
    var door_mutations: DoorStateMutationService = DoorMutationClass.new(doors, world)
    var registry: MaterializationRegistry = RegistryClass.new()
    var area_source: AreaSiteMaterializationSource = AreaSourceClass.new(registry)
    var countryside: CountrysideMaterializationSource = CountrysideSourceClass.new(registry, catalog)
    var materialization: WorldMaterializationCoordinator = MaterializationClass.new(
        world, mutations, doors, door_mutations, registry, area_source, countryside
    )
    return {
        "world": world,
        "mutations": mutations,
        "doors": doors,
        "door_mutations": door_mutations,
        "registry": registry,
        "area_source": area_source,
        "countryside": countryside,
        "materialization": materialization,
    }

func _streaming_for_stack(
    global_plan: GeneratedGlobalWorldPlan,
    stack: Dictionary,
    active_radius: int
) -> WorldStreamingCoordinator:
    var grid: StreamingRegionGrid = GridClass.new(global_plan.bounds, Vector2i(256, 256))
    return StreamingClass.new(
        global_plan,
        grid,
        stack.get("materialization") as WorldMaterializationCoordinator,
        stack.get("area_source") as AreaSiteMaterializationSource,
        active_radius,
        stack.get("countryside") as CountrysideMaterializationSource
    )

func _find_source(
    global_plan: GeneratedGlobalWorldPlan,
    catalog: CountrysideSourceCatalog,
    require_road: bool,
    require_prop: bool
) -> Dictionary:
    var projector: System20AreaRequestProjector = ProjectorClass.new()
    var generator: LocalAreaGenerator = GeneratorClass.new()
    for source: Dictionary in catalog.sources():
        var bounds: Rect2i = source.get("bounds", Rect2i())
        if bounds.size.x < 24 or bounds.size.y < 24:
            continue
        var projected: Dictionary = projector.project_rural_open_bounds(global_plan, String(source.get("source_id", "")), bounds)
        if not bool(projected.get("ok", false)):
            continue
        var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
        if request == null or require_road != (not request.inherited_roads.is_empty()):
            continue
        if not require_prop:
            return source
        var plan: GeneratedAreaPlan = generator.generate(request)
        if plan != null and plan.is_generated() and not plan.outdoor_props.is_empty():
            return source
    return {}

func _small_source(catalog: CountrysideSourceCatalog) -> Dictionary:
    var best: Dictionary = {}
    var best_area: int = 2147483647
    for source: Dictionary in catalog.sources():
        var bounds: Rect2i = source.get("bounds", Rect2i())
        var area: int = bounds.size.x * bounds.size.y
        if area > 0 and area < best_area:
            best_area = area
            best = source
    return best

func _registry_kind_count(registry: MaterializationRegistry, kind: StringName) -> int:
    var count: int = 0
    for source_key: String in registry.source_keys():
        var record: MaterializationRecord = registry.record(source_key)
        if record != null and record.source_kind == kind:
            count += 1
    return count

func _exact_dry_coverage(catalog: CountrysideSourceCatalog) -> bool:
    var context: Rect2i = catalog.context_bounds()
    var source_rects: Array[Rect2i] = []
    for source: Dictionary in catalog.sources():
        source_rects.append(source.get("bounds", Rect2i()))
    var settlement_rects: Array[Rect2i] = catalog.settlement_exclusion_rects()
    var river_rects: Array[Rect2i] = catalog.river_exclusion_rects()
    var width: int = context.size.x

    for y in range(context.position.y, context.position.y + context.size.y):
        var counts := PackedByteArray()
        var excluded := PackedByteArray()
        counts.resize(width)
        excluded.resize(width)
        for rect: Rect2i in source_rects:
            if y < rect.position.y or y >= rect.position.y + rect.size.y:
                continue
            var start_x: int = maxi(rect.position.x, context.position.x)
            var end_x: int = mini(rect.position.x + rect.size.x, context.position.x + context.size.x)
            for x in range(start_x, end_x):
                var index: int = x - context.position.x
                counts[index] = mini(2, int(counts[index]) + 1)
        for rect: Rect2i in settlement_rects + river_rects:
            if y < rect.position.y or y >= rect.position.y + rect.size.y:
                continue
            var start_x: int = maxi(rect.position.x, context.position.x)
            var end_x: int = mini(rect.position.x + rect.size.x, context.position.x + context.size.x)
            for x in range(start_x, end_x):
                excluded[x - context.position.x] = 1
        for index in range(width):
            if excluded[index] == 1:
                if counts[index] != 0:
                    return false
            elif counts[index] != 1:
                return false
    return true

func _dry_land_beside_river_exists(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog) -> bool:
    for corridor: Rect2i in catalog.river_exclusion_rects():
        var candidates: Array[Vector2i] = [
            Vector2i(corridor.position.x - 1, corridor.position.y + corridor.size.y / 2),
            Vector2i(corridor.position.x + corridor.size.x, corridor.position.y + corridor.size.y / 2),
            Vector2i(corridor.position.x + corridor.size.x / 2, corridor.position.y - 1),
            Vector2i(corridor.position.x + corridor.size.x / 2, corridor.position.y + corridor.size.y),
        ]
        for cell: Vector2i in candidates:
            if not global_plan.bounds.has_point(cell) or _inside_any_site(global_plan, cell):
                continue
            if not catalog.descriptor_for_cell(cell).is_empty():
                return true
    return false

func _inside_any_site(global_plan: GeneratedGlobalWorldPlan, cell: Vector2i) -> bool:
    for site: Dictionary in global_plan.area_sites:
        var bounds: Rect2i = site.get("bounds", Rect2i())
        if bounds.has_point(cell):
            return true
    return false

func _geography_by_id(global_plan: GeneratedGlobalWorldPlan, geography_id: String) -> Dictionary:
    for geography: Dictionary in global_plan.geography_cells:
        if String(geography.get("id", "")) == geography_id:
            return geography
    return {}

func _far_cell(bounds: Rect2i, from_cell: Vector2i) -> Vector2i:
    var corners: Array[Vector2i] = [
        bounds.position,
        Vector2i(bounds.position.x + bounds.size.x - 1, bounds.position.y),
        Vector2i(bounds.position.x, bounds.position.y + bounds.size.y - 1),
        bounds.position + bounds.size - Vector2i.ONE,
    ]
    var best: Vector2i = corners[0]
    var best_distance: int = -1
    for value: Vector2i in corners:
        var distance: int = absi(value.x - from_cell.x) + absi(value.y - from_cell.y)
        if distance > best_distance:
            best_distance = distance
            best = value
    return best

func _rect_center(rect: Rect2i) -> Vector2i:
    return Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2)

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var last: Vector2i = inner.position + inner.size - Vector2i.ONE
    return outer.has_point(inner.position) and outer.has_point(last)

func _overlap(a: Rect2i, b: Rect2i) -> bool:
    if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0:
        return false
    var a_end: Vector2i = a.position + a.size
    var b_end: Vector2i = b.position + b.size
    return a.position.x < b_end.x and a_end.x > b.position.x \
        and a.position.y < b_end.y and a_end.y > b.position.y

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("COUNTRYSIDE_STREAMING_MATERIALIZATION_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("COUNTRYSIDE_STREAMING_MATERIALIZATION_SMOKE_FAIL: %s" % failure)
    quit(1)
