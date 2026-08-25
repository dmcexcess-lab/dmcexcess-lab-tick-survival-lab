extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const BuildingPlanClass = preload("res://scripts/generation/buildings/GeneratedBuildingPlan.gd")
const TimeProfileClass = preload("res://scripts/simulation/world_time/WorldTimeProfile.gd")
const HandStateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const HandMutationClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd")
const InventoryStateClass = preload("res://scripts/simulation/inventory/InventoryContainmentState.gd")
const InventoryMutationClass = preload("res://scripts/simulation/inventory/InventoryContainmentMutationService.gd")
const PhysicalCatalogClass = preload("res://scripts/simulation/items/properties/ItemPhysicalPropertyCatalog.gd")
const WeightQueryClass = preload("res://scripts/simulation/items/properties/ItemWeightQuery.gd")
const CarryStateClass = preload("res://scripts/simulation/actors/carry/ActorCarryState.gd")
const CarryQueryClass = preload("res://scripts/simulation/actors/carry/ActorCarryQuery.gd")
const LootItemsClass = preload("res://scripts/simulation/loot/LootItemCatalog.gd")
const LootStateClass = preload("res://scripts/simulation/loot/LootState.gd")
const LootInitializerClass = preload("res://scripts/simulation/loot/LootSourceInitializer.gd")
const LootInspectionClass = preload("res://scripts/simulation/loot/LootContainerInspectionQuery.gd")
const InventoryInspectorClass = preload("res://scripts/ui/ActorInventoryInspectorQuery.gd")
const FailingContainmentClass = preload("res://scripts/ci/LootFailingContainmentMutations.gd")
const FreshLootProfilesClass = preload("res://scripts/ci/ItemFreshnessTestLootProfileCatalog.gd")
const FreshProfileClass = preload("res://scripts/simulation/items/freshness/ItemFreshnessProfile.gd")
const FreshCatalogClass = preload("res://scripts/simulation/items/freshness/ItemFreshnessProfileCatalog.gd")
const FreshStateClass = preload("res://scripts/simulation/items/freshness/ItemFreshnessState.gd")
const AmbientClass = preload("res://scripts/simulation/items/freshness/AmbientSpoilageEnvironmentProvider.gd")
const FreshMutationClass = preload("res://scripts/simulation/items/freshness/ItemFreshnessMutationService.gd")
const FreshQueryClass = preload("res://scripts/simulation/items/freshness/ItemFreshnessQuery.gd")

const ACTOR_ID: String = "actor.freshness.test"
const CONTAINER_ROLE: String = "prop.sales.shelf_1"

var failures: Array[String] = []

