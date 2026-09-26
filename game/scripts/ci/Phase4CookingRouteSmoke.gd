extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StoreClass = preload("res://scripts/persistence/DurableSessionStore.gd")
const ConditionState = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")

const PRIMARY := "user://phase4_cooking_route.save"
const BACKUP := "user://phase4_cooking_route.backup.save"
const TEMP := "user://phase4_cooking_route.tmp.save"
const SOUP_ID := "item.phase4.canned_soup.001"
const POT_ID := "item.phase4.cooking_pot.001"
const RECIPE := &"cooking.heated_soup"
const HEATED_SOUP := &"item.crafting.heated_soup"

var _craft_result: Dictionary = {}

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE4_COOKING_ROUTE: " + message)
    quit(1)

func _cleanup() -> void:
    for path: String in [PRIMARY, BACKUP, TEMP]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _boot(session: Dictionary = {}) -> Node:
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("production gameplay scene missing")
        return null
    var game: Node = scene.instantiate()
    if game == null or not game.call("configure_session_paths", PRIMARY, BACKUP, TEMP):
        _fail("production session path configuration unavailable")
        return null
    if not session.is_empty() and not game.call("configure_continue_session", session):
        _fail("valid saved session rejected")
        return null
    get_root().add_child(game)
    await process_frame
    await process_frame
    await process_frame
    if not bool(game.call("session_boot_ok")):
        _fail("production gameplay boot failed: %s" % String(game.call("session_boot_error")))
        return null
    var adapter: Node = game.get_node_or_null("PoweredCraftingWorkstationAdapter")
    if adapter == null or not bool(adapter.call("is_bound")):
        _fail("powered workstation bridge did not bind existing owners")
        return null
    return game

func _on_craft_resolved(recipe_id: StringName, success: bool, reason: String, world_tick: int, workstation_id: String) -> void:
    _craft_result = {
        "recipe_id": recipe_id,
        "success": success,
        "reason": reason,
        "world_tick": world_tick,
        "workstation_id": workstation_id,
    }

