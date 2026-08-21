extends Node
class_name DoorPointerInputAdapter

## Device-only pointer/touch -> world-cell adapter. Simulation legality lives elsewhere.
## Screen coordinates are transformed back through the active canvas/camera transform
## before the existing world-view cell mapping is applied.

signal world_cell_primary(cell: Vector2i)

const TOUCH_TAP_MAX_DISTANCE: float = 14.0

var _enabled: bool = true
var _world_view_origin: Vector2 = Vector2.ZERO
var _visible_origin: Vector2i = Vector2i.ZERO
var _visible_size: Vector2i = Vector2i.ZERO
var _cell_pixels: float = 0.0
var _suppress_mouse_until_ms: int = 0
var _touch_positions: Dictionary = {}
var _primary_touch_index: int = -1
var _primary_touch_start: Vector2 = Vector2.ZERO
var _primary_touch_canceled: bool = false

func configure(world_view_origin: Vector2, visible_origin: Vector2i, visible_size: Vector2i, cell_pixels: float) -> bool:
    if visible_size.x <= 0 or visible_size.y <= 0 or cell_pixels <= 0.0:
        return false
    _world_view_origin = world_view_origin
    _visible_origin = visible_origin
    _visible_size = visible_size
    _cell_pixels = cell_pixels
    return true

func set_enabled(value: bool) -> void:
    _enabled = value
    if not value:
        _reset_touch_tracking()

func is_enabled() -> bool:
    return _enabled

func world_cell_for_screen(screen_position: Vector2) -> Variant:
    if _cell_pixels <= 0.0:
        return null
    var canvas_position: Vector2 = screen_position
    if is_inside_tree():
        canvas_position = get_viewport().get_canvas_transform().affine_inverse() * screen_position
    var local: Vector2 = canvas_position - _world_view_origin
    if local.x < 0.0 or local.y < 0.0:
        return null
    var local_cell := Vector2i(int(floor(local.x / _cell_pixels)), int(floor(local.y / _cell_pixels)))
    if local_cell.x < 0 or local_cell.y < 0 or local_cell.x >= _visible_size.x or local_cell.y >= _visible_size.y:
        return null
    return _visible_origin + local_cell

func _unhandled_input(event: InputEvent) -> void:
    if not _enabled:
        return
    var now_ms: int = Time.get_ticks_msec()
    if event is InputEventScreenTouch:
        _handle_touch(event as InputEventScreenTouch, now_ms)
        return
    if event is InputEventScreenDrag:
        _handle_touch_drag(event as InputEventScreenDrag)
        return
    if event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
            return
        if now_ms <= _suppress_mouse_until_ms:
            get_viewport().set_input_as_handled()
            return
        _emit_position(mouse.position)
        get_viewport().set_input_as_handled()

func _handle_touch(event: InputEventScreenTouch, now_ms: int) -> void:
    _suppress_mouse_until_ms = now_ms + 500
    if event.pressed:
        _touch_positions[event.index] = event.position
        if _touch_positions.size() == 1:
            _primary_touch_index = event.index
            _primary_touch_start = event.position
            _primary_touch_canceled = false
        else:
            _primary_touch_canceled = true
        return

    var should_emit: bool = (
        event.index == _primary_touch_index
        and not _primary_touch_canceled
        and _touch_positions.size() == 1
        and _primary_touch_start.distance_to(event.position) <= TOUCH_TAP_MAX_DISTANCE
    )
    _touch_positions.erase(event.index)
    if event.index == _primary_touch_index:
        _primary_touch_index = -1
        _primary_touch_canceled = false
    if _touch_positions.size() > 0:
        _primary_touch_canceled = true
    if should_emit:
        _emit_position(event.position)

func _handle_touch_drag(event: InputEventScreenDrag) -> void:
    if not _touch_positions.has(event.index):
        return
    _touch_positions[event.index] = event.position
    if event.index == _primary_touch_index \
        and _primary_touch_start.distance_to(event.position) > TOUCH_TAP_MAX_DISTANCE:
        _primary_touch_canceled = true
    if _touch_positions.size() > 1:
        _primary_touch_canceled = true

func _reset_touch_tracking() -> void:
    _touch_positions.clear()
    _primary_touch_index = -1
    _primary_touch_start = Vector2.ZERO
    _primary_touch_canceled = false

func _emit_position(position: Vector2) -> void:
    var cell_value: Variant = world_cell_for_screen(position)
    if cell_value == null:
        return
    world_cell_primary.emit(cell_value as Vector2i)
