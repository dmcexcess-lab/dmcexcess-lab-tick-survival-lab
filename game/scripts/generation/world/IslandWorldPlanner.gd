extends RefCounted
class_name IslandWorldPlanner

const RequestClass = preload("res://scripts/generation/world/GlobalWorldGenerationRequest.gd")
const BasePlannerClass = preload("res://scripts/generation/world/GlobalWorldPlanner.gd")
const PlanClass = preload("res://scripts/generation/world/GeneratedGlobalWorldPlan.gd")
const ProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const BridgePlannerClass = preload("res://scripts/generation/world/GlobalBridgeIntentPlanner.gd")
const HydrologyQueryClass = preload("res://scripts/generation/world/GlobalHydrologyQuery.gd")
const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")
const Surface = preload("res://scripts/generation/shared/IslandSurfaceMath.gd")

const INVALID_CELL := Vector2i(-999999, -999999)
const DISTRICT_SITE_SIZE := Vector2i(256, 256)

var _base_planner: GlobalWorldPlanner = BasePlannerClass.new()
var _bridges: GlobalBridgeIntentPlanner = BridgePlannerClass.new()
var _hydrology: GlobalHydrologyQuery = HydrologyQueryClass.new()
var _profiles: GlobalWorldProfileCatalog = ProfilesClass.new()

func generate(request: GlobalWorldGenerationRequest) -> GeneratedGlobalWorldPlan:
    var failed := PlanClass.new()
    if request == null or not request.is_valid() or request.profile_id != ProfilesClass.TEMPERATE_ISLAND_REGION:
        failed.failure_reason = "invalid_island_world_request"
        return failed
    var island_profile: Dictionary = _profiles.profile(ProfilesClass.TEMPERATE_ISLAND_REGION)
    if island_profile.is_empty():
        failed.failure_reason = "island_profile_missing"
        return failed

    ## Preserve the mature rural planning skeleton as the upstream baseline. The island
    ## composition changes coast-facing topology and adds small-town districts without
    ## rewriting the accepted settlement/road/utility planners.
    var base_request := RequestClass.new(
        request.world_id,
        request.seed,
        request.bounds,
        ProfilesClass.TEMPERATE_RURAL_REGION
    )
    var base: GeneratedGlobalWorldPlan = _base_planner.generate(base_request)
    if base == null or not base.is_generated():
        failed.failure_reason = "island_base_world_generation_failed:%s" % ("null" if base == null else base.failure_reason)
        return failed

    var plan := PlanClass.new()
    plan.world_id = request.world_id
    plan.seed = request.seed
    plan.bounds = request.bounds
    plan.profile_id = ProfilesClass.TEMPERATE_ISLAND_REGION
    plan.profile_version = int(island_profile.get("version", 1))
    plan.geography_cells = _decorate_geography(base.geography_cells, request, island_profile)
    plan.river_segments = base.river_segments.duplicate(true)
    plan.settlements = base.settlements.duplicate(true)

    var sites_result: Dictionary = _build_area_sites(base.area_sites, plan.settlements, plan.river_segments, request, island_profile)
    if not bool(sites_result.get("ok", false)):
        plan.failure_reason = String(sites_result.get("failure_reason", "island_area_site_planning_failed"))
        return plan
    plan.area_sites = sites_result.get("area_sites", [])

    var roads: Array[Dictionary] = _clip_base_roads(base.road_segments, request, island_profile)
    if roads.is_empty():
        plan.failure_reason = "island_road_clipping_failed"
        return plan
    var district_result: Dictionary = _append_district_roads(roads, plan.area_sites, plan.settlements, request, island_profile)
    if not bool(district_result.get("ok", false)):
        plan.failure_reason = String(district_result.get("failure_reason", "island_district_road_planning_failed"))
        return plan
    plan.road_segments = district_result.get("roads", [])

    var bridge_result: Dictionary = _bridges.plan(plan.road_segments, plan.river_segments)
    if not bool(bridge_result.get("ok", false)):
        plan.failure_reason = String(bridge_result.get("failure_reason", "island_bridge_planning_failed"))
        return plan
    plan.bridge_intents = bridge_result.get("bridge_intents", [])

    var power_result: Dictionary = _adapt_power(base, plan.road_segments)
    if not bool(power_result.get("ok", false)):
        plan.failure_reason = String(power_result.get("failure_reason", "island_power_adaptation_failed"))
        return plan
    plan.power_nodes = power_result.get("nodes", [])
    plan.power_segments = power_result.get("segments", [])
    plan.water_services = base.water_services.duplicate(true)
    plan.water_nodes = base.water_nodes.duplicate(true)
    plan.water_segments = base.water_segments.duplicate(true)
    plan.wastewater_services = base.wastewater_services.duplicate(true)
    plan.wastewater_nodes = base.wastewater_nodes.duplicate(true)
    plan.wastewater_segments = base.wastewater_segments.duplicate(true)
    plan.regions = _build_regions(base.regions, plan.area_sites)

    var validation: Dictionary = _validate(request, plan, island_profile)
    if not bool(validation.get("ok", false)):
        plan.failure_reason = "island_world_validation_failed:%s" % ",".join(PackedStringArray(validation.get("failures", [])))
    return plan

