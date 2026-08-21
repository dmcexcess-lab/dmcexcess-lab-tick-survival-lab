extends RefCounted
class_name TacticalCameraState

enum Mode {
    FOLLOW_PLAYER,
    DETACHED,
    FOCUS_CELL,
    FOCUS_ACTOR,
    SCRIPTED,
}

const DEFAULT_ZOOM_LEVEL: int = 2

var _mode: int = Mode.FOLLOW_PLAYER
var _zoom_level: int = DEFAULT_ZOOM_LEVEL
var _focus_cell: Vector2i = Vector2i.ZERO
var _focus_actor_id: String = ""
var _detached_global_position: Vector2 = Vector2.ZERO
var _scripted_target_kind: StringName = &""
var _previous_snapshot: Dictionary = {}

func reset() -> void:
    _mode = Mode.FOLLOW_PLAYER
    _zoom_level = DEFAULT_ZOOM_LEVEL
    _focus_cell = Vector2i.ZERO
    _focus_actor_id = ""
    _detached_global_position = Vector2.ZERO
    _scripted_target_kind = &""
    _previous_snapshot.clear()

func mode() -> int:
    return _mode

func zoom_level() -> int:
    return _zoom_level

func set_zoom_level(value: int) -> void:
    _zoom_level = value

func focus_cell() -> Vector2i:
    return _focus_cell

func focus_actor_id() -> String:
    return _focus_actor_id

func detached_global_position() -> Vector2:
    return _detached_global_position

func scripted_target_kind() -> StringName:
    return _scripted_target_kind

func set_follow_player() -> void:
    _mode = Mode.FOLLOW_PLAYER
    _focus_actor_id = ""
    _scripted_target_kind = &""

func set_detached(global_position: Vector2) -> void:
    _mode = Mode.DETACHED
    _detached_global_position = global_position
    _focus_actor_id = ""
    _scripted_target_kind = &""

func set_focus_cell(cell: Vector2i) -> void:
    _mode = Mode.FOCUS_CELL
    _focus_cell = cell
    _focus_actor_id = ""
    _scripted_target_kind = &""

func set_focus_actor(actor_id: String) -> void:
    _mode = Mode.FOCUS_ACTOR
    _focus_actor_id = actor_id.strip_edges()
    _scripted_target_kind = &""

func set_scripted_cell(cell: Vector2i) -> void:
    _mode = Mode.SCRIPTED
    _focus_cell = cell
    _focus_actor_id = ""
    _scripted_target_kind = &"cell"

func set_scripted_actor(actor_id: String) -> void:
    _mode = Mode.SCRIPTED
    _focus_actor_id = actor_id.strip_edges()
    _scripted_target_kind = &"actor"

func remember_current() -> void:
    _previous_snapshot = snapshot()

func has_previous() -> bool:
    return not _previous_snapshot.is_empty()

func take_previous() -> Dictionary:
    var result: Dictionary = _previous_snapshot.duplicate(true)
    _previous_snapshot.clear()
    return result

func restore_snapshot(value: Dictionary) -> bool:
    if value.is_empty():
        return false
    var restored_mode: int = int(value.get("mode", -1))
    if restored_mode < Mode.FOLLOW_PLAYER or restored_mode > Mode.SCRIPTED:
        return false
    _mode = restored_mode
    _zoom_level = int(value.get("zoom_level", DEFAULT_ZOOM_LEVEL))
    _focus_cell = value.get("focus_cell", Vector2i.ZERO)
    _focus_actor_id = String(value.get("focus_actor_id", ""))
    _detached_global_position = value.get("detached_global_position", Vector2.ZERO)
    _scripted_target_kind = StringName(value.get("scripted_target_kind", &""))
    return true

func snapshot() -> Dictionary:
    return {
        "mode": _mode,
        "zoom_level": _zoom_level,
        "focus_cell": _focus_cell,
        "focus_actor_id": _focus_actor_id,
        "detached_global_position": _detached_global_position,
        "scripted_target_kind": _scripted_target_kind,
    }
