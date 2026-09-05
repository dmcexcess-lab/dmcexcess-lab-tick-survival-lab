extends RefCounted
class_name IslandPopulationPlanner

## Population is derived from the same deterministic building manifests that
## materialize the island.  It deliberately records aggregate residents and
## infected groups rather than instantiating thousands of distant actors.

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const LocalGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const INVALID_CELL := Vector2i(2147483647, 2147483647)

func plan(world_plan: GeneratedGlobalWorldPlan) -> Dictionary:
    if world_plan == null or not world_plan.is_generated():
        return _failure("invalid_island_population_plan_input")
    var projector := ProjectorClass.new()
    var generator := LocalGeneratorClass.new()
    var settlements: Array[Dictionary] = []
    var total_residents: int = 0
    var total_infected: int = 0
    var total_survivors: int = 0
    var all_buildings: Array[Dictionary] = []
    var building_ids: Dictionary = {}
    var blocked_prop_cells: Dictionary = {}
    var pole_exclusion_cells: Dictionary = {}
    var local_roads: Array[Dictionary] = []
    var site_building_counts: Dictionary = {}
    for site: Dictionary in world_plan.area_sites:
        var site_id: String = String(site.get("id", ""))
        var settlement_id: String = String(site.get("settlement_id", ""))
        var projected: Dictionary = projector.project_site(world_plan, site_id)
        if not bool(projected.get("ok", false)):
            return _failure("island_population_site_projection_failed:%s" % site_id)
        var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
        if request == null or not request.is_valid():
            return _failure("island_population_site_request_invalid:%s" % site_id)
        var area_plan: GeneratedAreaPlan = generator.generate_manifest(request)
        if area_plan == null or not area_plan.is_generated():
            return _failure("island_population_site_generation_failed:%s:%s" % [site_id, "null" if area_plan == null else area_plan.failure_reason])
        var household_records: Array[Dictionary] = []
        var residents: int = 0
        for building: BuildingGenerationRequest in area_plan.building_requests:
            if building == null or not building.is_valid() or building_ids.has(building.instance_id):
                return _failure("island_population_building_request_invalid:%s" % site_id)
            var rect: Rect2i = building.envelope
            all_buildings.append({
                "building_id": building.instance_id,
                "archetype_id": building.archetype_id,
                "rect": rect,
                "cell": rect.position + Vector2i(rect.size.x / 2, rect.size.y / 2),
                "site_id": site_id,
                "settlement_id": settlement_id,
            })
            building_ids[building.instance_id] = true
            var capacity: int = _resident_capacity(building.archetype_id)
            if capacity <= 0:
                continue
            household_records.append({
                "building_id": building.instance_id,
                "archetype_id": building.archetype_id,
                "capacity": capacity,
            })
            residents += capacity
        site_building_counts[site_id] = area_plan.building_requests.size()
        for parcel: Dictionary in area_plan.parcels:
            for value: Variant in parcel.get("driveway_cells", []):
                if typeof(value) == TYPE_VECTOR2I:
                    pole_exclusion_cells[value] = true
            for value: Variant in parcel.get("parking_cells", []):
                if typeof(value) == TYPE_VECTOR2I:
                    pole_exclusion_cells[value] = true
        for prop: Dictionary in area_plan.outdoor_props:
            var prop_cell: Vector2i = prop.get("cell", INVALID_CELL)
            if prop_cell != INVALID_CELL:
                blocked_prop_cells[prop_cell] = true
        for road: Dictionary in area_plan.roads:
            local_roads.append(road.duplicate(true))
        if household_records.is_empty() or residents <= 0:
            return _failure("island_population_site_has_no_real_homes:%s" % site_id)
        var infection_percent: int = 84 + Seed.hash_2d(world_plan.seed, site_id.length(), residents, 9701) % 13
        var infected: int = clampi((residents * infection_percent) / 100, 1, residents)
        var survivor_count: int = residents - infected
        settlements.append({
            "settlement_id": settlement_id,
            "area_site_id": site_id,
            "households": household_records,
            "resident_population": residents,
            "infected_population": infected,
            "survivor_population": survivor_count,
        })
        total_residents += residents
        total_infected += infected
        total_survivors += survivor_count
    var blocked_cells: Array[Vector2i] = _ordered_cells(blocked_prop_cells)
    var excluded_pole_cells: Array[Vector2i] = _ordered_cells(pole_exclusion_cells)
    return {
        "ok": true,
        "failure_reason": "",
        "settlements": settlements,
        "resident_population": total_residents,
        "infected_population": total_infected,
        "survivor_population": total_survivors,
        "local_area_manifest": {
            "ok": true,
            "world_seed": world_plan.seed,
            "site_count": world_plan.area_sites.size(),
            "buildings": all_buildings,
            "site_building_counts": site_building_counts,
            "blocked_prop_cells": blocked_cells,
            "pole_exclusion_cells": excluded_pole_cells,
            "local_roads": local_roads,
        },
    }

func _ordered_cells(cell_set: Dictionary) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for value: Variant in cell_set.keys():
        if typeof(value) == TYPE_VECTOR2I:
            result.append(value)
    result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        return a.y < b.y if a.y != b.y else a.x < b.x
    )
    return result

func _resident_capacity(archetype_id: StringName) -> int:
    match archetype_id:
        &"residential.trailer.singlewide":
            return 2
        &"residential.house.suburban_small", &"residential.house.compact_laundry":
            return 3
        &"residential.house.suburban_family", &"residential.house.farm_small":
            return 4
        &"residential.house.farm_large":
            return 5
        &"residential.townhomes.row3":
            return 8
        &"residential.multiunit.row4":
            return 10
    return 0

func _failure(reason: String) -> Dictionary:
    return {
        "ok": false,
        "failure_reason": reason,
        "settlements": [],
        "resident_population": 0,
        "infected_population": 0,
        "survivor_population": 0,
        "local_area_manifest": {},
    }
