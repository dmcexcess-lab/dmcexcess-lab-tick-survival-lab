extends RefCounted
class_name VisionQuery

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const DoorValues = preload("res://scripts/simulation/doors/DoorStateValue.gd")

## Deterministic visual LOS over current WHAT + Door State. The bounded observer
## field caches opacity/structure reads behind the exact relevant revisions.
## Collision/art never define opacity.

var _world: WorldState = null
var _door_state: DoorStateStore = null
var _prepared_bounds: Rect2i = Rect2i()
var _prepared_terrain_revision: int = -1
var _prepared_structure_revision: int = -1
var _prepared_door_revision: int = -1
var _opaque_by_cell: Dictionary = {}
var _structure_by_cell: Dictionary = {}

func _init(world_state: WorldState = null, door_state: DoorStateStore = null) -> void:
    _world = world_state
    _door_state = door_state

func is_ready() -> bool:
    return _world != null and _door_state != null

func visible_cells(origin: Vector2i, facing: int, profile: VisionProfile) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    if not is_ready() or profile == null or not profile.is_valid() or not FacingRules.is_valid(facing):
        return result

    _prepare_local_field(Rect2i(
        origin - Vector2i(profile.max_range, profile.max_range),
        Vector2i(profile.max_range * 2 + 1, profile.max_range * 2 + 1)
    ))

    result.append(origin)
    for y in range(-profile.max_range, profile.max_range + 1):
        for x in range(-profile.max_range, profile.max_range + 1):
            var offset := Vector2i(x, y)
            if offset == Vector2i.ZERO or not profile.contains_offset(offset, facing):
                continue
            var target := origin + offset
            if not _world.has_terrain(target):
                continue
            if _line_clear(origin, target):
                result.append(target)

    result.sort_custom(_cell_less)
    return result

func can_see(origin: Vector2i, facing: int, target: Vector2i, profile: VisionProfile) -> bool:
    if not is_ready() or profile == null or not profile.is_valid() or not FacingRules.is_valid(facing):
        return false
    _prepare_local_field(Rect2i(
        origin - Vector2i(profile.max_range, profile.max_range),
        Vector2i(profile.max_range * 2 + 1, profile.max_range * 2 + 1)
    ))
    var offset := target - origin
    if not profile.contains_offset(offset, facing):
        return false
    if target != origin and not _world.has_terrain(target):
        return false
    return target == origin or _line_clear(origin, target)

func cell_is_opaque(cell: Vector2i) -> bool:
    if not is_ready() or not _world.has_terrain(cell):
        return true

    var structure_ids: Array[String] = _world.entities_at(cell, Layers.Channel.STRUCTURE)
    if structure_ids.is_empty():
        return false
    if structure_ids.size() != 1:
        return true

    var structure_id: String = structure_ids[0]
    var entity: WorldEntityRecord = _world.entity(structure_id)
    var placement: WorldPlacement = _world.placement(structure_id)
    if entity == null or placement == null:
        return true
    if placement.channel != Layers.Channel.STRUCTURE:
        return true
    if not StructureGeometry.is_valid_axis(placement.structure_axis):
        return true
    if cell not in placement.world_cells():
        return true

    var semantic: String = String(entity.semantic_type).strip_edges()
    if semantic.begins_with("wall.") and semantic.length() > 5:
        return true
    if semantic.begins_with("window.") and semantic.length() > 7:
        return false
    if semantic.begins_with("door.") and semantic.length() > 5:
        var state: StringName = _door_state.state(structure_id)
        if state == DoorValues.OPEN:
            return false
        return true
    return true

func structure_observation(cell: Vector2i) -> Dictionary:
    if _prepared_bounds.has_point(cell) and _structure_by_cell.has(cell) \
        and _prepared_terrain_revision == _world.terrain_revision() \
        and _prepared_structure_revision == _world.placement_revision(Layers.Channel.STRUCTURE) \
        and _prepared_door_revision == _door_state.revision():
        var prepared: Dictionary = _structure_by_cell[cell]
        return prepared.duplicate(true)
    return _structure_observation_uncached(cell)

