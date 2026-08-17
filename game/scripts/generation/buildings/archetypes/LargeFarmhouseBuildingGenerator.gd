extends RefCounted
class_name LargeFarmhouseBuildingGenerator

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const PlanClass = preload("res://scripts/generation/buildings/GeneratedBuildingPlan.gd")

const ARCHETYPE_ID: StringName = &"residential.house.farm_large"
const ARCHETYPE_VERSION: int = 4
const BASE_WIDTH: int = 21
const BASE_HEIGHT: int = 9

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
    var living_rect := Rect2i(1, 1, 10, 3)
    var kitchen_rect := Rect2i(12, 1, 8, 3)
    var bedroom_1_rect := Rect2i(1, 5, 3, 3)
    var bathroom_1_rect := Rect2i(5, 5, 3, 3)
    var bedroom_2_rect := Rect2i(9, 5, 3, 3)
    var bathroom_2_rect := Rect2i(13, 5, 3, 3)
    var bedroom_3_rect := Rect2i(17, 5, 3, 3)
    var rooms: Dictionary = {
        "living_room": [],
        "kitchen": [],
        "bedroom_1": [],
        "bathroom_1": [],
        "bedroom_2": [],
        "bathroom_2": [],
        "bedroom_3": [],
    }
    var bedroom_2_floor: StringName = &"ground.carpet_blue" if absi(request.seed) % 2 == 0 else &"ground.carpet_beige"
    var bedroom_3_floor: StringName = &"ground.carpet_beige" if absi(request.seed) % 2 == 0 else &"ground.carpet_blue"

    for y in range(1, BASE_HEIGHT - 1):
        for x in range(1, BASE_WIDTH - 1):
            var local := Vector2i(x, y)
            var semantic: StringName = &"ground.laminate_light"
            if kitchen_rect.has_point(local):
                semantic = &"ground.laminate_light" if local.y == 3 else &"ground.linoleum_yellow"
            elif bathroom_1_rect.has_point(local) or bathroom_2_rect.has_point(local):
                semantic = &"ground.tile_white"
            elif bedroom_1_rect.has_point(local):
                semantic = &"ground.carpet_beige"
            elif bedroom_2_rect.has_point(local):
                semantic = bedroom_2_floor
            elif bedroom_3_rect.has_point(local):
                semantic = bedroom_3_floor
            plan.ground_entries.append({"cell": _global_cell(local, request), "semantic": semantic})

            var purpose: String = ""
            if living_rect.has_point(local):
                purpose = "living_room"
            elif kitchen_rect.has_point(local):
                purpose = "kitchen"
            elif bedroom_1_rect.has_point(local):
                purpose = "bedroom_1"
            elif bathroom_1_rect.has_point(local):
                purpose = "bathroom_1"
            elif bedroom_2_rect.has_point(local):
                purpose = "bedroom_2"
            elif bathroom_2_rect.has_point(local):
                purpose = "bathroom_2"
            elif bedroom_3_rect.has_point(local):
                purpose = "bedroom_3"
            if not purpose.is_empty():
                (rooms[purpose] as Array).append(_global_cell(local, request))

    for purpose: String in ["living_room", "kitchen", "bedroom_1", "bathroom_1", "bedroom_2", "bathroom_2", "bedroom_3"]:
        plan.rooms.append({"purpose": purpose, "cells": rooms[purpose]})

func _add_exterior_structure(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest) -> void:
    var primary_entry := Vector2i(5, 0)
    var kitchen_entry := Vector2i(20, 2)
    var windows: Dictionary = {
        Vector2i(2, 0): "living_front_left",
        Vector2i(8, 0): "living_front_right",
        Vector2i(14, 0): "kitchen_front_left",
        Vector2i(18, 0): "kitchen_front_right",
        Vector2i(0, 2): "living_side",
        Vector2i(20, 1): "kitchen_side",
        Vector2i(2, 8): "bedroom_1_rear",
        Vector2i(6, 8): "bathroom_1_rear",
        Vector2i(10, 8): "bedroom_2_rear",
        Vector2i(14, 8): "bathroom_2_rear",
        Vector2i(18, 8): "bedroom_3_rear",
    }
    var wall_index: int = 1
    var window_index: int = 1
    for y in range(BASE_HEIGHT):
        for x in range(BASE_WIDTH):
            if x != 0 and x != BASE_WIDTH - 1 and y != 0 and y != BASE_HEIGHT - 1:
                continue
            var local := Vector2i(x, y)
            var axis: int = StructureGeometry.Axis.HORIZONTAL if y == 0 or y == BASE_HEIGHT - 1 else StructureGeometry.Axis.VERTICAL
            var facing: int = _boundary_facing(local)
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
    for y in range(1, 3):
        _structure(plan, request, "wall.interior.%03d" % wall_index, Vector2i(11, y), &"wall.interior", StructureGeometry.Axis.VERTICAL, "wall", Facing.Value.NORTH)
        wall_index += 1

    var private_doors: Dictionary = {
        2: "door.interior.bedroom_1",
        6: "door.interior.bathroom_1",
        10: "door.interior.bedroom_2",
        14: "door.interior.bathroom_2",
        18: "door.interior.bedroom_3",
    }
    for x in range(1, 20):
        var local := Vector2i(x, 4)
        if private_doors.has(x):
            _structure(plan, request, String(private_doors[x]), local, &"door.house", StructureGeometry.Axis.HORIZONTAL, "door", Facing.Value.SOUTH)
        else:
            _structure(plan, request, "wall.interior.%03d" % wall_index, local, &"wall.interior", StructureGeometry.Axis.HORIZONTAL, "wall", Facing.Value.NORTH)
            wall_index += 1

    for partition_x in [4, 8, 12, 16]:
        for y in range(5, 8):
            _structure(plan, request, "wall.interior.%03d" % wall_index, Vector2i(partition_x, y), &"wall.interior", StructureGeometry.Axis.VERTICAL, "wall", Facing.Value.NORTH)
            wall_index += 1

