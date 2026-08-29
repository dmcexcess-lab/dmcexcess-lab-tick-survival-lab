extends SceneTree

const GlobalFixture = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const RequestClass = preload("res://scripts/generation/world/GlobalWorldGenerationRequest.gd")
const ProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const BasePlannerClass = preload("res://scripts/generation/world/GlobalWorldPlanner.gd")
const Surface = preload("res://scripts/generation/shared/IslandSurfaceMath.gd")

func _initialize() -> void:
    var profile: Dictionary = ProfilesClass.new().profile(ProfilesClass.TEMPERATE_ISLAND_REGION)
    for seed in [GlobalFixture.SEED, GlobalFixture.SEED + 1]:
        var request := RequestClass.new(
            GlobalFixture.WORLD_ID,
            seed,
            GlobalFixture.BOUNDS,
            ProfilesClass.TEMPERATE_ISLAND_REGION
        )
        var base: GeneratedGlobalWorldPlan = BasePlannerClass.new().generate(request)
        print("ISLAND_REPAIR_PROBE seed=%d generated=%s reason=%s" % [seed, str(base != null and base.is_generated()), "null" if base == null else base.failure_reason])
        if base == null or not base.is_generated():
            continue
        for site: Dictionary in base.area_sites:
            var rect: Rect2i = site.get("bounds", Rect2i())
            var settlement_id: String = String(site.get("settlement_id", ""))
            var center := Vector2i(-999999, -999999)
            for settlement: Dictionary in base.settlements:
                if String(settlement.get("id", "")) == settlement_id:
                    center = settlement.get("center", center)
                    break
            var road_count: int = 0
            for road: Dictionary in base.road_segments:
                if _segment_intersects_rect(road, rect):
                    road_count += 1
            var land: bool = Surface.rect_is_land(
                request.bounds,
                request.seed,
                rect,
                int(profile.get("island_ocean_margin", 24)),
                int(profile.get("island_shore_width", 8)),
                int(profile.get("island_coast_wobble", 8)),
                int(profile.get("island_coast_scale", 96))
            )
            print("ISLAND_REPAIR_SITE seed=%d id=%s settlement=%s center=%s bounds=%s contains_center=%s roads=%d land=%s" % [
                seed,
                String(site.get("id", "")),
                settlement_id,
                str(center),
                str(rect),
                str(rect.has_point(center)),
                road_count,
                str(land),
            ])
        for first_index in range(base.area_sites.size()):
            for second_index in range(first_index + 1, base.area_sites.size()):
                var first: Dictionary = base.area_sites[first_index]
                var second: Dictionary = base.area_sites[second_index]
                var overlap: Rect2i = _intersection(first.get("bounds", Rect2i()), second.get("bounds", Rect2i()))
                if overlap.size.x > 0 and overlap.size.y > 0:
                    print("ISLAND_REPAIR_OVERLAP seed=%d first=%s second=%s rect=%s" % [seed, String(first.get("id", "")), String(second.get("id", "")), str(overlap)])
    quit(0)

func _intersection(a: Rect2i, b: Rect2i) -> Rect2i:
    var start := Vector2i(maxi(a.position.x, b.position.x), maxi(a.position.y, b.position.y))
    var finish := Vector2i(mini(a.position.x + a.size.x, b.position.x + b.size.x), mini(a.position.y + a.size.y, b.position.y + b.size.y))
    if finish.x <= start.x or finish.y <= start.y:
        return Rect2i()
    return Rect2i(start, finish - start)

func _segment_intersects_rect(segment: Dictionary, rect: Rect2i) -> bool:
    var start: Vector2i = segment.get("start", Vector2i(-999999, -999999))
    var finish: Vector2i = segment.get("end", Vector2i(-999999, -999999))
    if start.y == finish.y:
        return start.y >= rect.position.y and start.y < rect.position.y + rect.size.y \
            and maxi(mini(start.x, finish.x), rect.position.x) < mini(maxi(start.x, finish.x), rect.position.x + rect.size.x)
    if start.x == finish.x:
        return start.x >= rect.position.x and start.x < rect.position.x + rect.size.x \
            and maxi(mini(start.y, finish.y), rect.position.y) < mini(maxi(start.y, finish.y), rect.position.y + rect.size.y)
    return false
