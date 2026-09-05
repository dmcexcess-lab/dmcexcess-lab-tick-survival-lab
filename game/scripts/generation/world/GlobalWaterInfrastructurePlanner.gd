extends RefCounted
class_name GlobalWaterInfrastructurePlanner

const SERVICE_ID: String = "water.service.island"
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

    # Water is intentionally binary at island scope. There is one physical building
    # selected from the generated host site. Runtime availability is exactly that
    # building/facility's operational state; there is no pipe, node, well, treatment
    # chain, or settlement-by-settlement network model.
    var service: Dictionary = {
        "id": SERVICE_ID,
        "facility_id": FACILITY_ID,
        "settlement_id": host_settlement_id,
        "host_site_id": host_site_id,
        "preferred_archetype_id": PREFERRED_ARCHETYPE,
        "service_mode": &"single_building_island_wide",
        "source_type": &"facility_operational_state",
        "island_wide": true,
    }
    return {
        "ok": true,
        "failure_reason": "",
        "water_services": [service],
        "water_nodes": [],
        "water_segments": [],
    }

func _preferred_host_site(area_sites: Array[Dictionary]) -> Dictionary:
    # Prefer the first small-town center because its manifest always contains
    # substantial civic/commercial buildings. Deterministic fallbacks keep older
    # regional test fixtures valid without inventing another water object.
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
