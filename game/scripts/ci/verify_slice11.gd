extends SceneTree

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const VehicleProfiles = preload("res://scripts/simulation/vehicles/VehicleProfileCatalog.gd")
const VehicleActions = preload("res://scripts/simulation/vehicles/VehicleActionService.gd")
const VehicleHeading = preload("res://scripts/simulation/vehicles/VehicleHeading.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")

const SEED := 20001
const SAVE_A := "user://slice11_verify.save"
const SAVE_B := "user://slice11_verify.backup.save"
const SAVE_T := "user://slice11_verify.tmp.save"

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    _cleanup_files()
    var game = await _boot_game()
    if game == null:
        _finish()
        return

    var world_time = game.get("_world_time")
    var weather = game.get("_weather")
    var daylight = game.get("_ambient_daylight")
    var kernel = game.get("_kernel")
    var simple = game.call("simple_turn_controller")

    _check(world_time != null and world_time.uses_manual_clock(), "world time uses explicit canonical clock")
    _check(weather != null and weather.uses_manual_clock(), "weather uses explicit canonical clock")
    _check(daylight != null and daylight.is_ready(), "daylight owner is ready")
    _check(simple != null, "simple-turn owner is ready")

    var idle_tick := int(world_time.world_tick())
    for _i in range(20):
        await process_frame
    _check(int(world_time.world_tick()) == idle_tick, "idle render frames do not advance world time")

    var kernel_tick_before := int(kernel.world_tick())
    var ordinary_before := int(world_time.world_tick())
    var moved := _perform_clear_player_move(game, simple)
    _check(moved, "ordinary canonical movement succeeds")
    if moved:
        var ordinary_after := int(world_time.world_tick())
        _check(ordinary_after - ordinary_before == int(game.call("survival_ticks_per_turn")), "ordinary action advances expected time exactly once")
        _check(int(game.call("survival_elapsed_tick")) == ordinary_after, "survival and world-time clocks agree after ordinary action")

    var weather_serial_before := int(weather.debug_snapshot().get("transition_serial", -1))
    _check(int(kernel.world_tick()) == kernel_tick_before, "canonical actions do not advance legacy TickKernel")

    var vehicle_id := _install_test_car(game)
    _check(not vehicle_id.is_empty(), "authoritative test car installed")
    if not vehicle_id.is_empty():
        var enter: Dictionary = game.call("run_simple_vehicle_action", VehicleActions.ENTER, "", vehicle_id)
        _check(bool(enter.get("success", false)), "vehicle enter succeeds")
        var state = game.get("_vehicle_state")
        state.mutate(vehicle_id, {"key_in_ignition": true, "powered": true, "moving": false})
        var vehicle_before := int(world_time.world_tick())
        var move_result: Dictionary = game.call("run_simple_vehicle_action", VehicleActions.MOVE, "", "")
        _check(bool(move_result.get("success", false)), "vehicle movement succeeds")
        if bool(move_result.get("success", false)):
            _check(int(world_time.world_tick()) - vehicle_before == int(move_result.get("elapsed_ticks", -1)), "vehicle action advances its explicit elapsed time exactly once")

    _check(int(weather.debug_snapshot().get("transition_serial", -1)) == weather_serial_before, "weather does not reroll on short ordinary actions")

    var profile = daylight.daylight_profile()
    _check(daylight.phase_for_second_of_day(profile.dawn_start_second) == &"dawn", "dawn phase derives from time")
    _check(daylight.phase_for_second_of_day(profile.day_start_second) == &"day", "day phase derives from time")
    _check(daylight.phase_for_second_of_day(profile.dusk_start_second) == &"dusk", "dusk phase derives from time")
    _check(daylight.phase_for_second_of_day(profile.night_start_second) == &"night", "night phase derives from time")
    _check(daylight.level_for_second_of_day(profile.day_start_second) > daylight.level_for_second_of_day(profile.night_start_second), "night ambient light is materially darker than day")
    _check(game.get("_perception") != null and game.get("_physical_lighting") != null, "perception and physical lighting remain configured")
    _check(game.get("_utility_lighting") != null and game.get("_vehicle_lighting") != null, "utility and vehicle artificial lighting remain authoritative")

    var long_before := int(world_time.world_tick())
    var infected_actions_before := int(simple.individual_actor_actions())
    var turn_before := int(simple.turn_number())
    var long_elapsed := int(game.get("_world_time_profile").ticks_per_hour()) * 8
    game.set("_simple_elapsed_override_ticks", long_elapsed)
    _check(simple._begin_direct_action(&"condition.sleep"), "long action begins through simple-turn seam")
    var long_result: Dictionary = simple._complete_direct_action(&"condition.sleep", "")
    _check(bool(long_result.get("success", false)), "long action completes")
    var long_after := int(world_time.world_tick())
    _check(long_after - long_before == long_elapsed, "eight-hour action advances world time in one bounded operation")
    _check(int(simple.turn_number()) == turn_before + 1, "long action consumes one player turn boundary")
    var infected_delta := int(simple.individual_actor_actions()) - infected_actions_before
    _check(infected_delta <= game.call("simple_infected_actor_ids").size(), "long action does not multiply local infected turns")
    _check(simple.has_control(), "long action returns player control")
    _check(int(kernel.world_tick()) == kernel_tick_before, "long action still does not use legacy TickKernel")

    var weather_after: Dictionary = weather.debug_snapshot()
    _check(int(weather_after.get("transition_serial", -1)) > weather_serial_before, "coarse elapsed time advances weather transitions")
    _check(int(weather_after.get("world_tick", -1)) == long_after, "weather samples authoritative world time")
    _check(int(game.call("canonical_daylight_snapshot").get("world_tick", -1)) == long_after, "daylight samples authoritative world time")

    var hud = game.get("_hud")
    var hud_line := String(hud.presentation_snapshot().get("line_1", ""))
    _check(hud_line.contains("DAY ") and (hud_line.contains("AM") or hud_line.contains("PM")), "HUD exposes compact day/time")
    _check(
        hud_line.contains("CLEAR") or hud_line.contains("OVERCAST") or hud_line.contains("RAIN") or hud_line.contains("STORM") or hud_line.contains("FOG"),
        "HUD exposes weather"
    )

    var before_save_time: Dictionary = game.call("canonical_world_time_snapshot")
    var before_save_weather: Dictionary = game.call("canonical_weather_snapshot")
    var session: Dictionary = game.call("durable_session_snapshot")
    var owners: Dictionary = session.get("owners", {})
    _check(typeof(owners.get("world_time", null)) == TYPE_DICTIONARY, "durable snapshot contains canonical world time")
    _check(typeof(owners.get("weather", null)) == TYPE_DICTIONARY, "durable snapshot contains weather state")

    game.queue_free()
    await process_frame

    var restored = await _boot_game(session)
    if restored != null:
        var restored_time: Dictionary = restored.call("canonical_world_time_snapshot")
        var restored_weather: Dictionary = restored.call("canonical_weather_snapshot")
        _check(restored_time == before_save_time, "Continue restores exact day/time")
        _check(String(restored_weather.get("current_profile_id", "")) == String(before_save_weather.get("current_profile_id", "")), "Continue restores weather profile")
        _check(String(restored_weather.get("target_profile_id", "")) == String(before_save_weather.get("target_profile_id", "")), "Continue restores weather target")
        _check(int(restored_weather.get("transition_end_tick", -1)) == int(before_save_weather.get("transition_end_tick", -2)), "Continue restores weather progression")
        _check(int(restored.call("canonical_daylight_snapshot").get("world_tick", -1)) == int(restored_time.get("world_tick", -2)), "Continue restores matching daylight")
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
    _check(game != null and game.has_method("canonical_world_time_snapshot"), "production scene composes Slice11GameMain")
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

