extends RefCounted
class_name LargeFarmhouseBuildingGenerator

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const PlanClass = preload("res://scripts/generation/buildings/GeneratedBuildingPlan.gd")

const ARCHETYPE_ID: StringName = &"residential.house.farm_large"
const ARCHETYPE_VERSION: int = 1
const BASE_WIDTH: int = 25
const BASE_HEIGHT: int = 20
const MAIN_BODY_WIDTH: int = 19
const KITCHEN_WING_HEIGHT: int = 8

func generate(request: BuildingGenerationRequest) -> GeneratedBuildingPlan:
    var plan := PlanClass.new()
    if request == null or not request.is_valid() or request.archetype_id != ARCHETYPE_ID:
        plan.failure_reason = "invalid_large_farmhouse_request"
        return plan
    var expected_frontage: int = _rotate_facing(Facing.Value.NORTH, request.orientation)
    if request.frontage_side != expected_frontage:
        plan.failure_reason = "frontage_incompatible_with_orientation"
        return plan
    var required_size: Vector2i = _rotated_size(request.orientation)
    if request.envelope.size.x < required_size.x or request.envelope.size.y < required_size.y:
        plan.failure_reason = "large_farmhouse_envelope_too_small"
        return plan

    plan.instance_id = request.instance_id
    plan.archetype_id = ARCHETYPE_ID
    plan.archetype_version = ARCHETYPE_VERSION
    plan.seed = request.seed
    plan.orientation = request.orientation
    plan.frontage_side = request.frontage_side
    plan.footprint_rect = Rect2i(request.envelope.position, required_size)

    _add_ground_and_rooms(plan, request)
    _add_exterior_structure(plan, request)
    _add_interior_partitions(plan, request)
    _add_props(plan, request)
    return plan

func _add_ground_and_rooms(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest) -> void:
    var living_rect := Rect2i(1, 1, 6, 5)
    var kitchen_rect := Rect2i(19, 1, 5, 5)
    var bedroom_1_rect := Rect2i(1, 9, 6, 4)
    var bedroom_2_rect := Rect2i(12, 9, 6, 4)
    var bedroom_3_rect := Rect2i(1, 16, 6, 3)
    var bathroom_1_rect := Rect2i(9, 16, 3, 3)
    var bathroom_2_rect := Rect2i(14, 16, 3, 3)
    var rooms: Dictionary = {
        "living_room": [],
        "kitchen": [],
        "bedroom_1": [],
        "bedroom_2": [],
        "bedroom_3": [],
        "bathroom_1": [],
        "bathroom_2": [],
    }
    var bedroom_2_floor: StringName = &"ground.carpet_blue" if absi(request.seed) % 2 == 0 else &"ground.carpet_beige"
    var bedroom_3_floor: StringName = &"ground.carpet_beige" if absi(request.seed) % 2 == 0 else &"ground.carpet_blue"

    for y in range(1, BASE_HEIGHT - 1):
        for x in range(1, MAIN_BODY_WIDTH - 1):
            var local := Vector2i(x, y)
            _ground(plan, request, local, _floor_for(local, living_rect, bedroom_1_rect, bedroom_2_rect, bedroom_3_rect, bathroom_1_rect, bathroom_2_rect, bedroom_2_floor, bedroom_3_floor))
            _append_room_cell(rooms, local, request, living_rect, kitchen_rect, bedroom_1_rect, bedroom_2_rect, bedroom_3_rect, bathroom_1_rect, bathroom_2_rect)

    for y in range(1, KITCHEN_WING_HEIGHT - 1):
        for x in range(MAIN_BODY_WIDTH - 1, BASE_WIDTH - 1):
            var local := Vector2i(x, y)
            _ground(plan, request, local, &"ground.linoleum_yellow" if kitchen_rect.has_point(local) else &"ground.laminate_light")
            _append_room_cell(rooms, local, request, living_rect, kitchen_rect, bedroom_1_rect, bedroom_2_rect, bedroom_3_rect, bathroom_1_rect, bathroom_2_rect)

    for purpose: String in ["living_room", "kitchen", "bedroom_1", "bedroom_2", "bedroom_3", "bathroom_1", "bathroom_2"]:
        plan.rooms.append({"purpose": purpose, "cells": rooms[purpose]})

