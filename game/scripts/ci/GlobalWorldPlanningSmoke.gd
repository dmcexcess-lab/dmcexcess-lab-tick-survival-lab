extends SceneTree

const GlobalFixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const GlobalPlannerClass = preload("res://scripts/generation/world/GlobalWorldPlanner.gd")
const GlobalValidatorClass = preload("res://scripts/generation/world/GeneratedGlobalWorldValidator.gd")
const PowerValidatorClass = preload("res://scripts/generation/world/GlobalPowerInfrastructureValidator.gd")
const PowerQueryClass = preload("res://scripts/generation/world/GlobalPowerInfrastructureQuery.gd")
const WaterValidatorClass = preload("res://scripts/generation/world/GlobalWaterInfrastructureValidator.gd")
const WaterQueryClass = preload("res://scripts/generation/world/GlobalWaterInfrastructureQuery.gd")
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

    _test_global_candidate(planner, validator, power_validator, water_validator, request, plan)
    _test_system20_projection(projector, plan)
    _test_adjacent_road_projection(projector, plan)
    _test_hydrology_projection(projector, plan)
    _test_power_projection(projector, plan)
    _test_water_projection(projector, plan)

    if failures.is_empty():
        print("GLOBAL_WORLD_PLANNING_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("GLOBAL_WORLD_PLANNING_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_global_candidate(
    planner: GlobalWorldPlanner,
    validator: GeneratedGlobalWorldValidator,
    power_validator: GlobalPowerInfrastructureValidator,
    water_validator: GlobalWaterInfrastructureValidator,
    request: GlobalWorldGenerationRequest,
    plan: GeneratedGlobalWorldPlan
) -> void:
    _check(request.is_valid(), "Slice 005 request is valid")
    _check(plan.is_generated(), "Slice 005 water-aware global world plan generates")
    if not plan.is_generated():
        push_error("GLOBAL_WORLD_PLAN_FAILURE_REASON: %s" % plan.failure_reason)
        return

    _check(bool(validator.validate(request, plan).get("ok", false)), "Slices 001-003 still pass independent global validation")
    _check(bool(power_validator.validate(request, plan).get("ok", false)), "Slice 004 still passes independent power validation")
    _check(bool(water_validator.validate(request, plan).get("ok", false)), "Slice 005 passes independent potable-water validation")
    _check(plan.profile_version == 5, "temperate.rural.region v5 is recorded")
    _check(plan.bounds == GlobalFixtureClass.BOUNDS, "global fixture keeps approved bounds")
    _check(plan.geography_cells.size() == 196, "128-cell geography lattice remains 14x14")
    _check(plan.settlements.size() == 5, "regional skeleton still contains five settlements")
    _check(plan.area_sites.size() == 5, "each settlement still exposes one local-area site")
    _check(plan.regions.size() == 6, "broad rural background plus five settlement regions remain")
    _check(not plan.river_segments.is_empty(), "regional river remains present")
    _check(not plan.bridge_intents.is_empty(), "regional bridge intents remain present")
    _check(plan.road_segments.size() > 4, "geography/hydrology-aware road network remains composed")

    _check(_count_power_kind(plan, &"regional_ingress") == 1, "exactly one regional power ingress exists")
    _check(_count_power_kind(plan, &"substation") == 1, "exactly one regional substation exists")
    _check(_count_power_kind(plan, &"settlement_service") == 5, "all five settlements retain power service nodes")
    _check(not plan.power_segments.is_empty(), "regional feeder network contains real segments")
    _check(_all_settlements_have_power_service(plan), "every settlement retains exactly one power service node at its center")
    _check(_power_ingress_is_boundary(plan), "regional power ingress remains on a world boundary gateway")
    _check(_all_power_nodes_reachable(plan), "all power nodes remain reachable from regional ingress")

    _check(plan.water_services.size() == 5, "all five settlements have potable-water service intent")
    _check(_count_water_service_mode(plan, &"municipal") == 1, "exactly one municipal water service exists")
    _check(_count_water_service_mode(plan, &"decentralized_source") == 4, "four rural settlements use decentralized water-source intent")
    _check(_count_water_node_kind(plan, &"groundwater_source") == 1, "municipal network has one groundwater-source anchor")
    _check(_count_water_node_kind(plan, &"treatment_storage") == 1, "municipal network has one treatment/storage anchor")
    _check(_count_water_node_kind(plan, &"settlement_service") == 1, "municipal network has one small-town service anchor")
    _check(plan.water_segments.size() == 2, "municipal backbone contains exactly two trunk segments")
    _check(_water_service_modes_are_correct(plan), "small town is municipal while crossroads/hamlets remain decentralized groundwater")
    _check(_municipal_water_nodes_reachable(plan), "groundwater source reaches treatment/storage and small-town service")

    var replay: GeneratedGlobalWorldPlan = planner.generate(GlobalFixtureClass.request(GlobalFixtureClass.SEED))
    _check(replay.is_generated() and replay.signature() == plan.signature(), "same seed replays geography/hydrology/roads/power/water identically")
    var alternate_request: GlobalWorldGenerationRequest = GlobalFixtureClass.request(GlobalFixtureClass.SEED + 1)
    var alternate: GeneratedGlobalWorldPlan = planner.generate(alternate_request)
    _check(alternate.is_generated(), "alternate global seed still generates legally")
    if alternate.is_generated():
        _check(bool(validator.validate(alternate_request, alternate).get("ok", false)), "alternate seed still passes base global validation")
        _check(bool(power_validator.validate(alternate_request, alternate).get("ok", false)), "alternate seed still passes power validation")
        _check(bool(water_validator.validate(alternate_request, alternate).get("ok", false)), "alternate seed still passes water validation")
        _check(_power_signature(alternate) != _power_signature(plan), "alternate seed still changes legal power infrastructure")

func _test_system20_projection(projector: System20AreaRequestProjector, plan: GeneratedGlobalWorldPlan) -> void:
    if not plan.is_generated():
        return
    var projected_result: Dictionary = projector.project_site(plan, GlobalFixtureClass.CENTRAL_SITE_ID)
    _check(bool(projected_result.get("ok", false)), "central global site still projects into existing System 20 request")
    var projected_request: AreaGenerationRequest = projected_result.get("request") as AreaGenerationRequest
    if projected_request == null:
        return
    var baseline_request: AreaGenerationRequest = LocalFixtureClass.request(LocalFixtureClass.SEED)
    _check(_area_request_signature(projected_request) == _area_request_signature(baseline_request), "Slice 005 leaves Candidate 006 request unchanged")

    var local_generator: LocalAreaGenerator = LocalGeneratorClass.new()
    var projected_plan: GeneratedAreaPlan = local_generator.generate(projected_request)
    var baseline_plan: GeneratedAreaPlan = local_generator.generate(baseline_request)
    _check(projected_plan.is_generated(), "System 20 still generates from global inherited-road facts")
    _check(baseline_plan.is_generated(), "current Candidate 006 baseline still generates")
    if projected_plan.is_generated() and baseline_plan.is_generated():
        _check(projected_plan.signature() == baseline_plan.signature(), "global water planning does not change Candidate 006 semantic output")
        _check(projected_plan.area_profile_version == 5, "Candidate 006 still uses rural.crossroads v5")

    var unsupported_result: Dictionary = projector.project_site(plan, "area.smalltown.center.001")
    _check(not bool(unsupported_result.get("ok", true)), "small-town local profile remains honestly unsupported")
    _check(String(unsupported_result.get("failure_reason", "")) == "system20_area_profile_unsupported", "unsupported small-town projection fails at adapter seam")

func _test_adjacent_road_projection(projector: System20AreaRequestProjector, plan: GeneratedGlobalWorldPlan) -> void:
    if not plan.is_generated():
        return
    var center: Rect2i = LocalFixtureClass.BOUNDS
    var windows: Array[Rect2i] = [
        Rect2i(Vector2i(center.position.x - center.size.x, center.position.y), center.size),
        Rect2i(Vector2i(center.position.x + center.size.x, center.position.y), center.size),
        Rect2i(Vector2i(center.position.x, center.position.y - center.size.y), center.size),
        Rect2i(Vector2i(center.position.x, center.position.y + center.size.y), center.size),
    ]
    for bounds: Rect2i in windows:
        var result: Dictionary = projector.road_constraints_for_bounds(plan, bounds)
        _check(bool(result.get("ok", false)), "adjacent road projection remains valid after Slice 005")
        _check(not (result.get("roads", []) as Array).is_empty(), "adjacent window still receives inherited regional road facts")

func _test_hydrology_projection(projector: System20AreaRequestProjector, plan: GeneratedGlobalWorldPlan) -> void:
    if not plan.is_generated():
        return
    var center: Rect2i = LocalFixtureClass.BOUNDS
    var protected_windows: Array[Rect2i] = [
        center,
        Rect2i(Vector2i(center.position.x - center.size.x, center.position.y), center.size),
        Rect2i(Vector2i(center.position.x + center.size.x, center.position.y), center.size),
        Rect2i(Vector2i(center.position.x, center.position.y - center.size.y), center.size),
        Rect2i(Vector2i(center.position.x, center.position.y + center.size.y), center.size),
    ]
    for bounds: Rect2i in protected_windows:
        var result: Dictionary = projector.hydrology_constraints_for_bounds(plan, bounds)
        _check(bool(result.get("ok", false)), "protected hydrology projection still succeeds")
        _check((result.get("rivers", []) as Array).is_empty(), "protected center/adjacent window remains river-free")
        _check((result.get("bridges", []) as Array).is_empty(), "protected center/adjacent window remains bridge-free")

    if plan.bridge_intents.is_empty():
        return
    var crossing: Vector2i = plan.bridge_intents[0].get("cell", Vector2i.ZERO)
    var outer_window: Rect2i = _window_around_cell(plan.bounds, crossing, Vector2i(256, 256))
    var outer_result: Dictionary = projector.hydrology_constraints_for_bounds(plan, outer_window)
    _check(bool(outer_result.get("ok", false)), "outer bridge hydrology projection still succeeds")
    _check(not (outer_result.get("rivers", []) as Array).is_empty(), "outer bridge window still exposes river facts")
    _check(not (outer_result.get("bridges", []) as Array).is_empty(), "outer bridge window still exposes bridge intent")

func _test_power_projection(projector: System20AreaRequestProjector, plan: GeneratedGlobalWorldPlan) -> void:
    if not plan.is_generated():
        return
    var result: Dictionary = projector.power_constraints_for_bounds(plan, LocalFixtureClass.BOUNDS)
    _check(bool(result.get("ok", false)), "Candidate 006 power projection succeeds read-only")
    _check(not (result.get("segments", []) as Array).is_empty(), "Candidate 006 exposes regional feeder facts")
    var nodes: Array = result.get("nodes", [])
    var found_crossroads_service: bool = false
    for node_value: Variant in nodes:
        if typeof(node_value) != TYPE_DICTIONARY:
            continue
        var node: Dictionary = node_value
        if StringName(node.get("kind", &"")) == &"settlement_service" and String(node.get("settlement_id", "")) == "settlement.rural.crossroads.001":
            found_crossroads_service = true
    _check(found_crossroads_service, "Candidate 006 exposes its global power service node")

func _test_water_projection(projector: System20AreaRequestProjector, plan: GeneratedGlobalWorldPlan) -> void:
    if not plan.is_generated():
        return

    var center_result: Dictionary = projector.water_constraints_for_bounds(plan, LocalFixtureClass.BOUNDS)
    _check(bool(center_result.get("ok", false)), "Candidate 006 water projection succeeds read-only")
    var center_services: Array = center_result.get("services", [])
    _check(center_services.size() == 1, "Candidate 006 exposes exactly its water-service intent")
    if center_services.size() == 1 and typeof(center_services[0]) == TYPE_DICTIONARY:
        var center_service: Dictionary = center_services[0]
        _check(String(center_service.get("settlement_id", "")) == "settlement.rural.crossroads.001", "Candidate 006 water service belongs to crossroads")
        _check(StringName(center_service.get("service_mode", &"")) == &"decentralized_source", "Candidate 006 remains decentralized water service")
        _check(StringName(center_service.get("source_type", &"")) == &"groundwater", "Candidate 006 decentralized source type is groundwater")
    _check((center_result.get("nodes", []) as Array).is_empty(), "Candidate 006 gets no fake municipal water nodes")
    _check((center_result.get("segments", []) as Array).is_empty(), "Candidate 006 gets no fake municipal trunk")

    var smalltown_site: Dictionary = _site_by_id(plan, "area.smalltown.center.001")
    _check(not smalltown_site.is_empty(), "small-town global site remains available for water projection")
    if smalltown_site.is_empty():
        return
    var smalltown_result: Dictionary = projector.water_constraints_for_bounds(plan, smalltown_site.get("bounds", Rect2i()))
    _check(bool(smalltown_result.get("ok", false)), "small-town water projection succeeds before local profile exists")
    var smalltown_services: Array = smalltown_result.get("services", [])
    _check(smalltown_services.size() == 1, "small-town window exposes one municipal service record")
    if smalltown_services.size() == 1 and typeof(smalltown_services[0]) == TYPE_DICTIONARY:
        var smalltown_service: Dictionary = smalltown_services[0]
        _check(StringName(smalltown_service.get("service_mode", &"")) == &"municipal", "small-town water service is municipal")
        _check(StringName(smalltown_service.get("source_type", &"")) == &"groundwater", "small-town municipal source type is groundwater")
    _check((smalltown_result.get("nodes", []) as Array).size() == 3, "small-town window exposes three municipal connection anchors")
    _check((smalltown_result.get("segments", []) as Array).size() == 2, "small-town window exposes two municipal trunk segments")

func _count_power_kind(plan: GeneratedGlobalWorldPlan, kind: StringName) -> int:
    var count: int = 0
    for node: Dictionary in plan.power_nodes:
        if StringName(node.get("kind", &"")) == kind:
            count += 1
    return count

func _all_settlements_have_power_service(plan: GeneratedGlobalWorldPlan) -> bool:
    var counts: Dictionary = {}
    var centers: Dictionary = {}
    for settlement: Dictionary in plan.settlements:
        var settlement_id: String = String(settlement.get("id", ""))
        counts[settlement_id] = 0
        centers[settlement_id] = settlement.get("center", Vector2i.ZERO)
    for node: Dictionary in plan.power_nodes:
        if StringName(node.get("kind", &"")) != &"settlement_service":
            continue
        var settlement_id: String = String(node.get("settlement_id", ""))
        if not counts.has(settlement_id):
            return false
        if node.get("cell", Vector2i(-999999, -999999)) != centers[settlement_id]:
            return false
        counts[settlement_id] = int(counts[settlement_id]) + 1
    for count_value: Variant in counts.values():
        if int(count_value) != 1:
            return false
    return true

func _power_ingress_is_boundary(plan: GeneratedGlobalWorldPlan) -> bool:
    for node: Dictionary in plan.power_nodes:
        if StringName(node.get("kind", &"")) != &"regional_ingress":
            continue
        return _is_boundary_cell(plan.bounds, node.get("cell", Vector2i(-999999, -999999)))
    return false

func _all_power_nodes_reachable(plan: GeneratedGlobalWorldPlan) -> bool:
    var query: GlobalPowerInfrastructureQuery = PowerQueryClass.new()
    var ingress: Dictionary = query.ingress_node(plan.power_nodes)
    if ingress.is_empty():
        return false
    var ingress_cell: Vector2i = ingress.get("cell", Vector2i(-999999, -999999))
    var reachable: Dictionary = query.reachable_nodes_from(ingress_cell, plan.power_segments)
    for node: Dictionary in plan.power_nodes:
        if not reachable.has(node.get("cell", Vector2i(-999999, -999999))):
            return false
    return true

func _count_water_service_mode(plan: GeneratedGlobalWorldPlan, mode: StringName) -> int:
    var count: int = 0
    for service: Dictionary in plan.water_services:
        if StringName(service.get("service_mode", &"")) == mode:
            count += 1
    return count

func _count_water_node_kind(plan: GeneratedGlobalWorldPlan, kind: StringName) -> int:
    var count: int = 0
    for node: Dictionary in plan.water_nodes:
        if StringName(node.get("kind", &"")) == kind:
            count += 1
    return count

func _water_service_modes_are_correct(plan: GeneratedGlobalWorldPlan) -> bool:
    var query: GlobalWaterInfrastructureQuery = WaterQueryClass.new()
    for settlement: Dictionary in plan.settlements:
        var settlement_id: String = String(settlement.get("id", ""))
        var service: Dictionary = query.service_for_settlement(plan.water_services, settlement_id)
        if service.is_empty() or StringName(service.get("source_type", &"")) != &"groundwater":
            return false
        if settlement_id == "settlement.smalltown.001":
            if StringName(service.get("service_mode", &"")) != &"municipal":
                return false
        elif StringName(service.get("service_mode", &"")) != &"decentralized_source":
            return false
    return true

func _municipal_water_nodes_reachable(plan: GeneratedGlobalWorldPlan) -> bool:
    var query: GlobalWaterInfrastructureQuery = WaterQueryClass.new()
    var source: Dictionary = query.node_by_kind(plan.water_nodes, &"groundwater_source")
    var treatment: Dictionary = query.node_by_kind(plan.water_nodes, &"treatment_storage")
    var service: Dictionary = query.node_by_kind(plan.water_nodes, &"settlement_service")
    if source.is_empty() or treatment.is_empty() or service.is_empty():
        return false
    var reachable: Dictionary = query.reachable_nodes_from(source.get("cell", Vector2i(-999999, -999999)), plan.water_segments)
    return reachable.has(treatment.get("cell", Vector2i(-999999, -999999))) \
        and reachable.has(service.get("cell", Vector2i(-999999, -999999)))

func _power_signature(plan: GeneratedGlobalWorldPlan) -> String:
    var parts := PackedStringArray()
    for node: Dictionary in plan.power_nodes:
        var cell: Vector2i = node.get("cell", Vector2i.ZERO)
        parts.append("n:%s:%s:%d,%d:%s" % [String(node.get("id", "")), String(node.get("kind", &"")), cell.x, cell.y, String(node.get("settlement_id", ""))])
    for segment: Dictionary in plan.power_segments:
        var start: Vector2i = segment.get("start", Vector2i.ZERO)
        var finish: Vector2i = segment.get("end", Vector2i.ZERO)
        parts.append("s:%s:%d,%d>%d,%d:%s" % [String(segment.get("id", "")), start.x, start.y, finish.x, finish.y, String(segment.get("source_road_id", ""))])
    return "|".join(parts)

func _site_by_id(plan: GeneratedGlobalWorldPlan, site_id: String) -> Dictionary:
    for site: Dictionary in plan.area_sites:
        if String(site.get("id", "")) == site_id:
            return site
    return {}

func _window_around_cell(world_bounds: Rect2i, cell: Vector2i, size: Vector2i) -> Rect2i:
    var x: int = cell.x - size.x / 2
    var y: int = cell.y - size.y / 2
    x = clampi(x, world_bounds.position.x, world_bounds.position.x + world_bounds.size.x - size.x)
    y = clampi(y, world_bounds.position.y, world_bounds.position.y + world_bounds.size.y - size.y)
    return Rect2i(Vector2i(x, y), size)

func _is_boundary_cell(rect: Rect2i, cell: Vector2i) -> bool:
    if not rect.has_point(cell):
        return false
    var max_x: int = rect.position.x + rect.size.x - 1
    var max_y: int = rect.position.y + rect.size.y - 1
    return cell.x == rect.position.x or cell.x == max_x or cell.y == rect.position.y or cell.y == max_y

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
