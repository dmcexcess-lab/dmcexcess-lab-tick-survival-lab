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

    var planning_constraints: Array[Dictionary] = []
    if area_profile_id == AreaProfileCatalog.SMALLTOWN_CENTER:
        var constraint_result: Dictionary = _smalltown_planning_constraints(plan, site_bounds)
        if not bool(constraint_result.get("ok", false)):
            return {
                "ok": false,
                "failure_reason": String(constraint_result.get("failure_reason", "smalltown_planning_constraint_projection_failed")),
                "request": null,
            }
        for constraint_value: Variant in constraint_result.get("constraints", []):
            if typeof(constraint_value) != TYPE_DICTIONARY:
                return {"ok": false, "failure_reason": "smalltown_planning_constraint_result_invalid", "request": null}
            planning_constraints.append(constraint_value)
    elif area_profile_id == AreaProfileCatalog.RURAL_SCATTERED:
        var scattered_result: Dictionary = _rural_scattered_planning_constraints(plan, site)
        if not bool(scattered_result.get("ok", false)):
            return {
                "ok": false,
                "failure_reason": String(scattered_result.get("failure_reason", "rural_scattered_planning_constraint_projection_failed")),
                "request": null,
            }
        for constraint_value: Variant in scattered_result.get("constraints", []):
            if typeof(constraint_value) != TYPE_DICTIONARY:
                return {"ok": false, "failure_reason": "rural_scattered_planning_constraint_result_invalid", "request": null}
            planning_constraints.append(constraint_value)

    var request: AreaGenerationRequest = AreaRequestClass.new(
        String(site.get("id", "")),
        int(site.get("seed", 0)),
        site_bounds,
        area_profile_id,
        environment_profile_id,
        roads,
        [],
        planning_constraints
    )
    if not request.is_valid():
        return {"ok": false, "failure_reason": "projected_system20_request_invalid", "request": null}
    return {"ok": true, "failure_reason": "", "request": request}

func project_rural_open_bounds(
    plan: GeneratedGlobalWorldPlan,
    area_id: String,
    bounds: Rect2i
) -> Dictionary:
    var clean_area_id: String = area_id.strip_edges()
    if plan == null or not plan.is_generated() or clean_area_id.is_empty() or not _rect_inside(plan.bounds, bounds):
        return {"ok": false, "failure_reason": "invalid_rural_open_projection_input", "request": null}
    if not _rural_open_context_contains_bounds(plan, bounds):
        return {"ok": false, "failure_reason": "rural_open_context_missing", "request": null}
    for site: Dictionary in plan.area_sites:
        var site_bounds: Rect2i = site.get("bounds", Rect2i())
        if _rects_overlap_positive(bounds, site_bounds):
            return {"ok": false, "failure_reason": "rural_open_overlaps_settlement_site", "request": null}

    var hydrology_result: Dictionary = hydrology_constraints_for_bounds(plan, bounds)
    if not bool(hydrology_result.get("ok", false)):
        return {"ok": false, "failure_reason": "rural_open_hydrology_projection_failed", "request": null}
    if not (hydrology_result.get("rivers", []) as Array).is_empty() or not (hydrology_result.get("bridges", []) as Array).is_empty():
        return {"ok": false, "failure_reason": "rural_open_hydrology_not_materializable", "request": null}

    var road_result: Dictionary = road_constraints_for_bounds(plan, bounds)
    if not bool(road_result.get("ok", false)):
        return {"ok": false, "failure_reason": "rural_open_road_projection_failed", "request": null}
    var roads: Array[Dictionary] = []
    for road_value: Variant in road_result.get("roads", []):
        if typeof(road_value) != TYPE_DICTIONARY:
            return {"ok": false, "failure_reason": "rural_open_road_projection_result_invalid", "request": null}
        roads.append(road_value)

    var geography_result: Dictionary = _rural_open_geography_for_bounds(plan, bounds)
    if not bool(geography_result.get("ok", false)):
        return {"ok": false, "failure_reason": String(geography_result.get("failure_reason", "rural_open_geography_projection_failed")), "request": null}
    var inherited_geography: Array[Dictionary] = []
    for geography_value: Variant in geography_result.get("geography", []):
        if typeof(geography_value) != TYPE_DICTIONARY:
            return {"ok": false, "failure_reason": "rural_open_geography_projection_result_invalid", "request": null}
        inherited_geography.append(geography_value)

    var planning_result: Dictionary = _rural_open_planning_constraints(plan, bounds)
    if not bool(planning_result.get("ok", false)):
        return {"ok": false, "failure_reason": String(planning_result.get("failure_reason", "rural_open_planning_constraint_projection_failed")), "request": null}
    var planning_constraints: Array[Dictionary] = []
    for constraint_value: Variant in planning_result.get("constraints", []):
        if typeof(constraint_value) != TYPE_DICTIONARY:
            return {"ok": false, "failure_reason": "rural_open_planning_constraint_result_invalid", "request": null}
        planning_constraints.append(constraint_value)

    var request: AreaGenerationRequest = AreaRequestClass.new(
        clean_area_id,
        plan.seed,
        bounds,
        AreaProfileCatalog.RURAL_OPEN,
        EnvironmentProfileCatalog.TEMPERATE_RURAL,
        roads,
        [],
        planning_constraints,
        inherited_geography
    )
    if not request.is_valid():
        return {"ok": false, "failure_reason": "projected_rural_open_request_invalid", "request": null}
    return {"ok": true, "failure_reason": "", "request": request}

