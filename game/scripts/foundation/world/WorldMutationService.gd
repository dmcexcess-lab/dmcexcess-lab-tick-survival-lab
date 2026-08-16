extends RefCounted
class_name WorldMutationService

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")
const EntityRecordClass = preload("res://scripts/foundation/world/WorldEntityRecord.gd")
const PlacementClass = preload("res://scripts/foundation/world/WorldPlacement.gd")
const ChangeClass = preload("res://scripts/foundation/world/WorldChange.gd")

## Normal validated write path for foundation WHAT facts.
## Gameplay legality/collision/mechanic rules remain outside this service.

var _state: WorldState = null

func _init(world_state: WorldState = null) -> void:
    _state = world_state

func is_ready() -> bool:
    return _state != null

func create_entity(semantic_type: StringName, requested_id: String = "") -> String:
    if _state == null or String(semantic_type).strip_edges().is_empty():
        return ""

    var entity_id: String = requested_id
    if entity_id.is_empty():
        entity_id = _state._allocate_runtime_id()
    elif not EntityIdRules.is_valid(entity_id):
        return ""

    if _state.has_entity(entity_id):
        return ""

    var record := EntityRecordClass.new(entity_id, semantic_type)
    if not record.is_valid() or not _state._insert_entity(record):
        return ""

    var change := ChangeClass.new(ChangeClass.Kind.ENTITY_CREATED, entity_id)
    _state._commit_change(change)
    return entity_id

func remove_entity(entity_id: String) -> bool:
    if _state == null or not _state.has_entity(entity_id):
        return false

    var previous_placement: WorldPlacement = _state._placement_ref(entity_id)
    var before_cells: Array[Vector2i] = []
    if previous_placement != null:
        before_cells = previous_placement.world_cells()
        _state._remove_placement_record(entity_id)

    var removed: WorldEntityRecord = _state._remove_entity_record(entity_id)
    if removed == null:
        if previous_placement != null:
            _state._set_placement_record(previous_placement)
        return false

    var change := ChangeClass.new(ChangeClass.Kind.ENTITY_REMOVED, entity_id)
    change.before_cells = before_cells
    _state._commit_change(change)
    return true

func set_placement(
    entity_id: String,
    channel: int,
    anchor: Vector2i,
    facing: int,
    footprint: SpatialFootprint,
    structure_axis: int = WorldPlacement.NO_STRUCTURE_AXIS
) -> bool:
    if _state == null or not _state.has_entity(entity_id):
        return false

    var candidate := PlacementClass.new(entity_id, channel, anchor, facing, footprint, structure_axis)
    if not candidate.is_valid():
        return false

    var previous: WorldPlacement = _state._placement_ref(entity_id)
    if previous != null and previous.equivalent(candidate):
        return true

    var before_cells: Array[Vector2i] = previous.world_cells() if previous != null else []
    if not _state._set_placement_record(candidate):
        return false

    var change := ChangeClass.new(ChangeClass.Kind.PLACEMENT_SET, entity_id)
    change.before_cells = before_cells
    change.after_cells = candidate.world_cells()
    _state._commit_change(change)
    return true

func unplace_entity(entity_id: String) -> bool:
    if _state == null or not _state.has_placement(entity_id):
        return false

    var removed: WorldPlacement = _state._remove_placement_record(entity_id)
    if removed == null:
        return false

    var change := ChangeClass.new(ChangeClass.Kind.PLACEMENT_REMOVED, entity_id)
    change.before_cells = removed.world_cells()
    _state._commit_change(change)
    return true

func set_terrain(cell: Vector2i, semantic_type: StringName) -> bool:
    if _state == null or String(semantic_type).strip_edges().is_empty():
        return false

    var previous: StringName = _state.terrain_at(cell)
    if previous == semantic_type and _state.has_terrain(cell):
        return true

    _state._set_terrain_record(cell, semantic_type)
    var change := ChangeClass.new(ChangeClass.Kind.TERRAIN_SET)
    change.terrain_cell = cell
    change.terrain_before = previous
    change.terrain_after = semantic_type
    _state._commit_change(change)
    return true

func clear_terrain(cell: Vector2i) -> bool:
    if _state == null or not _state.has_terrain(cell):
        return false

    var previous: StringName = _state.terrain_at(cell)
    _state._remove_terrain_record(cell)
    var change := ChangeClass.new(ChangeClass.Kind.TERRAIN_REMOVED)
    change.terrain_cell = cell
    change.terrain_before = previous
    _state._commit_change(change)
    return true
