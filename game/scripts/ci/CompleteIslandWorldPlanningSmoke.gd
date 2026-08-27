extends SceneTree

const FixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const PlayableFixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const RequestClass = preload("res://scripts/generation/world/GlobalWorldGenerationRequest.gd")
const ProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const AreaProfilesClass = preload("res://scripts/generation/areas/AreaProfileCatalog.gd")
const IslandPlannerClass = preload("res://scripts/generation/world/IslandWorldPlanner.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const IslandProjectionClass = preload("res://scripts/generation/integration/IslandSurfaceRequestProjection.gd")
const LocalGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const IslandSurfaceGeneratorClass = preload("res://scripts/generation/areas/IslandSurfaceAreaGenerator.gd")
const IslandSurfaceCatalogClass = preload("res://scripts/streaming/IslandSurfaceSourceCatalog.gd")
const WatercourseCatalogClass = preload("res://scripts/streaming/WatercourseSourceCatalog.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Surface = preload("res://scripts/generation/shared/IslandSurfaceMath.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var area_profiles := AreaProfilesClass.new()
    _check(area_profiles.has_profile(&"smalltown.center"), "small-town center profile remains available")
    _check(area_profiles.has_profile(&"suburban.neighborhood"), "suburban neighborhood profile remains available")
    _check(area_profiles.has_profile(&"urban.mixed"), "urban mixed/city-center-style profile remains available")

    var request := RequestClass.new(
        FixtureClass.WORLD_ID,
        FixtureClass.SEED,
        FixtureClass.BOUNDS,
        ProfilesClass.TEMPERATE_ISLAND_REGION
    )
    var planner := IslandPlannerClass.new()
    var plan: GeneratedGlobalWorldPlan = planner.generate(request)
    _check(plan != null and plan.is_generated(), "temperate island global plan generates")
    if plan == null or not plan.is_generated():
        if plan != null:
            push_error("COMPLETE_ISLAND_PLAN_FAILURE_REASON: %s" % plan.failure_reason)
        _finish()
        return

    _check(plan.profile_id == ProfilesClass.TEMPERATE_ISLAND_REGION, "island profile identity is recorded")
    _check(plan.area_sites.size() == 5, "five proven connected settlement sites form the first complete island")
    _check(_site_profile(plan, "area.rural.crossroads.001") == &"rural.crossroads", "rural crossroads remains globally placed")
    _check(_site_profile(plan, "area.smalltown.center.001") == &"smalltown.center", "small-town center is globally placed")
    _check(_site_profile(plan, "area.rural.scattered.001") == &"rural.scattered", "north rural satellite remains globally placed")
    _check(_site_profile(plan, "area.rural.scattered.002") == &"rural.scattered", "southwest rural satellite remains globally placed")
    _check(_site_profile(plan, "area.rural.scattered.003") == &"rural.scattered", "northeast rural satellite remains globally placed")
    _check(not plan.river_segments.is_empty(), "island retains a physical river")
    _check(not plan.bridge_intents.is_empty(), "real road/river crossings retain explicit bridges")

    var replay: GeneratedGlobalWorldPlan = planner.generate(request)
    _check(replay != null and replay.is_generated() and replay.signature() == plan.signature(), "island global plan replays deterministically")

    _test_all_area_sites(plan)
    _test_playable_spawn(plan)
    _test_surface_source_partition(plan)
    _test_surface_detail_and_road_paint(plan)
    _test_surface_shape(plan)
    _finish()

func _test_all_area_sites(plan: GeneratedGlobalWorldPlan) -> void:
    var projector := ProjectorClass.new()
    var generator := LocalGeneratorClass.new()
    var profiles_seen: Dictionary = {}
    for site: Dictionary in plan.area_sites:
        var site_id: String = String(site.get("id", ""))
        var projected: Dictionary = projector.project_site(plan, site_id)
        _check(bool(projected.get("ok", false)), "area site projects: %s" % site_id)
        var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
        if request == null or not request.is_valid():
            continue
        profiles_seen[String(request.area_profile_id)] = true
        var generated: GeneratedAreaPlan = generator.generate(request)
        _check(generated != null and generated.is_generated(), "area site generates: %s" % site_id)
        if generated != null and not generated.is_generated():
            push_error("COMPLETE_ISLAND_AREA_FAILURE:%s:%s" % [site_id, generated.failure_reason])
    for required: String in ["rural.crossroads", "smalltown.center", "rural.scattered"]:
        _check(profiles_seen.has(required), "integrated island uses profile %s" % required)

func _test_playable_spawn(plan: GeneratedGlobalWorldPlan) -> void:
    var projected: Dictionary = ProjectorClass.new().project_site(plan, PlayableFixtureClass.CENTRAL_SITE_ID)
    _check(bool(projected.get("ok", false)), "playable central site projects for spawn verification")
    var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
    if request == null or not request.is_valid():
        return
    var generated: GeneratedAreaPlan = LocalGeneratorClass.new().generate(request)
    _check(generated != null and generated.is_generated(), "playable central site generates for spawn verification")
    if generated == null or not generated.is_generated():
        return
    var spawn: Vector2i = PlayableFixtureClass.player_start_for_plan(generated)
    var center: Vector2i = _nearest_intersection_to_center(generated)
    _check(spawn.x >= 0 and generated.bounds.has_point(spawn), "playable spawn is a valid central-site cell")
    _check(center.x >= 0 and absi(spawn.x - center.x) + absi(spawn.y - center.y) <= 6, "playable spawn stays at the neutral central crossroads")
    _check(_cell_on_inherited_road(generated, spawn), "playable spawn is on inherited crossroads pavement")
    var legacy_diner_spawn: Vector2i = _legacy_diner_spawn(generated)
    _check(legacy_diner_spawn.x < 0 or spawn != legacy_diner_spawn, "playable spawn is no longer tied to the diner entrance")

func _test_surface_source_partition(plan: GeneratedGlobalWorldPlan) -> void:
    var surface_catalog := IslandSurfaceCatalogClass.new(plan)
    var water_catalog := WatercourseCatalogClass.new(plan)
    _check(surface_catalog.is_ready(), "island surface source catalog is ready")
    _check(water_catalog.is_ready(), "watercourse source catalog is ready")
    if not surface_catalog.is_ready() or not water_catalog.is_ready():
        return
    _check(bool(surface_catalog.validate_source_bounds(plan).get("ok", false)), "island surface sources validate")
    _check(bool(water_catalog.validate_source_bounds(plan).get("ok", false)), "watercourse sources validate")

    var source_rects: Array[Rect2i] = []
    for source: Dictionary in surface_catalog.sources():
        source_rects.append(source.get("bounds", Rect2i()))
    for source: Dictionary in water_catalog.sources():
        source_rects.append(source.get("bounds", Rect2i()))
    for site: Dictionary in plan.area_sites:
        source_rects.append(site.get("bounds", Rect2i()))

    var sample_step: int = 32
    for y in range(plan.bounds.position.y, plan.bounds.position.y + plan.bounds.size.y, sample_step):
        for x in range(plan.bounds.position.x, plan.bounds.position.x + plan.bounds.size.x, sample_step):
            var cell := Vector2i(x, y)
            var count: int = 0
            for rect: Rect2i in source_rects:
                if rect.has_point(cell):
                    count += 1
            _check(count == 1, "sampled world cell belongs to exactly one logical materialization source at %s" % cell)

func _test_surface_detail_and_road_paint(plan: GeneratedGlobalWorldPlan) -> void:
    var catalog := IslandSurfaceCatalogClass.new(plan)
    _check(catalog.is_ready(), "surface catalog is ready for continuity verification")
    if not catalog.is_ready():
        return
    var land_source: Dictionary = _first_land_surface_source(plan, catalog)
    var road_source: Dictionary = _first_road_surface_source(plan, catalog)
    _check(not land_source.is_empty(), "island has an ordinary-land surface source")
    _check(not road_source.is_empty(), "island has a road-bearing surface source")
    if land_source.is_empty() or road_source.is_empty():
        return

    var land_plan: GeneratedAreaPlan = _generate_surface_source(plan, land_source)
    _check(land_plan != null and land_plan.is_generated(), "ordinary island land source generates")
    if land_plan != null and land_plan.is_generated():
        _check(land_plan.area_profile_version >= 2, "island surface records countryside-dressing revision")
        _check(not land_plan.outdoor_props.is_empty(), "ordinary island land is dressed instead of becoming a blank green belt")
        _check(_all_surface_props_are_land(plan, land_plan), "island natural dressing stays on physical land")
        _check(_surface_props_avoid_roads(land_plan), "island natural dressing preserves road clearance")

    var road_plan: GeneratedAreaPlan = _generate_surface_source(plan, road_source)
    _check(road_plan != null and road_plan.is_generated(), "road-bearing island surface source generates")
    if road_plan != null and road_plan.is_generated():
        _check(not road_plan.roads.is_empty(), "road-bearing island surface retains inherited regional road")
        _check(_has_ground_semantic(road_plan, &"ground.road_plain"), "regional road surface persists outside settlement rectangles")
        var painted: bool = false
        for road: Dictionary in road_plan.roads:
            if bool(road.get("paint_centerline", false)):
                painted = true
                break
        if painted:
            _check(
                _has_ground_semantic(road_plan, &"ground.road_yellow_line_h") or _has_ground_semantic(road_plan, &"ground.road_yellow_line_v"),
                "painted regional road centerline continues through island-surface materialization"
            )

func _generate_surface_source(plan: GeneratedGlobalWorldPlan, source: Dictionary) -> GeneratedAreaPlan:
    var bounds: Rect2i = source.get("bounds", Rect2i())
    var source_id: String = String(source.get("source_id", ""))
    var projected: Dictionary = IslandProjectionClass.new().project(plan, source_id, bounds)
    _check(bool(projected.get("ok", false)), "island surface source projects: %s" % source_id)
    var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
    if request == null or not request.is_valid():
        return null
    return IslandSurfaceGeneratorClass.new().generate(request)

func _first_land_surface_source(plan: GeneratedGlobalWorldPlan, catalog: IslandSurfaceSourceCatalog) -> Dictionary:
    var profile: Dictionary = ProfilesClass.new().profile(ProfilesClass.TEMPERATE_ISLAND_REGION)
    for source: Dictionary in catalog.sources():
        var bounds: Rect2i = source.get("bounds", Rect2i())
        if bounds.size.x <= 0 or bounds.size.y <= 0:
            continue
        var center: Vector2i = bounds.position + Vector2i(bounds.size.x / 2, bounds.size.y / 2)
        if _surface_kind(plan, profile, center) == Surface.LAND:
            return source
    return {}

func _first_road_surface_source(plan: GeneratedGlobalWorldPlan, catalog: IslandSurfaceSourceCatalog) -> Dictionary:
    for source: Dictionary in catalog.sources():
        var bounds: Rect2i = source.get("bounds", Rect2i())
        for road: Dictionary in plan.road_segments:
            if _segment_has_positive_overlap(road, bounds):
                return source
    return {}

func _segment_has_positive_overlap(segment: Dictionary, bounds: Rect2i) -> bool:
    var start: Vector2i = segment.get("start", Vector2i(-999999, -999999))
    var finish: Vector2i = segment.get("end", Vector2i(-999999, -999999))
    if start.y == finish.y and start.y >= bounds.position.y and start.y < bounds.position.y + bounds.size.y:
        var lo: int = maxi(mini(start.x, finish.x), bounds.position.x)
        var hi: int = mini(maxi(start.x, finish.x), bounds.position.x + bounds.size.x - 1)
        return hi > lo
    if start.x == finish.x and start.x >= bounds.position.x and start.x < bounds.position.x + bounds.size.x:
        var lo_y: int = maxi(mini(start.y, finish.y), bounds.position.y)
        var hi_y: int = mini(maxi(start.y, finish.y), bounds.position.y + bounds.size.y - 1)
        return hi_y > lo_y
    return false

func _all_surface_props_are_land(plan: GeneratedGlobalWorldPlan, generated: GeneratedAreaPlan) -> bool:
    var profile: Dictionary = ProfilesClass.new().profile(ProfilesClass.TEMPERATE_ISLAND_REGION)
    for prop: Dictionary in generated.outdoor_props:
        var cell: Vector2i = prop.get("cell", Vector2i(-999999, -999999))
        if _surface_kind(plan, profile, cell) != Surface.LAND:
            return false
    return true

func _surface_props_avoid_roads(generated: GeneratedAreaPlan) -> bool:
    var road_cells: Dictionary = {}
    for road: Dictionary in generated.roads:
        for value: Variant in road.get("corridor_cells", []):
            if typeof(value) == TYPE_VECTOR2I:
                road_cells[value] = true
    for prop: Dictionary in generated.outdoor_props:
        if road_cells.has(prop.get("cell", Vector2i(-999999, -999999))):
            return false
    return true

func _surface_kind(plan: GeneratedGlobalWorldPlan, profile: Dictionary, cell: Vector2i) -> StringName:
    return Surface.classify(
        plan.bounds,
        plan.seed,
        cell,
        int(profile.get("island_ocean_margin", 24)),
        int(profile.get("island_shore_width", 8)),
        int(profile.get("island_coast_wobble", 8)),
        int(profile.get("island_coast_scale", 96))
    )

func _has_ground_semantic(plan: GeneratedAreaPlan, semantic: StringName) -> bool:
    for region: Dictionary in plan.ground_regions:
        if StringName(region.get("semantic", &"")) == semantic:
            return true
    return false

func _nearest_intersection_to_center(plan: GeneratedAreaPlan) -> Vector2i:
    var expected: Vector2i = plan.bounds.position + Vector2i(plan.bounds.size.x / 2, plan.bounds.size.y / 2)
    var best: Vector2i = Vector2i(-1, -1)
    var best_distance: int = 2147483647
    for intersection: Dictionary in plan.intersections:
        var cell: Vector2i = intersection.get("cell", Vector2i(-1, -1))
        var distance: int = absi(cell.x - expected.x) + absi(cell.y - expected.y)
        if distance < best_distance:
            best = cell
            best_distance = distance
    return best

func _cell_on_inherited_road(plan: GeneratedAreaPlan, cell: Vector2i) -> bool:
    for road: Dictionary in plan.roads:
        if not bool(road.get("inherited", false)):
            continue
        for value: Variant in road.get("corridor_cells", []):
            if typeof(value) == TYPE_VECTOR2I and value == cell:
                return true
    return false

func _legacy_diner_spawn(plan: GeneratedAreaPlan) -> Vector2i:
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("building_archetype_id", &"")) != &"commercial.diner.rural_small":
            continue
        var entry: Vector2i = parcel.get("building_entry_cell", Vector2i(-1, -1))
        var frontage: int = int(parcel.get("frontage_side", -1))
        if entry.x >= 0 and Facing.is_valid(frontage):
            return entry + Facing.vector(frontage)
    return Vector2i(-1, -1)

func _test_surface_shape(plan: GeneratedGlobalWorldPlan) -> void:
    var profiles := ProfilesClass.new()
    var profile: Dictionary = profiles.profile(ProfilesClass.TEMPERATE_ISLAND_REGION)
    var ocean_count: int = 0
    var shore_count: int = 0
    var land_count: int = 0
    var step: int = 16
    for y in range(plan.bounds.position.y, plan.bounds.position.y + plan.bounds.size.y, step):
        for x in range(plan.bounds.position.x, plan.bounds.position.x + plan.bounds.size.x, step):
            var kind: StringName = _surface_kind(plan, profile, Vector2i(x, y))
            if kind == Surface.OCEAN:
                ocean_count += 1
            elif kind == Surface.SHORE:
                shore_count += 1
            elif kind == Surface.LAND:
                land_count += 1
    _check(ocean_count > 0, "island has surrounding ocean")
    _check(shore_count > 0, "island has a coast transition band")
    _check(land_count > ocean_count, "playable island retains a large connected land interior")
    print("COMPLETE_ISLAND_SURFACE_COUNTS=land:%d,shore:%d,ocean:%d" % [land_count, shore_count, ocean_count])

func _site_profile(plan: GeneratedGlobalWorldPlan, site_id: String) -> StringName:
    for site: Dictionary in plan.area_sites:
        if String(site.get("id", "")) == site_id:
            return StringName(site.get("area_profile_hint", &""))
    return &""

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("COMPLETE_ISLAND_WORLD_PLANNING_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("COMPLETE_ISLAND_WORLD_PLANNING_SMOKE_FAIL: %s" % failure)
    quit(1)
