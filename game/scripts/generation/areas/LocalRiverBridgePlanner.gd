extends RefCounted
class_name LocalRiverBridgePlanner

const WATERCOURSE_PROFILE: StringName = &"rural.watercourse"
const RIVER_KIND: StringName = &"river_segment"
const BRIDGE_KIND: StringName = &"bridge_intent"

func plan(
    request: AreaGenerationRequest,
    area_profile: Dictionary,
    environment_profile: Dictionary
) -> Dictionary:
    var ground_regions: Array[Dictionary] = []
    var features: Array[Dictionary] = []
    if request == null or not request.is_valid() or request.area_profile_id != WATERCOURSE_PROFILE:
        return _failure("invalid_watercourse_planner_input")
    if area_profile.is_empty() or environment_profile.is_empty():
        return _failure("invalid_watercourse_profile_input")

    var rivers: Array[Dictionary] = []
    var bridges: Array[Dictionary] = []
    var river_by_segment: Dictionary = {}
    var feature_ids: Dictionary = {}
    for value: Variant in request.inherited_hydrology:
        if typeof(value) != TYPE_DICTIONARY:
            return _failure("watercourse_hydrology_record_invalid")
        var record: Dictionary = value
        var kind: StringName = StringName(record.get("kind", &""))
        if kind == RIVER_KIND:
            if not _river_record_valid(request.bounds, record):
                return _failure("watercourse_river_record_invalid")
            var segment_id: String = String(record.get("segment_id", ""))
            if feature_ids.has("river:%s" % segment_id):
                return _failure("watercourse_river_record_duplicate")
            feature_ids["river:%s" % segment_id] = true
            river_by_segment[segment_id] = record.duplicate(true)
            rivers.append(record.duplicate(true))
        elif kind == BRIDGE_KIND:
            if not _bridge_record_structurally_valid(request.bounds, record):
                return _failure("watercourse_bridge_record_invalid")
            var bridge_id: String = String(record.get("id", ""))
            if feature_ids.has("bridge:%s" % bridge_id):
                return _failure("watercourse_bridge_record_duplicate")
            feature_ids["bridge:%s" % bridge_id] = true
            bridges.append(record.duplicate(true))
        else:
            return _failure("watercourse_hydrology_kind_unknown")

    if rivers.is_empty():
        return _failure("watercourse_river_record_missing")
    if not _request_fully_covered(request.bounds, rivers):
        return _failure("watercourse_request_not_fully_river")

    rivers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var ao: int = int(a.get("ordinal", 0))
        var bo: int = int(b.get("ordinal", 0))
        if ao != bo:
            return ao < bo
        return String(a.get("segment_id", "")) < String(b.get("segment_id", ""))
    )
    bridges.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("id", "")) < String(b.get("id", ""))
    )

    for river: Dictionary in rivers:
        features.append(river.duplicate(true))

    var river_ground: StringName = StringName(area_profile.get("river_ground_semantic", &"ground.water_river"))
    if river_ground == &"":
        return _failure("watercourse_ground_semantic_missing")
    ground_regions.append({
        "id": "%s.ground.river" % request.area_id,
        "semantic": river_ground,
        "rect": request.bounds,
        "priority": 0,
    })

    var bridge_ground: StringName = StringName(environment_profile.get("road_surface_ground", environment_profile.get("road_ground", &"ground.road_plain")))
    if bridge_ground == &"":
        return _failure("watercourse_bridge_ground_semantic_missing")
    for bridge: Dictionary in bridges:
        var segment_id: String = String(bridge.get("river_segment_id", ""))
        if not river_by_segment.has(segment_id):
            return _failure("watercourse_bridge_river_segment_missing")
        var river: Dictionary = river_by_segment[segment_id]
        if String(bridge.get("river_id", "")) != String(river.get("river_id", "")) \
            or int(bridge.get("river_width", 0)) != int(river.get("width", 0)):
            return _failure("watercourse_bridge_river_mismatch")
        var expected_full: Rect2i = _bridge_deck_rect(bridge)
        var expected_clip: Rect2i = _rect_intersection(expected_full, request.bounds)
        var deck_rect: Rect2i = bridge.get("deck_rect", Rect2i())
        if expected_full.size.x <= 0 or expected_clip != deck_rect:
            return _failure("watercourse_bridge_deck_geometry_mismatch")
        if not _rect_covered_by_rivers(deck_rect, rivers):
            return _failure("watercourse_bridge_deck_outside_river")
        features.append(bridge.duplicate(true))
        ground_regions.append({
            "id": "%s.ground.bridge.%s" % [request.area_id, String(bridge.get("id", "bridge"))],
            "semantic": bridge_ground,
            "rect": deck_rect,
            "priority": 100,
        })

    return {
        "ok": true,
        "failure_reason": "",
        "ground_regions": ground_regions,
        "hydrology_features": features,
    }

