extends RefCounted
class_name TerrainStore

## Internal semantic terrain store keyed by authoritative global cells.
## Uniform full chunks are represented compactly; sparse overrides and explicit
## holes preserve exact cell-authoritative query semantics.

const BULK_CHUNK_SIZE: int = 16
const BULK_CHUNK_AREA: int = BULK_CHUNK_SIZE * BULK_CHUNK_SIZE

## A chunk default means every cell in that 16x16 chunk is known with that
## semantic unless a sparse override or explicit hole says otherwise.
var _chunk_defaults: Dictionary = {}
## Without a default these are ordinary known cells; with a default they are
## sparse semantic overrides.
var _chunk_cells: Dictionary = {}
## Holes are explicit unknown cells inside an otherwise fully known default chunk.
var _chunk_holes: Dictionary = {}

func has(cell: Vector2i) -> bool:
    var chunk: Vector2i = _chunk_coord(cell)
    var index: int = _local_index(cell)
    var cells: Dictionary = _chunk_cells.get(chunk, {})
    if cells.has(index):
        return true
    if not _chunk_defaults.has(chunk):
        return false
    var holes: Dictionary = _chunk_holes.get(chunk, {})
    return not holes.has(index)

func get_type(cell: Vector2i) -> StringName:
    var chunk: Vector2i = _chunk_coord(cell)
    var index: int = _local_index(cell)
    var cells: Dictionary = _chunk_cells.get(chunk, {})
    if cells.has(index):
        return StringName(cells[index])
    if not _chunk_defaults.has(chunk):
        return &""
    var holes: Dictionary = _chunk_holes.get(chunk, {})
    if holes.has(index):
        return &""
    return StringName(_chunk_defaults[chunk])

func set_type(cell: Vector2i, semantic_type: StringName) -> void:
    var chunk: Vector2i = _chunk_coord(cell)
    var index: int = _local_index(cell)
    var cells: Dictionary = _chunk_cells.get(chunk, {})

    if _chunk_defaults.has(chunk):
        var default_type: StringName = StringName(_chunk_defaults[chunk])
        var holes: Dictionary = _chunk_holes.get(chunk, {})
        holes.erase(index)
        if holes.is_empty():
            _chunk_holes.erase(chunk)
        else:
            _chunk_holes[chunk] = holes

        if semantic_type == default_type:
            cells.erase(index)
        else:
            cells[index] = semantic_type
        if cells.is_empty():
            _chunk_cells.erase(chunk)
        else:
            _chunk_cells[chunk] = cells
        return

    cells[index] = semantic_type
    _chunk_cells[chunk] = cells
    if cells.size() == BULK_CHUNK_AREA:
        _try_compress_complete_chunk(chunk)

## Exact bulk rectangle assignment. Fully covered chunks are assigned as one
## compact semantic default instead of performing 256 Dictionary writes. Only
## partial edge chunks and sparse exceptions are inspected cell-by-cell.
func set_rect_type(rect: Rect2i, semantic_type: StringName) -> Dictionary:
    var result: Dictionary = {
        "ok": false,
        "changed_any": false,
        "changed_cells": 0,
        "visited_cells": 0,
        "skipped_cells": 0,
        "skipped_chunks": 0,
        "compact_chunks": 0,
    }
    if rect.size.x <= 0 or rect.size.y <= 0 or String(semantic_type).strip_edges().is_empty():
        return result

    var first_chunk: Vector2i = _chunk_coord(rect.position)
    var last_cell: Vector2i = rect.position + rect.size - Vector2i(1, 1)
    var last_chunk: Vector2i = _chunk_coord(last_cell)
    var rect_end_x: int = rect.position.x + rect.size.x
    var rect_end_y: int = rect.position.y + rect.size.y

    for chunk_y in range(first_chunk.y, last_chunk.y + 1):
        for chunk_x in range(first_chunk.x, last_chunk.x + 1):
            var chunk := Vector2i(chunk_x, chunk_y)
            var chunk_origin := Vector2i(chunk_x * BULK_CHUNK_SIZE, chunk_y * BULK_CHUNK_SIZE)
            var start_x: int = maxi(rect.position.x, chunk_origin.x)
            var start_y: int = maxi(rect.position.y, chunk_origin.y)
            var end_x: int = mini(rect_end_x, chunk_origin.x + BULK_CHUNK_SIZE)
            var end_y: int = mini(rect_end_y, chunk_origin.y + BULK_CHUNK_SIZE)
            var full_chunk: bool = (
                start_x == chunk_origin.x
                and start_y == chunk_origin.y
                and end_x == chunk_origin.x + BULK_CHUNK_SIZE
                and end_y == chunk_origin.y + BULK_CHUNK_SIZE
            )

            if full_chunk:
                var chunk_result: Dictionary = _assign_full_chunk(chunk, semantic_type)
                result["changed_cells"] = int(result["changed_cells"]) + int(chunk_result.get("changed_cells", 0))
                result["visited_cells"] = int(result["visited_cells"]) + int(chunk_result.get("visited_cells", 0))
                result["skipped_cells"] = int(result["skipped_cells"]) + int(chunk_result.get("skipped_cells", 0))
                result["skipped_chunks"] = int(result["skipped_chunks"]) + 1
                result["compact_chunks"] = int(result["compact_chunks"]) + 1
                continue

            for y in range(start_y, end_y):
                for x in range(start_x, end_x):
                    var cell := Vector2i(x, y)
                    result["visited_cells"] = int(result["visited_cells"]) + 1
                    if has(cell) and get_type(cell) == semantic_type:
                        result["skipped_cells"] = int(result["skipped_cells"]) + 1
                        continue
                    set_type(cell, semantic_type)
                    result["changed_cells"] = int(result["changed_cells"]) + 1

    result["changed_any"] = int(result["changed_cells"]) > 0
    result["ok"] = true
    return result

