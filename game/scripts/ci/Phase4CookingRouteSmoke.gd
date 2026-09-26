extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StoreClass = preload("res://scripts/persistence/DurableSessionStore.gd")

const PRIMARY := "user://phase4_cooking_route.save"
const BACKUP := "user://phase4_cooking_route.backup.save"
const TEMP := "user://phase4_cooking_route.tmp.save"
const SOUP_ID := "item.phase4.canned_soup.001"
const POT_ID := "item.phase4.cooking_pot.001"
const RECIPE := &"cooking.heated_soup"
const HEATED_SOUP := &"item.crafting.heated_soup"
var _craft_result: Dictionary = {}

func _initialize() -> void: call_deferred("_run")
func _fail(message: String) -> void:
    push_error("PHASE4_COOKING_ROUTE: " + message)
    quit(1)
func _cleanup() -> void:
    for path: String in [PRIMARY, BACKUP, TEMP]:
        if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _boot(session: Dictionary = {}) -> Node:
    var scene: PackedScene = load("res://gameplay.tscn")
    var game: Node = null if scene == null else scene.instantiate()
    if game == null or not game.call("configure_session_paths", PRIMARY, BACKUP, TEMP):
        _fail("production gameplay/session configuration unavailable"); return null
    if not session.is_empty() and not game.call("configure_continue_session", session):
        _fail("valid saved session rejected"); return null
    get_root().add_child(game)
    await process_frame; await process_frame; await process_frame
    if not bool(game.call("session_boot_ok")):
        _fail("production gameplay boot failed: %s" % String(game.call("session_boot_error"))); return null
    var adapter: Node = game.get_node_or_null("PoweredCraftingWorkstationAdapter")
    if adapter == null or not bool(adapter.call("is_bound")):
        _fail("powered workstation bridge did not bind existing owners"); return null
    return game

func _on_craft_resolved(recipe_id: StringName, success: bool, reason: String, world_tick: int, workstation_id: String) -> void:
    _craft_result = {"recipe_id": recipe_id, "success": success, "reason": reason, "world_tick": world_tick, "workstation_id": workstation_id}