func _floor_for(
    local: Vector2i,
    living_rect: Rect2i,
    bedroom_1_rect: Rect2i,
    bedroom_2_rect: Rect2i,
    bedroom_3_rect: Rect2i,
    bathroom_1_rect: Rect2i,
    bathroom_2_rect: Rect2i,
    bedroom_2_floor: StringName,
    bedroom_3_floor: StringName
) -> StringName:
    if bathroom_1_rect.has_point(local) or bathroom_2_rect.has_point(local):
        return &"ground.tile_white"
    if bedroom_1_rect.has_point(local):
        return &"ground.carpet_beige"
    if bedroom_2_rect.has_point(local):
        return bedroom_2_floor
    if bedroom_3_rect.has_point(local):
        return bedroom_3_floor
    if living_rect.has_point(local):
        return &"ground.laminate_light"
    return &"ground.laminate_light"

func _append_room_cell(
    rooms: Dictionary,
    local: Vector2i,
    request: BuildingGenerationRequest,
    living_rect: Rect2i,
    kitchen_rect: Rect2i,
    bedroom_1_rect: Rect2i,
    bedroom_2_rect: Rect2i,
    bedroom_3_rect: Rect2i,
    bathroom_1_rect: Rect2i,
    bathroom_2_rect: Rect2i
) -> void:
    var purpose: String = ""
    if living_rect.has_point(local):
        purpose = "living_room"
    elif kitchen_rect.has_point(local):
        purpose = "kitchen"
    elif bedroom_1_rect.has_point(local):
        purpose = "bedroom_1"
    elif bedroom_2_rect.has_point(local):
        purpose = "bedroom_2"
    elif bedroom_3_rect.has_point(local):
        purpose = "bedroom_3"
    elif bathroom_1_rect.has_point(local):
        purpose = "bathroom_1"
    elif bathroom_2_rect.has_point(local):
        purpose = "bathroom_2"
    if not purpose.is_empty():
        (rooms[purpose] as Array).append(_global_cell(local, request))

func _add_exterior_structure(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest) -> void:
    var primary_entry := Vector2i(9, 0)
    var kitchen_entry := Vector2i(24, 4)
    var windows: Dictionary = {
        Vector2i(2, 0): "living_front_left",
        Vector2i(5, 0): "living_front_right",
        Vector2i(13, 0): "hall_front",
        Vector2i(21, 0): "kitchen_front",
        Vector2i(0, 3): "living_side",
        Vector2i(0, 10): "bedroom_1_side",
        Vector2i(0, 17): "bedroom_3_side",
        Vector2i(24, 2): "kitchen_side",
        Vector2i(18, 10): "bedroom_2_notch",
        Vector2i(3, 19): "bedroom_3_rear",
        Vector2i(10, 19): "bathroom_1_rear",
        Vector2i(15, 19): "bathroom_2_rear",
    }
    var boundary: Array = []
    for x in range(BASE_WIDTH):
        boundary.append([Vector2i(x, 0), StructureGeometry.Axis.HORIZONTAL, Facing.Value.NORTH])
    for y in range(1, KITCHEN_WING_HEIGHT - 1):
        boundary.append([Vector2i(BASE_WIDTH - 1, y), StructureGeometry.Axis.VERTICAL, Facing.Value.EAST])
    for x in range(MAIN_BODY_WIDTH, BASE_WIDTH):
        boundary.append([Vector2i(x, KITCHEN_WING_HEIGHT - 1), StructureGeometry.Axis.HORIZONTAL, Facing.Value.SOUTH])
    for y in range(KITCHEN_WING_HEIGHT, BASE_HEIGHT - 1):
        boundary.append([Vector2i(MAIN_BODY_WIDTH - 1, y), StructureGeometry.Axis.VERTICAL, Facing.Value.EAST])
    for x in range(MAIN_BODY_WIDTH):
        boundary.append([Vector2i(x, BASE_HEIGHT - 1), StructureGeometry.Axis.HORIZONTAL, Facing.Value.SOUTH])
    for y in range(1, BASE_HEIGHT - 1):
        boundary.append([Vector2i(0, y), StructureGeometry.Axis.VERTICAL, Facing.Value.WEST])

    var wall_index: int = 1
    var window_index: int = 1
    for value: Variant in boundary:
        var spec: Array = value
        var local: Vector2i = spec[0]
        var axis: int = int(spec[1])
        var facing: int = int(spec[2])
        if local == primary_entry:
            _structure(plan, request, "door.exterior.primary", local, &"door.house", axis, "door", Facing.Value.NORTH)
        elif local == kitchen_entry:
            _structure(plan, request, "door.exterior.kitchen", local, &"door.house", axis, "door", Facing.Value.EAST)
        elif windows.has(local):
            _structure(plan, request, "window.%03d.%s" % [window_index, String(windows[local])], local, &"window.house", axis, "window", facing)
            window_index += 1
        else:
            _structure(plan, request, "wall.exterior.%03d" % wall_index, local, &"wall.plaster", axis, "wall", facing)
            wall_index += 1

