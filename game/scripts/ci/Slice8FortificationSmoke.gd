extends SceneTree

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const WorldActions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const PlayerId := "actor.player"

var failures: Array[String] = []
var game: Node = null

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://gameplay.tscn")
    _check(packed != null, "production scene loads")
    if packed == null:
        _finish()
        return
    game = packed.instantiate()
    get_root().add_child(game)
    await process_frame
    _check(bool(game.call("session_boot_ok")), "production session boots")
    if not failures.is_empty():
        _finish()
        return

    var world: WorldState = game.get("_world")
    var state: WorldInteractableState = game.get("_world_interaction_state")
    var inventory: InventoryContainmentState = game.get("_inventory_state")
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations")
    var skills: ActorSkillState = game.get("_skill_state")
    var kernel: TickKernel = game.get("_kernel")
    var simple: SimpleTurnController = game.get("_simple_turns")
    var shell: CanonicalPlayerShell = game.get("_shell")
    _check(world != null and state != null and inventory != null and inventory_mutations != null, "authoritative fortification owners available")
    _check(skills != null and kernel != null and simple != null and simple.is_ready(), "skill and simple-turn owners available")
    _check(shell != null and shell.is_configured(), "canonical phone shell remains configured")
    if not failures.is_empty():
        _finish()
        return

    _check(skills.set_skill(PlayerId, SkillCatalog.MECHANICAL, 10, 0), "Mechanical test level set")
    var target: String = _first_generated_opening(world, state)
    _check(not target.is_empty(), "real generated boardable opening found")
    if target.is_empty():
        _finish()
        return
    _check(_face_target(world, target), "player positioned at generated opening")

    var initial_boards: int = state.board_count(target)
    var initial_survival: int = int(game.call("survival_elapsed_tick"))
    var initial_kernel: int = int(kernel.current_tick())
    var rejected: Dictionary = game.call("run_simple_fortification", target, WorldActions.OPENING_BOARD)
    _check(not bool(rejected.get("success", false)), "BOARD rejects without real requirements")
    _check(state.board_count(target) == initial_boards, "rejected BOARD mutates no fortification state")
    _check(int(game.call("survival_elapsed_tick")) == initial_survival, "rejected BOARD is zero-time")

    var hammer: String = _give(world, inventory_mutations, &"item.tool.hammer", "ci.slice8.hammer")
    var plank: String = _give(world, inventory_mutations, &"item.material.wood_plank", "ci.slice8.plank")
    var nails: String = _give(world, inventory_mutations, &"item.material.nails_box", "ci.slice8.nails")
    _check(not hammer.is_empty() and not plank.is_empty() and not nails.is_empty(), "real hammer/plank/nails enter authoritative inventory")

    var before_turn: int = int(simple.turn_index())
    var before_survival: int = int(game.call("survival_elapsed_tick"))
    var boarded: Dictionary = game.call("run_simple_fortification", target, WorldActions.OPENING_BOARD)
    _check(bool(boarded.get("success", false)), "BOARD succeeds through canonical production route")
    _check(state.board_count(target) == initial_boards + 1, "BOARD increments authoritative opening board count by one")
    _check(world.has_entity(hammer) and inventory.is_contained(hammer), "hammer remains a real carried tool")
    _check(not world.has_entity(plank) and not world.has_entity(nails), "BOARD consumes exact plank and nails entities")
    _check(int(simple.turn_index()) == before_turn + 1, "BOARD completes exactly one canonical player turn")
    _check(int(game.call("survival_elapsed_tick")) > before_survival, "BOARD advances explicit survival elapsed time")
    _check(int(kernel.current_tick()) == initial_kernel, "BOARD does not advance TickKernel")

    var affordances: InteractionAffordanceQuery = game.call("simple_contextual_affordances")
    var offers: Array[InteractionOffer] = affordances.offers()
    var has_remove := false
    for offer: InteractionOffer in offers:
        if offer.target_entity_id == target and offer.action_id == WorldActions.OPENING_UNBOARD:
            has_remove = true
            break
    _check(has_remove, "boarded real opening exposes REMOVE BOARD contextually")

    _check(_face_target(world, target), "player remains/repositions at boarded opening")
    before_turn = int(simple.turn_index())
    before_survival = int(game.call("survival_elapsed_tick"))
    var unboarded: Dictionary = game.call("run_simple_fortification", target, WorldActions.OPENING_UNBOARD)
    _check(bool(unboarded.get("success", false)), "REMOVE BOARD succeeds through canonical production route")
    _check(state.board_count(target) == initial_boards, "REMOVE BOARD updates the same authoritative board state")
    _check(int(simple.turn_index()) == before_turn + 1, "REMOVE BOARD completes exactly one canonical player turn")
    _check(int(game.call("survival_elapsed_tick")) > before_survival, "REMOVE BOARD advances explicit survival elapsed time once")
    _check(int(kernel.current_tick()) == initial_kernel, "REMOVE BOARD does not advance TickKernel")

    var recovered := false
    for item_id: String in world.entity_ids_of_type(&"item.material.wood_plank"):
        if item_id != plank and inventory.is_contained(item_id) and inventory.container_of(item_id) == PlayerId:
            recovered = true
            break
    _check(recovered, "REMOVE BOARD recovers a real authoritative plank entity")

    var save_result: Dictionary = game.call("save_durable_session", &"slice8_smoke")
    _check(bool(save_result.get("ok", false)), "durable save accepts fortification state")
    _check(String(game.call("save_menu_destination")) == "res://startup.tscn", "SAVE & MENU destination remains startup")
    _check(shell.get_viewport() != null, "canonical touch shell remains present")

    print("SLICE8_OK target=%s boards=%d turn=%d survival_tick=%d save=%s" % [target, state.board_count(target), int(simple.turn_index()), int(game.call("survival_elapsed_tick")), str(bool(save_result.get("ok", false)))])
    _finish()