func _rural_open_context_contains_bounds(plan: GeneratedGlobalWorldPlan, bounds: Rect2i) -> bool:
    for region: Dictionary in plan.regions:
        if StringName(region.get("kind", &"")) != &"rural_open":
            continue
        if StringName(region.get("area_profile_hint", &"")) != AreaProfileCatalog.RURAL_OPEN:
            continue
        var region_rect: Rect2i = region.get("rect", Rect2i())
        if _rect_inside(region_rect, bounds):
            return true
    return false

func _rural_open_geography_for_bounds(plan: GeneratedGlobalWorldPlan, bounds: Rect2i) -> Dictionary:
    var geography: Array[Dictionary] = []
    for source: Dictionary in plan.geography_cells:
        var source_rect: Rect2i = source.get("rect", Rect2i())
        var clipped: Rect2i = _rect_intersection(source_rect, bounds)
        if clipped.size.x <= 0 or clipped.size.y <= 0:
            continue
        geography.append({
            "id": String(source.get("id", "")),
            "grid": source.get("grid", Vector2i(-999999, -999999)),
            "rect": clipped,
            "elevation": int(source.get("elevation", -1)),
            "landform": StringName(source.get("landform", &"")),
        })
    if geography.is_empty():
        return {"ok": false, "failure_reason": "rural_open_geography_missing", "geography": []}
    geography.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var a_rect: Rect2i = a.get("rect", Rect2i())
        var b_rect: Rect2i = b.get("rect", Rect2i())
        if a_rect.position.y != b_rect.position.y:
            return a_rect.position.y < b_rect.position.y
        if a_rect.position.x != b_rect.position.x:
            return a_rect.position.x < b_rect.position.x
        return String(a.get("id", "")) < String(b.get("id", ""))
    )
    return {"ok": true, "failure_reason": "", "geography": geography}