func _perform_clear_player_move(game, simple) -> bool:
    var world = game.get("_world")
    var query = game.get("_spatial_query")
    var player = world.placement("actor.player")
    if player == null:
        return false
    var choices: Array[Dictionary] = [
        {"intent": Intents.FORWARD, "cell": player.anchor + Facing.vector(player.facing)},
        {"intent": Intents.BACKWARD, "cell": player.anchor - Facing.vector(player.facing)},
        {"intent": Intents.TURN_LEFT, "cell": player.anchor},
        {"intent": Intents.TURN_RIGHT, "cell": player.anchor},
    ]
    for choice: Dictionary in choices:
        var intent: StringName = choice["intent"]
        if intent in [Intents.TURN_LEFT, Intents.TURN_RIGHT]:
            simple.submit_intent(intent)
            return simple.last_completed_intent() == intent
        var check = query.query_cell(choice["cell"], "actor.player", true)
        if check != null and check.is_clear():
            simple.submit_intent(intent)
            return simple.last_completed_intent() == intent
    return false

func _install_test_car(game) -> String:
    var world = game.get("_world")
    var mutations = game.get("_world_mutations")
    var inventory_mutations = game.get("_inventory_mutations")
    var profiles = game.get("_vehicle_profiles")
    var state = game.get("_vehicle_state")
    var query = game.get("_spatial_query")
    var player = world.placement("actor.player")
    if player == null:
        return ""
    var footprint = profiles.footprint(VehicleProfiles.CAR)
    for radius in range(8, 30):
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if absi(dx) != radius and absi(dy) != radius:
                    continue
                var anchor: Vector2i = player.anchor + Vector2i(dx, dy)
                var route_ok := true
                var route: Array[Vector2i] = [Vector2i.ZERO]
                route.append_array(VehicleHeading.forward_path(0, profiles.movement_cells(VehicleProfiles.CAR)))
                for offset: Vector2i in route:
                    var check = query.query_footprint(anchor + offset, Facing.Value.NORTH, footprint, "", true)
                    if check == null or not check.is_clear():
                        route_ok = false
                        break
                if not route_ok:
                    continue
                var actor_cell: Vector2i = anchor + Vector2i.RIGHT
                var actor_check = query.query_cell(actor_cell, "actor.player", true)
                if actor_check == null or not actor_check.is_clear():
                    continue
                var vehicle_id := "vehicle:slice11:car"
                if mutations.create_entity(profiles.semantic_type(VehicleProfiles.CAR), vehicle_id).is_empty():
                    return ""
                if not mutations.set_placement(vehicle_id, Layers.Channel.OBJECT, anchor, Facing.Value.NORTH, footprint):
                    mutations.remove_entity(vehicle_id)
                    return ""
                if not inventory_mutations.enroll_container(vehicle_id):
                    mutations.remove_entity(vehicle_id)
                    return ""
                if not state.create_vehicle(vehicle_id, VehicleProfiles.CAR, profiles.max_fuel(VehicleProfiles.CAR), false, 0, true):
                    return ""
                var actor_place = world.placement("actor.player")
                if not mutations.set_placement("actor.player", Layers.Channel.ACTOR, actor_cell, Facing.Value.WEST, actor_place.footprint):
                    return ""
                return vehicle_id
    return ""

func _cleanup_files() -> void:
    for path in [SAVE_A, SAVE_B, SAVE_T]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    failures.append(message)
    push_error("SLICE11_FAIL: %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("SLICE11_TIME_WEATHER_OK")
        quit(0)
        return
    quit(1)
