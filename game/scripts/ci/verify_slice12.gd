extends SceneTree

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")

const SEED := 20001
const SAVE_A := "user://slice12_verify.save"
const SAVE_B := "user://slice12_verify.backup.save"
const SAVE_T := "user://slice12_verify.tmp.save"

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    _cleanup_files()
    var game = await _boot_game()
    if game == null:
        _finish()
        return

    var world = game.get("_world")
    var mutations = game.get("_world_mutations")
    var simple = game.call("simple_turn_controller")
    var streaming = game.call("slice12_cell_active", world.placement("actor.player").anchor)
    _check(bool(streaming), "player begins inside active streaming neighborhood")

    var fixture := _install_boundary_fixture(game)
    _check(bool(fixture.get("ok", false)), "near/far infected fixture installed")
    if not bool(fixture.get("ok", false)):
        game.queue_free()
        await process_frame
        _finish()
        return

    var near_id := String(fixture.get("near_id", ""))
    var far_id := String(fixture.get("far_id", ""))
    var far_cell: Vector2i = fixture.get("far_cell", Vector2i.ZERO)
    var far_before: Vector2i = world.placement(far_id).anchor
    var actions_before := int(simple.individual_actor_actions())
    var active_before: Array = game.call("slice12_active_infected_ids")
    _check(active_before.has(near_id), "near infected is eligible in active roster")
    _check(not active_before.has(far_id), "far infected is excluded from active roster")

    var ordinary := _perform_turn_action(simple)
    _check(ordinary, "normal player action succeeds")
    var far_after: Vector2i = world.placement(far_id).anchor
    var action_delta := int(simple.individual_actor_actions()) - actions_before
    _check(action_delta >= 1, "relevant local infected receives an ordinary response opportunity")
    _check(far_after == far_before, "far inactive infected receives zero individual action")
    _check(action_delta <= active_before.size(), "actor work is bounded by active roster")

    var far_hp_before := int(game.get("_health_state").current_hp(far_id))
    var idle_far_before: Vector2i = world.placement(far_id).anchor
    for _i in range(20):
        await process_frame
    _check(world.placement(far_id).anchor == idle_far_before, "idle render frames do not move far infected")
    _check(int(game.get("_health_state").current_hp(far_id)) == far_hp_before, "idle render frames do not simulate far infected")

    var turn_before := int(simple.turn_number())
    var infected_actions_before := int(simple.individual_actor_actions())
    var time_before := int(game.get("_world_time").world_tick())
    var long_elapsed := int(game.get("_world_time_profile").ticks_per_hour()) * 8
    game.set("_simple_elapsed_override_ticks", long_elapsed)
    _check(simple._begin_direct_action(&"condition.sleep"), "long action begins")
    var long_result: Dictionary = simple._complete_direct_action(&"condition.sleep", "")
    _check(bool(long_result.get("success", false)), "long action completes")
    _check(int(simple.turn_number()) == turn_before + 1, "eight-hour action consumes one turn boundary")
    _check(int(game.get("_world_time").world_tick()) - time_before == long_elapsed, "eight-hour action advances authoritative world time")
    _check(int(simple.individual_actor_actions()) - infected_actions_before <= game.call("slice12_active_infected_ids").size(), "eight-hour action does not multiply infected turns")
    _check(world.placement(far_id).anchor == far_before, "far infected remains dormant across long time jump")

    var far_persist_before: Vector2i = world.placement(far_id).anchor
    _check(_move_player_to_far_neighborhood(game, far_cell), "player can move streaming focus to far neighborhood")
    _check(game.call("_refresh_slice12_simulation_boundary"), "far neighborhood boundary refresh succeeds")
    var active_after_move: Array = game.call("slice12_active_infected_ids")
    _check(active_after_move.has(far_id), "far infected becomes eligible when its neighborhood becomes active")
    _check(not active_after_move.has(near_id), "previous local infected becomes dormant outside active neighborhood")
    _check(world.placement(near_id) != null, "leaving area does not delete previous infected")

    var near_before_far_turn: Vector2i = world.placement(near_id).anchor
    var far_actions_before := int(simple.individual_actor_actions())
    _perform_turn_action(simple)
    var far_action_delta := int(simple.individual_actor_actions()) - far_actions_before
    _check(far_action_delta <= active_after_move.size(), "new neighborhood response work stays bounded by active roster")
    _check(world.placement(near_id).anchor == near_before_far_turn, "old-area infected remains dormant")
    _check(world.has_entity(near_id) and world.has_entity(far_id), "both near and far infected remain persistent entities")

    var session: Dictionary = game.call("durable_session_snapshot")
    _check(not session.is_empty(), "durable snapshot created with boundary fixture state")
    var saved_near: Vector2i = world.placement(near_id).anchor
    var saved_far: Vector2i = world.placement(far_id).anchor
    var saved_time := int(game.get("_world_time").world_tick())

    game.queue_free()
    await process_frame

    var restored = await _boot_game(session)
    if restored != null:
        var restored_world = restored.get("_world")
        _check(restored_world.has_entity(near_id) and restored_world.has_entity(far_id), "Continue preserves dormant and active infected identities")
        _check(restored_world.placement(near_id) != null and restored_world.placement(near_id).anchor == saved_near, "Continue preserves old-area infected placement")
        _check(restored_world.placement(far_id) != null and restored_world.placement(far_id).anchor == saved_far, "Continue preserves active-area infected placement")
        _check(int(restored.get("_world_time").world_tick()) == saved_time, "Slice 11 authoritative world time survives Continue")
        var restored_kernel_tick := int(restored.get("_kernel").world_tick())
        for _i in range(10):
            await process_frame
        _check(int(restored.get("_kernel").world_tick()) == restored_kernel_tick, "legacy TickKernel remains dormant after Continue")
        restored.queue_free()
        await process_frame

    _cleanup_files()
    _finish()

