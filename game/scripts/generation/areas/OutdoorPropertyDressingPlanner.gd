extends RefCounted
class_name OutdoorPropertyDressingPlanner

const Seed = preload("res://scripts/generation/areas/AreaSeed.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

func plan(
    request: AreaGenerationRequest,
    environment: Dictionary,
    roads: Array[Dictionary],
    intersections: Array[Dictionary],
    parcels: Array[Dictionary]
) -> Dictionary:
    var ground_regions: Array[Dictionary] = []
    var props: Array[Dictionary] = []
    if request == null or environment.is_empty():
        return {"ok": false, "failure_reason": "invalid_outdoor_dressing_input", "ground_regions": ground_regions, "props": props}

    ground_regions.append({
        "id": "%s.ground.base" % request.area_id,
        "semantic": environment.get("base_ground", &"ground.grass_lush"),
        "rect": request.bounds,
        "priority": 0,
    })

    for road: Dictionary in roads:
        ground_regions.append({
            "id": "%s.ground.road.%s" % [request.area_id, String(road.get("road_id", ""))],
            "semantic": environment.get("road_ground", &"ground.road"),
            "cells": (road.get("corridor_cells", []) as Array).duplicate(),
            "priority": 100,
        })

    for parcel: Dictionary in parcels:
        var driveway: Array = parcel.get("driveway_cells", [])
        if not driveway.is_empty():
            ground_regions.append({
                "id": "%s.ground.driveway" % String(parcel.get("id", "parcel")),
                "semantic": environment.get("driveway_ground", &"ground.driveway_gravel"),
                "cells": driveway.duplicate(),
                "priority": 90,
            })
        var land_use: StringName = StringName(parcel.get("land_use", &""))
        if land_use == &"farmstead" or land_use == &"agricultural":
            var field_rect: Rect2i = _field_rect(parcel)
            var building_envelope: Rect2i = parcel.get("building_envelope", Rect2i())
            if field_rect.size.x > 0 and field_rect.size.y > 0 and not _rects_intersect(field_rect, building_envelope):
                parcel["field_rect"] = field_rect
                ground_regions.append({
                    "id": "%s.ground.field" % String(parcel.get("id", "parcel")),
                    "semantic": environment.get("field_ground", &"ground.field_green"),
                    "rect": field_rect,
                    "priority": 40,
                })

    var blocked: Dictionary = _blocked_cells(roads, parcels)
    _add_signal_prop(request, environment, intersections, props, blocked)
    _add_parcel_props(request, environment, parcels, props, blocked)
    return {"ok": true, "failure_reason": "", "ground_regions": ground_regions, "props": props}

func _add_signal_prop(
    request: AreaGenerationRequest,
    environment: Dictionary,
    intersections: Array[Dictionary],
    props: Array[Dictionary],
    blocked: Dictionary
) -> void:
    for intersection: Dictionary in intersections:
        if StringName(intersection.get("control", &"")) != &"signalized":
            continue
        var center: Vector2i = intersection.get("cell", Vector2i.ZERO)
        var candidates: Array[Vector2i] = [
            center + Vector2i(3, 3),
            center + Vector2i(-3, 3),
            center + Vector2i(3, -3),
            center + Vector2i(-3, -3),
        ]
        for cell: Vector2i in candidates:
            if not request.bounds.has_point(cell) or blocked.has(cell):
                continue
            _append_prop(
                props,
                blocked,
                "%s.prop.traffic_signal" % String(intersection.get("id", "intersection")),
                StringName(environment.get("traffic_signal_semantic", &"prop.traffic_light")),
                cell,
                Facing.Value.SOUTH
            )
            return

func _add_parcel_props(
    request: AreaGenerationRequest,
    environment: Dictionary,
    parcels: Array[Dictionary],
    props: Array[Dictionary],
    blocked: Dictionary
) -> void:
    var tree_semantics: Array = environment.get("tree_semantics", [])
    for parcel: Dictionary in parcels:
        var land_use: StringName = StringName(parcel.get("land_use", &""))
        if land_use == &"residential" or land_use == &"farmstead":
            var mailbox: Vector2i = _mailbox_cell(parcel)
            if request.bounds.has_point(mailbox) and not blocked.has(mailbox):
                _append_prop(
                    props,
                    blocked,
                    "%s.prop.mailbox" % String(parcel.get("id", "parcel")),
                    StringName(environment.get("mailbox_semantic", &"prop.curb_mailbox")),
                    mailbox,
                    int(parcel.get("frontage_side", Facing.Value.SOUTH))
                )
        if land_use == &"farmstead":
            _add_farm_boundary(parcel, environment, props, blocked)
        elif land_use == &"residential" and not tree_semantics.is_empty():
            var tree_cell: Vector2i = _back_corner_cell(parcel)
            if request.bounds.has_point(tree_cell) and not blocked.has(tree_cell):
                var tree_index: int = Seed.choose_index(request.seed, "tree:%s" % String(parcel.get("id", "")), tree_semantics.size())
                _append_prop(
                    props,
                    blocked,
                    "%s.prop.tree" % String(parcel.get("id", "parcel")),
                    StringName(tree_semantics[tree_index]),
                    tree_cell,
                    Facing.Value.SOUTH
                )

func _add_farm_boundary(
    parcel: Dictionary,
    environment: Dictionary,
    props: Array[Dictionary],
    blocked: Dictionary
) -> void:
    var rect: Rect2i = parcel.get("rect", Rect2i())
    var frontage: int = int(parcel.get("frontage_side", Facing.Value.SOUTH))
    var cells: Array[Vector2i] = _back_edge_cells(rect, frontage)
    var ordinal: int = 0
    for index in range(0, cells.size(), 6):
        var cell: Vector2i = cells[index]
        if blocked.has(cell):
            continue
        _append_prop(
            props,
            blocked,
            "%s.prop.fence.%02d" % [String(parcel.get("id", "parcel")), ordinal],
            StringName(environment.get("fence_semantic", &"prop.wood_fence")),
            cell,
            Facing.Value.SOUTH
        )
        ordinal += 1

func _append_prop(
    props: Array[Dictionary],
    blocked: Dictionary,
    id: String,
    semantic: StringName,
    cell: Vector2i,
    facing: int
) -> void:
    if blocked.has(cell):
        return
    blocked[cell] = true
    props.append({"id": id, "semantic": semantic, "cell": cell, "facing": facing})

func _blocked_cells(roads: Array[Dictionary], parcels: Array[Dictionary]) -> Dictionary:
    var blocked: Dictionary = {}
    for road: Dictionary in roads:
        for value: Variant in road.get("corridor_cells", []):
            blocked[value] = true
    for parcel: Dictionary in parcels:
        for value: Variant in parcel.get("driveway_cells", []):
            blocked[value] = true
        var envelope: Rect2i = parcel.get("building_envelope", Rect2i())
        if envelope.size.x > 0 and envelope.size.y > 0:
            for y in range(envelope.position.y, envelope.position.y + envelope.size.y):
                for x in range(envelope.position.x, envelope.position.x + envelope.size.x):
                    blocked[Vector2i(x, y)] = true
    return blocked

func _field_rect(parcel: Dictionary) -> Rect2i:
    var rect: Rect2i = parcel.get("rect", Rect2i())
    var frontage: int = int(parcel.get("frontage_side", Facing.Value.SOUTH))
    var frontage_depth: int = rect.size.y if frontage == Facing.Value.NORTH or frontage == Facing.Value.SOUTH else rect.size.x
    var depth: int = mini(8, maxi(4, int(frontage_depth / 3)))
    match frontage:
        Facing.Value.NORTH:
            return Rect2i(Vector2i(rect.position.x + 2, rect.position.y + rect.size.y - depth - 2), Vector2i(rect.size.x - 4, depth))
        Facing.Value.SOUTH:
            return Rect2i(rect.position + Vector2i(2, 2), Vector2i(rect.size.x - 4, depth))
        Facing.Value.WEST:
            return Rect2i(Vector2i(rect.position.x + rect.size.x - depth - 2, rect.position.y + 2), Vector2i(depth, rect.size.y - 4))
        Facing.Value.EAST:
            return Rect2i(rect.position + Vector2i(2, 2), Vector2i(depth, rect.size.y - 4))
    return Rect2i()

func _mailbox_cell(parcel: Dictionary) -> Vector2i:
    var cell: Vector2i = parcel.get("parcel_access_cell", Vector2i(-1, -1))
    var frontage: int = int(parcel.get("frontage_side", Facing.Value.SOUTH))
    if frontage == Facing.Value.NORTH or frontage == Facing.Value.SOUTH:
        cell.x += 2
    else:
        cell.y += 2
    return cell

func _back_corner_cell(parcel: Dictionary) -> Vector2i:
    var rect: Rect2i = parcel.get("rect", Rect2i())
    var frontage: int = int(parcel.get("frontage_side", Facing.Value.SOUTH))
    match frontage:
        Facing.Value.NORTH:
            return Vector2i(rect.position.x + 2, rect.position.y + rect.size.y - 3)
        Facing.Value.SOUTH:
            return rect.position + Vector2i(2, 2)
        Facing.Value.WEST:
            return Vector2i(rect.position.x + rect.size.x - 3, rect.position.y + 2)
        Facing.Value.EAST:
            return rect.position + Vector2i(2, 2)
    return rect.position

func _back_edge_cells(rect: Rect2i, frontage: int) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    match frontage:
        Facing.Value.NORTH:
            for x in range(rect.position.x + 2, rect.position.x + rect.size.x - 2):
                result.append(Vector2i(x, rect.position.y + rect.size.y - 2))
        Facing.Value.SOUTH:
            for x in range(rect.position.x + 2, rect.position.x + rect.size.x - 2):
                result.append(Vector2i(x, rect.position.y + 1))
        Facing.Value.WEST:
            for y in range(rect.position.y + 2, rect.position.y + rect.size.y - 2):
                result.append(Vector2i(rect.position.x + rect.size.x - 2, y))
        Facing.Value.EAST:
            for y in range(rect.position.y + 2, rect.position.y + rect.size.y - 2):
                result.append(Vector2i(rect.position.x + 1, y))
    return result

func _rects_intersect(a: Rect2i, b: Rect2i) -> bool:
    if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0:
        return false
    return a.position.x < b.position.x + b.size.x \
        and a.position.x + a.size.x > b.position.x \
        and a.position.y < b.position.y + b.size.y \
        and a.position.y + a.size.y > b.position.y
