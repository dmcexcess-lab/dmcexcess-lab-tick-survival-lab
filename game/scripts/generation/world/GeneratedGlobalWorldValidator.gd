extends RefCounted
class_name GeneratedGlobalWorldValidator

const GeographyQueryClass = preload("res://scripts/generation/world/GlobalGeographyQuery.gd")

var _geography: GlobalGeographyQuery

func _init() -> void:
    _geography = GeographyQueryClass.new()

func validate(request: GlobalWorldGenerationRequest, plan: GeneratedGlobalWorldPlan) -> Dictionary:
    var failures: Array[String] = []
    if request == null or not request.is_valid() or plan == null or not plan.is_generated():
        return {"ok": false, "failures": ["invalid_global_world_plan_input"]}
    if plan.world_id != request.world_id or plan.seed != request.seed or plan.bounds != request.bounds or plan.profile_id != request.profile_id:
        failures.append("global_world_provenance_mismatch")

    var ids: Dictionary = {}
    _validate_geography(plan, ids, failures)

    var settlement_centers: Dictionary = {}
    var settlement_ids: Dictionary = {}

    var has_rural_background: bool = false
    for region: Dictionary in plan.regions:
        _claim_id(ids, String(region.get("id", "")), failures)
        var rect: Rect2i = region.get("rect", Rect2i())
        if not _rect_inside(plan.bounds, rect):
            failures.append("global_region_out_of_bounds")
        if StringName(region.get("kind", &"")) == &"rural_open" and rect == plan.bounds:
            has_rural_background = true
    if not has_rural_background:
        failures.append("global_rural_background_missing")

    for settlement: Dictionary in plan.settlements:
        var settlement_id: String = String(settlement.get("id", ""))
        _claim_id(ids, settlement_id, failures)
        settlement_ids[settlement_id] = true
        var center: Vector2i = settlement.get("center", Vector2i(-999999, -999999))
        if not plan.bounds.has_point(center):
            failures.append("global_settlement_out_of_bounds")
        if settlement_centers.has(center):
            failures.append("global_settlement_center_duplicate")
        settlement_centers[center] = settlement_id
        if int(settlement.get("influence_radius", 0)) <= 0:
            failures.append("global_settlement_influence_invalid")
        if not _geography.settlement_allowed(center, plan.geography_cells):
            failures.append("global_settlement_on_forbidden_landform")

    for first_index in range(plan.settlements.size()):
        var first_center: Vector2i = plan.settlements[first_index].get("center", Vector2i.ZERO)
        for second_index in range(first_index + 1, plan.settlements.size()):
            var second_center: Vector2i = plan.settlements[second_index].get("center", Vector2i.ZERO)
            var dx: int = first_center.x - second_center.x
            var dy: int = first_center.y - second_center.y
            if dx * dx + dy * dy < 128 * 128:
                failures.append("global_settlements_collapsed")

    var gateway_count: int = 0
    for road: Dictionary in plan.road_segments:
        _claim_id(ids, String(road.get("road_id", "")), failures)
        var start: Vector2i = road.get("start", Vector2i(-999999, -999999))
        var finish: Vector2i = road.get("end", Vector2i(-999999, -999999))
        var width: int = int(road.get("width", 0))
        if start == finish or (start.x != finish.x and start.y != finish.y):
            failures.append("global_road_not_cardinal")
        if width <= 0 or width % 2 == 0:
            failures.append("global_road_width_invalid")
        if not plan.bounds.has_point(start) or not plan.bounds.has_point(finish):
            failures.append("global_road_endpoint_out_of_bounds")
        if _segment_intersects_ridge(road, plan.geography_cells):
            failures.append("global_road_crosses_ridge")
        if _is_boundary_cell(plan.bounds, start):
            gateway_count += 1
        if _is_boundary_cell(plan.bounds, finish):
            gateway_count += 1
    if gateway_count < 4:
        failures.append("global_boundary_gateway_count_too_low")

    if not _road_network_connected(plan.road_segments):
        failures.append("global_road_network_disconnected")

    for settlement: Dictionary in plan.settlements:
        var center: Vector2i = settlement.get("center", Vector2i.ZERO)
        if not _point_on_any_road(center, plan.road_segments):
            failures.append("global_settlement_not_on_major_road")

    for road_index in range(plan.road_segments.size()):
        var road: Dictionary = plan.road_segments[road_index]
        var start: Vector2i = road.get("start", Vector2i.ZERO)
        var finish: Vector2i = road.get("end", Vector2i.ZERO)
        if not _endpoint_justified(start, road_index, plan.bounds, plan.road_segments, settlement_centers):
            failures.append("global_road_start_unjustified")
        if not _endpoint_justified(finish, road_index, plan.bounds, plan.road_segments, settlement_centers):
            failures.append("global_road_end_unjustified")

    for region: Dictionary in plan.regions:
        var region_settlement_id: String = String(region.get("settlement_id", ""))
        if not region_settlement_id.is_empty() and not settlement_ids.has(region_settlement_id):
            failures.append("global_region_settlement_missing")

    var site_ids: Dictionary = {}
    for site: Dictionary in plan.area_sites:
        var site_id: String = String(site.get("id", ""))
        _claim_id(ids, site_id, failures)
        site_ids[site_id] = true
        var site_bounds: Rect2i = site.get("bounds", Rect2i())
        if not _rect_inside(plan.bounds, site_bounds):
            failures.append("global_area_site_out_of_bounds")
        var settlement_id: String = String(site.get("settlement_id", ""))
        if not settlement_ids.has(settlement_id):
            failures.append("global_area_site_settlement_missing")
            continue
        var settlement_center: Vector2i = _settlement_center(plan.settlements, settlement_id)
        if settlement_center.x < -900000 or not site_bounds.has_point(settlement_center):
            failures.append("global_area_site_does_not_contain_settlement")
        if String(site.get("area_profile_hint", &"")).strip_edges().is_empty() or String(site.get("environment_profile_hint", &"")).strip_edges().is_empty():
            failures.append("global_area_site_profile_hint_missing")

    for settlement: Dictionary in plan.settlements:
        var area_site_id: String = String(settlement.get("area_site_id", ""))
        if area_site_id.is_empty() or not site_ids.has(area_site_id):
            failures.append("global_settlement_area_site_missing")

    return {"ok": failures.is_empty(), "failures": failures}

