extends RefCounted
class_name GlobalPowerInfrastructurePlanner

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")

const INVALID_CELL := Vector2i(-999999, -999999)
const NETWORK_ID: String = "power.network.regional.001"

func plan(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    settlements: Array[Dictionary],
    road_segments: Array[Dictionary]
) -> Dictionary:
    var power_nodes: Array[Dictionary] = []
    var power_segments: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty() or settlements.is_empty() or road_segments.is_empty():
        return {"ok": false, "failure_reason": "invalid_power_infrastructure_planner_input", "power_nodes": power_nodes, "power_segments": power_segments}

    var smalltown: Dictionary = _settlement_by_id(settlements, "settlement.smalltown.001")
    if smalltown.is_empty():
        return {"ok": false, "failure_reason": "power_smalltown_settlement_missing", "power_nodes": power_nodes, "power_segments": power_segments}

    var gateways: Array[Vector2i] = _boundary_gateways(request.bounds, road_segments)
    if gateways.is_empty():
        return {"ok": false, "failure_reason": "power_regional_ingress_unresolved", "power_nodes": power_nodes, "power_segments": power_segments}
    var ingress_index: int = Seed.choose_index(request.seed, "power:regional_ingress", gateways.size())
    if ingress_index < 0:
        return {"ok": false, "failure_reason": "power_regional_ingress_unresolved", "power_nodes": power_nodes, "power_segments": power_segments}
    var ingress_cell: Vector2i = gateways[ingress_index]

    var smalltown_center: Vector2i = smalltown.get("center", INVALID_CELL)
    if smalltown_center == INVALID_CELL:
        return {"ok": false, "failure_reason": "power_substation_location_invalid", "power_nodes": power_nodes, "power_segments": power_segments}

    power_nodes.append({
        "id": "power.node.ingress.001",
        "network_id": NETWORK_ID,
        "kind": &"regional_ingress",
        "cell": ingress_cell,
        "settlement_id": "",
    })
    power_nodes.append({
        "id": "power.node.substation.001",
        "network_id": NETWORK_ID,
        "kind": &"substation",
        "cell": smalltown_center,
        "settlement_id": String(smalltown.get("id", "")),
    })

    for index in range(settlements.size()):
        var settlement: Dictionary = settlements[index]
        var center: Vector2i = settlement.get("center", INVALID_CELL)
        if center == INVALID_CELL:
            return {"ok": false, "failure_reason": "power_settlement_service_location_invalid", "power_nodes": [], "power_segments": []}
        power_nodes.append({
            "id": "power.node.service.%03d" % [index + 1],
            "network_id": NETWORK_ID,
            "kind": &"settlement_service",
            "cell": center,
            "settlement_id": String(settlement.get("id", "")),
        })

    var graph_result: Dictionary = _build_road_graph(road_segments, settlements, gateways)
    if not bool(graph_result.get("ok", false)):
        return {"ok": false, "failure_reason": String(graph_result.get("failure_reason", "power_road_graph_failed")), "power_nodes": [], "power_segments": []}
    var adjacency: Dictionary = graph_result.get("adjacency", {})
    var edges_by_key: Dictionary = graph_result.get("edges_by_key", {})

    var used_edge_keys: Dictionary = {}
    for node: Dictionary in power_nodes:
        if StringName(node.get("kind", &"")) == &"regional_ingress":
            continue
        var target: Vector2i = node.get("cell", INVALID_CELL)
        var path_result: Dictionary = _shortest_path(ingress_cell, target, adjacency, profile)
        if not bool(path_result.get("ok", false)):
            return {"ok": false, "failure_reason": "power_required_node_unreachable", "power_nodes": [], "power_segments": []}
        for edge_key_value: Variant in path_result.get("edge_keys", []):
            used_edge_keys[String(edge_key_value)] = true

    if used_edge_keys.is_empty():
        return {"ok": false, "failure_reason": "power_feeder_network_empty", "power_nodes": [], "power_segments": []}

    var ordered_keys: Array = used_edge_keys.keys()
    ordered_keys.sort()
    var ordinal: int = 1
    for edge_key_value: Variant in ordered_keys:
        var edge_key: String = String(edge_key_value)
        if not edges_by_key.has(edge_key):
            return {"ok": false, "failure_reason": "power_feeder_edge_missing", "power_nodes": [], "power_segments": []}
        var edge: Dictionary = edges_by_key[edge_key]
        power_segments.append({
            "id": "power.segment.%03d" % ordinal,
            "network_id": NETWORK_ID,
            "power_class": &"regional_feeder",
            "start": edge.get("a", INVALID_CELL),
            "end": edge.get("b", INVALID_CELL),
            "ordinal": ordinal,
            "source_road_id": String(edge.get("road_id", "")),
            "source_route_id": String(edge.get("route_id", "")),
        })
        ordinal += 1

    return {"ok": true, "failure_reason": "", "power_nodes": power_nodes, "power_segments": power_segments}

