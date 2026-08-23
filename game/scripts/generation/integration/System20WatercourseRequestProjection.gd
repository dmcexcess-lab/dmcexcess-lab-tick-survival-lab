extends RefCounted
class_name System20WatercourseRequestProjection

const AreaRequestClass = preload("res://scripts/generation/areas/AreaGenerationRequest.gd")
const AreaProfiles = preload("res://scripts/generation/areas/AreaProfileCatalog.gd")
const EnvironmentProfiles = preload("res://scripts/generation/areas/EnvironmentProfileCatalog.gd")
const HydrologyQueryClass = preload("res://scripts/generation/world/GlobalHydrologyQuery.gd")

var _hydrology: GlobalHydrologyQuery = HydrologyQueryClass.new()

func project(
    plan: GeneratedGlobalWorldPlan,
    area_id: String,
    bounds: Rect2i,
    rural_open_context_contains: Callable,
    road_projector: Callable
) -> Dictionary:
    var clean_area_id: String = area_id.strip_edges()
    if plan == null or not plan.is_generated() or clean_area_id.is_empty() or not _rect_inside(plan.bounds, bounds):
        return _failure("invalid_watercourse_projection_input")
    if not bool(rural_open_context_contains.call(plan, bounds)):
        return _failure("watercourse_context_missing")
    for site: Dictionary in plan.area_sites:
        var site_bounds: Rect2i = site.get("bounds", Rect2i())
        if _rects_overlap_positive(bounds, site_bounds):
            return _failure("watercourse_overlaps_settlement_site")

    var rivers: Array[Dictionary] = []
    var coverage: Array[Rect2i] = []
    for source: Dictionary in plan.river_segments:
        var full_corridor: Rect2i = _hydrology.segment_corridor_rect(source)
        var clipped: Rect2i = _rect_intersection(full_corridor, bounds)
        if clipped.size.x <= 0 or clipped.size.y <= 0:
            continue
        rivers.append({
            "kind": &"river_segment",
            "segment_id": String(source.get("segment_id", "")),
            "river_id": String(source.get("river_id", "")),
            "start": source.get("start", Vector2i.ZERO),
            "end": source.get("end", Vector2i.ZERO),
            "width": int(source.get("width", 0)),
            "ordinal": int(source.get("ordinal", 0)),
            "corridor_rect": clipped,
        })
        coverage.append(clipped)
    if rivers.is_empty() or not _rect_fully_covered(bounds, coverage):
        return _failure("watercourse_bounds_not_fully_river")
    rivers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var ao: int = int(a.get("ordinal", 0))
        var bo: int = int(b.get("ordinal", 0))
        if ao != bo:
            return ao < bo
        return String(a.get("segment_id", "")) < String(b.get("segment_id", ""))
    )

    var bridges: Array[Dictionary] = []
    for source: Dictionary in plan.bridge_intents:
        var full_deck: Rect2i = _hydrology.bridge_deck_rect(source)
        var clipped_deck: Rect2i = _rect_intersection(full_deck, bounds)
        if clipped_deck.size.x <= 0 or clipped_deck.size.y <= 0:
            continue
        bridges.append({
            "kind": &"bridge_intent",
            "id": String(source.get("id", "")),
            "road_id": String(source.get("road_id", "")),
            "route_id": String(source.get("route_id", "")),
            "river_id": String(source.get("river_id", "")),
            "river_segment_id": String(source.get("river_segment_id", "")),
            "cell": source.get("cell", Vector2i.ZERO),
            "bridge_axis": StringName(source.get("bridge_axis", &"")),
            "road_width": int(source.get("road_width", 0)),
            "river_width": int(source.get("river_width", 0)),
            "deck_rect": clipped_deck,
        })
    bridges.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("id", "")) < String(b.get("id", ""))
    )

    var road_result_value: Variant = road_projector.call(plan, bounds)
    if typeof(road_result_value) != TYPE_DICTIONARY:
        return _failure("watercourse_road_projection_failed")
    var road_result: Dictionary = road_result_value
    if not bool(road_result.get("ok", false)):
        return _failure("watercourse_road_projection_failed")
    var roads: Array[Dictionary] = []
    for value: Variant in road_result.get("roads", []):
        if typeof(value) != TYPE_DICTIONARY:
            return _failure("watercourse_road_projection_result_invalid")
        roads.append(value)

    var hydrology: Array[Dictionary] = []
    for river: Dictionary in rivers:
        hydrology.append(river)
    for bridge: Dictionary in bridges:
        hydrology.append(bridge)

    var request: AreaGenerationRequest = AreaRequestClass.new(
        clean_area_id,
        plan.seed,
        bounds,
        AreaProfiles.RURAL_WATERCOURSE,
        EnvironmentProfiles.TEMPERATE_RURAL,
        roads,
        [],
        [],
        [],
        hydrology
    )
    if not request.is_valid():
        return _failure("projected_watercourse_request_invalid")
    return {"ok": true, "failure_reason": "", "request": request}

func _failure(reason: String) -> Dictionary:
    return {"ok": false, "failure_reason": reason, "request": null}

func _rect_fully_covered(bounds: Rect2i, rects: Array[Rect2i]) -> bool:
    for y in range(bounds.position.y, bounds.position.y + bounds.size.y):
        for x in range(bounds.position.x, bounds.position.x + bounds.size.x):
            var cell := Vector2i(x, y)
            var covered: bool = false
            for rect: Rect2i in rects:
                if rect.has_point(cell):
                    covered = true
                    break
            if not covered:
                return false
    return true

func _rect_intersection(a: Rect2i, b: Rect2i) -> Rect2i:
    var start_x: int = maxi(a.position.x, b.position.x)
    var start_y: int = maxi(a.position.y, b.position.y)
    var end_x: int = mini(a.position.x + a.size.x, b.position.x + b.size.x)
    var end_y: int = mini(a.position.y + a.size.y, b.position.y + b.size.y)
    if end_x <= start_x or end_y <= start_y:
        return Rect2i()
    return Rect2i(Vector2i(start_x, start_y), Vector2i(end_x - start_x, end_y - start_y))

func _rects_overlap_positive(a: Rect2i, b: Rect2i) -> bool:
    var overlap: Rect2i = _rect_intersection(a, b)
    return overlap.size.x > 0 and overlap.size.y > 0

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var inner_max: Vector2i = inner.position + inner.size - Vector2i.ONE
    return outer.has_point(inner.position) and outer.has_point(inner_max)
