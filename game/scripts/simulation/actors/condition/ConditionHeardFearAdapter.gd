extends RefCounted
class_name ConditionHeardFearAdapter

const StateClass = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")

## System 26 -> System 34 fear seam. Consumes only HeardSoundObservation listener
## knowledge, which deliberately contains no exact hidden source cell/entity identity.
## Only sufficiently strong/alarming perceived cues lower Calm.

var _sound: SpatialSoundService = null
var _condition: ActorConditionService = null
var _actor_id: String = ""

func _init(
    sound_service: SpatialSoundService = null,
    condition_service: ActorConditionService = null,
    actor_id: String = ""
) -> void:
    _sound = sound_service
    _condition = condition_service
    _actor_id = actor_id.strip_edges()
    if _sound != null:
        var callable := Callable(self, "_on_sound_heard")
        if not _sound.sound_heard.is_connected(callable):
            _sound.sound_heard.connect(callable)

func is_ready() -> bool:
    return _sound != null and _sound.is_ready() \
        and _condition != null and _condition.is_ready() \
        and _condition.has_actor(_actor_id)

func _on_sound_heard(listener_id: String, observation: HeardSoundObservation) -> void:
    if not is_ready() or listener_id != _actor_id or observation == null or not observation.is_valid():
        return
    var category: StringName = observation.recognized_category
    var strength: float = observation.perceived_strength
    var pressure: int = 0
    if category in [&"impact", &"utility"] and strength >= 0.65:
        pressure = 5 if strength >= 0.85 else 3
    elif category == &"movement" and strength >= 0.85:
        pressure = 2
    if pressure > 0:
        _condition.change_condition(_actor_id, StateClass.CALM, -pressure, &"alarming_heard_sound")
