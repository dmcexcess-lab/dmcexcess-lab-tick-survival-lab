extends RefCounted
class_name GlobalWaterInfrastructurePlanner

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")

const INVALID_CELL := Vector2i(-999999, -999999)
const NETWORK_ID: String = "water.network.municipal.smalltown.001"
const SMALLTOWN_ID: String = "settlement.smalltown.001"
const SMALLTOWN_SITE_ID: String = "area.smalltown.center.001"

func plan(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    settlements: Array[Dictionary],
    area_sites: Array[Dictionary],
    road_segments: Array[Dictionary]
) -> Dictionary:
    var water_services: Array[Dictionary] = []
    var water_nodes: Array[Dictionary] = []
    var water_segments: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty() or settlements.is_empty() or area_sites.is_empty() or road_segments.is_empty():
        return _failure("invalid_water_infrastructure_planner_input")

    var smalltown: Dictionary = _settlement_by_id(settlements, SMALLTOWN_ID)
    var smalltown_site: Dictionary = _site_by_id(area_sites, SMALLTOWN_SITE_ID)
    if smalltown.is_empty():
        return _failure("water_smalltown_settlement_missing")
    if smalltown_site.is_empty() or String(smalltown_site.get("settlement_id", "")) != SMALLTOWN_ID:
        return _failure("water_smalltown_site_missing")

    var known_current_ids: Dictionary = {
        "settlement.rural.crossroads.001": true,
        SMALLTOWN_ID: true,
        "settlement.rural.hamlet.001": true,
        "settlement.rural.hamlet.002": true,
        "settlement.rural.hamlet.003": true,
    }
    if settlements.size() != known_current_ids.size():
        return _failure("water_current_settlement_set_unsupported")

    for index in range(settlements.size()):
        var settlement: Dictionary = settlements[index]
        var settlement_id: String = String(settlement.get("id", ""))
        if not known_current_ids.has(settlement_id):
            return _failure("water_current_settlement_set_unsupported")
        var municipal: bool = settlement_id == SMALLTOWN_ID
        water_services.append({
            "id": "water.service.%03d" % [index + 1],
            "settlement_id": settlement_id,
            "service_mode": &"municipal" if municipal else &"decentralized_source",
            "source_type": &"groundwater",
            "network_id": NETWORK_ID if municipal else "",
        })

    var center: Vector2i = smalltown.get("center", INVALID_CELL)
    var site_bounds: Rect2i = smalltown_site.get("bounds", Rect2i())
    if center == INVALID_CELL or not site_bounds.has_point(center):
        return _failure("water_smalltown_center_invalid")

    var treatment_offset: int = int(profile.get("water_treatment_anchor_offset", 24))
    var source_offset: int = int(profile.get("water_source_anchor_offset", 48))
    if treatment_offset <= 0 or source_offset <= treatment_offset:
        return _failure("water_anchor_offsets_invalid")

    var options: Array[Dictionary] = _legal_anchor_options(center, site_bounds, road_segments, source_offset)
    if options.is_empty():
        return _failure("water_smalltown_source_corridor_unresolved")

    var preferred: Array[Dictionary] = []
    for option: Dictionary in options:
        if StringName(option.get("road_class", &"")) == &"primary":
            preferred.append(option)
    var choices: Array[Dictionary] = preferred if not preferred.is_empty() else options
    var choice_index: int = Seed.choose_index(request.seed, "water:smalltown:source_corridor", choices.size())
    if choice_index < 0:
        return _failure("water_smalltown_source_corridor_unresolved")
    var choice: Dictionary = choices[choice_index]
    var direction: Vector2i = choice.get("direction", Vector2i.ZERO)
    if direction == Vector2i.ZERO:
        return _failure("water_smalltown_source_direction_invalid")

    var treatment_cell: Vector2i = center + direction * treatment_offset
    var source_cell: Vector2i = center + direction * source_offset
    if not site_bounds.has_point(treatment_cell) or not site_bounds.has_point(source_cell):
        return _failure("water_smalltown_anchor_out_of_site")

    var source_road_id: String = String(choice.get("road_id", ""))
    var source_route_id: String = String(choice.get("route_id", ""))

    water_nodes.append({
        "id": "water.node.source.001",
        "network_id": NETWORK_ID,
        "kind": &"groundwater_source",
        "cell": source_cell,
        "settlement_id": SMALLTOWN_ID,
    })
    water_nodes.append({
        "id": "water.node.treatment_storage.001",
        "network_id": NETWORK_ID,
        "kind": &"treatment_storage",
        "cell": treatment_cell,
        "settlement_id": SMALLTOWN_ID,
    })
    water_nodes.append({
        "id": "water.node.service.001",
        "network_id": NETWORK_ID,
        "kind": &"settlement_service",
        "cell": center,
        "settlement_id": SMALLTOWN_ID,
    })

    water_segments.append(_segment(
        "water.segment.001",
        1,
        source_cell,
        treatment_cell,
        source_road_id,
        source_route_id
    ))
    water_segments.append(_segment(
        "water.segment.002",
        2,
        treatment_cell,
        center,
        source_road_id,
        source_route_id
    ))

    for segment: Dictionary in water_segments:
        if segment.is_empty():
            return _failure("water_municipal_trunk_invalid")

    return {
        "ok": true,
        "failure_reason": "",
        "water_services": water_services,
        "water_nodes": water_nodes,
        "water_segments": water_segments,
    }

