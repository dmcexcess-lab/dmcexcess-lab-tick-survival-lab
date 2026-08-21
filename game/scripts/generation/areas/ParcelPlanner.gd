extends RefCounted
class_name ParcelPlanner

const Seed = preload("res://scripts/generation/areas/AreaSeed.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

func plan(
    request: AreaGenerationRequest,
    profile: Dictionary,
    roads: Array[Dictionary],
    intersections: Array[Dictionary]
) -> Dictionary:
    var parcels: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty() or roads.is_empty() or intersections.is_empty():
        return {"ok": false, "failure_reason": "invalid_parcel_planner_input", "parcels": parcels}

    var center: Vector2i = intersections[0].get("cell", request.bounds.get_center())
    for road: Dictionary in roads:
        _append_road_frontage_parcels(request, profile, road, center, parcels)

    if parcels.size() < int(profile.get("commercial_count", 0)) + int(profile.get("residential_count", 0)) + int(profile.get("farmstead_count", 0)):
        return {"ok": false, "failure_reason": "insufficient_rural_parcel_candidates", "parcels": parcels}

    _classify_land_use(request.seed, profile, center, parcels)
    return {"ok": true, "failure_reason": "", "parcels": parcels}

func _append_road_frontage_parcels(
    request: AreaGenerationRequest,
    profile: Dictionary,
    road: Dictionary,
    center: Vector2i,
    parcels: Array[Dictionary]
) -> void:
    var road_class: StringName = road.get("road_class", &"")
    var depth: int = int(profile.get("primary_parcel_depth", 28)) if road_class == &"primary" else int(profile.get("secondary_parcel_depth", 32))
    var radius: int = int(profile.get("center_exclusion_radius", 30))
    var edge_margin: int = int(profile.get("edge_margin", 8))
    var road_id: String = String(road.get("road_id", ""))
    var width: int = int(road.get("width", 1))
    var half_width: int = width / 2
    var gap_from_road: int = 2
    var spans: Array[Vector2i] = []

    if StringName(road.get("axis", &"")) == &"horizontal":
        spans.append(Vector2i(request.bounds.position.x + edge_margin, center.x - radius - 1))
        spans.append(Vector2i(center.x + radius + 1, request.bounds.position.x + request.bounds.size.x - edge_margin - 1))
        for side: StringName in [&"north", &"south"]:
            for span: Vector2i in spans:
                var segment_rects: Array[Rect2i] = _segment_rects(request, profile, road_id, side, span.x, span.y, true, depth)
                for rect: Rect2i in segment_rects:
                    var y: int
                    var frontage: int
                    if side == &"north":
                        var bottom: int = int(road.get("start", Vector2i.ZERO).y) - half_width - gap_from_road - 1
                        y = bottom - depth + 1
                        frontage = Facing.Value.SOUTH
                    else:
                        y = int(road.get("start", Vector2i.ZERO).y) + half_width + gap_from_road + 1
                        frontage = Facing.Value.NORTH
                    var placed := Rect2i(Vector2i(rect.position.x, y), Vector2i(rect.size.x, depth))
                    _try_append_parcel(request, road, side, frontage, placed, center, parcels)
        return

    spans.append(Vector2i(request.bounds.position.y + edge_margin, center.y - radius - 1))
    spans.append(Vector2i(center.y + radius + 1, request.bounds.position.y + request.bounds.size.y - edge_margin - 1))
    for side: StringName in [&"west", &"east"]:
        for span: Vector2i in spans:
            var segment_rects: Array[Rect2i] = _segment_rects(request, profile, road_id, side, span.x, span.y, false, depth)
            for rect: Rect2i in segment_rects:
                var x: int
                var frontage: int
                if side == &"west":
                    var right: int = int(road.get("start", Vector2i.ZERO).x) - half_width - gap_from_road - 1
                    x = right - depth + 1
                    frontage = Facing.Value.EAST
                else:
                    x = int(road.get("start", Vector2i.ZERO).x) + half_width + gap_from_road + 1
                    frontage = Facing.Value.WEST
                var placed := Rect2i(Vector2i(x, rect.position.y), Vector2i(depth, rect.size.y))
                _try_append_parcel(request, road, side, frontage, placed, center, parcels)

func _segment_rects(
    request: AreaGenerationRequest,
    profile: Dictionary,
    road_id: String,
    side: StringName,
    span_start: int,
    span_end: int,
    horizontal: bool,
    depth: int
) -> Array[Rect2i]:
    var result: Array[Rect2i] = []
    var minimum: int = int(profile.get("frontage_min", 28))
    var maximum: int = int(profile.get("frontage_max", 36))
    var gap: int = int(profile.get("parcel_gap", 3))
    var cursor: int = span_start
    var ordinal: int = 0
    while cursor + minimum - 1 <= span_end:
        var remaining: int = span_end - cursor + 1
        var domain: String = "parcel_width:%s:%s:%d:%d" % [road_id, String(side), cursor, ordinal]
        var width: int = minimum + Seed.choose_index(request.seed, domain, maximum - minimum + 1)
        if width > remaining:
            if remaining < minimum:
                break
            width = remaining
        if horizontal:
            result.append(Rect2i(Vector2i(cursor, 0), Vector2i(width, depth)))
        else:
            result.append(Rect2i(Vector2i(0, cursor), Vector2i(depth, width)))
        cursor += width + gap
        ordinal += 1
    return result

func _try_append_parcel(
    request: AreaGenerationRequest,
    road: Dictionary,
    side: StringName,
    frontage: int,
    rect: Rect2i,
    center: Vector2i,
    parcels: Array[Dictionary]
) -> void:
    if not _rect_inside(request.bounds, rect):
        return
    for forbidden: Rect2i in request.forbidden_regions:
        if _rects_intersect(rect, forbidden):
            return
    for existing: Dictionary in parcels:
        if _rects_intersect(rect, existing.get("rect", Rect2i())):
            return
    var shrink: int = 2
    var buildable := Rect2i(
        rect.position + Vector2i(shrink, shrink),
        rect.size - Vector2i(shrink * 2, shrink * 2)
    )
    var center_cell := Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2)
    var role: String = "%s.%s.%d.%d" % [String(road.get("road_id", "road")), String(side), rect.position.x, rect.position.y]
    parcels.append({
        "id": "%s.parcel.%s" % [request.area_id, role],
        "rect": rect,
        "buildable_rect": buildable,
        "land_use": &"unclassified",
        "frontage_road_id": String(road.get("road_id", "")),
        "frontage_road_class": StringName(road.get("road_class", &"")),
        "frontage_side": frontage,
        "side": side,
        "distance_to_center": absi(center_cell.x - center.x) + absi(center_cell.y - center.y),
        "access_cell": Vector2i(-1, -1),
        "parcel_access_cell": Vector2i(-1, -1),
        "driveway_cells": [],
        "building_archetype_id": &"",
        "building_envelope": Rect2i(),
        "building_entry_cell": Vector2i(-1, -1),
    })