func _rural_open_planning_constraints(plan: GeneratedGlobalWorldPlan, bounds: Rect2i) -> Dictionary:
    var constraints: Array[Dictionary] = []
    var power_result: Dictionary = power_constraints_for_bounds(plan, bounds)
    if not bool(power_result.get("ok", false)):
        return {"ok": false, "failure_reason": "rural_open_power_projection_failed", "constraints": constraints}
    for value: Variant in power_result.get("segments", []):
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var segment: Dictionary = value
        constraints.append(_corridor_constraint(
            "constraint.power.%s" % String(segment.get("id", "segment")),
            String(segment.get("id", "")),
            &"power",
            StringName(segment.get("power_class", &"feeder")),
            segment.get("start", Vector2i.ZERO),
            segment.get("end", Vector2i.ZERO),
            1,
            false,
            String(segment.get("network_id", ""))
        ))

    var water_result: Dictionary = water_constraints_for_bounds(plan, bounds)
    if not bool(water_result.get("ok", false)):
        return {"ok": false, "failure_reason": "rural_open_water_projection_failed", "constraints": constraints}
    for value: Variant in water_result.get("segments", []):
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var segment: Dictionary = value
        constraints.append(_corridor_constraint(
            "constraint.water.%s" % String(segment.get("id", "segment")),
            String(segment.get("id", "")),
            &"potable_water",
            StringName(segment.get("water_class", &"municipal_trunk")),
            segment.get("start", Vector2i.ZERO),
            segment.get("end", Vector2i.ZERO),
            1,
            false,
            String(segment.get("network_id", ""))
        ))

    var wastewater_result: Dictionary = wastewater_constraints_for_bounds(plan, bounds)
    if not bool(wastewater_result.get("ok", false)):
        return {"ok": false, "failure_reason": "rural_open_wastewater_projection_failed", "constraints": constraints}
    for value: Variant in wastewater_result.get("segments", []):
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var segment: Dictionary = value
        constraints.append(_corridor_constraint(
            "constraint.wastewater.%s" % String(segment.get("id", "segment")),
            String(segment.get("id", "")),
            &"wastewater",
            StringName(segment.get("wastewater_class", &"municipal_collection_trunk")),
            segment.get("start", Vector2i.ZERO),
            segment.get("end", Vector2i.ZERO),
            1,
            false,
            String(segment.get("network_id", ""))
        ))
    return {"ok": true, "failure_reason": "", "constraints": constraints}

