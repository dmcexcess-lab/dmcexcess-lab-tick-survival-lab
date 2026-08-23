extends RefCounted
class_name GlobalWastewaterInfrastructurePlanner

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")

const INVALID_CELL := Vector2i(-999999, -999999)
const NETWORK_ID: String = "wastewater.network.municipal.smalltown.001"
const SMALLTOWN_ID: String = "settlement.smalltown.001"
const SMALLTOWN_SITE_ID: String = "area.smalltown.center.001"

func plan(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    settlements: Array[Dictionary],
    area_sites: Array[Dictionary],
    road_segments: Array[Dictionary],
    water_nodes: Array[Dictionary],
    water_segments: Array[Dictionary]
) -> Dictionary:
    var wastewater_services: Array[Dictionary] = []
    var wastewater_nodes: Array[Dictionary] = []
    var wastewater_segments: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty() or settlements.is_empty() or area_sites.is_empty() or road_segments.is_empty() or water_nodes.is_empty() or water_segments.is_empty():
        return _failure("invalid_wastewater_infrastructure_planner_input")

    var smalltown: Dictionary = _settlement_by_id(settlements, SMALLTOWN_ID)
    var smalltown_site: Dictionary = _site_by_id(area_sites, SMALLTOWN_SITE_ID)
    if smalltown.is_empty():
        return _failure("wastewater_smalltown_settlement_missing")
    if smalltown_site.is_empty() or String(smalltown_site.get("settlement_id", "")) != SMALLTOWN_ID:
        return _failure("wastewater_smalltown_site_missing")

    var known_current_ids: Dictionary = {
        "settlement.rural.crossroads.001": true,
        SMALLTOWN_ID: true,
        "settlement.rural.hamlet.001": true,
        "settlement.rural.hamlet.002": true,
        "settlement.rural.hamlet.003": true,
    }
    if settlements.size() != known_current_ids.size():
        return _failure("wastewater_current_settlement_set_unsupported")

    for index in range(settlements.size()):
        var settlement: Dictionary = settlements[index]
        var settlement_id: String = String(settlement.get("id", ""))
        if not known_current_ids.has(settlement_id):
            return _failure("wastewater_current_settlement_set_unsupported")
        var municipal: bool = settlement_id == SMALLTOWN_ID
        wastewater_services.append({
            "id": "wastewater.service.%03d" % [index + 1],
            "settlement_id": settlement_id,
            "service_mode": &"municipal" if municipal else &"decentralized_septic",
            "disposal_type": &"municipal_treatment" if municipal else &"onsite_septic",
            "network_id": NETWORK_ID if municipal else "",
            "separation_policy": &"" if municipal else &"potable_source_clearance_required",
        })

    var center: Vector2i = smalltown.get("center", INVALID_CELL)
    var site_bounds: Rect2i = smalltown_site.get("bounds", Rect2i())
    if center == INVALID_CELL or not site_bounds.has_point(center):
        return _failure("wastewater_smalltown_center_invalid")

    var potable_source: Dictionary = _water_node_by_kind(water_nodes, &"groundwater_source")
    if potable_source.is_empty() or String(potable_source.get("settlement_id", "")) != SMALLTOWN_ID:
        return _failure("wastewater_potable_source_missing")
    var potable_source_cell: Vector2i = potable_source.get("cell", INVALID_CELL)
    var potable_direction: Vector2i = _cardinal_direction(center, potable_source_cell)
    if potable_direction == Vector2i.ZERO:
        return _failure("wastewater_potable_source_direction_invalid")

    var treatment_offset: int = int(profile.get("wastewater_treatment_anchor_offset", 64))
    if treatment_offset <= 0:
        return _failure("wastewater_treatment_anchor_offset_invalid")

    var options: Array[Dictionary] = _legal_anchor_options(center, site_bounds, road_segments, treatment_offset)
    var separated_options: Array[Dictionary] = []
    for option: Dictionary in options:
        var direction: Vector2i = option.get("direction", Vector2i.ZERO)
        if direction == Vector2i.ZERO or direction == potable_direction:
            continue
        var treatment_cell: Vector2i = center + direction * treatment_offset
        if _point_on_any_water_segment(treatment_cell, water_segments):
            continue
        separated_options.append(option)
    if separated_options.is_empty():
        return _failure("wastewater_separate_treatment_corridor_unresolved")

    var preferred: Array[Dictionary] = []
    for option: Dictionary in separated_options:
        if StringName(option.get("road_class", &"")) == &"primary":
            preferred.append(option)
    var choices: Array[Dictionary] = preferred if not preferred.is_empty() else separated_options
    var choice_index: int = Seed.choose_index(request.seed, "wastewater:smalltown:treatment_corridor", choices.size())
    if choice_index < 0:
        return _failure("wastewater_separate_treatment_corridor_unresolved")
    var choice: Dictionary = choices[choice_index]
    var direction: Vector2i = choice.get("direction", Vector2i.ZERO)
    var treatment_cell: Vector2i = center + direction * treatment_offset
    if not site_bounds.has_point(treatment_cell):
        return _failure("wastewater_treatment_anchor_out_of_site")
    if _cell_matches_any_water_node(treatment_cell, water_nodes):
        return _failure("wastewater_treatment_overlaps_potable_node")

    var source_road_id: String = String(choice.get("road_id", ""))
    var source_route_id: String = String(choice.get("route_id", ""))

    wastewater_nodes.append({
        "id": "wastewater.node.collection.001",
        "network_id": NETWORK_ID,
        "kind": &"settlement_collection",
        "cell": center,
        "settlement_id": SMALLTOWN_ID,
    })
    wastewater_nodes.append({
        "id": "wastewater.node.treatment_disposal.001",
        "network_id": NETWORK_ID,
        "kind": &"treatment_disposal",
        "cell": treatment_cell,
        "settlement_id": SMALLTOWN_ID,
    })

    var segment: Dictionary = _segment(
        "wastewater.segment.001",
        center,
        treatment_cell,
        source_road_id,
        source_route_id
    )
    if segment.is_empty() or _segment_overlaps_any_water_segment(segment, water_segments):
        return _failure("wastewater_municipal_trunk_overlaps_potable_water")
    wastewater_segments.append(segment)

    return {
        "ok": true,
        "failure_reason": "",
        "wastewater_services": wastewater_services,
        "wastewater_nodes": wastewater_nodes,
        "wastewater_segments": wastewater_segments,
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
            var treatment_cell: Vector2i = center + direction * required_distance
            if not site_bounds.has_point(treatment_cell):
                continue
            options.append({
                "direction": direction,
                "road_id": String(road.get("road_id", "")),
                "route_id": String(road.get("route_id", "")),
                "road_class": StringName(road.get("road_class", &"")),
            })
    return options

func _segment(id: String, start: Vector2i, finish: Vector2i, source_road_id: String, source_route_id: String) -> Dictionary:
    if id.is_empty() or start == finish or (start.x != finish.x and start.y != finish.y):
        return {}
    if source_road_id.is_empty() or source_route_id.is_empty():
        return {}
    return {
        "id": id,
        "network_id": NETWORK_ID,
        "wastewater_class": &"municipal_collection_trunk",
        "start": start,
        "end": finish,
        "ordinal": 1,
        "source_road_id": source_road_id,
        "source_route_id": source_route_id,
    }

func _cardinal_direction(from_cell: Vector2i, to_cell: Vector2i) -> Vector2i:
    var delta: Vector2i = to_cell - from_cell
    if delta == Vector2i.ZERO:
        return Vector2i.ZERO
    if delta.x != 0 and delta.y != 0:
        return Vector2i.ZERO
    return Vector2i(signi(delta.x), signi(delta.y))

func _water_node_by_kind(nodes: Array[Dictionary], kind: StringName) -> Dictionary:
    for node: Dictionary in nodes:
        if StringName(node.get("kind", &"")) == kind:
            return node
    return {}

func _cell_matches_any_water_node(cell: Vector2i, nodes: Array[Dictionary]) -> bool:
    for node: Dictionary in nodes:
        if node.get("cell", INVALID_CELL) == cell:
            return true
    return false

func _point_on_any_water_segment(cell: Vector2i, segments: Array[Dictionary]) -> bool:
    for segment: Dictionary in segments:
        if _point_on_segment(cell, segment):
            return true
    return false

func _segment_overlaps_any_water_segment(segment: Dictionary, water_segments: Array[Dictionary]) -> bool:
    for water_segment: Dictionary in water_segments:
        if _segments_overlap_positive_length(segment, water_segment):
            return true
    return false

func _segments_overlap_positive_length(a: Dictionary, b: Dictionary) -> bool:
    var a_start: Vector2i = a.get("start", INVALID_CELL)
    var a_end: Vector2i = a.get("end", INVALID_CELL)
    var b_start: Vector2i = b.get("start", INVALID_CELL)
    var b_end: Vector2i = b.get("end", INVALID_CELL)
    if a_start.y == a_end.y and b_start.y == b_end.y and a_start.y == b_start.y:
        var overlap_min_x: int = maxi(mini(a_start.x, a_end.x), mini(b_start.x, b_end.x))
        var overlap_max_x: int = mini(maxi(a_start.x, a_end.x), maxi(b_start.x, b_end.x))
        return overlap_min_x < overlap_max_x
    if a_start.x == a_end.x and b_start.x == b_end.x and a_start.x == b_start.x:
        var overlap_min_y: int = maxi(mini(a_start.y, a_end.y), mini(b_start.y, b_end.y))
        var overlap_max_y: int = mini(maxi(a_start.y, a_end.y), maxi(b_start.y, b_end.y))
        return overlap_min_y < overlap_max_y
    return false

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
        "wastewater_services": [],
        "wastewater_nodes": [],
        "wastewater_segments": [],
    }
