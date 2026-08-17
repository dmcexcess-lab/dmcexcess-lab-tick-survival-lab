extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const CatalogClass = preload("res://scripts/simulation/collision/CollisionCatalog.gd")
const OverridesClass = preload("res://scripts/simulation/collision/CollisionOverrideState.gd")
const QueryClass = preload("res://scripts/simulation/collision/SpatialQueryService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const TickRules = preload("res://scripts/foundation/time/TickRules.gd")
const BasePolicyClass = preload("res://scripts/simulation/movement/MovementTraversalPolicy.gd")
const MovementClass = preload("res://scripts/simulation/movement/MovementActionService.gd")
const MovementResult = preload("res://scripts/simulation/movement/MovementActionResult.gd")
const DamageInterruptClass = preload("res://scripts/simulation/movement/MovementDamageInterruptionService.gd")
const LocomotionStateClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionState.gd")
const LocomotionMutationClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionMutationService.gd")
const Stance = preload("res://scripts/simulation/actors/locomotion/ActorStance.gd")
const CapabilityClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementCapabilityService.gd")
const ActorPolicyClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementTraversalPolicy.gd")
const HealthClass = preload("res://scripts/simulation/actors/health/ActorHealthState.gd")
const NeedsClass = preload("res://scripts/simulation/actors/needs/ActorNeedsState.gd")
const NeedsProviderClass = preload("res://scripts/simulation/actors/needs/ActorNeedsMobilityModifierProvider.gd")
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const KeyboardClass = preload("res://scripts/input/KeyboardInputAdapter.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _test_two_stride_run_baseline()
    _test_fatigue_gate()
    _test_crouched_run_blocked()
    _test_damage_interrupts_walk_not_run()
    _test_input_contract()
    if failures.is_empty():
        print("RUN_DAMAGE_WALKING_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("RUN_DAMAGE_WALKING_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture(actor_id: String) -> Dictionary:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var catalog := CatalogClass.new()
    var overrides := OverridesClass.new()
    var query := QueryClass.new(world, catalog, overrides)
    var kernel := TickKernelClass.new()
    var base_policy := BasePolicyClass.new(3)
    _check(catalog.register(&"actor.survivor", true), "register actor collision")
    _check(base_policy.register_terrain(&"ground.test", true, 10), "register terrain")
    for y: int in range(0, 8):
        for x: int in range(0, 12):
            mutations.set_terrain(Vector2i(x, y), &"ground.test")
    mutations.create_entity(&"actor.survivor", actor_id)
    mutations.set_placement(actor_id, Layers.Channel.ACTOR, Vector2i(2, 2), Facing.Value.EAST, Footprint.single_cell())
    var locomotion := LocomotionStateClass.new()
    var locomotion_mutations := LocomotionMutationClass.new(locomotion)
    locomotion_mutations.enroll(actor_id)
    var health := HealthClass.new(world)
    health.enroll_actor(actor_id)
    var needs := NeedsClass.new(world)
    needs.enroll_actor(actor_id)
    var capability := CapabilityClass.new(locomotion)
    capability.register_provider(NeedsProviderClass.new(needs))
    var actor_policy := ActorPolicyClass.new(base_policy, capability)
    var movement := MovementClass.new(world, mutations, query, kernel, actor_policy)
    var damage_interrupt := DamageInterruptClass.new(health, kernel)
    return {
        "world": world,
        "kernel": kernel,
        "movement": movement,
        "health": health,
        "needs": needs,
        "locomotion_mutations": locomotion_mutations,
        "damage_interrupt": damage_interrupt,
    }

func _test_two_stride_run_baseline() -> void:
    var f := _fixture("actor.run")
    var run: MovementActionResult = f["movement"].request_run_forward("actor.run")
    _check(run.is_accepted() and run.duration_ticks == 12, "healthy Run remains two cells in twelve ticks")
    _check(f["kernel"].schedule_event(6, "system17", &"observe") > 0, "midpoint event scheduled")
    _check(f["kernel"].run_next_batch() == TickRules.RunStopReason.BATCH_COMPLETE, "first stride batch resolves")
    _check(f["world"].placement("actor.run").anchor == Vector2i(3, 2), "first stride reaches intermediate cell")
    _check(f["kernel"].run_until_stop() == TickRules.RunStopReason.IDLE, "Run drains")
    _check(f["world"].placement("actor.run").anchor == Vector2i(4, 2), "second stride reaches final cell")

func _test_fatigue_gate() -> void:
    var f := _fixture("actor.fatigue")
    f["needs"].set_need("actor.fatigue", NeedsClass.FATIGUE, 79)
    var accepted: MovementActionResult = f["movement"].request_run_forward("actor.fatigue")
    _check(accepted.is_accepted(), "fatigue 79 may start Run")
    var blocked_f := _fixture("actor.exhausted")
    blocked_f["needs"].set_need("actor.exhausted", NeedsClass.FATIGUE, 80)
    var blocked: MovementActionResult = blocked_f["movement"].request_run_forward("actor.exhausted")
    _check(blocked.status == MovementResult.Status.CAPABILITY_BLOCKED and blocked.reason == "too_exhausted_to_run", "fatigue 80 blocks Run")

func _test_crouched_run_blocked() -> void:
    var f := _fixture("actor.crouched")
    f["locomotion_mutations"].set_stance("actor.crouched", Stance.CROUCHED)
    var run: MovementActionResult = f["movement"].request_run_forward("actor.crouched")
    _check(run.status == MovementResult.Status.CAPABILITY_BLOCKED, "crouched Run remains blocked")

func _test_damage_interrupts_walk_not_run() -> void:
    var walk_f := _fixture("actor.walk_damage")
    walk_f["kernel"].external_event_due.connect(
        func(event):
            if event.event_type == &"damage":
                walk_f["health"].apply_damage("actor.walk_damage", 5)
    )
    var walk: MovementActionResult = walk_f["movement"].request_step_forward("actor.walk_damage")
    _check(walk.is_accepted(), "Walk accepted")
    walk_f["kernel"].schedule_event(5, "system17", &"damage")
    walk_f["kernel"].run_until_stop()
    _check(walk_f["world"].placement("actor.walk_damage").anchor == Vector2i(2, 2), "damage still cancels Walk")

    var run_f := _fixture("actor.run_damage")
    run_f["kernel"].external_event_due.connect(
        func(event):
            if event.event_type == &"damage":
                run_f["health"].apply_damage("actor.run_damage", 5)
    )
    var run: MovementActionResult = run_f["movement"].request_run_forward("actor.run_damage")
    _check(run.is_accepted(), "Run accepted")
    run_f["kernel"].schedule_event(8, "system17", &"damage")
    run_f["kernel"].run_until_stop()
    _check(run_f["world"].placement("actor.run_damage").anchor == Vector2i(4, 2), "damage still does not cancel committed Run")

func _test_input_contract() -> void:
    var shifted := InputEventKey.new()
    shifted.keycode = KEY_W
    shifted.shift_pressed = true
    _check(KeyboardClass._intent_for_key(shifted) == Intents.RUN_FORWARD, "Shift+W emits Run")
    var plain := InputEventKey.new()
    plain.keycode = KEY_W
    _check(KeyboardClass._intent_for_key(plain) == Intents.FORWARD, "plain W remains Walk")

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
