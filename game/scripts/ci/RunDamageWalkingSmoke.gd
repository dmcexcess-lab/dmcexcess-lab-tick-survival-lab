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
const RunExertionClass = preload("res://scripts/simulation/movement/MovementRunExertionService.gd")
const LocomotionStateClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionState.gd")
const LocomotionMutationClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionMutationService.gd")
const Stance = preload("res://scripts/simulation/actors/locomotion/ActorStance.gd")
const CapabilityClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementCapabilityService.gd")
const ActorPolicyClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementTraversalPolicy.gd")
const HealthClass = preload("res://scripts/simulation/actors/health/ActorHealthState.gd")
const NeedsClass = preload("res://scripts/simulation/actors/needs/ActorNeedsState.gd")
const NeedsProviderClass = preload("res://scripts/simulation/actors/needs/ActorNeedsMobilityModifierProvider.gd")
const ProviderBase = preload("res://scripts/simulation/actors/locomotion/ActorMobilityModifierProvider.gd")
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const KeyboardClass = preload("res://scripts/input/KeyboardInputAdapter.gd")
const ControlsClass = preload("res://scripts/ui/DemoMovementControls.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_healthy_run_two_phases_and_fatigue()
    _test_mixed_terrain_duration()
    _test_fatigue_gate_and_committed_crossing()
    _test_crouched_run_blocked()
    _test_damage_interrupts_walk_not_run()
    _test_second_stride_blocker_keeps_intermediate()
    _test_damage_signal_is_semantic()
    _test_input_contract()

    if _failures.is_empty():
        print("RUN_DAMAGE_WALKING_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("RUN_DAMAGE_WALKING_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture(actor_id: String = "actor.runner") -> Dictionary:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var catalog := CatalogClass.new()
    var overrides := OverridesClass.new()
    var query := QueryClass.new(world, catalog, overrides)
    var kernel := TickKernelClass.new()
    var base_policy := BasePolicyClass.new(3)

    _check(catalog.register(&"actor.survivor", true), "fixture survivor collision profile")
    _check(catalog.register(&"structure.wall", true), "fixture wall collision profile")
    _check(base_policy.register_terrain(&"ground.test", true, 10), "fixture 10-tick terrain")
    _check(base_policy.register_terrain(&"ground.slow", true, 14), "fixture 14-tick terrain")
    _check(base_policy.register_terrain(&"ground.water", false), "fixture blocked terrain")
    for y: int in range(0, 12):
        for x: int in range(0, 24):
            _check(mutations.set_terrain(Vector2i(x, y), &"ground.test"), "fixture terrain setup")

    _check(mutations.create_entity(&"actor.survivor", actor_id) == actor_id, "create survivor")
    _check(
        mutations.set_placement(
            actor_id,
            Layers.Channel.ACTOR,
            Vector2i(2, 2),
            Facing.Value.EAST,
            Footprint.single_cell()
        ),
        "place survivor"
    )

    var locomotion := LocomotionStateClass.new()
    var locomotion_mutations := LocomotionMutationClass.new(locomotion)
    _check(locomotion_mutations.enroll(actor_id), "enroll locomotion")

    var health := HealthClass.new(world)
    _check(health.enroll_actor(actor_id), "enroll health")
    var needs := NeedsClass.new(world)
    _check(needs.enroll_actor(actor_id), "enroll needs")

    var capability := CapabilityClass.new(locomotion)
    _check(capability.register_provider(NeedsProviderClass.new(needs)), "register Needs provider")
    var actor_policy := ActorPolicyClass.new(base_policy, capability)
    var movement := MovementClass.new(world, mutations, query, kernel, actor_policy)
    var damage_interrupt := DamageInterruptClass.new(health, kernel)
    var exertion := RunExertionClass.new(movement, needs)
    _check(movement.is_ready(), "movement ready")
    _check(damage_interrupt.is_ready(), "damage interruption ready")
    _check(exertion.is_ready(), "run exertion ready")

    return {
        "actor_id": actor_id,
        "world": world,
        "mutations": mutations,
        "catalog": catalog,
        "query": query,
        "kernel": kernel,
        "base_policy": base_policy,
        "locomotion": locomotion,
        "locomotion_mutations": locomotion_mutations,
        "health": health,
        "needs": needs,
        "capability": capability,
        "movement": movement,
        "damage_interrupt": damage_interrupt,
        "exertion": exertion,
    }

func _test_healthy_run_two_phases_and_fatigue() -> void:
    var f: Dictionary = _fixture("actor.healthy")
    var world: WorldState = f["world"]
    var kernel: TickKernel = f["kernel"]
    var movement: MovementActionService = f["movement"]
    var needs: ActorNeedsState = f["needs"]

    var run: MovementActionResult = movement.request_run_forward("actor.healthy")
    _check(run.is_accepted(), "healthy run accepted")
    _check(run.duration_ticks == 12 and run.target_anchor == Vector2i(4, 2), "healthy run is two cells / twelve ticks")
    _check(kernel.schedule_event(6, "run_smoke", &"test.stride_one_observe") > 0, "stride-one observation scheduled")
    _check(kernel.run_next_batch() == TickRules.RunStopReason.BATCH_COMPLETE, "kernel resolves tick-six batch")
    _check(kernel.world_tick() == 6, "first stride occurs at tick six")
    _check(world.placement("actor.healthy").anchor == Vector2i(3, 2), "first stride physically advances one cell")
    _check(needs.fatigue("actor.healthy") == 1, "first successful stride adds one fatigue")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "healthy run drains")
    _check(kernel.world_tick() == 12 and world.placement("actor.healthy").anchor == Vector2i(4, 2), "second stride commits at tick twelve")
    _check(needs.fatigue("actor.healthy") == 2, "full run adds two fatigue")

func _test_mixed_terrain_duration() -> void:
    var f: Dictionary = _fixture("actor.mixed")
    var mutations: WorldMutationService = f["mutations"]
    var movement: MovementActionService = f["movement"]
    _check(mutations.set_terrain(Vector2i(4, 2), &"ground.slow"), "mixed run second terrain made slow")
    var run: MovementActionResult = movement.request_run_forward("actor.mixed")
    _check(run.is_accepted() and run.duration_ticks == 15, "10 then 14 walk terrain resolves to 6 plus 9 run ticks")

func _test_fatigue_gate_and_committed_crossing() -> void:
    var f: Dictionary = _fixture("actor.fatigue")
    var world: WorldState = f["world"]
    var kernel: TickKernel = f["kernel"]
    var movement: MovementActionService = f["movement"]
    var needs: ActorNeedsState = f["needs"]
    _check(needs.set_need("actor.fatigue", NeedsClass.FATIGUE, 79), "fatigue set to last runnable value")
    var run: MovementActionResult = movement.request_run_forward("actor.fatigue")
    _check(run.is_accepted(), "fatigue 79 can start run")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "fatigue-79 committed run drains")
    _check(world.placement("actor.fatigue").anchor == Vector2i(4, 2), "crossing exhausted threshold mid-run does not stop stride two")
    _check(needs.fatigue("actor.fatigue") == 81, "run from 79 ends at 81 fatigue")
    var rejected: MovementActionResult = movement.request_run_forward("actor.fatigue")
    _check(rejected.status == MovementResult.Status.CAPABILITY_BLOCKED and rejected.reason == "too_exhausted_to_run", "fatigue 80+ blocks next run")

    var provider := NeedsProviderClass.new(needs)
    var provider_result: Dictionary = provider.evaluate("actor.fatigue", &"movement.run_forward")
    _check(int(provider_result.get("status", -1)) == ProviderBase.Status.BLOCKED, "Needs provider exposes exhausted run block")

