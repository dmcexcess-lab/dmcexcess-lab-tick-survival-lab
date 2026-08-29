extends SceneTree

const FixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const FAILING_SEEDS: Array[int] = [997, 28028, 524287]

func _initialize() -> void:
    var expected_prefix: String = OS.get_environment("TICK_LAB_EXPECT_FAILURE_PREFIX")
    if expected_prefix.is_empty():
        push_error("PROCEDURAL_ISLAND_FAILURE_CLASSIFIER_CONFIG_MISSING")
        quit(2)
        return

    for seed: int in FAILING_SEEDS:
        var plan: GeneratedGlobalWorldPlan = FixtureClass.generate_global_plan(seed)
        if plan == null:
            quit(1)
            return
        if plan.is_generated():
            quit(1)
            return
        if not String(plan.failure_reason).begins_with(expected_prefix):
            quit(1)
            return

    print("PROCEDURAL_ISLAND_FAILURE_CLASSIFIER_OK prefix=%s" % expected_prefix)
    quit(0)
