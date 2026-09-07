extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Rules = preload("res://scripts/foundation/time/TickRules.gd")
const SoundProfiles = preload("res://scripts/simulation/sound/SoundEmissionProfileCatalog.gd")
const Behavior = preload("res://scripts/simulation/infected/FirstInfectedBehaviorService.gd")

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("run_smoke")

func run_smoke() -> void:
    var packed := load("res://main.tscn") as PackedScene
    expect(packed != null, "production main scene loads")
    if packed == null:
        return finish()
    var game := packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame

    var world: WorldState = game.get("_world")
    var mutations: WorldMutationService = game.get("_world_mutations")
    var spatial: SpatialQueryService = game.get("_spatial_query")
    var kernel: TickKernel = game.get("_kernel")
    var health: ActorHealthState = game.get("_health_state")
    var memory: PerceptionMemoryStore = game.get("_perception_memory")
    var sound: SpatialSoundService = game.get("_spatial_sound")
    var infected: InfectedState = game.get("_infected_state")
    var infected_perception: ObserverPerceptionService = game.get("_first_infected_perception")
    var behavior: FirstInfectedBehaviorService = game.get("_first_infected_behavior")
    var first: Dictionary = game.get("_first_infected_result")

    expect(bool(first.get("ok", false)), "production first resident-backed infected remains hydrated")
    expect(behavior != null and behavior.is_running(), "production first infected behavior loop is running")
    expect(infected_perception != null and infected_perception.is_ready(), "first infected owns a real System-23 observer")
    if not failures.is_empty():
        game.queue_free()
        return finish()

    var actor_id := String(first.get("actor_id", ""))
    var resident_before := infected.resident_record(actor_id)
    expect(not resident_before.is_empty(), "resident/infection provenance exists before behavior")
    expect(kernel.is_decision_paused(), "production starts at player decision pause")
    expect(behavior.action_submission_count() == 0, "infected does not advance on render frames while player is paused")

    # --- Visible pursuit -> ordinary movement -> System-37 attack.
    var visual_setup := place_visible_lane(world, mutations, spatial, infected_perception, actor_id)
    expect(bool(visual_setup.get("ok", false)), "found truthful clear visible lane to player")
    if bool(visual_setup.get("ok", false)):
        infected_perception.recompute(&"prompt_visual_setup")
        var seen := memory.last_seen_actor(actor_id, Fixture.PLAYER_ID)
        expect(not seen.is_empty() and seen.get("cell", Vector2i.ZERO) == world.placement(Fixture.PLAYER_ID).anchor, "infected learns player cell through its System-23 actor observation")
        expect(infected_perception.is_visible(seen.get("cell", Vector2i.ZERO)), "player observation is currently visible rather than omniscient remembered truth")
        expect(behavior.current_intention() == Behavior.PURSUE_VISIBLE, "visible observation deterministically becomes pursue-visible intention")

        var player_hp_before := health.current_hp(Fixture.PLAYER_ID)
        var history_before := behavior.action_submission_count()
        var player_hold := kernel.begin_action(Fixture.PLAYER_ID, &"prompt.player.hold_visual", 60, Rules.InterruptionPolicy.COMMITTED)
        expect(player_hold > 0, "player commitment opens the shared WHEN clock")
        expect(behavior.action_submission_count() > history_before, "infected autonomously submits an ordinary action when the shared clock opens")
        run_until(func() -> bool: return health.current_hp(Fixture.PLAYER_ID) < player_hp_before, kernel, 80)
        var visual_history := behavior.action_history()
        expect(_history_has_prefix(visual_history, "movement."), "visible pursuit uses ordinary movement actions")
        expect(_history_has_prefix(visual_history, "combat.strike"), "contact pursuit submits ordinary System-37 strike")
        expect(health.current_hp(Fixture.PLAYER_ID) < player_hp_before, "System-37 infected strike causes canonical player Health consequence")
        expect(infected.resident_record(actor_id) == resident_before, "visual pursuit/combat preserves resident infection provenance")

    reset_actions(kernel, actor_id)
    health.heal(Fixture.PLAYER_ID, 100)

    # --- No visual truth -> real System-26 propagated cue -> uncertain-cell investigation.
    var hearing_setup := place_hearing_lane(world, mutations, spatial, infected_perception, actor_id)
    expect(bool(hearing_setup.get("ok", false)), "found truthful hearing-only setup")
    memory.forget_actor(actor_id, Fixture.PLAYER_ID)
    infected_perception.recompute(&"prompt_hearing_setup")
    expect(memory.last_seen_actor(actor_id, Fixture.PLAYER_ID).is_empty(), "hearing scenario contains no player visual actor knowledge")

    var player_placement: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    var event_id := sound.emit_sound(
        SoundProfiles.WALK_STEP,
        player_placement.anchor,
        Fixture.PLAYER_ID,
        "prompt.player.external_step"
    )
    expect(not event_id.is_empty(), "real System-26 sound emission propagates")
    var heard := _latest_nonlocal(sound.active_observations(actor_id), world.placement(actor_id).anchor)
    expect(heard != null, "infected receives observer-scoped heard-sound observation")
    if heard != null:
        expect(behavior.current_intention() == Behavior.INVESTIGATE_SOUND, "heard observation becomes investigate-sound intention while player remains unseen")
        expect(behavior.target_actor_id().is_empty(), "auditory intention carries no hidden exact source actor identity")
        expect(behavior.target_cell() == heard.perceived_cell, "auditory intention targets only System-26 perceived cell")
        var start_cell := world.placement(actor_id).anchor
        var start_distance := _manhattan(start_cell, heard.perceived_cell)
        var hearing_history_before := behavior.action_submission_count()
        var hearing_hold := kernel.begin_action(Fixture.PLAYER_ID, &"prompt.player.hold_hearing", 60, Rules.InterruptionPolicy.COMMITTED)
        expect(hearing_hold > 0, "hearing investigation runs on the same player-opened WHEN clock")
        run_until(func() -> bool: return world.has_placement(actor_id) and world.placement(actor_id).anchor != start_cell, kernel, 80)
        expect(behavior.action_submission_count() > hearing_history_before, "heard cue causes autonomous ordinary action submission")
        var moved_cell := world.placement(actor_id).anchor if world.has_placement(actor_id) else start_cell
        expect(moved_cell != start_cell, "infected physically moves while investigating sound")
        expect(_manhattan(moved_cell, heard.perceived_cell) < start_distance, "investigation movement advances toward perceived—not true-source—location")
        expect(infected.resident_record(actor_id) == resident_before, "heard-sound investigation preserves resident infection provenance")

    reset_actions(kernel, actor_id)

    # --- Generic death ends behavior and prevents further autonomous submission.
    var submissions_before_death := behavior.action_submission_count()
    expect(health.apply_damage(actor_id, 1000), "canonical Health can lethally damage first infected")
    expect(not behavior.is_running(), "behavior stops when generic death removes living actor truth")
    expect(not world.has_placement(actor_id), "generic death removes infected ACTOR occupancy")
    expect(infected.is_infected(actor_id) and infected.resident_record(actor_id) == resident_before, "death still preserves resident/infection provenance")
    var post_death_hold := kernel.begin_action(Fixture.PLAYER_ID, &"prompt.player.after_infected_death", 20, Rules.InterruptionPolicy.COMMITTED)
    expect(post_death_hold > 0, "shared WHEN can continue after infected death")
    kernel.run_until_stop()
    expect(behavior.action_submission_count() == submissions_before_death, "dead infected submits no further movement or combat actions")
    expect(not kernel.has_active_action(actor_id), "dead infected owns no active WHEN action")

    game.queue_free()
    await process_frame
    finish()

