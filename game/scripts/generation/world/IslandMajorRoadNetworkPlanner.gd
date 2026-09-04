extends "res://scripts/generation/world/GlobalMajorRoadPlanner.gd"
class_name IslandMajorRoadNetworkPlanner

const INVALID_CELL := Vector2i(-999999, -999999)

func plan(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    settlements: Array[Dictionary],
    geography_cells: Array[Dictionary],
    river_segments: Array[Dictionary]
) -> Dictionary:
    var road_segments: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty() or settlements.size() < 2 or geography_cells.is_empty() or river_segments.is_empty():
        return {"ok": false, "failure_reason": "invalid_island_major_road_planner_input", "road_segments": road_segments}

    var primary_width: int = int(profile.get("primary_width", 5))
    var secondary_width: int = int(profile.get("secondary_width", 3))
    var connected: Dictionary = {0: true}
    var edge_ordinal: int = 1

    # Standard Prim-style minimum spanning tree over the generated settlements.
    # Candidate selection uses deterministic geometric distance; the expensive
    # terrain pathfinder runs only for the ten edges we actually materialize.
    while connected.size() < settlements.size():
        var best: Dictionary = _best_routable_edge(connected, settlements, geography_cells, river_segments, profile)
        if best.is_empty():
            return {"ok": false, "failure_reason": "island_settlement_road_tree_unresolved", "road_segments": []}
        var from_index: int = int(best.get("from", -1))
        var to_index: int = int(best.get("to", -1))
        if from_index < 0 or to_index < 0:
            return {"ok": false, "failure_reason": "island_settlement_road_edge_invalid", "road_segments": []}
        var from_settlement: Dictionary = settlements[from_index]
        var to_settlement: Dictionary = settlements[to_index]
        var road_class: StringName = _road_class_for_edge(from_settlement, to_settlement)
        var width: int = primary_width if road_class == &"primary" else secondary_width
        var prefix: String = "road.island.network.%03d" % edge_ordinal
        var route_id: String = "route.island.network.%03d" % edge_ordinal
        if not _append_routed_path(
            road_segments,
            prefix,
            road_class,
            route_id,
            from_settlement.get("center", INVALID_CELL),
            to_settlement.get("center", INVALID_CELL),
            width,
            geography_cells,
            river_segments,
            profile
        ):
            return {"ok": false, "failure_reason": "island_settlement_road_edge_failed", "road_segments": []}
        connected[to_index] = true
        edge_ordinal += 1

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
            river_segments,
            profile
        ):
            gateway = _reachable_boundary_gateway(
                request.bounds,
                side,
                source_center,
                gateway,
                geography_cells,
                river_segments,
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
                river_segments,
                profile
            ):
                return {"ok": false, "failure_reason": "island_boundary_gateway_route_failed:%s" % String(side), "road_segments": []}

    if road_segments.is_empty():
        return {"ok": false, "failure_reason": "island_major_road_network_empty", "road_segments": []}
    return {"ok": true, "failure_reason": "", "road_segments": road_segments}

func _best_routable_edge(
    connected: Dictionary,
    settlements: Array[Dictionary],
    geography_cells: Array[Dictionary],
    river_segments: Array[Dictionary],
    profile: Dictionary
) -> Dictionary:
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
    if a_kind == &"smalltown" and b_kind != &"rural_hamlet":
        return &"primary"
    if b_kind == &"smalltown" and a_kind != &"rural_hamlet":
        return &"primary"
    return &"secondary"

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
