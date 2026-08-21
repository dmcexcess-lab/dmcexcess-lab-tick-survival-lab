extends RefCounted
class_name GlobalPowerInfrastructureValidator

const QueryClass = preload("res://scripts/generation/world/GlobalPowerInfrastructureQuery.gd")

const INVALID_CELL := Vector2i(-999999, -999999)

var _query: GlobalPowerInfrastructureQuery

func _init() -> void:
    _query = QueryClass.new()

func validate(request: GlobalWorldGenerationRequest, plan: GeneratedGlobalWorldPlan) -> Dictionary:
    var failures: Array[String] = []
    if request == null or not request.is_valid() or plan == null:
        return {"ok": false, "failures": ["invalid_global_power_validation_input"]}
    if plan.power_nodes.is_empty():
        failures.append("global_power_nodes_missing")
    if plan.power_segments.is_empty():
        failures.append("global_power_segments_missing")
    if not failures.is_empty():
        return {"ok": false, "failures": failures}

    var all_ids: Dictionary = {}
    _claim_existing_plan_ids(plan, all_ids)
    var ingress_count: int = 0
    var substation_count: int = 0
    var ingress_cell: Vector2i = INVALID_CELL
    var service_by_settlement: Dictionary = {}
    var known_settlements: Dictionary = {}
    for settlement: Dictionary in plan.settlements:
        known_settlements[String(settlement.get("id", ""))] = settlement.get("center", INVALID_CELL)

    for node: Dictionary in plan.power_nodes:
        _claim_power_id(all_ids, String(node.get("id", "")), failures)
        if String(node.get("network_id", "")) != "power.network.regional.001":
            failures.append("global_power_node_network_invalid")
        var cell: Vector2i = node.get("cell", INVALID_CELL)
        if cell == INVALID_CELL or not plan.bounds.has_point(cell):
            failures.append("global_power_node_out_of_bounds")
        if not _point_on_any_road(cell, plan.road_segments):
            failures.append("global_power_node_off_major_road")
        var kind: StringName = StringName(node.get("kind", &""))
        var settlement_id: String = String(node.get("settlement_id", ""))
        match kind:
            &"regional_ingress":
                ingress_count += 1
                ingress_cell = cell
                if not settlement_id.is_empty():
                    failures.append("global_power_ingress_has_settlement")
                if not _is_boundary_cell(plan.bounds, cell):
                    failures.append("global_power_ingress_not_boundary")
            &"substation":
                substation_count += 1
                if settlement_id != "settlement.smalltown.001":
                    failures.append("global_power_substation_not_smalltown")
                if not known_settlements.has(settlement_id) or known_settlements[settlement_id] != cell:
                    failures.append("global_power_substation_location_mismatch")
            &"settlement_service":
                if settlement_id.is_empty() or not known_settlements.has(settlement_id):
                    failures.append("global_power_service_settlement_missing")
                else:
                    if service_by_settlement.has(settlement_id):
                        failures.append("global_power_service_duplicate")
                    service_by_settlement[settlement_id] = cell
                    if known_settlements[settlement_id] != cell:
                        failures.append("global_power_service_location_mismatch")
            _:
                failures.append("global_power_node_kind_invalid")

    if ingress_count != 1:
        failures.append("global_power_ingress_count_invalid")
    if substation_count != 1:
        failures.append("global_power_substation_count_invalid")
    if service_by_settlement.size() != known_settlements.size():
        failures.append("global_power_service_count_invalid")
    for settlement_id_value: Variant in known_settlements.keys():
        if not service_by_settlement.has(settlement_id_value):
            failures.append("global_power_settlement_unserved")

    var edge_keys: Dictionary = {}
    for segment: Dictionary in plan.power_segments:
        _claim_power_id(all_ids, String(segment.get("id", "")), failures)
        if String(segment.get("network_id", "")) != "power.network.regional.001":
            failures.append("global_power_segment_network_invalid")
        if StringName(segment.get("power_class", &"")) != &"regional_feeder":
            failures.append("global_power_segment_class_invalid")
        var start: Vector2i = segment.get("start", INVALID_CELL)
        var finish: Vector2i = segment.get("end", INVALID_CELL)
        if start == INVALID_CELL or finish == INVALID_CELL or start == finish or (start.x != finish.x and start.y != finish.y):
            failures.append("global_power_segment_not_cardinal")
            continue
        if not plan.bounds.has_point(start) or not plan.bounds.has_point(finish):
            failures.append("global_power_segment_out_of_bounds")
        if _is_boundary_cell(plan.bounds, start) and start != ingress_cell:
            failures.append("global_power_unintended_boundary_endpoint")
        if _is_boundary_cell(plan.bounds, finish) and finish != ingress_cell:
            failures.append("global_power_unintended_boundary_endpoint")
        var edge_key: String = _edge_key(start, finish)
        if edge_keys.has(edge_key):
            failures.append("global_power_segment_duplicate")
        edge_keys[edge_key] = true

        var source_road_id: String = String(segment.get("source_road_id", ""))
        var source_route_id: String = String(segment.get("source_route_id", ""))
        var source_road: Dictionary = _road_by_id(plan.road_segments, source_road_id)
        if source_road.is_empty():
            failures.append("global_power_source_road_missing")
        else:
            if String(source_road.get("route_id", "")) != source_route_id:
                failures.append("global_power_source_route_mismatch")
            if not _query.segment_contained_in(segment, source_road):
                failures.append("global_power_segment_off_source_road")
        if _segment_intersects_ridge(segment, plan.geography_cells):
            failures.append("global_power_crosses_ridge")

    if ingress_cell != INVALID_CELL:
        var reachable: Dictionary = _query.reachable_nodes_from(ingress_cell, plan.power_segments)
        for node: Dictionary in plan.power_nodes:
            var cell: Vector2i = node.get("cell", INVALID_CELL)
            if not reachable.has(cell):
                failures.append("global_power_required_node_unreachable")
        for segment: Dictionary in plan.power_segments:
            if not reachable.has(segment.get("start", INVALID_CELL)) or not reachable.has(segment.get("end", INVALID_CELL)):
                failures.append("global_power_orphan_segment")
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
    for site: Dictionary in plan.area_sites:
        ids[String(site.get("id", ""))] = true

func _claim_power_id(ids: Dictionary, id: String, failures: Array[String]) -> void:
    if id.strip_edges().is_empty():
        failures.append("global_power_id_missing")
        return
    if ids.has(id):
        failures.append("global_power_id_duplicate")
        return
    ids[id] = true

func _point_on_any_road(point: Vector2i, roads: Array[Dictionary]) -> bool:
    for road: Dictionary in roads:
        if _point_on_segment(point, road):
            return true
    return false

func _point_on_segment(point: Vector2i, segment: Dictionary) -> bool:
    var start: Vector2i = segment.get("start", INVALID_CELL)
    var finish: Vector2i = segment.get("end", INVALID_CELL)
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
