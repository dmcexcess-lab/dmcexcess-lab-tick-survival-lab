extends RefCounted
class_name HeardSoundObservation

## Listener-specific auditory knowledge. Deliberately contains no exact source
## cell/entity identity.

var cue_id: String = ""
var listener_id: String = ""
var heard_tick: int = -1
var perceived_cell: Vector2i = Vector2i.ZERO
var perceived_strength: float = 0.0
var certainty: float = 0.0
var display_word: String = ""
var recognized_category: StringName = &""
var expiry_tick: int = -1
var group_id: String = ""

func _init(
    observation_id: String = "",
    actor_id: String = "",
    tick: int = -1,
    estimated_cell: Vector2i = Vector2i.ZERO,
    strength: float = 0.0,
    localization_certainty: float = 0.0,
    word: String = "",
    category: StringName = &"",
    expires_at: int = -1,
    repeated_group_id: String = ""
) -> void:
    cue_id = observation_id.strip_edges()
    listener_id = actor_id.strip_edges()
    heard_tick = tick
    perceived_cell = estimated_cell
    perceived_strength = clampf(strength, 0.0, 1.0)
    certainty = clampf(localization_certainty, 0.0, 1.0)
    display_word = word.strip_edges().to_upper()
    recognized_category = category
    expiry_tick = expires_at
    group_id = repeated_group_id.strip_edges()

func is_valid() -> bool:
    return not cue_id.is_empty() \
        and not listener_id.is_empty() \
        and heard_tick >= 0 \
        and expiry_tick >= heard_tick \
        and not display_word.is_empty() \
        and not String(recognized_category).strip_edges().is_empty() \
        and not group_id.is_empty()

func copy() -> HeardSoundObservation:
    return HeardSoundObservation.new(
        cue_id,
        listener_id,
        heard_tick,
        perceived_cell,
        perceived_strength,
        certainty,
        display_word,
        recognized_category,
        expiry_tick,
        group_id
    )

func to_snapshot() -> Dictionary:
    return {
        "cue_id": cue_id,
        "listener_id": listener_id,
        "heard_tick": heard_tick,
        "perceived_cell": [perceived_cell.x, perceived_cell.y],
        "perceived_strength": perceived_strength,
        "certainty": certainty,
        "display_word": display_word,
        "recognized_category": String(recognized_category),
        "expiry_tick": expiry_tick,
        "group_id": group_id,
    }

static func from_snapshot(data: Dictionary) -> HeardSoundObservation:
    var cell_value: Variant = data.get("perceived_cell", [])
    if typeof(cell_value) != TYPE_ARRAY or cell_value.size() != 2:
        return null
    var observation := HeardSoundObservation.new(
        String(data.get("cue_id", "")),
        String(data.get("listener_id", "")),
        int(data.get("heard_tick", -1)),
        Vector2i(int(cell_value[0]), int(cell_value[1])),
        float(data.get("perceived_strength", 0.0)),
        float(data.get("certainty", 0.0)),
        String(data.get("display_word", "")),
        StringName(String(data.get("recognized_category", ""))),
        int(data.get("expiry_tick", -1)),
        String(data.get("group_id", ""))
    )
    if not observation.is_valid():
        return null
    return observation
