extends SceneTree

const Store = preload("res://scripts/persistence/DurableSessionStore.gd")
const Bootstrap = preload("res://scripts/generation/integration/ProductionWorldBootstrap.gd")
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const WorldActions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const SoundProfiles = preload("res://scripts/simulation/sound/SoundEmissionProfileCatalog.gd")
const RunImpactRules = preload("res://scripts/simulation/movement/MovementRunImpactDamageService.gd")
const ExertionRules = preload("res://scripts/simulation/actors/condition/MovementConditionExertionService.gd")

const PLAYER_ID := "actor.player"
const INVALID_CELL := Vector2i(-999999, -999999)

var failures: Array[String] = []
var emissions: Array[Dictionary] = []

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    _cleanup_save()
    var game = await _boot_real_new_game()
    if game == null:
        _finish()
        return

    var sound = game.get("_spatial_sound")
    _check(sound != null and sound.emission_created.is_connected(_on_emission_created) == false, "sound emission observation available")
    if sound != null and not sound.emission_created.is_connected(_on_emission_created):
        sound.emission_created.connect(_on_emission_created)

    var simple = game.simple_turn_controller()
    _check(simple != null and simple.has_control(), "canonical simple-turn movement is ready")
    _check(RunImpactRules.IMPACT_DAMAGE_HP == 5, "run impact uses established 5 HP consequence")
    _check(ExertionRules.RUN_BASE_FATIGUE_COST == 8, "run uses established 8-point base fatigue cost")

    var door_id := _fixture_door_id(game)
    _check(not door_id.is_empty(), "materialized generated door available for passage tests")
    var blocker_semantic := _blocking_semantic(game)
    _check(not String(blocker_semantic).is_empty(), "ordinary non-door solid collision profile available")
    if door_id.is_empty() or String(blocker_semantic).is_empty():
        _finish()
        return

    # Suppress actor responses while isolating pure movement consequences.
    simple.set_before_local_infected_turns(Callable(self, "_noop_before_local_infected"))
    var no_infected: Array[String] = []
    simple.set_infected_actor_ids(no_infected)

    var powers: Dictionary = {}

    # WALK clear = exactly one cell, one action, no impact damage.
    var line := _find_clear_line(game, 3)
    _check(bool(line.get("ok", false)), "clear test lane found")
    if not bool(line.get("ok", false)):
        _finish()
        return
    _place_player(game, line)
    _reset_player_health_and_fatigue(game)
    emissions.clear()
    var walk_start: Vector2i = game.get("_world").placement(PLAYER_ID).anchor
    var walk_turn := int(simple.turn_number())
    var walk_hp := int(game.get("_health_state").current_hp(PLAYER_ID))
    simple.submit_intent(Intents.FORWARD)
    _check(game.get("_world").placement(PLAYER_ID).anchor == walk_start + _line_direction(line), "WALK clear moves exactly one square")
    _check(int(simple.turn_number()) == walk_turn + 1, "WALK clear consumes one player action")
    _check(int(game.get("_health_state").current_hp(PLAYER_ID)) == walk_hp, "ordinary WALK applies no impact damage")
    powers["walk"] = _max_power()

    # WALK into ordinary solid obstruction = blocked, no RUN damage.
    line = _find_clear_line(game, 2)
    _place_player(game, line)
    var walk_blocker := _place_blocker(game, blocker_semantic, _line_cell(line, 1), "slice15m.blocker.walk")
    _check(not walk_blocker.is_empty(), "ordinary walk blocker installed")
    _reset_player_health_and_fatigue(game)
    emissions.clear()
    walk_start = game.get("_world").placement(PLAYER_ID).anchor
    walk_turn = int(simple.turn_number())
    walk_hp = int(game.get("_health_state").current_hp(PLAYER_ID))
    simple.submit_intent(Intents.FORWARD)
    _check(game.get("_world").placement(PLAYER_ID).anchor == walk_start, "WALK into solid obstruction does not move")
    _check(int(simple.turn_number()) == walk_turn, "blocked WALK remains unsuccessful under current simple-turn rules")
    _check(int(game.get("_health_state").current_hp(PLAYER_ID)) == walk_hp, "blocked WALK does not apply RUN collision damage")
    _remove_fixture(game, walk_blocker)

    # RUN clear = two ordered cells, one turn, one fatigue charge, RUN noise.
    line = _find_clear_line(game, 3)
    _place_player(game, line)
    _reset_player_health_and_fatigue(game)
    _clear_simple_infected(simple)
    emissions.clear()
    var run_start: Vector2i = game.get("_world").placement(PLAYER_ID).anchor
    var run_turn := int(simple.turn_number())
    var fatigue_before := int(game.get("_condition_service").current_fatigue(PLAYER_ID))
    var kernel_before := int(game.get("_kernel").world_tick())
    simple.submit_intent(Intents.RUN_FORWARD)
    var fatigue_after := int(game.get("_condition_service").current_fatigue(PLAYER_ID))
    _check(game.get("_world").placement(PLAYER_ID).anchor == run_start + _line_direction(line) * 2, "RUN clear moves exactly two squares")
    _check(int(simple.turn_number()) == run_turn + 1, "two-square RUN is one player action")
    _check(fatigue_after > fatigue_before and fatigue_after - fatigue_before <= ExertionRules.RUN_BASE_FATIGUE_COST, "RUN pays one modest per-action fatigue charge")
    _check(int(game.get("_kernel").world_tick()) == kernel_before, "RUN does not advance compatibility TickKernel")
    powers["run"] = _max_power()

    # Existing zombie hearing receives canonical movement sound.
    var hearer := _fixture_hearing_infected(game, run_start)
    _check(not hearer.is_empty(), "infected hearing fixture available")
    if not hearer.is_empty():
        sound.register_listener(hearer)
        line = _find_clear_line(game, 3)
        _place_player(game, line)
        _clear_simple_infected(simple)
        emissions.clear()
        simple.submit_intent(Intents.RUN_FORWARD)
        _check(not sound.active_observations(hearer).is_empty(), "canonical RUN reaches existing zombie hearing system")

    # RUN: first clear, second blocked -> one-square partial move + 5 HP impact.
    line = _find_clear_line(game, 3)
    _place_player(game, line)
    var blocker2 := _place_blocker(game, blocker_semantic, _line_cell(line, 2), "slice15m.blocker.second")
    _reset_player_health_and_fatigue(game)
    _clear_simple_infected(simple)
    emissions.clear()
    run_start = game.get("_world").placement(PLAYER_ID).anchor
    run_turn = int(simple.turn_number())
    var hp_before := int(game.get("_health_state").current_hp(PLAYER_ID))
    fatigue_before = int(game.get("_condition_service").current_fatigue(PLAYER_ID))
    simple.submit_intent(Intents.RUN_FORWARD)
    _check(game.get("_world").placement(PLAYER_ID).anchor == _line_cell(line, 1), "RUN preserves legal first step before second-step impact")
    _check(int(game.get("_health_state").current_hp(PLAYER_ID)) == hp_before - RunImpactRules.IMPACT_DAMAGE_HP, "second-step RUN impact deals 5 HP")
    _check(int(simple.turn_number()) == run_turn + 1, "partial RUN collision remains one action")
    _check(int(game.get("_condition_service").current_fatigue(PLAYER_ID)) > fatigue_before, "partial RUN collision still pays RUN fatigue")
    powers["impact"] = _max_power()
    _remove_fixture(game, blocker2)

    # RUN: first square blocked -> no movement + damage, still one action/fatigue.
    line = _find_clear_line(game, 2)
    _place_player(game, line)
    var blocker1 := _place_blocker(game, blocker_semantic, _line_cell(line, 1), "slice15m.blocker.first")
    _reset_player_health_and_fatigue(game)
    _clear_simple_infected(simple)
    emissions.clear()
    run_start = game.get("_world").placement(PLAYER_ID).anchor
    run_turn = int(simple.turn_number())
    hp_before = int(game.get("_health_state").current_hp(PLAYER_ID))
    fatigue_before = int(game.get("_condition_service").current_fatigue(PLAYER_ID))
    simple.submit_intent(Intents.RUN_FORWARD)
    _check(game.get("_world").placement(PLAYER_ID).anchor == run_start, "first-step RUN impact does not move player")
    _check(int(game.get("_health_state").current_hp(PLAYER_ID)) == hp_before - RunImpactRules.IMPACT_DAMAGE_HP, "first-step RUN impact damages player")
    _check(int(simple.turn_number()) == run_turn + 1, "first-step impact still consumes one RUN action")
    _check(int(game.get("_condition_service").current_fatigue(PLAYER_ID)) > fatigue_before, "first-step impact still pays RUN fatigue")
    _remove_fixture(game, blocker1)

    # Explicit OPEN remains the quiet door route.
    line = _find_clear_line(game, 3)
    _prepare_door(game, door_id, _line_cell(line, 1), false)
    _place_player(game, line)
    _clear_simple_infected(simple)
    emissions.clear()
    var manual := game.run_simple_contextual_action(PLAYER_ID, door_id, WorldActions.DOOR_OPEN)
    _check(bool(manual.get("success", false)), "explicit OPEN still works")
    _check(game.get("_door_state").state(door_id) == DoorValue.OPEN, "explicit OPEN changes authoritative door state")
    powers["manual_open"] = _max_power()

    # WALK through closed unlocked door = auto-open + one-cell move in one action.
    _prepare_door(game, door_id, _line_cell(line, 1), false)
    _place_player(game, line)
    _clear_simple_infected(simple)
    emissions.clear()
    walk_turn = int(simple.turn_number())
    simple.submit_intent(Intents.FORWARD)
    _check(game.get("_world").placement(PLAYER_ID).anchor == _line_cell(line, 1), "WALK passes through closed unlocked door")
    _check(game.get("_door_state").state(door_id) == DoorValue.OPEN, "WALK auto-opens authoritative door")
    _check(int(simple.turn_number()) == walk_turn + 1, "WALK-through-door is one action")
    powers["walk_door"] = _max_power()

    # WALK into locked door = no pass, no damage.
    _prepare_door(game, door_id, _line_cell(line, 1), true)
    _place_player(game, line)
    _reset_player_health_and_fatigue(game)
    _clear_simple_infected(simple)
    emissions.clear()
    walk_start = game.get("_world").placement(PLAYER_ID).anchor
    walk_turn = int(simple.turn_number())
    walk_hp = int(game.get("_health_state").current_hp(PLAYER_ID))
    simple.submit_intent(Intents.FORWARD)
    _check(game.get("_world").placement(PLAYER_ID).anchor == walk_start, "locked door stops WALK")
    _check(game.get("_door_state").state(door_id) == DoorValue.CLOSED and game.get("_world_interaction_state").is_locked(door_id), "locked door remains closed and locked after WALK")
    _check(int(game.get("_health_state").current_hp(PLAYER_ID)) == walk_hp, "walking into locked door causes no RUN impact damage")
    _check(int(simple.turn_number()) == walk_turn, "locked-door WALK remains unsuccessful")

    # RUN through unlocked door = open + continue to second cell in one action.
    _prepare_door(game, door_id, _line_cell(line, 1), false)
    _place_player(game, line)
    _reset_player_health_and_fatigue(game)
    _clear_simple_infected(simple)
    emissions.clear()
    run_turn = int(simple.turn_number())
    simple.submit_intent(Intents.RUN_FORWARD)
    _check(game.get("_world").placement(PLAYER_ID).anchor == _line_cell(line, 2), "RUN continues through unlocked door to second square")
    _check(game.get("_door_state").state(door_id) == DoorValue.OPEN, "RUN auto-opens unlocked door")
    _check(int(simple.turn_number()) == run_turn + 1, "RUN-through-door remains one player action")
    powers["run_door"] = _max_power()

    # RUN into locked door = stop + impact damage + loud sound.
    _prepare_door(game, door_id, _line_cell(line, 1), true)
    _place_player(game, line)
    _reset_player_health_and_fatigue(game)
    _clear_simple_infected(simple)
    emissions.clear()
    run_start = game.get("_world").placement(PLAYER_ID).anchor
    hp_before = int(game.get("_health_state").current_hp(PLAYER_ID))
    run_turn = int(simple.turn_number())
    simple.submit_intent(Intents.RUN_FORWARD)
    _check(game.get("_world").placement(PLAYER_ID).anchor == run_start, "locked door stops RUN at first step")
    _check(game.get("_door_state").state(door_id) == DoorValue.CLOSED and game.get("_world_interaction_state").is_locked(door_id), "RUN does not unlock or open locked door")
    _check(int(game.get("_health_state").current_hp(PLAYER_ID)) == hp_before - RunImpactRules.IMPACT_DAMAGE_HP, "RUN into locked door applies impact damage")
    _check(int(simple.turn_number()) == run_turn + 1, "RUN into locked door is one completed action")

    # Ordered RUN: unlocked door first, solid blocker second.
    line = _find_clear_line(game, 3)
    _prepare_door(game, door_id, _line_cell(line, 1), false)
    var blocker_after_door := _place_blocker(game, blocker_semantic, _line_cell(line, 2), "slice15m.blocker.afterdoor")
    _place_player(game, line)
    _reset_player_health_and_fatigue(game)
    _clear_simple_infected(simple)
    emissions.clear()
    hp_before = int(game.get("_health_state").current_hp(PLAYER_ID))
    fatigue_before = int(game.get("_condition_service").current_fatigue(PLAYER_ID))
    run_turn = int(simple.turn_number())
    simple.submit_intent(Intents.RUN_FORWARD)
    var persisted_anchor: Vector2i = game.get("_world").placement(PLAYER_ID).anchor
    var persisted_hp := int(game.get("_health_state").current_hp(PLAYER_ID))
    var persisted_fatigue := int(game.get("_condition_service").current_fatigue(PLAYER_ID))
    _check(persisted_anchor == _line_cell(line, 1), "RUN through door then obstruction preserves first legal step")
    _check(game.get("_door_state").state(door_id) == DoorValue.OPEN, "door remains opened before later RUN collision")
    _check(persisted_hp == hp_before - RunImpactRules.IMPACT_DAMAGE_HP, "post-door collision damages player")
    _check(persisted_fatigue > fatigue_before, "post-door collision pays RUN fatigue once")
    _check(int(simple.turn_number()) == run_turn + 1, "door+collision RUN is one player action")
    _remove_fixture(game, blocker_after_door)

    # Noise hierarchy from real emitted acoustic powers.
    _check(int(powers.get("manual_open", 0)) < int(powers.get("walk", 0)), "manual OPEN is quieter than walking")
    _check(int(powers.get("walk", 0)) < int(powers.get("walk_door", 0)), "WALK-through-door is louder than ordinary WALK")
    _check(int(powers.get("walk_door", 0)) < int(powers.get("run", 0)), "ordinary RUN is louder than WALK-through-door")
    _check(int(powers.get("run", 0)) < int(powers.get("run_door", 0)), "RUN-through-door is louder than ordinary RUN")
    _check(int(powers.get("run_door", 0)) < int(powers.get("impact", 0)), "RUN impact is loudest movement consequence")
    print("MOVEMENT_NOISE_POWERS %s" % str(powers))

    # One RUN still produces at most one local response opportunity, and a known
    # non-active infected remains dormant.
    simple.set_before_local_infected_turns(Callable(game, "_refresh_simulation_boundary"))
    game.call("_refresh_simulation_boundary")
    var active_count: int = game.active_infected_ids().size()
    var far_id := _known_dormant_infected(game)
    var far_before := INVALID_CELL
    if not far_id.is_empty() and game.get("_world").placement(far_id) != null:
        far_before = game.get("_world").placement(far_id).anchor
    line = _find_clear_line(game, 3)
    _place_player(game, line)
    game.call("_refresh_simulation_boundary")
    active_count = game.active_infected_ids().size()
    var actor_actions_before := int(simple.individual_actor_actions())
    simple.submit_intent(Intents.RUN_FORWARD)
    _check(int(simple.individual_actor_actions()) - actor_actions_before <= active_count, "two-cell RUN gives local infected at most one action each")
    if not far_id.is_empty() and far_before != INVALID_CELL:
        var far_after = game.get("_world").placement(far_id)
        _check(far_after != null and far_after.anchor == far_before, "known dormant infected remains unchanged by RUN")

    # Re-establish the persisted door+impact state and prove real SAVE/MENU/CONTINUE.
    simple.set_before_local_infected_turns(Callable(self, "_noop_before_local_infected"))
    _clear_simple_infected(simple)
    line = _find_clear_line(game, 3)
    _prepare_door(game, door_id, _line_cell(line, 1), false)
    var persist_blocker := _place_blocker(game, blocker_semantic, _line_cell(line, 2), "slice15m.blocker.persist")
    _place_player(game, line)
    _reset_player_health_and_fatigue(game)
    _clear_simple_infected(simple)
    simple.submit_intent(Intents.RUN_FORWARD)
    persisted_anchor = game.get("_world").placement(PLAYER_ID).anchor
    persisted_hp = int(game.get("_health_state").current_hp(PLAYER_ID))
    persisted_fatigue = int(game.get("_condition_service").current_fatigue(PLAYER_ID))
    _check(game.get("_door_state").state(door_id) == DoorValue.OPEN, "persistence fixture door is auto-opened")
    game._on_shell_save_menu_requested()
    var menu = await _wait_for_scene_script("res://scripts/ui/StartupMenu.gd", 360)
    _check(menu != null, "SAVE & MENU returns to StartupMenu")
    if menu == null:
        _finish()
        return
    menu.call("_on_continue_pressed")
    var continued = await _wait_for_scene_script("res://scripts/app/ProductionGameMain.gd", 480)
    _check(continued != null and continued.session_boot_ok(), "real CONTINUE boots after movement maintenance")
    if continued != null:
        var restored = continued.get("_world").placement(PLAYER_ID)
        _check(restored != null and restored.anchor == persisted_anchor, "Continue restores partial RUN position")
        _check(continued.get("_door_state").state(door_id) == DoorValue.OPEN, "Continue preserves auto-opened door")
        _check(int(continued.get("_health_state").current_hp(PLAYER_ID)) == persisted_hp, "Continue preserves RUN impact Health consequence")
        _check(int(continued.get("_condition_service").current_fatigue(PLAYER_ID)) == persisted_fatigue, "Continue preserves RUN fatigue consequence")
        var idle_anchor: Vector2i = restored.anchor
        var idle_fatigue := int(continued.get("_condition_service").current_fatigue(PLAYER_ID))
        var idle_actions := int(continued.simple_turn_controller().individual_actor_actions())
        for _i in range(30):
            await process_frame
        _check(continued.get("_world").placement(PLAYER_ID).anchor == idle_anchor, "idle frames do not move player")
        _check(int(continued.get("_condition_service").current_fatigue(PLAYER_ID)) == idle_fatigue, "idle frames do not drain RUN fatigue")
        _check(int(continued.simple_turn_controller().individual_actor_actions()) == idle_actions, "idle frames do not run zombies")
        _check(continued.get("_controller") == null and continued.get("_vehicle_controller") == null, "deleted controller architecture remains absent")
        continued.queue_free()
        await process_frame

    _cleanup_save()
    _finish()

