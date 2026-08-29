extends Node2D
class_name PowerLinePresentationRenderer

## Event-driven overhead-wire presentation for real persistent utility supports.
## Wire edges are cached 00D4 topology projection. Electrical service state never owns visibility.

const WIRE_COLOR := Color(0.10, 0.11, 0.12, 0.92)
const WIRE_HIGHLIGHT := Color(0.23, 0.24, 0.25, 0.72)

var _world: WorldState = null
var _wires: Array[Dictionary] = []
var _visible_wires: Array[Dictionary] = []
var _wire_endpoint_ids: Dictionary = {}
var _visible_origin: Vector2i = Vector2i.ZERO
var _visible_size: Vector2i = Vector2i.ZERO
var _cell_pixels: float = 0.0
var _view_valid: bool = false

func configure(world_state: WorldState, wire_edges: Array[Dictionary]) -> bool:
    if world_state == null:
        return false
    _disconnect_world_signals()
    _world = world_state
    _wires = wire_edges.duplicate(true)
    _rebuild_endpoint_index()
    _connect_world_signals()
    _rebuild_visible_wires()
    queue_redraw()
    return true

func is_configured() -> bool:
    return _world != null

func set_visible_window(origin: Vector2i, size_cells: Vector2i, cell_pixels: float) -> bool:
    if size_cells.x <= 0 or size_cells.y <= 0 or cell_pixels <= 0.0:
        return false
    var changed: bool = not _view_valid or origin != _visible_origin or size_cells != _visible_size \
        or not is_equal_approx(cell_pixels, _cell_pixels)
    _visible_origin = origin
    _visible_size = size_cells
    _cell_pixels = cell_pixels
    _view_valid = true
    if changed:
        _rebuild_visible_wires()
        queue_redraw()
    return true

func visible_wire_count() -> int:
    return _visible_wires.size()

func total_wire_count() -> int:
    return _wires.size()

func _draw() -> void:
    if not is_configured() or not _view_valid:
        return
    var width: float = maxf(1.0, _cell_pixels * 0.055)
    var separation: float = maxf(1.0, _cell_pixels * 0.08)
    for wire: Dictionary in _visible_wires:
        var start_placement: WorldPlacement = _world.placement(String(wire.get("start_id", "")))
        var end_placement: WorldPlacement = _world.placement(String(wire.get("end_id", "")))
        if start_placement == null or end_placement == null:
            continue
        var start: Vector2 = _screen_point(start_placement.anchor)
        var finish: Vector2 = _screen_point(end_placement.anchor)
        var delta: Vector2 = finish - start
        var normal: Vector2 = Vector2(0.0, -1.0)
        if delta.length_squared() > 0.001:
            normal = Vector2(-delta.y, delta.x).normalized()
        draw_line(start - normal * separation, finish - normal * separation, WIRE_COLOR, width, true)
        draw_line(start + normal * separation, finish + normal * separation, WIRE_HIGHLIGHT, width, true)

func _screen_point(cell: Vector2i) -> Vector2:
    return (Vector2(cell - _visible_origin) + Vector2(0.5, 0.18)) * _cell_pixels

func _rebuild_endpoint_index() -> void:
    _wire_endpoint_ids.clear()
    for wire: Dictionary in _wires:
        var start_id: String = String(wire.get("start_id", "")).strip_edges()
        var end_id: String = String(wire.get("end_id", "")).strip_edges()
        if not start_id.is_empty():
            _wire_endpoint_ids[start_id] = true
        if not end_id.is_empty():
            _wire_endpoint_ids[end_id] = true

func _rebuild_visible_wires() -> void:
    _visible_wires.clear()
    if not is_configured() or not _view_valid:
        return
    var visible_rect := Rect2i(_visible_origin - Vector2i(2, 2), _visible_size + Vector2i(4, 4))
    for wire: Dictionary in _wires:
        var start_placement: WorldPlacement = _world.placement(String(wire.get("start_id", "")))
        var end_placement: WorldPlacement = _world.placement(String(wire.get("end_id", "")))
        if start_placement == null or end_placement == null:
            continue
        var min_x: int = mini(start_placement.anchor.x, end_placement.anchor.x)
        var min_y: int = mini(start_placement.anchor.y, end_placement.anchor.y)
        var max_x: int = maxi(start_placement.anchor.x, end_placement.anchor.x)
        var max_y: int = maxi(start_placement.anchor.y, end_placement.anchor.y)
        var edge_rect := Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))
        if edge_rect.intersects(visible_rect):
            _visible_wires.append(wire)

func _connect_world_signals() -> void:
    if _world == null:
        return
    var changed_callable := Callable(self, "_on_world_changed")
    var reset_callable := Callable(self, "_on_world_reset")
    if not _world.changed.is_connected(changed_callable):
        _world.changed.connect(changed_callable)
    if not _world.world_reset.is_connected(reset_callable):
        _world.world_reset.connect(reset_callable)

func _disconnect_world_signals() -> void:
    if _world == null:
        return
    var changed_callable := Callable(self, "_on_world_changed")
    var reset_callable := Callable(self, "_on_world_reset")
    if _world.changed.is_connected(changed_callable):
        _world.changed.disconnect(changed_callable)
    if _world.world_reset.is_connected(reset_callable):
        _world.world_reset.disconnect(reset_callable)

func _on_world_changed(change: WorldChange) -> void:
    if change == null or change.entity_id.is_empty() or not _wire_endpoint_ids.has(change.entity_id):
        return
    _rebuild_visible_wires()
    queue_redraw()

func _on_world_reset() -> void:
    _rebuild_visible_wires()
    queue_redraw()
