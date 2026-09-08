extends ObserverPerceptionService
class_name StreamingObserverPerceptionService

## Reuses System-23 exactly, while allowing a streaming owner to suspend costly
## recomputation for an observer whose actor is outside the technical active envelope.
## Memory remains persistent; current visibility is treated as inactive until re-entry.

var _stream_active: bool = true

func set_stream_active(value: bool) -> bool:
    if _stream_active == value:
        return true
    _stream_active = value
    if _stream_active:
        return super.recompute(&"stream_reactivated")
    return true

func is_stream_active() -> bool:
    return _stream_active

func recompute(reason: StringName = &"manual") -> bool:
    if not _stream_active:
        return false
    return super.recompute(reason)

func is_visible(cell: Vector2i) -> bool:
    return _stream_active and super.is_visible(cell)

func visible_cells() -> Array[Vector2i]:
    return super.visible_cells() if _stream_active else []