func _boot_real_new_game():
    var packed := load("res://main.tscn") as PackedScene
    _check(packed != null, "fresh production main.tscn loads")
    if packed == null:
        return null
    var menu = packed.instantiate()
    root.add_child(menu)
    current_scene = menu
    await process_frame
    await process_frame
    menu.call("_launch_game", {})
    var game = await _wait_for_scene_script("res://scripts/app/ProductionGameMain.gd", 480)
    _check(game != null and game.session_boot_ok(), "StartupMenu NEW GAME reaches healthy ProductionGameMain")
    return game

func _wait_for_scene_script(path: String, frames: int):
    for _i in range(frames):
        await process_frame
        if current_scene != null and current_scene.get_script() != null             and String(current_scene.get_script().resource_path) == path:
            return current_scene
    return null

func _fixture_door_id(game) -> String:
    for door_id: String in game.get("_door_state").door_ids():
        if game.get("_world").has_entity(door_id) and game.get("_world").placement(door_id) != null:
            return door_id
    return ""

func _blocking_semantic(game) -> StringName:
    var catalog = game.get("_collision_catalog")
    for semantic: StringName in catalog.semantic_types():
        if String(semantic).begins_with("door."):
            continue
        var profile = catalog.profile_for(semantic)
        if profile != null and profile.blocks_movement:
            return semantic
    return &""