func _boot_game(session: Dictionary = {}):
    var packed := load("res://gameplay.tscn") as PackedScene
    _check(packed != null, "production gameplay scene loads")
    if packed == null:
        return null
    var game = packed.instantiate()
    _check(game != null and game.has_method("slice12_active_infected_ids"), "production scene composes Slice12GameMain")
    if game == null:
        return null
    game.configure_session_paths(SAVE_A, SAVE_B, SAVE_T)
    if session.is_empty():
        _check(game.configure_world_seed_override(SEED), "new-game seed configured")
    else:
        _check(game.configure_continue_session(session), "Continue session accepted")
    root.add_child(game)
    await process_frame
    await process_frame
    _check(game.session_boot_ok(), "production gameplay boots: %s" % game.session_boot_error())
    if not game.session_boot_ok():
        game.queue_free()
        await process_frame
        return null
    return game

func _install_boundary_fixture(game) -> Dictionary:
    var world = game.get("_world")
    var mutations = game.get("_world_mutations")
    var player = world.placement("actor.player")
    var streaming = game.call("slice12_cell_active", player.anchor)
    if player == null or not bool(streaming):
        return {"ok": false}

    var near_cell := _find_clear_cell(game, player.anchor, 1, 1, true)
    if near_cell == Vector2i(-999999, -999999):
        return {"ok": false}
    var far_cell := _find_far_stream_cell(game, player.anchor)
    if far_cell == Vector2i(-999999, -999999):
        return {"ok": false}

    var near_id := "slice12.infected.near"
    var far_id := "slice12.infected.far"
    if not _create_infected(game, near_id, near_cell):
        return {"ok": false}
    if not _create_infected(game, far_id, far_cell):
        return {"ok": false}

    var known: Array[String] = game.call("simple_infected_actor_ids")
    if not known.has(near_id):
        known.append(near_id)
    if not known.has(far_id):
        known.append(far_id)
    game.set("_simple_infected_ids", known)
    _check(game.call("_refresh_slice12_simulation_boundary"), "fixture boundary refresh succeeds")

    return {
        "ok": true,
        "near_id": near_id,
        "far_id": far_id,
        "near_cell": near_cell,
        "far_cell": far_cell,
    }

func _create_infected(game, actor_id: String, cell: Vector2i) -> bool:
    var world = game.get("_world")
    if world.has_entity(actor_id):
        return false
    if world.create_entity(&"actor.survivor", actor_id) != actor_id:
        return false
    if not world.set_placement(actor_id, Layers.Channel.ACTOR, cell, Facing.Value.SOUTH, Footprint.single_cell()):
        world.remove_entity(actor_id)
        return false
    if not game.call("_ensure_simple_infected_state", actor_id):
        world.remove_entity(actor_id)
        return false
    return true

