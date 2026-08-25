extends Node2D
class_name InteractionHighlightRenderer

## Presentation-only System-29 highlight layer. It draws a restrained pixel-native
## corner outline for already-valid, currently-visible interaction targets. It emits
## no physical light and never decides whether an action exists.
##
## Signal-driven refreshes are coalesced to one deferred refresh. Streaming and
## perception can legitimately emit several synchronous invalidations during one
## committed player step; presentation only needs the final state before drawing.

signal redraw_requested(reason: StringName)

const HIGHLIGHT_COLOR := Color(1.0, 0.86, 0.42, 0.92)

var _query: InteractionAffordanceQuery = null
var _visible_origin: Vector2i = Vector2i.ZERO
var _visible_size: Vector2i = Vector2i.ZERO
var _cell_pixels: float = 0.0
var _view_valid: bool = false
var _highlights: Array[Dictionary] = []
var _refresh_queued: bool = false
var _queued_reason: StringName = &""

func configure(query: InteractionAffordanceQuery) -> bool:
    if query == null or not query.is_ready():
        return false
    _disconnect_query()
    _query = query
    var callback := Callable(self, "_on_affordances_changed")
    if not _query.affordances_changed.is_connected(callback):
        _query.affordances_changed.connect(callback)
    _refresh_queued = false
    _queued_reason = &""
    _refresh(&"configured")
    return true

func is_configured() -> bool:
    return _query != null and _query.is_ready()

func set_visible_window(origin: Vector2i, size_cells: Vector2i, cell_pixels: float) -> bool:
    if size_cells.x <= 0 or size_cells.y <= 0 or cell_pixels <= 0.0:
        return false
    var changed: bool = (
        not _view_valid
        or origin != _visible_origin
        or size_cells != _visible_size
        or not is_equal_approx(cell_pixels, _cell_pixels)
    )
    _visible_origin = origin
    _visible_size = size_cells
    _cell_pixels = cell_pixels
    _view_valid = true
    if changed:
        _request_redraw(&"view_changed")
    return true

func highlight_count() -> int:
    return _highlights.size()

func highlighted_target_ids() -> Array[String]:
    var result: Array[String] = []
    for descriptor: Dictionary in _highlights:
        result.append(String(descriptor.get("target_entity_id", "")))
    result.sort()
    return result

func highlight_descriptors() -> Array[Dictionary]:
    return _highlights.duplicate(true)

func _draw() -> void:
    if not is_configured() or not _view_valid:
        return
    var thickness: float = clampf(roundf(_cell_pixels / 16.0), 1.0, 2.0)
    var tick: float = clampf(roundf(_cell_pixels * 0.25), 3.0, 7.0)
    var inset: float = maxf(1.0, thickness)
    for descriptor: Dictionary in _highlights:
        var cells_value: Variant = descriptor.get("visible_cells", [])
        if typeof(cells_value) != TYPE_ARRAY:
            continue
        for value: Variant in cells_value:
            if typeof(value) != TYPE_VECTOR2I:
                continue
            var cell: Vector2i = value
            if not _cell_in_view(cell):
                continue
            _draw_cell_ticks(_cell_rect(cell), inset, tick, thickness)

func _draw_cell_ticks(rect: Rect2, inset: float, tick: float, thickness: float) -> void:
    var left: float = rect.position.x + inset
    var top: float = rect.position.y + inset
    var right: float = rect.end.x - inset
    var bottom: float = rect.end.y - inset

    draw_line(Vector2(left, top), Vector2(left + tick, top), HIGHLIGHT_COLOR, thickness, false)
    draw_line(Vector2(left, top), Vector2(left, top + tick), HIGHLIGHT_COLOR, thickness, false)
    draw_line(Vector2(right, top), Vector2(right - tick, top), HIGHLIGHT_COLOR, thickness, false)
    draw_line(Vector2(right, top), Vector2(right, top + tick), HIGHLIGHT_COLOR, thickness, false)
    draw_line(Vector2(left, bottom), Vector2(left + tick, bottom), HIGHLIGHT_COLOR, thickness, false)
    draw_line(Vector2(left, bottom), Vector2(left, bottom - tick), HIGHLIGHT_COLOR, thickness, false)
    draw_line(Vector2(right, bottom), Vector2(right - tick, bottom), HIGHLIGHT_COLOR, thickness, false)
    draw_line(Vector2(right, bottom), Vector2(right, bottom - tick), HIGHLIGHT_COLOR, thickness, false)

func _cell_rect(cell: Vector2i) -> Rect2:
    var local: Vector2i = cell - _visible_origin
    return Rect2(
        Vector2(float(local.x) * _cell_pixels, float(local.y) * _cell_pixels),
        Vector2(_cell_pixels, _cell_pixels)
    )

func _cell_in_view(cell: Vector2i) -> bool:
    return _view_valid \
        and cell.x >= _visible_origin.x and cell.x < _visible_origin.x + _visible_size.x \
        and cell.y >= _visible_origin.y and cell.y < _visible_origin.y + _visible_size.y

func _refresh(reason: StringName) -> void:
    _highlights = [] if _query == null else _query.highlight_descriptors()
    _request_redraw(reason)

func _queue_refresh(reason: StringName) -> void:
    _queued_reason = reason
    if _refresh_queued:
        return
    _refresh_queued = true
    call_deferred("_flush_queued_refresh")

func _flush_queued_refresh() -> void:
    if not _refresh_queued:
        return
    _refresh_queued = false
    var reason: StringName = _queued_reason
    _queued_reason = &""
    _refresh(reason)

func _request_redraw(reason: StringName) -> void:
    redraw_requested.emit(reason)
    queue_redraw()

func _on_affordances_changed(_reason: StringName) -> void:
    _queue_refresh(&"affordances_changed")

func _disconnect_query() -> void:
    if _query == null:
        return
    var callback := Callable(self, "_on_affordances_changed")
    if _query.affordances_changed.is_connected(callback):
        _query.affordances_changed.disconnect(callback)