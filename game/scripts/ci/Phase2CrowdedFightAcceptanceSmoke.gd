extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

const MAX_APPROACH_TURNS: int = 16
const MAX_WAIT_FRAMES: int = 5000

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE2_CROWDED_FIGHT_ACCEPTANCE: " + message)
    quit(1)

func _run() -> void:
    var gameplay: PackedScene = load("res://gameplay.tscn")
    if gameplay == null:
        _fail("production gameplay scene missing")
        return

    var game: Node = gameplay.instantiate()
    get_root().add_child(game)
    await process_frame

    var kernel: TickKernel = game.get("_kernel")
    var cohort: ActiveInfectedCohortService = game.infected_cohort_service()
    var presenter: ConsequenceMomentPresenter = game.consequence_presenter()
    var controls: PlayerMovementControls = game.get_node_or_null("Controls") as PlayerMovementControls
    var health: ActorHealthState = game.get("_health_state")
    var player_perception: ObserverPerceptionService = game.get("_perception")
    var world: WorldState = game.get("_world")
    var mutations: WorldMutationService = game.get("_world_mutations")
    var spatial: SpatialQueryService = game.get("_spatial_query")

    if kernel == null or cohort == null or not cohort.is_configured() or presenter == null         or controls == null or health == null or player_perception == null or world == null \
        or mutations == null or spatial == null:
        _fail("production crowded-fight route owners are incomplete")
        return
    if not kernel.is_decision_paused():
        _fail("production route did not begin at a legitimate decision pause")
        return

    var active: Array[String] = cohort.active_actor_ids()
    if active.size() != 8:
        _fail("expected eight active production infected, got %d" % active.size())
        return

    # Acceptance fixture only: move the already-hydrated production actors into
    # a nearby valid ring. From this point onward all decisions and consequences
    # use the ordinary production touch/controller/simulation route.
    if not _arrange_crowd_fixture(world, mutations, spatial, active):
        _fail("could not arrange the existing production infected into a valid crowded-fight fixture")
        return
    if not cohort.sync_active_now():
        _fail("production infected cohort did not remain active after bounded fixture arrangement")
        return
    if cohort.active_actor_ids().size() != 8:
        _fail("crowded fixture did not retain all eight active production infected")
        return
    player_perception.recompute(&"crowded_fight_acceptance_fixture")
    for actor_id: String in active:
        var infected_perception: StreamingObserverPerceptionService = cohort.perception_for_actor(actor_id)
        if infected_perception != null:
            infected_perception.recompute(&"crowded_fight_acceptance_fixture")

    var turn_right: Button = _button_by_text(controls, "TURN R")
    var strike: Button = controls.get_node_or_null("CombatForwardButton") as Button
    if turn_right == null or strike == null:
        _fail("touch-first production controls are missing TURN R or STRIKE")
        return
    if turn_right.focus_mode != Control.FOCUS_NONE or strike.focus_mode != Control.FOCUS_NONE:
        _fail("touch-first controls unexpectedly require keyboard focus")
        return
    if not controls.control_surface_visible() or not controls.is_enabled():
        _fail("touch-first control surface is not initially usable")
        return

    var behavior_before: Dictionary = cohort.metrics_snapshot()
    var infected_perception_before: int = _perception_usec_total(cohort, active)
    var infected_recompute_before: int = _perception_recompute_total(cohort, active)
    var infected_geometry_before: int = _geometry_recompute_total(cohort, active)
    var player_perception_usec_before: int = player_perception.recompute_total_usec()
    var player_perception_count_before: int = player_perception.recompute_count()
    var start_tick: int = kernel.world_tick()
    PerformanceTelemetry.reset()
    var route_started_usec: int = Time.get_ticks_usec()

    var accepted_turns: int = 0
    var accepted_strikes: int = 0
    var lock_cycles: int = 0
    var max_action_usec: int = 0
    var action_elapsed_total_usec: int = 0

    # Try the real touch STRIKE first. If no target is forward yet, ordinary
    # turn actions advance the same shared clock and let all eight infected react.
    for attempt: int in range(MAX_APPROACH_TURNS + 1):
        if health.current_hp(Fixture.PLAYER_ID) <= 0:
            break

        var strike_result: Dictionary = await _press_and_wait(strike, controls, kernel, false)
        if bool(strike_result.get("accepted", false)):
            accepted_strikes += 1
            lock_cycles += 1
            var strike_usec: int = int(strike_result.get("elapsed_usec", 0))
            action_elapsed_total_usec += strike_usec
            max_action_usec = maxi(max_action_usec, strike_usec)
            await process_frame
        if _history_has_contact(presenter.history_snapshot()):
            break

        if attempt >= MAX_APPROACH_TURNS:
            break

        var turn_result: Dictionary = await _press_and_wait(turn_right, controls, kernel, true)
        if not bool(turn_result.get("accepted", false)):
            _fail("ordinary touch TURN R was not accepted at a decision pause")
            return
        accepted_turns += 1
        lock_cycles += 1
        var turn_usec: int = int(turn_result.get("elapsed_usec", 0))
        action_elapsed_total_usec += turn_usec
        max_action_usec = maxi(max_action_usec, turn_usec)

    var route_elapsed_usec: int = maxi(0, Time.get_ticks_usec() - route_started_usec)
    if accepted_turns < 1:
        _fail("crowded route never completed an ordinary touch movement decision")
        return
    if accepted_strikes < 1:
        _fail("eight-infected production route never reached an accepted ordinary STRIKE within %d approach turns" % MAX_APPROACH_TURNS)
        return
    if lock_cycles != accepted_turns + accepted_strikes:
        _fail("accepted actions did not each produce one input-lock cycle")
        return
    if not kernel.is_decision_paused():
        _fail("crowded route did not return to a legitimate decision pause")
        return
    if health.current_hp(Fixture.PLAYER_ID) > 0 and not controls.is_enabled():
        _fail("touch controls remained locked after the next legitimate decision pause")
        return

    await process_frame
    var history: Array[Dictionary] = presenter.history_snapshot()
    if history.is_empty():
        var diagnostic_metrics: Dictionary = cohort.metrics_snapshot()
        var player_placement: WorldPlacement = world.placement(Fixture.PLAYER_ID)
        print("PHASE2_CROWDED_FIGHT_NO_PRESENTATION turns=%d strikes=%d tick=%d behavior_evals=%d submissions=%d player=%s infected=%s" % [
            accepted_turns,
            accepted_strikes,
            kernel.world_tick(),
            int(diagnostic_metrics.get("behavior_evaluation_count", 0)),
            int(diagnostic_metrics.get("ordinary_action_submission_count", 0)),
            str(player_placement.anchor if player_placement != null else Vector2i(-9999, -9999)),
            _actor_anchor_summary(world, active),
        ])
        _fail("real crowded route produced no consequence presentation")
        return

    var saw_overlap: bool = false
    var saw_contact: bool = false
    var ticks_seen: Dictionary = {}
    for moment: Dictionary in history:
        var tick: int = int(moment.get("tick", -1))
        if tick < 0:
            _fail("consequence presentation contains an invalid world tick")
            return
        if ticks_seen.has(tick):
            _fail("one real world tick was fragmented into multiple consequence moments")
            return
        ticks_seen[tick] = true
        if int(moment.get("event_count", 0)) >= 2 and String(moment.get("text", "")).contains("SAME MOMENT"):
            saw_overlap = true
        for value: Variant in moment.get("events", []):
            if typeof(value) != TYPE_DICTIONARY:
                continue
            var kind: String = String((value as Dictionary).get("kind", ""))
            if kind == "hit" or kind == "pressure" or kind == "shove" or kind == "death":
                saw_contact = true

    if not saw_overlap:
        _fail("real eight-infected route never produced a coherent overlapping consequence moment")
        return
    if not saw_contact:
        _fail("real eight-infected route never produced physical combat/crowd contact")
        return

    var behavior_after: Dictionary = cohort.metrics_snapshot()
    var infected_perception_after: int = _perception_usec_total(cohort, active)
    var infected_recompute_after: int = _perception_recompute_total(cohort, active)
    var infected_geometry_after: int = _geometry_recompute_total(cohort, active)
    var player_perception_usec_after: int = player_perception.recompute_total_usec()
    var player_perception_count_after: int = player_perception.recompute_count()

    var behavior_usec: int = int(behavior_after.get("behavior_evaluation_total_usec", 0))         - int(behavior_before.get("behavior_evaluation_total_usec", 0))
    var intention_usec: int = int(behavior_after.get("behavior_intention_refresh_total_usec", 0))         - int(behavior_before.get("behavior_intention_refresh_total_usec", 0))
    var submission_usec: int = int(behavior_after.get("behavior_submission_total_usec", 0))         - int(behavior_before.get("behavior_submission_total_usec", 0))
    var sync_usec: int = int(behavior_after.get("activation_sync_total_usec", 0))         - int(behavior_before.get("activation_sync_total_usec", 0))
    var infected_perception_usec: int = infected_perception_after - infected_perception_before
    var player_perception_usec: int = player_perception_usec_after - player_perception_usec_before
    var infected_recomputes: int = infected_recompute_after - infected_recompute_before
    var player_recomputes: int = player_perception_count_after - player_perception_count_before
    var infected_geometry_recomputes: int = infected_geometry_after - infected_geometry_before
    var tracked_usec: int = maxi(0, behavior_usec) + maxi(0, infected_perception_usec)         + maxi(0, player_perception_usec) + maxi(0, sync_usec)
    var unattributed_estimate_usec: int = maxi(0, action_elapsed_total_usec - tracked_usec)

    if behavior_usec < 0 or infected_perception_usec < 0 or player_perception_usec < 0         or sync_usec < 0 or infected_recomputes < 0 or player_recomputes < 0         or infected_geometry_recomputes < 0:
        _fail("existing performance counters moved backward")
        return
    if infected_geometry_recomputes != 0:
        _fail("crowded route rebuilt infected geometric LOS despite unchanged geometry contract")
        return

    var telemetry: Dictionary = PerformanceTelemetry.snapshot()
    print("PHASE2_CROWDED_FIGHT_TELEMETRY %s" % JSON.stringify(telemetry.get("timings", {})))
    print("PHASE2_CROWDED_FIGHT_VALUES %s" % JSON.stringify(telemetry.get("values", {})))
    print("PHASE2_CROWDED_FIGHT_PERF accepted_turns=%d accepted_strikes=%d lock_cycles=%d tick_delta=%d route_elapsed_usec=%d accepted_action_elapsed_usec=%d max_action_usec=%d behavior_usec=%d infected_perception_usec=%d player_perception_usec=%d activation_sync_usec=%d intention_usec=%d submission_usec=%d tracked_usec=%d unattributed_estimate_usec=%d infected_recomputes=%d player_recomputes=%d history=%d player_hp=%d" % [
        accepted_turns,
        accepted_strikes,
        lock_cycles,
        kernel.world_tick() - start_tick,
        route_elapsed_usec,
        action_elapsed_total_usec,
        max_action_usec,
        behavior_usec,
        infected_perception_usec,
        player_perception_usec,
        sync_usec,
        intention_usec,
        submission_usec,
        tracked_usec,
        unattributed_estimate_usec,
        infected_recomputes,
        player_recomputes,
        history.size(),
        health.current_hp(Fixture.PLAYER_ID),
    ])
    print("PHASE2_CROWDED_FIGHT_ACCEPTANCE_OK active=%d turns=%d strikes=%d overlap=%s contact=%s final_tick=%d" % [
        active.size(),
        accepted_turns,
        accepted_strikes,
        str(saw_overlap),
        str(saw_contact),
        kernel.world_tick(),
    ])
    quit(0)

