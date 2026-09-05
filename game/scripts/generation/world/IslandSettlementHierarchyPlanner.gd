extends RefCounted
class_name IslandSettlementHierarchyPlanner

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")
const GeographyQueryClass = preload("res://scripts/generation/world/GlobalGeographyQuery.gd")
const HydrologyQueryClass = preload("res://scripts/generation/world/GlobalHydrologyQuery.gd")
const Surface = preload("res://scripts/generation/shared/IslandSurfaceMath.gd")

const INVALID_CELL := Vector2i(-999999, -999999)

var _geography: GlobalGeographyQuery = GeographyQueryClass.new()
var _hydrology: GlobalHydrologyQuery = HydrologyQueryClass.new()

func plan(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    geography_cells: Array[Dictionary],
    river_segments: Array[Dictionary]
) -> Dictionary:
    var settlements: Array[Dictionary] = []
    var area_sites: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty() or geography_cells.is_empty() or river_segments.is_empty():
        return _failure("invalid_island_settlement_planner_input")

    var specs: Array[Dictionary] = _settlement_specs(profile)

    var accepted_rects: Array[Rect2i] = []
    var accepted_centers: Array[Vector2i] = []
    var world_center: Vector2i = request.bounds.position + Vector2i(request.bounds.size.x / 2, request.bounds.size.y / 2)
    var direction_rotation: int = Seed.choose_index(request.seed, "island:settlement:direction_rotation", 8)

    for index: int in range(specs.size()):
        var spec: Dictionary = specs[index]
        var direction_index: int = (direction_rotation + int(spec.get("direction_offset", 0))) % 8
        var target_radius: float = float(spec.get("target_radius", 512))
        var desired: Vector2i = world_center + _direction(direction_index, target_radius)
        var site_size: Vector2i = spec.get("site_size", profile.get("local_site_size", Vector2i(256, 256)))
        var candidates: Array[Dictionary] = _legal_candidates(request, profile, geography_cells, river_segments, site_size)
        if candidates.is_empty():
            return _failure("insufficient_legal_island_settlement_candidates:%s" % String(spec.get("settlement_id", "unknown")))
        var selected: Dictionary = _select_candidate(
            request.seed,
            index,
            desired,
            int(spec.get("minimum_spacing", 256)),
            candidates,
            accepted_rects,
            accepted_centers
        )
        if selected.is_empty():
            return _failure("island_settlement_spacing_unresolved:%s" % String(spec.get("settlement_id", "unknown")))

        var settlement_center: Vector2i = selected.get("center", INVALID_CELL)
        var site_rect: Rect2i = selected.get("rect", Rect2i())
        if settlement_center == INVALID_CELL or site_rect.size.x <= 0 or site_rect.size.y <= 0:
            return _failure("island_settlement_candidate_invalid")
        accepted_centers.append(settlement_center)
        accepted_rects.append(site_rect)

        var settlement_id: String = String(spec.get("settlement_id", ""))
        var site_id: String = String(spec.get("site_id", ""))
        var site_seed: int = Seed.derive(request.seed, "area_site:%s" % site_id)
        settlements.append({
            "id": settlement_id,
            "kind": StringName(spec.get("kind", &"rural_hamlet")),
            "center": settlement_center,
            "desired_center": desired,
            "influence_radius": int(spec.get("influence_radius", 192)),
            "area_site_id": site_id,
        })
        area_sites.append({
            "id": site_id,
            "settlement_id": settlement_id,
            "bounds": site_rect,
            "seed": site_seed,
            "area_profile_hint": StringName(spec.get("area_profile_hint", &"rural.scattered")),
            "environment_profile_hint": &"temperate.rural",
        })

    return {"ok": true, "failure_reason": "", "settlements": settlements, "area_sites": area_sites}

# The incoming island request supplies a stable world anchor, never a hard coast.
# Settlement intent owns the required land envelope; the coast is generated only
# after this extent is known.  Keeping the result grid-aligned also preserves the
# regional geography and streaming contracts.
func planning_bounds(request: GlobalWorldGenerationRequest, profile: Dictionary) -> Rect2i:
    if request == null or not request.is_valid():
        return Rect2i()
    var half_span: int = int(profile.get("island_edge_padding", 320))
    for spec: Dictionary in _settlement_specs(profile):
        var site_size: Vector2i = spec.get("site_size", profile.get("local_site_size", Vector2i(256, 256)))
        var reach: int = int(spec.get("target_radius", 0)) + maxi(site_size.x, site_size.y) / 2
        half_span = maxi(half_span, reach + int(profile.get("island_edge_padding", 320)))
    var cell_size: int = maxi(1, int(profile.get("geography_cell_size", 128)))
    var span: int = _round_up(half_span * 2, cell_size)
    var center: Vector2i = request.bounds.get_center()
    return Rect2i(center - Vector2i(span / 2, span / 2), Vector2i(span, span))