func profile_ids() -> Array[StringName]:
    return [ProfilesClass.TEMPERATE_ISLAND_REGION]

func _decorate_geography(
    source: Array[Dictionary],
    request: GlobalWorldGenerationRequest,
    profile: Dictionary
) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for value: Dictionary in source:
        var cell: Dictionary = value.duplicate(true)
        var rect: Rect2i = cell.get("rect", Rect2i())
        var center: Vector2i = rect.position + Vector2i(rect.size.x / 2, rect.size.y / 2)
        cell["surface_kind"] = _surface_kind(request, profile, center)
        result.append(cell)
    return result

func _build_area_sites(
    base_sites: Array[Dictionary],
    settlements: Array[Dictionary],
    rivers: Array[Dictionary],
    request: GlobalWorldGenerationRequest,
    profile: Dictionary
) -> Dictionary:
    var sites: Array[Dictionary] = []
    for value: Dictionary in base_sites:
        var copied: Dictionary = value.duplicate(true)
        copied["site_role"] = &"primary"
        var rect: Rect2i = copied.get("bounds", Rect2i())
        if not _site_legal(rect, sites, rivers, request, profile):
            return {"ok": false, "failure_reason": "island_primary_site_not_on_land:%s" % String(copied.get("id", "")), "area_sites": []}
        sites.append(copied)

    var smalltown: Dictionary = _settlement_by_id(settlements, "settlement.smalltown.001")
    if smalltown.is_empty():
        return {"ok": false, "failure_reason": "island_smalltown_missing", "area_sites": []}
    var center: Vector2i = smalltown.get("center", INVALID_CELL)
    if center == INVALID_CELL:
        return {"ok": false, "failure_reason": "island_smalltown_center_invalid", "area_sites": []}

    var district_specs: Array[Dictionary] = [
        {"suffix":"urban", "profile":&"urban.mixed", "environment":&"temperate.urban"},
        {"suffix":"suburban", "profile":&"suburban.neighborhood", "environment":&"temperate.suburban"},
        {"suffix":"commercial", "profile":&"commercial.corridor", "environment":&"temperate.suburban"},
        {"suffix":"industrial", "profile":&"industrial.district", "environment":&"temperate.industrial"},
        {"suffix":"civic", "profile":&"civic.campus", "environment":&"temperate.suburban"},
    ]
    var candidate_offsets: Array[Vector2i] = [
        Vector2i(-256, 0), Vector2i(0, -256), Vector2i(0, 256),
        Vector2i(-256, -256), Vector2i(-256, 256),
        Vector2i(256, 0), Vector2i(256, -256), Vector2i(256, 256),
        Vector2i(-512, 0), Vector2i(0, -512), Vector2i(0, 512),
    ]
    var used_offsets: Dictionary = {}
    for spec_index in range(district_specs.size()):
        var spec: Dictionary = district_specs[spec_index]
        var selected_rect := Rect2i()
        var selected_offset := Vector2i.ZERO
        for offset: Vector2i in candidate_offsets:
            if used_offsets.has(offset):
                continue
            var district_center: Vector2i = center + offset
            var rect := Rect2i(district_center - DISTRICT_SITE_SIZE / 2, DISTRICT_SITE_SIZE)
            if not _site_legal(rect, sites, rivers, request, profile):
                continue
            selected_rect = rect
            selected_offset = offset
            break
        if selected_rect.size.x <= 0:
            return {"ok": false, "failure_reason": "island_district_site_unresolved:%s" % String(spec.get("suffix", "unknown")), "area_sites": []}
        used_offsets[selected_offset] = true
        var site_id: String = "area.smalltown.%s.001" % String(spec.get("suffix", "district"))
        sites.append({
            "id": site_id,
            "settlement_id": "settlement.smalltown.001",
            "bounds": selected_rect,
            "seed": Seed.derive(request.seed, "area_site:%s" % site_id),
            "area_profile_hint": StringName(spec.get("profile", &"")),
            "environment_profile_hint": StringName(spec.get("environment", &"")),
            "site_role": &"district",
        })
    return {"ok": true, "failure_reason": "", "area_sites": sites}

