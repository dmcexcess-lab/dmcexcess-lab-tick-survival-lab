extends RefCounted
class_name CompactLaundryHouseBuildingGenerator

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const PlanClass = preload("res://scripts/generation/buildings/GeneratedBuildingPlan.gd")

const ARCHETYPE_ID: StringName = &"residential.house.compact_laundry"
const ARCHETYPE_VERSION: int = 1
const BASE_WIDTH: int = 17
const BASE_HEIGHT: int = 13
const CANONICAL_FRONTAGE: int = Facing.Value.SOUTH

func generate(request: BuildingGenerationRequest) -> GeneratedBuildingPlan:
    var plan := PlanClass.new()
    if request == null or not request.is_valid() or request.archetype_id != ARCHETYPE_ID:
        plan.failure_reason = "invalid_compact_laundry_house_request"
        return plan
    var expected_frontage: int = _rotate_facing(CANONICAL_FRONTAGE, request.orientation)
    if request.frontage_side != expected_frontage:
        plan.failure_reason = "frontage_incompatible_with_orientation"
        return plan
    var required_size: Vector2i = _rotated_size(request.orientation)
    if request.envelope.size.x < required_size.x or request.envelope.size.y < required_size.y:
        plan.failure_reason = "compact_laundry_house_envelope_too_small"
        return plan

    plan.instance_id = request.instance_id
    plan.archetype_id = ARCHETYPE_ID
    plan.archetype_version = ARCHETYPE_VERSION
    plan.seed = request.seed
    plan.orientation = request.orientation
    plan.frontage_side = request.frontage_side
    plan.footprint_rect = Rect2i(request.envelope.position, required_size)

    _add_ground_and_rooms(plan, request)
    _add_structure(plan, request)
    _add_props(plan, request)
    return plan

func _add_ground_and_rooms(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest) -> void:
    var rooms: Dictionary = {
        "bedroom_1": [],
        "kitchen": [],
        "laundry": [],
        "bathroom": [],
        "living_room": [],
        "entry": [],
        "bedroom_2": [],
    }

    _add_room_rect(plan, rooms, request, "bedroom_1", Rect2i(1, 1, 4, 4), &"ground.carpet_beige")
    _add_room_rect(plan, rooms, request, "kitchen", Rect2i(6, 1, 6, 4), &"ground.tile_white")
    _add_room_rect(plan, rooms, request, "laundry", Rect2i(13, 1, 3, 3), &"ground.laminate_dark")
    _add_room_rect(plan, rooms, request, "bathroom", Rect2i(13, 5, 3, 3), &"ground.tile_mosaic")
    _add_room_rect(plan, rooms, request, "living_room", Rect2i(4, 6, 8, 2), &"ground.laminate_dark")
    _add_room_rect(plan, rooms, request, "living_room", Rect2i(4, 8, 7, 3), &"ground.laminate_dark")
    _add_room_rect(plan, rooms, request, "entry", Rect2i(6, 11, 3, 1), &"ground.laminate_dark")
    _add_room_rect(plan, rooms, request, "bedroom_2", Rect2i(12, 9, 4, 3), &"ground.carpet_blue")

    _ground(plan, request, Vector2i(4, 5), &"ground.laminate_dark")
    _ground(plan, request, Vector2i(7, 5), &"ground.laminate_dark")
    _ground(plan, request, Vector2i(8, 5), &"ground.laminate_dark")
    _ground(plan, request, Vector2i(12, 2), &"ground.tile_white")
    _ground(plan, request, Vector2i(12, 6), &"ground.tile_mosaic")
    _ground(plan, request, Vector2i(11, 9), &"ground.laminate_dark")
    _ground(plan, request, Vector2i(7, 12), &"ground.laminate_dark")

    for purpose: String in ["bedroom_1", "kitchen", "laundry", "bathroom", "living_room", "entry", "bedroom_2"]:
        plan.rooms.append({"purpose": purpose, "cells": rooms[purpose]})

