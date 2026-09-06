extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const QueryResult = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const Actions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const PickupOffers = preload("res://scripts/simulation/interaction/LooseItemPickupInteractionOfferProvider.gd")
const SustainmentOffers = preload("res://scripts/simulation/interaction/SustainmentInteractionOfferProvider.gd")
const LootOffers = preload("res://scripts/simulation/loot/LootSearchInteractionOfferProvider.gd")
const CraftingOffers = preload("res://scripts/simulation/crafting/CraftingInteractionOfferProvider.gd")
const Workstations = preload("res://scripts/simulation/crafting/CraftingWorkstationCatalog.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const ConditionState = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const EquipmentProfiles = preload("res://scripts/simulation/actors/equipment/ActorEquipmentProfileCatalog.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")

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
    var skills: ActorSkillState = game.get("_skill_state")
    var condition: ActorConditionService = game.get("_condition_service")
    var hand_state: ActorHandEquipmentState = game.get("_hand_state")
    var inventory_state: InventoryContainmentState = game.get("_inventory_state")
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations")
    var door_state: DoorStateStore = game.get("_door_state")
    var door_transitions: DoorPhysicalTransitionService = game.get("_door_transition")
    var interaction_state: WorldInteractableState = game.get("_world_interaction_state")
    var controller: WorldInteractionPlayerController = game.get("_world_interaction_controller")
    var panel: WorldInteractionPanel = game.get("_world_interaction_panel")
    var pointer: DoorPointerInputAdapter = game.get("_door_pointer")
    var crafting_panel: CraftingPanel = game.get("_crafting_panel")
    var loot_panel: LootContainerPanel = game.get("_loot_panel")
    var loot_inspection: LootContainerInspectionQuery = game.get("_loot_inspection")

    _check(world != null and mutations != null and spatial != null, "world route owners available")
    _check(skills != null and condition != null and hand_state != null and inventory_state != null and inventory_mutations != null, "player state owners available")
    _check(door_state != null and door_transitions != null and interaction_state != null, "opening owners available")
    _check(controller != null and controller.is_ready() and panel != null and pointer != null, "unified world-click route ready")
    _check(crafting_panel != null and crafting_panel.is_configured(), "crafting panel ready")
    _check(loot_panel != null and loot_panel.is_configured() and loot_inspection != null and loot_inspection.is_ready(), "loot panel ready")
    if not failures.is_empty():
        _finish()
        return

    var actor_id: String = Fixture.PLAYER_ID
    _check(skills.set_skill(actor_id, SkillCatalog.MECHANICAL, 10, 0), "Mechanical set to expert")
    _check(skills.set_skill(actor_id, SkillCatalog.SURVIVAL, 10, 0), "Survival set to expert")

    var resolved: Array[Dictionary] = []
    controller.action_finished.connect(func(target_id, action_id, success, reason):
        resolved.append({"target": target_id, "action": String(action_id), "success": success, "reason": reason})
    )

    await _test_loose_skateboard_pickup_route(world, mutations, spatial, hand_state, inventory_state, pointer, panel, actor_id)
    await _test_sink_route(world, mutations, condition, pointer, panel, actor_id)
    await _test_bed_route(world, mutations, condition, pointer, panel, actor_id)
    await _test_door_route(world, mutations, door_state, door_transitions, interaction_state, pointer, panel, actor_id)
    await _test_window_route(world, mutations, spatial, inventory_mutations, interaction_state, pointer, panel, actor_id)
    await _test_stove_route(world, mutations, pointer, panel, crafting_panel, actor_id)
    await _test_loot_route(world, mutations, pointer, panel, loot_panel, loot_inspection, actor_id)
    await _test_deconstruction_route(world, mutations, inventory_mutations, interaction_state, pointer, panel, actor_id)

    var saw_native_success: bool = false
    for entry: Dictionary in resolved:
        if bool(entry.get("success", false)) and String(entry.get("action", "")) in [
            String(PickupOffers.ACTION_ID), String(Actions.DOOR_OPEN), String(Actions.WINDOW_OPEN), String(Actions.OPENING_BOARD), String(Actions.OBJECT_DECONSTRUCT)
        ]:
            saw_native_success = true
            break
    _check(saw_native_success, "world chooser reports completed native actions")
    _finish()

func _test_loose_skateboard_pickup_route(
    world: WorldState,
    mutations: WorldMutationService,
    spatial: SpatialQueryService,
    hand_state: ActorHandEquipmentState,
    inventory_state: InventoryContainmentState,
    pointer: DoorPointerInputAdapter,
    panel: WorldInteractionPanel,
    actor_id: String
) -> void:
    var skateboard: String = ""
    for candidate: String in world.entity_ids_of_type(EquipmentProfiles.SKATEBOARD):
        if world.placement(candidate) != null and _place_actor_facing(world, mutations, spatial, actor_id, candidate, false):
            skateboard = candidate
            break
    _check(not skateboard.is_empty(), "seeded loose skateboard reachable")
    if skateboard.is_empty(): return
    var loose_cell: Vector2i = world.placement(skateboard).anchor
    pointer.world_cell_primary.emit(loose_cell)
    await process_frame
    var pickup: Button = _world_button(panel, skateboard, PickupOffers.ACTION_ID)
    _check(panel.is_open() and pickup != null and pickup.text == "PICK UP", "clicking loose skateboard exposes PICK UP")
    if pickup != null: pickup.pressed.emit()
    await process_frame

    var equipped_slot: int = -1
    for slot: int in [Slots.Value.PRIMARY_RIGHT, Slots.Value.SECONDARY_LEFT, Slots.Value.BACK]:
        if hand_state.item_in_slot(actor_id, slot) == skateboard:
            equipped_slot = slot
            break
    _check(world.placement(skateboard) == null, "PICK UP removes exact skateboard loose-world placement")
    _check(equipped_slot >= 0, "PICK UP equips the same skateboard in RH/LH/back")
    _check(not inventory_state.is_contained(skateboard), "skateboard pickup never routes through ordinary backpack/personal containment")

func _test_sink_route(world: WorldState, mutations: WorldMutationService, condition: ActorConditionService, pointer: DoorPointerInputAdapter, panel: WorldInteractionPanel, actor_id: String) -> void:
    var sink: String = _first_reachable_target(world, mutations, actor_id, [&"prop.kitchen_sink", &"prop.bathroom_vanity", &"prop.utility_sink"], false)
    _check(not sink.is_empty(), "generated sink reachable")
    if sink.is_empty(): return
    condition.set_condition(actor_id, ConditionState.HYDRATION, 10)
    var before: int = condition.value(actor_id, ConditionState.HYDRATION)
    pointer.world_cell_primary.emit(world.placement(sink).anchor)
    await process_frame
    var drink: Button = _world_button(panel, sink, SustainmentOffers.DRINK_FROM_FIXTURE)
    _check(panel.is_open() and drink != null, "clicking exact sink exposes DRINK")
    if drink != null: drink.pressed.emit()
    _check(condition.value(actor_id, ConditionState.HYDRATION) > before, "sink DRINK changes canonical hydration")
    await process_frame

func _test_bed_route(world: WorldState, mutations: WorldMutationService, condition: ActorConditionService, pointer: DoorPointerInputAdapter, panel: WorldInteractionPanel, actor_id: String) -> void:
    var bed: String = _first_reachable_target(world, mutations, actor_id, [&"prop.bed_single", &"prop.bed_double"], false)
    _check(not bed.is_empty(), "generated bed reachable")
    if bed.is_empty(): return
    condition.set_condition(actor_id, ConditionState.REST, 10)
    var before: int = condition.value(actor_id, ConditionState.REST)
    pointer.world_cell_primary.emit(world.placement(bed).anchor)
    await process_frame
    var sleep: Button = _world_button(panel, bed, SustainmentOffers.SLEEP_IN_BED)
    var rest: Button = _world_button(panel, bed, SustainmentOffers.REST_ON_FURNITURE)
    _check(panel.is_open() and sleep != null and rest != null, "clicking exact bed exposes SLEEP and REST")
    if sleep != null: sleep.pressed.emit()
    _check(condition.value(actor_id, ConditionState.REST) > before, "bed SLEEP changes canonical Rest")
    await process_frame

func _test_door_route(world: WorldState, mutations: WorldMutationService, door_state: DoorStateStore, door_transitions: DoorPhysicalTransitionService, interaction_state: WorldInteractableState, pointer: DoorPointerInputAdapter, panel: WorldInteractionPanel, actor_id: String) -> void:
    var door: String = _first_prefix_target(world, mutations, actor_id, "door.")
    _check(not door.is_empty(), "generated door reachable")
    if door.is_empty(): return
    if door_state.state(door) == DoorValue.OPEN:
        door_transitions.close_manually(actor_id, door)
    interaction_state.set_locked(door, false, &"ci_quiet_entry_unlocked")

    pointer.world_cell_primary.emit(world.placement(door).anchor)
    await process_frame
    var open_button: Button = _world_button(panel, door, Actions.DOOR_OPEN)
    _check(panel.is_open() and open_button != null and open_button.text == "OPEN", "unlocked closed door exposes OPEN")
    _check(_world_button(panel, door, Actions.DOOR_LOCK) == null and _world_button(panel, door, Actions.DOOR_UNLOCK) == null, "door chooser never exposes player LOCK/UNLOCK")
    if open_button != null: open_button.pressed.emit()
    _check(door_state.state(door) == DoorValue.OPEN, "door OPEN button mutates real door state")
    await process_frame

    pointer.world_cell_primary.emit(world.placement(door).anchor)
    await process_frame
    var close_button: Button = _world_button(panel, door, Actions.DOOR_CLOSE)
    _check(close_button != null, "open door exposes CLOSE")
    if close_button != null: close_button.pressed.emit()
    _check(door_state.state(door) == DoorValue.CLOSED, "door CLOSE button mutates real door state")
    await process_frame

    interaction_state.set_locked(door, true, &"ci_quiet_entry_locked")
    pointer.world_cell_primary.emit(world.placement(door).anchor)
    await process_frame
    var try_open: Button = _world_button(panel, door, Actions.DOOR_OPEN)
    _check(try_open != null and try_open.text == "TRY OPEN", "locked door exposes TRY OPEN without revealing success")
    _check(_world_button(panel, door, Actions.DOOR_LOCK) == null and _world_button(panel, door, Actions.DOOR_UNLOCK) == null, "locked door still exposes no key/lock management")
    _check(_world_button(panel, door, Actions.OPENING_BREAK) != null, "locked door still exposes noisy BREAK entry")
    if try_open != null: try_open.pressed.emit()
    _check(door_state.state(door) == DoorValue.CLOSED, "TRY OPEN leaves locked door closed")
    interaction_state.set_locked(door, false, &"ci_quiet_entry_cleanup")
    panel.close_panel()
    await process_frame

func _test_window_route(world: WorldState, mutations: WorldMutationService, spatial: SpatialQueryService, inventory_mutations: InventoryContainmentMutationService, interaction_state: WorldInteractableState, pointer: DoorPointerInputAdapter, panel: WorldInteractionPanel, actor_id: String) -> void:
    var window: String = ""
    for candidate: String in _prefix_ids(world, "window."):
        if _place_actor_facing(world, mutations, spatial, actor_id, candidate, true):
            window = candidate
            break
    _check(not window.is_empty(), "generated climbable window reachable")
    if window.is_empty(): return
    interaction_state.set_locked(window, false, &"ci_quiet_entry_unlocked")
    if interaction_state.window_open(window): interaction_state.set_window_open(window, false, &"ci_route_close")

    pointer.world_cell_primary.emit(world.placement(window).anchor)
    await process_frame
    var open_button: Button = _world_button(panel, window, Actions.WINDOW_OPEN)
    _check(open_button != null and open_button.text == "OPEN", "unlocked closed window exposes quiet OPEN")
    _check(_world_button(panel, window, Actions.WINDOW_LOCK) == null and _world_button(panel, window, Actions.WINDOW_UNLOCK) == null, "window chooser never exposes player LOCK/UNLOCK")
    if open_button != null: open_button.pressed.emit()
    _check(interaction_state.window_open(window), "window OPEN button persists open state")
    await process_frame

    pointer.world_cell_primary.emit(world.placement(window).anchor)
    await process_frame
    var climb_open: Button = _world_button(panel, window, Actions.WINDOW_CLIMB)
    _check(climb_open != null, "open window exposes CLIMB THROUGH")
    var before_climb: Vector2i = world.placement(actor_id).anchor
    if climb_open != null: climb_open.pressed.emit()
    _check(world.placement(actor_id).anchor != before_climb, "CLIMB THROUGH moves actor across open window")
    await process_frame

    _check(_place_actor_facing(world, mutations, spatial, actor_id, window, true), "actor returns to window with clear far-side climb destination")
    pointer.world_cell_primary.emit(world.placement(window).anchor)
    await process_frame
    var close_button: Button = _world_button(panel, window, Actions.WINDOW_CLOSE)
    if close_button != null: close_button.pressed.emit()
    _check(not interaction_state.window_open(window), "window closes through normal UI")
    await process_frame

    interaction_state.set_locked(window, true, &"ci_quiet_entry_locked")
    pointer.world_cell_primary.emit(world.placement(window).anchor)
    await process_frame
    var try_open: Button = _world_button(panel, window, Actions.WINDOW_OPEN)
    _check(try_open != null and try_open.text == "TRY OPEN", "locked window exposes TRY OPEN without revealing success")
    _check(_world_button(panel, window, Actions.WINDOW_LOCK) == null and _world_button(panel, window, Actions.WINDOW_UNLOCK) == null, "locked window exposes no key/lock management")
    _check(_world_button(panel, window, Actions.OPENING_BREAK) != null, "locked window still exposes noisy BREAK entry")
    if try_open != null: try_open.pressed.emit()
    _check(not interaction_state.window_open(window), "TRY OPEN leaves locked window closed")
    interaction_state.set_locked(window, false, &"ci_quiet_entry_cleanup")
    panel.close_panel()
    await process_frame

    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.tool.hammer", "ci.ui.window.hammer"), "hammer carried for boarding")
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.material.wood_plank", "ci.ui.window.plank"), "plank carried for boarding")
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.material.nails_box", "ci.ui.window.nails"), "nails carried for boarding")
    pointer.world_cell_primary.emit(world.placement(window).anchor)
    await process_frame
    var board_button: Button = _world_button(panel, window, Actions.OPENING_BOARD)
    _check(board_button != null, "closed window exposes BOARD")
    if board_button != null: board_button.pressed.emit()
    _check(interaction_state.board_count(window) == 1, "BOARD consumes real prerequisites and persists board")
    await process_frame

    pointer.world_cell_primary.emit(world.placement(window).anchor)
    await process_frame
    var break_button: Button = _world_button(panel, window, Actions.OPENING_BREAK)
    _check(break_button != null, "boarded window exposes BREAK")
    if break_button != null: break_button.pressed.emit()
    _check(interaction_state.is_broken(window) and interaction_state.board_count(window) == 0, "BREAK destroys window/boards through real owner")
    await process_frame

    pointer.world_cell_primary.emit(world.placement(window).anchor)
    await process_frame
    var climb_broken: Button = _world_button(panel, window, Actions.WINDOW_CLIMB)
    _check(climb_broken != null, "broken window exposes CLIMB THROUGH")
    before_climb = world.placement(actor_id).anchor
    if climb_broken != null: climb_broken.pressed.emit()
    _check(world.placement(actor_id).anchor != before_climb, "broken-window CLIMB THROUGH moves actor across aperture")
    await process_frame

func _test_stove_route(world: WorldState, mutations: WorldMutationService, pointer: DoorPointerInputAdapter, panel: WorldInteractionPanel, crafting_panel: CraftingPanel, actor_id: String) -> void:
    var stove: String = ""
    for candidate: String in _ids_of_any(world, [&"prop.stove_range"]):
        if not _place_actor_facing(world, mutations, game.get("_spatial_query"), actor_id, candidate, false): continue
        if bool(game.call("_crafting_workstation_available", actor_id, candidate, Workstations.COOKING_STOVE)):
            stove = candidate
            break
    _check(not stove.is_empty(), "generated powered stove reachable")
    if stove.is_empty(): return

    pointer.world_cell_primary.emit(world.placement(stove).anchor)
    await process_frame
    var craft_button: Button = _world_button(panel, stove, CraftingOffers.ACTION_ID)
    var deconstruct_button: Button = _world_button(panel, stove, Actions.OBJECT_DECONSTRUCT)
    _check(panel.is_open() and not crafting_panel.is_open(), "stove click first opens one unified action chooser")
    _check(craft_button != null and deconstruct_button != null, "stove chooser exposes both CRAFT and DECONSTRUCT")
    if craft_button != null: craft_button.pressed.emit()
    var snapshot: Dictionary = crafting_panel.presentation_snapshot()
    _check(crafting_panel.is_open() and String(snapshot.get("workstation_id", "")) == stove, "CRAFT delegates exact stove to cooking panel")
    crafting_panel.close_panel()
    await process_frame

func _test_loot_route(world: WorldState, mutations: WorldMutationService, pointer: DoorPointerInputAdapter, panel: WorldInteractionPanel, loot_panel: LootContainerPanel, loot_inspection: LootContainerInspectionQuery, actor_id: String) -> void:
    var container: String = ""
    for semantic: StringName in [&"prop.refrigerator_white", &"prop.pantry", &"prop.medicine_cabinet", &"prop.dresser_wide"]:
        for candidate: String in world.entity_ids_of_type(semantic):
            if not _place_actor_facing(world, mutations, game.get("_spatial_query"), actor_id, candidate, false): continue
            if bool(loot_inspection.query(actor_id, candidate).get("ok", false)):
                container = candidate
                break
        if not container.is_empty(): break
    _check(not container.is_empty(), "generated searchable container reachable")
    if container.is_empty(): return

    pointer.world_cell_primary.emit(world.placement(container).anchor)
    await process_frame
    var search_button: Button = _world_button(panel, container, LootOffers.SEARCH_ACTION_ID)
    _check(panel.is_open() and not loot_panel.is_open(), "container click first opens unified action chooser")
    _check(search_button != null, "searchable container chooser exposes SEARCH")
    if search_button != null: search_button.pressed.emit()
    var snapshot: Dictionary = loot_panel.presentation_snapshot()
    _check(loot_panel.is_open() and String(snapshot.get("container_id", "")) == container, "SEARCH delegates exact target and opens real loot panel")
    loot_panel.close_panel()
    await process_frame

func _test_deconstruction_route(world: WorldState, mutations: WorldMutationService, inventory_mutations: InventoryContainmentMutationService, interaction_state: WorldInteractableState, pointer: DoorPointerInputAdapter, panel: WorldInteractionPanel, actor_id: String) -> void:
    var chair: String = _first_reachable_target(world, mutations, actor_id, [&"prop.dining_chair", &"prop.armchair", &"prop.sofa"], false)
    _check(not chair.is_empty(), "deconstructible furniture reachable")
    if chair.is_empty(): return
    _give_item(world, mutations, inventory_mutations, actor_id, &"item.tool.hammer", "ci.ui.deconstruct.hammer")
    pointer.world_cell_primary.emit(world.placement(chair).anchor)
    await process_frame
    var deconstruct: Button = _world_button(panel, chair, Actions.OBJECT_DECONSTRUCT)
    _check(deconstruct != null, "furniture click exposes DECONSTRUCT")
    if deconstruct != null: deconstruct.pressed.emit()
    _check(not world.has_entity(chair) and interaction_state.is_destroyed(chair), "DECONSTRUCT removes exact world object")
    await process_frame

func _world_button(root: Node, target_id: String, action_id: StringName) -> Button:
    var button := root as Button
    if button != null \
        and String(button.get_meta("world_target_id", "")) == target_id \
        and String(button.get_meta("world_action_id", "")) == String(action_id):
        return button
    for child: Node in root.get_children():
        var found: Button = _world_button(child, target_id, action_id)
        if found != null: return found
    return null

func _first_reachable_target(world: WorldState, mutations: WorldMutationService, actor_id: String, semantics: Array[StringName], require_clear_destination: bool) -> String:
    var spatial: SpatialQueryService = game.get("_spatial_query")
    for target_id: String in _ids_of_any(world, semantics):
        if _place_actor_facing(world, mutations, spatial, actor_id, target_id, require_clear_destination):
            return target_id
    return ""

func _first_prefix_target(world: WorldState, mutations: WorldMutationService, actor_id: String, prefix: String) -> String:
    var spatial: SpatialQueryService = game.get("_spatial_query")
    for target_id: String in _prefix_ids(world, prefix):
        if _place_actor_facing(world, mutations, spatial, actor_id, target_id, false):
            return target_id
    return ""

func _place_actor_facing(world: WorldState, mutations: WorldMutationService, spatial: SpatialQueryService, actor_id: String, target_id: String, require_clear_destination: bool) -> bool:
    var actor: WorldPlacement = world.placement(actor_id)
    var target: WorldPlacement = world.placement(target_id)
    if actor == null or target == null or actor.footprint == null or spatial == null:
        return false
    var target_cell: Vector2i = target.anchor
    for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
        var actor_cell: Vector2i = target_cell - direction
        var facing: int = Facing.from_vector(direction)
        if not world.has_terrain(actor_cell) or facing < 0: continue
        if require_clear_destination:
            var destination: Vector2i = target_cell + direction
            if not world.has_terrain(destination): continue
            var query: SpatialQueryResult = spatial.query_entity_footprint(actor_id, destination, facing, true)
            if query.status != QueryResult.Status.CLEAR: continue
        if mutations.set_placement(actor_id, actor.channel, actor_cell, facing, actor.footprint): return true
    return false

func _give_item(world: WorldState, mutations: WorldMutationService, inventory_mutations: InventoryContainmentMutationService, actor_id: String, semantic: StringName, item_id: String) -> bool:
    if world.has_entity(item_id): return false
    if mutations.create_entity(semantic, item_id) != item_id: return false
    if inventory_mutations.set_container(item_id, actor_id): return true
    mutations.remove_entity(item_id)
    return false

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
        if entity != null and String(entity.semantic_type).begins_with(prefix): result.append(entity_id)
    result.sort()
    return result

func _check(condition: bool, message: String) -> void:
    if not condition: failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("PLAYER_WORLD_UI_ROUTE_SMOKE_OK")
        if game != null: game.queue_free()
        quit(0)
        return
    for failure: String in failures:
        push_error("PLAYER_WORLD_UI_ROUTE_SMOKE_FAIL: %s" % failure)
    if game != null: game.queue_free()
    quit(1)