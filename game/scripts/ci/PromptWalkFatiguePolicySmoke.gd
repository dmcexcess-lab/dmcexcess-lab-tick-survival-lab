extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const CollisionCatalogClass = preload("res://scripts/simulation/collision/CollisionCatalog.gd")
const CollisionOverridesClass = preload("res://scripts/simulation/collision/CollisionOverrideState.gd")
const SpatialQueryClass = preload("res://scripts/simulation/collision/SpatialQueryService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const BaseTraversalClass = preload("res://scripts/simulation/movement/MovementTraversalPolicy.gd")
const MovementClass = preload("res://scripts/simulation/movement/MovementActionService.gd")
const LocomotionStateClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionState.gd")
const LocomotionMutationClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionMutationService.gd")
const MovementCapabilityClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementCapabilityService.gd")
const ActorTraversalClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementTraversalPolicy.gd")
const HealthClass = preload("res://scripts/simulation/actors/health/ActorHealthState.gd")
const TimeProfileClass = preload("res://scripts/simulation/world_time/WorldTimeProfile.gd")
const ConditionStateClass = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const ConditionModifierClass = preload("res://scripts/simulation/actors/condition/ActorConditionModifierQuery.gd")
const ConditionServiceClass = preload("res://scripts/simulation/actors/condition/ActorConditionService.gd")
const ConditionExertionClass = preload("res://scripts/simulation/actors/condition/MovementConditionExertionService.gd")
const HandStateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const HandMutationClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd")
const InventoryStateClass = preload("res://scripts/simulation/inventory/InventoryContainmentState.gd")
const InventoryMutationClass = preload("res://scripts/simulation/inventory/InventoryContainmentMutationService.gd")
const PhysicalCatalogClass = preload("res://scripts/simulation/items/properties/ItemPhysicalPropertyCatalog.gd")
const WeightQueryClass = preload("res://scripts/simulation/items/properties/ItemWeightQuery.gd")
const CarryStateClass = preload("res://scripts/simulation/actors/carry/ActorCarryState.gd")
const CarryQueryClass = preload("res://scripts/simulation/actors/carry/ActorCarryQuery.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _test_healthy_walk_is_free_and_harmless()
    _test_mild_and_single_severe_pressure_stay_free()
    _test_multiple_severe_pressures_make_walk_exertion()
    _test_overburden_requires_another_severe_pressure()
    _test_run_still_costs_fatigue()
    if failures.is_empty():
        print("PROMPT_WALK_FATIGUE_POLICY_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PROMPT_WALK_FATIGUE_POLICY_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture(actor_id: String, load_grams: int = 0) -> Dictionary:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var collision_catalog := CollisionCatalogClass.new()
    var collision_overrides := CollisionOverridesClass.new()
    var spatial_query := SpatialQueryClass.new(world, collision_catalog, collision_overrides)
    var kernel := TickKernelClass.new()
    var base_traversal := BaseTraversalClass.new(3)

    _check(collision_catalog.register(&"actor.survivor", true), "%s collision profile" % actor_id)
    _check(base_traversal.register_terrain(&"ground.test", true, 10), "%s terrain profile" % actor_id)
    for y: int in range(0, 8):
        for x: int in range(0, 30):
            _check(mutations.set_terrain(Vector2i(x, y), &"ground.test"), "%s terrain fill" % actor_id)

    _check(mutations.create_entity(&"actor.survivor", actor_id) == actor_id, "%s actor created" % actor_id)
    _check(
        mutations.set_placement(actor_id, Layers.Channel.ACTOR, Vector2i(2, 2), Facing.Value.EAST, Footprint.single_cell()),
        "%s actor placed" % actor_id
    )

    var locomotion := LocomotionStateClass.new()
    var locomotion_mutations := LocomotionMutationClass.new(locomotion)
    _check(locomotion_mutations.enroll(actor_id), "%s locomotion enrolled" % actor_id)
    var capability := MovementCapabilityClass.new(locomotion)
    var actor_traversal := ActorTraversalClass.new(base_traversal, capability)
    var movement := MovementClass.new(world, mutations, spatial_query, kernel, actor_traversal)
    _check(movement.is_ready(), "%s movement ready" % actor_id)

    var health := HealthClass.new(world)
    _check(health.enroll_actor(actor_id), "%s health enrolled" % actor_id)
    var time_profile := TimeProfileClass.new()
    var condition_state := ConditionStateClass.new(world)
    _check(condition_state.enroll_actor(actor_id, kernel.world_tick()), "%s condition enrolled" % actor_id)
    var modifiers := ConditionModifierClass.new(condition_state, time_profile, kernel)
    var condition := ConditionServiceClass.new(condition_state, health, kernel, time_profile, modifiers)
    _check(condition.is_ready(), "%s condition ready" % actor_id)

    var hands := HandStateClass.new()
    var hand_mutations := HandMutationClass.new(hands, world)
    _check(hand_mutations.enroll_actor(actor_id), "%s hands enrolled" % actor_id)
    var inventory := InventoryStateClass.new()
    var inventory_mutations := InventoryMutationClass.new(inventory, world)
    _check(inventory_mutations.enroll_container(actor_id), "%s inventory enrolled" % actor_id)
    var physical_catalog := PhysicalCatalogClass.new()
    var weight_query := WeightQueryClass.new(world, physical_catalog)
    var carry_state := CarryStateClass.new(world)
    _check(carry_state.enroll_actor(actor_id), "%s carry enrolled" % actor_id)
    _check(carry_state.set_capacity_grams(actor_id, 10000), "%s carry capacity" % actor_id)
    if load_grams > 0:
        var item_id: String = "%s.load" % actor_id
        _check(mutations.create_entity(&"item.test_load", item_id) == item_id, "%s load item created" % actor_id)
        _check(physical_catalog.register_profile(&"item.test_load", load_grams), "%s load profile" % actor_id)
        _check(inventory_mutations.set_container(item_id, actor_id), "%s load contained" % actor_id)
    var carry_query := CarryQueryClass.new(world, hands, inventory, weight_query, carry_state)
    _check(carry_query.configure_capacity_modifier(modifiers), "%s condition carry modifier" % actor_id)

    var exertion := ConditionExertionClass.new(movement, condition, carry_query)
    _check(exertion.is_ready(), "%s exertion ready" % actor_id)

    return {
        "actor_id": actor_id,
        "world": world,
        "kernel": kernel,
        "movement": movement,
        "health": health,
        "condition": condition,
        "carry_query": carry_query,
        "exertion": exertion,
    }

func _walk_once(fixture: Dictionary) -> bool:
    var actor_id: String = String(fixture["actor_id"])
    var result = fixture["movement"].request_step_forward(actor_id)
    if not result.is_accepted():
        failures.append("%s walk accepted" % actor_id)
        return false
    fixture["kernel"].run_until_stop()
    return true

func _run_once(fixture: Dictionary) -> bool:
    var actor_id: String = String(fixture["actor_id"])
    var result = fixture["movement"].request_run_forward(actor_id)
    if not result.is_accepted():
        failures.append("%s run accepted" % actor_id)
        return false
    fixture["kernel"].run_until_stop()
    return true

func _test_healthy_walk_is_free_and_harmless() -> void:
    var f := _fixture("actor.walk.healthy")
    var hp_before: int = f["health"].current_hp("actor.walk.healthy")
    var max_before: int = f["health"].max_hp("actor.walk.healthy")
    _check(_walk_once(f), "healthy first walk completed")
    _check(_walk_once(f), "healthy second walk completed")
    _check(f["condition"].current_fatigue("actor.walk.healthy") == 0, "healthy repeated Walk adds zero fatigue")
    _check(f["health"].current_hp("actor.walk.healthy") == hp_before, "healthy Walk does not damage health")
    _check(f["health"].max_hp("actor.walk.healthy") == max_before, "healthy Walk does not alter max health")

func _test_mild_and_single_severe_pressure_stay_free() -> void:
    var mild := _fixture("actor.walk.mild")
    _check(mild["condition"].set_condition("actor.walk.mild", ConditionStateClass.HYDRATION, 29), "orange hydration set")
    _check(_walk_once(mild), "orange-pressure walk completed")
    _check(mild["condition"].current_fatigue("actor.walk.mild") == 0, "orange pressure alone does not make Walk tiring")

    var single_red := _fixture("actor.walk.one_red")
    _check(single_red["condition"].set_condition("actor.walk.one_red", ConditionStateClass.HYDRATION, 10), "single red hydration set")
    var hp_before: int = single_red["health"].current_hp("actor.walk.one_red")
    _check(_walk_once(single_red), "single-red walk completed")
    _check(single_red["condition"].current_fatigue("actor.walk.one_red") == 0, "one red physical pressure still leaves Walk fatigue-free")
    _check(single_red["health"].current_hp("actor.walk.one_red") == hp_before, "single-red Walk itself adds no health harm")

func _test_multiple_severe_pressures_make_walk_exertion() -> void:
    var f := _fixture("actor.walk.two_red")
    _check(f["condition"].set_condition("actor.walk.two_red", ConditionStateClass.HYDRATION, 10), "red hydration set")
    _check(f["condition"].set_condition("actor.walk.two_red", ConditionStateClass.REST, 10), "red rest set")
    var before: int = f["condition"].current_fatigue("actor.walk.two_red")
    _check(_walk_once(f), "two-red walk completed")
    _check(f["condition"].current_fatigue("actor.walk.two_red") > before, "two severe physical pressures make Walk exertion")

func _test_overburden_requires_another_severe_pressure() -> void:
    var over := _fixture("actor.walk.over", 12000)
    _check(int(over["carry_query"].query("actor.walk.over").get("load_ratio_bp", 0)) > 10000, "overburden fixture exceeds carry capacity")
    _check(_walk_once(over), "overburden-only walk completed")
    _check(over["condition"].current_fatigue("actor.walk.over") == 0, "overburden alone is not enough to tax ordinary Walk")

    var combined := _fixture("actor.walk.over_red", 12000)
    _check(combined["condition"].set_condition("actor.walk.over_red", ConditionStateClass.HYDRATION, 10), "combined red hydration set")
    var before: int = combined["condition"].current_fatigue("actor.walk.over_red")
    _check(_walk_once(combined), "overburden-plus-red walk completed")
    _check(combined["condition"].current_fatigue("actor.walk.over_red") > before, "overburden plus another severe pressure makes Walk exertion")

func _test_run_still_costs_fatigue() -> void:
    var f := _fixture("actor.run.healthy")
    _check(_run_once(f), "healthy Run completed")
    _check(f["condition"].current_fatigue("actor.run.healthy") > 0, "healthy Run still costs fatigue")

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)