extends RefCounted
class_name GasStationBuildingGenerator

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const PlanClass = preload("res://scripts/generation/buildings/GeneratedBuildingPlan.gd")

const ARCHETYPE_ID: StringName = &"commercial.gas_station.small"
const ARCHETYPE_VERSION: int = 1
const BASE_WIDTH: int = 19
const BASE_HEIGHT: int = 15
const CANONICAL_FRONTAGE: int = Facing.Value.SOUTH

func generate(request: BuildingGenerationRequest) -> GeneratedBuildingPlan:
    var plan := PlanClass.new()
    if request == null or not request.is_valid() or request.archetype_id != ARCHETYPE_ID:
        plan.failure_reason = "invalid_gas_station_request"
        return plan
    var expected_frontage: int = _rotate_facing(CANONICAL_FRONTAGE, request.orientation)
    if request.frontage_side != expected_frontage:
        plan.failure_reason = "frontage_incompatible_with_orientation"
        return plan
    var required_size: Vector2i = _rotated_size(request.orientation)
    if request.envelope.size.x < required_size.x or request.envelope.size.y < required_size.y:
        plan.failure_reason = "gas_station_envelope_too_small"
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
        "storage": [],
        "office": [],
        "bathroom": [],
        "sales_floor": [],
    }

    _add_room_rect(plan, rooms, request, "storage", Rect2i(1, 1, 5, 3), &"ground.warehouse_floor")
    _add_room_rect(plan, rooms, request, "office", Rect2i(7, 1, 4, 3), &"ground.office_carpet")
    _add_room_rect(plan, rooms, request, "bathroom", Rect2i(12, 1, 3, 3), &"ground.tile_mosaic")
    _add_room_rect(plan, rooms, request, "sales_floor", Rect2i(1, 5, 17, 4), &"ground.shop_floor")
    _add_room_rect(plan, rooms, request, "sales_floor", Rect2i(16, 1, 2, 4), &"ground.shop_floor")

    _ground(plan, request, Vector2i(3, 0), &"ground.warehouse_floor")
    _ground(plan, request, Vector2i(3, 4), &"ground.shop_floor")
    _ground(plan, request, Vector2i(9, 4), &"ground.shop_floor")
    _ground(plan, request, Vector2i(13, 4), &"ground.shop_floor")
    _ground(plan, request, Vector2i(9, 9), &"ground.shop_floor")

    for x in range(BASE_WIDTH):
        _ground(plan, request, Vector2i(x, 10), &"ground.concrete_clean")
    for y in range(11, BASE_HEIGHT):
        for x in range(BASE_WIDTH):
            _ground(plan, request, Vector2i(x, y), &"ground.parking_faded")

    for purpose: String in ["storage", "office", "bathroom", "sales_floor"]:
        plan.rooms.append({"purpose": purpose, "cells": rooms[purpose]})

