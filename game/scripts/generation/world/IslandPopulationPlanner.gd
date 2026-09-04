extends RefCounted
class_name IslandPopulationPlanner

## Population is derived from the same deterministic building manifests that
## materialize the island.  It deliberately records aggregate residents and
## infected groups rather than instantiating thousands of distant actors.

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const LocalGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")

func plan(world_plan: GeneratedGlobalWorldPlan) -> Dictionary:
    if world_plan == null or not world_plan.is_generated():
        return _failure("invalid_island_population_plan_input")
    var projector := ProjectorClass.new()
    var generator := LocalGeneratorClass.new()
    var settlements: Array[Dictionary] = []
    var total_residents: int = 0
    var total_infected: int = 0
    var total_survivors: int = 0
    for site: Dictionary in world_plan.area_sites:
        var site_id: String = String(site.get("id", ""))
        var settlement_id: String = String(site.get("settlement_id", ""))
        var projected: Dictionary = projector.project_site(world_plan, site_id)
        if not bool(projected.get("ok", false)):
            return _failure("island_population_site_projection_failed:%s" % site_id)
        var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
        if request == null or not request.is_valid():
            return _failure("island_population_site_request_invalid:%s" % site_id)
        var area_plan: GeneratedAreaPlan = generator.generate(request)
        if area_plan == null or not area_plan.is_generated():
            return _failure("island_population_site_generation_failed:%s" % site_id)
        var household_records: Array[Dictionary] = []
        var residents: int = 0
        for building: BuildingGenerationRequest in area_plan.building_requests:
            var capacity: int = _resident_capacity(building.archetype_id)
            if capacity <= 0:
                continue
            household_records.append({
                "building_id": building.instance_id,
                "archetype_id": building.archetype_id,
                "capacity": capacity,
            })
            residents += capacity
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
    return {
        "ok": true,
        "failure_reason": "",
        "settlements": settlements,
        "resident_population": total_residents,
        "infected_population": total_infected,
        "survivor_population": total_survivors,
    }

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
    }
