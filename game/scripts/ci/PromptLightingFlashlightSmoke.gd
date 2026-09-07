extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const LightActions = preload("res://scripts/simulation/utilities/UtilityLightingInteractionActionService.gd")

const FLASHLIGHT_ID: String = "item.prompt.flashlight.001"
const FLASHLIGHT_SEMANTIC: StringName = &"item.tool.flashlight"
const FIXED_LIGHT_ID: String = "fixture.prompt.light.001"
const FIXED_LIGHT_SEMANTIC: StringName = &"fixture.room_light"

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://main.tscn")
    _expect(packed != null, "production main scene loads")
    if packed == null:
        _finish()
        return
    var game: Node = packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame

    var world: WorldState = game.get("_world")
    var mutations: WorldMutationService = game.get("_world_mutations")
    var reach: WorldInteractionReachQuery = game.get("_interaction_reach")
    var utilities: UtilityRuntimeState = game.get("_utilities")
    var utility_lighting: UtilityPoweredLightingSourceAdapter = game.get("_utility_lighting")
    var physical_lighting: PhysicalLightingService = game.get("_physical_lighting")
    var fixed_actions: UtilityLightingInteractionActionService = game.get("_utility_lighting_actions")
    var fixed_offers: UtilityLightingInteractionOfferProvider = game.get("_utility_lighting_offers")
    var controller: WorldInteractionPlayerController = game.get("_world_interaction_controller")
    var panel: WorldInteractionPanel = game.get("_world_interaction_panel")
    var kernel: TickKernel = game.get("_kernel")
    var hand_state: ActorHandEquipmentState = game.get("_hand_state")
    var hand_mutations: ActorHandEquipmentMutationService = game.get("_hand_mutations")
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations")
    var flashlight_state: FlashlightItemState = game.get("_flashlight_state")
    var flashlight_actions: FlashlightToggleActionService = game.get("_flashlight_actions")
    var shell: EquipmentPlayerShell = game.get_node_or_null("PlayerShell") as EquipmentPlayerShell

    _expect(world != null and mutations != null and reach != null, "production world interaction foundations are ready")
    _expect(utilities != null and utilities.is_ready(), "System 33 utility runtime is authoritative and ready")
    _expect(utility_lighting != null and utility_lighting.is_ready(), "utility lighting source adapter is ready")
    _expect(physical_lighting != null, "System 27 physical lighting service is ready")
    _expect(fixed_actions != null and fixed_actions.is_ready(), "fixed-light action owner is production wired")
    _expect(fixed_offers != null and fixed_offers.is_ready(), "fixed-light ordinary offer provider is production wired")
    _expect(controller != null and controller.is_ready() and panel != null, "ordinary world interaction controller is production wired")
    _expect(kernel != null and hand_state != null and hand_mutations != null, "authoritative WHEN/equipment setup is ready")
    _expect(inventory_mutations != null and flashlight_state != null and flashlight_actions != null, "persistent flashlight owners are ready")
    _expect(shell != null and shell.is_configured(), "ordinary production Inventory shell is ready")
    if not _failures.is_empty():
        game.queue_free()
        _finish()
        return

    _test_fixed_light_switch(
        world, mutations, reach, utilities, utility_lighting,
        fixed_actions, controller, panel, kernel
    )
    _test_exact_flashlight(
        world, mutations, utilities, utility_lighting, hand_state, hand_mutations,
        inventory_mutations, flashlight_state, flashlight_actions, shell
    )

    game.queue_free()
    await process_frame
    _finish()

