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
    var player_perception: ObserverPerceptionService = game.get("_perception")
    if kernel == null or movement == null or cohort == null or not cohort.is_configured()         or player_perception == null:
        _fail("production infected performance owners are incomplete")
        return

    var active: Array[String] = cohort.active_actor_ids()
    if active.size() != 8:
        _fail("expected eight active production infected, got %d" % active.size())
        return

    var perception_before: int = _perception_recompute_total(cohort, active)
    var infected_perception_usec_before: int = _perception_usec_total(cohort, active)
    var infected_geometry_before: int = _geometry_recompute_total(cohort, active)
    var infected_geometry_usec_before: int = _geometry_usec_total(cohort, active)
    var player_perception_count_before: int = player_perception.recompute_count()
    var player_perception_usec_before: int = player_perception.recompute_total_usec()
    var behavior_before: Dictionary = cohort.metrics_snapshot()
    var start_tick: int = kernel.world_tick()

    var first_started_usec: int = Time.get_ticks_usec()
    var first_action: MovementActionResult = movement.request_turn_right(Fixture.PLAYER_ID)
    if first_action == null or not first_action.is_accepted():
        _fail("first ordinary player decision was not accepted")
        return
    var first_stop_reason: int = kernel.run_until_stop()
    var first_elapsed_usec: int = maxi(0, Time.get_ticks_usec() - first_started_usec)
    if not kernel.is_decision_paused():
        _fail("first ordinary decision did not return to player pause")
        return

    var second_started_usec: int = Time.get_ticks_usec()
    var second_action: MovementActionResult = movement.request_turn_left(Fixture.PLAYER_ID)
    if second_action == null or not second_action.is_accepted():
        _fail("second ordinary player decision was not accepted")
        return
    var second_stop_reason: int = kernel.run_until_stop()
    var second_elapsed_usec: int = maxi(0, Time.get_ticks_usec() - second_started_usec)
    if not kernel.is_decision_paused():
        _fail("second ordinary decision did not return to player pause")
        return

    var elapsed_usec: int = first_elapsed_usec + second_elapsed_usec
    var perception_after: int = _perception_recompute_total(cohort, active)
    var infected_perception_usec_after: int = _perception_usec_total(cohort, active)
    var infected_geometry_after: int = _geometry_recompute_total(cohort, active)
    var infected_geometry_usec_after: int = _geometry_usec_total(cohort, active)
    var player_perception_count_after: int = player_perception.recompute_count()
    var player_perception_usec_after: int = player_perception.recompute_total_usec()
    var behavior_after: Dictionary = cohort.metrics_snapshot()
    var perception_delta: int = perception_after - perception_before
    var infected_perception_usec_delta: int = infected_perception_usec_after - infected_perception_usec_before
    var infected_geometry_delta: int = infected_geometry_after - infected_geometry_before
    var infected_geometry_usec_delta: int = infected_geometry_usec_after - infected_geometry_usec_before
    var player_perception_delta: int = player_perception_count_after - player_perception_count_before
    var player_perception_usec_delta: int = player_perception_usec_after - player_perception_usec_before
    var evaluation_delta: int = int(behavior_after.get("behavior_evaluation_count", 0)) \
        - int(behavior_before.get("behavior_evaluation_count", 0))
    var evaluation_usec_delta: int = int(behavior_after.get("behavior_evaluation_total_usec", 0)) \
        - int(behavior_before.get("behavior_evaluation_total_usec", 0))
    var evaluation_max_usec: int = int(behavior_after.get("behavior_evaluation_max_usec", 0))
    var submission_delta: int = int(behavior_after.get("ordinary_action_submission_count", 0)) \
        - int(behavior_before.get("ordinary_action_submission_count", 0))

    if perception_delta < 0 or infected_perception_usec_delta < 0         or infected_geometry_delta < 0 or infected_geometry_usec_delta < 0         or player_perception_delta < 0 or player_perception_usec_delta < 0         or evaluation_delta < 0 or evaluation_usec_delta < 0 or submission_delta < 0:
        _fail("performance counters moved backward")
        return
    if infected_geometry_delta != 0:
        _fail("lighting/acquisition refresh rebuilt infected geometric LOS")
        return
    if evaluation_delta != active.size() * 2:
        _fail("expected one behavior evaluation per active infected per player decision")
        return
    if evaluation_usec_delta > 10000:
        _fail("infected behavior evaluation exceeded focused 10ms aggregate budget")
        return

    print("PHASE2_INFECTED_PERF_METRIC head_route=two_player_turns active=%d tick_delta=%d elapsed_usec=%d first_elapsed_usec=%d second_elapsed_usec=%d infected_perception_recomputes=%d infected_perception_usec=%d infected_geometry_recomputes=%d infected_geometry_usec=%d player_perception_recomputes=%d player_perception_usec=%d behavior_evaluations=%d behavior_eval_usec=%d behavior_eval_max_usec=%d submissions=%d stop_reasons=%d/%d" % [
        active.size(),
        kernel.world_tick() - start_tick,
        elapsed_usec,
        first_elapsed_usec,
        second_elapsed_usec,
        perception_delta,
        infected_perception_usec_delta,
        infected_geometry_delta,
        infected_geometry_usec_delta,
        player_perception_delta,
        player_perception_usec_delta,
        evaluation_delta,
        evaluation_usec_delta,
        evaluation_max_usec,
        submission_delta,
        first_stop_reason,
        second_stop_reason,
    ])
    quit(0)

func _geometry_recompute_total(cohort: ActiveInfectedCohortService, actor_ids: Array[String]) -> int:
    var total: int = 0
    for actor_id: String in actor_ids:
        var perception: StreamingObserverPerceptionService = cohort.perception_for_actor(actor_id)
        if perception != null:
            total += perception.geometry_recompute_count()
    return total

func _geometry_usec_total(cohort: ActiveInfectedCohortService, actor_ids: Array[String]) -> int:
    var total: int = 0
    for actor_id: String in actor_ids:
        var perception: StreamingObserverPerceptionService = cohort.perception_for_actor(actor_id)
        if perception != null:
            total += perception.geometry_recompute_total_usec()
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