func _site_legal(
    rect: Rect2i,
    existing: Array[Dictionary],
    rivers: Array[Dictionary],
    request: GlobalWorldGenerationRequest,
    profile: Dictionary
) -> bool:
    if not _rect_inside(request.bounds, rect):
        return false
    if not Surface.rect_is_land(
        request.bounds, request.seed, rect,
        int(profile.get("island_ocean_margin", 48)),
        int(profile.get("island_shore_width", 12)),
        int(profile.get("island_coast_wobble", 18)),
        int(profile.get("island_coast_scale", 96))
    ):
        return false
    if not _hydrology.rect_clear_of_rivers(rect, rivers, int(profile.get("settlement_river_clearance", 16))):
        return false
    for site: Dictionary in existing:
        if _rects_overlap(rect, site.get("bounds", Rect2i())):
            return false
    return true

func _clip_base_roads(
    source: Array[Dictionary],
    request: GlobalWorldGenerationRequest,
    profile: Dictionary
) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for road: Dictionary in source:
        var clipped: Dictionary = _clip_road_to_island(road, request, profile)
        if not clipped.is_empty():
            result.append(clipped)
    return result

func _clip_road_to_island(
    road: Dictionary,
    request: GlobalWorldGenerationRequest,
    profile: Dictionary
) -> Dictionary:
    var start: Vector2i = road.get("start", INVALID_CELL)
    var finish: Vector2i = road.get("end", INVALID_CELL)
    var width: int = int(road.get("width", 0))
    if start == INVALID_CELL or finish == INVALID_CELL or start == finish or width <= 0:
        return {}
    var delta := Vector2i(signi(finish.x - start.x), signi(finish.y - start.y))
    var length: int = absi(finish.x - start.x) + absi(finish.y - start.y)
    var best_start: int = -1
    var best_end: int = -1
    var run_start: int = -1
    for index in range(length + 1):
        var cell: Vector2i = start + delta * index
        var safe: bool = _road_cross_section_walkable(cell, start.y == finish.y, width, request, profile)
        if safe and run_start < 0:
            run_start = index
        var closes: bool = (not safe or index == length) and run_start >= 0
        if closes:
            var run_end: int = index if safe and index == length else index - 1
            if run_end - run_start > best_end - best_start:
                best_start = run_start
                best_end = run_end
            run_start = -1
    if best_start < 0 or best_end - best_start < 1:
        return {}
    var copied: Dictionary = road.duplicate(true)
    copied["start"] = start + delta * best_start
    copied["end"] = start + delta * best_end
    return copied

func _road_cross_section_walkable(
    center: Vector2i,
    horizontal: bool,
    width: int,
    request: GlobalWorldGenerationRequest,
    profile: Dictionary
) -> bool:
    var radius: int = width / 2
    for offset in range(-radius, radius + 1):
        var cell: Vector2i = center + (Vector2i(0, offset) if horizontal else Vector2i(offset, 0))
        if _surface_kind(request, profile, cell) == Surface.OCEAN:
            return false
    return true

