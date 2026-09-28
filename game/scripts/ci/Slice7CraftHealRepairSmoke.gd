extends SceneTree

const SEED := 20001
const PLAYER := "actor.player"
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Injury = preload("res://scripts/simulation/actors/health/ActorInjuryRecord.gd")
const WorldActions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const SAVE_PRIMARY := "user://slice7_session.save"
const SAVE_BACKUP := "user://slice7_session.backup.save"
const SAVE_TEMP := "user://slice7_session.tmp.save"
func _initialize() -> void: call_deferred("_run")
func _fail(message: String) -> void: push_error("SLICE7: " + message); quit(1)
func _run() -> void:
    _clear_saves(); var scene: PackedScene = load("res://gameplay.tscn"); var game := scene.instantiate() if scene != null else null
    if game == null or not game.call("configure_world_seed_override", SEED) or not game.call("configure_session_paths", SAVE_PRIMARY, SAVE_BACKUP, SAVE_TEMP): _fail("setup failed"); return
    get_root().add_child(game); await process_frame; await process_frame
    if not game.call("canonical_boot_ok") or not game.call("session_boot_ok"): _fail("production boot failed"); return
    var turns: SimpleTurnController = game.call("simple_turn_controller"); var world: WorldState = turns._world
    if turns == null or not turns.has_control() or game.get_node_or_null("SessionControls") != null: _fail("canonical route/menu unavailable"); return
    var kernel_before: int = int(game._kernel.world_tick()); var rejected_turn := turns.turn_number(); var rejected_tick := int(game.call("survival_elapsed_tick")); var rejected: Dictionary = game.call("run_simple_craft", &"missing.recipe", "")
    if bool(rejected.get("success", false)) or turns.turn_number() != rejected_turn or int(game.call("survival_elapsed_tick")) != rejected_tick: _fail("rejected craft mutated time"); return

    var craft_recipe: StringName = &"crafting.sharpened_stake"; var recipe: CraftingRecipe = game._crafting_recipes.recipe(craft_recipe)
    if recipe == null or not _supply_recipe(game, recipe): _fail("could not supply real craft recipe"); return
    var pre_plan: Dictionary = game._crafting_plans.query(PLAYER, craft_recipe, ""); var craft_inputs: Array[String] = []
    for value: Variant in pre_plan.get("consumed_item_ids", []): craft_inputs.append(String(value))
    var craft_turn := turns.turn_number(); var craft_tick := int(game.call("survival_elapsed_tick")); var craft: Dictionary = game.call("run_simple_craft", craft_recipe, "")
    if not bool(craft.get("success", false)) or turns.turn_number() != craft_turn + 1 or int(game.call("survival_elapsed_tick")) != craft_tick + int(craft.get("elapsed_ticks", 0)): _fail("real craft did not complete once"); return
    for item_id: String in craft_inputs:
        if world.has_entity(item_id): _fail("exact craft input survived"); return
    var craft_outputs: Array = craft.get("output_item_ids", [])
    if craft_outputs.size() != 1 or not world.has_entity(String(craft_outputs[0])) or game._inventory_state.container_of(String(craft_outputs[0])) != PLAYER: _fail("craft output not authoritative"); return

    var stove: String = _find_semantic(world, &"prop.stove_range"); var cook_recipe: CraftingRecipe = game._crafting_recipes.recipe(&"cooking.heated_beans")
    if stove.is_empty() or cook_recipe == null or not _place_for(world, stove) or not _supply_recipe(game, cook_recipe): _fail("real cooking fixture unavailable"); return
    var cook_plan: Dictionary = game._crafting_plans.query(PLAYER, &"cooking.heated_beans", stove)
    if String(cook_plan.get("reason", "")) == "workstation_unpowered": print("SLICE7_COOK_BLOCKED_BY_REAL_POWER seed=%d stove=%s" % [SEED, stove])
    elif bool(cook_plan.get("ready", false)):
        var cook: Dictionary = game.call("run_simple_craft", &"cooking.heated_beans", stove); if not bool(cook.get("success", false)): _fail("powered real cooking failed"); return
    else: _fail("cooking blocked for unexpected reason: %s" % String(cook_plan.get("reason", "unknown"))); return

    var med_id := _create_carried(game, &"item.medical.first_aid_kit", "slice7.medkit"); var injury_id: String = game._health_state.add_injury(PLAYER, &"laceration", Injury.LEFT_ARM, Injury.Severity.SERIOUS)
    if med_id.is_empty() or injury_id.is_empty(): _fail("first aid fixture failed"); return
    var heal_turn := turns.turn_number(); var heal: Dictionary = game.call("run_simple_first_aid", med_id, injury_id); var wound: ActorInjuryRecord = game._health_state.injury(PLAYER, injury_id)
    if not bool(heal.get("success", false)) or turns.turn_number() != heal_turn + 1 or world.has_entity(med_id) or wound == null or not wound.stabilized: _fail("canonical first aid failed"); return

    var door: String = _find_repairable_door(game)
    if door.is_empty() or not _place_for(world, door): _fail("repairable door unavailable"); return
    game._world_interaction_state.set_broken(door, true, &"slice7_setup"); _create_carried(game, &"item.tool.hammer", "slice7.hammer"); _create_carried(game, &"item.material.wood_plank", "slice7.plank"); _create_carried(game, &"item.material.nails_box", "slice7.nails")
    var repair: Dictionary = game.call("run_simple_repair", door); if not bool(repair.get("success", false)) or game._world_interaction_state.is_broken(door): _fail("real door repair failed"); return

    var target: String = _find_deconstructable(game)
    if target.is_empty() or not _place_for(world, target): _fail("deconstructable object unavailable"); return
    var target_entity: WorldEntityRecord = world.entity(target); var profile: Dictionary = game._world_interaction_catalog.deconstruction_profile(target_entity.semantic_type); _create_carried(game, StringName(profile.get("tool_semantics", [])[0]), "slice7.deconstruct_tool")
    var deconstruct: Dictionary = game.call("run_simple_contextual_action", PLAYER, target, WorldActions.OBJECT_DECONSTRUCT)
    if not bool(deconstruct.get("success", false)) or world.has_entity(target) or deconstruct.get("output_item_ids", []).size() != int(profile.get("output_count", 0)): _fail("real deconstruction failed"); return
    if int(game._kernel.world_tick()) != kernel_before: _fail("Slice 7 advanced TickKernel"); return
    var save: Dictionary = game.call("save_durable_session", &"slice7"); var loaded: Dictionary = game._session_store.load_best(); if not bool(save.get("ok", false)) or not bool(loaded.get("ok", false)): _fail("durable save failed"); return
    print("SLICE7_OK seed=%d turns=%d survival_tick=%d craft=true heal=true repair=true deconstruct=true cook_checked=true save=true" % [SEED, turns.turn_number(), game.call("survival_elapsed_tick")]); _clear_saves(); quit(0)
