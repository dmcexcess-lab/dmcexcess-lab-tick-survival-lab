extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")

const FLASHLIGHT_ID: String = "item.prompt.flashlight.001"
const FLASHLIGHT_SEMANTIC: StringName = &"item.tool.flashlight"
const ROOM_LIGHT_SEMANTIC: StringName = &"fixture.room_light"

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
    var utilities: UtilityRuntimeState = game.get("_utilities")
    var utility_lighting: UtilityPoweredLightingSourceAdapter = game.get("_utility_lighting")
    var physical_lighting: PhysicalLightingService = game.get("_physical_lighting")
    var hand_state: ActorHandEquipmentState = game.get("_hand_state")
    var hand_mutations: ActorHandEquipmentMutationService = game.get("_hand_mutations")
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations")
    var flashlight_state: FlashlightItemState = game.get("_flashlight_state")
    var flashlight_actions: FlashlightToggleActionService = game.get("_flashlight_actions")
    var shell: EquipmentPlayerShell = game.get_node_or_null("PlayerShell") as EquipmentPlayerShell

    _expect(world != null and mutations != null, "production world state is ready")
    _expect(utilities != null and utilities.is_ready(), "System 33 utility runtime is authoritative and ready")
    _expect(utility_lighting != null and utility_lighting.is_ready(), "utility-powered lighting source adapter is ready")
    _expect(physical_lighting != null, "System 27 physical lighting service is ready")
    _expect(hand_state != null and hand_mutations != null and inventory_mutations != null, "authoritative item/equipment owners are ready")
    _expect(flashlight_state != null and flashlight_actions != null, "persistent flashlight owners are ready")
    _expect(shell != null and shell.is_configured(), "ordinary production Inventory shell is ready")
    if not _failures.is_empty():
        game.queue_free()
        _finish()
        return

    _test_house_power_lighting(world, utilities, utility_lighting)
    _test_exact_flashlight(
        world, mutations, utility_lighting, hand_state, hand_mutations,
        inventory_mutations, flashlight_state, flashlight_actions, shell
    )

    game.queue_free()
    await process_frame
    _finish()

func _test_house_power_lighting(
    world: WorldState,
    utilities: UtilityRuntimeState,
    utility_lighting: UtilityPoweredLightingSourceAdapter
) -> void:
    var room_light_ids: Array[String] = world.entity_ids_of_type(ROOM_LIGHT_SEMANTIC)
    room_light_ids.sort()
    _expect(not room_light_ids.is_empty(), "generated world contains persistent room-light fixtures")
    if room_light_ids.is_empty():
        return

    var room_light_id: String = ""
    var appliance_id: String = ""
    var record: Dictionary = {}
    for candidate: String in room_light_ids:
        var candidate_appliance: String = "utility.light:%s" % candidate
        var candidate_record: Dictionary = utilities.appliance_record(candidate_appliance)
        if not candidate_record.is_empty():
            room_light_id = candidate
            appliance_id = candidate_appliance
            record = candidate_record
            break
    _expect(not room_light_id.is_empty(), "generated room light is bound to System 33 power truth")
    if room_light_id.is_empty():
        return

    _expect(StringName(record.get("kind", &"")) == &"fixed_light", "room light is a fixed electrical load")
    _expect(String(record.get("owner_entity_id", "")) == room_light_id, "fixed-light load keeps exact fixture identity")
    var service_id: String = String(record.get("power_service_id", ""))
    _expect(not service_id.is_empty(), "room light is attached to one authoritative power service")
    _expect(utilities.power_service_available(service_id), "selected house/room service begins powered")
    _expect(utilities.appliance_powered(appliance_id), "powered house makes its room light electrically active")
    _expect(_has_emitter(utility_lighting, appliance_id), "powered room light projects one physical emitter")

    var branch_id: String = utilities.power_branch_component_id(service_id)
    _expect(not branch_id.is_empty(), "room-light service has an authoritative local power branch")
    if branch_id.is_empty():
        return
    _expect(utilities.set_power_component_state(branch_id, UtilityRuntimeState.DISABLED, &"prompt_house_power_off"), "test removes house/service power through System 33")
    _expect(not utilities.power_service_available(service_id), "disabled local branch makes house/service unpowered")
    _expect(not utilities.appliance_powered(appliance_id), "unpowered house makes room light inactive")
    _expect(not _has_emitter(utility_lighting, appliance_id), "unpowered room light produces no physical emitter")

    _expect(utilities.set_power_component_state(branch_id, UtilityRuntimeState.OPERATIONAL, &"prompt_house_power_on"), "test restores house/service power through System 33")
    _expect(utilities.power_service_available(service_id), "restored local branch makes house/service powered")
    _expect(utilities.appliance_powered(appliance_id), "restored house power reactivates room light automatically")
    _expect(_has_emitter(utility_lighting, appliance_id), "restored room power restores physical illumination automatically")

