extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const Actions = preload("res://scripts/simulation/utilities/PortableGeneratorActionService.gd")

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
    var kernel: TickKernel = game.get("_kernel")
    var utilities: UtilityRuntimeState = game.get("_utilities")
    var utility_lighting: UtilityPoweredLightingSourceAdapter = game.get("_utility_lighting")
    var generators: PortableGeneratorState = game.get("_portable_generators")
    var actions: PortableGeneratorActionService = game.get("_generator_actions")
    var skills: ActorSkillState = game.get("_skill_state")
    var inventory: InventoryContainmentState = game.get("_inventory_state")
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations")
    var controller: WorldInteractionPlayerController = game.get("_world_interaction_controller")
    var panel: WorldInteractionPanel = game.get("_world_interaction_panel")
    var pointer: DoorPointerInputAdapter = game.get("_door_pointer")
    _check(world != null and mutations != null and kernel != null and utilities != null and utility_lighting != null, "WHAT/WHEN/System-33/light owners available")
    _check(generators != null and actions != null and actions.is_ready(), "portable-generator state/action owners ready")
    _check(skills != null and inventory != null and inventory_mutations != null, "skill/inventory owners available")
    _check(controller != null and controller.is_ready() and panel != null and pointer != null, "unified player interaction route ready")
    if not failures.is_empty():
        _finish()
        return

    var generator_ids: Array[String] = generators.generator_ids()
    if generator_ids.is_empty():
        var fixture_id: String = "ci.generator.physical"
        var fixture_cell: Vector2i = _empty_nearby_cell(world, Fixture.PLAYER_ID)
        _check(fixture_cell != Vector2i(2147483647, 2147483647), "test finds a real nearby world cell")
        _check(mutations.create_entity(PortableGeneratorState.SEMANTIC, fixture_id) == fixture_id, "physical generator WHAT entity created")
        _check(mutations.set_placement(fixture_id, Layers.Channel.OBJECT, fixture_cell, Facing.Value.SOUTH, Footprint.single_cell()), "physical generator occupies the world")
        generator_ids = generators.generator_ids()
    _check(not generator_ids.is_empty(), "generated physical portable generator is enrolled")
    if generator_ids.is_empty():
        _finish()
        return
    var target: String = generator_ids[0]
    var actor_id: String = Fixture.PLAYER_ID
    const ROOM_LIGHT_ID := "ci.generator.room_light"
    var generator_cell: Vector2i = world.placement(target).anchor
    _check(mutations.create_entity(&"fixture.room_light", ROOM_LIGHT_ID) == ROOM_LIGHT_ID, "real automatic room-light fixture created")
    _check(mutations.set_placement(ROOM_LIGHT_ID, Layers.Channel.EFFECT, generator_cell, Facing.Value.NORTH, Footprint.single_cell()), "room-light fixture occupies generator scope")
    _check(world.entity(target).semantic_type == PortableGeneratorState.SEMANTIC, "generator state owns a real WHAT prop")
    _check(_place_actor_facing(world, mutations, actor_id, target), "player can stand in contact with generator")
    _check(skills.set_skill(actor_id, SkillCatalog.MECHANICAL, 10, 0), "Mechanical set to expert for deterministic repair")

    var initial: Dictionary = generators.record(target)
    var service_id: String = String(initial.get("power_service_id", ""))
    var scope_id: String = String(initial.get("power_scope_id", ""))
    _check(not service_id.is_empty() and not scope_id.is_empty(), "generator binds to existing service and building scope")
    var branch_id: String = utilities.power_branch_component_id(service_id)
    _check(not branch_id.is_empty(), "generator building belongs to real distribution branch")
    _check(utilities.bind_appliance("ci.generator.local", &"fixed_light", service_id, "", true, scope_id), "local fixed appliance binds")
    _check(utilities.bind_appliance("ci.generator.cold", &"refrigeration", service_id, "", true, scope_id), "local refrigeration appliance binds")
    _check(utilities.bind_appliance("ci.generator.neighbor", &"fixed_light", service_id, "", true, "ci.neighbor.building"), "neighbor fixed appliance binds")
    _check(utilities.set_power_component_state(branch_id, UtilityRuntimeState.DAMAGED, &"generator_ci_grid_outage"), "real grid branch fails")
    _check(not utilities.appliance_powered("ci.generator.local") and not utilities.appliance_powered("ci.generator.neighbor"), "grid outage removes both fixed loads")
    _check(not utilities.cold_storage_available("ci.generator.cold"), "grid outage warms local refrigeration")
    _check(not _has_emitter(utility_lighting.emitters(), "utility.light:%s" % ROOM_LIGHT_ID), "grid outage automatically darkens fixed room light")

    pointer.world_cell_primary.emit(world.placement(target).anchor)
    await process_frame
    _check(_world_button(panel, target, Actions.INSPECT) != null, "chooser exposes stateful INSPECT")
    _check(_world_button(panel, target, Actions.REFUEL) != null, "empty stopped generator exposes REFUEL")
    _check(_world_button(panel, target, Actions.START) == null and _world_button(panel, target, Actions.STOP) == null, "empty stopped generator hides invalid START/STOP")
    panel.close_panel()
    var empty_start: Dictionary = actions.request_action(actor_id, target, Actions.START)
    _check(not bool(empty_start.get("accepted", true)) and String(empty_start.get("reason", "")) == "generator_out_of_fuel", "start failure reports truthful empty-fuel cause")

    const GAS_CAN_A := "ci.generator.gas_can.a"
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.automotive.gas_can", GAS_CAN_A), "existing whole gas-can item is carried")
    var before_refuel_tick: int = kernel.world_tick()
    pointer.world_cell_primary.emit(world.placement(target).anchor)
    await process_frame
    var refuel_button: Button = _world_button(panel, target, Actions.REFUEL)
    _check(refuel_button != null, "REFUEL is reachable through ordinary chooser")
    if refuel_button != null:
        refuel_button.pressed.emit()
    _check(kernel.world_tick() > before_refuel_tick, "refuel spends real WHEN time")
    _check(not world.has_entity(GAS_CAN_A), "refuel consumes the exact whole gas can")
    _check(int(generators.record(target).get("fuel_ticks", 0)) == PortableGeneratorState.MAX_FUEL_TICKS, "generator owns full persisted fuel quantity")

    pointer.world_cell_primary.emit(world.placement(target).anchor)
    await process_frame
    var start_button: Button = _world_button(panel, target, Actions.START)
    _check(start_button != null and _world_button(panel, target, Actions.REFUEL) == null, "fueled generator exposes START and hides full-tank REFUEL")
    var before_start_tick: int = kernel.world_tick()
    if start_button != null:
        start_button.pressed.emit()
    _check(kernel.world_tick() > before_start_tick and bool(generators.record(target).get("running", false)), "START spends WHEN time and commits ON state")
    _check(utilities.appliance_powered("ci.generator.local"), "running generator restores actual local fixed-load service")
    _check(utilities.cold_storage_available("ci.generator.cold"), "running generator automatically restores local refrigeration")
    _check(_has_emitter(utility_lighting.emitters(), "utility.light:%s" % ROOM_LIGHT_ID), "running generator automatically restores real fixed room light")
    _check(not utilities.appliance_powered("ci.generator.neighbor"), "generator does not power another building on the same branch")

    var fuel_before_turn: int = int(generators.record(target).get("fuel_ticks", 0))
    pointer.world_cell_primary.emit(world.placement(target).anchor)
    await process_frame
    _check(_world_button(panel, target, Actions.STOP) != null, "running generator exposes STOP")
    _check(_world_button(panel, target, Actions.START) == null and _world_button(panel, target, Actions.REFUEL) == null and _world_button(panel, target, Actions.REPAIR) == null, "running state hides invalid start/refuel/repair routes")
    var inspect_button: Button = _world_button(panel, target, Actions.INSPECT)
    if inspect_button != null:
        inspect_button.pressed.emit()
    _check(int(generators.record(target).get("fuel_ticks", 0)) < fuel_before_turn, "fuel consumption follows WHEN advancement, not frames")

    var persisted: Dictionary = generators.snapshot()
    var restored := PortableGeneratorState.new()
    _check(restored.restore_snapshot(persisted), "generator snapshot restores")
    _check(restored.record(target) == generators.record(target), "fuel/on/condition/service state persists exactly")
    var restored_fuel: int = int(restored.record(target).get("fuel_ticks", 0))
    _check(restored.advance_to_tick(int(restored.record(target).get("last_world_tick", 0)) + restored_fuel), "restored running generator settles analytically")
    _check(not bool(restored.record(target).get("running", true)) and int(restored.record(target).get("fuel_ticks", -1)) == 0, "fuel exhaustion persists OFF and removes local supply")

    pointer.world_cell_primary.emit(world.placement(target).anchor)
    await process_frame
    var stop_button: Button = _world_button(panel, target, Actions.STOP)
    if stop_button != null:
        stop_button.pressed.emit()
    _check(not bool(generators.record(target).get("running", true)), "STOP commits persistent OFF state")
    _check(not utilities.appliance_powered("ci.generator.local"), "STOP removes local service immediately")
    _check(not utilities.cold_storage_available("ci.generator.cold"), "STOP warms local refrigeration")
    _check(not _has_emitter(utility_lighting.emitters(), "utility.light:%s" % ROOM_LIGHT_ID), "STOP automatically darkens fixed room light")

    _check(generators.damage(target, 70, kernel.world_tick()), "generator can enter real damaged condition")
    var damaged_start: Dictionary = actions.request_action(actor_id, target, Actions.START)
    _check(not bool(damaged_start.get("accepted", true)) and String(damaged_start.get("reason", "")) == "generator_requires_repair", "damaged start failure reports repair requirement")
    var missing_tools: Dictionary = actions.request_action(actor_id, target, Actions.REPAIR)
    _check(not bool(missing_tools.get("accepted", true)) and String(missing_tools.get("reason", "")) == "generator_repair_requires_wrench", "repair failure reports missing physical tool")

    const WRENCH_ID := "ci.generator.wrench"
    const SCRAP_ID := "ci.generator.scrap"
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.tool.adjustable_wrench", WRENCH_ID), "repair wrench carried")
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.material.scrap_metal", SCRAP_ID), "repair reclaimed metal scrap carried")
    pointer.world_cell_primary.emit(world.placement(target).anchor)
    await process_frame
    _check(_world_button(panel, target, Actions.REPAIR) != null, "damaged stopped generator exposes REPAIR")
    _check(_world_button(panel, target, Actions.START) == null, "damaged generator hides START")
    panel.close_panel()
    var before_repair_tick: int = kernel.world_tick()
    var repair_request: Dictionary = actions.request_action(actor_id, target, Actions.REPAIR)
    _check(bool(repair_request.get("accepted", false)), "Mechanical repair owner accepts real prerequisites: %s" % String(repair_request.get("reason", "unknown")))
    if bool(repair_request.get("accepted", false)):
        kernel.run_until_stop()
    _check(kernel.world_tick() > before_repair_tick, "Mechanical repair spends real WHEN time")
    _check(int(generators.record(target).get("condition", 0)) == PortableGeneratorState.MAX_CONDITION, "Mechanical repair restores owning condition")
    _check(world.has_entity(WRENCH_ID) and inventory.is_contained(WRENCH_ID), "repair retains exact wrench")
    _check(not world.has_entity(SCRAP_ID), "repair consumes exact metal scrap")
    _check(utilities.set_power_component_state(branch_id, UtilityRuntimeState.OPERATIONAL, &"generator_ci_grid_restore"), "protected grid service restores")
    _finish()