func _test_crouched_run_blocked() -> void:
    var f: Dictionary = _fixture("actor.crouched")
    var locomotion_mutations: ActorLocomotionMutationService = f["locomotion_mutations"]
    var movement: MovementActionService = f["movement"]
    _check(locomotion_mutations.set_stance("actor.crouched", Stance.CROUCHED), "actor crouches")
    var run: MovementActionResult = movement.request_run_forward("actor.crouched")
    _check(run.status == MovementResult.Status.CAPABILITY_BLOCKED, "crouched actor cannot run")

func _test_damage_interrupts_walk_not_run() -> void:
    var walk_f: Dictionary = _fixture("actor.walk_damage")
    var walk_world: WorldState = walk_f["world"]
    var walk_kernel: TickKernel = walk_f["kernel"]
    var walk_movement: MovementActionService = walk_f["movement"]
    var walk_health: ActorHealthState = walk_f["health"]
    walk_kernel.external_event_due.connect(
        func(event):
            if event.event_type == &"test.damage_walk":
                walk_health.apply_damage("actor.walk_damage", 5)
    )
    var walk: MovementActionResult = walk_movement.request_step_forward("actor.walk_damage")
    _check(walk.is_accepted(), "damage-interrupt walk accepted")
    _check(walk_kernel.schedule_event(5, "run_smoke", &"test.damage_walk") > 0, "walk damage event scheduled")
    _check(walk_kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "damage-interrupted walk resolves")
    _check(walk_kernel.world_tick() == 5, "walk interruption keeps elapsed ticks spent")
    _check(walk_world.placement("actor.walk_damage").anchor == Vector2i(2, 2), "damage cancels walk before placement commit")
    _check(walk_health.current_hp("actor.walk_damage") == 95, "walk damage is real HP damage")

    var run_f: Dictionary = _fixture("actor.run_damage")
    var run_world: WorldState = run_f["world"]
    var run_kernel: TickKernel = run_f["kernel"]
    var run_movement: MovementActionService = run_f["movement"]
    var run_health: ActorHealthState = run_f["health"]
    run_kernel.external_event_due.connect(
        func(event):
            if event.event_type == &"test.damage_run":
                run_health.apply_damage("actor.run_damage", 5)
    )
    var run: MovementActionResult = run_movement.request_run_forward("actor.run_damage")
    _check(run.is_accepted(), "damage-during-run action accepted")
    _check(run_kernel.schedule_event(8, "run_smoke", &"test.damage_run") > 0, "run damage event scheduled between strides")
    _check(run_kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "committed damaged run drains")
    _check(run_world.placement("actor.run_damage").anchor == Vector2i(4, 2), "damage does not cancel committed run")
    _check(run_kernel.world_tick() == 12 and run_health.current_hp("actor.run_damage") == 95, "run finishes on schedule despite damage")

