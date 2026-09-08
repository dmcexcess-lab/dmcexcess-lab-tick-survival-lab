extends CombatGameMain
class_name EnvironmentalPressureGameMain

const OpeningPressureClass = preload("res://scripts/simulation/interaction/ActorOpeningPressureActionService.gd")

@onready var _resolution_indicator: WorldResolutionIndicator = $ResolutionIndicator

var _opening_pressure: ActorOpeningPressureActionService = null

func _boot_canonical_demo() -> bool:
    if not super._boot_canonical_demo():
        return false
    if not _boot_system39_environmental_pressure():
        return false
    return _boot_world_resolution_indicator()

func _boot_system39_environmental_pressure() -> bool:
    if _world == null or _world_interaction_state == null or _door_state == null \
        or _door_transition == null or _interaction_reach == null or _spatial_query == null \
        or _kernel == null or _world_interaction_catalog == null or _world_interaction_actions == null \
        or _spatial_sound == null or _infected_cohort == null:
        return false

    _opening_pressure = OpeningPressureClass.new(
        _world,
        _world_interaction_state,
        _door_state,
        _door_transition,
        _interaction_reach,
        _spatial_query,
        _kernel,
        _world_interaction_catalog,
        _world_interaction_actions,
        _spatial_sound
    )
    if _opening_pressure == null or not _opening_pressure.is_ready():
        return false

    for actor_id: String in _infected_cohort.roster_actor_ids():
        var behavior: CohortInfectedBehaviorService = _infected_cohort.behavior_for_actor(actor_id)
        if behavior == null or not behavior.configure_opening_pressure(_opening_pressure):
            return false
    return true

func _boot_world_resolution_indicator() -> bool:
    var streaming: WorldStreamingCoordinator = FixtureClass.streaming_coordinator()
    if _resolution_indicator == null or _kernel == null or _infected_cohort == null or streaming == null:
        return false
    return _resolution_indicator.configure(_kernel, _infected_cohort, streaming)

func opening_pressure_service() -> ActorOpeningPressureActionService:
    return _opening_pressure

func world_resolution_indicator() -> WorldResolutionIndicator:
    return _resolution_indicator
