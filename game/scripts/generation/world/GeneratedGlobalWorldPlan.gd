extends RefCounted
class_name GeneratedGlobalWorldPlan

var world_id: String = ""
var seed: int = 0
var bounds: Rect2i = Rect2i()
var profile_id: StringName = &""
var profile_version: int = 0
var geography_cells: Array[Dictionary] = []
var regions: Array[Dictionary] = []
var settlements: Array[Dictionary] = []
var road_segments: Array[Dictionary] = []
var power_nodes: Array[Dictionary] = []
var power_segments: Array[Dictionary] = []
var water_services: Array[Dictionary] = []
var area_sites: Array[Dictionary] = []
## Compact, deterministic projection of the real local-area plans. This lets
## population and utility boot share one whole-island generation pass instead
## of regenerating every settlement twice before the first frame.
var local_area_manifest: Dictionary = {}
var population_settlements: Array[Dictionary] = []
var resident_population: int = 0
var infected_population: int = 0
var survivor_population: int = 0
var failure_reason: String = ""

func is_generated() -> bool:
    return failure_reason.is_empty() \
        and not world_id.is_empty() \
        and bounds.size.x > 0 and bounds.size.y > 0 \
        and profile_version > 0 \
        and not geography_cells.is_empty() \
        and not settlements.is_empty() \
        and not road_segments.is_empty() \
        and not power_nodes.is_empty() \
        and not power_segments.is_empty() \
        and not water_services.is_empty()

func signature() -> String:
    if not is_generated():
        return "FAILED:%s" % failure_reason
    var parts := PackedStringArray()
    parts.append("world=%s" % world_id)
    parts.append("seed=%d" % seed)
    parts.append("bounds=%d,%d,%d,%d" % [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y])
    parts.append("profile=%s@%d" % [String(profile_id), profile_version])
    for geography: Dictionary in geography_cells:
        var grid: Vector2i = geography.get("grid", Vector2i.ZERO)
        var rect: Rect2i = geography.get("rect", Rect2i())
        parts.append("geography=%s|g%d,%d|%d,%d,%d,%d|e%d|%s" % [
            String(geography.get("id", "")),
            grid.x, grid.y,
            rect.position.x, rect.position.y, rect.size.x, rect.size.y,
            int(geography.get("elevation", 0)),
            String(geography.get("landform", &"")),
        ])
    for region: Dictionary in regions:
        var rect: Rect2i = region.get("rect", Rect2i())
        parts.append("region=%s|%s|%d,%d,%d,%d|p%d|%s|%s" % [
            String(region.get("id", "")),
            String(region.get("kind", &"")),
            rect.position.x, rect.position.y, rect.size.x, rect.size.y,
            int(region.get("priority", 0)),
            String(region.get("area_profile_hint", &"")),
            String(region.get("settlement_id", "")),
        ])
    for settlement: Dictionary in settlements:
        var center: Vector2i = settlement.get("center", Vector2i.ZERO)
        parts.append("settlement=%s|%s|%d,%d|r%d|%s" % [
            String(settlement.get("id", "")),
            String(settlement.get("kind", &"")),
            center.x, center.y,
            int(settlement.get("influence_radius", 0)),
            String(settlement.get("area_site_id", "")),
        ])
    for road: Dictionary in road_segments:
        var start: Vector2i = road.get("start", Vector2i.ZERO)
        var finish: Vector2i = road.get("end", Vector2i.ZERO)
        parts.append("road=%s|%s|%d,%d>%d,%d|w%d|%s" % [
            String(road.get("road_id", "")),
            String(road.get("road_class", &"")),
            start.x, start.y, finish.x, finish.y,
            int(road.get("width", 0)),
            String(road.get("route_id", "")),
        ])
    for power_node: Dictionary in power_nodes:
        var power_cell: Vector2i = power_node.get("cell", Vector2i.ZERO)
        parts.append("power_node=%s|%s|%s|%d,%d|%s" % [
            String(power_node.get("id", "")),
            String(power_node.get("network_id", "")),
            String(power_node.get("kind", &"")),
            power_cell.x, power_cell.y,
            String(power_node.get("settlement_id", "")),
        ])
    for power_segment: Dictionary in power_segments:
        var power_start: Vector2i = power_segment.get("start", Vector2i.ZERO)
        var power_end: Vector2i = power_segment.get("end", Vector2i.ZERO)
        parts.append("power_segment=%s|%s|%s|%d,%d>%d,%d|o%d|%s|%s" % [
            String(power_segment.get("id", "")),
            String(power_segment.get("network_id", "")),
            String(power_segment.get("power_class", &"")),
            power_start.x, power_start.y, power_end.x, power_end.y,
            int(power_segment.get("ordinal", 0)),
            String(power_segment.get("source_road_id", "")),
            String(power_segment.get("source_route_id", "")),
        ])
    for water_service: Dictionary in water_services:
        parts.append("water_service=%s|%s|%s|%s|%s" % [
            String(water_service.get("id", "")),
            String(water_service.get("settlement_id", "")),
            String(water_service.get("service_mode", &"")),
            String(water_service.get("source_type", &"")),
            String(water_service.get("facility_id", "")),
        ])
    for site: Dictionary in area_sites:
        var site_bounds: Rect2i = site.get("bounds", Rect2i())
        parts.append("site=%s|%s|%d,%d,%d,%d|seed%d|%s|%s" % [
            String(site.get("id", "")),
            String(site.get("settlement_id", "")),
            site_bounds.position.x, site_bounds.position.y, site_bounds.size.x, site_bounds.size.y,
            int(site.get("seed", 0)),
            String(site.get("area_profile_hint", &"")),
            String(site.get("environment_profile_hint", &"")),
        ])
    parts.append("population=%d|%d|%d" % [resident_population, infected_population, survivor_population])
    for population: Dictionary in population_settlements:
        parts.append("population_settlement=%s|%s|r%d|i%d|s%d" % [
            String(population.get("settlement_id", "")),
            String(population.get("area_site_id", "")),
            int(population.get("resident_population", 0)),
            int(population.get("infected_population", 0)),
            int(population.get("survivor_population", 0)),
        ])
        for household: Dictionary in population.get("households", []):
            parts.append("household=%s|%s|c%d" % [
                String(household.get("building_id", "")),
                String(household.get("archetype_id", "")),
                int(household.get("capacity", 0)),
            ])
    return "\n".join(parts)
