extends RefCounted
class_name GlobalPlanningRegionPlanner

func plan(
    request: GlobalWorldGenerationRequest,
    settlements: Array[Dictionary]
) -> Dictionary:
    var regions: Array[Dictionary] = []
    if request == null or not request.is_valid() or settlements.is_empty():
        return {"ok": false, "failure_reason": "invalid_global_region_planner_input", "regions": regions}

    regions.append({
        "id": "region.rural.open.001",
        "kind": &"rural_open",
        "rect": request.bounds,
        "priority": 0,
        "area_profile_hint": &"rural.open",
        "environment_profile_hint": &"temperate.rural",
        "settlement_id": "",
    })

    var crossroads_ordinal: int = 0
    var smalltown_ordinal: int = 0
    var hamlet_ordinal: int = 0
    for settlement: Dictionary in settlements:
        var kind: StringName = StringName(settlement.get("kind", &""))
        var center: Vector2i = settlement.get("center", Vector2i.ZERO)
        var radius: int = int(settlement.get("influence_radius", 0))
        if radius <= 0:
            return {"ok": false, "failure_reason": "settlement_influence_invalid", "regions": []}
        var region_id: String = ""
        var region_kind: StringName = &""
        var priority: int = 10
        var area_profile_hint: StringName = &""
        match kind:
            &"rural_crossroads":
                crossroads_ordinal += 1
                region_id = "region.rural.crossroads.%03d" % crossroads_ordinal
                region_kind = &"rural_crossroads"
                priority = 20
                area_profile_hint = &"rural.crossroads"
            &"smalltown":
                smalltown_ordinal += 1
                region_id = "region.smalltown.%03d" % smalltown_ordinal
                region_kind = &"smalltown"
                priority = 30
                area_profile_hint = &"smalltown.center"
            &"rural_hamlet":
                hamlet_ordinal += 1
                region_id = "region.rural.settlement.%03d" % hamlet_ordinal
                region_kind = &"rural_settlement"
                priority = 15
                area_profile_hint = &"rural.scattered"
            _:
                return {"ok": false, "failure_reason": "settlement_kind_unsupported", "regions": []}
        var rect := Rect2i(center - Vector2i(radius, radius), Vector2i(radius * 2, radius * 2))
        if not _rect_inside(request.bounds, rect):
            return {"ok": false, "failure_reason": "settlement_region_out_of_bounds", "regions": []}
        regions.append({
            "id": region_id,
            "kind": region_kind,
            "rect": rect,
            "priority": priority,
            "area_profile_hint": area_profile_hint,
            "environment_profile_hint": &"temperate.rural",
            "settlement_id": String(settlement.get("id", "")),
        })

    return {"ok": true, "failure_reason": "", "regions": regions}

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var inner_max := Vector2i(inner.position.x + inner.size.x - 1, inner.position.y + inner.size.y - 1)
    return outer.has_point(inner.position) and outer.has_point(inner_max)