func _add_interior_partitions(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest) -> void:
    var wall_index: int = 1
    wall_index = _vertical_partition(plan, request, wall_index, 7, 1, 5, {3: "door.interior.living"})
    wall_index = _horizontal_partition(plan, request, wall_index, 6, 1, 7, {})
    wall_index = _vertical_partition(plan, request, wall_index, 18, 1, 5, {3: "door.interior.kitchen"})
    wall_index = _horizontal_partition(plan, request, wall_index, 6, 18, 23, {})

    wall_index = _horizontal_partition(plan, request, wall_index, 8, 1, 7, {4: "door.interior.bedroom_1"})
    wall_index = _horizontal_partition(plan, request, wall_index, 8, 11, 17, {14: "door.interior.bedroom_2"})
    wall_index = _vertical_partition(plan, request, wall_index, 7, 9, 12, {})
    wall_index = _vertical_partition(plan, request, wall_index, 11, 9, 12, {})
    wall_index = _horizontal_partition(plan, request, wall_index, 13, 1, 7, {})
    wall_index = _horizontal_partition(plan, request, wall_index, 13, 11, 17, {})

    wall_index = _horizontal_partition(plan, request, wall_index, 15, 1, 7, {4: "door.interior.bedroom_3"})
    wall_index = _vertical_partition(plan, request, wall_index, 7, 16, 18, {})
    wall_index = _horizontal_partition(plan, request, wall_index, 15, 8, 12, {10: "door.interior.bathroom_1"})
    wall_index = _vertical_partition(plan, request, wall_index, 8, 16, 18, {})
    wall_index = _vertical_partition(plan, request, wall_index, 12, 16, 18, {})
    wall_index = _horizontal_partition(plan, request, wall_index, 15, 13, 17, {15: "door.interior.bathroom_2"})
    wall_index = _vertical_partition(plan, request, wall_index, 13, 16, 18, {})
    _vertical_partition(plan, request, wall_index, 17, 16, 18, {})

func _horizontal_partition(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest, wall_index: int, y: int, x_from: int, x_to: int, doors: Dictionary) -> int:
    var next_index := wall_index
    for x in range(x_from, x_to + 1):
        var local := Vector2i(x, y)
        if doors.has(x):
            _structure(plan, request, String(doors[x]), local, &"door.house", StructureGeometry.Axis.HORIZONTAL, "door", Facing.Value.SOUTH)
        else:
            _structure(plan, request, "wall.interior.%03d" % next_index, local, &"wall.interior", StructureGeometry.Axis.HORIZONTAL, "wall", Facing.Value.NORTH)
            next_index += 1
    return next_index

func _vertical_partition(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest, wall_index: int, x: int, y_from: int, y_to: int, doors: Dictionary) -> int:
    var next_index := wall_index
    for y in range(y_from, y_to + 1):
        var local := Vector2i(x, y)
        if doors.has(y):
            _structure(plan, request, String(doors[y]), local, &"door.house", StructureGeometry.Axis.VERTICAL, "door", Facing.Value.EAST)
        else:
            _structure(plan, request, "wall.interior.%03d" % next_index, local, &"wall.interior", StructureGeometry.Axis.VERTICAL, "wall", Facing.Value.NORTH)
            next_index += 1
    return next_index

