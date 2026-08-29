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
    for seed: int in SEEDS:
        var plan: GeneratedGlobalWorldPlan = FixtureClass.generate_global_plan(seed)
        if plan == null:
            _failures.append("seed=%d reason=null_plan" % seed)
            continue
        if not plan.is_generated():
            _failures.append("seed=%d reason=%s" % [seed, plan.failure_reason])
            continue
        print("PROCEDURAL_ISLAND_SEED_OK seed=%d signature=%s" % [seed, plan.deterministic_signature()])

    if _failures.is_empty():
        print("PROCEDURAL_ISLAND_SEED_MATRIX_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("PROCEDURAL_ISLAND_SEED_MATRIX_SMOKE_FAIL: %s" % failure)
    quit(1)
