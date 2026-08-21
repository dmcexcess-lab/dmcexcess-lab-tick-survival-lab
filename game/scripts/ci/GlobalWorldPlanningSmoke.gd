extends SceneTree

const GlobalFixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const GlobalPlannerClass = preload("res://scripts/generation/world/GlobalWorldPlanner.gd")
const GlobalValidatorClass = preload("res://scripts/generation/world/GeneratedGlobalWorldValidator.gd")
const GeographyQueryClass = preload("res://scripts/generation/world/GlobalGeographyQuery.gd")
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
    _check(request.is_valid(), "Slice 002 request is valid")
    _check(plan.is_generated(), "Slice 002 geography-aware global world plan generates")
    if not plan.is_generated():
        return

    _check(bool(validator.validate(request, plan).get("ok", false)), "Slice 002 passes independent global validation")
    _check(plan.profile_version == 2, "temperate.rural.region v2 is recorded")
    _check(plan.bounds == GlobalFixtureClass.BOUNDS, "global fixture keeps approved bounds")
    _check(plan.geography_cells.size() == 196, "128-cell geography lattice tiles the 1792x1792 fixture with 14x14 cells")
    _check(_geography_area(plan) == plan.bounds.size.x * plan.bounds.size.y, "coarse geography covers every global planning cell exactly by area")
    _check(_landform_class_count(plan) >= 3, "regional geography contains multiple meaningful landform classes")
    _check(_count_landform(plan, &"ridge") > 0, "regional geography includes real ridge constraints")
    _check(_all_settlements_use_legal_landform(plan), "all settlement anchors occupy lowland or rolling geography")
    _check(_no_major_road_crosses_ridge(plan), "major roads route around ridge geography")
    _check(_at_least_one_route_bends(plan), "canonical outer road topology bends through geography rather than remaining only straight axes")

    _check(plan.settlements.size() == 5, "regional skeleton still contains five settlement anchors")
    _check(_count_settlement_kind(plan, &"rural_crossroads") == 1, "regional skeleton contains one central rural crossroads")
    _check(_count_settlement_kind(plan, &"smalltown") == 1, "regional skeleton contains one small-town anchor")
    _check(_count_settlement_kind(plan, &"rural_hamlet") == 3, "regional skeleton contains three rural hamlets")
    _check(plan.road_segments.size() > 4, "geography-aware routes may compose multiple cardinal segments")
    _check(_count_road_class(plan, &"primary") >= 3, "primary route spans the protected center and outer geography")
    _check(_count_road_class(plan, &"secondary") >= 5, "secondary network connects gateways and rural settlements")
    _check(plan.regions.size() == 6, "broad rural background plus five settlement influence regions remain recorded")
    _check(plan.area_sites.size() == 5, "each settlement still exposes a future local-area site")

    var central_site: Dictionary = _site_by_id(plan, GlobalFixtureClass.CENTRAL_SITE_ID)
    _check(not central_site.is_empty(), "central accepted rural crossroads remains a global area site")
    if not central_site.is_empty():
        _check(central_site.get("bounds", Rect2i()) == LocalFixtureClass.BOUNDS, "central global site exactly preserves accepted local bounds")
        _check(int(central_site.get("seed", -1)) == LocalFixtureClass.SEED, "central global site exactly preserves accepted local seed")
        _check(StringName(central_site.get("area_profile_hint", &"")) == &"rural.crossroads", "central site selects rural.crossroads")
        _check(StringName(central_site.get("environment_profile_hint", &"")) == &"temperate.rural", "central site selects temperate.rural")

    var central_primary: Dictionary = _road_by_id(plan.road_segments, LocalFixtureClass.PRIMARY_ROAD_ID)
    var central_secondary: Dictionary = _road_by_id(plan.road_segments, LocalFixtureClass.SECONDARY_ROAD_ID)
    _check(not central_primary.is_empty() and not central_secondary.is_empty(), "protected central primary and secondary segment IDs remain stable")
    if not central_primary.is_empty():
        _check(int(central_primary.get("width", 0)) == 5, "protected primary keeps five-cell width")
        _check(_segment_covers_rect_axis(central_primary, LocalFixtureClass.BOUNDS, &"horizontal"), "protected primary spans the complete accepted local window")
    if not central_secondary.is_empty():
        _check(int(central_secondary.get("width", 0)) == 3, "protected secondary keeps three-cell width")
        _check(_segment_covers_rect_axis(central_secondary, LocalFixtureClass.BOUNDS, &"vertical"), "protected secondary spans the complete accepted local window")

    var replay: GeneratedGlobalWorldPlan = planner.generate(GlobalFixtureClass.request(GlobalFixtureClass.SEED))
    _check(replay.is_generated() and replay.signature() == plan.signature(), "same global request and seed replay geography/settlements/routes identically")
    var alternate: GeneratedGlobalWorldPlan = planner.generate(GlobalFixtureClass.request(GlobalFixtureClass.SEED + 1))
    _check(alternate.is_generated(), "alternate global seed still generates legally")
    if alternate.is_generated():
        _check(_geography_signature(alternate) != _geography_signature(plan), "different global seed changes geography outside the protected anchor")
        var alternate_central: Dictionary = _site_by_id(alternate, GlobalFixtureClass.CENTRAL_SITE_ID)
        _check(alternate_central.get("bounds", Rect2i()) == LocalFixtureClass.BOUNDS, "seed variation does not move protected central integration bounds")
        _check(_all_settlements_use_legal_landform(alternate), "alternate seed still places settlements on legal geography")
        _check(_no_major_road_crosses_ridge(alternate), "alternate seed roads still avoid ridges")