func _structure_observation_uncached(cell: Vector2i) -> Dictionary:
    if not is_ready() or not _world.has_terrain(cell):
        return {"valid": false, "present": false}

    var structure_ids: Array[String] = _world.entities_at(cell, Layers.Channel.STRUCTURE)
    if structure_ids.is_empty():
        return {"valid": true, "present": false}
    if structure_ids.size() != 1:
        return {"valid": false, "present": true}

    var structure_id: String = structure_ids[0]
    var entity: WorldEntityRecord = _world.entity(structure_id)
    var placement: WorldPlacement = _world.placement(structure_id)
    if entity == null or placement == null:
        return {"valid": false, "present": true}
    if placement.channel != Layers.Channel.STRUCTURE:
        return {"valid": false, "present": true}
    if not StructureGeometry.is_valid_axis(placement.structure_axis):
        return {"valid": false, "present": true}
    if cell not in placement.world_cells():
        return {"valid": false, "present": true}

    var semantic: String = String(entity.semantic_type).strip_edges()
    var family: StringName = &""
    var door_state_value: StringName = &""
    if semantic.begins_with("wall.") and semantic.length() > 5:
        family = &"wall"
    elif semantic.begins_with("window.") and semantic.length() > 7:
        family = &"window"
    elif semantic.begins_with("door.") and semantic.length() > 5:
        family = &"door"
        door_state_value = _door_state.state(structure_id)
        if not DoorValues.is_known(door_state_value):
            return {"valid": false, "present": true}
    else:
        return {"valid": false, "present": true}

    return {
        "valid": true,
        "present": true,
        "entity_id": structure_id,
        "semantic_type": semantic,
        "family": String(family),
        "structure_axis": placement.structure_axis,
        "door_state": String(door_state_value),
    }

func _line_clear(origin: Vector2i, target: Vector2i) -> bool:
    var delta := target - origin
    var nx: int = abs(delta.x)
    var ny: int = abs(delta.y)
    var step_x: int = signi(delta.x)
    var step_y: int = signi(delta.y)
    var ix: int = 0
    var iy: int = 0
    var current: Vector2i = origin

    while ix < nx or iy < ny:
        var decision: int = (1 + 2 * ix) * ny - (1 + 2 * iy) * nx
        if decision == 0:
            var side_x := current + Vector2i(step_x, 0)
            var side_y := current + Vector2i(0, step_y)
            if _prepared_cell_is_opaque(side_x) and _prepared_cell_is_opaque(side_y):
                return false
            current += Vector2i(step_x, step_y)
            ix += 1
            iy += 1
        elif decision < 0:
            current += Vector2i(step_x, 0)
            ix += 1
        else:
            current += Vector2i(0, step_y)
            iy += 1

        if current == target:
            return true
        if _prepared_cell_is_opaque(current):
            return false

    return true

func _prepare_local_field(bounds: Rect2i) -> void:
    var terrain_revision: int = _world.terrain_revision()
    var structure_revision: int = _world.placement_revision(Layers.Channel.STRUCTURE)
    var door_revision: int = _door_state.revision()
    if bounds == _prepared_bounds \
        and terrain_revision == _prepared_terrain_revision \
        and structure_revision == _prepared_structure_revision \
        and door_revision == _prepared_door_revision:
        return

    _prepared_bounds = bounds
    _prepared_terrain_revision = terrain_revision
    _prepared_structure_revision = structure_revision
    _prepared_door_revision = door_revision
    _opaque_by_cell.clear()
    _structure_by_cell.clear()
    var end: Vector2i = bounds.position + bounds.size
    for y: int in range(bounds.position.y, end.y):
        for x: int in range(bounds.position.x, end.x):
            var cell := Vector2i(x, y)
            var observation: Dictionary = _structure_observation_uncached(cell)
            _structure_by_cell[cell] = observation
            var opaque: bool = not bool(observation.get("valid", false))
            if bool(observation.get("valid", false)):
                if not bool(observation.get("present", false)):
                    opaque = false
                else:
                    var family: String = String(observation.get("family", ""))
                    opaque = family == "wall" \
                        or (family == "door" and StringName(observation.get("door_state", &"")) != DoorValues.OPEN)
            _opaque_by_cell[cell] = opaque

func _prepared_cell_is_opaque(cell: Vector2i) -> bool:
    if _prepared_bounds.has_point(cell) and _opaque_by_cell.has(cell):
        return bool(_opaque_by_cell[cell])
    return cell_is_opaque(cell)

static func _cell_less(a: Vector2i, b: Vector2i) -> bool:
    if a.y == b.y:
        return a.x < b.x
    return a.y < b.y
