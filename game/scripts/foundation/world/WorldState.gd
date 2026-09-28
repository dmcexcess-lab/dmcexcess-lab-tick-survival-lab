extends RefCounted
class_name WorldState

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")
const EntityRecordClass = preload("res://scripts/foundation/world/WorldEntityRecord.gd")
const PlacementClass = preload("res://scripts/foundation/world/WorldPlacement.gd")
const TerrainStoreClass = preload("res://scripts/foundation/world/TerrainStore.gd")
const EntityStoreClass = preload("res://scripts/foundation/world/EntityStore.gd")
const PlacementStoreClass = preload("res://scripts/foundation/world/PlacementStore.gd")
const OccupancyIndexClass = preload("res://scripts/foundation/world/OccupancyIndex.gd")
const ChangeBatchClass = preload("res://scripts/foundation/world/WorldChangeBatch.gd")
const ChangeClass = preload("res://scripts/foundation/world/WorldChange.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const PerformanceTelemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")
signal changed(change)
signal batch_changed(batch)
signal world_reset
const SNAPSHOT_SCHEMA_VERSION: int = 1
var _terrain: TerrainStore = TerrainStoreClass.new()
var _entities: EntityStore = EntityStoreClass.new()
var _placements: PlacementStore = PlacementStoreClass.new()
var _occupancy: OccupancyIndex = OccupancyIndexClass.new()
var _next_entity_serial: int = 1
var _revision: int = 0
var _terrain_revision: int = 0
var _placement_revisions: Dictionary = {}
var _batch_depth: int = 0
var _active_batch: WorldChangeBatch = null
func revision() -> int: return _revision
func terrain_revision() -> int: return _terrain_revision
func placement_revision(channel: int) -> int: return int(_placement_revisions.get(channel, 0))
func begin_change_batch(label: StringName = &"world_batch") -> bool:
    if _batch_depth == 0: _active_batch = ChangeBatchClass.new(label)
    _batch_depth += 1; return true
func end_change_batch() -> WorldChangeBatch:
    if _batch_depth <= 0: return null
    _batch_depth -= 1
    if _batch_depth > 0: return null
    var completed: WorldChangeBatch = _active_batch; _active_batch = null
    if completed != null and completed.change_count > 0: PerformanceTelemetry.record_batch(completed); batch_changed.emit(completed.copy())
    return completed.copy() if completed != null else null
func cancel_change_batch() -> void: _batch_depth = 0; _active_batch = null
func is_change_batch_active() -> bool: return _batch_depth > 0 and _active_batch != null
func has_entity(entity_id: String) -> bool: return _entities.has(entity_id)
func entity(entity_id: String) -> WorldEntityRecord:
    var record: WorldEntityRecord = _entities.get_record(entity_id); return null if record == null else record.copy()
func entity_ids() -> Array[String]: return _entities.ids()
func entity_ids_of_type(semantic_type: StringName) -> Array[String]: return _entities.ids_of_type(semantic_type)
func has_terrain(cell: Vector2i) -> bool: return _terrain.has(cell)
func terrain_at(cell: Vector2i) -> StringName: return _terrain.get_type(cell)
func has_placement(entity_id: String) -> bool: return _placements.has(entity_id)
func placement(entity_id: String) -> WorldPlacement:
    var value: WorldPlacement = _placements.get_placement(entity_id); return null if value == null else value.copy()
func entities_at(cell: Vector2i, channel: int = -1) -> Array[String]: return _occupancy.ids_at(cell, channel)
func create_entity(semantic_type: StringName, requested_id: String = "") -> String:
    if String(semantic_type).strip_edges().is_empty(): return ""
    var entity_id := requested_id
    if entity_id.is_empty(): entity_id = _allocate_runtime_id()
    elif not EntityIdRules.is_valid(entity_id): return ""
    if _entities.has(entity_id): return ""
    var record := EntityRecordClass.new(entity_id, semantic_type)
    if not record.is_valid() or not _insert_entity(record): return ""
    var change := ChangeClass.new(ChangeClass.Kind.ENTITY_CREATED, entity_id); _commit_change(change)
    if entity_id.begins_with("slice7.recipe."): print("SLICE7_TRACE create %s %s" % [entity_id, String(semantic_type)])
    return entity_id