func _add_structure(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest) -> void:
    var primary_entry := Vector2i(9, 9)
    var service_entry := Vector2i(3, 0)

    for x in range(BASE_WIDTH):
        var local := Vector2i(x, 0)
        if local == service_entry:
            _structure(plan, request, "door.exterior.service", local, &"door.store", StructureGeometry.Axis.HORIZONTAL, "door", Facing.Value.NORTH)
        elif x == 9:
            _structure(plan, request, "window.back.office", local, &"window.office", StructureGeometry.Axis.HORIZONTAL, "window", Facing.Value.NORTH)
        elif x == 13:
            _structure(plan, request, "window.back.bathroom", local, &"window.store", StructureGeometry.Axis.HORIZONTAL, "window", Facing.Value.NORTH)
        else:
            _structure(plan, request, "wall.exterior.%02d_%02d" % [x, 0], local, &"wall.white_brick", StructureGeometry.Axis.HORIZONTAL, "wall", Facing.Value.NORTH)

    for y in range(1, 9):
        var west := Vector2i(0, y)
        var east := Vector2i(18, y)
        if y == 6:
            _structure(plan, request, "window.side.west", west, &"window.store", StructureGeometry.Axis.VERTICAL, "window", Facing.Value.WEST)
            _structure(plan, request, "window.side.east", east, &"window.store", StructureGeometry.Axis.VERTICAL, "window", Facing.Value.EAST)
        else:
            _structure(plan, request, "wall.exterior.%02d_%02d" % [0, y], west, &"wall.white_brick", StructureGeometry.Axis.VERTICAL, "wall", Facing.Value.WEST)
            _structure(plan, request, "wall.exterior.%02d_%02d" % [18, y], east, &"wall.white_brick", StructureGeometry.Axis.VERTICAL, "wall", Facing.Value.EAST)

    var front_windows: Dictionary = {
        2: true,
        4: true,
        6: true,
        12: true,
        14: true,
        16: true,
    }
    for x in range(BASE_WIDTH):
        var local := Vector2i(x, 9)
        if local == primary_entry:
            _structure(plan, request, "door.exterior.primary", local, &"door.storefront", StructureGeometry.Axis.HORIZONTAL, "door", Facing.Value.SOUTH)
        elif front_windows.has(x):
            _structure(plan, request, "window.front.%02d" % x, local, &"window.storefront", StructureGeometry.Axis.HORIZONTAL, "window", Facing.Value.SOUTH)
        else:
            _structure(plan, request, "wall.exterior.%02d_%02d" % [x, 9], local, &"wall.storefront", StructureGeometry.Axis.HORIZONTAL, "wall", Facing.Value.SOUTH)

    for y in range(1, 4):
        _interior_wall(plan, request, Vector2i(6, y), StructureGeometry.Axis.VERTICAL)
        _interior_wall(plan, request, Vector2i(11, y), StructureGeometry.Axis.VERTICAL)
        _interior_wall(plan, request, Vector2i(15, y), StructureGeometry.Axis.VERTICAL)

    for x in range(1, 16):
        var local := Vector2i(x, 4)
        if x == 3:
            _interior_door(plan, request, "door.interior.storage", local, &"door.commercial", StructureGeometry.Axis.HORIZONTAL, Facing.Value.SOUTH)
        elif x == 9:
            _interior_door(plan, request, "door.interior.office", local, &"door.office", StructureGeometry.Axis.HORIZONTAL, Facing.Value.SOUTH)
        elif x == 13:
            _interior_door(plan, request, "door.interior.bathroom", local, &"door.commercial", StructureGeometry.Axis.HORIZONTAL, Facing.Value.SOUTH)
        else:
            _interior_wall(plan, request, local, StructureGeometry.Axis.HORIZONTAL)

