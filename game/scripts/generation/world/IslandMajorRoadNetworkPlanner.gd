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
    if request == null or not request.is_valid() or profile.is_empty() or settlements.size() < 2 or geography_cells.is_empty():
        return {"ok": false, "failure_reason": "invalid_island_major_road_planner_input", "road_segments": road_segments}

    var primary_width: int = int(profile.get("primary_width", 5))
    var secondary_width: int = int(profile.get("secondary_width", 3))
    var connected: Dictionary = {0: true}
    var used_edges: Dictionary = {}
    var edge_ordinal: int = 1

    while connected.size() < settlements.size():
        var best: Dictionary = _best_routable_edge(connected, settlements)
        if best.is_empty():
            return {"ok": false, "failure_reason": "island_settlement_road_tree_unresolved", "road_segments": []}
        var from_index: int = int(best.get("from", -1))
        var to_index: int = int(best.get("to", -1))
        if from_index < 0 or to_index < 0:
            return {"ok": false, "failure_reason": "island_settlement_road_edge_invalid", "road_segments": []}
        var from_settlement: Dictionary = settlements[from_index]
        var to_settlement: Dictionary = settlements[to_index]
        var road_class: StringName = _road_class_for_edge(from_settlement, to_settlement)
        var prefix: String = "road.island.network.%03d" % edge_ordinal
        var route_id: String = "route.island.network.%03d" % edge_ordinal
        if not _append_routed_path(
            road_segments,
            prefix,
            road_class,
            route_id,
            from_settlement.get("center", INVALID_CELL),
            to_settlement.get("center", INVALID_CELL),
            secondary_width,
            geography_cells,
            profile
        ):
            return {"ok": false, "failure_reason": "island_settlement_road_edge_failed", "road_segments": []}
        connected[to_index] = true
        used_edges[_edge_key(from_index, to_index)] = true
        edge_ordinal += 1

    # Extra settlement links create alternate journeys without a dense road grid.
    var alternatives: int = 0
    for from_index: int in range(settlements.size()):
        if alternatives >= int(profile.get("island_alternate_road_count", 8)):
            break
        var best_to: int = -1
        var best_distance: int = 2147483647
        var start: Vector2i = settlements[from_index].get("center", INVALID_CELL)
        for to_index: int in range(settlements.size()):
            if from_index == to_index or used_edges.has(_edge_key(from_index, to_index)):
                continue
            var finish: Vector2i = settlements[to_index].get("center", INVALID_CELL)
            var distance: int = absi(start.x - finish.x) + absi(start.y - finish.y)
            if distance < best_distance:
                best_distance = distance
                best_to = to_index
        if best_to < 0:
            continue
        var target: Dictionary = settlements[best_to]
        var road_class: StringName = _road_class_for_edge(settlements[from_index], target)
        var extra: Array[Dictionary] = []
        if _append_routed_path(
            extra,
            "road.island.loop.%03d" % alternatives,
            road_class,
            "route.island.loop.%03d" % alternatives,
            start,
            target.get("center", INVALID_CELL),
            secondary_width,
            geography_cells,
            profile
        ):
            road_segments.append_array(extra)
            used_edges[_edge_key(from_index, best_to)] = true
            alternatives += 1

    var gateway_sources: Dictionary = {}
    var gateway_sides: Array[StringName] = [&"west", &"east", &"north", &"south"]
    for side_index: int in range(gateway_sides.size()):
        var side: StringName = gateway_sides[side_index]
        var source: Dictionary = _settlement_nearest_side(request.bounds, settlements, side)
        if source.is_empty():
            return {"ok": false, "failure_reason": "island_gateway_source_unresolved", "road_segments": []}
        var source_center: Vector2i = source.get("center", INVALID_CELL)
        var gateway: Vector2i = _boundary_gateway(request.bounds, side, source_center, geography_cells, profile)
        if gateway == INVALID_CELL:
            return {"ok": false, "failure_reason": "island_boundary_gateway_unresolved", "road_segments": []}
        var prefix: String = "road.island.gateway.%s" % String(side)
        var route_id: String = "route.island.gateway.%s" % String(side)
        if not _append_routed_path(
            road_segments,
            prefix,
            &"primary",
            route_id,
            source_center,
            gateway,
            primary_width,
            geography_cells,
            profile
        ):
            gateway = _reachable_boundary_gateway(
                request.bounds,
                side,
                source_center,
                gateway,
                geography_cells,
                profile
            )
            if gateway == INVALID_CELL or not _append_routed_path(
                road_segments,
                prefix,
                &"primary",
                route_id,
                source_center,
                gateway,
                primary_width,
                geography_cells,
                profile
            ):
                return {"ok": false, "failure_reason": "island_boundary_gateway_route_failed:%s" % String(side), "road_segments": []}
        gateway_sources[route_id] = source

    if road_segments.is_empty():
        return {"ok": false, "failure_reason": "island_major_road_network_empty", "road_segments": []}
    road_segments = _apply_road_hierarchy(
        road_segments,
        settlements,
        gateway_sources,
        primary_width,
        secondary_width
    )
    return {"ok": true, "failure_reason": "", "road_segments": road_segments}

