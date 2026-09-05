extends RefCounted
class_name GlobalWaterInfrastructurePlanner

const FACILITY_ID: String = "water.facility.island"
const PREFERRED_ARCHETYPE: StringName = &"civic.post_office.small"

func plan(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    settlements: Array[Dictionary],
    area_sites: Array[Dictionary],
    road_segments: Array[Dictionary]
) -> Dictionary:
    if request == null or not request.is_valid() or profile.is_empty() or settlements.is_empty() \
        or area_sites.is_empty() or road_segments.is_empty():
        return _failure("invalid_water_infrastructure_planner_input")

    var host_site: Dictionary = _preferred_host_site(area_sites)
    if host_site.is_empty():
        return _failure("water_facility_host_site_missing")
    var host_site_id: String = String(host_site.get("id", "")).strip_edges()
    var host_settlement_id: String = String(host_site.get("settlement_id", "")).strip_edges()
    if host_site_id.is_empty() or host_settlement_id.is_empty():
        return _failure("water_facility_host_identity_invalid")

    # There is one physical water building. Per-settlement service records are only
    # cheap projection references so local-area generation can ask whether a site
    # participates in island water without inventing pipes, wells, or local plants.
    var services: Array[Dictionary] = []
    for index: int in range(settlements.size()):
        var settlement_id: String = String(settlements[index].get("id", "")).strip_edges()
        if settlement_id.is_empty():
            return _failure("water_service_settlement_invalid")
        services.append({
            "id": "water.service.%03d" % [index + 1],
            "facility_id": FACILITY_ID,
            "plant_id": FACILITY_ID,
            "settlement_id": settlement_id,
            "host_settlement_id": host_settlement_id,
            "host_site_id": host_site_id,
            "preferred_archetype_id": PREFERRED_ARCHETYPE,
            "service_mode": &"island_wide_municipal",
            "source_type": &"treated_municipal",
            "network_id": "",
            "island_wide": true,
        })
    return {
        "ok": true,
        "failure_reason": "",
        "water_services": services,
        "water_nodes": [],
        "water_segments": [],
    }

func _preferred_host_site(area_sites: Array[Dictionary]) -> Dictionary:
    var ordered: Array[Dictionary] = area_sites.duplicate(true)
    ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("id", "")) < String(b.get("id", ""))
    )
    for site: Dictionary in ordered:
        if StringName(site.get("area_profile_hint", &"")) == &"smalltown.center":
            return site
    return {} if ordered.is_empty() else ordered[0]

func _failure(reason: String) -> Dictionary:
    return {
        "ok": false,
        "failure_reason": reason,
        "water_services": [],
        "water_nodes": [],
        "water_segments": [],
    }
