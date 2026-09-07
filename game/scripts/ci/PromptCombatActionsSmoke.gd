extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const Rules = preload("res://scripts/foundation/time/TickRules.gd")
const Combat = preload("res://scripts/simulation/combat/CombatActionService.gd")

const TARGET_ID := "actor.prompt.combat.target"
const HAMMER_ID := "item.prompt.combat.hammer"
const STAKE_ID := "item.prompt.combat.stake"

var failures: Array[String] = []
var last_contact_item := ""
var last_miss_serial := 0

func _initialize() -> void:
    call_deferred("run_smoke")

func run_smoke() -> void:
    var packed := load("res://main.tscn") as PackedScene
    expect(packed != null, "production main scene loads")
    if packed == null: return finish()
    var game := packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame

    var world: WorldState = game.get("_world")
    var mutations: WorldMutationService = game.get("_world_mutations")
    var kernel: TickKernel = game.get("_kernel")
    var health: ActorHealthState = game.get("_health_state")
    var hands: ActorHandEquipmentState = game.get("_hand_state")
    var hand_mutations: ActorHandEquipmentMutationService = game.get("_hand_mutations")
    var physical: ItemPhysicalPropertyCatalog = game.get("_physical_catalog")
    var perception: ObserverPerceptionService = game.get("_perception")
    var interaction: WorldInteractionPlayerController = game.get("_world_interaction_controller")
    var panel: WorldInteractionPanel = game.get("_world_interaction_panel")
    var combat: CombatActionService = game.get("_combat_actions")
    var condition: ActorConditionService = game.get("_condition_service")
    var sound: SpatialSoundService = game.get("_spatial_sound")
    var controls: PlayerMovementControls = game.get("_controls")

    expect(world != null and mutations != null and kernel != null and health != null, "canonical physical owners are ready")
    expect(combat != null and combat.is_ready(), "production combat service is ready")
    expect(interaction != null and interaction.is_ready() and panel != null, "shared exact-target chooser is ready")
    expect(physical != null and physical.weight_grams(&"item.crafting.stone_hammer") == 1100, "real hammer mass is registered")
    if not failures.is_empty():
        game.queue_free(); return finish()

    var player := world.placement(Fixture.PLAYER_ID)
    expect(player != null, "player has physical placement")
    if player == null:
        game.queue_free(); return finish()
    var target_cell := player.anchor + Facing.vector(player.facing)
    expect(world.has_terrain(target_cell), "forward contact cell is real world terrain")
    expect(mutations.create_entity(&"actor.survivor", TARGET_ID) == TARGET_ID, "created DEV-only survivor target")
    expect(mutations.set_placement(TARGET_ID, Layers.Channel.ACTOR, target_cell, Facing.opposite(player.facing), Footprint.single_cell()), "placed target in forward contact")
    expect(health.enroll_actor(TARGET_ID), "target uses canonical Health")
    expect(hand_mutations.enroll_actor(TARGET_ID), "target uses canonical hand state")
    expect(perception.recompute(&"prompt_combat"), "perception refreshed")
    expect(perception.is_visible(target_cell), "target is currently visible")

    var strike_control := controls.find_child("CombatForwardButton", true, false) as Button
    expect(strike_control != null and strike_control.size.y >= 48.0, "touch STRIKE control is practical")
    interaction.submit_world_cell(target_cell)
    await process_frame
    var shove_button := find_action_button(panel, TARGET_ID, Combat.SHOVE)
    var fist_button := find_action_button(panel, TARGET_ID, Combat.STRIKE_UNARMED)
    expect(panel.is_open() and shove_button != null and fist_button != null, "visible actor exposes combat in shared chooser")
    if shove_button != null:
        expect(shove_button.text.contains("6t") and shove_button.text.contains("COMMITTED"), "chooser exposes ticks and commitment before choice")
    panel.close_panel()

    # Heavy real item: exact hand identity, committed timing, Health injury, Fatigue and sound.
    expect(mutations.create_entity(&"item.crafting.stone_hammer", HAMMER_ID) == HAMMER_ID, "created exact hammer")
    if not hands.primary_item(Fixture.PLAYER_ID).is_empty(): hand_mutations.clear_slot(Fixture.PLAYER_ID, Slots.Value.PRIMARY_RIGHT)
    expect(hand_mutations.set_item(Fixture.PLAYER_ID, Slots.Value.PRIMARY_RIGHT, HAMMER_ID), "equipped exact hammer in right hand")
    combat.attack_contact.connect(capture_contact)
    var hp0 := health.current_hp(TARGET_ID)
    var fatigue0 := condition.current_fatigue(Fixture.PLAYER_ID)
    var heavy := combat.request_action(Fixture.PLAYER_ID, TARGET_ID, Combat.STRIKE_PRIMARY)
    var heavy_serial := int(heavy.get("action_serial", 0))
    var heavy_action := kernel.action_by_serial(heavy_serial)
    expect(bool(heavy.get("accepted", false)) and heavy_action != null, "hammer strike starts as real WHEN action")
    expect(heavy_action != null and heavy_action.interruption_policy == Rules.InterruptionPolicy.COMMITTED, "heavy strike is COMMITTED")
    kernel.run_until_stop()
    expect(last_contact_item == HAMMER_ID, "contact preserves exact item identity")
    expect(health.current_hp(TARGET_ID) < hp0 and not health.injuries(TARGET_ID).is_empty(), "impact writes real HP loss and injury")
    expect(condition.current_fatigue(Fixture.PLAYER_ID) > fatigue0, "combat spends Fatigue without recovering during the committed act")
    expect(has_combat_sound(sound.presentation_descriptors(Fixture.PLAYER_ID)), "combat produces physical System-26 sound")

    # Movement-as-evasion: leave the contact cell after action starts but before late resolution.
    health.heal(TARGET_ID, 100)
    var miss_hp := health.current_hp(TARGET_ID)
    combat.attack_missed.connect(capture_miss)
    var miss := combat.request_action(Fixture.PLAYER_ID, TARGET_ID, Combat.STRIKE_PRIMARY)
    var miss_serial := int(miss.get("action_serial", 0))
    var move_target := func(action: TimedAction, phase: ActionPhase) -> void:
        if action != null and phase != null and action.serial == miss_serial and phase.phase_id == Combat.CONTACT_PHASE:
            mutations.set_placement(TARGET_ID, Layers.Channel.ACTOR, target_cell + Vector2i(1, 0), Facing.opposite(player.facing), Footprint.single_cell())
    kernel.action_phase.connect(move_target)
    kernel.run_until_stop()
    if kernel.action_phase.is_connected(move_target): kernel.action_phase.disconnect(move_target)
    expect(health.current_hp(TARGET_ID) == miss_hp and last_miss_serial == miss_serial, "attack does not home after target leaves strike cell")
    expect(mutations.set_placement(TARGET_ID, Layers.Channel.ACTOR, target_cell, Facing.opposite(player.facing), Footprint.single_cell()), "target returned to contact")

    # Light action cancels on real damage before CONTACT.
    hand_mutations.clear_slot(Fixture.PLAYER_ID, Slots.Value.PRIMARY_RIGHT)
    expect(mutations.create_entity(&"item.crafting.sharpened_stake", STAKE_ID) == STAKE_ID, "created exact light stake")
    expect(hand_mutations.set_item(Fixture.PLAYER_ID, Slots.Value.PRIMARY_RIGHT, STAKE_ID), "equipped stake")
    var light := combat.request_action(Fixture.PLAYER_ID, TARGET_ID, Combat.STRIKE_PRIMARY)
    var light_serial := int(light.get("action_serial", 0))
    var light_action := kernel.action_by_serial(light_serial)
    expect(light_action != null and light_action.interruption_policy == Rules.InterruptionPolicy.CANCELABLE, "light strike is interruptible")
    var light_status := -1
    var capture_light := func(action: TimedAction) -> void:
        if action != null and action.serial == light_serial: light_status = action.status
    kernel.action_finished.connect(capture_light)
    health.apply_damage(Fixture.PLAYER_ID, 1)
    expect(light_status == Rules.ActionStatus.CANCELED, "pre-contact damage cancels light strike")
    if kernel.action_finished.is_connected(capture_light): kernel.action_finished.disconnect(capture_light)
    health.heal(Fixture.PLAYER_ID, 100)

    # Heavy action ignores ordinary interruption and still reaches CONTACT.
    hand_mutations.clear_slot(Fixture.PLAYER_ID, Slots.Value.PRIMARY_RIGHT)
    hand_mutations.set_item(Fixture.PLAYER_ID, Slots.Value.PRIMARY_RIGHT, HAMMER_ID)
    health.heal(TARGET_ID, 100)
    var committed_hp := health.current_hp(TARGET_ID)
    var committed := combat.request_action(Fixture.PLAYER_ID, TARGET_ID, Combat.STRIKE_PRIMARY)
    expect(bool(committed.get("accepted", false)), "second committed strike starts")
    health.apply_damage(Fixture.PLAYER_ID, 1)
    expect(kernel.has_active_action(Fixture.PLAYER_ID), "ordinary damage does not cancel COMMITTED strike")
    kernel.run_until_stop()
    expect(health.current_hp(TARGET_ID) < committed_hp, "committed strike lands after ordinary damage")
    health.heal(Fixture.PLAYER_ID, 100)

    # Two actions with the same CONTACT tick both resolve before tactical pause.
    hand_mutations.clear_slot(Fixture.PLAYER_ID, Slots.Value.PRIMARY_RIGHT)
    if not hands.secondary_item(Fixture.PLAYER_ID).is_empty(): hand_mutations.clear_slot(Fixture.PLAYER_ID, Slots.Value.SECONDARY_LEFT)
    health.heal(Fixture.PLAYER_ID, 100); health.heal(TARGET_ID, 100)
    var player_hp := health.current_hp(Fixture.PLAYER_ID)
    var target_hp := health.current_hp(TARGET_ID)
    var first := combat.request_action(Fixture.PLAYER_ID, TARGET_ID, Combat.STRIKE_UNARMED)
    var second := combat.request_action(TARGET_ID, Fixture.PLAYER_ID, Combat.STRIKE_UNARMED)
    expect(bool(first.get("accepted", false)) and bool(second.get("accepted", false)), "different actors act concurrently on one WHEN clock")
    kernel.run_until_stop()
    expect(health.current_hp(Fixture.PLAYER_ID) < player_hp and health.current_hp(TARGET_ID) < target_hp, "same-tick contacts both land before decision pause")

    game.queue_free()
    await process_frame
    finish()