func _apply_road_hierarchy(
    roads: Array[Dictionary],
    settlements: Array[Dictionary],
    gateway_sources: Dictionary,
    primary_width: int,
    secondary_width: int
) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var freeway_sides: Dictionary = _freeway_gateway_sides(settlements)
    var gateway_progress: Dictionary = {}

    for source_road: Dictionary in roads:
        var route_id: String = String(source_road.get("route_id", ""))
        if route_id.begins_with("route.island.gateway."):
            var side: StringName = StringName(route_id.substr("route.island.gateway.".length()))
            if not freeway_sides.has(side):
                result.append(_styled_road(source_road, &"two_lane", secondary_width))
                continue

            var source_settlement: Dictionary = gateway_sources.get(route_id, {})
            var approach_length: int = maxi(96, int(source_settlement.get("influence_radius", 160)))
            var traveled: int = int(gateway_progress.get(route_id, 0))
            var segment_length: int = _road_segment_length(source_road)
            var approach_remaining: int = approach_length - traveled

            if approach_remaining <= 0:
                result.append(_styled_road(source_road, &"four_lane", primary_width))
            elif approach_remaining >= segment_length:
                result.append(_styled_road(source_road, &"two_lane", secondary_width))
            else:
                result.append_array(_split_gateway_transition(
                    source_road,
                    approach_remaining,
                    primary_width,
                    secondary_width
                ))
            gateway_progress[route_id] = traveled + segment_length
            continue

        var road_class: StringName = StringName(source_road.get("road_class", &""))
        if road_class == &"primary":
            # Towns and one-light crossroads are served by ordinary paved two-lane roads.
            result.append(_styled_road(source_road, &"two_lane", secondary_width))
        elif route_id.begins_with("route.island.loop."):
            # Alternate rural links behave like local/farm access rather than another county highway.
            result.append(_styled_road(source_road, &"dirt", secondary_width))
        else:
            # The settlement tree is the dependable secondary rural network.
            result.append(_styled_road(source_road, &"gravel", secondary_width))

    return result

func _freeway_gateway_sides(settlements: Array[Dictionary]) -> Dictionary:
    var smalltowns: Array[Dictionary] = []
    for settlement: Dictionary in settlements:
        if StringName(settlement.get("kind", &"")) == &"smalltown":
            smalltowns.append(settlement)
    if smalltowns.size() < 2:
        return {&"west": true, &"east": true}

    smalltowns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("id", "")) < String(b.get("id", ""))
    )
    var first: Vector2i = smalltowns[0].get("center", INVALID_CELL)
    var second: Vector2i = smalltowns[1].get("center", INVALID_CELL)
    var dx: int = absi(second.x - first.x)
    var dy: int = absi(second.y - first.y)
    if dx >= dy:
        return {&"west": true, &"east": true}
    return {&"north": true, &"south": true}

func _split_gateway_transition(
    source_road: Dictionary,
    approach_length: int,
    primary_width: int,
    secondary_width: int
) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var start: Vector2i = source_road.get("start", INVALID_CELL)
    var finish: Vector2i = source_road.get("end", INVALID_CELL)
    var split_cell: Vector2i = _point_along_cardinal_segment(start, finish, approach_length)
    if split_cell == INVALID_CELL or split_cell == start or split_cell == finish:
        result.append(_styled_road(source_road, &"two_lane", secondary_width))
        return result

    var road_id: String = String(source_road.get("road_id", "road.island.gateway"))
    var approach: Dictionary = source_road.duplicate(true)
    approach["road_id"] = "%s.approach" % road_id
    approach["end"] = split_cell
    result.append(_styled_road(approach, &"two_lane", secondary_width))

    var freeway: Dictionary = source_road.duplicate(true)
    freeway["road_id"] = "%s.freeway" % road_id
    freeway["start"] = split_cell
    result.append(_styled_road(freeway, &"four_lane", primary_width))
    return result

