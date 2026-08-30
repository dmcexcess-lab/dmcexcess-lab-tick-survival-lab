extends SceneTree

const FixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const PlayableFixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const RequestClass = preload("res://scripts/generation/world/GlobalWorldGenerationRequest.gd")
const ProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const IslandPlannerClass = preload("res://scripts/generation/world/IslandWorldPlanner.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const LocalGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const IslandSurfaceCatalogClass = preload("res://scripts/streaming/IslandSurfaceSourceCatalog.gd")
const WatercourseCatalogClass = preload("res://scripts/streaming/WatercourseSourceCatalog.gd")

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
    _check(plan != null and plan.is_generated(), "procedural rural island generates")
    if plan == null or not plan.is_generated():
        if plan != null:
            push_error("COMPLETE_ISLAND_PLAN_FAILURE_REASON: %s" % plan.failure_reason)
        _finish()
        return

    _check(plan.profile_id == ProfilesClass.TEMPERATE_ISLAND_REGION, "island profile identity is recorded")
    _check(plan.profile_version == 5, "rural island hierarchy v5 is recorded")
    _check(plan.area_sites.size() == 9, "island has nine sparse settlement sites")
    _check(_site_profile_count(plan, &"smalltown.center") == 2, "island has two larger small-town anchors")
    _check(_site_profile_count(plan, &"rural.crossroads") == 3, "island has three rural crossroads")
    _check(_site_profile_count(plan, &"rural.scattered") == 4, "island has four sparse rural hamlets")
    _check(_sites_do_not_overlap(plan), "settlement envelopes do not overlap")
    _check(_settlement_coverage_ratio(plan) <= 0.30, "most island area remains outside settlement envelopes")
    _check(_has_outer_rural_settlement(plan), "rural development reaches outward without filling the coast")
    _check(not plan.river_segments.is_empty(), "island retains physical hydrology")
    _check(not plan.bridge_intents.is_empty(), "real road/river crossings retain explicit bridges")
    _check(not plan.power_nodes.is_empty() and not plan.power_segments.is_empty(), "utilities consume the generated settlement road network")
    _check(plan.water_services.size() == plan.settlements.size(), "island-wide municipal water serves every generated settlement")

    var replay: GeneratedGlobalWorldPlan = planner.generate(request)
    _check(replay != null and replay.is_generated() and replay.signature() == plan.signature(), "same island seed replays exactly")

    _test_all_area_sites(plan)
    _test_playable_spawn(plan)
    _test_surface_partition(plan)
    _finish()

func _test_all_area_sites(plan: GeneratedGlobalWorldPlan) -> void:
    var projector := ProjectorClass.new()
    var generator := LocalGeneratorClass.new()
    var generated_count: int = 0
    var smalltown_count: int = 0
    for site: Dictionary in plan.area_sites:
        var site_id: String = String(site.get("id", ""))
        var projected: Dictionary = projector.project_site(plan, site_id)
        _check(bool(projected.get("ok", false)), "area site projects: %s" % site_id)
        var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
        if request == null or not request.is_valid():
            continue
        var generated: GeneratedAreaPlan = generator.generate(request)
        _check(generated != null and generated.is_generated(), "area site generates: %s" % site_id)
        if generated == null or not generated.is_generated():
            if generated != null:
                push_error("COMPLETE_ISLAND_AREA_FAILURE:%s:%s" % [site_id, generated.failure_reason])
            continue
        generated_count += 1
        if request.area_profile_id == &"smalltown.center":
            smalltown_count += 1
            _check(_smalltown_has_required_buildings(generated), "small town has real stores, post office, police, diner, and gas station: %s" % site_id)
            _check(_count_residential_buildings(generated) >= 12, "small town has clustered residential density: %s" % site_id)
    _check(generated_count == plan.area_sites.size(), "every procedural settlement site materializes")
    _check(smalltown_count == 2, "both procedural small towns materialize")

func _test_playable_spawn(plan: GeneratedGlobalWorldPlan) -> void:
    var projected: Dictionary = ProjectorClass.new().project_site(plan, PlayableFixtureClass.CENTRAL_SITE_ID)
    _check(bool(projected.get("ok", false)), "playable rural crossroads still projects")
    var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
    if request == null or not request.is_valid():
        return
    var generated: GeneratedAreaPlan = LocalGeneratorClass.new().generate(request)
    _check(generated != null and generated.is_generated(), "playable rural crossroads generates")
    if generated == null or not generated.is_generated():
        return
    var spawn: Vector2i = PlayableFixtureClass.player_start_for_plan(generated)
    _check(spawn.x >= 0 and generated.bounds.has_point(spawn), "playable spawn remains valid")

func _test_surface_partition(plan: GeneratedGlobalWorldPlan) -> void:
    var surface_catalog := IslandSurfaceCatalogClass.new(plan)
    var water_catalog := WatercourseCatalogClass.new(plan)
    _check(surface_catalog.is_ready(), "island wilderness surface catalog is ready")
    _check(water_catalog.is_ready(), "watercourse source catalog is ready")
    if not surface_catalog.is_ready() or not water_catalog.is_ready():
        return
    _check(bool(surface_catalog.validate_source_bounds(plan).get("ok", false)), "wilderness surface sources validate around settlement sites")
    _check(bool(water_catalog.validate_source_bounds(plan).get("ok", false)), "watercourse sources validate around settlement sites")

func _smalltown_has_required_buildings(plan: GeneratedAreaPlan) -> bool:
    var required: Dictionary = {
        &"commercial.gas_station.small": false,
        &"commercial.diner.rural_small": false,
        &"commercial.convenience_store.small": false,
        &"commercial.grocery.neighborhood": false,
        &"commercial.hardware_store.small": false,
        &"civic.post_office.small": false,
        &"civic.police_station.small": false,
    }
    for request: BuildingGenerationRequest in plan.building_requests:
        if required.has(request.archetype_id):
            required[request.archetype_id] = true
    for value: Variant in required.values():
        if not bool(value):
            return false
    return true

func _count_residential_buildings(plan: GeneratedAreaPlan) -> int:
    var count: int = 0
    for request: BuildingGenerationRequest in plan.building_requests:
        if String(request.archetype_id).begins_with("residential."):
            count += 1
    return count

func _site_profile_count(plan: GeneratedGlobalWorldPlan, profile_id: StringName) -> int:
    var count: int = 0
    for site: Dictionary in plan.area_sites:
        if StringName(site.get("area_profile_hint", &"")) == profile_id:
            count += 1
    return count

func _sites_do_not_overlap(plan: GeneratedGlobalWorldPlan) -> bool:
    for first_index: int in range(plan.area_sites.size()):
        var first: Rect2i = plan.area_sites[first_index].get("bounds", Rect2i())
        for second_index: int in range(first_index + 1, plan.area_sites.size()):
            var second: Rect2i = plan.area_sites[second_index].get("bounds", Rect2i())
            if first.intersects(second):
                return false
    return true

func _settlement_coverage_ratio(plan: GeneratedGlobalWorldPlan) -> float:
    var settlement_area: int = 0
    for site: Dictionary in plan.area_sites:
        var rect: Rect2i = site.get("bounds", Rect2i())
        settlement_area += rect.size.x * rect.size.y
    var world_area: int = plan.bounds.size.x * plan.bounds.size.y
    return 1.0 if world_area <= 0 else float(settlement_area) / float(world_area)

func _has_outer_rural_settlement(plan: GeneratedGlobalWorldPlan) -> bool:
    var center: Vector2i = plan.bounds.position + Vector2i(plan.bounds.size.x / 2, plan.bounds.size.y / 2)
    var threshold: int = int(float(mini(plan.bounds.size.x, plan.bounds.size.y)) * 0.28)
    for settlement: Dictionary in plan.settlements:
        if StringName(settlement.get("kind", &"")) == &"smalltown":
            continue
        var point: Vector2i = settlement.get("center", center)
        if absi(point.x - center.x) + absi(point.y - center.y) >= threshold:
            return true
    return false

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    failures.append(message)
    push_error("COMPLETE_ISLAND_WORLD_PLANNING_SMOKE_FAIL: %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("COMPLETE_ISLAND_WORLD_PLANNING_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("COMPLETE_ISLAND_WORLD_PLANNING_SMOKE_FAIL: %s" % failure)
    quit(1)