func _test_fixed_light_switch(
    world: WorldState,
    mutations: WorldMutationService,
    reach: WorldInteractionReachQuery,
    utilities: UtilityRuntimeState,
    utility_lighting: UtilityPoweredLightingSourceAdapter,
    fixed_actions: UtilityLightingInteractionActionService,
    controller: WorldInteractionPlayerController,
    panel: WorldInteractionPanel,
    kernel: TickKernel
) -> void:
    var player: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    _expect(player != null, "controlled survivor has a placement")
    if player == null:
        return
    var reachable: Array[Vector2i] = reach.reachable_cells(Fixture.PLAYER_ID, WorldInteractionReachQuery.CONTACT_FORWARD)
    var target_cell: Vector2i = player.anchor
    for cell: Vector2i in reachable:
        if cell != player.anchor:
            target_cell = cell
            break
    _expect(target_cell != player.anchor or not reachable.is_empty(), "fixed-light test has an ordinary reachable cell")

    _expect(mutations.create_entity(FIXED_LIGHT_SEMANTIC, FIXED_LIGHT_ID) == FIXED_LIGHT_ID, "test fixed light is one real WHAT entity")
    _expect(mutations.set_placement(FIXED_LIGHT_ID, Layers.Channel.OBJECT, target_cell, player.facing, Footprint.single_cell()), "test fixed light is physically placed in interaction reach")
    var appliance_id: String = LightActions.appliance_id_for_target(FIXED_LIGHT_ID)
    var initial: Dictionary = utilities.appliance_record(appliance_id)
    _expect(not initial.is_empty(), "real fixed light is bound as one System 33 appliance")
    _expect(bool(initial.get("switched_on", false)), "fixed light begins with authoritative switch ON")

    controller.submit_world_cell(target_cell)
    _expect(panel.is_open(), "ordinary world chooser opens for reachable fixed light")
    var off_button: Button = _find_button(panel, "world_action_id", String(LightActions.ACTION_TOGGLE))
    _expect(off_button != null, "ordinary chooser exposes fixed-light TURN OFF")
    if off_button != null:
        _expect(off_button.text.begins_with("TURN OFF"), "fixed-light label reflects authoritative ON state")
        off_button.emit_signal("pressed")
    var after_off: Dictionary = utilities.appliance_record(appliance_id)
    _expect(not bool(after_off.get("switched_on", true)), "ordinary action commits switch OFF only through System 33")
    _expect(not _has_emitter(utility_lighting, appliance_id), "switched-off fixed light produces no physical emitter")

    _expect(utilities.set_appliance_operational_state(appliance_id, UtilityRuntimeState.DAMAGED, &"prompt_light_damage"), "test can mark exact fixed light damaged through System 33")
    var failed: Dictionary = {}
    var failure_callback := func(target_id: String, action_id: StringName, success: bool, reason: String) -> void:
        if target_id == FIXED_LIGHT_ID and action_id == LightActions.ACTION_TOGGLE:
            failed["seen"] = true
            failed["success"] = success
            failed["reason"] = reason
    controller.action_finished.connect(failure_callback)
    controller.submit_world_cell(target_cell)
    var damaged_button: Button = _find_button(panel, "world_action_id", String(LightActions.ACTION_TOGGLE))
    _expect(damaged_button != null and damaged_button.text.contains("DAMAGED"), "ordinary chooser truthfully marks damaged fixed light")
    if damaged_button != null:
        damaged_button.emit_signal("pressed")
    if controller.action_finished.is_connected(failure_callback):
        controller.action_finished.disconnect(failure_callback)
    _expect(bool(failed.get("seen", false)) and not bool(failed.get("success", true)), "damaged fixed-light interaction fails through ordinary controller")
    _expect(String(failed.get("reason", "")) == "light_not_operational", "damaged fixed-light failure exposes authoritative reason")
    _expect(not bool(utilities.appliance_record(appliance_id).get("switched_on", true)), "failed damaged toggle does not mutate switch truth")
    _expect(utilities.set_appliance_operational_state(appliance_id, UtilityRuntimeState.OPERATIONAL, &"prompt_light_repair"), "test restores fixed light operation")

    var source_id: String = utilities.power_source_component_id()
    _expect(not source_id.is_empty(), "System 33 exposes authoritative grid source")
    _expect(utilities.set_power_component_state(source_id, UtilityRuntimeState.DISABLED, &"prompt_grid_off"), "test disables grid through System 33")
    _expect(not utilities.appliance_powered(appliance_id), "fixed light has no power with authoritative grid disabled")
    controller.submit_world_cell(target_cell)
    var no_power_button: Button = _find_button(panel, "world_action_id", String(LightActions.ACTION_TOGGLE))
    _expect(no_power_button != null and no_power_button.text.contains("NO POWER"), "ordinary chooser distinguishes switch request from missing power")
    if no_power_button != null:
        no_power_button.emit_signal("pressed")
    var switched_without_power: Dictionary = utilities.appliance_record(appliance_id)
    _expect(bool(switched_without_power.get("switched_on", false)), "unpowered fixed light can retain authoritative switch ON")
    _expect(not utilities.appliance_powered(appliance_id), "switch ON does not fabricate electrical power")
    _expect(not _has_emitter(utility_lighting, appliance_id), "unpowered switched-ON light produces no physical emitter")
    _expect(_snapshot_appliance_switched_on(utilities.snapshot(), appliance_id), "fixed-light switch state is present in System 33 persistence snapshot")

    _expect(utilities.set_power_component_state(source_id, UtilityRuntimeState.OPERATIONAL, &"prompt_grid_on"), "test restores authoritative grid source")
    _expect(utilities.appliance_powered(appliance_id), "restored power energizes the already-ON fixed light")
    _expect(_has_emitter(utility_lighting, appliance_id), "System 27 source projection follows authoritative switch plus power truth")
    _expect(not kernel.is_hard_paused(), "world switch actions leave ordinary WHEN decision state usable")

