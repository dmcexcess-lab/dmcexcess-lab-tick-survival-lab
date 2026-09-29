extends SceneTree

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Store = preload("res://scripts/persistence/DurableSessionStore.gd")

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

    _check(game.get("_controller") == null, "legacy player action controller is not constructed")
    _check(game.get("_door_controller") == null, "legacy door controller is not constructed")
    _check(game.get("_loot_controller") == null, "legacy loot controller is not constructed")
    _check(game.get("_crafting_controller") == null, "legacy crafting controller is not constructed")
    _check(game.get("_world_interaction_controller") == null, "legacy world interaction dispatcher is not constructed")
    _check(game.get("_vehicle_controller") == null, "legacy vehicle controller is not constructed")
    _check(game.get("_combat_controller") == null, "legacy combat controller is not constructed")
    _check(game.get("_firearm_actions") == null, "legacy scheduled firearm action service is not constructed")
    _check(game.get("_consequence_presenter") == null, "legacy consequence presenter is not constructed")

    var session: Dictionary = game.call("durable_session_snapshot")
    var owners: Dictionary = session.get("owners", {})
    for key: String in ["kernel", "combat_runtime", "perception_memory"]:
        _check(not owners.has(key), "durable schema excludes runtime owner: %s" % key)

    var simple = game.call("simple_turn_controller")
    var turn_before := int(simple.turn_number())
    simple.submit_intent(Intents.TURN_RIGHT)
    _check(int(simple.turn_number()) == turn_before + 1, "canonical movement/turn route still completes")
    _check(simple.has_control(), "control returns after canonical action")

    var world_time = game.get("_world_time")
    var time_before := int(world_time.world_tick())
    var infected_before := int(simple.individual_actor_actions())
    var active_count := game.call("slice12_active_infected_ids").size()
    var elapsed := int(game.get("_world_time_profile").ticks_per_hour()) * 8
    game.set("_simple_elapsed_override_ticks", elapsed)
    _check(simple._begin_direct_action(&"condition.sleep"), "long direct action begins")
    var long_result: Dictionary = simple._complete_direct_action(&"condition.sleep", "")
    _check(bool(long_result.get("success", false)), "long direct action completes")
    _check(int(world_time.world_tick()) - time_before == elapsed, "long action advances authoritative world time once")
    _check(int(simple.individual_actor_actions()) - infected_before <= active_count, "long action does not multiply infected turns")

    var save_result: Dictionary = game.call("save_durable_session", &"slice14_verify")
    _check(bool(save_result.get("ok", false)), "real SAVE works")
    _check(game.call("save_menu_destination") == "res://main.tscn", "SAVE & MENU destination remains valid")
    var loaded: Dictionary = Store.new(SAVE_A, SAVE_B, SAVE_T).load_best()
    _check(bool(loaded.get("ok", false)), "saved session reloads from store")
    var saved_session: Dictionary = loaded.get("session", {})
    var saved_time := int(game.get("_world_time").world_tick())
    var saved_player = game.get("_world").placement("actor.player")
    var saved_anchor: Vector2i = saved_player.anchor
    var saved_facing := saved_player.facing

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
        continued.queue_free()
        await process_frame

    _cleanup()
    _finish()

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
