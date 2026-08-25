extends RefCounted
class_name IslandDistrictSitePlanner

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")
const HydrologyQueryClass = preload("res://scripts/generation/world/GlobalHydrologyQuery.gd")
const Surface = preload("res://scripts/generation/shared/IslandSurfaceMath.gd")

const SITE_SIZE := Vector2i(384, 384)
const SAMPLE_STEP: int = 32
const INVALID_CELL := Vector2i(-999999, -999999)

var _hydrology: GlobalHydrologyQuery = HydrologyQueryClass.new()

func append_required_districts(
    base_sites: Array[Dictionary],
    roads: Array[Dictionary],
    rivers: Array[Dictionary],
    request: GlobalWorldGenerationRequest,
    profile: Dictionary
) -> Dictionary:
    if request == null or not request.is_valid() or roads.is_empty() or base_sites.is_empty():
        return _failure("invalid_island_district_site_input")

    var sites: Array[Dictionary] = base_sites.duplicate(true)
    var first: Dictionary = _find_site(
        "area.island.suburban.001",
        &"suburban.neighborhood",
        &"temperate.suburban",
        &"suburban_district",
        sites,
        roads,
        rivers,
        request,
        profile
    )
    if first.is_empty():
        return _failure("island_suburban_site_unresolved")
    sites.append(first)

    var second: Dictionary = _find_site(
        "area.island.urban.001",
        &"urban.mixed",
        &"temperate.urban",
        &"urban_district",
        sites,
        roads,
        rivers,
        request,
        profile
    )
    if second.is_empty():
        return _failure("island_urban_site_unresolved")
    sites.append(second)

    return {"ok": true, "failure_reason": "", "area_sites": sites}

func _find_site(
    site_id: String,
    area_profile: StringName,
    environment_profile: StringName,
    role: StringName,
    occupied_sites: Array[Dictionary],
    roads: Array[Dictionary],
    rivers: Array[Dictionary],
    request: GlobalWorldGenerationRequest,
    profile: Dictionary
) -> Dictionary:
    var candidates: Array[Dictionary] = []
    var ordered_roads: Array[Dictionary] = roads.duplicate(true)
    ordered_roads.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var a_primary: bool = StringName(a.get("road_class", &"")) == &"primary"
        var b_primary: bool = StringName(b.get("road_class", &"")) == &"primary"
        if a_primary != b_primary:
            return a_primary
        return String(a.get("road_id", "")) < String(b.get("road_id", ""))
    )

    for road: Dictionary in ordered_roads:
        var start: Vector2i = road.get("start", INVALID_CELL)
        var finish: Vector2i = road.get("end", INVALID_CELL)
        if start == INVALID_CELL or finish == INVALID_CELL or start == finish:
            continue
        if start.x != finish.x and start.y != finish.y:
            continue
        var horizontal: bool = start.y == finish.y
        var low: int = mini(start.x, finish.x) if horizontal else mini(start.y, finish.y)
        var high: int = maxi(start.x, finish.x) if horizontal else maxi(start.y, finish.y)
        var half_axis: int = SITE_SIZE.x / 2 if horizontal else SITE_SIZE.y / 2
        if high - low + 1 < half_axis * 2:
            continue

        var sample: int = _align_up(low + half_axis, SAMPLE_STEP)
        var last: int = high - half_axis + 1
        while sample <= last:
            var center := Vector2i(sample, start.y) if horizontal else Vector2i(start.x, sample)
            var rect := Rect2i(center - SITE_SIZE / 2, SITE_SIZE)
            if _candidate_legal(rect, road, occupied_sites, roads, rivers, request, profile):
                candidates.append({
                    "center": center,
                    "bounds": rect,
                    "road_id": String(road.get("road_id", "")),
                    "road_class": StringName(road.get("road_class", &"")),
                    "score": _candidate_score(center, road, request),
                })
            sample += SAMPLE_STEP

    if candidates.is_empty():
        return {}
    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var ascore: int = int(a.get("score", 2147483647))
        var bscore: int = int(b.get("score", 2147483647))
        if ascore != bscore:
            return ascore < bscore
        var ar: String = String(a.get("road_id", ""))
        var br: String = String(b.get("road_id", ""))
        if ar != br:
            return ar < br
        var ac: Vector2i = a.get("center", Vector2i.ZERO)
        var bc: Vector2i = b.get("center", Vector2i.ZERO)
        return ac.y < bc.y or (ac.y == bc.y and ac.x < bc.x)
    )

    var chosen: Dictionary = candidates[0]
    return {
        "id": site_id,
        "settlement_id": "",
        "bounds": chosen.get("bounds", Rect2i()),
        "seed": Seed.derive(request.seed, "area_site:%s" % site_id),
        "area_profile_hint": area_profile,
        "environment_profile_hint": environment_profile,
        "site_role": role,
        "source_road_id": String(chosen.get("road_id", "")),
    }