func capture_contact(_attacker: String, _serial: int, _cell: Vector2i, item_id: String) -> void:
    if not item_id.is_empty(): last_contact_item = item_id

func capture_miss(_attacker: String, serial: int, _cell: Vector2i) -> void:
    last_miss_serial = serial

func find_action_button(node: Node, target_id: String, action_id: StringName) -> Button:
    if node == null: return null
    for child: Node in node.get_children():
        if child is Button and child.has_meta("world_target_id") and child.has_meta("world_action_id") \
            and String(child.get_meta("world_target_id")) == target_id and StringName(child.get_meta("world_action_id")) == action_id:
            return child as Button
        var nested := find_action_button(child, target_id, action_id)
        if nested != null: return nested
    return null

func has_combat_sound(descriptors: Array[Dictionary]) -> bool:
    for value: Dictionary in descriptors:
        if String(value.get("category", "")) == "combat": return true
    return false

func expect(ok: bool, message: String) -> void:
    if ok: print("PASS: %s" % message)
    else:
        failures.append(message)
        push_error("FAIL: %s" % message)

func finish() -> void:
    if failures.is_empty():
        print("PROMPT_COMBAT_ACTIONS_SMOKE: PASS")
        quit(0)
    else:
        push_error("PROMPT_COMBAT_ACTIONS_SMOKE: FAIL (%d)" % failures.size())
        for value: String in failures: push_error(" - %s" % value)
        quit(1)