func _test_exact_flashlight(
    world: WorldState,
    mutations: WorldMutationService,
    utilities: UtilityRuntimeState,
    utility_lighting: UtilityPoweredLightingSourceAdapter,
    hand_state: ActorHandEquipmentState,
    hand_mutations: ActorHandEquipmentMutationService,
    inventory_mutations: InventoryContainmentMutationService,
    flashlight_state: FlashlightItemState,
    flashlight_actions: FlashlightToggleActionService,
    shell: EquipmentPlayerShell
) -> void:
    _expect(mutations.create_entity(FLASHLIGHT_SEMANTIC, FLASHLIGHT_ID) == FLASHLIGHT_ID, "flashlight is one exact persistent physical item")
    _expect(hand_mutations.set_item(Fixture.PLAYER_ID, Slots.Value.PRIMARY_RIGHT, FLASHLIGHT_ID), "test setup equips exact flashlight through authoritative equipment owner")
    _expect(String(hand_state.primary_item(Fixture.PLAYER_ID)) == FLASHLIGHT_ID, "exact flashlight identity is in right hand")

    shell.set("_selected_inventory_item_id", FLASHLIGHT_ID)
    shell.open_inventory()
    var on_button: Button = _find_button(shell, "flashlight_toggle_item_id", FLASHLIGHT_ID)
    _expect(on_button != null and on_button.text == "TURN ON", "ordinary Inventory exposes TURN ON for exact equipped flashlight")
    if on_button != null:
        on_button.emit_signal("pressed")
    _expect(flashlight_state.is_switched_on(FLASHLIGHT_ID), "ordinary Inventory toggle commits exact flashlight ON")
    _expect(_has_emitter(utility_lighting, "equipment.flashlight:%s" % FLASHLIGHT_ID), "switched-ON equipped exact flashlight projects one physical emitter")

    var flashlight_snapshot: Dictionary = flashlight_state.snapshot()
    _expect(flashlight_state.set_switched_on(FLASHLIGHT_ID, false), "test can perturb exact flashlight state")
    _expect(not flashlight_state.is_switched_on(FLASHLIGHT_ID), "perturbed flashlight is OFF before restore")
    _expect(flashlight_state.load_snapshot(flashlight_snapshot), "persistent flashlight state snapshot restores")
    _expect(flashlight_state.is_switched_on(FLASHLIGHT_ID), "restored state remains attached to exact flashlight identity")

    if shell.active_modal() != CanonicalPlayerShell.MODAL_NONE:
        shell.close_modal()
    _expect(hand_mutations.clear_slot(Fixture.PLAYER_ID, Slots.Value.PRIMARY_RIGHT), "test setup clears flashlight hand slot")
    _expect(inventory_mutations.set_container(FLASHLIGHT_ID, Fixture.PLAYER_ID), "test setup stows same physical flashlight in carried inventory")
    _expect(flashlight_state.is_switched_on(FLASHLIGHT_ID), "stowing does not erase exact flashlight switch state")
    _expect(not _has_emitter(utility_lighting, "equipment.flashlight:%s" % FLASHLIGHT_ID), "stowed switched-ON flashlight does not project a hand-held beam")

    shell.set("_selected_inventory_item_id", FLASHLIGHT_ID)
    shell.open_inventory()
    var inventory_snapshot: Dictionary = shell.presentation_snapshot()
    var lines: Array = inventory_snapshot.get("lines", [])
    _expect(_array_contains_text(lines, "Equip flashlight to use its switch."), "ordinary Inventory gives truthful not-equipped flashlight prerequisite")
    _expect(_find_button(shell, "flashlight_toggle_item_id", FLASHLIGHT_ID) == null, "stowed flashlight cannot invoke switch button")
    shell.close_modal()

    _expect(inventory_mutations.clear_container(FLASHLIGHT_ID), "test setup removes same flashlight from carried containment")
    _expect(hand_mutations.set_item(Fixture.PLAYER_ID, Slots.Value.SECONDARY_LEFT, FLASHLIGHT_ID), "test setup re-equips same flashlight in left hand")
    _expect(flashlight_state.is_switched_on(FLASHLIGHT_ID), "switch state survives hand/equip transition on same physical item")
    _expect(_has_emitter(utility_lighting, "equipment.flashlight:%s" % FLASHLIGHT_ID), "re-equipped switched-ON exact flashlight resumes physical emitter")

    shell.set("_selected_inventory_item_id", FLASHLIGHT_ID)
    shell.open_inventory()
    var off_button: Button = _find_button(shell, "flashlight_toggle_item_id", FLASHLIGHT_ID)
    _expect(off_button != null and off_button.text == "TURN OFF", "ordinary Inventory reads restored exact-item ON state")
    if off_button != null:
        off_button.emit_signal("pressed")
    _expect(not flashlight_state.is_switched_on(FLASHLIGHT_ID), "ordinary Inventory commits exact flashlight OFF")
    _expect(not _has_emitter(utility_lighting, "equipment.flashlight:%s" % FLASHLIGHT_ID), "switched-OFF flashlight produces no physical emitter")
    if shell.active_modal() != CanonicalPlayerShell.MODAL_NONE:
        shell.close_modal()

    var wrong_offer: Dictionary = flashlight_actions.toggle_offer(Fixture.PLAYER_ID, "item.missing.flashlight")
    _expect(not bool(wrong_offer.get("available", true)) and String(wrong_offer.get("reason", "")) == "item_missing", "flashlight action rejects missing exact item truthfully")
    _expect(utilities != null, "flashlight verification did not create a parallel power owner")

