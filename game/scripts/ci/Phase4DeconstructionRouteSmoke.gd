extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const TickRules = preload("res://scripts/foundation/time/TickRules.gd")
const Actions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const StoreClass = preload("res://scripts/persistence/DurableSessionStore.gd")

const PRIMARY := "user://phase4_deconstruction_route.save"
const BACKUP := "user://phase4_deconstruction_route.backup.save"
const TEMP := "user://phase4_deconstruction_route.tmp.save"
const HAMMER_ID := "item.phase4.deconstruction.hammer"
const TARGET_SEMANTIC := &"prop.dining_chair"
const SALVAGE_SEMANTIC := &"item.material.wood_plank"

var _finished: Dictionary = {}

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE4_DECONSTRUCTION_ROUTE: " + message)
    quit(1)

func _cleanup() -> void:
    for path: String in [PRIMARY, BACKUP, TEMP]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _boot(session: Dictionary = {}) -> Node:
    var scene: PackedScene = load("res://gameplay.tscn")
    var game: Node = null if scene == null else scene.instantiate()
    if game == null or not game.call("configure_session_paths", PRIMARY, BACKUP, TEMP):
        _fail("production gameplay/session configuration unavailable")
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
    return game

func _on_finished(target_id: String, action_id: StringName, success: bool, reason: String) -> void:
    _finished = {"target_id": target_id, "action_id": action_id, "success": success, "reason": reason}

