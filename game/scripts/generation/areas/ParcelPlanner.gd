extends RefCounted
class_name ParcelPlanner

const Seed = preload("res://scripts/generation/areas/AreaSeed.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

func plan(
    request: AreaGenerationRequest,
    profile: Dictionary,
    roads: Array[Dictionary],
    intersections: Array[Dictionary],
    reservations: Array[Dictionary] = []
) -> Dictionary:
    var parcels: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty() or roads.is_empty() or intersections.is_empty():
        return {"ok": false, "failure_reason": "invalid_parcel_planner_input", "parcels": parcels}

    var land_use_mode: StringName = StringName(profile.get("land_use_mode", &"rural_crossroads"))
    var center: Vector2i = intersections[0].get("cell", request.bounds.get_center())
    if land_use_mode == &"smalltown_center" or land_use_mode == &"rural_scattered":
        center = Vector2i(
            request.bounds.position.x + request.bounds.size.x / 2,
            request.bounds.position.y + request.bounds.size.y / 2
        )
    var road_cells: Dictionary = _road_cell_set(roads)
    var frontage_roads: Array[Dictionary] = roads
    if land_use_mode == &"rural_scattered":
        frontage_roads = _rural_scattered_frontage_order(roads)
    for road: Dictionary in frontage_roads:
        if not bool(road.get("parcel_frontage_enabled", true)):
            continue
        _append_road_frontage_parcels(request, profile, road, center, road_cells, parcels)

    if not reservations.is_empty():
        _remove_blocked_parcels(parcels, reservations)

    var required_total: int = int(profile.get("commercial_count", 0)) + int(profile.get("residential_count", 0)) + int(profile.get("farmstead_count", 0))
    if parcels.size() < required_total:
        return {"ok": false, "failure_reason": "insufficient_parcel_candidates", "parcels": parcels}
    var required_local: int = int(profile.get("local_residential_target", 0)) + int(profile.get("local_farmstead_target", 0))
    var local_frontage_class: StringName = StringName(profile.get("local_frontage_road_class", &"local_rural"))
    if _count_road_class_candidates(parcels, local_frontage_class) < required_local:
        return {"ok": false, "failure_reason": "insufficient_local_road_parcel_candidates", "parcels": parcels}

    if land_use_mode == &"smalltown_center":
        _classify_smalltown_land_use(request.seed, profile, center, parcels)
    elif land_use_mode == &"rural_scattered":
        _classify_rural_scattered_land_use(request.seed, profile, center, parcels)
    else:
        _classify_rural_land_use(request.seed, profile, center, parcels)
    if _count_land_use(parcels, &"commercial_small") != int(profile.get("commercial_count", 0)) \
        or _count_land_use(parcels, &"residential") != int(profile.get("residential_count", 0)) \
        or _count_land_use(parcels, &"farmstead") != int(profile.get("farmstead_count", 0)):
        return {"ok": false, "failure_reason": "land_use_targets_unmet", "parcels": parcels}
    return {"ok": true, "failure_reason": "", "parcels": parcels}

func _rural_scattered_frontage_order(roads: Array[Dictionary]) -> Array[Dictionary]:
    var ordered: Array[Dictionary] = []
    for road: Dictionary in roads:
        if StringName(road.get("road_class", &"")) == &"local_rural":
            ordered.append(road)
    for road: Dictionary in roads:
        if StringName(road.get("road_class", &"")) != &"local_rural":
            ordered.append(road)
    return ordered

func _append_road_frontage_parcels(
    request: AreaGenerationRequest,
    profile: Dictionary,
    road: Dictionary,
    center: Vector2i,
    road_cells: Dictionary,
    parcels: Array[Dictionary]
) -> void:
    var axis: StringName = StringName(road.get("axis", &""))
    var road_class: StringName = StringName(road.get("road_class", &""))
    if (axis == &"horizontal" or axis == &"vertical") and road_class == &"local_town":
        _append_local_straight_frontage(request, profile, road, center, road_cells, parcels)
        return
    if axis == &"horizontal" or axis == &"vertical":
        _append_inherited_straight_frontage(request, profile, road, center, road_cells, parcels)
        return
    if axis == &"polyline":
        _append_polyline_frontage(request, profile, road, center, road_cells, parcels)

func _append_inherited_straight_frontage(
    request: AreaGenerationRequest,
    profile: Dictionary,
    road: Dictionary,
    center: Vector2i,
    road_cells: Dictionary,
    parcels: Array[Dictionary]
) -> void:
    var road_class: StringName = StringName(road.get("road_class", &""))
    var depth: int = int(profile.get("primary_parcel_depth", 24)) if road_class == &"primary" else int(profile.get("secondary_parcel_depth", 24))
    var radius: int = int(profile.get("center_exclusion_radius", 20))
    var edge_margin: int = int(profile.get("edge_margin", 8))
    var width: int = int(road.get("width", 1))
    var half_width: int = width / 2
    var gap_from_road: int = int(profile.get("parcel_road_gap", 1))
    var minimum: int = int(profile.get("frontage_min", 28))
    var maximum: int = int(profile.get("frontage_max", 36))
    var parcel_gap: int = int(profile.get("parcel_gap", 3))
    var axis: StringName = StringName(road.get("axis", &""))
    var start: Vector2i = road.get("start", Vector2i.ZERO)
    var finish: Vector2i = road.get("end", Vector2i.ZERO)
    var spans: Array[Vector2i] = []

    if axis == &"horizontal":
        var road_min_x: int = maxi(mini(start.x, finish.x), request.bounds.position.x) + edge_margin
        var road_max_x: int = mini(maxi(start.x, finish.x), request.bounds.position.x + request.bounds.size.x - 1) - edge_margin
        spans.append(Vector2i(road_min_x, mini(center.x - radius - 1, road_max_x)))
        spans.append(Vector2i(maxi(center.x + radius + 1, road_min_x), road_max_x))
        var centerline_y: int = start.y
        for side: StringName in [&"north", &"south"]:
            for span: Vector2i in spans:
                _append_axis_segment_parcels(
                    request, profile, road, center, road_cells, parcels,
                    &"horizontal", centerline_y, span.x, span.y, side,
                    depth, half_width, gap_from_road, minimum, maximum, parcel_gap
                )
        return

    var road_min_y: int = maxi(mini(start.y, finish.y), request.bounds.position.y) + edge_margin
    var road_max_y: int = mini(maxi(start.y, finish.y), request.bounds.position.y + request.bounds.size.y - 1) - edge_margin
    spans.append(Vector2i(road_min_y, mini(center.y - radius - 1, road_max_y)))
    spans.append(Vector2i(maxi(center.y + radius + 1, road_min_y), road_max_y))
    var centerline_x: int = start.x
    for side: StringName in [&"west", &"east"]:
        for span: Vector2i in spans:
            _append_axis_segment_parcels(
                request, profile, road, center, road_cells, parcels,
                &"vertical", centerline_x, span.x, span.y, side,
                depth, half_width, gap_from_road, minimum, maximum, parcel_gap
            )

func _append_local_straight_frontage(
    request: AreaGenerationRequest,
    profile: Dictionary,
    road: Dictionary,
    center: Vector2i,
    road_cells: Dictionary,
    parcels: Array[Dictionary]
) -> void:
    var start: Vector2i = road.get("start", Vector2i.ZERO)
    var finish: Vector2i = road.get("end", Vector2i.ZERO)
    var axis: StringName = StringName(road.get("axis", &""))
    var depth: int = int(profile.get("local_parcel_depth", 22))
    var half_width: int = int(road.get("width", 3)) / 2
    var gap_from_road: int = int(profile.get("parcel_road_gap", 1))
    var minimum: int = int(profile.get("local_frontage_min", 23))
    var maximum: int = int(profile.get("local_frontage_max", 28))
    var parcel_gap: int = int(profile.get("parcel_gap", 2))
    var end_margin: int = int(profile.get("local_frontage_end_margin", 5))
    if axis == &"horizontal":
        var span_start: int = mini(start.x, finish.x) + end_margin
        var span_end: int = maxi(start.x, finish.x) - end_margin
        if span_end - span_start + 1 < minimum:
            return
        for side: StringName in [&"north", &"south"]:
            _append_axis_segment_parcels(
                request, profile, road, center, road_cells, parcels,
                &"horizontal", start.y, span_start, span_end, side,
                depth, half_width, gap_from_road, minimum, maximum, parcel_gap
            )
        return
    if axis == &"vertical":
        var span_start: int = mini(start.y, finish.y) + end_margin
        var span_end: int = maxi(start.y, finish.y) - end_margin
        if span_end - span_start + 1 < minimum:
            return
        for side: StringName in [&"west", &"east"]:
            _append_axis_segment_parcels(
                request, profile, road, center, road_cells, parcels,
                &"vertical", start.x, span_start, span_end, side,
                depth, half_width, gap_from_road, minimum, maximum, parcel_gap
            )

func _append_polyline_frontage(
    request: AreaGenerationRequest,
    profile: Dictionary,
    road: Dictionary,
    center: Vector2i,
    road_cells: Dictionary,
    parcels: Array[Dictionary]
) -> void:
    var waypoints: Array = road.get("waypoints", [])
    if waypoints.size() < 2:
        return
    var depth: int = int(profile.get("local_parcel_depth", 20))
    var half_width: int = int(road.get("width", 3)) / 2
    var gap_from_road: int = int(profile.get("parcel_road_gap", 1))
    var minimum: int = int(profile.get("local_frontage_min", 23))
    var maximum: int = int(profile.get("local_frontage_max", 28))
    var parcel_gap: int = int(profile.get("parcel_gap", 3))
    var end_margin: int = int(profile.get("local_frontage_end_margin", 3))

    for segment_index in range(waypoints.size() - 1):
        var start: Vector2i = waypoints[segment_index]
        var finish: Vector2i = waypoints[segment_index + 1]
        if start.x == finish.x:
            var span_start: int = mini(start.y, finish.y) + end_margin
            var span_end: int = maxi(start.y, finish.y) - end_margin
            if span_end - span_start + 1 < minimum:
                continue
            for side: StringName in [&"west", &"east"]:
                _append_axis_segment_parcels(
                    request, profile, road, center, road_cells, parcels,
                    &"vertical", start.x, span_start, span_end, side,
                    depth, half_width, gap_from_road, minimum, maximum, parcel_gap
                )
        elif start.y == finish.y:
            var span_start: int = mini(start.x, finish.x) + end_margin
            var span_end: int = maxi(start.x, finish.x) - end_margin
            if span_end - span_start + 1 < minimum:
                continue
            for side: StringName in [&"north", &"south"]:
                _append_axis_segment_parcels(
                    request, profile, road, center, road_cells, parcels,
                    &"horizontal", start.y, span_start, span_end, side,
                    depth, half_width, gap_from_road, minimum, maximum, parcel_gap
                )

func _append_axis_segment_parcels(
    request: AreaGenerationRequest,
    profile: Dictionary,
    road: Dictionary,
    center: Vector2i,
    road_cells: Dictionary,
    parcels: Array[Dictionary],
    axis: StringName,
    centerline: int,
    span_start: int,
    span_end: int,
    side: StringName,
    depth: int,
    half_width: int,
    gap_from_road: int,
    minimum: int,
    maximum: int,
    parcel_gap: int
) -> void:
    var segment_rects: Array[Rect2i] = _segment_rects(
        request.seed,
        String(road.get("road_id", "")),
        side,
        span_start,
        span_end,
        axis == &"horizontal",
        depth,
        minimum,
        maximum,
        parcel_gap
    )
    for rect: Rect2i in segment_rects:
        var placed: Rect2i = Rect2i()
        var frontage: int = -1
        if axis == &"horizontal":
            if side == &"north":
                var bottom: int = centerline - half_width - gap_from_road - 1
                placed = Rect2i(Vector2i(rect.position.x, bottom - depth + 1), Vector2i(rect.size.x, depth))
                frontage = Facing.Value.SOUTH
            else:
                var top: int = centerline + half_width + gap_from_road + 1
                placed = Rect2i(Vector2i(rect.position.x, top), Vector2i(rect.size.x, depth))
                frontage = Facing.Value.NORTH
        else:
            if side == &"west":
                var right: int = centerline - half_width - gap_from_road - 1
                placed = Rect2i(Vector2i(right - depth + 1, rect.position.y), Vector2i(depth, rect.size.y))
                frontage = Facing.Value.EAST
            else:
                var left: int = centerline + half_width + gap_from_road + 1
                placed = Rect2i(Vector2i(left, rect.position.y), Vector2i(depth, rect.size.y))
                frontage = Facing.Value.WEST
        _try_append_parcel(request, profile, road, side, frontage, placed, center, road_cells, parcels)

func _segment_rects(
    seed: int,
    road_id: String,
    side: StringName,
    span_start: int,
    span_end: int,
    horizontal: bool,
    depth: int,
    minimum: int,
    maximum: int,
    gap: int
) -> Array[Rect2i]:
    var result: Array[Rect2i] = []
    var cursor: int = span_start
    var ordinal: int = 0
    while cursor + minimum - 1 <= span_end:
        var remaining: int = span_end - cursor + 1
        var domain: String = "parcel_width:%s:%s:%d:%d" % [road_id, String(side), cursor, ordinal]
        var width: int = minimum + Seed.choose_index(seed, domain, maximum - minimum + 1)
        if width > remaining:
            if remaining < minimum:
                break
            width = remaining
        if horizontal:
            result.append(Rect2i(Vector2i(cursor, 0), Vector2i(width, depth)))
        else:
            result.append(Rect2i(Vector2i(0, cursor), Vector2i(depth, width)))
        cursor += width + gap
        ordinal += 1
    return result

func _try_append_parcel(
    request: AreaGenerationRequest,
    profile: Dictionary,
    road: Dictionary,
    side: StringName,
    frontage: int,
    rect: Rect2i,
    center: Vector2i,
    road_cells: Dictionary,
    parcels: Array[Dictionary]
) -> void:
    if not _rect_inside(request.bounds, rect):
        return
    for forbidden: Rect2i in request.forbidden_regions:
        if _rects_intersect(rect, forbidden):
            return
    if _rect_contains_any_cell(rect, road_cells):
        return
    for existing: Dictionary in parcels:
        if _rects_intersect(rect, existing.get("rect", Rect2i())):
            return
    var shrink: int = int(profile.get("parcel_buildable_margin", 1))
    var buildable := Rect2i(
        rect.position + Vector2i(shrink, shrink),
        rect.size - Vector2i(shrink * 2, shrink * 2)
    )
    var center_cell := Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2)
    var role: String = "%s.%s.%d.%d" % [String(road.get("road_id", "road")), String(side), rect.position.x, rect.position.y]
    parcels.append({
        "id": "%s.parcel.%s" % [request.area_id, role],
        "rect": rect,
        "buildable_rect": buildable,
        "land_use": &"unclassified",
        "frontage_road_id": String(road.get("road_id", "")),
        "frontage_road_class": StringName(road.get("road_class", &"")),
        "frontage_side": frontage,
        "side": side,
        "distance_to_center": absi(center_cell.x - center.x) + absi(center_cell.y - center.y),
        "access_cell": Vector2i(-1, -1),
        "parcel_access_cell": Vector2i(-1, -1),
        "driveway_cells": [],
        "parking_cells": [],
        "building_archetype_id": &"",
        "building_envelope": Rect2i(),
        "building_entry_cell": Vector2i(-1, -1),
    })

