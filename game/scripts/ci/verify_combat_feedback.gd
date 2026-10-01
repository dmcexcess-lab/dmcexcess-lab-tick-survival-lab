extends SceneTree

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")

const PLAYER_ID := "actor.player"
const ZOMBIE_ID := "actor.combat_feedback_fixture"

var failures: Array[String] = []
var last_success := false
var last_reason := ""
var last_intent: StringName = &""

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(390, 844)
    var game = await _boot_real_new_game()
    if game == null:
        _finish()
        return

    var simple = game.simple_turn_controller()
    _check(simple != null and simple.has_control(), "canonical simple-turn combat is ready")
    if simple == null:
        _finish()
        return

    simple.action_resolved.connect(_on_action_resolved)
    simple.set_before_local_infected_turns(Callable(self, "_noop_before_local_infected"))

    var lane := _find_clear_combat_pair(game)
    _check(bool(lane.get("ok", false)), "clear adjacent combat fixture cells exist")
    if not bool(lane.get("ok", false)):
        _finish()
        return

    _place_player(game, lane)
    _empty_player_hands(game)
    _reset_player_health(game)
    var zombie_id := _install_zombie(game, lane)
    _check(zombie_id == ZOMBIE_ID, "adjacent zombie fixture installed")
    if zombie_id.is_empty():
        _finish()
        return

    var infected: Array[String] = [zombie_id]
    simple.set_infected_actor_ids(infected)

    var health = game.get("_health_state")
    var zombie_before := int(health.current_hp(zombie_id))
    var player_before := int(health.current_hp(PLAYER_ID))
    simple.submit_intent(Intents.COMBAT_FORWARD)

    var first_damage := zombie_before - int(health.current_hp(zombie_id))
    var first_incoming := player_before - int(health.current_hp(PLAYER_ID))
    _check(last_success and last_intent == Intents.COMBAT_FORWARD, "unarmed strike resolves as a combat action")
    _check(first_damage >= 6 and first_damage <= 12, "unarmed strike deals meaningful but non-instant damage")
    _check(first_incoming > 0 and first_incoming < first_damage, "single zombie retaliation remains dangerous but weaker than the player's committed punch")
    _check(last_reason.contains("FIST") and last_reason.contains("DMG") and last_reason.contains("ZOMBIE"), "combat result reports strike source, damage and target state")
    _check(last_reason.contains("YOU -") and last_reason.contains("HP"), "combat result reports retaliation and player HP")

    var hud = game.get("_hud")
    var first_line := ""
    if hud != null:
        first_line = String(hud.presentation_snapshot().get("line_1", ""))
    _check(first_line.contains("FIST") and first_line.contains("DMG") and first_line.contains("YOU -"), "successful combat feedback is visible in the production HUD")

    var strikes := 1
    while health.current_hp(zombie_id) > 0 and health.current_hp(PLAYER_ID) > 0 and strikes < 20:
        simple.submit_intent(Intents.COMBAT_FORWARD)
        strikes += 1

    _check(health.current_hp(zombie_id) == 0, "unarmed combat can kill a full-health zombie")
    _check(strikes <= 15, "unarmed kill does not require absurd punch counts")
    _check(health.current_hp(PLAYER_ID) > 0, "healthy player can survive a clean one-on-one unarmed zombie fight")
    _check(game.combat_corpse_state().has_corpse_for_actor(zombie_id), "unarmed kill performs canonical corpse transition")

    var death_line := ""
    if hud != null:
        death_line = String(hud.presentation_snapshot().get("line_1", ""))
    print("COMBAT_FEEDBACK_DIAG strikes=%d zombie_hp=%d player_hp=%d final_reason=%s hud=%s" % [
        strikes,
        int(health.current_hp(zombie_id)),
        int(health.current_hp(PLAYER_ID)),
        last_reason,
        death_line,
    ])
    _check(last_reason.contains("ZOMBIE DOWN"), "killing blow reports zombie death")
    _check(death_line.contains("ZOMBIE DOWN"), "production HUD reports the killing blow")

    var turn_before_miss := int(simple.turn_number())
    simple.submit_intent(Intents.COMBAT_FORWARD)
    _check(int(simple.turn_number()) == turn_before_miss + 1, "empty forward strike still consumes one ordinary combat action")
    _check(last_reason.contains("MISS"), "empty strike provides explicit miss feedback")

    var idle_turn := int(simple.turn_number())
    var idle_hp := int(health.current_hp(PLAYER_ID))
    for _i in range(20):
        await process_frame
    _check(int(simple.turn_number()) == idle_turn, "idle frames do not advance combat")
    _check(int(health.current_hp(PLAYER_ID)) == idle_hp, "idle frames do not deal combat damage")

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
        if current_scene != null and current_scene.get_script() != null \
                and String(current_scene.get_script().resource_path) == path:
            return current_scene
    return null

