extends RefCounted
class_name ActionPhase

## Semantic timing checkpoint. Meaning/effects belong to the owning gameplay system.

var phase_id: StringName = &""
var offset_ticks: int = 0

func _init(id: StringName = &"", offset: int = 0) -> void:
    phase_id = id
    offset_ticks = offset

func is_valid(duration_ticks: int = -1) -> bool:
    if String(phase_id).strip_edges().is_empty():
        return false
    if offset_ticks < 1:
        return false
    if duration_ticks >= 0 and offset_ticks > duration_ticks:
        return false
    return true

func copy() -> ActionPhase:
    return ActionPhase.new(phase_id, offset_ticks)

func to_snapshot() -> Dictionary:
    return {
        "phase_id": String(phase_id),
        "offset_ticks": offset_ticks,
    }

static func from_snapshot(data: Dictionary, duration_ticks: int = -1) -> ActionPhase:
    var value := ActionPhase.new(
        StringName(String(data.get("phase_id", ""))),
        int(data.get("offset_ticks", 0))
    )
    if not value.is_valid(duration_ticks):
        return null
    return value

static func less(a: ActionPhase, b: ActionPhase) -> bool:
    if a.offset_ticks == b.offset_ticks:
        return String(a.phase_id) < String(b.phase_id)
    return a.offset_ticks < b.offset_ticks
