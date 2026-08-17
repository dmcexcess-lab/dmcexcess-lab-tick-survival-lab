extends Node
class_name DoorPointerInputAdapter

## Device-only pointer/touch -> world-cell adapter. Simulation legality lives elsewhere.

signal world_cell_primary(cell: Vector2i)

var _enabled: bool = true
var _world_view_origin: Vector2 = Vector2.ZERO
var _visible_origin: Vector2i = Vector2i.ZERO
var _visible_size: Vector2i = Vector2i.ZERO
var _cell_pixels: float = 0.0
var _suppress_mouse_until_ms: int = 0

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

func is_enabled() -> bool:
    return _enabled

func world_cell_for_screen(screen_position: Vector2) -> Variant:
    if _cell_pixels <= 0.0:
        return null
    var local: Vector2 = screen_position - _world_view_origin
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
        var touch := event as InputEventScreenTouch
        if not touch.pressed:
            return
        _suppress_mouse_until_ms = now_ms + 500
        _emit_position(touch.position)
        get_viewport().set_input_as_handled()
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

func _emit_position(position: Vector2) -> void:
    var cell_value: Variant = world_cell_for_screen(position)
    if cell_value == null:
        return
    world_cell_primary.emit(cell_value as Vector2i)
