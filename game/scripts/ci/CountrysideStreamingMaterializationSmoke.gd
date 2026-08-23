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
    _check(global_plan != null and global_plan.is_generated(), "System 00D v6 world generates")
    if global_plan == null or not global_plan.is_generated():
        _finish()
        return
    var replay: GeneratedGlobalWorldPlan = planner.generate(GlobalFixtureClass.request())
    _check(replay.is_generated() and replay.signature() == global_plan.signature(), "System 00D signature remains exact")

    var catalog: CountrysideSourceCatalog = CatalogClass.new(global_plan)
    _check(catalog.is_ready(), "countryside logical source catalog builds")
    if not catalog.is_ready():
        push_error("COUNTRYSIDE_CATALOG_FAILURE: %s" % catalog.failure_reason())
        _finish()
        return

    _test_catalog(global_plan, catalog)
    _test_preparation(global_plan, catalog)
    _test_mixed_materialization(global_plan, catalog)
    _test_revisit(global_plan, catalog)
    _test_mixed_rollback(global_plan, catalog)
    _test_river_gap(global_plan, catalog)
    _finish()

func _test_catalog(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog) -> void:
    _check(catalog.catalog_version() == 1, "catalog is explicitly version 1")
    _check(catalog.context_bounds() == global_plan.bounds, "canonical rural-open context matches global bounds")
    _check(bool(catalog.validate_source_bounds(global_plan).get("ok", false)), "catalog validates against the real global plan")
    _check(not catalog.source_keys().is_empty() and catalog.source_keys().size() == catalog.source_ids().size(), "catalog has unique logical sources")

    var replay: CountrysideSourceCatalog = CatalogClass.new(global_plan)
    _check(replay.is_ready() and replay.source_keys() == catalog.source_keys(), "same global plan reproduces identical source keys")
    var grid_256: StreamingRegionGrid = GridClass.new(global_plan.bounds, Vector2i(256, 256))
    var grid_320: StreamingRegionGrid = GridClass.new(global_plan.bounds, Vector2i(320, 320))
    _check(grid_256.is_valid() and grid_320.is_valid() and grid_256.grid_size() != grid_320.grid_size(), "technical stream grids may differ")
    _check(replay.source_keys() == catalog.source_keys(), "technical stream-grid size does not define source identity")

    var seen: Dictionary = {}
    for source: Dictionary in catalog.sources():
        var source_id: String = String(source.get("source_id", ""))
        var source_key: String = String(source.get("source_key", ""))
        var bounds: Rect2i = source.get("bounds", Rect2i())
        var parent: Dictionary = _geography_by_id(global_plan, String(source.get("parent_geography_id", "")))
        _check(source_id.begins_with("rural.open.v1."), "source ID carries catalog version")
        _check(source_key == "system20_rural_open:%s" % source_id and not seen.has(source_key), "source key is unique and kind-scoped")
        seen[source_key] = true
        _check(not parent.is_empty() and _rect_inside(parent.get("rect", Rect2i()), bounds), "source stays inside one geography parent")
        for site: Dictionary in global_plan.area_sites:
            _check(not _overlap(bounds, site.get("bounds", Rect2i())), "source does not overlap settlement ownership")
        for river_rect: Rect2i in catalog.river_exclusion_rects():
            _check(not _overlap(bounds, river_rect), "source does not overlap river corridor")

    _check(_exact_dry_coverage(catalog), "all dry cells are covered exactly once and exclusions zero times")
    _check(_dry_land_beside_river_exists(global_plan, catalog), "dry land immediately beside river remains source-owned")

func _test_preparation(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog) -> void:
    var registry: MaterializationRegistry = RegistryClass.new()
    var countryside: CountrysideMaterializationSource = CountrysideSourceClass.new(registry, catalog)
    var roadless: Dictionary = _find_source(global_plan, catalog, false, false)
    var roadside: Dictionary = _find_source(global_plan, catalog, true, false)
    _check(countryside.is_ready() and not roadless.is_empty() and not roadside.is_empty(), "adapter finds roadless and roadside countryside")

    if not roadless.is_empty():
        var prepared: Dictionary = countryside.prepare(global_plan, String(roadless.get("source_id", "")))
        var plan: GeneratedAreaPlan = prepared.get("plan") as GeneratedAreaPlan
        _check(bool(prepared.get("ok", false)) and plan != null and plan.is_generated() and plan.roads.is_empty(), "roadless source prepares through System 20C without a fake road")

    if not roadside.is_empty():
        var prepared: Dictionary = countryside.prepare(global_plan, String(roadside.get("source_id", "")))
        var plan: GeneratedAreaPlan = prepared.get("plan") as GeneratedAreaPlan
        _check(bool(prepared.get("ok", false)) and plan != null and plan.is_generated() and not plan.roads.is_empty(), "roadside source preserves real regional roads")
        if plan != null and plan.is_generated():
            for road: Dictionary in plan.roads:
                _check(bool(road.get("inherited", false)), "rural-open roadside plan contains inherited roads only")

