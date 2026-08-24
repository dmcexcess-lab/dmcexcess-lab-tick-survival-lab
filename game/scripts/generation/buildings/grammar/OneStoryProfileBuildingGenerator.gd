extends RefCounted
class_name OneStoryProfileBuildingGenerator

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const PlanClass = preload("res://scripts/generation/buildings/GeneratedBuildingPlan.gd")

var _profile: Dictionary = {}

func _init(profile: Dictionary = {}) -> void:
    _profile = profile.duplicate(true)

func archetype_id() -> StringName:
    return StringName(_profile.get("id", &""))

func generate(request: BuildingGenerationRequest) -> GeneratedBuildingPlan:
    var plan := PlanClass.new()
    var validation: Dictionary = _validate_profile(_profile)
    if not bool(validation.get("ok", false)):
        plan.failure_reason = "one_story_profile_invalid"
        return plan
    if request == null or not request.is_valid():
        plan.failure_reason = "invalid_building_request"
        return plan
    var profile_id: StringName = StringName(_profile.get("id", &""))
    if request.archetype_id != profile_id:
        plan.failure_reason = "one_story_archetype_mismatch"
        return plan

    var canonical_size: Vector2i = _profile.get("canonical_size", Vector2i.ZERO)
    var canonical_frontage: int = int(_profile.get("canonical_frontage", Facing.Value.SOUTH))
    var expected_frontage: int = _rotate_facing(canonical_frontage, request.orientation)
    if request.frontage_side != expected_frontage:
        plan.failure_reason = "frontage_incompatible_with_orientation"
        return plan
    var required_size: Vector2i = _rotated_size(canonical_size, request.orientation)
    if request.envelope.size.x < required_size.x or request.envelope.size.y < required_size.y:
        plan.failure_reason = "one_story_envelope_too_small"
        return plan

    var room_cells: Dictionary = _room_cell_map(_profile)
    var opening_by_cell: Dictionary = {}
    for opening_value: Variant in _profile.get("doors", []):
        var opening: Dictionary = opening_value
        opening_by_cell[opening.get("cell", Vector2i.ZERO)] = opening

    plan.instance_id = request.instance_id
    plan.archetype_id = profile_id
    plan.archetype_version = int(_profile.get("version", 1))
    plan.seed = request.seed
    plan.orientation = request.orientation
    plan.frontage_side = request.frontage_side
    plan.footprint_rect = Rect2i(request.envelope.position, required_size)

    _materialize_rooms(plan, request, canonical_size, room_cells)
    _materialize_structure(plan, request, canonical_size, room_cells, opening_by_cell)
    _materialize_props(plan, request, canonical_size, room_cells, opening_by_cell)
    return plan

func _validate_profile(profile: Dictionary) -> Dictionary:
    var failures: Array[String] = []
    if profile.is_empty() or String(profile.get("id", "")).is_empty():
        failures.append("profile_id_missing")
    if int(profile.get("version", 0)) <= 0 or int(profile.get("story_count", 0)) != 1:
        failures.append("profile_version_or_story_count_invalid")
    var size: Vector2i = profile.get("canonical_size", Vector2i.ZERO)
    if size.x < 7 or size.y < 7:
        failures.append("profile_size_invalid")
    var frontage: int = int(profile.get("canonical_frontage", -1))
    if not Facing.is_valid(frontage):
        failures.append("profile_frontage_invalid")

    var room_cells: Dictionary = {}
    var purposes: Dictionary = {}
    var rooms: Array = profile.get("rooms", [])
    if rooms.is_empty():
        failures.append("profile_rooms_missing")
    for room_value: Variant in rooms:
        if typeof(room_value) != TYPE_DICTIONARY:
            failures.append("profile_room_invalid")
            continue
        var room: Dictionary = room_value
        var purpose: String = String(room.get("purpose", ""))
        var rect: Rect2i = room.get("rect", Rect2i())
        if purpose.is_empty() or purposes.has(purpose) or rect.size.x <= 0 or rect.size.y <= 0 or String(room.get("floor", "")).is_empty():
            failures.append("profile_room_invalid")
            continue
        purposes[purpose] = true
        for y in range(rect.position.y, rect.position.y + rect.size.y):
            for x in range(rect.position.x, rect.position.x + rect.size.x):
                var cell := Vector2i(x, y)
                if x <= 0 or y <= 0 or x >= size.x - 1 or y >= size.y - 1 or room_cells.has(cell):
                    failures.append("profile_room_overlap_or_shell_violation")
                room_cells[cell] = purpose

    var opening_cells: Dictionary = {}
    var roles: Dictionary = {}
    var primary_count: int = 0
    for opening_value: Variant in profile.get("doors", []):
        if typeof(opening_value) != TYPE_DICTIONARY:
            failures.append("profile_opening_invalid")
            continue
        var opening: Dictionary = opening_value
        var role: String = String(opening.get("role", ""))
        var cell: Vector2i = opening.get("cell", Vector2i(-1, -1))
        if role.is_empty() or roles.has(role) or opening_cells.has(cell) or String(opening.get("semantic", "")).is_empty():
            failures.append("profile_opening_invalid")
            continue
        if not _cell_inside_footprint(cell, size) or room_cells.has(cell):
            failures.append("profile_opening_not_on_wall")
        roles[role] = true
        opening_cells[cell] = true
        if role == "door.exterior.primary":
            primary_count += 1
    if primary_count != 1:
        failures.append("profile_primary_door_count_invalid")

    var prop_cells: Dictionary = {}
    for prop_value: Variant in profile.get("props", []):
        if typeof(prop_value) != TYPE_DICTIONARY:
            failures.append("profile_prop_invalid")
            continue
        var prop: Dictionary = prop_value
        var role: String = String(prop.get("role", ""))
        var cell: Vector2i = prop.get("cell", Vector2i(-1, -1))
        if role.is_empty() or roles.has(role) or prop_cells.has(cell) or String(prop.get("semantic", "")).is_empty():
            failures.append("profile_prop_invalid")
            continue
        if not room_cells.has(cell) or opening_cells.has(cell):
            failures.append("profile_prop_not_in_room")
        roles[role] = true
        prop_cells[cell] = true
    return {"ok": failures.is_empty(), "failures": failures}

