extends SceneTree

const GlobalFixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const GlobalPlannerClass = preload("res://scripts/generation/world/GlobalWorldPlanner.gd")
const GlobalValidatorClass = preload("res://scripts/generation/world/GeneratedGlobalWorldValidator.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const LocalFixtureClass = preload("res://scripts/demo/RuralCrossroadsPlanFixture.gd")
const LocalGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var planner: GlobalWorldPlanner = GlobalPlannerClass.new()
    var validator: GeneratedGlobalWorldValidator = GlobalValidatorClass.new()
    var projector: System20AreaRequestProjector = ProjectorClass.new()
    var request: GlobalWorldGenerationRequest = GlobalFixtureClass.request()
    var plan: GeneratedGlobalWorldPlan = planner.generate(request)

    _test_global_candidate(planner, validator, request, plan)
    _test_system20_projection(projector, plan)
    _test_adjacent_road_projection(projector, plan)

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
    request: GlobalWorldGenerationRequest,
    plan: GeneratedGlobalWorldPlan
) -> void:
    _check(request.is_valid(), "Slice 001 request is valid")
    _check(plan.is_generated(), "Slice 001 global world plan generates")
    if not plan.is_generated():
        return
    _check(bool(validator.validate(request, plan).get("ok", false)), "Slice 001 passes independent global validation")
    _check(plan.profile_version == 1, "temperate.rural.region v1 is recorded")
    _check(plan.bounds == GlobalFixtureClass.BOUNDS, "global fixture keeps approved bounds")
    _check(plan.settlements.size() == 5, "regional skeleton contains five settlement anchors")
    _check(_count_settlement_kind(plan, &"rural_crossroads") == 1, "regional skeleton contains one central rural crossroads")
    _check(_count_settlement_kind(plan, &"smalltown") == 1, "regional skeleton contains one small-town anchor")
    _check(_count_settlement_kind(plan, &"rural_hamlet") == 3, "regional skeleton contains three rural hamlets")
    _check(plan.road_segments.size() == 4, "regional skeleton contains two regional corridors plus two settlement branches")
    _check(_count_road_class(plan, &"primary") == 1, "regional skeleton contains one primary road segment")
    _check(_count_road_class(plan, &"secondary") == 3, "regional skeleton contains three secondary road segments")
    _check(plan.regions.size() == 6, "broad rural background plus five settlement influence regions are recorded")
    _check(plan.area_sites.size() == 5, "each settlement exposes a future local-area site")

    var central_site: Dictionary = _site_by_id(plan, GlobalFixtureClass.CENTRAL_SITE_ID)
    _check(not central_site.is_empty(), "central accepted rural crossroads is a global area site")
    if not central_site.is_empty():
        _check(central_site.get("bounds", Rect2i()) == LocalFixtureClass.BOUNDS, "central global site exactly preserves Candidate 005 bounds")
        _check(int(central_site.get("seed", -1)) == LocalFixtureClass.SEED, "central global site exactly preserves Candidate 005 seed")
        _check(StringName(central_site.get("area_profile_hint", &"")) == &"rural.crossroads", "central site selects the existing rural.crossroads local profile")
        _check(StringName(central_site.get("environment_profile_hint", &"")) == &"temperate.rural", "central site selects the existing temperate.rural environment profile")

    var replay: GeneratedGlobalWorldPlan = planner.generate(GlobalFixtureClass.request(GlobalFixtureClass.SEED))
    _check(replay.is_generated() and replay.signature() == plan.signature(), "same global request and seed replay identically")
    var alternate: GeneratedGlobalWorldPlan = planner.generate(GlobalFixtureClass.request(GlobalFixtureClass.SEED + 1))
    _check(alternate.is_generated(), "alternate global seed still generates")
    if alternate.is_generated():
        _check(alternate.signature() != plan.signature(), "different global seed changes legal non-central regional geometry")
        var alternate_central: Dictionary = _site_by_id(alternate, GlobalFixtureClass.CENTRAL_SITE_ID)
        _check(alternate_central.get("bounds", Rect2i()) == LocalFixtureClass.BOUNDS, "seed variation does not move the central integration anchor bounds")

func _test_system20_projection(projector: System20AreaRequestProjector, plan: GeneratedGlobalWorldPlan) -> void:
    if not plan.is_generated():
        return
    var projected_result: Dictionary = projector.project_site(plan, GlobalFixtureClass.CENTRAL_SITE_ID)
    _check(bool(projected_result.get("ok", false)), "central global site projects into the existing System 20 request contract")
    var projected_request: AreaGenerationRequest = projected_result.get("request") as AreaGenerationRequest
    if projected_request == null:
        return
    var baseline_request: AreaGenerationRequest = LocalFixtureClass.request(LocalFixtureClass.SEED)
    _check(_area_request_signature(projected_request) == _area_request_signature(baseline_request), "global projection is semantically identical to the accepted Candidate 005 request")

    var local_generator: LocalAreaGenerator = LocalGeneratorClass.new()
    var projected_plan: GeneratedAreaPlan = local_generator.generate(projected_request)
    var baseline_plan: GeneratedAreaPlan = local_generator.generate(baseline_request)
    _check(projected_plan.is_generated(), "System 20 generates from global inherited-road facts")
    _check(baseline_plan.is_generated(), "accepted Candidate 005 baseline still generates")
    if projected_plan.is_generated() and baseline_plan.is_generated():
        _check(projected_plan.signature() == baseline_plan.signature(), "global planning preserves the exact accepted Candidate 005 semantic output")

    var unsupported_result: Dictionary = projector.project_site(plan, "area.smalltown.center.001")
    _check(not bool(unsupported_result.get("ok", true)), "future small-town site does not fabricate an unsupported System 20 profile")
    _check(String(unsupported_result.get("failure_reason", "")) == "system20_area_profile_unsupported", "unsupported local profile fails honestly at the adapter seam")

