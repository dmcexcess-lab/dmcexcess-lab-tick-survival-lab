extends RefCounted
class_name ConditionEnvironmentPressureAdapter

const StateClass = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const Rules = preload("res://scripts/foundation/time/TickRules.gd")
const SkyExposureClass = preload("res://scripts/simulation/weather/SkyExposureQuery.gd")

## Event-driven real-environment -> System 34 comfort pressure.
## Uses actual Weather precipitation + cached sky exposure and actual Carry load.
## It runs only at completed actor actions; there is no frame/weather-particle-driven condition loop.

const LOCAL_EXPOSURE_RADIUS: int = 20
const SEVERE_LOAD_RATIO_BP: int = 12500

var _world: WorldState = null
var _weather: WeatherService = null
var _carry_query: ActorCarryQuery = null
var _condition: ActorConditionService = null
var _kernel: TickKernel = null
var _actor_id: String = ""
var _sky_exposure: SkyExposureQuery = null

func _init(
    world_state: WorldState = null,
    weather_service: WeatherService = null,
    carry_query: ActorCarryQuery = null,
    condition_service: ActorConditionService = null,
    kernel: TickKernel = null,
    actor_id: String = ""
) -> void:
    _world = world_state
    _weather = weather_service
    _carry_query = carry_query
    _condition = condition_service
    _kernel = kernel
    _actor_id = actor_id.strip_edges()
    _sky_exposure = SkyExposureClass.new(_world)
    if _kernel != null:
        var callable := Callable(self, "_on_action_finished")
        if not _kernel.action_finished.is_connected(callable):
            _kernel.action_finished.connect(callable)

func is_ready() -> bool:
    return _world != null and _weather != null and _weather.is_ready() \
        and _carry_query != null and _condition != null and _condition.is_ready() \
        and _kernel != null and not _actor_id.is_empty() and _condition.has_actor(_actor_id) \
        and _sky_exposure != null and _sky_exposure.is_ready()

func _on_action_finished(action: TimedAction) -> void:
    if not is_ready() or action == null or action.actor_id != _actor_id \
        or action.status != Rules.ActionStatus.COMPLETED:
        return
    var pressure: int = 0
    var placement: WorldPlacement = _world.placement(_actor_id)
    if placement != null:
        var sample: Dictionary = _weather.current_sample()
        var precipitation: float = float(sample.get("precipitation", 0.0))
        if precipitation >= 0.15:
            var radius: int = LOCAL_EXPOSURE_RADIUS
            var bounds := Rect2i(
                placement.anchor - Vector2i(radius, radius),
                Vector2i(radius * 2 + 1, radius * 2 + 1)
            )
            if _sky_exposure.is_exposed(placement.anchor, bounds):
                pressure += 2 if precipitation >= 0.65 else 1

    var carry: Dictionary = _carry_query.query(_actor_id)
    if int(carry.get("status", -1)) == ActorCarryQuery.Status.KNOWN \
        and int(carry.get("load_ratio_bp", 0)) >= SEVERE_LOAD_RATIO_BP:
        pressure += 1
    if pressure > 0:
        _condition.change_condition(_actor_id, StateClass.COMFORT, -pressure, &"environmental_discomfort")
