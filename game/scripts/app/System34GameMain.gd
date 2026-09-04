extends UtilityGameMain
class_name System34GameMain

const ConditionStateClass = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const ConditionModifierClass = preload("res://scripts/simulation/actors/condition/ActorConditionModifierQuery.gd")
const ConditionServiceClass = preload("res://scripts/simulation/actors/condition/ActorConditionService.gd")
const ConditionMoodletClass = preload("res://scripts/simulation/actors/condition/ActorConditionMoodletQuery.gd")
const ConditionMobilityClass = preload("res://scripts/simulation/actors/condition/ActorConditionMobilityModifierProvider.gd")
const ConditionExertionClass = preload("res://scripts/simulation/actors/condition/MovementConditionExertionService.gd")
const ConditionFearClass = preload("res://scripts/simulation/actors/condition/ConditionPerceptionFearAdapter.gd")
const ConditionHeardFearClass = preload("res://scripts/simulation/actors/condition/ConditionHeardFearAdapter.gd")
const ConditionEnvironmentClass = preload("res://scripts/simulation/actors/condition/ConditionEnvironmentPressureAdapter.gd")
const SustainmentProfilesClass = preload("res://scripts/simulation/actors/condition/SurvivorSustainmentProfileCatalog.gd")
const SustainmentActionsClass = preload("res://scripts/simulation/actors/condition/SurvivorSustainmentActionService.gd")
const FirstAidActionsClass = preload("res://scripts/simulation/actors/health/SurvivorFirstAidActionService.gd")
const ConditionControlsClass = preload("res://scripts/ui/ConditionPlayerControls.gd")

const WATER_FIXTURE_SEMANTICS: Array[StringName] = [&"prop.kitchen_sink", &"prop.bathroom_vanity"]
const BED_SEMANTICS: Array[StringName] = [&"prop.bed_double", &"prop.bed_single"]

var _condition_state: ActorConditionState = null
var _condition_modifiers: ActorConditionModifierQuery = null
var _condition_service: ActorConditionService = null
var _condition_moodlets: ActorConditionMoodletQuery = null
var _condition_mobility: ActorConditionMobilityModifierProvider = null
var _condition_exertion: MovementConditionExertionService = null
var _condition_fear: ConditionPerceptionFearAdapter = null
var _condition_heard_fear: ConditionHeardFearAdapter = null
var _condition_environment: ConditionEnvironmentPressureAdapter = null
var _sustainment_profiles: SurvivorSustainmentProfileCatalog = null
var _sustainment_actions: SurvivorSustainmentActionService = null
var _first_aid_actions: SurvivorFirstAidActionService = null
var _condition_controls: ConditionPlayerControls = null

func _boot_canonical_demo() -> bool:
    if not super._boot_canonical_demo():
        return false
    return _boot_system34()

