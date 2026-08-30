extends RefCounted
class_name GlobalWaterInfrastructureValidator

const QueryClass = preload("res://scripts/generation/world/GlobalWaterInfrastructureQuery.gd")

const INVALID_CELL := Vector2i(-999999, -999999)
const REGIONAL_PLANT_COUNT: int = 4
const SMALLTOWN_ID: String = "settlement.smalltown.001"
const CENTRAL_SETTLEMENT_ID: String = "settlement.rural.crossroads.001"
const EXPECTED_PLANT_HOSTS: Dictionary = {
    SMALLTOWN_ID: true,
    "settlement.rural.hamlet.001": true,
    "settlement.rural.hamlet.002": true,
    "settlement.rural.hamlet.003": true,
}

var _query: GlobalWaterInfrastructureQuery

func _init() -> void:
    _query = QueryClass.new()

func validate(request: GlobalWorldGenerationRequest, plan: GeneratedGlobalWorldPlan) -> Dictionary:
    var failures: Array[String] = []
    if request == null or not request.is_valid() or plan == null:
        return {"ok": false, "failures": ["invalid_global_water_validation_input"]}
    if plan.water_services.is_empty():
        failures.append("global_water_services_missing")
    if plan.water_nodes.is_empty():
        failures.append("global_water_nodes_missing")
    if plan.water_segments.is_empty():
        failures.append("global_water_segments_missing")
    if not failures.is_empty():
        return {"ok": false, "failures": failures}

    var all_ids: Dictionary = {}
    _claim_existing_plan_ids(plan, all_ids)

    var settlements: Dictionary = {}
    for settlement: Dictionary in plan.settlements:
        var settlement_id: String = String(settlement.get("id", ""))
        settlements[settlement_id] = settlement

    var nodes_by_id: Dictionary = {}
    var plant_records: Dictionary = {}
    var host_counts: Dictionary = {}
    for node: Dictionary in plan.water_nodes:
        var node_id: String = String(node.get("id", ""))
        _claim_water_id(all_ids, node_id, failures)
        if node_id.is_empty():
            continue
        nodes_by_id[node_id] = node
        var plant_id: String = String(node.get("plant_id", ""))
        var network_id: String = String(node.get("network_id", ""))
        var host_id: String = String(node.get("host_settlement_id", node.get("settlement_id", "")))
        var kind: StringName = StringName(node.get("kind", &""))
        var cell: Vector2i = node.get("cell", INVALID_CELL)
        var coverage_center: Vector2i = node.get("coverage_center", INVALID_CELL)
        var radius: int = int(node.get("service_radius", 0))
        if plant_id.is_empty() or network_id.is_empty() or host_id.is_empty():
            failures.append("global_water_plant_identity_missing")
            continue
        if not EXPECTED_PLANT_HOSTS.has(host_id) or not settlements.has(host_id):
            failures.append("global_water_plant_host_invalid")
        if cell == INVALID_CELL or not plan.bounds.has_point(cell):
            failures.append("global_water_plant_node_out_of_bounds")
        if coverage_center == INVALID_CELL or radius <= 0:
            failures.append("global_water_plant_coverage_invalid")
        if not _point_on_any_road(cell, plan.road_segments):
            failures.append("global_water_plant_node_off_major_road")
        var host_site: Dictionary = _site_for_settlement(plan.area_sites, host_id)
        if host_site.is_empty() or not (host_site.get("bounds", Rect2i()) as Rect2i).has_point(cell):
            failures.append("global_water_plant_node_outside_host_site")
        if not [&"groundwater_source", &"treatment_storage", &"regional_service_anchor"].has(kind):
            failures.append("global_water_plant_node_kind_invalid")

        if not plant_records.has(plant_id):
            plant_records[plant_id] = {
                "network_id": network_id,
                "host_settlement_id": host_id,
                "coverage_center": coverage_center,
                "service_radius": radius,
                "nodes": {},
                "segment_count": 0,
            }
            host_counts[host_id] = int(host_counts.get(host_id, 0)) + 1
        var plant: Dictionary = plant_records[plant_id]
        if String(plant.get("network_id", "")) != network_id \
            or String(plant.get("host_settlement_id", "")) != host_id \
            or plant.get("coverage_center", INVALID_CELL) != coverage_center \
            or int(plant.get("service_radius", 0)) != radius:
            failures.append("global_water_plant_node_metadata_mismatch")
        var kind_nodes: Dictionary = plant.get("nodes", {})
        if kind_nodes.has(kind):
            failures.append("global_water_plant_node_kind_duplicate")
        kind_nodes[kind] = node_id
        plant["nodes"] = kind_nodes
        plant_records[plant_id] = plant

    if plant_records.size() != REGIONAL_PLANT_COUNT:
        failures.append("global_water_regional_plant_count_invalid")
    if plan.water_nodes.size() != REGIONAL_PLANT_COUNT * 3:
        failures.append("global_water_node_count_invalid")
    for host_id: String in EXPECTED_PLANT_HOSTS.keys():
        if int(host_counts.get(host_id, 0)) != 1:
            failures.append("global_water_required_plant_host_missing")
    if host_counts.has(CENTRAL_SETTLEMENT_ID):
        failures.append("global_water_crossroads_must_not_have_private_source")

    for segment: Dictionary in plan.water_segments:
        _claim_water_id(all_ids, String(segment.get("id", "")), failures)
        var plant_id: String = String(segment.get("plant_id", ""))
        var network_id: String = String(segment.get("network_id", ""))
        if not plant_records.has(plant_id):
            failures.append("global_water_segment_plant_missing")
            continue
        var plant: Dictionary = plant_records[plant_id]
        if String(plant.get("network_id", "")) != network_id:
            failures.append("global_water_segment_network_mismatch")
        if StringName(segment.get("water_class", &"")) != &"plant_internal":
            failures.append("global_water_segment_class_invalid")
        var start: Vector2i = segment.get("start", INVALID_CELL)
        var finish: Vector2i = segment.get("end", INVALID_CELL)
        if start == INVALID_CELL or finish == INVALID_CELL or start == finish \
            or (start.x != finish.x and start.y != finish.y):
            failures.append("global_water_segment_not_cardinal")
            continue
        if not plan.bounds.has_point(start) or not plan.bounds.has_point(finish):
            failures.append("global_water_segment_out_of_bounds")
        var source_road_id: String = String(segment.get("source_road_id", ""))
        var source_route_id: String = String(segment.get("source_route_id", ""))
        var source_road: Dictionary = _road_by_id(plan.road_segments, source_road_id)
        if source_road.is_empty():
            failures.append("global_water_source_road_missing")
        else:
            if String(source_road.get("route_id", "")) != source_route_id:
                failures.append("global_water_source_route_mismatch")
            if not _query.segment_contained_in(segment, source_road):
                failures.append("global_water_segment_off_source_road")
        plant["segment_count"] = int(plant.get("segment_count", 0)) + 1
        plant_records[plant_id] = plant

    if plan.water_segments.size() != REGIONAL_PLANT_COUNT * 2:
        failures.append("global_water_segment_count_invalid")
    for plant_id: String in plant_records.keys():
        var plant: Dictionary = plant_records[plant_id]
        var kind_nodes: Dictionary = plant.get("nodes", {})
        if kind_nodes.size() != 3 \
            or not kind_nodes.has(&"groundwater_source") \
            or not kind_nodes.has(&"treatment_storage") \
            or not kind_nodes.has(&"regional_service_anchor"):
            failures.append("global_water_plant_required_nodes_missing")
            continue
        if int(plant.get("segment_count", 0)) != 2:
            failures.append("global_water_plant_segment_count_invalid")
        var source: Dictionary = nodes_by_id.get(String(kind_nodes[&"groundwater_source"]), {})
        var treatment: Dictionary = nodes_by_id.get(String(kind_nodes[&"treatment_storage"]), {})
        var service_anchor: Dictionary = nodes_by_id.get(String(kind_nodes[&"regional_service_anchor"]), {})
        var source_cell: Vector2i = source.get("cell", INVALID_CELL)
        var treatment_cell: Vector2i = treatment.get("cell", INVALID_CELL)
        var service_cell: Vector2i = service_anchor.get("cell", INVALID_CELL)
        if plant.get("coverage_center", INVALID_CELL) != treatment_cell:
            failures.append("global_water_plant_coverage_center_mismatch")
        if not _has_plant_edge(plan.water_segments, plant_id, source_cell, treatment_cell) \
            or not _has_plant_edge(plan.water_segments, plant_id, treatment_cell, service_cell):
            failures.append("global_water_plant_internal_topology_invalid")

    var service_by_settlement: Dictionary = {}
    for service: Dictionary in plan.water_services:
        _claim_water_id(all_ids, String(service.get("id", "")), failures)
        var settlement_id: String = String(service.get("settlement_id", ""))
        var plant_id: String = String(service.get("plant_id", ""))
        var mode: StringName = StringName(service.get("service_mode", &""))
        if settlement_id.is_empty() or not settlements.has(settlement_id):
            failures.append("global_water_service_settlement_missing")
            continue
        if service_by_settlement.has(settlement_id):
            failures.append("global_water_service_duplicate")
        service_by_settlement[settlement_id] = true
        if mode == &"decentralized_source":
            failures.append("global_water_private_source_forbidden")
        if settlement_id == SMALLTOWN_ID:
            if mode != &"municipal":
                failures.append("global_water_smalltown_service_mode_invalid")
        elif mode != &"regional_radius":
            failures.append("global_water_regional_service_mode_invalid")
        if StringName(service.get("source_type", &"")) != &"groundwater":
            failures.append("global_water_source_type_invalid")
        if not plant_records.has(plant_id):
            failures.append("global_water_service_plant_missing")
            continue
        var plant: Dictionary = plant_records[plant_id]
        if String(service.get("network_id", "")) != String(plant.get("network_id", "")) \
            or String(service.get("plant_host_settlement_id", "")) != String(plant.get("host_settlement_id", "")) \
            or service.get("coverage_center", INVALID_CELL) != plant.get("coverage_center", INVALID_CELL) \
            or int(service.get("service_radius", 0)) != int(plant.get("service_radius", 0)):
            failures.append("global_water_service_plant_metadata_mismatch")
        var kind_nodes: Dictionary = plant.get("nodes", {})
        if String(service.get("source_node_id", "")) != String(kind_nodes.get(&"groundwater_source", "")) \
            or String(service.get("treatment_node_id", "")) != String(kind_nodes.get(&"treatment_storage", "")) \
            or String(service.get("service_anchor_node_id", "")) != String(kind_nodes.get(&"regional_service_anchor", "")):
            failures.append("global_water_service_node_binding_invalid")
        var settlement: Dictionary = settlements[settlement_id]
        var center: Vector2i = settlement.get("center", INVALID_CELL)
        var coverage_center: Vector2i = service.get("coverage_center", INVALID_CELL)
        var radius: int = int(service.get("service_radius", 0))
        if not _cell_within_radius(center, coverage_center, radius):
            failures.append("global_water_settlement_outside_service_radius")
        var resolved: Dictionary = _query.service_for_cell(plan.water_services, center)
        if resolved.is_empty() or String(resolved.get("plant_id", "")) != plant_id:
            failures.append("global_water_settlement_radius_resolution_mismatch")

    if plan.water_services.size() != settlements.size() or service_by_settlement.size() != settlements.size():
        failures.append("global_water_service_count_invalid")
    for settlement_id: String in settlements.keys():
        if not service_by_settlement.has(settlement_id):
            failures.append("global_water_settlement_service_missing")

    return {"ok": failures.is_empty(), "failures": failures}

