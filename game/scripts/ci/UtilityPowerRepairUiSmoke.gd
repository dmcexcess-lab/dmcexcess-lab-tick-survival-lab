extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const ConditionStore = preload("res://scripts/simulation/utilities/UtilityNetworkConditionStore.gd")
const RepairActions = preload("res://scripts/simulation/utilities/UtilityPowerRepairActionService.gd")

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
    var utilities: UtilityRuntimeState = game.get("_utilities")
    var network: UtilityPowerNetworkRuntime = game.get("_power_network")
    var repair_actions: UtilityPowerRepairActionService = game.get("_utility_power_repair_actions")
    var controller: WorldInteractionPlayerController = game.get("_world_interaction_controller")
    var panel: WorldInteractionPanel = game.get("_world_interaction_panel")
    var pointer: DoorPointerInputAdapter = game.get("_door_pointer")

    _check(world != null and mutations != null and spatial != null and kernel != null, "world/WHEN owners available")
    _check(skills != null and inventory != null and inventory_mutations != null, "skill/inventory owners available")
    _check(utilities != null and network != null and network.is_ready(), "canonical utility network owner ready")
    _check(repair_actions != null and repair_actions.is_ready(), "player utility repair owner ready")
    _check(controller != null and controller.is_ready() and panel != null and pointer != null, "unified player interaction route ready")
    if not failures.is_empty():
        _finish()
        return

    var actor_id: String = Fixture.PLAYER_ID
    _check(skills.set_skill(actor_id, SkillCatalog.MECHANICAL, 10, 0), "Mechanical set to expert")

    var target: String = _find_reachable_wood_support(world, mutations, spatial, network, actor_id)
    _check(not target.is_empty(), "physical wood distribution support reachable")
    if target.is_empty():
        _finish()
        return

    var before_asset: Dictionary = network.asset_record(target)
    _check(StringName(before_asset.get("kind", &"")) == ConditionStore.DISTRIBUTION_SUPPORT, "target is canonical distribution support")
    _check(String(before_asset.get("entity_id", "")) == target, "utility asset maps to clicked WHAT entity")
    var requirements: Dictionary = network.repair_requirements(target)
    _check(int(requirements.get("mechanical_skill", -1)) == 2, "owner Mechanical requirement preserved")
    _check(int(requirements.get("material_units", -1)) == 2, "owner material-unit requirement preserved")

    var affected_services: Array[String] = []
    for value: Variant in before_asset.get("affected_services", []):
        affected_services.append(String(value))
    _check(not affected_services.is_empty(), "support affects real power service")

    _check(network.damage_asset(target, 1000, &"ci_player_repair"), "canonical owner accepts physical support damage")
    var failed_asset: Dictionary = network.asset_record(target)
    _check(bool(failed_asset.get("failed", false)), "support reaches canonical failed state")
    if not affected_services.is_empty():
        _check(not utilities.power_service_available(affected_services[0]), "support failure causes real outage")

    const HAMMER_ID := "ci.utility.repair.hammer"
    const PLANK_A_ID := "ci.utility.repair.plank.a"
    const PLANK_B_ID := "ci.utility.repair.plank.b"
    const NAILS_ID := "ci.utility.repair.nails"
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.tool.hammer", HAMMER_ID), "real hammer carried")
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.material.wood_plank", PLANK_A_ID), "first real plank carried")
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.material.wood_plank", PLANK_B_ID), "second real plank carried")
    _check(_give_item(world, mutations, inventory_mutations, actor_id, &"item.material.nails_box", NAILS_ID), "real fasteners carried")

    var resolved: Array[Dictionary] = []
    controller.action_finished.connect(func(target_id, action_id, success, reason):
        resolved.append({"target": target_id, "action": String(action_id), "success": success, "reason": reason})
    )

    await process_frame
    var before_tick: int = kernel.world_tick()
    pointer.world_cell_primary.emit(world.placement(target).anchor)
    await process_frame
    var repair_button: Button = _world_button(panel, target, RepairActions.ACTION_ID)
    _check(panel.is_open() and repair_button != null, "failed pole chooser exposes real REPAIR POWER POLE")
    if repair_button != null:
        repair_button.pressed.emit()

    var repaired_asset: Dictionary = network.asset_record(target)
    _check(not bool(repaired_asset.get("failed", true)), "repair commits canonical utility condition")
    _check(int(repaired_asset.get("derived_condition", 0)) == int(requirements.get("restored_condition", -1)), "owner restored condition is preserved")
    _check(kernel.world_tick() > before_tick, "utility repair spends real WHEN time")
    _check(world.has_entity(HAMMER_ID) and inventory.is_contained(HAMMER_ID), "hammer is retained and carried")
    _check(not world.has_entity(PLANK_A_ID) and not world.has_entity(PLANK_B_ID), "two exact planks are consumed")
    _check(not world.has_entity(NAILS_ID), "exact nails box is consumed")
    if not affected_services.is_empty():
        _check(utilities.power_service_available(affected_services[0]), "repair restores real affected power service")

    var saw_success: bool = false
    for entry: Dictionary in resolved:
        if String(entry.get("target", "")) == target \
            and String(entry.get("action", "")) == String(RepairActions.ACTION_ID) \
            and bool(entry.get("success", false)):
            saw_success = true
            break
    _check(saw_success, "unified controller reports exact successful utility repair completion")

    await process_frame
    pointer.world_cell_primary.emit(world.placement(target).anchor)
    await process_frame
    _check(_world_button(panel, target, RepairActions.ACTION_ID) == null, "healthy pole no longer exposes repair")

    _finish()

