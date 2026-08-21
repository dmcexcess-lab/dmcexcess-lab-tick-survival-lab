extends RefCounted
class_name LocalRoadPlanner

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

    if int(profile.get("local_road_spurs", 0)) != 0:
        return {"ok": false, "failure_reason": "local_road_spurs_not_implemented", "roads": roads, "intersections": intersections}

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
    corridor_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        return a.y < b.y or (a.y == b.y and a.x < b.x)
    )
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
    }

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
