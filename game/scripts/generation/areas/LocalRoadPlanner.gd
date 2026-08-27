extends RefCounted
class_name LocalRoadPlanner

const Seed = preload("res://scripts/generation/areas/AreaSeed.gd")

func plan(
    request: AreaGenerationRequest,
    profile: Dictionary,
    reservations: Array[Dictionary] = []
) -> Dictionary:
    var roads: Array[Dictionary] = []
    var intersections: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty():
        return {"ok": false, "failure_reason": "invalid_road_planner_input", "roads": roads, "intersections": intersections}

    for constraint: Dictionary in request.inherited_roads:
        var built: Dictionary = _build_inherited_road(constraint)
        if built.is_empty():
            return {"ok": false, "failure_reason": "invalid_inherited_road", "roads": roads, "intersections": intersections}
        roads.append(built)

    var layout: StringName = StringName(profile.get("road_layout", &"rural_spurs"))
    if layout == &"smalltown_grid":
        var town_result: Dictionary = _build_smalltown_streets(request, profile, roads, reservations)
        if not bool(town_result.get("ok", false)):
            return {
                "ok": false,
                "failure_reason": String(town_result.get("failure_reason", "smalltown_street_planning_failed")),
                "roads": roads,
                "intersections": intersections,
            }
        for road_value: Variant in town_result.get("roads", []):
            if typeof(road_value) != TYPE_DICTIONARY:
                return {"ok": false, "failure_reason": "smalltown_street_result_invalid", "roads": roads, "intersections": intersections}
            roads.append(road_value)
    elif layout == &"rural_scattered_lanes":
        var scattered_result: Dictionary = _build_rural_scattered_lanes(request, profile, roads, reservations)
        if not bool(scattered_result.get("ok", false)):
            return {
                "ok": false,
                "failure_reason": String(scattered_result.get("failure_reason", "rural_scattered_lane_planning_failed")),
                "roads": roads,
                "intersections": intersections,
            }
        for road_value: Variant in scattered_result.get("roads", []):
            if typeof(road_value) != TYPE_DICTIONARY:
                return {"ok": false, "failure_reason": "rural_scattered_lane_result_invalid", "roads": roads, "intersections": intersections}
            roads.append(road_value)
    else:
        var local_count: int = int(profile.get("local_road_spurs", 0))
        for ordinal in range(local_count):
            var local_road: Dictionary = _build_local_rural_spur(request, profile, roads, ordinal)
            if local_road.is_empty():
                return {"ok": false, "failure_reason": "local_road_spur_failed", "roads": roads, "intersections": intersections}
            roads.append(local_road)

    var signalize_first: bool = bool(profile.get("signalize_first_inherited_intersection", true))
    for first_index in range(roads.size()):
        for second_index in range(first_index + 1, roads.size()):
            var cell: Vector2i = _path_intersection_cell(roads[first_index], roads[second_index])
            if cell.x < -100000:
                continue
            intersections.append({
                "id": "%s.intersection.%03d" % [request.area_id, intersections.size()],
                "cell": cell,
                "road_ids": [String(roads[first_index].get("road_id", "")), String(roads[second_index].get("road_id", ""))],
                "control": &"signalized" if signalize_first and intersections.size() == 0 else &"uncontrolled",
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

func _build_smalltown_streets(
    request: AreaGenerationRequest,
    profile: Dictionary,
    inherited_roads: Array[Dictionary],
    reservations: Array[Dictionary]
) -> Dictionary:
    var center := Vector2i(
        request.bounds.position.x + request.bounds.size.x / 2,
        request.bounds.position.y + request.bounds.size.y / 2
    )
    var spine: Dictionary = _select_town_spine(inherited_roads, center)
    if spine.is_empty():
        return {"ok": false, "failure_reason": "smalltown_spine_missing", "roads": []}
    var axis: StringName = StringName(spine.get("axis", &""))
    if axis != &"horizontal" and axis != &"vertical":
        return {"ok": false, "failure_reason": "smalltown_spine_axis_invalid", "roads": []}
    spine["town_spine"] = true

    var cross_offsets: Array = profile.get("town_cross_offset_candidates", [48, 60, 72, 84])
    var back_offsets: Array = profile.get("town_back_offset_candidates", [40, 52, 64, 76])
    if cross_offsets.is_empty() or back_offsets.is_empty():
        return {"ok": false, "failure_reason": "smalltown_street_offsets_missing", "roads": []}
    var width: int = int(profile.get("local_town_width", 3))
    var extension: int = int(profile.get("town_street_extension", 10))
    if width <= 0 or width % 2 == 0 or extension < 0:
        return {"ok": false, "failure_reason": "smalltown_street_profile_invalid", "roads": []}

    var cross_start_index: int = Seed.choose_index(request.seed, "smalltown:cross_offset_start", cross_offsets.size())
    var back_start_index: int = Seed.choose_index(request.seed, "smalltown:back_offset_start", back_offsets.size())
    if cross_start_index < 0 or back_start_index < 0:
        return {"ok": false, "failure_reason": "smalltown_street_seed_choice_failed", "roads": []}

    for cross_step_a in range(cross_offsets.size()):
        var cross_offset_a: int = int(cross_offsets[(cross_start_index + cross_step_a) % cross_offsets.size()])
        for cross_step_b in range(cross_offsets.size()):
            var cross_offset_b: int = int(cross_offsets[(cross_start_index + cross_step_b + 1) % cross_offsets.size()])
            for back_step_a in range(back_offsets.size()):
                var back_offset_a: int = int(back_offsets[(back_start_index + back_step_a) % back_offsets.size()])
                for back_step_b in range(back_offsets.size()):
                    var back_offset_b: int = int(back_offsets[(back_start_index + back_step_b + 1) % back_offsets.size()])
                    var candidate: Array[Dictionary] = _smalltown_street_candidate(
                        request,
                        spine,
                        center,
                        width,
                        extension,
                        cross_offset_a,
                        cross_offset_b,
                        back_offset_a,
                        back_offset_b
                    )
                    if candidate.size() != 4:
                        continue
                    if not _local_roads_legal(candidate, request, inherited_roads, reservations):
                        continue
                    return {"ok": true, "failure_reason": "", "roads": candidate}

    return {"ok": false, "failure_reason": "smalltown_street_layout_unresolved", "roads": []}

func _select_town_spine(roads: Array[Dictionary], center: Vector2i) -> Dictionary:
    var fallback: Dictionary = {}
    for road: Dictionary in roads:
        if not _point_on_road_path(center, road):
            continue
        if fallback.is_empty():
            fallback = road
        if StringName(road.get("road_class", &"")) == &"primary":
            return road
    return fallback

func _smalltown_street_candidate(
    request: AreaGenerationRequest,
    spine: Dictionary,
    center: Vector2i,
    width: int,
    extension: int,
    cross_offset_negative: int,
    cross_offset_positive: int,
    back_offset_negative: int,
    back_offset_positive: int
) -> Array[Dictionary]:
    var roads: Array[Dictionary] = []
    var axis: StringName = StringName(spine.get("axis", &""))
    if axis == &"horizontal":
        var x_negative: int = center.x - cross_offset_negative
        var x_positive: int = center.x + cross_offset_positive
        var y_negative: int = center.y - back_offset_negative
        var y_positive: int = center.y + back_offset_positive
        roads.append(_build_local_town_street(
            request, 0, &"town_cross_negative",
            Vector2i(x_negative, y_negative - extension),
            Vector2i(x_negative, y_positive + extension), width
        ))
        roads.append(_build_local_town_street(
            request, 1, &"town_cross_positive",
            Vector2i(x_positive, y_negative - extension),
            Vector2i(x_positive, y_positive + extension), width
        ))
        roads.append(_build_local_town_street(
            request, 2, &"town_back_negative",
            Vector2i(x_negative - extension, y_negative),
            Vector2i(x_positive + extension, y_negative), width
        ))
        roads.append(_build_local_town_street(
            request, 3, &"town_back_positive",
            Vector2i(x_negative - extension, y_positive),
            Vector2i(x_positive + extension, y_positive), width
        ))
    elif axis == &"vertical":
        var y_negative: int = center.y - cross_offset_negative
        var y_positive: int = center.y + cross_offset_positive
        var x_negative: int = center.x - back_offset_negative
        var x_positive: int = center.x + back_offset_positive
        roads.append(_build_local_town_street(
            request, 0, &"town_cross_negative",
            Vector2i(x_negative - extension, y_negative),
            Vector2i(x_positive + extension, y_negative), width
        ))
        roads.append(_build_local_town_street(
            request, 1, &"town_cross_positive",
            Vector2i(x_negative - extension, y_positive),
            Vector2i(x_positive + extension, y_positive), width
        ))
        roads.append(_build_local_town_street(
            request, 2, &"town_back_negative",
            Vector2i(x_negative, y_negative - extension),
            Vector2i(x_negative, y_positive + extension), width
        ))
        roads.append(_build_local_town_street(
            request, 3, &"town_back_positive",
            Vector2i(x_positive, y_negative - extension),
            Vector2i(x_positive, y_positive + extension), width
        ))
    for road: Dictionary in roads:
        if road.is_empty():
            return []
    return roads

func _build_local_town_street(
    request: AreaGenerationRequest,
    ordinal: int,
    role: StringName,
    start: Vector2i,
    finish: Vector2i,
    width: int
) -> Dictionary:
    if start == finish or (start.x != finish.x and start.y != finish.y):
        return {}
    if not request.bounds.has_point(start) or not request.bounds.has_point(finish):
        return {}
    if AreaGenerationRequest._is_boundary_cell(request.bounds, start) or AreaGenerationRequest._is_boundary_cell(request.bounds, finish):
        return {}
    var axis: StringName = &"horizontal" if start.y == finish.y else &"vertical"
    var path_cells: Array[Vector2i] = _line_cells(start, finish)
    var corridor_cells: Array[Vector2i] = _straight_corridor(path_cells, axis, width)
    for cell: Vector2i in corridor_cells:
        if not request.bounds.has_point(cell):
            return {}
    return {
        "road_id": "%s.road.local.town.%02d" % [request.area_id, ordinal],
        "road_class": &"local_town",
        "start": start,
        "end": finish,
        "width": width,
        "axis": axis,
        "path_cells": path_cells,
        "corridor_cells": corridor_cells,
        "inherited": false,
        "allowed_boundary_cells": [],
        "surface_family": &"paved_local",
        "paint_centerline": false,
        "parcel_frontage_enabled": true,
        "town_role": role,
    }

func _build_rural_scattered_lanes(
    request: AreaGenerationRequest,
    profile: Dictionary,
    inherited_roads: Array[Dictionary],
    reservations: Array[Dictionary]
) -> Dictionary:
    var center := Vector2i(
        request.bounds.position.x + request.bounds.size.x / 2,
        request.bounds.position.y + request.bounds.size.y / 2
    )
    var lane_count: int = int(profile.get("rural_scattered_lane_count", 2))
    var width: int = int(profile.get("rural_scattered_lane_width", 3))
    var branch_margin: int = int(profile.get("rural_scattered_branch_margin", 24))
    var branch_separation: int = int(profile.get("rural_scattered_branch_separation", 44))
    var first_leg: int = int(profile.get("rural_scattered_first_leg", 54))
    var tail_leg: int = int(profile.get("rural_scattered_tail_leg", 34))
    if lane_count != 2 or width <= 0 or width % 2 == 0 or branch_margin < 0 or branch_separation <= 0 or first_leg <= 0 or tail_leg <= 0:
        return {"ok": false, "failure_reason": "rural_scattered_lane_profile_invalid", "roads": []}

    var spine_candidates: Array[Dictionary] = _rural_scattered_spine_candidates(inherited_roads, center)
    if spine_candidates.is_empty():
        return {"ok": false, "failure_reason": "rural_scattered_spine_missing", "roads": []}

    var found_anchor_set: bool = false
    var found_branch_pair: bool = false
    var preferred_side: int = -1 if Seed.choose_index(request.seed, "rural_scattered:side_flip", 2) == 0 else 1
    var side_pairs: Array[Vector2i] = [
        Vector2i(preferred_side, -preferred_side),
        Vector2i(-preferred_side, preferred_side),
        Vector2i(preferred_side, preferred_side),
        Vector2i(-preferred_side, -preferred_side),
    ]
    var tail_direction_pairs: Array[Vector2i] = [
        Vector2i(-1, 1),
        Vector2i(1, -1),
        Vector2i(-1, -1),
        Vector2i(1, 1),
    ]
    for spine: Dictionary in spine_candidates:
        var axis: StringName = StringName(spine.get("axis", &""))
        var anchors: Array[Vector2i] = _rural_scattered_branch_anchors(request, spine, inherited_roads, branch_margin, width)
        if anchors.size() < 2:
            continue
        found_anchor_set = true

        var pairs: Array[Array] = []
        for first_index in range(anchors.size()):
            for second_index in range(first_index + 1, anchors.size()):
                var a: Vector2i = anchors[first_index]
                var b: Vector2i = anchors[second_index]
                var separation: int = absi(a.x - b.x) + absi(a.y - b.y)
                if separation < branch_separation:
                    continue
                pairs.append([a, b])
        if pairs.is_empty():
            continue
        found_branch_pair = true

        pairs.sort_custom(func(a: Array, b: Array) -> bool:
            var a0: Vector2i = a[0]
            var a1: Vector2i = a[1]
            var b0: Vector2i = b[0]
            var b1: Vector2i = b[1]
            var a_distance: int = absi(a0.x - center.x) + absi(a0.y - center.y) + absi(a1.x - center.x) + absi(a1.y - center.y)
            var b_distance: int = absi(b0.x - center.x) + absi(b0.y - center.y) + absi(b1.x - center.x) + absi(b1.y - center.y)
            if a_distance != b_distance:
                return a_distance < b_distance
            if a0.y != b0.y:
                return a0.y < b0.y
            if a0.x != b0.x:
                return a0.x < b0.x
            if a1.y != b1.y:
                return a1.y < b1.y
            return a1.x < b1.x
        )

        var pair_domain: String = "rural_scattered:branch_pair_start:%s" % String(spine.get("road_id", ""))
        var pair_start: int = Seed.choose_index(request.seed, pair_domain, pairs.size())
        if pair_start < 0:
            continue
        for pair_step in range(pairs.size()):
            var pair: Array = pairs[(pair_start + pair_step) % pairs.size()]
            var anchor_a: Vector2i = pair[0]
            var anchor_b: Vector2i = pair[1]
            if _axis_coordinate(anchor_a, axis) > _axis_coordinate(anchor_b, axis):
                var swap: Vector2i = anchor_a
                anchor_a = anchor_b
                anchor_b = swap

            for side_pair: Vector2i in side_pairs:
                for tail_directions: Vector2i in tail_direction_pairs:
                    var candidate: Array[Dictionary] = []
                    candidate.append(_build_rural_scattered_lane(request, 0, spine, anchor_a, side_pair.x, tail_directions.x, width, first_leg, tail_leg))
                    candidate.append(_build_rural_scattered_lane(request, 1, spine, anchor_b, side_pair.y, tail_directions.y, width, first_leg, tail_leg))
                    if candidate[0].is_empty() or candidate[1].is_empty():
                        continue
                    if not _local_roads_legal(candidate, request, inherited_roads, reservations):
                        continue
                    if _roads_share_corridor_cells(candidate[0], candidate[1]):
                        continue
                    return {"ok": true, "failure_reason": "", "roads": candidate}

    if not found_anchor_set:
        return {"ok": false, "failure_reason": "rural_scattered_branch_anchors_insufficient", "roads": []}
    if not found_branch_pair:
        return {"ok": false, "failure_reason": "rural_scattered_branch_pair_unresolved", "roads": []}
    return {"ok": false, "failure_reason": "rural_scattered_lane_layout_unresolved", "roads": []}

func _rural_scattered_spine_candidates(roads: Array[Dictionary], center: Vector2i) -> Array[Dictionary]:
    var candidates: Array[Dictionary] = []
    for road: Dictionary in roads:
        var axis: StringName = StringName(road.get("axis", &""))
        if axis == &"horizontal" or axis == &"vertical":
            candidates.append(road)
    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var a_contains_center: bool = _point_on_road_path(center, a)
        var b_contains_center: bool = _point_on_road_path(center, b)
        if a_contains_center != b_contains_center:
            return a_contains_center
        var a_distance: int = _distance_to_road_path(center, a)
        var b_distance: int = _distance_to_road_path(center, b)
        if a_distance != b_distance:
            return a_distance < b_distance
        var a_class_rank: int = _road_class_rank(StringName(a.get("road_class", &"")))
        var b_class_rank: int = _road_class_rank(StringName(b.get("road_class", &"")))
        if a_class_rank != b_class_rank:
            return a_class_rank < b_class_rank
        return String(a.get("road_id", "")) < String(b.get("road_id", ""))
    )
    return candidates

func _rural_scattered_branch_anchors(
    request: AreaGenerationRequest,
    spine: Dictionary,
    inherited_roads: Array[Dictionary],
    branch_margin: int,
    width: int
) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var path: Array = spine.get("path_cells", [])
    if path.is_empty():
        return result
    var start: Vector2i = spine.get("start", Vector2i.ZERO)
    var finish: Vector2i = spine.get("end", Vector2i.ZERO)
    var radius: int = width / 2
    var safe_bounds := Rect2i(
        request.bounds.position + Vector2i(radius + 2, radius + 2),
        request.bounds.size - Vector2i((radius + 2) * 2, (radius + 2) * 2)
    )
    for value: Variant in path:
        if typeof(value) != TYPE_VECTOR2I:
            continue
        var cell: Vector2i = value
        if not safe_bounds.has_point(cell):
            continue
        if absi(cell.x - start.x) + absi(cell.y - start.y) < branch_margin:
            continue
        if absi(cell.x - finish.x) + absi(cell.y - finish.y) < branch_margin:
            continue
        if _cell_on_other_inherited_road(cell, spine, inherited_roads):
            continue
        result.append(cell)
    result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        return a.y < b.y or (a.y == b.y and a.x < b.x)
    )
    return result