func _test_adjacent_road_projection(projector: System20AreaRequestProjector, plan: GeneratedGlobalWorldPlan) -> void:
    if not plan.is_generated():
        return
    var center_bounds: Rect2i = LocalFixtureClass.BOUNDS
    var west_bounds := Rect2i(center_bounds.position.x - center_bounds.size.x, center_bounds.position.y, center_bounds.size.x, center_bounds.size.y)
    var east_bounds := Rect2i(center_bounds.position.x + center_bounds.size.x, center_bounds.position.y, center_bounds.size.x, center_bounds.size.y)
    var north_bounds := Rect2i(center_bounds.position.x, center_bounds.position.y - center_bounds.size.y, center_bounds.size.x, center_bounds.size.y)
    var south_bounds := Rect2i(center_bounds.position.x, center_bounds.position.y + center_bounds.size.y, center_bounds.size.x, center_bounds.size.y)

    var center_result: Dictionary = projector.road_constraints_for_bounds(plan, center_bounds)
    var west_result: Dictionary = projector.road_constraints_for_bounds(plan, west_bounds)
    var east_result: Dictionary = projector.road_constraints_for_bounds(plan, east_bounds)
    var north_result: Dictionary = projector.road_constraints_for_bounds(plan, north_bounds)
    var south_result: Dictionary = projector.road_constraints_for_bounds(plan, south_bounds)
    _check(bool(center_result.get("ok", false)), "central arbitrary road projection succeeds")
    _check(bool(west_result.get("ok", false)) and bool(east_result.get("ok", false)), "east/west adjacent road projections succeed")
    _check(bool(north_result.get("ok", false)) and bool(south_result.get("ok", false)), "north/south adjacent road projections succeed")
    if not bool(center_result.get("ok", false)) or not bool(west_result.get("ok", false)) or not bool(east_result.get("ok", false)) or not bool(north_result.get("ok", false)) or not bool(south_result.get("ok", false)):
        return

    var center_primary: Dictionary = _road_by_id(center_result.get("roads", []), LocalFixtureClass.PRIMARY_ROAD_ID)
    var west_primary: Dictionary = _road_by_id(west_result.get("roads", []), LocalFixtureClass.PRIMARY_ROAD_ID)
    var east_primary: Dictionary = _road_by_id(east_result.get("roads", []), LocalFixtureClass.PRIMARY_ROAD_ID)
    var center_secondary: Dictionary = _road_by_id(center_result.get("roads", []), LocalFixtureClass.SECONDARY_ROAD_ID)
    var north_secondary: Dictionary = _road_by_id(north_result.get("roads", []), LocalFixtureClass.SECONDARY_ROAD_ID)
    var south_secondary: Dictionary = _road_by_id(south_result.get("roads", []), LocalFixtureClass.SECONDARY_ROAD_ID)

    _check(not center_primary.is_empty() and not west_primary.is_empty() and not east_primary.is_empty(), "same global primary road is visible in three adjacent windows")
    _check(not center_secondary.is_empty() and not north_secondary.is_empty() and not south_secondary.is_empty(), "same global secondary road is visible in three adjacent windows")
    if not center_primary.is_empty() and not west_primary.is_empty():
        var west_end: Vector2i = west_primary.get("end", Vector2i.ZERO)
        var center_start: Vector2i = center_primary.get("start", Vector2i.ZERO)
        _check(west_end + Vector2i(1, 0) == center_start, "west and center windows preserve adjacent cells on one continuous primary road")
    if not center_primary.is_empty() and not east_primary.is_empty():
        var center_end: Vector2i = center_primary.get("end", Vector2i.ZERO)
        var east_start: Vector2i = east_primary.get("start", Vector2i.ZERO)
        _check(center_end + Vector2i(1, 0) == east_start, "center and east windows preserve adjacent cells on one continuous primary road")
    if not center_secondary.is_empty() and not north_secondary.is_empty():
        var north_end: Vector2i = north_secondary.get("end", Vector2i.ZERO)
        var center_start: Vector2i = center_secondary.get("start", Vector2i.ZERO)
        _check(north_end + Vector2i(0, 1) == center_start, "north and center windows preserve adjacent cells on one continuous secondary road")
    if not center_secondary.is_empty() and not south_secondary.is_empty():
        var center_end: Vector2i = center_secondary.get("end", Vector2i.ZERO)
        var south_start: Vector2i = south_secondary.get("start", Vector2i.ZERO)
        _check(center_end + Vector2i(0, 1) == south_start, "center and south windows preserve adjacent cells on one continuous secondary road")

func _count_settlement_kind(plan: GeneratedGlobalWorldPlan, kind: StringName) -> int:
    var count: int = 0
    for settlement: Dictionary in plan.settlements:
        if StringName(settlement.get("kind", &"")) == kind:
            count += 1
    return count

func _count_road_class(plan: GeneratedGlobalWorldPlan, road_class: StringName) -> int:
    var count: int = 0
    for road: Dictionary in plan.road_segments:
        if StringName(road.get("road_class", &"")) == road_class:
            count += 1
    return count

func _site_by_id(plan: GeneratedGlobalWorldPlan, site_id: String) -> Dictionary:
    for site: Dictionary in plan.area_sites:
        if String(site.get("id", "")) == site_id:
            return site
    return {}

func _road_by_id(road_values: Variant, road_id: String) -> Dictionary:
    if typeof(road_values) != TYPE_ARRAY:
        return {}
    for value: Variant in road_values:
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var road: Dictionary = value
        if String(road.get("road_id", "")) == road_id:
            return road
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
