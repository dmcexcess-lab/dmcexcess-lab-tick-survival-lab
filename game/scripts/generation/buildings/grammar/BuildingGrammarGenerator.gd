extends RefCounted
class_name BuildingGrammarGenerator

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const PlanClass = preload("res://scripts/generation/buildings/GeneratedBuildingPlan.gd")
const DressingPlannerClass = preload("res://scripts/generation/buildings/grammar/BuildingRoomDressingPlanner.gd")
const QualityValidatorClass = preload("res://scripts/generation/buildings/grammar/BuildingGrammarQualityValidator.gd")

func generate(profile: BuildingGrammarProfile, request: BuildingGenerationRequest) -> GeneratedBuildingPlan:
    var plan := PlanClass.new()
    if profile == null or not profile.is_valid() or request == null or not request.is_valid():
        plan.failure_reason = "invalid_building_grammar_request"
        return plan
    if request.archetype_id != profile.archetype_id:
        plan.failure_reason = "building_grammar_archetype_mismatch"
        return plan
    var expected_frontage: int = _rotate_facing(profile.canonical_frontage, request.orientation)
    if request.frontage_side != expected_frontage:
        plan.failure_reason = "frontage_incompatible_with_orientation"
        return plan
    var required_size: Vector2i = _rotated_size(profile.canonical_size, request.orientation)
    if request.envelope.size.x < required_size.x or request.envelope.size.y < required_size.y:
        plan.failure_reason = "building_grammar_envelope_too_small"
        return plan

    var layout: Dictionary = _build_layout(profile, request.seed)
    if layout.is_empty():
        plan.failure_reason = "building_grammar_layout_failed"
        return plan

    var dressing_result: Dictionary = DressingPlannerClass.new().plan(profile, layout, request.seed)
    if not bool(dressing_result.get("ok", false)):
        plan.failure_reason = "building_grammar_dressing_failed"
        return plan
    var local_props: Array[Dictionary] = []
    for value: Variant in dressing_result.get("props", []):
        local_props.append(value)

    var quality: Dictionary = QualityValidatorClass.new().validate(profile, layout, local_props)
    if not bool(quality.get("ok", false)):
        plan.failure_reason = "building_grammar_quality_failed"
        return plan

    plan.instance_id = request.instance_id
    plan.archetype_id = profile.archetype_id
    plan.archetype_version = profile.archetype_version
    plan.seed = request.seed
    plan.orientation = request.orientation
    plan.frontage_side = request.frontage_side
    plan.footprint_rect = Rect2i(request.envelope.position, required_size)

    _materialize_ground_and_rooms(plan, profile, layout, request)
    _materialize_structure(plan, profile, layout, request)
    _materialize_props(plan, local_props, profile.canonical_size, request)
    return plan