func _remove_blocked_parcels(parcels: Array[Dictionary], reservations: Array[Dictionary]) -> void:
    for index in range(parcels.size() - 1, -1, -1):
        var rect: Rect2i = parcels[index].get("rect", Rect2i())
        var blocked: bool = false
        for reservation: Dictionary in reservations:
            if not bool(reservation.get("blocks_parcels", false)):
                continue
            if _rects_intersect(rect, reservation.get("rect", Rect2i())):
                blocked = true
                break
        if blocked:
            parcels.remove_at(index)

func _classify_rural_land_use(seed: int, profile: Dictionary, center: Vector2i, parcels: Array[Dictionary]) -> void:
    parcels.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var da: int = int(a.get("distance_to_center", 0))
        var db: int = int(b.get("distance_to_center", 0))
        if da != db:
            return da < db
        return String(a.get("id", "")) < String(b.get("id", ""))
    )

    var commercial_target: int = int(profile.get("commercial_count", 3))
    var commercial_used: int = 0
    for parcel: Dictionary in parcels:
        if commercial_used >= commercial_target:
            break
        if StringName(parcel.get("frontage_road_class", &"")) != &"primary":
            continue
        parcel["land_use"] = &"commercial_small"
        commercial_used += 1

    var residential_target: int = int(profile.get("residential_count", 6))
    var local_residential_target: int = mini(residential_target, int(profile.get("local_residential_target", 0)))
    var residential_used: int = _assign_local_land_use(
        parcels,
        &"residential",
        local_residential_target,
        false,
        StringName(profile.get("local_frontage_road_class", &"local_rural"))
    )
    for parcel: Dictionary in parcels:
        if residential_used >= residential_target:
            break
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        parcel["land_use"] = &"residential"
        residential_used += 1

    var farmstead_target: int = int(profile.get("farmstead_count", 4))
    var local_farmstead_target: int = mini(farmstead_target, int(profile.get("local_farmstead_target", 0)))
    var farmstead_used: int = _assign_local_land_use(
        parcels,
        &"farmstead",
        local_farmstead_target,
        true,
        StringName(profile.get("local_frontage_road_class", &"local_rural"))
    )
    for index in range(parcels.size() - 1, -1, -1):
        if farmstead_used >= farmstead_target:
            break
        var parcel: Dictionary = parcels[index]
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        parcel["land_use"] = &"farmstead"
        farmstead_used += 1

    for parcel: Dictionary in parcels:
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        var choice: int = Seed.choose_index(seed, "open_land:%s" % String(parcel.get("id", "")), 3)
        match choice:
            0:
                parcel["land_use"] = &"agricultural"
            1:
                parcel["land_use"] = &"vacant"
            _:
                parcel["land_use"] = &"wilderness"

