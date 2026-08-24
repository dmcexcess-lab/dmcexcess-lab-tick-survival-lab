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

    var before_cells: Array[Vector2i] = []
    if previous != null:
        before_cells = previous.world_cells()

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

## Coalesced rectangular terrain write. The full rectangle is replay-safe dirty geometry;
## WHAT revision and change notification advance once for the whole successful batch.
func set_terrain_rect(rect: Rect2i, semantic_type: StringName) -> bool:
    if _state == null or rect.size.x <= 0 or rect.size.y <= 0 or String(semantic_type).strip_edges().is_empty():
        return false

    var changed_any: bool = false
    for y in range(rect.position.y, rect.position.y + rect.size.y):
        for x in range(rect.position.x, rect.position.x + rect.size.x):
            var cell := Vector2i(x, y)
            if _state.has_terrain(cell) and _state.terrain_at(cell) == semantic_type:
                continue
            _state._set_terrain_record(cell, semantic_type)
            changed_any = true

    if changed_any:
        var change := ChangeClass.new(ChangeClass.Kind.TERRAIN_BATCH_SET)
        change.terrain_rect = rect
        change.terrain_after = semantic_type
        _state._commit_change(change)
    return true

## Coalesced sparse terrain write. Duplicate cells are collapsed and notification order is deterministic.
func set_terrain_cells(cells: Array[Vector2i], semantic_type: StringName) -> bool:
    if _state == null or String(semantic_type).strip_edges().is_empty():
        return false
    if cells.is_empty():
        return true

    var unique: Dictionary = {}
    for cell: Vector2i in cells:
        unique[cell] = true

    var ordered: Array[Vector2i] = []
    for value: Variant in unique.keys():
        var cell: Vector2i = value
        ordered.append(cell)
    ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        if a.y == b.y:
            return a.x < b.x
        return a.y < b.y
    )

    var changed_cells: Array[Vector2i] = []
    for cell: Vector2i in ordered:
        if _state.has_terrain(cell) and _state.terrain_at(cell) == semantic_type:
            continue
        _state._set_terrain_record(cell, semantic_type)
        changed_cells.append(cell)

    if not changed_cells.is_empty():
        var change := ChangeClass.new(ChangeClass.Kind.TERRAIN_BATCH_SET)
        change.terrain_cells = changed_cells
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
