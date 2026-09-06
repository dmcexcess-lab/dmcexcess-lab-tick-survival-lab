extends SceneTree

const FixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const RequestClass = preload("res://scripts/generation/world/GlobalWorldGenerationRequest.gd")
const ProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const IslandPlannerClass = preload("res://scripts/generation/world/IslandWorldPlanner.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var request := RequestClass.new(
        FixtureClass.WORLD_ID,
        FixtureClass.SEED,
        FixtureClass.BOUNDS,
        ProfilesClass.TEMPERATE_ISLAND_REGION
    )
    var plan: GeneratedGlobalWorldPlan = IslandPlannerClass.new().generate(request)
    _check(plan != null and plan.is_generated(), "procedural island generates for road hierarchy regression")
    if plan != null and plan.is_generated():
        _test_destination_based_hierarchy(plan)
    _finish()

func _test_destination_based_hierarchy(plan: GeneratedGlobalWorldPlan) -> void:
    var routes: Dictionary = {}
    for road: Dictionary in plan.road_segments:
        var route_id: String = String(road.get("route_id", ""))
        _check(not route_id.is_empty(), "every island road segment has a route id")
        if route_id.is_empty():
            continue
        var route_segments: Array = routes.get(route_id, [])
        route_segments.append(road)
        routes[route_id] = route_segments

    var gateway_routes: int = 0
    var paved_settlement_routes: int = 0
    var rural_settlement_routes: int = 0
    var alternate_routes: int = 0

    for route_value: Variant in routes.keys():
        var route_id: String = String(route_value)
        var segments: Array = routes[route_value]
        _check(not segments.is_empty(), "route retains physical segments: %s" % route_id)
        if segments.is_empty():
            continue
        var road_type: StringName = StringName((segments[0] as Dictionary).get("road_type", &""))
        var road_class: StringName = StringName((segments[0] as Dictionary).get("road_class", &""))
        _check(_route_metadata_is_consistent(segments, road_type, road_class), "route metadata is consistent: %s" % route_id)

        if route_id.begins_with("route.island.gateway."):
            gateway_routes += 1
            _check(road_class == &"primary", "gateway remains primary: %s" % route_id)
            _check(road_type == &"four_lane", "gateway remains four-lane: %s" % route_id)
            _check(_all_segments_match_surface(segments, 4, &"paved_centerline", true), "gateway retains four-lane paved material contract: %s" % route_id)
            continue

        var endpoints: Array[Vector2i] = _route_endpoint_cells(segments)
        _check(endpoints.size() == 2, "settlement route has exactly two physical endpoints: %s" % route_id)
        if endpoints.size() != 2:
            continue

        var endpoint_kinds: Array[StringName] = []
        for endpoint: Vector2i in endpoints:
            var kind: StringName = _settlement_kind_at(plan, endpoint)
            if kind != &"":
                endpoint_kinds.append(kind)
        _check(endpoint_kinds.size() == 2, "non-gateway route terminates at two settlements: %s" % route_id)
        if endpoint_kinds.size() != 2:
            continue

        var requires_pavement: bool = _requires_paved_access(endpoint_kinds[0]) or _requires_paved_access(endpoint_kinds[1])
        if requires_pavement:
            paved_settlement_routes += 1
            _check(road_class == &"primary", "town/crossroads route is primary: %s" % route_id)
            _check(road_type == &"two_lane", "town/crossroads route is paved two-lane: %s" % route_id)
            _check(_all_segments_match_surface(segments, 2, &"paved_centerline", true), "town/crossroads route retains paved material contract: %s" % route_id)
        else:
            rural_settlement_routes += 1
            _check(road_class == &"secondary", "rural-to-rural route is secondary: %s" % route_id)
            _check(road_type == &"gravel" or road_type == &"dirt", "only rural-to-rural route may be unpaved: %s" % route_id)
            var expected_surface: StringName = &"rural_dirt" if road_type == &"dirt" else &"rural_gravel"
            _check(_all_segments_match_surface(segments, 1, expected_surface, false), "rural-to-rural route retains one-lane unpaved contract: %s" % route_id)

        if route_id.begins_with("route.island.loop."):
            alternate_routes += 1

    _check(gateway_routes == 4, "island retains four four-lane gateway routes")
    _check(paved_settlement_routes > 0, "reference island has destination-driven paved settlement routes")
    _check(rural_settlement_routes > 0, "reference island retains rural-to-rural gravel/dirt routes")
    _check(alternate_routes > 0, "alternate settlement links participate in endpoint-based classification")

func _route_endpoint_cells(segments: Array) -> Array[Vector2i]:
    var degree: Dictionary = {}
    for value: Variant in segments:
        var segment: Dictionary = value
        var start: Vector2i = segment.get("start", Vector2i(-999999, -999999))
        var finish: Vector2i = segment.get("end", Vector2i(-999999, -999999))
        degree[start] = int(degree.get(start, 0)) + 1
        degree[finish] = int(degree.get(finish, 0)) + 1
    var endpoints: Array[Vector2i] = []
    for cell_value: Variant in degree.keys():
        var cell: Vector2i = cell_value
        if int(degree[cell]) == 1:
            endpoints.append(cell)
    return endpoints

func _settlement_kind_at(plan: GeneratedGlobalWorldPlan, cell: Vector2i) -> StringName:
    for settlement: Dictionary in plan.settlements:
        if settlement.get("center", Vector2i(-999999, -999999)) == cell:
            return StringName(settlement.get("kind", &""))
    return &""

func _requires_paved_access(kind: StringName) -> bool:
    return kind == &"smalltown" or kind == &"rural_crossroads"

func _route_metadata_is_consistent(segments: Array, road_type: StringName, road_class: StringName) -> bool:
    for value: Variant in segments:
        var segment: Dictionary = value
        if StringName(segment.get("road_type", &"")) != road_type:
            return false
        if StringName(segment.get("road_class", &"")) != road_class:
            return false
    return true

func _all_segments_match_surface(segments: Array, lane_count: int, surface_family: StringName, paint_centerline: bool) -> bool:
    for value: Variant in segments:
        var segment: Dictionary = value
        if int(segment.get("lane_count", 0)) != lane_count:
            return false
        if StringName(segment.get("surface_family", &"")) != surface_family:
            return false
        if bool(segment.get("paint_centerline", false)) != paint_centerline:
            return false
    return true

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    failures.append(message)
    push_error("ISLAND_ROAD_HIERARCHY_SMOKE_FAIL: %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("ISLAND_ROAD_HIERARCHY_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("ISLAND_ROAD_HIERARCHY_SMOKE_FAIL: %s" % failure)
    quit(1)
