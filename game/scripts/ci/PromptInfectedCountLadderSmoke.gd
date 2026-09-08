extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Rules = preload("res://scripts/foundation/time/TickRules.gd")

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
    var cohort: ActiveInfectedCohortService = game.infected_cohort_service()
    var members: Array[Dictionary] = game.infected_cohort_results()
    var streaming: WorldStreamingCoordinator = Fixture.streaming_coordinator()
    var target_count: int = game.ACTIVE_INFECTED_COHORT_SIZE

    expect(cohort != null and cohort.is_configured(), "production cohort is configured")
    expect(target_count in [4, 8, 16], "production count is on the approved 4 -> 8 -> 16 ladder")
    expect(members.size() == target_count, "production hydrates the configured ladder count")
    expect(kernel.is_decision_paused(), "ladder begins at the normal player decision pause")
    if not failures.is_empty():
        game.queue_free()
        return finish()

    var actor_ids := cohort.roster_actor_ids()
    var player: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    expect(actor_ids.size() == target_count and player != null, "ladder has exact resident actors and a real player placement")

    var burst_started := Time.get_ticks_usec()
    var placed := 0
    for actor_id: String in actor_ids:
        var cell := _find_clear_active_cell(world, spatial, streaming, player.anchor, actor_id, placed)
        if cell == Vector2i(-2147483648, -2147483648):
            break
        var current: WorldPlacement = world.placement(actor_id)
        if current == null:
            break
        if not mutations.set_placement(actor_id, Layers.Channel.ACTOR, cell, current.facing, Footprint.single_cell()):
            break
        placed += 1
    var placement_burst_usec := Time.get_ticks_usec() - burst_started

    expect(placed == target_count, "all ladder actors fit in distinct physical cells inside the active envelope")
    expect(cohort.sync_active_now(), "cohort synchronizes against the existing streaming owner")
    expect(cohort.active_actor_ids().size() == target_count, "all ladder actors are behavior-active without a second activation system")

    var unique_cells: Dictionary = {}
    for actor_id: String in actor_ids:
        var placement: WorldPlacement = world.placement(actor_id)
        expect(placement != null and streaming.is_cell_active(placement.anchor), "ladder actor remains in authoritative active stream truth")
        if placement != null:
            expect(not unique_cells.has(placement.anchor), "physical congestion keeps every infected on a distinct ACTOR cell")
            unique_cells[placement.anchor] = actor_id
        expect(cohort.perception_for_actor(actor_id) != null and cohort.perception_for_actor(actor_id).is_stream_active(), "active actor uses ordinary System-23 perception")

    var eval_before_frames := int(cohort.metrics_snapshot().get("behavior_evaluation_count", 0))
    await process_frame
    await process_frame
    expect(int(cohort.metrics_snapshot().get("behavior_evaluation_count", 0)) == eval_before_frames, "render frames do not become an AI scheduler")

    var perception_started := Time.get_ticks_usec()
    var recomputed := 0
    for actor_id: String in actor_ids:
        var perception := cohort.perception_for_actor(actor_id)
        if perception != null and perception.recompute(&"prompt_count_ladder"):
            recomputed += 1
    var perception_sweep_usec := Time.get_ticks_usec() - perception_started
    expect(recomputed == target_count, "one explicit System-23 sweep can evaluate every active infected")

    var eval_before_when := int(cohort.metrics_snapshot().get("behavior_evaluation_count", 0))
    var hold := kernel.begin_action(Fixture.PLAYER_ID, &"prompt.count_ladder_hold", 40, Rules.InterruptionPolicy.COMMITTED)
    expect(hold > 0, "one ordinary player commitment opens shared WHEN")
    var eval_after_when := int(cohort.metrics_snapshot().get("behavior_evaluation_count", 0))
    expect(eval_after_when > eval_before_when, "active infected react through the existing event-driven behavior path")

    var metrics := cohort.metrics_snapshot()
    print("PROMPT_COUNT_LADDER_METRICS count=%d placement_burst_usec=%d perception_sweep_usec=%d cohort=%s" % [target_count, placement_burst_usec, perception_sweep_usec, JSON.stringify(metrics)])

    game.queue_free()
    await process_frame
    finish()

func _find_clear_active_cell(world: WorldState, spatial: SpatialQueryService, streaming: WorldStreamingCoordinator, origin: Vector2i, actor_id: String, ordinal: int) -> Vector2i:
    var max_radius := 18
    var skipped := 0
    for radius in range(2, max_radius + 1):
        for y in range(-radius, radius + 1):
            for x in range(-radius, radius + 1):
                if maxi(abs(x), abs(y)) != radius:
                    continue
                var cell := origin + Vector2i(x, y)
                if not streaming.is_cell_active(cell) or not spatial.has_terrain(cell):
                    continue
                var query := spatial.query_cell(cell, actor_id, true)
                if query == null or not query.is_clear():
                    continue
                if skipped < ordinal:
                    skipped += 1
                    continue
                return cell
    return Vector2i(-2147483648, -2147483648)

func expect(ok: bool, message: String) -> void:
    if ok:
        print("PASS: %s" % message)
    else:
        failures.append(message)
        push_error("FAIL: %s" % message)

func finish() -> void:
    if failures.is_empty():
        print("PROMPT_INFECTED_COUNT_LADDER_SMOKE: PASS")
        quit(0)
    else:
        push_error("PROMPT_INFECTED_COUNT_LADDER_SMOKE: FAIL (%d)" % failures.size())
        for value: String in failures:
            push_error(" - %s" % value)
        quit(1)
