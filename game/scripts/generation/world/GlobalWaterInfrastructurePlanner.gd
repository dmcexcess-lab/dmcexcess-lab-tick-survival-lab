extends RefCounted
class_name GlobalWaterInfrastructurePlanner

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")

const INVALID_CELL := Vector2i(-999999, -999999)
const PLANT_ID: String = "water.plant.001"
const NETWORK_ID: String = "water.network.municipal.001"
const SOURCE_NODE_ID: String = "water.node.raw_source.001"
const TREATMENT_NODE_ID: String = "water.node.treatment_plant.001"
const SERVICE_NODE_ID: String = "water.node.island_service.001"
const CRITICAL_ASSET_ID: String = "water.physical.plant.001"

func plan(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    settlements: Array[Dictionary],
    area_sites: Array[Dictionary],
    road_segments: Array[Dictionary]
) -> Dictionary:
    if request == null or not request.is_valid() or profile.is_empty() or settlements.is_empty() \
        or area_sites.is_empty() or road_segments.is_empty():
        return _failure("invalid_water_infrastructure_planner_input")

    var shore_offset: int = int(profile.get("water_plant_shore_offset_cells", 48))
    var internal_spacing: int = int(profile.get("water_plant_internal_spacing_cells", 3))
    if shore_offset <= internal_spacing + 1 or internal_spacing <= 0:
        return _failure("water_island_profile_invalid")
    if request.bounds.size.x <= shore_offset * 2 + 8 or request.bounds.size.y <= shore_offset * 2 + 8:
        return _failure("water_island_bounds_too_small")

    var facility: Dictionary = _shore_facility(request, shore_offset, internal_spacing)
    if facility.is_empty():
        return _failure("water_island_shore_facility_unresolved")
    var source_cell: Vector2i = facility.get("source", INVALID_CELL)
    var treatment_cell: Vector2i = facility.get("treatment", INVALID_CELL)
    var service_cell: Vector2i = facility.get("service", INVALID_CELL)
    if source_cell == INVALID_CELL or treatment_cell == INVALID_CELL or service_cell == INVALID_CELL:
        return _failure("water_island_facility_anchor_invalid")

    var water_nodes: Array[Dictionary] = [
        _node(SOURCE_NODE_ID, &"raw_water_source", source_cell, treatment_cell, ""),
        _node(TREATMENT_NODE_ID, &"treatment_plant", treatment_cell, treatment_cell, CRITICAL_ASSET_ID),
        _node(SERVICE_NODE_ID, &"island_service_anchor", service_cell, treatment_cell, ""),
    ]
    var water_segments: Array[Dictionary] = [
        _segment("water.segment.plant.001.01", 1, source_cell, treatment_cell),
        _segment("water.segment.plant.001.02", 2, treatment_cell, service_cell),
    ]
    for segment: Dictionary in water_segments:
        if segment.is_empty():
            return _failure("water_island_plant_internal_link_invalid")

    var water_services: Array[Dictionary] = []
    for index: int in range(settlements.size()):
        var settlement: Dictionary = settlements[index]
        var settlement_id: String = String(settlement.get("id", "")).strip_edges()
        if settlement_id.is_empty():
            return _failure("water_service_settlement_invalid")
        water_services.append({
            "id": "water.service.%03d" % [index + 1],
            "settlement_id": settlement_id,
            "service_mode": &"island_wide_municipal",
            "source_type": &"treated_municipal",
            "network_id": NETWORK_ID,
            "plant_id": PLANT_ID,
            "source_node_id": SOURCE_NODE_ID,
            "treatment_node_id": TREATMENT_NODE_ID,
            "service_anchor_node_id": SERVICE_NODE_ID,
            "critical_asset_id": CRITICAL_ASSET_ID,
            "island_wide": true,
        })

    return {
        "ok": true,
        "failure_reason": "",
        "water_services": water_services,
        "water_nodes": water_nodes,
        "water_segments": water_segments,
    }

func _shore_facility(request: GlobalWorldGenerationRequest, shore_offset: int, spacing: int) -> Dictionary:
    var edge: int = Seed.choose_index(request.seed, "water:island_plant:shore_edge", 4)
    if edge < 0:
        return {}
    var bounds: Rect2i = request.bounds
    var min_x: int = bounds.position.x + shore_offset
    var max_x: int = bounds.end.x - 1 - shore_offset
    var min_y: int = bounds.position.y + shore_offset
    var max_y: int = bounds.end.y - 1 - shore_offset
    if max_x <= min_x or max_y <= min_y:
        return {}

    var treatment := Vector2i.ZERO
    var outward := Vector2i.ZERO
    if edge == 0 or edge == 2:
        var span_x: int = max_x - min_x + 1
        var offset_x: int = Seed.choose_index(request.seed, "water:island_plant:shore_along_x", span_x)
        if offset_x < 0:
            return {}
        treatment.x = min_x + offset_x
        if edge == 0:
            treatment.y = bounds.position.y + shore_offset
            outward = Vector2i(0, -1)
        else:
            treatment.y = bounds.end.y - 1 - shore_offset
            outward = Vector2i(0, 1)
    else:
        var span_y: int = max_y - min_y + 1
        var offset_y: int = Seed.choose_index(request.seed, "water:island_plant:shore_along_y", span_y)
        if offset_y < 0:
            return {}
        treatment.y = min_y + offset_y
        if edge == 1:
            treatment.x = bounds.end.x - 1 - shore_offset
            outward = Vector2i(1, 0)
        else:
            treatment.x = bounds.position.x + shore_offset
            outward = Vector2i(-1, 0)

    var source: Vector2i = treatment + outward * spacing
    var service: Vector2i = treatment - outward * spacing
    if not bounds.has_point(source) or not bounds.has_point(treatment) or not bounds.has_point(service):
        return {}
    return {"source": source, "treatment": treatment, "service": service, "edge": edge}

func _node(
    id: String,
    kind: StringName,
    cell: Vector2i,
    facility_cell: Vector2i,
    critical_asset_id: String
) -> Dictionary:
    return {
        "id": id,
        "network_id": NETWORK_ID,
        "plant_id": PLANT_ID,
        "kind": kind,
        "cell": cell,
        "settlement_id": "",
        "host_settlement_id": "",
        "facility_cell": facility_cell,
        "critical_asset_id": critical_asset_id,
        "island_wide": true,
    }

func _segment(id: String, ordinal: int, start: Vector2i, finish: Vector2i) -> Dictionary:
    if id.is_empty() or start == finish or (start.x != finish.x and start.y != finish.y):
        return {}
    return {
        "id": id,
        "network_id": NETWORK_ID,
        "plant_id": PLANT_ID,
        "water_class": &"plant_internal",
        "start": start,
        "end": finish,
        "ordinal": ordinal,
        "source_road_id": "",
        "source_route_id": "",
    }

func _failure(reason: String) -> Dictionary:
    return {
        "ok": false,
        "failure_reason": reason,
        "water_services": [],
        "water_nodes": [],
        "water_segments": [],
    }