func _press_and_wait(
    button: Button,
    controls: PlayerMovementControls,
    kernel: TickKernel,
    require_accept: bool
) -> Dictionary:
    if button == null or button.disabled or not controls.is_enabled() or not kernel.is_decision_paused():
        return {"accepted": false, "reason": "not_ready"}

    var tick_before: int = kernel.world_tick()
    var started_usec: int = Time.get_ticks_usec()
    button.pressed.emit()

    # Accepted production actions synchronously set the player controller busy,
    # which disables this same touch surface until the next decision pause.
    var accepted: bool = not controls.is_enabled()
    if not accepted:
        return {
            "accepted": false,
            "elapsed_usec": maxi(0, Time.get_ticks_usec() - started_usec),
            "tick_before": tick_before,
            "tick_after": kernel.world_tick(),
        }

    if kernel.is_decision_paused():
        _fail("accepted action left WHEN decision-paused while input was locked")
        return {}

    for _frame: int in range(MAX_WAIT_FRAMES):
        await process_frame
        if controls.is_enabled():
            var elapsed_usec: int = maxi(0, Time.get_ticks_usec() - started_usec)
            if not kernel.is_decision_paused():
                _fail("touch input unlocked before WHEN returned to decision pause")
                return {}
            if kernel.world_tick() <= tick_before:
                _fail("accepted ordinary action did not advance the shared world clock")
                return {}
            return {
                "accepted": true,
                "elapsed_usec": elapsed_usec,
                "tick_before": tick_before,
                "tick_after": kernel.world_tick(),
            }

    if require_accept:
        _fail("accepted touch action never unlocked at the next decision pause")
    return {"accepted": false, "reason": "wait_timeout"}

