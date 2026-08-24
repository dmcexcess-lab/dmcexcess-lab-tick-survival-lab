extends RefCounted
class_name LightningEvent

## One deterministic physical atmospheric lightning pulse. The event intentionally
## carries no strike-cell claim yet: damage/fire/spatial thunder require a later
## owner that can supply honest strike geography.

var event_id: String = ""
var start_tick: int = 0
var end_tick: int = 1
var intensity: float = 1.0
var bolt_seed: int = 1

func _init(
    id_value: String = "",
    start_value: int = 0,
    end_value: int = 1,
    intensity_value: float = 1.0,
    seed_value: int = 1
) -> void:
    event_id = id_value.strip_edges()
    start_tick = start_value
    end_tick = end_value
    intensity = intensity_value
    bolt_seed = seed_value

func is_valid() -> bool:
    return (
        not event_id.is_empty()
        and start_tick >= 0
        and end_tick > start_tick
        and intensity > 0.0 and intensity <= 1.0
        and bolt_seed >= 0
    )

func copy() -> LightningEvent:
    return LightningEvent.new(event_id, start_tick, end_tick, intensity, bolt_seed)

func to_dictionary() -> Dictionary:
    return {
        "event_id": event_id,
        "start_tick": start_tick,
        "end_tick": end_tick,
        "intensity": intensity,
        "bolt_seed": bolt_seed,
    }
