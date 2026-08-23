extends RefCounted
class_name TownBlockPlanner

func plan(
    request: AreaGenerationRequest,
    profile: Dictionary,
    roads: Array[Dictionary],
    reservations: Array[Dictionary]
) -> Dictionary:
    var blocks: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty() or roads.is_empty():
        return {"ok": false, "failure_reason": "invalid_town_block_planner_input", "blocks": blocks}
    if StringName(profile.get("road_layout", &"")) != &"smalltown_grid":
        return {"ok": true, "failure_reason": "", "blocks": blocks}

    var spine: Dictionary = _road_by_flag(roads, "town_spine")
    var cross_a: Dictionary = _road_by_role(roads, &"town_cross_negative")
    var cross_b: Dictionary = _road_by_role(roads, &"town_cross_positive")
    var back_a: Dictionary = _road_by_role(roads, &"town_back_negative")
    var back_b: Dictionary = _road_by_role(roads, &"town_back_positive")
    if spine.is_empty() or cross_a.is_empty() or cross_b.is_empty() or back_a.is_empty() or back_b.is_empty():
        return {"ok": false, "failure_reason": "smalltown_block_street_roles_missing", "blocks": blocks}

    var axis: StringName = StringName(spine.get("axis", &""))
    var center := Vector2i(
        request.bounds.position.x + request.bounds.size.x / 2,
        request.bounds.position.y + request.bounds.size.y / 2
    )
    var half_extent: int = int(profile.get("town_core_half_extent", 92))
    var min_span: int = int(profile.get("town_block_min_span", 12))
    var candidates: Array[Rect2i] = []

    if axis == &"horizontal":
        var cross_a_start: Vector2i = cross_a.get("start", center)
        var cross_b_start: Vector2i = cross_b.get("start", center)
        var x1: int = mini(cross_a_start.x, cross_b_start.x)
        var x2: int = maxi(cross_a_start.x, cross_b_start.x)
        var cross_half: int = maxi(int(cross_a.get("width", 3)), int(cross_b.get("width", 3))) / 2
        var spine_start: Vector2i = spine.get("start", center)
        var spine_y: int = spine_start.y
        var spine_half: int = int(spine.get("width", 1)) / 2
        var back_a_start: Vector2i = back_a.get("start", center)
        var back_b_start: Vector2i = back_b.get("start", center)
        var north_y: int = mini(back_a_start.y, back_b_start.y)
        var south_y: int = maxi(back_a_start.y, back_b_start.y)
        var back_half: int = maxi(int(back_a.get("width", 3)), int(back_b.get("width", 3))) / 2
        var x_start: int = x1 + cross_half + 1
        var x_end: int = x2 - cross_half - 1
        candidates.append(_rect_from_inclusive(x_start, north_y + back_half + 1, x_end, spine_y - spine_half - 1))
        candidates.append(_rect_from_inclusive(x_start, spine_y + spine_half + 1, x_end, south_y - back_half - 1))
    elif axis == &"vertical":
        var cross_a_start: Vector2i = cross_a.get("start", center)
        var cross_b_start: Vector2i = cross_b.get("start", center)
        var y1: int = mini(cross_a_start.y, cross_b_start.y)
        var y2: int = maxi(cross_a_start.y, cross_b_start.y)
        var cross_half: int = maxi(int(cross_a.get("width", 3)), int(cross_b.get("width", 3))) / 2
        var spine_start: Vector2i = spine.get("start", center)
        var spine_x: int = spine_start.x
        var spine_half: int = int(spine.get("width", 1)) / 2
        var back_a_start: Vector2i = back_a.get("start", center)
        var back_b_start: Vector2i = back_b.get("start", center)
        var west_x: int = mini(back_a_start.x, back_b_start.x)
        var east_x: int = maxi(back_a_start.x, back_b_start.x)
        var back_half: int = maxi(int(back_a.get("width", 3)), int(back_b.get("width", 3))) / 2
        var y_start: int = y1 + cross_half + 1
        var y_end: int = y2 - cross_half - 1
        candidates.append(_rect_from_inclusive(west_x + back_half + 1, y_start, spine_x - spine_half - 1, y_end))
        candidates.append(_rect_from_inclusive(spine_x + spine_half + 1, y_start, east_x - back_half - 1, y_end))
    else:
        return {"ok": false, "failure_reason": "smalltown_block_spine_axis_invalid", "blocks": blocks}

    var core_rect := Rect2i(
        center - Vector2i(half_extent, half_extent),
        Vector2i(half_extent * 2 + 1, half_extent * 2 + 1)
    )
    var carved_candidates: Array[Rect2i] = []
    for candidate: Rect2i in candidates:
        if candidate.size.x <= 0 or candidate.size.y <= 0:
            continue
        var pieces: Array[Rect2i] = [candidate]
        for reservation: Dictionary in reservations:
            if not bool(reservation.get("blocks_parcels", false)):
                continue
            pieces = _subtract_rect_from_pieces(pieces, reservation.get("rect", Rect2i()))
        for piece: Rect2i in pieces:
            carved_candidates.append(piece)

    carved_candidates.sort_custom(func(a: Rect2i, b: Rect2i) -> bool:
        if a.position.y != b.position.y:
            return a.position.y < b.position.y
        if a.position.x != b.position.x:
            return a.position.x < b.position.x
        if a.size.y != b.size.y:
            return a.size.y < b.size.y
        return a.size.x < b.size.x
    )

    var ordinal: int = 0
    for rect: Rect2i in carved_candidates:
        if rect.size.x < min_span or rect.size.y < min_span:
            continue
        if not _rect_inside(request.bounds, rect) or not _rect_inside(core_rect, rect):
            continue
        if _rect_intersects_blocking_reservation(rect, reservations):
            continue
        if _rect_contains_road_cell(rect, roads):
            continue
        blocks.append({
            "id": "%s.block.%02d" % [request.area_id, ordinal],
            "kind": &"town_block",
            "rect": rect,
        })
        ordinal += 1

    if blocks.size() < 2:
        return {"ok": false, "failure_reason": "smalltown_blocks_insufficient", "blocks": blocks}
    return {"ok": true, "failure_reason": "", "blocks": blocks}