func _build_layout(profile: BuildingGrammarProfile, seed: int) -> Dictionary:
    if profile.layout_strategy != &"front_hub_back_strip":
        return {}
    var width: int = profile.canonical_size.x
    var height: int = profile.canonical_size.y
    var partition_y: int = profile.service_depth + 1
    var public_y: int = partition_y + 1
    var public_height: int = height - public_y - 1
    if public_height < 3:
        return {}

    var room_rects: Dictionary = {}
    var service_order: Array[String] = profile.service_order(seed)
    var service_door_cells: Dictionary = {}
    var separator_xs: Array[int] = []
    var x: int = 1
    var rear_service_door_local: Vector2i = Vector2i(-1, -1)

    for i in range(service_order.size()):
        var purpose: String = service_order[i]
        var spec: Dictionary = profile.service_spec(purpose)
        var room_width: int = int(spec.get("width", 0))
        var room_rect := Rect2i(x, 1, room_width, profile.service_depth)
        room_rects[purpose] = room_rect
        var door_x: int = x + room_width / 2
        service_door_cells[purpose] = Vector2i(door_x, partition_y)
        if bool(spec.get("service_exit", false)):
            rear_service_door_local = Vector2i(door_x, 0)
        x += room_width
        if i < service_order.size() - 1:
            separator_xs.append(x)
            x += 1

    if x != width - 1:
        return {}

    var public_purpose: String = String(profile.public_room.get("purpose", ""))
    var public_rect := Rect2i(1, public_y, width - 2, public_height)
    room_rects[public_purpose] = public_rect
    var primary_door_local := Vector2i(width / 2, height - 1)

    var reserved_clear: Array[Vector2i] = []
    _append_unique(reserved_clear, primary_door_local)
    for y in range(public_rect.position.y, public_rect.position.y + public_rect.size.y):
        _append_unique(reserved_clear, Vector2i(primary_door_local.x, y))
    for purpose: String in service_order:
        var door_cell: Vector2i = service_door_cells[purpose]
        _append_unique(reserved_clear, door_cell)
        _append_unique(reserved_clear, door_cell + Vector2i.UP)
        _append_unique(reserved_clear, door_cell + Vector2i.DOWN)
    if rear_service_door_local.x >= 0:
        _append_unique(reserved_clear, rear_service_door_local)
        var service_room: Rect2i = Rect2i()
        for purpose: String in service_order:
            var spec: Dictionary = profile.service_spec(purpose)
            if bool(spec.get("service_exit", false)):
                service_room = room_rects[purpose]
                break
        if service_room.size.x > 0:
            var lane_x: int = service_room.position.x + service_room.size.x / 2
            for y in range(service_room.position.y, service_room.position.y + service_room.size.y):
                _append_unique(reserved_clear, Vector2i(lane_x, y))

    return {
        "room_rects": room_rects,
        "service_order": service_order,
        "service_door_cells": service_door_cells,
        "separator_xs": separator_xs,
        "partition_y": partition_y,
        "public_rect": public_rect,
        "primary_door_local": primary_door_local,
        "rear_service_door_local": rear_service_door_local,
        "reserved_clear": reserved_clear,
    }

func _materialize_ground_and_rooms(
    plan: GeneratedBuildingPlan,
    profile: BuildingGrammarProfile,
    layout: Dictionary,
    request: BuildingGenerationRequest
) -> void:
    var room_rects: Dictionary = layout.get("room_rects", {})
    var public_purpose: String = String(profile.public_room.get("purpose", ""))
    var ordered_purposes: Array[String] = layout.get("service_order", []).duplicate()
    ordered_purposes.append(public_purpose)
    for purpose: String in ordered_purposes:
        var room: Rect2i = room_rects[purpose]
        var floor_semantic: StringName = profile.public_room.get("floor", &"") if purpose == public_purpose else profile.service_spec(purpose).get("floor", &"")
        var cells: Array[Vector2i] = []
        for y in range(room.position.y, room.position.y + room.size.y):
            for x in range(room.position.x, room.position.x + room.size.x):
                var global_cell := _global_cell(Vector2i(x, y), profile.canonical_size, request)
                cells.append(global_cell)
                plan.ground_entries.append({"cell": global_cell, "semantic": floor_semantic})
        plan.rooms.append({"purpose": purpose, "cells": cells})

    var primary_door: Vector2i = layout.get("primary_door_local", Vector2i(-1, -1))
    _ground(plan, profile, request, primary_door, profile.public_room.get("floor", &""))
    var service_door_cells: Dictionary = layout.get("service_door_cells", {})
    for purpose: String in layout.get("service_order", []):
        var door_cell: Vector2i = service_door_cells[purpose]
        _ground(plan, profile, request, door_cell, profile.service_spec(purpose).get("floor", &""))
    var rear_service: Vector2i = layout.get("rear_service_door_local", Vector2i(-1, -1))
    if rear_service.x >= 0:
        for purpose: String in layout.get("service_order", []):
            var spec: Dictionary = profile.service_spec(purpose)
            if bool(spec.get("service_exit", false)):
                _ground(plan, profile, request, rear_service, spec.get("floor", &""))
                break

