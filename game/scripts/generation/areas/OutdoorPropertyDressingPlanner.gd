extends RefCounted
class_name OutdoorPropertyDressingPlanner

const Seed = preload("res://scripts/generation/areas/AreaSeed.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const NaturalEcology = preload("res://scripts/generation/shared/NaturalEcologyField.gd")

func plan(
    request: AreaGenerationRequest,
    environment: Dictionary,
    roads: Array[Dictionary],
    intersections: Array[Dictionary],
    parcels: Array[Dictionary],
    reservations: Array[Dictionary] = [],
    include_natural_noise: bool = true
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

    _add_road_ground_regions(request, environment, roads, intersections, ground_regions)

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
    _block_reservations(blocked, reservations)
    _add_signal_prop(request, environment, intersections, props, blocked)
    _add_parcel_props(request, environment, parcels, props, blocked)
    if include_natural_noise:
        _add_natural_noise(request, environment, roads, intersections, parcels, props, blocked)
    return {"ok": true, "failure_reason": "", "ground_regions": ground_regions, "props": props}

func _add_road_ground_regions(
    request: AreaGenerationRequest,
    environment: Dictionary,
    roads: Array[Dictionary],
    intersections: Array[Dictionary],
    ground_regions: Array[Dictionary]
) -> void:
    for road: Dictionary in roads:
        var road_id: String = String(road.get("road_id", "road"))
        var surface_family: StringName = StringName(road.get("surface_family", &"paved_centerline"))
        var surface_semantic: StringName = StringName(environment.get("road_surface_ground", environment.get("road_ground", &"ground.road_plain")))
        if surface_family == &"rural_gravel":
            surface_semantic = StringName(environment.get("local_road_ground", &"ground.gravel_dark"))
        ground_regions.append({
            "id": "%s.ground.road.%s.surface" % [request.area_id, road_id],
            "semantic": surface_semantic,
            "cells": (road.get("corridor_cells", []) as Array).duplicate(),
            "priority": 100,
        })

        if not bool(road.get("paint_centerline", false)):
            continue
        var line_groups: Dictionary = _centerline_cells_by_axis(road, intersections)
        var horizontal: Array = line_groups.get(&"horizontal", [])
        if not horizontal.is_empty():
            ground_regions.append({
                "id": "%s.ground.road.%s.centerline_h" % [request.area_id, road_id],
                "semantic": environment.get("road_centerline_horizontal", &"ground.road_yellow_line_h"),
                "cells": horizontal.duplicate(),
                "priority": 110,
            })
        var vertical: Array = line_groups.get(&"vertical", [])
        if not vertical.is_empty():
            ground_regions.append({
                "id": "%s.ground.road.%s.centerline_v" % [request.area_id, road_id],
                "semantic": environment.get("road_centerline_vertical", &"ground.road_yellow_line_v"),
                "cells": vertical.duplicate(),
                "priority": 110,
            })

func _centerline_cells_by_axis(road: Dictionary, intersections: Array[Dictionary]) -> Dictionary:
    var horizontal: Array[Vector2i] = []
    var vertical: Array[Vector2i] = []
    var path: Array = road.get("path_cells", [])
    var road_id: String = String(road.get("road_id", ""))
    var intersection_clearance: int = int(road.get("width", 1)) / 2 + 1
    var explicit_axis: StringName = StringName(road.get("axis", &""))
    for index in range(path.size()):
        var cell: Vector2i = path[index]
        if _near_road_intersection(cell, road_id, intersections, intersection_clearance):
            continue
        var axis: StringName = explicit_axis
        if axis != &"horizontal" and axis != &"vertical":
            axis = _path_axis(path, index)
        if axis == &"horizontal":
            horizontal.append(cell)
        elif axis == &"vertical":
            vertical.append(cell)
    return {&"horizontal": horizontal, &"vertical": vertical}

func _path_axis(path: Array, index: int) -> StringName:
    var cell: Vector2i = path[index]
    var before: Vector2i = cell
    var after: Vector2i = cell
    if index > 0:
        before = path[index - 1]
    if index + 1 < path.size():
        after = path[index + 1]
    if before.y == cell.y and after.y == cell.y:
        return &"horizontal"
    if before.x == cell.x and after.x == cell.x:
        return &"vertical"
    if after != cell:
        return &"horizontal" if after.y == cell.y else &"vertical"
    if before != cell:
        return &"horizontal" if before.y == cell.y else &"vertical"
    return &""

func _near_road_intersection(
    cell: Vector2i,
    road_id: String,
    intersections: Array[Dictionary],
    clearance: int
) -> bool:
    for intersection: Dictionary in intersections:
        var ids: Array = intersection.get("road_ids", [])
        if not ids.has(road_id):
            continue
        var center: Vector2i = intersection.get("cell", Vector2i(-999999, -999999))
        if absi(cell.x - center.x) + absi(cell.y - center.y) <= clearance:
            return true
    return false

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

func _add_natural_noise(
    request: AreaGenerationRequest,
    environment: Dictionary,
    roads: Array[Dictionary],
    intersections: Array[Dictionary],
    parcels: Array[Dictionary],
    props: Array[Dictionary],
    blocked: Dictionary
) -> void:
    var trees: Array = environment.get("tree_semantics", [])
    var shrubs: Array = environment.get("shrub_semantics", [])
    var rocks: Array = environment.get("rock_semantics", [])
    if trees.is_empty() or shrubs.is_empty() or rocks.is_empty():
        return

    var base_density: float = clampf(float(environment.get("natural_noise_density", 0.0105)), 0.0, 1.0)
    var patch_scale: int = maxi(4, int(environment.get("natural_noise_patch_scale", 22)))
    var sparse_multiplier: float = maxf(0.0, float(environment.get("natural_noise_sparse_multiplier", 0.20)))
    var dense_multiplier: float = maxf(sparse_multiplier, float(environment.get("natural_noise_dense_multiplier", 2.25)))
    var natural_blocked: Dictionary = blocked.duplicate()
    _reserve_natural_road_halo(roads, parcels, int(environment.get("natural_road_clearance", 1)), natural_blocked, request.bounds)
    var use_inherited_ecology: bool = request.inherited_ecology_seed != null
    var ecology_seed: int = int(request.inherited_ecology_seed) if use_inherited_ecology else request.seed

    var ordinal: int = 0
    for y in range(request.bounds.position.y, request.bounds.position.y + request.bounds.size.y):
        for x in range(request.bounds.position.x, request.bounds.position.x + request.bounds.size.x):
            var cell := Vector2i(x, y)
            if not _natural_cell_allowed(request, environment, intersections, parcels, natural_blocked, cell):
                continue

            if use_inherited_ecology:
                var shared_semantic: StringName = NaturalEcology.semantic_at(environment, ecology_seed, cell)
                if shared_semantic == &"":
                    continue
                _append_prop(
                    props,
                    natural_blocked,
                    "%s.prop.natural.%04d" % [request.area_id, ordinal],
                    shared_semantic,
                    cell,
                    Facing.Value.SOUTH
                )
                ordinal += 1
                continue

            var local_cell: Vector2i = cell - request.bounds.position
            var patch_noise: float = _value_noise_2d(request.seed, local_cell, patch_scale, 401)
            var local_density: float = base_density * lerpf(sparse_multiplier, dense_multiplier, patch_noise)
            var cell_noise: float = Seed.unit_2d(request.seed, cell.x, cell.y, 503)
            if cell_noise >= local_density:
                continue

            var family_noise: float = _value_noise_2d(request.seed, local_cell, patch_scale * 2, 607)
            var family: int = 0
            if family_noise >= 0.78:
                family = 2
            elif family_noise >= 0.43:
                family = 1
            var semantic: StringName = _natural_semantic_at(request.seed, cell, family, trees, shrubs, rocks)
            if semantic == &"":
                continue

            _append_prop(
                props,
                natural_blocked,
                "%s.prop.natural.%04d" % [request.area_id, ordinal],
                semantic,
                cell,
                Facing.Value.SOUTH
            )
            ordinal += 1

func _value_noise_2d(seed: int, local_cell: Vector2i, scale: int, salt: int) -> float:
    var safe_scale: int = maxi(1, scale)
    var grid_x: int = floori(float(local_cell.x) / float(safe_scale))
    var grid_y: int = floori(float(local_cell.y) / float(safe_scale))
    var frac_x: float = float(local_cell.x - grid_x * safe_scale) / float(safe_scale)
    var frac_y: float = float(local_cell.y - grid_y * safe_scale) / float(safe_scale)
    var smooth_x: float = frac_x * frac_x * (3.0 - 2.0 * frac_x)
    var smooth_y: float = frac_y * frac_y * (3.0 - 2.0 * frac_y)

    var n00: float = Seed.unit_2d(seed, grid_x, grid_y, salt)
    var n10: float = Seed.unit_2d(seed, grid_x + 1, grid_y, salt)
    var n01: float = Seed.unit_2d(seed, grid_x, grid_y + 1, salt)
    var n11: float = Seed.unit_2d(seed, grid_x + 1, grid_y + 1, salt)
    var top: float = lerpf(n00, n10, smooth_x)
    var bottom: float = lerpf(n01, n11, smooth_x)
    return lerpf(top, bottom, smooth_y)

func _natural_cell_allowed(
    request: AreaGenerationRequest,
    environment: Dictionary,
    intersections: Array[Dictionary],
    parcels: Array[Dictionary],
    blocked: Dictionary,
    cell: Vector2i
) -> bool:
    if not request.bounds.has_point(cell) or blocked.has(cell):
        return false
    var center_clear_radius: int = int(environment.get("natural_center_clear_radius", 0))
    if center_clear_radius > 0:
        for intersection: Dictionary in intersections:
            if StringName(intersection.get("control", &"")) != &"signalized":
                continue
            var center: Vector2i = intersection.get("cell", Vector2i.ZERO)
            if absi(cell.x - center.x) + absi(cell.y - center.y) < center_clear_radius:
                return false
    for parcel: Dictionary in parcels:
        var rect: Rect2i = parcel.get("rect", Rect2i())
        if not rect.has_point(cell):
            continue
        var land_use: StringName = StringName(parcel.get("land_use", &""))
        return land_use == &"wilderness" or land_use == &"vacant"
    return true

func _natural_semantic_at(
    seed: int,
    cell: Vector2i,
    family: int,
    trees: Array,
    shrubs: Array,
    rocks: Array
) -> StringName:
    var roll: int = Seed.hash_2d(seed, cell.x, cell.y, 709) % 10
    var source: Array = trees
    match family:
        0:
            source = trees if roll < 7 else (shrubs if roll < 9 else rocks)
        1:
            source = shrubs if roll < 7 else (trees if roll < 9 else rocks)
        _:
            source = rocks if roll < 6 else (shrubs if roll < 8 else trees)
    if source.is_empty():
        return &""
    var index: int = Seed.hash_2d(seed, cell.x, cell.y, 811) % source.size()
    return StringName(source[index])

func _reserve_natural_road_halo(
    roads: Array[Dictionary],
    parcels: Array[Dictionary],
    clearance: int,
    blocked: Dictionary,
    bounds: Rect2i
) -> void:
    var radius: int = maxi(0, clearance)
    for road: Dictionary in roads:
        for value: Variant in road.get("corridor_cells", []):
            var road_cell: Vector2i = value
            for dy in range(-radius, radius + 1):
                for dx in range(-radius, radius + 1):
                    var cell := road_cell + Vector2i(dx, dy)
                    if bounds.has_point(cell):
                        blocked[cell] = true
    for parcel: Dictionary in parcels:
        for value: Variant in parcel.get("driveway_cells", []):
            var driveway_cell: Vector2i = value
            for dy in range(-radius, radius + 1):
                for dx in range(-radius, radius + 1):
                    var cell := driveway_cell + Vector2i(dx, dy)
                    if bounds.has_point(cell):
                        blocked[cell] = true

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
            _block_rect(blocked, envelope)
        var field_rect: Rect2i = parcel.get("field_rect", Rect2i())
        if field_rect.size.x > 0 and field_rect.size.y > 0:
            _block_rect(blocked, field_rect)
    return blocked

func _block_reservations(blocked: Dictionary, reservations: Array[Dictionary]) -> void:
    for reservation: Dictionary in reservations:
        var rect: Rect2i = reservation.get("rect", Rect2i())
        if rect.size.x <= 0 or rect.size.y <= 0:
            continue
        _block_rect(blocked, rect)

func _block_rect(blocked: Dictionary, rect: Rect2i) -> void:
    for y in range(rect.position.y, rect.position.y + rect.size.y):
        for x in range(rect.position.x, rect.position.x + rect.size.x):
            blocked[Vector2i(x, y)] = true

func _field_rect(parcel: Dictionary) -> Rect2i:
    var rect: Rect2i = parcel.get("rect", Rect2i())
    var envelope: Rect2i = parcel.get("building_envelope", Rect2i())
    var frontage: int = int(parcel.get("frontage_side", Facing.Value.SOUTH))
    var inner_left: int = rect.position.x + 2
    var inner_top: int = rect.position.y + 2
    var inner_right: int = rect.position.x + rect.size.x - 2
    var inner_bottom: int = rect.position.y + rect.size.y - 2
    var desired_depth: int = 8
    var gap: int = 1

    match frontage:
        Facing.Value.NORTH:
            var start_y: int = inner_top
            if envelope.size.x > 0 and envelope.size.y > 0:
                start_y = maxi(start_y, envelope.position.y + envelope.size.y + gap)
            var depth_north: int = mini(desired_depth, inner_bottom - start_y)
            if depth_north < 4 or inner_right - inner_left < 4:
                return Rect2i()
            return Rect2i(Vector2i(inner_left, start_y), Vector2i(inner_right - inner_left, depth_north))
        Facing.Value.SOUTH:
            var end_y: int = inner_bottom
            if envelope.size.x > 0 and envelope.size.y > 0:
                end_y = mini(end_y, envelope.position.y - gap)
            var depth_south: int = mini(desired_depth, end_y - inner_top)
            if depth_south < 4 or inner_right - inner_left < 4:
                return Rect2i()
            return Rect2i(Vector2i(inner_left, end_y - depth_south), Vector2i(inner_right - inner_left, depth_south))
        Facing.Value.WEST:
            var start_x: int = inner_left
            if envelope.size.x > 0 and envelope.size.y > 0:
                start_x = maxi(start_x, envelope.position.x + envelope.size.x + gap)
            var depth_west: int = mini(desired_depth, inner_right - start_x)
            if depth_west < 4 or inner_bottom - inner_top < 4:
                return Rect2i()
            return Rect2i(Vector2i(start_x, inner_top), Vector2i(depth_west, inner_bottom - inner_top))
        Facing.Value.EAST:
            var end_x: int = inner_right
            if envelope.size.x > 0 and envelope.size.y > 0:
                end_x = mini(end_x, envelope.position.x - gap)
            var depth_east: int = mini(desired_depth, end_x - inner_left)
            if depth_east < 4 or inner_bottom - inner_top < 4:
                return Rect2i()
            return Rect2i(Vector2i(end_x - depth_east, inner_top), Vector2i(depth_east, inner_bottom - inner_top))
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
