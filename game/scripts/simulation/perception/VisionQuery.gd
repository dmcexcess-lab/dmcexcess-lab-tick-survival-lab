extends RefCounted
class_name VisionQuery

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const DoorValues = preload("res://scripts/simulation/doors/DoorStateValue.gd")

## Stateless deterministic visual LOS over current WHAT + Door State.
## Collision/art never define opacity.

var _world: WorldState = null
var _door_state: DoorStateStore = null

func _init(world_state: WorldState = null, door_state: DoorStateStore = null) -> void:
    _world = world_state
    _door_state = door_state

func is_ready() -> bool:
    return _world != null and _door_state != null

func visible_cells(origin: Vector2i, facing: int, profile: VisionProfile) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    if not is_ready() or profile == null or not profile.is_valid() or not FacingRules.is_valid(facing):
        return result

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
            if cell_is_opaque(side_x) and cell_is_opaque(side_y):
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
        if cell_is_opaque(current):
            return false

    return true

static func _cell_less(a: Vector2i, b: Vector2i) -> bool:
    if a.y == b.y:
        return a.x < b.x
    return a.y < b.y