func _classify_rural_scattered_land_use(seed: int, profile: Dictionary, center: Vector2i, parcels: Array[Dictionary]) -> void:
    parcels.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var da: int = int(a.get("distance_to_center", 0))
        var db: int = int(b.get("distance_to_center", 0))
        if da != db:
            return da < db
        return String(a.get("id", "")) < String(b.get("id", ""))
    )

    var local_class: StringName = StringName(profile.get("local_frontage_road_class", &"local_rural"))
    var residential_target: int = int(profile.get("residential_count", 4))
    var local_residential_target: int = mini(residential_target, int(profile.get("local_residential_target", 3)))
    var residential_used: int = _assign_local_land_use(parcels, &"residential", local_residential_target, false, local_class)
    for parcel: Dictionary in parcels:
        if residential_used >= residential_target:
            break
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        parcel["land_use"] = &"residential"
        residential_used += 1

    var farmstead_target: int = int(profile.get("farmstead_count", 2))
    var local_farmstead_target: int = mini(farmstead_target, int(profile.get("local_farmstead_target", 1)))
    var farmstead_used: int = _assign_local_land_use(parcels, &"farmstead", local_farmstead_target, true, local_class)
    for index in range(parcels.size() - 1, -1, -1):
        if farmstead_used >= farmstead_target:
            break
        var parcel: Dictionary = parcels[index]
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        parcel["land_use"] = &"farmstead"
        farmstead_used += 1

    var edge_distance: int = int(profile.get("rural_scattered_edge_open_distance", 72))
    for parcel: Dictionary in parcels:
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        var far: bool = int(parcel.get("distance_to_center", 0)) >= edge_distance
        var choice_count: int = 2 if far else 3
        var choice: int = Seed.choose_index(seed, "rural_scattered_open:%s" % String(parcel.get("id", "")), choice_count)
        if far:
            parcel["land_use"] = &"agricultural" if choice == 0 else &"wilderness"
        else:
            parcel["land_use"] = &"agricultural" if choice == 0 else (&"vacant" if choice == 1 else &"wilderness")

