extends "res://scripts/generation/world/GlobalMajorRoadPlanner.gd"
class_name IslandMajorRoadNetworkPlanner

const INVALID_CELL := Vector2i(-999999, -999999)

func plan(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    settlements: Array[Dictionary],
    geography_cells: Array[Dictionary]
) -> Dictionary:
    var road_segments: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty() or settlements.is_empty() or geography_cells.is_empty():
        return {"ok": false, "failure_reason": "invalid_island_major_road_planner_input", "road_segments": road_segments}

    var primary_width: int = int(profile.get("primary_width", 5))
    var secondary_width: int = int(profile.get("secondary_width", 3))
    var arterials: Array[Dictionary] = []
    var arterial_result := _build_cross_island_arterials(request, profile, geography_cells, primary_width)
    if not bool(arterial_result.get("ok", false)):
        return {"ok": false, "failure_reason": String(arterial_result.get("failure_reason", "island_arterial_network_failed")), "road_segments": []}
    for value: Variant in arterial_result.get("roads", []):
        if typeof(value) == TYPE_DICTIONARY:
            arterials.append(value)
            road_segments.append(value)

    # Settlements attach to the transportation backbone instead of defining it.
    # Developed places receive paved two-lane access; rural hamlets receive gravel.
    var access_ordinal: int = 1
    for settlement: Dictionary in settlements:
        var center: Vector2i = settlement.get("center", INVALID_CELL)
        if center == INVALID_CELL:
            return {"ok": false, "failure_reason": "island_settlement_center_invalid", "road_segments": []}
        var anchor: Vector2i = _nearest_arterial_cell(center, arterials)
        if anchor == INVALID_CELL:
            return {"ok": false, "failure_reason": "island_settlement_arterial_anchor_missing", "road_segments": []}
        if center == anchor:
            continue
        var route_id := "route.island.access.%03d" % access_ordinal
        var branch: Array[Dictionary] = []
        if not _append_routed_path(
            branch,
            "road.island.access.%03d" % access_ordinal,
            &"secondary",
            route_id,
            center,
            anchor,
            secondary_width,
            geography_cells,
            profile
        ):
            return {"ok": false, "failure_reason": "island_settlement_access_failed:%s" % String(settlement.get("id", "")), "road_segments": []}
        var kind: StringName = StringName(settlement.get("kind", &""))
        var road_type: StringName = &"two_lane" if kind == &"smalltown" or kind == &"rural_crossroads" else &"gravel"
        for branch_segment: Dictionary in branch:
            road_segments.append(_styled_road(branch_segment, road_type, secondary_width))
        access_ordinal += 1

    if arterials.size() < 4:
        return {"ok": false, "failure_reason": "island_cross_arterial_count_below_target", "road_segments": []}
    return {"ok": true, "failure_reason": "", "road_segments": road_segments}

func _build_cross_island_arterials(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    geography_cells: Array[Dictionary],
    primary_width: int
) -> Dictionary:
    var roads: Array[Dictionary] = []
    var bounds: Rect2i = request.bounds
    var min_x := bounds.position.x
    var min_y := bounds.position.y
    var max_x := bounds.position.x + bounds.size.x - 1
    var max_y := bounds.position.y + bounds.size.y - 1
    var x_a := min_x + bounds.size.x / 3
    var x_b := min_x + (bounds.size.x * 2) / 3
    var y_a := min_y + bounds.size.y / 3
    var y_b := min_y + (bounds.size.y * 2) / 3

    var specs: Array[Dictionary] = [
        {"id": "we.north", "a_side": &"west", "b_side": &"east", "a": Vector2i(min_x, y_a), "b": Vector2i(max_x, y_a)},
        {"id": "we.south", "a_side": &"west", "b_side": &"east", "a": Vector2i(min_x, y_b), "b": Vector2i(max_x, y_b)},
        {"id": "ns.west", "a_side": &"north", "b_side": &"south", "a": Vector2i(x_a, min_y), "b": Vector2i(x_a, max_y)},
        {"id": "ns.east", "a_side": &"north", "b_side": &"south", "a": Vector2i(x_b, min_y), "b": Vector2i(x_b, max_y)},
    ]

    for spec: Dictionary in specs:
        var start: Vector2i = _boundary_gateway(bounds, StringName(spec.get("a_side", &"")), spec.get("a", INVALID_CELL), geography_cells, profile)
        var finish: Vector2i = _boundary_gateway(bounds, StringName(spec.get("b_side", &"")), spec.get("b", INVALID_CELL), geography_cells, profile)
        if start == INVALID_CELL or finish == INVALID_CELL:
            return {"ok": false, "failure_reason": "island_cross_arterial_gateway_unresolved:%s" % String(spec.get("id", "")), "roads": []}
        var routed: Array[Dictionary] = []
        var route_id := "route.island.arterial.%s" % String(spec.get("id", ""))
        if not _append_routed_path(
            routed,
            "road.island.arterial.%s" % String(spec.get("id", "")),
            &"primary",
            route_id,
            start,
            finish,
            primary_width,
            geography_cells,
            profile
        ):
            return {"ok": false, "failure_reason": "island_cross_arterial_route_failed:%s" % String(spec.get("id", "")), "roads": []}
        for segment: Dictionary in routed:
            roads.append(_styled_road(segment, &"four_lane", primary_width))
    return {"ok": true, "failure_reason": "", "roads": roads}

func _nearest_arterial_cell(center: Vector2i, arterials: Array[Dictionary]) -> Vector2i:
    var best := INVALID_CELL
    var best_distance := 2147483647
    for road: Dictionary in arterials:
        var start: Vector2i = road.get("start", INVALID_CELL)
        var finish: Vector2i = road.get("end", INVALID_CELL)
        if start == INVALID_CELL or finish == INVALID_CELL:
            continue
        var candidate := INVALID_CELL
        if start.y == finish.y:
            candidate = Vector2i(clampi(center.x, mini(start.x, finish.x), maxi(start.x, finish.x)), start.y)
        elif start.x == finish.x:
            candidate = Vector2i(start.x, clampi(center.y, mini(start.y, finish.y), maxi(start.y, finish.y)))
        if candidate == INVALID_CELL:
            continue
        var distance := absi(center.x - candidate.x) + absi(center.y - candidate.y)
        if distance < best_distance or (distance == best_distance and _point_before(candidate, best)):
            best = candidate
            best_distance = distance
    return best

func _styled_road(source_road: Dictionary, road_type: StringName, width: int) -> Dictionary:
    var road: Dictionary = source_road.duplicate(true)
    road["road_type"] = road_type
    road["width"] = width
    match road_type:
        &"four_lane":
            road["road_class"] = &"primary"
            road["lane_count"] = 4
            road["surface_family"] = &"paved_centerline"
            road["paint_centerline"] = true
        &"two_lane":
            road["lane_count"] = 2
            road["surface_family"] = &"paved_centerline"
            road["paint_centerline"] = true
        &"dirt":
            road["lane_count"] = 1
            road["surface_family"] = &"rural_dirt"
            road["paint_centerline"] = false
        _:
            road["road_type"] = &"gravel"
            road["lane_count"] = 1
            road["surface_family"] = &"rural_gravel"
            road["paint_centerline"] = false
    return road
