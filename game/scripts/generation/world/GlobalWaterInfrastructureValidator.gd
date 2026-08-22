extends RefCounted
class_name GlobalWaterInfrastructureValidator

const QueryClass = preload("res://scripts/generation/world/GlobalWaterInfrastructureQuery.gd")

const INVALID_CELL := Vector2i(-999999, -999999)
const NETWORK_ID: String = "water.network.municipal.smalltown.001"
const SMALLTOWN_ID: String = "settlement.smalltown.001"

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

    var known_settlements: Dictionary = {}
    for settlement: Dictionary in plan.settlements:
        known_settlements[String(settlement.get("id", ""))] = settlement.get("center", INVALID_CELL)

    var expected_rural: Dictionary = {
        "settlement.rural.crossroads.001": true,
        "settlement.rural.hamlet.001": true,
        "settlement.rural.hamlet.002": true,
        "settlement.rural.hamlet.003": true,
    }
    var service_by_settlement: Dictionary = {}
    var municipal_count: int = 0

    for service: Dictionary in plan.water_services:
        _claim_water_id(all_ids, String(service.get("id", "")), failures)
        var settlement_id: String = String(service.get("settlement_id", ""))
        if settlement_id.is_empty() or not known_settlements.has(settlement_id):
            failures.append("global_water_service_settlement_missing")
            continue
        if service_by_settlement.has(settlement_id):
            failures.append("global_water_service_duplicate")
        service_by_settlement[settlement_id] = true

        var mode: StringName = StringName(service.get("service_mode", &""))
        var source_type: StringName = StringName(service.get("source_type", &""))
        var network_id: String = String(service.get("network_id", ""))
        if source_type != &"groundwater":
            failures.append("global_water_source_type_invalid")
        if settlement_id == SMALLTOWN_ID:
            if mode != &"municipal":
                failures.append("global_water_smalltown_not_municipal")
            if network_id != NETWORK_ID:
                failures.append("global_water_smalltown_network_invalid")
            municipal_count += 1
        elif expected_rural.has(settlement_id):
            if mode != &"decentralized_source":
                failures.append("global_water_rural_service_not_decentralized")
            if not network_id.is_empty():
                failures.append("global_water_decentralized_claims_network")
        else:
            failures.append("global_water_current_settlement_unsupported")

    if plan.water_services.size() != known_settlements.size() or service_by_settlement.size() != known_settlements.size():
        failures.append("global_water_service_count_invalid")
    for settlement_id_value: Variant in known_settlements.keys():
        if not service_by_settlement.has(settlement_id_value):
            failures.append("global_water_settlement_service_missing")
    if municipal_count != 1:
        failures.append("global_water_municipal_service_count_invalid")

    var smalltown_site: Dictionary = _site_for_settlement(plan.area_sites, SMALLTOWN_ID)
    if smalltown_site.is_empty():
        failures.append("global_water_smalltown_site_missing")
    var site_bounds: Rect2i = smalltown_site.get("bounds", Rect2i())
    var smalltown_center: Vector2i = known_settlements.get(SMALLTOWN_ID, INVALID_CELL)

    var node_counts: Dictionary = {
        &"groundwater_source": 0,
        &"treatment_storage": 0,
        &"settlement_service": 0,
    }
    var node_cells: Dictionary = {}
    for node: Dictionary in plan.water_nodes:
        _claim_water_id(all_ids, String(node.get("id", "")), failures)
        if String(node.get("network_id", "")) != NETWORK_ID:
            failures.append("global_water_node_network_invalid")
        if String(node.get("settlement_id", "")) != SMALLTOWN_ID:
            failures.append("global_water_node_not_smalltown")
        var cell: Vector2i = node.get("cell", INVALID_CELL)
        if cell == INVALID_CELL or not plan.bounds.has_point(cell):
            failures.append("global_water_node_out_of_bounds")
        if not site_bounds.has_point(cell):
            failures.append("global_water_node_outside_smalltown_site")
        if not _point_on_any_road(cell, plan.road_segments):
            failures.append("global_water_node_off_major_road")
        if _is_boundary_cell(plan.bounds, cell):
            failures.append("global_water_node_on_world_boundary")

        var kind: StringName = StringName(node.get("kind", &""))
        if not node_counts.has(kind):
            failures.append("global_water_node_kind_invalid")
            continue
        node_counts[kind] = int(node_counts[kind]) + 1
        if node_cells.has(kind):
            failures.append("global_water_node_kind_duplicate")
        node_cells[kind] = cell

    if plan.water_nodes.size() != 3:
        failures.append("global_water_node_count_invalid")
    for count_value: Variant in node_counts.values():
        if int(count_value) != 1:
            failures.append("global_water_required_node_count_invalid")
    if node_cells.get(&"settlement_service", INVALID_CELL) != smalltown_center:
        failures.append("global_water_service_node_location_mismatch")
    var source_cell: Vector2i = node_cells.get(&"groundwater_source", INVALID_CELL)
    var treatment_cell: Vector2i = node_cells.get(&"treatment_storage", INVALID_CELL)
    var service_cell: Vector2i = node_cells.get(&"settlement_service", INVALID_CELL)
    if source_cell == treatment_cell or source_cell == service_cell or treatment_cell == service_cell:
        failures.append("global_water_node_cells_not_distinct")

    var edge_keys: Dictionary = {}
    for segment: Dictionary in plan.water_segments:
        _claim_water_id(all_ids, String(segment.get("id", "")), failures)
        if String(segment.get("network_id", "")) != NETWORK_ID:
            failures.append("global_water_segment_network_invalid")
        if StringName(segment.get("water_class", &"")) != &"municipal_trunk":
            failures.append("global_water_segment_class_invalid")
        var start: Vector2i = segment.get("start", INVALID_CELL)
        var finish: Vector2i = segment.get("end", INVALID_CELL)
        if start == INVALID_CELL or finish == INVALID_CELL or start == finish or (start.x != finish.x and start.y != finish.y):
            failures.append("global_water_segment_not_cardinal")
            continue
        if not plan.bounds.has_point(start) or not plan.bounds.has_point(finish):
            failures.append("global_water_segment_out_of_bounds")
        if not site_bounds.has_point(start) or not site_bounds.has_point(finish):
            failures.append("global_water_segment_outside_smalltown_site")
        if _is_boundary_cell(plan.bounds, start) or _is_boundary_cell(plan.bounds, finish):
            failures.append("global_water_segment_reaches_world_boundary")

        var edge_key: String = _edge_key(start, finish)
        if edge_keys.has(edge_key):
            failures.append("global_water_segment_duplicate")
        edge_keys[edge_key] = true

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
        if _segment_intersects_ridge(segment, plan.geography_cells):
            failures.append("global_water_crosses_ridge")

    if plan.water_segments.size() != 2:
        failures.append("global_water_segment_count_invalid")
    if source_cell != INVALID_CELL and treatment_cell != INVALID_CELL and service_cell != INVALID_CELL:
        if not _has_edge(plan.water_segments, source_cell, treatment_cell):
            failures.append("global_water_source_treatment_link_missing")
        if not _has_edge(plan.water_segments, treatment_cell, service_cell):
            failures.append("global_water_treatment_service_link_missing")
        var reachable: Dictionary = _query.reachable_nodes_from(source_cell, plan.water_segments)
        if not reachable.has(treatment_cell) or not reachable.has(service_cell):
            failures.append("global_water_required_node_unreachable")
        for segment: Dictionary in plan.water_segments:
            if not reachable.has(segment.get("start", INVALID_CELL)) or not reachable.has(segment.get("end", INVALID_CELL)):
                failures.append("global_water_orphan_segment")
                break

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
        if _point_on_segment(point, road):
            return true
    return false

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

