extends RefCounted
class_name GlobalMajorRoadPlanner

const GeographyQueryClass = preload("res://scripts/generation/world/GlobalGeographyQuery.gd")

var _geography: GlobalGeographyQuery

func _init() -> void:
    _geography = GeographyQueryClass.new()

func plan(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    settlements: Array[Dictionary],
    geography_cells: Array[Dictionary]
) -> Dictionary:
    var road_segments: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty() or settlements.is_empty() or geography_cells.is_empty():
        return {"ok": false, "failure_reason": "invalid_major_road_planner_input", "road_segments": road_segments}

    var crossroads: Dictionary = _settlement_by_id(settlements, "settlement.rural.crossroads.001")
    var smalltown: Dictionary = _settlement_by_id(settlements, "settlement.smalltown.001")
    var north_hamlet: Dictionary = _settlement_by_id(settlements, "settlement.rural.hamlet.001")
    var southwest: Dictionary = _settlement_by_id(settlements, "settlement.rural.hamlet.002")
    var northeast: Dictionary = _settlement_by_id(settlements, "settlement.rural.hamlet.003")
    if crossroads.is_empty() or smalltown.is_empty() or north_hamlet.is_empty() or southwest.is_empty() or northeast.is_empty():
        return {"ok": false, "failure_reason": "required_settlement_missing", "road_segments": road_segments}

    var center: Vector2i = crossroads.get("center", Vector2i.ZERO)
    var primary_width: int = int(profile.get("primary_width", 5))
    var secondary_width: int = int(profile.get("secondary_width", 3))
    var half_span: int = int(profile.get("protected_cross_half_span", 640))

    var primary_start := Vector2i(center.x - half_span, center.y)
    var primary_end := Vector2i(center.x + half_span - 1, center.y)
    var secondary_start := Vector2i(center.x, center.y - half_span)
    var secondary_end := Vector2i(center.x, center.y + half_span - 1)
    if not request.bounds.has_point(primary_start) or not request.bounds.has_point(primary_end) \
        or not request.bounds.has_point(secondary_start) or not request.bounds.has_point(secondary_end):
        return {"ok": false, "failure_reason": "protected_global_road_cross_out_of_bounds", "road_segments": road_segments}

    road_segments.append(_segment(
        "road.region.primary.001",
        &"primary",
        primary_start,
        primary_end,
        primary_width,
        "route.region.primary.001"
    ))
    road_segments.append(_segment(
        "road.region.secondary.001",
        &"secondary",
        secondary_start,
        secondary_end,
        secondary_width,
        "route.region.secondary.001"
    ))

    var west_gateway: Vector2i = _boundary_gateway(request.bounds, &"west", primary_start, geography_cells, profile)
    var east_gateway: Vector2i = _boundary_gateway(request.bounds, &"east", smalltown.get("center", primary_end), geography_cells, profile)
    var north_gateway: Vector2i = _boundary_gateway(request.bounds, &"north", north_hamlet.get("center", secondary_start), geography_cells, profile)
    var south_gateway: Vector2i = _boundary_gateway(request.bounds, &"south", secondary_end, geography_cells, profile)
    if west_gateway.x < -900000 or east_gateway.x < -900000 or north_gateway.x < -900000 or south_gateway.x < -900000:
        return {"ok": false, "failure_reason": "global_road_gateway_unresolved", "road_segments": []}

    if not _append_routed_path(road_segments, "road.region.primary.west", &"primary", "route.region.primary.001", west_gateway, primary_start, primary_width, geography_cells, profile):
        west_gateway = _reachable_boundary_gateway(request.bounds, &"west", primary_start, west_gateway, geography_cells, profile)
        if west_gateway.x < -900000 or not _append_routed_path(road_segments, "road.region.primary.west", &"primary", "route.region.primary.001", west_gateway, primary_start, primary_width, geography_cells, profile):
            return {"ok": false, "failure_reason": "global_primary_west_route_failed", "road_segments": []}
    var smalltown_center: Vector2i = smalltown.get("center", Vector2i.ZERO)
    if not _append_routed_path(road_segments, "road.region.primary.east.inner", &"primary", "route.region.primary.001", primary_end, smalltown_center, primary_width, geography_cells, profile):
        return {"ok": false, "failure_reason": "global_primary_smalltown_route_failed", "road_segments": []}
    if not _append_routed_path(road_segments, "road.region.primary.east.outer", &"primary", "route.region.primary.001", smalltown_center, east_gateway, primary_width, geography_cells, profile):
        east_gateway = _reachable_boundary_gateway(request.bounds, &"east", smalltown_center, east_gateway, geography_cells, profile)
        if east_gateway.x < -900000 or not _append_routed_path(road_segments, "road.region.primary.east.outer", &"primary", "route.region.primary.001", smalltown_center, east_gateway, primary_width, geography_cells, profile):
            return {"ok": false, "failure_reason": "global_primary_east_route_failed", "road_segments": []}

    var north_center: Vector2i = north_hamlet.get("center", Vector2i.ZERO)
    if not _append_routed_path(road_segments, "road.region.secondary.north.inner", &"secondary", "route.region.secondary.001", secondary_start, north_center, secondary_width, geography_cells, profile):
        return {"ok": false, "failure_reason": "global_secondary_north_settlement_route_failed", "road_segments": []}
    if not _append_routed_path(road_segments, "road.region.secondary.north.outer", &"secondary", "route.region.secondary.001", north_center, north_gateway, secondary_width, geography_cells, profile):
        north_gateway = _reachable_boundary_gateway(request.bounds, &"north", north_center, north_gateway, geography_cells, profile)
        if north_gateway.x < -900000 or not _append_routed_path(road_segments, "road.region.secondary.north.outer", &"secondary", "route.region.secondary.001", north_center, north_gateway, secondary_width, geography_cells, profile):
            return {"ok": false, "failure_reason": "global_secondary_north_gateway_route_failed", "road_segments": []}
    if not _append_routed_path(road_segments, "road.region.secondary.south", &"secondary", "route.region.secondary.001", secondary_end, south_gateway, secondary_width, geography_cells, profile):
        south_gateway = _reachable_boundary_gateway(request.bounds, &"south", secondary_end, south_gateway, geography_cells, profile)
        if south_gateway.x < -900000 or not _append_routed_path(road_segments, "road.region.secondary.south", &"secondary", "route.region.secondary.001", secondary_end, south_gateway, secondary_width, geography_cells, profile):
            return {"ok": false, "failure_reason": "global_secondary_south_route_failed", "road_segments": []}

    var southwest_center: Vector2i = southwest.get("center", Vector2i.ZERO)
    if not _append_routed_path(road_segments, "road.region.secondary.southwest", &"secondary", "route.region.secondary.002", primary_start, southwest_center, secondary_width, geography_cells, profile):
        return {"ok": false, "failure_reason": "global_southwest_branch_route_failed", "road_segments": []}
    var northeast_center: Vector2i = northeast.get("center", Vector2i.ZERO)
    if not _append_routed_path(road_segments, "road.region.secondary.northeast", &"secondary", "route.region.secondary.003", secondary_start, northeast_center, secondary_width, geography_cells, profile):
        return {"ok": false, "failure_reason": "global_northeast_branch_route_failed", "road_segments": []}

    for road: Dictionary in road_segments:
        if road.is_empty():
            return {"ok": false, "failure_reason": "major_road_segment_invalid", "road_segments": []}

    return {"ok": true, "failure_reason": "", "road_segments": road_segments}

