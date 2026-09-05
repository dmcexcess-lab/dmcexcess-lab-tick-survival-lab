extends SceneTree

const GlobalFixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const GlobalPlannerClass = preload("res://scripts/generation/world/GlobalWorldPlanner.gd")
const GlobalValidatorClass = preload("res://scripts/generation/world/GeneratedGlobalWorldValidator.gd")
const PowerValidatorClass = preload("res://scripts/generation/world/GlobalPowerInfrastructureValidator.gd")
const WaterValidatorClass = preload("res://scripts/generation/world/GlobalWaterInfrastructureValidator.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const LocalFixtureClass = preload("res://scripts/demo/RuralCrossroadsPlanFixture.gd")
const LocalGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var planner: GlobalWorldPlanner = GlobalPlannerClass.new()
    var validator: GeneratedGlobalWorldValidator = GlobalValidatorClass.new()
    var power_validator: GlobalPowerInfrastructureValidator = PowerValidatorClass.new()
    var water_validator: GlobalWaterInfrastructureValidator = WaterValidatorClass.new()
    var projector: System20AreaRequestProjector = ProjectorClass.new()
    var request: GlobalWorldGenerationRequest = GlobalFixtureClass.request()
    var plan: GeneratedGlobalWorldPlan = planner.generate(request)

    _test_global_plan(planner, validator, power_validator, water_validator, request, plan)
    _test_system20_projection(projector, plan)
    _test_utility_projection_seams(projector, plan)

    if failures.is_empty():
        print("GLOBAL_WORLD_PLANNING_V7_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("GLOBAL_WORLD_PLANNING_V7_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_global_plan(
    planner: GlobalWorldPlanner,
    validator: GeneratedGlobalWorldValidator,
    power_validator: GlobalPowerInfrastructureValidator,
    water_validator: GlobalWaterInfrastructureValidator,
    request: GlobalWorldGenerationRequest,
    plan: GeneratedGlobalWorldPlan
) -> void:
    _check(request.is_valid(), "current global-world request remains valid")
    _check(plan.is_generated(), "current global plan generates")
    if not plan.is_generated():
        push_error("GLOBAL_WORLD_PLAN_FAILURE_REASON: %s" % plan.failure_reason)
        return

    _check(plan.profile_version == 8, "temperate.rural.region v8 is recorded")
    _check(bool(validator.validate(request, plan).get("ok", false)), "base geography/road validation remains green")
    _check(bool(power_validator.validate(request, plan).get("ok", false)), "regional power validation remains green")
    _check(bool(water_validator.validate(request, plan).get("ok", false)), "island-wide potable-water validation remains green")
    _check(plan.water_services.size() == plan.settlements.size(), "every settlement receives island-wide municipal water service")
    _check(_all_water_services_share_one_facility(plan), "all settlements reference one physical water facility")
    _check(_all_water_services_are_island_wide(plan), "all potable-water services use the island-wide municipal contract")

    var replay: GeneratedGlobalWorldPlan = planner.generate(GlobalFixtureClass.request(GlobalFixtureClass.SEED))
    _check(replay.is_generated() and replay.signature() == plan.signature(), "same seed replays all current global facts identically")

    var alternate_request: GlobalWorldGenerationRequest = GlobalFixtureClass.request(GlobalFixtureClass.SEED + 1)
    var alternate: GeneratedGlobalWorldPlan = planner.generate(alternate_request)
    _check(alternate.is_generated(), "alternate seed still generates a legal current world")
    if alternate.is_generated():
        _check(bool(validator.validate(alternate_request, alternate).get("ok", false)), "alternate seed passes base validation")
        _check(bool(power_validator.validate(alternate_request, alternate).get("ok", false)), "alternate seed passes power validation")
        _check(bool(water_validator.validate(alternate_request, alternate).get("ok", false)), "alternate seed passes island-wide potable-water validation")
        _check(_all_water_services_share_one_facility(alternate), "alternate seed preserves one shared water facility")
        _check(_all_water_services_are_island_wide(alternate), "alternate seed preserves island-wide municipal water service")

func _test_system20_projection(projector: System20AreaRequestProjector, plan: GeneratedGlobalWorldPlan) -> void:
    if not plan.is_generated():
        return
    var projected_result: Dictionary = projector.project_site(plan, GlobalFixtureClass.CENTRAL_SITE_ID)
    _check(bool(projected_result.get("ok", false)), "Candidate 006 still projects from global facts")
    var projected_request: AreaGenerationRequest = projected_result.get("request") as AreaGenerationRequest
    if projected_request == null:
        return
    var baseline_request: AreaGenerationRequest = LocalFixtureClass.request(LocalFixtureClass.SEED)
    _check(_area_request_signature(projected_request) == _area_request_signature(baseline_request), "retired infrastructure does not alter Candidate 006 request")
    _check(projected_request.inherited_planning_constraints.is_empty(), "Candidate 006 receives no unsupported infrastructure-reservation constraints")

    var local_generator: LocalAreaGenerator = LocalGeneratorClass.new()
    var projected_plan: GeneratedAreaPlan = local_generator.generate(projected_request)
    var baseline_plan: GeneratedAreaPlan = local_generator.generate(baseline_request)
    _check(projected_plan.is_generated(), "Candidate 006 still generates from projected request")
    _check(baseline_plan.is_generated(), "Candidate 006 baseline still generates")
    if projected_plan.is_generated() and baseline_plan.is_generated():
        _check(projected_plan.signature() == baseline_plan.signature(), "retired infrastructure leaves Candidate 006 semantic output exact")
        _check(projected_plan.area_profile_version == 5, "Candidate 006 remains rural.crossroads v5")
        _check(projected_plan.reservations.is_empty() and projected_plan.blocks.is_empty(), "Candidate 006 gains no unsupported reservation/block facts")

    var smalltown_result: Dictionary = projector.project_site(plan, "area.smalltown.center.001")
    _check(bool(smalltown_result.get("ok", false)), "small-town global site still projects into System 20")
    var smalltown_request: AreaGenerationRequest = smalltown_result.get("request") as AreaGenerationRequest
    _check(smalltown_request != null and smalltown_request.is_valid(), "projected small-town request remains valid")
    if smalltown_request != null and smalltown_request.is_valid():
        _check(smalltown_request.area_profile_id == &"smalltown.center", "small-town site selects smalltown.center")
        _check(not smalltown_request.inherited_planning_constraints.is_empty(), "small-town request carries current power/service infrastructure facts")
        var smalltown_plan: GeneratedAreaPlan = local_generator.generate(smalltown_request)
        _check(smalltown_plan.is_generated(), "small-town Candidate 001 still generates from current global facts")
        if smalltown_plan.is_generated():
            _check(smalltown_plan.area_profile_version == 5, "small-town Candidate 001 records profile v5")
            _check(not smalltown_plan.reservations.is_empty(), "small-town local plan contains current infrastructure reservations")
            _check(not smalltown_plan.blocks.is_empty(), "small-town local plan contains semantic town blocks")

    for hamlet_site_id: String in [
        "area.rural.scattered.001",
        "area.rural.scattered.002",
        "area.rural.scattered.003",
    ]:
        var hamlet_result: Dictionary = projector.project_site(plan, hamlet_site_id)
        _check(bool(hamlet_result.get("ok", false)), "%s projects into System 20" % hamlet_site_id)
        var hamlet_request: AreaGenerationRequest = hamlet_result.get("request") as AreaGenerationRequest
        _check(hamlet_request != null and hamlet_request.is_valid(), "%s projected request is valid" % hamlet_site_id)
        if hamlet_request == null or not hamlet_request.is_valid():
            continue
        _check(hamlet_request.area_profile_id == &"rural.scattered", "%s selects rural.scattered" % hamlet_site_id)
        _check(not hamlet_request.inherited_planning_constraints.is_empty(), "%s consumes current service/infrastructure facts" % hamlet_site_id)
        var hamlet_plan: GeneratedAreaPlan = local_generator.generate(hamlet_request)
        _check(hamlet_plan.is_generated(), "%s Candidate 001 generates from current global facts" % hamlet_site_id)
        if hamlet_plan.is_generated():
            _check(hamlet_plan.area_profile_version == 1, "%s records rural.scattered v1" % hamlet_site_id)
            _check(hamlet_plan.blocks.is_empty(), "%s remains block-free sparse rural morphology" % hamlet_site_id)
            _check(hamlet_plan.building_requests.size() == 6, "%s produces six occupied rural properties" % hamlet_site_id)

func _test_utility_projection_seams(projector: System20AreaRequestProjector, plan: GeneratedGlobalWorldPlan) -> void:
    if not plan.is_generated():
        return
    var center_bounds: Rect2i = LocalFixtureClass.BOUNDS

    var power: Dictionary = projector.power_constraints_for_bounds(plan, center_bounds)
    _check(bool(power.get("ok", false)), "Candidate 006 power projection still succeeds")
    _check(not (power.get("segments", []) as Array).is_empty(), "Candidate 006 still exposes regional feeder facts")

    var water: Dictionary = projector.water_constraints_for_bounds(plan, center_bounds)
    _check(bool(water.get("ok", false)), "Candidate 006 potable-water projection still succeeds")
    _check(_projection_has_one_island_wide_water_service(water), "Candidate 006 sees one island-wide municipal water service")

    var smalltown_site: Dictionary = _site_by_id(plan, "area.smalltown.center.001")
    _check(not smalltown_site.is_empty(), "small-town site remains available")
    if smalltown_site.is_empty():
        return
    var smalltown_bounds: Rect2i = smalltown_site.get("bounds", Rect2i())

    var smalltown_water: Dictionary = projector.water_constraints_for_bounds(plan, smalltown_bounds)
    _check(bool(smalltown_water.get("ok", false)), "small-town potable-water projection remains valid")
    _check(_projection_has_one_island_wide_water_service(smalltown_water), "small town sees one island-wide municipal water service")

func _all_water_services_are_island_wide(plan: GeneratedGlobalWorldPlan) -> bool:
    if plan.water_services.is_empty():
        return false
    for service: Dictionary in plan.water_services:
        if StringName(service.get("service_mode", &"")) != &"island_wide_municipal":
            return false
        if StringName(service.get("source_type", &"")) != &"treated_municipal":
            return false
        if not bool(service.get("island_wide", false)):
            return false
        if service.has("service_radius") and int(service.get("service_radius", 0)) > 0:
            return false
    return true

func _all_water_services_share_one_facility(plan: GeneratedGlobalWorldPlan) -> bool:
    if plan.water_services.is_empty():
        return false
    var facility_id: String = ""
    for service: Dictionary in plan.water_services:
        var current: String = String(service.get("facility_id", "")).strip_edges()
        if current.is_empty():
            return false
        if facility_id.is_empty():
            facility_id = current
        elif current != facility_id:
            return false
    return not facility_id.is_empty()

func _projection_has_one_island_wide_water_service(result: Dictionary) -> bool:
    var services: Array = result.get("services", [])
    if services.size() != 1 or typeof(services[0]) != TYPE_DICTIONARY:
        return false
    var service: Dictionary = services[0]
    return StringName(service.get("service_mode", &"")) == &"island_wide_municipal" \
        and StringName(service.get("source_type", &"")) == &"treated_municipal" \
        and bool(service.get("island_wide", false))

func _site_by_id(plan: GeneratedGlobalWorldPlan, site_id: String) -> Dictionary:
    for site: Dictionary in plan.area_sites:
        if String(site.get("id", "")) == site_id:
            return site
    return {}

func _area_request_signature(request: AreaGenerationRequest) -> String:
    var parts := PackedStringArray()
    parts.append("area=%s" % request.area_id)
    parts.append("seed=%d" % request.seed)
    parts.append("bounds=%d,%d,%d,%d" % [request.bounds.position.x, request.bounds.position.y, request.bounds.size.x, request.bounds.size.y])
    parts.append("profile=%s" % String(request.area_profile_id))
    parts.append("environment=%s" % String(request.environment_profile_id))
    for road: Dictionary in request.inherited_roads:
        var start: Vector2i = road.get("start", Vector2i.ZERO)
        var finish: Vector2i = road.get("end", Vector2i.ZERO)
        var allowed_parts := PackedStringArray()
        for allowed_value: Variant in road.get("allowed_boundary_cells", []):
            var cell: Vector2i = allowed_value
            allowed_parts.append("%d,%d" % [cell.x, cell.y])
        parts.append("road=%s|%s|%d,%d>%d,%d|w%d|a%s" % [
            String(road.get("road_id", "")),
            String(road.get("road_class", &"")),
            start.x, start.y, finish.x, finish.y,
            int(road.get("width", 0)),
            ";".join(allowed_parts),
        ])
    return "\n".join(parts)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
