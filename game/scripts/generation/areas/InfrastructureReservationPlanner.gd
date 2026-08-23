extends RefCounted
class_name InfrastructureReservationPlanner

const Seed = preload("res://scripts/generation/areas/AreaSeed.gd")

const INVALID_CELL := Vector2i(-999999, -999999)

func plan(
    request: AreaGenerationRequest,
    profile: Dictionary,
    inherited_roads: Array[Dictionary]
) -> Dictionary:
    var reservations: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty() or inherited_roads.is_empty():
        return {"ok": false, "failure_reason": "invalid_infrastructure_reservation_input", "reservations": reservations}

    for constraint: Dictionary in request.inherited_planning_constraints:
        var role: StringName = StringName(constraint.get("reservation_role", &""))
        if role == &"service":
            continue
        var reservation: Dictionary = {}
        if role == &"corridor":
            reservation = _corridor_reservation(request, constraint, reservations.size())
        elif role == &"facility":
            reservation = _facility_reservation(request, profile, inherited_roads, reservations, constraint, reservations.size())
        if reservation.is_empty():
            return {
                "ok": false,
                "failure_reason": "infrastructure_reservation_unresolved:%s" % String(constraint.get("id", "unknown")),
                "reservations": reservations,
            }
        reservations.append(reservation)

    return {"ok": true, "failure_reason": "", "reservations": reservations}

func _corridor_reservation(
    request: AreaGenerationRequest,
    constraint: Dictionary,
    ordinal: int
) -> Dictionary:
    var start: Vector2i = constraint.get("start", INVALID_CELL)
    var finish: Vector2i = constraint.get("end", INVALID_CELL)
    var width: int = maxi(1, int(constraint.get("width", 1)))
    var rect: Rect2i = _corridor_rect(start, finish, width)
    if rect.size.x <= 0 or rect.size.y <= 0 or not _rect_inside(request.bounds, rect):
        return {}
    return _reservation_record(request, constraint, ordinal, rect)

func _facility_reservation(
    request: AreaGenerationRequest,
    profile: Dictionary,
    inherited_roads: Array[Dictionary],
    existing: Array[Dictionary],
    constraint: Dictionary,
    ordinal: int
) -> Dictionary:
    var source_cell: Vector2i = constraint.get("cell", INVALID_CELL)
    var size: Vector2i = _facility_size(profile, constraint)
    if source_cell == INVALID_CELL or size.x <= 0 or size.y <= 0:
        return {}

    var candidates: Array[Dictionary] = []
    for road: Dictionary in inherited_roads:
        if not _point_on_road(source_cell, road):
            continue
        var road_candidates: Array[Rect2i] = _candidate_facility_rects(
            source_cell,
            road,
            size,
            int(profile.get("reservation_road_gap", 2))
        )
        for rect: Rect2i in road_candidates:
            if not _facility_rect_legal(request, inherited_roads, existing, rect):
                continue
            candidates.append({
                "rect": rect,
                "road_id": String(road.get("road_id", "")),
            })

    if candidates.is_empty():
        return {}
    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var a_rect: Rect2i = a.get("rect", Rect2i())
        var b_rect: Rect2i = b.get("rect", Rect2i())
        if a_rect.position.y != b_rect.position.y:
            return a_rect.position.y < b_rect.position.y
        if a_rect.position.x != b_rect.position.x:
            return a_rect.position.x < b_rect.position.x
        return String(a.get("road_id", "")) < String(b.get("road_id", ""))
    )
    var index: int = Seed.choose_index(
        request.seed,
        "infrastructure_reservation:%s" % String(constraint.get("id", "")),
        candidates.size()
    )
    if index < 0:
        return {}
    var chosen: Dictionary = candidates[index]
    var reservation: Dictionary = _reservation_record(request, constraint, ordinal, chosen.get("rect", Rect2i()))
    reservation["source_road_id"] = String(chosen.get("road_id", ""))
    reservation["source_cell"] = source_cell
    return reservation

func _facility_size(profile: Dictionary, constraint: Dictionary) -> Vector2i:
    var domain: StringName = StringName(constraint.get("domain", &""))
    var kind: StringName = StringName(constraint.get("kind", &""))
    if domain == &"power" and kind == &"substation":
        return profile.get("reservation_substation_size", Vector2i(14, 12))
    if domain == &"potable_water" and kind == &"groundwater_source":
        return profile.get("reservation_groundwater_source_size", Vector2i(12, 12))
    if domain == &"potable_water" and kind == &"treatment_storage":
        return profile.get("reservation_water_treatment_size", Vector2i(16, 16))
    if domain == &"wastewater" and kind == &"treatment_disposal":
        return profile.get("reservation_wastewater_treatment_size", Vector2i(20, 16))
    return Vector2i.ZERO

