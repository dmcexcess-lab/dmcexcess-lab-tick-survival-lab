extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const Actions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const RepairActions = preload("res://scripts/simulation/interaction/WorldObjectRepairActionService.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")

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
    var inventory: InventoryContainmentState = game.get("_inventory_state")
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations")
    var door_state: DoorStateStore = game.get("_door_state")
    var door_transitions: DoorPhysicalTransitionService = game.get("_door_transition")
    var interaction_state: WorldInteractableState = game.get("_world_interaction_state")
    var repair_actions: WorldObjectRepairActionService = game.get("_world_repair_actions")
    var controller: WorldInteractionPlayerController = game.get("_world_interaction_controller")
    var panel: WorldInteractionPanel = game.get("_world_interaction_panel")
    var pointer: DoorPointerInputAdapter = game.get("_door_pointer")

    _check(world != null and mutations != null and spatial != null and kernel != null, "world/WHEN owners available")
    _check(skills != null and inventory != null and inventory_mutations != null, "skill/inventory owners available")
    _check(door_state != null and door_transitions != null and interaction_state != null, "door damage owners available")
    _check(repair_actions != null and repair_actions.is_ready(), "world repair action owner ready")
    _check(controller != null and controller.is_ready() and panel != null and pointer != null, "unified player interaction route ready")
    if not failures.is_empty():
        _finish()
        return

    var actor_id: String = Fixture.PLAYER_ID
    _check(skills.set_skill(actor_id, SkillCatalog.MECHANICAL, 10, 0), "Mechanical set to expert")

    var door: String = _first_prefix_target(world, mutations, spatial, actor_id, "door.")
    _check(not door.is_empty(), "generated door reachable")
    if door.is_empty():
        _finish()
        return
    if door_state.state(door) == DoorValue.OPEN:
        _check(door_transitions.close_manually(actor_id, door), "door normalized closed")
    if interaction_state.is_locked(door):
        _check(interaction_state.set_locked(door, false, &"repair_ci_unlock"), "door normalized unlocked")
    if interaction_state.board_count(door) > 0:
        _check(interaction_state.set_board_count(door, 0, &"repair_ci_unboard"), "door normalized unboarded")
    if interaction_state.is_broken(door):
        _check(interaction_state.set_broken(door, false, &"repair_ci_intact"), "door normalized intact")

    const HAMMER_ID := "ci.repair.hammer"
    const PLANK_ID := "ci.repair.plank"
    const NAILS_ID := "ci.repair.nails"
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.tool.hammer", HAMMER_ID), "real hammer carried")
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.material.wood_plank", PLANK_ID), "real reclaimed plank carried")
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.material.nails_box", NAILS_ID), "real nails carried")

    var resolved: Array[Dictionary] = []
    controller.action_finished.connect(func(target_id, action_id, success, reason):
        resolved.append({"target": target_id, "action": String(action_id), "success": success, "reason": reason})
    )

    var before_break_tick: int = kernel.world_tick()
    pointer.world_cell_primary.emit(world.placement(door).anchor)
    await process_frame
    var break_button: Button = _world_button(panel, door, Actions.OPENING_BREAK)
    _check(panel.is_open() and break_button != null, "intact door chooser exposes BREAK")
    if break_button != null:
        break_button.pressed.emit()
    _check(interaction_state.is_broken(door), "BREAK commits persistent broken door truth")
    _check(door_state.state(door) == DoorValue.OPEN, "broken door is physically open")
    _check(kernel.world_tick() > before_break_tick, "BREAK spends real WHEN time")
    _check(world.has_entity(HAMMER_ID) and world.has_entity(PLANK_ID) and world.has_entity(NAILS_ID), "repair resources remain physical before repair")
    await process_frame

    var before_repair_tick: int = kernel.world_tick()
    pointer.world_cell_primary.emit(world.placement(door).anchor)
    await process_frame
    var repair_button: Button = _world_button(panel, door, RepairActions.ACTION_ID)
    var broken_open_button: Button = _world_button(panel, door, Actions.DOOR_OPEN)
    _check(panel.is_open() and repair_button != null, "broken door chooser exposes REPAIR")
    _check(broken_open_button == null, "broken door does not expose normal OPEN")
    if repair_button != null:
        repair_button.pressed.emit()

    _check(not interaction_state.is_broken(door), "REPAIR clears canonical broken state")
    _check(door_state.state(door) == DoorValue.CLOSED, "repaired door returns to coherent closed collision state")
    _check(kernel.world_tick() > before_repair_tick, "REPAIR spends real WHEN time")
    _check(world.has_entity(HAMMER_ID), "repair tool is retained")
    _check(inventory.is_contained(HAMMER_ID), "repair tool remains carried")
    _check(not world.has_entity(PLANK_ID) and not world.has_entity(NAILS_ID), "exact plank and nails are consumed")

    var saw_repair_success: bool = false
    for entry: Dictionary in resolved:
        if String(entry.get("target", "")) == door \
            and String(entry.get("action", "")) == String(RepairActions.ACTION_ID) \
            and bool(entry.get("success", false)):
            saw_repair_success = true
            break
    _check(saw_repair_success, "unified controller reports true WHEN repair completion")
    await process_frame

    pointer.world_cell_primary.emit(world.placement(door).anchor)
    await process_frame
    _check(_world_button(panel, door, RepairActions.ACTION_ID) == null, "intact repaired door no longer exposes REPAIR")
    _check(_world_button(panel, door, Actions.DOOR_OPEN) != null, "repaired door resumes normal OPEN interaction")

    # Shattered windows stay honestly broken. There is no glass replacement resource
    # in the current catalog, so the player must not receive a fake REPAIR affordance.
    var window: String = _first_prefix_target(world, mutations, spatial, actor_id, "window.")
    _check(not window.is_empty(), "generated window reachable for honesty check")
    if not window.is_empty():
        interaction_state.set_board_count(window, 0, &"repair_ci_window_unboarded")
        interaction_state.set_locked(window, false, &"repair_ci_window_unlocked")
        interaction_state.set_broken(window, true, &"repair_ci_window_broken")
        interaction_state.set_window_open(window, true, &"repair_ci_window_aperture")
        pointer.world_cell_primary.emit(world.placement(window).anchor)
        await process_frame
        _check(_world_button(panel, window, RepairActions.ACTION_ID) == null, "broken window has no fake repair without glass")

    _finish()

