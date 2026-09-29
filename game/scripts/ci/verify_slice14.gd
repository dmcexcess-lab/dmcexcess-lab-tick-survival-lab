extends SceneTree

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Store = preload("res://scripts/persistence/DurableSessionStore.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const WorldActions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")

const SAVE_A := "user://slice14_verify.save"
const SAVE_B := "user://slice14_verify.backup.save"
const SAVE_T := "user://slice14_verify.tmp.save"

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    _cleanup()
    var game = await _boot_new()
    if game == null:
        _finish()
        return

    _check(String(game.get_script().resource_path) == "res://scripts/app/ProductionGameMain.gd", "gameplay.tscn uses consolidated ProductionGameMain")
    _check(game.get("_controller") == null, "legacy player action controller is not constructed")
    _check(game.get("_door_controller") == null, "legacy door controller is not constructed")
    _check(game.get("_loot_controller") == null, "legacy loot controller is not constructed")
    _check(game.get("_crafting_controller") == null, "legacy crafting controller is not constructed")
    _check(game.get("_world_interaction_controller") == null, "legacy world interaction dispatcher is not constructed")
    _check(game.get("_vehicle_controller") == null, "legacy vehicle controller is not constructed")
    _check(game.get("_combat_controller") == null, "legacy combat controller is not constructed")
    _check(game.get("_firearm_actions") == null, "legacy scheduled firearm action service is not constructed")
    _check(game.get("_consequence_presenter") == null, "legacy consequence presenter is not constructed")
    _check(game.get("_vehicle_state") != null and game.get("_vehicle_profiles") != null and game.get("_vehicle_controls") != null, "canonical vehicle state/control path remains available")
    _check(game.get("_utilities") != null and game.get("_power_network") != null and game.get("_portable_generators") != null, "canonical utility state remains available")

    var session: Dictionary = game.call("durable_session_snapshot")
    var owners: Dictionary = session.get("owners", {})
    for key: String in ["kernel", "combat_runtime", "perception_memory"]:
        _check(not owners.has(key), "durable schema excludes runtime owner: %s" % key)

    var simple = game.call("simple_turn_controller")
    var kernel_tick_before := int(game.get("_kernel").world_tick())
    var turn_before := int(simple.turn_number())
    simple.submit_intent(Intents.TURN_RIGHT)
    _check(int(simple.turn_number()) == turn_before + 1, "canonical movement/turn route still completes")
    _check(simple.has_control(), "control returns after canonical action")
    _check(int(game.get("_kernel").world_tick()) == kernel_tick_before, "canonical turn does not advance compatibility TickKernel")

    _check(_verify_combat_action(game), "representative canonical melee combat completes")
    _check(int(game.get("_kernel").world_tick()) == kernel_tick_before, "canonical combat does not advance compatibility TickKernel")
    _check(_verify_context_action(game), "representative direct contextual door action completes")
    _check(int(game.get("_kernel").world_tick()) == kernel_tick_before, "canonical contextual action does not advance compatibility TickKernel")

    var world_time = game.get("_world_time")
    var time_before := int(world_time.world_tick())
    var infected_before := int(simple.individual_actor_actions())
    var active_count: int = game.call("slice12_active_infected_ids").size()
    var elapsed := int(game.get("_world_time_profile").ticks_per_hour()) * 8
    game.set("_simple_elapsed_override_ticks", elapsed)
    _check(simple._begin_direct_action(&"condition.sleep"), "long direct action begins")
    var long_result: Dictionary = simple._complete_direct_action(&"condition.sleep", "")
    _check(bool(long_result.get("success", false)), "long direct action completes")
    _check(int(world_time.world_tick()) - time_before == elapsed, "long action advances authoritative world time once")
    _check(int(simple.individual_actor_actions()) - infected_before <= active_count, "long action does not multiply infected turns")
    _check(int(game.get("_kernel").world_tick()) == kernel_tick_before, "long canonical action does not advance compatibility TickKernel")

    var save_result: Dictionary = game.call("save_durable_session", &"slice14_verify")
    _check(bool(save_result.get("ok", false)), "real SAVE works")
    _check(game.call("save_menu_destination") == "res://main.tscn", "SAVE & MENU destination remains valid")
    var loaded: Dictionary = Store.new(SAVE_A, SAVE_B, SAVE_T).load_best()
    _check(bool(loaded.get("ok", false)), "saved session reloads from store")
    var saved_session: Dictionary = loaded.get("session", {})
    var saved_time := int(game.get("_world_time").world_tick())
    var saved_player = game.get("_world").placement("actor.player")
    var saved_anchor: Vector2i = saved_player.anchor
    var saved_facing: int = saved_player.facing

    game.queue_free()
    await process_frame

    var continued = await _boot_continue(saved_session)
    if continued != null:
        var restored = continued.get("_world").placement("actor.player")
        _check(restored != null and restored.anchor == saved_anchor and restored.facing == saved_facing, "Continue restores player placement/facing")
        _check(int(continued.get("_world_time").world_tick()) == saved_time, "Continue restores authoritative world time")
        _check(continued.call("simple_turn_controller").has_control(), "Continue reconstructs playable direct-turn runtime")
        var idle_time := int(continued.get("_world_time").world_tick())
        var idle_actions := int(continued.call("simple_turn_controller").individual_actor_actions())
        for _i in range(12):
            await process_frame
        _check(int(continued.get("_world_time").world_tick()) == idle_time, "idle frames do not advance gameplay time")
        _check(int(continued.call("simple_turn_controller").individual_actor_actions()) == idle_actions, "idle frames do not run actors")
        var canonical_after_continue: Dictionary = continued.call("durable_session_snapshot")
        continued.queue_free()
        await process_frame

        var legacy: Dictionary = canonical_after_continue.duplicate(true)
        legacy["schema_version"] = Store.LEGACY_SESSION_SCHEMA_VERSION
        var legacy_owners: Dictionary = legacy.get("owners", {})
        legacy_owners.erase("world_time")
        legacy_owners.erase("refrigeration")
        legacy_owners["kernel"] = {"retired_runtime_payload": "ignored"}
        legacy_owners["perception_memory"] = {"retired_runtime_payload": "ignored"}
        legacy_owners["combat_runtime"] = {"retired_runtime_payload": "ignored"}
        legacy["owners"] = legacy_owners
        _check(bool(Store.new(SAVE_A, SAVE_B, SAVE_T).validate_session(legacy).get("ok", false)), "current schema-1 lineage remains accepted")
        var migrated = await _boot_continue(legacy)
        if migrated != null:
            var migrated_snapshot: Dictionary = migrated.call("durable_session_snapshot")
            var migrated_owners: Dictionary = migrated_snapshot.get("owners", {})
            _check(int(migrated_snapshot.get("schema_version", -1)) == Store.SESSION_SCHEMA_VERSION, "schema-1 Continue emits canonical schema 2")
            _check(not migrated_owners.has("kernel") and not migrated_owners.has("combat_runtime") and not migrated_owners.has("perception_memory"), "schema-1 runtime payloads are ignored rather than restored")
            migrated.queue_free()
            await process_frame

    _cleanup()
    _finish()