func place_visible_lane(world: WorldState, mutations: WorldMutationService, spatial: SpatialQueryService, perception: ObserverPerceptionService, actor_id: String) -> Dictionary:
    var player: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if player == null:
        return {"ok": false}
    for distance in [2, 3]:
        for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
            var candidate: Vector2i = player.anchor + direction * distance
            if not _clear_lane(spatial, actor_id, player.anchor, direction, distance):
                continue
            if world.has_placement(actor_id):
                mutations.unplace_entity(actor_id)
            var toward_player := Facing.from_vector(-direction)
            if not mutations.set_placement(actor_id, Layers.Channel.ACTOR, candidate, toward_player, Footprint.single_cell()):
                continue
            perception.recompute(&"prompt_visible_lane_probe")
            var seen := perception.memory_store().last_seen_actor(actor_id, Fixture.PLAYER_ID)
            if not seen.is_empty() and perception.is_visible(player.anchor):
                return {"ok": true, "cell": candidate, "distance": distance}
    return {"ok": false}

func place_hearing_lane(world: WorldState, mutations: WorldMutationService, spatial: SpatialQueryService, perception: ObserverPerceptionService, actor_id: String) -> Dictionary:
    var player: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if player == null:
        return {"ok": false}
    for distance in [4, 5, 6]:
        for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
            var candidate: Vector2i = player.anchor + direction * distance
            if not _clear_lane(spatial, actor_id, player.anchor, direction, distance):
                continue
            if world.has_placement(actor_id):
                mutations.unplace_entity(actor_id)
            var away_from_player := Facing.from_vector(direction)
            if not mutations.set_placement(actor_id, Layers.Channel.ACTOR, candidate, away_from_player, Footprint.single_cell()):
                continue
            perception.recompute(&"prompt_hearing_lane_probe")
            if not perception.is_visible(player.anchor):
                return {"ok": true, "cell": candidate, "distance": distance}
    return {"ok": false}

