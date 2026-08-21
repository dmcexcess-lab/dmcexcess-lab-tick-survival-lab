extends RefCounted
class_name GlobalMajorRoadPlanner

func plan(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    settlements: Array[Dictionary]
) -> Dictionary:
    var road_segments: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty() or settlements.is_empty():
        return {"ok": false, "failure_reason": "invalid_major_road_planner_input", "road_segments": road_segments}

    var crossroads: Dictionary = _settlement_by_id(settlements, "settlement.rural.crossroads.001")
    var southwest: Dictionary = _settlement_by_id(settlements, "settlement.rural.hamlet.002")
    var northeast: Dictionary = _settlement_by_id(settlements, "settlement.rural.hamlet.003")
    if crossroads.is_empty() or southwest.is_empty() or northeast.is_empty():
        return {"ok": false, "failure_reason": "required_settlement_missing", "road_segments": road_segments}

    var center: Vector2i = crossroads.get("center", Vector2i.ZERO)
    var southwest_center: Vector2i = southwest.get("center", Vector2i.ZERO)
    var northeast_center: Vector2i = northeast.get("center", Vector2i.ZERO)
    var min_x: int = request.bounds.position.x
    var max_x: int = request.bounds.position.x + request.bounds.size.x - 1
    var min_y: int = request.bounds.position.y
    var max_y: int = request.bounds.position.y + request.bounds.size.y - 1
    var primary_width: int = int(profile.get("primary_width", 5))
    var secondary_width: int = int(profile.get("secondary_width", 3))

    road_segments.append(_segment(
        "road.region.primary.001",
        &"primary",
        Vector2i(min_x, center.y),
        Vector2i(max_x, center.y),
        primary_width,
        "route.region.primary.001"
    ))
    road_segments.append(_segment(
        "road.region.secondary.001",
        &"secondary",
        Vector2i(center.x, min_y),
        Vector2i(center.x, max_y),
        secondary_width,
        "route.region.secondary.001"
    ))
    road_segments.append(_segment(
        "road.region.secondary.002",
        &"secondary",
        Vector2i(southwest_center.x, center.y),
        southwest_center,
        secondary_width,
        "route.region.secondary.002"
    ))
    road_segments.append(_segment(
        "road.region.secondary.003",
        &"secondary",
        Vector2i(center.x, northeast_center.y),
        northeast_center,
        secondary_width,
        "route.region.secondary.003"
    ))

    for road: Dictionary in road_segments:
        if road.is_empty():
            return {"ok": false, "failure_reason": "major_road_segment_invalid", "road_segments": []}

    return {"ok": true, "failure_reason": "", "road_segments": road_segments}

func _segment(
    road_id: String,
    road_class: StringName,
    start: Vector2i,
    finish: Vector2i,
    width: int,
    route_id: String
) -> Dictionary:
    if start == finish or (start.x != finish.x and start.y != finish.y):
        return {}
    if width <= 0 or width % 2 == 0:
        return {}
    return {
        "road_id": road_id,
        "road_class": road_class,
        "start": start,
        "end": finish,
        "width": width,
        "route_id": route_id,
    }

func _settlement_by_id(settlements: Array[Dictionary], settlement_id: String) -> Dictionary:
    for settlement: Dictionary in settlements:
        if String(settlement.get("id", "")) == settlement_id:
            return settlement
    return {}
