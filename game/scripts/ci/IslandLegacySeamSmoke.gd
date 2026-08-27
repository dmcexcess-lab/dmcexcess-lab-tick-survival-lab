extends SceneTree

const GlobalFixture = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const LegacyFixture = preload("res://scripts/demo/RuralCrossroadsPlanFixture.gd")
const RequestClass = preload("res://scripts/generation/world/GlobalWorldGenerationRequest.gd")
const ProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const EnvironmentProfilesClass = preload("res://scripts/generation/areas/EnvironmentProfileCatalog.gd")
const IslandPlannerClass = preload("res://scripts/generation/world/IslandWorldPlanner.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const SurfaceProjectionClass = preload("res://scripts/generation/integration/IslandSurfaceRequestProjection.gd")
const LocalGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const SurfaceGeneratorClass = preload("res://scripts/generation/areas/IslandSurfaceAreaGenerator.gd")
const SurfaceCatalogClass = preload("res://scripts/streaming/IslandSurfaceSourceCatalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var request := RequestClass.new(
        GlobalFixture.WORLD_ID,
        GlobalFixture.SEED,
        GlobalFixture.BOUNDS,
        ProfilesClass.TEMPERATE_ISLAND_REGION
    )
    var plan: GeneratedGlobalWorldPlan = IslandPlannerClass.new().generate(request)
    _check(plan != null and plan.is_generated(), "island v2 plan generates")
    if plan == null or not plan.is_generated():
        _finish()
        return

    var profile: Dictionary = ProfilesClass.new().profile(ProfilesClass.TEMPERATE_ISLAND_REGION)
    _check(int(profile.get("version", 0)) >= 2, "island profile records legacy-layout removal revision")
    _check(not bool(profile.get("reuse_world_seed_for_central_site", true)), "island profile forbids legacy central seed reuse")

    var central: Dictionary = _site(plan, GlobalFixture.CENTRAL_SITE_ID)
    var smalltown: Dictionary = _site(plan, "area.smalltown.center.001")
    _check(not central.is_empty(), "central crossroads site exists")
    _check(not smalltown.is_empty(), "small-town site exists")
    if not central.is_empty():
        _check(int(central.get("seed", GlobalFixture.SEED)) != LegacyFixture.SEED, "island central site no longer reuses legacy critique seed")
        _check(central.get("bounds", Rect2i()) == LegacyFixture.BOUNDS, "central world location may remain stable while generated identity changes")

    var projector := ProjectorClass.new()
    var local_generator := LocalGeneratorClass.new()
    var island_projected: Dictionary = projector.project_site(plan, GlobalFixture.CENTRAL_SITE_ID)
    _check(bool(island_projected.get("ok", false)), "island central site projects")
    var island_request: AreaGenerationRequest = island_projected.get("request") as AreaGenerationRequest
    var island_area: GeneratedAreaPlan = null
    if island_request != null and island_request.is_valid():
        island_area = local_generator.generate(island_request)
    var legacy_area: GeneratedAreaPlan = local_generator.generate(LegacyFixture.request())
    _check(island_area != null and island_area.is_generated(), "island central site generates")
    _check(legacy_area != null and legacy_area.is_generated(), "legacy critique reference still generates independently")
    if island_area != null and island_area.is_generated() and legacy_area != null and legacy_area.is_generated():
        _check(island_area.signature() != legacy_area.signature(), "playable island no longer embeds the original 256x256 critique map")
        print("ISLAND_CENTRAL_SIGNATURE=%s" % island_area.signature())
        print("LEGACY_CENTRAL_SIGNATURE=%s" % legacy_area.signature())

    if not central.is_empty() and not smalltown.is_empty():
        var gap: int = _rect_manhattan_gap(central.get("bounds", Rect2i()), smalltown.get("bounds", Rect2i()))
        print("ISLAND_CENTRAL_TO_SMALLTOWN_EDGE_GAP=%d" % gap)
        _check(gap <= 192, "central-to-small-town countryside gap is compact rather than a giant legacy belt")

    var surface_catalog := SurfaceCatalogClass.new(plan)
    _check(surface_catalog.is_ready(), "island surface catalog is ready")
    if surface_catalog.is_ready() and not surface_catalog.sources().is_empty():
        var source: Dictionary = surface_catalog.sources()[0]
        var source_id: String = String(source.get("source_id", ""))
        var source_bounds: Rect2i = source.get("bounds", Rect2i())
        var surface_projected: Dictionary = SurfaceProjectionClass.new().project(plan, source_id, source_bounds)
        _check(bool(surface_projected.get("ok", false)), "island surface source projects")
        var surface_request: AreaGenerationRequest = surface_projected.get("request") as AreaGenerationRequest
        if surface_request != null and surface_request.is_valid():
            _check(surface_request.environment_profile_id == EnvironmentProfilesClass.TEMPERATE_RURAL, "island interior uses the same rural environment vocabulary as settlement sites")
            var surface_plan: GeneratedAreaPlan = SurfaceGeneratorClass.new().generate(surface_request)
            _check(surface_plan != null and surface_plan.is_generated(), "island surface v3 generates")
            if surface_plan != null and surface_plan.is_generated():
                _check(surface_plan.area_profile_version >= 3, "island surface records unified-interior revision")
                _check(not _has_ground_semantic(surface_plan, &"ground.forest_floor"), "island interior no longer switches base ground palette at settlement rectangles")

    _finish()

func _site(plan: GeneratedGlobalWorldPlan, site_id: String) -> Dictionary:
    for site: Dictionary in plan.area_sites:
        if String(site.get("id", "")) == site_id:
            return site
    return {}

func _rect_manhattan_gap(a: Rect2i, b: Rect2i) -> int:
    if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0:
        return 2147483647
    var a_right: int = a.position.x + a.size.x
    var b_right: int = b.position.x + b.size.x
    var a_bottom: int = a.position.y + a.size.y
    var b_bottom: int = b.position.y + b.size.y
    var gap_x: int = maxi(0, maxi(a.position.x, b.position.x) - mini(a_right, b_right))
    var gap_y: int = maxi(0, maxi(a.position.y, b.position.y) - mini(a_bottom, b_bottom))
    return gap_x + gap_y

func _has_ground_semantic(plan: GeneratedAreaPlan, semantic: StringName) -> bool:
    for region: Dictionary in plan.ground_regions:
        if StringName(region.get("semantic", &"")) == semantic:
            return true
    return false

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("ISLAND_LEGACY_SEAM_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("ISLAND_LEGACY_SEAM_SMOKE_FAIL: %s" % failure)
    quit(1)
