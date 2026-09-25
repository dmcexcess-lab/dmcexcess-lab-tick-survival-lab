extends RefCounted
class_name ConditionHeardFearAdapter

## Threat-sound -> canonical fear-pressure adapter. Heard observations preserve
## epistemic limits: no hidden exact source identity/location is invented.

const THREAT_CATEGORY: StringName = &"threat"
const THREAT_NOTICE_STRENGTH: float = 0.65
const THREAT_SEVERE_STRENGTH: float = 0.85
const THREAT_NOTICE_PRESSURE: int = 3
const THREAT_SEVERE_PRESSURE: int = 5

var _sound: SpatialSoundService = null
var _fear: ActorFearPressureService = null
var _actor_id: String = ""

func _init(
    sound_service: SpatialSoundService = null,
    fear_service: ActorFearPressureService = null,
    actor_id: String = ""
) -> void:
    _sound = sound_service
    _fear = fear_service
    _actor_id = actor_id.strip_edges()
    if _sound != null:
        var callable := Callable(self, "_on_sound_heard")
        if not _sound.sound_heard.is_connected(callable):
            _sound.sound_heard.connect(callable)

func is_ready() -> bool:
    return _sound != null and _sound.is_ready()         and _fear != null and _fear.is_ready() and not _actor_id.is_empty()

func _on_sound_heard(listener_id: String, observation: HeardSoundObservation) -> void:
    if not is_ready() or listener_id != _actor_id or observation == null or not observation.is_valid():
        return
    var pressure: int = fear_pressure(observation.recognized_category, observation.perceived_strength)
    if pressure > 0:
        _fear.queue_pressure(_actor_id, pressure, &"heard_threat")

static func fear_pressure(category: StringName, strength: float) -> int:
    if category != THREAT_CATEGORY:
        return 0
    var normalized_strength: float = clampf(strength, 0.0, 1.0)
    if normalized_strength >= THREAT_SEVERE_STRENGTH:
        return THREAT_SEVERE_PRESSURE
    if normalized_strength >= THREAT_NOTICE_STRENGTH:
        return THREAT_NOTICE_PRESSURE
    return 0
