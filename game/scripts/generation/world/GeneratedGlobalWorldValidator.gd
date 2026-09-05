extends RefCounted
class_name GeneratedGlobalWorldValidator

const GeographyQueryClass = preload("res://scripts/generation/world/GlobalGeographyQuery.gd")
const ProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")

var _geography: GlobalGeographyQuery = GeographyQueryClass.new()
var _profiles: GlobalWorldProfileCatalog = ProfilesClass.new()

func validate(request: GlobalWorldGenerationRequest, plan: GeneratedGlobalWorldPlan) -> Dictionary:
    var failures: Array[String] = []
    if request == null or not request.is_valid() or plan == null or not plan.is_generated():
        return {"ok": false, "failures": ["invalid_global_world_plan_input"]}
    if plan.world_id != request.world_id or plan.seed != request.seed or plan.bounds != request.bounds or plan.profile_id != request.profile_id:
        failures.append("global_world_provenance_mismatch")
    var profile: Dictionary = _profiles.profile(plan.profile_id)
    if profile.is_empty() or int(profile.get("version", 0)) != plan.profile_version:
        failures.append("global_world_profile_version_mismatch")

    var ids: Dictionary = {}
    _validate_geography(plan, ids, failures)
    var settlement_ids: Dictionary = {}
    var settlement_centers: Dictionary = {}
    var has_rural_background: bool = false
    for region: Dictionary in plan.regions:
        _claim_id(ids, String(region.get("id", "")), failures)
        var rect: Rect2i = region.get("rect", Rect2i())
        if not _rect_inside(plan.bounds, rect): failures.append("global_region_out_of_bounds")
        if StringName(region.get("kind", &"")) == &"rural_open" and rect == plan.bounds: has_rural_background = true
    if not has_rural_background: failures.append("global_rural_background_missing")

    for settlement: Dictionary in plan.settlements:
        var sid: String = String(settlement.get("id", ""))
        _claim_id(ids, sid, failures)
        settlement_ids[sid] = true
        var center: Vector2i = settlement.get("center", Vector2i(-999999, -999999))
        if not plan.bounds.has_point(center): failures.append("global_settlement_out_of_bounds")
        if settlement_centers.has(center): failures.append("global_settlement_center_duplicate")
        settlement_centers[center] = sid
        if int(settlement.get("influence_radius", 0)) <= 0: failures.append("global_settlement_influence_invalid")
        if not _geography.settlement_allowed(center, plan.geography_cells): failures.append("global_settlement_on_forbidden_landform")

    for a: int in range(plan.settlements.size()):
        var ac: Vector2i = plan.settlements[a].get("center", Vector2i.ZERO)
        for b: int in range(a + 1, plan.settlements.size()):
            var bc: Vector2i = plan.settlements[b].get("center", Vector2i.ZERO)
            var dx: int = ac.x - bc.x
            var dy: int = ac.y - bc.y
            if dx * dx + dy * dy < 128 * 128: failures.append("global_settlements_collapsed")

    var gateway_count: int = 0
    for road: Dictionary in plan.road_segments:
        _claim_id(ids, String(road.get("road_id", "")), failures)
        var start: Vector2i = road.get("start", Vector2i(-999999, -999999))
        var finish: Vector2i = road.get("end", Vector2i(-999999, -999999))
        var width: int = int(road.get("width", 0))
        if start == finish or (start.x != finish.x and start.y != finish.y): failures.append("global_road_not_cardinal")
        if width <= 0 or width % 2 == 0: failures.append("global_road_width_invalid")
        if not plan.bounds.has_point(start) or not plan.bounds.has_point(finish): failures.append("global_road_endpoint_out_of_bounds")
        if _segment_intersects_ridge(road, plan.geography_cells): failures.append("global_road_crosses_ridge")
        if _is_boundary_cell(plan.bounds, start): gateway_count += 1
        if _is_boundary_cell(plan.bounds, finish): gateway_count += 1
    if gateway_count < 4: failures.append("global_boundary_gateway_count_too_low")
    if not _road_network_connected(plan.road_segments): failures.append("global_road_network_disconnected")
    for settlement: Dictionary in plan.settlements:
        if not _point_on_any_road(settlement.get("center", Vector2i.ZERO), plan.road_segments): failures.append("global_settlement_not_on_major_road")

    var site_ids: Dictionary = {}
    for site: Dictionary in plan.area_sites:
        var site_id: String = String(site.get("id", ""))
        _claim_id(ids, site_id, failures)
        site_ids[site_id] = true
        var site_bounds: Rect2i = site.get("bounds", Rect2i())
        if not _rect_inside(plan.bounds, site_bounds): failures.append("global_area_site_out_of_bounds")
        var settlement_id: String = String(site.get("settlement_id", ""))
        if not settlement_ids.has(settlement_id):
            failures.append("global_area_site_settlement_missing")
        else:
            var center: Vector2i = _settlement_center(plan.settlements, settlement_id)
            if center.x < -900000 or not site_bounds.has_point(center): failures.append("global_area_site_does_not_contain_settlement")
        if String(site.get("area_profile_hint", &"")).strip_edges().is_empty() or String(site.get("environment_profile_hint", &"")).strip_edges().is_empty(): failures.append("global_area_site_profile_hint_missing")
    for settlement: Dictionary in plan.settlements:
        var area_site_id: String = String(settlement.get("area_site_id", ""))
        if area_site_id.is_empty() or not site_ids.has(area_site_id): failures.append("global_settlement_area_site_missing")
    return {"ok": failures.is_empty(), "failures": failures}