func _append_routed_path(
    output: Array[Dictionary],
    id_prefix: String,
    road_class: StringName,
    route_id: String,
    start: Vector2i,
    finish: Vector2i,
    width: int,
    geography_cells: Array[Dictionary],
    profile: Dictionary
) -> bool:
    if start == finish:
        return true
    var points: Array[Vector2i] = _route_points(start, finish, geography_cells, profile)
    if points.size() < 2:
        return false
    var ordinal: int = 1
    for index in range(points.size() - 1):
        var a: Vector2i = points[index]
        var b: Vector2i = points[index + 1]
        if a == b:
            continue
        var segment: Dictionary = _segment(
            "%s.%03d" % [id_prefix, ordinal],
            road_class,
            a,
            b,
            width,
            route_id
        )
        if segment.is_empty():
            return false
        output.append(segment)
        ordinal += 1
    return ordinal > 1

func _route_points(
    start: Vector2i,
    finish: Vector2i,
    geography_cells: Array[Dictionary],
    profile: Dictionary
) -> Array[Vector2i]:
    var start_grid: Vector2i = _geography.grid_for_point(start, geography_cells)
    var finish_grid: Vector2i = _geography.grid_for_point(finish, geography_cells)
    if start_grid.x < -900000 or finish_grid.x < -900000:
        return []
    if not _geography.road_allowed_grid(start_grid, geography_cells) or not _geography.road_allowed_grid(finish_grid, geography_cells):
        return []

    var grid_path: Array[Vector2i] = _a_star_grid(start_grid, finish_grid, geography_cells, profile)
    if grid_path.is_empty():
        return []

    var raw_points: Array[Vector2i] = [start]
    for grid: Vector2i in grid_path:
        var geography_cell: Dictionary = _geography.cell_by_grid(grid, geography_cells)
        var center: Vector2i = _geography.cell_center(geography_cell)
        if center.x > -900000:
            raw_points.append(center)
    raw_points.append(finish)

    var cardinal: Array[Vector2i] = []
    for point: Vector2i in raw_points:
        if cardinal.is_empty():
            cardinal.append(point)
            continue
        _append_cardinal_connection(cardinal, point)
    return _compress_collinear(cardinal)

