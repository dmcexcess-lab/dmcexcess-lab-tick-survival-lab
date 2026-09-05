extends RefCounted
class_name GlobalWaterInfrastructureValidator

func validate(request: GlobalWorldGenerationRequest, plan: GeneratedGlobalWorldPlan) -> Dictionary:
    var failures: Array[String] = []
    if request == null or not request.is_valid() or plan == null:
        return {"ok": false, "failures": ["invalid_global_water_validation_input"]}
    if plan.water_services.is_empty():
        failures.append("global_water_service_refs_missing")
        return {"ok": false, "failures": failures}
    if not plan.water_nodes.is_empty() or not plan.water_segments.is_empty():
        failures.append("global_water_network_topology_forbidden")

    var settlements: Dictionary = {}
    for settlement: Dictionary in plan.settlements:
        var settlement_id: String = String(settlement.get("id", "")).strip_edges()
        if not settlement_id.is_empty():
            settlements[settlement_id] = true
    var seen_settlements: Dictionary = {}
    var facility_id: String = ""
    var host_site_id: String = ""
    var host_settlement_id: String = ""
    for service: Dictionary in plan.water_services:
        var service_id: String = String(service.get("id", "")).strip_edges()
        var settlement_id: String = String(service.get("settlement_id", "")).strip_edges()
        var candidate_facility: String = String(service.get("facility_id", "")).strip_edges()
        var candidate_host_site: String = String(service.get("host_site_id", "")).strip_edges()
        var candidate_host_settlement: String = String(service.get("host_settlement_id", "")).strip_edges()
        if service_id.is_empty() or settlement_id.is_empty() or not settlements.has(settlement_id) or seen_settlements.has(settlement_id):
            failures.append("global_water_service_ref_identity_invalid")
            continue
        seen_settlements[settlement_id] = true
        if candidate_facility.is_empty() or candidate_host_site.is_empty() or candidate_host_settlement.is_empty():
            failures.append("global_water_facility_identity_missing")
        if facility_id.is_empty():
            facility_id = candidate_facility
            host_site_id = candidate_host_site
            host_settlement_id = candidate_host_settlement
        elif facility_id != candidate_facility or host_site_id != candidate_host_site or host_settlement_id != candidate_host_settlement:
            failures.append("global_water_multiple_physical_facilities_forbidden")
        if StringName(service.get("service_mode", &"")) != &"island_wide_municipal" \
            or StringName(service.get("source_type", &"")) != &"treated_municipal" \
            or not bool(service.get("island_wide", false)):
            failures.append("global_water_service_ref_mode_invalid")
        if String(service.get("plant_id", "")) != candidate_facility:
            failures.append("global_water_service_ref_facility_mismatch")
        if String(StringName(service.get("preferred_archetype_id", &""))).is_empty():
            failures.append("global_water_facility_preferred_archetype_missing")

    if seen_settlements.size() != settlements.size() or plan.water_services.size() != settlements.size():
        failures.append("global_water_service_ref_count_invalid")
    var host_site: Dictionary = _site_by_id(plan.area_sites, host_site_id)
    if host_site.is_empty() or String(host_site.get("settlement_id", "")) != host_settlement_id:
        failures.append("global_water_facility_host_site_invalid")
    if not settlements.has(host_settlement_id):
        failures.append("global_water_facility_host_settlement_missing")

    if not plan.wastewater_services.is_empty() or not plan.wastewater_nodes.is_empty() or not plan.wastewater_segments.is_empty():
        failures.append("global_wastewater_model_forbidden")
    return {"ok": failures.is_empty(), "failures": failures}

func _site_by_id(sites: Array[Dictionary], site_id: String) -> Dictionary:
    for site: Dictionary in sites:
        if String(site.get("id", "")) == site_id:
            return site
    return {}