func _room_cell_map(profile: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for room_value: Variant in profile.get("rooms", []):
        var room: Dictionary = room_value
        var rect: Rect2i = room.get("rect", Rect2i())
        var floor: StringName = StringName(room.get("floor", &""))
        var purpose: String = String(room.get("purpose", ""))
        for y in range(rect.position.y, rect.position.y + rect.size.y):
            for x in range(rect.position.x, rect.position.x + rect.size.x):
                result[Vector2i(x, y)] = {"purpose": purpose, "floor": floor}
    return result

func _materialize_rooms(
    plan: GeneratedBuildingPlan,
    request: BuildingGenerationRequest,
    canonical_size: Vector2i,
    room_cells: Dictionary
) -> void:
    for room_value: Variant in _profile.get("rooms", []):
        var room: Dictionary = room_value
        var rect: Rect2i = room.get("rect", Rect2i())
        var floor: StringName = StringName(room.get("floor", &""))
        var cells: Array[Vector2i] = []
        for y in range(rect.position.y, rect.position.y + rect.size.y):
            for x in range(rect.position.x, rect.position.x + rect.size.x):
                var global_cell: Vector2i = _global_cell(Vector2i(x, y), canonical_size, request)
                cells.append(global_cell)
                plan.ground_entries.append({"cell": global_cell, "semantic": floor})
        plan.rooms.append({"purpose": String(room.get("purpose", "")), "cells": cells})

func _materialize_structure(
    plan: GeneratedBuildingPlan,
    request: BuildingGenerationRequest,
    canonical_size: Vector2i,
    room_cells: Dictionary,
    opening_by_cell: Dictionary
) -> void:
    var shell_semantic: StringName = StringName(_profile.get("shell_wall_semantic", &"wall.house"))
    var interior_semantic: StringName = StringName(_profile.get("interior_wall_semantic", &"wall.interior"))
    for y in range(canonical_size.y):
        for x in range(canonical_size.x):
            var cell := Vector2i(x, y)
            if room_cells.has(cell):
                continue
            if opening_by_cell.has(cell):
                var opening: Dictionary = opening_by_cell[cell]
                var semantic: StringName = StringName(opening.get("semantic", _profile.get("exterior_door_semantic", &"door.house")))
                var facing: int = int(opening.get("facing", Facing.Value.SOUTH))
                _append_structure(
                    plan,
                    request,
                    canonical_size,
                    String(opening.get("role", "door.generated")),
                    cell,
                    semantic,
                    _axis_for_wall_cell(cell, canonical_size, room_cells),
                    "door",
                    facing
                )
                var door_floor: StringName = _adjacent_room_floor(cell, room_cells)
                if door_floor != &"":
                    plan.ground_entries.append({"cell": _global_cell(cell, canonical_size, request), "semantic": door_floor})
                continue
            if _auto_window_allowed(cell, canonical_size, room_cells):
                _append_structure(
                    plan,
                    request,
                    canonical_size,
                    "window.auto.%02d_%02d" % [x, y],
                    cell,
                    StringName(_profile.get("window_semantic", &"window.house")),
                    _axis_for_wall_cell(cell, canonical_size, room_cells),
                    "window",
                    _outward_facing(cell, canonical_size)
                )
                continue
            var is_shell: bool = x == 0 or y == 0 or x == canonical_size.x - 1 or y == canonical_size.y - 1
            _append_structure(
                plan,
                request,
                canonical_size,
                "wall.%s.%02d_%02d" % ["exterior" if is_shell else "interior", x, y],
                cell,
                shell_semantic if is_shell else interior_semantic,
                _axis_for_wall_cell(cell, canonical_size, room_cells),
                "wall",
                _outward_facing(cell, canonical_size) if is_shell else Facing.Value.NORTH
            )

func _materialize_props(
    plan: GeneratedBuildingPlan,
    request: BuildingGenerationRequest,
    canonical_size: Vector2i,
    room_cells: Dictionary,
    opening_by_cell: Dictionary
) -> void:
    for prop_value: Variant in _profile.get("props", []):
        var prop: Dictionary = prop_value
        var cell: Vector2i = prop.get("cell", Vector2i.ZERO)
        if not room_cells.has(cell) or opening_by_cell.has(cell):
            continue
        plan.props.append({
            "role": String(prop.get("role", "")),
            "cell": _global_cell(cell, canonical_size, request),
            "semantic": StringName(prop.get("semantic", &"")),
            "facing": _rotate_facing(int(prop.get("facing", Facing.Value.SOUTH)), request.orientation),
            "blocking": bool(prop.get("blocking", true)),
        })

func _auto_window_allowed(cell: Vector2i, size: Vector2i, room_cells: Dictionary) -> bool:
    var sides: Array = _profile.get("window_sides", [])
    var side: int = _outward_facing(cell, size)
    if side < 0 or side not in sides:
        return false
    var inward: Vector2i = Vector2i.ZERO
    match side:
        Facing.Value.NORTH:
            inward = Vector2i.DOWN
        Facing.Value.EAST:
            inward = Vector2i.LEFT
        Facing.Value.SOUTH:
            inward = Vector2i.UP
        Facing.Value.WEST:
            inward = Vector2i.RIGHT
    if not room_cells.has(cell + inward):
        return false
    var spacing: int = maxi(2, int(_profile.get("window_spacing", 3)))
    var coordinate: int = cell.x if side == Facing.Value.NORTH or side == Facing.Value.SOUTH else cell.y
    return coordinate > 0 and coordinate < (size.x - 1 if side == Facing.Value.NORTH or side == Facing.Value.SOUTH else size.y - 1) and (coordinate - 1) % spacing == 1

func _axis_for_wall_cell(cell: Vector2i, size: Vector2i, room_cells: Dictionary) -> int:
    if cell.y == 0 or cell.y == size.y - 1:
        return StructureGeometry.Axis.HORIZONTAL
    if cell.x == 0 or cell.x == size.x - 1:
        return StructureGeometry.Axis.VERTICAL
    var left_right: bool = room_cells.has(cell + Vector2i.LEFT) or room_cells.has(cell + Vector2i.RIGHT)
    var up_down: bool = room_cells.has(cell + Vector2i.UP) or room_cells.has(cell + Vector2i.DOWN)
    if left_right and not up_down:
        return StructureGeometry.Axis.VERTICAL
    if up_down and not left_right:
        return StructureGeometry.Axis.HORIZONTAL
    if room_cells.has(cell + Vector2i.LEFT) and room_cells.has(cell + Vector2i.RIGHT):
        return StructureGeometry.Axis.VERTICAL
    return StructureGeometry.Axis.HORIZONTAL

func _adjacent_room_floor(cell: Vector2i, room_cells: Dictionary) -> StringName:
    for offset: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
        if room_cells.has(cell + offset):
            var data: Dictionary = room_cells[cell + offset]
            return StringName(data.get("floor", &""))
    return &""

func _append_structure(
    plan: GeneratedBuildingPlan,
    request: BuildingGenerationRequest,
    canonical_size: Vector2i,
    role: String,
    local_cell: Vector2i,
    semantic: StringName,
    axis: int,
    kind: String,
    facing: int
) -> void:
    plan.structures.append({
        "role": role,
        "cell": _global_cell(local_cell, canonical_size, request),
        "semantic": semantic,
        "axis": _rotate_axis(axis, request.orientation),
        "kind": kind,
        "facing": _rotate_facing(facing, request.orientation),
    })

func _outward_facing(cell: Vector2i, size: Vector2i) -> int:
    if cell.y == 0:
        return Facing.Value.NORTH
    if cell.x == size.x - 1:
        return Facing.Value.EAST
    if cell.y == size.y - 1:
        return Facing.Value.SOUTH
    if cell.x == 0:
        return Facing.Value.WEST
    return Facing.Value.NORTH

func _cell_inside_footprint(cell: Vector2i, size: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y

func _global_cell(local_cell: Vector2i, canonical_size: Vector2i, request: BuildingGenerationRequest) -> Vector2i:
    return request.envelope.position + _rotate_cell(local_cell, canonical_size, request.orientation)

func _rotated_size(size: Vector2i, orientation: int) -> Vector2i:
    if orientation == Facing.Value.EAST or orientation == Facing.Value.WEST:
        return Vector2i(size.y, size.x)
    return size

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

func _rotate_facing(facing: int, orientation: int) -> int:
    if not Facing.is_valid(facing) or not Facing.is_valid(orientation):
        return Facing.Value.NORTH
    return (facing + orientation) % 4

func _rotate_axis(axis: int, orientation: int) -> int:
    if orientation == Facing.Value.EAST or orientation == Facing.Value.WEST:
        return StructureGeometry.Axis.VERTICAL if axis == StructureGeometry.Axis.HORIZONTAL else StructureGeometry.Axis.HORIZONTAL
    return axis
