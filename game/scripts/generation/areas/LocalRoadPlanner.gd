extends RefCounted
class_name LocalRoadPlanner

const Seed = preload("res://scripts/generation/areas/AreaSeed.gd")

func plan(request: AreaGenerationRequest, profile: Dictionary) -> Dictionary:
    var roads: Array[Dictionary] = []
    var intersections: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty():
        return {"ok": false, "failure_reason": "invalid_road_planner_input", "roads": roads, "intersections": intersections}

    for constraint: Dictionary in request.inherited_roads:
        var built: Dictionary = _build_inherited_road(constraint)
        if built.is_empty():
            return {"ok": false, "failure_reason": "invalid_inherited_road", "roads": roads, "intersections": intersections}
        roads.append(built)

    var local_count: int = int(profile.get("local_road_spurs", 0))
    for ordinal in range(local_count):
        var local_road: Dictionary = _build_local_rural_spur(request, profile, roads, ordinal)
        if local_road.is_empty():
            return {"ok": false, "failure_reason": "local_road_spur_failed", "roads": roads, "intersections": intersections}
        roads.append(local_road)

    for first_index in range(roads.size()):
        for second_index in range(first_index + 1, roads.size()):
            var cell: Vector2i = _path_intersection_cell(roads[first_index], roads[second_index])
            if cell.x < -100000:
                continue
            intersections.append({
                "id": "%s.intersection.%03d" % [request.area_id, intersections.size()],
                "cell": cell,
                "road_ids": [String(roads[first_index].get("road_id", "")), String(roads[second_index].get("road_id", ""))],
                "control": &"signalized" if intersections.is_empty() else &"uncontrolled",
            })

    return {"ok": true, "failure_reason": "", "roads": roads, "intersections": intersections}

func _build_inherited_road(constraint: Dictionary) -> Dictionary:
    var start: Vector2i = constraint.get("start", Vector2i.ZERO)
    var finish: Vector2i = constraint.get("end", Vector2i.ZERO)
    var width: int = int(constraint.get("width", 0))
    if width <= 0 or width % 2 == 0:
        return {}
    var axis: StringName = &"horizontal" if start.y == finish.y else &"vertical"
    var path_cells: Array[Vector2i] = _line_cells(start, finish)
    if path_cells.is_empty():
        return {}
    var corridor_cells: Array[Vector2i] = _straight_corridor(path_cells, axis, width)
    return {
        "road_id": String(constraint.get("road_id", "")),
        "road_class": StringName(constraint.get("road_class", &"")),
        "start": start,
        "end": finish,
        "width": width,
        "axis": axis,
        "path_cells": path_cells,
        "corridor_cells": corridor_cells,
        "inherited": true,
        "allowed_boundary_cells": (constraint.get("allowed_boundary_cells", []) as Array).duplicate(),
        "surface_family": &"paved_centerline",
        "paint_centerline": true,
        "parcel_frontage_enabled": true,
    }