func _find_button(node: Node, meta_name: String, expected: String) -> Button:
    for child: Node in node.get_children():
        if child is Button and child.has_meta(meta_name) and String(child.get_meta(meta_name)) == expected:
            return child as Button
        var nested: Button = _find_button(child, meta_name, expected)
        if nested != null:
            return nested
    return null

func _has_emitter(adapter: UtilityPoweredLightingSourceAdapter, emitter_id: String) -> bool:
    for emitter: LightEmitter in adapter.emitters():
        if emitter != null and emitter.emitter_id == emitter_id:
            return true
    return false

func _snapshot_appliance_switched_on(snapshot: Dictionary, appliance_id: String) -> bool:
    for value: Variant in snapshot.get("appliances", []):
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var record: Dictionary = value
        if String(record.get("appliance_id", "")) == appliance_id:
            return bool(record.get("switched_on", false))
    return false

func _array_contains_text(values: Array, expected: String) -> bool:
    for value: Variant in values:
        if String(value) == expected:
            return true
    return false

func _expect(condition: bool, message: String) -> void:
    if condition:
        print("PASS: %s" % message)
        return
    _failures.append(message)
    push_error("FAIL: %s" % message)

func _finish() -> void:
    if _failures.is_empty():
        print("PROMPT_LIGHTING_FLASHLIGHT_SMOKE: PASS")
        quit(0)
        return
    push_error("PROMPT_LIGHTING_FLASHLIGHT_SMOKE: FAIL (%d)" % _failures.size())
    for failure: String in _failures:
        push_error(" - %s" % failure)
    quit(1)
