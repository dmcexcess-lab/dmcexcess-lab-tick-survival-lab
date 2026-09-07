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
const FirearmSoundClass = preload("res://scripts/simulation/sound/FirearmSoundEmitterAdapter.gd")
const CorpseStateClass = preload("res://scripts/simulation/combat/CorpseState.gd")
const DeathTransitionsClass = preload("res://scripts/simulation/combat/ActorDeathTransitionService.gd")

var _combat_impact_profiles: CombatImpactProfileCatalog = null
var _combat_actions: CombatActionService = null
var _combat_offers: CombatInteractionOfferProvider = null
var _combat_sound: CombatSoundEmitterAdapter = null
var _combat_controller: CombatPlayerController = null
var _firearm_profiles: FirearmProfileCatalog = null
var _firearm_state: FirearmState = null
var _firearm_actions: FirearmActionService = null
var _firearm_sound: FirearmSoundEmitterAdapter = null
var _corpse_state: CorpseState = null
var _death_transitions: ActorDeathTransitionService = null

func _boot_canonical_demo() -> bool:
    if not super._boot_canonical_demo(): return false
    return _boot_system37_combat()

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

func _route_player_intent(intent: StringName) -> void:
    if intent == Intents.COMBAT_FORWARD and _combat_controller != null and (_vehicle_controller == null or not _vehicle_controller.is_mounted()):
        _combat_controller.submit_intent(intent)
        return
    super._route_player_intent(intent)
