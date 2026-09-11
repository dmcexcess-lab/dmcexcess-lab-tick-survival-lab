extends RefCounted
class_name TerrainStore

## Internal semantic terrain store keyed by authoritative global cells.
## Cells remain the public truth, while storage is grouped into fixed chunks so
## bulk rectangle writes avoid a global Dictionary<Vector2i, semantic> mutation
## for every terrain cell.

const BULK_CHUNK_SIZE: int = 16
const BULK_CHUNK_AREA: int = BULK_CHUNK_SIZE * BULK_CHUNK_SIZE

## chunk coord -> Array[256] of StringName; empty StringName means unknown cell.
var _chunks: Dictionary = {}
## chunk coord -> Dictionary[StringName, count], maintained for O(1) full-chunk
## equality/change accounting and exact no-op detection.
var _type_counts: Dictionary = {}

func has(cell: Vector2i) -> bool:
    var chunk: Vector2i = _chunk_coord(cell)
    if not _chunks.has(chunk):
        return false
    var values: Array = _chunks[chunk]
    return not String(StringName(values[_local_index(cell)])).is_empty()

func get_type(cell: Vector2i) -> StringName:
    var chunk: Vector2i = _chunk_coord(cell)
    if not _chunks.has(chunk):
        return &""
    var values: Array = _chunks[chunk]
    return StringName(values[_local_index(cell)])

func set_type(cell: Vector2i, semantic_type: StringName) -> void:
    var chunk: Vector2i = _chunk_coord(cell)
    var values: Array = _chunk_values(chunk)
    var counts: Dictionary = _type_counts.get(chunk, {})
    _set_index(values, counts, _local_index(cell), semantic_type)
    _chunks[chunk] = values
    _type_counts[chunk] = counts

## Exact bulk rectangle assignment. Work is grouped by storage chunk. Fully
## covered chunks are assigned with one native Array.fill() and one chunk-map
## update instead of 256 global hash-table writes. Partial edge chunks retain
## exact cell semantics while reusing a single chunk lookup/count map.
func set_rect_type(rect: Rect2i, semantic_type: StringName) -> Dictionary:
    var result: Dictionary = {
        "ok": false,
        "changed_any": false,
        "changed_cells": 0,
        "visited_cells": 0,
        "skipped_cells": 0,
        "skipped_chunks": 0,
        "bulk_assigned_chunks": 0,
        "bulk_assigned_cells": 0,
    }
    if rect.size.x <= 0 or rect.size.y <= 0 or String(semantic_type).strip_edges().is_empty():
        return result

    var first_chunk: Vector2i = _chunk_coord(rect.position)
    var last_cell: Vector2i = rect.position + rect.size - Vector2i.ONE
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
                var counts: Dictionary = _type_counts.get(chunk, {})
                var matching: int = int(counts.get(semantic_type, 0))
                if matching == BULK_CHUNK_AREA:
                    result["skipped_cells"] = int(result["skipped_cells"]) + BULK_CHUNK_AREA
                    result["skipped_chunks"] = int(result["skipped_chunks"]) + 1
                    continue
                var values: Array = _new_chunk(semantic_type)
                _chunks[chunk] = values
                var uniform_counts: Dictionary = {}
                uniform_counts[semantic_type] = BULK_CHUNK_AREA
                _type_counts[chunk] = uniform_counts
                result["changed_cells"] = int(result["changed_cells"]) + (BULK_CHUNK_AREA - matching)
                result["skipped_cells"] = int(result["skipped_cells"]) + matching
                result["bulk_assigned_chunks"] = int(result["bulk_assigned_chunks"]) + 1
                result["bulk_assigned_cells"] = int(result["bulk_assigned_cells"]) + BULK_CHUNK_AREA
                continue

            var values: Array = _chunk_values(chunk)
            var counts: Dictionary = _type_counts.get(chunk, {})
            var changed_in_chunk: bool = false
            for y in range(start_y, end_y):
                var row_index: int = (y - chunk_origin.y) * BULK_CHUNK_SIZE
                for x in range(start_x, end_x):
                    var index: int = row_index + (x - chunk_origin.x)
                    result["visited_cells"] = int(result["visited_cells"]) + 1
                    var previous: StringName = StringName(values[index])
                    if previous == semantic_type:
                        result["skipped_cells"] = int(result["skipped_cells"]) + 1
                        continue
                    _set_index(values, counts, index, semantic_type)
                    result["changed_cells"] = int(result["changed_cells"]) + 1
                    changed_in_chunk = true
            if changed_in_chunk or _chunks.has(chunk):
                _chunks[chunk] = values
                _type_counts[chunk] = counts

    result["changed_any"] = int(result["changed_cells"]) > 0
    result["ok"] = true
    return result

func erase(cell: Vector2i) -> void:
    var chunk: Vector2i = _chunk_coord(cell)
    if not _chunks.has(chunk):
        return
    var values: Array = _chunks[chunk]
    var index: int = _local_index(cell)
    var previous: StringName = StringName(values[index])
    if String(previous).is_empty():
        return

    var counts: Dictionary = _type_counts.get(chunk, {})
    _decrement_count(counts, previous)
    values[index] = &""
    if counts.is_empty():
        _chunks.erase(chunk)
        _type_counts.erase(chunk)
    else:
        _chunks[chunk] = values
        _type_counts[chunk] = counts

func clear() -> void:
    _chunks.clear()
    _type_counts.clear()

func snapshot_entries() -> Array:
    var rows: Dictionary = {}
    for value: Variant in _chunks.keys():
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
                var values: Array = _chunks[chunk]
                for local_x in range(BULK_CHUNK_SIZE):
                    var index: int = local_y * BULK_CHUNK_SIZE + local_x
                    var semantic_type: StringName = StringName(values[index])
                    if String(semantic_type).is_empty():
                        continue
                    entries.append({
                        "cell": [chunk_x * BULK_CHUNK_SIZE + local_x, chunk_y * BULK_CHUNK_SIZE + local_y],
                        "semantic_type": String(semantic_type),
                    })
    return entries

func _chunk_values(chunk: Vector2i) -> Array:
    if _chunks.has(chunk):
        return _chunks[chunk]
    return _new_chunk(&"")

func _new_chunk(fill_type: StringName) -> Array:
    var values: Array = []
    values.resize(BULK_CHUNK_AREA)
    values.fill(fill_type)
    return values

func _set_index(values: Array, counts: Dictionary, index: int, semantic_type: StringName) -> void:
    var previous: StringName = StringName(values[index])
    if previous == semantic_type:
        return
    if not String(previous).is_empty():
        _decrement_count(counts, previous)
    values[index] = semantic_type
    if not String(semantic_type).is_empty():
        counts[semantic_type] = int(counts.get(semantic_type, 0)) + 1

func _decrement_count(counts: Dictionary, semantic_type: StringName) -> void:
    var count: int = int(counts.get(semantic_type, 0))
    if count <= 1:
        counts.erase(semantic_type)
    else:
        counts[semantic_type] = count - 1

static func _chunk_coord(cell: Vector2i) -> Vector2i:
    return Vector2i(
        floori(float(cell.x) / float(BULK_CHUNK_SIZE)),
        floori(float(cell.y) / float(BULK_CHUNK_SIZE))
    )

static func _local_index(cell: Vector2i) -> int:
    return posmod(cell.y, BULK_CHUNK_SIZE) * BULK_CHUNK_SIZE + posmod(cell.x, BULK_CHUNK_SIZE)