func _build_rural_scattered_lane(
    request: AreaGenerationRequest,
    ordinal: int,
    spine: Dictionary,
    anchor: Vector2i,
    side: int,
    tail_direction: int,
    width: int,
    first_leg: int,
    tail_leg: int
) -> Dictionary:
    var axis: StringName = StringName(spine.get("axis", &""))
    var first: Vector2i = anchor
    var finish: Vector2i = anchor
    if axis == &"horizontal":
        first = anchor + Vector2i(0, side * first_leg)
        finish = first + Vector2i(tail_direction * tail_leg, 0)
    elif axis == &"vertical":
        first = anchor + Vector2i(side * first_leg, 0)
        finish = first + Vector2i(0, tail_direction * tail_leg)
    else:
        return {}

    var waypoints: Array[Vector2i] = [anchor, first, finish]
    for point: Vector2i in waypoints:
        if not request.bounds.has_point(point) or AreaGenerationRequest._is_boundary_cell(request.bounds, point):
            return {}
    var path_cells: Array[Vector2i] = _polyline_cells(waypoints)
    if path_cells.is_empty() or not _path_has_full_corridor_inside(path_cells, width, request.bounds):
        return {}
    var corridor_cells: Array[Vector2i] = _polyline_corridor(path_cells, width, request.bounds)
    if corridor_cells.is_empty():
        return {}
    return {
        "road_id": "%s.road.local.rural.%02d" % [request.area_id, ordinal],
        "road_class": &"local_rural",
        "start": anchor,
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
        "rural_scattered_lane": true,
    }