func remove_entity(entity_id: String) -> bool:
    if not _entities.has(entity_id): return false
    var previous := _placements.get_placement(entity_id); var before_cells: Array[Vector2i] = []; var before_channel := -1
    if previous != null: before_cells = previous.world_cells(); before_channel = previous.channel; _remove_placement_record(entity_id)
    var removed := _remove_entity_record(entity_id)
    if removed == null:
        if previous != null: _set_placement_record(previous)
        return false
    var change := ChangeClass.new(ChangeClass.Kind.ENTITY_REMOVED, entity_id); change.before_cells = before_cells; change.before_channel = before_channel; _commit_change(change)
    if entity_id.begins_with("slice7.recipe."): print("SLICE7_TRACE remove %s present=%s" % [entity_id, str(_entities.has(entity_id))])
    return true
func set_placement(entity_id: String, channel: int, anchor: Vector2i, facing: int, footprint: SpatialFootprint, structure_axis: int = WorldPlacement.NO_STRUCTURE_AXIS) -> bool:
    if not _entities.has(entity_id): return false
    var candidate := PlacementClass.new(entity_id, channel, anchor, facing, footprint, structure_axis); if not candidate.is_valid(): return false
    var previous := _placements.get_placement(entity_id); if previous != null and previous.equivalent(candidate): return true
    var before_cells: Array[Vector2i] = []; var before_channel := -1
    if previous != null: before_cells = previous.world_cells(); before_channel = previous.channel
    if not _set_placement_record(candidate): return false
    var change := ChangeClass.new(ChangeClass.Kind.PLACEMENT_SET, entity_id); change.before_cells = before_cells; change.after_cells = candidate.world_cells(); change.before_channel = before_channel; change.after_channel = candidate.channel; _commit_change(change); return true
func unplace_entity(entity_id: String) -> bool:
    if not _placements.has(entity_id): return false
    var removed := _remove_placement_record(entity_id); if removed == null: return false
    var change := ChangeClass.new(ChangeClass.Kind.PLACEMENT_REMOVED, entity_id); change.before_cells = removed.world_cells(); change.before_channel = removed.channel; _commit_change(change); return true
func move_entity(entity_id: String, anchor: Vector2i, facing: int) -> bool:
    var previous: WorldPlacement = _placements.get_placement(entity_id); if previous == null: return false
    var candidate := PlacementClass.new(entity_id, previous.channel, anchor, facing, previous.footprint, previous.structure_axis); if not candidate.is_valid(): return false
    if previous.equivalent(candidate): return true
    var before_cells := previous.world_cells(); var before_channel := previous.channel
    if not _set_placement_record(candidate): return false
    var change := ChangeClass.new(ChangeClass.Kind.PLACEMENT_SET, entity_id); change.before_cells = before_cells; change.after_cells = candidate.world_cells(); change.before_channel = before_channel; change.after_channel = candidate.channel; _commit_change(change); return true
func snapshot() -> Dictionary:
    return {"schema_version": SNAPSHOT_SCHEMA_VERSION, "next_entity_serial": _next_entity_serial, "revision": _revision, "terrain": _terrain.snapshot_entries(), "entities": _entities.snapshot_entries(), "placements": _placements.snapshot_entries()}
