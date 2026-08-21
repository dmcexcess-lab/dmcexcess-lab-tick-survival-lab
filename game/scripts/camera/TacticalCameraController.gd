extends Node
class_name TacticalCameraController

const StateClass = preload("res://scripts/camera/TacticalCameraState.gd")
const ZoomClass = preload("res://scripts/camera/ZoomController.gd")
const ChangeClass = preload("res://scripts/foundation/world/WorldChange.gd")

signal presentation_changed(snapshot: Dictionary)
signal scripted_transition_finished(target_kind: StringName)

var _world: WorldState = null
var _camera: Camera2D = null
var _world_view: Node2D = null
var _controlled_actor_id: String = ""
var _render_origin: Vector2i = Vector2i.ZERO
var _cell_pixels: float = 0.0
var _state: TacticalCameraState = StateClass.new()
var _zoom: ZoomController = ZoomClass.new()
var _active_tween: Tween = null
var _scripted_serial: int = 0

func configure(
    world: WorldState,
    camera: Camera2D,
    world_view: Node2D,
    controlled_actor_id: String,
    render_origin: Vector2i,
    cell_pixels: float
) -> bool:
    var normalized_actor_id: String = controlled_actor_id.strip_edges()
    if world == null or camera == null or world_view == null or normalized_actor_id.is_empty() or cell_pixels <= 0.0:
        return false
    if world.placement(normalized_actor_id) == null:
        return false

    _disconnect_world()
    _cancel_tween()
    _world = world
    _camera = camera
    _world_view = world_view
    _controlled_actor_id = normalized_actor_id
    _render_origin = render_origin
    _cell_pixels = cell_pixels
    _state.reset()
    _state.set_zoom_level(ZoomController.DEFAULT_LEVEL)
    _camera.enabled = true
    _apply_zoom()
    _connect_world()
    if _camera.is_inside_tree():
        _camera.make_current()
    if not _center_on_entity(_controlled_actor_id):
        return false
    _emit_presentation()
    return true

func is_configured() -> bool:
    return _world != null \
        and _camera != null \
        and _world_view != null \
        and not _controlled_actor_id.is_empty() \
        and _cell_pixels > 0.0

func state() -> TacticalCameraState:
    return _state

func zoom_controller() -> ZoomController:
    return _zoom

func mode() -> int:
    return _state.mode()

func zoom_level() -> int:
    return _state.zoom_level()

func set_render_window(origin: Vector2i, cell_pixels: float, world_view: Node2D = null) -> bool:
    if not is_configured() or cell_pixels <= 0.0:
        return false
    if world_view != null:
        _world_view = world_view
    _render_origin = origin
    _cell_pixels = cell_pixels
    _apply_state_target()
    _emit_presentation()
    return true

func zoom_in() -> bool:
    if not is_configured():
        return false
    _cancel_script_for_manual_control()
    var next_level: int = _zoom.zoom_in(_state.zoom_level())
    if next_level == _state.zoom_level():
        return true
    _state.set_zoom_level(next_level)
    _apply_zoom()
    _emit_presentation()
    return true

func zoom_out() -> bool:
    if not is_configured():
        return false
    _cancel_script_for_manual_control()
    var next_level: int = _zoom.zoom_out(_state.zoom_level())
    if next_level == _state.zoom_level():
        return true
    _state.set_zoom_level(next_level)
    _apply_zoom()
    _emit_presentation()
    return true

func set_zoom_level(level: int) -> bool:
    if not is_configured() or not _zoom.is_valid_level(level):
        return false
    _cancel_script_for_manual_control()
    _state.set_zoom_level(level)
    _apply_zoom()
    _emit_presentation()
    return true

func pan_screen_pixels(screen_delta: Vector2) -> bool:
    if not is_configured():
        return false
    if screen_delta.is_zero_approx():
        return true
    _cancel_tween()
    var scale_value: float = maxf(0.001, _camera.zoom.x)
    _camera.global_position -= screen_delta / scale_value
    _state.set_detached(_camera.global_position)
    _emit_presentation()
    return true

func recenter_player() -> bool:
    if not is_configured():
        return false
    _cancel_tween()
    _state.set_follow_player()
    if not _center_on_entity(_controlled_actor_id):
        return false
    _emit_presentation()
    return true

func focus_cell(cell: Vector2i, zoom_override: int = -1, remember_previous: bool = true) -> bool:
    if not is_configured() or not _valid_optional_zoom(zoom_override):
        return false
    _cancel_tween()
    if remember_previous:
        _state.remember_current()
    if zoom_override >= 0:
        _state.set_zoom_level(zoom_override)
    _state.set_focus_cell(cell)
    _apply_zoom()
    _camera.global_position = _cell_global_position(cell)
    _emit_presentation()
    return true