func _test_mixed_materialization(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog) -> void:
    var stack: Dictionary = _stack(catalog)
    var materialization: WorldMaterializationCoordinator = stack.get("materialization") as WorldMaterializationCoordinator
    var registry: MaterializationRegistry = stack.get("registry") as MaterializationRegistry
    var area_source: AreaSiteMaterializationSource = stack.get("area_source") as AreaSiteMaterializationSource
    var countryside: CountrysideMaterializationSource = stack.get("countryside") as CountrysideMaterializationSource
    var rural: Dictionary = _find_source(global_plan, catalog, false, false)
    _check(materialization.is_ready() and not rural.is_empty(), "mixed-source coordinator and countryside source are ready")
    if rural.is_empty():
        return

    var handles: Array = [
        area_source.source_handle_for_site(global_plan, String(global_plan.area_sites[0].get("id", ""))),
        countryside.source_handle_for_id(String(rural.get("source_id", ""))),
    ]
    var mixed: Dictionary = materialization.ensure_sources(global_plan, handles)
    _check(bool(mixed.get("ok", false)) and _strings_sorted(mixed.get("newly_materialized", [])), "mixed settlement+countryside batch commits in stable key order")

    var all_site_ids: Array[String] = []
    for site: Dictionary in global_plan.area_sites:
        all_site_ids.append(String(site.get("id", "")))
    _check(bool(materialization.ensure_area_sites(global_plan, all_site_ids).get("ok", false)), "legacy area-site API still ensures all five settlements")
    _check(_registry_kind_count(registry, AreaSiteMaterializationSource.SOURCE_KIND) == 5, "all five settlement records coexist")
    _check(_registry_kind_count(registry, CountrysideSourceCatalog.SOURCE_KIND) >= 1, "countryside record coexists with settlement records")
    _check(MaterializationRegistry.SNAPSHOT_SCHEMA_VERSION == 1, "mixed source kinds keep registry schema v1")
    var snapshot: Dictionary = registry.snapshot()
    var restored: MaterializationRegistry = RegistryClass.new()
    _check(restored.load_snapshot(snapshot) and restored.snapshot() == snapshot, "mixed registry snapshot round-trips")

func _test_revisit(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog) -> void:
    var candidate: Dictionary = _find_source(global_plan, catalog, false, true)
    _check(not candidate.is_empty(), "natural-prop countryside exists for revisit test")
    if candidate.is_empty():
        return
    var stack: Dictionary = _stack(catalog)
    var world: WorldState = stack.get("world") as WorldState
    var mutations: WorldMutationService = stack.get("mutations") as WorldMutationService
    var doors: DoorStateStore = stack.get("doors") as DoorStateStore
    var registry: MaterializationRegistry = stack.get("registry") as MaterializationRegistry
    var countryside: CountrysideMaterializationSource = stack.get("countryside") as CountrysideMaterializationSource
    var streaming: WorldStreamingCoordinator = _streaming(global_plan, stack, 0)

    var prepared: Dictionary = countryside.prepare(global_plan, String(candidate.get("source_id", "")))
    var plan: GeneratedAreaPlan = prepared.get("plan") as GeneratedAreaPlan
    if not bool(prepared.get("ok", false)) or plan == null or plan.outdoor_props.is_empty():
        _check(false, "revisit source prepares with a natural prop")
        return
    var prop_id: String = String(plan.outdoor_props[0].get("id", ""))
    var focus: Vector2i = _rect_center(candidate.get("bounds", Rect2i()))
    _check(bool(streaming.update_focus(focus).get("ok", false)), "countryside focus materializes nearby logical sources")
    _check(registry.has_source(String(candidate.get("source_key", ""))) and world.has_entity(prop_id), "focused source receives provenance and real prop")
    _check(mutations.remove_entity(prop_id) and not world.has_entity(prop_id), "real countryside prop can be persistently removed")

    var away: Vector2i = _far_cell(global_plan.bounds, focus)
    _check(bool(streaming.update_focus(away).get("ok", false)) and not streaming.is_cell_active(focus), "technical region deactivates without deleting world truth")
    var world_revision: int = world.revision()
    var door_revision: int = doors.revision()
    var registry_revision: int = registry.revision()
    _check(bool(streaming.update_focus(focus).get("ok", false)), "countryside revisits")
    _check(not world.has_entity(prop_id), "removed prop does not regenerate on revisit")
    _check(world.revision() == world_revision and doors.revision() == door_revision and registry.revision() == registry_revision, "revisit causes zero persistent writes")