func _build_road_graph(
    road_segments: Array[Dictionary],
    settlements: Array[Dictionary],
    gateways: Array[Vector2i]
) -> Dictionary:
    var vertices: Dictionary = {}
    for road: Dictionary in road_segments:
        var start: Vector2i = road.get("start", INVALID_CELL)
        var finish: Vector2i = road.get("end", INVALID_CELL)
        if start == INVALID_CELL or finish == INVALID_CELL or start == finish or (start.x != finish.x and start.y != finish.y):
            return {"ok": false, "failure_reason": "power_source_road_invalid", "adjacency": {}, "edges_by_key": {}}
        vertices[start] = true
        vertices[finish] = true
    for settlement: Dictionary in settlements:
        vertices[settlement.get("center", INVALID_CELL)] = true
    for gateway: Vector2i in gateways:
        vertices[gateway] = true

    for first_index in range(road_segments.size()):
        for second_index in range(first_index + 1, road_segments.size()):
            var crossing: Vector2i = _segment_intersection(road_segments[first_index], road_segments[second_index])
            if crossing != INVALID_CELL:
                vertices[crossing] = true

    var adjacency: Dictionary = {}
    var edges_by_key: Dictionary = {}
    for road: Dictionary in road_segments:
        var points: Array[Vector2i] = []
        for vertex_value: Variant in vertices.keys():
            var vertex: Vector2i = vertex_value
            if _point_on_segment(vertex, road):
                points.append(vertex)
        _sort_points_on_segment(points, road)
        if points.size() < 2:
            continue
        for index in range(points.size() - 1):
            var a: Vector2i = points[index]
            var b: Vector2i = points[index + 1]
            if a == b:
                continue
            var key: String = _edge_key(a, b)
            var edge: Dictionary = {
                "key": key,
                "a": a,
                "b": b,
                "road_id": String(road.get("road_id", "")),
                "route_id": String(road.get("route_id", "")),
                "road_class": StringName(road.get("road_class", &"")),
                "length": absi(a.x - b.x) + absi(a.y - b.y),
            }
            if edges_by_key.has(key):
                var existing: Dictionary = edges_by_key[key]
                if String(edge.get("road_id", "")) < String(existing.get("road_id", "")):
                    edges_by_key[key] = edge
            else:
                edges_by_key[key] = edge

    for edge_value: Variant in edges_by_key.values():
        var edge: Dictionary = edge_value
        var a: Vector2i = edge.get("a", INVALID_CELL)
        var b: Vector2i = edge.get("b", INVALID_CELL)
        if not adjacency.has(a):
            adjacency[a] = []
        if not adjacency.has(b):
            adjacency[b] = []
        var from_a: Array = adjacency[a]
        from_a.append({"to": b, "edge_key": String(edge.get("key", "")), "road_class": edge.get("road_class", &""), "length": int(edge.get("length", 0))})
        adjacency[a] = from_a
        var from_b: Array = adjacency[b]
        from_b.append({"to": a, "edge_key": String(edge.get("key", "")), "road_class": edge.get("road_class", &""), "length": int(edge.get("length", 0))})
        adjacency[b] = from_b

    for vertex_value: Variant in vertices.keys():
        var vertex: Vector2i = vertex_value
        if not adjacency.has(vertex):
            adjacency[vertex] = []

    return {"ok": true, "failure_reason": "", "adjacency": adjacency, "edges_by_key": edges_by_key}

func _shortest_path(start: Vector2i, finish: Vector2i, adjacency: Dictionary, profile: Dictionary) -> Dictionary:
    if start == finish:
        return {"ok": true, "edge_keys": []}
    if not adjacency.has(start) or not adjacency.has(finish):
        return {"ok": false, "edge_keys": []}

    var open_set: Dictionary = {start: true}
    var distance: Dictionary = {start: 0}
    var came_from: Dictionary = {}
    var closed: Dictionary = {}

    while not open_set.is_empty():
        var current: Vector2i = _lowest_distance(open_set, distance)
        if current == INVALID_CELL:
            break
        if current == finish:
            return {"ok": true, "edge_keys": _reconstruct_edge_keys(came_from, start, finish)}
        open_set.erase(current)
        closed[current] = true
        var base_distance: int = int(distance.get(current, 2147483647))
        var neighbors: Array = adjacency.get(current, [])
        for neighbor_value: Variant in neighbors:
            if typeof(neighbor_value) != TYPE_DICTIONARY:
                continue
            var neighbor: Dictionary = neighbor_value
            var target: Vector2i = neighbor.get("to", INVALID_CELL)
            if target == INVALID_CELL or closed.has(target):
                continue
            var road_class: StringName = StringName(neighbor.get("road_class", &""))
            var class_cost: int = int(profile.get("power_cost_secondary", 12))
            if road_class == &"primary":
                class_cost = int(profile.get("power_cost_primary", 10))
            var edge_length: int = maxi(1, int(neighbor.get("length", 1)))
            var tentative: int = base_distance + edge_length * maxi(1, class_cost)
            var known: int = int(distance.get(target, 2147483647))
            if tentative > known:
                continue
            if tentative == known and came_from.has(target):
                var existing: Dictionary = came_from[target]
                if String(neighbor.get("edge_key", "")) >= String(existing.get("edge_key", "")):
                    continue
            distance[target] = tentative
            came_from[target] = {"prior": current, "edge_key": String(neighbor.get("edge_key", ""))}
            open_set[target] = true

    return {"ok": false, "edge_keys": []}