func _verify_combat_action(game) -> bool:
    var world = game.get("_world")
    var query = game.get("_spatial_query")
    var player = world.placement("actor.player")
    if player == null:
        return false

    var chosen_facing: int = player.facing
    var target_cell := Vector2i.ZERO
    var found := false
    for facing_value: int in [Facing.Value.NORTH, Facing.Value.EAST, Facing.Value.SOUTH, Facing.Value.WEST]:
        var candidate: Vector2i = player.anchor + Facing.vector(facing_value)
        var check = query.query_cell(candidate, "", true)
        if check != null and check.is_clear():
            chosen_facing = facing_value
            target_cell = candidate
            found = true
            break
    if not found:
        return false
    if not world.move_entity("actor.player", player.anchor, chosen_facing):
        return false

    var infected_id := "slice14.infected.combat"
    if world.has_entity(infected_id):
        world.remove_entity(infected_id)
    if world.create_entity(&"actor.survivor", infected_id) != infected_id:
        return false
    if not world.set_placement(infected_id, Layers.Channel.ACTOR, target_cell, Facing.from_vector(player.anchor - target_cell), Footprint.single_cell()):
        world.remove_entity(infected_id)
        return false
    if not game.call("_ensure_simple_infected_state", infected_id):
        world.remove_entity(infected_id)
        return false
    var known: Array[String] = game.call("simple_infected_actor_ids")
    if not known.has(infected_id):
        known.append(infected_id)
    game.set("_simple_infected_ids", known)
    if not game.call("_refresh_simulation_boundary"):
        return false
    var hp_before := int(game.get("_health_state").current_hp(infected_id))
    var turn_before := int(game.call("simple_turn_controller").turn_number())
    game.call("simple_turn_controller").submit_intent(Intents.COMBAT_FORWARD)
    var hp_after := int(game.get("_health_state").current_hp(infected_id))
    return int(game.call("simple_turn_controller").turn_number()) == turn_before + 1 and hp_after < hp_before

