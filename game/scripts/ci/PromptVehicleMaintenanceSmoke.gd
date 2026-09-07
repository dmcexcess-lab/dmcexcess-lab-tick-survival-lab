extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Profiles = preload("res://scripts/simulation/vehicles/VehicleProfileCatalog.gd")
const Actions = preload("res://scripts/simulation/vehicles/VehicleActionService.gd")
const Skills = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")

const TARGET_ID: String = "vehicle.prompt.maintenance.target"
const DECOY_ID: String = "vehicle.prompt.maintenance.decoy"
const FAR_ID: String = "vehicle.prompt.maintenance.far"
const WRENCH_ID: String = "item.prompt.maintenance.wrench"
const PART_ID: String = "item.prompt.maintenance.part"
const GAS_ID: String = "item.prompt.maintenance.gas"
const RACK_ID: String = "item.prompt.maintenance.rack"

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
    var state: VehicleState = game.get("_vehicle_state")
    var profiles: VehicleProfileCatalog = game.get("_vehicle_profiles")
    var actions: VehicleActionService = game.get("_vehicle_actions")
    var handler: VehicleMaintenancePlayerInteractionHandler = game.get("_vehicle_maintenance_handler")
    var skill_state: ActorSkillState = game.get("_skill_state")
    var inventory: InventoryContainmentState = game.get("_inventory_state")
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations")
    var vehicle_controls: VehiclePlayerControls = game.get("_vehicle_controls")

    _expect(world != null and mutations != null, "authoritative world owners are ready")
    _expect(reach != null and reach.is_ready(), "ordinary interaction reach is ready")
    _expect(controller != null and controller.is_ready() and panel != null, "ordinary click-menu chooser is ready")
    _expect(state != null and profiles != null and actions != null and actions.is_ready(), "authoritative vehicle owners are ready")
    _expect(handler != null and handler.is_ready(), "exact-target on-foot maintenance handler is ready")
    _expect(skill_state != null and inventory != null and inventory_mutations != null and inventory_mutations.is_ready(), "skill and carried-item owners are ready")
    _expect(vehicle_controls != null and vehicle_controls.find_child("HotwireButton", true, false) is Button, "mounted driving controls still own HOTWIRE button")
    if not _failures.is_empty():
        game.queue_free()
        _finish()
        return

    controller.action_finished.connect(_on_action_finished)

    var player: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    _expect(player != null, "player has authoritative placement")
    if player == null:
        game.queue_free()
        _finish()
        return

    var fixture_cells: Array[Vector2i] = _pick_fixture_cells(world, player.anchor)
    _expect(fixture_cells.size() >= 2, "found two nearby clear vehicle fixture cells")
    if fixture_cells.size() < 2:
        game.queue_free()
        _finish()
        return
    var decoy_cell: Vector2i = fixture_cells[0]
    var target_cell: Vector2i = fixture_cells[1]

    _expect(_create_test_car(world, mutations, inventory_mutations, state, profiles, DECOY_ID, decoy_cell, 0), "created deliberately nearer decoy car")
    _expect(_create_test_car(world, mutations, inventory_mutations, state, profiles, TARGET_ID, target_cell, 0), "created exact clicked maintenance target car")
    _expect(state.mutate(DECOY_ID, {"body": 35, "propulsion": 45, "wheels": 55, "electrical": 65}), "damaged decoy state for exact-target proof")
    _expect(state.mutate(TARGET_ID, {"body": 40, "propulsion": 50, "wheels": 60, "electrical": 70}), "damaged target state for maintenance menu")

    var decoy_before: Dictionary = state.record(DECOY_ID)
    var target_before: Dictionary = state.record(TARGET_ID)

    # On foot, clicking the exact vehicle opens the normal interaction menu with only
    # on-foot maintenance actions. HOTWIRE is intentionally not part of this menu.
    controller.submit_world_cell(target_cell)
    _expect(_find_action_button(panel, TARGET_ID, Actions.REPAIR) != null, "vehicle click menu exposes REPAIR for damaged exact target")
    _expect(_find_action_button(panel, TARGET_ID, Actions.REFUEL) != null, "vehicle click menu exposes REFUEL for non-full motor vehicle")
    var rack_button: Button = _find_action_button(panel, TARGET_ID, Actions.MODIFY)
    _expect(rack_button != null and rack_button.text == "ADD RACK", "vehicle click menu exposes ADD RACK")
    _expect(_find_action_button(panel, TARGET_ID, Actions.HOTWIRE) == null, "on-foot vehicle click menu never exposes HOTWIRE")

    var unmounted_hotwire: Dictionary = actions.request_hotwire(Fixture.PLAYER_ID, TARGET_ID)
    _expect(not bool(unmounted_hotwire.get("accepted", false)) and String(unmounted_hotwire.get("reason", "")) == "not_mounted", "authoritative HOTWIRE rejects an unmounted actor")

    _press_and_expect_failure(controller, panel, target_cell, TARGET_ID, Actions.REPAIR, "repair_requires_wrench")
    _press_and_expect_failure(controller, panel, target_cell, TARGET_ID, Actions.REFUEL, "refuel_requires_gas_can")
    _press_and_expect_failure(controller, panel, target_cell, TARGET_ID, Actions.MODIFY, "modify_requires_wrench_and_cargo_rack")

    _expect(_carry_item(mutations, inventory_mutations, &"item.tool.adjustable_wrench", WRENCH_ID), "carries exact wrench through authoritative containment")
    _expect(_carry_item(mutations, inventory_mutations, &"item.crafting.metal_scrap", PART_ID), "carries exact repair part through authoritative containment")
    _expect(skill_state.remove_actor(Fixture.PLAYER_ID), "focused setup removes Mechanical classification")
    _press_and_expect_failure(controller, panel, target_cell, TARGET_ID, Actions.REPAIR, "skill_actor_unclassified")
    _expect(skill_state.enroll_actor(Fixture.PLAYER_ID), "focused setup restores player skill classification")
    _expect(skill_state.set_skill(Fixture.PLAYER_ID, Skills.MECHANICAL, Skills.LEVEL_MAX, 0), "sets focused Mechanical skill high enough for deterministic maintenance success")

    _last_result.clear()
    controller.submit_world_cell(target_cell)
    var repair_button: Button = _find_action_button(panel, TARGET_ID, Actions.REPAIR)
    _expect(repair_button != null, "REPAIR remains reachable after prerequisites are supplied")
    if repair_button != null:
        repair_button.emit_signal("pressed")
    _expect(bool(_last_result.get("success", false)) and StringName(_last_result.get("action_id", &"")) == Actions.REPAIR, "on-foot REPAIR resolves successfully through exact-target delegated handler")
    var target_after_repair: Dictionary = state.record(TARGET_ID)
    _expect(int(target_after_repair.get("body", 0)) > int(target_before.get("body", 0)), "clicked target receives repair condition gain")
    _expect(_same_condition(state.record(DECOY_ID), decoy_before), "nearer decoy vehicle is untouched by clicked-target repair")
    _expect(world.has_entity(WRENCH_ID) and inventory.direct_contents(Fixture.PLAYER_ID).has(WRENCH_ID), "repair retains exact wrench")
    _expect(not world.has_entity(PART_ID), "repair consumes exact carried part")

    _expect(_carry_item(mutations, inventory_mutations, &"item.automotive.gas_can", GAS_ID), "carries exact gas can")
    _last_result.clear()
    controller.submit_world_cell(target_cell)
    var refuel_button: Button = _find_action_button(panel, TARGET_ID, Actions.REFUEL)
    _expect(refuel_button != null, "REFUEL remains reachable with exact gas can")
    if refuel_button != null:
        refuel_button.emit_signal("pressed")
    _expect(bool(_last_result.get("success", false)) and StringName(_last_result.get("action_id", &"")) == Actions.REFUEL, "on-foot REFUEL resolves successfully")
    _expect(int(state.record(TARGET_ID).get("fuel", -1)) == profiles.max_fuel(Profiles.CAR), "clicked target receives full authoritative fuel")
    _expect(int(state.record(DECOY_ID).get("fuel", -1)) == 0, "nearer decoy fuel is unchanged")
    _expect(not world.has_entity(GAS_ID), "refuel consumes exact carried gas-can entity")

    _expect(_carry_item(mutations, inventory_mutations, &"item.automotive.cargo_rack", RACK_ID), "carries exact cargo rack")
    _last_result.clear()
    controller.submit_world_cell(target_cell)
    rack_button = _find_action_button(panel, TARGET_ID, Actions.MODIFY)
    _expect(rack_button != null, "ADD RACK remains reachable with exact rack and wrench")
    if rack_button != null:
        rack_button.emit_signal("pressed")
    var target_after_rack: Dictionary = state.record(TARGET_ID)
    _expect(bool(_last_result.get("success", false)) and StringName(_last_result.get("action_id", &"")) == Actions.MODIFY, "on-foot ADD RACK resolves successfully")
    _expect(&"cargo_rack" in target_after_rack.get("mods", []), "clicked target owns cargo-rack modification")
    _expect(inventory.container_of(RACK_ID) == TARGET_ID, "exact physical rack becomes contained by clicked vehicle")
    _expect(&"cargo_rack" not in state.record(DECOY_ID).get("mods", []), "nearer decoy does not receive clicked-target rack")

    controller.submit_world_cell(target_cell)
    _expect(_find_action_button(panel, TARGET_ID, Actions.REFUEL) == null, "full vehicle no longer offers REFUEL")
    _expect(_find_action_button(panel, TARGET_ID, Actions.MODIFY) == null, "racked vehicle no longer offers ADD RACK")
    _expect(_find_action_button(panel, TARGET_ID, Actions.HOTWIRE) == null, "HOTWIRE remains absent from on-foot click menu")

    var far_cell: Vector2i = _find_far_clear_cell(world, player.anchor)
    _expect(far_cell != Vector2i(2147483647, 2147483647), "found far clear vehicle fixture cell")
    if far_cell != Vector2i(2147483647, 2147483647):
        _expect(_create_test_car(world, mutations, inventory_mutations, state, profiles, FAR_ID, far_cell, 0), "created out-of-reach vehicle fixture")
        var far_result: Dictionary = handler.request_action(Fixture.PLAYER_ID, FAR_ID, Actions.REFUEL)
        _expect(not bool(far_result.get("success", false)) and String(far_result.get("reason", "")) == "vehicle_out_of_reach", "out-of-reach exact vehicle is rejected truthfully")

    var missing_result: Dictionary = handler.request_action(Fixture.PLAYER_ID, "vehicle.prompt.missing", Actions.REFUEL)
    _expect(not bool(missing_result.get("success", false)) and String(missing_result.get("reason", "")) == "vehicle_target_missing", "missing exact vehicle is rejected truthfully")

    _expect(state.set_driver(TARGET_ID, Fixture.PLAYER_ID), "focused setup marks actor mounted for menu gating check")
    var mounted_result: Dictionary = handler.request_action(Fixture.PLAYER_ID, TARGET_ID, Actions.REPAIR)
    _expect(not bool(mounted_result.get("success", false)) and String(mounted_result.get("reason", "")) == "vehicle_maintenance_requires_unmounted", "on-foot maintenance route rejects mounted actor")
    controller.submit_world_cell(target_cell)
    _expect(_find_action_button(panel, TARGET_ID, Actions.REPAIR) == null and _find_action_button(panel, TARGET_ID, Actions.REFUEL) == null and _find_action_button(panel, TARGET_ID, Actions.MODIFY) == null, "mounted actor receives no on-foot maintenance click menu")
    _expect(state.clear_driver(TARGET_ID), "focused setup restores unmounted state")

    game.queue_free()
    await process_frame
    _finish()

