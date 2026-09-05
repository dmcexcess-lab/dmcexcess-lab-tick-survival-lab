extends RefCounted
class_name PlayerStreamingFocusAdapter

const NO_ANCHOR: Vector2i = Vector2i(-999999999, -999999999)

var _world: WorldState = null
var _streaming: WorldStreamingCoordinator = null
var _actor_id: String = ""
var _last_anchor: Vector2i = NO_ANCHOR
var _updating: bool = false
var _last_failure: String = ""
var _last_lookahead_failure: String = ""

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

func last_lookahead_failure() -> String:
    return _last_lookahead_failure

func sync_now() -> bool:
    if not is_ready() or _updating:
        return false
    var placement: WorldPlacement = _world.placement(_actor_id)
    if placement == null:
        return false
    if placement.anchor == _last_anchor and _streaming.has_focus():
        return true

    var previous_anchor: Vector2i = _last_anchor
    _updating = true
    var result: Dictionary = _streaming.update_focus(placement.anchor)
    _updating = false
    if not bool(result.get("ok", false)):
        _last_failure = String(result.get("failure_reason", "streaming_focus_update_failed"))
        return false

    _last_anchor = placement.anchor
    _last_failure = ""
    _last_lookahead_failure = ""
    if previous_anchor != NO_ANCHOR:
        var movement_delta: Vector2i = placement.anchor - previous_anchor
        if movement_delta != Vector2i.ZERO:
            var lookahead: Dictionary = _streaming.prepare_lookahead(placement.anchor, movement_delta, 1)
            if not bool(lookahead.get("ok", false)):
                ## Speculative preparation must never reject an otherwise valid authoritative move.
                ## The boundary update retains its synchronous fallback and reports a hard failure there.
                _last_lookahead_failure = String(lookahead.get("failure_reason", "streaming_lookahead_prepare_failed"))
    return true

func _on_world_changed(_change) -> void:
    if _updating or not is_ready():
        return
    var placement: WorldPlacement = _world.placement(_actor_id)
    if placement == null or placement.anchor == _last_anchor:
        return
    sync_now()

func _on_world_reset() -> void:
    _last_anchor = NO_ANCHOR
    _last_lookahead_failure = ""