func _settlement_specs(profile: Dictionary) -> Array[Dictionary]:
    var smalltown_radius: int = int(profile.get("smalltown_influence_radius", 256))
    var crossroads_radius: int = int(profile.get("crossroads_influence_radius", 160))
    var hamlet_radius: int = int(profile.get("hamlet_influence_radius", 192))
    var town_spacing: int = int(profile.get("island_smalltown_min_spacing", 640))
    var crossroads_spacing: int = int(profile.get("island_crossroads_min_spacing", 288))
    var hamlet_spacing: int = int(profile.get("island_hamlet_min_spacing", 256))
    return [
        _spec("settlement.smalltown.001", "area.smalltown.center.001", &"smalltown", &"smalltown.center", smalltown_radius, 640, 0, town_spacing, Vector2i(512, 512)),
        _spec("settlement.smalltown.002", "area.smalltown.center.002", &"smalltown", &"smalltown.center", smalltown_radius, 640, 4, town_spacing, Vector2i(512, 512)),
        _spec("settlement.rural.crossroads.001", "area.rural.crossroads.001", &"rural_crossroads", &"rural.crossroads", crossroads_radius, 820, 2, crossroads_spacing, Vector2i(256, 256)),
        _spec("settlement.rural.crossroads.002", "area.rural.crossroads.002", &"rural_crossroads", &"rural.crossroads", crossroads_radius, 820, 5, crossroads_spacing, Vector2i(256, 256)),
        _spec("settlement.rural.crossroads.003", "area.rural.crossroads.003", &"rural_crossroads", &"rural.crossroads", crossroads_radius, 820, 7, crossroads_spacing, Vector2i(256, 256)),
        _spec("settlement.rural.hamlet.001", "area.rural.scattered.001", &"rural_hamlet", &"rural.scattered", hamlet_radius, 1080, 1, hamlet_spacing, Vector2i(256, 256)),
        _spec("settlement.rural.hamlet.002", "area.rural.scattered.002", &"rural_hamlet", &"rural.scattered", hamlet_radius, 1080, 3, hamlet_spacing, Vector2i(256, 256)),
        _spec("settlement.rural.hamlet.003", "area.rural.scattered.003", &"rural_hamlet", &"rural.scattered", hamlet_radius, 1080, 4, hamlet_spacing, Vector2i(256, 256)),
        _spec("settlement.rural.hamlet.004", "area.rural.scattered.004", &"rural_hamlet", &"rural.scattered", hamlet_radius, 1080, 6, hamlet_spacing, Vector2i(256, 256)),
        _spec("settlement.rural.hamlet.005", "area.rural.scattered.005", &"rural_hamlet", &"rural.scattered", hamlet_radius, 1080, 0, hamlet_spacing, Vector2i(256, 256)),
        _spec("settlement.rural.hamlet.006", "area.rural.scattered.006", &"rural_hamlet", &"rural.scattered", hamlet_radius, 1080, 5, hamlet_spacing, Vector2i(256, 256)),
    ]

func _spec(
    settlement_id: String,
    site_id: String,
    kind: StringName,
    area_profile_hint: StringName,
    influence_radius: int,
    target_radius: int,
    direction_offset: int,
    minimum_spacing: int,
    site_size: Vector2i
) -> Dictionary:
    return {
        "settlement_id": settlement_id,
        "site_id": site_id,
        "kind": kind,
        "area_profile_hint": area_profile_hint,
        "influence_radius": influence_radius,
        "target_radius": target_radius,
        "direction_offset": direction_offset,
        "minimum_spacing": minimum_spacing,
        "site_size": site_size,
    }