func _materialize_structure(
    plan: GeneratedBuildingPlan,
    profile: BuildingGrammarProfile,
    layout: Dictionary,
    request: BuildingGenerationRequest
) -> void:
    var width: int = profile.canonical_size.x
    var height: int = profile.canonical_size.y
    var primary: Vector2i = layout.get("primary_door_local", Vector2i(-1, -1))
    var service_exit: Vector2i = layout.get("rear_service_door_local", Vector2i(-1, -1))
    var rear_windows: Dictionary = _rear_window_cells(profile, layout)
    var front_windows: Dictionary = {}
    for x in range(1, width - 1):
        if x != primary.x and x % profile.front_window_spacing == 0:
            front_windows[Vector2i(x, height - 1)] = true
    var public_rect: Rect2i = layout.get("public_rect", Rect2i())
    var side_window_y: int = public_rect.position.y + public_rect.size.y / 2

    for x in range(width):
        var north := Vector2i(x, 0)
        if north == service_exit:
            _structure(plan, profile, request, "door.exterior.service", north, profile.service_door_semantic, StructureGeometry.Axis.HORIZONTAL, "door", Facing.Value.NORTH)
        elif rear_windows.has(north):
            _structure(plan, profile, request, "window.rear.%02d" % x, north, profile.rear_window_semantic, StructureGeometry.Axis.HORIZONTAL, "window", Facing.Value.NORTH)
        else:
            _structure(plan, profile, request, "wall.exterior.%02d_%02d" % [x, 0], north, profile.shell_wall_semantic, StructureGeometry.Axis.HORIZONTAL, "wall", Facing.Value.NORTH)

        var south := Vector2i(x, height - 1)
        if south == primary:
            _structure(plan, profile, request, "door.exterior.primary", south, profile.primary_door_semantic, StructureGeometry.Axis.HORIZONTAL, "door", Facing.Value.SOUTH)
        elif front_windows.has(south):
            _structure(plan, profile, request, "window.front.%02d" % x, south, profile.front_window_semantic, StructureGeometry.Axis.HORIZONTAL, "window", Facing.Value.SOUTH)
        else:
            _structure(plan, profile, request, "wall.exterior.%02d_%02d" % [x, height - 1], south, profile.front_wall_semantic, StructureGeometry.Axis.HORIZONTAL, "wall", Facing.Value.SOUTH)

    for y in range(1, height - 1):
        var west := Vector2i(0, y)
        var east := Vector2i(width - 1, y)
        if y == side_window_y:
            _structure(plan, profile, request, "window.side.west", west, profile.side_window_semantic, StructureGeometry.Axis.VERTICAL, "window", Facing.Value.WEST)
            _structure(plan, profile, request, "window.side.east", east, profile.side_window_semantic, StructureGeometry.Axis.VERTICAL, "window", Facing.Value.EAST)
        else:
            _structure(plan, profile, request, "wall.exterior.%02d_%02d" % [0, y], west, profile.shell_wall_semantic, StructureGeometry.Axis.VERTICAL, "wall", Facing.Value.WEST)
            _structure(plan, profile, request, "wall.exterior.%02d_%02d" % [width - 1, y], east, profile.shell_wall_semantic, StructureGeometry.Axis.VERTICAL, "wall", Facing.Value.EAST)

    var partition_y: int = int(layout.get("partition_y", -1))
    var service_door_cells: Dictionary = layout.get("service_door_cells", {})
    var door_by_x: Dictionary = {}
    for purpose: String in layout.get("service_order", []):
        var door_cell: Vector2i = service_door_cells[purpose]
        door_by_x[door_cell.x] = purpose
    for x in range(1, width - 1):
        var local := Vector2i(x, partition_y)
        if door_by_x.has(x):
            var purpose: String = String(door_by_x[x])
            _structure(plan, profile, request, "door.interior.%s" % purpose, local, profile.interior_door_semantic, StructureGeometry.Axis.HORIZONTAL, "door", Facing.Value.SOUTH)
        else:
            _structure(plan, profile, request, "wall.interior.%02d_%02d" % [x, partition_y], local, profile.interior_wall_semantic, StructureGeometry.Axis.HORIZONTAL, "wall", Facing.Value.NORTH)

    for separator_value: Variant in layout.get("separator_xs", []):
        var separator_x: int = int(separator_value)
        for y in range(1, profile.service_depth + 1):
            var local := Vector2i(separator_x, y)
            _structure(plan, profile, request, "wall.interior.%02d_%02d" % [separator_x, y], local, profile.interior_wall_semantic, StructureGeometry.Axis.VERTICAL, "wall", Facing.Value.NORTH)

