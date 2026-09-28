extends SceneTree

const REGRESSION_SEED := 20001
const PLAYER_ID := "actor.player"
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("SLICE3_SIMPLE_COMBAT: " + message)
    quit(1)

func _run() -> void:
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("canonical gameplay scene missing")
        return
    var game := scene.instantiate()
    if game == null or not game.call("configure_world_seed_override", REGRESSION_SEED):
        _fail("could not configure production world")
        return
    get_root().add_child(game)
    await process_frame
    await process_frame
    if not bool(game.call("canonical_boot_ok")):
        _fail("production boot failed")
        return

    var turns = game.call("simple_turn_controller")
    if turns == null or not turns.is_ready() or not turns.has_control():
        _fail("simple turn controller not ready")
        return
    var world: WorldState = turns._world
    var health: ActorHealthState = game.call("combat_health_state")
    var corpses: CorpseState = game.call("combat_corpse_state")
    var infected_ids: Array[String] = game.call("simple_infected_actor_ids")
    if world == null or health == null or corpses == null:
        _fail("combat owners missing")
        return
    if infected_ids.size() < 3:
        _fail("production world did not hydrate enough infected for bounded combat proof")
        return

    var arena := _find_arena(world)
    if arena.is_empty():
        _fail("could not locate a clear production combat arena")
        return
    var center: Vector2i = arena["center"]
    if not world.move_entity(PLAYER_ID, center, Facing.Value.EAST):
        _fail("could not place player in combat arena")
        return

    var kill_target := infected_ids[0]
    var attacker := infected_ids[1]
    var distant := infected_ids[2]
    if not world.move_entity(kill_target, center + Vector2i.RIGHT, Facing.Value.WEST):
        _fail("could not place lethal melee target")
        return
    if not world.move_entity(attacker, center + Vector2i.UP, Facing.Value.SOUTH):
        _fail("could not place adjacent infected attacker")
        return
    if not world.move_entity(distant, center + Vector2i(40, 40), Facing.Value.WEST):
        _fail("could not place distant infected")
        return
    for index in range(3, infected_ids.size()):
        world.move_entity(infected_ids[index], center + Vector2i(40 + index, 40), Facing.Value.WEST)

    if not health.has_actor(kill_target) or not health.has_actor(attacker) or not health.has_actor(distant):
        _fail("hydrated infected are not enrolled in canonical Health")
        return
    if not health.set_hp(kill_target, 1):
        _fail("could not prepare lethal target health")
        return
    if not health.set_hp(PLAYER_ID, health.max_hp(PLAYER_ID)):
        _fail("could not reset player health")
        return

    var distant_before := world.placement(distant)
    var player_hp_before: int = health.current_hp(PLAYER_ID)
    var turn_before: int = int(turns.turn_number())
    var actor_actions_before: int = int(turns.individual_actor_actions())

    turns.submit_intent(Intents.COMBAT_FORWARD)

    if int(turns.turn_number()) != turn_before + 1:
        _fail("player attack did not consume exactly one turn")
        return
    if health.current_hp(kill_target) != 0:
        _fail("player strike did not apply authoritative lethal damage")
        return
    var corpse_id := corpses.corpse_for_actor(kill_target)
    if corpse_id.is_empty() or not world.has_entity(corpse_id) or world.placement(corpse_id) == null:
        _fail("lethal infected did not transition to persistent corpse state")
        return
    if world.placement(kill_target) != null:
        _fail("dead infected remained physically placed as a living actor")
        return
    if health.current_hp(PLAYER_ID) >= player_hp_before:
        _fail("adjacent infected did not attack the player on its ordinary action")
        return
    if int(turns.individual_actor_actions()) != actor_actions_before + 1:
        _fail("bounded local actor phase did not resolve exactly one surviving adjacent infected action")
        return
    var distant_after := world.placement(distant)
    if distant_before == null or distant_after == null or distant_before.anchor != distant_after.anchor:
        _fail("distant infected received an individual combat turn")
        return
    if not turns.has_control():
        _fail("player control was not returned after combat actor phase")
        return

    print("SLICE3_SIMPLE_COMBAT_OK seed=%d turn=%d corpse=%s player_hp=%d" % [
        REGRESSION_SEED,
        turns.turn_number(),
        corpse_id,
        health.current_hp(PLAYER_ID),
    ])
    quit(0)

func _find_arena(world: WorldState) -> Dictionary:
    var player := world.placement(PLAYER_ID)
    if player == null:
        return {}
    for radius in range(0, 9):
        for y in range(-radius, radius + 1):
            for x in range(-radius, radius + 1):
                if radius > 0 and absi(x) != radius and absi(y) != radius:
                    continue
                var center := player.anchor + Vector2i(x, y)
                var cells := [
                    center,
                    center + Vector2i.RIGHT,
                    center + Vector2i.UP,
                ]
                var valid := true
                for cell: Vector2i in cells:
                    if not world.has_terrain(cell):
                        valid = false
                        break
                    for entity_id: String in world.entities_at(cell):
                        if entity_id != PLAYER_ID:
                            valid = false
                            break
                    if not valid:
                        break
                if valid:
                    return {"center": center}
    return {}
