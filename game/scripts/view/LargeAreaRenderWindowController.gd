extends Node
class_name LargeAreaRenderWindowController

const EDGE_BUFFER_CELLS: int = 12

var _renderer: TacticalRendererStack = null
var _world_view: Node2D = null
var _door_pointer: DoorPointerInputAdapter = null
var _camera_controller: TacticalCameraController = null
var _area_bounds: Rect2i = Rect2i()
var _window_size: Vector2i = Vector2i.ZERO
var _cell_pixels: float = 0.0
var _base_pixel_origin: Vector2 = Vector2.ZERO
var _render_origin: Vector2i = Vector2i.ZERO
var _configured: bool = false
var _shifting: bool = false

func configure(
    renderer: TacticalRendererStack,
    world_view: Node2D,
    door_pointer: DoorPointerInputAdapter,
    area_bounds: Rect2i,
    window_size: Vector2i,
    cell_pixels: float,
    initial_origin: Vector2i,
    base_pixel_origin: Vector2 = Vector2.ZERO
) -> bool:
    if renderer == null or world_view == null or door_pointer == null:
        return false
    if area_bounds.size.x <= 0 or area_bounds.size.y <= 0 or window_size.x <= 0 or window_size.y <= 0 or cell_pixels <= 0.0:
        return false
    if window_size.x > area_bounds.size.x or window_size.y > area_bounds.size.y:
        return false
    _renderer = renderer
    _world_view = world_view
    _door_pointer = door_pointer
    _area_bounds = area_bounds
    _window_size = window_size
    _cell_pixels = cell_pixels
    _base_pixel_origin = base_pixel_origin
    _configured = true
    return _apply_window(_clamp_origin(initial_origin), false)

func attach_camera(camera_controller: TacticalCameraController) -> bool:
    if not _configured or camera_controller == null or not camera_controller.is_configured():
        return false
    if _camera_controller != null:
        var old_callable := Callable(self, "_on_camera_presentation_changed")
        if _camera_controller.presentation_changed.is_connected(old_callable):
            _camera_controller.presentation_changed.disconnect(old_callable)
    _camera_controller = camera_controller
    var changed_callable := Callable(self, "_on_camera_presentation_changed")
    if not _camera_controller.presentation_changed.is_connected(changed_callable):
        _camera_controller.presentation_changed.connect(changed_callable)
    if not _camera_controller.set_render_window(_render_origin, _cell_pixels, _world_view):
        return false
    _on_camera_presentation_changed(_camera_controller.presentation_snapshot())
    return true

func is_configured() -> bool:
    return _configured

func render_origin() -> Vector2i:
    return _render_origin

func render_size() -> Vector2i:
    return _window_size

func area_bounds() -> Rect2i:
    return _area_bounds

func cell_pixels() -> float:
    return _cell_pixels

func world_cell_global_center(cell: Vector2i) -> Vector2:
    return _base_pixel_origin + Vector2(
        (float(cell.x - _area_bounds.position.x) + 0.5) * _cell_pixels,
        (float(cell.y - _area_bounds.position.y) + 0.5) * _cell_pixels
    )

func presentation_snapshot() -> Dictionary:
    return {
        "configured": _configured,
        "area_bounds": _area_bounds,
        "render_origin": _render_origin,
        "render_size": _window_size,
        "cell_pixels": _cell_pixels,
        "world_view_position": Vector2.ZERO if _world_view == null else _world_view.position,
    }

func _on_camera_presentation_changed(snapshot: Dictionary) -> void:
    if not _configured or _shifting:
        return
    var camera_position: Vector2 = snapshot.get("camera_global_position", Vector2.ZERO)
    var camera_cell: Vector2i = _world_cell_for_global_position(camera_position)
    if not _area_bounds.has_point(camera_cell):
        return
    if not _needs_shift(camera_cell):
        return
    var desired := camera_cell - Vector2i(_window_size.x / 2, _window_size.y / 2)
    _apply_window(_clamp_origin(desired), true)

func _apply_window(origin: Vector2i, notify_camera: bool) -> bool:
    if not _configured:
        return false
    _shifting = true
    _render_origin = origin
    var offset_cells: Vector2i = _render_origin - _area_bounds.position
    _world_view.position = _base_pixel_origin + Vector2(float(offset_cells.x), float(offset_cells.y)) * _cell_pixels
    var ok: bool = _renderer.set_visible_window(_render_origin, _window_size, _cell_pixels)
    if ok:
        ok = _door_pointer.configure(_world_view.position, _render_origin, _window_size, _cell_pixels)
    if ok and notify_camera and _camera_controller != null and _camera_controller.is_configured():
        ok = _camera_controller.set_render_window(_render_origin, _cell_pixels, _world_view)
    _shifting = false
    return ok

func _needs_shift(cell: Vector2i) -> bool:
    var local: Vector2i = cell - _render_origin
    return local.x < EDGE_BUFFER_CELLS \
        or local.y < EDGE_BUFFER_CELLS \
        or local.x >= _window_size.x - EDGE_BUFFER_CELLS \
        or local.y >= _window_size.y - EDGE_BUFFER_CELLS

func _clamp_origin(origin: Vector2i) -> Vector2i:
    var max_origin: Vector2i = _area_bounds.position + _area_bounds.size - _window_size
    return Vector2i(
        clampi(origin.x, _area_bounds.position.x, max_origin.x),
        clampi(origin.y, _area_bounds.position.y, max_origin.y)
    )

func _world_cell_for_global_position(position: Vector2) -> Vector2i:
    var relative: Vector2 = (position - _base_pixel_origin) / _cell_pixels
    return _area_bounds.position + Vector2i(int(floor(relative.x)), int(floor(relative.y)))
