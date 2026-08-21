extends RefCounted
class_name GlobalSettlementPlanner

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")

func plan(request: GlobalWorldGenerationRequest, profile: Dictionary) -> Dictionary:
    var settlements: Array[Dictionary] = []
    var area_sites: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty():
        return {"ok": false, "failure_reason": "invalid_settlement_planner_input", "settlements": settlements, "area_sites": area_sites}

    var minimum_size: Vector2i = profile.get("minimum_world_size", Vector2i.ZERO)
    if request.bounds.size.x < minimum_size.x or request.bounds.size.y < minimum_size.y:
        return {"ok": false, "failure_reason": "world_bounds_too_small_for_profile", "settlements": settlements, "area_sites": area_sites}

    var center := Vector2i(
        request.bounds.position.x + request.bounds.size.x / 2,
        request.bounds.position.y + request.bounds.size.y / 2
    )
    var site_size: Vector2i = profile.get("local_site_size", Vector2i(256, 256))

    var smalltown_distance: int = Seed.choose_inclusive(
        request.seed,
        "settlement:smalltown:east_distance",
        int(profile.get("smalltown_distance_min", 520)),
        int(profile.get("smalltown_distance_max", 620))
    )
    var north_distance: int = Seed.choose_inclusive(
        request.seed,
        "settlement:hamlet:north_distance",
        int(profile.get("north_hamlet_distance_min", 500)),
        int(profile.get("north_hamlet_distance_max", 610))
    )
    var southwest_x: int = Seed.choose_inclusive(
        request.seed,
        "settlement:hamlet:southwest_x_distance",
        int(profile.get("southwest_x_distance_min", 440)),
        int(profile.get("southwest_x_distance_max", 560))
    )
    var southwest_y: int = Seed.choose_inclusive(
        request.seed,
        "settlement:hamlet:southwest_y_distance",
        int(profile.get("southwest_y_distance_min", 500)),
        int(profile.get("southwest_y_distance_max", 620))
    )
    var northeast_x: int = Seed.choose_inclusive(
        request.seed,
        "settlement:hamlet:northeast_x_distance",
        int(profile.get("northeast_x_distance_min", 450)),
        int(profile.get("northeast_x_distance_max", 570))
    )
    var northeast_y: int = Seed.choose_inclusive(
        request.seed,
        "settlement:hamlet:northeast_y_distance",
        int(profile.get("northeast_y_distance_min", 460)),
        int(profile.get("northeast_y_distance_max", 580))
    )

    var centers: Array[Vector2i] = [
        center,
        center + Vector2i(smalltown_distance, 0),
        center + Vector2i(0, -north_distance),
        center + Vector2i(-southwest_x, southwest_y),
        center + Vector2i(northeast_x, -northeast_y),
    ]
    var settlement_ids: Array[String] = [
        "settlement.rural.crossroads.001",
        "settlement.smalltown.001",
        "settlement.rural.hamlet.001",
        "settlement.rural.hamlet.002",
        "settlement.rural.hamlet.003",
    ]
    var kinds: Array[StringName] = [
        &"rural_crossroads",
        &"smalltown",
        &"rural_hamlet",
        &"rural_hamlet",
        &"rural_hamlet",
    ]
    var influence_radii: Array[int] = [
        int(profile.get("crossroads_influence_radius", 160)),
        int(profile.get("smalltown_influence_radius", 256)),
        int(profile.get("hamlet_influence_radius", 192)),
        int(profile.get("hamlet_influence_radius", 192)),
        int(profile.get("hamlet_influence_radius", 192)),
    ]
    var site_ids: Array[String] = [
        "area.rural.crossroads.001",
        "area.smalltown.center.001",
        "area.rural.scattered.001",
        "area.rural.scattered.002",
        "area.rural.scattered.003",
    ]
    var area_profile_hints: Array[StringName] = [
        &"rural.crossroads",
        &"smalltown.center",
        &"rural.scattered",
        &"rural.scattered",
        &"rural.scattered",
    ]

    for index in range(centers.size()):
        var settlement_center: Vector2i = centers[index]
        var site_rect: Rect2i = _centered_rect(settlement_center, site_size)
        if not _rect_inside(request.bounds, site_rect):
            return {"ok": false, "failure_reason": "settlement_site_out_of_bounds", "settlements": settlements, "area_sites": area_sites}
        var site_seed: int = request.seed if index == 0 else Seed.derive(request.seed, "area_site:%s" % site_ids[index])
        settlements.append({
            "id": settlement_ids[index],
            "kind": kinds[index],
            "center": settlement_center,
            "influence_radius": influence_radii[index],
            "area_site_id": site_ids[index],
        })
        area_sites.append({
            "id": site_ids[index],
            "settlement_id": settlement_ids[index],
            "bounds": site_rect,
            "seed": site_seed,
            "area_profile_hint": area_profile_hints[index],
            "environment_profile_hint": &"temperate.rural",
        })

    return {"ok": true, "failure_reason": "", "settlements": settlements, "area_sites": area_sites}

func _centered_rect(center: Vector2i, size: Vector2i) -> Rect2i:
    return Rect2i(center - Vector2i(size.x / 2, size.y / 2), size)

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var inner_max := Vector2i(inner.position.x + inner.size.x - 1, inner.position.y + inner.size.y - 1)
    return outer.has_point(inner.position) and outer.has_point(inner_max)