func _world_button(root: Node, target_id: String, action_id: StringName) -> Button:
    var button := root as Button
    if button != null \
        and String(button.get_meta("world_target_id", "")) == target_id \
        and String(button.get_meta("world_action_id", "")) == String(action_id):
        return button
    for child: Node in root.get_children():
        var found: Button = _world_button(child, target_id, action_id)
        if found != null:
            return found
    return null

func _first_prefix_target(world: WorldState, mutations: WorldMutationService, spatial: SpatialQueryService, actor_id: String, prefix: String) -> String:
    for target_id: String in _prefix_ids(world, prefix):
        if _place_actor_facing(world, mutations, spatial, actor_id, target_id):
            return target_id
    return ""

func _place_actor_facing(world: WorldState, mutations: WorldMutationService, spatial: SpatialQueryService, actor_id: String, target_id: String) -> bool:
    var actor: WorldPlacement = world.placement(actor_id)
    var target: WorldPlacement = world.placement(target_id)
    if actor == null or target == null or actor.footprint == null or spatial == null:
        return false
    var target_cell: Vector2i = target.anchor
    for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
        var actor_cell: Vector2i = target_cell - direction
        var facing: int = Facing.from_vector(direction)
        if not world.has_terrain(actor_cell) or facing < 0:
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
        print("WORLD_OBJECT_REPAIR_UI_SMOKE_OK")
        if game != null:
            game.queue_free()
        quit(0)
        return
    for failure: String in failures:
        push_error("WORLD_OBJECT_REPAIR_UI_SMOKE_FAIL: %s" % failure)
    if game != null:
        game.queue_free()
    quit(1)
