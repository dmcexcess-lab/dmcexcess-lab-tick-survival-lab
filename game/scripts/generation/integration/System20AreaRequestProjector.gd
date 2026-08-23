extends RefCounted
class_name System20AreaRequestProjector

const AreaRequestClass = preload("res://scripts/generation/areas/AreaGenerationRequest.gd")
const AreaProfilesClass = preload("res://scripts/generation/areas/AreaProfileCatalog.gd")
const EnvironmentProfilesClass = preload("res://scripts/generation/areas/EnvironmentProfileCatalog.gd")

var _area_profiles: AreaProfileCatalog
var _environment_profiles: EnvironmentProfileCatalog

func _init() -> void:
    _area_profiles = AreaProfilesClass.new()
    _environment_profiles = EnvironmentProfilesClass.new()

func project_site(plan: GeneratedGlobalWorldPlan, site_id: String) -> Dictionary:
    if plan == null or not plan.is_generated() or site_id.strip_edges().is_empty():
        return {"ok": false, "failure_reason": "invalid_global_to_local_projection_input", "request": null}
    var site: Dictionary = _site_by_id(plan.area_sites, site_id)
    if site.is_empty():
        return {"ok": false, "failure_reason": "global_area_site_missing", "request": null}

    var area_profile_id: StringName = StringName(site.get("area_profile_hint", &""))
    var environment_profile_id: StringName = StringName(site.get("environment_profile_hint", &""))
    if not _area_profiles.has_profile(area_profile_id):
        return {"ok": false, "failure_reason": "system20_area_profile_unsupported", "request": null}
    if not _environment_profiles.has_profile(environment_profile_id):
        return {"ok": false, "failure_reason": "system20_environment_profile_unsupported", "request": null}

    var site_bounds: Rect2i = site.get("bounds", Rect2i())
    var road_result: Dictionary = road_constraints_for_bounds(plan, site_bounds)
    if not bool(road_result.get("ok", false)):
        return {"ok": false, "failure_reason": String(road_result.get("failure_reason", "global_road_projection_failed")), "request": null}
    var roads: Array[Dictionary] = []
    for road_value: Variant in road_result.get("roads", []):
        if typeof(road_value) != TYPE_DICTIONARY:
            return {"ok": false, "failure_reason": "global_road_projection_result_invalid", "request": null}
        roads.append(road_value)
    if roads.is_empty():
        return {"ok": false, "failure_reason": "global_area_site_has_no_major_road", "request": null}

    var request: AreaGenerationRequest = AreaRequestClass.new(
        String(site.get("id", "")),
        int(site.get("seed", 0)),
        site_bounds,
        area_profile_id,
        environment_profile_id,
        roads,
        []
    )
    if not request.is_valid():
        return {"ok": false, "failure_reason": "projected_system20_request_invalid", "request": null}
    return {"ok": true, "failure_reason": "", "request": request}

func road_constraints_for_bounds(plan: GeneratedGlobalWorldPlan, bounds: Rect2i) -> Dictionary:
    var roads: Array[Dictionary] = []
    if plan == null or not plan.is_generated() or not _rect_inside(plan.bounds, bounds):
        return {"ok": false, "failure_reason": "invalid_global_road_projection_bounds", "roads": roads}
    for segment: Dictionary in plan.road_segments:
        if _segment_overlap_is_single_point(segment, bounds):
            continue
        var clipped: Dictionary = _clip_segment(segment, bounds)
        if clipped.is_empty():
            continue
        var start: Vector2i = clipped.get("start", Vector2i.ZERO)
        var finish: Vector2i = clipped.get("end", Vector2i.ZERO)
        var allowed: Array[Vector2i] = []
        if _is_boundary_cell(bounds, start):
            allowed.append(start)
        if _is_boundary_cell(bounds, finish) and finish != start:
            allowed.append(finish)
        if allowed.is_empty():
            return {
                "ok": false,
                "failure_reason": "global_major_road_fully_internal_to_system20_area_unsupported",
                "roads": [],
            }
        roads.append({
            "road_id": String(segment.get("road_id", "")),
            "road_class": StringName(segment.get("road_class", &"")),
            "start": start,
            "end": finish,
            "width": int(segment.get("width", 0)),
            "allowed_boundary_cells": allowed,
        })
    return {"ok": true, "failure_reason": "", "roads": roads}

