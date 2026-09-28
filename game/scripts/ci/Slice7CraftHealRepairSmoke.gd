extends SceneTree
const SEED := 20001
const PLAYER := "actor.player"
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Injury = preload("res://scripts/simulation/actors/health/ActorInjuryRecord.gd")
const SAVE_PRIMARY := "user://slice7_session.save"
const SAVE_BACKUP := "user://slice7_session.backup.save"
const SAVE_TEMP := "user://slice7_session.tmp.save"
func _initialize() -> void: call_deferred("_run")
func _fail(message: String) -> void: push_error("SLICE7: " + message); quit(1)
func _run() -> void:
    _clear_saves()
    var scene: PackedScene = load("res://gameplay.tscn"); var game := scene.instantiate() if scene != null else null
    if game == null or not game.call("configure_world_seed_override", SEED) or not game.call("configure_session_paths", SAVE_PRIMARY, SAVE_BACKUP, SAVE_TEMP): _fail("production setup failed"); return
    get_root().add_child(game); await process_frame; await process_frame
    if not bool(game.call("canonical_boot_ok")) or not bool(game.call("session_boot_ok")): _fail("production/session boot failed"); return
    var turns: SimpleTurnController = game.call("simple_turn_controller")
    if turns == null or not turns.has_control() or game.get_node_or_null("SessionControls") != null: _fail("canonical simple-turn/menu route unavailable"); return
    var kernel_before := int(game._kernel.world_tick()); var rejected_turn := turns.turn_number(); var rejected_tick := int(game.call("survival_elapsed_tick")); var rejected: Dictionary = game.call("run_simple_craft", &"missing.recipe", "")
    if bool(rejected.get("success", false)) or turns.turn_number() != rejected_turn or int(game.call("survival_elapsed_tick")) != rejected_tick: _fail("rejected craft mutated state/time"); return
    var stick := _take_real_generated_item(game, &"item.outdoors.sturdy_stick"); var knife := _take_real_generated_item(game, &"item.kitchen.kitchen_knife")
    if stick.is_empty() or knife.is_empty(): _fail("real generated sharpened-stake inputs unavailable"); return
    var craft_tick := int(game.call("survival_elapsed_tick")); var craft: Dictionary = _attempt_until_success(Callable(game, "run_simple_craft"), [&"crafting.sharpened_stake", ""], 12)
    if not bool(craft.get("success", false)): _fail("real sharpened-stake craft never succeeded: %s" % str(craft)); return
    var outputs: Array = craft.get("output_item_ids", [])
    if game._world.has_entity(stick) or outputs.is_empty() or not game._world.has_entity(String(outputs[0])): _fail("craft exact input/output identity incorrect"); return
    if int(game.call("survival_elapsed_tick")) <= craft_tick: _fail("craft did not advance survival time"); return
    var medkit := _take_real_generated_item(game, &"item.medical.first_aid_kit"); var injury_id: String = game._health_state.add_injury(PLAYER, &"laceration", Injury.LEFT_ARM, Injury.Severity.SERIOUS)
    if medkit.is_empty() or injury_id.is_empty(): _fail("real first-aid content unavailable"); return
    var heal_turn := turns.turn_number(); var heal: Dictionary = game.call("run_simple_first_aid", medkit, injury_id); var wound: ActorInjuryRecord = game._health_state.injury(PLAYER, injury_id)
    if not bool(heal.get("success", false)) or turns.turn_number() != heal_turn + 1 or game._world.has_entity(medkit) or wound == null or not wound.stabilized: _fail("canonical first aid failed: %s" % str(heal)); return
    var hammer := _take_real_generated_item(game, &"item.tool.hammer"); var deconstruct_target := _nearest_deconstructable(game, &"wood")
    if hammer.is_empty() or deconstruct_target.is_empty() or not _place_for(game._world, deconstruct_target): _fail("real wood deconstruction content unavailable"); return
    var deconstruct: Dictionary = _attempt_until_success(Callable(game, "run_simple_deconstruct"), [deconstruct_target], 12)
    if not bool(deconstruct.get("success", false)) or game._world.has_entity(deconstruct_target): _fail("real deconstruction failed: %s" % str(deconstruct)); return
    var salvage: Array = deconstruct.get("output_item_ids", [])
    if salvage.is_empty() or not game._world.has_entity(String(salvage[0])): _fail("deconstruction salvage missing"); return
    var nails := _take_real_generated_item(game, &"item.material.nails_box"); var door := _nearest_repairable_door(game)
    if nails.is_empty() or door.is_empty() or not _place_for(game._world, door): _fail("real door repair content unavailable"); return
    game._world_interaction_state.set_broken(door, true, &"slice7_verify_damage")
    var repair: Dictionary = _attempt_until_success(Callable(game, "run_simple_repair"), [door], 12)
    if not bool(repair.get("success", false)) or game._world_interaction_state.is_broken(door): _fail("real door repair failed: %s" % str(repair)); return
    var beans := _take_real_generated_item(game, &"item.food.canned_beans"); var opener := _take_real_generated_item(game, &"item.kitchen.can_opener"); var stove := _nearest_semantic(game._world, &"prop.stove_range")
    if beans.is_empty() or opener.is_empty() or stove.is_empty() or not _place_for(game._world, stove): _fail("real cooking content unavailable"); return
    var cook_plan: Dictionary = game._crafting_plans.query(PLAYER, &"cooking.heated_beans", stove); var cook_status := "blocked_by_real_power"
    if bool(cook_plan.get("ready", false)):
        var cook: Dictionary = _attempt_until_success(Callable(game, "run_simple_craft"), [&"cooking.heated_beans", stove], 12)
        if not bool(cook.get("success", false)): _fail("powered real cooking failed: %s" % str(cook)); return
        cook_status = "cooked"
    elif String(cook_plan.get("reason", "")) not in ["workstation_unavailable_now", "workstation_power_unclassified"]: _fail("cooking blocked unexpectedly: %s" % String(cook_plan.get("reason", "unknown"))); return
    if int(game._kernel.world_tick()) != kernel_before: _fail("Slice 7 advanced TickKernel"); return
    var save: Dictionary = game.call("save_durable_session", &"slice7"); var loaded: Dictionary = game._session_store.load_best()
    if not bool(save.get("ok", false)) or not bool(loaded.get("ok", false)): _fail("durable save/Continue contract failed"); return
    print("SLICE7_OK seed=%d turns=%d survival_tick=%d craft=true heal=true repair=true deconstruct=true cook=%s save=true" % [SEED, turns.turn_number(), game.call("survival_elapsed_tick"), cook_status]); _clear_saves(); quit(0)
