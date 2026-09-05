extends RefCounted
class_name UtilityLocalPowerTopologyPlanner

const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const AreaGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")

const TARGET_BUILDINGS_PER_SUBSTATION: int = 10
const INVALID_CELL := Vector2i(2147483647, 2147483647)

## One-shot bridge from deterministic local-area generation to System 33 power truth.
## Substation count is derived from the buildings that the generated sites actually contain;
## there is no fixed island substation count and no recurring world scan. Water is owned by
## the separate single-facility runtime model and does not participate in this planner.
func plan(global_plan: GeneratedGlobalWorldPlan) -> Dictionary:
    if global_plan == null or not global_plan.is_generated():
        return _failure("invalid_global_power_topology_input")

    var projector := ProjectorClass.new()
    var generator := AreaGeneratorClass.new()
    var sites: Array[Dictionary] = []
    for site_value: Variant in global_plan.area_sites:
        if typeof(site_value) == TYPE_DICTIONARY:
            sites.append((site_value as Dictionary).duplicate(true))
    sites.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("id", "")) < String(b.get("id", ""))
    )

    var buildings: Array[Dictionary] = []
    var building_ids: Dictionary = {}
    var blocked_prop_cells: Dictionary = {}
    var pole_exclusion_cells: Dictionary = {}
    var local_roads: Array[Dictionary] = []
    var site_building_counts: Dictionary = {}
    var used_cached_manifest: bool = false

    var cached_manifest: Dictionary = global_plan.local_area_manifest
    if _cached_manifest_is_valid(cached_manifest, global_plan, sites):
        used_cached_manifest = true
        for value: Variant in cached_manifest.get("buildings", []):
            buildings.append((value as Dictionary).duplicate(true))
        site_building_counts = (cached_manifest.get("site_building_counts", {}) as Dictionary).duplicate(true)
        for value: Variant in cached_manifest.get("blocked_prop_cells", []):
            blocked_prop_cells[value] = true
        for value: Variant in cached_manifest.get("pole_exclusion_cells", []):
            pole_exclusion_cells[value] = true
        for value: Variant in cached_manifest.get("local_roads", []):
            local_roads.append((value as Dictionary).duplicate(true))
    else:
        for site: Dictionary in sites:
            var site_id: String = String(site.get("id", "")).strip_edges()
            if site_id.is_empty():
                return _failure("local_power_site_id_missing")
            var projected: Dictionary = projector.project_site(global_plan, site_id)
            if not bool(projected.get("ok", false)):
                return _failure("local_power_site_projection_failed:%s:%s" % [site_id, String(projected.get("failure_reason", "unknown"))])
            var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
            var area_plan: GeneratedAreaPlan = generator.generate(request)
            if area_plan == null or not area_plan.is_generated():
                return _failure("local_power_site_generation_failed:%s:%s" % [site_id, "null" if area_plan == null else area_plan.failure_reason])

            var settlement_id: String = String(site.get("settlement_id", "")).strip_edges()
            var site_count: int = 0
            for building_request: BuildingGenerationRequest in area_plan.building_requests:
                if building_request == null or not building_request.is_valid() or building_ids.has(building_request.instance_id):
                    return _failure("local_power_building_request_invalid:%s" % site_id)
                var rect: Rect2i = building_request.envelope
                var center := Vector2i(
                    rect.position.x + int(rect.size.x / 2),
                    rect.position.y + int(rect.size.y / 2)
                )
                buildings.append({
                    "building_id": building_request.instance_id,
                    "archetype_id": building_request.archetype_id,
                    "rect": rect,
                    "cell": center,
                    "site_id": site_id,
                    "settlement_id": settlement_id,
                })
                building_ids[building_request.instance_id] = true
                site_count += 1
            site_building_counts[site_id] = site_count

            for parcel: Dictionary in area_plan.parcels:
                for value: Variant in parcel.get("driveway_cells", []):
                    if typeof(value) == TYPE_VECTOR2I:
                        pole_exclusion_cells[value] = true
                for value: Variant in parcel.get("parking_cells", []):
                    if typeof(value) == TYPE_VECTOR2I:
                        pole_exclusion_cells[value] = true
            for prop: Dictionary in area_plan.outdoor_props:
                blocked_prop_cells[prop.get("cell", INVALID_CELL)] = true
            for road: Dictionary in area_plan.roads:
                local_roads.append(road.duplicate(true))

    if buildings.is_empty():
        return _failure("local_power_has_no_generated_buildings")

    buildings.sort_custom(_building_before)
    var substations: Array[Dictionary] = []
    var building_service: Dictionary = {}
    var ordinal: int = 1

    for site: Dictionary in sites:
        var site_id: String = String(site.get("id", ""))
        var pending: Array[Dictionary] = []
        for building: Dictionary in buildings:
            if String(building.get("site_id", "")) == site_id:
                pending.append(building)
        pending.sort_custom(_building_before)

        while not pending.is_empty():
            var seed_building: Dictionary = pending.pop_front()
            var seed_cell: Vector2i = seed_building.get("cell", INVALID_CELL)
            pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
                var a_cell: Vector2i = a.get("cell", INVALID_CELL)
                var b_cell: Vector2i = b.get("cell", INVALID_CELL)
                var a_distance: int = absi(a_cell.x - seed_cell.x) + absi(a_cell.y - seed_cell.y)
                var b_distance: int = absi(b_cell.x - seed_cell.x) + absi(b_cell.y - seed_cell.y)
                if a_distance != b_distance:
                    return a_distance < b_distance
                return _building_before(a, b)
            )
            var group: Array[Dictionary] = [seed_building]
            while group.size() < TARGET_BUILDINGS_PER_SUBSTATION and not pending.is_empty():
                group.append(pending.pop_front())
            group.sort_custom(_building_before)

            var service_key: String = "local.%03d" % ordinal
            var service_id: String = "power.service.%s" % service_key
            var substation_id: String = "power.node.substation.%s" % service_key
            var group_building_ids: Array[String] = []
            var group_rects: Array[Rect2i] = []
            var settlement_ids: Array[String] = []
            var site_ids: Array[String] = []
            var cell_sum := Vector2i.ZERO
            for building: Dictionary in group:
                var building_id: String = String(building.get("building_id", ""))
                var building_rect: Rect2i = building.get("rect", Rect2i())
                var building_cell: Vector2i = building.get("cell", INVALID_CELL)
                var building_settlement: String = String(building.get("settlement_id", ""))
                var building_site: String = String(building.get("site_id", ""))
                group_building_ids.append(building_id)
                group_rects.append(building_rect)
                building_service[building_id] = service_id
                cell_sum += building_cell
                if not building_settlement.is_empty() and not settlement_ids.has(building_settlement):
                    settlement_ids.append(building_settlement)
                if not building_site.is_empty() and not site_ids.has(building_site):
                    site_ids.append(building_site)
            settlement_ids.sort()
            site_ids.sort()
            var anchor := Vector2i(
                int(cell_sum.x / group.size()),
                int(cell_sum.y / group.size())
            )
            substations.append({
                "id": substation_id,
                "ordinal": ordinal,
                "service_key": service_key,
                "service_id": service_id,
                "cell": anchor,
                "building_ids": group_building_ids,
                "building_rects": group_rects,
                "settlement_ids": settlement_ids,
                "site_ids": site_ids,
            })
            ordinal += 1

    var blocked_cells: Array[Vector2i] = []
    for value: Variant in blocked_prop_cells.keys():
        var cell: Vector2i = value
        if cell != INVALID_CELL:
            blocked_cells.append(cell)
    blocked_cells.sort_custom(_cell_before)

    var excluded_pole_cells: Array[Vector2i] = []
    for value: Variant in pole_exclusion_cells.keys():
        var cell: Vector2i = value
        if cell != INVALID_CELL:
            excluded_pole_cells.append(cell)
    excluded_pole_cells.sort_custom(_cell_before)

    return {
        "ok": true,
        "failure_reason": "",
        "manifest_source": &"global_plan_cache" if used_cached_manifest else &"generated_fallback",
        "target_buildings_per_substation": TARGET_BUILDINGS_PER_SUBSTATION,
        "building_count": buildings.size(),
        "buildings": buildings,
        "substations": substations,
        "building_service": building_service,
        "site_building_counts": site_building_counts,
        "blocked_prop_cells": blocked_cells,
        "pole_exclusion_cells": excluded_pole_cells,
        "local_roads": local_roads,
    }

