extends SceneTree

const BOOTSTRAP_PATH := "res://scripts/generation/integration/ProductionWorldBootstrap.gd"

var _failures: Array[String] = []

func _initialize() -> void:
    var file := FileAccess.open(BOOTSTRAP_PATH, FileAccess.READ)
    if file == null:
        push_error("PRODUCTION_SEED_ACCEPTANCE_REGRESSION_SMOKE_FAIL: bootstrap source unreadable")
        quit(1)
        return
    var source: String = file.get_as_text()
    file.close()
    _require(source, "_resolve_new_game_plan(requested_seed)", "NEW GAME does not pass through production seed acceptance")
    _require(source, "for attempt: int in range(MAX_WORLD_SEED_ATTEMPTS)", "production seed acceptance does not retry bounded candidates")
    _require(source, "_retryable_seed_failure(last_failure)", "retry gate is missing")
    _require(source, "candidate_seed = _next_world_seed(candidate_seed)", "candidate seed does not advance")
    _require(source, "island_population_planning_failed", "local-site generation failures are not accepted as seed-sensitive")
    _require(source, "return {\"ok\": false, \"seed\": candidate_seed", "non-seed failures do not fail diagnostically")
    if source.contains("scripts/demo") or source.contains("FixtureClass") or source.contains("actor.player.demo"):
        _failures.append("production bootstrap regained demo ownership")

    if _failures.is_empty():
        print("PRODUCTION_SEED_ACCEPTANCE_REGRESSION_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("PRODUCTION_SEED_ACCEPTANCE_REGRESSION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _require(source: String, needle: String, failure: String) -> void:
    if not source.contains(needle):
        _failures.append(failure)
