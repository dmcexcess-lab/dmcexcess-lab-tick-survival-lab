extends SceneTree

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const WorldActions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const PlayerId := "actor.player"
const Seed := 20001
const SavePrimary := "user://slice8_session.save"
const SaveBackup := "user://slice8_session.backup.save"
const SaveTemp := "user://slice8_session.tmp.save"

var failures: Array[String] = []
var game: Node = null

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
    _clear_saves()
    var packed: PackedScene = load("res://gameplay.tscn")
    _check(packed != null, "production scene loads")
    if packed == null: _finish(); return
    game = packed.instantiate()
    _check(game.call("configure_world_seed_override", Seed), "production deterministic seed accepted")
    _check(game.call("configure_session_paths", SavePrimary, SaveBackup, SaveTemp), "isolated durable paths accepted")
    get_root().add_child(game)
    await process_frame; await process_frame
    _check(bool(game.call("session_boot_ok")), "production session boots")
    if not failures.is_empty(): _finish(); return

    var world: WorldState = game._world
    var state: WorldInteractableState = game._world_interaction_state
    var inventory: InventoryContainmentState = game._inventory_state
    var inventory_mutations: InventoryContainmentMutationService = game._inventory_mutations
    var skills: ActorSkillState = game._skill_state
    var kernel: TickKernel = game._kernel
    var simple: SimpleTurnController = game.call("simple_turn_controller")
    var shell: CanonicalPlayerShell = game._shell
    _check(world != null and state != null and inventory != null and inventory_mutations != null, "authoritative fortification owners available")
    _check(skills != null and kernel != null and simple != null and simple.is_ready(), "skill and simple-turn owners available")
    _check(shell != null and shell.is_configured() and game.get_node_or_null("SessionControls") == null, "canonical phone shell/menu composition remains healthy")
    if not failures.is_empty(): _finish(); return

    _check(skills.set_skill(PlayerId, SkillCatalog.MECHANICAL, 10, 0), "Mechanical test level set")
    var target: String = _first_generated_opening(world, state)
    _check(not target.is_empty(), "real generated boardable opening found")
    if target.is_empty() or not _place_for(world, target): _check(false, "player positioned at generated opening"); _finish(); return

    var initial_boards: int = state.board_count(target)
    var initial_survival: int = int(game.call("survival_elapsed_tick"))
    var initial_kernel: int = int(kernel.world_tick())
    var rejected: Dictionary = game.call("run_simple_fortification", target, WorldActions.OPENING_BOARD)
    _check(not bool(rejected.get("success", false)), "BOARD rejects without real requirements")
    _check(state.board_count(target) == initial_boards, "rejected BOARD mutates no fortification state")
    _check(int(game.call("survival_elapsed_tick")) == initial_survival, "rejected BOARD is zero-time")

    var hammer: String = _give(world, inventory_mutations, &"item.tool.hammer", "slice8.hammer")
    var plank: String = _give(world, inventory_mutations, &"item.material.wood_plank", "slice8.plank")
    var nails: String = _give(world, inventory_mutations, &"item.material.nails_box", "slice8.nails")
    _check(not hammer.is_empty() and not plank.is_empty() and not nails.is_empty(), "real hammer/plank/nails enter authoritative inventory")

    var before_turn: int = simple.turn_number()
    var before_survival: int = int(game.call("survival_elapsed_tick"))
    var boarded: Dictionary = game.call("run_simple_fortification", target, WorldActions.OPENING_BOARD)
    _check(bool(boarded.get("success", false)), "BOARD succeeds through canonical production route")
    _check(state.board_count(target) == initial_boards + 1, "BOARD increments authoritative opening board count by one")
    _check(world.has_entity(hammer) and inventory.is_contained(hammer), "hammer remains a real carried tool")
    _check(not world.has_entity(plank) and not world.has_entity(nails), "BOARD consumes exact plank and nails entities")
    _check(simple.turn_number() == before_turn + 1, "BOARD completes exactly one canonical player turn")
    _check(int(game.call("survival_elapsed_tick")) > before_survival, "BOARD advances explicit survival elapsed time")
    _check(int(kernel.world_tick()) == initial_kernel, "BOARD does not advance TickKernel")

    var offers: Array[InteractionOffer] = game.call("simple_contextual_affordances").offers()
    var has_remove := false
    for offer: InteractionOffer in offers:
        if offer.target_entity_id == target and offer.action_id == WorldActions.OPENING_UNBOARD: has_remove = true
    _check(has_remove, "boarded real opening exposes REMOVE BOARD contextually")

    if not _place_for(world, target): _check(false, "player remains/repositions at boarded opening")
    before_turn = simple.turn_number(); before_survival = int(game.call("survival_elapsed_tick"))
    var unboarded: Dictionary = game.call("run_simple_fortification", target, WorldActions.OPENING_UNBOARD)
    _check(bool(unboarded.get("success", false)), "REMOVE BOARD succeeds through canonical production route")
    _check(state.board_count(target) == initial_boards, "REMOVE BOARD updates the same authoritative board state")
    _check(simple.turn_number() == before_turn + 1, "REMOVE BOARD completes exactly one canonical player turn")
    _check(int(game.call("survival_elapsed_tick")) > before_survival, "REMOVE BOARD advances explicit survival elapsed time once")
    _check(int(kernel.world_tick()) == initial_kernel, "REMOVE BOARD does not advance TickKernel")

    var recovered_id := String(unboarded.get("recovered_item_id", ""))
    _check(not recovered_id.is_empty() and world.has_entity(recovered_id), "REMOVE BOARD recovers a real authoritative plank entity")

    var save_result: Dictionary = game.call("save_durable_session", &"slice8_smoke")
    var loaded: Dictionary = game._session_store.load_best()
    _check(bool(save_result.get("ok", false)) and bool(loaded.get("ok", false)), "durable save accepts fortification state")
    var menu_destination := String(game.call("save_menu_destination"))
    _check(not menu_destination.is_empty() and menu_destination != "res://gameplay.tscn" and ResourceLoader.exists(menu_destination), "SAVE & MENU destination remains a real non-gameplay startup scene")
    _check(shell.get_viewport() != null, "canonical touch shell remains present")

    print("SLICE8_OK seed=%d target=%s boards=%d turn=%d survival_tick=%d save=true" % [Seed, target, state.board_count(target), simple.turn_number(), int(game.call("survival_elapsed_tick"))])
    _finish()