func _find_clear_line(game, length: int) -> Dictionary:
    var world = game.get("_world")
    var query = game.get("_spatial_query")
    var player = world.placement(PLAYER_ID)
    if player == null:
        return {"ok": false}
    for radius in range(2, 22):
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if absi(dx) != radius and absi(dy) != radius:
                    continue
                var origin := player.anchor + Vector2i(dx, dy)
                for facing: int in [Facing.Value.NORTH, Facing.Value.EAST, Facing.Value.SOUTH, Facing.Value.WEST]:
                    var direction := Facing.vector(facing)
                    var clear := true
                    for step in range(0, length + 1):
                        var cell := origin + direction * step
                        if not game.cell_active(cell) or not world.has_terrain(cell):
                            clear = false
                            break
                        var check = query.query_cell(cell, PLAYER_ID, true)
                        if check == null or not check.is_clear():
                            clear = false
                            break
                    if clear:
                        return {"ok": true, "origin": origin, "facing": facing, "direction": direction}
    return {"ok": false}

func _line_direction(line: Dictionary) -> Vector2i:
    return line.get("direction", Vector2i.ZERO)

func _line_cell(line: Dictionary, step: int) -> Vector2i:
    return line.get("origin", Vector2i.ZERO) + _line_direction(line) * step

func _place_player(game, line: Dictionary) -> void:
    game.get("_world").move_entity(PLAYER_ID, line.get("origin", Vector2i.ZERO), int(line.get("facing", Facing.Value.NORTH)))