func focus_actor(actor_id: String, zoom_override: int = -1, remember_previous: bool = true) -> bool:
    if not is_configured() or not _valid_optional_zoom(zoom_override):
        return false
    var normalized: String = actor_id.strip_edges()
    if normalized.is_empty() or _world.placement(normalized) == null:
        return false
    _cancel_tween()
    if remember_previous:
        _state.remember_current()
    if zoom_override >= 0:
        _state.set_zoom_level(zoom_override)
    _state.set_focus_actor(normalized)
    _apply_zoom()
    if not _center_on_entity(normalized):
        return false
    _emit_presentation()
    return true

func scripted_focus_cell(
    cell: Vector2i,
    zoom_override: int = -1,
    duration_seconds: float = 0.45,
    remember_previous: bool = true
) -> bool:
    if not is_configured() or duration_seconds < 0.0 or not _valid_optional_zoom(zoom_override):
        return false
    _cancel_tween()
    if remember_previous:
        _state.remember_current()
    if zoom_override >= 0:
        _state.set_zoom_level(zoom_override)
    _state.set_scripted_cell(cell)
    return _begin_scripted_transition(_cell_global_position(cell), duration_seconds)

func scripted_focus_actor(
    actor_id: String,
    zoom_override: int = -1,
    duration_seconds: float = 0.45,
    remember_previous: bool = true
) -> bool:
    if not is_configured() or duration_seconds < 0.0 or not _valid_optional_zoom(zoom_override):
        return false
    var normalized: String = actor_id.strip_edges()
    var placement: WorldPlacement = _world.placement(normalized)
    if normalized.is_empty() or placement == null:
        return false
    _cancel_tween()
    if remember_previous:
        _state.remember_current()
    if zoom_override >= 0:
        _state.set_zoom_level(zoom_override)
    _state.set_scripted_actor(normalized)
    return _begin_scripted_transition(_cell_global_position(placement.anchor), duration_seconds)

func restore_previous() -> bool:
    if not is_configured():
        return false
    _cancel_tween()
    var previous: Dictionary = _state.take_previous()
    if previous.is_empty():
        return recenter_player()
    if not _state.restore_snapshot(previous):
        return recenter_player()
    _state.set_zoom_level(_zoom.clamp_level(_state.zoom_level()))
    _apply_zoom()
    _apply_state_target()
    _emit_presentation()
    return true

func presentation_snapshot() -> Dictionary:
    var result: Dictionary = _state.snapshot()
    result["configured"] = is_configured()
    result["mode_label"] = mode_label(_state.mode())
    result["zoom_label"] = _zoom.label(_state.zoom_level())
    result["zoom_scale"] = _zoom.scale(_state.zoom_level())
    result["zoom_level_count"] = _zoom.level_count()
    result["camera_global_position"] = Vector2.ZERO if _camera == null else _camera.global_position
    result["camera_zoom"] = Vector2.ONE if _camera == null else _camera.zoom
    result["controlled_actor_id"] = _controlled_actor_id
    result["render_origin"] = _render_origin
    result["cell_pixels"] = _cell_pixels
    return result

static func mode_label(value: int) -> String:
    match value:
        TacticalCameraState.Mode.FOLLOW_PLAYER:
            return "FOLLOW PLAYER"
        TacticalCameraState.Mode.DETACHED:
            return "INSPECT"
        TacticalCameraState.Mode.FOCUS_CELL:
            return "FOCUS CELL"
        TacticalCameraState.Mode.FOCUS_ACTOR:
            return "FOCUS ACTOR"
        TacticalCameraState.Mode.SCRIPTED:
            return "SCRIPTED"
        _:
            return "UNKNOWN"

func _begin_scripted_transition(target_position: Vector2, duration_seconds: float) -> bool:
    _scripted_serial += 1
    var serial: int = _scripted_serial
    var target_zoom: Vector2 = _zoom.zoom_vector(_state.zoom_level())
    if duration_seconds <= 0.0 or not is_inside_tree():
        _camera.global_position = target_position
        _camera.zoom = target_zoom
        _finish_scripted_transition(serial)
        return true

    _active_tween = create_tween()
    _active_tween.set_parallel(true)
    _active_tween.tween_property(_camera, "global_position", target_position, duration_seconds)
    _active_tween.tween_property(_camera, "zoom", target_zoom, duration_seconds)
    _active_tween.finished.connect(_finish_scripted_transition.bind(serial), CONNECT_ONE_SHOT)
    _emit_presentation()
    return true