func _legal_candidates(
    request: GlobalWorldGenerationRequest,
    profile: Dictionary,
    geography_cells: Array[Dictionary],
    river_segments: Array[Dictionary],
    site_size: Vector2i
) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var river_clearance: int = int(profile.get("settlement_river_clearance", 16))
    var ocean_margin: int = int(profile.get("island_ocean_margin", 24))
    var shore_width: int = int(profile.get("island_shore_width", 8))
    var coast_wobble: int = int(profile.get("island_coast_wobble", 8))
    var coast_scale: int = int(profile.get("island_coast_scale", 96))
    for geography_cell: Dictionary in geography_cells:
        var landform: StringName = StringName(geography_cell.get("landform", &""))
        if landform != &"lowland" and landform != &"rolling":
            continue
        var center: Vector2i = _geography.cell_center(geography_cell)
        if center == INVALID_CELL:
            continue
        var rect := Rect2i(center - Vector2i(site_size.x / 2, site_size.y / 2), site_size)
        if not _rect_inside(request.bounds, rect):
            continue
        if not Surface.rect_is_land(request.bounds, request.seed, rect, ocean_margin, shore_width, coast_wobble, coast_scale):
            continue
        if not _hydrology.rect_clear_of_rivers(rect, river_segments, river_clearance):
            continue
        result.append({"center": center, "rect": rect, "grid": geography_cell.get("grid", Vector2i.ZERO)})
    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var ag: Vector2i = a.get("grid", Vector2i.ZERO)
        var bg: Vector2i = b.get("grid", Vector2i.ZERO)
        return ag.y < bg.y or (ag.y == bg.y and ag.x < bg.x)
    )
    return result

func _select_candidate(
    seed: int,
    ordinal: int,
    desired: Vector2i,
    minimum_spacing: int,
    candidates: Array[Dictionary],
    accepted_rects: Array[Rect2i],
    accepted_centers: Array[Vector2i]
) -> Dictionary:
    var spacing_levels: Array[int] = [minimum_spacing, maxi(224, minimum_spacing - 64), 192]
    for spacing: int in spacing_levels:
        var best: Dictionary = {}
        var best_score: int = 2147483647
        for candidate: Dictionary in candidates:
            var center: Vector2i = candidate.get("center", INVALID_CELL)
            var rect: Rect2i = candidate.get("rect", Rect2i())
            if center == INVALID_CELL or _overlaps_any(rect, accepted_rects) or _too_close(center, accepted_centers, spacing):
                continue
            var distance: int = absi(center.x - desired.x) + absi(center.y - desired.y)
            var grid: Vector2i = candidate.get("grid", Vector2i.ZERO)
            var jitter: int = Seed.hash_2d(seed, grid.x, grid.y, 9100 + ordinal) % 48
            var score: int = distance + jitter
            if score < best_score or (score == best_score and _candidate_before(candidate, best)):
                best = candidate
                best_score = score
        if not best.is_empty():
            return best
    return {}

func _direction(index: int, radius: float) -> Vector2i:
    var directions: Array[Vector2] = [
        Vector2(1.0, 0.0),
        Vector2(0.7071, 0.7071),
        Vector2(0.0, 1.0),
        Vector2(-0.7071, 0.7071),
        Vector2(-1.0, 0.0),
        Vector2(-0.7071, -0.7071),
        Vector2(0.0, -1.0),
        Vector2(0.7071, -0.7071),
    ]
    var direction: Vector2 = directions[posmod(index, directions.size())]
    return Vector2i(roundi(direction.x * radius), roundi(direction.y * radius))

func _round_up(value: int, multiple: int) -> int:
    return int(ceili(float(value) / float(multiple))) * multiple

func _too_close(candidate: Vector2i, accepted: Array[Vector2i], minimum_spacing: int) -> bool:
    var squared: int = minimum_spacing * minimum_spacing
    for center: Vector2i in accepted:
        var dx: int = candidate.x - center.x
        var dy: int = candidate.y - center.y
        if dx * dx + dy * dy < squared:
            return true
    return false

func _overlaps_any(rect: Rect2i, accepted: Array[Rect2i]) -> bool:
    for other: Rect2i in accepted:
        if rect.intersects(other):
            return true
    return false

func _candidate_before(a: Dictionary, b: Dictionary) -> bool:
    if b.is_empty():
        return true
    var ag: Vector2i = a.get("grid", Vector2i.ZERO)
    var bg: Vector2i = b.get("grid", Vector2i.ZERO)
    return ag.y < bg.y or (ag.y == bg.y and ag.x < bg.x)

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var inner_max: Vector2i = inner.position + inner.size - Vector2i.ONE
    return outer.has_point(inner.position) and outer.has_point(inner_max)

func _failure(reason: String) -> Dictionary:
    return {"ok": false, "failure_reason": reason, "settlements": [], "area_sites": []}
