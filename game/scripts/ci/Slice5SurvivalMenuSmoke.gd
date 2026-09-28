extends SceneTree

const REGRESSION_SEED := 20001
const PLAYER_ID := "actor.player"
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const ConditionStateClass = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")

const SAVE_PRIMARY := "user://slice5_session.save"
const SAVE_BACKUP := "user://slice5_session.backup.save"
const SAVE_TEMP := "user://slice5_session.tmp.save"

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("SLICE5_SURVIVAL_UI: " + message)
    quit(1)

func _run() -> void:
    _clear_save_files()
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("canonical gameplay scene missing")
        return
    var game := scene.instantiate()
    if game == null:
        _fail("could not instantiate production game")
        return
    if not game.call("configure_world_seed_override", REGRESSION_SEED):
        _fail("could not configure production seed")
        return
    if not game.call("configure_session_paths", SAVE_PRIMARY, SAVE_BACKUP, SAVE_TEMP):
        _fail("canonical turn game does not expose existing durable session path")
        return
    get_root().add_child(game)
    await process_frame
    await process_frame
    if not bool(game.call("canonical_boot_ok")) or not bool(game.call("session_boot_ok")):
        _fail("production/session boot failed")
        return

    var turns: SimpleTurnController = game.call("simple_turn_controller")
    var world: WorldState = turns._world if turns != null else null
    if turns == null or world == null or not turns.has_control():
        _fail("simple turn route unavailable")
        return
    if game.get_node_or_null("SessionControls") != null:
        _fail("duplicate legacy save strip still overlays canonical header")
        return

    # MENU is the single visible top-right control; opening it is pure UI and costs no turn/survival time.
    var shell = game._shell
    var menu_button: Button = null
    for value: Variant in shell._header_buttons.values():
        var candidate := value as Button
        if candidate != null and candidate.text == "MENU":
            menu_button = candidate
            break
    if menu_button == null or not menu_button.visible or menu_button.disabled:
        _fail("canonical MENU button is not visible/touchable")
        return
    var menu_rect := Rect2(menu_button.position, menu_button.size)
    if menu_rect.position.x < 0 or menu_rect.end.x > 640 or menu_rect.position.y < 0 or menu_rect.end.y > 844:
        _fail("MENU control is outside canonical phone viewport")
        return
    var turn_before_ui: int = turns.turn_number()
    var survival_before_ui: int = int(game.call("survival_elapsed_tick"))
    shell.open_menu()
    if shell.active_modal() != shell.MODAL_MENU:
        _fail("MENU button route does not open the production menu")
        return
    if turns.turn_number() != turn_before_ui or int(game.call("survival_elapsed_tick")) != survival_before_ui:
        _fail("opening MENU advanced gameplay/survival time")
        return
    if not shell.call("menu_has_session_actions"):
        _fail("production MENU does not contain SAVE and SAVE & MENU")
        return

    # SAVE uses the real existing DurableSessionStore and yields a Continue-compatible session.
    shell.save_requested.emit()
    await process_frame
    var loaded: Dictionary = game._session_store.load_best()
    if not bool(loaded.get("ok", false)):
        _fail("MENU SAVE did not create a valid durable session")
        return
    var resume_probe := scene.instantiate()
    if resume_probe == null or not resume_probe.call("configure_session_paths", SAVE_PRIMARY, SAVE_BACKUP, SAVE_TEMP) \
        or not resume_probe.call("configure_continue_session", loaded.get("session", {})):
        _fail("saved session is not accepted by production Continue")
        return
    resume_probe.free()
    if not shell.save_menu_requested.is_connected(Callable(game, "_on_shell_save_menu_requested")):
        _fail("SAVE & MENU is not wired to the canonical production navigation handler")
        return
    if String(game.call("save_menu_destination")) != "res://main.tscn":
        _fail("SAVE & MENU destination is not startup menu")
        return
    shell.close_modal()
    if shell.active_modal() != shell.MODAL_NONE:
        _fail("menu modal did not release correctly")
        return

    var condition = game._condition_service
    if condition == null or not condition.is_ready() or not condition.has_actor(PLAYER_ID):
        _fail("canonical condition owner missing")
        return

    # No render-frame survival progression.
    var idle_tick: int = int(game.call("survival_elapsed_tick"))
    await process_frame
    await process_frame
    if int(game.call("survival_elapsed_tick")) != idle_tick:
        _fail("survival advanced from render frames")
        return

    var infected_ids: Array[String] = []
    for value: Variant in game.call("simple_infected_actor_ids"):
        infected_ids.append(String(value))
    if infected_ids.size() < 3:
        _fail("not enough production infected for bounded actor proof")
        return
    var attacker := infected_ids[0]
    var combat_target := infected_ids[1]
    var distant := infected_ids[2]

    # Keep all threats distant while proving ordinary survival accumulation.
    var player: WorldPlacement = world.placement(PLAYER_ID)
    if player == null:
        _fail("player unplaced")
        return
    for index in range(infected_ids.size()):
        world.move_entity(infected_ids[index], player.anchor + Vector2i(40 + index, 40), Facing.Value.WEST)

    var values_before: Dictionary = condition.values(PLAYER_ID)
    var survival_start: int = int(game.call("survival_elapsed_tick"))
    var turn_start: int = turns.turn_number()
    for _index in range(3):
        turns.submit_intent(Intents.TURN_RIGHT)
    if turns.turn_number() != turn_start + 3:
        _fail("ordinary turns did not resolve")
        return
    if int(game.call("survival_elapsed_tick")) != survival_start + 3 * int(game.call("survival_ticks_per_turn")):
        _fail("survival elapsed time did not advance exactly once per ordinary turn")
        return
    var values_after: Dictionary = condition.values(PLAYER_ID)
    if int(values_after.get("satiety", 100)) >= int(values_before.get("satiety", 0)) \
        or int(values_after.get("hydration", 100)) >= int(values_before.get("hydration", 0)):
        _fail("hunger/thirst did not progress from ordinary elapsed turns")
        return

    # Rejected action advances neither turn nor survival.
    var rejected_turn: int = turns.turn_number()
    var rejected_survival: int = int(game.call("survival_elapsed_tick"))
    var rejected: Dictionary = turns.take_loot_item("missing.container", "missing.item")
    if bool(rejected.get("success", false)) or turns.turn_number() != rejected_turn \
        or int(game.call("survival_elapsed_tick")) != rejected_survival:
        _fail("rejected action advanced survival or mutated turn count")
        return

    # A run uses the existing fatigue owner; ordinary walking remains fatigue-free unless pressured.
    var arena := _find_clear_arena(world)
    if arena == Vector2i(-999999, -999999):
        _fail("no clear arena for protected routes")
        return
    if not world.move_entity(PLAYER_ID, arena, Facing.Value.EAST):
        _fail("could not place player in arena")
        return
    var fatigue_before: int = condition.current_fatigue(PLAYER_ID)
    turns.submit_intent(Intents.RUN_FORWARD)
    if condition.current_fatigue(PLAYER_ID) <= fatigue_before:
        _fail("run did not produce existing fatigue pressure")
        return

    # Combat advances survival exactly once, preserves Health damage, and local actors remain bounded.
    player = world.placement(PLAYER_ID)
    if player == null or not world.move_entity(combat_target, player.anchor + Vector2i.RIGHT, Facing.Value.WEST):
        _fail("could not place combat target")
        return
    if not game._health_state.set_hp(combat_target, 1):
        _fail("could not prepare lethal combat target")
        return
    world.move_entity(attacker, player.anchor + Vector2i.UP, Facing.Value.SOUTH)
    world.move_entity(distant, player.anchor + Vector2i(40, 40), Facing.Value.WEST)
    var distant_before: WorldPlacement = world.placement(distant)
    var hp_before: int = game._health_state.current_hp(PLAYER_ID)
    var target_hp_before: int = game._health_state.current_hp(combat_target)
    var calm_before: int = condition.value(PLAYER_ID, ConditionStateClass.CALM)
    var actor_actions_before: int = turns.individual_actor_actions()
    var combat_survival_before: int = int(game.call("survival_elapsed_tick"))
    var legacy_tick_before: int = game._kernel.world_tick()
    turns.submit_intent(Intents.COMBAT_FORWARD)
    if int(game.call("survival_elapsed_tick")) != combat_survival_before + int(game.call("survival_ticks_per_turn")):
        _fail("combat advanced survival more/less than once")
        return
    if game._kernel.world_tick() != legacy_tick_before:
        _fail("canonical survival/combat advanced legacy TickKernel")
        return
    if game._health_state.current_hp(combat_target) >= target_hp_before:
        _fail("protected combat damage regressed")
        return
    if game._health_state.current_hp(PLAYER_ID) >= hp_before or turns.individual_actor_actions() != actor_actions_before + 1:
        _fail("adjacent infected ordinary response regressed")
        return
    var distant_after: WorldPlacement = world.placement(distant)
    if distant_before == null or distant_after == null or distant_before.anchor != distant_after.anchor:
        _fail("distant infected received an individual turn")
        return
    if condition.value(PLAYER_ID, ConditionStateClass.CALM) >= calm_before:
        _fail("immediate infected/injury danger did not create canonical fear pressure")
        return

    # Real generated loot search is one survival turn; read-only inspection is zero.
    var source := _real_loot_source(game)
    if source.is_empty() or not _place_player_for_container(world, String(source["container_id"])):
        _fail("could not reach real generated loot source")
        return
    var inspect_survival: int = int(game.call("survival_elapsed_tick"))
    var inspected: Dictionary = game._loot_inspection.query(PLAYER_ID, String(source["container_id"]))
    if not bool(inspected.get("ok", false)) or int(game.call("survival_elapsed_tick")) != inspect_survival:
        _fail("loot inspection advanced survival")
        return
    var search_before: int = int(game.call("survival_elapsed_tick"))
    var search_result: Dictionary = turns.search_loot_container(String(source["container_id"]))
    if not bool(search_result.get("success", false)) \
        or int(game.call("survival_elapsed_tick")) != search_before + int(game.call("survival_ticks_per_turn")):
        _fail("scavenging did not advance survival exactly once")
        return

    # Status presentation reads the same canonical survival owner.
    var status: Dictionary = game._status_summary.query(PLAYER_ID)
    if not bool(status.get("ok", false)):
        _fail("status summary unavailable after survival migration")
        return
    if int(status.get("hunger", -1)) < 0 or int(status.get("thirst", -1)) < 0 \
        or int(status.get("fatigue", -1)) < 0 or int(status.get("sleep_pressure", -1)) < 0:
        _fail("status presentation is not reading canonical survival state")
        return

    print("SLICE5_SURVIVAL_UI_OK seed=%d turns=%d survival_tick=%d calm=%d hp=%d save=true menu=true" % [
        REGRESSION_SEED,
        turns.turn_number(),
        game.call("survival_elapsed_tick"),
        condition.value(PLAYER_ID, ConditionStateClass.CALM),
        game._health_state.current_hp(PLAYER_ID),
    ])
    _clear_save_files()
    quit(0)

