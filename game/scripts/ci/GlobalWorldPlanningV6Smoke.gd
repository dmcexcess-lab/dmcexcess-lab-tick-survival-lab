extends SceneTree

const GlobalFixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const GlobalPlannerClass = preload("res://scripts/generation/world/GlobalWorldPlanner.gd")
const GlobalValidatorClass = preload("res://scripts/generation/world/GeneratedGlobalWorldValidator.gd")
const PowerValidatorClass = preload("res://scripts/generation/world/GlobalPowerInfrastructureValidator.gd")
const WaterValidatorClass = preload("res://scripts/generation/world/GlobalWaterInfrastructureValidator.gd")
const WastewaterValidatorClass = preload("res://scripts/generation/world/GlobalWastewaterInfrastructureValidator.gd")
const WastewaterQueryClass = preload("res://scripts/generation/world/GlobalWastewaterInfrastructureQuery.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const LocalFixtureClass = preload("res://scripts/demo/RuralCrossroadsPlanFixture.gd")
const LocalGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var planner: GlobalWorldPlanner = GlobalPlannerClass.new()
    var validator: GeneratedGlobalWorldValidator = GlobalValidatorClass.new()
    var power_validator: GlobalPowerInfrastructureValidator = PowerValidatorClass.new()
    var water_validator: GlobalWaterInfrastructureValidator = WaterValidatorClass.new()
    var wastewater_validator: GlobalWastewaterInfrastructureValidator = WastewaterValidatorClass.new()
    var projector: System20AreaRequestProjector = ProjectorClass.new()
    var request: GlobalWorldGenerationRequest = GlobalFixtureClass.request()
    var plan: GeneratedGlobalWorldPlan = planner.generate(request)

    _test_global_plan(planner, validator, power_validator, water_validator, wastewater_validator, request, plan)
    _test_system20_projection(projector, plan)
    _test_projection_seams(projector, plan)

    if failures.is_empty():
        print("GLOBAL_WORLD_PLANNING_V6_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("GLOBAL_WORLD_PLANNING_V6_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_global_plan(
    planner: GlobalWorldPlanner,
    validator: GeneratedGlobalWorldValidator,
    power_validator: GlobalPowerInfrastructureValidator,
    water_validator: GlobalWaterInfrastructureValidator,
    wastewater_validator: GlobalWastewaterInfrastructureValidator,
    request: GlobalWorldGenerationRequest,
    plan: GeneratedGlobalWorldPlan
) -> void:
    _check(request.is_valid(), "Slice 006 request remains valid")
    _check(plan.is_generated(), "Slice 006 wastewater-aware global plan generates")
    if not plan.is_generated():
        push_error("GLOBAL_WORLD_PLAN_FAILURE_REASON: %s" % plan.failure_reason)
        return

    _check(plan.profile_version == 6, "temperate.rural.region v6 is recorded")
    _check(bool(validator.validate(request, plan).get("ok", false)), "base geography/hydrology/road validation remains green")
    _check(bool(power_validator.validate(request, plan).get("ok", false)), "regional power validation remains green")
    _check(bool(water_validator.validate(request, plan).get("ok", false)), "potable-water validation remains green")
    _check(bool(wastewater_validator.validate(request, plan).get("ok", false)), "Slice 006 wastewater validation passes")

    _check(plan.wastewater_services.size() == 5, "all five settlements have wastewater-service intent")
    _check(_count_wastewater_mode(plan, &"municipal") == 1, "exactly one municipal wastewater service exists")
    _check(_count_wastewater_mode(plan, &"decentralized_septic") == 4, "four rural settlements use decentralized septic")
    _check(_all_rural_septic_records_require_clearance(plan), "all rural septic records require potable-source clearance")
    _check(_count_wastewater_node_kind(plan, &"settlement_collection") == 1, "municipal wastewater has one collection anchor")
    _check(_count_wastewater_node_kind(plan, &"treatment_disposal") == 1, "municipal wastewater has one treatment/disposal anchor")
    _check(plan.wastewater_segments.size() == 1, "municipal wastewater has one collection trunk")
    _check(not _wastewater_overlaps_water(plan), "municipal wastewater trunk does not overlap potable-water trunk")

    var replay: GeneratedGlobalWorldPlan = planner.generate(GlobalFixtureClass.request(GlobalFixtureClass.SEED))
    _check(replay.is_generated() and replay.signature() == plan.signature(), "same seed replays all Slice 001-006 facts identically")

    var alternate_request: GlobalWorldGenerationRequest = GlobalFixtureClass.request(GlobalFixtureClass.SEED + 1)
    var alternate: GeneratedGlobalWorldPlan = planner.generate(alternate_request)
    _check(alternate.is_generated(), "alternate seed still generates a legal Slice 006 world")
    if alternate.is_generated():
        _check(bool(validator.validate(alternate_request, alternate).get("ok", false)), "alternate seed passes base validation")
        _check(bool(power_validator.validate(alternate_request, alternate).get("ok", false)), "alternate seed passes power validation")
        _check(bool(water_validator.validate(alternate_request, alternate).get("ok", false)), "alternate seed passes potable-water validation")
        _check(bool(wastewater_validator.validate(alternate_request, alternate).get("ok", false)), "alternate seed passes wastewater validation")
        _check(not _wastewater_overlaps_water(alternate), "alternate seed wastewater remains separated from potable-water trunk")

func _test_system20_projection(projector: System20AreaRequestProjector, plan: GeneratedGlobalWorldPlan) -> void:
    if not plan.is_generated():
        return
    var projected_result: Dictionary = projector.project_site(plan, GlobalFixtureClass.CENTRAL_SITE_ID)
    _check(bool(projected_result.get("ok", false)), "Candidate 006 still projects from global facts")
    var projected_request: AreaGenerationRequest = projected_result.get("request") as AreaGenerationRequest
    if projected_request == null:
        return
    var baseline_request: AreaGenerationRequest = LocalFixtureClass.request(LocalFixtureClass.SEED)
    _check(_area_request_signature(projected_request) == _area_request_signature(baseline_request), "additional System 20 profiles leave Candidate 006 request unchanged")
    _check(projected_request.inherited_planning_constraints.is_empty(), "Candidate 006 receives no new infrastructure-reservation constraints")

    var local_generator: LocalAreaGenerator = LocalGeneratorClass.new()
    var projected_plan: GeneratedAreaPlan = local_generator.generate(projected_request)
    var baseline_plan: GeneratedAreaPlan = local_generator.generate(baseline_request)
    _check(projected_plan.is_generated(), "Candidate 006 still generates from projected request")
    _check(baseline_plan.is_generated(), "Candidate 006 baseline still generates")
    if projected_plan.is_generated() and baseline_plan.is_generated():
        _check(projected_plan.signature() == baseline_plan.signature(), "additional System 20 profiles leave Candidate 006 semantic output exact")
        _check(projected_plan.area_profile_version == 5, "Candidate 006 remains rural.crossroads v5")
        _check(projected_plan.reservations.is_empty() and projected_plan.blocks.is_empty(), "Candidate 006 gains no infrastructure reservation/block facts")

    var smalltown_result: Dictionary = projector.project_site(plan, "area.smalltown.center.001")
    _check(bool(smalltown_result.get("ok", false)), "small-town global site still projects into System 20")
    var smalltown_request: AreaGenerationRequest = smalltown_result.get("request") as AreaGenerationRequest
    _check(smalltown_request != null and smalltown_request.is_valid(), "projected small-town request remains valid")
    if smalltown_request != null and smalltown_request.is_valid():
        _check(smalltown_request.area_profile_id == &"smalltown.center", "small-town site selects smalltown.center")
        _check(not smalltown_request.inherited_planning_constraints.is_empty(), "small-town request carries normalized regional infrastructure facts")
        var smalltown_plan: GeneratedAreaPlan = local_generator.generate(smalltown_request)
        _check(smalltown_plan.is_generated(), "small-town Candidate 001 still generates from exact v6 global facts")
        if smalltown_plan.is_generated():
            _check(smalltown_plan.area_profile_version == 2, "small-town Candidate 001 records profile v2")
            _check(not smalltown_plan.reservations.is_empty(), "small-town local plan contains infrastructure reservations")
            _check(not smalltown_plan.blocks.is_empty(), "small-town local plan contains semantic town blocks")

    for hamlet_site_id: String in [
        "area.rural.scattered.001",
        "area.rural.scattered.002",
        "area.rural.scattered.003",
    ]:
        var hamlet_result: Dictionary = projector.project_site(plan, hamlet_site_id)
        _check(bool(hamlet_result.get("ok", false)), "%s now projects into System 20" % hamlet_site_id)
        var hamlet_request: AreaGenerationRequest = hamlet_result.get("request") as AreaGenerationRequest
        _check(hamlet_request != null and hamlet_request.is_valid(), "%s projected request is valid" % hamlet_site_id)
        if hamlet_request == null or not hamlet_request.is_valid():
            continue
        _check(hamlet_request.area_profile_id == &"rural.scattered", "%s selects rural.scattered" % hamlet_site_id)
        _check(not hamlet_request.inherited_planning_constraints.is_empty(), "%s consumes regional service/infrastructure facts" % hamlet_site_id)
        var hamlet_plan: GeneratedAreaPlan = local_generator.generate(hamlet_request)
        _check(hamlet_plan.is_generated(), "%s Candidate 001 generates from exact v6 global facts" % hamlet_site_id)
        if hamlet_plan.is_generated():
            _check(hamlet_plan.area_profile_version == 1, "%s records rural.scattered v1" % hamlet_site_id)
            _check(hamlet_plan.blocks.is_empty(), "%s remains block-free sparse rural morphology" % hamlet_site_id)
            _check(hamlet_plan.building_requests.size() == 6, "%s produces six occupied rural properties" % hamlet_site_id)

func _test_projection_seams(projector: System20AreaRequestProjector, plan: GeneratedGlobalWorldPlan) -> void:
    if not plan.is_generated():
        return
    var center_bounds: Rect2i = LocalFixtureClass.BOUNDS
    var hydrology: Dictionary = projector.hydrology_constraints_for_bounds(plan, center_bounds)
    _check(bool(hydrology.get("ok", false)), "Candidate 006 hydrology projection still succeeds")
    _check((hydrology.get("rivers", []) as Array).is_empty(), "Candidate 006 remains river-free")
    _check((hydrology.get("bridges", []) as Array).is_empty(), "Candidate 006 remains bridge-free")

    var power: Dictionary = projector.power_constraints_for_bounds(plan, center_bounds)
    _check(bool(power.get("ok", false)), "Candidate 006 power projection still succeeds")
    _check(not (power.get("segments", []) as Array).is_empty(), "Candidate 006 still exposes regional feeder facts")

    var water: Dictionary = projector.water_constraints_for_bounds(plan, center_bounds)
    _check(bool(water.get("ok", false)), "Candidate 006 potable-water projection still succeeds")
    _check((water.get("services", []) as Array).size() == 1, "Candidate 006 still exposes one potable-water service")
    _check((water.get("nodes", []) as Array).is_empty(), "Candidate 006 still has no municipal water nodes")
    _check((water.get("segments", []) as Array).is_empty(), "Candidate 006 still has no municipal water trunk")

    var wastewater: Dictionary = projector.wastewater_constraints_for_bounds(plan, center_bounds)
    _check(bool(wastewater.get("ok", false)), "Candidate 006 wastewater projection succeeds")
    var center_services: Array = wastewater.get("services", [])
    _check(center_services.size() == 1, "Candidate 006 exposes exactly one wastewater-service intent")
    if center_services.size() == 1 and typeof(center_services[0]) == TYPE_DICTIONARY:
        var center_service: Dictionary = center_services[0]
        _check(String(center_service.get("settlement_id", "")) == "settlement.rural.crossroads.001", "Candidate 006 wastewater intent belongs to crossroads")
        _check(StringName(center_service.get("service_mode", &"")) == &"decentralized_septic", "Candidate 006 wastewater remains decentralized septic")
        _check(StringName(center_service.get("separation_policy", &"")) == &"potable_source_clearance_required", "Candidate 006 septic intent preserves potable-source clearance policy")
    _check((wastewater.get("nodes", []) as Array).is_empty(), "Candidate 006 gets no fake municipal wastewater nodes")
    _check((wastewater.get("segments", []) as Array).is_empty(), "Candidate 006 gets no fake municipal wastewater trunk")

    var smalltown_site: Dictionary = _site_by_id(plan, "area.smalltown.center.001")
    _check(not smalltown_site.is_empty(), "small-town site remains available")
    if smalltown_site.is_empty():
        return
    var smalltown_bounds: Rect2i = smalltown_site.get("bounds", Rect2i())

    var smalltown_water: Dictionary = projector.water_constraints_for_bounds(plan, smalltown_bounds)
    _check(bool(smalltown_water.get("ok", false)), "small-town potable-water projection remains valid")
    _check((smalltown_water.get("services", []) as Array).size() == 1, "small town still exposes one municipal water service")
    _check((smalltown_water.get("nodes", []) as Array).size() == 3, "small town still exposes three potable-water anchors")
    _check((smalltown_water.get("segments", []) as Array).size() == 2, "small town still exposes two potable-water trunk segments")

    var smalltown_wastewater: Dictionary = projector.wastewater_constraints_for_bounds(plan, smalltown_bounds)
    _check(bool(smalltown_wastewater.get("ok", false)), "small-town wastewater projection remains valid")
    var smalltown_services: Array = smalltown_wastewater.get("services", [])
    _check(smalltown_services.size() == 1, "small-town window exposes one wastewater-service record")
    if smalltown_services.size() == 1 and typeof(smalltown_services[0]) == TYPE_DICTIONARY:
        var smalltown_service: Dictionary = smalltown_services[0]
        _check(StringName(smalltown_service.get("service_mode", &"")) == &"municipal", "small-town wastewater service is municipal")
        _check(StringName(smalltown_service.get("disposal_type", &"")) == &"municipal_treatment", "small-town wastewater disposal is municipal treatment")
    _check((smalltown_wastewater.get("nodes", []) as Array).size() == 2, "small-town window exposes two wastewater anchors")
    _check((smalltown_wastewater.get("segments", []) as Array).size() == 1, "small-town window exposes one wastewater trunk")

func _count_wastewater_mode(plan: GeneratedGlobalWorldPlan, mode: StringName) -> int:
    var count: int = 0
    for service: Dictionary in plan.wastewater_services:
        if StringName(service.get("service_mode", &"")) == mode:
            count += 1
    return count

func _count_wastewater_node_kind(plan: GeneratedGlobalWorldPlan, kind: StringName) -> int:
    var count: int = 0
    for node: Dictionary in plan.wastewater_nodes:
        if StringName(node.get("kind", &"")) == kind:
            count += 1
    return count

func _all_rural_septic_records_require_clearance(plan: GeneratedGlobalWorldPlan) -> bool:
    for service: Dictionary in plan.wastewater_services:
        if StringName(service.get("service_mode", &"")) != &"decentralized_septic":
            continue
        if StringName(service.get("separation_policy", &"")) != &"potable_source_clearance_required":
            return false
    return true

func _wastewater_overlaps_water(plan: GeneratedGlobalWorldPlan) -> bool:
    var query: GlobalWastewaterInfrastructureQuery = WastewaterQueryClass.new()
    for wastewater_segment: Dictionary in plan.wastewater_segments:
        for water_segment: Dictionary in plan.water_segments:
            if query.segments_overlap_positive_length(wastewater_segment, water_segment):
                return true
    return false

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