func _button_by_text(controls: PlayerMovementControls, text_value: String) -> Button:
    for child: Node in controls.get_children():
        var button: Button = child as Button
        if button != null and button.text == text_value:
            return button
    return null

func _geometry_recompute_total(cohort: ActiveInfectedCohortService, actor_ids: Array[String]) -> int:
    var total: int = 0
    for actor_id: String in actor_ids:
        var perception: StreamingObserverPerceptionService = cohort.perception_for_actor(actor_id)
        if perception != null:
            total += perception.geometry_recompute_count()
    return total

func _perception_usec_total(cohort: ActiveInfectedCohortService, actor_ids: Array[String]) -> int:
    var total: int = 0
    for actor_id: String in actor_ids:
        var perception: StreamingObserverPerceptionService = cohort.perception_for_actor(actor_id)
        if perception != null:
            total += perception.recompute_total_usec()
    return total

func _perception_recompute_total(cohort: ActiveInfectedCohortService, actor_ids: Array[String]) -> int:
    var total: int = 0
    for actor_id: String in actor_ids:
        var perception: StreamingObserverPerceptionService = cohort.perception_for_actor(actor_id)
        if perception != null:
            total += perception.recompute_count()
    return total


func _actor_anchor_summary(world: WorldState, actor_ids: Array[String]) -> String:
    var parts := PackedStringArray()
    for actor_id: String in actor_ids:
        var placement: WorldPlacement = world.placement(actor_id)
        parts.append("%s=%s" % [
            actor_id,
            str(placement.anchor if placement != null else Vector2i(-9999, -9999)),
        ])
    return ",".join(parts)