func _smalltown_planning_constraints(plan: GeneratedGlobalWorldPlan, bounds: Rect2i) -> Dictionary:
    var constraints: Array[Dictionary] = []

    var water_result: Dictionary = water_constraints_for_bounds(plan, bounds)
    if not bool(water_result.get("ok", false)):
        return {"ok": false, "failure_reason": "smalltown_water_projection_failed", "constraints": constraints}
    var water_services: Array = water_result.get("services", [])
    if water_services.size() != 1 or typeof(water_services[0]) != TYPE_DICTIONARY \
        or StringName((water_services[0] as Dictionary).get("service_mode", &"")) != &"municipal":
        return {"ok": false, "failure_reason": "smalltown_municipal_water_service_missing", "constraints": constraints}

    var wastewater_result: Dictionary = wastewater_constraints_for_bounds(plan, bounds)
    if not bool(wastewater_result.get("ok", false)):
        return {"ok": false, "failure_reason": "smalltown_wastewater_projection_failed", "constraints": constraints}
    var wastewater_services: Array = wastewater_result.get("services", [])
    if wastewater_services.size() != 1 or typeof(wastewater_services[0]) != TYPE_DICTIONARY \
        or StringName((wastewater_services[0] as Dictionary).get("service_mode", &"")) != &"municipal":
        return {"ok": false, "failure_reason": "smalltown_municipal_wastewater_service_missing", "constraints": constraints}

    var hydrology_result: Dictionary = hydrology_constraints_for_bounds(plan, bounds)
    if not bool(hydrology_result.get("ok", false)):
        return {"ok": false, "failure_reason": "smalltown_hydrology_projection_failed", "constraints": constraints}
    for river_value: Variant in hydrology_result.get("rivers", []):
        if typeof(river_value) != TYPE_DICTIONARY:
            continue
        var river: Dictionary = river_value
        constraints.append(_corridor_constraint(
            "constraint.hydrology.%s" % String(river.get("segment_id", "river")),
            String(river.get("segment_id", "")),
            &"hydrology",
            &"river",
            river.get("start", Vector2i.ZERO),
            river.get("end", Vector2i.ZERO),
            int(river.get("width", 1)),
            true
        ))
    for bridge_value: Variant in hydrology_result.get("bridges", []):
        if typeof(bridge_value) != TYPE_DICTIONARY:
            continue
        var bridge: Dictionary = bridge_value
        constraints.append(_point_constraint(
            "constraint.hydrology.%s" % String(bridge.get("id", "bridge")),
            String(bridge.get("id", "")),
            &"hydrology",
            &"bridge_intent",
            &"service",
            bridge.get("cell", Vector2i.ZERO),
            false,
            false,
            "",
            ""
        ))

    var power_result: Dictionary = power_constraints_for_bounds(plan, bounds)
    if not bool(power_result.get("ok", false)):
        return {"ok": false, "failure_reason": "smalltown_power_projection_failed", "constraints": constraints}
    for power_segment_value: Variant in power_result.get("segments", []):
        if typeof(power_segment_value) != TYPE_DICTIONARY:
            continue
        var power_segment: Dictionary = power_segment_value
        constraints.append(_corridor_constraint(
            "constraint.power.%s" % String(power_segment.get("id", "segment")),
            String(power_segment.get("id", "")),
            &"power",
            StringName(power_segment.get("power_class", &"feeder")),
            power_segment.get("start", Vector2i.ZERO),
            power_segment.get("end", Vector2i.ZERO),
            1,
            false,
            String(power_segment.get("network_id", ""))
        ))
    var found_substation: bool = false
    for power_node_value: Variant in power_result.get("nodes", []):
        if typeof(power_node_value) != TYPE_DICTIONARY:
            continue
        var power_node: Dictionary = power_node_value
        var power_kind: StringName = StringName(power_node.get("kind", &""))
        var power_role: StringName = &"facility" if power_kind == &"substation" else &"service"
        if power_kind == &"substation":
            found_substation = true
        constraints.append(_point_constraint(
            "constraint.power.%s" % String(power_node.get("id", "node")),
            String(power_node.get("id", "")),
            &"power",
            power_kind,
            power_role,
            power_node.get("cell", Vector2i.ZERO),
            power_role == &"facility",
            power_role == &"facility",
            String(power_node.get("settlement_id", "")),
            String(power_node.get("network_id", ""))
        ))
    if not found_substation:
        return {"ok": false, "failure_reason": "smalltown_substation_missing", "constraints": constraints}

    for water_segment_value: Variant in water_result.get("segments", []):
        if typeof(water_segment_value) != TYPE_DICTIONARY:
            continue
        var water_segment: Dictionary = water_segment_value
        constraints.append(_corridor_constraint(
            "constraint.water.%s" % String(water_segment.get("id", "segment")),
            String(water_segment.get("id", "")),
            &"potable_water",
            StringName(water_segment.get("water_class", &"municipal_trunk")),
            water_segment.get("start", Vector2i.ZERO),
            water_segment.get("end", Vector2i.ZERO),
            1,
            false,
            String(water_segment.get("network_id", ""))
        ))
    for water_node_value: Variant in water_result.get("nodes", []):
        if typeof(water_node_value) != TYPE_DICTIONARY:
            continue
        var water_node: Dictionary = water_node_value
        var water_kind: StringName = StringName(water_node.get("kind", &""))
        var water_facility: bool = water_kind == &"groundwater_source" or water_kind == &"treatment_storage"
        constraints.append(_point_constraint(
            "constraint.water.%s" % String(water_node.get("id", "node")),
            String(water_node.get("id", "")),
            &"potable_water",
            water_kind,
            &"facility" if water_facility else &"service",
            water_node.get("cell", Vector2i.ZERO),
            water_facility,
            water_facility,
            String(water_node.get("settlement_id", "")),
            String(water_node.get("network_id", ""))
        ))

    for waste_segment_value: Variant in wastewater_result.get("segments", []):
        if typeof(waste_segment_value) != TYPE_DICTIONARY:
            continue
        var waste_segment: Dictionary = waste_segment_value
        constraints.append(_corridor_constraint(
            "constraint.wastewater.%s" % String(waste_segment.get("id", "segment")),
            String(waste_segment.get("id", "")),
            &"wastewater",
            StringName(waste_segment.get("wastewater_class", &"municipal_collection_trunk")),
            waste_segment.get("start", Vector2i.ZERO),
            waste_segment.get("end", Vector2i.ZERO),
            1,
            false,
            String(waste_segment.get("network_id", ""))
        ))
    for waste_node_value: Variant in wastewater_result.get("nodes", []):
        if typeof(waste_node_value) != TYPE_DICTIONARY:
            continue
        var waste_node: Dictionary = waste_node_value
        var waste_kind: StringName = StringName(waste_node.get("kind", &""))
        var waste_facility: bool = waste_kind == &"treatment_disposal"
        constraints.append(_point_constraint(
            "constraint.wastewater.%s" % String(waste_node.get("id", "node")),
            String(waste_node.get("id", "")),
            &"wastewater",
            waste_kind,
            &"facility" if waste_facility else &"service",
            waste_node.get("cell", Vector2i.ZERO),
            waste_facility,
            waste_facility,
            String(waste_node.get("settlement_id", "")),
            String(waste_node.get("network_id", ""))
        ))

    return {"ok": true, "failure_reason": "", "constraints": constraints}

