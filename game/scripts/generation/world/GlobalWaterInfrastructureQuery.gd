extends RefCounted
class_name GlobalWaterInfrastructureQuery

const INVALID_CELL := Vector2i(-999999, -999999)

func service_for_settlement(water_services: Array[Dictionary], settlement_id: String) -> Dictionary:
    for service: Dictionary in water_services:
        if String(service.get("settlement_id", "")) == settlement_id:
            return service.duplicate(true)
    return {}

func service_for_cell(water_services: Array[Dictionary], _cell: Vector2i) -> Dictionary:
    var candidates: Array[Dictionary] = []
    for service: Dictionary in water_services:
        if StringName(service.get("service_mode", &"")) == &"island_wide_municipal" \
            and bool(service.get("island_wide", false)):
            candidates.append(service)
    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("id", "")) < String(b.get("id", ""))
    )
    return {} if candidates.is_empty() else candidates[0].duplicate(true)

func node_by_kind(water_nodes: Array[Dictionary], kind: StringName) -> Dictionary:
    for node: Dictionary in water_nodes:
        if StringName(node.get("kind", &"")) == kind:
            return node.duplicate(true)
    return {}

func node_by_id(water_nodes: Array[Dictionary], node_id: String) -> Dictionary:
    for node: Dictionary in water_nodes:
        if String(node.get("id", "")) == node_id:
            return node.duplicate(true)
    return {}

func point_on_segment(point: Vector2i, segment: Dictionary) -> bool:
    var start: Vector2i = segment.get("start", INVALID_CELL)
    var finish: Vector2i = segment.get("end", INVALID_CELL)
    if start == INVALID_CELL or finish == INVALID_CELL:
        return false
    if start.y == finish.y:
        return point.y == start.y and point.x >= mini(start.x, finish.x) and point.x <= maxi(start.x, finish.x)
    if start.x == finish.x:
        return point.x == start.x and point.y >= mini(start.y, finish.y) and point.y <= maxi(start.y, finish.y)
    return false

func segment_contained_in(segment: Dictionary, container: Dictionary) -> bool:
    var start: Vector2i = segment.get("start", INVALID_CELL)
    var finish: Vector2i = segment.get("end", INVALID_CELL)
    if start == INVALID_CELL or finish == INVALID_CELL:
        return false
    return point_on_segment(start, container) and point_on_segment(finish, container)

func reachable_nodes_from(start: Vector2i, water_segments: Array[Dictionary]) -> Dictionary:
    var adjacency: Dictionary = {}
    for segment: Dictionary in water_segments:
        var a: Vector2i = segment.get("start", INVALID_CELL)
        var b: Vector2i = segment.get("end", INVALID_CELL)
        if a == INVALID_CELL or b == INVALID_CELL or a == b:
            continue
        if not adjacency.has(a):
            adjacency[a] = []
        if not adjacency.has(b):
            adjacency[b] = []
        var a_neighbors: Array = adjacency[a]
        if not a_neighbors.has(b):
            a_neighbors.append(b)
        adjacency[a] = a_neighbors
        var b_neighbors: Array = adjacency[b]
        if not b_neighbors.has(a):
            b_neighbors.append(a)
        adjacency[b] = b_neighbors

    var reachable: Dictionary = {start: true}
    if not adjacency.has(start):
        return reachable
    var queue: Array[Vector2i] = [start]
    var index: int = 0
    while index < queue.size():
        var current: Vector2i = queue[index]
        index += 1
        var neighbors: Array = adjacency.get(current, [])
        for neighbor_value: Variant in neighbors:
            var neighbor: Vector2i = neighbor_value
            if reachable.has(neighbor):
                continue
            reachable[neighbor] = true
            queue.append(neighbor)
    return reachable