func _arrange_crowd_fixture(
    world: WorldState,
    mutations: WorldMutationService,
    spatial: SpatialQueryService,
    actor_ids: Array[String]
) -> bool:
    var player: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if player == null:
        return false

    var offsets: Array[Vector2i] = [
        Vector2i(0, -2),
        Vector2i(1, -2),
        Vector2i(2, -1),
        Vector2i(2, 0),
        Vector2i(2, 1),
        Vector2i(1, 2),
        Vector2i(0, 2),
        Vector2i(-1, 2),
    ]
    var placements: Array = []
    var used: Dictionary = {}
    for index: int in range(actor_ids.size()):
        var actor_id: String = actor_ids[index]
        var current: WorldPlacement = world.placement(actor_id)
        if current == null:
            return false
        var target: Vector2i = _find_fixture_cell(player.anchor + offsets[index], player.anchor, spatial, actor_id, used)
        if target == Vector2i(-999999, -999999):
            return false
        used[target] = true
        placements.append(WorldPlacement.new(
            actor_id,
            current.channel,
            target,
            current.facing,
            current.footprint,
            current.structure_axis
        ))
    return mutations.set_placements_batch(placements)

func _find_fixture_cell(
    preferred: Vector2i,
    player_anchor: Vector2i,
    spatial: SpatialQueryService,
    actor_id: String,
    used: Dictionary
) -> Vector2i:
    const INVALID := Vector2i(-999999, -999999)
    for radius: int in range(0, 4):
        for y: int in range(-radius, radius + 1):
            for x: int in range(-radius, radius + 1):
                if radius > 0 and absi(x) != radius and absi(y) != radius:
                    continue
                var cell: Vector2i = preferred + Vector2i(x, y)
                if cell == player_anchor or used.has(cell):
                    continue
                var query: SpatialQueryResult = spatial.query_cell(cell, actor_id, true)
                if query != null and query.is_clear():
                    return cell
    return INVALID

func _history_has_contact(history: Array[Dictionary]) -> bool:
    for moment: Dictionary in history:
        for value: Variant in moment.get("events", []):
            if typeof(value) != TYPE_DICTIONARY:
                continue
            var kind: String = String((value as Dictionary).get("kind", ""))
            if kind == "hit" or kind == "pressure" or kind == "shove" or kind == "death":
                return true
    return false