func _append_district_roads(
    source_roads: Array[Dictionary],
    sites: Array[Dictionary],
    settlements: Array[Dictionary],
    request: GlobalWorldGenerationRequest,
    profile: Dictionary
) -> Dictionary:
    var roads: Array[Dictionary] = source_roads.duplicate(true)
    var smalltown: Dictionary = _settlement_by_id(settlements, "settlement.smalltown.001")
    var origin: Vector2i = smalltown.get("center", INVALID_CELL)
    if origin == INVALID_CELL:
        return {"ok": false, "failure_reason": "island_district_road_origin_missing", "roads": []}
    var width: int = int(profile.get("secondary_width", 3))
    var ordinal: int = 1
    for site: Dictionary in sites:
        if StringName(site.get("site_role", &"primary")) != &"district":
            continue
        var rect: Rect2i = site.get("bounds", Rect2i())
        var target: Vector2i = rect.position + Vector2i(rect.size.x / 2, rect.size.y / 2)
        var route_id: String = "route.region.district.%03d" % ordinal
        var corner := Vector2i(target.x, origin.y)
        var pieces: Array[Dictionary] = []
        if corner != origin:
            pieces.append(_road_record(route_id, "%s.a" % route_id, origin, corner, width, ordinal))
        if corner != target:
            pieces.append(_road_record(route_id, "%s.b" % route_id, corner, target, width, ordinal))
        if pieces.is_empty():
            return {"ok": false, "failure_reason": "island_district_road_zero_length", "roads": []}
        for piece: Dictionary in pieces:
            if not _road_record_walkable(piece, request, profile):
                return {"ok": false, "failure_reason": "island_district_road_enters_ocean", "roads": []}
            roads.append(piece)
        ordinal += 1
    return {"ok": true, "failure_reason": "", "roads": roads}

func _road_record(route_id: String, road_id: String, start: Vector2i, finish: Vector2i, width: int, ordinal: int) -> Dictionary:
    return {
        "road_id": road_id,
        "route_id": route_id,
        "road_class": &"secondary",
        "start": start,
        "end": finish,
        "width": width,
        "ordinal": ordinal,
    }

func _road_record_walkable(road: Dictionary, request: GlobalWorldGenerationRequest, profile: Dictionary) -> bool:
    var start: Vector2i = road.get("start", INVALID_CELL)
    var finish: Vector2i = road.get("end", INVALID_CELL)
    var width: int = int(road.get("width", 0))
    var delta := Vector2i(signi(finish.x - start.x), signi(finish.y - start.y))
    var length: int = absi(finish.x - start.x) + absi(finish.y - start.y)
    for index in range(length + 1):
        if not _road_cross_section_walkable(start + delta * index, start.y == finish.y, width, request, profile):
            return false
    return true

func _adapt_power(base: GeneratedGlobalWorldPlan, island_roads: Array[Dictionary]) -> Dictionary:
    var nodes: Array[Dictionary] = base.power_nodes.duplicate(true)
    var segments: Array[Dictionary] = []
    var old_ingress: Vector2i = INVALID_CELL
    for node: Dictionary in nodes:
        if StringName(node.get("kind", &"")) == &"regional_ingress":
            old_ingress = node.get("cell", INVALID_CELL)
            break
    if old_ingress == INVALID_CELL:
        return {"ok": false, "failure_reason": "island_power_ingress_missing", "nodes": [], "segments": []}

    var ingress_road_id: String = ""
    for segment: Dictionary in base.power_segments:
        if segment.get("start", INVALID_CELL) == old_ingress or segment.get("end", INVALID_CELL) == old_ingress:
            ingress_road_id = String(segment.get("source_road_id", ""))
            break
    var ingress_road: Dictionary = _road_by_id(island_roads, ingress_road_id)
    if ingress_road.is_empty():
        return {"ok": false, "failure_reason": "island_power_ingress_road_missing", "nodes": [], "segments": []}
    var a: Vector2i = ingress_road.get("start", INVALID_CELL)
    var b: Vector2i = ingress_road.get("end", INVALID_CELL)
    var new_ingress: Vector2i = a if _distance_sq(a, old_ingress) <= _distance_sq(b, old_ingress) else b
    for node: Dictionary in nodes:
        if StringName(node.get("kind", &"")) == &"regional_ingress":
            node["cell"] = new_ingress

    for source: Dictionary in base.power_segments:
        var road: Dictionary = _road_by_id(island_roads, String(source.get("source_road_id", "")))
        if road.is_empty():
            continue
        var clipped: Dictionary = _clip_collinear_segment(source, road)
        if clipped.is_empty():
            continue
        var copied: Dictionary = source.duplicate(true)
        copied["start"] = clipped.get("start", INVALID_CELL)
        copied["end"] = clipped.get("end", INVALID_CELL)
        segments.append(copied)
    if segments.is_empty():
        return {"ok": false, "failure_reason": "island_power_segments_missing", "nodes": [], "segments": []}
    return {"ok": true, "failure_reason": "", "nodes": nodes, "segments": segments}