func _styled_road(source_road: Dictionary, road_type: StringName, width: int) -> Dictionary:
    var road: Dictionary = source_road.duplicate(true)
    road["road_type"] = road_type
    road["width"] = width
    if road_type == &"four_lane":
        road["lane_count"] = 4
        road["surface_family"] = &"paved_centerline"
        road["paint_centerline"] = true
    elif road_type == &"two_lane":
        road["lane_count"] = 2
        road["surface_family"] = &"paved_centerline"
        road["paint_centerline"] = true
    elif road_type == &"dirt":
        road["lane_count"] = 1
        road["surface_family"] = &"rural_dirt"
        road["paint_centerline"] = false
    else:
        road["road_type"] = &"gravel"
        road["lane_count"] = 1
        road["surface_family"] = &"rural_gravel"
        road["paint_centerline"] = false
    return road

func _road_segment_length(road: Dictionary) -> int:
    var start: Vector2i = road.get("start", INVALID_CELL)
    var finish: Vector2i = road.get("end", INVALID_CELL)
    if start == INVALID_CELL or finish == INVALID_CELL:
        return 0
    return absi(finish.x - start.x) + absi(finish.y - start.y)

func _point_along_cardinal_segment(start: Vector2i, finish: Vector2i, distance: int) -> Vector2i:
    if distance <= 0 or start == INVALID_CELL or finish == INVALID_CELL:
        return INVALID_CELL
    if start.x == finish.x:
        var direction_y: int = 1 if finish.y > start.y else -1
        return Vector2i(start.x, start.y + direction_y * distance)
    if start.y == finish.y:
        var direction_x: int = 1 if finish.x > start.x else -1
        return Vector2i(start.x + direction_x * distance, start.y)
    return INVALID_CELL

func _edge_key(a: int, b: int) -> String:
    return "%d:%d" % [mini(a, b), maxi(a, b)]

func _best_routable_edge(connected: Dictionary, settlements: Array[Dictionary]) -> Dictionary:
    var best: Dictionary = {}
    var best_score: int = 2147483647
    for from_value: Variant in connected.keys():
        var from_index: int = int(from_value)
        var from_center: Vector2i = settlements[from_index].get("center", INVALID_CELL)
        if from_center == INVALID_CELL:
            continue
        for to_index: int in range(settlements.size()):
            if connected.has(to_index):
                continue
            var to_center: Vector2i = settlements[to_index].get("center", INVALID_CELL)
            if to_center == INVALID_CELL:
                continue
            var score: int = absi(from_center.x - to_center.x) + absi(from_center.y - to_center.y)
            if score < best_score or (score == best_score and _edge_before(from_index, to_index, best)):
                best = {"from": from_index, "to": to_index}
                best_score = score
    return best

func _road_class_for_edge(a: Dictionary, b: Dictionary) -> StringName:
    var a_kind: StringName = StringName(a.get("kind", &""))
    var b_kind: StringName = StringName(b.get("kind", &""))
    if _settlement_requires_paved_access(a_kind) or _settlement_requires_paved_access(b_kind):
        return &"primary"
    return &"secondary"

func _settlement_requires_paved_access(kind: StringName) -> bool:
    return kind == &"smalltown" or kind == &"rural_crossroads"

func _settlement_nearest_side(bounds: Rect2i, settlements: Array[Dictionary], side: StringName) -> Dictionary:
    var best: Dictionary = {}
    var best_distance: int = 2147483647
    var max_x: int = bounds.end.x - 1
    var max_y: int = bounds.end.y - 1
    for settlement: Dictionary in settlements:
        var center: Vector2i = settlement.get("center", INVALID_CELL)
        if center == INVALID_CELL:
            continue
        var distance: int = 0
        match side:
            &"west": distance = center.x - bounds.position.x
            &"east": distance = max_x - center.x
            &"north": distance = center.y - bounds.position.y
            &"south": distance = max_y - center.y
            _: continue
        if distance < best_distance or (distance == best_distance and String(settlement.get("id", "")) < String(best.get("id", "~"))):
            best = settlement
            best_distance = distance
    return best

func _edge_before(from_index: int, to_index: int, best: Dictionary) -> bool:
    if best.is_empty():
        return true
    var best_from: int = int(best.get("from", 2147483647))
    var best_to: int = int(best.get("to", 2147483647))
    return from_index < best_from or (from_index == best_from and to_index < best_to)