func _find_clear_cell(game, origin: Vector2i, min_radius: int, max_radius: int, require_active: bool) -> Vector2i:
    var world = game.get("_world")
    var query = game.get("_spatial_query")
    for radius in range(min_radius, max_radius + 1):
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if absi(dx) != radius and absi(dy) != radius:
                    continue
                var cell := origin + Vector2i(dx, dy)
                if require_active and not game.call("slice12_cell_active", cell):
                    continue
                if not world.has_terrain(cell):
                    continue
                var check = query.query_cell(cell, "", true)
                if check != null and check.is_clear():
                    return cell
    return Vector2i(-999999, -999999)

func _find_far_stream_cell(game, origin: Vector2i) -> Vector2i:
    var streaming = game.call("slice12_cell_active", origin)
    if not bool(streaming):
        return Vector2i(-999999, -999999)
    var coordinator = game.call("_slice12_streaming_for_verify") if game.has_method("_slice12_streaming_for_verify") else null
    if coordinator == null:
        coordinator = game.get("_streaming") if game.get("_streaming") != null else null
    var global_plan = game.call("_slice12_global_plan_for_verify") if game.has_method("_slice12_global_plan_for_verify") else null
    if global_plan == null:
        global_plan = game.get("_global_plan") if game.get("_global_plan") != null else null

    # Use the coordinator's public active bounds to step beyond the current active set,
    # then ask production streaming to materialize that location before fixture placement.
    var sc = preload("res://scripts/generation/integration/ProductionWorldBootstrap.gd").streaming_coordinator()
    if sc == null:
        return Vector2i(-999999, -999999)
    var active_bounds: Array[Rect2i] = sc.active_region_bounds()
    if active_bounds.is_empty():
        return Vector2i(-999999, -999999)
    var world_bounds = preload("res://scripts/generation/integration/ProductionWorldBootstrap.gd").global_plan().bounds
    for bounds: Rect2i in active_bounds:
        var candidates: Array[Vector2i] = [
            bounds.position + Vector2i(bounds.size.x + 40, bounds.size.y / 2),
            bounds.position + Vector2i(-40, bounds.size.y / 2),
            bounds.position + Vector2i(bounds.size.x / 2, bounds.size.y + 40),
            bounds.position + Vector2i(bounds.size.x / 2, -40),
        ]
        for candidate: Vector2i in candidates:
            if not world_bounds.has_point(candidate) or sc.is_cell_active(candidate):
                continue
            var result: Dictionary = sc.update_focus(candidate)
            if not bool(result.get("ok", false)):
                continue
            var clear := _find_clear_cell(game, candidate, 0, 18, true)
            if clear != Vector2i(-999999, -999999):
                # Restore player-focused streaming; the fixture stays persistent but inactive.
                var player = game.get("_world").placement("actor.player")
                sc.update_focus(player.anchor)
                return clear
    return Vector2i(-999999, -999999)

func _move_player_to_far_neighborhood(game, target: Vector2i) -> bool:
    var world = game.get("_world")
    var player = world.placement("actor.player")
    if player == null:
        return false
    var sc = preload("res://scripts/generation/integration/ProductionWorldBootstrap.gd").streaming_coordinator()
    if sc == null:
        return false
    var result: Dictionary = sc.update_focus(target)
    if not bool(result.get("ok", false)):
        return false
    var clear := _find_clear_cell(game, target, 1, 2, true)
    if clear == Vector2i(-999999, -999999):
        return false
    return world.move_entity("actor.player", clear, player.facing)

func _perform_turn_action(simple) -> bool:
    var before := int(simple.turn_number())
    simple.submit_intent(Intents.TURN_LEFT)
    return int(simple.turn_number()) == before + 1

func _cleanup_files() -> void:
    for path in [SAVE_A, SAVE_B, SAVE_T]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    failures.append(message)
    push_error("SLICE12_FAIL: %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("SLICE12_WORLD_BOUNDARY_OK")
        quit(0)
        return
    quit(1)