func _test_mixed_rollback(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog) -> void:
    var candidate: Dictionary = _find_source(global_plan, catalog, false, true)
    if candidate.is_empty():
        _check(false, "rollback countryside source exists")
        return
    var stack: Dictionary = _stack(catalog)
    var world: WorldState = stack.get("world") as WorldState
    var mutations: WorldMutationService = stack.get("mutations") as WorldMutationService
    var doors: DoorStateStore = stack.get("doors") as DoorStateStore
    var registry: MaterializationRegistry = stack.get("registry") as MaterializationRegistry
    var area_source: AreaSiteMaterializationSource = stack.get("area_source") as AreaSiteMaterializationSource
    var countryside: CountrysideMaterializationSource = stack.get("countryside") as CountrysideMaterializationSource
    var materialization: WorldMaterializationCoordinator = stack.get("materialization") as WorldMaterializationCoordinator

    var source_id: String = String(candidate.get("source_id", ""))
    var prepared: Dictionary = countryside.prepare(global_plan, source_id)
    var plan: GeneratedAreaPlan = prepared.get("plan") as GeneratedAreaPlan
    if plan == null or plan.outdoor_props.is_empty():
        _check(false, "rollback source exposes deterministic prop ID")
        return
    var collision_id: String = String(plan.outdoor_props[0].get("id", ""))
    _check(mutations.create_entity(&"prop.test_countryside_collision", collision_id) == collision_id, "forced countryside entity-ID collision installed")

    var handles: Array = [
        area_source.source_handle_for_site(global_plan, String(global_plan.area_sites[0].get("id", ""))),
        countryside.source_handle_for_id(source_id),
    ]
    var world_before: Dictionary = world.snapshot()
    var doors_before: Dictionary = doors.snapshot()
    var registry_before: Dictionary = registry.snapshot()
    var failed: Dictionary = materialization.ensure_sources(global_plan, handles)
    _check(not bool(failed.get("ok", false)), "countryside collision fails entire mixed batch")
    _check(world.snapshot() == world_before and doors.snapshot() == doors_before and registry.snapshot() == registry_before, "mixed failure rolls all three domains back exactly")

func _test_river_gap(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog) -> void:
    if global_plan.river_segments.is_empty():
        _check(false, "canonical river exists")
        return
    var river: Dictionary = global_plan.river_segments[global_plan.river_segments.size() / 2]
    var start: Vector2i = river.get("start", Vector2i.ZERO)
    var finish: Vector2i = river.get("end", Vector2i.ZERO)
    var river_cell := Vector2i((start.x + finish.x) / 2, (start.y + finish.y) / 2)
    if not global_plan.bounds.has_point(river_cell):
        _check(false, "river test cell inside world")
        return
    var stack: Dictionary = _stack(catalog)
    var world: WorldState = stack.get("world") as WorldState
    var streaming: WorldStreamingCoordinator = _streaming(global_plan, stack, 0)
    _check(bool(streaming.update_focus(river_cell).get("ok", false)), "river-region focus can materialize surrounding dry sources")
    _check(catalog.descriptor_for_cell(river_cell).is_empty() and not world.has_terrain(river_cell), "river corridor stays source-free and unmaterialized")

func _stack(catalog: CountrysideSourceCatalog) -> Dictionary:
    var world: WorldState = WorldStateClass.new()
    var mutations: WorldMutationService = WorldMutationClass.new(world)
    var doors: DoorStateStore = DoorStateClass.new()
    var door_mutations: DoorStateMutationService = DoorMutationClass.new(doors, world)
    var registry: MaterializationRegistry = RegistryClass.new()
    var area_source: AreaSiteMaterializationSource = AreaSourceClass.new(registry)
    var countryside: CountrysideMaterializationSource = CountrysideSourceClass.new(registry, catalog)
    var materialization: WorldMaterializationCoordinator = MaterializationClass.new(world, mutations, doors, door_mutations, registry, area_source, countryside)
    return {"world": world, "mutations": mutations, "doors": doors, "registry": registry, "area_source": area_source, "countryside": countryside, "materialization": materialization}