func _finish_scripted_transition(serial: int) -> void:
    if serial != _scripted_serial or _state.mode() != TacticalCameraState.Mode.SCRIPTED:
        return
    _active_tween = null
    var target_kind: StringName = _state.scripted_target_kind()
    if target_kind == &"actor":
        var actor_id: String = _state.focus_actor_id()
        _state.set_focus_actor(actor_id)
        _center_on_entity(actor_id)
    else:
        var cell: Vector2i = _state.focus_cell()
        _state.set_focus_cell(cell)
        _camera.global_position = _cell_global_position(cell)
    _apply_zoom()
    _emit_presentation()
    scripted_transition_finished.emit(target_kind)

func _cancel_script_for_manual_control() -> void:
    if _state.mode() != TacticalCameraState.Mode.SCRIPTED:
        return
    _cancel_tween()
    _state.set_detached(_camera.global_position)

func _cancel_tween() -> void:
    _scripted_serial += 1
    if _active_tween != null and _active_tween.is_valid():
        _active_tween.kill()
    _active_tween = null

func _apply_zoom() -> void:
    if _camera == null:
        return
    _camera.zoom = _zoom.zoom_vector(_state.zoom_level())

func _apply_state_target() -> void:
    if not is_configured():
        return
    match _state.mode():
        TacticalCameraState.Mode.FOLLOW_PLAYER:
            _center_on_entity(_controlled_actor_id)
        TacticalCameraState.Mode.DETACHED:
            _camera.global_position = _state.detached_global_position()
        TacticalCameraState.Mode.FOCUS_CELL:
            _camera.global_position = _cell_global_position(_state.focus_cell())
        TacticalCameraState.Mode.FOCUS_ACTOR:
            _center_on_entity(_state.focus_actor_id())
        TacticalCameraState.Mode.SCRIPTED:
            if _state.scripted_target_kind() == &"actor":
                _center_on_entity(_state.focus_actor_id())
            else:
                _camera.global_position = _cell_global_position(_state.focus_cell())

func _center_on_entity(entity_id: String) -> bool:
    if _world == null or _camera == null:
        return false
    var placement: WorldPlacement = _world.placement(entity_id)
    if placement == null:
        return false
    _camera.global_position = _cell_global_position(placement.anchor)
    return true

func _cell_global_position(cell: Vector2i) -> Vector2:
    var local_cell: Vector2i = cell - _render_origin
    var local_center := Vector2(
        (float(local_cell.x) + 0.5) * _cell_pixels,
        (float(local_cell.y) + 0.5) * _cell_pixels
    )
    return _world_view.to_global(local_center)

func _valid_optional_zoom(level: int) -> bool:
    return level < 0 or _zoom.is_valid_level(level)

func _connect_world() -> void:
    if _world == null:
        return
    var changed_callable := Callable(self, "_on_world_changed")
    var reset_callable := Callable(self, "_on_world_reset")
    if not _world.changed.is_connected(changed_callable):
        _world.changed.connect(changed_callable)
    if not _world.world_reset.is_connected(reset_callable):
        _world.world_reset.connect(reset_callable)

func _disconnect_world() -> void:
    if _world == null:
        return
    var changed_callable := Callable(self, "_on_world_changed")
    var reset_callable := Callable(self, "_on_world_reset")
    if _world.changed.is_connected(changed_callable):
        _world.changed.disconnect(changed_callable)
    if _world.world_reset.is_connected(reset_callable):
        _world.world_reset.disconnect(reset_callable)

func _on_world_changed(change: WorldChange) -> void:
    if change == null or not is_configured():
        return
    if change.kind != ChangeClass.Kind.PLACEMENT_SET \
        and change.kind != ChangeClass.Kind.PLACEMENT_REMOVED \
        and change.kind != ChangeClass.Kind.ENTITY_REMOVED:
        return
    var tracked_id: String = ""
    if _state.mode() == TacticalCameraState.Mode.FOLLOW_PLAYER:
        tracked_id = _controlled_actor_id
    elif _state.mode() == TacticalCameraState.Mode.FOCUS_ACTOR:
        tracked_id = _state.focus_actor_id()
    else:
        return
    if change.entity_id != tracked_id:
        return
    if _center_on_entity(tracked_id):
        _emit_presentation()

func _on_world_reset() -> void:
    if not is_configured():
        return
    _apply_state_target()
    _emit_presentation()

func _emit_presentation() -> void:
    presentation_changed.emit(presentation_snapshot())