func erase(cell: Vector2i) -> void:
    if not has(cell):
        return
    var chunk: Vector2i = _chunk_coord(cell)
    var index: int = _local_index(cell)
    var cells: Dictionary = _chunk_cells.get(chunk, {})

    if _chunk_defaults.has(chunk):
        cells.erase(index)
        if cells.is_empty():
            _chunk_cells.erase(chunk)
        else:
            _chunk_cells[chunk] = cells
        var holes: Dictionary = _chunk_holes.get(chunk, {})
        holes[index] = true
        _chunk_holes[chunk] = holes
        return

    cells.erase(index)
    if cells.is_empty():
        _chunk_cells.erase(chunk)
    else:
        _chunk_cells[chunk] = cells

func clear() -> void:
    _chunk_defaults.clear()
    _chunk_cells.clear()
    _chunk_holes.clear()

func snapshot_entries() -> Array:
    var chunk_set: Dictionary = {}
    for value: Variant in _chunk_defaults.keys():
        chunk_set[value] = true
    for value: Variant in _chunk_cells.keys():
        chunk_set[value] = true

    var rows: Dictionary = {}
    for value: Variant in chunk_set.keys():
        var chunk: Vector2i = value
        var xs: Array = rows.get(chunk.y, [])
        xs.append(chunk.x)
        rows[chunk.y] = xs

    var ys: Array = rows.keys()
    ys.sort()
    var entries: Array = []
    for y_value: Variant in ys:
        var chunk_y: int = int(y_value)
        var xs: Array = rows[chunk_y]
        xs.sort()
        for local_y in range(BULK_CHUNK_SIZE):
            for x_value: Variant in xs:
                var chunk_x: int = int(x_value)
                var chunk := Vector2i(chunk_x, chunk_y)
                var default_exists: bool = _chunk_defaults.has(chunk)
                var default_type: StringName = StringName(_chunk_defaults.get(chunk, &""))
                var cells: Dictionary = _chunk_cells.get(chunk, {})
                var holes: Dictionary = _chunk_holes.get(chunk, {})
                for local_x in range(BULK_CHUNK_SIZE):
                    var index: int = local_y * BULK_CHUNK_SIZE + local_x
                    var semantic_type: StringName = &""
                    if cells.has(index):
                        semantic_type = StringName(cells[index])
                    elif default_exists and not holes.has(index):
                        semantic_type = default_type
                    else:
                        continue
                    entries.append({
                        "cell": [chunk_x * BULK_CHUNK_SIZE + local_x, chunk_y * BULK_CHUNK_SIZE + local_y],
                        "semantic_type": String(semantic_type),
                    })
    return entries

func _assign_full_chunk(chunk: Vector2i, semantic_type: StringName) -> Dictionary:
    var cells: Dictionary = _chunk_cells.get(chunk, {})
    var holes: Dictionary = _chunk_holes.get(chunk, {})
    var visited: int = cells.size() + holes.size()
    var changed: int = 0

    if _chunk_defaults.has(chunk):
        var default_type: StringName = StringName(_chunk_defaults[chunk])
        if default_type == semantic_type:
            changed = cells.size() + holes.size()
        else:
            var matching_overrides: int = 0
            for value: Variant in cells.values():
                if StringName(value) == semantic_type:
                    matching_overrides += 1
            changed = BULK_CHUNK_AREA - matching_overrides
    else:
        var matching_cells: int = 0
        for value: Variant in cells.values():
            if StringName(value) == semantic_type:
                matching_cells += 1
        changed = BULK_CHUNK_AREA - matching_cells

    _chunk_defaults[chunk] = semantic_type
    _chunk_cells.erase(chunk)
    _chunk_holes.erase(chunk)
    return {
        "changed_cells": changed,
        "visited_cells": visited,
        "skipped_cells": BULK_CHUNK_AREA - visited,
    }

func _try_compress_complete_chunk(chunk: Vector2i) -> void:
    if _chunk_defaults.has(chunk):
        return
    var cells: Dictionary = _chunk_cells.get(chunk, {})
    if cells.size() != BULK_CHUNK_AREA:
        return
    var first: StringName = &""
    var has_first: bool = false
    for value: Variant in cells.values():
        var semantic_type: StringName = StringName(value)
        if not has_first:
            first = semantic_type
            has_first = true
        elif semantic_type != first:
            return
    if not has_first:
        return
    _chunk_defaults[chunk] = first
    _chunk_cells.erase(chunk)

static func _chunk_coord(cell: Vector2i) -> Vector2i:
    return Vector2i(
        floori(float(cell.x) / float(BULK_CHUNK_SIZE)),
        floori(float(cell.y) / float(BULK_CHUNK_SIZE))
    )

static func _local_index(cell: Vector2i) -> int:
    return posmod(cell.y, BULK_CHUNK_SIZE) * BULK_CHUNK_SIZE + posmod(cell.x, BULK_CHUNK_SIZE)