## Read-only future seam. Slice 003 does not inject tactical river/bridge facts into
## the current AreaGenerationRequest because System 20 tactical hydrology is not
## designed. Callers may inspect global river/bridge facts without changing Candidate 006.
func hydrology_constraints_for_bounds(plan: GeneratedGlobalWorldPlan, bounds: Rect2i) -> Dictionary:
    var rivers: Array[Dictionary] = []
    var bridges: Array[Dictionary] = []
    if plan == null or not plan.is_generated() or not _rect_inside(plan.bounds, bounds):
        return {"ok": false, "failure_reason": "invalid_global_hydrology_projection_bounds", "rivers": rivers, "bridges": bridges}

    for segment: Dictionary in plan.river_segments:
        if _segment_overlap_is_single_point(segment, bounds):
            continue
        var clipped: Dictionary = _clip_segment(segment, bounds)
        if clipped.is_empty():
            continue
        rivers.append({
            "segment_id": String(segment.get("segment_id", "")),
            "river_id": String(segment.get("river_id", "")),
            "start": clipped.get("start", Vector2i.ZERO),
            "end": clipped.get("end", Vector2i.ZERO),
            "width": int(segment.get("width", 0)),
            "ordinal": int(segment.get("ordinal", 0)),
        })

    for bridge: Dictionary in plan.bridge_intents:
        var cell: Vector2i = bridge.get("cell", Vector2i(-999999, -999999))
        if bounds.has_point(cell):
            bridges.append(bridge.duplicate(true))

    return {"ok": true, "failure_reason": "", "rivers": rivers, "bridges": bridges}

## Read-only Slice 004 seam. Regional power remains pure global planning truth;
## `project_site()` intentionally does not inject poles/wires into the current
## AreaGenerationRequest before local utility materialization is designed.
func power_constraints_for_bounds(plan: GeneratedGlobalWorldPlan, bounds: Rect2i) -> Dictionary:
    var segments: Array[Dictionary] = []
    var nodes: Array[Dictionary] = []
    if plan == null or not plan.is_generated() or not _rect_inside(plan.bounds, bounds):
        return {"ok": false, "failure_reason": "invalid_global_power_projection_bounds", "segments": segments, "nodes": nodes}

    for segment: Dictionary in plan.power_segments:
        if _segment_overlap_is_single_point(segment, bounds):
            continue
        var clipped: Dictionary = _clip_segment(segment, bounds)
        if clipped.is_empty():
            continue
        segments.append({
            "id": String(segment.get("id", "")),
            "network_id": String(segment.get("network_id", "")),
            "power_class": StringName(segment.get("power_class", &"")),
            "start": clipped.get("start", Vector2i.ZERO),
            "end": clipped.get("end", Vector2i.ZERO),
            "ordinal": int(segment.get("ordinal", 0)),
            "source_road_id": String(segment.get("source_road_id", "")),
            "source_route_id": String(segment.get("source_route_id", "")),
        })

    for node: Dictionary in plan.power_nodes:
        var cell: Vector2i = node.get("cell", Vector2i(-999999, -999999))
        if bounds.has_point(cell):
            nodes.append(node.duplicate(true))

    return {"ok": true, "failure_reason": "", "segments": segments, "nodes": nodes}

## Read-only Slice 005 seam. Potable-water service classification and municipal
## connection anchors remain global planning truth. Current System 20 requests do
## not receive wells, pipes, pumps or fixture-water state.
func water_constraints_for_bounds(plan: GeneratedGlobalWorldPlan, bounds: Rect2i) -> Dictionary:
    var services: Array[Dictionary] = []
    var nodes: Array[Dictionary] = []
    var segments: Array[Dictionary] = []
    if plan == null or not plan.is_generated() or not _rect_inside(plan.bounds, bounds):
        return {"ok": false, "failure_reason": "invalid_global_water_projection_bounds", "services": services, "nodes": nodes, "segments": segments}

    for service: Dictionary in plan.water_services:
        var settlement_id: String = String(service.get("settlement_id", ""))
        var settlement: Dictionary = _settlement_by_id(plan.settlements, settlement_id)
        if settlement.is_empty():
            continue
        var center: Vector2i = settlement.get("center", Vector2i(-999999, -999999))
        if bounds.has_point(center):
            services.append(service.duplicate(true))

    for node: Dictionary in plan.water_nodes:
        var cell: Vector2i = node.get("cell", Vector2i(-999999, -999999))
        if bounds.has_point(cell):
            nodes.append(node.duplicate(true))

    for segment: Dictionary in plan.water_segments:
        if _segment_overlap_is_single_point(segment, bounds):
            continue
        var clipped: Dictionary = _clip_segment(segment, bounds)
        if clipped.is_empty():
            continue
        segments.append({
            "id": String(segment.get("id", "")),
            "network_id": String(segment.get("network_id", "")),
            "water_class": StringName(segment.get("water_class", &"")),
            "start": clipped.get("start", Vector2i.ZERO),
            "end": clipped.get("end", Vector2i.ZERO),
            "ordinal": int(segment.get("ordinal", 0)),
            "source_road_id": String(segment.get("source_road_id", "")),
            "source_route_id": String(segment.get("source_route_id", "")),
        })

    return {"ok": true, "failure_reason": "", "services": services, "nodes": nodes, "segments": segments}

