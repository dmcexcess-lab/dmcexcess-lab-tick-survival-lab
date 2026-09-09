extends DynamicInfectedCohortService
class_name ActiveSurvivorCohortService

const StreamingPerceptionClass = preload("res://scripts/simulation/perception/StreamingObserverPerceptionService.gd")
const SurvivorBehaviorClass = preload("res://scripts/simulation/population/SurvivorNpcBehaviorService.gd")
const VisionProfileClass = preload("res://scripts/simulation/perception/VisionProfile.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

## Technical-stream lifecycle for resident-backed survivors. The inherited cohort
## machinery owns only activation/deactivation; survivor role state owns policy.

var _npc_state: SurvivorNpcState = null

func configure_survivor_state(state: SurvivorNpcState) -> bool:
    if state == null or is_configured():
        return false
    _npc_state = state
    return true

func is_ready() -> bool:
    return _npc_state != null and super.is_ready()

func _valid_living_infected(actor_id: String) -> bool:
    if _npc_state == null or not _npc_state.has_actor(actor_id) or _infected.is_infected(actor_id) \
        or not _health.has_actor(actor_id) or _health.current_hp(actor_id) <= 0:
        return false
    var placement: WorldPlacement = _world.placement(actor_id)
    return placement != null and placement.channel == Layers.Channel.ACTOR

func _activate(actor_id: String) -> bool:
    var perception: StreamingObserverPerceptionService = perception_for_actor(actor_id)
    if perception == null:
        perception = StreamingPerceptionClass.new(
            _world, _door_state, _kernel, _memory, actor_id, VisionProfileClass.new(), _acquisition
        )
        if perception == null or not perception.is_ready():
            return false
        _perceptions[actor_id] = perception
    elif not perception.set_stream_active(true):
        return false
    if not _sound.register_listener(actor_id):
        perception.set_stream_active(false)
        return false
    var behavior: CohortInfectedBehaviorService = behavior_for_actor(actor_id)
    if behavior == null:
        var survivor_behavior := SurvivorBehaviorClass.new(
            _world, _kernel, _infected, perception, _sound, _movement, _combat, _health, actor_id, _player_id
        ) as SurvivorNpcBehaviorService
        if survivor_behavior == null or not survivor_behavior.configure_survivor_state(_npc_state):
            _sound.unregister_listener(actor_id)
            perception.set_stream_active(false)
            return false
        behavior = survivor_behavior
        _behaviors[actor_id] = behavior
    if not behavior.start():
        _sound.unregister_listener(actor_id)
        perception.set_stream_active(false)
        return false
    _active[actor_id] = true
    _activation_count += 1
    return true
