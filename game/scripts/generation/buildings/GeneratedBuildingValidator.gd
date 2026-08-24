extends RefCounted
class_name GeneratedBuildingValidator

const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")

func validate(plan: GeneratedBuildingPlan) -> Dictionary:
    var failures: Array[String] = []
    if plan == null or not plan.is_generated():
        return {"ok": false, "failures": ["plan_not_generated"]}

    var roles: Dictionary = {}
    var structure_cells: Dictionary = {}
    var door_cells: Dictionary = {}
    var primary_exterior_door_count: int = 0
    for entry: Dictionary in plan.structures:
        var role: String = String(entry.get("role", ""))
        var cell: Vector2i = entry.get("cell", Vector2i(2147483647, 2147483647))
        var semantic: String = String(entry.get("semantic", ""))
        var kind: String = String(entry.get("kind", ""))
        var axis: int = int(entry.get("axis", -1))
        if role.is_empty() or roles.has(role):
            failures.append("duplicate_or_missing_role")
        else:
            roles[role] = true
        if not plan.footprint_rect.has_point(cell):
            failures.append("structure_outside_footprint")
        if structure_cells.has(cell):
            failures.append("duplicate_structure_cell")
        structure_cells[cell] = kind
        if semantic.is_empty() or not StructureGeometry.is_valid_axis(axis):
            failures.append("invalid_structure_entry")
        if kind == "door":
            door_cells[cell] = true
            if role == "door.exterior.primary":
                primary_exterior_door_count += 1
    if primary_exterior_door_count != 1:
        failures.append("exterior_door_count_invalid")

    var prop_cells: Dictionary = {}
    for entry: Dictionary in plan.props:
        var role: String = String(entry.get("role", ""))
        var cell: Vector2i = entry.get("cell", Vector2i(2147483647, 2147483647))
        if role.is_empty() or roles.has(role):
            failures.append("duplicate_or_missing_role")
        else:
            roles[role] = true
        if not plan.footprint_rect.has_point(cell):
            failures.append("prop_outside_footprint")
        if structure_cells.has(cell) or prop_cells.has(cell):
            failures.append("prop_overlap")
        prop_cells[cell] = bool(entry.get("blocking", true))

    var ground_cells: Dictionary = {}
    for entry: Dictionary in plan.ground_entries:
        var cell: Vector2i = entry.get("cell", Vector2i(2147483647, 2147483647))
        if not plan.footprint_rect.has_point(cell):
            failures.append("ground_outside_footprint")
        ground_cells[cell] = true

    if plan.rooms.is_empty():
        failures.append("rooms_missing")
    var room_purposes: Dictionary = {}
    for room: Dictionary in plan.rooms:
        var purpose: String = String(room.get("purpose", ""))
        var cells: Array = room.get("cells", [])
        if purpose.is_empty() or cells.is_empty() or room_purposes.has(purpose):
            failures.append("invalid_room")
        else:
            room_purposes[purpose] = true
        for cell_value: Variant in cells:
            var cell: Vector2i = cell_value
            if not ground_cells.has(cell):
                failures.append("room_cell_missing_ground")

    for cell: Variant in door_cells.keys():
        if prop_cells.has(cell) and bool(prop_cells[cell]):
            failures.append("blocking_prop_on_door")

    if failures.is_empty() and not _rooms_reachable(plan, structure_cells, prop_cells, door_cells):
        failures.append("room_connectivity_failed")
    return {"ok": failures.is_empty(), "failures": failures}

func _rooms_reachable(
    plan: GeneratedBuildingPlan,
    structure_cells: Dictionary,
    prop_cells: Dictionary,
    door_cells: Dictionary
) -> bool:
    var exterior_doors: Array[Vector2i] = []
    for entry: Dictionary in plan.structures:
        if String(entry.get("kind", "")) != "door":
            continue
        if not String(entry.get("role", "")).begins_with("door.exterior."):
            continue
        exterior_doors.append(entry.get("cell", Vector2i(2147483647, 2147483647)))
    if exterior_doors.is_empty():
        return false

    var allowed: Dictionary = {}
    for entry: Dictionary in plan.ground_entries:
        allowed[entry.get("cell", Vector2i.ZERO)] = true
    for cell: Variant in door_cells.keys():
        allowed[cell] = true
    for cell: Variant in prop_cells.keys():
        if bool(prop_cells[cell]):
            allowed.erase(cell)
    for cell: Variant in structure_cells.keys():
        if String(structure_cells[cell]) != "door":
            allowed.erase(cell)

    var visited: Dictionary = {}
    var queue: Array[Vector2i] = []
    for exterior: Vector2i in exterior_doors:
        if not allowed.has(exterior):
            continue
        if visited.has(exterior):
            continue
        visited[exterior] = true
        queue.append(exterior)
    if queue.is_empty():
        return false

    var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
    while not queue.is_empty():
        var current: Vector2i = queue.pop_front()
        for direction: Vector2i in directions:
            var next: Vector2i = current + direction
            if allowed.has(next) and not visited.has(next):
                visited[next] = true
                queue.append(next)

    for room: Dictionary in plan.rooms:
        var reached: bool = false
        for cell_value: Variant in room.get("cells", []):
            if visited.has(cell_value):
                reached = true
                break
        if not reached:
            return false
    return true