func _prepare_door(game, door_id: String, cell: Vector2i, locked: bool) -> void:
    var state = game.get("_world_interaction_state")
    state.set_locked(door_id, locked, &"movement_maintenance_fixture")
    state.set_board_count(door_id, 0, &"movement_maintenance_fixture")
    state.set_broken(door_id, false, &"movement_maintenance_fixture")
    game.get("_door_transition").close_manually(PLAYER_ID, door_id)
    var placement = game.get("_world").placement(door_id)
    game.get("_world").move_entity(door_id, cell, placement.facing)

func _place_blocker(game, semantic: StringName, cell: Vector2i, entity_id: String) -> String:
    var world = game.get("_world")
    if world.has_entity(entity_id):
        world.remove_entity(entity_id)
    if world.create_entity(semantic, entity_id) != entity_id:
        return ""
    if not world.set_placement(entity_id, Layers.Channel.OBJECT, cell, Facing.Value.NORTH, Footprint.single_cell()):
        world.remove_entity(entity_id)
        return ""
    return entity_id

func _remove_fixture(game, entity_id: String) -> void:
    if not entity_id.is_empty() and game.get("_world").has_entity(entity_id):
        game.get("_world").remove_entity(entity_id)

func _reset_player_health_and_fatigue(game) -> void:
    var health = game.get("_health_state")
    health.set_hp(PLAYER_ID, health.max_hp(PLAYER_ID))
    game.get("_condition_service").relieve_fatigue(PLAYER_ID, 100, &"movement_maintenance_reset")