func _clear_lane(spatial: SpatialQueryService, actor_id: String, origin: Vector2i, direction: Vector2i, distance: int) -> bool:
    for step in range(1, distance + 1):
        var cell := origin + direction * step
        if not spatial.has_terrain(cell):
            return false
        var query := spatial.query_cell(cell, actor_id, true)
        if query == null or not query.is_clear():
            return false
    return true

func _latest_nonlocal(values: Array[HeardSoundObservation], local_cell: Vector2i) -> HeardSoundObservation:
    var best: HeardSoundObservation = null
    for value: HeardSoundObservation in values:
        if value == null or value.perceived_cell == local_cell:
            continue
        if best == null or value.heard_tick > best.heard_tick or (value.heard_tick == best.heard_tick and value.cue_id < best.cue_id):
            best = value
    return best

func run_until(done: Callable, kernel: TickKernel, limit: int) -> void:
    var guard := 0
    while not done.call() and guard < limit and not kernel.is_decision_paused():
        kernel.run_next_batch()
        guard += 1

func reset_actions(kernel: TickKernel, infected_id: String) -> void:
    kernel.set_hard_paused(true)
    var infected_action := kernel.active_action_for_actor(infected_id)
    if infected_action != null:
        kernel.interrupt_action(infected_action.serial, "prompt_scenario_reset", true)
    var player_action := kernel.active_action_for_actor(Fixture.PLAYER_ID)
    if player_action != null:
        kernel.interrupt_action(player_action.serial, "prompt_scenario_reset", true)
    kernel.set_hard_paused(false)
    # Apply pending player decision pause without advancing unrelated time.
    kernel.run_next_batch()

func _history_has_prefix(history: Array[Dictionary], prefix: String) -> bool:
    for entry: Dictionary in history:
        if String(entry.get("action_type", "")).begins_with(prefix):
            return true
    return false

func _manhattan(a: Vector2i, b: Vector2i) -> int:
    return absi(a.x - b.x) + absi(a.y - b.y)

func expect(ok: bool, message: String) -> void:
    if ok:
        print("PASS: %s" % message)
    else:
        failures.append(message)
        push_error("FAIL: %s" % message)

func finish() -> void:
    if failures.is_empty():
        print("PROMPT_FIRST_INFECTED_BEHAVIOR_SMOKE: PASS")
        quit(0)
    else:
        push_error("PROMPT_FIRST_INFECTED_BEHAVIOR_SMOKE: FAIL (%d)" % failures.size())
        for value: String in failures:
            push_error(" - %s" % value)
        quit(1)