func _failure(reason: String) -> Dictionary:
    return {
        "ok": false,
        "failure_reason": reason,
        "ground_regions": [],
        "hydrology_features": [],
    }

func _river_record_valid(bounds: Rect2i, river: Dictionary) -> bool:
    if StringName(river.get("kind", &"")) != RIVER_KIND:
        return false
    if String(river.get("segment_id", "")).strip_edges().is_empty() \
        or String(river.get("river_id", "")).strip_edges().is_empty():
        return false
    var start: Vector2i = river.get("start", Vector2i.ZERO)
    var finish: Vector2i = river.get("end", Vector2i.ZERO)
    var width: int = int(river.get("width", 0))
    var corridor: Rect2i = river.get("corridor_rect", Rect2i())
    if start == finish or (start.x != finish.x and start.y != finish.y):
        return false
    if width <= 0 or width % 2 == 0:
        return false
    return corridor.size.x > 0 and corridor.size.y > 0 and _rect_inside(bounds, corridor)

func _bridge_record_structurally_valid(bounds: Rect2i, bridge: Dictionary) -> bool:
    if StringName(bridge.get("kind", &"")) != BRIDGE_KIND:
        return false
    for key: String in ["id", "road_id", "route_id", "river_id", "river_segment_id"]:
        if String(bridge.get(key, "")).strip_edges().is_empty():
            return false
    var axis: StringName = StringName(bridge.get("bridge_axis", &""))
    var road_width: int = int(bridge.get("road_width", 0))
    var river_width: int = int(bridge.get("river_width", 0))
    var deck: Rect2i = bridge.get("deck_rect", Rect2i())
    if axis != &"horizontal" and axis != &"vertical":
        return false
    if road_width <= 0 or road_width % 2 == 0 or river_width <= 0 or river_width % 2 == 0:
        return false
    return deck.size.x > 0 and deck.size.y > 0 and _rect_inside(bounds, deck)

func _request_fully_covered(bounds: Rect2i, rivers: Array[Dictionary]) -> bool:
    for y in range(bounds.position.y, bounds.position.y + bounds.size.y):
        for x in range(bounds.position.x, bounds.position.x + bounds.size.x):
            var cell := Vector2i(x, y)
            var covered: bool = false
            for river: Dictionary in rivers:
                var corridor: Rect2i = river.get("corridor_rect", Rect2i())
                if corridor.has_point(cell):
                    covered = true
                    break
            if not covered:
                return false
    return true

func _rect_covered_by_rivers(rect: Rect2i, rivers: Array[Dictionary]) -> bool:
    if rect.size.x <= 0 or rect.size.y <= 0:
        return false
    for y in range(rect.position.y, rect.position.y + rect.size.y):
        for x in range(rect.position.x, rect.position.x + rect.size.x):
            var cell := Vector2i(x, y)
            var covered: bool = false
            for river: Dictionary in rivers:
                var corridor: Rect2i = river.get("corridor_rect", Rect2i())
                if corridor.has_point(cell):
                    covered = true
                    break
            if not covered:
                return false
    return true

func _bridge_deck_rect(bridge: Dictionary) -> Rect2i:
    var cell: Vector2i = bridge.get("cell", Vector2i.ZERO)
    var axis: StringName = StringName(bridge.get("bridge_axis", &""))
    var road_width: int = int(bridge.get("road_width", 0))
    var river_width: int = int(bridge.get("river_width", 0))
    if road_width <= 0 or river_width <= 0 or road_width % 2 == 0 or river_width % 2 == 0:
        return Rect2i()
    if axis == &"horizontal":
        return Rect2i(
            cell - Vector2i(river_width / 2, road_width / 2),
            Vector2i(river_width, road_width)
        )
    if axis == &"vertical":
        return Rect2i(
            cell - Vector2i(road_width / 2, river_width / 2),
            Vector2i(road_width, river_width)
        )
    return Rect2i()

func _rect_intersection(a: Rect2i, b: Rect2i) -> Rect2i:
    var start_x: int = maxi(a.position.x, b.position.x)
    var start_y: int = maxi(a.position.y, b.position.y)
    var end_x: int = mini(a.position.x + a.size.x, b.position.x + b.size.x)
    var end_y: int = mini(a.position.y + a.size.y, b.position.y + b.size.y)
    if end_x <= start_x or end_y <= start_y:
        return Rect2i()
    return Rect2i(Vector2i(start_x, start_y), Vector2i(end_x - start_x, end_y - start_y))

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var inner_max := inner.position + inner.size - Vector2i.ONE
    return outer.has_point(inner.position) and outer.has_point(inner_max)