func _claim_existing_plan_ids(plan: GeneratedGlobalWorldPlan, ids: Dictionary) -> void:
    for geography: Dictionary in plan.geography_cells:
        ids[String(geography.get("id", ""))] = true
    for river: Dictionary in plan.river_segments:
        ids[String(river.get("segment_id", ""))] = true
    for region: Dictionary in plan.regions:
        ids[String(region.get("id", ""))] = true
    for settlement: Dictionary in plan.settlements:
        ids[String(settlement.get("id", ""))] = true
    for road: Dictionary in plan.road_segments:
        ids[String(road.get("road_id", ""))] = true
    for bridge: Dictionary in plan.bridge_intents:
        ids[String(bridge.get("id", ""))] = true
    for power_node: Dictionary in plan.power_nodes:
        ids[String(power_node.get("id", ""))] = true
    for power_segment: Dictionary in plan.power_segments:
        ids[String(power_segment.get("id", ""))] = true
    for site: Dictionary in plan.area_sites:
        ids[String(site.get("id", ""))] = true

func _claim_water_id(ids: Dictionary, id: String, failures: Array[String]) -> void:
    if id.strip_edges().is_empty():
        failures.append("global_water_id_missing")
        return
    if ids.has(id):
        failures.append("global_water_id_duplicate")
        return
    ids[id] = true

