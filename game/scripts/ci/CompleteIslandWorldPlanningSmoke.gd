extends SceneTree

const FixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const PlayableFixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const RequestClass = preload("res://scripts/generation/world/GlobalWorldGenerationRequest.gd")
const ProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const IslandPlannerClass = preload("res://scripts/generation/world/IslandWorldPlanner.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const LocalGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const IslandSurfaceGeneratorClass = preload("res://scripts/generation/areas/IslandSurfaceAreaGenerator.gd")
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

    print("ISLAND_DENSITY buildings=%d residents=%d infected=%d survivors=%d" % [(plan.local_area_manifest.get("buildings", []) as Array).size(), plan.resident_population, plan.infected_population, plan.survivor_population])
    _check(plan.profile_id == ProfilesClass.TEMPERATE_ISLAND_REGION, "island profile identity is recorded")
    _check(plan.profile_version == 9, "rural infill island profile v9 is recorded")
    _check(plan.bounds.size == Vector2i(3072, 3072), "settlement-first envelope determines island size")
    _check(plan.area_sites.size() == 35, "island has two towns, three crossroads and thirty sparse rural sites")
    _check(_site_profile_count(plan, &"smalltown.center") == 2, "island has two larger small-town anchors")
    _check(_site_bounds_size_count(plan, &"smalltown.center", Vector2i(512, 512)) == 2, "both town anchors receive full 512-cell town envelopes")
    _check(_site_profile_count(plan, &"rural.crossroads") == 3, "island has three rural crossroads")
    _check(_site_profile_count(plan, &"rural.scattered") == 30, "island has thirty distributed rural home-and-farm sites")
    _check(_sites_do_not_overlap(plan), "settlement envelopes do not overlap")
    _check(_settlement_coverage_ratio(plan) <= 0.30, "compact settlement cores leave room for managed countryside")
    _check(_has_outer_rural_settlement(plan), "rural development reaches outward without filling the coast")
    _check(not plan.river_segments.is_empty(), "island retains physical hydrology")
    _check(not plan.bridge_intents.is_empty(), "real road/river crossings retain explicit bridges")
    _check(not plan.power_nodes.is_empty() and not plan.power_segments.is_empty(), "utilities consume the generated settlement road network")
    _check(plan.water_services.size() == plan.settlements.size(), "island-wide municipal water serves every generated settlement")
    _check((plan.local_area_manifest.get("buildings", []) as Array).size() >= 550 and (plan.local_area_manifest.get("buildings", []) as Array).size() <= 650, "reference island has roughly six hundred physical buildings")
    _check(plan.population_settlements.size() == plan.area_sites.size(), "each real settlement manifest owns a population record")
    _check(plan.resident_population > 0 and plan.infected_population + plan.survivor_population == plan.resident_population, "infected population is constrained by actual island residents")
    _check(bool(plan.local_area_manifest.get("ok", false)), "real local-area manifest is retained for startup consumers")
    _check(int(plan.local_area_manifest.get("world_seed", -1)) == plan.seed, "retained local-area manifest owns the island seed")
    _check((plan.local_area_manifest.get("site_building_counts", {}) as Dictionary).size() == plan.area_sites.size(), "retained manifest covers every settlement exactly once")

    var replay: GeneratedGlobalWorldPlan = planner.generate(request)
    _check(replay != null and replay.is_generated() and replay.signature() == plan.signature(), "same island seed replays exactly")

    _test_rural_land_use_target()
    _test_all_area_sites(plan)
    _test_playable_spawn(plan)
    _test_surface_partition(plan)
    _finish()

func _test_rural_land_use_target() -> void:
    var profile: Dictionary = ProfilesClass.new().profile(ProfilesClass.TEMPERATE_ISLAND_REGION)
    var wilderness_target: float = float(profile.get("island_wilderness_fraction", -1.0))
    var block_size: int = int(profile.get("island_land_use_block_size", 0))
    _check(is_equal_approx(wilderness_target, 0.10), "island targets ten percent true wilderness")
    _check(block_size == 64, "rural land use uses coarse generation-time blocks")
    if wilderness_target < 0.0 or block_size <= 0:
        return

    var wilderness: int = 0
    var fields: int = 0
    var pasture: int = 0
    var samples: int = 0
    for block_y: int in range(100):
        for block_x: int in range(100):
            var cell := Vector2i(block_x * block_size, block_y * block_size)
            var use: StringName = IslandSurfaceGeneratorClass.land_use_kind(
                FixtureClass.SEED,
                cell,
                block_size,
                wilderness_target
            )
            samples += 1
            if use == IslandSurfaceGeneratorClass.LAND_USE_WILDERNESS:
                wilderness += 1
            elif use == IslandSurfaceGeneratorClass.LAND_USE_FIELD:
                fields += 1
            elif use == IslandSurfaceGeneratorClass.LAND_USE_PASTURE:
                pasture += 1
    var wilderness_ratio: float = float(wilderness) / float(samples)
    _check(wilderness_ratio >= 0.08 and wilderness_ratio <= 0.12, "deterministic countryside field stays near ten percent wilderness")
    _check(fields > wilderness and pasture > wilderness, "managed fields and pasture dominate wilderness")
    _check(wilderness + fields + pasture == samples, "every countryside block receives one real land-use class")

func _site_bounds_size_count(plan: GeneratedGlobalWorldPlan, profile_id: StringName, size: Vector2i) -> int:
    var count: int = 0
    for site: Dictionary in plan.area_sites:
        var bounds: Rect2i = site.get("bounds", Rect2i())
        if StringName(site.get("area_profile_hint", &"")) == profile_id and bounds.size == size:
            count += 1
    return count

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
            _check(_count_residential_buildings(generated) >= 70, "small town has clustered residential density: %s" % site_id)
        if request.area_profile_id == &"rural.crossroads":
            _check(generated.building_requests.size() <= 22, "crossroads remains a compact one-light settlement")
            var businesses: int = 0
            for building: BuildingGenerationRequest in generated.building_requests:
                if String(building.archetype_id).begins_with("commercial."):
                    businesses += 1
            _check(businesses >= 1, "each crossroads has a real service center")
        if request.area_profile_id == &"rural.scattered":
            _check(generated.building_requests.size() <= 14, "rural lanes remain sparsely inhabited")
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
    _check(surface_catalog.is_ready(), "island countryside surface catalog is ready")
    _check(water_catalog.is_ready(), "watercourse source catalog is ready")
    if not surface_catalog.is_ready() or not water_catalog.is_ready():
        return
    _check(bool(surface_catalog.validate_source_bounds(plan).get("ok", false)), "countryside surface sources validate around settlement sites")
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
