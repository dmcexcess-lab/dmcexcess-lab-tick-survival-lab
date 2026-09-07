extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const GeneratorActions = preload("res://scripts/simulation/utilities/PortableGeneratorActionService.gd")

const GENERATOR_ID: String = "prop.prompt.generator.001"
const GAS_CAN_ID: String = "item.prompt.generator.gas_can.001"

var _failures: Array[String] = []
var _last_result: Dictionary = {}

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
    var controller: WorldInteractionPlayerController = game.get("_world_interaction_controller")
    var panel: WorldInteractionPanel = game.get("_world_interaction_panel")
    var generators: PortableGeneratorState = game.get("_portable_generators")
    var utilities: UtilityRuntimeState = game.get("_utilities")
    var kernel: TickKernel = game.get("_kernel")
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations")

    _expect(world != null and mutations != null, "authoritative production world owners are ready")
    _expect(reach != null and reach.is_ready(), "ordinary world interaction reach query is ready")
    _expect(controller != null and controller.is_ready() and panel != null, "ordinary production world chooser is ready")
    _expect(generators != null and utilities != null and utilities.is_ready(), "portable generator and System-33 utility owners are ready")
    _expect(kernel != null and inventory_mutations != null and inventory_mutations.is_ready(), "WHEN and exact carried-item mutation owners are ready")
    if not _failures.is_empty():
        game.queue_free()
        _finish()
        return

    controller.action_finished.connect(_on_action_finished)

    var player: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    _expect(player != null, "production player has authoritative placement")
    if player == null:
        game.queue_free()
        _finish()
        return

    var target_cell: Vector2i = _pick_reachable_object_cell(world, reach, player)
    _expect(target_cell != Vector2i(2147483647, 2147483647), "focused fixture found one reachable generator test cell")
    if target_cell == Vector2i(2147483647, 2147483647):
        game.queue_free()
        _finish()
        return

    _expect(mutations.create_entity(PortableGeneratorState.SEMANTIC, GENERATOR_ID) == GENERATOR_ID, "creates one exact persistent portable generator WHAT for focused play-path setup")
    _expect(mutations.set_placement(GENERATOR_ID, Layers.Channel.OBJECT, target_cell, player.facing, Footprint.single_cell()), "places exact generator on ordinary reachable OBJECT channel")
    await process_frame
    _expect(generators.has_generator(GENERATOR_ID), "production generator enrollment observes the exact placed WHAT entity")
    var record: Dictionary = generators.record(GENERATOR_ID)
    var service_id: String = String(record.get("power_service_id", ""))
    var scope_id: String = String(record.get("power_scope_id", ""))
    _expect(not service_id.is_empty() and not scope_id.is_empty(), "generator binds to authoritative System-33 service and local scope")

    var branch_id: String = utilities.power_branch_component_id(service_id)
    _expect(not branch_id.is_empty(), "generator's canonical service has a local grid branch")
    if not branch_id.is_empty():
        _expect(utilities.set_power_component_state(branch_id, UtilityRuntimeState.DISABLED, &"prompt_generator_grid_outage"), "focused setup disables only the generator service's authoritative grid branch")
    _expect(not utilities.power_service_available(service_id), "grid service is genuinely unavailable before generator start")
    _expect(not utilities.power_service_available_for_scope(service_id, scope_id), "local scope is also unpowered while generator is stopped")

    # Ordinary click exposes status and REFUEL while START/STOP remain truthfully unavailable.
    controller.submit_world_cell(target_cell)
    var inspect_button: Button = _find_action_button(panel, GENERATOR_ID, GeneratorActions.INSPECT)
    var refuel_button: Button = _find_action_button(panel, GENERATOR_ID, GeneratorActions.REFUEL)
    _expect(inspect_button != null and inspect_button.text.contains("OFF") and inspect_button.text.contains("FUEL 0/240"), "ordinary generator chooser exposes truthful OFF / empty-fuel status")
    _expect(refuel_button != null, "ordinary generator chooser exposes REFUEL")
    _expect(_find_action_button(panel, GENERATOR_ID, GeneratorActions.START) == null, "START is not offered while fuel is empty")
    _expect(_find_action_button(panel, GENERATOR_ID, GeneratorActions.STOP) == null, "STOP is not offered while generator is stopped")

    _last_result.clear()
    if inspect_button != null:
        inspect_button.emit_signal("pressed")
    _expect(bool(_last_result.get("success", false)) and StringName(_last_result.get("action_id", &"")) == GeneratorActions.INSPECT, "INSPECT completes through ordinary chooser and authoritative WHEN")
    await process_frame

    # REFUEL without the required exact carried fuel item must fail truthfully through the same UI route.
    controller.submit_world_cell(target_cell)
    refuel_button = _find_action_button(panel, GENERATOR_ID, GeneratorActions.REFUEL)
    _last_result.clear()
    if refuel_button != null:
        refuel_button.emit_signal("pressed")
    _expect(not bool(_last_result.get("success", true)) and String(_last_result.get("reason", "")) == "generator_refuel_requires_gas_can", "ordinary REFUEL reports missing gas can truthfully")
    _expect(int(generators.record(GENERATOR_ID).get("fuel_ticks", -1)) == 0, "failed refuel does not mutate generator fuel")
    await process_frame

    # Add one real persistent gas-can item to authoritative carried containment.
    _expect(mutations.create_entity(GeneratorActions.GAS_CAN, GAS_CAN_ID) == GAS_CAN_ID, "creates one exact persistent gas-can item for focused setup")
    _expect(inventory_mutations.set_container(GAS_CAN_ID, Fixture.PLAYER_ID), "gas can is carried through authoritative containment")
    controller.submit_world_cell(target_cell)
    refuel_button = _find_action_button(panel, GENERATOR_ID, GeneratorActions.REFUEL)
    _expect(refuel_button != null, "REFUEL remains ordinarily reachable with required fuel item carried")
    _last_result.clear()
    if refuel_button != null:
        refuel_button.emit_signal("pressed")
    _expect(bool(_last_result.get("success", false)) and StringName(_last_result.get("action_id", &"")) == GeneratorActions.REFUEL, "REFUEL completes through ordinary chooser and timed generator action")
    _expect(int(generators.record(GENERATOR_ID).get("fuel_ticks", 0)) == PortableGeneratorState.MAX_FUEL_TICKS, "successful refuel fills authoritative generator fuel")
    _expect(not world.has_entity(GAS_CAN_ID), "successful refuel consumes the exact carried gas-can entity")
    _expect(not utilities.power_service_available_for_scope(service_id, scope_id), "fueled but stopped generator still supplies no local power")
    await process_frame

    # START becomes reachable only after real fuel exists and contributes local power without healing grid truth.
    controller.submit_world_cell(target_cell)
    var start_button: Button = _find_action_button(panel, GENERATOR_ID, GeneratorActions.START)
    _expect(start_button != null, "ordinary chooser exposes START after refuel")
    _last_result.clear()
    if start_button != null:
        start_button.emit_signal("pressed")
    record = generators.record(GENERATOR_ID)
    _expect(bool(_last_result.get("success", false)) and StringName(_last_result.get("action_id", &"")) == GeneratorActions.START, "START completes through ordinary chooser and authoritative WHEN")
    _expect(bool(record.get("running", false)), "authoritative generator state is running after START")
    _expect(not utilities.power_service_available(service_id), "starting generator does not fake-repair the failed canonical grid branch")
    _expect(utilities.power_service_available_for_scope(service_id, scope_id), "running generator contributes power through System-33 local-power provider")
    await process_frame

    controller.submit_world_cell(target_cell)
    inspect_button = _find_action_button(panel, GENERATOR_ID, GeneratorActions.INSPECT)
    var stop_button: Button = _find_action_button(panel, GENERATOR_ID, GeneratorActions.STOP)
    _expect(inspect_button != null and inspect_button.text.contains("ON"), "ordinary status reports generator ON while running")
    _expect(stop_button != null, "ordinary chooser exposes STOP while running")
    _expect(_find_action_button(panel, GENERATOR_ID, GeneratorActions.REFUEL) == null, "REFUEL is not offered while generator is running")
    _expect(_find_action_button(panel, GENERATOR_ID, GeneratorActions.START) == null, "START is not offered while generator is already running")

    var fuel_before_stop: int = int(record.get("fuel_ticks", 0))
    _last_result.clear()
    if stop_button != null:
        stop_button.emit_signal("pressed")
    record = generators.record(GENERATOR_ID)
    _expect(bool(_last_result.get("success", false)) and StringName(_last_result.get("action_id", &"")) == GeneratorActions.STOP, "STOP completes through ordinary chooser and authoritative WHEN")
    _expect(not bool(record.get("running", true)), "authoritative generator state is stopped after STOP")
    _expect(int(record.get("fuel_ticks", fuel_before_stop)) < fuel_before_stop, "running generator fuel is consumed only as WHEN advances")
    _expect(not utilities.power_service_available_for_scope(service_id, scope_id), "STOP removes generator local-power contribution immediately")
    _expect(not utilities.power_service_available(service_id), "canonical grid outage remains unchanged after generator stop")

    game.queue_free()
    await process_frame
    _finish()