func _a_star_grid(
    start: Vector2i,
    finish: Vector2i,
    geography_cells: Array[Dictionary],
    profile: Dictionary
) -> Array[Vector2i]:
    var open_set: Dictionary = {start: true}
    var came_from: Dictionary = {}
    var g_score: Dictionary = {start: 0}
    var closed: Dictionary = {}
    var directions: Array[Vector2i] = [
        Vector2i(0, -1),
        Vector2i(1, 0),
        Vector2i(0, 1),
        Vector2i(-1, 0),
    ]

    while not open_set.is_empty():
        var current: Vector2i = _lowest_f_score(open_set, g_score, finish)
        if current == finish:
            return _reconstruct_grid_path(came_from, current)
        open_set.erase(current)
        closed[current] = true
        var current_score: int = int(g_score.get(current, 2147483647))

        for direction: Vector2i in directions:
            var neighbor: Vector2i = current + direction
            if closed.has(neighbor) or not _geography.road_allowed_grid(neighbor, geography_cells):
                continue
            var step_cost: int = _geography.road_cost_grid(neighbor, geography_cells, profile)
            if step_cost >= 2147483647:
                continue
            var tentative: int = current_score + step_cost
            var known: int = int(g_score.get(neighbor, 2147483647))
            if tentative >= known:
                continue
            came_from[neighbor] = current
            g_score[neighbor] = tentative
            open_set[neighbor] = true
    return []

func _lowest_f_score(open_set: Dictionary, g_score: Dictionary, finish: Vector2i) -> Vector2i:
    var best := Vector2i(-999999, -999999)
    var best_score: int = 2147483647
    for value: Variant in open_set.keys():
        var grid: Vector2i = value
        var heuristic: int = (absi(grid.x - finish.x) + absi(grid.y - finish.y)) * 10
        var score: int = int(g_score.get(grid, 2147483647)) + heuristic
        if score < best_score or (score == best_score and _grid_before(grid, best)):
            best = grid
            best_score = score
    return best

func _reconstruct_grid_path(came_from: Dictionary, finish: Vector2i) -> Array[Vector2i]:
    var reversed: Array[Vector2i] = [finish]
    var current: Vector2i = finish
    while came_from.has(current):
        var prior: Vector2i = came_from[current]
        current = prior
        reversed.append(current)
    reversed.reverse()
    return reversed

func _append_cardinal_connection(points: Array[Vector2i], target: Vector2i) -> void:
    var current: Vector2i = points.back()
    if current == target:
        return
    if current.x == target.x or current.y == target.y:
        points.append(target)
        return
    var elbow := Vector2i(target.x, current.y)
    if elbow != current:
        points.append(elbow)
    if target != points.back():
        points.append(target)

func _compress_collinear(points: Array[Vector2i]) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for point: Vector2i in points:
        if not result.is_empty() and result.back() == point:
            continue
        result.append(point)
        while result.size() >= 3:
            var a: Vector2i = result[result.size() - 3]
            var b: Vector2i = result[result.size() - 2]
            var c: Vector2i = result[result.size() - 1]
            if (a.x == b.x and b.x == c.x) or (a.y == b.y and b.y == c.y):
                result.remove_at(result.size() - 2)
            else:
                break
    return result