func _first_generated_opening(world: WorldState, state: WorldInteractableState) -> String:
    var ids := world.entity_ids()
    ids.sort()
    for entity_id: String in ids:
        var entity := world.entity(entity_id)
        if entity == null:
            continue
        var semantic := String(entity.semantic_type)
        if not (semantic.begins_with("door.") or semantic.begins_with("window.")):
            continue
        if state.is_broken(entity_id) or state.board_count(entity_id) >= WorldInteractableState.MAX_BOARDS:
            continue
        return entity_id
    return ""

func _face_target(world: WorldState, target_id: String) -> bool:
    var actor := world.placement(PlayerId)
    var target := world.placement(target_id)
    if actor == null or target == null:
        return false
    var candidates := [
        [Vector2i(0, 1), Facing.Value.NORTH],
        [Vector2i(1, 0), Facing.Value.WEST],
        [Vector2i(0, -1), Facing.Value.SOUTH],
        [Vector2i(-1, 0), Facing.Value.EAST],
    ]
    for candidate: Array in candidates:
        var anchor: Vector2i = target.anchor + candidate[0]
        if world.set_placement(PlayerId, actor.channel, anchor, int(candidate[1]), actor.footprint, actor.structure_axis):
            return true
    return false

func _give(world: WorldState, inventory_mutations: InventoryContainmentMutationService, semantic: StringName, item_id: String) -> String:
    if world.has_entity(item_id):
        world.remove_entity(item_id)
    var created: String = world.create_entity(semantic, item_id)
    if created.is_empty() or not inventory_mutations.set_container(created, PlayerId):
        if not created.is_empty() and world.has_entity(created):
            world.remove_entity(created)
        return ""
    return created

func _check(ok: bool, label: String) -> void:
    if ok:
        print("PASS: %s" % label)
    else:
        failures.append(label)
        push_error("FAIL: %s" % label)

func _finish() -> void:
    if game != null and is_instance_valid(game):
        game.queue_free()
    if failures.is_empty():
        quit(0)
    else:
        push_error("Slice 8 fortification smoke failed: %s" % str(failures))
        quit(1)
