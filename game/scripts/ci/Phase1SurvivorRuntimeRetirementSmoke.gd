extends SceneTree

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Telemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")

const BASELINE_BOOT_USEC: int = 19780576
const BASELINE_INFECTED_EVAL_DELTA: int = 8
const BASELINE_INFECTED_EVAL_USEC_DELTA: int = 164489
const BASELINE_SURVIVOR_EVAL_DELTA: int = 2
const BASELINE_SURVIVOR_EVAL_USEC_DELTA: int = 43198

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE1_SURVIVOR_RUNTIME_RETIREMENT: " + message)
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

    if not game.has_method("infected_cohort_service"):
        _fail("infected cohort API was removed")
        return
    for retired_method: StringName in [
        &"survivor_npc_state",
        &"survivor_cohort_service",
        &"survivor_interaction_service",
        &"survivor_infection_service",
    ]:
        if game.has_method(retired_method):
            _fail("retired survivor runtime API is still composed: %s" % String(retired_method))
            return

    var infected: ActiveInfectedCohortService = game.infected_cohort_service()
    var infected_state: InfectedState = game.infected_state()
    if infected == null or infected_state == null:
        _fail("infected runtime did not boot")
        return
    if infected.roster_actor_ids().size() != 8:
        _fail("expected eight infected in production cohort")
        return
    if infected.has_method("add_member") or infected.has_method("remove_member"):
        _fail("live infected cohort still exposes the retired outbreak-conversion mutation seam")
        return

    var world: WorldState = game.get("_world")
    var kernel: TickKernel = game.get("_kernel")
    var controller: PlayerActionController = game.get("_controller")
    var world_time: WorldTimeService = game.get("_world_time")
    var inventory: InventoryContainmentState = game.get("_inventory_state")
    var utilities: UtilityRuntimeState = game.get("_utilities")
    if world == null or kernel == null or controller == null or world_time == null or inventory == null or utilities == null:
        _fail("ordinary startup/time/inventory/utility services are incomplete")
        return
    if not world_time.is_ready() or world_time.current_time().is_empty():
        _fail("world time is not operational after survivor retirement")
        return
    if not inventory.has_container(Fixture.PLAYER_ID):
        _fail("player inventory container is missing after survivor retirement")
        return
    if not utilities.is_ready():
        _fail("utility runtime is not operational after survivor retirement")
        return

    var live_noninfected_npcs: Array[String] = []
    for actor_id: String in world.entity_ids_of_type(&"actor.survivor"):
        if actor_id == Fixture.PLAYER_ID:
            continue
        if not infected_state.is_infected(actor_id):
            live_noninfected_npcs.append(actor_id)
    if not live_noninfected_npcs.is_empty():
        _fail("non-infected survivor NPCs are still hydrated: %s" % str(live_noninfected_npcs))
        return

    var infected_before: Dictionary = infected.metrics_snapshot()
    var tick_before: int = kernel.world_tick()
    controller.submit_intent(Intents.TURN_RIGHT)
    if not controller.is_busy():
        _fail("ordinary player action was not accepted")
        return
    for _frame: int in range(240):
        if not controller.is_busy():
            break
        await process_frame
    if controller.is_busy() or kernel.world_tick() <= tick_before or not kernel.is_decision_paused():
        _fail("ordinary player action did not return to the decision pause")
        return

    var infected_after: Dictionary = infected.metrics_snapshot()
    var infected_eval_delta: int = int(infected_after.get("behavior_evaluation_count", 0)) - int(infected_before.get("behavior_evaluation_count", 0))
    var infected_eval_usec_delta: int = int(infected_after.get("behavior_evaluation_total_usec", 0)) - int(infected_before.get("behavior_evaluation_total_usec", 0))
    if infected_eval_delta <= 0:
        _fail("infected behavior no longer evaluates on an ordinary player commitment")
        return
    var current_time: Dictionary = world_time.current_time()
    if int(current_time.get("world_tick", -1)) != kernel.world_tick():
        _fail("world time no longer follows the authoritative tick")
        return

    print(
        "PHASE1_SURVIVOR_RUNTIME_RETIREMENT_OK boot_usec=%d baseline_boot_usec=%d infected_roster=%d live_survivor_npcs=0 infected_eval_delta=%d baseline_infected_eval_delta=%d infected_eval_usec_delta=%d baseline_infected_eval_usec_delta=%d removed_survivor_eval_delta=%d removed_survivor_eval_usec_delta=%d" % [
            boot_usec,
            BASELINE_BOOT_USEC,
            infected.roster_actor_ids().size(),
            infected_eval_delta,
            BASELINE_INFECTED_EVAL_DELTA,
            infected_eval_usec_delta,
            BASELINE_INFECTED_EVAL_USEC_DELTA,
            BASELINE_SURVIVOR_EVAL_DELTA,
            BASELINE_SURVIVOR_EVAL_USEC_DELTA,
        ]
    )
    quit(0)
