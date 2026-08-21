extends RefCounted
class_name GlobalHydrologyPlanner

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")
const GeographyQueryClass = preload("res://scripts/generation/world/GlobalGeographyQuery.gd")

var _geography: GlobalGeographyQuery

func _init() -> void:
    _geography = GeographyQueryClass.new()

func plan(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    geography_cells: Array[Dictionary]
) -> Dictionary:
    var river_segments: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty() or geography_cells.is_empty():
        return {"ok": false, "failure_reason": "invalid_global_hydrology_input", "river_segments": river_segments}

    var source_grid: Vector2i = _boundary_grid(request, profile, geography_cells, &"north", true)
    var outlet_grid: Vector2i = _boundary_grid(request, profile, geography_cells, &"south", false)
    if source_grid.x < -900000 or outlet_grid.x < -900000:
        return {"ok": false, "failure_reason": "global_river_boundary_endpoint_unresolved", "river_segments": river_segments}

    var grid_path: Array[Vector2i] = _a_star_river(request, profile, geography_cells, source_grid, outlet_grid)
    if grid_path.size() < 2:
        return {"ok": false, "failure_reason": "global_primary_river_route_failed", "river_segments": river_segments}

    var source_cell: Dictionary = _geography.cell_by_grid(source_grid, geography_cells)
    var outlet_cell: Dictionary = _geography.cell_by_grid(outlet_grid, geography_cells)
    if source_cell.is_empty() or outlet_cell.is_empty():
        return {"ok": false, "failure_reason": "global_river_endpoint_geography_missing", "river_segments": river_segments}

    var source_center: Vector2i = _geography.cell_center(source_cell)
    var outlet_center: Vector2i = _geography.cell_center(outlet_cell)
    var max_y: int = request.bounds.position.y + request.bounds.size.y - 1
    var source := Vector2i(source_center.x, request.bounds.position.y)
    var outlet := Vector2i(outlet_center.x, max_y)

    var raw_points: Array[Vector2i] = [source]
    for grid: Vector2i in grid_path:
        var geography_cell: Dictionary = _geography.cell_by_grid(grid, geography_cells)
        var center: Vector2i = _geography.cell_center(geography_cell)
        if center.x > -900000:
            raw_points.append(center)
    raw_points.append(outlet)

    var cardinal: Array[Vector2i] = []
    for point: Vector2i in raw_points:
        if cardinal.is_empty():
            cardinal.append(point)
            continue
        _append_cardinal_connection(cardinal, point)
    cardinal = _compress_collinear(cardinal)
    if cardinal.size() < 2:
        return {"ok": false, "failure_reason": "global_primary_river_cardinalization_failed", "river_segments": river_segments}

    var river_id: String = "river.region.primary.001"
    var width: int = int(profile.get("primary_river_width", 5))
    var ordinal: int = 1
    for index in range(cardinal.size() - 1):
        var start: Vector2i = cardinal[index]
        var finish: Vector2i = cardinal[index + 1]
        if start == finish:
            continue
        if start.x != finish.x and start.y != finish.y:
            return {"ok": false, "failure_reason": "global_primary_river_noncardinal_segment", "river_segments": []}
        river_segments.append({
            "segment_id": "%s.segment.%03d" % [river_id, ordinal],
            "river_id": river_id,
            "start": start,
            "end": finish,
            "width": width,
            "ordinal": ordinal,
        })
        ordinal += 1

    if river_segments.is_empty():
        return {"ok": false, "failure_reason": "global_primary_river_empty", "river_segments": []}
    return {"ok": true, "failure_reason": "", "river_segments": river_segments}

func _boundary_grid(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    geography_cells: Array[Dictionary],
    side: StringName,
    choose_highest: bool
) -> Vector2i:
    var center_x: int = request.bounds.position.x + request.bounds.size.x / 2
    var half_span: int = int(profile.get("protected_cross_half_span", 640))
    var use_west: bool = Seed.choose_index(request.seed, "hydrology:primary_side", 2) == 0
    var selected := Vector2i(-999999, -999999)
    var selected_elevation: int = -1 if choose_highest else 101
    var selected_noise: int = 2147483647
    var max_y: int = request.bounds.position.y + request.bounds.size.y - 1

    for cell: Dictionary in geography_cells:
        var rect: Rect2i = cell.get("rect", Rect2i())
        var touches_boundary: bool = false
        if side == &"north":
            touches_boundary = rect.position.y == request.bounds.position.y
        elif side == &"south":
            touches_boundary = rect.position.y + rect.size.y - 1 == max_y
        if not touches_boundary:
            continue
        var cell_center: Vector2i = _geography.cell_center(cell)
        if cell_center.x < -900000:
            continue
        if use_west:
            if cell_center.x >= center_x - half_span:
                continue
        else:
            if cell_center.x <= center_x + half_span:
                continue
        var elevation: int = int(cell.get("elevation", 0))
        var grid: Vector2i = cell.get("grid", Vector2i(-999999, -999999))
        var noise: int = Seed.hash_2d(request.seed, grid.x, grid.y, 701)
        var better: bool = false
        if choose_highest:
            better = elevation > selected_elevation or (elevation == selected_elevation and noise < selected_noise)
        else:
            better = elevation < selected_elevation or (elevation == selected_elevation and noise < selected_noise)
        if better:
            selected = grid
            selected_elevation = elevation
            selected_noise = noise
    return selected