func _run() -> void:
    _cleanup()
    var game: Node = await _boot()
    if game == null:
        return

    var world: WorldState = game.get("_world") as WorldState
    var mutations: WorldMutationService = game.get("_world_mutations") as WorldMutationService
    var inventory: InventoryContainmentState = game.get("_inventory_state") as InventoryContainmentState
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations") as InventoryContainmentMutationService
    var skills: ActorSkillState = game.get("_skill_state") as ActorSkillState
    var plans: CraftingPlanQuery = game.get("_crafting_plans") as CraftingPlanQuery
    var controller: CraftingPlayerInteractionController = game.get("_crafting_controller") as CraftingPlayerInteractionController
    var utilities: UtilityRuntimeState = game.get("_utilities") as UtilityRuntimeState
    var sustainment: SurvivorSustainmentActionService = game.get("_sustainment_actions") as SurvivorSustainmentActionService
    var condition: ActorConditionService = game.get("_condition_service") as ActorConditionService
    var kernel: TickKernel = game.get("_kernel") as TickKernel
    if world == null or mutations == null or inventory == null or inventory_mutations == null \
        or skills == null or plans == null or controller == null or utilities == null \
        or sustainment == null or condition == null or kernel == null:
        _fail("production cooking owners unavailable")
        return

    var stoves: Array[String] = world.entity_ids_of_type(&"prop.stove_range")
    if stoves.is_empty():
        _fail("generated production world has no cooking stove")
        return
    var stove_id: String = ""
    for candidate: String in stoves:
        var candidate_placement: WorldPlacement = world.placement(candidate)
        if candidate_placement != null and utilities.power_available_at_cell(candidate_placement.anchor):
            stove_id = candidate
            break
    if stove_id.is_empty():
        _fail("generated production world has no powered cooking stove")
        return

    var stove: WorldPlacement = world.placement(stove_id)
    var player: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if stove == null or player == null:
        _fail("stove/player placement missing")
        return
    var player_anchor: Vector2i = stove.anchor + Vector2i.LEFT
    if not mutations.set_placement(Fixture.PLAYER_ID, player.channel, player_anchor, Facing.Value.EAST, player.footprint):
        _fail("could not place survivor in contact with stove")
        return

    # The stove must obey the existing live power owner, not recipe/UI guesses.
    var service_id: String = utilities.power_service_for_cell(stove.anchor)
    var branch_id: String = utilities.power_branch_component_id(service_id)
    if service_id.is_empty() or branch_id.is_empty():
        _fail("stove power service is not physically classified")
        return
    if not utilities.set_power_component_state(branch_id, UtilityRuntimeState.DAMAGED, &"phase4_cooking_test"):
        _fail("could not exercise stove outage")
        return
    var unpowered_plan: Dictionary = plans.query(Fixture.PLAYER_ID, RECIPE, stove_id)
    if int(unpowered_plan.get("status", -1)) != CraftingPlanQuery.Status.BLOCKED \
        or String(unpowered_plan.get("reason", "")) != "workstation_unavailable_now":
        _fail("unpowered stove did not block cooking through authoritative power truth")
        return
    if not utilities.set_power_component_state(branch_id, UtilityRuntimeState.OPERATIONAL, &"phase4_cooking_test_restore"):
        _fail("could not restore stove power for cooking")
        return

    if mutations.create_entity(&"item.food.canned_soup", SOUP_ID) != SOUP_ID \
        or mutations.create_entity(&"item.kitchen.cooking_pot", POT_ID) != POT_ID \
        or not inventory_mutations.set_container(SOUP_ID, Fixture.PLAYER_ID) \
        or not inventory_mutations.set_container(POT_ID, Fixture.PLAYER_ID):
        _fail("could not stage scavenged cooking inputs in survivor inventory")
        return
    if not skills.set_skill(Fixture.PLAYER_ID, &"survival", 10, 0):
        _fail("could not stabilize verifier survival skill")
        return

    var ready_plan: Dictionary = plans.query(Fixture.PLAYER_ID, RECIPE, stove_id)
    if int(ready_plan.get("status", -1)) != CraftingPlanQuery.Status.READY:
        _fail("powered stove cooking plan not ready: %s" % String(ready_plan.get("reason", "unknown")))
        return

    var craft_cb := Callable(self, "_on_craft_resolved")
    if not controller.action_resolved.is_connected(craft_cb):
        controller.action_resolved.connect(craft_cb)
    _craft_result = {}
    controller.request_craft(RECIPE, stove_id)
    if not bool(_craft_result.get("success", false)):
        _fail("player crafting controller failed cooking route: %s" % String(_craft_result.get("reason", "unresolved")))
        return
    if world.has_entity(SOUP_ID) or inventory.is_contained(SOUP_ID):
        _fail("canned soup input was not consumed exactly once")
        return
    if not world.has_entity(POT_ID) or inventory.container_of(POT_ID) != Fixture.PLAYER_ID:
        _fail("cooking tool was incorrectly consumed")
        return

    var cooked_ids: Array[String] = world.entity_ids_of_type(HEATED_SOUP)
    if cooked_ids.size() != 1:
        _fail("cooking did not create exactly one heated soup")
        return
    var cooked_id: String = cooked_ids[0]
    if inventory.container_of(cooked_id) != Fixture.PLAYER_ID:
        _fail("heated soup was not returned to survivor inventory")
        return

    # The output must immediately re-enter the established contextual item-use route.
    var before_satiety: int = condition.value(Fixture.PLAYER_ID, ConditionState.SATIETY)
    if not condition.change_condition(Fixture.PLAYER_ID, ConditionState.SATIETY, -20, &"phase4_cooking_test"):
        _fail("could not create visible hunger for cooked-food use")
        return
    var hungry_satiety: int = condition.value(Fixture.PLAYER_ID, ConditionState.SATIETY)
    var offer: Dictionary = sustainment.consumption_offer(Fixture.PLAYER_ID, cooked_id)
    if not bool(offer.get("available", false)) or String(offer.get("label", "")) != "EAT":
        _fail("heated soup did not expose established EAT interaction")
        return
    var consume_serial: int = sustainment.begin_consume(Fixture.PLAYER_ID, cooked_id)
    if consume_serial <= 0:
        _fail("heated soup EAT action could not start")
        return
    kernel.run_until_stop()
    var consume_outcome: Dictionary = sustainment.consumption_outcome(consume_serial)
    if not bool(consume_outcome.get("committed", false)):
        _fail("heated soup EAT action did not commit")
        return
    var fed_satiety: int = condition.value(Fixture.PLAYER_ID, ConditionState.SATIETY)
    if fed_satiety <= hungry_satiety or world.has_entity(cooked_id):
        _fail("eating cooked soup did not apply its consequence exactly once")
        return

    var save_result: Dictionary = game.call("save_durable_session", &"phase4_cooking_route")
    if not bool(save_result.get("ok", false)):
        _fail("durable save failed after cooking/eating consequence")
        return
    var store = StoreClass.new(PRIMARY, BACKUP, TEMP)
    var loaded: Dictionary = store.load_best()
    if not bool(loaded.get("ok", false)):
        _fail("saved cooking consequence was unreadable")
        return
    var session: Dictionary = loaded.get("session", {})

    game.queue_free()
    await process_frame
    await process_frame

    var reopened: Node = await _boot(session)
    if reopened == null:
        return
    world = reopened.get("_world") as WorldState
    inventory = reopened.get("_inventory_state") as InventoryContainmentState
    condition = reopened.get("_condition_service") as ActorConditionService
    if condition.value(Fixture.PLAYER_ID, ConditionState.SATIETY) != fed_satiety:
        _fail("cooked-food condition consequence reset across Continue")
        return
    if world.has_entity(SOUP_ID) or world.has_entity(cooked_id):
        _fail("consumed cooking input/output resurrected across Continue")
        return
    if not world.has_entity(POT_ID) or inventory.container_of(POT_ID) != Fixture.PLAYER_ID:
        _fail("cooking tool state did not survive Continue")
        return

    reopened.queue_free()
    await process_frame
    _cleanup()
    print("PHASE4_COOKING_ROUTE_OK stove_power=true craft=true eat=true input_once=true tool_preserved=true continue=true satiety_before=%d hungry=%d fed=%d" % [before_satiety, hungry_satiety, fed_satiety])
    quit(0)