func _path_has_full_corridor_inside(path_cells: Array[Vector2i], width: int, bounds: Rect2i) -> bool:
    var radius: int = width / 2
    for cell: Vector2i in path_cells:
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if not bounds.has_point(cell + Vector2i(dx, dy)):
                    return false
    return true

func _cell_on_other_inherited_road(cell: Vector2i, spine: Dictionary, roads: Array[Dictionary]) -> bool:
    var spine_id: String = String(spine.get("road_id", ""))
    for road: Dictionary in roads:
        if String(road.get("road_id", "")) == spine_id:
            continue
        if _point_on_road_path(cell, road):
            return true
    return false

func _roads_share_corridor_cells(a: Dictionary, b: Dictionary) -> bool:
    var cells: Dictionary = {}
    for value: Variant in a.get("corridor_cells", []):
        if typeof(value) == TYPE_VECTOR2I:
            cells[value] = true
    for value: Variant in b.get("corridor_cells", []):
        if typeof(value) == TYPE_VECTOR2I and cells.has(value):
            return true
    return false

func _distance_to_road_path(point: Vector2i, road: Dictionary) -> int:
    var best: int = 2147483647
    for value: Variant in road.get("path_cells", []):
        if typeof(value) != TYPE_VECTOR2I:
            continue
        var cell: Vector2i = value
        best = mini(best, absi(cell.x - point.x) + absi(cell.y - point.y))
    return best