func _classify_smalltown_land_use(seed: int, profile: Dictionary, center: Vector2i, parcels: Array[Dictionary]) -> void:
    parcels.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var da: int = int(a.get("distance_to_center", 0))
        var db: int = int(b.get("distance_to_center", 0))
        if da != db:
            return da < db
        return String(a.get("id", "")) < String(b.get("id", ""))
    )

    var commercial_target: int = int(profile.get("commercial_count", 4))
    var residential_target: int = int(profile.get("residential_count", 10))
    var local_class: StringName = StringName(profile.get("local_frontage_road_class", &"local_town"))
    var local_target: int = mini(residential_target, int(profile.get("local_residential_target", 6)))
    var commercial_used: int = 0

    # Main-street frontage is preferred, not mandatory. This is a quota/reserve
    # assignment: consume primary frontage first, then ordinary non-local frontage,
    # and touch local-town frontage only when there is surplus beyond the home reserve.
    for parcel: Dictionary in parcels:
        if commercial_used >= commercial_target:
            break
        if StringName(parcel.get("frontage_road_class", &"")) != &"primary":
            continue
        parcel["land_use"] = &"commercial_small"
        commercial_used += 1

    for parcel: Dictionary in parcels:
        if commercial_used >= commercial_target:
            break
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        var road_class: StringName = StringName(parcel.get("frontage_road_class", &""))
        if road_class == &"primary" or road_class == local_class:
            continue
        parcel["land_use"] = &"commercial_small"
        commercial_used += 1

    for parcel: Dictionary in parcels:
        if commercial_used >= commercial_target:
            break
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        if StringName(parcel.get("frontage_road_class", &"")) != local_class:
            continue
        if _count_unclassified_road_class(parcels, local_class) <= local_target:
            break
        parcel["land_use"] = &"commercial_small"
        commercial_used += 1

    var residential_used: int = _assign_local_land_use(parcels, &"residential", local_target, false, local_class)

    for parcel: Dictionary in parcels:
        if residential_used >= residential_target:
            break
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        if StringName(parcel.get("frontage_road_class", &"")) == &"primary":
            continue
        parcel["land_use"] = &"residential"
        residential_used += 1
    for parcel: Dictionary in parcels:
        if residential_used >= residential_target:
            break
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        parcel["land_use"] = &"residential"
        residential_used += 1

    var edge_distance: int = int(profile.get("town_edge_open_distance", 82))
    for parcel: Dictionary in parcels:
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        if int(parcel.get("distance_to_center", 0)) < edge_distance:
            parcel["land_use"] = &"vacant"
            continue
        var choice: int = Seed.choose_index(seed, "town_open_land:%s" % String(parcel.get("id", "")), 3)
        parcel["land_use"] = &"agricultural" if choice == 0 else (&"wilderness" if choice == 1 else &"vacant")