func _clear_simple_infected(simple) -> void:
    var empty_ids: Array[String] = []
    simple.set_infected_actor_ids(empty_ids)

func _fixture_hearing_infected(game, origin: Vector2i) -> String:
    for actor_id: String in game.known_infected_ids():
        if game.get("_world").placement(actor_id) == null:
            continue
        var target := origin + Vector2i(0, 3)
        var check = game.get("_spatial_query").query_cell(target, actor_id, true)
        if check != null and check.is_clear():
            game.get("_world").move_entity(actor_id, target, Facing.Value.SOUTH)
            return actor_id
    return ""

func _known_dormant_infected(game) -> String:
    var active: Array[String] = game.active_infected_ids()
    for actor_id: String in game.known_infected_ids():
        if not active.has(actor_id) and game.get("_world").placement(actor_id) != null:
            return actor_id
    return ""

func _max_power() -> int:
    var result := 0
    for row: Dictionary in emissions:
        result = maxi(result, int(row.get("power", 0)))
    return result

func _on_emission_created(
    event_id: String,
    profile_id: StringName,
    acoustic_power: int,
    origin_cell: Vector2i,
    source_entity_id: String
) -> void:
    emissions.append({
        "event_id": event_id,
        "profile_id": profile_id,
        "power": acoustic_power,
        "cell": origin_cell,
        "source": source_entity_id,
    })

func _noop_before_local_infected() -> bool:
    return true

func _cleanup_save() -> void:
    for path in [Store.DEFAULT_PRIMARY_PATH, Store.DEFAULT_BACKUP_PATH, Store.DEFAULT_TEMP_PATH]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    failures.append(message)
    push_error("MOVEMENT_MAINT_FAIL: %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("TURN_BASED_RUN_DOOR_OK")
        quit(0)
        return
    quit(1)
