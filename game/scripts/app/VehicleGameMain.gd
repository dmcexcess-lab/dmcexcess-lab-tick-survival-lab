extends System34GameMain
class_name VehicleGameMain

const VehicleProfilesClass = preload("res://scripts/simulation/vehicles/VehicleProfileCatalog.gd")
const VehicleStateClass = preload("res://scripts/simulation/vehicles/VehicleState.gd")
const VehicleSeederClass = preload("res://scripts/simulation/vehicles/VehicleWorldSeeder.gd")
const VehicleActionsClass = preload("res://scripts/simulation/vehicles/VehicleActionService.gd")
const VehicleCargoClass = preload("res://scripts/simulation/vehicles/VehicleCargoService.gd")
const VehicleConsequencesClass = preload("res://scripts/simulation/vehicles/VehicleConsequenceAdapter.gd")
const VehicleLightingClass = preload("res://scripts/simulation/vehicles/VehicleLightingSourceAdapter.gd")
const VehicleItems = preload("res://scripts/simulation/vehicles/VehicleItemCatalog.gd")
const VehicleControllerClass = preload("res://scripts/player/VehiclePlayerController.gd")
const VehicleControlsClass = preload("res://scripts/ui/VehiclePlayerControls.gd")

const InteractionStateClass = preload("res://scripts/simulation/interaction/WorldInteractableState.gd")
const InteractionCatalogClass = preload("res://scripts/simulation/interaction/WorldInteractionCatalog.gd")
const InteractionItemsClass = preload("res://scripts/simulation/interaction/WorldInteractionItemCatalog.gd")
const InteractionActionsClass = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const RepairActionsClass = preload("res://scripts/simulation/interaction/WorldObjectRepairActionService.gd")
const InteractionOffersClass = preload("res://scripts/simulation/interaction/WorldInteractionOfferProvider.gd")
const SustainmentOffersClass = preload("res://scripts/simulation/interaction/SustainmentInteractionOfferProvider.gd")
const InteractionPanelClass = preload("res://scripts/ui/WorldInteractionPanel.gd")
const InteractionControllerClass = preload("res://scripts/player/WorldInteractionPlayerController.gd")
const LootOffersClass = preload("res://scripts/simulation/loot/LootSearchInteractionOfferProvider.gd")
const CraftingOffersClass = preload("res://scripts/simulation/crafting/CraftingInteractionOfferProvider.gd")
const Workstations = preload("res://scripts/simulation/crafting/CraftingWorkstationCatalog.gd")
const UtilityRepairActionsClass = preload("res://scripts/simulation/utilities/UtilityPowerRepairActionService.gd")
const UtilityRepairOffersClass = preload("res://scripts/simulation/utilities/UtilityPowerRepairInteractionOfferProvider.gd")

var _vehicle_profiles: VehicleProfileCatalog = null
var _vehicle_state: VehicleState = null
var _vehicle_seeder: VehicleWorldSeeder = null
var _vehicle_actions: VehicleActionService = null
var _vehicle_cargo: VehicleCargoService = null
var _vehicle_consequences: VehicleConsequenceAdapter = null
var _vehicle_lighting: VehicleLightingSourceAdapter = null
var _vehicle_controller: VehiclePlayerController = null
var _vehicle_controls: VehiclePlayerControls = null

var _world_interaction_state: WorldInteractableState = null
var _world_interaction_catalog: WorldInteractionCatalog = null
var _world_interaction_actions: WorldInteractionActionService = null
var _world_repair_actions: WorldObjectRepairActionService = null
var _utility_power_repair_actions: UtilityPowerRepairActionService = null
var _world_interaction_offers: WorldInteractionOfferProvider = null
var _sustainment_interaction_offers: SustainmentInteractionOfferProvider = null
var _utility_power_repair_offers: UtilityPowerRepairInteractionOfferProvider = null
var _world_interaction_panel: WorldInteractionPanel = null
var _world_interaction_controller: WorldInteractionPlayerController = null
var _world_blocks_interaction: bool = false

func _boot_canonical_demo() -> bool:
    if not super._boot_canonical_demo():
        return false
    if not _boot_system36():
        return false
    return _boot_world_interactions()