func _test_second_stride_blocker_keeps_intermediate() -> void:
    var f: Dictionary = _fixture("actor.partial")
    var world: WorldState = f["world"]
    var mutations: WorldMutationService = f["mutations"]
    var kernel: TickKernel = f["kernel"]
    var movement: MovementActionService = f["movement"]
    var needs: ActorNeedsState = f["needs"]
    kernel.external_event_due.connect(
        func(event):
            if event.event_type == &"test.block_final":
                mutations.create_entity(&"structure.wall", "wall.final")
                mutations.set_placement(
                    "wall.final",
                    Layers.Channel.STRUCTURE,
                    Vector2i(4, 2),
                    Facing.Value.NORTH,
                    Footprint.single_cell()
                )
    )
    var run: MovementActionResult = movement.request_run_forward("actor.partial")
    _check(run.is_accepted(), "partial-run request accepted before race blocker")
    _check(kernel.schedule_event(8, "run_smoke", &"test.block_final") > 0, "final blocker scheduled after stride one")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "partial run resolves")
    _check(world.placement("actor.partial").anchor == Vector2i(3, 2), "failed second stride preserves intermediate cell")
    _check(needs.fatigue("actor.partial") == 1, "only successful first stride charges fatigue")

func _test_damage_signal_is_semantic() -> void:
    var f: Dictionary = _fixture("actor.damage_signal")
    var health: ActorHealthState = f["health"]
    var events: Array = []
    health.damage_applied.connect(func(actor_id, amount, previous_hp, current_hp, version): events.append([actor_id, amount, previous_hp, current_hp, version]))
    _check(health.apply_damage("actor.damage_signal", 7), "real damage applies")
    _check(events.size() == 1 and int(events[0][1]) == 7, "damage signal emits actual HP loss")
    _check(health.heal("actor.damage_signal", 3), "healing succeeds")
    _check(health.set_max_hp("actor.damage_signal", 90), "max HP bookkeeping succeeds")
    _check(events.size() == 1, "healing/max-HP changes do not masquerade as damage")

func _test_input_contract() -> void:
    var shifted := InputEventKey.new()
    shifted.keycode = KEY_W
    shifted.shift_pressed = true
    _check(KeyboardClass._intent_for_key(shifted) == Intents.RUN_FORWARD, "Shift+W emits semantic Run intent")
    var plain := InputEventKey.new()
    plain.keycode = KEY_W
    _check(KeyboardClass._intent_for_key(plain) == Intents.FORWARD, "plain W remains Walk")

    var controls := ControlsClass.new()
    controls.set_enabled(true)
    var found_run: bool = false
    for child: Node in controls.get_children():
        var button := child as Button
        if button != null and button.text == "RUN":
            found_run = true
            break
    _check(found_run, "touch controls expose native RUN button")
    controls.free()

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
