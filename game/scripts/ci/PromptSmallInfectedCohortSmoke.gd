extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
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
    var health: ActorHealthState = game.get("_health_state")
    var infected: InfectedState = game.get("_infected_state")
    var heard_store: HeardSoundObservationStore = game.get("_heard_sounds")
    var projection: PopulationResidentProjection = game.get("_population_resident_projection")
    var cohort: ActiveInfectedCohortService = game.infected_cohort_service()
    var members: Array[Dictionary] = game.infected_cohort_results()
    var streaming: WorldStreamingCoordinator = Fixture.streaming_coordinator()
    var global_plan: GeneratedGlobalWorldPlan = Fixture.global_plan()

    expect(cohort != null and cohort.is_configured(), "production active infected cohort is configured")
    expect(members.size() == game.ACTIVE_INFECTED_COHORT_SIZE and members.size() == 4, "production hydrates a deliberately small four-member cohort")
    expect(streaming != null and streaming.has_focus(), "cohort shares the authoritative technical streaming owner")
    if not failures.is_empty():
        game.queue_free()
        return finish()

    var population_plan := {
        "ok": true,
        "settlements": global_plan.population_settlements.duplicate(true),
        "resident_population": global_plan.resident_population,
        "infected_population": global_plan.infected_population,
        "survivor_population": global_plan.survivor_population,
        "local_area_manifest": global_plan.local_area_manifest.duplicate(true),
    }
    var projected := projection.infected_near(population_plan, Fixture.CENTRAL_SITE_ID, world.placement(Fixture.PLAYER_ID).anchor)
    var projected_ids: Dictionary = {}
    for record: Dictionary in projected:
        projected_ids[String(record.get("resident_id", ""))] = true

    var roster := cohort.roster_actor_ids()
    expect(roster.size() == 4, "cohort roster contains exactly four exact resident identities")
    expect(roster == _sorted_copy(roster), "cohort scheduling order is deterministic by actor identity")
    var occupied_cells: Dictionary = {}
    for member: Dictionary in members:
        var actor_id := String(member.get("actor_id", ""))
        var placement: WorldPlacement = world.placement(actor_id)
        expect(not actor_id.is_empty() and projected_ids.has(actor_id), "hydrated cohort member is a deterministic projected infected resident slot")
        expect(infected.is_infected(actor_id) and not infected.resident_record(actor_id).is_empty(), "cohort member preserves population/infection provenance")
        expect(placement != null and placement.channel == Layers.Channel.ACTOR, "cohort member is a normal physical ACTOR")
        if placement != null:
            expect(not occupied_cells.has(placement.anchor), "hydration preserves physical congestion by never overlapping ACTOR cells")
            occupied_cells[placement.anchor] = actor_id

    var active_before := cohort.active_actor_ids()
    expect(active_before.size() >= 2, "at least two real cohort members begin inside the active streaming envelope")
    for actor_id: String in active_before:
        expect(streaming.is_cell_active(world.placement(actor_id).anchor), "every active cohort member is inside the authoritative technical stream envelope")
        expect(heard_store.has_listener(actor_id), "active cohort member is enrolled as a System-26 listener")
        var perception := cohort.perception_for_actor(actor_id)
        var behavior := cohort.behavior_for_actor(actor_id)
        expect(perception != null and perception.is_stream_active(), "active cohort member owns active System-23 perception")
        expect(behavior != null and behavior.is_running(), "active cohort member reuses the exact infected behavior loop")

    var boot_metrics := cohort.metrics_snapshot()
    var eval_before_frames := int(boot_metrics.get("behavior_evaluation_count", 0))
    expect(kernel.is_decision_paused(), "production still begins at player decision pause")
    await process_frame
    await process_frame
    expect(int(cohort.metrics_snapshot().get("behavior_evaluation_count", 0)) == eval_before_frames, "cohort performs no per-frame behavior scheduling while WHEN is paused")

    # Streaming exit: move only technical focus, not actor truth.
    var original_focus := streaming.focus_cell()
    var far_focus := _far_focus(global_plan.bounds, original_focus)
    expect(far_focus != original_focus, "found a distant valid technical stream focus for deactivation proof")
    var first_id := String(members[0].get("actor_id", ""))
    var first_record_before := infected.resident_record(first_id)
    var first_placement_before: WorldPlacement = world.placement(first_id)
    var first_behavior := cohort.behavior_for_actor(first_id)
    var far_result := streaming.update_focus(far_focus)
    expect(bool(far_result.get("ok", false)), "authoritative streaming owner can move active envelope away from cohort")
    expect(not cohort.is_actor_active(first_id), "cohort member deactivates when its physical cell leaves active stream envelope")
    expect(world.placement(first_id) != null and world.placement(first_id).anchor == first_placement_before.anchor, "stream deactivation preserves the physical resident body/state instead of deleting it")
    expect(infected.resident_record(first_id) == first_record_before, "stream deactivation preserves resident provenance")
    expect(not heard_store.has_listener(first_id), "stream-deactivated member is removed from System-26 listener work")
    var first_perception := cohort.perception_for_actor(first_id)
    expect(first_perception != null and not first_perception.is_stream_active(), "stream-deactivated member suspends System-23 recomputation")
    var dormant_recompute_before := first_perception.recompute_count()
    expect(not first_perception.recompute(&"prompt_dormant_probe"), "dormant observer refuses explicit expensive perception recompute")
    expect(first_perception.recompute_count() == dormant_recompute_before, "dormant observer accrues no System-23 recomputation work")
    var dormant_eval_before := first_behavior.evaluation_count()
    await process_frame
    await process_frame
    expect(first_behavior.evaluation_count() == dormant_eval_before, "stream-deactivated behavior performs no render-frame work")

    var restore_result := streaming.update_focus(original_focus)
    expect(bool(restore_result.get("ok", false)), "authoritative streaming owner restores original active envelope")
    expect(cohort.is_actor_active(first_id), "same resident identity reactivates on streaming re-entry")
    expect(heard_store.has_listener(first_id), "reactivated member re-enrolls in System-26 hearing")
    expect(first_perception.is_stream_active(), "reactivated member resumes System-23 perception")
    expect(cohort.behavior_for_actor(first_id) == first_behavior and first_behavior.is_running(), "reactivation reuses the same behavior/state identity")

    # Put two active members into truthful visible lanes and prove the shared WHEN clock can schedule both.
    var active_now := cohort.active_actor_ids()
    expect(active_now.size() >= 2, "two active infected remain available for shared-WHEN scheduling proof")
    if active_now.size() >= 2:
        var actor_a := active_now[0]
        var actor_b := active_now[1]
        expect(_place_visible_distinct(world, mutations, spatial, cohort, actor_a, actor_b), "two active infected can occupy distinct visible approach lanes")
        var behavior_a := cohort.behavior_for_actor(actor_a)
        var behavior_b := cohort.behavior_for_actor(actor_b)
        var a_before := behavior_a.action_submission_count()
        var b_before := behavior_b.action_submission_count()
        var hold := kernel.begin_action(Fixture.PLAYER_ID, &"prompt.cohort.shared_when_hold", 80, Rules.InterruptionPolicy.COMMITTED)
        expect(hold > 0, "one player commitment opens the ordinary shared WHEN clock")
        expect(behavior_a.action_submission_count() > a_before, "first active infected submits an ordinary action on shared WHEN")
        expect(behavior_b.action_submission_count() > b_before, "second active infected submits an ordinary action on shared WHEN")

        var placement_a: WorldPlacement = world.placement(actor_a)
        var placement_b: WorldPlacement = world.placement(actor_b)
        expect(placement_a != null and placement_b != null and placement_a.anchor != placement_b.anchor, "concurrent infected scheduling never overlaps physical ACTOR occupancy")
        if placement_a != null and placement_b != null:
            var blocked_query := spatial.query_cell(placement_a.anchor, actor_b, true)
            expect(blocked_query != null and not blocked_query.is_clear(), "ordinary collision sees another infected body as congestion rather than a pass-through")

        _reset_actions(kernel, cohort.roster_actor_ids())

        var active_count_before_death := cohort.active_actor_ids().size()
        var survivor_other := actor_b
        expect(health.apply_damage(actor_a, 1000), "canonical Health can kill one cohort member")
        expect(not cohort.is_actor_active(actor_a), "dead cohort member leaves active scheduling")
        expect(cohort.is_actor_active(survivor_other), "one infected death does not stop the rest of the active cohort")
        expect(cohort.active_actor_ids().size() == active_count_before_death - 1, "active cohort count drops by exactly the dead actor")
        expect(infected.resident_record(actor_a).get("resident_id", "") == actor_a, "death still preserves population provenance for scaled member")

    var metrics := cohort.metrics_snapshot()
    expect(int(metrics.get("roster_count", 0)) == 4, "metrics report fixed small hydrated roster")
    expect(int(metrics.get("activation_count", 0)) >= 2, "metrics count stream activations")
    expect(int(metrics.get("deactivation_count", 0)) >= 1, "metrics count stream deactivations")
    expect(int(metrics.get("activation_sync_count", 0)) >= 1, "metrics count activation-envelope synchronization work")
    expect(int(metrics.get("behavior_evaluation_count", 0)) > 0, "metrics measure behavior scheduling evaluations")
    expect(int(metrics.get("ordinary_action_submission_count", 0)) > 0, "metrics measure ordinary action submissions")
    expect(int(metrics.get("behavior_evaluation_total_usec", -1)) >= 0 and int(metrics.get("behavior_evaluation_max_usec", -1)) >= 0, "metrics measure behavior scheduling cost in microseconds")
    expect(int(metrics.get("activation_sync_total_usec", -1)) >= 0 and int(metrics.get("activation_sync_max_usec", -1)) >= 0, "metrics measure streaming activation synchronization cost")
    print("PROMPT_COHORT_METRICS %s" % JSON.stringify(metrics))

    game.queue_free()
    await process_frame
    finish()

