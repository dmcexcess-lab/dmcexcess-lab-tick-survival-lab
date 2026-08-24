extends RefCounted
class_name PerceptionMemoryStore

## Persistent observer knowledge, separate from WHAT. Internal storage is intentionally replaceable.

const SNAPSHOT_SCHEMA_VERSION: int = 2

var _observers: Dictionary = {}

func enroll_observer(observer_id: String) -> bool:
    var normalized: String = observer_id.strip_edges()
    if normalized.is_empty():
        return false
    if _observers.has(normalized):
        return true
    _observers[normalized] = {"cells": {}, "actors": {}}
    return true

func has_observer(observer_id: String) -> bool:
    return _observers.has(observer_id)

func observer_ids() -> Array[String]:
    var values: Array[String] = []
    for key: Variant in _observers.keys():
        values.append(String(key))
    values.sort()
    return values

func has_seen_cell(observer_id: String, cell: Vector2i) -> bool:
    var record: Dictionary = _observer_record(observer_id)
    if record.is_empty():
        return false
    var cells: Dictionary = record["cells"]
    return cells.has(cell)

func explored_cell_count(observer_id: String) -> int:
    var record: Dictionary = _observer_record(observer_id)
    if record.is_empty():
        return 0
    var cells: Dictionary = record["cells"]
    return cells.size()

func remember_environment(
    observer_id: String,
    cell: Vector2i,
    observed_tick: int,
    terrain_semantic: StringName,
    structure_snapshot: Dictionary = {},
    prop_snapshots: Array[Dictionary] = []
) -> bool:
    if observed_tick < 0 or String(terrain_semantic).strip_edges().is_empty():
        return false
    var record: Dictionary = _observer_record(observer_id)
    if record.is_empty():
        return false
    var normalized: Dictionary = _normalize_props(prop_snapshots)
    if not bool(normalized.get("ok", false)):
        return false
    var cells: Dictionary = record["cells"]
    cells[cell] = {
        "cell": cell,
        "observed_tick": observed_tick,
        "terrain_semantic": String(terrain_semantic),
        "structure": structure_snapshot.duplicate(true),
        "props": normalized.get("props", []).duplicate(true),
    }
    return true

func environment_memory(observer_id: String, cell: Vector2i) -> Dictionary:
    var record: Dictionary = _observer_record(observer_id)
    if record.is_empty():
        return {}
    var cells: Dictionary = record["cells"]
    if not cells.has(cell):
        return {}
    var value: Dictionary = cells[cell]
    return value.duplicate(true)

func remember_actor(
    observer_id: String,
    actor_id: String,
    semantic_type: StringName,
    cell: Vector2i,
    facing: int,
    observed_tick: int
) -> bool:
    if actor_id.strip_edges().is_empty() or String(semantic_type).strip_edges().is_empty() or observed_tick < 0:
        return false
    var record: Dictionary = _observer_record(observer_id)
    if record.is_empty():
        return false
    var actors: Dictionary = record["actors"]
    actors[actor_id] = {
        "observer_id": observer_id,
        "actor_id": actor_id,
        "semantic_type": String(semantic_type),
        "cell": cell,
        "facing": facing,
        "observed_tick": observed_tick,
    }
    return true

func forget_actor(observer_id: String, actor_id: String) -> bool:
    var record: Dictionary = _observer_record(observer_id)
    if record.is_empty():
        return false
    var actors: Dictionary = record["actors"]
    if not actors.has(actor_id):
        return true
    actors.erase(actor_id)
    return true

func last_seen_actor(observer_id: String, actor_id: String) -> Dictionary:
    var record: Dictionary = _observer_record(observer_id)
    if record.is_empty():
        return {}
    var actors: Dictionary = record["actors"]
    if not actors.has(actor_id):
        return {}
    var value: Dictionary = actors[actor_id]
    return value.duplicate(true)