func _streaming(global_plan: GeneratedGlobalWorldPlan, stack: Dictionary, radius: int) -> WorldStreamingCoordinator:
    return StreamingClass.new(global_plan, GridClass.new(global_plan.bounds, Vector2i(256, 256)), stack.get("materialization") as WorldMaterializationCoordinator, stack.get("area_source") as AreaSiteMaterializationSource, radius, stack.get("countryside") as CountrysideMaterializationSource)

func _find_source(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog, require_road: bool, require_prop: bool) -> Dictionary:
    var projector: System20AreaRequestProjector = ProjectorClass.new()
    var generator: LocalAreaGenerator = GeneratorClass.new()
    for source: Dictionary in catalog.sources():
        var bounds: Rect2i = source.get("bounds", Rect2i())
        if bounds.size.x < 16 or bounds.size.y < 16:
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

func _registry_kind_count(registry: MaterializationRegistry, kind: StringName) -> int:
    var count: int = 0
    for key: String in registry.source_keys():
        var record: MaterializationRecord = registry.record(key)
        if record != null and record.source_kind == kind:
            count += 1
    return count

func _strings_sorted(values: Array) -> bool:
    var copied: Array[String] = []
    for value: Variant in values:
        copied.append(String(value))
    var sorted: Array[String] = copied.duplicate()
    sorted.sort()
    return copied == sorted

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
            if y >= rect.position.y and y < rect.position.y + rect.size.y:
                for x in range(maxi(rect.position.x, context.position.x), mini(rect.position.x + rect.size.x, context.position.x + context.size.x)):
                    var index: int = x - context.position.x
                    counts[index] = mini(2, int(counts[index]) + 1)
        for rect: Rect2i in settlement_rects:
            _mark_exclusion_row(rect, y, context, excluded)
        for rect: Rect2i in river_rects:
            _mark_exclusion_row(rect, y, context, excluded)
        for index in range(width):
            if excluded[index] == 1:
                if counts[index] != 0:
                    return false
            elif counts[index] != 1:
                return false
    return true

func _mark_exclusion_row(rect: Rect2i, y: int, context: Rect2i, excluded: PackedByteArray) -> void:
    if y < rect.position.y or y >= rect.position.y + rect.size.y:
        return
    for x in range(maxi(rect.position.x, context.position.x), mini(rect.position.x + rect.size.x, context.position.x + context.size.x)):
        excluded[x - context.position.x] = 1

func _dry_land_beside_river_exists(global_plan: GeneratedGlobalWorldPlan, catalog: CountrysideSourceCatalog) -> bool:
    for corridor: Rect2i in catalog.river_exclusion_rects():
        var candidates: Array[Vector2i] = [Vector2i(corridor.position.x - 1, corridor.position.y + corridor.size.y / 2), Vector2i(corridor.position.x + corridor.size.x, corridor.position.y + corridor.size.y / 2), Vector2i(corridor.position.x + corridor.size.x / 2, corridor.position.y - 1), Vector2i(corridor.position.x + corridor.size.x / 2, corridor.position.y + corridor.size.y)]
        for cell: Vector2i in candidates:
            if global_plan.bounds.has_point(cell) and not _inside_site(global_plan, cell) and not catalog.descriptor_for_cell(cell).is_empty():
                return true
    return false

func _inside_site(global_plan: GeneratedGlobalWorldPlan, cell: Vector2i) -> bool:
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
    var a: Vector2i = bounds.position
    var b: Vector2i = bounds.position + bounds.size - Vector2i.ONE
    return a if absi(a.x - from_cell.x) + absi(a.y - from_cell.y) >= absi(b.x - from_cell.x) + absi(b.y - from_cell.y) else b

func _rect_center(rect: Rect2i) -> Vector2i:
    return Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2)

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    return inner.size.x > 0 and inner.size.y > 0 and outer.has_point(inner.position) and outer.has_point(inner.position + inner.size - Vector2i.ONE)

func _overlap(a: Rect2i, b: Rect2i) -> bool:
    if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0:
        return false
    var a_end: Vector2i = a.position + a.size
    var b_end: Vector2i = b.position + b.size
    return a.position.x < b_end.x and a_end.x > b.position.x and a.position.y < b_end.y and a_end.y > b.position.y

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
