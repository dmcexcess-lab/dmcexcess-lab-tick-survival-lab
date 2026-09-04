extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const QueryResult = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const DoorTransitions = preload("res://scripts/simulation/doors/DoorPhysicalTransitionService.gd")
const Actions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const SustainmentOffers = preload("res://scripts/simulation/interaction/SustainmentInteractionOfferProvider.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const ConditionState = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const Injury = preload("res://scripts/simulation/actors/health/ActorInjuryRecord.gd")
const SoundProfiles = preload("res://scripts/simulation/sound/SoundEmissionProfileCatalog.gd")
const TickRules = preload("res://scripts/foundation/time/TickRules.gd")

var failures: Array[String] = []
var game: Node = null

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://main.tscn")
    _check(packed != null, "main scene loads")
    if packed == null:
        _finish()
        return
    game = packed.instantiate()
    get_root().add_child(game)
    await process_frame

    var world: WorldState = game.get("_world")
    var mutations: WorldMutationService = game.get("_world_mutations")
    var spatial: SpatialQueryService = game.get("_spatial_query")
    var kernel: TickKernel = game.get("_kernel")
    var skills: ActorSkillState = game.get("_skill_state")
    var condition: ActorConditionService = game.get("_condition_service")
    var sustainment: SurvivorSustainmentActionService = game.get("_sustainment_actions")
    var first_aid: SurvivorFirstAidActionService = game.get("_first_aid_actions")
    var health: ActorHealthState = game.get("_health_state")
    var crafting: CraftingActionService = game.get("_crafting_actions")
    var inventory: InventoryContainmentState = game.get("_inventory_state")
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations")
    var door_state: DoorStateStore = game.get("_door_state")
    var door_transitions: DoorPhysicalTransitionService = game.get("_door_transition")
    var interaction_state: WorldInteractableState = game.get("_world_interaction_state")
    var interactions: WorldInteractionActionService = game.get("_world_interaction_actions")
    var affordances: InteractionAffordanceQuery = game.get("_interaction_affordances")
    var shell: CanonicalPlayerShell = game.get("_shell")

    _check(world != null and mutations != null and spatial != null and kernel != null, "core live owners available")
    _check(skills != null and condition != null and sustainment != null and first_aid != null and health != null and crafting != null, "condition/health/crafting owners available")
    _check(interaction_state != null and interactions != null and interactions.is_ready(), "world interaction runtime ready")
    _check(affordances != null and affordances.is_ready(), "System 29 affordances remain ready")
    _check(shell != null and shell.is_configured(), "live player shell is ready")
    if not failures.is_empty():
        _finish()
        return

    var actor_id: String = Fixture.PLAYER_ID
    _check(skills.set_skill(actor_id, SkillCatalog.MECHANICAL, 10, 0), "Mechanical fixture set to expert")
    _check(skills.set_skill(actor_id, SkillCatalog.SURVIVAL, 10, 0), "Survival fixture set to expert")

    _test_sink(world, mutations, sustainment, condition, kernel, actor_id)
    _test_inventory_item_actions(world, mutations, inventory_mutations, condition, kernel, shell, actor_id)
    _test_inventory_first_aid(world, mutations, inventory_mutations, health, kernel, shell, actor_id)
    _test_rest_and_sleep(world, mutations, sustainment, condition, kernel, actor_id)
    _test_cooking(world, mutations, inventory_mutations, crafting, inventory, kernel, actor_id)
    _test_doors(world, mutations, door_state, door_transitions, interactions, interaction_state, kernel, actor_id)
    _test_window_and_reclamation(world, mutations, spatial, inventory, inventory_mutations, interactions, interaction_state, kernel, actor_id)

    _finish()

func _test_inventory_item_actions(
    world: WorldState,
    mutations: WorldMutationService,
    inventory_mutations: InventoryContainmentMutationService,
    condition: ActorConditionService,
    kernel: TickKernel,
    shell: CanonicalPlayerShell,
    actor_id: String
) -> void:
    var apple_id: String = "ci.inventory.action.apple"
    var water_id: String = "ci.inventory.action.water"
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.food.apple", apple_id), "specific edible item enters personal inventory")
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.drink.water_bottle", water_id), "specific drink item enters personal inventory")
    condition.set_condition(actor_id, ConditionState.SATIETY, 10)
    var before_satiety: int = condition.value(actor_id, ConditionState.SATIETY)

    shell.open_inventory()
    _check(kernel.is_hard_paused() and shell.active_modal() == CanonicalPlayerShell.MODAL_INVENTORY, "inventory item action starts from normal paused inventory modal")
    var apple_button: Button = _button_with_meta(shell, "inventory_item_id", apple_id)
    _check(apple_button != null, "specific carried food is a clickable inventory row")
    if apple_button != null:
        apple_button.pressed.emit()
    var eat_button: Button = _button_with_meta(shell, "inventory_action_item_id", apple_id)
    _check(eat_button != null and eat_button.text == "EAT", "clicking the food exposes its direct EAT action")
    if eat_button != null:
        eat_button.pressed.emit()

    _check(not world.has_entity(apple_id), "inventory EAT consumes the exact selected food entity")
    _check(world.has_entity(water_id), "inventory EAT does not consume a different carried consumable")
    _check(condition.value(actor_id, ConditionState.SATIETY) > before_satiety, "inventory EAT advances WHEN and changes canonical satiety")
    _check(shell.active_modal() == CanonicalPlayerShell.MODAL_INVENTORY and kernel.is_hard_paused(), "inventory reopens after the completed item action")
    shell.close_modal()

    var hammer_id: String = "ci.inventory.action.hammer"
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.tool.hammer", hammer_id), "specific tool enters personal inventory")
    shell.open_inventory()
    var hammer_button: Button = _button_with_meta(shell, "inventory_item_id", hammer_id)
    _check(hammer_button != null, "specific carried tool is a clickable inventory row")
    if hammer_button != null:
        hammer_button.pressed.emit()
    var equip_button: Button = _button_with_action(shell, hammer_id, "equip", "RIGHT HAND")
    _check(equip_button != null, "selected pack item exposes a right-hand equip action")
    if equip_button != null:
        equip_button.pressed.emit()
    var hands: ActorHandEquipmentState = game.get("_hand_state")
    _check(hands != null and hands.primary_item(actor_id) == hammer_id, "inventory equip spends WHEN and moves the exact item to the real right hand")
    var stow_button: Button = _button_with_action(shell, hammer_id, "stow", "STOW")
    _check(stow_button != null, "selected hand item exposes a stow action")
    if stow_button != null:
        stow_button.pressed.emit()
    _check(hands != null and hands.primary_item(actor_id).is_empty(), "inventory stow clears the real hand assignment")
    shell.close_modal()

func _test_inventory_first_aid(
    world: WorldState,
    mutations: WorldMutationService,
    inventory_mutations: InventoryContainmentMutationService,
    health: ActorHealthState,
    kernel: TickKernel,
    shell: CanonicalPlayerShell,
    actor_id: String
) -> void:
    var rag_id: String = "ci.inventory.first_aid.rags"
    var alcohol_id: String = "ci.inventory.first_aid.alcohol"
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.material.rag_bundle", rag_id), "rag bundle enters inventory for improvised first aid")
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.medical.disinfectant", alcohol_id), "disinfectant enters inventory for improvised first aid")
    var injury_id: String = health.add_injury(actor_id, &"laceration", Injury.LEFT_ARM, Injury.Severity.SERIOUS)
    _check(not injury_id.is_empty(), "real untreated injury added for player first aid")

    shell.open_inventory()
    var rag_button: Button = _button_with_meta(shell, "inventory_item_id", rag_id)
    _check(rag_button != null, "specific rag bundle is selectable for first aid")
    if rag_button != null:
        rag_button.pressed.emit()
    var treatment_button: Button = _button_with_treatment(shell, rag_id, injury_id)
    _check(treatment_button != null and treatment_button.text.begins_with("IMPROVISE BANDAGE"), "rag plus alcohol exposes exact-injury first aid UI")
    if treatment_button != null:
        treatment_button.pressed.emit()

    var treated: ActorInjuryRecord = health.injury(actor_id, injury_id)
    _check(treated != null and treated.stabilized and treated.treated, "expert Survival first aid stabilizes and treats the real injury")
    _check(not world.has_entity(rag_id) and not world.has_entity(alcohol_id), "first aid consumes the exact rag and disinfectant entities")
    _check(shell.active_modal() == CanonicalPlayerShell.MODAL_INVENTORY and kernel.is_hard_paused(), "inventory reopens after first aid WHEN completion")
    shell.close_modal()

func _test_sink(world: WorldState, mutations: WorldMutationService, sustainment: SurvivorSustainmentActionService, condition: ActorConditionService, kernel: TickKernel, actor_id: String) -> void:
    var sink: String = _first_reachable_target(world, mutations, actor_id, [&"prop.kitchen_sink", &"prop.bathroom_vanity", &"prop.utility_sink"], false)
    _check(not sink.is_empty(), "generated working water fixture found")
    if sink.is_empty(): return
    _check(bool(game.call("_potable_target_available", actor_id, sink)), "sink reads live utility water truth")
    condition.set_condition(actor_id, ConditionState.HYDRATION, 10)
    var before: int = condition.value(actor_id, ConditionState.HYDRATION)
    var serial: int = sustainment.begin_tap_drink_from(actor_id, sink)
    _check(serial > 0, "drink-from-sink WHEN action starts")
    if serial > 0: kernel.run_until_stop()
    _check(condition.value(actor_id, ConditionState.HYDRATION) > before, "drinking from exact sink changes canonical hydration")

func _test_rest_and_sleep(world: WorldState, mutations: WorldMutationService, sustainment: SurvivorSustainmentActionService, condition: ActorConditionService, kernel: TickKernel, actor_id: String) -> void:
    var chair: String = _first_reachable_target(world, mutations, actor_id, [&"prop.dining_chair", &"prop.armchair", &"prop.sofa"], false)
    _check(not chair.is_empty(), "generated chair/sofa found")
    if not chair.is_empty():
        condition.set_condition(actor_id, ConditionState.REST, 20)
        condition.add_fatigue(actor_id, 50)
        var before_rest: int = condition.value(actor_id, ConditionState.REST)
        var rest_serial: int = sustainment.begin_rest_on(actor_id, chair)
        _check(rest_serial > 0, "rest-on-furniture WHEN action starts")
        if rest_serial > 0: kernel.run_until_stop()
        _check(condition.value(actor_id, ConditionState.REST) > before_rest, "resting on furniture changes canonical Rest")

    var bed: String = _first_reachable_target(world, mutations, actor_id, [&"prop.bed_single", &"prop.bed_double"], false)
    _check(not bed.is_empty(), "generated bed found")
    if not bed.is_empty():
        condition.set_condition(actor_id, ConditionState.REST, 10)
        var sleep_serial: int = sustainment.begin_sleep_in(actor_id, bed)
        _check(sleep_serial > 0, "sleep-in-bed WHEN action starts")
        if sleep_serial > 0: kernel.run_until_stop()
        _check(condition.value(actor_id, ConditionState.REST) > 10, "sleeping in exact bed changes canonical Rest")

func _test_cooking(world: WorldState, mutations: WorldMutationService, inventory_mutations: InventoryContainmentMutationService, crafting: CraftingActionService, inventory: InventoryContainmentState, kernel: TickKernel, actor_id: String) -> void:
    var stove: String = ""
    for candidate: String in _ids_of_any(world, [&"prop.stove_range"]):
        if not _place_actor_facing(world, mutations, actor_id, candidate, false): continue
        if bool(game.call("_crafting_workstation_available", actor_id, candidate, CraftingWorkstationCatalog.COOKING_STOVE)):
            stove = candidate
            break
    _check(not stove.is_empty(), "generated powered stove found")
    if stove.is_empty(): return
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.food.canned_soup", "ci.cook.soup"), "canned soup carried")
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.kitchen.cooking_pot", "ci.cook.pot"), "cooking pot carried")
    var request: Dictionary = crafting.request_craft(actor_id, &"cooking.heated_soup", stove)
    _check(bool(request.get("accepted", false)), "powered-stove Survival cooking starts")
    if bool(request.get("accepted", false)): kernel.run_until_stop()
    var cooked: Array[String] = world.entity_ids_of_type(&"item.crafting.heated_soup")
    var carried_cooked: bool = false
    for item_id: String in cooked:
        if inventory.is_contained(item_id) and inventory.container_of(item_id) == actor_id:
            carried_cooked = true
            break
    _check(carried_cooked, "cooking commits a real heated-food WHAT entity to personal inventory")

func _test_doors(world: WorldState, mutations: WorldMutationService, door_state: DoorStateStore, door_transitions: DoorPhysicalTransitionService, interactions: WorldInteractionActionService, interaction_state: WorldInteractableState, kernel: TickKernel, actor_id: String) -> void:
    var door: String = _first_prefix_target(world, mutations, actor_id, "door.")
    _check(not door.is_empty(), "generated door found")
    if door.is_empty(): return
    if door_state.state(door) == DoorValue.OPEN:
        door_transitions.close_manually(actor_id, door)

    var noises: Array[StringName] = []
    door_transitions.transition_resolved.connect(func(_actor, _door, _previous, _new, _cause, noise, _cell): noises.append(StringName(noise)))

    var click: Dictionary = interactions.request_action(actor_id, door, Actions.DOOR_OPEN)
    _check(bool(click.get("accepted", false)), "click-open action starts")
    if bool(click.get("accepted", false)): kernel.run_until_stop()
    _check(door_state.state(door) == DoorValue.OPEN, "click-open opens door")
    _check(not noises.is_empty() and noises.back() == DoorTransitions.NOISE_QUIET, "click-open is quiet")

    door_transitions.close_manually(actor_id, door)
    _check(door_transitions.open_for_passage(actor_id, door, &"movement.step_forward"), "walking passage auto-opens closed door")
    _check(noises.back() == DoorTransitions.NOISE_NORMAL, "walking through door is somewhat loud/normal")
    _check(door_state.state(door) == DoorValue.OPEN, "walk-open door remains open")
    var wait_serial: int = kernel.begin_action(actor_id, &"ci.wait", 3, TickRules.InterruptionPolicy.COMMITTED)
    if wait_serial > 0: kernel.run_until_stop()
    _check(door_state.state(door) == DoorValue.OPEN, "door does not auto-close after time advances")

    door_transitions.close_manually(actor_id, door)
    _check(door_transitions.open_for_passage(actor_id, door, &"movement.run_forward"), "running passage auto-opens closed door")
    _check(noises.back() == DoorTransitions.NOISE_LOUD, "running through door is loud")

    door_transitions.close_manually(actor_id, door)
    var lock_request: Dictionary = interactions.request_action(actor_id, door, Actions.DOOR_LOCK)
    _check(bool(lock_request.get("accepted", false)), "door lock action starts")
    if bool(lock_request.get("accepted", false)): kernel.run_until_stop()
    _check(interaction_state.is_locked(door), "door lock persists in interaction state")
    _check(not bool(game.call("_door_passage_allowed", actor_id, door, &"movement.step_forward")), "locked door blocks auto-open passage")
    var unlock_request: Dictionary = interactions.request_action(actor_id, door, Actions.DOOR_UNLOCK)
    _check(bool(unlock_request.get("accepted", false)), "door unlock action starts")
    if bool(unlock_request.get("accepted", false)): kernel.run_until_stop()
    _check(not interaction_state.is_locked(door), "door unlock restores passage eligibility")

    var catalog := SoundEmissionProfileCatalog.new()
    _check(catalog.power(SoundProfiles.DOOR_QUIET) < catalog.power(SoundProfiles.DOOR_NORMAL), "quiet door acoustic power is below walking door power")
    _check(catalog.power(SoundProfiles.DOOR_NORMAL) < catalog.power(SoundProfiles.DOOR_LOUD), "walking door acoustic power is below running door power")

func _test_window_and_reclamation(world: WorldState, mutations: WorldMutationService, spatial: SpatialQueryService, inventory: InventoryContainmentState, inventory_mutations: InventoryContainmentMutationService, interactions: WorldInteractionActionService, interaction_state: WorldInteractableState, kernel: TickKernel, actor_id: String) -> void:
    var window: String = ""
    for candidate: String in _prefix_ids(world, "window."):
        if _place_actor_facing(world, mutations, actor_id, candidate, true):
            window = candidate
            break
    _check(not window.is_empty(), "generated climbable window found")
    if window.is_empty(): return

    var open_request: Dictionary = interactions.request_action(actor_id, window, Actions.WINDOW_OPEN)
    _check(bool(open_request.get("accepted", false)), "unlocked window opens")
    if bool(open_request.get("accepted", false)): kernel.run_until_stop()
    _check(interaction_state.window_open(window), "window open state persists")
    var before_climb: Vector2i = world.placement(actor_id).anchor
    var climb_request: Dictionary = interactions.request_action(actor_id, window, Actions.WINDOW_CLIMB)
    _check(bool(climb_request.get("accepted", false)), "open window climb action starts")
    if bool(climb_request.get("accepted", false)): kernel.run_until_stop()
    _check(world.placement(actor_id).anchor != before_climb, "climbing through window moves actor across aperture")

    _check(_place_actor_facing(world, mutations, actor_id, window, false), "actor returns to window for lock test")
    var close_request: Dictionary = interactions.request_action(actor_id, window, Actions.WINDOW_CLOSE)
    _check(bool(close_request.get("accepted", false)), "window close action starts")
    if bool(close_request.get("accepted", false)): kernel.run_until_stop()
    var window_lock: Dictionary = interactions.request_action(actor_id, window, Actions.WINDOW_LOCK)
    _check(bool(window_lock.get("accepted", false)), "window lock action starts")
    if bool(window_lock.get("accepted", false)): kernel.run_until_stop()
    _check(interaction_state.is_locked(window), "window lock persists")
    var window_unlock: Dictionary = interactions.request_action(actor_id, window, Actions.WINDOW_UNLOCK)
    if bool(window_unlock.get("accepted", false)): kernel.run_until_stop()
    _check(not interaction_state.is_locked(window), "window unlock works")

    var chair: String = _first_reachable_target(world, mutations, actor_id, [&"prop.dining_chair", &"prop.armchair", &"prop.sofa"], false)
    _check(not chair.is_empty(), "deconstructible furniture found")
    if chair.is_empty(): return
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.tool.hammer", "ci.interaction.hammer"), "hammer carried for deconstruction/boarding")
    var deconstruct: Dictionary = interactions.request_action(actor_id, chair, Actions.OBJECT_DECONSTRUCT)
    _check(bool(deconstruct.get("accepted", false)), "Mechanical furniture deconstruction starts")
    if bool(deconstruct.get("accepted", false)): kernel.run_until_stop()
    _check(not world.has_entity(chair) and interaction_state.is_destroyed(chair), "deconstruction removes real object and records destroyed identity")
    var planks: Array[String] = world.entity_ids_of_type(&"item.material.wood_plank")
    var carried_plank: String = ""
    for item_id: String in planks:
        if inventory.is_contained(item_id) and inventory.container_of(item_id) == actor_id:
            carried_plank = item_id
            break
    _check(not carried_plank.is_empty(), "deconstruction reclaims a real wood plank")

    _check(_place_actor_facing(world, mutations, actor_id, window, false), "actor reaches window for boarding")
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.material.nails_box", "ci.interaction.nails"), "nails carried for boarding")
    var board: Dictionary = interactions.request_action(actor_id, window, Actions.OPENING_BOARD)
    _check(bool(board.get("accepted", false)), "board-window action starts with hammer + plank + nails")
    if bool(board.get("accepted", false)): kernel.run_until_stop()
    _check(interaction_state.board_count(window) == 1, "window records one real board")
    _check(not world.has_entity(carried_plank), "boarding consumes reclaimed plank")

    var break_request: Dictionary = interactions.request_action(actor_id, window, Actions.OPENING_BREAK)
    _check(bool(break_request.get("accepted", false)), "break boarded window action starts")
    if bool(break_request.get("accepted", false)): kernel.run_until_stop()
    _check(interaction_state.is_broken(window), "window breakage persists")
    _check(interaction_state.board_count(window) == 0, "breaking opening destroys attached boards")

func _first_reachable_target(world: WorldState, mutations: WorldMutationService, actor_id: String, semantics: Array[StringName], require_clear_destination: bool) -> String:
    for target_id: String in _ids_of_any(world, semantics):
        if _place_actor_facing(world, mutations, actor_id, target_id, require_clear_destination):
            return target_id
    return ""

func _first_prefix_target(world: WorldState, mutations: WorldMutationService, actor_id: String, prefix: String) -> String:
    for target_id: String in _prefix_ids(world, prefix):
        if _place_actor_facing(world, mutations, actor_id, target_id, false):
            return target_id
    return ""

func _place_actor_facing(world: WorldState, mutations: WorldMutationService, actor_id: String, target_id: String, require_clear_destination: bool) -> bool:
    var actor: WorldPlacement = world.placement(actor_id)
    var target: WorldPlacement = world.placement(target_id)
    var spatial: SpatialQueryService = game.get("_spatial_query")
    if actor == null or target == null or actor.footprint == null:
        return false
    var target_cell: Vector2i = target.anchor
    for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
        var actor_cell: Vector2i = target_cell - direction
        var facing: int = Facing.from_vector(direction)
        if not world.has_terrain(actor_cell) or facing < 0:
            continue
        if require_clear_destination:
            var destination: Vector2i = target_cell + direction
            if not world.has_terrain(destination):
                continue
            var query: SpatialQueryResult = spatial.query_entity_footprint(actor_id, destination, facing, true)
            if query.status != QueryResult.Status.CLEAR:
                continue
        if mutations.set_placement(actor_id, actor.channel, actor_cell, facing, actor.footprint):
            return true
    return false

func _give_item(world: WorldState, mutations: WorldMutationService, inventory_mutations: InventoryContainmentMutationService, actor_id: String, semantic: StringName, item_id: String) -> bool:
    if world.has_entity(item_id):
        return false
    if mutations.create_entity(semantic, item_id) != item_id:
        return false
    if inventory_mutations.set_container(item_id, actor_id):
        return true
    mutations.remove_entity(item_id)
    return false

func _button_with_meta(root: Node, meta_key: String, expected: String) -> Button:
    var button := root as Button
    if button != null and button.has_meta(meta_key) and String(button.get_meta(meta_key)) == expected:
        return button
    for child: Node in root.get_children():
        var found: Button = _button_with_meta(child, meta_key, expected)
        if found != null:
            return found
    return null

func _button_with_action(root: Node, item_id: String, action: String, label: String) -> Button:
    var button := root as Button
    if button != null and button.text == label \
        and String(button.get_meta("inventory_transfer_item_id", "")) == item_id \
        and String(button.get_meta("inventory_transfer_action", "")) == action:
        return button
    for child: Node in root.get_children():
        var found: Button = _button_with_action(child, item_id, action, label)
        if found != null:
            return found
    return null

func _button_with_treatment(root: Node, item_id: String, injury_id: String) -> Button:
    var button := root as Button
    if button != null \
        and String(button.get_meta("inventory_treatment_item_id", "")) == item_id \
        and String(button.get_meta("inventory_treatment_injury_id", "")) == injury_id:
        return button
    for child: Node in root.get_children():
        var found: Button = _button_with_treatment(child, item_id, injury_id)
        if found != null:
            return found
    return null

func _ids_of_any(world: WorldState, semantics: Array[StringName]) -> Array[String]:
    var result: Array[String] = []
    for semantic: StringName in semantics:
        for entity_id: String in world.entity_ids_of_type(semantic):
            if not result.has(entity_id): result.append(entity_id)
    result.sort()
    return result

func _prefix_ids(world: WorldState, prefix: String) -> Array[String]:
    var result: Array[String] = []
    for entity_id: String in world.entity_ids():
        var entity: WorldEntityRecord = world.entity(entity_id)
        if entity != null and String(entity.semantic_type).begins_with(prefix):
            result.append(entity_id)
    result.sort()
    return result

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("WORLD_INTERACTION_SMOKE_OK")
        if game != null: game.queue_free()
        quit(0)
        return
    for failure: String in failures:
        push_error("WORLD_INTERACTION_SMOKE_FAIL: %s" % failure)
    if game != null: game.queue_free()
    quit(1)
