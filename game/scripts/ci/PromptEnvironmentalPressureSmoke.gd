extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Rules = preload("res://scripts/foundation/time/TickRules.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const WorldActions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")

const PROMPT_DOOR_SEMANTIC: StringName = &"door.prompt_pressure"
const PROMPT_DOOR_ID: String = "door.promptpressure.001"
const PROMPT_WINDOW_SEMANTIC: StringName = &"window.prompt_pressure"
const PROMPT_WINDOW_ID: String = "window.promptpressure.001"
const PROMPT_WINDOW_ACTOR: String = "actor.promptpressure.window"

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

    expect(game is EnvironmentalPressureGameMain, "production root includes System 39 environmental pressure")
    var world: WorldState = game.get("_world")
    var mutations: WorldMutationService = game.get("_world_mutations")
    var spatial: SpatialQueryService = game.get("_spatial_query")
    var collision: CollisionCatalog = game.get("_collision_catalog")
    var kernel: TickKernel = game.get("_kernel")
    var door_state: DoorStateStore = game.get("_door_state")
    var door_mutations: DoorStateMutationService = game.get("_door_mutations")
    var door_transition: DoorPhysicalTransitionService = game.get("_door_transition")
    var interactable: WorldInteractableState = game.get("_world_interaction_state")
    var sound: SpatialSoundService = game.get("_spatial_sound")
    var memory: PerceptionMemoryStore = game.get("_perception_memory")
    var world_actions: WorldInteractionActionService = game.get("_world_interaction_actions")
    var cohort: ActiveInfectedCohortService = game.infected_cohort_service()
    var pressure: ActorOpeningPressureActionService = game.opening_pressure_service()
    var streaming: WorldStreamingCoordinator = Fixture.streaming_coordinator()

    expect(pressure != null and pressure.is_ready(), "generic opening pressure service is ready")
    expect(cohort != null and cohort.is_configured(), "resident-backed infected cohort remains configured")
    expect(game.ACTIVE_INFECTED_COHORT_SIZE == 8, "System 39 preserves production cohort size eight")
    var ids: Array[String] = cohort.roster_actor_ids()
    expect(ids.size() >= 2, "two real resident-backed infected are available for pressure proof")
    if not failures.is_empty():
        game.queue_free()
        return finish()

    var first_id: String = ids[0]
    var second_id: String = ids[1]
    var first_behavior: CohortInfectedBehaviorService = cohort.behavior_for_actor(first_id)
    var second_behavior: CohortInfectedBehaviorService = cohort.behavior_for_actor(second_id)
    expect(first_behavior != null and first_behavior.opening_pressure_service() == pressure, "first infected uses shared generic pressure owner")
    expect(second_behavior != null and second_behavior.opening_pressure_service() == pressure, "second infected uses the same generic pressure owner")

    var player: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    var line: Dictionary = _find_clear_line(spatial, streaming, player.anchor, 11)
    expect(not line.is_empty(), "focused fixture finds a real clear active-stream line")
    if line.is_empty():
        game.queue_free()
        return finish()

    var base: Vector2i = line["base"]
    var facing: int = int(line["facing"])
    var direction: Vector2i = Facing.vector(facing)
    var second_cell: Vector2i = base
    var first_cell: Vector2i = base + direction * 8
    var door_cell: Vector2i = base + direction * 9
    var player_cell: Vector2i = base + direction * 10

    expect(collision.register(PROMPT_DOOR_SEMANTIC, true), "prompt door registers ordinary blocking collision")
    expect(mutations.create_entity(PROMPT_DOOR_SEMANTIC, PROMPT_DOOR_ID) == PROMPT_DOOR_ID, "prompt door is exact WHAT identity")
    expect(mutations.set_placement(PROMPT_DOOR_ID, Layers.Channel.STRUCTURE, door_cell, facing, Footprint.single_cell()), "prompt door occupies exact structure cell")
    expect(door_mutations.enroll(PROMPT_DOOR_ID, DoorValue.CLOSED), "prompt door uses canonical door state")
    expect(interactable.set_locked(PROMPT_DOOR_ID, false, &"prompt_setup"), "prompt door setup begins unlocked")
    expect(door_transition.open_manually(first_id, PROMPT_DOOR_ID), "prompt door opens through canonical transition for initial sight")

    expect(_relocate_actor(world, mutations, second_id, second_cell, Facing.opposite(facing)), "second real infected is physically placed behind the pressure scene")
    expect(_relocate_actor(world, mutations, first_id, first_cell, facing), "first real infected is physically placed at door contact")
    expect(_relocate_actor(world, mutations, Fixture.PLAYER_ID, player_cell, Facing.opposite(facing)), "player is physically beyond the opening")
    expect(cohort.sync_active_now(), "cohort remains tied to authoritative technical streaming")

    var first_perception: StreamingObserverPerceptionService = cohort.perception_for_actor(first_id)
    var second_perception: StreamingObserverPerceptionService = cohort.perception_for_actor(second_id)
    expect(first_perception.recompute(&"prompt_open_door_sight"), "first infected recomputes ordinary System-23 sight")
    var seen: Dictionary = memory.last_seen_actor(first_id, Fixture.PLAYER_ID)
    expect(not seen.is_empty() and seen.get("cell", Vector2i.ZERO) == player_cell, "first infected truthfully sees player through open doorway")

    expect(door_transition.close_manually(first_id, PROMPT_DOOR_ID), "door closes through canonical transition")
    expect(interactable.set_locked(PROMPT_DOOR_ID, true, &"prompt_locked"), "exact door becomes locked physical truth")
    expect(first_perception.recompute(&"prompt_closed_door"), "first infected updates perception after closure")
    expect(not memory.last_seen_actor(first_id, Fixture.PLAYER_ID).is_empty(), "first infected retains only legitimate last-seen player memory")

    expect(memory.clear_observer(second_id), "second infected prior visual memory is cleared for causal hearing proof")
    expect(second_perception.recompute(&"prompt_second_no_visual"), "second infected recomputes from its actual facing")
    expect(memory.last_seen_actor(second_id, Fixture.PLAYER_ID).is_empty(), "second infected has no visual player knowledge")
    expect(sound.unregister_listener(second_id) and sound.register_listener(second_id), "second infected auditory setup cues are cleared without changing identity")

    var impacts: Array[Dictionary] = []
    pressure.impact_resolved.connect(func(actor_id, serial, target_id, damage, total_damage, breached, cell):
        if target_id == PROMPT_DOOR_ID:
            impacts.append({"actor_id": actor_id, "serial": serial, "damage": damage, "total": total_damage, "breached": breached, "cell": cell, "tick": kernel.world_tick()})
    )

    var second_history_before: int = second_behavior.action_submission_count()
    var hold: int = kernel.begin_action(Fixture.PLAYER_ID, &"prompt.environmental_pressure_hold", 200, Rules.InterruptionPolicy.COMMITTED)
    expect(hold > 0, "one ordinary player commitment opens shared WHEN")
    var first_active: TimedAction = kernel.active_action_for_actor(first_id)
    expect(first_active != null and first_active.action_type == ActorOpeningPressureActionService.ACTION_TYPE, "blocked pursuit submits generic opening pressure action")
    expect(first_active != null and String(first_active.payload.get("action_id", "")) == String(ActorOpeningPressureActionService.TRY_OPEN), "locked door is physically tried before resistance is known")
    expect(not pressure.actor_knows_opening_resisted(first_id, PROMPT_DOOR_ID), "lock resistance is not known before try-open resolves")
    expect(interactable.opening_damage(PROMPT_DOOR_ID) == 0, "try-open does not fake barrier damage")

    kernel.run_next_batch()
    expect(pressure.actor_knows_opening_resisted(first_id, PROMPT_DOOR_ID), "actor learns exact door resistance only after timed physical try")
    expect(interactable.is_locked(PROMPT_DOOR_ID) and door_state.state(PROMPT_DOOR_ID) == DoorValue.CLOSED, "resisted try leaves canonical locked door closed")
    expect(interactable.opening_damage(PROMPT_DOOR_ID) == 0, "resisted try still causes no fake damage")
    expect(sound.active_observations(second_id).is_empty(), "distant second infected does not join from the quiet latch try")

    var safety := 0
    while impacts.is_empty() and safety < 20:
        kernel.run_next_batch()
        safety += 1
    expect(not impacts.is_empty(), "physical contact produces first real opening impact")
    if not impacts.is_empty():
        expect(int(impacts[0]["damage"]) == ActorOpeningPressureActionService.DOOR_IMPACT_DAMAGE and int(impacts[0]["total"]) == ActorOpeningPressureActionService.DOOR_IMPACT_DAMAGE, "first body impact changes persistent door condition by one actor's force only")
        var impact_tick: int = int(impacts[0]["tick"])
        var heard_impact := false
        for observation: HeardSoundObservation in sound.active_observations(second_id):
            if observation.heard_tick == impact_tick:
                heard_impact = true
        expect(heard_impact, "second infected receives System-26 observation from actual barrier impact")

    safety = 0
    while second_behavior.action_submission_count() <= second_history_before and safety < 10:
        kernel.run_next_batch()
        safety += 1
    var investigated := false
    for entry: Dictionary in second_behavior.action_history():
        if String(entry.get("intention", "")) == String(FirstInfectedBehaviorService.INVESTIGATE_SOUND):
            investigated = true
    expect(investigated, "second infected reacts through ordinary investigate-sound intention, not shared aggro")

    safety = 0
    while not interactable.is_broken(PROMPT_DOOR_ID) and safety < 40:
        kernel.run_next_batch()
        safety += 1
    expect(interactable.is_broken(PROMPT_DOOR_ID), "repeated independent physical impacts breach canonical door truth")
    expect(interactable.opening_damage(PROMPT_DOOR_ID) == WorldInteractableState.MAX_OPENING_DAMAGE, "door breach comes from persistent accumulated opening damage")
    expect(not interactable.is_locked(PROMPT_DOOR_ID) and door_state.state(PROMPT_DOOR_ID) == DoorValue.OPEN, "breach destroys lock and uses canonical door transition/passability")
    expect(impacts.size() >= 4, "wooden door requires repeated contacts rather than one scripted breach")

    safety = 0
    while world.placement(first_id).anchor != door_cell and safety < 20:
        kernel.run_next_batch()
        safety += 1
    expect(world.placement(first_id).anchor == door_cell, "after breach infected enters through ordinary movement")
    var door_query: SpatialQueryResult = spatial.query_cell(door_cell, first_id, true)
    expect(door_query != null and door_query.is_clear(), "canonical broken-open door no longer blocks movement")
    expect(world.placement(first_id).anchor != world.placement(second_id).anchor, "ordinary ACTOR congestion remains intact during pressure")

    await _verify_generic_window_pressure(game, world, mutations, spatial, collision, kernel, interactable, pressure, world_actions, streaming)

    game.queue_free()
    await process_frame
    finish()