func _boot_system36() -> bool:
    if _world == null or _world_mutations == null or _spatial_query == null or _collision_catalog == null \
        or _collision_overrides == null or _kernel == null or _skill_checks == null or _condition_service == null \
        or _inventory_state == null or _inventory_mutations == null or _weight_query == null or _physical_catalog == null \
        or _spatial_sound == null or _health_state == null or _utility_lighting == null or _physical_lighting == null:
        return false
    _vehicle_profiles = VehicleProfilesClass.new()
    _vehicle_state = VehicleStateClass.new()
    if not VehicleItems.register_physical_profiles(_physical_catalog):
        return false
    _vehicle_seeder = VehicleSeederClass.new(
        _world,
        _world_mutations,
        _spatial_query,
        _collision_catalog,
        _inventory_mutations,
        _vehicle_profiles,
        _vehicle_state,
        FixtureClass.active_seed()
    )
    var seeded := _vehicle_seeder.seed_near(FixtureClass.PLAYER_ID)
    if seeded < 1:
        push_error("VehicleGameMain: no plausible parked vehicle locations were generated near the playable start")
        return false
    _vehicle_actions = VehicleActionsClass.new(
        _world,
        _world_mutations,
        _spatial_query,
        _collision_overrides,
        _kernel,
        _skill_checks,
        _condition_service,
        _inventory_state,
        _inventory_mutations,
        _vehicle_profiles,
        _vehicle_state
    )
    if not _vehicle_actions.is_ready():
        return false
    _vehicle_cargo = VehicleCargoClass.new(
        _world,
        _vehicle_state,
        _vehicle_profiles,
        _inventory_state,
        _inventory_mutations,
        _weight_query
    )
    if not _vehicle_cargo.is_ready():
        return false

    _vehicle_consequences = VehicleConsequencesClass.new(
        _world,
        _vehicle_state,
        _vehicle_profiles,
        _vehicle_actions,
        _spatial_sound,
        _health_state
    )
    if not _vehicle_consequences.is_ready():
        return false

    _vehicle_lighting = VehicleLightingClass.new(_world, _vehicle_state, _vehicle_profiles)
    if not _vehicle_lighting.is_ready() or not _wire_vehicle_lighting():
        return false

    _vehicle_controller = VehicleControllerClass.new(_vehicle_actions, _kernel, FixtureClass.PLAYER_ID)
    add_child(_vehicle_controller)
    if not _vehicle_controller.is_ready():
        return false

    var base_callable := Callable(_controller, "submit_intent")
    if _keyboard.action_intent.is_connected(base_callable):
        _keyboard.action_intent.disconnect(base_callable)
    if _controls.action_intent.is_connected(base_callable):
        _controls.action_intent.disconnect(base_callable)
    _keyboard.action_intent.connect(_route_player_intent)
    _controls.action_intent.connect(_route_player_intent)
    _vehicle_controller.action_resolved.connect(Callable(_hud, "present_action_result"))
    _vehicle_controller.action_busy_changed.connect(_on_player_action_busy_changed)

    if not _world_view.configure_vehicles(_world, _vehicle_state, _vehicle_profiles):
        return false
    _vehicle_controls = VehicleControlsClass.new()
    add_child(_vehicle_controls)
    if not _vehicle_controls.configure(
        _vehicle_controller,
        _vehicle_actions,
        _vehicle_state,
        _vehicle_cargo,
        _inventory_state,
        FixtureClass.PLAYER_ID
    ):
        return false
    return true