func _supply_recipe(game: Node, recipe: CraftingRecipe) -> bool:
    var index := 0
    for req: Dictionary in recipe.consumed_inputs + recipe.required_tools:
        for _n in range(int(req.get("count", 1))): index += 1; if _create_carried(game, StringName(req.get("semantic_type", &"")), "slice7.recipe.%03d" % index).is_empty(): return false
    return true
func _create_carried(game: Node, semantic: StringName, item_id: String) -> String:
    if game._world.create_entity(semantic, item_id) != item_id: return ""
    if not game._inventory_mutations.set_container(item_id, PLAYER): game._world.remove_entity(item_id); return ""
    return item_id
func _find_semantic(world: WorldState, semantic: StringName) -> String:
    for entity_id: String in world.entity_ids_of_type(semantic): if world.placement(entity_id) != null: return entity_id
    return ""
func _find_repairable_door(game: Node) -> String:
    for entity_id: String in game._world.entity_ids():
        var entity: WorldEntityRecord = game._world.entity(entity_id); if entity != null and game._world_interaction_catalog.is_door(entity.semantic_type) and game._door_state.has_door(entity_id): return entity_id
    return ""
func _find_deconstructable(game: Node) -> String:
    for entity_id: String in game._world.entity_ids():
        var entity: WorldEntityRecord = game._world.entity(entity_id); var placement: WorldPlacement = game._world.placement(entity_id)
        if entity != null and placement != null and placement.channel == Layers.Channel.OBJECT and game._world_interaction_catalog.deconstructible(entity.semantic_type) and not game._inventory_state.has_container(entity_id): return entity_id
    return ""
func _place_for(world: WorldState, target_id: String) -> bool:
    var target: WorldPlacement = world.placement(target_id); if target == null: return false
    for cell: Vector2i in target.world_cells():
        for direction: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
            var player_cell := cell - direction
            if not world.has_terrain(player_cell): continue
            var occupied := false
            for actor_id: String in world.entities_at(player_cell, Layers.Channel.ACTOR): if actor_id != PLAYER: occupied = true
            if not occupied: return world.move_entity(PLAYER, player_cell, Facing.from_vector(direction))
    return false
func _clear_saves() -> void:
    for path: String in [SAVE_PRIMARY, SAVE_BACKUP, SAVE_TEMP]: if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