## Read-only Slice 006 seam. Wastewater service intent remains upstream planning
## truth; current System 20 requests do not receive septic tanks, drain fields,
## sewer pipes, treatment facilities or runtime sanitation state.
func wastewater_constraints_for_bounds(plan: GeneratedGlobalWorldPlan, bounds: Rect2i) -> Dictionary:
    var services: Array[Dictionary] = []
    var nodes: Array[Dictionary] = []
    var segments: Array[Dictionary] = []
    if plan == null or not plan.is_generated() or not _rect_inside(plan.bounds, bounds):
        return {"ok": false, "failure_reason": "invalid_global_wastewater_projection_bounds", "services": services, "nodes": nodes, "segments": segments}

    for service: Dictionary in plan.wastewater_services:
        var settlement_id: String = String(service.get("settlement_id", ""))
        var settlement: Dictionary = _settlement_by_id(plan.settlements, settlement_id)
        if settlement.is_empty():
            continue
        var center: Vector2i = settlement.get("center", Vector2i(-999999, -999999))
        if bounds.has_point(center):
            services.append(service.duplicate(true))

    for node: Dictionary in plan.wastewater_nodes:
        var cell: Vector2i = node.get("cell", Vector2i(-999999, -999999))
        if bounds.has_point(cell):
            nodes.append(node.duplicate(true))

    for segment: Dictionary in plan.wastewater_segments:
        if _segment_overlap_is_single_point(segment, bounds):
            continue
        var clipped: Dictionary = _clip_segment(segment, bounds)
        if clipped.is_empty():
            continue
        segments.append({
            "id": String(segment.get("id", "")),
            "network_id": String(segment.get("network_id", "")),
            "wastewater_class": StringName(segment.get("wastewater_class", &"")),
            "start": clipped.get("start", Vector2i.ZERO),
            "end": clipped.get("end", Vector2i.ZERO),
            "ordinal": int(segment.get("ordinal", 0)),
            "source_road_id": String(segment.get("source_road_id", "")),
            "source_route_id": String(segment.get("source_route_id", "")),
        })

    return {"ok": true, "failure_reason": "", "services": services, "nodes": nodes, "segments": segments}

func _segment_overlap_is_single_point(segment: Dictionary, bounds: Rect2i) -> bool:
    var start: Vector2i = segment.get("start", Vector2i.ZERO)
    var finish: Vector2i = segment.get("end", Vector2i.ZERO)
    var min_x: int = bounds.position.x
    var max_x: int = bounds.position.x + bounds.size.x - 1
    var min_y: int = bounds.position.y
    var max_y: int = bounds.position.y + bounds.size.y - 1
    if start.y == finish.y:
        if start.y < min_y or start.y > max_y:
            return false
        var overlap_min_x: int = maxi(mini(start.x, finish.x), min_x)
        var overlap_max_x: int = mini(maxi(start.x, finish.x), max_x)
        return overlap_min_x == overlap_max_x
    if start.x == finish.x:
        if start.x < min_x or start.x > max_x:
            return false
        var overlap_min_y: int = maxi(mini(start.y, finish.y), min_y)
        var overlap_max_y: int = mini(maxi(start.y, finish.y), max_y)
        return overlap_min_y == overlap_max_y
    return false

func _clip_segment(segment: Dictionary, bounds: Rect2i) -> Dictionary:
    var start: Vector2i = segment.get("start", Vector2i.ZERO)
    var finish: Vector2i = segment.get("end", Vector2i.ZERO)
    var min_x: int = bounds.position.x
    var max_x: int = bounds.position.x + bounds.size.x - 1
    var min_y: int = bounds.position.y
    var max_y: int = bounds.position.y + bounds.size.y - 1
    if start.y == finish.y:
        if start.y < min_y or start.y > max_y:
            return {}
        var clipped_min_x: int = maxi(mini(start.x, finish.x), min_x)
        var clipped_max_x: int = mini(maxi(start.x, finish.x), max_x)
        if clipped_min_x >= clipped_max_x:
            return {}
        if start.x <= finish.x:
            return {"start": Vector2i(clipped_min_x, start.y), "end": Vector2i(clipped_max_x, start.y)}
        return {"start": Vector2i(clipped_max_x, start.y), "end": Vector2i(clipped_min_x, start.y)}
    if start.x == finish.x:
        if start.x < min_x or start.x > max_x:
            return {}
        var clipped_min_y: int = maxi(mini(start.y, finish.y), min_y)
        var clipped_max_y: int = mini(maxi(start.y, finish.y), max_y)
        if clipped_min_y >= clipped_max_y:
            return {}
        if start.y <= finish.y:
            return {"start": Vector2i(start.x, clipped_min_y), "end": Vector2i(start.x, clipped_max_y)}
        return {"start": Vector2i(start.x, clipped_max_y), "end": Vector2i(start.x, clipped_min_y)}
    return {}

func _site_by_id(sites: Array[Dictionary], site_id: String) -> Dictionary:
    for site: Dictionary in sites:
        if String(site.get("id", "")) == site_id:
            return site
    return {}

func _settlement_by_id(settlements: Array[Dictionary], settlement_id: String) -> Dictionary:
    for settlement: Dictionary in settlements:
        if String(settlement.get("id", "")) == settlement_id:
            return settlement
    return {}

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