func _boot_world_interactions() -> bool:
    if _interaction_reach == null or _interaction_affordances == null or _door_state == null \
        or _door_transition == null or _door_passage == null or _spatial_query == null \
        or _skill_checks == null or _carry_query == null or _hand_state == null or _hand_mutations == null \
        or _carry_acquisition == null or _sustainment_actions == null or _utilities == null or _power_network == null \
        or _crafting_plans == null or _crafting_interaction_offers == null \
        or _crafting_controller == null or _loot_controller == null:
        return false

    _world_interaction_catalog = InteractionCatalogClass.new()
    _world_interaction_state = InteractionStateClass.new()
    if not InteractionItemsClass.register_physical_profiles(_physical_catalog):
        return false

    _world_interaction_actions = InteractionActionsClass.new(
        _world,
        _world_mutations,
        _door_state,
        _door_transition,
        _interaction_reach,
        _spatial_query,
        _kernel,
        _skill_checks,
        _carry_query,
        _hand_state,
        _hand_mutations,
        _inventory_state,
        _inventory_mutations,
        _carry_acquisition,
        _world_interaction_state,
        _world_interaction_catalog
    )
    if not _world_interaction_actions.is_ready():
        return false
    _world_repair_actions = RepairActionsClass.new(
        _world,
        _world_mutations,
        _door_state,
        _door_transition,
        _interaction_reach,
        _kernel,
        _skill_checks,
        _carry_query,
        _hand_state,
        _hand_mutations,
        _inventory_state,
        _inventory_mutations,
        _world_interaction_state,
        _world_interaction_catalog
    )
    if not _world_repair_actions.is_ready():
        return false
    _utility_power_repair_actions = UtilityRepairActionsClass.new(
        _world,
        _world_mutations,
        _interaction_reach,
        _kernel,
        _skill_checks,
        _carry_query,
        _hand_state,
        _hand_mutations,
        _inventory_state,
        _inventory_mutations,
        _power_network
    )
    if not _utility_power_repair_actions.is_ready():
        return false
    if not _door_passage.set_access_provider(Callable(self, "_door_passage_allowed")):
        return false

    _world_interaction_offers = InteractionOffersClass.new(
        _world,
        _interaction_reach,
        _door_state,
        _world_interaction_state,
        _world_interaction_catalog
    )
    if not _interaction_affordances.register_provider(_world_interaction_offers):
        return false
    _utility_power_repair_offers = UtilityRepairOffersClass.new(
        _world,
        _interaction_reach,
        _power_network
    )
    if not _interaction_affordances.register_provider(_utility_power_repair_offers):
        return false

    if not _sustainment_actions.set_potable_target_provider(Callable(self, "_potable_target_available")) \
        or not _sustainment_actions.set_rest_target_provider(Callable(self, "_rest_target_surface")):
        return false
    _sustainment_interaction_offers = SustainmentOffersClass.new(
        _world,
        _interaction_reach,
        _world_interaction_catalog,
        Callable(self, "_potable_target_available")
    )
    if not _interaction_affordances.register_provider(_sustainment_interaction_offers):
        return false

    if not _crafting_plans.set_workstation_availability_provider(Callable(self, "_crafting_workstation_available")):
        return false
    var utility_callback := Callable(self, "_on_interaction_utility_changed")
    if not _utilities.power_changed.is_connected(utility_callback):
        _utilities.power_changed.connect(utility_callback)
    if not _utilities.water_changed.is_connected(utility_callback):
        _utilities.water_changed.connect(utility_callback)

    if not _world_view.configure_world_interaction_state(_world, _world_interaction_state):
        return false

    _world_interaction_panel = InteractionPanelClass.new()
    add_child(_world_interaction_panel)
    _world_interaction_panel.interaction_blocked_changed.connect(_on_world_interaction_blocked_changed)
    _world_interaction_controller = InteractionControllerClass.new(
        _world,
        _interaction_affordances,
        _kernel,
        _world_interaction_panel,
        FixtureClass.PLAYER_ID
    )
    if not _world_interaction_controller.is_ready():
        return false

    for action_id: StringName in InteractionActionsClass.CORE_ACTIONS:
        if not _world_interaction_controller.register_handler(action_id, Callable(_world_interaction_actions, "request_action")):
            return false
    if not _world_interaction_controller.register_handler(
        RepairActionsClass.ACTION_ID,
        Callable(_world_repair_actions, "request_action")
    ):
        return false
    if not _world_interaction_controller.register_handler(
        UtilityRepairActionsClass.ACTION_ID,
        Callable(_utility_power_repair_actions, "request_action")
    ):
        return false
    for action_id: StringName in [
        SustainmentOffersClass.DRINK_FROM_FIXTURE,
        SustainmentOffersClass.REST_ON_FURNITURE,
        SustainmentOffersClass.SLEEP_IN_BED,
    ]:
        if not _world_interaction_controller.register_handler(action_id, Callable(self, "_request_target_sustainment")):
            return false
    if not _world_interaction_controller.register_delegated_handler(
        CraftingOffersClass.ACTION_ID,
        Callable(self, "_request_target_crafting")
    ):
        return false
    if not _world_interaction_controller.register_delegated_handler(
        LootOffersClass.SEARCH_ACTION_ID,
        Callable(self, "_request_target_loot")
    ):
        return false
    _world_interaction_controller.action_finished.connect(_on_world_interaction_action_finished)

    var old_door_callable := Callable(_door_controller, "submit_world_cell")
    if _door_controller != null and _door_pointer.world_cell_primary.is_connected(old_door_callable):
        _door_pointer.world_cell_primary.disconnect(old_door_callable)
    var old_loot_callable := Callable(_loot_controller, "submit_world_cell")
    if _door_pointer.world_cell_primary.is_connected(old_loot_callable):
        _door_pointer.world_cell_primary.disconnect(old_loot_callable)
    var old_crafting_callable := Callable(_crafting_controller, "submit_world_cell")
    if _door_pointer.world_cell_primary.is_connected(old_crafting_callable):
        _door_pointer.world_cell_primary.disconnect(old_crafting_callable)
    var interaction_callable := Callable(_world_interaction_controller, "submit_world_cell")
    if not _door_pointer.world_cell_primary.is_connected(interaction_callable):
        _door_pointer.world_cell_primary.connect(interaction_callable)
    return true