func _create_test_car(
    world: WorldState,
    mutations: WorldMutationService,
    inventory_mutations: InventoryContainmentMutationService,
    state: VehicleState,
    profiles: VehicleProfileCatalog,
    vehicle_id: String,
    cell: Vector2i,
    fuel: int
) -> bool:
    if mutations.create_entity(profiles.semantic_type(Profiles.CAR), vehicle_id) != vehicle_id:
        return false
    if not mutations.set_placement(vehicle_id, Layers.Channel.OBJECT, cell, Facing.Value.NORTH, Footprint.single_cell()):
        return false
    if not inventory_mutations.enroll_container(vehicle_id):
        return false
    return state.create_vehicle(vehicle_id, Profiles.CAR, fuel, false, 0, false)

func _carry_item(
    mutations: WorldMutationService,
    inventory_mutations: InventoryContainmentMutationService,
    semantic: StringName,
    item_id: String
) -> bool:
    if mutations.create_entity(semantic, item_id) != item_id:
        return false
    return inventory_mutations.set_container(item_id, Fixture.PLAYER_ID)

func _pick_fixture_cells(world: WorldState, anchor: Vector2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for cell: Vector2i in [anchor, anchor + Vector2i.UP, anchor + Vector2i.RIGHT, anchor + Vector2i.DOWN, anchor + Vector2i.LEFT]:
        if not world.has_terrain(cell) or not world.entities_at(cell, Layers.Channel.OBJECT).is_empty():
            continue
        result.append(cell)
        if result.size() >= 2:
            break
    return result

func _find_far_clear_cell(world: WorldState, anchor: Vector2i) -> Vector2i:
    for distance: int in range(6, 25):
        for delta: Vector2i in [Vector2i(distance, 0), Vector2i(-distance, 0), Vector2i(0, distance), Vector2i(0, -distance)]:
            var cell: Vector2i = anchor + delta
            if world.has_terrain(cell) and world.entities_at(cell, Layers.Channel.OBJECT).is_empty():
                return cell
    return Vector2i(2147483647, 2147483647)

func _press_and_expect_failure(
    controller: WorldInteractionPlayerController,
    panel: WorldInteractionPanel,
    target_cell: Vector2i,
    target_id: String,
    action_id: StringName,
    expected_reason: String
) -> void:
    _last_result.clear()
    controller.submit_world_cell(target_cell)
    var button: Button = _find_action_button(panel, target_id, action_id)
    _expect(button != null, "%s button is present for prerequisite failure check" % String(action_id))
    if button != null:
        button.emit_signal("pressed")
    _expect(not bool(_last_result.get("success", true)) and String(_last_result.get("reason", "")) == expected_reason, "%s reports %s truthfully" % [String(action_id), expected_reason])

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

func _same_condition(a: Dictionary, b: Dictionary) -> bool:
    for field_name: String in ["body", "propulsion", "wheels", "electrical", "fuel"]:
        if int(a.get(field_name, -1)) != int(b.get(field_name, -1)):
            return false
    return true

func _on_action_finished(target_id: String, action_id: StringName, success: bool, reason: String) -> void:
    if target_id != TARGET_ID:
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
        print("PROMPT_VEHICLE_MAINTENANCE_SMOKE: PASS")
        quit(0)
        return
    push_error("PROMPT_VEHICLE_MAINTENANCE_SMOKE: FAIL (%d)" % _failures.size())
    for failure: String in _failures:
        push_error(" - %s" % failure)
    quit(1)
