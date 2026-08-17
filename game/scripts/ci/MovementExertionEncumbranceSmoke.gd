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
const ExertionClass = preload("res://scripts/simulation/movement/MovementExertionService.gd")
const ImpactDamageClass = preload("res://scripts/simulation/movement/MovementRunImpactDamageService.gd")
const LocomotionStateClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionState.gd")
const LocomotionMutationClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionMutationService.gd")
const CapabilityClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementCapabilityService.gd")
const ActorPolicyClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementTraversalPolicy.gd")
const HealthClass = preload("res://scripts/simulation/actors/health/ActorHealthState.gd")
const NeedsClass = preload("res://scripts/simulation/actors/needs/ActorNeedsState.gd")
const NeedsProviderClass = preload("res://scripts/simulation/actors/needs/ActorNeedsMobilityModifierProvider.gd")
const HandStateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const HandMutationClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd")
const InventoryStateClass = preload("res://scripts/simulation/inventory/InventoryContainmentState.gd")
const InventoryMutationClass = preload("res://scripts/simulation/inventory/InventoryContainmentMutationService.gd")
const PhysicalCatalogClass = preload("res://scripts/simulation/items/properties/ItemPhysicalPropertyCatalog.gd")
const WeightQueryClass = preload("res://scripts/simulation/items/properties/ItemWeightQuery.gd")
const CarryStateClass = preload("res://scripts/simulation/actors/carry/ActorCarryState.gd")
const CarryQueryClass = preload("res://scripts/simulation/actors/carry/ActorCarryQuery.gd")
const CarryProviderClass = preload("res://scripts/simulation/actors/carry/ActorCarryMobilityModifierProvider.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _test_baselines_and_multiplication()
    _test_encumbrance_run_gate_and_overweight_walk()
    _test_walk_fatigue_is_terrain_only()
    _test_run_fatigue_uses_terrain_and_load()
    _test_first_stride_impact()
    _test_second_stride_impact()
    _test_unknown_is_not_impact()
    _test_damage_canceled_walk_has_no_exertion_commit()
    if failures.is_empty():
        print("MOVEMENT_EXERTION_ENCUMBRANCE_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("MOVEMENT_EXERTION_ENCUMBRANCE_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture(actor_id: String, load_grams: int = 0, capacity_grams: int = 10000) -> Dictionary:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var catalog := CatalogClass.new()
    var overrides := OverridesClass.new()
    var query := QueryClass.new(world, catalog, overrides)
    var kernel := TickKernelClass.new()
    var base_policy := BasePolicyClass.new(3)
    _check(catalog.register(&"actor.survivor", true), "register survivor collision")
    _check(catalog.register(&"structure.wall", true), "register wall collision")
    _check(base_policy.register_terrain(&"ground.test", true, 10), "register normal terrain")
    _check(base_policy.register_terrain(&"ground.slow", true, 14), "register slow terrain")
    _check(base_policy.register_terrain(&"ground.rough", true, 20), "register rough terrain")
    _check(base_policy.register_terrain(&"ground.water", false), "register blocked terrain")
    for y: int in range(0, 10):
        for x: int in range(0, 20):
            _check(mutations.set_terrain(Vector2i(x, y), &"ground.test"), "fill terrain")

    _check(mutations.create_entity(&"actor.survivor", actor_id) == actor_id, "create actor")
    _check(mutations.set_placement(actor_id, Layers.Channel.ACTOR, Vector2i(2, 2), Facing.Value.EAST, Footprint.single_cell()), "place actor")

    var locomotion := LocomotionStateClass.new()
    var locomotion_mutations := LocomotionMutationClass.new(locomotion)
    _check(locomotion_mutations.enroll(actor_id), "enroll locomotion")
    var health := HealthClass.new(world)
    _check(health.enroll_actor(actor_id), "enroll health")
    var needs := NeedsClass.new(world)
    _check(needs.enroll_actor(actor_id), "enroll needs")

    var hands := HandStateClass.new()
    var hand_mutations := HandMutationClass.new(hands, world)
    _check(hand_mutations.enroll_actor(actor_id), "enroll hands")
    var inventory := InventoryStateClass.new()
    var inventory_mutations := InventoryMutationClass.new(inventory, world)
    _check(inventory_mutations.enroll_container(actor_id), "enroll inventory root")
    var physical_catalog := PhysicalCatalogClass.new()
    var weight_query := WeightQueryClass.new(world, physical_catalog)
    var carry_state := CarryStateClass.new(world)
    _check(carry_state.enroll_actor(actor_id), "enroll carry")
    _check(carry_state.set_capacity_grams(actor_id, capacity_grams), "set carry capacity")
    if load_grams > 0:
        var item_id: String = "%s.load" % actor_id
        _check(mutations.create_entity(&"item.test_load", item_id) == item_id, "create load item")
        _check(physical_catalog.register_profile(&"item.test_load", load_grams), "register load weight")
        _check(inventory_mutations.set_container(item_id, actor_id), "contain load item")
    var carry_query := CarryQueryClass.new(world, hands, inventory, weight_query, carry_state)

    var capability := CapabilityClass.new(locomotion)
    _check(capability.register_provider(NeedsProviderClass.new(needs)), "register needs provider")
    _check(capability.register_provider(CarryProviderClass.new(carry_query)), "register carry provider")
    var actor_policy := ActorPolicyClass.new(base_policy, capability)
    var movement := MovementClass.new(world, mutations, query, kernel, actor_policy)
    var damage_interrupt := DamageInterruptClass.new(health, kernel)
    var exertion := ExertionClass.new(movement, needs, carry_query)
    var impact_damage := ImpactDamageClass.new(movement, health)
    _check(movement.is_ready(), "movement ready")
    _check(damage_interrupt.is_ready(), "damage interrupt ready")
    _check(exertion.is_ready(), "exertion ready")
    _check(impact_damage.is_ready(), "impact damage ready")

    return {
        "actor_id": actor_id,
        "world": world,
        "mutations": mutations,
        "kernel": kernel,
        "base_policy": base_policy,
        "movement": movement,
        "health": health,
        "needs": needs,
        "carry_state": carry_state,
        "carry_query": carry_query,
        "locomotion_mutations": locomotion_mutations,
    }

func _test_baselines_and_multiplication() -> void:
    var walk_f := _fixture("actor.base_walk")
    var walk: MovementActionResult = walk_f["movement"].request_step_forward("actor.base_walk")
    _check(walk.is_accepted() and walk.duration_ticks == 10, "fresh empty normal walk stays ten ticks")

    var run_f := _fixture("actor.base_run")
    var run: MovementActionResult = run_f["movement"].request_run_forward("actor.base_run")
    _check(run.is_accepted() and run.duration_ticks == 12, "fresh empty normal run stays twelve ticks")

    var mult_f := _fixture("actor.mult", 5000, 10000)
    var mutations: WorldMutationService = mult_f["mutations"]
    var needs: ActorNeedsState = mult_f["needs"]
    _check(needs.set_need("actor.mult", NeedsClass.FATIGUE, 20), "set multiplier fatigue")
    _check(mutations.set_terrain(Vector2i(3, 2), &"ground.slow"), "set slow walk terrain")
    var multiplied_walk: MovementActionResult = mult_f["movement"].request_step_forward("actor.mult")
    _check(multiplied_walk.is_accepted() and multiplied_walk.duration_ticks == 22, "14 terrain x 1.13 fatigue x 1.375 carry rounds once to 22")

    var run_mult_f := _fixture("actor.run_mult", 5000, 10000)
    var run_mutations: WorldMutationService = run_mult_f["mutations"]
    var run_needs: ActorNeedsState = run_mult_f["needs"]
    _check(run_needs.set_need("actor.run_mult", NeedsClass.FATIGUE, 20), "set run multiplier fatigue")
    _check(run_mutations.set_terrain(Vector2i(3, 2), &"ground.slow"), "set run slow stride one")
    _check(run_mutations.set_terrain(Vector2i(4, 2), &"ground.slow"), "set run slow stride two")
    var multiplied_run: MovementActionResult = run_mult_f["movement"].request_run_forward("actor.run_mult")
    _check(multiplied_run.is_accepted() and multiplied_run.duration_ticks == 28, "run stride timing multiplies terrain fatigue and carry")

func _test_encumbrance_run_gate_and_overweight_walk() -> void:
    var full_f := _fixture("actor.full", 10000, 10000)
    var blocked: MovementActionResult = full_f["movement"].request_run_forward("actor.full")
    _check(blocked.status == MovementResult.Status.CAPABILITY_BLOCKED and blocked.reason == "too_encumbered_to_run", "100 percent carry blocks Run")

    var over_f := _fixture("actor.over", 12000, 10000)
    var walk: MovementActionResult = over_f["movement"].request_step_forward("actor.over")
    _check(walk.is_accepted() and walk.duration_ticks == 19, "over-capacity Walk remains legal and slower")

func _test_walk_fatigue_is_terrain_only() -> void:
    var light_f := _fixture("actor.walk_light", 5000, 10000)
    var light_mutations: WorldMutationService = light_f["mutations"]
    _check(light_mutations.set_terrain(Vector2i(3, 2), &"ground.slow"), "light walk slow terrain")
    var light_walk: MovementActionResult = light_f["movement"].request_step_forward("actor.walk_light")
    _check(light_walk.is_accepted(), "light slow walk accepted")
    _check(light_f["kernel"].run_until_stop() == TickRules.RunStopReason.IDLE, "light walk drains")
    _check(light_f["needs"].fatigue("actor.walk_light") == 2, "14-tick terrain adds two walk fatigue")

    var heavy_f := _fixture("actor.walk_heavy", 9000, 10000)
    var heavy_mutations: WorldMutationService = heavy_f["mutations"]
    _check(heavy_mutations.set_terrain(Vector2i(3, 2), &"ground.slow"), "heavy walk slow terrain")
    var heavy_walk: MovementActionResult = heavy_f["movement"].request_step_forward("actor.walk_heavy")
    _check(heavy_walk.is_accepted(), "heavy slow walk accepted")
    _check(heavy_f["kernel"].run_until_stop() == TickRules.RunStopReason.IDLE, "heavy walk drains")
    _check(heavy_f["needs"].fatigue("actor.walk_heavy") == 2, "walk fatigue ignores carry load")

func _test_run_fatigue_uses_terrain_and_load() -> void:
    var baseline_f := _fixture("actor.run_effort_base")
    var baseline_run: MovementActionResult = baseline_f["movement"].request_run_forward("actor.run_effort_base")
    _check(baseline_run.is_accepted(), "baseline exertion run accepted")
    baseline_f["kernel"].run_until_stop()
    _check(baseline_f["needs"].fatigue("actor.run_effort_base") == 2, "empty normal run costs one fatigue per stride")

    var loaded_f := _fixture("actor.run_effort_load", 7500, 10000)
    var loaded_run: MovementActionResult = loaded_f["movement"].request_run_forward("actor.run_effort_load")
    _check(loaded_run.is_accepted(), "loaded run accepted below max carry")
    loaded_f["kernel"].run_until_stop()
    _check(loaded_f["needs"].fatigue("actor.run_effort_load") == 4, "75 percent load raises normal run fatigue to two per stride")

    var rough_f := _fixture("actor.run_effort_rough", 5000, 10000)
    var rough_mutations: WorldMutationService = rough_f["mutations"]
    rough_mutations.set_terrain(Vector2i(3, 2), &"ground.rough")
    rough_mutations.set_terrain(Vector2i(4, 2), &"ground.rough")
    var rough_run: MovementActionResult = rough_f["movement"].request_run_forward("actor.run_effort_rough")
    _check(rough_run.is_accepted(), "rough loaded run accepted")
    rough_f["kernel"].run_until_stop()
    _check(rough_f["needs"].fatigue("actor.run_effort_rough") == 6, "rough terrain and 50 percent load multiply run fatigue to three per stride")

func _test_first_stride_impact() -> void:
    var f := _fixture("actor.impact_first")
    _place_wall(f, "wall.first", Vector2i(3, 2))
    var run: MovementActionResult = f["movement"].request_run_forward("actor.impact_first")
    _check(run.is_accepted(), "known first-stride blocker is a committed impact candidate")
    _check(f["kernel"].run_until_stop() == TickRules.RunStopReason.IDLE, "first-stride impact resolves")
    _check(f["kernel"].world_tick() == 6, "first-stride impact spends first stride time only")
    _check(f["world"].placement("actor.impact_first").anchor == Vector2i(2, 2), "first impact does not enter blocker")
    _check(f["health"].current_hp("actor.impact_first") == 95, "first impact causes five HP damage")
    _check(f["needs"].fatigue("actor.impact_first") == 1, "impact stride still costs run fatigue")

func _test_second_stride_impact() -> void:
    var f := _fixture("actor.impact_second")
    _place_wall(f, "wall.second", Vector2i(4, 2))
    var run: MovementActionResult = f["movement"].request_run_forward("actor.impact_second")
    _check(run.is_accepted(), "known second-stride blocker is a committed impact candidate")
    _check(f["kernel"].run_until_stop() == TickRules.RunStopReason.IDLE, "second-stride impact resolves")
    _check(f["kernel"].world_tick() == 12, "second impact resolves at second stride tick")
    _check(f["world"].placement("actor.impact_second").anchor == Vector2i(3, 2), "valid first stride remains after second impact")
    _check(f["health"].current_hp("actor.impact_second") == 95, "second impact causes five HP damage")
    _check(f["needs"].fatigue("actor.impact_second") == 2, "successful plus impact stride both cost fatigue")

func _test_unknown_is_not_impact() -> void:
    var f := _fixture("actor.unknown")
    _check(f["mutations"].clear_terrain(Vector2i(3, 2)), "clear target terrain")
    var run: MovementActionResult = f["movement"].request_run_forward("actor.unknown")
    _check(run.status == MovementResult.Status.TARGET_UNKNOWN, "unknown Run target fails closed")
    _check(f["kernel"].world_tick() == 0, "unknown target spends zero ticks")
    _check(f["health"].current_hp("actor.unknown") == 100, "unknown target causes no fake impact damage")
    _check(f["needs"].fatigue("actor.unknown") == 0, "unknown target causes no exertion")

func _test_damage_canceled_walk_has_no_exertion_commit() -> void:
    var f := _fixture("actor.walk_damage")
    var health: ActorHealthState = f["health"]
    f["kernel"].external_event_due.connect(
        func(event):
            if event.event_type == &"test.damage_walk":
                health.apply_damage("actor.walk_damage", 5)
    )
    var walk: MovementActionResult = f["movement"].request_step_forward("actor.walk_damage")
    _check(walk.is_accepted(), "damage-cancel walk accepted")
    _check(f["kernel"].schedule_event(5, "17a_smoke", &"test.damage_walk") > 0, "walk damage scheduled")
    _check(f["kernel"].run_until_stop() == TickRules.RunStopReason.IDLE, "damage-cancel walk resolves")
    _check(f["kernel"].world_tick() == 5, "canceled walk retains spent time")
    _check(f["world"].placement("actor.walk_damage").anchor == Vector2i(2, 2), "canceled walk stays at origin")
    _check(f["needs"].fatigue("actor.walk_damage") == 0, "uncommitted walk adds no movement fatigue")

func _place_wall(f: Dictionary, wall_id: String, cell: Vector2i) -> void:
    var mutations: WorldMutationService = f["mutations"]
    _check(mutations.create_entity(&"structure.wall", wall_id) == wall_id, "create %s" % wall_id)
    _check(mutations.set_placement(wall_id, Layers.Channel.STRUCTURE, cell, Facing.Value.NORTH, Footprint.single_cell()), "place %s" % wall_id)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
