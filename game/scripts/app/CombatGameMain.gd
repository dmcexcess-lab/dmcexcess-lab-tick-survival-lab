extends VehicleGameMain
class_name CombatGameMain

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const CombatImpactProfilesClass = preload("res://scripts/simulation/combat/CombatImpactProfileCatalog.gd")
const CombatActionsClass = preload("res://scripts/simulation/combat/CombatActionService.gd")
const CombatOffersClass = preload("res://scripts/simulation/combat/CombatInteractionOfferProvider.gd")
const CombatSoundClass = preload("res://scripts/simulation/sound/CombatSoundEmitterAdapter.gd")
const CombatControllerClass = preload("res://scripts/player/CombatPlayerController.gd")
const FirearmProfilesClass = preload("res://scripts/simulation/combat/FirearmProfileCatalog.gd")
const FirearmStateClass = preload("res://scripts/simulation/combat/FirearmState.gd")
const FirearmActionsClass = preload("res://scripts/simulation/combat/FirearmActionService.gd")
const FirearmDamageClass = preload("res://scripts/simulation/combat/FirearmDamageInterruptionService.gd")
const FirearmSoundClass = preload("res://scripts/simulation/sound/FirearmSoundEmitterAdapter.gd")
const CorpseStateClass = preload("res://scripts/simulation/combat/CorpseState.gd")
const DeathTransitionsClass = preload("res://scripts/simulation/combat/ActorDeathTransitionService.gd")
const PopulationProjectionClass = preload("res://scripts/simulation/population/PopulationResidentProjection.gd")
const InfectedStateClass = preload("res://scripts/simulation/infected/InfectedState.gd")
const FirstInfectedHydratorClass = preload("res://scripts/simulation/infected/FirstInfectedHydrationService.gd")
const ActiveInfectedCohortClass = preload("res://scripts/simulation/infected/ActiveInfectedCohortService.gd")

const ACTIVE_INFECTED_COHORT_SIZE: int = 8

var _combat_impact_profiles: CombatImpactProfileCatalog = null
var _combat_actions: CombatActionService = null
var _combat_offers: CombatInteractionOfferProvider = null
var _combat_sound: CombatSoundEmitterAdapter = null
var _combat_controller: CombatPlayerController = null
var _firearm_profiles: FirearmProfileCatalog = null
var _firearm_state: FirearmState = null
var _firearm_actions: FirearmActionService = null
var _firearm_damage: FirearmDamageInterruptionService = null
var _firearm_sound: FirearmSoundEmitterAdapter = null
var _corpse_state: CorpseState = null
var _death_transitions: ActorDeathTransitionService = null
var _population_resident_projection: PopulationResidentProjection = null
var _infected_state: InfectedState = null
var _first_infected_hydrator: FirstInfectedHydrationService = null
var _infected_cohort_results: Array[Dictionary] = []
var _infected_cohort: ActiveInfectedCohortService = null

# Compatibility aliases for the already-closed one-infected seam.
var _first_infected_result: Dictionary = {}
var _first_infected_perception: ObserverPerceptionService = null
var _first_infected_behavior: FirstInfectedBehaviorService = null

func _boot_canonical_demo() -> bool:
    if not super._boot_canonical_demo(): return false
    if not _boot_system37_combat(): return false
    return _boot_first_real_infected()

func _boot_system37_combat() -> bool:
    if _world == null or _world_mutations == null or _spatial_query == null or _kernel == null \
        or _hand_state == null or _hand_mutations == null or _health_state == null or _condition_service == null \
        or _condition_modifiers == null or _physical_catalog == null or _spatial_sound == null \
        or _inventory_state == null or _inventory_mutations == null or _collision_catalog == null \
        or _interaction_reach == null or _interaction_affordances == null or _perception == null \
        or _world_interaction_controller == null:
        return false

    _combat_impact_profiles = CombatImpactProfilesClass.new()
    _combat_actions = CombatActionsClass.new(_world, _world_mutations, _spatial_query, _kernel, _hand_state, _health_state, _condition_service, _condition_modifiers, _physical_catalog, _combat_impact_profiles)
    if not _combat_actions.is_ready(): return false
    _combat_sound = CombatSoundClass.new(_world, _combat_actions, _spatial_sound)
    if not _combat_sound.is_ready(): return false
    _combat_offers = CombatOffersClass.new(_world, _interaction_reach, _perception, _health_state, _combat_actions)
    if not _combat_offers.is_ready() or not _interaction_affordances.register_provider(_combat_offers): return false
    for action_id: StringName in CombatActionsClass.ACTION_IDS:
        if not _world_interaction_controller.register_handler(action_id, Callable(_combat_actions, "request_action")): return false

    _firearm_profiles = FirearmProfilesClass.new()
    if not _firearm_profiles.register_physical_profiles(_physical_catalog): return false
    _firearm_state = FirearmStateClass.new(_world, _inventory_state, _inventory_mutations, _firearm_profiles)
    if not _firearm_state.is_ready(): return false
    _firearm_actions = FirearmActionsClass.new(_world, _world_mutations, _spatial_query, _kernel, _hand_state, _health_state, _inventory_state, _inventory_mutations, _firearm_profiles, _firearm_state)
    if not _firearm_actions.is_ready(): return false
    _firearm_damage = FirearmDamageClass.new(_health_state, _kernel)
    if not _firearm_damage.is_ready(): return false
    _firearm_sound = FirearmSoundClass.new(_firearm_actions, _spatial_sound)
    if not _firearm_sound.is_ready(): return false

    _corpse_state = CorpseStateClass.new()
    if not _collision_catalog.register(DeathTransitionsClass.CORPSE_SEMANTIC, false): return false
    _death_transitions = DeathTransitionsClass.new(_world, _world_mutations, _kernel, _health_state, _hand_state, _hand_mutations, _inventory_state, _inventory_mutations, _corpse_state)
    if not _death_transitions.is_ready(): return false

    _combat_controller = CombatControllerClass.new(_combat_actions, _kernel, FixtureClass.PLAYER_ID, _firearm_actions)
    add_child(_combat_controller)
    if not _combat_controller.is_ready(): return false
    _combat_controller.action_resolved.connect(Callable(_hud, "present_action_result"))
    _combat_controller.action_busy_changed.connect(_on_player_action_busy_changed)
    return true

