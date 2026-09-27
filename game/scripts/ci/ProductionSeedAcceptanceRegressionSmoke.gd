extends SceneTree

const Bootstrap = preload("res://scripts/generation/integration/ProductionWorldBootstrap.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    var screenshot_failure := "island_population_planning_failed:island_population_site_generation_failed:area.rural.scattered.003:parcel_access_failed"
    if not Bootstrap._retryable_seed_failure(screenshot_failure):
        _failures.append("observed local-generation rejection is not classified as seed-sensitive")
    if not Bootstrap._retryable_seed_failure("island_population_planning_failed:island_population_site_generation_failed:area.smalltown.center.001:infrastructure_reservation_unresolved"):
        _failures.append("observed infrastructure-local rejection is not classified as seed-sensitive")
    if Bootstrap._retryable_seed_failure("invalid_island_world_request"):
        _failures.append("deterministic configuration failure must not be retried")
    if Bootstrap._next_world_seed(41) != 42:
        _failures.append("candidate seed does not advance deterministically")
    if Bootstrap._next_world_seed(0x7fffffff) != 1:
        _failures.append("candidate seed wrap is invalid")

    if _failures.is_empty():
        print("PRODUCTION_SEED_ACCEPTANCE_REGRESSION_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("PRODUCTION_SEED_ACCEPTANCE_REGRESSION_SMOKE_FAIL: %s" % failure)
    quit(1)
