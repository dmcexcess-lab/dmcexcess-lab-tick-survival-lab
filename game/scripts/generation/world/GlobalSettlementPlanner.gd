extends RefCounted
class_name GlobalSettlementPlanner

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")
const GeographyQueryClass = preload("res://scripts/generation/world/GlobalGeographyQuery.gd")
const HydrologyQueryClass = preload("res://scripts/generation/world/GlobalHydrologyQuery.gd")

var _geography: GlobalGeographyQuery
var _hydrology: GlobalHydrologyQuery

func _init() -> void:
    _geography = GeographyQueryClass.new()
    _hydrology = HydrologyQueryClass.new()

func plan(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    geography_cells: Array[Dictionary],
    river_segments: Array[Dictionary]
) -> Dictionary:
    var settlements: Array[Dictionary] = []
    var area_sites: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty() or geography_cells.is_empty() or river_segments.is_empty():
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

    var desired_centers: Array[Vector2i] = [
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

    var occupied_centers: Array[Vector2i] = []
    var river_clearance: int = int(profile.get("settlement_river_clearance", 16))
    var reuse_world_seed_for_central_site: bool = bool(profile.get("reuse_world_seed_for_central_site", true))
    for index in range(desired_centers.size()):
        var settlement_center: Vector2i = desired_centers[index]
        if index > 0:
            settlement_center = _snap_to_legal_geography(
                desired_centers[index],
                site_size,
                request.bounds,
                geography_cells,
                river_segments,
                river_clearance,
                profile,
                occupied_centers
            )
            if settlement_center.x < -900000:
                return {"ok": false, "failure_reason": "settlement_geography_or_hydrology_unresolved", "settlements": settlements, "area_sites": area_sites}
        elif not _geography.settlement_allowed(settlement_center, geography_cells):
            return {"ok": false, "failure_reason": "central_settlement_geography_invalid", "settlements": settlements, "area_sites": area_sites}

        var site_rect: Rect2i = _centered_rect(settlement_center, site_size)
        if not _rect_inside(request.bounds, site_rect):
            return {"ok": false, "failure_reason": "settlement_site_out_of_bounds", "settlements": settlements, "area_sites": area_sites}
        if not _hydrology.rect_clear_of_rivers(site_rect, river_segments, river_clearance):
            return {"ok": false, "failure_reason": "settlement_site_intersects_river_clearance", "settlements": settlements, "area_sites": area_sites}

        occupied_centers.append(settlement_center)
        var site_seed: int = request.seed if index == 0 and reuse_world_seed_for_central_site else Seed.derive(request.seed, "area_site:%s" % site_ids[index])
        settlements.append({
            "id": settlement_ids[index],
            "kind": kinds[index],
            "center": settlement_center,
            "desired_center": desired_centers[index],
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

func _snap_to_legal_geography(
    desired: Vector2i,
    site_size: Vector2i,
    world_bounds: Rect2i,
    geography_cells: Array[Dictionary],
    river_segments: Array[Dictionary],
    river_clearance: int,
    profile: Dictionary,
    occupied_centers: Array[Vector2i]
) -> Vector2i:
    var desired_grid: Vector2i = _geography.grid_for_point(desired, geography_cells)
    if desired_grid.x < -900000:
        return Vector2i(-999999, -999999)
    var search_radius: int = maxi(0, int(profile.get("settlement_geography_search_radius_cells", 4)))
    var best_center := Vector2i(-999999, -999999)
    var best_distance: int = 2147483647
    var best_grid := Vector2i(2147483647, 2147483647)

    for cell: Dictionary in geography_cells:
        var grid: Vector2i = cell.get("grid", Vector2i(-999999, -999999))
        var grid_distance: int = absi(grid.x - desired_grid.x) + absi(grid.y - desired_grid.y)
        if grid_distance > search_radius:
            continue
        var landform: StringName = StringName(cell.get("landform", &""))
        if landform != &"lowland" and landform != &"rolling":
            continue
        var candidate: Vector2i = _geography.cell_center(cell)
        var site_rect: Rect2i = _centered_rect(candidate, site_size)
        if not _rect_inside(world_bounds, site_rect):
            continue
        if not _hydrology.rect_clear_of_rivers(site_rect, river_segments, river_clearance):
            continue
        if _overlaps_existing_site(candidate, site_size, occupied_centers):
            continue
        var distance: int = absi(candidate.x - desired.x) + absi(candidate.y - desired.y)
        if distance < best_distance or (distance == best_distance and _grid_before(grid, best_grid)):
            best_distance = distance
            best_grid = grid
            best_center = candidate
    return best_center

func _overlaps_existing_site(candidate: Vector2i, site_size: Vector2i, existing: Array[Vector2i]) -> bool:
    var candidate_rect: Rect2i = _centered_rect(candidate, site_size)
    for center: Vector2i in existing:
        if _rects_overlap(candidate_rect, _centered_rect(center, site_size)):
            return true
    return false

func _rects_overlap(a: Rect2i, b: Rect2i) -> bool:
    return (
        a.position.x < b.position.x + b.size.x
        and a.position.x + a.size.x > b.position.x
        and a.position.y < b.position.y + b.size.y
        and a.position.y + a.size.y > b.position.y
    )

func _grid_before(a: Vector2i, b: Vector2i) -> bool:
    return a.y < b.y or (a.y == b.y and a.x < b.x)

func _centered_rect(center: Vector2i, size: Vector2i) -> Rect2i:
    return Rect2i(center - Vector2i(size.x / 2, size.y / 2), size)

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var inner_max := Vector2i(inner.position.x + inner.size.x - 1, inner.position.y + inner.size.y - 1)
    return outer.has_point(inner.position) and outer.has_point(inner_max)