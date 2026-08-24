extends RefCounted
class_name SoundEmission

## Exact transient physical sound truth. Listener-facing consumers must receive
## HeardSoundObservation instead of this record.

var event_id: String = ""
var emitted_tick: int = -1
var origin_cell: Vector2i = Vector2i.ZERO
var profile_id: StringName = &""
var acoustic_power: int = 0
var source_entity_id: String = ""
var group_key: String = ""

func _init(
    id: String = "",
    tick: int = -1,
    origin: Vector2i = Vector2i.ZERO,
    profile: StringName = &"",
    power: int = 0,
    source_id: String = "",
    repeated_group_key: String = ""
) -> void:
    event_id = id.strip_edges()
    emitted_tick = tick
    origin_cell = origin
    profile_id = profile
    acoustic_power = power
    source_entity_id = source_id.strip_edges()
    group_key = repeated_group_key.strip_edges()

func is_valid() -> bool:
    return not event_id.is_empty() \
        and emitted_tick >= 0 \
        and not String(profile_id).strip_edges().is_empty() \
        and acoustic_power > 0

func copy() -> SoundEmission:
    return SoundEmission.new(
        event_id,
        emitted_tick,
        origin_cell,
        profile_id,
        acoustic_power,
        source_entity_id,
        group_key
    )