func _place_actor_facing(world: WorldState, mutations: WorldMutationService, actor_id: String, target_id: String) -> bool:
    var actor: WorldPlacement = world.placement(actor_id)
    var target: WorldPlacement = world.placement(target_id)
    if actor == null or target == null or actor.footprint == null:
        return false
    for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
        var actor_cell: Vector2i = target.anchor - direction
        var facing: int = Facing.from_vector(direction)
        if facing >= 0 and world.has_terrain(actor_cell) \
            and mutations.set_placement(actor_id, actor.channel, actor_cell, facing, actor.footprint):
            return true
    return false

func _empty_nearby_cell(world: WorldState, actor_id: String) -> Vector2i:
    var actor: WorldPlacement = world.placement(actor_id)
    if actor == null:
        return Vector2i(2147483647, 2147483647)
    for radius: int in range(1, 8):
        for y: int in range(actor.anchor.y - radius, actor.anchor.y + radius + 1):
            for x: int in range(actor.anchor.x - radius, actor.anchor.x + radius + 1):
                var cell := Vector2i(x, y)
                if not world.has_terrain(cell):
                    continue
                var occupied: bool = false
                for channel: int in [Layers.Channel.OBJECT, Layers.Channel.STRUCTURE, Layers.Channel.ACTOR]:
                    if not world.entities_at(cell, channel).is_empty():
                        occupied = true
                        break
                if not occupied:
                    return cell
    return Vector2i(2147483647, 2147483647)

func _give_item(world: WorldState, mutations: WorldMutationService, inventory_mutations: InventoryContainmentMutationService, actor_id: String, semantic: StringName, item_id: String) -> bool:
    if world.has_entity(item_id) or mutations.create_entity(semantic, item_id) != item_id:
        return false
    if inventory_mutations.set_container(item_id, actor_id):
        return true
    mutations.remove_entity(item_id)
    return false

func _world_button(root: Node, target_id: String, action_id: StringName) -> Button:
    var button := root as Button
    if button != null and String(button.get_meta("world_target_id", "")) == target_id \
        and String(button.get_meta("world_action_id", "")) == String(action_id):
        return button
    for child: Node in root.get_children():
        var found: Button = _world_button(child, target_id, action_id)
        if found != null:
            return found
    return null

func _has_emitter(emitters: Array[LightEmitter], emitter_id: String) -> bool:
    for emitter: LightEmitter in emitters:
        if emitter != null and emitter.emitter_id == emitter_id:
            return true
    return false

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("PORTABLE_GENERATOR_UI_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PORTABLE_GENERATOR_UI_SMOKE_FAIL: %s" % failure)
    quit(1)
