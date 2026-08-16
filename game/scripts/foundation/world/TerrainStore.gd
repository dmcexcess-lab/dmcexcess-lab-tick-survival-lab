extends RefCounted
class_name TerrainStore

## Internal semantic terrain store keyed by authoritative global cells.

var _by_cell: Dictionary = {}

func has(cell: Vector2i) -> bool:
    return _by_cell.has(cell)

func get_type(cell: Vector2i) -> StringName:
    return StringName(_by_cell.get(cell, &""))

func set_type(cell: Vector2i, semantic_type: StringName) -> void:
    _by_cell[cell] = semantic_type

func erase(cell: Vector2i) -> void:
    _by_cell.erase(cell)

func clear() -> void:
    _by_cell.clear()

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

static func _cell_less(a: Variant, b: Variant) -> bool:
    var cell_a: Vector2i = a
    var cell_b: Vector2i = b
    if cell_a.y == cell_b.y:
        return cell_a.x < cell_b.x
    return cell_a.y < cell_b.y