func _road_class_rank(road_class: StringName) -> int:
    if road_class == &"primary":
        return 0
    if road_class == &"secondary":
        return 1
    return 2

func _axis_coordinate(cell: Vector2i, axis: StringName) -> int:
    return cell.x if axis == &"horizontal" else cell.y

func _local_roads_legal(
    local_roads: Array[Dictionary],
    request: AreaGenerationRequest,
    inherited_roads: Array[Dictionary],
    reservations: Array[Dictionary]
) -> bool:
    for road: Dictionary in local_roads:
        for cell_value: Variant in road.get("corridor_cells", []):
            if typeof(cell_value) != TYPE_VECTOR2I:
                return false
            var cell: Vector2i = cell_value
            if not request.bounds.has_point(cell):
                return false
            for reservation: Dictionary in reservations:
                if not bool(reservation.get("blocks_local_roads", false)):
                    continue
                var rect: Rect2i = reservation.get("rect", Rect2i())
                if rect.has_point(cell):
                    return false
        for inherited: Dictionary in inherited_roads:
            if _positive_length_collinear_overlap(road, inherited):
                return false
    return true

func _positive_length_collinear_overlap(a: Dictionary, b: Dictionary) -> bool:
    var a_start: Vector2i = a.get("start", Vector2i.ZERO)
    var a_end: Vector2i = a.get("end", Vector2i.ZERO)
    var b_start: Vector2i = b.get("start", Vector2i.ZERO)
    var b_end: Vector2i = b.get("end", Vector2i.ZERO)
    if a_start.y == a_end.y and b_start.y == b_end.y and a_start.y == b_start.y:
        var overlap_min_x: int = maxi(mini(a_start.x, a_end.x), mini(b_start.x, b_end.x))
        var overlap_max_x: int = mini(maxi(a_start.x, a_end.x), maxi(b_start.x, b_end.x))
        return overlap_max_x > overlap_min_x
    if a_start.x == a_end.x and b_start.x == b_end.x and a_start.x == b_start.x:
        var overlap_min_y: int = maxi(mini(a_start.y, a_end.y), mini(b_start.y, b_end.y))
        var overlap_max_y: int = mini(maxi(a_start.y, a_end.y), maxi(b_start.y, b_end.y))
        return overlap_max_y > overlap_min_y
    return false

func _point_on_road_path(point: Vector2i, road: Dictionary) -> bool:
    for value: Variant in road.get("path_cells", []):
        if typeof(value) == TYPE_VECTOR2I and value == point:
            return true
    return false

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