func _place_visible_distinct(world: WorldState, mutations: WorldMutationService, spatial: SpatialQueryService, cohort: ActiveInfectedCohortService, actor_a: String, actor_b: String) -> bool:
    var player: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if player == null: return false
    var candidates: Array[Dictionary] = []
    for distance in [2, 3]:
        for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
            var cell: Vector2i = player.anchor + direction * distance
            if not _clear_lane(spatial, actor_a, player.anchor, direction, distance): continue
            candidates.append({"cell": cell, "facing": Facing.from_vector(-direction)})
    for a_index in range(candidates.size()):
        var a: Dictionary = candidates[a_index]
        if not mutations.set_placement(actor_a, Layers.Channel.ACTOR, a["cell"], int(a["facing"]), Footprint.single_cell()): continue
        var pa := cohort.perception_for_actor(actor_a)
        if pa == null: continue
        pa.recompute(&"prompt_cohort_a")
        if not pa.is_visible(player.anchor): continue
        for b_index in range(candidates.size()):
            if b_index == a_index: continue
            var b: Dictionary = candidates[b_index]
            if b["cell"] == a["cell"]: continue
            if spatial.query_cell(b["cell"], actor_b, true) == null or not spatial.query_cell(b["cell"], actor_b, true).is_clear(): continue
            if not mutations.set_placement(actor_b, Layers.Channel.ACTOR, b["cell"], int(b["facing"]), Footprint.single_cell()): continue
            var pb := cohort.perception_for_actor(actor_b)
            if pb == null: continue
            pb.recompute(&"prompt_cohort_b")
            if pb.is_visible(player.anchor): return true
    return false

