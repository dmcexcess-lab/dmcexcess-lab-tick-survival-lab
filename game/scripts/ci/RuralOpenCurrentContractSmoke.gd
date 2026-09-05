extends "res://scripts/ci/RuralOpenCountrysideGenerationSmoke.gd"

# Part-one contract adapter: preserve the mature rural.open regression suite while
# replacing its one retired river-materialization assertion with the production
# contract. Hydrology and wastewater contribute no active local-area constraints,
# and potable water projects service facts rather than a pipe/node graph.
func _test_river_rejection(global_plan: GeneratedGlobalWorldPlan, projector: System20AreaRequestProjector) -> void:
    var hydrology: Dictionary = projector.hydrology_constraints_for_bounds(global_plan, global_plan.bounds)
    _check(
        bool(hydrology.get("ok", false))
            and (hydrology.get("rivers", []) as Array).is_empty()
            and (hydrology.get("bridges", []) as Array).is_empty(),
        "retired hydrology contributes zero active rural-open constraints"
    )

    var wastewater: Dictionary = projector.wastewater_constraints_for_bounds(global_plan, global_plan.bounds)
    _check(
        bool(wastewater.get("ok", false))
            and (wastewater.get("services", []) as Array).is_empty()
            and (wastewater.get("nodes", []) as Array).is_empty()
            and (wastewater.get("segments", []) as Array).is_empty(),
        "retired wastewater contributes zero active rural-open constraints"
    )

    var water: Dictionary = projector.water_constraints_for_bounds(global_plan, global_plan.bounds)
    _check(
        bool(water.get("ok", false))
            and not (water.get("services", []) as Array).is_empty()
            and not water.has("nodes")
            and not water.has("segments"),
        "potable water projection exposes service facts without a pipe graph"
    )