func _validate_geography(plan: GeneratedGlobalWorldPlan, ids: Dictionary, failures: Array[String]) -> void:
    if plan.geography_cells.is_empty():
        failures.append("global_geography_missing")
        return
    var grids: Dictionary = {}
    var total_area: int = 0
    var valid_landforms: Array[StringName] = _geography.valid_landforms()
    for i: int in range(plan.geography_cells.size()):
        var cell: Dictionary = plan.geography_cells[i]
        _claim_id(ids, String(cell.get("id", "")), failures)
        var grid: Vector2i = cell.get("grid", Vector2i(-999999, -999999))
        if grids.has(grid): failures.append("global_geography_grid_duplicate")
        grids[grid] = true
        var rect: Rect2i = cell.get("rect", Rect2i())
        if not _rect_inside(plan.bounds, rect): failures.append("global_geography_out_of_bounds")
        total_area += maxi(0, rect.size.x) * maxi(0, rect.size.y)
        var elevation: int = int(cell.get("elevation", -1))
        if elevation < 0 or elevation > 100: failures.append("global_geography_elevation_invalid")
        if not valid_landforms.has(StringName(cell.get("landform", &""))): failures.append("global_geography_landform_invalid")
        for j: int in range(i + 1, plan.geography_cells.size()):
            if _rects_intersect(rect, plan.geography_cells[j].get("rect", Rect2i())):
                failures.append("global_geography_overlap")
                break
    if total_area != plan.bounds.size.x * plan.bounds.size.y: failures.append("global_geography_does_not_tile_bounds")

func _road_network_connected(roads: Array[Dictionary]) -> bool:
    if roads.is_empty(): return false
    var adjacency: Dictionary = {}
    for road: Dictionary in roads:
        var a: Vector2i = road.get("start", Vector2i.ZERO)
        var b: Vector2i = road.get("end", Vector2i.ZERO)
        if not adjacency.has(a): adjacency[a] = []
        if not adjacency.has(b): adjacency[b] = []
        (adjacency[a] as Array).append(b)
        (adjacency[b] as Array).append(a)
    var queue: Array[Vector2i] = [roads[0].get("start", Vector2i.ZERO)]
    var visited: Dictionary = {}
    while not queue.is_empty():
        var current: Vector2i = queue.pop_front()
        if visited.has(current): continue
        visited[current] = true
        for neighbor: Vector2i in adjacency.get(current, []):
            if not visited.has(neighbor): queue.append(neighbor)
    return visited.size() == adjacency.size()

func _point_on_any_road(point: Vector2i, roads: Array[Dictionary]) -> bool:
    for road: Dictionary in roads:
        var a: Vector2i = road.get("start", Vector2i.ZERO)
        var b: Vector2i = road.get("end", Vector2i.ZERO)
        if a.x == b.x and point.x == a.x and point.y >= mini(a.y, b.y) and point.y <= maxi(a.y, b.y): return true
        if a.y == b.y and point.y == a.y and point.x >= mini(a.x, b.x) and point.x <= maxi(a.x, b.x): return true
    return false

func _segment_intersects_ridge(segment: Dictionary, geography_cells: Array[Dictionary]) -> bool:
    var a: Vector2i = segment.get("start", Vector2i.ZERO)
    var b: Vector2i = segment.get("end", Vector2i.ZERO)
    for cell: Dictionary in geography_cells:
        if StringName(cell.get("landform", &"")) != &"ridge": continue
        var rect: Rect2i = cell.get("rect", Rect2i())
        if a.x == b.x and a.x >= rect.position.x and a.x < rect.end.x and maxi(mini(a.y,b.y),rect.position.y) <= mini(maxi(a.y,b.y),rect.end.y-1): return true
        if a.y == b.y and a.y >= rect.position.y and a.y < rect.end.y and maxi(mini(a.x,b.x),rect.position.x) <= mini(maxi(a.x,b.x),rect.end.x-1): return true
    return false

func _settlement_center(settlements: Array[Dictionary], settlement_id: String) -> Vector2i:
    for settlement: Dictionary in settlements:
        if String(settlement.get("id", "")) == settlement_id: return settlement.get("center", Vector2i(-999999, -999999))
    return Vector2i(-999999, -999999)

func _claim_id(ids: Dictionary, value: String, failures: Array[String]) -> void:
    var clean: String = value.strip_edges()
    if clean.is_empty(): failures.append("global_id_missing")
    elif ids.has(clean): failures.append("global_id_duplicate")
    else: ids[clean] = true

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    return inner.size.x > 0 and inner.size.y > 0 and outer.has_point(inner.position) and outer.has_point(inner.position + inner.size - Vector2i.ONE)

func _rects_intersect(a: Rect2i, b: Rect2i) -> bool:
    return a.position.x < b.end.x and a.end.x > b.position.x and a.position.y < b.end.y and a.end.y > b.position.y

func _is_boundary_cell(bounds: Rect2i, cell: Vector2i) -> bool:
    return bounds.has_point(cell) and (cell.x == bounds.position.x or cell.y == bounds.position.y or cell.x == bounds.end.x - 1 or cell.y == bounds.end.y - 1)