func _run() -> void:
    _cleanup()
    var game: Node = await _boot()
    if game == null:
        return

    var world: WorldState = game.get("_world") as WorldState
    var mutations: WorldMutationService = game.get("_world_mutations") as WorldMutationService
    var inventory: InventoryContainmentState = game.get("_inventory_state") as InventoryContainmentState
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations") as InventoryContainmentMutationService
    var kernel: TickKernel = game.get("_kernel") as TickKernel
    var affordances: InteractionAffordanceQuery = game.get("_interaction_affordances") as InteractionAffordanceQuery
    var actions: WorldInteractionActionService = game.get("_world_interaction_actions") as WorldInteractionActionService
    var controller: WorldInteractionPlayerController = game.get("_world_interaction_controller") as WorldInteractionPlayerController
    var panel: WorldInteractionPanel = game.get("_world_interaction_panel") as WorldInteractionPanel
    var skills: ActorSkillState = game.get("_skill_state") as ActorSkillState
    if world == null or mutations == null or inventory == null or inventory_mutations == null or kernel == null \
        or affordances == null or actions == null or controller == null or panel == null or skills == null:
        _fail("production deconstruction owners unavailable")
        return

    var targets: Array[String] = world.entity_ids_of_type(TARGET_SEMANTIC)
    if targets.is_empty():
        _fail("generated production world has no dining chair")
        return
    var target_id: String = targets[0]
    var target: WorldPlacement = world.placement(target_id)
    var player: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if target == null or player == null:
        _fail("target/player placement missing")
        return

    var player_anchor: Vector2i = target.anchor + Vector2i.LEFT
    if not mutations.set_placement(Fixture.PLAYER_ID, player.channel, player_anchor, Facing.Value.EAST, player.footprint):
        _fail("could not place survivor in contact with deconstruction target")
        return
    if mutations.create_entity(&"item.tool.hammer", HAMMER_ID) != HAMMER_ID or not inventory_mutations.set_container(HAMMER_ID, Fixture.PLAYER_ID):
        _fail("could not stage existing hammer tool")
        return
    if not skills.set_skill(Fixture.PLAYER_ID, &"mechanical", 10, 0):
        _fail("could not stabilize verifier mechanical skill")
        return

    var offer_found := false
    for offer: InteractionOffer in affordances.offers():
        if offer.target_entity_id == target_id and offer.action_id == Actions.OBJECT_DECONSTRUCT and offer.label == "DECONSTRUCT":
            offer_found = true
            break
    if not offer_found:
        _fail("reachable dining chair did not expose contextual DECONSTRUCT")
        return

    # CANCELABLE actions terminate as CANCELED when interrupted before their commit phase.
    # The player-visible invariant is that neither target nor salvage changes.
    var interrupted: Dictionary = actions.request_action(Fixture.PLAYER_ID, target_id, Actions.OBJECT_DECONSTRUCT)
    var interrupted_serial: int = int(interrupted.get("action_serial", 0))
    if not bool(interrupted.get("accepted", false)) or interrupted_serial <= 0:
        _fail("timed deconstruction action could not start")
        return
    var interrupt_status: int = kernel.interrupt_action(interrupted_serial, "phase4_precommit_cancel")
    if interrupt_status != TickRules.ActionStatus.CANCELED:
        _fail("cancelable deconstruction did not cancel before commit")
        return
    if not world.has_entity(target_id) or not world.entity_ids_of_type(SALVAGE_SEMANTIC).is_empty():
        _fail("pre-commit interruption changed target or created salvage")
        return

    # Exercise the real player surface: world cell -> contextual panel -> DECONSTRUCT choice.
    var finished_cb := Callable(self, "_on_finished")
    if not controller.action_finished.is_connected(finished_cb):
        controller.action_finished.connect(finished_cb)
    _finished = {}
    controller.submit_world_cell(target.anchor)
    if not panel.is_open():
        _fail("world-cell interaction did not open contextual panel")
        return
    panel.call("_choose", target_id, Actions.OBJECT_DECONSTRUCT)
    if not bool(_finished.get("success", false)) or StringName(_finished.get("action_id", &"")) != Actions.OBJECT_DECONSTRUCT:
        _fail("player-facing DECONSTRUCT route failed: %s" % String(_finished.get("reason", "unresolved")))
        return
    if world.has_entity(target_id):
        _fail("deconstructed dining chair still exists in authoritative WHAT")
        return
    if not world.has_entity(HAMMER_ID) or inventory.container_of(HAMMER_ID) != Fixture.PLAYER_ID:
        _fail("deconstruction incorrectly consumed the hammer")
        return

    var salvage_ids: Array[String] = world.entity_ids_of_type(SALVAGE_SEMANTIC)
    if salvage_ids.size() != 1:
        _fail("dining chair did not yield exactly one existing wood-plank material")
        return
    var salvage_id: String = salvage_ids[0]
    var salvage_container: String = inventory.container_of(salvage_id)
    var salvage_placement: WorldPlacement = world.placement(salvage_id)
    if salvage_container != Fixture.PLAYER_ID and salvage_placement == null:
        _fail("salvage entered neither existing inventory nor loose-world truth")
        return

    var save_result: Dictionary = game.call("save_durable_session", &"phase4_deconstruction_route")
    if not bool(save_result.get("ok", false)):
        _fail("durable save failed after deconstruction")
        return
    var loaded: Dictionary = StoreClass.new(PRIMARY, BACKUP, TEMP).load_best()
    if not bool(loaded.get("ok", false)):
        _fail("saved deconstruction consequence unreadable")
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
    if world.has_entity(target_id):
        _fail("deconstructed chair resurrected across Continue")
        return
    salvage_ids = world.entity_ids_of_type(SALVAGE_SEMANTIC)
    if salvage_ids.size() != 1 or salvage_ids[0] != salvage_id:
        _fail("salvage duplicated or changed identity across Continue")
        return
    if not world.has_entity(HAMMER_ID) or inventory.container_of(HAMMER_ID) != Fixture.PLAYER_ID:
        _fail("hammer state did not survive Continue")
        return

    reopened.queue_free()
    await process_frame
    _cleanup()
    print("PHASE4_DECONSTRUCTION_ROUTE_OK target=dining_chair contextual=true timed=true interrupted_safe=true removed=true salvage=wood_plank salvage_once=true tool_preserved=true continue=true")
    quit(0)
