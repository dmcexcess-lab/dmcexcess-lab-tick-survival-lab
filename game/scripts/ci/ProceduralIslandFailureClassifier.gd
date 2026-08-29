extends SceneTree

const FixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

func _initialize() -> void:
    var expected_prefix: String = OS.get_environment("TICK_LAB_EXPECT_FAILURE_PREFIX")
    var seed_text: String = OS.get_environment("TICK_LAB_SEED")
    if expected_prefix.is_empty() or seed_text.is_empty() or not seed_text.is_valid_int():
        push_error("PROCEDURAL_ISLAND_FAILURE_CLASSIFIER_CONFIG_MISSING")
        quit(2)
        return

    var seed: int = seed_text.to_int()
    var plan: GeneratedGlobalWorldPlan = FixtureClass.generate_global_plan(seed)
    if plan == null:
        print("::error title=Procedural island seed %d::failure_reason=null_plan" % seed)
        quit(1)
        return
    if plan.is_generated():
        print("::error title=Procedural island seed %d::failure_reason=unexpected_success" % seed)
        quit(1)
        return

    var reason: String = String(plan.failure_reason)
    if not reason.begins_with(expected_prefix):
        print("::error title=Procedural island seed %d::failure_reason=%s" % [seed, reason])
        quit(1)
        return

    print("PROCEDURAL_ISLAND_FAILURE_CLASSIFIER_OK seed=%d prefix=%s" % [seed, expected_prefix])
    quit(0)
