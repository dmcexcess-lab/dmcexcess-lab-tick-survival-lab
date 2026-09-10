extends SceneTree

const FixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const RequestClass = preload("res://scripts/generation/world/GlobalWorldGenerationRequest.gd")
const ProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const IslandPlannerClass = preload("res://scripts/generation/world/IslandWorldPlanner.gd")

const INVALID_CELL := Vector2i(-999999, -999999)

var failures: Array[String] = []

func _initialize() -> void:
    var request := RequestClass.new(
        FixtureClass.WORLD_ID,
        FixtureClass.SEED,
        FixtureClass.BOUNDS,
        ProfilesClass.TEMPERATE_ISLAND_REGION
    )
    var plan: Variant = IslandPlannerClass.new().generate(request)
    _check(plan != null and plan.is_generated(), "procedural island generates for road hierarchy regression")
    if plan != null and plan.is_generated():
        _test_geographic_hierarchy(plan)
        _test_settlement_connectivity(plan)
    _finish()

func _test_geographic_hierarchy(plan: Variant) -> void:
    var routes: Dictionary = _routes(plan)
    var freeway_sides: Dictionary = _expected_freeway_sides(plan.settlements)
    var type_counts: Dictionary = {
        &"four_lane": 0,
        &"two_lane": 0,
        &"gravel": 0,
        &"dirt": 0,
    }
    var gateway_routes: int = 0
    var freeway_gateway_routes: int = 0
    var ordinary_gateway_routes: int = 0
    var paved_settlement_routes: int = 0
    var gravel_rural_routes: int = 0
    var dirt_rural_routes: int = 0

    for road: Dictionary in plan.road_segments:
        var road_type: StringName = StringName(road.get("road_type", &""))
        _check(type_counts.has(road_type), "road uses a supported hierarchy type: %s" % String(road.get("road_id", "")))
        if type_counts.has(road_type):
            type_counts[road_type] = int(type_counts[road_type]) + 1
        _check(_surface_contract_is_valid(road), "road metadata matches its physical hierarchy: %s" % String(road.get("road_id", "")))

    for route_value: Variant in routes.keys():
        var route_id: String = String(route_value)
        var segments: Array = routes[route_value]
        _check(not segments.is_empty(), "route retains physical segments: %s" % route_id)
        if segments.is_empty():
            continue
        _check(_route_is_contiguous(segments), "route remains contiguous after hierarchy styling: %s" % route_id)

        if route_id.begins_with("route.island.gateway."):
            gateway_routes += 1
            var side: StringName = StringName(route_id.substr("route.island.gateway.".length()))
            _check(_all_class(segments, &"primary"), "gateway remains primary: %s" % route_id)
            if freeway_sides.has(side):
                freeway_gateway_routes += 1
                _check(StringName(segments[0].get("road_type", &"")) == &"two_lane", "freeway gateway begins as a two-lane settlement approach: %s" % route_id)
                _check(_contains_type(segments, &"four_lane"), "freeway gateway contains a four-lane trunk: %s" % route_id)
                _check(_single_forward_freeway_transition(segments), "freeway gateway widens once outside the settlement approach: %s" % route_id)
            else:
                ordinary_gateway_routes += 1
                _check(_all_type(segments, &"two_lane"), "perpendicular gateway stays two-lane: %s" % route_id)
            continue

        var road_class: StringName = StringName(segments[0].get("road_class", &""))
        if road_class == &"primary":
            paved_settlement_routes += 1
            _check(_all_type(segments, &"two_lane"), "town/crossroads route is paved two-lane: %s" % route_id)
            _check(_route_has_paved_destination(plan, segments), "primary two-lane route serves a town or crossroads: %s" % route_id)
        elif route_id.begins_with("route.island.loop."):
            dirt_rural_routes += 1
            _check(_all_type(segments, &"dirt"), "alternate rural/local route is dirt: %s" % route_id)
            _check(_route_endpoints_are_rural_hamlets(plan, segments), "dirt route remains rural/farm/home access: %s" % route_id)
        else:
            gravel_rural_routes += 1
            _check(_all_type(segments, &"gravel"), "settlement-tree rural route is gravel: %s" % route_id)
            _check(_route_endpoints_are_rural_hamlets(plan, segments), "gravel secondary route serves rural hamlets: %s" % route_id)

    _check(gateway_routes == 4, "island retains four gateway routes")
    _check(freeway_gateway_routes == 2, "exactly two opposite gateways form the sparse freeway axis")
    _check(ordinary_gateway_routes == 2, "the perpendicular gateway pair remains ordinary two-lane")
    _check(paved_settlement_routes > 0, "reference island retains paved town/crossroads routes")
    _check(gravel_rural_routes > 0, "reference island retains gravel secondary rural routes")
    _check(dirt_rural_routes > 0, "reference island retains dirt rural/local routes")
    _check(int(type_counts[&"four_lane"]) > 0, "four-lane trunk segments exist")
    _check(int(type_counts[&"two_lane"]) > 0, "two-lane paved segments exist")
    _check(int(type_counts[&"gravel"]) > 0, "gravel segments exist")
    _check(int(type_counts[&"dirt"]) > 0, "dirt segments exist")
    _check(int(type_counts[&"gravel"]) < plan.road_segments.size(), "road network never collapses to all gravel")