func _route_player_intent(intent: StringName) -> void:
    if _vehicle_controller != null and _vehicle_controller.is_mounted():
        _vehicle_controller.submit_intent(intent)
    elif _controller != null:
        _controller.submit_intent(intent)

func _wire_vehicle_lighting() -> bool:
    if _vehicle_lighting == null or _utility_lighting == null or _physical_lighting == null:
        return false
    var inherited_callable := Callable(self, "_on_lighting_emitters_changed")
    if _utility_lighting.emitters_changed.is_connected(inherited_callable):
        _utility_lighting.emitters_changed.disconnect(inherited_callable)
    var combined_callable := Callable(self, "_on_vehicle_lighting_inputs_changed")
    if not _utility_lighting.emitters_changed.is_connected(combined_callable):
        _utility_lighting.emitters_changed.connect(combined_callable)
    if not _vehicle_lighting.emitters_changed.is_connected(combined_callable):
        _vehicle_lighting.emitters_changed.connect(combined_callable)
    return _sync_vehicle_lighting_emitters()

func _sync_vehicle_lighting_emitters() -> bool:
    if _utility_lighting == null or _vehicle_lighting == null or _physical_lighting == null:
        return false
    var combined: Array[LightEmitter] = []
    for emitter: LightEmitter in _utility_lighting.emitters():
        combined.append(emitter)
    for emitter: LightEmitter in _vehicle_lighting.emitters():
        combined.append(emitter)
    return _physical_lighting.set_emitters(combined)

func _on_vehicle_lighting_inputs_changed(_emitters: Array) -> void:
    if not _sync_vehicle_lighting_emitters():
        return
    _lighting_refresh_pending = true
    call_deferred("_flush_pending_visual_state")

func _door_passage_allowed(_actor_id: String, door_id: String, _action_type: StringName) -> bool:
    if _world_interaction_state == null:
        return true
    return not _world_interaction_state.is_locked(door_id) \
        and _world_interaction_state.board_count(door_id) == 0 \
        and not _world_interaction_state.is_broken(door_id)

func _potable_target_available(actor_id: String, target_id: String) -> bool:
    if _world == null or _utilities == null or _interaction_reach == null \
        or not _world.has_entity(target_id) \
        or not _interaction_reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
        return false
    var entity: WorldEntityRecord = _world.entity(target_id)
    var placement: WorldPlacement = _world.placement(target_id)
    if entity == null or placement == null or not _world_interaction_catalog.is_water_fixture(entity.semantic_type):
        return false
    var service_id: String = _utilities.water_service_for_cell(placement.anchor)
    return not service_id.is_empty() and _utilities.water_service_available(service_id)

