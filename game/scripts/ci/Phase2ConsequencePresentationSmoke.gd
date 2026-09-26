extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE2_CONSEQUENCE_PRESENTATION: " + message)
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
    var combat: CombatActionService = game.get("_combat_actions")
    var movement: MovementActionService = game.get("_movement")
    var health: ActorHealthState = game.get("_health_state")
    var deaths: ActorDeathTransitionService = game.get("_death_transitions")
    var presenter: ConsequenceMomentPresenter = game.consequence_presenter()
    if kernel == null or combat == null or movement == null or health == null or deaths == null         or presenter == null or not presenter.is_configured():
        _fail("production consequence presentation owners are incomplete")
        return

    if not combat.impact_resolved.is_connected(Callable(presenter, "note_impact"))         or not combat.shove_resolved.is_connected(Callable(presenter, "note_shove"))         or not movement.movement_committed.is_connected(Callable(presenter, "note_movement"))         or not movement.physical_pressure_resolved.is_connected(Callable(presenter, "note_pressure"))         or not deaths.actor_died.is_connected(Callable(presenter, "note_death")):
        _fail("production consequence signals are not wired to the presenter")
        return

    var cohort: Array[Dictionary] = game.infected_cohort_results()
    if cohort.size() < 2:
        _fail("production infected cohort unavailable")
        return
    var infected_a: String = String(cohort[0].get("actor_id", ""))
    var infected_b: String = String(cohort[1].get("actor_id", ""))
    if infected_a.is_empty() or infected_b.is_empty():
        _fail("infected actor identity missing")
        return

    var tick_before: int = kernel.world_tick()
    health.begin_consequence_batch()
    presenter.note_impact(Fixture.PLAYER_ID, infected_a, 1001, Vector2i.ZERO, 4, &"blunt")
    presenter.note_impact(infected_a, Fixture.PLAYER_ID, 1002, Vector2i.ZERO, 5, &"blunt")
    presenter.note_shove(Fixture.PLAYER_ID, infected_b, 1003, true)
    presenter.note_pressure(infected_b, 11, true, false)
    presenter.note_pressure(infected_b, 9, false, false)
    presenter.note_movement(Fixture.PLAYER_ID, 1004, MovementActionService.STEP_FORWARD, Vector2i(1, 0), 1)
    presenter.note_movement(infected_a, 1005, MovementActionService.STEP_FORWARD, Vector2i(2, 0), 3)
    presenter.note_death(Fixture.PLAYER_ID, "corpse.test.player")
    presenter.note_death(infected_a, "corpse.test.infected")
    health.end_consequence_batch()

    if kernel.world_tick() != tick_before:
        _fail("presentation advanced WHEN time")
        return

    var snapshot: Dictionary = presenter.presentation_snapshot()
    var text_value: String = String(snapshot.get("text", ""))
    if int(snapshot.get("tick", -1)) != tick_before:
        _fail("presentation did not retain the shared consequence tick")
        return
    if int(snapshot.get("event_count", 0)) != 8:
        _fail("duplicate pressure was not coalesced at one consequence boundary")
        return
    if not text_value.contains("SAME MOMENT")         or not text_value.contains("YOU ↔ INFECTED hit each other")         or not text_value.contains("BOTH DOWN")         or not text_value.contains("crowd pressure shifts 1")         or not text_value.contains("2 actors reposition together"):
        _fail("coherent consequence summary missing required simultaneous cues: %s" % text_value)
        return

    var history_before: int = presenter.history_snapshot().size()
    presenter.note_movement(Fixture.PLAYER_ID, 2001, MovementActionService.STEP_FORWARD, Vector2i(9, 9), 1)
    await process_frame
    if presenter.history_snapshot().size() != history_before:
        _fail("single ordinary movement created presentation spam")
        return
    if kernel.world_tick() != tick_before:
        _fail("deferred presentation work advanced WHEN time")
        return

    print("PHASE2_CONSEQUENCE_PRESENTATION_OK tick=%d events=%d history=%d text=%s" % [
        tick_before,
        int(snapshot.get("event_count", 0)),
        presenter.history_snapshot().size(),
        text_value,
    ])
    quit(0)