func _legal_anchor_options(
    center: Vector2i,
    site_bounds: Rect2i,
    road_segments: Array[Dictionary],
    required_distance: int
) -> Array[Dictionary]:
    var options: Array[Dictionary] = []
    for road: Dictionary in road_segments:
        if not _point_on_segment(center, road):
            continue
        var start: Vector2i = road.get("start", INVALID_CELL)
        var finish: Vector2i = road.get("end", INVALID_CELL)
        var directions: Array[Vector2i] = []
        if start.y == finish.y:
            var min_x: int = mini(start.x, finish.x)
            var max_x: int = maxi(start.x, finish.x)
            if center.x - min_x >= required_distance:
                directions.append(Vector2i(-1, 0))
            if max_x - center.x >= required_distance:
                directions.append(Vector2i(1, 0))
        elif start.x == finish.x:
            var min_y: int = mini(start.y, finish.y)
            var max_y: int = maxi(start.y, finish.y)
            if center.y - min_y >= required_distance:
                directions.append(Vector2i(0, -1))
            if max_y - center.y >= required_distance:
                directions.append(Vector2i(0, 1))

        for direction: Vector2i in directions:
            var source_cell: Vector2i = center + direction * required_distance
            if not site_bounds.has_point(source_cell):
                continue
            options.append({
                "direction": direction,
                "road_id": String(road.get("road_id", "")),
                "route_id": String(road.get("route_id", "")),
                "road_class": StringName(road.get("road_class", &"")),
            })
    return options

func _segment(
    id: String,
    ordinal: int,
    start: Vector2i,
    finish: Vector2i,
    source_road_id: String,
    source_route_id: String
) -> Dictionary:
    if id.is_empty() or start == finish or (start.x != finish.x and start.y != finish.y):
        return {}
    if source_road_id.is_empty() or source_route_id.is_empty():
        return {}
    return {
        "id": id,
        "network_id": NETWORK_ID,
        "water_class": &"municipal_trunk",
        "start": start,
        "end": finish,
        "ordinal": ordinal,
        "source_road_id": source_road_id,
        "source_route_id": source_route_id,
    }

func _settlement_by_id(settlements: Array[Dictionary], settlement_id: String) -> Dictionary:
    for settlement: Dictionary in settlements:
        if String(settlement.get("id", "")) == settlement_id:
            return settlement
    return {}

func _site_by_id(sites: Array[Dictionary], site_id: String) -> Dictionary:
    for site: Dictionary in sites:
        if String(site.get("id", "")) == site_id:
            return site
    return {}

func _point_on_segment(point: Vector2i, segment: Dictionary) -> bool:
    var start: Vector2i = segment.get("start", INVALID_CELL)
    var finish: Vector2i = segment.get("end", INVALID_CELL)
    if start == INVALID_CELL or finish == INVALID_CELL:
        return false
    if start.y == finish.y:
        return point.y == start.y and point.x >= mini(start.x, finish.x) and point.x <= maxi(start.x, finish.x)
    if start.x == finish.x:
        return point.x == start.x and point.y >= mini(start.y, finish.y) and point.y <= maxi(start.y, finish.y)
    return false

func _failure(reason: String) -> Dictionary:
    return {
        "ok": false,
        "failure_reason": reason,
        "water_services": [],
        "water_nodes": [],
        "water_segments": [],
    }
