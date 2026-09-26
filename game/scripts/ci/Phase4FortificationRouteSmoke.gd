extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Actions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const StoreClass = preload("res://scripts/persistence/DurableSessionStore.gd")

const PRIMARY := "user://phase4_fortification_route.save"
const BACKUP := "user://phase4_fortification_route.backup.save"
const TEMP := "user://phase4_fortification_route.tmp.save"
const HAMMER_ID := "item.phase4.fortification.hammer"
var _finished: Dictionary = {}
var _impact: Dictionary = {}

func _initialize() -> void: call_deferred("_run")
func _fail(message: String) -> void:
    push_error("PHASE4_FORTIFICATION_ROUTE: " + message); quit(1)
func _cleanup() -> void:
    for path: String in [PRIMARY, BACKUP, TEMP]:
        if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
func _boot(session: Dictionary = {}) -> Node:
    var scene: PackedScene = load("res://gameplay.tscn")
    var game: Node = null if scene == null else scene.instantiate()
    if game == null or not game.call("configure_session_paths", PRIMARY, BACKUP, TEMP): _fail("production session configuration unavailable"); return null
    if not session.is_empty() and not game.call("configure_continue_session", session): _fail("valid saved session rejected"); return null
    get_root().add_child(game); await process_frame; await process_frame; await process_frame
    if not bool(game.call("session_boot_ok")): _fail("production gameplay boot failed"); return null
    return game
func _on_finished(target_id: String, action_id: StringName, success: bool, reason: String) -> void:
    _finished = {"target_id": target_id, "action_id": action_id, "success": success, "reason": reason}
func _on_impact(_actor_id: String, _serial: int, target_id: String, damage: int, total_damage: int, breached: bool, _cell: Vector2i) -> void:
    _impact = {"target_id": target_id, "damage": damage, "total": total_damage, "breached": breached}

