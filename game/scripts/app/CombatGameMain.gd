extends VehicleGameMain
class_name CombatGameMain

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const CombatImpactProfilesClass = preload("res://scripts/simulation/combat/CombatImpactProfileCatalog.gd")
const CombatActionsClass = preload("res://scripts/simulation/combat/CombatActionService.gd")
const CombatOffersClass = preload("res://scripts/simulation/combat/CombatInteractionOfferProvider.gd")
const CombatSoundClass = preload("res://scripts/simulation/sound/CombatSoundEmitterAdapter.gd")
const CombatControllerClass = preload("res://scripts/player/CombatPlayerController.gd")

var _combat_impact_profiles: CombatImpactProfileCatalog = null
var _combat_actions: CombatActionService = null
var _combat_offers: CombatInteractionOfferProvider = null
var _combat_sound: CombatSoundEmitterAdapter = null
var _combat_controller: CombatPlayerController = null

func _boot_canonical_demo() -> bool:
    if not super._boot_canonical_demo():
        return false
    return _boot_system37_combat()

func _boot_system37_combat() -> bool:
    if _world == null or _world_mutations == null or _spatial_query == null or _kernel == null \
        or _hand_state == null or _health_state == null or _condition_service == null \
        or _condition_modifiers == null or _physical_catalog == null or _spatial_sound == null \
        or _interaction_reach == null or _interaction_affordances == null or _perception == null \
        or _world_interaction_controller == null:
        return false
    _combat_impact_profiles = CombatImpactProfilesClass.new()
    _combat_actions = CombatActionsClass.new(
        _world,
        _world_mutations,
        _spatial_query,
        _kernel,
        _hand_state,
        _health_state,
        _condition_service,
        _condition_modifiers,
        _physical_catalog,
        _combat_impact_profiles
    )
    if not _combat_actions.is_ready():
        return false
    _combat_sound = CombatSoundClass.new(_world, _combat_actions, _spatial_sound)
    if not _combat_sound.is_ready():
        return false
    _combat_offers = CombatOffersClass.new(_world, _interaction_reach, _perception, _health_state, _combat_actions)
    if not _combat_offers.is_ready() or not _interaction_affordances.register_provider(_combat_offers):
        return false
    for action_id: StringName in CombatActionsClass.ACTION_IDS:
        if not _world_interaction_controller.register_handler(action_id, Callable(_combat_actions, "request_action")):
            return false
    _combat_controller = CombatControllerClass.new(_combat_actions, _kernel, FixtureClass.PLAYER_ID)
    add_child(_combat_controller)
    if not _combat_controller.is_ready():
        return false
    _combat_controller.action_resolved.connect(Callable(_hud, "present_action_result"))
    _combat_controller.action_busy_changed.connect(_on_player_action_busy_changed)
    return true

func _route_player_intent(intent: StringName) -> void:
    if intent == Intents.COMBAT_FORWARD and _combat_controller != null \
        and (_vehicle_controller == null or not _vehicle_controller.is_mounted()):
        _combat_controller.submit_intent(intent)
        return
    super._route_player_intent(intent)
