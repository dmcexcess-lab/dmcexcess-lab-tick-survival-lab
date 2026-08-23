extends RefCounted
class_name GlobalWastewaterInfrastructureQuery

const INVALID_CELL := Vector2i(-999999, -999999)

func service_for_settlement(wastewater_services: Array[Dictionary], settlement_id: String) -> Dictionary:
    for service: Dictionary in wastewater_services:
        if String(service.get("settlement_id", "")) == settlement_id:
            return service.duplicate(true)
    return {}

func node_by_kind(wastewater_nodes: Array[Dictionary], kind: StringName) -> Dictionary:
    for node: Dictionary in wastewater_nodes:
        if StringName(node.get("kind", &"")) == kind:
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

func segments_overlap_positive_length(a: Dictionary, b: Dictionary) -> bool:
    var a_start: Vector2i = a.get("start", INVALID_CELL)
    var a_end: Vector2i = a.get("end", INVALID_CELL)
    var b_start: Vector2i = b.get("start", INVALID_CELL)
    var b_end: Vector2i = b.get("end", INVALID_CELL)
    if a_start == INVALID_CELL or a_end == INVALID_CELL or b_start == INVALID_CELL or b_end == INVALID_CELL:
        return false
    if a_start.y == a_end.y and b_start.y == b_end.y and a_start.y == b_start.y:
        var overlap_min_x: int = maxi(mini(a_start.x, a_end.x), mini(b_start.x, b_end.x))
        var overlap_max_x: int = mini(maxi(a_start.x, a_end.x), maxi(b_start.x, b_end.x))
        return overlap_min_x < overlap_max_x
    if a_start.x == a_end.x and b_start.x == b_end.x and a_start.x == b_start.x:
        var overlap_min_y: int = maxi(mini(a_start.y, a_end.y), mini(b_start.y, b_end.y))
        var overlap_max_y: int = mini(maxi(a_start.y, a_end.y), maxi(b_start.y, b_end.y))
        return overlap_min_y < overlap_max_y
    return false
