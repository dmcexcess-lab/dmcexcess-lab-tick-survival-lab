extends RefCounted
class_name IslandSurfaceRequestProjection

const AreaRequestClass = preload("res://scripts/generation/areas/AreaGenerationRequest.gd")
const EnvironmentProfiles = preload("res://scripts/generation/areas/EnvironmentProfileCatalog.gd")
const GlobalProfiles = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")

const AREA_PROFILE: StringName = &"island.surface"

var _profiles: GlobalWorldProfileCatalog = GlobalProfiles.new()
var _projector: System20AreaRequestProjector = ProjectorClass.new()

func project(plan: GeneratedGlobalWorldPlan, area_id: String, bounds: Rect2i) -> Dictionary:
    var clean_id: String = area_id.strip_edges()
    if plan == null or not plan.is_generated() or clean_id.is_empty() \
        or plan.profile_id != GlobalProfiles.TEMPERATE_ISLAND_REGION \
        or not _rect_inside(plan.bounds, bounds):
        return _failure("invalid_island_surface_projection_input")
    for site: Dictionary in plan.area_sites:
        if _overlap(bounds, site.get("bounds", Rect2i())):
            return _failure("island_surface_overlaps_area_site")

    var road_result: Dictionary = _projector.road_constraints_for_bounds(plan, bounds)
    if not bool(road_result.get("ok", false)):
        return _failure("island_surface_road_projection_failed")
    var roads: Array[Dictionary] = []
    for value: Variant in road_result.get("roads", []):
        if typeof(value) != TYPE_DICTIONARY:
            return _failure("island_surface_road_projection_invalid")
        roads.append(value)

    var profile: Dictionary = _profiles.profile(plan.profile_id)
    if profile.is_empty():
        return _failure("island_global_profile_missing")
    var context: Dictionary = {
        "id": "constraint.island.%s" % clean_id,
        "source_id": "island.surface.context",
        "domain": &"island",
        "kind": &"surface_context",
        "reservation_role": &"service",
        "cell": bounds.position,
        "blocks_parcels": false,
        "blocks_local_roads": false,
        "settlement_id": "",
        "network_id": "",
        "world_bounds": plan.bounds,
        "world_seed": plan.seed,
        "ocean_margin": int(profile.get("island_ocean_margin", 48)),
        "shore_width": int(profile.get("island_shore_width", 12)),
        "coast_wobble": int(profile.get("island_coast_wobble", 18)),
        "coast_scale": int(profile.get("island_coast_scale", 96)),
        "wilderness_fraction": float(profile.get("island_wilderness_fraction", 0.10)),
        "land_use_block_size": int(profile.get("island_land_use_block_size", 64)),
    }
    var request := AreaRequestClass.new(
        clean_id,
        plan.seed,
        bounds,
        AREA_PROFILE,
        EnvironmentProfiles.TEMPERATE_RURAL,
        roads,
        [],
        [context],
        []
    )
    if not request.is_valid():
        return _failure("projected_island_surface_request_invalid")
    return {"ok": true, "failure_reason": "", "request": request}

func _failure(reason: String) -> Dictionary:
    return {"ok": false, "failure_reason": reason, "request": null}

func _rect_intersection(a: Rect2i, b: Rect2i) -> Rect2i:
    var start := Vector2i(maxi(a.position.x, b.position.x), maxi(a.position.y, b.position.y))
    var finish := Vector2i(mini(a.position.x + a.size.x, b.position.x + b.size.x), mini(a.position.y + a.size.y, b.position.y + b.size.y))
    if finish.x <= start.x or finish.y <= start.y:
        return Rect2i()
    return Rect2i(start, finish - start)

func _overlap(a: Rect2i, b: Rect2i) -> bool:
    var r: Rect2i = _rect_intersection(a, b)
    return r.size.x > 0 and r.size.y > 0

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var max_cell: Vector2i = inner.position + inner.size - Vector2i.ONE
    return outer.has_point(inner.position) and outer.has_point(max_cell)