func _materialize_props(
    plan: GeneratedBuildingPlan,
    local_props: Array[Dictionary],
    canonical_size: Vector2i,
    request: BuildingGenerationRequest
) -> void:
    for prop: Dictionary in local_props:
        plan.props.append({
            "role": String(prop.get("role", "")),
            "cell": _global_cell(prop.get("local_cell", Vector2i.ZERO), canonical_size, request),
            "semantic": prop.get("semantic", &""),
            "facing": _rotate_facing(int(prop.get("facing", Facing.Value.NORTH)), request.orientation),
            "blocking": bool(prop.get("blocking", true)),
        })

func _rear_window_cells(profile: BuildingGrammarProfile, layout: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    var room_rects: Dictionary = layout.get("room_rects", {})
    for purpose: String in layout.get("service_order", []):
        var spec: Dictionary = profile.service_spec(purpose)
        if not bool(spec.get("rear_window", false)):
            continue
        var room: Rect2i = room_rects[purpose]
        if room.size.x >= 5:
            result[Vector2i(room.position.x + 1, 0)] = true
            result[Vector2i(room.position.x + room.size.x - 2, 0)] = true
        else:
            result[Vector2i(room.position.x + room.size.x / 2, 0)] = true
    return result

func _ground(
    plan: GeneratedBuildingPlan,
    profile: BuildingGrammarProfile,
    request: BuildingGenerationRequest,
    local: Vector2i,
    semantic: StringName
) -> void:
    plan.ground_entries.append({"cell": _global_cell(local, profile.canonical_size, request), "semantic": semantic})

func _structure(
    plan: GeneratedBuildingPlan,
    profile: BuildingGrammarProfile,
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
        "cell": _global_cell(local, profile.canonical_size, request),
        "semantic": semantic,
        "axis": _rotate_axis(axis, request.orientation),
        "kind": kind,
        "facing": _rotate_facing(facing, request.orientation),
    })

func _global_cell(local: Vector2i, canonical_size: Vector2i, request: BuildingGenerationRequest) -> Vector2i:
    return request.envelope.position + _rotate_cell(local, canonical_size, request.orientation)

func _rotated_size(canonical_size: Vector2i, orientation: int) -> Vector2i:
    if orientation == Facing.Value.EAST or orientation == Facing.Value.WEST:
        return Vector2i(canonical_size.y, canonical_size.x)
    return canonical_size

func _rotate_cell(cell: Vector2i, size: Vector2i, orientation: int) -> Vector2i:
    match orientation:
        Facing.Value.NORTH:
            return cell
        Facing.Value.EAST:
            return Vector2i(size.y - 1 - cell.y, cell.x)
        Facing.Value.SOUTH:
            return Vector2i(size.x - 1 - cell.x, size.y - 1 - cell.y)
        Facing.Value.WEST:
            return Vector2i(cell.y, size.x - 1 - cell.x)
    return cell

func _rotate_axis(axis: int, orientation: int) -> int:
    if orientation == Facing.Value.EAST or orientation == Facing.Value.WEST:
        return StructureGeometry.Axis.VERTICAL if axis == StructureGeometry.Axis.HORIZONTAL else StructureGeometry.Axis.HORIZONTAL
    return axis

func _rotate_facing(facing: int, orientation: int) -> int:
    return (facing + orientation) % 4

func _append_unique(values: Array[Vector2i], value: Vector2i) -> void:
    if not values.has(value):
        values.append(value)
