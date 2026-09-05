extends RefCounted
class_name GlobalWaterInfrastructureValidator

const INVALID_CELL := Vector2i(-999999, -999999)
const PLANT_ID: String = "water.plant.001"
const NETWORK_ID: String = "water.network.municipal.001"
const CRITICAL_ASSET_ID: String = "water.physical.plant.001"
const MAX_SHORE_DISTANCE: int = 96

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
        var settlement_id: String = String(settlement.get("id", "")).strip_edges()
        if settlement_id.is_empty():
            failures.append("global_water_settlement_id_missing")
        else:
            settlements[settlement_id] = settlement

    if plan.water_nodes.size() != 3:
        failures.append("global_water_single_plant_node_count_invalid")
    var nodes_by_kind: Dictionary = {}
    var nodes_by_id: Dictionary = {}
    var treatment_cell: Vector2i = INVALID_CELL
    for node: Dictionary in plan.water_nodes:
        var node_id: String = String(node.get("id", "")).strip_edges()
        _claim_water_id(all_ids, node_id, failures)
        if node_id.is_empty():
            continue
        nodes_by_id[node_id] = node
        var kind: StringName = StringName(node.get("kind", &""))
        if not [&"raw_water_source", &"treatment_plant", &"island_service_anchor"].has(kind):
            failures.append("global_water_plant_node_kind_invalid")
            continue
        if nodes_by_kind.has(kind):
            failures.append("global_water_plant_node_kind_duplicate")
        nodes_by_kind[kind] = node
        if String(node.get("plant_id", "")) != PLANT_ID or String(node.get("network_id", "")) != NETWORK_ID:
            failures.append("global_water_single_plant_identity_invalid")
        if not bool(node.get("island_wide", false)):
            failures.append("global_water_node_must_be_island_wide")
        if node.has("service_radius") and int(node.get("service_radius", 0)) > 0:
            failures.append("global_water_radius_model_must_be_absent")
        var cell: Vector2i = node.get("cell", INVALID_CELL)
        if cell == INVALID_CELL or not plan.bounds.has_point(cell):
            failures.append("global_water_plant_node_out_of_bounds")
        if kind == &"treatment_plant":
            treatment_cell = cell
            if String(node.get("critical_asset_id", "")) != CRITICAL_ASSET_ID:
                failures.append("global_water_critical_asset_identity_invalid")

    if nodes_by_kind.size() != 3:
        failures.append("global_water_plant_required_nodes_missing")
    if treatment_cell != INVALID_CELL:
        var shore_distance: int = _distance_to_bounds_edge(treatment_cell, plan.bounds)
        if shore_distance <= 0 or shore_distance > MAX_SHORE_DISTANCE:
            failures.append("global_water_treatment_not_near_shore")

    if plan.water_segments.size() != 2:
        failures.append("global_water_single_plant_segment_count_invalid")
    var edges: Dictionary = {}
    for segment: Dictionary in plan.water_segments:
        _claim_water_id(all_ids, String(segment.get("id", "")), failures)
        if String(segment.get("plant_id", "")) != PLANT_ID or String(segment.get("network_id", "")) != NETWORK_ID:
            failures.append("global_water_segment_identity_invalid")
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
        edges[_edge_key(start, finish)] = true

    if nodes_by_kind.has(&"raw_water_source") and nodes_by_kind.has(&"treatment_plant") and nodes_by_kind.has(&"island_service_anchor"):
        var source: Vector2i = (nodes_by_kind[&"raw_water_source"] as Dictionary).get("cell", INVALID_CELL)
        var treatment: Vector2i = (nodes_by_kind[&"treatment_plant"] as Dictionary).get("cell", INVALID_CELL)
        var service_cell: Vector2i = (nodes_by_kind[&"island_service_anchor"] as Dictionary).get("cell", INVALID_CELL)
        if not edges.has(_edge_key(source, treatment)) or not edges.has(_edge_key(treatment, service_cell)):
            failures.append("global_water_plant_internal_topology_invalid")

    var service_by_settlement: Dictionary = {}
    for service: Dictionary in plan.water_services:
        _claim_water_id(all_ids, String(service.get("id", "")), failures)
        var settlement_id: String = String(service.get("settlement_id", "")).strip_edges()
        if settlement_id.is_empty() or not settlements.has(settlement_id):
            failures.append("global_water_service_settlement_missing")
            continue
        if service_by_settlement.has(settlement_id):
            failures.append("global_water_service_duplicate")
        service_by_settlement[settlement_id] = true
        if StringName(service.get("service_mode", &"")) != &"island_wide_municipal":
            failures.append("global_water_service_mode_invalid")
        if StringName(service.get("source_type", &"")) != &"treated_municipal":
            failures.append("global_water_source_type_invalid")
        if String(service.get("plant_id", "")) != PLANT_ID or String(service.get("network_id", "")) != NETWORK_ID:
            failures.append("global_water_service_plant_identity_invalid")
        if String(service.get("critical_asset_id", "")) != CRITICAL_ASSET_ID:
            failures.append("global_water_service_critical_asset_invalid")
        if not bool(service.get("island_wide", false)):
            failures.append("global_water_service_not_island_wide")
        if service.has("service_radius") and int(service.get("service_radius", 0)) > 0:
            failures.append("global_water_service_radius_model_must_be_absent")
        var source_node_id: String = String(service.get("source_node_id", ""))
        var treatment_node_id: String = String(service.get("treatment_node_id", ""))
        var anchor_node_id: String = String(service.get("service_anchor_node_id", ""))
        if not nodes_by_id.has(source_node_id) or not nodes_by_id.has(treatment_node_id) or not nodes_by_id.has(anchor_node_id):
            failures.append("global_water_service_node_binding_invalid")

    if plan.water_services.size() != settlements.size() or service_by_settlement.size() != settlements.size():
        failures.append("global_water_service_count_invalid")
    for settlement_id: String in settlements.keys():
        if not service_by_settlement.has(settlement_id):
            failures.append("global_water_settlement_service_missing")

    return {"ok": failures.is_empty(), "failures": failures}

func _distance_to_bounds_edge(cell: Vector2i, bounds: Rect2i) -> int:
    var horizontal: int = mini(cell.x - bounds.position.x, bounds.end.x - 1 - cell.x)
    var vertical: int = mini(cell.y - bounds.position.y, bounds.end.y - 1 - cell.y)
    return mini(horizontal, vertical)

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

func _edge_key(a: Vector2i, b: Vector2i) -> String:
    if a.y < b.y or (a.y == b.y and a.x <= b.x):
        return "%d,%d>%d,%d" % [a.x, a.y, b.x, b.y]
    return "%d,%d>%d,%d" % [b.x, b.y, a.x, a.y]
