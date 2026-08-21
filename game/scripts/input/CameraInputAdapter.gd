extends Node
class_name CameraInputAdapter

signal zoom_in_requested
signal zoom_out_requested
signal pan_requested(screen_delta: Vector2)
signal recenter_requested

const PINCH_ZOOM_IN_THRESHOLD: float = 1.18
const PINCH_ZOOM_OUT_THRESHOLD: float = 0.85
const MIN_PINCH_DISTANCE: float = 12.0

var _enabled: bool = true
var _mouse_drag_button: int = 0
var _touches: Dictionary = {}
var _pinch_accumulator: float = 1.0

func set_enabled(value: bool) -> void:
    _enabled = value
    if not value:
        _mouse_drag_button = 0
        _touches.clear()
        _pinch_accumulator = 1.0

func is_enabled() -> bool:
    return _enabled

func tracked_touch_count() -> int:
    return _touches.size()

func _unhandled_input(event: InputEvent) -> void:
    if not _enabled:
        return
    if event is InputEventMouseButton:
        _handle_mouse_button(event as InputEventMouseButton)
        return
    if event is InputEventMouseMotion:
        _handle_mouse_motion(event as InputEventMouseMotion)
        return
    if event is InputEventKey:
        _handle_key(event as InputEventKey)
        return
    if event is InputEventMagnifyGesture:
        _handle_magnify(event as InputEventMagnifyGesture)
        return
    if event is InputEventScreenTouch:
        _handle_screen_touch(event as InputEventScreenTouch)
        return
    if event is InputEventScreenDrag:
        _handle_screen_drag(event as InputEventScreenDrag)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
    if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
        zoom_in_requested.emit()
        get_viewport().set_input_as_handled()
        return
    if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
        zoom_out_requested.emit()
        get_viewport().set_input_as_handled()
        return
    if event.button_index != MOUSE_BUTTON_MIDDLE and event.button_index != MOUSE_BUTTON_RIGHT:
        return
    if event.pressed:
        _mouse_drag_button = event.button_index
    elif _mouse_drag_button == event.button_index:
        _mouse_drag_button = 0
    get_viewport().set_input_as_handled()

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
    if _mouse_drag_button == 0:
        return
    if not event.relative.is_zero_approx():
        pan_requested.emit(event.relative)
    get_viewport().set_input_as_handled()

func _handle_key(event: InputEventKey) -> void:
    if not event.pressed or event.echo:
        return
    match event.keycode:
        KEY_HOME:
            recenter_requested.emit()
        KEY_BRACKETLEFT:
            zoom_out_requested.emit()
        KEY_BRACKETRIGHT:
            zoom_in_requested.emit()
        _:
            return
    get_viewport().set_input_as_handled()

func _handle_magnify(event: InputEventMagnifyGesture) -> void:
    if event.factor > 1.0:
        zoom_in_requested.emit()
    elif event.factor < 1.0:
        zoom_out_requested.emit()
    else:
        return
    get_viewport().set_input_as_handled()

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
    if event.pressed:
        _touches[event.index] = event.position
        if _touches.size() >= 2:
            _pinch_accumulator = 1.0
    else:
        _touches.erase(event.index)
        if _touches.size() < 2:
            _pinch_accumulator = 1.0

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
    if not _touches.has(event.index):
        _touches[event.index] = event.position
        return
    if _touches.size() < 2:
        _touches[event.index] = event.position
        return

    var before: Array[Vector2] = _first_two_touch_positions()
    _touches[event.index] = event.position
    var after: Array[Vector2] = _first_two_touch_positions()
    if before.size() < 2 or after.size() < 2:
        return

    var before_center: Vector2 = (before[0] + before[1]) * 0.5
    var after_center: Vector2 = (after[0] + after[1]) * 0.5
    var pan_delta: Vector2 = after_center - before_center
    if not pan_delta.is_zero_approx():
        pan_requested.emit(pan_delta)

    var before_distance: float = before[0].distance_to(before[1])
    var after_distance: float = after[0].distance_to(after[1])
    if before_distance < MIN_PINCH_DISTANCE or after_distance < MIN_PINCH_DISTANCE:
        return
    _pinch_accumulator *= after_distance / before_distance
    if _pinch_accumulator >= PINCH_ZOOM_IN_THRESHOLD:
        zoom_in_requested.emit()
        _pinch_accumulator = 1.0
    elif _pinch_accumulator <= PINCH_ZOOM_OUT_THRESHOLD:
        zoom_out_requested.emit()
        _pinch_accumulator = 1.0

func _first_two_touch_positions() -> Array[Vector2]:
    var ids: Array[int] = []
    for key: Variant in _touches.keys():
        ids.append(int(key))
    ids.sort()
    var result: Array[Vector2] = []
    for index in range(mini(2, ids.size())):
        var value: Variant = _touches[ids[index]]
        if typeof(value) == TYPE_VECTOR2:
            result.append(value)
    return result