func _add_structure(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest) -> void:
    var windows: Dictionary = {
        Vector2i(2, 0): "bedroom_1_north",
        Vector2i(8, 0): "kitchen_north_left",
        Vector2i(10, 0): "kitchen_north_right",
        Vector2i(14, 0): "laundry_north",
        Vector2i(0, 2): "bedroom_1_west",
        Vector2i(3, 8): "living_west",
        Vector2i(16, 6): "bathroom_east",
        Vector2i(16, 10): "bedroom_2_east",
        Vector2i(4, 11): "living_south",
        Vector2i(14, 12): "bedroom_2_south",
    }
    var primary_entry := Vector2i(7, 12)

    for x in range(BASE_WIDTH):
        _exterior(plan, request, Vector2i(x, 0), StructureGeometry.Axis.HORIZONTAL, Facing.Value.NORTH, windows, primary_entry)
    for y in range(1, 6):
        _exterior(plan, request, Vector2i(0, y), StructureGeometry.Axis.VERTICAL, Facing.Value.WEST, windows, primary_entry)
    for x in range(1, 4):
        _exterior(plan, request, Vector2i(x, 5), StructureGeometry.Axis.HORIZONTAL, Facing.Value.SOUTH, windows, primary_entry)
    for y in range(6, 12):
        _exterior(plan, request, Vector2i(3, y), StructureGeometry.Axis.VERTICAL, Facing.Value.WEST, windows, primary_entry)
    for x in [4, 5, 9, 10]:
        _exterior(plan, request, Vector2i(x, 11), StructureGeometry.Axis.HORIZONTAL, Facing.Value.SOUTH, windows, primary_entry)
    for x in range(5, 10):
        _exterior(plan, request, Vector2i(x, 12), StructureGeometry.Axis.HORIZONTAL, Facing.Value.SOUTH, windows, primary_entry)
    for x in range(11, 17):
        _exterior(plan, request, Vector2i(x, 12), StructureGeometry.Axis.HORIZONTAL, Facing.Value.SOUTH, windows, primary_entry)
    for y in range(1, 12):
        _exterior(plan, request, Vector2i(16, y), StructureGeometry.Axis.VERTICAL, Facing.Value.EAST, windows, primary_entry)

    for y in range(1, 5):
        _interior_wall(plan, request, Vector2i(5, y), StructureGeometry.Axis.VERTICAL)
    _interior_door(plan, request, "door.interior.bedroom_1", Vector2i(4, 5), StructureGeometry.Axis.HORIZONTAL, Facing.Value.SOUTH)
    _interior_wall(plan, request, Vector2i(5, 5), StructureGeometry.Axis.HORIZONTAL)
    _interior_wall(plan, request, Vector2i(6, 5), StructureGeometry.Axis.HORIZONTAL)
    for x in [9, 10, 11]:
        _interior_wall(plan, request, Vector2i(x, 5), StructureGeometry.Axis.HORIZONTAL)

    _interior_wall(plan, request, Vector2i(12, 1), StructureGeometry.Axis.VERTICAL)
    _interior_door(plan, request, "door.interior.laundry", Vector2i(12, 2), StructureGeometry.Axis.VERTICAL, Facing.Value.EAST)
    _interior_wall(plan, request, Vector2i(12, 3), StructureGeometry.Axis.VERTICAL)
    for x in range(12, 16):
        _interior_wall(plan, request, Vector2i(x, 4), StructureGeometry.Axis.HORIZONTAL)

    _interior_wall(plan, request, Vector2i(12, 5), StructureGeometry.Axis.VERTICAL)
    _interior_door(plan, request, "door.interior.bathroom", Vector2i(12, 6), StructureGeometry.Axis.VERTICAL, Facing.Value.EAST)
    _interior_wall(plan, request, Vector2i(12, 7), StructureGeometry.Axis.VERTICAL)
    for x in range(11, 16):
        _interior_wall(plan, request, Vector2i(x, 8), StructureGeometry.Axis.HORIZONTAL)

    _interior_door(plan, request, "door.interior.bedroom_2", Vector2i(11, 9), StructureGeometry.Axis.VERTICAL, Facing.Value.EAST)
    _interior_wall(plan, request, Vector2i(11, 10), StructureGeometry.Axis.VERTICAL)
    _interior_wall(plan, request, Vector2i(11, 11), StructureGeometry.Axis.VERTICAL)