func _test_system20_projection(projector: System20AreaRequestProjector, plan: GeneratedGlobalWorldPlan) -> void:
    if not plan.is_generated():
        return
    var projected_result: Dictionary = projector.project_site(plan, GlobalFixtureClass.CENTRAL_SITE_ID)
    _check(bool(projected_result.get("ok", false)), "central global site projects into the existing System 20 request contract")
    var projected_request: AreaGenerationRequest = projected_result.get("request") as AreaGenerationRequest
    if projected_request == null:
        return
    var baseline_request: AreaGenerationRequest = LocalFixtureClass.request(LocalFixtureClass.SEED)
    _check(_area_request_signature(projected_request) == _area_request_signature(baseline_request), "geography-aware global projection remains semantically identical to the accepted local request")

    var local_generator: LocalAreaGenerator = LocalGeneratorClass.new()
    var projected_plan: GeneratedAreaPlan = local_generator.generate(projected_request)
    var baseline_plan: GeneratedAreaPlan = local_generator.generate(baseline_request)
    _check(projected_plan.is_generated(), "System 20 generates from geography-aware global inherited-road facts")
    _check(baseline_plan.is_generated(), "current rural-crossroads baseline still generates")
    if projected_plan.is_generated() and baseline_plan.is_generated():
        _check(projected_plan.signature() == baseline_plan.signature(), "global geography preserves exact current local semantic output")
        _check(projected_plan.area_profile_version == 5, "projected local area uses current rural.crossroads v5")

    var unsupported_result: Dictionary = projector.project_site(plan, "area.smalltown.center.001")
    _check(not bool(unsupported_result.get("ok", true)), "future small-town site does not fabricate an unsupported System 20 profile")
    _check(String(unsupported_result.get("failure_reason", "")) == "system20_area_profile_unsupported", "unsupported local profile fails honestly at adapter seam")

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

    _check(not center_primary.is_empty() and not west_primary.is_empty() and not east_primary.is_empty(), "same protected primary road is visible in three adjacent windows")
    _check(not center_secondary.is_empty() and not north_secondary.is_empty() and not south_secondary.is_empty(), "same protected secondary road is visible in three adjacent windows")
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

func _geography_area(plan: GeneratedGlobalWorldPlan) -> int:
    var total: int = 0
    for geography: Dictionary in plan.geography_cells:
        var rect: Rect2i = geography.get("rect", Rect2i())
        total += rect.size.x * rect.size.y
    return total

func _landform_class_count(plan: GeneratedGlobalWorldPlan) -> int:
    var kinds: Dictionary = {}
    for geography: Dictionary in plan.geography_cells:
        kinds[StringName(geography.get("landform", &""))] = true
    return kinds.size()