func _verify_generic_window_pressure(game, world: WorldState, mutations: WorldMutationService, spatial: SpatialQueryService, collision: CollisionCatalog, kernel: TickKernel, interactable: WorldInteractableState, pressure: ActorOpeningPressureActionService, _world_actions: WorldInteractionActionService, streaming: WorldStreamingCoordinator) -> void:
    if kernel.is_decision_paused():
        var hold := kernel.begin_action(Fixture.PLAYER_ID, &"prompt.window_pressure_hold", 100, Rules.InterruptionPolicy.COMMITTED)
        expect(hold > 0, "window proof reopens ordinary WHEN if needed")

    var player: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    var line: Dictionary = _find_clear_line(spatial, streaming, player.anchor, 3)
    expect(not line.is_empty(), "window proof finds three truthful clear cells")
    if line.is_empty():
        return
    var base: Vector2i = line["base"]
    var facing: int = int(line["facing"])
    var direction: Vector2i = Facing.vector(facing)
    var window_cell: Vector2i = base + direction
    var destination: Vector2i = base + direction * 2

    expect(collision.register(PROMPT_WINDOW_SEMANTIC, true), "prompt window registers ordinary blocking collision")
    expect(mutations.create_entity(PROMPT_WINDOW_SEMANTIC, PROMPT_WINDOW_ID) == PROMPT_WINDOW_ID, "prompt window is exact WHAT identity")
    expect(mutations.set_placement(PROMPT_WINDOW_ID, Layers.Channel.STRUCTURE, window_cell, facing, Footprint.single_cell()), "prompt window occupies exact structure cell")
    expect(interactable.set_locked(PROMPT_WINDOW_ID, false, &"prompt_window_setup"), "window setup uses canonical interactable state")

    expect(mutations.create_entity(&"actor.survivor", PROMPT_WINDOW_ACTOR) == PROMPT_WINDOW_ACTOR, "generic non-infected actor identity exists")
    expect(mutations.set_placement(PROMPT_WINDOW_ACTOR, Layers.Channel.ACTOR, base, facing, Footprint.single_cell()), "generic actor physically contacts window")

    var first: Dictionary = pressure.request_target(PROMPT_WINDOW_ACTOR, PROMPT_WINDOW_ID)
    expect(bool(first.get("accepted", false)) and String(first.get("action_id", "")) == String(ActorOpeningPressureActionService.IMPACT), "generic actor can physically impact window without infected-only API")
    _run_until_actor_idle(kernel, PROMPT_WINDOW_ACTOR, 10)
    expect(interactable.opening_damage(PROMPT_WINDOW_ID) == ActorOpeningPressureActionService.WINDOW_IMPACT_DAMAGE and not interactable.is_broken(PROMPT_WINDOW_ID), "first window impact persists partial physical damage")

    var second: Dictionary = pressure.request_target(PROMPT_WINDOW_ACTOR, PROMPT_WINDOW_ID)
    expect(bool(second.get("accepted", false)), "same generic actor can make second lawful contact")
    _run_until_actor_idle(kernel, PROMPT_WINDOW_ACTOR, 10)
    expect(interactable.is_broken(PROMPT_WINDOW_ID) and interactable.window_open(PROMPT_WINDOW_ID), "second impact shatters canonical window opening")

    var climb: Dictionary = pressure.request_target(PROMPT_WINDOW_ACTOR, PROMPT_WINDOW_ID)
    expect(bool(climb.get("accepted", false)) and String(climb.get("action_id", "")) == String(WorldActions.WINDOW_CLIMB), "broken window delegates to existing generic climb-through action")
    _run_until_actor_idle(kernel, PROMPT_WINDOW_ACTOR, 10)
    expect(world.placement(PROMPT_WINDOW_ACTOR).anchor == destination, "existing climb action moves generic actor through broken window")

