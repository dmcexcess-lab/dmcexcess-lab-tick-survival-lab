extends "res://scripts/ci/RuralOpenCountrysideGenerationSmoke.gd"

# Part-two contract adapter: preserve the mature rural.open regression suite while
# proving the retired hydrology/wastewater projection APIs stay physically absent.
# Potable water remains a lightweight municipal service projection with no pipe graph.
func _test_river_rejection(global_plan: GeneratedGlobalWorldPlan, projector: System20AreaRequestProjector) -> void:
    _check(
        not projector.has_method("hydrology_constraints_for_bounds")
            and not projector.has_method("wastewater_constraints_for_bounds"),
        "retired hydrology and wastewater projection APIs remain physically absent"
    )

    var water: Dictionary = projector.water_constraints_for_bounds(global_plan, global_plan.bounds)
    _check(
        bool(water.get("ok", false))
            and not (water.get("services", []) as Array).is_empty()
            and not water.has("nodes")
            and not water.has("segments"),
        "potable water projection exposes service facts without a pipe graph"
    )