func _pick_reachable_object_cell(world: WorldState, reach: WorldInteractionReachQuery, player: WorldPlacement) -> Vector2i:
    var cells: Array[Vector2i] = reach.reachable_cells(Fixture.PLAYER_ID, WorldInteractionReachQuery.CONTACT_FORWARD)
    for cell: Vector2i in cells:
        if cell == player.anchor or not world.has_terrain(cell):
            continue
        if world.entities_at(cell, Layers.Channel.OBJECT).is_empty():
            return cell
    # Prefer the actual forward cell as a final focused-fixture fallback; WHAT placement itself remains authoritative.
    var forward: Vector2i = player.anchor + Facing.vector(player.facing)
    if world.has_terrain(forward):
        return forward
    return Vector2i(2147483647, 2147483647)

func _find_action_button(root_node: Node, target_id: String, action_id: StringName) -> Button:
    if root_node == null:
        return null
    for child: Node in root_node.get_children():
        if child is Button and not child.is_queued_for_deletion() \
            and child.has_meta("world_target_id") and child.has_meta("world_action_id") \
            and String(child.get_meta("world_target_id")) == target_id \
            and StringName(child.get_meta("world_action_id")) == action_id:
            return child as Button
        var nested: Button = _find_action_button(child, target_id, action_id)
        if nested != null:
            return nested
    return null

func _on_action_finished(target_id: String, action_id: StringName, success: bool, reason: String) -> void:
    if target_id != GENERATOR_ID:
        return
    _last_result = {
        "target_id": target_id,
        "action_id": action_id,
        "success": success,
        "reason": reason,
    }

func _expect(condition: bool, message: String) -> void:
    if condition:
        print("PASS: %s" % message)
        return
    _failures.append(message)
    push_error("FAIL: %s" % message)

func _finish() -> void:
    if _failures.is_empty():
        print("PROMPT_GENERATOR_OPERATION_SMOKE: PASS")
        quit(0)
        return
    push_error("PROMPT_GENERATOR_OPERATION_SMOKE: FAIL (%d)" % _failures.size())
    for failure: String in _failures:
        push_error(" - %s" % failure)
    quit(1)
