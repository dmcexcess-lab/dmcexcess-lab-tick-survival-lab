extends SceneTree

const REGRESSION_SEED := 20001
const PLAYER_ID := "actor.player"
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const FirearmProfiles = preload("res://scripts/simulation/combat/FirearmProfileCatalog.gd")

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
    var infected_ids: Array[String] = []
    for value: Variant in game.call("simple_infected_actor_ids"):
        infected_ids.append(String(value))
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
    var legacy_kernel = game._kernel
    var legacy_tick_before: int = int(legacy_kernel.world_tick()) if legacy_kernel != null else -1

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
    if legacy_kernel != null and int(legacy_kernel.world_tick()) != legacy_tick_before:
        _fail("canonical combat advanced the retired shared TickKernel")
        return

    # Prove the existing exact firearm/magazine/round content uses the same one-turn path.
    if not world.move_entity(attacker, center + Vector2i(40, 41), Facing.Value.WEST):
        _fail("could not move melee attacker out of the firearm lane")
        return
    var ranged_target := distant
    if not world.move_entity(ranged_target, center + Vector2i(3, 0), Facing.Value.WEST):
        _fail("could not place ranged target")
        return
    if not health.set_hp(ranged_target, health.max_hp(ranged_target)):
        _fail("could not reset ranged target health")
        return

    var firearm_id := "slice3.test.firearm"
    var magazine_id := "slice3.test.magazine"
    var round_id := "slice3.test.round"
    if world.create_entity(FirearmProfiles.SERVICE_PISTOL, firearm_id) != firearm_id:
        _fail("could not create focused-test firearm identity")
        return
    if world.create_entity(FirearmProfiles.SERVICE_MAGAZINE, magazine_id) != magazine_id:
        _fail("could not create focused-test magazine identity")
        return
    if world.create_entity(FirearmProfiles.SERVICE_ROUND, round_id) != round_id:
        _fail("could not create focused-test round identity")
        return

    var firearm_state: FirearmState = game.call("combat_firearm_state")
    if firearm_state == null or not firearm_state.ensure_firearm(firearm_id) or not firearm_state.ensure_magazine(magazine_id):
        _fail("firearm state did not accept exact physical identities")
        return
    if not game._inventory_mutations.set_container(round_id, magazine_id):
        _fail("could not place exact round into magazine")
        return
    if not firearm_state.insert_magazine(firearm_id, magazine_id):
        _fail("could not insert exact magazine")
        return
    if firearm_state.chamber_from_magazine(firearm_id) != round_id:
        _fail("could not chamber exact live round")
        return
    if not game._hand_mutations.set_item(PLAYER_ID, Slots.Value.PRIMARY_RIGHT, firearm_id):
        _fail("could not equip focused-test firearm")
        return

    var ranged_hp_before: int = health.current_hp(ranged_target)
    var ranged_turn_before: int = int(turns.turn_number())
    var ranged_tick_before: int = int(legacy_kernel.world_tick()) if legacy_kernel != null else -1
    turns.submit_intent(Intents.COMBAT_FORWARD)

    if int(turns.turn_number()) != ranged_turn_before + 1:
        _fail("firearm attack did not consume exactly one turn")
        return
    if health.current_hp(ranged_target) != ranged_hp_before - 34:
        _fail("firearm attack did not apply canonical profile damage")
        return
    if world.has_entity(round_id):
        _fail("discharged exact chambered round still exists")
        return
    if not firearm_state.chamber_round(firearm_id).is_empty():
        _fail("single-round firearm did not end with an empty chamber")
        return
    var gunshot_found := false
    for injury: ActorInjuryRecord in health.injuries(ranged_target):
        if injury.injury_type == &"gunshot":
            gunshot_found = true
            break
    if not gunshot_found:
        _fail("firearm impact did not create canonical gunshot injury")
        return
    if legacy_kernel != null and int(legacy_kernel.world_tick()) != ranged_tick_before:
        _fail("firearm combat advanced the retired shared TickKernel")
        return
    if not turns.has_control():
        _fail("player control was not returned after firearm turn")
        return

    print("SLICE3_SIMPLE_COMBAT_OK seed=%d turns=%d corpse=%s player_hp=%d firearm_damage=34" % [
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
                    center + Vector2i(2, 0),
                    center + Vector2i(3, 0),
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