func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION: return false
    var restored_next_serial := int(data.get("next_entity_serial", -1)); var restored_revision := int(data.get("revision", -1)); if restored_next_serial < 1 or restored_revision < 0: return false
    var terrain_value: Variant = data.get("terrain", []); var entities_value: Variant = data.get("entities", []); var placements_value: Variant = data.get("placements", [])
    if typeof(terrain_value) != TYPE_ARRAY or typeof(entities_value) != TYPE_ARRAY or typeof(placements_value) != TYPE_ARRAY: return false
    var restored_terrain := TerrainStoreClass.new()
    for value: Variant in terrain_value:
        if typeof(value) != TYPE_DICTIONARY: return false
        var entry: Dictionary = value; var cell_value: Variant = entry.get("cell", []); if typeof(cell_value) != TYPE_ARRAY or cell_value.size() != 2: return false
        var cell := Vector2i(int(cell_value[0]), int(cell_value[1])); var semantic_type := StringName(String(entry.get("semantic_type", ""))); if String(semantic_type).strip_edges().is_empty() or restored_terrain.has(cell): return false
        restored_terrain.set_type(cell, semantic_type)
    var restored_entities := EntityStoreClass.new()
    for value: Variant in entities_value:
        if typeof(value) != TYPE_DICTIONARY: return false
        var record: WorldEntityRecord = EntityRecordClass.from_snapshot(value); if record == null or not restored_entities.insert(record): return false
    var restored_placements := PlacementStoreClass.new()
    for value: Variant in placements_value:
        if typeof(value) != TYPE_DICTIONARY: return false
        var placed: WorldPlacement = PlacementClass.from_snapshot(value); if placed == null or not restored_entities.has(placed.entity_id) or restored_placements.has(placed.entity_id) or not restored_placements.set_placement(placed): return false
    var restored_occupancy := OccupancyIndexClass.new(); restored_occupancy.rebuild(restored_placements); _terrain = restored_terrain; _entities = restored_entities; _placements = restored_placements; _occupancy = restored_occupancy; _next_entity_serial = restored_next_serial; _revision = restored_revision; _terrain_revision = restored_revision; _placement_revisions.clear()
    for channel in range(Layers.Channel.TERRAIN, Layers.Channel.EFFECT + 1): _placement_revisions[channel] = restored_revision
    cancel_change_batch(); world_reset.emit(); return true
func _allocate_runtime_id() -> String:
    while true:
        var candidate := EntityIdRules.runtime_id(_next_entity_serial); _next_entity_serial += 1
        if not _entities.has(candidate): return candidate
    return ""
func _entity_ref(entity_id: String) -> WorldEntityRecord: return _entities.get_record(entity_id)
func _placement_ref(entity_id: String) -> WorldPlacement: return _placements.get_placement(entity_id)
func _insert_entity(record: WorldEntityRecord) -> bool: return _entities.insert(record)
func _remove_entity_record(entity_id: String) -> WorldEntityRecord: return _entities.remove(entity_id)
func _set_placement_record(value: WorldPlacement) -> bool:
    if value == null: return false
    var previous: WorldPlacement = _placements.get_placement(value.entity_id)
    if previous != null: _occupancy.remove(previous)
    if not _placements.set_placement(value):
        if previous != null: _placements.set_placement(previous); _occupancy.add(previous)
        return false
    _occupancy.add(_placements.get_placement(value.entity_id)); return true
func _remove_placement_record(entity_id: String) -> WorldPlacement:
    var previous := _placements.get_placement(entity_id); if previous == null: return null
    _occupancy.remove(previous); return _placements.remove(entity_id)
func _set_terrain_record(cell: Vector2i, semantic_type: StringName) -> void: _terrain.set_type(cell, semantic_type)
func _set_terrain_rect_records(rect: Rect2i, semantic_type: StringName) -> Dictionary: return _terrain.set_rect_type(rect, semantic_type)
func _remove_terrain_record(cell: Vector2i) -> void: _terrain.erase(cell)
func _commit_change(change: WorldChange) -> void:
    if change == null or not change.is_valid(): return
    _revision += 1; change.sequence = _revision
    if change.is_terrain_change(): _terrain_revision += 1
    var touched: Dictionary = {}; if change.before_channel >= 0: touched[change.before_channel] = true
    if change.after_channel >= 0: touched[change.after_channel] = true
    for channel_value: Variant in touched.keys(): var channel := int(channel_value); _placement_revisions[channel] = int(_placement_revisions.get(channel, 0)) + 1
    if _active_batch != null: _active_batch.include(change)
    changed.emit(change.copy())