func actor_observations(observer_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var record: Dictionary = _observer_record(observer_id)
    if record.is_empty():
        return result
    var actors: Dictionary = record["actors"]
    var ids: Array[String] = []
    for key: Variant in actors.keys():
        ids.append(String(key))
    ids.sort()
    for actor_id: String in ids:
        var value: Dictionary = actors[actor_id]
        result.append(value.duplicate(true))
    return result

func clear_observer(observer_id: String) -> bool:
    if not _observers.has(observer_id):
        return false
    _observers[observer_id] = {"cells": {}, "actors": {}}
    return true

func snapshot() -> Dictionary:
    var observer_entries: Array = []
    for observer_id: String in observer_ids():
        var record: Dictionary = _observers[observer_id]
        var cells: Dictionary = record["cells"]
        var cell_keys: Array[Vector2i] = []
        for cell_value: Variant in cells.keys():
            var cell: Vector2i = cell_value
            cell_keys.append(cell)
        cell_keys.sort_custom(_cell_less)
        var cell_entries: Array = []
        for cell: Vector2i in cell_keys:
            var memory: Dictionary = cells[cell]
            var stored_structure: Dictionary = memory.get("structure", {})
            var stored_props: Array = memory.get("props", [])
            var prop_entries: Array = []
            for prop_value: Variant in stored_props:
                if typeof(prop_value) != TYPE_DICTIONARY:
                    continue
                var prop: Dictionary = prop_value
                var anchor: Vector2i = prop.get("anchor", cell)
                prop_entries.append({
                    "entity_id": String(prop.get("entity_id", "")),
                    "semantic_type": String(prop.get("semantic_type", "")),
                    "anchor": [anchor.x, anchor.y],
                    "facing": int(prop.get("facing", -1)),
                })
            cell_entries.append({
                "cell": [cell.x, cell.y],
                "observed_tick": int(memory.get("observed_tick", 0)),
                "terrain_semantic": String(memory.get("terrain_semantic", "")),
                "structure": stored_structure.duplicate(true),
                "props": prop_entries,
            })
        var actor_entries: Array = []
        for actor_memory: Dictionary in actor_observations(observer_id):
            var actor_cell: Vector2i = actor_memory.get("cell", Vector2i.ZERO)
            actor_entries.append({
                "actor_id": String(actor_memory.get("actor_id", "")),
                "semantic_type": String(actor_memory.get("semantic_type", "")),
                "cell": [actor_cell.x, actor_cell.y],
                "facing": int(actor_memory.get("facing", -1)),
                "observed_tick": int(actor_memory.get("observed_tick", 0)),
            })
        observer_entries.append({"observer_id": observer_id, "cells": cell_entries, "actors": actor_entries})
    return {"schema_version": SNAPSHOT_SCHEMA_VERSION, "observers": observer_entries}

func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var observer_values: Variant = data.get("observers", [])
    if typeof(observer_values) != TYPE_ARRAY:
        return false

    var restored: Dictionary = {}
    for observer_value: Variant in observer_values:
        if typeof(observer_value) != TYPE_DICTIONARY:
            return false
        var observer_data: Dictionary = observer_value
        var observer_id: String = String(observer_data.get("observer_id", "")).strip_edges()
        if observer_id.is_empty() or restored.has(observer_id):
            return false
        var cells: Dictionary = {}
        var actors: Dictionary = {}
        var cells_value: Variant = observer_data.get("cells", [])
        var actors_value: Variant = observer_data.get("actors", [])
        if typeof(cells_value) != TYPE_ARRAY or typeof(actors_value) != TYPE_ARRAY:
            return false
        for cell_value: Variant in cells_value:
            if typeof(cell_value) != TYPE_DICTIONARY:
                return false
            var cell_data: Dictionary = cell_value
            var cell_array: Variant = cell_data.get("cell", [])
            if typeof(cell_array) != TYPE_ARRAY or cell_array.size() != 2:
                return false
            var cell := Vector2i(int(cell_array[0]), int(cell_array[1]))
            var terrain: String = String(cell_data.get("terrain_semantic", "")).strip_edges()
            var observed_tick: int = int(cell_data.get("observed_tick", -1))
            var structure_value: Variant = cell_data.get("structure", {})
            var props_value: Variant = cell_data.get("props", [])
            if terrain.is_empty() or observed_tick < 0 or typeof(structure_value) != TYPE_DICTIONARY or typeof(props_value) != TYPE_ARRAY or cells.has(cell):
                return false
            var structure_data: Dictionary = structure_value
            var restored_props: Array[Dictionary] = []
            for prop_value: Variant in props_value:
                if typeof(prop_value) != TYPE_DICTIONARY:
                    return false
                var prop_data: Dictionary = prop_value
                var entity_id: String = String(prop_data.get("entity_id", "")).strip_edges()
                var semantic: String = String(prop_data.get("semantic_type", "")).strip_edges()
                var anchor_value: Variant = prop_data.get("anchor", [])
                var facing: int = int(prop_data.get("facing", -1))
                if entity_id.is_empty() or semantic.is_empty() or typeof(anchor_value) != TYPE_ARRAY or anchor_value.size() != 2 or facing < 0 or facing > 3:
                    return false
                restored_props.append({
                    "entity_id": entity_id,
                    "semantic_type": semantic,
                    "anchor": Vector2i(int(anchor_value[0]), int(anchor_value[1])),
                    "facing": facing,
                })
            var normalized: Dictionary = _normalize_props(restored_props)
            if not bool(normalized.get("ok", false)):
                return false
            cells[cell] = {
                "cell": cell,
                "observed_tick": observed_tick,
                "terrain_semantic": terrain,
                "structure": structure_data.duplicate(true),
                "props": normalized.get("props", []).duplicate(true),
            }
        for actor_value: Variant in actors_value:
            if typeof(actor_value) != TYPE_DICTIONARY:
                return false
            var actor_data: Dictionary = actor_value
            var actor_id: String = String(actor_data.get("actor_id", "")).strip_edges()
            var semantic: String = String(actor_data.get("semantic_type", "")).strip_edges()
            var actor_cell_value: Variant = actor_data.get("cell", [])
            var observed_actor_tick: int = int(actor_data.get("observed_tick", -1))
            if actor_id.is_empty() or semantic.is_empty() or observed_actor_tick < 0 or actors.has(actor_id):
                return false
            if typeof(actor_cell_value) != TYPE_ARRAY or actor_cell_value.size() != 2:
                return false
            actors[actor_id] = {
                "observer_id": observer_id,
                "actor_id": actor_id,
                "semantic_type": semantic,
                "cell": Vector2i(int(actor_cell_value[0]), int(actor_cell_value[1])),
                "facing": int(actor_data.get("facing", -1)),
                "observed_tick": observed_actor_tick,
            }
        restored[observer_id] = {"cells": cells, "actors": actors}

    _observers = restored
    return true

func _normalize_props(values: Array) -> Dictionary:
    var result: Array[Dictionary] = []
    var seen_ids: Dictionary = {}
    for value: Variant in values:
        if typeof(value) != TYPE_DICTIONARY:
            return {"ok": false, "props": []}
        var prop: Dictionary = value
        var entity_id: String = String(prop.get("entity_id", "")).strip_edges()
        var semantic: String = String(prop.get("semantic_type", "")).strip_edges()
        var anchor_value: Variant = prop.get("anchor", null)
        var facing: int = int(prop.get("facing", -1))
        if entity_id.is_empty() or semantic.is_empty() or typeof(anchor_value) != TYPE_VECTOR2I or facing < 0 or facing > 3 or seen_ids.has(entity_id):
            return {"ok": false, "props": []}
        seen_ids[entity_id] = true
        result.append({
            "entity_id": entity_id,
            "semantic_type": semantic,
            "anchor": anchor_value,
            "facing": facing,
        })
    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("entity_id", "")) < String(b.get("entity_id", ""))
    )
    return {"ok": true, "props": result}

func _observer_record(observer_id: String) -> Dictionary:
    if not _observers.has(observer_id):
        return {}
    return _observers[observer_id]

static func _cell_less(a: Vector2i, b: Vector2i) -> bool:
    if a.y == b.y:
        return a.x < b.x
    return a.y < b.y
