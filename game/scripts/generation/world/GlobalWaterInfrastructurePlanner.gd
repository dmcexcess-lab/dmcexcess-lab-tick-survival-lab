extends RefCounted
class_name GlobalWaterInfrastructurePlanner

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")

const INVALID_CELL := Vector2i(-999999, -999999)
const SMALLTOWN_ID: String = "settlement.smalltown.001"
const CENTRAL_SETTLEMENT_ID: String = "settlement.rural.crossroads.001"
const PLANT_HOST_SETTLEMENT_IDS: Array[String] = [
    SMALLTOWN_ID,
    "settlement.rural.hamlet.001",
    "settlement.rural.hamlet.002",
    "settlement.rural.hamlet.003",
]

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

    var plant_count: int = int(profile.get("water_regional_plant_count", 4))
    var service_radius: int = int(profile.get("water_service_radius_cells", 704))
    var treatment_offset: int = int(profile.get("water_treatment_anchor_offset", 24))
    var source_offset: int = int(profile.get("water_source_anchor_offset", 48))
    if plant_count != PLANT_HOST_SETTLEMENT_IDS.size() or service_radius <= 0 \
        or treatment_offset <= 0 or source_offset <= treatment_offset:
        return _failure("water_regional_profile_invalid")

    var plants: Array[Dictionary] = []
    for ordinal in range(plant_count):
        var host_settlement_id: String = PLANT_HOST_SETTLEMENT_IDS[ordinal]
        var host: Dictionary = _settlement_by_id(settlements, host_settlement_id)
        var host_site: Dictionary = _site_for_settlement(area_sites, host_settlement_id)
        if host.is_empty() or host_site.is_empty():
            return _failure("water_regional_plant_host_missing")
        var center: Vector2i = host.get("center", INVALID_CELL)
        var site_bounds: Rect2i = host_site.get("bounds", Rect2i())
        if center == INVALID_CELL or not site_bounds.has_point(center):
            return _failure("water_regional_plant_host_invalid")

        var options: Array[Dictionary] = _legal_anchor_options(center, site_bounds, road_segments, source_offset)
        if options.is_empty():
            return _failure("water_regional_plant_corridor_unresolved")
        var preferred: Array[Dictionary] = []
        for option: Dictionary in options:
            if StringName(option.get("road_class", &"")) == &"primary":
                preferred.append(option)
        var choices: Array[Dictionary] = preferred if not preferred.is_empty() else options
        var choice_index: int = Seed.choose_index(
            request.seed,
            "water:regional_plant:%s:source_corridor" % host_settlement_id,
            choices.size()
        )
        if choice_index < 0:
            return _failure("water_regional_plant_corridor_unresolved")
        var choice: Dictionary = choices[choice_index]
        var direction: Vector2i = choice.get("direction", Vector2i.ZERO)
        if direction == Vector2i.ZERO:
            return _failure("water_regional_plant_direction_invalid")

        var source_cell: Vector2i = center + direction * source_offset
        var treatment_cell: Vector2i = center + direction * treatment_offset
        if not site_bounds.has_point(source_cell) or not site_bounds.has_point(treatment_cell):
            return _failure("water_regional_plant_anchor_out_of_site")

        var plant_number: int = ordinal + 1
        var plant_id: String = "water.plant.%03d" % plant_number
        var network_id: String = "water.network.regional.%03d" % plant_number
        var source_node_id: String = "water.node.source.%03d" % plant_number
        var treatment_node_id: String = "water.node.treatment_storage.%03d" % plant_number
        var service_node_id: String = "water.node.regional_service.%03d" % plant_number
        var source_road_id: String = String(choice.get("road_id", ""))
        var source_route_id: String = String(choice.get("route_id", ""))

        water_nodes.append(_node(
            source_node_id, network_id, plant_id, &"groundwater_source",
            source_cell, host_settlement_id, treatment_cell, service_radius
        ))
        water_nodes.append(_node(
            treatment_node_id, network_id, plant_id, &"treatment_storage",
            treatment_cell, host_settlement_id, treatment_cell, service_radius
        ))
        water_nodes.append(_node(
            service_node_id, network_id, plant_id, &"regional_service_anchor",
            center, host_settlement_id, treatment_cell, service_radius
        ))

        var source_segment: Dictionary = _segment(
            "water.segment.plant.%03d.01" % plant_number,
            network_id,
            plant_id,
            1,
            source_cell,
            treatment_cell,
            source_road_id,
            source_route_id
        )
        var service_segment: Dictionary = _segment(
            "water.segment.plant.%03d.02" % plant_number,
            network_id,
            plant_id,
            2,
            treatment_cell,
            center,
            source_road_id,
            source_route_id
        )
        if source_segment.is_empty() or service_segment.is_empty():
            return _failure("water_regional_plant_internal_link_invalid")
        water_segments.append(source_segment)
        water_segments.append(service_segment)
        plants.append({
            "plant_id": plant_id,
            "network_id": network_id,
            "host_settlement_id": host_settlement_id,
            "source_node_id": source_node_id,
            "treatment_node_id": treatment_node_id,
            "service_anchor_node_id": service_node_id,
            "coverage_center": treatment_cell,
            "service_radius": service_radius,
        })

    for index in range(settlements.size()):
        var settlement: Dictionary = settlements[index]
        var settlement_id: String = String(settlement.get("id", ""))
        var center: Vector2i = settlement.get("center", INVALID_CELL)
        if settlement_id.is_empty() or center == INVALID_CELL:
            return _failure("water_service_settlement_invalid")
        var plant: Dictionary = _nearest_covering_plant(center, plants)
        if plant.is_empty():
            return _failure("water_settlement_outside_regional_service")
        water_services.append({
            "id": "water.service.%03d" % [index + 1],
            "settlement_id": settlement_id,
            "service_mode": &"municipal" if settlement_id == SMALLTOWN_ID else &"regional_radius",
            "source_type": &"groundwater",
            "network_id": String(plant.get("network_id", "")),
            "plant_id": String(plant.get("plant_id", "")),
            "plant_host_settlement_id": String(plant.get("host_settlement_id", "")),
            "source_node_id": String(plant.get("source_node_id", "")),
            "treatment_node_id": String(plant.get("treatment_node_id", "")),
            "service_anchor_node_id": String(plant.get("service_anchor_node_id", "")),
            "coverage_center": plant.get("coverage_center", INVALID_CELL),
            "service_radius": int(plant.get("service_radius", 0)),
        })

    return {
        "ok": true,
        "failure_reason": "",
        "water_services": water_services,
        "water_nodes": water_nodes,
        "water_segments": water_segments,
    }

