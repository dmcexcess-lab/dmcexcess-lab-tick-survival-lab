extends RefCounted
class_name PlayerStreamingFocusAdapter

var _world: WorldState = null
var _streaming: WorldStreamingCoordinator = null
var _actor_id: String = ""
var _last_anchor: Vector2i = Vector2i(-999999999, -999999999)
var _updating: bool = false
var _last_failure: String = ""

func _init(world: WorldState = null, streaming: WorldStreamingCoordinator = null, actor_id: String = "") -> void:
    _world = world
    _streaming = streaming
    _actor_id = actor_id.strip_edges()
    if is_ready():
        var placement: WorldPlacement = _world.placement(_actor_id)
        if placement != null:
            _last_anchor = placement.anchor
        var changed_callable := Callable(self, "_on_world_changed")
        if not _world.changed.is_connected(changed_callable):
            _world.changed.connect(changed_callable)
        var reset_callable := Callable(self, "_on_world_reset")
        if not _world.world_reset.is_connected(reset_callable):
            _world.world_reset.connect(reset_callable)

func is_ready() -> bool:
    return _world != null and _streaming != null and _streaming.is_ready() and not _actor_id.is_empty()

func last_failure() -> String:
    return _last_failure

func sync_now() -> bool:
    if not is_ready() or _updating:
        return false
    var placement: WorldPlacement = _world.placement(_actor_id)
    if placement == null:
        return false
    if placement.anchor == _last_anchor and _streaming.has_focus():
        return true
    _updating = true
    var result: Dictionary = _streaming.update_focus(placement.anchor)
    _updating = false
    if not bool(result.get("ok", false)):
        _last_failure = String(result.get("failure_reason", "streaming_focus_update_failed"))
        return false
    _last_anchor = placement.anchor
    _last_failure = ""
    return true

func _on_world_changed(_change) -> void:
    if _updating or not is_ready():
        return
    var placement: WorldPlacement = _world.placement(_actor_id)
    if placement == null or placement.anchor == _last_anchor:
        return
    sync_now()

func _on_world_reset() -> void:
    _last_anchor = Vector2i(-999999999, -999999999)
