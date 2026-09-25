extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE2_INFECTED_PERF: " + message)
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
    var movement: MovementActionService = game.get("_movement")
    var cohort: ActiveInfectedCohortService = game.infected_cohort_service()
    if kernel == null or movement == null or cohort == null or not cohort.is_configured():
        _fail("production infected performance owners are incomplete")
        return

    var active: Array[String] = cohort.active_actor_ids()
    if active.size() != 8:
        _fail("expected eight active production infected, got %d" % active.size())
        return

    var perception_before: int = _perception_recompute_total(cohort, active)
    var behavior_before: Dictionary = cohort.metrics_snapshot()
    var start_tick: int = kernel.world_tick()
    var started_usec: int = Time.get_ticks_usec()

    var player_action: MovementActionResult = movement.request_turn_right(Fixture.PLAYER_ID)
    if player_action == null or not player_action.is_accepted():
        _fail("ordinary player decision was not accepted")
        return
    var stop_reason: int = kernel.run_until_stop()
    var elapsed_usec: int = maxi(0, Time.get_ticks_usec() - started_usec)

    if not kernel.is_decision_paused():
        _fail("ordinary decision route did not return to player decision pause")
        return

    var perception_after: int = _perception_recompute_total(cohort, active)
    var behavior_after: Dictionary = cohort.metrics_snapshot()
    var perception_delta: int = perception_after - perception_before
    var evaluation_delta: int = int(behavior_after.get("behavior_evaluation_count", 0))         - int(behavior_before.get("behavior_evaluation_count", 0))
    var submission_delta: int = int(behavior_after.get("ordinary_action_submission_count", 0))         - int(behavior_before.get("ordinary_action_submission_count", 0))

    if perception_delta < 0 or evaluation_delta < 0 or submission_delta < 0:
        _fail("performance counters moved backward")
        return

    print("PHASE2_INFECTED_PERF_METRIC head_route=player_turn active=%d tick_delta=%d elapsed_usec=%d perception_recomputes=%d behavior_evaluations=%d submissions=%d stop_reason=%d" % [
        active.size(),
        kernel.world_tick() - start_tick,
        elapsed_usec,
        perception_delta,
        evaluation_delta,
        submission_delta,
        stop_reason,
    ])
    quit(0)

func _perception_recompute_total(cohort: ActiveInfectedCohortService, actor_ids: Array[String]) -> int:
    var total: int = 0
    for actor_id: String in actor_ids:
        var perception: StreamingObserverPerceptionService = cohort.perception_for_actor(actor_id)
        if perception != null:
            total += perception.recompute_count()
    return total