func _count_landform(plan: GeneratedGlobalWorldPlan, landform: StringName) -> int:
    var count: int = 0
    for geography: Dictionary in plan.geography_cells:
        if StringName(geography.get("landform", &"")) == landform:
            count += 1
    return count

func _all_settlements_use_legal_landform(plan: GeneratedGlobalWorldPlan) -> bool:
    var query: GlobalGeographyQuery = GeographyQueryClass.new()
    for settlement: Dictionary in plan.settlements:
        var center: Vector2i = settlement.get("center", Vector2i(-999999, -999999))
        if not query.settlement_allowed(center, plan.geography_cells):
            return false
    return true

func _no_major_road_crosses_ridge(plan: GeneratedGlobalWorldPlan) -> bool:
    for road: Dictionary in plan.road_segments:
        var start: Vector2i = road.get("start", Vector2i.ZERO)
        var finish: Vector2i = road.get("end", Vector2i.ZERO)
        for geography: Dictionary in plan.geography_cells:
            if StringName(geography.get("landform", &"")) != &"ridge":
                continue
            var rect: Rect2i = geography.get("rect", Rect2i())
            var max_x: int = rect.position.x + rect.size.x - 1
            var max_y: int = rect.position.y + rect.size.y - 1
            if start.y == finish.y:
                if start.y >= rect.position.y and start.y <= max_y and _ranges_overlap(mini(start.x, finish.x), maxi(start.x, finish.x), rect.position.x, max_x):
                    return false
            elif start.x == finish.x:
                if start.x >= rect.position.x and start.x <= max_x and _ranges_overlap(mini(start.y, finish.y), maxi(start.y, finish.y), rect.position.y, max_y):
                    return false
    return true

func _at_least_one_route_bends(plan: GeneratedGlobalWorldPlan) -> bool:
    var axes_by_route: Dictionary = {}
    for road: Dictionary in plan.road_segments:
        var route_id: String = String(road.get("route_id", ""))
        if not axes_by_route.has(route_id):
            axes_by_route[route_id] = {"horizontal": false, "vertical": false}
        var axes: Dictionary = axes_by_route[route_id]
        var start: Vector2i = road.get("start", Vector2i.ZERO)
        var finish: Vector2i = road.get("end", Vector2i.ZERO)
        if start.y == finish.y:
            axes["horizontal"] = true
        if start.x == finish.x:
            axes["vertical"] = true
        axes_by_route[route_id] = axes
    for value: Variant in axes_by_route.values():
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var axes: Dictionary = value
        if bool(axes.get("horizontal", false)) and bool(axes.get("vertical", false)):
            return true
    return false

func _segment_covers_rect_axis(road: Dictionary, rect: Rect2i, axis: StringName) -> bool:
    var start: Vector2i = road.get("start", Vector2i.ZERO)
    var finish: Vector2i = road.get("end", Vector2i.ZERO)
    var max_x: int = rect.position.x + rect.size.x - 1
    var max_y: int = rect.position.y + rect.size.y - 1
    if axis == &"horizontal":
        return start.y == finish.y and start.y >= rect.position.y and start.y <= max_y \
            and mini(start.x, finish.x) <= rect.position.x and maxi(start.x, finish.x) >= max_x
    return start.x == finish.x and start.x >= rect.position.x and start.x <= max_x \
        and mini(start.y, finish.y) <= rect.position.y and maxi(start.y, finish.y) >= max_y

func _geography_signature(plan: GeneratedGlobalWorldPlan) -> String:
    var parts := PackedStringArray()
    for geography: Dictionary in plan.geography_cells:
        var grid: Vector2i = geography.get("grid", Vector2i.ZERO)
        parts.append("%d,%d:%d:%s" % [
            grid.x,
            grid.y,
            int(geography.get("elevation", 0)),
            String(geography.get("landform", &"")),
        ])
    return "|".join(parts)

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

func _ranges_overlap(a_min: int, a_max: int, b_min: int, b_max: int) -> bool:
    return a_min <= b_max and b_min <= a_max

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