func _verify_context_action(game) -> bool:
    var world = game.get("_world")
    var query = game.get("_spatial_query")
    var catalog = game.get("_world_interaction_catalog")
    var interaction_state = game.get("_world_interaction_state")
    var door_state = game.get("_door_state")
    var player = world.placement("actor.player")
    if player == null or catalog == null or interaction_state == null or door_state == null:
        return false

    for target_id: String in world.entity_ids():
        var entity = world.entity(target_id)
        var target = world.placement(target_id)
        if entity == null or target == null or not catalog.is_door(entity.semantic_type) or not door_state.has_door(target_id):
            continue
        for offset: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
            var actor_cell: Vector2i = target.anchor + offset
            var check = query.query_cell(actor_cell, "actor.player", true)
            if check == null or not check.is_clear():
                continue
            var facing: int = Facing.from_vector(target.anchor - actor_cell)
            if not world.move_entity("actor.player", actor_cell, facing):
                continue
            interaction_state.set_locked(target_id, false, &"slice14_verify")
            interaction_state.set_board_count(target_id, 0, &"slice14_verify")
            interaction_state.set_broken(target_id, false, &"slice14_verify")
            game.call("_refresh_simulation_boundary")
            var action_id: StringName = WorldActions.DOOR_CLOSE if door_state.state(target_id) == DoorValue.OPEN else WorldActions.DOOR_OPEN
            var result: Dictionary = game.call("run_simple_contextual_action", "actor.player", target_id, action_id)
            return bool(result.get("success", false))
    return false

func _boot_new():
    var packed := load("res://gameplay.tscn") as PackedScene
    _check(packed != null, "production gameplay scene loads")
    if packed == null: return null
    var game = packed.instantiate()
    if game == null:
        _check(false, "production gameplay scene instantiates")
        return null
    game.configure_session_paths(SAVE_A, SAVE_B, SAVE_T)
    _check(game.configure_world_seed_override(20001), "production seed override accepted")
    root.add_child(game)
    await process_frame
    await process_frame
    _check(game.session_boot_ok(), "New Game boots: %s" % game.session_boot_error())
    return game if game.session_boot_ok() else null

func _boot_continue(session: Dictionary):
    var packed := load("res://gameplay.tscn") as PackedScene
    if packed == null: return null
    var game = packed.instantiate()
    if game == null: return null
    game.configure_session_paths(SAVE_A, SAVE_B, SAVE_T)
    _check(game.configure_continue_session(session), "Continue accepts real schema-2 session")
    root.add_child(game)
    await process_frame
    await process_frame
    _check(game.session_boot_ok(), "Continue boots: %s" % game.session_boot_error())
    return game if game.session_boot_ok() else null

func _cleanup() -> void:
    for path in [SAVE_A, SAVE_B, SAVE_T]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(condition: bool, message: String) -> void:
    if condition: return
    failures.append(message)
    push_error("SLICE14_FAIL: %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("SLICE14_DEMOLITION_OK")
        quit(0)
    else:
        quit(1)