func _first_generated_opening(world: WorldState, state: WorldInteractableState) -> String:
    var ids := world.entity_ids(); ids.sort()
    for entity_id: String in ids:
        var entity := world.entity(entity_id); var placement := world.placement(entity_id)
        if entity == null or placement == null: continue
        var semantic := String(entity.semantic_type)
        if not (semantic.begins_with("window.") or semantic.begins_with("door.")): continue
        if state.is_broken(entity_id) or state.board_count(entity_id) >= WorldInteractableState.MAX_BOARDS: continue
        return entity_id
    return ""

func _place_for(world: WorldState, target_id: String) -> bool:
    var target: WorldPlacement = world.placement(target_id)
    if target == null: return false
    for target_cell: Vector2i in target.world_cells():
        for direction: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
            var player_cell := target_cell - direction
            if not world.has_terrain(player_cell): continue
            var occupied := false
            for actor_id: String in world.entities_at(player_cell, Layers.Channel.ACTOR):
                if actor_id != PlayerId: occupied = true
            if not occupied and world.move_entity(PlayerId, player_cell, Facing.from_vector(direction)): return true
    return false

func _give(world: WorldState, inventory_mutations: InventoryContainmentMutationService, semantic: StringName, item_id: String) -> String:
    if world.has_entity(item_id): world.remove_entity(item_id)
    var created: String = world.create_entity(semantic, item_id)
    if created.is_empty() or not inventory_mutations.set_container(created, PlayerId):
        if not created.is_empty() and world.has_entity(created): world.remove_entity(created)
        return ""
    return created

func _check(ok: bool, label: String) -> void:
    if ok: print("PASS: %s" % label)
    else: failures.append(label); push_error("FAIL: %s" % label)

func _finish() -> void:
    _clear_saves()
    if game != null and is_instance_valid(game): game.queue_free()
    if failures.is_empty(): quit(0)
    else: push_error("Slice 8 fortification smoke failed: %s" % str(failures)); quit(1)

func _clear_saves() -> void:
    for path: String in [SavePrimary, SaveBackup, SaveTemp]:
        if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
