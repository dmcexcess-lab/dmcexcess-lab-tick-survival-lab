extends RefCounted
class_name GeneratedGlobalWorldPlan

var world_id: String = ""
var seed: int = 0
var bounds: Rect2i = Rect2i()
var profile_id: StringName = &""
var profile_version: int = 0
var geography_cells: Array[Dictionary] = []
var river_segments: Array[Dictionary] = []
var regions: Array[Dictionary] = []
var settlements: Array[Dictionary] = []
var road_segments: Array[Dictionary] = []
var bridge_intents: Array[Dictionary] = []
var area_sites: Array[Dictionary] = []
var failure_reason: String = ""

func is_generated() -> bool:
    return failure_reason.is_empty() \
        and not world_id.is_empty() \
        and bounds.size.x > 0 and bounds.size.y > 0 \
        and profile_version > 0 \
        and not geography_cells.is_empty() \
        and not settlements.is_empty() \
        and not road_segments.is_empty()

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
    for river: Dictionary in river_segments:
        var river_start: Vector2i = river.get("start", Vector2i.ZERO)
        var river_end: Vector2i = river.get("end", Vector2i.ZERO)
        parts.append("river=%s|%s|%d,%d>%d,%d|w%d|o%d" % [
            String(river.get("segment_id", "")),
            String(river.get("river_id", "")),
            river_start.x, river_start.y, river_end.x, river_end.y,
            int(river.get("width", 0)),
            int(river.get("ordinal", 0)),
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
    for bridge: Dictionary in bridge_intents:
        var cell: Vector2i = bridge.get("cell", Vector2i.ZERO)
        parts.append("bridge=%s|%s|%s|%s|%s|%d,%d|%s|rw%d|ww%d" % [
            String(bridge.get("id", "")),
            String(bridge.get("road_id", "")),
            String(bridge.get("route_id", "")),
            String(bridge.get("river_id", "")),
            String(bridge.get("river_segment_id", "")),
            cell.x, cell.y,
            String(bridge.get("bridge_axis", &"")),
            int(bridge.get("road_width", 0)),
            int(bridge.get("river_width", 0)),
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
    return "\n".join(parts)