func _clip_collinear_segment(segment: Dictionary, road: Dictionary) -> Dictionary:
    var a: Vector2i = segment.get("start", INVALID_CELL)
    var b: Vector2i = segment.get("end", INVALID_CELL)
    var r0: Vector2i = road.get("start", INVALID_CELL)
    var r1: Vector2i = road.get("end", INVALID_CELL)
    if a == INVALID_CELL or b == INVALID_CELL or r0 == INVALID_CELL or r1 == INVALID_CELL:
        return {}
    if a.y == b.y and r0.y == r1.y and a.y == r0.y:
        var lo: int = maxi(mini(a.x, b.x), mini(r0.x, r1.x))
        var hi: int = mini(maxi(a.x, b.x), maxi(r0.x, r1.x))
        if hi <= lo:
            return {}
        return {"start": Vector2i(lo, a.y) if a.x <= b.x else Vector2i(hi, a.y), "end": Vector2i(hi, a.y) if a.x <= b.x else Vector2i(lo, a.y)}
    if a.x == b.x and r0.x == r1.x and a.x == r0.x:
        var lo_y: int = maxi(mini(a.y, b.y), mini(r0.y, r1.y))
        var hi_y: int = mini(maxi(a.y, b.y), maxi(r0.y, r1.y))
        if hi_y <= lo_y:
            return {}
        return {"start": Vector2i(a.x, lo_y) if a.y <= b.y else Vector2i(a.x, hi_y), "end": Vector2i(a.x, hi_y) if a.y <= b.y else Vector2i(a.x, lo_y)}
    return {}

func _build_regions(base_regions: Array[Dictionary], sites: Array[Dictionary]) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for region: Dictionary in base_regions:
        if StringName(region.get("kind", &"")) == &"rural_open":
            continue
        result.append(region.duplicate(true))
    result.push_front({
        "id": "region.island.surface.001",
        "kind": &"island_surface",
        "rect": base_regions[0].get("rect", Rect2i()) if not base_regions.is_empty() else Rect2i(),
        "area_profile_hint": &"island.surface",
        "environment_profile_hint": &"temperate.coastal",
        "settlement_id": "",
    })
    for site: Dictionary in sites:
        if StringName(site.get("site_role", &"primary")) != &"district":
            continue
        result.append({
            "id": "region.%s" % String(site.get("id", "district")),
            "kind": &"smalltown_district",
            "rect": site.get("bounds", Rect2i()),
            "area_profile_hint": site.get("area_profile_hint", &""),
            "environment_profile_hint": site.get("environment_profile_hint", &""),
            "settlement_id": String(site.get("settlement_id", "")),
        })
    return result