func _rural_scattered_planning_constraints(plan: GeneratedGlobalWorldPlan, site: Dictionary) -> Dictionary:
    var constraints: Array[Dictionary] = []
    var bounds: Rect2i = site.get("bounds", Rect2i())
    var settlement_id: String = String(site.get("settlement_id", ""))
    var settlement: Dictionary = _settlement_by_id(plan.settlements, settlement_id)
    if settlement.is_empty():
        return {"ok": false, "failure_reason": "rural_scattered_settlement_missing", "constraints": constraints}
    var center: Vector2i = settlement.get("center", Vector2i(-999999, -999999))
    if not bounds.has_point(center):
        return {"ok": false, "failure_reason": "rural_scattered_settlement_center_invalid", "constraints": constraints}

    var hydrology_result: Dictionary = hydrology_constraints_for_bounds(plan, bounds)
    if not bool(hydrology_result.get("ok", false)):
        return {"ok": false, "failure_reason": "rural_scattered_hydrology_projection_failed", "constraints": constraints}
    for river_value: Variant in hydrology_result.get("rivers", []):
        if typeof(river_value) != TYPE_DICTIONARY:
            continue
        var river: Dictionary = river_value
        constraints.append(_corridor_constraint(
            "constraint.hydrology.%s" % String(river.get("segment_id", "river")),
            String(river.get("segment_id", "")),
            &"hydrology",
            &"river",
            river.get("start", Vector2i.ZERO),
            river.get("end", Vector2i.ZERO),
            int(river.get("width", 1)),
            true
        ))
    for bridge_value: Variant in hydrology_result.get("bridges", []):
        if typeof(bridge_value) != TYPE_DICTIONARY:
            continue
        var bridge: Dictionary = bridge_value
        constraints.append(_point_constraint(
            "constraint.hydrology.%s" % String(bridge.get("id", "bridge")),
            String(bridge.get("id", "")),
            &"hydrology",
            &"bridge_intent",
            &"service",
            bridge.get("cell", center),
            false,
            false,
            settlement_id,
            ""
        ))

    var power_result: Dictionary = power_constraints_for_bounds(plan, bounds)
    if not bool(power_result.get("ok", false)):
        return {"ok": false, "failure_reason": "rural_scattered_power_projection_failed", "constraints": constraints}
    for power_segment_value: Variant in power_result.get("segments", []):
        if typeof(power_segment_value) != TYPE_DICTIONARY:
            continue
        var power_segment: Dictionary = power_segment_value
        constraints.append(_corridor_constraint(
            "constraint.power.%s" % String(power_segment.get("id", "segment")),
            String(power_segment.get("id", "")),
            &"power",
            StringName(power_segment.get("power_class", &"feeder")),
            power_segment.get("start", Vector2i.ZERO),
            power_segment.get("end", Vector2i.ZERO),
            1,
            false,
            String(power_segment.get("network_id", ""))
        ))
    var found_power_service: bool = false
    for power_node_value: Variant in power_result.get("nodes", []):
        if typeof(power_node_value) != TYPE_DICTIONARY:
            continue
        var power_node: Dictionary = power_node_value
        if String(power_node.get("settlement_id", "")) != settlement_id:
            continue
        if StringName(power_node.get("kind", &"")) != &"settlement_service":
            continue
        found_power_service = true
        constraints.append(_point_constraint(
            "constraint.power.%s" % String(power_node.get("id", "node")),
            String(power_node.get("id", "")),
            &"power",
            &"settlement_service",
            &"service",
            power_node.get("cell", center),
            false,
            false,
            settlement_id,
            String(power_node.get("network_id", ""))
        ))
    if not found_power_service:
        return {"ok": false, "failure_reason": "rural_scattered_power_service_missing", "constraints": constraints}

    var water_result: Dictionary = water_constraints_for_bounds(plan, bounds)
    if not bool(water_result.get("ok", false)):
        return {"ok": false, "failure_reason": "rural_scattered_water_projection_failed", "constraints": constraints}
    var water_service: Dictionary = _service_by_settlement(water_result.get("services", []), settlement_id)
    if water_service.is_empty() \
        or StringName(water_service.get("service_mode", &"")) != &"decentralized_source" \
        or StringName(water_service.get("source_type", &"")) != &"groundwater":
        return {"ok": false, "failure_reason": "rural_scattered_decentralized_water_service_missing", "constraints": constraints}
    var water_constraint: Dictionary = _point_constraint(
        "constraint.water.%s" % String(water_service.get("id", "service")),
        String(water_service.get("id", "")),
        &"potable_water",
        &"decentralized_source",
        &"service",
        center,
        false,
        false,
        settlement_id,
        String(water_service.get("network_id", ""))
    )
    water_constraint["service_mode"] = StringName(water_service.get("service_mode", &""))
    water_constraint["source_type"] = StringName(water_service.get("source_type", &""))
    constraints.append(water_constraint)

    var wastewater_result: Dictionary = wastewater_constraints_for_bounds(plan, bounds)
    if not bool(wastewater_result.get("ok", false)):
        return {"ok": false, "failure_reason": "rural_scattered_wastewater_projection_failed", "constraints": constraints}
    var wastewater_service: Dictionary = _service_by_settlement(wastewater_result.get("services", []), settlement_id)
    if wastewater_service.is_empty() \
        or StringName(wastewater_service.get("service_mode", &"")) != &"decentralized_septic" \
        or StringName(wastewater_service.get("disposal_type", &"")) != &"onsite_septic" \
        or StringName(wastewater_service.get("separation_policy", &"")) != &"potable_source_clearance_required":
        return {"ok": false, "failure_reason": "rural_scattered_decentralized_wastewater_service_missing", "constraints": constraints}
    var wastewater_constraint: Dictionary = _point_constraint(
        "constraint.wastewater.%s" % String(wastewater_service.get("id", "service")),
        String(wastewater_service.get("id", "")),
        &"wastewater",
        &"decentralized_septic",
        &"service",
        center,
        false,
        false,
        settlement_id,
        String(wastewater_service.get("network_id", ""))
    )
    wastewater_constraint["service_mode"] = StringName(wastewater_service.get("service_mode", &""))
    wastewater_constraint["disposal_type"] = StringName(wastewater_service.get("disposal_type", &""))
    wastewater_constraint["separation_policy"] = StringName(wastewater_service.get("separation_policy", &""))
    constraints.append(wastewater_constraint)

    return {"ok": true, "failure_reason": "", "constraints": constraints}