func _rest_target_surface(actor_id: String, target_id: String) -> StringName:
    if _world == null or _interaction_reach == null or not _world.has_entity(target_id) \
        or not _interaction_reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
        return &""
    var entity: WorldEntityRecord = _world.entity(target_id)
    if entity == null:
        return &""
    return _world_interaction_catalog.rest_surface(entity.semantic_type)

func _request_target_sustainment(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    var serial: int = 0
    if action_id == SustainmentOffersClass.DRINK_FROM_FIXTURE:
        serial = _sustainment_actions.begin_tap_drink_from(actor_id, target_id)
    elif action_id == SustainmentOffersClass.REST_ON_FURNITURE:
        serial = _sustainment_actions.begin_rest_on(actor_id, target_id)
    elif action_id == SustainmentOffersClass.SLEEP_IN_BED:
        serial = _sustainment_actions.begin_sleep_in(actor_id, target_id)
    return {
        "accepted": serial > 0,
        "action_serial": serial,
        "reason": "" if serial > 0 else "sustainment_target_unavailable",
        "action_id": action_id,
        "target_id": target_id,
    }

func _request_target_crafting(_actor_id: String, target_id: String, _action_id: StringName) -> Dictionary:
    if _crafting_controller == null or _crafting_panel == null:
        return {"success": false, "reason": "crafting_input_not_ready"}
    var success: bool = _crafting_controller.request_open_workstation(target_id)
    if success:
        var snapshot: Dictionary = _crafting_panel.presentation_snapshot()
        success = _crafting_panel.is_open() and String(snapshot.get("workstation_id", "")) == target_id
    return {"success": success, "reason": "" if success else "workstation_unavailable"}

func _request_target_loot(_actor_id: String, target_id: String, _action_id: StringName) -> Dictionary:
    if _loot_controller == null or _loot_panel == null:
        return {"success": false, "reason": "loot_input_not_ready"}
    var result: Dictionary = _loot_controller.request_search_container(target_id)
    var success: bool = bool(result.get("success", false))
    if success:
        var snapshot: Dictionary = _loot_panel.presentation_snapshot()
        success = _loot_panel.is_open() and String(snapshot.get("container_id", "")) == target_id
    return {"success": success, "reason": String(result.get("reason", "" if success else "search_rejected"))}

func _crafting_workstation_available(_actor_id: String, workstation_id: String, capability: StringName) -> bool:
    if capability != Workstations.COOKING_STOVE:
        return true
    if _world == null or _utilities == null or not _world.has_entity(workstation_id):
        return false
    var entity: WorldEntityRecord = _world.entity(workstation_id)
    var placement: WorldPlacement = _world.placement(workstation_id)
    if entity == null or placement == null or not _world_interaction_catalog.is_cooking_stove(entity.semantic_type):
        return false
    var service_id: String = _utilities.power_service_for_cell(placement.anchor)
    return not service_id.is_empty() and _utilities.power_service_available(service_id)

func _on_world_interaction_action_finished(_target_id: String, action_id: StringName, success: bool, reason: String) -> void:
    if action_id in [CraftingOffersClass.ACTION_ID, LootOffersClass.SEARCH_ACTION_ID]:
        return
    if _hud != null and _kernel != null:
        _hud.present_action_result(action_id, success, reason, _kernel.world_tick())

func _on_interaction_utility_changed(_revision: int, _reason: StringName) -> void:
    if _sustainment_interaction_offers != null:
        _sustainment_interaction_offers.availability_changed.emit(&"utility_changed")
    if _crafting_interaction_offers != null:
        _crafting_interaction_offers.availability_changed.emit(&"utility_changed")
    if _utility_power_repair_offers != null:
        _utility_power_repair_offers.availability_changed.emit(&"utility_changed")

func _on_world_interaction_blocked_changed(blocked: bool) -> void:
    _world_blocks_interaction = blocked
    _refresh_interaction_enabled()

func _refresh_interaction_enabled() -> void:
    super._refresh_interaction_enabled()
    if not _world_blocks_interaction:
        return
    if _keyboard != null:
        _keyboard.set_enabled(false)
    if _controls != null:
        _controls.set_enabled(false)
    if _door_pointer != null:
        _door_pointer.set_enabled(false)
    if _camera_input != null:
        _camera_input.set_enabled(false)
    if _camera_controls != null:
        _camera_controls.set_enabled(false)
