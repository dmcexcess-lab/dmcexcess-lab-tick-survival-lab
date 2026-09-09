extends RefCounted
class_name PopulationResidentProjection

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")

## On-demand individual identity projection from the authoritative aggregate population plan.
## This does not add residents. It deterministically names household slots that were already counted.
## Infected and survivor records are exact complementary views of those same slots.

func infected_records(population_plan: Dictionary, preferred_area_site_id: String = "") -> Array[Dictionary]:
    return _classified_records(population_plan, preferred_area_site_id, true)

func survivor_records(population_plan: Dictionary, preferred_area_site_id: String = "") -> Array[Dictionary]:
    return _classified_records(population_plan, preferred_area_site_id, false)

func infected_near(population_plan: Dictionary, preferred_area_site_id: String, reference_cell: Vector2i) -> Array[Dictionary]:
    return _records_near(infected_records(population_plan, preferred_area_site_id), infected_records(population_plan), preferred_area_site_id, reference_cell)

func survivors_near(population_plan: Dictionary, preferred_area_site_id: String, reference_cell: Vector2i) -> Array[Dictionary]:
    return _records_near(survivor_records(population_plan, preferred_area_site_id), survivor_records(population_plan), preferred_area_site_id, reference_cell)

func first_infected_near(population_plan: Dictionary, preferred_area_site_id: String, reference_cell: Vector2i) -> Dictionary:
    var records := infected_near(population_plan, preferred_area_site_id, reference_cell)
    return {} if records.is_empty() else records[0].duplicate(true)

func first_survivor_near(population_plan: Dictionary, preferred_area_site_id: String, reference_cell: Vector2i) -> Dictionary:
    var records := survivors_near(population_plan, preferred_area_site_id, reference_cell)
    return {} if records.is_empty() else records[0].duplicate(true)

func _classified_records(population_plan: Dictionary, preferred_area_site_id: String, want_infected: bool) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not bool(population_plan.get("ok", false)):
        return result
    var manifest: Dictionary = population_plan.get("local_area_manifest", {})
    var world_seed := int(manifest.get("world_seed", -1))
    if world_seed <= 0:
        return result
    var building_cells := _building_cells(manifest)
    for settlement_value: Variant in population_plan.get("settlements", []):
        if typeof(settlement_value) != TYPE_DICTIONARY:
            continue
        var settlement: Dictionary = settlement_value
        var site_id := String(settlement.get("area_site_id", ""))
        if not preferred_area_site_id.is_empty() and site_id != preferred_area_site_id:
            continue
        var slots := _resident_slots(world_seed, settlement, building_cells)
        var infected_count := clampi(int(settlement.get("infected_population", 0)), 0, slots.size())
        slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
            var sa := int(a.get("infection_score", 0))
            var sb := int(b.get("infection_score", 0))
            if sa == sb:
                return String(a.get("resident_id", "")) < String(b.get("resident_id", ""))
            return sa < sb
        )
        var first_index: int = 0 if want_infected else infected_count
        var last_index: int = infected_count if want_infected else slots.size()
        for index in range(first_index, last_index):
            var record: Dictionary = slots[index].duplicate(true)
            record.erase("infection_score")
            record["infected"] = want_infected
            result.append(record)
    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("resident_id", "")) < String(b.get("resident_id", ""))
    )
    return result

func _records_near(preferred: Array[Dictionary], all_records: Array[Dictionary], preferred_area_site_id: String, reference_cell: Vector2i) -> Array[Dictionary]:
    _sort_by_distance(preferred, reference_cell)
    _sort_by_distance(all_records, reference_cell)
    if preferred_area_site_id.is_empty():
        return all_records
    var result: Array[Dictionary] = []
    var seen: Dictionary = {}
    for record: Dictionary in preferred:
        var actor_id := String(record.get("resident_id", ""))
        if actor_id.is_empty() or seen.has(actor_id):
            continue
        result.append(record.duplicate(true))
        seen[actor_id] = true
    for record: Dictionary in all_records:
        var actor_id := String(record.get("resident_id", ""))
        if actor_id.is_empty() or seen.has(actor_id):
            continue
        result.append(record.duplicate(true))
        seen[actor_id] = true
    return result

func _sort_by_distance(records: Array[Dictionary], reference_cell: Vector2i) -> void:
    records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var ac: Vector2i = a.get("home_cell", Vector2i.ZERO)
        var bc: Vector2i = b.get("home_cell", Vector2i.ZERO)
        var ad := absi(ac.x-reference_cell.x)+absi(ac.y-reference_cell.y)
        var bd := absi(bc.x-reference_cell.x)+absi(bc.y-reference_cell.y)
        if ad == bd:
            return String(a.get("resident_id", "")) < String(b.get("resident_id", ""))
        return ad < bd
    )

func _resident_slots(world_seed: int, settlement: Dictionary, building_cells: Dictionary) -> Array[Dictionary]:
    var slots: Array[Dictionary] = []
    var households: Array = Array(settlement.get("households", [])).duplicate(true)
    households.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("building_id", "")) < String(b.get("building_id", ""))
    )
    for household_value: Variant in households:
        if typeof(household_value) != TYPE_DICTIONARY:
            continue
        var household: Dictionary = household_value
        var building_id := String(household.get("building_id", ""))
        var capacity := int(household.get("capacity", 0))
        if building_id.is_empty() or capacity < 1 or not building_cells.has(building_id):
            continue
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
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var building: Dictionary = value
        var building_id := String(building.get("building_id", ""))
        var cell: Variant = building.get("cell", null)
        if not building_id.is_empty() and typeof(cell) == TYPE_VECTOR2I:
            result[building_id] = cell
    return result