func _service_by_settlement(services: Array, settlement_id: String) -> Dictionary:
    for service_value: Variant in services:
        if typeof(service_value) != TYPE_DICTIONARY:
            continue
        var service: Dictionary = service_value
        if String(service.get("settlement_id", "")) == settlement_id:
            return service
    return {}

func _corridor_constraint(
    id: String,
    source_id: String,
    domain: StringName,
    kind: StringName,
    start: Vector2i,
    finish: Vector2i,
    width: int,
    blocks_local_roads: bool,
    network_id: String = ""
) -> Dictionary:
    return {
        "id": id,
        "source_id": source_id,
        "domain": domain,
        "kind": kind,
        "reservation_role": &"corridor",
        "start": start,
        "end": finish,
        "width": maxi(1, width),
        "blocks_parcels": true,
        "blocks_local_roads": blocks_local_roads,
        "network_id": network_id,
    }

func _point_constraint(
    id: String,
    source_id: String,
    domain: StringName,
    kind: StringName,
    reservation_role: StringName,
    cell: Vector2i,
    blocks_parcels: bool,
    blocks_local_roads: bool,
    settlement_id: String,
    network_id: String
) -> Dictionary:
    return {
        "id": id,
        "source_id": source_id,
        "domain": domain,
        "kind": kind,
        "reservation_role": reservation_role,
        "cell": cell,
        "blocks_parcels": blocks_parcels,
        "blocks_local_roads": blocks_local_roads,
        "settlement_id": settlement_id,
        "network_id": network_id,
    }

