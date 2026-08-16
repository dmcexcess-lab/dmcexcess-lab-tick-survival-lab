extends RefCounted
class_name WorldState

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")
const EntityRecordClass = preload("res://scripts/foundation/world/WorldEntityRecord.gd")
const PlacementClass = preload("res://scripts/foundation/world/WorldPlacement.gd")
const TerrainStoreClass = preload("res://scripts/foundation/world/TerrainStore.gd")
const EntityStoreClass = preload("res://scripts/foundation/world/EntityStore.gd")
const PlacementStoreClass = preload("res://scripts/foundation/world/PlacementStore.gd")
const OccupancyIndexClass = preload("res://scripts/foundation/world/OccupancyIndex.gd")

## Authoritative WHAT read/query facade and state composition.
## Normal writes go through WorldMutationService.

signal changed(change)
signal world_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1

var _terrain: TerrainStore = TerrainStoreClass.new()
var _entities: EntityStore = EntityStoreClass.new()
var _placements: PlacementStore = PlacementStoreClass.new()
var _occupancy: OccupancyIndex = OccupancyIndexClass.new()
var _next_entity_serial: int = 1
var _revision: int = 0

func revision() -> int:
    return _revision

func has_entity(entity_id: String) -> bool:
    return _entities.has(entity_id)

func entity(entity_id: String) -> WorldEntityRecord:
    var record: WorldEntityRecord = _entities.get_record(entity_id)
    if record == null:
        return null
    return record.copy()

func entity_ids() -> Array[String]:
    return _entities.ids()

func has_terrain(cell: Vector2i) -> bool:
    return _terrain.has(cell)

func terrain_at(cell: Vector2i) -> StringName:
    return _terrain.get_type(cell)

func has_placement(entity_id: String) -> bool:
    return _placements.has(entity_id)

func placement(entity_id: String) -> WorldPlacement:
    var value: WorldPlacement = _placements.get_placement(entity_id)
    if value == null:
        return null
    return value.copy()

func entities_at(cell: Vector2i, channel: int = -1) -> Array[String]:
    return _occupancy.ids_at(cell, channel)

func snapshot() -> Dictionary:
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "next_entity_serial": _next_entity_serial,
        "revision": _revision,
        "terrain": _terrain.snapshot_entries(),
        "entities": _entities.snapshot_entries(),
        "placements": _placements.snapshot_entries(),
    }

func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false

    var restored_next_serial: int = int(data.get("next_entity_serial", -1))
    var restored_revision: int = int(data.get("revision", -1))
    if restored_next_serial < 1 or restored_revision < 0:
        return false

    var terrain_value: Variant = data.get("terrain", [])
    var entities_value: Variant = data.get("entities", [])
    var placements_value: Variant = data.get("placements", [])
    if typeof(terrain_value) != TYPE_ARRAY:
        return false
    if typeof(entities_value) != TYPE_ARRAY:
        return false
    if typeof(placements_value) != TYPE_ARRAY:
        return false

    var restored_terrain: TerrainStore = TerrainStoreClass.new()
    for value: Variant in terrain_value:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var entry: Dictionary = value
        var cell_value: Variant = entry.get("cell", [])
        if typeof(cell_value) != TYPE_ARRAY or cell_value.size() != 2:
            return false
        var cell := Vector2i(int(cell_value[0]), int(cell_value[1]))
        var semantic_type := StringName(String(entry.get("semantic_type", "")))
        if String(semantic_type).strip_edges().is_empty() or restored_terrain.has(cell):
            return false
        restored_terrain.set_type(cell, semantic_type)

    var restored_entities: EntityStore = EntityStoreClass.new()
    for value: Variant in entities_value:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var record: WorldEntityRecord = EntityRecordClass.from_snapshot(value)
        if record == null or not restored_entities.insert(record):
            return false

    var restored_placements: PlacementStore = PlacementStoreClass.new()
    for value: Variant in placements_value:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var placed: WorldPlacement = PlacementClass.from_snapshot(value)
        if placed == null:
            return false
        if not restored_entities.has(placed.entity_id) or restored_placements.has(placed.entity_id):
            return false
        if not restored_placements.set_placement(placed):
            return false

    var restored_occupancy: OccupancyIndex = OccupancyIndexClass.new()
    restored_occupancy.rebuild(restored_placements)

    _terrain = restored_terrain
    _entities = restored_entities
    _placements = restored_placements
    _occupancy = restored_occupancy
    _next_entity_serial = restored_next_serial
    _revision = restored_revision
    world_reset.emit()
    return true

# --- WHAT-internal mutation surface. External gameplay systems use WorldMutationService. ---

func _allocate_runtime_id() -> String:
    while true:
        var candidate: String = EntityIdRules.runtime_id(_next_entity_serial)
        _next_entity_serial += 1
        if not _entities.has(candidate):
            return candidate
    return ""

func _entity_ref(entity_id: String) -> WorldEntityRecord:
    return _entities.get_record(entity_id)

func _placement_ref(entity_id: String) -> WorldPlacement:
    return _placements.get_placement(entity_id)

func _insert_entity(record: WorldEntityRecord) -> bool:
    return _entities.insert(record)

func _remove_entity_record(entity_id: String) -> WorldEntityRecord:
    return _entities.remove(entity_id)

func _set_placement_record(value: WorldPlacement) -> bool:
    if value == null:
        return false
    var previous: WorldPlacement = _placements.get_placement(value.entity_id)
    if previous != null:
        _occupancy.remove(previous)
    if not _placements.set_placement(value):
        if previous != null:
            _placements.set_placement(previous)
            _occupancy.add(previous)
        return false
    _occupancy.add(_placements.get_placement(value.entity_id))
    return true

func _remove_placement_record(entity_id: String) -> WorldPlacement:
    var previous: WorldPlacement = _placements.get_placement(entity_id)
    if previous == null:
        return null
    _occupancy.remove(previous)
    return _placements.remove(entity_id)

func _set_terrain_record(cell: Vector2i, semantic_type: StringName) -> void:
    _terrain.set_type(cell, semantic_type)

func _remove_terrain_record(cell: Vector2i) -> void:
    _terrain.erase(cell)

func _commit_change(change: WorldChange) -> void:
    if change == null or not change.is_valid():
        return
    _revision += 1
    change.sequence = _revision
    changed.emit(change.copy())