func _clear_lane(spatial: SpatialQueryService, actor_id: String, origin: Vector2i, direction: Vector2i, distance: int) -> bool:
    for step in range(1, distance + 1):
        var cell: Vector2i = origin + direction * step
        if not spatial.has_terrain(cell): return false
        var query := spatial.query_cell(cell, actor_id, true)
        if query == null or not query.is_clear(): return false
    return true

func _far_focus(bounds: Rect2i, origin: Vector2i) -> Vector2i:
    var stride := Fixture.STREAM_REGION_SIZE.x * 4
    for delta in [Vector2i(stride, 0), Vector2i(-stride, 0), Vector2i(0, stride), Vector2i(0, -stride)]:
        var candidate: Vector2i = origin + delta
        if bounds.has_point(candidate): return candidate
    return origin

func _reset_actions(kernel: TickKernel, actor_ids: Array[String]) -> void:
    kernel.set_hard_paused(true)
    for actor_id: String in actor_ids:
        var action := kernel.active_action_for_actor(actor_id)
        if action != null: kernel.interrupt_action(action.serial, "prompt_cohort_reset", true)
    var player_action := kernel.active_action_for_actor(Fixture.PLAYER_ID)
    if player_action != null: kernel.interrupt_action(player_action.serial, "prompt_cohort_reset", true)
    kernel.set_hard_paused(false)
    kernel.run_next_batch()

func _sorted_copy(values: Array[String]) -> Array[String]:
    var result := values.duplicate()
    result.sort()
    return result

func expect(ok: bool, message: String) -> void:
    if ok:
        print("PASS: %s" % message)
    else:
        failures.append(message)
        push_error("FAIL: %s" % message)

func finish() -> void:
    if failures.is_empty():
        print("PROMPT_SMALL_INFECTED_COHORT_SMOKE: PASS")
        quit(0)
    else:
        push_error("PROMPT_SMALL_INFECTED_COHORT_SMOKE: FAIL (%d)" % failures.size())
        for value: String in failures: push_error(" - %s" % value)
        quit(1)