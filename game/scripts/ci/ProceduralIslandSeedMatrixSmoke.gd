extends SceneTree

const FixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

const SEEDS: Array[int] = [
    1,
    7,
    29,
    101,
    997,
    20001,
    28028,
    104729,
    524287,
    999983,
    123456789,
    2147483629,
]

var _failures: Array[String] = []

func _initialize() -> void:
    var seeds: Array[int] = SEEDS
    var requested_seed: String = OS.get_environment("TICK_LAB_PROCEDURAL_SEED")
    if not requested_seed.is_empty():
        seeds = [int(requested_seed)]

    for seed: int in seeds:
        var plan: GeneratedGlobalWorldPlan = FixtureClass.generate_global_plan(seed)
        if plan == null:
            _failures.append("requested_seed=%d reason=no_valid_plan_within_retry_budget" % seed)
            continue
        if not plan.is_generated():
            _failures.append("requested_seed=%d resolved_seed=%d reason=%s" % [seed, plan.seed, plan.failure_reason])
            continue
        if plan.seed <= 0:
            _failures.append("requested_seed=%d reason=invalid_resolved_seed" % seed)
            continue
        if plan.seed != seed:
            print("PROCEDURAL_ISLAND_SEED_REROLLED requested=%d resolved=%d" % [seed, plan.seed])
        print("PROCEDURAL_ISLAND_SEED_OK requested=%d resolved=%d signature=%s" % [seed, plan.seed, plan.signature()])

    if _failures.is_empty():
        print("PROCEDURAL_ISLAND_SEED_MATRIX_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("PROCEDURAL_ISLAND_SEED_MATRIX_SMOKE_FAIL: %s" % failure)
    quit(1)
