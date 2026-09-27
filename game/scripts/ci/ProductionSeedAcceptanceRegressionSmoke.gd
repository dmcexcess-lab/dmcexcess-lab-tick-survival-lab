extends SceneTree

const Bootstrap = preload("res://scripts/generation/integration/ProductionWorldBootstrap.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    var screenshot_failure := "island_population_planning_failed:island_population_site_generation_failed:area.rural.scattered.003:parcel_access_failed"
    if not Bootstrap._retryable_seed_failure(screenshot_failure):
        _failures.append("observed local-generation rejection is not classified as seed-sensitive")
    if Bootstrap._retryable_seed_failure("invalid_island_world_request"):
        _failures.append("deterministic configuration failure must not be retried")
    if Bootstrap._next_world_seed(41) != 42:
        _failures.append("candidate seed does not advance deterministically")

    var resolved: Dictionary = Bootstrap._resolve_new_game_plan(Bootstrap.DEFAULT_TEST_SEED)
    if not bool(resolved.get("ok", false)):
        _failures.append("default production seed could not resolve: %s" % String(resolved.get("failure_reason", "unknown")))
    else:
        var effective_seed: int = int(resolved.get("seed", -1))
        var plan: Variant = resolved.get("global_plan")
        if effective_seed <= 0 or plan == null or not plan.is_generated() or plan.seed != effective_seed:
            _failures.append("production resolver returned invalid/mismatched global plan")

    if _failures.is_empty():
        print("PRODUCTION_SEED_ACCEPTANCE_REGRESSION_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("PRODUCTION_SEED_ACCEPTANCE_REGRESSION_SMOKE_FAIL: %s" % failure)
    quit(1)