func _classify_land_use(seed: int, profile: Dictionary, center: Vector2i, parcels: Array[Dictionary]) -> void:
    parcels.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var da: int = int(a.get("distance_to_center", 0))
        var db: int = int(b.get("distance_to_center", 0))
        if da != db:
            return da < db
        return String(a.get("id", "")) < String(b.get("id", ""))
    )

    var commercial_target: int = int(profile.get("commercial_count", 3))
    var commercial_used: int = 0
    for parcel: Dictionary in parcels:
        if commercial_used >= commercial_target:
            break
        if StringName(parcel.get("frontage_road_class", &"")) != &"primary":
            continue
        parcel["land_use"] = &"commercial_small"
        commercial_used += 1

    var residential_target: int = int(profile.get("residential_count", 6))
    var residential_used: int = 0
    for parcel: Dictionary in parcels:
        if residential_used >= residential_target:
            break
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        parcel["land_use"] = &"residential"
        residential_used += 1

    var farmstead_target: int = int(profile.get("farmstead_count", 4))
    var farmstead_used: int = 0
    for index in range(parcels.size() - 1, -1, -1):
        if farmstead_used >= farmstead_target:
            break
        var parcel: Dictionary = parcels[index]
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        parcel["land_use"] = &"farmstead"
        farmstead_used += 1

    if commercial_used != commercial_target or residential_used != residential_target or farmstead_used != farmstead_target:
        return

    for parcel: Dictionary in parcels:
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        var choice: int = Seed.choose_index(seed, "open_land:%s" % String(parcel.get("id", "")), 3)
        match choice:
            0:
                parcel["land_use"] = &"agricultural"
            1:
                parcel["land_use"] = &"vacant"
            _:
                parcel["land_use"] = &"wilderness"

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var inner_max := Vector2i(inner.position.x + inner.size.x - 1, inner.position.y + inner.size.y - 1)
    return outer.has_point(inner.position) and outer.has_point(inner_max)

func _rects_intersect(a: Rect2i, b: Rect2i) -> bool:
    if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0:
        return false
    return a.position.x < b.position.x + b.size.x \
        and a.position.x + a.size.x > b.position.x \
        and a.position.y < b.position.y + b.size.y \
        and a.position.y + a.size.y > b.position.y