func _real_loot_source(game: Node) -> Dictionary:
    for container_id: String in game._loot_state.container_ids():
        var inspection: Dictionary = game._loot_inspection.query(PLAYER_ID, container_id)
        if not bool(inspection.get("ok", false)):
            continue
        var items: Array = inspection.get("items", [])
        if not items.is_empty():
            return {"container_id": container_id}
    return {}

func _place_player_for_container(world: WorldState, container_id: String) -> bool:
    var container: WorldPlacement = world.placement(container_id)
    if container == null:
        return false
    var directions := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
    for target_cell: Vector2i in container.world_cells():
        for direction: Vector2i in directions:
            var player_cell := target_cell - direction
            if not world.has_terrain(player_cell):
                continue
            var blocked := false
            for actor_id: String in world.entities_at(player_cell, Layers.Channel.ACTOR):
                if actor_id != PLAYER_ID:
                    blocked = true
                    break
            if not blocked:
                return world.move_entity(PLAYER_ID, player_cell, Facing.from_vector(direction))
    return false

func _find_clear_arena(world: WorldState) -> Vector2i:
    var player: WorldPlacement = world.placement(PLAYER_ID)
    if player == null:
        return Vector2i(-999999, -999999)
    for radius in range(0, 10):
        for y in range(-radius, radius + 1):
            for x in range(-radius, radius + 1):
                if radius > 0 and absi(x) != radius and absi(y) != radius:
                    continue
                var center := player.anchor + Vector2i(x, y)
                var clear := true
                for cell: Vector2i in [center, center + Vector2i.RIGHT, center + Vector2i.UP]:
                    if not world.has_terrain(cell):
                        clear = false
                        break
                    for actor_id: String in world.entities_at(cell, Layers.Channel.ACTOR):
                        if actor_id != PLAYER_ID:
                            clear = false
                            break
                    if not clear:
                        break
                if clear:
                    return center
    return Vector2i(-999999, -999999)

func _clear_save_files() -> void:
    for path: String in [SAVE_PRIMARY, SAVE_BACKUP, SAVE_TEMP]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