func _validate(
    request: GlobalWorldGenerationRequest,
    plan: GeneratedGlobalWorldPlan,
    profile: Dictionary
) -> Dictionary:
    var failures: Array[String] = []
    if plan == null or not plan.is_generated():
        return {"ok": false, "failures": ["island_plan_incomplete"]}
    if plan.profile_id != ProfilesClass.TEMPERATE_ISLAND_REGION or plan.bounds != request.bounds or plan.seed != request.seed:
        failures.append("island_provenance_mismatch")

    var surface_counts: Dictionary = {Surface.LAND:0, Surface.SHORE:0, Surface.OCEAN:0}
    for geography: Dictionary in plan.geography_cells:
        var kind: StringName = StringName(geography.get("surface_kind", &""))
        if not surface_counts.has(kind):
            failures.append("island_geography_surface_invalid")
        else:
            surface_counts[kind] = int(surface_counts[kind]) + 1
    for kind: StringName in [Surface.LAND, Surface.SHORE, Surface.OCEAN]:
        if int(surface_counts.get(kind, 0)) <= 0:
            failures.append("island_geography_surface_missing:%s" % String(kind))

    var profile_counts: Dictionary = {}
    for first_index in range(plan.area_sites.size()):
        var site: Dictionary = plan.area_sites[first_index]
        var rect: Rect2i = site.get("bounds", Rect2i())
        if not _rect_inside(plan.bounds, rect) or not Surface.rect_is_land(
            plan.bounds, plan.seed, rect,
            int(profile.get("island_ocean_margin", 48)),
            int(profile.get("island_shore_width", 12)),
            int(profile.get("island_coast_wobble", 18)),
            int(profile.get("island_coast_scale", 96))
        ):
            failures.append("island_area_site_not_land:%s" % String(site.get("id", "")))
        if not _hydrology.rect_clear_of_rivers(rect, plan.river_segments, int(profile.get("settlement_river_clearance", 16))):
            failures.append("island_area_site_hits_river:%s" % String(site.get("id", "")))
        var profile_id: String = String(site.get("area_profile_hint", &""))
        profile_counts[profile_id] = int(profile_counts.get(profile_id, 0)) + 1
        for second_index in range(first_index + 1, plan.area_sites.size()):
            if _rects_overlap(rect, plan.area_sites[second_index].get("bounds", Rect2i())):
                failures.append("island_area_site_overlap")
    for required: String in ["smalltown.center", "suburban.neighborhood", "urban.mixed", "commercial.corridor", "industrial.district", "civic.campus"]:
        if int(profile_counts.get(required, 0)) <= 0:
            failures.append("island_required_profile_missing:%s" % required)

    for road: Dictionary in plan.road_segments:
        if not _road_record_walkable(road, request, profile):
            failures.append("island_road_enters_ocean:%s" % String(road.get("road_id", "")))
    for settlement: Dictionary in plan.settlements:
        if not _point_on_any_road(settlement.get("center", INVALID_CELL), plan.road_segments):
            failures.append("island_settlement_disconnected:%s" % String(settlement.get("id", "")))
    for site: Dictionary in plan.area_sites:
        if StringName(site.get("site_role", &"primary")) != &"district":
            continue
        var rect: Rect2i = site.get("bounds", Rect2i())
        var center: Vector2i = rect.position + Vector2i(rect.size.x / 2, rect.size.y / 2)
        if not _point_on_any_road(center, plan.road_segments):
            failures.append("island_district_disconnected:%s" % String(site.get("id", "")))

    if plan.bridge_intents.is_empty():
        failures.append("island_bridge_intent_missing")
    if plan.power_nodes.is_empty() or plan.power_segments.is_empty():
        failures.append("island_power_missing")
    return {"ok": failures.is_empty(), "failures": failures}

func _surface_kind(request: GlobalWorldGenerationRequest, profile: Dictionary, cell: Vector2i) -> StringName:
    return Surface.classify(
        request.bounds, request.seed, cell,
        int(profile.get("island_ocean_margin", 48)),
        int(profile.get("island_shore_width", 12)),
        int(profile.get("island_coast_wobble", 18)),
        int(profile.get("island_coast_scale", 96))
    )

func _point_on_any_road(point: Vector2i, roads: Array[Dictionary]) -> bool:
    for road: Dictionary in roads:
        var a: Vector2i = road.get("start", INVALID_CELL)
        var b: Vector2i = road.get("end", INVALID_CELL)
        if a.y == b.y and point.y == a.y and point.x >= mini(a.x,b.x) and point.x <= maxi(a.x,b.x):
            return true
        if a.x == b.x and point.x == a.x and point.y >= mini(a.y,b.y) and point.y <= maxi(a.y,b.y):
            return true
    return false

func _road_by_id(roads: Array[Dictionary], road_id: String) -> Dictionary:
    for road: Dictionary in roads:
        if String(road.get("road_id", "")) == road_id:
            return road
    return {}

func _settlement_by_id(settlements: Array[Dictionary], settlement_id: String) -> Dictionary:
    for settlement: Dictionary in settlements:
        if String(settlement.get("id", "")) == settlement_id:
            return settlement
    return {}

func _distance_sq(a: Vector2i, b: Vector2i) -> int:
    var d: Vector2i = a - b
    return d.x * d.x + d.y * d.y

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var max_cell: Vector2i = inner.position + inner.size - Vector2i.ONE
    return outer.has_point(inner.position) and outer.has_point(max_cell)

func _rects_overlap(a: Rect2i, b: Rect2i) -> bool:
    return a.position.x < b.position.x + b.size.x and a.position.x + a.size.x > b.position.x \
        and a.position.y < b.position.y + b.size.y and a.position.y + a.size.y > b.position.y