func _boot_system34() -> bool:
    if _kernel == null or _world_time_profile == null or _health_state == null or _carry_query == null:
        return false
    _condition_state = ConditionStateClass.new(_world)
    if not _condition_state.enroll_actor(FixtureClass.PLAYER_ID, _kernel.world_tick()):
        return false
    _condition_modifiers = ConditionModifierClass.new(_condition_state, _world_time_profile, _kernel)
    if not _condition_modifiers.is_ready():
        return false
    _condition_service = ConditionServiceClass.new(
        _condition_state,
        _health_state,
        _kernel,
        _world_time_profile,
        _condition_modifiers
    )
    if not _condition_service.is_ready():
        return false
    _condition_moodlets = ConditionMoodletClass.new(_condition_modifiers, _health_state, _carry_query)
    if not _condition_moodlets.is_ready():
        return false
    if _hearing_profile != null and not _hearing_profile.configure_condition(_condition_service):
        return false

    if not _carry_query.configure_capacity_modifier(_condition_modifiers):
        return false
    _condition_mobility = ConditionMobilityClass.new(_condition_service, _condition_modifiers)
    if _movement_capability == null or not _movement_capability.register_provider(_condition_mobility):
        return false
    _condition_exertion = ConditionExertionClass.new(_movement, _condition_service, _carry_query)
    if not _condition_exertion.is_ready():
        return false

    _condition_fear = ConditionFearClass.new(_world, _perception, _condition_service, FixtureClass.PLAYER_ID)
    if _perception != null and _perception.is_ready() and not _condition_fear.is_ready():
        return false
    _condition_heard_fear = ConditionHeardFearClass.new(_spatial_sound, _condition_service, FixtureClass.PLAYER_ID)
    if _spatial_sound != null and _spatial_sound.is_ready() and not _condition_heard_fear.is_ready():
        return false
    _condition_environment = ConditionEnvironmentClass.new(
        _world,
        _weather,
        _carry_query,
        _condition_service,
        _kernel,
        FixtureClass.PLAYER_ID
    )
    if _weather != null and _weather.is_ready() and not _condition_environment.is_ready():
        return false

    _sustainment_profiles = SustainmentProfilesClass.new()
    _sustainment_actions = SustainmentActionsClass.new(
        _world,
        _world_mutations,
        _hand_state,
        _hand_mutations,
        _inventory_state,
        _inventory_mutations,
        _freshness_query,
        _freshness_mutations,
        _carry_query,
        _kernel,
        _world_time_profile,
        _condition_service,
        _sustainment_profiles
    )
    if not _sustainment_actions.is_ready():
        return false
    if _shell == null or not _shell.configure_inventory_actions(_sustainment_actions):
        return false
    _first_aid_actions = FirstAidActionsClass.new(
        _world,
        _world_mutations,
        _hand_state,
        _hand_mutations,
        _inventory_state,
        _inventory_mutations,
        _carry_query,
        _kernel,
        _health_state,
        _skill_checks
    )
    if not _first_aid_actions.is_ready() or not _shell.configure_first_aid_actions(_first_aid_actions):
        return false
    if not _sustainment_actions.set_potable_source_provider(Callable(self, "_potable_water_fixture_in_reach")):
        return false
    if not _sustainment_actions.set_sleep_surface_provider(Callable(self, "_sleep_surface_in_reach")):
        return false

    if _status_summary == null or not _status_summary.configure_condition(
        _condition_service,
        _condition_modifiers,
        _condition_moodlets
    ):
        return false

    _condition_controls = ConditionControlsClass.new()
    add_child(_condition_controls)
    if not _condition_controls.configure(_sustainment_actions, _kernel, FixtureClass.PLAYER_ID):
        return false

    var refresh_callable := Callable(self, "_on_system34_changed")
    if not _condition_service.condition_changed.is_connected(refresh_callable):
        _condition_service.condition_changed.connect(refresh_callable)
    if not _condition_service.fatigue_changed.is_connected(refresh_callable):
        _condition_service.fatigue_changed.connect(refresh_callable)
    _hud.refresh()
    return true

func _potable_water_fixture_in_reach(actor_id: String) -> bool:
    if _utilities == null or not _utilities.is_ready():
        return false
    var placement: WorldPlacement = _world.placement(actor_id)
    if placement == null:
        return false
    for cell: Vector2i in _contact_cells(placement.anchor):
        for entity_id: String in _world.entities_at(cell):
            var entity: WorldEntityRecord = _world.entity(entity_id)
            if entity == null or entity.semantic_type not in WATER_FIXTURE_SEMANTICS:
                continue
            var service_id: String = _utilities.water_service_for_cell(cell)
            if not service_id.is_empty() and _utilities.water_service_available(service_id):
                return true
    return false

func _sleep_surface_in_reach(actor_id: String) -> StringName:
    var placement: WorldPlacement = _world.placement(actor_id)
    if placement == null:
        return &"ground"
    for cell: Vector2i in _contact_cells(placement.anchor):
        for entity_id: String in _world.entities_at(cell):
            var entity: WorldEntityRecord = _world.entity(entity_id)
            if entity != null and entity.semantic_type in BED_SEMANTICS:
                return &"bed"
    return &"ground"

static func _contact_cells(anchor: Vector2i) -> Array[Vector2i]:
    return [
        anchor,
        anchor + Vector2i.UP,
        anchor + Vector2i.RIGHT,
        anchor + Vector2i.DOWN,
        anchor + Vector2i.LEFT,
    ]

func _on_system34_changed(_actor_id: String, _a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
    if _hud != null:
        _hud.refresh()