func _candidate_legal(
    rect: Rect2i,
    selected_road: Dictionary,
    occupied_sites: Array[Dictionary],
    roads: Array[Dictionary],
    rivers: Array[Dictionary],
    request: GlobalWorldGenerationRequest,
    profile: Dictionary
) -> bool:
    if not _rect_inside(request.bounds, rect):
        return false
    if not Surface.rect_is_land(
        request.bounds,
        request.seed,
        rect,
        int(profile.get("island_ocean_margin", 24)),
        int(profile.get("island_shore_width", 8)),
        int(profile.get("island_coast_wobble", 8)),
        int(profile.get("island_coast_scale", 96))
    ):
        return false
    if not _hydrology.rect_clear_of_rivers(rect, rivers, int(profile.get("settlement_river_clearance", 16))):
        return false
    for site: Dictionary in occupied_sites:
        if _rects_overlap(rect, site.get("bounds", Rect2i())):
            return false
    if not _selected_road_spans_site(selected_road, rect):
        return false
    var selected_id: String = String(selected_road.get("road_id", ""))
    for road: Dictionary in roads:
        if String(road.get("road_id", "")) == selected_id:
            continue
        if _road_intersects_rect(road, rect):
            return false
    return true

func _selected_road_spans_site(road: Dictionary, rect: Rect2i) -> bool:
    var start: Vector2i = road.get("start", INVALID_CELL)
    var finish: Vector2i = road.get("end", INVALID_CELL)
    if start == INVALID_CELL or finish == INVALID_CELL:
        return false
    var end_cell: Vector2i = rect.position + rect.size - Vector2i.ONE
    if start.y == finish.y:
        return start.y >= rect.position.y and start.y <= end_cell.y \
            and mini(start.x, finish.x) <= rect.position.x \
            and maxi(start.x, finish.x) >= end_cell.x
    if start.x == finish.x:
        return start.x >= rect.position.x and start.x <= end_cell.x \
            and mini(start.y, finish.y) <= rect.position.y \
            and maxi(start.y, finish.y) >= end_cell.y
    return false

func _road_intersects_rect(road: Dictionary, rect: Rect2i) -> bool:
    var start: Vector2i = road.get("start", INVALID_CELL)
    var finish: Vector2i = road.get("end", INVALID_CELL)
    var width: int = maxi(1, int(road.get("width", 1)))
    if start == INVALID_CELL or finish == INVALID_CELL:
        return false
    var radius: int = width / 2
    var road_rect := Rect2i()
    if start.y == finish.y:
        road_rect = Rect2i(
            Vector2i(mini(start.x, finish.x), start.y - radius),
            Vector2i(absi(finish.x - start.x) + 1, radius * 2 + 1)
        )
    elif start.x == finish.x:
        road_rect = Rect2i(
            Vector2i(start.x - radius, mini(start.y, finish.y)),
            Vector2i(radius * 2 + 1, absi(finish.y - start.y) + 1)
        )
    else:
        return false
    return _rects_overlap(road_rect, rect)

func _candidate_score(center: Vector2i, road: Dictionary, request: GlobalWorldGenerationRequest) -> int:
    var world_center := request.bounds.position + request.bounds.size / 2
    var distance_from_center: int = absi(center.x - world_center.x) + absi(center.y - world_center.y)
    var primary_bonus: int = -200 if StringName(road.get("road_class", &"")) == &"primary" else 0
    return distance_from_center + primary_bonus

func _align_up(value: int, step: int) -> int:
    if step <= 1:
        return value
    var remainder: int = posmod(value, step)
    return value if remainder == 0 else value + step - remainder

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    return outer.has_point(inner.position) and outer.has_point(inner.position + inner.size - Vector2i.ONE)

func _rects_overlap(a: Rect2i, b: Rect2i) -> bool:
    if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0:
        return false
    return a.position.x < b.position.x + b.size.x \
        and a.position.x + a.size.x > b.position.x \
        and a.position.y < b.position.y + b.size.y \
        and a.position.y + a.size.y > b.position.y

func _failure(reason: String) -> Dictionary:
    return {"ok": false, "failure_reason": reason, "area_sites": []}