func _find_clear_combat_pair(game) -> Dictionary:
    var world = game.get("_world")
    var query = game.get("_spatial_query")
    var player = world.placement(PLAYER_ID)
    if player == null or query == null:
        return {"ok": false}

    var facings: Array[int] = [
        Facing.Value.NORTH,
        Facing.Value.EAST,
        Facing.Value.SOUTH,
        Facing.Value.WEST,
    ]
    for radius in range(0, 33):
        for y in range(-radius, radius + 1):
            for x in range(-radius, radius + 1):
                if radius > 0 and absi(x) != radius and absi(y) != radius:
                    continue
                var origin: Vector2i = player.anchor + Vector2i(x, y)
                if not world.has_terrain(origin):
                    continue
                var origin_check = query.query_cell(origin, PLAYER_ID, true)
                if origin_check == null or not origin_check.is_clear():
                    continue
                for facing: int in facings:
                    var target := origin + Facing.vector(facing)
                    if not world.has_terrain(target):
                        continue
                    var target_check = query.query_cell(target, PLAYER_ID, true)
                    if target_check == null or not target_check.is_clear():
                        continue
                    return {"ok": true, "origin": origin, "target": target, "facing": facing}
    return {"ok": false}

func _place_player(game, lane: Dictionary) -> void:
    var world = game.get("_world")
    var current = world.placement(PLAYER_ID)
    if current == null:
        return
    world.move_entity(PLAYER_ID, lane.get("origin", current.anchor), int(lane.get("facing", current.facing)))

func _empty_player_hands(game) -> void:
    var hands = game.get("_hand_state")
    var hand_mutations = game.get("_hand_mutations")
    var inventory_mutations = game.get("_inventory_mutations")
    for slot: int in [Slots.Value.PRIMARY_RIGHT, Slots.Value.SECONDARY_LEFT]:
        var item_id := String(hands.item_in_slot(PLAYER_ID, slot))
        if item_id.is_empty():
            continue
        if hand_mutations.clear_slot(PLAYER_ID, slot):
            inventory_mutations.set_container(item_id, PLAYER_ID)

func _reset_player_health(game) -> void:
    var health = game.get("_health_state")
    health.set_hp(PLAYER_ID, health.max_hp(PLAYER_ID))

func _install_zombie(game, lane: Dictionary) -> String:
    var world = game.get("_world")
    if world.has_entity(ZOMBIE_ID):
        world.remove_entity(ZOMBIE_ID)
    if world.create_entity(&"actor.survivor", ZOMBIE_ID) != ZOMBIE_ID:
        return ""
    if not world.set_placement(
        ZOMBIE_ID,
        Layers.Channel.ACTOR,
        lane.get("target", Vector2i.ZERO),
        Facing.turn_left(int(lane.get("facing", Facing.Value.NORTH))),
        Footprint.single_cell()
    ):
        world.remove_entity(ZOMBIE_ID)
        return ""

    var hand_mutations = game.get("_hand_mutations")
    var inventory_mutations = game.get("_inventory_mutations")
    var health = game.get("_health_state")
    if not hand_mutations.enroll_actor(ZOMBIE_ID):
        world.remove_entity(ZOMBIE_ID)
        return ""
    if not inventory_mutations.enroll_container(ZOMBIE_ID):
        world.remove_entity(ZOMBIE_ID)
        return ""
    if not health.enroll_actor(ZOMBIE_ID):
        world.remove_entity(ZOMBIE_ID)
        return ""
    return ZOMBIE_ID

func _on_action_resolved(intent: StringName, success: bool, reason: String, _turn_number: int) -> void:
    last_intent = intent
    last_success = success
    last_reason = reason

func _noop_before_local_infected() -> bool:
    return true

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    failures.append(message)
    push_error("COMBAT_FEEDBACK_FAIL: %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("COMBAT_FEEDBACK_OK")
        quit(0)
        return
    quit(1)