func _add_props(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest) -> void:
    var entries: Array = [
        ["prop.living.sofa", Vector2i(1, 4), &"prop.sofa", Facing.Value.EAST],
        ["prop.living.armchair", Vector2i(6, 4), &"prop.armchair", Facing.Value.WEST],
        ["prop.living.coffee_table", Vector2i(4, 3), &"prop.coffee_table", Facing.Value.NORTH],
        ["prop.kitchen.stove", Vector2i(19, 1), &"prop.stove_range", Facing.Value.SOUTH],
        ["prop.kitchen.fridge", Vector2i(20, 1), &"prop.refrigerator_white", Facing.Value.SOUTH],
        ["prop.kitchen.sink", Vector2i(23, 2), &"prop.kitchen_sink", Facing.Value.WEST],
        ["prop.bedroom_1.bed", Vector2i(1, 10), &"prop.bed_double", Facing.Value.EAST],
        ["prop.bedroom_1.dresser", Vector2i(6, 11), &"prop.dresser_wide", Facing.Value.WEST],
        ["prop.bedroom_2.bed", Vector2i(12, 10), &"prop.bed_double", Facing.Value.EAST],
        ["prop.bedroom_2.dresser", Vector2i(17, 11), &"prop.dresser_wide", Facing.Value.WEST],
        ["prop.bedroom_3.bed", Vector2i(1, 17), &"prop.bed_double", Facing.Value.EAST],
        ["prop.bedroom_3.dresser", Vector2i(6, 17), &"prop.dresser_wide", Facing.Value.WEST],
        ["prop.bathroom_1.toilet", Vector2i(9, 17), &"prop.toilet_modern", Facing.Value.EAST],
        ["prop.bathroom_1.vanity", Vector2i(11, 16), &"prop.bathroom_vanity", Facing.Value.WEST],
        ["prop.bathroom_1.tub", Vector2i(9, 18), &"prop.bathtub_clawfoot", Facing.Value.EAST],
        ["prop.bathroom_2.toilet", Vector2i(14, 17), &"prop.toilet_modern", Facing.Value.EAST],
        ["prop.bathroom_2.vanity", Vector2i(16, 16), &"prop.bathroom_vanity", Facing.Value.WEST],
        ["prop.bathroom_2.tub", Vector2i(14, 18), &"prop.bathtub_clawfoot", Facing.Value.EAST],
    ]
    for entry: Array in entries:
        plan.props.append({
            "role": String(entry[0]),
            "cell": _global_cell(entry[1], request),
            "semantic": entry[2],
            "facing": _rotate_facing(int(entry[3]), request.orientation),
            "blocking": true,
        })

func _ground(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest, local: Vector2i, semantic: StringName) -> void:
    plan.ground_entries.append({"cell": _global_cell(local, request), "semantic": semantic})

func _structure(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest, role: String, local: Vector2i, semantic: StringName, axis: int, kind: String, facing: int) -> void:
    plan.structures.append({
        "role": role,
        "cell": _global_cell(local, request),
        "semantic": semantic,
        "axis": _rotate_axis(axis, request.orientation),
        "kind": kind,
        "facing": _rotate_facing(facing, request.orientation),
    })

func _global_cell(local: Vector2i, request: BuildingGenerationRequest) -> Vector2i:
    return request.envelope.position + _rotate_cell(local, request.orientation)

static func _rotated_size(orientation: int) -> Vector2i:
    if orientation == Facing.Value.EAST or orientation == Facing.Value.WEST:
        return Vector2i(BASE_HEIGHT, BASE_WIDTH)
    return Vector2i(BASE_WIDTH, BASE_HEIGHT)

static func _rotate_cell(cell: Vector2i, orientation: int) -> Vector2i:
    match orientation:
        Facing.Value.NORTH:
            return cell
        Facing.Value.EAST:
            return Vector2i(BASE_HEIGHT - 1 - cell.y, cell.x)
        Facing.Value.SOUTH:
            return Vector2i(BASE_WIDTH - 1 - cell.x, BASE_HEIGHT - 1 - cell.y)
        Facing.Value.WEST:
            return Vector2i(cell.y, BASE_WIDTH - 1 - cell.x)
    return cell

static func _rotate_axis(axis: int, orientation: int) -> int:
    if orientation == Facing.Value.EAST or orientation == Facing.Value.WEST:
        return StructureGeometry.Axis.VERTICAL if axis == StructureGeometry.Axis.HORIZONTAL else StructureGeometry.Axis.HORIZONTAL
    return axis

static func _rotate_facing(facing: int, orientation: int) -> int:
    return (facing + orientation) % 4