func _add_props(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest) -> void:
    var entries: Array = [
        ["prop.living.bookshelf", Vector2i(1, 1), &"prop.bookshelf_tall", Facing.Value.SOUTH, true],
        ["prop.living.end_table", Vector2i(2, 1), &"prop.end_table", Facing.Value.SOUTH, true],
        ["prop.living.coffee_table", Vector2i(2, 2), &"prop.coffee_table", Facing.Value.SOUTH, true],
        ["prop.living.sofa", Vector2i(1, 3), &"prop.sofa", Facing.Value.EAST, true],
        ["prop.living.armchair", Vector2i(3, 3), &"prop.armchair", Facing.Value.WEST, true],
        ["prop.living.entry_rug", Vector2i(5, 1), &"prop.rug", Facing.Value.SOUTH, false],
        ["prop.kitchen.stove", Vector2i(12, 1), &"prop.stove_range", Facing.Value.SOUTH, true],
        ["prop.kitchen.fridge", Vector2i(13, 1), &"prop.refrigerator_white", Facing.Value.SOUTH, true],
        ["prop.kitchen.counter", Vector2i(14, 1), &"prop.counter_straight", Facing.Value.SOUTH, true],
        ["prop.kitchen.sink", Vector2i(15, 1), &"prop.kitchen_sink", Facing.Value.SOUTH, true],
        ["prop.kitchen.chair", Vector2i(17, 2), &"prop.dining_chair", Facing.Value.EAST, true],
        ["prop.kitchen.table", Vector2i(18, 2), &"prop.breakfast_table", Facing.Value.WEST, true],
        ["prop.bedroom_1.bed", Vector2i(1, 6), &"prop.bed_double", Facing.Value.EAST, true],
        ["prop.bedroom_1.dresser", Vector2i(3, 6), &"prop.dresser_wide", Facing.Value.WEST, true],
        ["prop.bathroom_1.toilet", Vector2i(5, 6), &"prop.toilet_modern", Facing.Value.EAST, true],
        ["prop.bathroom_1.vanity", Vector2i(7, 6), &"prop.bathroom_vanity", Facing.Value.WEST, true],
        ["prop.bathroom_1.tub", Vector2i(5, 7), &"prop.bathtub_clawfoot", Facing.Value.EAST, true],
        ["prop.bedroom_2.bed", Vector2i(9, 6), &"prop.bed_double", Facing.Value.EAST, true],
        ["prop.bedroom_2.dresser", Vector2i(11, 6), &"prop.dresser_wide", Facing.Value.WEST, true],
        ["prop.bathroom_2.toilet", Vector2i(13, 6), &"prop.toilet_modern", Facing.Value.EAST, true],
        ["prop.bathroom_2.vanity", Vector2i(15, 6), &"prop.bathroom_vanity", Facing.Value.WEST, true],
        ["prop.bathroom_2.tub", Vector2i(13, 7), &"prop.bathtub_clawfoot", Facing.Value.EAST, true],
        ["prop.bedroom_3.bed", Vector2i(17, 6), &"prop.bed_double", Facing.Value.EAST, true],
        ["prop.bedroom_3.dresser", Vector2i(19, 6), &"prop.dresser_wide", Facing.Value.WEST, true],
    ]
    for entry: Array in entries:
        plan.props.append({
            "role": String(entry[0]),
            "cell": _global_cell(entry[1], request),
            "semantic": entry[2],
            "facing": _rotate_facing(int(entry[3]), request.orientation),
            "blocking": bool(entry[4]),
        })

func _structure(
    plan: GeneratedBuildingPlan,
    request: BuildingGenerationRequest,
    role: String,
    local: Vector2i,
    semantic: StringName,
    axis: int,
    kind: String,
    facing: int
) -> void:
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

static func _boundary_facing(local: Vector2i) -> int:
    if local.y == 0:
        return Facing.Value.NORTH
    if local.x == BASE_WIDTH - 1:
        return Facing.Value.EAST
    if local.y == BASE_HEIGHT - 1:
        return Facing.Value.SOUTH
    return Facing.Value.WEST