func _candidate_facility_rects(
    source_cell: Vector2i,
    road: Dictionary,
    size: Vector2i,
    gap: int
) -> Array[Rect2i]:
    var result: Array[Rect2i] = []
    var start: Vector2i = road.get("start", INVALID_CELL)
    var finish: Vector2i = road.get("end", INVALID_CELL)
    var width: int = maxi(1, int(road.get("width", 1)))
    var half_width: int = width / 2
    var safe_gap: int = maxi(0, gap)
    if start == INVALID_CELL or finish == INVALID_CELL:
        return result

    if start.y == finish.y:
        var x: int = source_cell.x - size.x / 2
        var north_bottom: int = start.y - half_width - safe_gap - 1
        var south_top: int = start.y + half_width + safe_gap + 1
        result.append(Rect2i(Vector2i(x, north_bottom - size.y + 1), size))
        result.append(Rect2i(Vector2i(x, south_top), size))
    elif start.x == finish.x:
        var y: int = source_cell.y - size.y / 2
        var west_right: int = start.x - half_width - safe_gap - 1
        var east_left: int = start.x + half_width + safe_gap + 1
        result.append(Rect2i(Vector2i(west_right - size.x + 1, y), size))
        result.append(Rect2i(Vector2i(east_left, y), size))
    return result

func _facility_rect_legal(
    request: AreaGenerationRequest,
    roads: Array[Dictionary],
    existing: Array[Dictionary],
    rect: Rect2i
) -> bool:
    if not _rect_inside(request.bounds, rect):
        return false
    for forbidden: Rect2i in request.forbidden_regions:
        if _rects_intersect(rect, forbidden):
            return false
    for road: Dictionary in roads:
        var road_rect: Rect2i = _corridor_rect(
            road.get("start", INVALID_CELL),
            road.get("end", INVALID_CELL),
            maxi(1, int(road.get("width", 1)))
        )
        if _rects_intersect(rect, road_rect):
            return false
    for reservation: Dictionary in existing:
        var existing_rect: Rect2i = reservation.get("rect", Rect2i())
        if existing_rect.size.x <= 0 or existing_rect.size.y <= 0:
            continue
        var existing_role: StringName = StringName(reservation.get("reservation_role", &""))
        if existing_role == &"facility" or bool(reservation.get("blocks_local_roads", false)):
            if _rects_intersect(rect, existing_rect):
                return false
    return true

func _reservation_record(
    request: AreaGenerationRequest,
    constraint: Dictionary,
    ordinal: int,
    rect: Rect2i
) -> Dictionary:
    return {
        "id": "%s.reservation.%03d" % [request.area_id, ordinal],
        "source_id": String(constraint.get("source_id", constraint.get("id", ""))),
        "constraint_id": String(constraint.get("id", "")),
        "domain": StringName(constraint.get("domain", &"")),
        "kind": StringName(constraint.get("kind", &"")),
        "reservation_role": StringName(constraint.get("reservation_role", &"")),
        "rect": rect,
        "blocks_parcels": bool(constraint.get("blocks_parcels", false)),
        "blocks_local_roads": bool(constraint.get("blocks_local_roads", false)),
        "settlement_id": String(constraint.get("settlement_id", "")),
        "network_id": String(constraint.get("network_id", "")),
    }

func _point_on_road(point: Vector2i, road: Dictionary) -> bool:
    var start: Vector2i = road.get("start", INVALID_CELL)
    var finish: Vector2i = road.get("end", INVALID_CELL)
    if start == INVALID_CELL or finish == INVALID_CELL:
        return false
    if start.y == finish.y:
        return point.y == start.y and point.x >= mini(start.x, finish.x) and point.x <= maxi(start.x, finish.x)
    if start.x == finish.x:
        return point.x == start.x and point.y >= mini(start.y, finish.y) and point.y <= maxi(start.y, finish.y)
    return false

func _corridor_rect(start: Vector2i, finish: Vector2i, width: int) -> Rect2i:
    if start == INVALID_CELL or finish == INVALID_CELL or start == finish or width <= 0:
        return Rect2i()
    var half_width: int = width / 2
    if start.y == finish.y:
        var min_x: int = mini(start.x, finish.x)
        var max_x: int = maxi(start.x, finish.x)
        return Rect2i(Vector2i(min_x, start.y - half_width), Vector2i(max_x - min_x + 1, width))
    if start.x == finish.x:
        var min_y: int = mini(start.y, finish.y)
        var max_y: int = maxi(start.y, finish.y)
        return Rect2i(Vector2i(start.x - half_width, min_y), Vector2i(width, max_y - min_y + 1))
    return Rect2i()

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