func _find_reachable_wood_support(
    world: WorldState,
    mutations: WorldMutationService,
    spatial: SpatialQueryService,
    network: UtilityPowerNetworkRuntime,
    actor_id: String
) -> String:
    for target_id: String in network.asset_ids(ConditionStore.DISTRIBUTION_SUPPORT):
        if not world.has_entity(target_id):
            continue
        var entity: WorldEntityRecord = world.entity(target_id)
        if entity == null or entity.semantic_type != RepairActions.SUPPORTED_SEMANTIC:
            continue
        if _place_actor_facing(world, mutations, spatial, actor_id, target_id):
            return target_id
    return ""

func _place_actor_facing(
    world: WorldState,
    mutations: WorldMutationService,
    _spatial: SpatialQueryService,
    actor_id: String,
    target_id: String
) -> bool:
    var actor: WorldPlacement = world.placement(actor_id)
    var target: WorldPlacement = world.placement(target_id)
    if actor == null or target == null or actor.footprint == null:
        return false
    var target_cell: Vector2i = target.anchor
    for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
        var actor_cell: Vector2i = target_cell - direction
        var facing: int = Facing.from_vector(direction)
        if facing < 0 or not world.has_terrain(actor_cell):
            continue
        if mutations.set_placement(actor_id, actor.channel, actor_cell, facing, actor.footprint):
            return true
    return false

func _give_item(
    world: WorldState,
    mutations: WorldMutationService,
    inventory_mutations: InventoryContainmentMutationService,
    actor_id: String,
    semantic: StringName,
    item_id: String
) -> bool:
    if world.has_entity(item_id):
        return false
    if mutations.create_entity(semantic, item_id) != item_id:
        return false
    if inventory_mutations.set_container(item_id, actor_id):
        return true
    mutations.remove_entity(item_id)
    return false

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

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("UTILITY_POWER_REPAIR_UI_SMOKE_OK")
        if game != null:
            game.queue_free()
        quit(0)
        return
    for failure: String in failures:
        push_error("UTILITY_POWER_REPAIR_UI_SMOKE_FAIL: %s" % failure)
    if game != null:
        game.queue_free()
    quit(1)
