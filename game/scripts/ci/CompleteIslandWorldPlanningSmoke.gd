extends SceneTree

const FixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const RequestClass = preload("res://scripts/generation/world/GlobalWorldGenerationRequest.gd")
const ProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const IslandPlannerClass = preload("res://scripts/generation/world/IslandWorldPlanner.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const LocalGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const IslandSurfaceCatalogClass = preload("res://scripts/streaming/IslandSurfaceSourceCatalog.gd")
const WatercourseCatalogClass = preload("res://scripts/streaming/WatercourseSourceCatalog.gd")
const Surface = preload("res://scripts/generation/shared/IslandSurfaceMath.gd")

var failures: Array[String] = []

func _initialize() -> void:
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
    _check(plan.area_sites.size() == 7, "five settlement sites plus two road-backed districts form the island local-site set")
    _check(_site_profile(plan, "area.rural.crossroads.001") == &"rural.crossroads", "rural crossroads remains globally placed")
    _check(_site_profile(plan, "area.smalltown.center.001") == &"smalltown.center", "small-town center is globally placed")
    _check(_site_profile(plan, "area.rural.scattered.001") == &"rural.scattered", "north rural satellite remains globally placed")
    _check(_site_profile(plan, "area.rural.scattered.002") == &"rural.scattered", "southwest rural satellite remains globally placed")
    _check(_site_profile(plan, "area.rural.scattered.003") == &"rural.scattered", "northeast rural satellite remains globally placed")
    _check(_site_profile(plan, "area.island.suburban.001") == &"suburban.neighborhood", "road-backed suburban neighborhood is globally placed")
    _check(_site_profile(plan, "area.island.urban.001") == &"urban.mixed", "road-backed urban mixed/city-center-style district is globally placed")
    _check(_site_size(plan, "area.island.suburban.001") == Vector2i(384, 384), "suburban district uses proven baseline site geometry")
    _check(_site_size(plan, "area.island.urban.001") == Vector2i(384, 384), "urban district uses proven baseline site geometry")
    _check(not plan.river_segments.is_empty(), "island retains a physical river")
    _check(not plan.bridge_intents.is_empty(), "real road/river crossings retain explicit bridges")

    var replay: GeneratedGlobalWorldPlan = planner.generate(request)
    _check(replay != null and replay.is_generated() and replay.signature() == plan.signature(), "island global plan replays deterministically")

    _test_all_area_sites(plan)
    _test_surface_source_partition(plan)
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
    for required: String in [
        "rural.crossroads",
        "smalltown.center",
        "suburban.neighborhood",
        "urban.mixed",
        "rural.scattered",
    ]:
        _check(profiles_seen.has(required), "integrated island uses profile %s" % required)

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

func _test_surface_shape(plan: GeneratedGlobalWorldPlan) -> void:
    var profiles := ProfilesClass.new()
    var profile: Dictionary = profiles.profile(ProfilesClass.TEMPERATE_ISLAND_REGION)
    var ocean_count: int = 0
    var shore_count: int = 0
    var land_count: int = 0
    var step: int = 16
    for y in range(plan.bounds.position.y, plan.bounds.position.y + plan.bounds.size.y, step):
        for x in range(plan.bounds.position.x, plan.bounds.position.x + plan.bounds.size.x, step):
            var kind: StringName = Surface.classify(
                plan.bounds,
                plan.seed,
                Vector2i(x, y),
                int(profile.get("island_ocean_margin", 24)),
                int(profile.get("island_shore_width", 8)),
                int(profile.get("island_coast_wobble", 8)),
                int(profile.get("island_coast_scale", 96))
            )
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

func _site_size(plan: GeneratedGlobalWorldPlan, site_id: String) -> Vector2i:
    for site: Dictionary in plan.area_sites:
        if String(site.get("id", "")) == site_id:
            var bounds: Rect2i = site.get("bounds", Rect2i())
            return bounds.size
    return Vector2i.ZERO

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
