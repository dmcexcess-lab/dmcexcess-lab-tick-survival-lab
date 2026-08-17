extends RefCounted
class_name TrailerBuildingGenerator

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const PlanClass = preload("res://scripts/generation/buildings/GeneratedBuildingPlan.gd")

const ARCHETYPE_ID: StringName = &"residential.trailer.singlewide"
const ARCHETYPE_VERSION: int = 2
const BASE_WIDTH: int = 5
const BASE_HEIGHT: int = 12

func generate(request: BuildingGenerationRequest) -> GeneratedBuildingPlan:
    var plan := PlanClass.new()
    if request == null or not request.is_valid() or request.archetype_id != ARCHETYPE_ID:
        plan.failure_reason = "invalid_trailer_request"
        return plan
    var expected_frontage: int = _rotate_facing(Facing.Value.EAST, request.orientation)
    if request.frontage_side != expected_frontage:
        plan.failure_reason = "frontage_incompatible_with_orientation"
        return plan
    var required_size: Vector2i = _rotated_size(request.orientation)
    if request.envelope.size.x < required_size.x or request.envelope.size.y < required_size.y:
        plan.failure_reason = "trailer_envelope_too_small"
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
    _add_partitions(plan, request)
    _add_props(plan, request)
    return plan

func _add_ground_and_rooms(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest) -> void:
    var living_cells: Array[Vector2i] = []
    var bath_cells: Array[Vector2i] = []
    var bed_cells: Array[Vector2i] = []
    var bedroom_floor: StringName = &"ground.carpet_blue" if absi(request.seed) % 2 == 0 else &"ground.carpet_beige"
    for y in range(1, 5):
        for x in range(1, 4):
            var cell: Vector2i = _global_cell(Vector2i(x, y), request)
            living_cells.append(cell)
            plan.ground_entries.append({"cell": cell, "semantic": &"ground.linoleum_green"})
    for y in range(6, 8):
        for x in range(1, 4):
            var cell: Vector2i = _global_cell(Vector2i(x, y), request)
            bath_cells.append(cell)
            plan.ground_entries.append({"cell": cell, "semantic": &"ground.tile_white"})
    for y in range(9, 11):
        for x in range(1, 4):
            var cell: Vector2i = _global_cell(Vector2i(x, y), request)
            bed_cells.append(cell)
            plan.ground_entries.append({"cell": cell, "semantic": bedroom_floor})
    plan.rooms.append({"purpose": "living_kitchen", "cells": living_cells})
    plan.rooms.append({"purpose": "bathroom", "cells": bath_cells})
    plan.rooms.append({"purpose": "bedroom", "cells": bed_cells})

func _add_exterior_structure(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest) -> void:
    var entry := Vector2i(4, 3)
    var windows: Dictionary = {
        Vector2i(0, 2): "living_west",
        Vector2i(4, 1): "living_east",
        Vector2i(0, 9): "bedroom_west",
        Vector2i(4, 10): "bedroom_east",
    }
    var wall_index: int = 1
    var window_index: int = 1
    for y in range(BASE_HEIGHT):
        for x in range(BASE_WIDTH):
            if x != 0 and x != BASE_WIDTH - 1 and y != 0 and y != BASE_HEIGHT - 1:
                continue
            var local := Vector2i(x, y)
            var axis: int = StructureGeometry.Axis.HORIZONTAL if y == 0 or y == BASE_HEIGHT - 1 else StructureGeometry.Axis.VERTICAL
            if local == entry:
                _structure(plan, request, "door.exterior.primary", local, &"door.rural_wood", axis, "door", Facing.Value.EAST)
            elif windows.has(local):
                _structure(plan, request, "window.%03d.%s" % [window_index, String(windows[local])], local, &"window.rural_wood", axis, "window", Facing.Value.NORTH)
                window_index += 1
            else:
                _structure(plan, request, "wall.exterior.%03d" % wall_index, local, &"wall.plaster", axis, "wall", Facing.Value.NORTH)
                wall_index += 1

func _add_partitions(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest) -> void:
    var wall_index: int = 1
    for partition_y in [5, 8]:
        for x in range(1, 4):
            var local := Vector2i(x, partition_y)
            if x == 2:
                var purpose: String = "bathroom" if partition_y == 5 else "bedroom"
                _structure(plan, request, "door.interior.%s" % purpose, local, &"door.house", StructureGeometry.Axis.HORIZONTAL, "door", Facing.Value.SOUTH)
            else:
                _structure(plan, request, "wall.interior.%03d" % wall_index, local, &"wall.interior", StructureGeometry.Axis.HORIZONTAL, "wall", Facing.Value.NORTH)
                wall_index += 1

func _add_props(plan: GeneratedBuildingPlan, request: BuildingGenerationRequest) -> void:
    var sofa_semantic: StringName = &"prop.loveseat" if absi(request.seed) % 2 == 0 else &"prop.sofa"
    var entries: Array = [
        ["prop.kitchen.stove", Vector2i(1, 1), &"prop.stove_range", Facing.Value.EAST],
        ["prop.kitchen.fridge", Vector2i(1, 2), &"prop.refrigerator_white", Facing.Value.EAST],
        ["prop.kitchen.sink", Vector2i(1, 3), &"prop.kitchen_sink", Facing.Value.EAST],
        ["prop.living.sofa", Vector2i(3, 1), sofa_semantic, Facing.Value.WEST],
        ["prop.bath.toilet", Vector2i(1, 6), &"prop.toilet_modern", Facing.Value.EAST],
        ["prop.bath.vanity", Vector2i(1, 7), &"prop.bathroom_vanity", Facing.Value.EAST],
        ["prop.bedroom.bed", Vector2i(1, 9), &"prop.bed_single", Facing.Value.EAST],
        ["prop.bedroom.dresser", Vector2i(1, 10), &"prop.dresser_wide", Facing.Value.EAST],
    ]
    for entry: Array in entries:
        plan.props.append({
            "role": String(entry[0]),
            "cell": _global_cell(entry[1], request),
            "semantic": entry[2],
            "facing": _rotate_facing(int(entry[3]), request.orientation),
            "blocking": true,
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