func _boot_first_real_infected() -> bool:
    var global_plan: GeneratedGlobalWorldPlan = FixtureClass.global_plan()
    var player: WorldPlacement = _world.placement(FixtureClass.PLAYER_ID)
    if global_plan == null or not global_plan.is_generated() or player == null \
        or _locomotion_mutations == null or _skill_state == null or _carry_state == null or _condition_state == null:
        return false
    var population_plan := {
        "ok": true,
        "settlements": global_plan.population_settlements.duplicate(true),
        "resident_population": global_plan.resident_population,
        "infected_population": global_plan.infected_population,
        "survivor_population": global_plan.survivor_population,
        "local_area_manifest": global_plan.local_area_manifest.duplicate(true),
    }
    _population_resident_projection = PopulationProjectionClass.new()
    _infected_state = InfectedStateClass.new()
    _first_infected_hydrator = FirstInfectedHydratorClass.new(
        _world, _world_mutations, _spatial_query, _kernel,
        _population_resident_projection, _infected_state,
        _locomotion_mutations, _hand_mutations, _inventory_mutations,
        _health_state, _skill_state, _carry_state, _condition_state
    )
    if not _first_infected_hydrator.is_ready(): return false

    var cohort_result: Dictionary = _first_infected_hydrator.hydrate_cohort(
        population_plan,
        FixtureClass.CENTRAL_SITE_ID,
        player.anchor,
        ACTIVE_INFECTED_COHORT_SIZE
    )
    if not bool(cohort_result.get("ok", false)):
        push_error("CombatGameMain: infected cohort hydration failed: %s" % String(cohort_result.get("reason", "unknown")))
        return false
    for value: Variant in cohort_result.get("members", []):
        if typeof(value) == TYPE_DICTIONARY:
            _infected_cohort_results.append((value as Dictionary).duplicate(true))
    if _infected_cohort_results.size() != ACTIVE_INFECTED_COHORT_SIZE:
        return false
    _first_infected_result = _infected_cohort_results[0].duplicate(true)
    if _perception != null: _perception.recompute(&"infected_cohort_hydrated")
    return _boot_infected_cohort_behavior()

func _boot_infected_cohort_behavior() -> bool:
    var streaming: WorldStreamingCoordinator = FixtureClass.streaming_coordinator()
    if streaming == null or _perception_memory == null or _perception == null \
        or _spatial_sound == null or _movement == null or _combat_actions == null:
        return false
    _infected_cohort = ActiveInfectedCohortClass.new(
        _world,
        _door_state,
        _kernel,
        _infected_state,
        _perception_memory,
        _perception.acquisition_provider(),
        _spatial_sound,
        _movement,
        _combat_actions,
        _health_state,
        streaming,
        FixtureClass.PLAYER_ID
    )
    if _infected_cohort == null or not _infected_cohort.configure(_infected_cohort_results):
        return false

    var first_id: String = String(_first_infected_result.get("actor_id", ""))
    _first_infected_perception = _infected_cohort.perception_for_actor(first_id)
    _first_infected_behavior = _infected_cohort.behavior_for_actor(first_id)
    return not first_id.is_empty() and _first_infected_perception != null and _first_infected_behavior != null

func infected_cohort_service() -> ActiveInfectedCohortService:
    return _infected_cohort

func infected_cohort_results() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for member: Dictionary in _infected_cohort_results:
        result.append(member.duplicate(true))
    return result

func first_infected_result() -> Dictionary:
    return _first_infected_result.duplicate(true)

func first_infected_behavior() -> FirstInfectedBehaviorService:
    return _first_infected_behavior

func first_infected_perception() -> ObserverPerceptionService:
    return _first_infected_perception

func _route_player_intent(intent: StringName) -> void:
    if intent == Intents.COMBAT_FORWARD and _combat_controller != null and (_vehicle_controller == null or not _vehicle_controller.is_mounted()):
        _combat_controller.submit_intent(intent)
        return
    super._route_player_intent(intent)