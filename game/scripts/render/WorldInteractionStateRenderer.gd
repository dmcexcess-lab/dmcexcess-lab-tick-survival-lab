extends Node2D
class_name WorldInteractionStateRenderer

## Presentation-only overlay for persistent world-interaction state. Backend state and
## collision remain authoritative; this layer only makes boards, breakage, locks and
## open windows legible on the tactical grid.

const BOARD_COLOR := Color(0.55, 0.34, 0.16, 1.0)
const BREAK_COLOR := Color(0.55, 0.08, 0.06, 0.95)
const LOCK_COLOR := Color(0.9, 0.72, 0.18, 0.95)
const OPEN_COLOR := Color(0.35, 0.8, 0.95, 0.9)

var _world: WorldState = null
var _state: WorldInteractableState = null
var _origin := Vector2i.ZERO
var _size := Vector2i.ZERO
var _cell_pixels: float = 0.0
var _view_valid: bool = false

func configure(world: WorldState, state: WorldInteractableState) -> bool:
    if world == null or state == null:
        return false
    _world = world
    _state = state
    var changed := Callable(self, "_on_state_changed")
    var reset := Callable(self, "_on_state_reset")
    if not _state.state_changed.is_connected(changed):
        _state.state_changed.connect(changed)
    if not _state.state_reset.is_connected(reset):
        _state.state_reset.connect(reset)
    queue_redraw()
    return true

func is_configured() -> bool:
    return _world != null and _state != null

func set_visible_window(origin: Vector2i, size_cells: Vector2i, cell_pixels: float) -> bool:
    if size_cells.x <= 0 or size_cells.y <= 0 or cell_pixels <= 0.0:
        return false
    _origin = origin
    _size = size_cells
    _cell_pixels = cell_pixels
    _view_valid = true
    queue_redraw()
    return true

func _draw() -> void:
    if not is_configured() or not _view_valid:
        return
    for target_id: String in _state_ids():
        if _state.is_destroyed(target_id) or not _world.has_entity(target_id):
            continue
        var placement: WorldPlacement = _world.placement(target_id)
        if placement == null:
            continue
        for cell: Vector2i in placement.world_cells():
            if not _cell_in_view(cell):
                continue
            var rect: Rect2 = _cell_rect(cell)
            _draw_state(rect, target_id)

func _draw_state(rect: Rect2, target_id: String) -> void:
    var inset: float = maxf(2.0, roundf(_cell_pixels * 0.12))
    var thickness: float = maxf(1.0, roundf(_cell_pixels / 16.0))
    var boards: int = _state.board_count(target_id)
    if boards > 0:
        for index in range(boards):
            var y: float = rect.position.y + rect.size.y * float(index + 1) / float(boards + 1)
            draw_line(
                Vector2(rect.position.x + inset, y),
                Vector2(rect.end.x - inset, y),
                BOARD_COLOR,
                thickness + 1.0,
                false
            )
    if _state.is_broken(target_id):
        draw_line(rect.position + Vector2(inset, inset), rect.end - Vector2(inset, inset), BREAK_COLOR, thickness, false)
        draw_line(Vector2(rect.end.x - inset, rect.position.y + inset), Vector2(rect.position.x + inset, rect.end.y - inset), BREAK_COLOR, thickness, false)
    if _state.is_locked(target_id):
        var side: float = maxf(4.0, roundf(_cell_pixels * 0.22))
        var lock_rect := Rect2(rect.end - Vector2(side + inset, side + inset), Vector2(side, side))
        draw_rect(lock_rect, LOCK_COLOR, false, thickness)
    if _state.window_open(target_id) and not _state.is_broken(target_id):
        var center: Vector2 = rect.get_center()
        var arm: float = maxf(3.0, _cell_pixels * 0.18)
        draw_line(center, center + Vector2(-arm, -arm * 0.55), OPEN_COLOR, thickness, false)
        draw_line(center, center + Vector2(arm, -arm * 0.55), OPEN_COLOR, thickness, false)

func _state_ids() -> Array[String]:
    var data: Dictionary = _state.snapshot()
    var result: Array[String] = []
    for value: Variant in data.get("records", []):
        if typeof(value) == TYPE_DICTIONARY:
            result.append(String((value as Dictionary).get("target_id", "")))
    result.sort()
    return result

func _cell_rect(cell: Vector2i) -> Rect2:
    var local: Vector2i = cell - _origin
    return Rect2(Vector2(local.x, local.y) * _cell_pixels, Vector2(_cell_pixels, _cell_pixels))

func _cell_in_view(cell: Vector2i) -> bool:
    return cell.x >= _origin.x and cell.x < _origin.x + _size.x \
        and cell.y >= _origin.y and cell.y < _origin.y + _size.y

func _on_state_changed(_target_id: String, _version: int, _reason: StringName) -> void:
    queue_redraw()

func _on_state_reset() -> void:
    queue_redraw()