func _test_exact_flashlight(
    world: WorldState,
    mutations: WorldMutationService,
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
    _expect(flashlight_state.is_switched_on(FLASHLIGHT_ID), "ordinary Inventory commits exact flashlight ON")
    _expect(_has_emitter(utility_lighting, "equipment.flashlight:%s" % FLASHLIGHT_ID), "switched-ON equipped flashlight projects one physical emitter")

    var saved: Dictionary = flashlight_state.snapshot()
    _expect(flashlight_state.set_switched_on(FLASHLIGHT_ID, false), "test can perturb exact flashlight state")
    _expect(flashlight_state.load_snapshot(saved), "persistent flashlight state snapshot restores")
    _expect(flashlight_state.is_switched_on(FLASHLIGHT_ID), "restored state remains attached to exact flashlight identity")

    if shell.active_modal() != CanonicalPlayerShell.MODAL_NONE:
        shell.close_modal()
    _expect(hand_mutations.clear_slot(Fixture.PLAYER_ID, Slots.Value.PRIMARY_RIGHT), "test setup clears flashlight hand slot")
    _expect(inventory_mutations.set_container(FLASHLIGHT_ID, Fixture.PLAYER_ID), "test setup stows same physical flashlight")
    _expect(flashlight_state.is_switched_on(FLASHLIGHT_ID), "stowing does not erase exact flashlight switch state")
    _expect(not _has_emitter(utility_lighting, "equipment.flashlight:%s" % FLASHLIGHT_ID), "stowed flashlight does not project a hand-held beam")

    shell.set("_selected_inventory_item_id", FLASHLIGHT_ID)
    shell.open_inventory()
    var snapshot: Dictionary = shell.presentation_snapshot()
    _expect(_array_contains_text(snapshot.get("lines", []), "Equip flashlight to use its switch."), "ordinary Inventory gives truthful flashlight equip prerequisite")
    _expect(_find_button(shell, "flashlight_toggle_item_id", FLASHLIGHT_ID) == null, "stowed flashlight cannot invoke its switch")
    shell.close_modal()

    _expect(inventory_mutations.clear_container(FLASHLIGHT_ID), "test setup removes same flashlight from carried containment")
    _expect(hand_mutations.set_item(Fixture.PLAYER_ID, Slots.Value.SECONDARY_LEFT, FLASHLIGHT_ID), "test setup re-equips same flashlight in left hand")
    _expect(flashlight_state.is_switched_on(FLASHLIGHT_ID), "flashlight state survives equip/stow/equip on same physical item")
    _expect(_has_emitter(utility_lighting, "equipment.flashlight:%s" % FLASHLIGHT_ID), "re-equipped switched-ON flashlight resumes beam")

    shell.set("_selected_inventory_item_id", FLASHLIGHT_ID)
    shell.open_inventory()
    var off_button: Button = _find_button(shell, "flashlight_toggle_item_id", FLASHLIGHT_ID)
    _expect(off_button != null and off_button.text == "TURN OFF", "ordinary Inventory reads exact flashlight ON state")
    if off_button != null:
        off_button.emit_signal("pressed")
    _expect(not flashlight_state.is_switched_on(FLASHLIGHT_ID), "ordinary Inventory commits exact flashlight OFF")
    _expect(not _has_emitter(utility_lighting, "equipment.flashlight:%s" % FLASHLIGHT_ID), "switched-OFF flashlight produces no physical emitter")
    if shell.active_modal() != CanonicalPlayerShell.MODAL_NONE:
        shell.close_modal()

    var wrong_offer: Dictionary = flashlight_actions.toggle_offer(Fixture.PLAYER_ID, "item.missing.flashlight")
    _expect(not bool(wrong_offer.get("available", true)) and String(wrong_offer.get("reason", "")) == "item_missing", "flashlight action rejects missing exact item truthfully")

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