func road_constraints_for_bounds(plan: GeneratedGlobalWorldPlan, bounds: Rect2i) -> Dictionary:
    var roads: Array[Dictionary] = []
    if plan == null or not plan.is_generated() or not _rect_inside(plan.bounds, bounds):
        return {"ok": false, "failure_reason": "invalid_global_road_projection_bounds", "roads": roads}
    for segment: Dictionary in plan.road_segments:
        if _segment_overlap_is_single_point(segment, bounds) or _segment_overlap_is_boundary_tangent(segment, bounds):
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
        roads.append({
            "road_id": String(segment.get("road_id", "")),
            "road_class": StringName(segment.get("road_class", &"")),
            "start": start,
            "end": finish,
            "width": int(segment.get("width", 0)),
            "allowed_boundary_cells": allowed,
        })
    return {"ok": true, "failure_reason": "", "roads": roads}

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

func _segment_overlap_is_boundary_tangent(segment: Dictionary, bounds: Rect2i) -> bool:
    var start: Vector2i = segment.get("start", Vector2i.ZERO)
    var finish: Vector2i = segment.get("end", Vector2i.ZERO)
    var min_x: int = bounds.position.x
    var max_x: int = bounds.position.x + bounds.size.x - 1
    var min_y: int = bounds.position.y
    var max_y: int = bounds.position.y + bounds.size.y - 1
    if start.y == finish.y and (start.y == min_y or start.y == max_y):
        var overlap_min_x: int = maxi(mini(start.x, finish.x), min_x)
        var overlap_max_x: int = mini(maxi(start.x, finish.x), max_x)
        return overlap_max_x > overlap_min_x
    if start.x == finish.x and (start.x == min_x or start.x == max_x):
        var overlap_min_y: int = maxi(mini(start.y, finish.y), min_y)
        var overlap_max_y: int = mini(maxi(start.y, finish.y), max_y)
        return overlap_max_y > overlap_min_y
    return false

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

func _rect_intersection(a: Rect2i, b: Rect2i) -> Rect2i:
    var start_x: int = maxi(a.position.x, b.position.x)
    var start_y: int = maxi(a.position.y, b.position.y)
    var end_x: int = mini(a.position.x + a.size.x, b.position.x + b.size.x)
    var end_y: int = mini(a.position.y + a.size.y, b.position.y + b.size.y)
    if end_x <= start_x or end_y <= start_y:
        return Rect2i()
    return Rect2i(Vector2i(start_x, start_y), Vector2i(end_x - start_x, end_y - start_y))

func _rects_overlap_positive(a: Rect2i, b: Rect2i) -> bool:
    return _rect_intersection(a, b).size.x > 0 and _rect_intersection(a, b).size.y > 0

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

func project_watercourse_bounds(
    plan: GeneratedGlobalWorldPlan,
    area_id: String,
    bounds: Rect2i
) -> Dictionary:
    var helper_script: Variant = load("res://scripts/generation/integration/System20WatercourseRequestProjection.gd")
    if helper_script == null:
        return {"ok": false, "failure_reason": "watercourse_projection_helper_missing", "request": null}
    var helper: Variant = helper_script.new()
    return helper.project(
        plan,
        area_id,
        bounds,
        Callable(self, "_rural_open_context_contains_bounds"),
        Callable(self, "road_constraints_for_bounds")
    )