func _initialize() -> void:
    _test_freshness_contract()
    _test_system24_transaction_and_inspection()
    _test_system24_freshness_rollback()
    if failures.is_empty():
        print("ITEM_FRESHNESS_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("ITEM_FRESHNESS_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_freshness_contract() -> void:
    var world := WorldStateClass.new()
    var wm := WorldMutationClass.new(world)
    var kernel := TickKernelClass.new()
    var time_profile := TimeProfileClass.new()
    var catalog := FreshCatalogClass.new(time_profile)
    var state := FreshStateClass.new()
    var ambient := AmbientClass.new()
    var providers: Array[SpoilageEnvironmentProvider] = [ambient]
    var mutations := FreshMutationClass.new(world, state, catalog, providers)
    var query := FreshQueryClass.new(world, state, catalog, kernel, providers)

    _check(time_profile.is_valid(), "world time profile valid")
    _check(catalog.semantic_types().size() == 6, "six Candidate 001 perishables registered")
    _check(catalog.has_profile(&"item.food.apple"), "apple classified perishable")
    _check(not catalog.has_profile(&"item.food.canned_beans"), "canned beans stay shelf stable")
    _check(ambient.exposure_ticks_at(12345) == 12345, "ambient cumulative exposure is authoritative tick")
    _check(mutations.is_ready() and query.is_ready(), "freshness services ready")

    _check(wm.create_entity(&"item.food.apple", "item.apple.a") == "item.apple.a", "apple created")
    _check(wm.create_entity(&"item.food.milk_carton", "item.milk.a") == "item.milk.a", "milk created")
    _check(wm.create_entity(&"item.food.canned_beans", "item.can.a") == "item.can.a", "can created")
    _check(mutations.enroll_virgin_item("item.apple.a", 0), "apple virgin freshness enrolled")
    _check(mutations.enroll_virgin_item("item.milk.a", 0), "milk virgin freshness enrolled")
    _check(not mutations.enroll_virgin_item("item.can.a", 0), "shelf-stable item does not get freshness record")
    _check(state.item_ids() == ["item.apple.a", "item.milk.a"], "freshness state is sparse and sorted")
    _check(mutations.has_record("item.apple.a"), "mutation transaction seam sees enrolled record")

    var apple_profile: ItemFreshnessProfile = catalog.profile(&"item.food.apple")
    var apple_zero: Dictionary = query.query_at_tick("item.apple.a", 0)
    var apple_late: Dictionary = query.query_at_tick("item.apple.a", apple_profile.ambient_lifetime_ticks)
    _check(int(apple_zero.get("status", -1)) == FreshQueryClass.Status.KNOWN, "perishable query known")
    _check(int(apple_zero.get("age_permille", -1)) >= 0 and int(apple_zero.get("age_permille", -1)) <= 200, "deterministic virgin age bounded to 20 percent")
    _check(StringName(apple_late.get("stage", &"")) == FreshQueryClass.SPOILED, "one ambient lifetime guarantees spoiled")
    _check(int(query.query_at_tick("item.can.a", 999999).get("status", -1)) == FreshQueryClass.Status.SHELF_STABLE, "shelf stable query requires no record")

    var state_revision_before_time: int = state.revision()
    query.query_at_tick("item.apple.a", apple_profile.ambient_lifetime_ticks * 20)
    _check(state.revision() == state_revision_before_time, "time passage/query performs zero freshness mutation")

    var late_world := WorldStateClass.new()
    var late_wm := WorldMutationClass.new(late_world)
    var late_state := FreshStateClass.new()
    var late_mutations := FreshMutationClass.new(late_world, late_state, catalog, providers)
    var late_query := FreshQueryClass.new(late_world, late_state, catalog, kernel, providers)
    _check(late_wm.create_entity(&"item.food.milk_carton", "item.milk.day5") == "item.milk.day5", "late materialized milk created")
    _check(late_mutations.enroll_virgin_item("item.milk.day5", 0), "late materialized virgin item anchors to logical tick zero")
    var day_five_tick: int = time_profile.ticks_per_day() * 5
    _check(StringName(late_query.query_at_tick("item.milk.day5", day_five_tick).get("stage", &"")) == FreshQueryClass.SPOILED, "day-five first materialization does not create fresh milk")

    var snapshot: Dictionary = state.snapshot()
    var restored := FreshStateClass.new()
    _check(restored.load_snapshot(snapshot), "freshness snapshot restores")
    _check(restored.snapshot() == snapshot, "freshness snapshot round-trips deterministically")
    var mutation_snapshot: Dictionary = mutations.snapshot_state()
    _check(mutations.restore_state(mutation_snapshot), "mutation owner exposes transactional snapshot restore seam")
    var bad: Dictionary = snapshot.duplicate(true)
    bad["schema_version"] = 999
    _check(not restored.load_snapshot(bad), "wrong snapshot schema rejected")

    _check(String(FreshQueryClass._stage(599)) == "FRESH", "fresh threshold below 60 percent")
    _check(String(FreshQueryClass._stage(600)) == "AGING", "aging starts at 60 percent")
    _check(String(FreshQueryClass._stage(850)) == "STALE", "stale starts at 85 percent")
    _check(String(FreshQueryClass._stage(1000)) == "SPOILED", "spoiled starts at 100 percent")

func _test_system24_transaction_and_inspection() -> void:
    var fx: Dictionary = _loot_fixture(false)
    var plan: GeneratedBuildingPlan = _freshness_plan("building.freshness.integration", Vector2i(6, 5))
    _materialize_container(fx, plan)
    var initializer: LootSourceInitializer = fx["initializer"]
    var result: Dictionary = initializer.initialize_source("source.freshness.integration", &"ci", "freshness", [plan])
    _check(bool(result.get("ok", false)), "System 24 initializes deterministic perishable source")
    var item_ids: Array = result.get("item_ids", [])
    _check(item_ids.size() == 1, "System 24 deterministic freshness profile creates one item")
    if item_ids.size() != 1:
        return
    var item_id: String = String(item_ids[0])
    var freshness_state: ItemFreshnessState = fx["freshness_state"]
    var world: WorldState = fx["world"]
    _check(world.entity(item_id).semantic_type == &"item.food.apple", "System 24 created expected perishable semantic")
    _check(freshness_state.has_item(item_id), "System 24 transaction enrolls perishable freshness")
    _check(freshness_state.item_ids().size() == 1, "only perishable item consumes freshness state")

    var freshness_query: ItemFreshnessQuery = fx["freshness_query"]
    var day_six: int = (fx["time_profile"] as WorldTimeProfile).ticks_per_day() * 6
    _check(StringName(freshness_query.query_at_tick(item_id, day_six).get("stage", &"")) == FreshQueryClass.SPOILED, "System 24 virgin item keeps logical origin tick zero")

    var container_id: String = plan.entity_id_for_role(CONTAINER_ROLE)
    var loot_inspection := LootInspectionClass.new(
        world,
        fx["containment"],
        fx["loot_state"],
        fx["items"],
        fx["profiles"],
        fx["weight_query"],
        fx["carry_query"],
        freshness_query
    )
    var container_view: Dictionary = loot_inspection.query(ACTOR_ID, container_id)
    _check(bool(container_view.get("ok", false)), "container inspection with freshness is ready")
    var container_items: Array = container_view.get("items", [])
    _check(container_items.size() == 1, "container inspection returns initialized apple")
    if container_items.size() == 1:
        var entry: Dictionary = container_items[0]
        _check(bool(entry.get("freshness_known", false)), "container inspection exposes coarse freshness")
        _check(String(entry.get("label", "")).contains(" — "), "container label includes freshness suffix")

    _check(fx["containment_mutations"].set_container(item_id, ACTOR_ID), "move perishable into actor inventory without changing freshness ownership")
    var inventory_inspection := InventoryInspectorClass.new(
        world,
        fx["hands"],
        fx["containment"],
        fx["weight_query"],
        fx["carry_query"],
        freshness_query
    )
    var inventory_view: Dictionary = inventory_inspection.query(ACTOR_ID)
    _check(bool(inventory_view.get("ok", false)), "inventory inspection with freshness is ready")
    var inventory_items: Array = inventory_view.get("inventory", [])
    _check(inventory_items.size() == 1, "inventory inspection returns moved apple")
    if inventory_items.size() == 1:
        var inventory_entry: Dictionary = inventory_items[0]
        _check(bool(inventory_entry.get("freshness_known", false)), "inventory inspection exposes coarse freshness")
        _check(String(inventory_entry.get("label", "")).contains(" — "), "inventory label includes freshness suffix")

func _test_system24_freshness_rollback() -> void:
    var fx: Dictionary = _loot_fixture(true)
    var plan: GeneratedBuildingPlan = _freshness_plan("building.freshness.rollback", Vector2i(6, 5))
    _materialize_container(fx, plan)
    var world: WorldState = fx["world"]
    var containment: InventoryContainmentState = fx["containment"]
    var loot_state: LootState = fx["loot_state"]
    var freshness_state: ItemFreshnessState = fx["freshness_state"]
    var world_before: String = JSON.stringify(world.snapshot())
    var containment_before: String = JSON.stringify(containment.snapshot())
    var loot_before: String = JSON.stringify(loot_state.snapshot())
    var freshness_before: String = JSON.stringify(freshness_state.snapshot())

    var result: Dictionary = fx["initializer"].initialize_source("source.freshness.rollback", &"ci", "rollback", [plan])
    _check(not bool(result.get("ok", true)), "injected containment failure aborts System 24 perishable transaction")
    _check(JSON.stringify(world.snapshot()) == world_before, "System 24 rollback restores WHAT after freshness enrollment")
    _check(JSON.stringify(containment.snapshot()) == containment_before, "System 24 rollback restores containment after freshness enrollment")
    _check(JSON.stringify(loot_state.snapshot()) == loot_before, "System 24 rollback restores loot provenance after freshness enrollment")
    _check(JSON.stringify(freshness_state.snapshot()) == freshness_before, "System 24 rollback restores System 30 with no orphan record")

func _loot_fixture(fail_containment: bool) -> Dictionary:
    var world := WorldStateClass.new()
    var wm := WorldMutationClass.new(world)
    var hands := HandStateClass.new()
    var hand_mutations := HandMutationClass.new(hands, world)
    var containment := InventoryStateClass.new()
    var containment_mutations: InventoryContainmentMutationService
    if fail_containment:
        containment_mutations = FailingContainmentClass.new(containment, world, 1)
    else:
        containment_mutations = InventoryMutationClass.new(containment, world)

    _check(wm.create_entity(&"actor.survivor", ACTOR_ID) == ACTOR_ID, "freshness integration actor created")
    _check(wm.set_placement(ACTOR_ID, Layers.Channel.ACTOR, Vector2i(5, 5), Facing.Value.EAST, Footprint.single_cell()), "freshness integration actor placed")
    _check(hand_mutations.enroll_actor(ACTOR_ID), "freshness integration hands enrolled")
    _check(containment_mutations.enroll_container(ACTOR_ID), "freshness integration personal inventory enrolled")

    var items := LootItemsClass.new()
    var profiles := FreshLootProfilesClass.new()
    var physical := PhysicalCatalogClass.new()
    _check(items.register_physical_profiles(physical), "freshness integration physical item profiles registered")
    var weight_query := WeightQueryClass.new(world, physical)
    var carry_state := CarryStateClass.new(world)
    _check(carry_state.enroll_actor(ACTOR_ID), "freshness integration carry state enrolled")
    var carry_query := CarryQueryClass.new(world, hands, containment, weight_query, carry_state)

    var time_profile := TimeProfileClass.new()
    var freshness_catalog := FreshCatalogClass.new(time_profile)
    var freshness_state := FreshStateClass.new()
    var ambient := AmbientClass.new()
    var providers: Array[SpoilageEnvironmentProvider] = [ambient]
    var freshness_mutations := FreshMutationClass.new(world, freshness_state, freshness_catalog, providers)
    var kernel := TickKernelClass.new(ACTOR_ID)
    var freshness_query := FreshQueryClass.new(world, freshness_state, freshness_catalog, kernel, providers)
    var loot_state := LootStateClass.new()
    var initializer := LootInitializerClass.new(
        world,
        wm,
        containment,
        containment_mutations,
        loot_state,
        items,
        profiles,
        physical,
        freshness_mutations
    )
    _check(initializer.is_ready(), "freshness-aware System 24 initializer ready")
    _check(freshness_query.is_ready(), "freshness integration query ready")
    return {
        "world": world,
        "world_mutations": wm,
        "hands": hands,
        "containment": containment,
        "containment_mutations": containment_mutations,
        "items": items,
        "profiles": profiles,
        "physical": physical,
        "weight_query": weight_query,
        "carry_query": carry_query,
        "time_profile": time_profile,
        "freshness_state": freshness_state,
        "freshness_mutations": freshness_mutations,
        "freshness_query": freshness_query,
        "loot_state": loot_state,
        "initializer": initializer,
    }

func _freshness_plan(instance_id: String, cell: Vector2i) -> GeneratedBuildingPlan:
    var plan := BuildingPlanClass.new()
    plan.instance_id = instance_id
    plan.archetype_id = &"commercial.grocery.neighborhood"
    plan.archetype_version = 1
    plan.seed = 3030
    plan.footprint_rect = Rect2i(cell - Vector2i(2, 2), Vector2i(5, 5))
    plan.orientation = Facing.Value.SOUTH
    plan.frontage_side = Facing.Value.SOUTH
    plan.props = [{
        "role": CONTAINER_ROLE,
        "cell": cell,
        "semantic": &"prop.retail_shelf",
        "facing": Facing.Value.SOUTH,
        "blocking": true,
    }]
    _check(plan.is_generated(), "System 30 authored loot plan valid")
    return plan

func _materialize_container(fx: Dictionary, plan: GeneratedBuildingPlan) -> void:
    var wm: WorldMutationService = fx["world_mutations"]
    var container_id: String = plan.entity_id_for_role(CONTAINER_ROLE)
    _check(wm.create_entity(&"prop.retail_shelf", container_id) == container_id, "freshness test container created")
    _check(wm.set_placement(container_id, Layers.Channel.OBJECT, plan.props[0].get("cell", Vector2i.ZERO), Facing.Value.SOUTH, Footprint.single_cell()), "freshness test container placed")

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