func _road_by_id(roads: Array[Dictionary], road_id: String) -> Dictionary:
    for road: Dictionary in roads:
        if String(road.get("road_id", "")) == road_id:
            return road
    return {}

func _has_edge(segments: Array[Dictionary], a: Vector2i, b: Vector2i) -> bool:
    var wanted: String = _edge_key(a, b)
    for segment: Dictionary in segments:
        if _edge_key(segment.get("start", INVALID_CELL), segment.get("end", INVALID_CELL)) == wanted:
            return true
    return false

func _segment_intersects_ridge(segment: Dictionary, geography_cells: Array[Dictionary]) -> bool:
    var start: Vector2i = segment.get("start", INVALID_CELL)
    var finish: Vector2i = segment.get("end", INVALID_CELL)
    for geography: Dictionary in geography_cells:
        if StringName(geography.get("landform", &"")) != &"ridge":
            continue
        var rect: Rect2i = geography.get("rect", Rect2i())
        var max_x: int = rect.position.x + rect.size.x - 1
        var max_y: int = rect.position.y + rect.size.y - 1
        if start.y == finish.y:
            if start.y >= rect.position.y and start.y <= max_y and _ranges_overlap(mini(start.x, finish.x), maxi(start.x, finish.x), rect.position.x, max_x):
                return true
        elif start.x == finish.x:
            if start.x >= rect.position.x and start.x <= max_x and _ranges_overlap(mini(start.y, finish.y), maxi(start.y, finish.y), rect.position.y, max_y):
                return true
    return false

func _edge_key(a: Vector2i, b: Vector2i) -> String:
    if a.y < b.y or (a.y == b.y and a.x <= b.x):
        return "%d,%d>%d,%d" % [a.x, a.y, b.x, b.y]
    return "%d,%d>%d,%d" % [b.x, b.y, a.x, a.y]

func _ranges_overlap(a_min: int, a_max: int, b_min: int, b_max: int) -> bool:
    return a_min <= b_max and b_min <= a_max

func _is_boundary_cell(rect: Rect2i, cell: Vector2i) -> bool:
    if not rect.has_point(cell):
        return false
    var max_x: int = rect.position.x + rect.size.x - 1
    var max_y: int = rect.position.y + rect.size.y - 1
    return cell.x == rect.position.x or cell.x == max_x or cell.y == rect.position.y or cell.y == max_y