func _boundary_gateway(
    bounds: Rect2i,
    side: StringName,
    desired: Vector2i,
    geography_cells: Array[Dictionary],
    profile: Dictionary
) -> Vector2i:
    var best := Vector2i(-999999, -999999)
    var best_score: int = 2147483647
    var max_x: int = bounds.position.x + bounds.size.x - 1
    var max_y: int = bounds.position.y + bounds.size.y - 1
    for geography_cell: Dictionary in geography_cells:
        var rect: Rect2i = geography_cell.get("rect", Rect2i())
        var touches: bool = false
        match side:
            &"west":
                touches = rect.position.x == bounds.position.x
            &"east":
                touches = rect.position.x + rect.size.x - 1 == max_x
            &"north":
                touches = rect.position.y == bounds.position.y
            &"south":
                touches = rect.position.y + rect.size.y - 1 == max_y
        if not touches:
            continue
        var grid: Vector2i = geography_cell.get("grid", Vector2i(-999999, -999999))
        var cost: int = _geography.road_cost_grid(grid, geography_cells, profile)
        if cost >= 2147483647:
            continue
        var center: Vector2i = _geography.cell_center(geography_cell)
        var candidate: Vector2i = center
        match side:
            &"west":
                candidate.x = bounds.position.x
            &"east":
                candidate.x = max_x
            &"north":
                candidate.y = bounds.position.y
            &"south":
                candidate.y = max_y
        var distance: int = absi(candidate.x - desired.x) + absi(candidate.y - desired.y)
        var score: int = distance + cost * 2
        if score < best_score or (score == best_score and _point_before(candidate, best)):
            best = candidate
            best_score = score
    return best

func _reachable_boundary_gateway(
    bounds: Rect2i,
    side: StringName,
    route_start: Vector2i,
    excluded: Vector2i,
    geography_cells: Array[Dictionary],
    profile: Dictionary
) -> Vector2i:
    var best := Vector2i(-999999, -999999)
    var best_score: int = 2147483647
    var max_x: int = bounds.position.x + bounds.size.x - 1
    var max_y: int = bounds.position.y + bounds.size.y - 1
    for geography_cell: Dictionary in geography_cells:
        var rect: Rect2i = geography_cell.get("rect", Rect2i())
        var touches: bool = false
        match side:
            &"west":
                touches = rect.position.x == bounds.position.x
            &"east":
                touches = rect.position.x + rect.size.x - 1 == max_x
            &"north":
                touches = rect.position.y == bounds.position.y
            &"south":
                touches = rect.position.y + rect.size.y - 1 == max_y
        if not touches:
            continue
        var grid: Vector2i = geography_cell.get("grid", Vector2i(-999999, -999999))
        var cost: int = _geography.road_cost_grid(grid, geography_cells, profile)
        if cost >= 2147483647:
            continue
        var center: Vector2i = _geography.cell_center(geography_cell)
        var candidate: Vector2i = center
        match side:
            &"west":
                candidate.x = bounds.position.x
            &"east":
                candidate.x = max_x
            &"north":
                candidate.y = bounds.position.y
            &"south":
                candidate.y = max_y
        if candidate == excluded:
            continue
        if _route_points(route_start, candidate, geography_cells, profile).size() < 2:
            continue
        var distance: int = absi(candidate.x - route_start.x) + absi(candidate.y - route_start.y)
        var score: int = distance + cost * 2
        if score < best_score or (score == best_score and _point_before(candidate, best)):
            best = candidate
            best_score = score
    return best

func _segment(
    road_id: String,
    road_class: StringName,
    start: Vector2i,
    finish: Vector2i,
    width: int,
    route_id: String
) -> Dictionary:
    if start == finish or (start.x != finish.x and start.y != finish.y):
        return {}
    if width <= 0 or width % 2 == 0:
        return {}
    return {
        "road_id": road_id,
        "road_class": road_class,
        "start": start,
        "end": finish,
        "width": width,
        "route_id": route_id,
    }

func _settlement_by_id(settlements: Array[Dictionary], settlement_id: String) -> Dictionary:
    for settlement: Dictionary in settlements:
        if String(settlement.get("id", "")) == settlement_id:
            return settlement
    return {}

func _grid_before(a: Vector2i, b: Vector2i) -> bool:
    if b.x < -900000:
        return true
    return a.y < b.y or (a.y == b.y and a.x < b.x)

func _point_before(a: Vector2i, b: Vector2i) -> bool:
    if b.x < -900000:
        return true
    return a.y < b.y or (a.y == b.y and a.x < b.x)
