extends SceneTree

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

var _failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://main.tscn") as PackedScene
    _check(packed != null, "production main scene loads")
    if packed == null:
        _finish()
        return

    var game: Node = packed.instantiate()
    root.add_child(game)
    await process_frame

    _check(game is EnvironmentalPressureGameMain, "production root retains environmental-pressure gameplay")
    var indicator: WorldResolutionIndicator = game.get_node_or_null("ResolutionIndicator") as WorldResolutionIndicator
    _check(indicator != null, "world resolution indicator is mounted in production")
    if indicator == null:
        _finish()
        return

    var initial: Dictionary = indicator.presentation_snapshot()
    _check(bool(initial.get("configured", false)), "indicator is wired to authoritative production owners")
    _check(bool(initial.get("decision_paused", false)), "player begins at the real WHEN decision pause")
    _check(not indicator.indicator_visible(), "indicator stays hidden while the player is ready")
    _check(indicator.current_text().is_empty(), "ready state has no fake status word")

    var cohort: ActiveInfectedCohortService = game.call("infected_cohort_service") as ActiveInfectedCohortService
    _check(cohort != null and not cohort.active_actor_ids().is_empty(), "real stream-active infected are present for zombie-turn presentation")

    var controls: PlayerMovementControls = game.get_node_or_null("Controls") as PlayerMovementControls
    _check(controls != null and controls.is_enabled(), "player controls begin enabled")

    game.call("_route_player_intent", Intents.TURN_LEFT)
    var resolving: Dictionary = indicator.presentation_snapshot()
    _check(not bool(resolving.get("decision_paused", true)), "ordinary player commitment opens shared WHEN")
    _check(indicator.indicator_visible(), "resolution indicator becomes visible while world time resolves")
    _check(indicator.current_text() == WorldResolutionIndicator.ZOMBIES_TEXT, "active infected explain the slower shared-WHEN resolution as ZOMBIES")
    _check(controls != null and not controls.is_enabled(), "existing input lock remains active while the turn resolves")

    var streaming: WorldStreamingCoordinator = Fixture.streaming_coordinator()
    _check(streaming != null and streaming.is_ready(), "production technical streaming owner is available")
    if streaming != null:
        # Presentation-contract pulse only: the production coordinator emits this exact
        # signal after a real focus-region change. No streaming state is fabricated here.
        streaming.active_regions_changed.emit([Vector2i(9001, 9001)], [])
        var loading_over_zombies: Dictionary = indicator.presentation_snapshot()
        _check(bool(loading_over_zombies.get("loading", false)), "technical region transition raises loading presentation")
        _check(indicator.current_text() == WorldResolutionIndicator.LOADING_TEXT, "LOADING takes presentation priority over ZOMBIES")
        _check(not bool(loading_over_zombies.get("decision_paused", true)), "loading label does not invent a new simulation pause")

    await process_frame
    var after_loading_frame: Dictionary = indicator.presentation_snapshot()
    if not bool(after_loading_frame.get("decision_paused", true)):
        _check(indicator.current_text() == WorldResolutionIndicator.ZOMBIES_TEXT, "after the loading pulse, unresolved world time returns to ZOMBIES")

    var frames: int = 0
    while frames < 256 and not bool(indicator.presentation_snapshot().get("decision_paused", false)):
        await process_frame
        frames += 1

    var ready_again: Dictionary = indicator.presentation_snapshot()
    _check(bool(ready_again.get("decision_paused", false)), "shared WHEN eventually returns to the player decision pause")
    _check(not indicator.indicator_visible(), "ZOMBIES disappears immediately when player decision control returns")
    _check(controls != null and controls.is_enabled(), "input unlocks at the same real decision boundary")

    if streaming != null:
        streaming.active_regions_changed.emit([Vector2i(9002, 9002)], [])
        _check(indicator.current_text() == WorldResolutionIndicator.LOADING_TEXT, "LOADING also explains a region transition when no zombie resolution is active")
        await process_frame
        await process_frame
        _check(not indicator.indicator_visible(), "loading word clears without spinner, progress bar, or persistent modal")

    _finish()

func _check(condition: bool, label: String) -> void:
    if condition:
        print("PASS: %s" % label)
        return
    _failures += 1
    push_error("FAIL: %s" % label)

func _finish() -> void:
    if _failures == 0:
        print("PROMPT_WORLD_RESOLUTION_INDICATOR_SMOKE: PASS")
        quit(0)
        return
    print("PROMPT_WORLD_RESOLUTION_INDICATOR_SMOKE: FAIL count=%d" % _failures)
    quit(1)