func _validate_geography(plan: GeneratedGlobalWorldPlan, ids: Dictionary, failures: Array[String]) -> void:
    if plan.geography_cells.is_empty():
        failures.append("global_geography_missing")
        return
    var grids: Dictionary = {}
    var total_area: int = 0
    var valid_landforms: Array[StringName] = _geography.valid_landforms()
    for first_index in range(plan.geography_cells.size()):
        var geography: Dictionary = plan.geography_cells[first_index]
        _claim_id(ids, String(geography.get("id", "")), failures)
        var grid: Vector2i = geography.get("grid", Vector2i(-999999, -999999))
        if grids.has(grid):
            failures.append("global_geography_grid_duplicate")
        grids[grid] = true
        var rect: Rect2i = geography.get("rect", Rect2i())
        if not _rect_inside(plan.bounds, rect):
            failures.append("global_geography_out_of_bounds")
        total_area += maxi(0, rect.size.x) * maxi(0, rect.size.y)
        var elevation: int = int(geography.get("elevation", -1))
        if elevation < 0 or elevation > 100:
            failures.append("global_geography_elevation_invalid")
        var landform: StringName = StringName(geography.get("landform", &""))
        if not valid_landforms.has(landform):
            failures.append("global_geography_landform_invalid")
        for second_index in range(first_index + 1, plan.geography_cells.size()):
            var other_rect: Rect2i = plan.geography_cells[second_index].get("rect", Rect2i())
            if _rects_intersect(rect, other_rect):
                failures.append("global_geography_overlap")
                break
    if total_area != plan.bounds.size.x * plan.bounds.size.y:
        failures.append("global_geography_does_not_tile_bounds")

func _segment_intersects_ridge(road: Dictionary, geography_cells: Array[Dictionary]) -> bool:
    var start: Vector2i = road.get("start", Vector2i.ZERO)
    var finish: Vector2i = road.get("end", Vector2i.ZERO)
    for geography: Dictionary in geography_cells:
        if StringName(geography.get("landform", &"")) != &"ridge":
            continue
        var rect: Rect2i = geography.get("rect", Rect2i())
        var max_x: int = rect.position.x + rect.size.x - 1
        var max_y: int = rect.position.y + rect.size.y - 1
        if start.y == finish.y:
            if start.y < rect.position.y or start.y > max_y:
                continue
            if _ranges_overlap(mini(start.x, finish.x), maxi(start.x, finish.x), rect.position.x, max_x):
                return true
        elif start.x == finish.x:
            if start.x < rect.position.x or start.x > max_x:
                continue
            if _ranges_overlap(mini(start.y, finish.y), maxi(start.y, finish.y), rect.position.y, max_y):
                return true
    return false