func _cached_manifest_is_valid(
    manifest: Dictionary,
    global_plan: GeneratedGlobalWorldPlan,
    sites: Array[Dictionary]
) -> bool:
    if not bool(manifest.get("ok", false)) \
        or int(manifest.get("world_seed", -1)) != global_plan.seed \
        or int(manifest.get("site_count", -1)) != sites.size():
        return false
    var cached_buildings: Array = manifest.get("buildings", [])
    var cached_counts: Dictionary = manifest.get("site_building_counts", {})
    if cached_buildings.is_empty() or cached_counts.size() != sites.size():
        return false
    var seen: Dictionary = {}
    for value: Variant in cached_buildings:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var building: Dictionary = value
        var building_id: String = String(building.get("building_id", "")).strip_edges()
        var site_id: String = String(building.get("site_id", "")).strip_edges()
        if building_id.is_empty() or site_id.is_empty() or seen.has(building_id) \
            or not cached_counts.has(site_id):
            return false
        seen[building_id] = true
    return true

static func _building_before(a: Dictionary, b: Dictionary) -> bool:
    var a_cell: Vector2i = a.get("cell", INVALID_CELL)
    var b_cell: Vector2i = b.get("cell", INVALID_CELL)
    if a_cell.y != b_cell.y:
        return a_cell.y < b_cell.y
    if a_cell.x != b_cell.x:
        return a_cell.x < b_cell.x
    return String(a.get("building_id", "")) < String(b.get("building_id", ""))

static func _cell_before(a: Vector2i, b: Vector2i) -> bool:
    if a.y != b.y:
        return a.y < b.y
    return a.x < b.x

static func _failure(reason: String) -> Dictionary:
    return {
        "ok": false,
        "failure_reason": reason,
        "manifest_source": &"none",
        "target_buildings_per_substation": TARGET_BUILDINGS_PER_SUBSTATION,
        "building_count": 0,
        "buildings": [],
        "substations": [],
        "building_service": {},
        "site_building_counts": {},
        "blocked_prop_cells": [],
        "pole_exclusion_cells": [],
        "local_roads": [],
    }