func _build_local_rural_spur(
    request: AreaGenerationRequest,
    profile: Dictionary,
    roads: Array[Dictionary],
    ordinal: int
) -> Dictionary:
    var primary: Dictionary = {}
    for road: Dictionary in roads:
        if StringName(road.get("road_class", &"")) == &"primary" and StringName(road.get("axis", &"")) == &"horizontal":
            primary = road
            break
    if primary.is_empty():
        return {}

    var width: int = int(profile.get("local_spur_width", 3))
    if width <= 0 or width % 2 == 0:
        return {}

    var center := Vector2i(
        request.bounds.position.x + request.bounds.size.x / 2,
        request.bounds.position.y + request.bounds.size.y / 2
    )
    var layout_flip: int = -1 if Seed.choose_index(request.seed, "local_roads:layout_flip", 2) == 0 else 1
    var branch_side: int = (-1 if ordinal % 2 == 0 else 1) * layout_flip
    var vertical_side: int = -1 if ordinal % 2 == 0 else 1
    var branch_offset: int = int(profile.get("local_spur_branch_offset", 64))
    branch_offset += Seed.choose_index(request.seed, "local_spur:branch_jitter:%d" % ordinal, 7) - 3

    var first_leg: int = int(profile.get("local_spur_first_leg", 36))
    first_leg += Seed.choose_index(request.seed, "local_spur:first_leg:%d" % ordinal, 7) - 3
    var lateral_leg: int = int(profile.get("local_spur_lateral_leg", 44))
    lateral_leg += Seed.choose_index(request.seed, "local_spur:lateral_leg:%d" % ordinal, 9) - 4
    var second_leg: int = int(profile.get("local_spur_second_leg", 46))
    second_leg += Seed.choose_index(request.seed, "local_spur:second_leg:%d" % ordinal, 9) - 4
    var tail_leg: int = int(profile.get("local_spur_tail_leg", 28))
    tail_leg += Seed.choose_index(request.seed, "local_spur:tail_leg:%d" % ordinal, 7) - 3

    var primary_start: Vector2i = primary.get("start", Vector2i.ZERO)
    var primary_end: Vector2i = primary.get("end", Vector2i.ZERO)
    var min_primary_x: int = mini(primary_start.x, primary_end.x) + width + 2
    var max_primary_x: int = maxi(primary_start.x, primary_end.x) - width - 2
    var branch_x: int = clampi(center.x + branch_side * branch_offset, min_primary_x, max_primary_x)
    var branch_y: int = primary_start.y

    var vertical_needed: int = first_leg + second_leg
    var margin: int = width + 3
    var north_space: int = branch_y - (request.bounds.position.y + margin)
    var south_limit: int = request.bounds.position.y + request.bounds.size.y - 1 - margin
    var south_space: int = south_limit - branch_y
    if vertical_side < 0 and north_space < vertical_needed:
        vertical_side = 1
    elif vertical_side > 0 and south_space < vertical_needed:
        vertical_side = -1
    if (vertical_side < 0 and north_space < vertical_needed) or (vertical_side > 0 and south_space < vertical_needed):
        return {}

    var start := Vector2i(branch_x, branch_y)
    var first := start + Vector2i(0, vertical_side * first_leg)
    var lateral_direction: int = -branch_side
    var second := first + Vector2i(lateral_direction * lateral_leg, 0)
    var third := second + Vector2i(0, vertical_side * second_leg)
    var finish := third + Vector2i(branch_side * tail_leg, 0)
    var waypoints: Array[Vector2i] = [start, first, second, third, finish]
    for point: Vector2i in waypoints:
        if not request.bounds.has_point(point):
            return {}

    var path_cells: Array[Vector2i] = _polyline_cells(waypoints)
    if path_cells.is_empty():
        return {}
    var corridor_cells: Array[Vector2i] = _polyline_corridor(path_cells, width, request.bounds)
    if corridor_cells.is_empty():
        return {}

    return {
        "road_id": "%s.road.local.rural.%02d" % [request.area_id, ordinal],
        "road_class": &"local_rural",
        "start": start,
        "end": finish,
        "width": width,
        "axis": &"polyline",
        "path_cells": path_cells,
        "corridor_cells": corridor_cells,
        "waypoints": waypoints,
        "inherited": false,
        "allowed_boundary_cells": [],
        "surface_family": &"rural_gravel",
        "paint_centerline": false,
        "parcel_frontage_enabled": true,
    }

func _straight_corridor(path_cells: Array[Vector2i], axis: StringName, width: int) -> Array[Vector2i]:
    var corridor_cells: Array[Vector2i] = []
    var seen: Dictionary = {}
    var half_width: int = width / 2
    for cell: Vector2i in path_cells:
        for offset in range(-half_width, half_width + 1):
            var corridor: Vector2i = cell + (Vector2i(0, offset) if axis == &"horizontal" else Vector2i(offset, 0))
            if seen.has(corridor):
                continue
            seen[corridor] = true
            corridor_cells.append(corridor)
    _sort_cells(corridor_cells)
    return corridor_cells

func _polyline_corridor(path_cells: Array[Vector2i], width: int, bounds: Rect2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var seen: Dictionary = {}
    var radius: int = width / 2
    for path_cell: Vector2i in path_cells:
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                var cell := path_cell + Vector2i(dx, dy)
                if not bounds.has_point(cell) or seen.has(cell):
                    continue
                seen[cell] = true
                result.append(cell)
    _sort_cells(result)
    return result

func _polyline_cells(points: Array[Vector2i]) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var seen: Dictionary = {}
    for index in range(points.size() - 1):
        var segment: Array[Vector2i] = _line_cells(points[index], points[index + 1])
        if segment.is_empty():
            return []
        for cell: Vector2i in segment:
            if seen.has(cell):
                continue
            seen[cell] = true
            result.append(cell)
    return result

func _line_cells(start: Vector2i, finish: Vector2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    if start.x == finish.x:
        var step_y: int = 1 if finish.y >= start.y else -1
        var y: int = start.y
        while true:
            result.append(Vector2i(start.x, y))
            if y == finish.y:
                break
            y += step_y
        return result
    if start.y == finish.y:
        var step_x: int = 1 if finish.x >= start.x else -1
        var x: int = start.x
        while true:
            result.append(Vector2i(x, start.y))
            if x == finish.x:
                break
            x += step_x
    return result

func _path_intersection_cell(first: Dictionary, second: Dictionary) -> Vector2i:
    var first_cells: Dictionary = {}
    for value: Variant in first.get("path_cells", []):
        first_cells[value] = true
    for value: Variant in second.get("path_cells", []):
        if first_cells.has(value):
            return value
    return Vector2i(-999999, -999999)

func _sort_cells(cells: Array[Vector2i]) -> void:
    cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        return a.y < b.y or (a.y == b.y and a.x < b.x)
    )