func _road_network_connected(roads: Array[Dictionary]) -> bool:
    if roads.is_empty():
        return false
    var visited: Dictionary = {0: true}
    var queue: Array[int] = [0]
    while not queue.is_empty():
        var current_index: int = queue.pop_front()
        for other_index in range(roads.size()):
            if visited.has(other_index) or other_index == current_index:
                continue
            if _segments_connected(roads[current_index], roads[other_index]):
                visited[other_index] = true
                queue.append(other_index)
    return visited.size() == roads.size()

func _segments_connected(first: Dictionary, second: Dictionary) -> bool:
    var a: Vector2i = first.get("start", Vector2i.ZERO)
    var b: Vector2i = first.get("end", Vector2i.ZERO)
    var c: Vector2i = second.get("start", Vector2i.ZERO)
    var d: Vector2i = second.get("end", Vector2i.ZERO)
    var first_horizontal: bool = a.y == b.y
    var second_horizontal: bool = c.y == d.y
    if first_horizontal and second_horizontal:
        if a.y != c.y:
            return false
        return _ranges_overlap(mini(a.x, b.x), maxi(a.x, b.x), mini(c.x, d.x), maxi(c.x, d.x))
    if not first_horizontal and not second_horizontal:
        if a.x != c.x:
            return false
        return _ranges_overlap(mini(a.y, b.y), maxi(a.y, b.y), mini(c.y, d.y), maxi(c.y, d.y))
    var horizontal_start: Vector2i = a if first_horizontal else c
    var horizontal_end: Vector2i = b if first_horizontal else d
    var vertical_start: Vector2i = c if first_horizontal else a
    var vertical_end: Vector2i = d if first_horizontal else b
    return vertical_start.x >= mini(horizontal_start.x, horizontal_end.x) \
        and vertical_start.x <= maxi(horizontal_start.x, horizontal_end.x) \
        and horizontal_start.y >= mini(vertical_start.y, vertical_end.y) \
        and horizontal_start.y <= maxi(vertical_start.y, vertical_end.y)

func _point_on_any_road(point: Vector2i, roads: Array[Dictionary]) -> bool:
    for road: Dictionary in roads:
        if _point_on_segment(point, road):
            return true
    return false

func _point_on_segment(point: Vector2i, road: Dictionary) -> bool:
    var start: Vector2i = road.get("start", Vector2i.ZERO)
    var finish: Vector2i = road.get("end", Vector2i.ZERO)
    if start.y == finish.y:
        return point.y == start.y and point.x >= mini(start.x, finish.x) and point.x <= maxi(start.x, finish.x)
    if start.x == finish.x:
        return point.x == start.x and point.y >= mini(start.y, finish.y) and point.y <= maxi(start.y, finish.y)
    return false

func _endpoint_justified(
    point: Vector2i,
    own_index: int,
    bounds: Rect2i,
    roads: Array[Dictionary],
    settlement_centers: Dictionary
) -> bool:
    if _is_boundary_cell(bounds, point) or settlement_centers.has(point):
        return true
    for index in range(roads.size()):
        if index == own_index:
            continue
        if _point_on_segment(point, roads[index]):
            return true
    return false

func _settlement_center(settlements: Array[Dictionary], settlement_id: String) -> Vector2i:
    for settlement: Dictionary in settlements:
        if String(settlement.get("id", "")) == settlement_id:
            return settlement.get("center", Vector2i(-999999, -999999))
    return Vector2i(-999999, -999999)

func _claim_id(ids: Dictionary, value: String, failures: Array[String]) -> void:
    if value.strip_edges().is_empty():
        failures.append("global_stable_id_empty")
        return
    if ids.has(value):
        failures.append("global_stable_id_duplicate")
        return
    ids[value] = true

func _ranges_overlap(a_min: int, a_max: int, b_min: int, b_max: int) -> bool:
    return a_min <= b_max and b_min <= a_max

func _is_boundary_cell(rect: Rect2i, cell: Vector2i) -> bool:
    if not rect.has_point(cell):
        return false
    var max_x: int = rect.position.x + rect.size.x - 1
    var max_y: int = rect.position.y + rect.size.y - 1
    return cell.x == rect.position.x or cell.x == max_x or cell.y == rect.position.y or cell.y == max_y

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var inner_max := Vector2i(inner.position.x + inner.size.x - 1, inner.position.y + inner.size.y - 1)
    return outer.has_point(inner.position) and outer.has_point(inner_max)

func _rects_intersect(a: Rect2i, b: Rect2i) -> bool:
    if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0:
        return false
    return a.position.x < b.position.x + b.size.x \
        and a.position.x + a.size.x > b.position.x \
        and a.position.y < b.position.y + b.size.y \
        and a.position.y + a.size.y > b.position.y
