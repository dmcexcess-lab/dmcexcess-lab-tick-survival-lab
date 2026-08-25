extends RefCounted
class_name WorldChangeBatch

## Compact completed-WHAT-batch notification. Authoritative writes still occur
## immediately; this only summarizes dirty domains/bounds for expensive readers.

var label: StringName = &""
var change_count: int = 0
var first_sequence: int = 0
var last_sequence: int = 0
var terrain_changed: bool = false
var _terrain_dirty_rect: Rect2i = Rect2i()
var _terrain_dirty_valid: bool = false
var _channel_dirty_rects: Dictionary = {}
var _kind_counts: Dictionary = {}

func _init(batch_label: StringName = &"") -> void:
    label = batch_label

func include(change: WorldChange) -> void:
    if change == null or not change.is_valid():
        return
    change_count += 1
    if first_sequence == 0:
        first_sequence = change.sequence
    last_sequence = change.sequence
    var kind_label: String = WorldChange.label(change.kind)
    _kind_counts[kind_label] = int(_kind_counts.get(kind_label, 0)) + 1

    if change.is_terrain_change():
        terrain_changed = true
        if change.kind == WorldChange.Kind.TERRAIN_BATCH_SET and change.terrain_rect.size.x > 0 and change.terrain_rect.size.y > 0:
            _include_terrain_rect(change.terrain_rect)
        elif change.kind == WorldChange.Kind.TERRAIN_BATCH_SET:
            _include_terrain_cells(change.terrain_cells)
        else:
            var one_cell: Array[Vector2i] = [change.terrain_cell]
            _include_terrain_cells(one_cell)

    if change.before_channel >= 0:
        _include_channel_cells(change.before_channel, change.before_cells)
    if change.after_channel >= 0:
        _include_channel_cells(change.after_channel, change.after_cells)

func channel_changed(channel: int) -> bool:
    return _channel_dirty_rects.has(channel)

func dirty_rect_for_channel(channel: int) -> Rect2i:
    return _channel_dirty_rects.get(channel, Rect2i())

func terrain_dirty_bounds() -> Rect2i:
    return _terrain_dirty_rect if _terrain_dirty_valid else Rect2i()

func kind_counts() -> Dictionary:
    return _kind_counts.duplicate(true)

func copy() -> WorldChangeBatch:
    var result := WorldChangeBatch.new(label)
    result.change_count = change_count
    result.first_sequence = first_sequence
    result.last_sequence = last_sequence
    result.terrain_changed = terrain_changed
    result._terrain_dirty_rect = _terrain_dirty_rect
    result._terrain_dirty_valid = _terrain_dirty_valid
    result._channel_dirty_rects = _channel_dirty_rects.duplicate(true)
    result._kind_counts = _kind_counts.duplicate(true)
    return result

func to_debug_dict() -> Dictionary:
    return {
        "label": String(label),
        "change_count": change_count,
        "first_sequence": first_sequence,
        "last_sequence": last_sequence,
        "terrain_changed": terrain_changed,
        "terrain_dirty_rect": terrain_dirty_bounds(),
        "channel_dirty_rects": _channel_dirty_rects.duplicate(true),
        "kind_counts": kind_counts(),
    }

func _include_terrain_rect(rect: Rect2i) -> void:
    if rect.size.x <= 0 or rect.size.y <= 0:
        return
    if not _terrain_dirty_valid:
        _terrain_dirty_rect = rect
        _terrain_dirty_valid = true
    else:
        _terrain_dirty_rect = _terrain_dirty_rect.merge(rect)

func _include_terrain_cells(cells: Array[Vector2i]) -> void:
    var rect: Rect2i = _rect_for_cells(cells)
    if rect.size.x > 0 and rect.size.y > 0:
        _include_terrain_rect(rect)

func _include_channel_cells(channel: int, cells: Array[Vector2i]) -> void:
    var rect: Rect2i = _rect_for_cells(cells)
    if rect.size.x <= 0 or rect.size.y <= 0:
        return
    if not _channel_dirty_rects.has(channel):
        _channel_dirty_rects[channel] = rect
    else:
        var previous: Rect2i = _channel_dirty_rects[channel]
        _channel_dirty_rects[channel] = previous.merge(rect)

static func _rect_for_cells(cells: Array[Vector2i]) -> Rect2i:
    if cells.is_empty():
        return Rect2i()
    var min_x: int = cells[0].x
    var min_y: int = cells[0].y
    var max_x: int = min_x
    var max_y: int = min_y
    for cell: Vector2i in cells:
        min_x = mini(min_x, cell.x)
        min_y = mini(min_y, cell.y)
        max_x = maxi(max_x, cell.x)
        max_y = maxi(max_y, cell.y)
    return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