func _run() -> void:
    _cleanup()
    var game: Node = await _boot()
    if game == null: return
    var world: WorldState = game.get("_world") as WorldState
    var mutations: WorldMutationService = game.get("_world_mutations") as WorldMutationService
    var inventory: InventoryContainmentState = game.get("_inventory_state") as InventoryContainmentState
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations") as InventoryContainmentMutationService
    var skills: ActorSkillState = game.get("_skill_state") as ActorSkillState
    var plans: CraftingPlanQuery = game.get("_crafting_plans") as CraftingPlanQuery
    var controller: CraftingPlayerInteractionController = game.get("_crafting_controller") as CraftingPlayerInteractionController
    var utilities: UtilityRuntimeState = game.get("_utilities") as UtilityRuntimeState
    var sustainment: SurvivorSustainmentActionService = game.get("_sustainment_actions") as SurvivorSustainmentActionService
    if world == null or mutations == null or inventory == null or inventory_mutations == null or skills == null or plans == null or controller == null or utilities == null or sustainment == null:
        _fail("production cooking owners unavailable"); return

    var stove_id := ""
    for candidate: String in world.entity_ids_of_type(&"prop.stove_range"):
        var p: WorldPlacement = world.placement(candidate)
        if p != null and utilities.power_available_at_cell(p.anchor): stove_id = candidate; break
    if stove_id.is_empty(): _fail("generated world has no powered cooking stove"); return
    var stove: WorldPlacement = world.placement(stove_id)
    var player: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if stove == null or player == null or not mutations.set_placement(Fixture.PLAYER_ID, player.channel, stove.anchor + Vector2i.LEFT, Facing.Value.EAST, player.footprint):
        _fail("could not establish player contact with stove"); return

    var service_id: String = utilities.power_service_for_cell(stove.anchor)
    var branch_id: String = utilities.power_branch_component_id(service_id)
    if service_id.is_empty() or branch_id.is_empty(): _fail("stove power service unclassified"); return
    if not utilities.set_power_component_state(branch_id, UtilityRuntimeState.DAMAGED, &"phase4_cooking_test"):
        _fail("could not exercise stove outage"); return
    var blocked: Dictionary = plans.query(Fixture.PLAYER_ID, RECIPE, stove_id)
    if int(blocked.get("status", -1)) != CraftingPlanQuery.Status.BLOCKED or String(blocked.get("reason", "")) != "workstation_unavailable_now":
        _fail("unpowered stove did not block cooking"); return
    if not utilities.set_power_component_state(branch_id, UtilityRuntimeState.OPERATIONAL, &"phase4_cooking_restore"):
        _fail("could not restore stove power"); return

    if mutations.create_entity(&"item.food.canned_soup", SOUP_ID) != SOUP_ID or mutations.create_entity(&"item.kitchen.cooking_pot", POT_ID) != POT_ID or not inventory_mutations.set_container(SOUP_ID, Fixture.PLAYER_ID) or not inventory_mutations.set_container(POT_ID, Fixture.PLAYER_ID):
        _fail("could not stage scavenged cooking inputs"); return
    if not skills.set_skill(Fixture.PLAYER_ID, &"survival", 10, 0): _fail("could not stabilize survival skill"); return
    var ready: Dictionary = plans.query(Fixture.PLAYER_ID, RECIPE, stove_id)
    if int(ready.get("status", -1)) != CraftingPlanQuery.Status.READY:
        _fail("powered stove cooking plan not ready: %s" % String(ready.get("reason", "unknown"))); return

    controller.action_resolved.connect(Callable(self, "_on_craft_resolved"))
    controller.request_craft(RECIPE, stove_id)
    if not bool(_craft_result.get("success", false)):
        _fail("player crafting controller failed: %s" % String(_craft_result.get("reason", "unresolved"))); return
    if world.has_entity(SOUP_ID): _fail("canned soup input was not consumed exactly once"); return
    if not world.has_entity(POT_ID) or inventory.container_of(POT_ID) != Fixture.PLAYER_ID:
        _fail("cooking tool was incorrectly consumed"); return
    var cooked_ids: Array[String] = world.entity_ids_of_type(HEATED_SOUP)
    if cooked_ids.size() != 1: _fail("cooking did not create exactly one heated soup"); return
    var cooked_id: String = cooked_ids[0]
    if inventory.container_of(cooked_id) != Fixture.PLAYER_ID: _fail("heated soup not returned to inventory"); return
    var offer: Dictionary = sustainment.consumption_offer(Fixture.PLAYER_ID, cooked_id)
    if not bool(offer.get("available", false)) or String(offer.get("label", "")) != "EAT":
        _fail("cooked output did not enter established EAT route"); return

    var save_result: Dictionary = game.call("save_durable_session", &"phase4_cooking_route")
    if not bool(save_result.get("ok", false)): _fail("save failed after cooking"); return
    var loaded: Dictionary = StoreClass.new(PRIMARY, BACKUP, TEMP).load_best()
    if not bool(loaded.get("ok", false)): _fail("cooking save unreadable"); return
    var session: Dictionary = loaded.get("session", {})
    game.queue_free(); await process_frame; await process_frame

    var reopened: Node = await _boot(session)
    if reopened == null: return
    world = reopened.get("_world") as WorldState
    inventory = reopened.get("_inventory_state") as InventoryContainmentState
    sustainment = reopened.get("_sustainment_actions") as SurvivorSustainmentActionService
    if world.has_entity(SOUP_ID) or not world.has_entity(cooked_id): _fail("cooking consequence reset across Continue"); return
    if not world.has_entity(POT_ID) or inventory.container_of(POT_ID) != Fixture.PLAYER_ID or inventory.container_of(cooked_id) != Fixture.PLAYER_ID:
        _fail("cooking inventory state did not survive Continue"); return
    offer = sustainment.consumption_offer(Fixture.PLAYER_ID, cooked_id)
    if not bool(offer.get("available", false)) or String(offer.get("label", "")) != "EAT":
        _fail("persisted cooked food lost EAT route"); return

    reopened.queue_free(); await process_frame; _cleanup()
    print("PHASE4_COOKING_ROUTE_OK stove_power=true outage_blocks=true craft=true input_once=true tool_preserved=true eat_offer=true continue=true")
    quit(0)
