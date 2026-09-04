extends SceneTree

const GlobalFixture = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const LegacyFixture = preload("res://scripts/demo/RuralCrossroadsPlanFixture.gd")
const RequestClass = preload("res://scripts/generation/world/GlobalWorldGenerationRequest.gd")
const AreaRequestClass = preload("res://scripts/generation/areas/AreaGenerationRequest.gd")
const ProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const AreaProfilesClass = preload("res://scripts/generation/areas/AreaProfileCatalog.gd")
const EnvironmentProfilesClass = preload("res://scripts/generation/areas/EnvironmentProfileCatalog.gd")
const IslandPlannerClass = preload("res://scripts/generation/world/IslandWorldPlanner.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const SurfaceProjectionClass = preload("res://scripts/generation/integration/IslandSurfaceRequestProjection.gd")
const LocalGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const OutdoorDressingClass = preload("res://scripts/generation/areas/OutdoorPropertyDressingPlanner.gd")
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
    _check(request.seed == GlobalFixture.SEED, "baseline request preserves requested world seed")
    var planner := IslandPlannerClass.new()
    var plan: GeneratedGlobalWorldPlan = planner.generate(request)
    _check(plan != null and plan.is_generated(), "island v3 plan generates")
    if plan == null or not plan.is_generated():
        _finish()
        return
    _check(plan.seed == request.seed, "baseline generated plan preserves request seed")
    var baseline_seed_before: int = plan.seed
    var baseline_signature_before: String = plan.signature()

    var profile: Dictionary = ProfilesClass.new().profile(ProfilesClass.TEMPERATE_ISLAND_REGION)
    _check(int(profile.get("version", 0)) >= 3, "island profile records fresh-new-game and belt-removal revision")
    _check(not bool(profile.get("reuse_world_seed_for_central_site", true)), "island profile forbids legacy central seed reuse")
    _check(int(profile.get("protected_cross_half_span", 9999)) <= 192, "playable island no longer inherits the 640-cell regional stress-fixture cross")

    var central: Dictionary = _site(plan, GlobalFixture.CENTRAL_SITE_ID)
    var smalltown: Dictionary = _site(plan, "area.smalltown.center.001")
    _check(not central.is_empty(), "central crossroads site exists")
    _check(not smalltown.is_empty(), "small-town site exists")
    if not central.is_empty():
        _check(int(central.get("seed", GlobalFixture.SEED)) != LegacyFixture.SEED, "island central site no longer reuses legacy critique seed")
        var central_bounds: Rect2i = central.get("bounds", Rect2i())
        var central_settlement: Dictionary = _settlement(plan, String(central.get("settlement_id", "")))
        _check(not central_settlement.is_empty(), "central generated site retains its procedural settlement")
        if not central_settlement.is_empty():
            _check(
                central_bounds.has_point(central_settlement.get("center", Vector2i(-999999, -999999))),
                "central generated site owns its procedural playable settlement location"
            )

    var alternate_request := RequestClass.new(
        GlobalFixture.WORLD_ID,
        GlobalFixture.SEED + 1,
        GlobalFixture.BOUNDS,
        ProfilesClass.TEMPERATE_ISLAND_REGION
    )
    _check(alternate_request.seed == GlobalFixture.SEED + 1, "alternate request preserves requested world seed")
    _check(alternate_request.seed != request.seed, "alternate request seed differs from baseline request seed")
    var alternate: GeneratedGlobalWorldPlan = planner.generate(alternate_request)
    var alternate_failure_reason: String = "null" if alternate == null else alternate.failure_reason
    _check(
        alternate != null and alternate.is_generated(),
        "alternate new-game island seed generates (reason=%s)" % alternate_failure_reason
    )
    if alternate != null and alternate.is_generated():
        var baseline_seed_after: int = plan.seed
        var baseline_signature_after: String = plan.signature()
        var alternate_signature: String = alternate.signature()
        print("ISLAND_SEED_DIAGNOSTIC baseline_request=%d baseline_plan_before=%d baseline_plan_after=%d alternate_request=%d alternate_plan=%d baseline_signature_before_hash=%d baseline_signature_after_hash=%d alternate_signature_hash=%d" % [
            request.seed,
            baseline_seed_before,
            baseline_seed_after,
            alternate_request.seed,
            alternate.seed,
            baseline_signature_before.hash(),
            baseline_signature_after.hash(),
            alternate_signature.hash(),
        ])
        _check(alternate.seed == alternate_request.seed, "alternate generated plan preserves request seed (request=%d plan=%d)" % [alternate_request.seed, alternate.seed])
        _check(
            baseline_seed_after == baseline_seed_before,
            "second generation does not mutate prior plan seed (before=%d after=%d alternate=%d)" % [baseline_seed_before, baseline_seed_after, alternate.seed]
        )
        _check(
            baseline_signature_after == baseline_signature_before,
            "second generation does not mutate prior plan signature (before_hash=%d after_hash=%d)" % [baseline_signature_before.hash(), baseline_signature_after.hash()]
        )
        _check(alternate.seed != baseline_seed_before, "different new-game seed changes authoritative plan seed")
        _check(
            alternate_signature != baseline_signature_before,
            "different new-game seed redraws the authoritative island plan (baseline_seed=%d alternate_seed=%d baseline_hash=%d alternate_hash=%d baseline_len=%d alternate_len=%d)" % [
                baseline_seed_before,
                alternate.seed,
                baseline_signature_before.hash(),
                alternate_signature.hash(),
                baseline_signature_before.length(),
                alternate_signature.length(),
            ]
        )
        var alternate_central: Dictionary = _site(alternate, GlobalFixture.CENTRAL_SITE_ID)
        _check(int(alternate_central.get("seed", -1)) != int(central.get("seed", -1)), "different new-game seed changes central local-area seed")

    var projector := ProjectorClass.new()
    var local_generator := LocalGeneratorClass.new()
    var island_projected: Dictionary = projector.project_site(plan, GlobalFixture.CENTRAL_SITE_ID)
    _check(bool(island_projected.get("ok", false)), "island central site projects")
    var island_request: AreaGenerationRequest = island_projected.get("request") as AreaGenerationRequest
    var island_area: GeneratedAreaPlan = null
    if island_request != null and island_request.is_valid():
        _check(
            island_request.inherited_ecology_seed != null \
                and int(island_request.inherited_ecology_seed) == plan.seed,
            "island settlement projection inherits the shared world ecology seed"
        )
        island_area = local_generator.generate(island_request)
    var legacy_area: GeneratedAreaPlan = local_generator.generate(LegacyFixture.request())
    _check(island_area != null and island_area.is_generated(), "island central site generates")
    _check(legacy_area != null and legacy_area.is_generated(), "legacy critique reference still generates independently")
    if island_area != null and island_area.is_generated() and legacy_area != null and legacy_area.is_generated():
        _check(island_area.signature() != legacy_area.signature(), "playable island no longer embeds the original 256x256 critique map")
        print("ISLAND_CENTRAL_SIGNATURE=%s" % island_area.signature())
        print("LEGACY_CENTRAL_SIGNATURE=%s" % legacy_area.signature())

    if not central.is_empty() and not smalltown.is_empty():
        var central_bounds: Rect2i = central.get("bounds", Rect2i())
        var smalltown_bounds: Rect2i = smalltown.get("bounds", Rect2i())
        _check(not central_bounds.intersects(smalltown_bounds), "central and small-town generated sites remain distinct instead of overlapping")
        var gap: int = _rect_manhattan_gap(central_bounds, smalltown_bounds)
        # Town-first islands deliberately place villages and rural homes between
        # the larger anchors.  The old 192-cell cross-fixture shortcut is no
        # longer the seam contract; this remains bounded so a true empty belt
        # cannot return.
        var max_seam: int = int(profile.get("island_settlement_seam_max", 1280))
        print("ISLAND_CENTRAL_TO_SMALLTOWN_EDGE_GAP=%d MAX=%d" % [gap, max_seam])
        _check(max_seam > 0 and gap <= max_seam, "central-to-small-town countryside seam stays within the protected rural corridor instead of becoming a giant green belt")

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

    _check_ecology_split_invariance(plan.seed)
    _finish()

func _check_ecology_split_invariance(world_seed: int) -> void:
    var environment: Dictionary = EnvironmentProfilesClass.new().profile(EnvironmentProfilesClass.TEMPERATE_RURAL)
    var combined_bounds := Rect2i(Vector2i(1000, 2000), Vector2i(128, 64))
    var left_bounds := Rect2i(combined_bounds.position, Vector2i(64, 64))
    var right_bounds := Rect2i(combined_bounds.position + Vector2i(64, 0), Vector2i(64, 64))
    var planner := OutdoorDressingClass.new()

    var combined: Dictionary = planner.plan(
        _ecology_request("area.ecology.probe.combined", combined_bounds, world_seed),
        environment,
        [],
        [],
        []
    )
    var left: Dictionary = planner.plan(
        _ecology_request("area.ecology.probe.left", left_bounds, world_seed),
        environment,
        [],
        [],
        []
    )
    var right: Dictionary = planner.plan(
        _ecology_request("area.ecology.probe.right", right_bounds, world_seed),
        environment,
        [],
        [],
        []
    )
    var all_ok: bool = bool(combined.get("ok", false)) and bool(left.get("ok", false)) and bool(right.get("ok", false))
    _check(all_ok, "shared world ecology probe plans")
    if not all_ok:
        return

    var combined_props: Array = combined.get("props", [])
    var split_props: Array = []
    split_props.append_array(left.get("props", []))
    split_props.append_array(right.get("props", []))
    _check(not combined_props.is_empty(), "shared world ecology probe produces natural dressing")
    _check(
        _natural_signature(combined_props) == _natural_signature(split_props),
        "shared world ecology is invariant when the same land is split across logical area bounds"
    )

func _ecology_request(area_id: String, bounds: Rect2i, world_seed: int) -> AreaGenerationRequest:
    var request: AreaGenerationRequest = AreaRequestClass.new(
        area_id,
        99173,
        bounds,
        AreaProfilesClass.RURAL_OPEN,
        EnvironmentProfilesClass.TEMPERATE_RURAL
    )
    request.inherited_ecology_seed = world_seed
    return request

func _natural_signature(values: Array) -> String:
    var parts := PackedStringArray()
    for value: Variant in values:
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var prop: Dictionary = value
        var cell: Vector2i = prop.get("cell", Vector2i(-999999, -999999))
        parts.append("%d,%d|%s" % [cell.x, cell.y, String(prop.get("semantic", &""))])
    parts.sort()
    return ";".join(parts)

func _site(plan: GeneratedGlobalWorldPlan, site_id: String) -> Dictionary:
    for site: Dictionary in plan.area_sites:
        if String(site.get("id", "")) == site_id:
            return site
    return {}

func _settlement(plan: GeneratedGlobalWorldPlan, settlement_id: String) -> Dictionary:
    for settlement: Dictionary in plan.settlements:
        if String(settlement.get("id", "")) == settlement_id:
            return settlement
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