func _add_props(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest) -> void:
    var entries: Array = [
        ["prop.bedroom_1.bed", Vector2i(1, 2), &"prop.bed_single", Facing.Value.EAST, true],
        ["prop.bedroom_1.nightstand", Vector2i(4, 1), &"prop.nightstand", Facing.Value.SOUTH, true],
        ["prop.bedroom_1.wardrobe", Vector2i(4, 3), &"prop.wardrobe", Facing.Value.WEST, true],
        ["prop.bedroom_1.rug", Vector2i(2, 4), &"prop.rug", Facing.Value.SOUTH, false],

        ["prop.kitchen.fridge", Vector2i(6, 1), &"prop.refrigerator_white", Facing.Value.SOUTH, true],
        ["prop.kitchen.counter_1", Vector2i(7, 1), &"prop.counter_straight", Facing.Value.SOUTH, true],
        ["prop.kitchen.sink", Vector2i(8, 1), &"prop.kitchen_sink", Facing.Value.SOUTH, true],
        ["prop.kitchen.counter_2", Vector2i(9, 1), &"prop.counter_straight", Facing.Value.SOUTH, true],
        ["prop.kitchen.stove", Vector2i(10, 1), &"prop.stove_range", Facing.Value.SOUTH, true],
        ["prop.kitchen.pantry", Vector2i(11, 1), &"prop.pantry", Facing.Value.SOUTH, true],
        ["prop.kitchen.table", Vector2i(8, 3), &"prop.breakfast_table", Facing.Value.SOUTH, true],
        ["prop.kitchen.chair", Vector2i(9, 3), &"prop.dining_chair", Facing.Value.WEST, true],

        ["prop.laundry.washer", Vector2i(13, 1), &"prop.washer_front", Facing.Value.SOUTH, true],
        ["prop.laundry.dryer", Vector2i(14, 1), &"prop.dryer_front", Facing.Value.SOUTH, true],
        ["prop.laundry.utility_sink", Vector2i(13, 3), &"prop.utility_sink", Facing.Value.NORTH, true],
        ["prop.laundry.hamper", Vector2i(15, 3), &"prop.hamper", Facing.Value.WEST, true],

        ["prop.bathroom.toilet", Vector2i(13, 5), &"prop.toilet_modern", Facing.Value.SOUTH, true],
        ["prop.bathroom.vanity", Vector2i(15, 5), &"prop.bathroom_vanity", Facing.Value.WEST, true],
        ["prop.bathroom.shower", Vector2i(15, 7), &"prop.shower_stall", Facing.Value.NORTH, true],
        ["prop.bathroom.rug", Vector2i(14, 6), &"prop.rug", Facing.Value.SOUTH, false],

        ["prop.living.bookshelf", Vector2i(4, 7), &"prop.bookshelf_tall", Facing.Value.EAST, true],
        ["prop.living.tv_stand", Vector2i(4, 9), &"prop.tv_stand", Facing.Value.EAST, true],
        ["prop.living.sofa", Vector2i(9, 8), &"prop.sofa", Facing.Value.WEST, true],
        ["prop.living.coffee_table", Vector2i(7, 8), &"prop.coffee_table", Facing.Value.WEST, true],
        ["prop.living.armchair", Vector2i(8, 10), &"prop.armchair", Facing.Value.NORTH, true],
        ["prop.living.end_table", Vector2i(9, 9), &"prop.end_table", Facing.Value.WEST, true],
        ["prop.living.rug", Vector2i(7, 9), &"prop.rug", Facing.Value.SOUTH, false],

        ["prop.bedroom_2.bed", Vector2i(15, 10), &"prop.bed_double", Facing.Value.WEST, true],
        ["prop.bedroom_2.dresser", Vector2i(13, 11), &"prop.dresser_wide", Facing.Value.NORTH, true],
        ["prop.bedroom_2.nightstand", Vector2i(15, 11), &"prop.nightstand", Facing.Value.WEST, true],
        ["prop.bedroom_2.rug", Vector2i(14, 9), &"prop.rug", Facing.Value.SOUTH, false],

        ["prop.entry.table", Vector2i(8, 11), &"prop.end_table", Facing.Value.WEST, true],
        ["prop.entry.rug", Vector2i(7, 11), &"prop.rug", Facing.Value.SOUTH, false],
    ]
    for entry: Array in entries:
        plan.props.append({
            "role": String(entry[0]),
            "cell": _global_cell(entry[1], request),
            "semantic": entry[2],
            "facing": _rotate_facing(int(entry[3]), request.orientation),
            "blocking": bool(entry[4]),
        })

func _add_room_rect(
    plan: GeneratedBuildingPlan,
    rooms: Dictionary,
    request: BuildingGenerationRequest,
    purpose: String,
    rect: Rect2i,
    semantic: StringName
) -> void:
    var end_x: int = rect.position.x + rect.size.x
    var end_y: int = rect.position.y + rect.size.y
    for y in range(rect.position.y, end_y):
        for x in range(rect.position.x, end_x):
            var local := Vector2i(x, y)
            var global_cell := _global_cell(local, request)
            plan.ground_entries.append({"cell": global_cell, "semantic": semantic})
            (rooms[purpose] as Array).append(global_cell)

func _ground(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest, local: Vector2i, semantic: StringName) -> void:
    plan.ground_entries.append({"cell": _global_cell(local, request), "semantic": semantic})

func _exterior(
    plan: GeneratedBuildingPlan,
    request: BuildingGenerationRequest,
    local: Vector2i,
    axis: int,
    facing: int,
    windows: Dictionary,
    primary_entry: Vector2i
) -> void:
    if local == primary_entry:
        _structure(plan, request, "door.exterior.primary", local, &"door.house", axis, "door", Facing.Value.SOUTH)
        return
    if windows.has(local):
        _structure(
            plan,
            request,
            "window.%02d_%02d.%s" % [local.x, local.y, String(windows[local])],
            local,
            &"window.house",
            axis,
            "window",
            facing
        )
        return
    _structure(
        plan,
        request,
        "wall.exterior.%02d_%02d" % [local.x, local.y],
        local,
        &"wall.plaster",
        axis,
        "wall",
        facing
    )

func _interior_wall(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest, local: Vector2i, axis: int) -> void:
    _structure(
        plan,
        request,
        "wall.interior.%02d_%02d" % [local.x, local.y],
        local,
        &"wall.interior",
        axis,
        "wall",
        Facing.Value.NORTH
    )

func _interior_door(
    plan: GeneratedBuildingPlan,
    request: BuildingGenerationRequest,
    role: String,
    local: Vector2i,
    axis: int,
    facing: int
) -> void:
    _structure(plan, request, role, local, &"door.house", axis, "door", facing)

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
