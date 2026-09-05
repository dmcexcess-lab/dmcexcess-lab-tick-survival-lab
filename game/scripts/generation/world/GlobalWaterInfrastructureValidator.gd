extends RefCounted
class_name GlobalWaterInfrastructureValidator

func validate(request: GlobalWorldGenerationRequest, plan: GeneratedGlobalWorldPlan) -> Dictionary:
    var failures: Array[String] = []
    if request == null or not request.is_valid() or plan == null:
        return {"ok": false, "failures": ["invalid_global_water_validation_input"]}
    if plan.water_services.size() != 1:
        failures.append("global_water_single_facility_service_required")
        return {"ok": false, "failures": failures}
    if not plan.water_nodes.is_empty() or not plan.water_segments.is_empty():
        failures.append("global_water_network_topology_forbidden")

    var service: Dictionary = plan.water_services[0]
    var service_id: String = String(service.get("id", "")).strip_edges()
    var facility_id: String = String(service.get("facility_id", "")).strip_edges()
    var settlement_id: String = String(service.get("settlement_id", "")).strip_edges()
    var host_site_id: String = String(service.get("host_site_id", "")).strip_edges()
    var preferred_archetype: StringName = StringName(service.get("preferred_archetype_id", &""))
    if service_id.is_empty() or facility_id.is_empty():
        failures.append("global_water_facility_identity_missing")
    if StringName(service.get("service_mode", &"")) != &"single_building_island_wide":
        failures.append("global_water_facility_mode_invalid")
    if StringName(service.get("source_type", &"")) != &"facility_operational_state":
        failures.append("global_water_facility_source_type_invalid")
    if not bool(service.get("island_wide", false)):
        failures.append("global_water_facility_not_island_wide")
    if String(preferred_archetype).is_empty():
        failures.append("global_water_facility_preferred_archetype_missing")

    var host_site: Dictionary = _site_by_id(plan.area_sites, host_site_id)
    if host_site.is_empty():
        failures.append("global_water_facility_host_site_missing")
    elif String(host_site.get("settlement_id", "")) != settlement_id:
        failures.append("global_water_facility_host_settlement_mismatch")
    if _settlement_by_id(plan.settlements, settlement_id).is_empty():
        failures.append("global_water_facility_settlement_missing")

    # Wastewater, private wells, and water-network geometry are intentionally not
    # part of the world model. Any population here is a regression.
    if not plan.wastewater_services.is_empty() or not plan.wastewater_nodes.is_empty() or not plan.wastewater_segments.is_empty():
        failures.append("global_wastewater_model_forbidden")
    return {"ok": failures.is_empty(), "failures": failures}

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
