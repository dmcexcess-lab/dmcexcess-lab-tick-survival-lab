extends RefCounted
class_name TerrainStore

## Internal semantic terrain store keyed by authoritative global cells.
## Chunk summaries accelerate exact bulk rectangle rewrites without changing the
## cell-authoritative storage/query contract.

const BULK_CHUNK_SIZE: int = 16
const BULK_CHUNK_AREA: int = BULK_CHUNK_SIZE * BULK_CHUNK_SIZE

var _by_cell: Dictionary = {}
var _chunk_known_counts: Dictionary = {}
var _chunk_type_counts: Dictionary = {}

func has(cell: Vector2i) -> bool:
    return _by_cell.has(cell)

func get_type(cell: Vector2i) -> StringName:
    return StringName(_by_cell.get(cell, &""))

func set_type(cell: Vector2i, semantic_type: StringName) -> void:
    var had_previous: bool = _by_cell.has(cell)
    var previous: StringName = StringName(_by_cell.get(cell, &""))
    if had_previous and previous == semantic_type:
        return

    var chunk: Vector2i = _chunk_coord(cell)
    var counts: Dictionary = _chunk_type_counts.get(chunk, {})
    if had_previous:
        var previous_count: int = int(counts.get(previous, 0))
        if previous_count <= 1:
            counts.erase(previous)
        else:
            counts[previous] = previous_count - 1
    else:
        _chunk_known_counts[chunk] = int(_chunk_known_counts.get(chunk, 0)) + 1

    counts[semantic_type] = int(counts.get(semantic_type, 0)) + 1
    _chunk_type_counts[chunk] = counts
    _by_cell[cell] = semantic_type

## Exact bulk rectangle assignment. Fully known 16x16 chunks that already carry
## the requested semantic are skipped without touching their cells. Mixed/full
## chunks are rewritten directly and partial edge chunks preserve cell-level
## behavior. The returned counters are diagnostics only.
func set_rect_type(rect: Rect2i, semantic_type: StringName) -> Dictionary:
    var result: Dictionary = {
        "ok": false,
        "changed_any": false,
        "changed_cells": 0,
        "visited_cells": 0,
        "skipped_cells": 0,
        "skipped_chunks": 0,
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
                var known_count: int = int(_chunk_known_counts.get(chunk, 0))
                var counts: Dictionary = _chunk_type_counts.get(chunk, {})
                var matching_count: int = int(counts.get(semantic_type, 0))
                if known_count == BULK_CHUNK_AREA and matching_count == BULK_CHUNK_AREA:
                    result["skipped_cells"] = int(result["skipped_cells"]) + BULK_CHUNK_AREA
                    result["skipped_chunks"] = int(result["skipped_chunks"]) + 1
                    continue

                for y in range(chunk_origin.y, chunk_origin.y + BULK_CHUNK_SIZE):
                    for x in range(chunk_origin.x, chunk_origin.x + BULK_CHUNK_SIZE):
                        _by_cell[Vector2i(x, y)] = semantic_type
                result["visited_cells"] = int(result["visited_cells"]) + BULK_CHUNK_AREA
                result["changed_cells"] = int(result["changed_cells"]) + (BULK_CHUNK_AREA - matching_count)
                _chunk_known_counts[chunk] = BULK_CHUNK_AREA
                var uniform_counts: Dictionary = {}
                uniform_counts[semantic_type] = BULK_CHUNK_AREA
                _chunk_type_counts[chunk] = uniform_counts
                continue

            for y in range(start_y, end_y):
                for x in range(start_x, end_x):
                    var cell := Vector2i(x, y)
                    result["visited_cells"] = int(result["visited_cells"]) + 1
                    if _by_cell.has(cell) and StringName(_by_cell[cell]) == semantic_type:
                        result["skipped_cells"] = int(result["skipped_cells"]) + 1
                        continue
                    set_type(cell, semantic_type)
                    result["changed_cells"] = int(result["changed_cells"]) + 1

    result["changed_any"] = int(result["changed_cells"]) > 0
    result["ok"] = true
    return result

func erase(cell: Vector2i) -> void:
    if not _by_cell.has(cell):
        return
    var previous: StringName = StringName(_by_cell[cell])
    var chunk: Vector2i = _chunk_coord(cell)
    var counts: Dictionary = _chunk_type_counts.get(chunk, {})
    var previous_count: int = int(counts.get(previous, 0))
    if previous_count <= 1:
        counts.erase(previous)
    else:
        counts[previous] = previous_count - 1

    var known_count: int = int(_chunk_known_counts.get(chunk, 0)) - 1
    if known_count <= 0:
        _chunk_known_counts.erase(chunk)
        _chunk_type_counts.erase(chunk)
    else:
        _chunk_known_counts[chunk] = known_count
        _chunk_type_counts[chunk] = counts
    _by_cell.erase(cell)

func clear() -> void:
    _by_cell.clear()
    _chunk_known_counts.clear()
    _chunk_type_counts.clear()

func snapshot_entries() -> Array:
    var cells: Array = _by_cell.keys()
    cells.sort_custom(_cell_less)
    var entries: Array = []
    for value: Variant in cells:
        var cell: Vector2i = value
        entries.append({
            "cell": [cell.x, cell.y],
            "semantic_type": String(_by_cell[cell]),
        })
    return entries

static func _chunk_coord(cell: Vector2i) -> Vector2i:
    return Vector2i(
        floori(float(cell.x) / float(BULK_CHUNK_SIZE)),
        floori(float(cell.y) / float(BULK_CHUNK_SIZE))
    )

static func _cell_less(a: Variant, b: Variant) -> bool:
    var cell_a: Vector2i = a
    var cell_b: Vector2i = b
    if cell_a.y == cell_b.y:
        return cell_a.x < cell_b.x
    return cell_a.y < cell_b.y