func _assign_local_land_use(
    parcels: Array[Dictionary],
    land_use: StringName,
    target: int,
    farthest_first: bool,
    road_class: StringName
) -> int:
    if target <= 0:
        return 0
    var candidates: Array[Dictionary] = []
    for parcel: Dictionary in parcels:
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        if StringName(parcel.get("frontage_road_class", &"")) != road_class:
            continue
        candidates.append(parcel)
    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var da: int = int(a.get("distance_to_center", 0))
        var db: int = int(b.get("distance_to_center", 0))
        if da != db:
            return da > db if farthest_first else da < db
        return String(a.get("id", "")) < String(b.get("id", ""))
    )
    var used: int = 0
    for parcel: Dictionary in candidates:
        if used >= target:
            break
        parcel["land_use"] = land_use
        used += 1
    return used

func _count_land_use(parcels: Array[Dictionary], land_use: StringName) -> int:
    var count: int = 0
    for parcel: Dictionary in parcels:
        if StringName(parcel.get("land_use", &"")) == land_use:
            count += 1
    return count

func _count_road_class_candidates(parcels: Array[Dictionary], road_class: StringName) -> int:
    var count: int = 0
    for parcel: Dictionary in parcels:
        if StringName(parcel.get("frontage_road_class", &"")) == road_class:
            count += 1
    return count

func _count_unclassified_road_class(parcels: Array[Dictionary], road_class: StringName) -> int:
    var count: int = 0
    for parcel: Dictionary in parcels:
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        if StringName(parcel.get("frontage_road_class", &"")) == road_class:
            count += 1
    return count

func _road_cell_set(roads: Array[Dictionary]) -> Dictionary:
    var result: Dictionary = {}
    for road: Dictionary in roads:
        for value: Variant in road.get("corridor_cells", []):
            if typeof(value) == TYPE_VECTOR2I:
                result[value] = true
    return result

func _rect_contains_any_cell(rect: Rect2i, cells: Dictionary) -> bool:
    for value: Variant in cells.keys():
        if rect.has_point(value as Vector2i):
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