func _reconstruct_edge_keys(came_from: Dictionary, start: Vector2i, finish: Vector2i) -> Array[String]:
    var reversed: Array[String] = []
    var current: Vector2i = finish
    while current != start:
        if not came_from.has(current):
            return []
        var step: Dictionary = came_from[current]
        reversed.append(String(step.get("edge_key", "")))
        current = step.get("prior", INVALID_CELL)
        if current == INVALID_CELL:
            return []
    reversed.reverse()
    return reversed

func _lowest_distance(open_set: Dictionary, distance: Dictionary) -> Vector2i:
    var best: Vector2i = INVALID_CELL
    var best_distance: int = 2147483647
    for point_value: Variant in open_set.keys():
        var point: Vector2i = point_value
        var value: int = int(distance.get(point, 2147483647))
        if value < best_distance or (value == best_distance and _point_before(point, best)):
            best = point
            best_distance = value
    return best

func _boundary_gateways(bounds: Rect2i, road_segments: Array[Dictionary]) -> Array[Vector2i]:
    var unique: Dictionary = {}
    for road: Dictionary in road_segments:
        var start: Vector2i = road.get("start", INVALID_CELL)
        var finish: Vector2i = road.get("end", INVALID_CELL)
        if _is_boundary_cell(bounds, start):
            unique[start] = true
        if _is_boundary_cell(bounds, finish):
            unique[finish] = true
    var result: Array[Vector2i] = []
    for value: Variant in unique.keys():
        result.append(value)
    result.sort_custom(_point_before)
    return result

func _segment_intersection(a: Dictionary, b: Dictionary) -> Vector2i:
    var a_start: Vector2i = a.get("start", INVALID_CELL)
    var a_end: Vector2i = a.get("end", INVALID_CELL)
    var b_start: Vector2i = b.get("start", INVALID_CELL)
    var b_end: Vector2i = b.get("end", INVALID_CELL)
    var a_horizontal: bool = a_start.y == a_end.y
    var b_horizontal: bool = b_start.y == b_end.y
    if a_horizontal == b_horizontal:
        return INVALID_CELL
    var horizontal: Dictionary = a if a_horizontal else b
    var vertical: Dictionary = b if a_horizontal else a
    var h_start: Vector2i = horizontal.get("start", INVALID_CELL)
    var h_end: Vector2i = horizontal.get("end", INVALID_CELL)
    var v_start: Vector2i = vertical.get("start", INVALID_CELL)
    var v_end: Vector2i = vertical.get("end", INVALID_CELL)
    var cell := Vector2i(v_start.x, h_start.y)
    if cell.x < mini(h_start.x, h_end.x) or cell.x > maxi(h_start.x, h_end.x):
        return INVALID_CELL
    if cell.y < mini(v_start.y, v_end.y) or cell.y > maxi(v_start.y, v_end.y):
        return INVALID_CELL
    return cell

func _point_on_segment(point: Vector2i, segment: Dictionary) -> bool:
    var start: Vector2i = segment.get("start", INVALID_CELL)
    var finish: Vector2i = segment.get("end", INVALID_CELL)
    if start.y == finish.y:
        return point.y == start.y and point.x >= mini(start.x, finish.x) and point.x <= maxi(start.x, finish.x)
    if start.x == finish.x:
        return point.x == start.x and point.y >= mini(start.y, finish.y) and point.y <= maxi(start.y, finish.y)
    return false

func _sort_points_on_segment(points: Array[Vector2i], segment: Dictionary) -> void:
    var start: Vector2i = segment.get("start", INVALID_CELL)
    var finish: Vector2i = segment.get("end", INVALID_CELL)
    if start.y == finish.y:
        points.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
            return a.x < b.x or (a.x == b.x and a.y < b.y)
        )
    else:
        points.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
            return a.y < b.y or (a.y == b.y and a.x < b.x)
        )

func _edge_key(a: Vector2i, b: Vector2i) -> String:
    var first: Vector2i = a
    var second: Vector2i = b
    if _point_before(second, first):
        first = b
        second = a
    return "%d,%d>%d,%d" % [first.x, first.y, second.x, second.y]

func _settlement_by_id(settlements: Array[Dictionary], settlement_id: String) -> Dictionary:
    for settlement: Dictionary in settlements:
        if String(settlement.get("id", "")) == settlement_id:
            return settlement
    return {}

func _point_before(a: Vector2i, b: Vector2i) -> bool:
    if b == INVALID_CELL:
        return true
    return a.y < b.y or (a.y == b.y and a.x < b.x)

func _is_boundary_cell(rect: Rect2i, cell: Vector2i) -> bool:
    if not rect.has_point(cell):
        return false
    var max_x: int = rect.position.x + rect.size.x - 1
    var max_y: int = rect.position.y + rect.size.y - 1
    return cell.x == rect.position.x or cell.x == max_x or cell.y == rect.position.y or cell.y == max_y