func _a_star_river(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    geography_cells: Array[Dictionary],
    start: Vector2i,
    finish: Vector2i
) -> Array[Vector2i]:
    var open_set: Dictionary = {start: true}
    var came_from: Dictionary = {}
    var g_score: Dictionary = {start: 0}
    var closed: Dictionary = {}
    var directions: Array[Vector2i] = [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]

    while not open_set.is_empty():
        var current: Vector2i = _lowest_f_score(open_set, g_score, finish)
        if current == finish:
            return _reconstruct(came_from, current)
        open_set.erase(current)
        closed[current] = true
        var current_cell: Dictionary = _geography.cell_by_grid(current, geography_cells)
        var current_elevation: int = int(current_cell.get("elevation", 0))
        var current_score: int = int(g_score.get(current, 2147483647))

        for direction: Vector2i in directions:
            var neighbor: Vector2i = current + direction
            if closed.has(neighbor):
                continue
            var neighbor_cell: Dictionary = _geography.cell_by_grid(neighbor, geography_cells)
            if neighbor_cell.is_empty() or _protected_hydrology_cell(neighbor_cell, request, profile):
                continue
            var neighbor_elevation: int = int(neighbor_cell.get("elevation", 0))
            var uphill: int = maxi(0, neighbor_elevation - current_elevation)
            var downhill_bonus: int = mini(6, maxi(0, current_elevation - neighbor_elevation) / 8)
            var meander: int = int(Seed.unit_2d(request.seed, neighbor.x, neighbor.y, 733) * float(int(profile.get("river_meander_cost", 7))))
            var step_cost: int = 10 + neighbor_elevation / 12 + uphill * int(profile.get("river_uphill_penalty", 5)) + meander - downhill_bonus
            step_cost = maxi(1, step_cost)
            var tentative: int = current_score + step_cost
            var known: int = int(g_score.get(neighbor, 2147483647))
            if tentative >= known:
                continue
            came_from[neighbor] = current
            g_score[neighbor] = tentative
            open_set[neighbor] = true
    return []

func _protected_hydrology_cell(cell: Dictionary, request: GlobalWorldGenerationRequest, profile: Dictionary) -> bool:
    var rect: Rect2i = cell.get("rect", Rect2i())
    var center := Vector2i(
        request.bounds.position.x + request.bounds.size.x / 2,
        request.bounds.position.y + request.bounds.size.y / 2
    )
    var half_span: int = int(profile.get("protected_cross_half_span", 640))
    var half_thickness: int = int(profile.get("protected_cross_half_thickness", 192)) + int(profile.get("hydrology_protected_margin", 0))
    var horizontal := Rect2i(
        Vector2i(center.x - half_span, center.y - half_thickness),
        Vector2i(half_span * 2, half_thickness * 2)
    )
    var vertical := Rect2i(
        Vector2i(center.x - half_thickness, center.y - half_span),
        Vector2i(half_thickness * 2, half_span * 2)
    )
    return _rects_intersect(rect, horizontal) or _rects_intersect(rect, vertical)

func _lowest_f_score(open_set: Dictionary, g_score: Dictionary, finish: Vector2i) -> Vector2i:
    var best := Vector2i(-999999, -999999)
    var best_score: int = 2147483647
    for value: Variant in open_set.keys():
        var grid: Vector2i = value
        var heuristic: int = (absi(grid.x - finish.x) + absi(grid.y - finish.y)) * 8
        var score: int = int(g_score.get(grid, 2147483647)) + heuristic
        if score < best_score or (score == best_score and _grid_before(grid, best)):
            best = grid
            best_score = score
    return best

func _reconstruct(came_from: Dictionary, finish: Vector2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = [finish]
    var current: Vector2i = finish
    while came_from.has(current):
        var previous: Vector2i = came_from[current]
        current = previous
        result.append(current)
    result.reverse()
    return result

func _append_cardinal_connection(points: Array[Vector2i], target: Vector2i) -> void:
    var current: Vector2i = points.back()
    if current == target:
        return
    if current.x == target.x or current.y == target.y:
        points.append(target)
        return
    var elbow := Vector2i(current.x, target.y)
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

func _grid_before(a: Vector2i, b: Vector2i) -> bool:
    if b.x < -900000:
        return true
    return a.y < b.y or (a.y == b.y and a.x < b.x)

func _rects_intersect(a: Rect2i, b: Rect2i) -> bool:
    if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0:
        return false
    return a.position.x < b.position.x + b.size.x \
        and a.position.x + a.size.x > b.position.x \
        and a.position.y < b.position.y + b.size.y \
        and a.position.y + a.size.y > b.position.y
