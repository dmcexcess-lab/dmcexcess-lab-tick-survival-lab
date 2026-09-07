extends RefCounted
class_name PopulationResidentProjection

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")

## On-demand individual identity projection from the authoritative aggregate population plan.
## This does not add residents. It deterministically names household slots that were already counted.

func infected_records(population_plan: Dictionary, preferred_area_site_id: String = "") -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not bool(population_plan.get("ok", false)): return result
    var manifest: Dictionary = population_plan.get("local_area_manifest", {})
    var world_seed := int(manifest.get("world_seed", -1))
    if world_seed <= 0: return result
    var building_cells := _building_cells(manifest)
    for settlement_value: Variant in population_plan.get("settlements", []):
        if typeof(settlement_value) != TYPE_DICTIONARY: continue
        var settlement: Dictionary = settlement_value
        var site_id := String(settlement.get("area_site_id", ""))
        if not preferred_area_site_id.is_empty() and site_id != preferred_area_site_id: continue
        var slots := _resident_slots(world_seed, settlement, building_cells)
        var infected_count := clampi(int(settlement.get("infected_population", 0)), 0, slots.size())
        slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
            var sa := int(a.get("infection_score", 0)); var sb := int(b.get("infection_score", 0))
            if sa == sb: return String(a.get("resident_id", "")) < String(b.get("resident_id", ""))
            return sa < sb
        )
        for index in range(infected_count):
            var record: Dictionary = slots[index].duplicate(true)
            record.erase("infection_score")
            record["infected"] = true
            result.append(record)
    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get("resident_id", "")) < String(b.get("resident_id", "")))
    return result

func first_infected_near(population_plan: Dictionary, preferred_area_site_id: String, reference_cell: Vector2i) -> Dictionary:
    var records := infected_records(population_plan, preferred_area_site_id)
    if records.is_empty() and not preferred_area_site_id.is_empty(): records = infected_records(population_plan)
    records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var ac: Vector2i = a.get("home_cell", Vector2i.ZERO); var bc: Vector2i = b.get("home_cell", Vector2i.ZERO)
        var ad := absi(ac.x-reference_cell.x)+absi(ac.y-reference_cell.y); var bd := absi(bc.x-reference_cell.x)+absi(bc.y-reference_cell.y)
        if ad == bd: return String(a.get("resident_id", "")) < String(b.get("resident_id", ""))
        return ad < bd
    )
    return {} if records.is_empty() else records[0].duplicate(true)

func _resident_slots(world_seed: int, settlement: Dictionary, building_cells: Dictionary) -> Array[Dictionary]:
    var slots: Array[Dictionary] = []
    var households: Array = Array(settlement.get("households", [])).duplicate(true)
    households.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get("building_id", "")) < String(b.get("building_id", "")))
    for household_value: Variant in households:
        if typeof(household_value) != TYPE_DICTIONARY: continue
        var household: Dictionary = household_value
        var building_id := String(household.get("building_id", ""))
        var capacity := int(household.get("capacity", 0))
        if building_id.is_empty() or capacity < 1 or not building_cells.has(building_id): continue
        for ordinal in range(1, capacity + 1):
            var resident_id := "resident.%s.%02d" % [building_id, ordinal]
            slots.append({
                "resident_id": resident_id,
                "building_id": building_id,
                "resident_ordinal": ordinal,
                "settlement_id": String(settlement.get("settlement_id", "")),
                "area_site_id": String(settlement.get("area_site_id", "")),
                "home_cell": building_cells[building_id],
                "infection_score": Seed.derive(world_seed, "infection-resident:%s:%d" % [building_id, ordinal]),
            })
    return slots

func _building_cells(manifest: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for value: Variant in manifest.get("buildings", []):
        if typeof(value) != TYPE_DICTIONARY: continue
        var building: Dictionary = value
        var building_id := String(building.get("building_id", ""))
        var cell: Variant = building.get("cell", null)
        if not building_id.is_empty() and typeof(cell) == TYPE_VECTOR2I: result[building_id] = cell
    return result
