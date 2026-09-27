extends SceneTree

const Bootstrap = preload("res://scripts/generation/integration/ProductionWorldBootstrap.gd")

const KNOWN_STRUCTURALLY_INVALID_SEED: int = 28028

var _failures: Array[String] = []

func _initialize() -> void:
    var resolved: Dictionary = Bootstrap._resolve_new_game_plan(KNOWN_STRUCTURALLY_INVALID_SEED)
    if not bool(resolved.get("ok", false)):
        _failures.append("production resolver did not recover from structurally invalid seed: %s" % String(resolved.get("failure_reason", "unknown")))
    else:
        var effective_seed: int = int(resolved.get("seed", -1))
        var plan: Variant = resolved.get("global_plan")
        if effective_seed <= 0 or effective_seed == KNOWN_STRUCTURALLY_INVALID_SEED:
            _failures.append("production resolver did not advance to a valid seed")
        elif plan == null or not plan.is_generated() or plan.seed != effective_seed:
            _failures.append("production resolver returned invalid/mismatched global plan")

    var deterministic: Dictionary = Bootstrap._resolve_new_game_plan(Bootstrap.DEFAULT_TEST_SEED)
    if not bool(deterministic.get("ok", false)):
        _failures.append("default production seed could not resolve: %s" % String(deterministic.get("failure_reason", "unknown")))

    if _failures.is_empty():
        print("PRODUCTION_SEED_ACCEPTANCE_REGRESSION_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("PRODUCTION_SEED_ACCEPTANCE_REGRESSION_SMOKE_FAIL: %s" % failure)
    quit(1)
