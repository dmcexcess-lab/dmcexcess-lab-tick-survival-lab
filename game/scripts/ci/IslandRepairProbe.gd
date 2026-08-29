extends SceneTree

const GlobalFixture = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const RequestClass = preload("res://scripts/generation/world/GlobalWorldGenerationRequest.gd")
const ProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const BasePlannerClass = preload("res://scripts/generation/world/GlobalWorldPlanner.gd")
const IslandPlannerClass = preload("res://scripts/generation/world/IslandWorldPlanner.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _check_seed(GlobalFixture.SEED, true)
    _check_seed(GlobalFixture.SEED + 1, false)
    if _failures.is_empty():
        print("ISLAND_REPAIR_BASELINE_GATE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("ISLAND_REPAIR_BASELINE_GATE_FAIL: %s" % failure)
    quit(1)

func _check_seed(seed: int, baseline: bool) -> void:
    var request := RequestClass.new(
        GlobalFixture.WORLD_ID,
        seed,
        GlobalFixture.BOUNDS,
        ProfilesClass.TEMPERATE_ISLAND_REGION
    )
    var base: GeneratedGlobalWorldPlan = BasePlannerClass.new().generate(request)
    var island: GeneratedGlobalWorldPlan = IslandPlannerClass.new().generate(request)
    _check(base != null and base.is_generated(), "base plan generates for seed %d" % seed)
    _check(island != null and island.is_generated(), "island plan generates for seed %d (reason=%s)" % [seed, "null" if island == null else island.failure_reason])
    if base == null or island == null or not base.is_generated() or not island.is_generated():
        return

    _check(base.settlements == island.settlements, "island adaptation does not move global settlements for seed %d" % seed)
    _check(_sites_contain_their_settlements(island), "all island local windows retain their authoritative settlement center for seed %d" % seed)
    _check(not _sites_overlap(island.area_sites), "island local windows do not overlap for seed %d" % seed)

    if baseline:
        _check(_same_site_bounds(base.area_sites, island.area_sites), "baseline seed keeps every pre-repair local window unchanged")
        _check(_site_bounds(island.area_sites, "area.rural.crossroads.001") == Rect2i(1000, 2000, 256, 256), "baseline crossroads window unchanged")
        _check(_site_bounds(island.area_sites, "area.smalltown.center.001") == Rect2i(1320, 1936, 256, 256), "baseline smalltown window unchanged")
        _check(_site_bounds(island.area_sites, "area.rural.scattered.001") == Rect2i(936, 1680, 256, 256), "baseline hamlet 1 window unchanged")
        _check(_site_bounds(island.area_sites, "area.rural.scattered.002") == Rect2i(680, 2448, 256, 256), "baseline hamlet 2 window unchanged")
        _check(_site_bounds(island.area_sites, "area.rural.scattered.003") == Rect2i(1320, 1680, 256, 256), "baseline hamlet 3 window unchanged")
    else:
        var base_smalltown: Rect2i = _site_bounds(base.area_sites, "area.smalltown.center.001")
        var island_smalltown: Rect2i = _site_bounds(island.area_sites, "area.smalltown.center.001")
        _check(base_smalltown == Rect2i(1192, 1936, 256, 256), "alternate base reproduces the known overlapping smalltown window")
        _check(island_smalltown == Rect2i(1256, 1936, 256, 256), "alternate island repairs only the smalltown local window by the minimal 64-cell east shift")
        _check(_site_bounds(base.area_sites, "area.rural.crossroads.001") == _site_bounds(island.area_sites, "area.rural.crossroads.001"), "alternate repair leaves crossroads local window unchanged")
        _check(_settlement_center(island.settlements, "settlement.smalltown.001") == Vector2i(1320, 2064), "alternate repair leaves smalltown global center unchanged")

func _same_site_bounds(first: Array[Dictionary], second: Array[Dictionary]) -> bool:
    if first.size() != second.size():
        return false
    for site: Dictionary in first:
        var site_id: String = String(site.get("id", ""))
        if _site_bounds(second, site_id) != site.get("bounds", Rect2i()):
            return false
    return true

func _sites_contain_their_settlements(plan: GeneratedGlobalWorldPlan) -> bool:
    for site: Dictionary in plan.area_sites:
        var center: Vector2i = _settlement_center(plan.settlements, String(site.get("settlement_id", "")))
        if center == Vector2i(-999999, -999999) or not Rect2i(site.get("bounds", Rect2i())).has_point(center):
            return false
    return true

func _sites_overlap(sites: Array[Dictionary]) -> bool:
    for first_index in range(sites.size()):
        var first: Rect2i = sites[first_index].get("bounds", Rect2i())
        for second_index in range(first_index + 1, sites.size()):
            var second: Rect2i = sites[second_index].get("bounds", Rect2i())
            if _rects_overlap(first, second):
                return true
    return false

func _site_bounds(sites: Array[Dictionary], site_id: String) -> Rect2i:
    for site: Dictionary in sites:
        if String(site.get("id", "")) == site_id:
            return site.get("bounds", Rect2i())
    return Rect2i()

func _settlement_center(settlements: Array[Dictionary], settlement_id: String) -> Vector2i:
    for settlement: Dictionary in settlements:
        if String(settlement.get("id", "")) == settlement_id:
            return settlement.get("center", Vector2i(-999999, -999999))
    return Vector2i(-999999, -999999)

func _rects_overlap(a: Rect2i, b: Rect2i) -> bool:
    return a.position.x < b.position.x + b.size.x \
        and a.position.x + a.size.x > b.position.x \
        and a.position.y < b.position.y + b.size.y \
        and a.position.y + a.size.y > b.position.y

func _check(condition: bool, message: String) -> void:
    if condition:
        print("ISLAND_REPAIR_CHECK_OK: %s" % message)
    else:
        _failures.append(message)
