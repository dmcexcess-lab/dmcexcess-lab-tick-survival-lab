extends SceneTree

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Telemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE1_SURVIVOR_RUNTIME_BASELINE: " + message)
    quit(1)

func _run() -> void:
    Telemetry.reset()
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("gameplay scene missing")
        return

    var game: Node = scene.instantiate()
    if game == null:
        _fail("gameplay scene failed to instantiate")
        return

    var boot_started: int = Time.get_ticks_usec()
    get_root().add_child(game)
    var boot_usec: int = maxi(Time.get_ticks_usec() - boot_started, 0)
    await process_frame

    if not game.has_method("infected_cohort_service") or not game.has_method("survivor_cohort_service"):
        _fail("expected current production cohort APIs are missing")
        return

    var infected: ActiveInfectedCohortService = game.infected_cohort_service()
    var survivors: ActiveSurvivorCohortService = game.survivor_cohort_service()
    if infected == null or survivors == null:
        _fail("current production cohorts did not boot")
        return
    if infected.roster_actor_ids().size() != 8:
        _fail("expected eight infected in current production cohort")
        return
    if survivors.roster_actor_ids().size() != 4:
        _fail("expected four live survivor NPCs in current production cohort")
        return

    var kernel: TickKernel = game.get("_kernel")
    var controller: PlayerActionController = game.get("_controller")
    if kernel == null or controller == null or game.get("_world_time") == null         or game.get("_inventory_state") == null or game.get("_utilities") == null:
        _fail("ordinary startup/time/inventory/utility services are incomplete")
        return

    var infected_before: Dictionary = infected.metrics_snapshot()
    var survivor_before: Dictionary = survivors.metrics_snapshot()
    var tick_before: int = kernel.world_tick()
    controller.submit_intent(Intents.TURN_RIGHT)
    if not controller.is_busy():
        _fail("ordinary player action was not accepted")
        return
    for _frame: int in range(240):
        if not controller.is_busy():
            break
        await process_frame
    if controller.is_busy() or kernel.world_tick() <= tick_before:
        _fail("ordinary player action did not return to the decision pause")
        return

    var infected_after: Dictionary = infected.metrics_snapshot()
    var survivor_after: Dictionary = survivors.metrics_snapshot()
    print(
        "PHASE1_SURVIVOR_RUNTIME_BASELINE_OK boot_usec=%d infected_roster=%d survivor_roster=%d infected_eval_delta=%d survivor_eval_delta=%d infected_eval_usec_delta=%d survivor_eval_usec_delta=%d" % [
            boot_usec,
            infected.roster_actor_ids().size(),
            survivors.roster_actor_ids().size(),
            int(infected_after.get("behavior_evaluation_count", 0)) - int(infected_before.get("behavior_evaluation_count", 0)),
            int(survivor_after.get("behavior_evaluation_count", 0)) - int(survivor_before.get("behavior_evaluation_count", 0)),
            int(infected_after.get("behavior_evaluation_total_usec", 0)) - int(infected_before.get("behavior_evaluation_total_usec", 0)),
            int(survivor_after.get("behavior_evaluation_total_usec", 0)) - int(survivor_before.get("behavior_evaluation_total_usec", 0)),
        ]
    )
    quit(0)