func _subtract_rect_from_pieces(pieces: Array[Rect2i], cutter: Rect2i) -> Array[Rect2i]:
    if cutter.size.x <= 0 or cutter.size.y <= 0:
        return pieces
    var result: Array[Rect2i] = []
    for piece: Rect2i in pieces:
        if not _rects_intersect(piece, cutter):
            result.append(piece)
            continue
        var intersection: Rect2i = piece.intersection(cutter)
        if intersection.size.x <= 0 or intersection.size.y <= 0:
            result.append(piece)
            continue

        var piece_right: int = piece.position.x + piece.size.x
        var piece_bottom: int = piece.position.y + piece.size.y
        var cut_right: int = intersection.position.x + intersection.size.x
        var cut_bottom: int = intersection.position.y + intersection.size.y

        var top_height: int = intersection.position.y - piece.position.y
        if top_height > 0:
            result.append(Rect2i(piece.position, Vector2i(piece.size.x, top_height)))
        var bottom_height: int = piece_bottom - cut_bottom
        if bottom_height > 0:
            result.append(Rect2i(Vector2i(piece.position.x, cut_bottom), Vector2i(piece.size.x, bottom_height)))

        var middle_height: int = intersection.size.y
        var left_width: int = intersection.position.x - piece.position.x
        if left_width > 0 and middle_height > 0:
            result.append(Rect2i(Vector2i(piece.position.x, intersection.position.y), Vector2i(left_width, middle_height)))
        var right_width: int = piece_right - cut_right
        if right_width > 0 and middle_height > 0:
            result.append(Rect2i(Vector2i(cut_right, intersection.position.y), Vector2i(right_width, middle_height)))
    return result

func _road_by_flag(roads: Array[Dictionary], key: String) -> Dictionary:
    for road: Dictionary in roads:
        if bool(road.get(key, false)):
            return road
    return {}

func _road_by_role(roads: Array[Dictionary], role: StringName) -> Dictionary:
    for road: Dictionary in roads:
        if StringName(road.get("town_role", &"")) == role:
            return road
    return {}

func _rect_from_inclusive(min_x: int, min_y: int, max_x: int, max_y: int) -> Rect2i:
    if max_x < min_x or max_y < min_y:
        return Rect2i()
    return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))

func _rect_contains_road_cell(rect: Rect2i, roads: Array[Dictionary]) -> bool:
    for road: Dictionary in roads:
        for value: Variant in road.get("corridor_cells", []):
            if typeof(value) == TYPE_VECTOR2I and rect.has_point(value):
                return true
    return false

func _rect_intersects_blocking_reservation(rect: Rect2i, reservations: Array[Dictionary]) -> bool:
    for reservation: Dictionary in reservations:
        if not bool(reservation.get("blocks_parcels", false)):
            continue
        if _rects_intersect(rect, reservation.get("rect", Rect2i())):
            return true
    return false

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var inner_max := Vector2i(inner.position.x + inner.size.x - 1, inner.position.y + inner.size.y - 1)
    return outer.has_point(inner.position) and outer.has_point(inner_max)

func _rects_intersect(a: Rect2i, b: Rect2i) -> bool:
    if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0:
        return false
    return a.position.x < b.position.x + b.size.x \
        and a.position.x + a.size.x > b.position.x \
        and a.position.y < b.position.y + b.size.y \
        and a.position.y + a.size.y > b.position.y