func _run() -> void:
    _cleanup()
    var game: Node = await _boot()
    if game == null: return
    var world: WorldState = game.get("_world")
    var mutations: WorldMutationService = game.get("_world_mutations")
    var inventory: InventoryContainmentState = game.get("_inventory_state")
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations")
    var skills: ActorSkillState = game.get("_skill_state")
    var kernel: TickKernel = game.get("_kernel")
    var state: WorldInteractableState = game.get("_world_interaction_state")
    var affordances: InteractionAffordanceQuery = game.get("_interaction_affordances")
    var controller: WorldInteractionPlayerController = game.get("_world_interaction_controller")
    var panel: WorldInteractionPanel = game.get("_world_interaction_panel")
    var pressure: ActorOpeningPressureActionService = game.call("opening_pressure_service")
    if world == null or mutations == null or inventory == null or inventory_mutations == null or skills == null or kernel == null or state == null or affordances == null or controller == null or panel == null or pressure == null:
        _fail("production fortification owners unavailable"); return
    controller.action_finished.connect(Callable(self, "_on_finished"))
    if not skills.set_skill(Fixture.PLAYER_ID, &"mechanical", 10, 0): _fail("could not stabilize Mechanical skill"); return

    var window := ""
    for candidate: String in _prefix_ids(world, "window."):
        if _place_actor_facing(world, mutations, Fixture.PLAYER_ID, candidate): window = candidate; break
    if window.is_empty(): _fail("generated world has no reachable existing window"); return

    var impact_cb := Callable(self, "_on_impact")
    pressure.impact_resolved.connect(impact_cb)
    _impact = {}
    var baseline: Dictionary = pressure.request_target(Fixture.PLAYER_ID, window)
    if not bool(baseline.get("accepted", false)): _fail("baseline opening pressure could not start"); return
    kernel.run_until_stop()
    var baseline_damage: int = int(_impact.get("damage", 0))
    if baseline_damage <= 0: _fail("baseline opening pressure produced no damage"); return
    if not state.set_opening_damage(window, 0, &"fortification_verifier_reset"): _fail("could not reset verifier-only baseline damage"); return

    if not _give(mutations, inventory_mutations, &"item.tool.hammer", HAMMER_ID): _fail("could not stage existing hammer"); return
    for index: int in range(3):
        var plank_id := "item.phase4.fortification.plank.%d" % index
        var nails_id := "item.phase4.fortification.nails.%d" % index
        if not _give(mutations, inventory_mutations, &"item.material.wood_plank", plank_id) or not _give(mutations, inventory_mutations, &"item.material.nails_box", nails_id):
            _fail("could not stage existing fortification materials"); return
        if not _place_actor_facing(world, mutations, Fixture.PLAYER_ID, window): _fail("lost contact with window"); return
        var board_offer := false
        for offer: InteractionOffer in affordances.offers():
            if offer.target_entity_id == window and offer.action_id == Actions.OPENING_BOARD and offer.label == "BOARD": board_offer = true; break
        if not board_offer: _fail("window did not expose contextual BOARD at layer %d" % (index + 1)); return
        _finished = {}
        controller.submit_world_cell(world.placement(window).anchor)
        if not panel.is_open(): _fail("world click did not open contextual window panel"); return
        panel.call("_choose", window, Actions.OPENING_BOARD)
        if not bool(_finished.get("success", false)): _fail("player-facing BOARD failed at layer %d: %s" % [index + 1, String(_finished.get("reason", "unresolved"))]); return
        if state.board_count(window) != index + 1: _fail("authoritative board count did not advance"); return
        if world.has_entity(plank_id) or world.has_entity(nails_id): _fail("boarding did not consume exact material pair once"); return
        if not world.has_entity(HAMMER_ID) or inventory.container_of(HAMMER_ID) != Fixture.PLAYER_ID: _fail("boarding consumed hammer"); return

    _impact = {}
    var fortified: Dictionary = pressure.request_target(Fixture.PLAYER_ID, window)
    if not bool(fortified.get("accepted", false)): _fail("fortified opening pressure could not start"); return
    kernel.run_until_stop()
    var fortified_damage: int = int(_impact.get("damage", 0))
    if fortified_damage <= 0 or fortified_damage >= baseline_damage: _fail("boards did not materially reduce opening-pressure damage"); return

    var save_result: Dictionary = game.call("save_durable_session", &"phase4_fortification_route")
    if not bool(save_result.get("ok", false)): _fail("durable save failed after fortification"); return
    var loaded: Dictionary = StoreClass.new(PRIMARY, BACKUP, TEMP).load_best()
    if not bool(loaded.get("ok", false)): _fail("fortification save unreadable"); return
    var session: Dictionary = loaded.get("session", {})
    game.queue_free(); await process_frame; await process_frame
    var reopened: Node = await _boot(session)
    if reopened == null: return
    world = reopened.get("_world"); inventory = reopened.get("_inventory_state"); state = reopened.get("_world_interaction_state")
    if state.board_count(window) != 3: _fail("fortification did not survive Continue"); return
    if state.opening_damage(window) != fortified_damage: _fail("fortification damage state did not survive Continue"); return
    if not world.has_entity(HAMMER_ID) or inventory.container_of(HAMMER_ID) != Fixture.PLAYER_ID: _fail("tool state did not survive Continue"); return
    for index: int in range(3):
        if world.has_entity("item.phase4.fortification.plank.%d" % index) or world.has_entity("item.phase4.fortification.nails.%d" % index): _fail("consumed fortification materials resurrected across Continue"); return
    reopened.queue_free(); await process_frame; _cleanup()
    print("PHASE4_FORTIFICATION_ROUTE_OK contextual=true timed=true boards=3 materials_once=true tool_preserved=true baseline_damage=%d fortified_damage=%d infected_pressure_owner=true continue=true" % [baseline_damage, fortified_damage]); quit(0)

func _give(mutations: WorldMutationService, inventory_mutations: InventoryContainmentMutationService, semantic: StringName, item_id: String) -> bool:
    return mutations.create_entity(semantic, item_id) == item_id and inventory_mutations.set_container(item_id, Fixture.PLAYER_ID)
func _prefix_ids(world: WorldState, prefix: String) -> Array[String]:
    var result: Array[String] = []
    for entity_id: String in world.entity_ids():
        var entity: WorldEntityRecord = world.entity(entity_id)
        if entity != null and String(entity.semantic_type).begins_with(prefix): result.append(entity_id)
    result.sort(); return result
func _place_actor_facing(world: WorldState, mutations: WorldMutationService, actor_id: String, target_id: String) -> bool:
    var actor: WorldPlacement = world.placement(actor_id); var target: WorldPlacement = world.placement(target_id)
    if actor == null or target == null or actor.footprint == null: return false
    for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
        var actor_cell := target.anchor - direction; var facing := Facing.from_vector(direction)
        if not world.has_terrain(actor_cell) or facing < 0: continue
        if mutations.set_placement(actor_id, actor.channel, actor_cell, facing, actor.footprint): return true
    return false