func _run_until_actor_idle(kernel: TickKernel, actor_id: String, max_batches: int) -> void:
    var batches := 0
    while kernel.has_active_action(actor_id) and batches < max_batches:
        kernel.run_next_batch()
        batches += 1

func _relocate_actor(world: WorldState, mutations: WorldMutationService, actor_id: String, cell: Vector2i, facing: int) -> bool:
    var current: WorldPlacement = world.placement(actor_id)
    if current == null:
        return false
    return mutations.set_placement(actor_id, Layers.Channel.ACTOR, cell, facing, current.footprint)

func _find_clear_line(spatial: SpatialQueryService, streaming: WorldStreamingCoordinator, origin: Vector2i, length: int) -> Dictionary:
    var facings: Array[int] = [Facing.Value.EAST, Facing.Value.SOUTH, Facing.Value.WEST, Facing.Value.NORTH]
    for radius in range(4, 36):
        for y in range(-radius, radius + 1):
            for x in range(-radius, radius + 1):
                if maxi(abs(x), abs(y)) != radius:
                    continue
                var base := origin + Vector2i(x, y)
                for facing: int in facings:
                    var direction: Vector2i = Facing.vector(facing)
                    var clear := true
                    for offset in range(length):
                        var cell: Vector2i = base + direction * offset
                        if not streaming.is_cell_active(cell) or not spatial.has_terrain(cell):
                            clear = false
                            break
                        var query: SpatialQueryResult = spatial.query_cell(cell, "", true)
                        if query == null or not query.is_clear():
                            clear = false
                            break
                    if clear:
                        return {"base": base, "facing": facing}
    return {}

func expect(ok: bool, message: String) -> void:
    if ok:
        print("PASS: %s" % message)
    else:
        failures.append(message)
        push_error("FAIL: %s" % message)

func finish() -> void:
    if failures.is_empty():
        print("PROMPT_ENVIRONMENTAL_PRESSURE_SMOKE: PASS")
        quit(0)
    else:
        push_error("PROMPT_ENVIRONMENTAL_PRESSURE_SMOKE: FAIL (%d)" % failures.size())
        for value: String in failures:
            push_error(" - %s" % value)
        quit(1)