func _test_settlement_connectivity(plan: Variant) -> void:
    var settlement_centers: Dictionary = {}
    for settlement: Dictionary in plan.settlements:
        var center: Vector2i = settlement.get("center", INVALID_CELL)
        _check(center != INVALID_CELL, "settlement retains a valid center")
        if center != INVALID_CELL:
            settlement_centers[center] = String(settlement.get("id", ""))

    var touched: Dictionary = {}
    for road: Dictionary in plan.road_segments:
        var start: Vector2i = road.get("start", INVALID_CELL)
        var finish: Vector2i = road.get("end", INVALID_CELL)
        if settlement_centers.has(start):
            touched[start] = true
        if settlement_centers.has(finish):
            touched[finish] = true
    _check(touched.size() == settlement_centers.size(), "road hierarchy styling preserves every settlement connection")

func _routes(plan: Variant) -> Dictionary:
    var routes: Dictionary = {}
    for road: Dictionary in plan.road_segments:
        var route_id: String = String(road.get("route_id", ""))
        _check(not route_id.is_empty(), "every island road segment has a route id")
        if route_id.is_empty():
            continue
        var segments: Array = routes.get(route_id, [])
        segments.append(road)
        routes[route_id] = segments
    return routes

func _expected_freeway_sides(settlements: Array[Dictionary]) -> Dictionary:
    var smalltowns: Array[Dictionary] = []
    for settlement: Dictionary in settlements:
        if StringName(settlement.get("kind", &"")) == &"smalltown":
            smalltowns.append(settlement)
    _check(smalltowns.size() >= 2, "reference island retains two small towns")
    if smalltowns.size() < 2:
        return {&"west": true, &"east": true}
    smalltowns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("id", "")) < String(b.get("id", ""))
    )
    var first: Vector2i = smalltowns[0].get("center", INVALID_CELL)
    var second: Vector2i = smalltowns[1].get("center", INVALID_CELL)
    if absi(second.x - first.x) >= absi(second.y - first.y):
        return {&"west": true, &"east": true}
    return {&"north": true, &"south": true}

func _route_is_contiguous(segments: Array) -> bool:
    for index: int in range(segments.size() - 1):
        var finish: Vector2i = segments[index].get("end", INVALID_CELL)
        var next_start: Vector2i = segments[index + 1].get("start", INVALID_CELL)
        if finish != next_start:
            return false
    return true

func _single_forward_freeway_transition(segments: Array) -> bool:
    var entered_freeway: bool = false
    var transition_count: int = 0
    for value: Variant in segments:
        var segment: Dictionary = value
        var road_type: StringName = StringName(segment.get("road_type", &""))
        if road_type == &"four_lane":
            if not entered_freeway:
                entered_freeway = true
                transition_count += 1
            continue
        if road_type != &"two_lane" or entered_freeway:
            return false
    return entered_freeway and transition_count == 1

func _surface_contract_is_valid(road: Dictionary) -> bool:
    var road_type: StringName = StringName(road.get("road_type", &""))
    var lanes: int = int(road.get("lane_count", 0))
    var surface: StringName = StringName(road.get("surface_family", &""))
    var centerline: bool = bool(road.get("paint_centerline", false))
    match road_type:
        &"four_lane":
            return lanes == 4 and surface == &"paved_centerline" and centerline
        &"two_lane":
            return lanes == 2 and surface == &"paved_centerline" and centerline
        &"gravel":
            return lanes == 1 and surface == &"rural_gravel" and not centerline
        &"dirt":
            return lanes == 1 and surface == &"rural_dirt" and not centerline
    return false

func _route_has_paved_destination(plan: Variant, segments: Array) -> bool:
    if segments.is_empty():
        return false
    var endpoints: Array[Vector2i] = [
        segments[0].get("start", INVALID_CELL),
        segments[segments.size() - 1].get("end", INVALID_CELL),
    ]
    for endpoint: Vector2i in endpoints:
        var kind: StringName = _settlement_kind_at(plan, endpoint)
        if kind == &"smalltown" or kind == &"rural_crossroads":
            return true
    return false

func _route_endpoints_are_rural_hamlets(plan: Variant, segments: Array) -> bool:
    if segments.is_empty():
        return false
    var endpoints: Array[Vector2i] = [
        segments[0].get("start", INVALID_CELL),
        segments[segments.size() - 1].get("end", INVALID_CELL),
    ]
    for endpoint: Vector2i in endpoints:
        if _settlement_kind_at(plan, endpoint) != &"rural_hamlet":
            return false
    return true

func _settlement_kind_at(plan: Variant, cell: Vector2i) -> StringName:
    for settlement: Dictionary in plan.settlements:
        if settlement.get("center", INVALID_CELL) == cell:
            return StringName(settlement.get("kind", &""))
    return &""

func _contains_type(segments: Array, expected: StringName) -> bool:
    for value: Variant in segments:
        var segment: Dictionary = value
        if StringName(segment.get("road_type", &"")) == expected:
            return true
    return false

func _all_type(segments: Array, expected: StringName) -> bool:
    for value: Variant in segments:
        var segment: Dictionary = value
        if StringName(segment.get("road_type", &"")) != expected:
            return false
    return true

func _all_class(segments: Array, expected: StringName) -> bool:
    for value: Variant in segments:
        var segment: Dictionary = value
        if StringName(segment.get("road_class", &"")) != expected:
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