func _add_props(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest) -> void:
    var entries: Array = [
        ["prop.storage.rack_left", Vector2i(1, 1), &"prop.warehouse_rack", Facing.Value.SOUTH, true],
        ["prop.storage.rack_right", Vector2i(5, 1), &"prop.warehouse_rack", Facing.Value.SOUTH, true],
        ["prop.storage.pallet_left", Vector2i(1, 3), &"prop.pallet_stack", Facing.Value.EAST, true],
        ["prop.storage.pallet_right", Vector2i(5, 3), &"prop.pallet_stack", Facing.Value.WEST, true],
        ["prop.storage.tool_cabinet", Vector2i(5, 2), &"prop.tool_cabinet", Facing.Value.WEST, true],

        ["prop.office.desk", Vector2i(8, 1), &"prop.office_desk", Facing.Value.SOUTH, true],
        ["prop.office.chair", Vector2i(8, 2), &"prop.office_chair", Facing.Value.NORTH, true],
        ["prop.office.file_cabinet", Vector2i(10, 1), &"prop.file_cabinet_tall", Facing.Value.SOUTH, true],
        ["prop.office.copier", Vector2i(10, 3), &"prop.copier", Facing.Value.NORTH, true],

        ["prop.bathroom.toilet", Vector2i(12, 1), &"prop.toilet_modern", Facing.Value.SOUTH, true],
        ["prop.bathroom.sink", Vector2i(14, 1), &"prop.pedestal_sink", Facing.Value.SOUTH, true],
        ["prop.bathroom.towel_rack", Vector2i(14, 3), &"prop.towel_rack", Facing.Value.NORTH, true],

        ["prop.sales.cooler_1", Vector2i(16, 1), &"prop.walkin_cooler", Facing.Value.SOUTH, true],
        ["prop.sales.cooler_2", Vector2i(17, 1), &"prop.walkin_cooler", Facing.Value.SOUTH, true],
        ["prop.sales.cooler_3", Vector2i(17, 3), &"prop.walkin_cooler", Facing.Value.WEST, true],

        ["prop.sales.checkout", Vector2i(12, 8), &"prop.checkout", Facing.Value.SOUTH, true],
        ["prop.sales.checkout_counter", Vector2i(13, 8), &"prop.counter_straight", Facing.Value.SOUTH, true],
        ["prop.sales.aisle_1_shelf_1", Vector2i(3, 6), &"prop.retail_shelf", Facing.Value.SOUTH, true],
        ["prop.sales.aisle_1_shelf_2", Vector2i(4, 6), &"prop.retail_shelf", Facing.Value.SOUTH, true],
        ["prop.sales.aisle_1_endcap", Vector2i(5, 6), &"prop.retail_endcap", Facing.Value.WEST, true],
        ["prop.sales.aisle_2_shelf_1", Vector2i(7, 6), &"prop.retail_shelf", Facing.Value.SOUTH, true],
        ["prop.sales.aisle_2_shelf_2", Vector2i(8, 6), &"prop.retail_shelf", Facing.Value.SOUTH, true],
        ["prop.sales.aisle_2_endcap", Vector2i(9, 6), &"prop.retail_endcap", Facing.Value.WEST, true],
        ["prop.sales.chest_freezer", Vector2i(16, 6), &"prop.chest_freezer", Facing.Value.WEST, true],
        ["prop.sales.vending", Vector2i(17, 7), &"prop.vending_machine", Facing.Value.WEST, true],

        ["prop.forecourt.pump_left_1", Vector2i(5, 12), &"prop.gas_pump", Facing.Value.SOUTH, true],
        ["prop.forecourt.pump_left_2", Vector2i(6, 12), &"prop.gas_pump", Facing.Value.SOUTH, true],
        ["prop.forecourt.pump_right_1", Vector2i(12, 12), &"prop.gas_pump", Facing.Value.SOUTH, true],
        ["prop.forecourt.pump_right_2", Vector2i(13, 12), &"prop.gas_pump", Facing.Value.SOUTH, true],
        ["prop.forecourt.sign", Vector2i(1, 13), &"prop.gas_sign", Facing.Value.SOUTH, true],
        ["prop.forecourt.ice_box", Vector2i(16, 10), &"prop.ice_box", Facing.Value.SOUTH, true],
        ["prop.forecourt.vending", Vector2i(17, 10), &"prop.vending_machine", Facing.Value.SOUTH, true],
        ["prop.forecourt.trash", Vector2i(15, 10), &"prop.public_trash_bin", Facing.Value.SOUTH, true],
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

func _interior_wall(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest, local: Vector2i, axis: int) -> void:
    _structure(plan, request, "wall.interior.%02d_%02d" % [local.x, local.y], local, &"wall.interior", axis, "wall", Facing.Value.NORTH)

func _interior_door(
    plan: GeneratedBuildingPlan,
    request: BuildingGenerationRequest,
    role: String,
    local: Vector2i,
    semantic: StringName,
    axis: int,
    facing: int
) -> void:
    _structure(plan, request, role, local, semantic, axis, "door", facing)

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