func _attempt_until_success(callback: Callable, args: Array, limit: int) -> Dictionary:
    var last: Dictionary = {}
    for _index in range(limit):
        last = callback.callv(args)
        if bool(last.get("success", false)): return last
        if String(last.get("reason", "")) not in ["skill_check_failed", "mechanical_skill_check_failed"]: return last
    return last
func _take_real_generated_item(game: Node, semantic: StringName) -> String:
    for container_id: String in game._loot_state.container_ids():
        for item_id: String in game._inventory_state.direct_contents(container_id):
            if not game._world.has_entity(item_id): continue
            var entity: WorldEntityRecord = game._world.entity(item_id)
            if entity == null or entity.semantic_type != semantic: continue
            if not game._inventory_mutations.clear_container(item_id): return ""
            if game._inventory_mutations.set_container(item_id, PLAYER): return item_id
            game._inventory_mutations.set_container(item_id, container_id); return ""
    return ""
func _nearest_semantic(world: WorldState, semantic: StringName) -> String:
    var player: WorldPlacement = world.placement(PLAYER)
    if player == null: return ""
    var best := ""; var best_distance := 1 << 30
    for entity_id: String in world.entity_ids_of_type(semantic):
        var placement := world.placement(entity_id)
        if placement == null: continue
        var distance := maxi(absi(placement.anchor.x - player.anchor.x), absi(placement.anchor.y - player.anchor.y))
        if distance < best_distance: best = entity_id; best_distance = distance
    return best
func _nearest_deconstructable(game: Node, material_kind: StringName) -> String:
    var world: WorldState = game._world; var player: WorldPlacement = world.placement(PLAYER)
    if player == null: return ""
    var best := ""; var best_distance := 1 << 30
    for entity_id: String in world.entity_ids():
        var entity: WorldEntityRecord = world.entity(entity_id); var placement: WorldPlacement = world.placement(entity_id)
        if entity == null or placement == null or placement.channel != Layers.Channel.OBJECT or game._inventory_state.has_container(entity_id): continue
        var profile: Dictionary = game._world_interaction_catalog.deconstruction_profile(entity.semantic_type)
        if profile.is_empty() or StringName(profile.get("material_kind", &"")) != material_kind: continue
        var distance := maxi(absi(placement.anchor.x - player.anchor.x), absi(placement.anchor.y - player.anchor.y))
        if distance < best_distance: best = entity_id; best_distance = distance
    return best
func _nearest_repairable_door(game: Node) -> String:
    var world: WorldState = game._world; var player: WorldPlacement = world.placement(PLAYER)
    if player == null: return ""
    var best := ""; var best_distance := 1 << 30
    for entity_id: String in world.entity_ids():
        var entity: WorldEntityRecord = world.entity(entity_id); var placement: WorldPlacement = world.placement(entity_id)
        if entity == null or placement == null or not game._world_interaction_catalog.repairable(entity.semantic_type) or not game._door_state.has_door(entity_id): continue
        var distance := maxi(absi(placement.anchor.x - player.anchor.x), absi(placement.anchor.y - player.anchor.y))
        if distance < best_distance: best = entity_id; best_distance = distance
    return best
func _place_for(world: WorldState, target_id: String) -> bool:
    var target: WorldPlacement = world.placement(target_id)
    if target == null: return false
    for target_cell: Vector2i in target.world_cells():
        for direction: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
            var player_cell := target_cell - direction
            if not world.has_terrain(player_cell): continue
            var occupied := false
            for actor_id: String in world.entities_at(player_cell, Layers.Channel.ACTOR):
                if actor_id != PLAYER: occupied = true
            if not occupied: return world.move_entity(PLAYER, player_cell, Facing.from_vector(direction))
    return false
func _clear_saves() -> void:
    for path: String in [SAVE_PRIMARY, SAVE_BACKUP, SAVE_TEMP]:
        if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