func _site_for_settlement(sites: Array[Dictionary], settlement_id: String) -> Dictionary:
    for site: Dictionary in sites:
        if String(site.get("settlement_id", "")) == settlement_id:
            return site
    return {}

func _point_on_any_road(point: Vector2i, roads: Array[Dictionary]) -> bool:
    for road: Dictionary in roads:
        if _query.point_on_segment(point, road):
            return true
    return false

func _road_by_id(roads: Array[Dictionary], road_id: String) -> Dictionary:
    for road: Dictionary in roads:
        if String(road.get("road_id", "")) == road_id:
            return road
    return {}

func _has_plant_edge(segments: Array[Dictionary], plant_id: String, a: Vector2i, b: Vector2i) -> bool:
    var wanted: String = _edge_key(a, b)
    for segment: Dictionary in segments:
        if String(segment.get("plant_id", "")) != plant_id:
            continue
        if _edge_key(segment.get("start", INVALID_CELL), segment.get("end", INVALID_CELL)) == wanted:
            return true
    return false

func _edge_key(a: Vector2i, b: Vector2i) -> String:
    if a.y < b.y or (a.y == b.y and a.x <= b.x):
        return "%d,%d>%d,%d" % [a.x, a.y, b.x, b.y]
    return "%d,%d>%d,%d" % [b.x, b.y, a.x, a.y]

func _cell_within_radius(cell: Vector2i, center: Vector2i, radius: int) -> bool:
    if cell == INVALID_CELL or center == INVALID_CELL or radius <= 0:
        return false
    var delta: Vector2i = cell - center
    return delta.x * delta.x + delta.y * delta.y <= radius * radius