func _nearest_covering_plant(cell: Vector2i, plants: Array[Dictionary]) -> Dictionary:
    var best: Dictionary = {}
    var best_distance_sq: int = 2147483647
    for plant: Dictionary in plants:
        var center: Vector2i = plant.get("coverage_center", INVALID_CELL)
        var radius: int = int(plant.get("service_radius", 0))
        if center == INVALID_CELL or radius <= 0:
            continue
        var delta: Vector2i = cell - center
        var distance_sq: int = delta.x * delta.x + delta.y * delta.y
        if distance_sq > radius * radius:
            continue
        var plant_id: String = String(plant.get("plant_id", ""))
        var best_id: String = String(best.get("plant_id", ""))
        if distance_sq < best_distance_sq \
            or (distance_sq == best_distance_sq and (best_id.is_empty() or plant_id < best_id)):
            best = plant
            best_distance_sq = distance_sq
    return best

func _node(
    id: String,
    network_id: String,
    plant_id: String,
    kind: StringName,
    cell: Vector2i,
    host_settlement_id: String,
    coverage_center: Vector2i,
    service_radius: int
) -> Dictionary:
    return {
        "id": id,
        "network_id": network_id,
        "plant_id": plant_id,
        "kind": kind,
        "cell": cell,
        "settlement_id": host_settlement_id,
        "host_settlement_id": host_settlement_id,
        "coverage_center": coverage_center,
        "service_radius": service_radius,
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
    network_id: String,
    plant_id: String,
    ordinal: int,
    start: Vector2i,
    finish: Vector2i,
    source_road_id: String,
    source_route_id: String
) -> Dictionary:
    if id.is_empty() or network_id.is_empty() or plant_id.is_empty() or start == finish \
        or (start.x != finish.x and start.y != finish.y):
        return {}
    if source_road_id.is_empty() or source_route_id.is_empty():
        return {}
    return {
        "id": id,
        "network_id": network_id,
        "plant_id": plant_id,
        "water_class": &"plant_internal",
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

func _site_for_settlement(sites: Array[Dictionary], settlement_id: String) -> Dictionary:
    for site: Dictionary in sites:
        if String(site.get("settlement_id", "")) == settlement_id:
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
