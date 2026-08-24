extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const BuildingPlanClass = preload("res://scripts/generation/buildings/GeneratedBuildingPlan.gd")
const HandStateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const HandMutationClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd")
const InventoryStateClass = preload("res://scripts/simulation/inventory/InventoryContainmentState.gd")
const InventoryMutationClass = preload("res://scripts/simulation/inventory/InventoryContainmentMutationService.gd")
const PhysicalCatalogClass = preload("res://scripts/simulation/items/properties/ItemPhysicalPropertyCatalog.gd")
const WeightQueryClass = preload("res://scripts/simulation/items/properties/ItemWeightQuery.gd")
const CarryStateClass = preload("res://scripts/simulation/actors/carry/ActorCarryState.gd")
const CarryQueryClass = preload("res://scripts/simulation/actors/carry/ActorCarryQuery.gd")
const CarryAcquisitionClass = preload("res://scripts/simulation/actors/carry/ActorCarryAcquisitionPolicy.gd")
const ActionTypes = preload("res://scripts/simulation/items/transfer/ItemTransferActionType.gd")
const TimingPolicyClass = preload("res://scripts/simulation/items/transfer/ItemTransferTimingPolicy.gd")
const DispositionQueryClass = preload("res://scripts/simulation/items/transfer/ItemDispositionQuery.gd")
const PolicyTransferClass = preload("res://scripts/simulation/items/transfer/PolicyAwareItemTransferActionService.gd")
const LootItemCatalogClass = preload("res://scripts/simulation/loot/LootItemCatalog.gd")
const LootProfileCatalogClass = preload("res://scripts/simulation/loot/LootContainerProfileCatalog.gd")
const LootStateClass = preload("res://scripts/simulation/loot/LootState.gd")
const LootInitializerClass = preload("res://scripts/simulation/loot/LootSourceInitializer.gd")
const LootAccessClass = preload("res://scripts/simulation/loot/LootWorldContainerAccessPolicy.gd")
const LootSearchClass = preload("res://scripts/simulation/loot/LootSearchActionService.gd")
const FailingContainmentClass = preload("res://scripts/ci/LootFailingContainmentMutations.gd")

const ACTOR_ID: String = "actor.loot.test"
const TRANSFER_TICKS: int = 5

var failures: Array[String] = []
var _search_contents: Array[String] = []
var _search_serial: int = 0
var _search_failed_reason: String = ""

func _initialize() -> void:
    _test_taxonomy_and_context_profiles()
    _test_deterministic_initialization_and_no_repopulation()
    _test_empty_source_and_snapshot()
    _test_atomic_rollback_after_partial_mutation()
    _test_timed_search_reads_current_contents()
    _test_external_take_store_and_carry_ceiling()
    if failures.is_empty():
        print("WORLD_LOOT_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("WORLD_LOOT_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_taxonomy_and_context_profiles() -> void:
    var items := LootItemCatalogClass.new()
    var profiles := LootProfileCatalogClass.new()
    _check(items.semantic_types().size() >= 50, "candidate item library is broad")
    var saw_usable: bool = false
    var saw_junk: bool = false
    var families: Dictionary = {}
    for semantic: StringName in items.semantic_types():
        var definition: Dictionary = items.definition(semantic)
        var utility: StringName = StringName(definition.get("utility_class", &""))
        var family: StringName = StringName(definition.get("family", &""))
        _check(utility == LootItemCatalogClass.USABLE or utility == LootItemCatalogClass.JUNK, "item utility class valid: %s" % String(semantic))
        _check(String(family) != "", "item family present: %s" % String(semantic))
        _check(int(definition.get("weight_grams", 0)) > 0, "item physical weight positive: %s" % String(semantic))
        saw_usable = saw_usable or utility == LootItemCatalogClass.USABLE
        saw_junk = saw_junk or utility == LootItemCatalogClass.JUNK
        families[String(family)] = true
    _check(saw_usable and saw_junk, "both USABLE and JUNK exist")
    for expected_family: String in ["food", "drink", "kitchen", "medical", "tools", "farming", "construction", "electrical", "office", "sanitation"]:
        _check(families.has(expected_family), "core family exists: %s" % expected_family)
    _check(items.utility_class(&"item.junk.empty_food_can") == LootItemCatalogClass.JUNK, "junk classification explicit")
    _check(items.family(&"item.junk.empty_food_can") == &"kitchen", "junk retains location family")
    _check(items.utility_class(&"item.kitchen.can_opener") == LootItemCatalogClass.USABLE, "usable classification explicit")
    _check(items.family(&"item.kitchen.can_opener") == &"kitchen", "usable kitchen family explicit")
    _check(profiles.validate_items(items), "all loot profiles resolve taxonomy items")

    var shelf: StringName = &"prop.retail_shelf"
    var convenience: StringName = profiles.classify(&"commercial.convenience_store.small", "prop.sales.shelf_1", shelf)
    var grocery: StringName = profiles.classify(&"commercial.grocery.neighborhood", "prop.sales.shelf_1", shelf)
    var pharmacy: StringName = profiles.classify(&"commercial.pharmacy.small", "prop.sales.shelf_1", shelf)
    var hardware: StringName = profiles.classify(&"commercial.hardware_store.small", "prop.sales.shelf_1", shelf)
    _check(convenience == &"retail.convenience", "convenience shelf contextual profile")
    _check(grocery == &"retail.grocery", "grocery shelf contextual profile")
    _check(pharmacy == &"retail.pharmacy", "pharmacy shelf contextual profile")
    _check(hardware == &"retail.hardware", "hardware shelf contextual profile")
    _check(convenience != grocery and grocery != pharmacy and pharmacy != hardware, "shared shelf semantic does not collapse context")

func _test_deterministic_initialization_and_no_repopulation() -> void:
    var fx: Dictionary = _fixture()
    var plan: GeneratedBuildingPlan = _plan(
        "building.grocery.test",
        &"commercial.grocery.neighborhood",
        411,
        "prop.sales.shelf_1",
        &"prop.retail_shelf",
        Vector2i(6, 5)
    )
    _materialize_plan_props(fx, plan)
    var initializer: LootSourceInitializer = fx["initializer"]
    var first_plan: Dictionary = initializer.plan_source("source.grocery", [plan])
    var second_plan: Dictionary = initializer.plan_source("source.grocery", [plan])
    _check(bool(first_plan.get("ok", false)) and bool(second_plan.get("ok", false)), "deterministic plans succeed")
    _check(String(first_plan.get("signature", "")) == String(second_plan.get("signature", "")), "same source/seed produces same virgin signature")

    var result: Dictionary = initializer.initialize_source("source.grocery", &"dev_area", "grocery", [plan])
    _check(bool(result.get("ok", false)) and not bool(result.get("already_initialized", true)), "virgin source initializes")
    var container_id: String = plan.entity_id_for_role("prop.sales.shelf_1")
    var containment: InventoryContainmentState = fx["containment"]
    var world: WorldState = fx["world"]
    var loot_state: LootState = fx["loot_state"]
    _check(loot_state.has_source("source.grocery"), "source provenance committed")
    _check(loot_state.has_container(container_id), "container provenance committed")
    _check(containment.has_container(container_id), "physical shelf explicitly enrolled")
    var initial_items: Array[String] = containment.direct_contents(container_id)
    _check(initial_items.size() >= 2, "grocery profile produces bounded nonempty baseline")
    for item_id: String in initial_items:
        _check(world.has_entity(item_id) and not world.has_placement(item_id), "loot item is stable unplaced WHAT entity")
        _check(containment.container_of(item_id) == container_id, "loot item contained exactly once")
        var semantic: StringName = world.entity(item_id).semantic_type
        _check(fx["physical"].has_profile(semantic), "generated loot has 13D weight profile")

    # Simulate complete looting through ordinary persistent containment truth.
    for item_id: String in initial_items:
        _check(fx["containment_mutations"].set_container(item_id, ACTOR_ID), "move item out of world container")
    _check(containment.direct_contents(container_id).is_empty(), "container can become honestly empty")
    var world_revision_before: int = world.revision()
    var containment_revision_before: int = containment.revision()
    var second_init: Dictionary = initializer.initialize_source("source.grocery", &"dev_area", "grocery", [plan])
    _check(bool(second_init.get("ok", false)) and bool(second_init.get("already_initialized", false)), "repeat initialization is successful no-op")
    _check(containment.direct_contents(container_id).is_empty(), "initialized empty container never repopulates")
    _check(world.revision() == world_revision_before, "repeat initialization creates no WHAT mutation")
    _check(containment.revision() == containment_revision_before, "repeat initialization creates no containment mutation")

func _test_empty_source_and_snapshot() -> void:
    var fx: Dictionary = _fixture()
    var initializer: LootSourceInitializer = fx["initializer"]
    var result: Dictionary = initializer.initialize_source("source.empty", &"dev_area", "empty", [])
    _check(bool(result.get("ok", false)), "zero-container source initializes")
    var loot_state: LootState = fx["loot_state"]
    _check(loot_state.has_source("source.empty"), "zero-container source records initialized truth")
    _check(loot_state.source_record("source.empty").get("container_ids", []).is_empty(), "zero-container source keeps empty list")
    var snapshot: Dictionary = loot_state.snapshot()
    var restored := LootStateClass.new()
    _check(restored.load_snapshot(snapshot), "loot snapshot round-trip loads")
    _check(JSON.stringify(restored.snapshot()) == JSON.stringify(snapshot), "loot snapshot round-trip deterministic")

func _test_atomic_rollback_after_partial_mutation() -> void:
    var fx: Dictionary = _fixture(2)
    var plan: GeneratedBuildingPlan = _plan(
        "building.rollback.test",
        &"commercial.grocery.neighborhood",
        901,
        "prop.sales.shelf_1",
        &"prop.retail_shelf",
        Vector2i(6, 5)
    )
    _materialize_plan_props(fx, plan)
    var world: WorldState = fx["world"]
    var containment: InventoryContainmentState = fx["containment"]
    var loot_state: LootState = fx["loot_state"]
    var world_before: String = JSON.stringify(world.snapshot())
    var containment_before: String = JSON.stringify(containment.snapshot())
    var loot_before: String = JSON.stringify(loot_state.snapshot())
    var result: Dictionary = fx["initializer"].initialize_source("source.rollback", &"dev_area", "rollback", [plan])
    _check(not bool(result.get("ok", true)), "injected mid-initialization containment failure surfaces")
    _check(JSON.stringify(world.snapshot()) == world_before, "WHAT rolls back exactly after partial loot mutation")
    _check(JSON.stringify(containment.snapshot()) == containment_before, "System 11 rolls back exactly after partial loot mutation")
    _check(JSON.stringify(loot_state.snapshot()) == loot_before, "System 24 rolls back exactly after partial loot mutation")

func _test_timed_search_reads_current_contents() -> void:
    var fx: Dictionary = _fixture()
    var plan: GeneratedBuildingPlan = _plan(
        "building.search.test",
        &"commercial.grocery.neighborhood",
        1201,
        "prop.sales.shelf_1",
        &"prop.retail_shelf",
        Vector2i(6, 5)
    )
    _materialize_plan_props(fx, plan)
    var init: Dictionary = fx["initializer"].initialize_source("source.search", &"dev_area", "search", [plan])
    _check(bool(init.get("ok", false)), "search source initializes")
    var container_id: String = plan.entity_id_for_role("prop.sales.shelf_1")
    var before: Array[String] = fx["containment"].direct_contents(container_id)
    _check(before.size() >= 2, "search fixture has contents")
    _search_contents = []
    _search_serial = 0
    _search_failed_reason = ""
    var search: LootSearchActionService = fx["search"]
    search.search_completed.connect(_on_search_completed)
    search.search_failed.connect(_on_search_failed)
    var request: Dictionary = search.request_search(ACTOR_ID, container_id)
    _check(bool(request.get("accepted", false)), "adjacent search accepted")
    var duration: int = int(request.get("duration_ticks", 0))
    _check(duration == 12, "grocery shelf search duration comes from profile")
    var moved_id: String = before[0]
    _check(fx["containment_mutations"].set_container(moved_id, ACTOR_ID), "other truth changes during search")
    var tick_before: int = fx["kernel"].world_tick()
    fx["kernel"].run_until_stop()
    _check(fx["kernel"].world_tick() - tick_before == duration, "search spends configured WHEN ticks")
    _check(_search_serial == int(request.get("action_serial", -1)) and _search_failed_reason.is_empty(), "search completes normally")
    _check(not _search_contents.has(moved_id), "search returns current completion-time contents, not stale request copy")
    _check(_search_contents.size() == before.size() - 1, "search completion reflects concurrent contents change")

func _test_external_take_store_and_carry_ceiling() -> void:
    var fx: Dictionary = _fixture()
    var plan: GeneratedBuildingPlan = _plan(
        "building.transfer.test",
        &"commercial.grocery.neighborhood",
        1501,
        "prop.sales.shelf_1",
        &"prop.retail_shelf",
        Vector2i(6, 5)
    )
    _materialize_plan_props(fx, plan)
    _check(bool(fx["initializer"].initialize_source("source.transfer", &"dev_area", "transfer", [plan]).get("ok", false)), "transfer source initializes")
    var container_id: String = plan.entity_id_for_role("prop.sales.shelf_1")
    var containment: InventoryContainmentState = fx["containment"]
    var item_id: String = containment.direct_contents(container_id)[0]
    var service: ItemTransferActionService = fx["transfer"]
    var kernel: TickKernel = fx["kernel"]
    var tick_before: int = kernel.world_tick()
    var take: ItemTransferActionResult = service.request_transfer_container(ACTOR_ID, item_id, ACTOR_ID)
    _check(take != null and take.is_accepted(), "external container TAKE uses System 12")
    kernel.run_until_stop()
    _check(kernel.world_tick() - tick_before == TRANSFER_TICKS, "TAKE spends explicit System 12 ticks")
    _check(containment.container_of(item_id) == ACTOR_ID, "TAKE moves real item into personal root")

    tick_before = kernel.world_tick()
    var store: ItemTransferActionResult = service.request_transfer_container(ACTOR_ID, item_id, container_id)
    _check(store != null and store.is_accepted(), "STORE to reachable world container uses System 12")
    kernel.run_until_stop()
    _check(kernel.world_tick() - tick_before == TRANSFER_TICKS, "STORE spends explicit System 12 ticks")
    _check(containment.container_of(item_id) == container_id, "STORE returns real item to world container")

    # A hardware shelf's lightest Candidate 001 entry is above a 100 g hard ceiling.
    var fx_limit: Dictionary = _fixture()
    _check(fx_limit["carry_state"].set_capacity_grams(ACTOR_ID, 50), "shrink carry capacity for hard-ceiling fixture")
    var hard_plan: GeneratedBuildingPlan = _plan(
        "building.hardware.limit",
        &"commercial.hardware_store.small",
        1901,
        "prop.sales.shelf_1",
        &"prop.retail_shelf",
        Vector2i(6, 5)
    )
    _materialize_plan_props(fx_limit, hard_plan)
    _check(bool(fx_limit["initializer"].initialize_source("source.limit", &"dev_area", "limit", [hard_plan]).get("ok", false)), "hard-limit source initializes")
    var hard_container: String = hard_plan.entity_id_for_role("prop.sales.shelf_1")
    var hard_item: String = fx_limit["containment"].direct_contents(hard_container)[0]
    var limit_kernel: TickKernel = fx_limit["kernel"]
    var rejected: ItemTransferActionResult = fx_limit["transfer"].request_transfer_container(ACTOR_ID, hard_item, ACTOR_ID)
    _check(rejected != null and not rejected.is_accepted(), "external TAKE obeys hard carry ceiling")
    _check(rejected.reason == "absolute_carry_limit_exceeded", "external TAKE reports carry ceiling reason")
    _check(limit_kernel.world_tick() == 0, "rejected external TAKE spends zero ticks")
    _check(fx_limit["containment"].container_of(hard_item) == hard_container, "rejected external TAKE leaves source truth unchanged")

func _fixture(fail_on_set_call: int = -1) -> Dictionary:
    var world := WorldStateClass.new()
    var world_mutations := WorldMutationClass.new(world)
    var hands := HandStateClass.new()
    var hand_mutations := HandMutationClass.new(hands, world)
    var containment := InventoryStateClass.new()
    var containment_mutations: InventoryContainmentMutationService
    if fail_on_set_call > 0:
        containment_mutations = FailingContainmentClass.new(containment, world, fail_on_set_call)
    else:
        containment_mutations = InventoryMutationClass.new(containment, world)

    _check(world_mutations.create_entity(&"actor.survivor", ACTOR_ID) == ACTOR_ID, "create loot actor")
    _check(world_mutations.set_placement(ACTOR_ID, Layers.Channel.ACTOR, Vector2i(5, 5), Facing.Value.EAST, Footprint.single_cell()), "place loot actor")
    _check(hand_mutations.enroll_actor(ACTOR_ID), "enroll loot actor hands")
    _check(containment_mutations.enroll_container(ACTOR_ID), "enroll loot actor inventory")

    var items := LootItemCatalogClass.new()
    var profiles := LootProfileCatalogClass.new()
    var physical := PhysicalCatalogClass.new()
    _check(items.register_physical_profiles(physical), "register Candidate 001 physical weights")
    var weight_query := WeightQueryClass.new(world, physical)
    var carry_state := CarryStateClass.new(world)
    _check(carry_state.enroll_actor(ACTOR_ID), "enroll carry state")
    var carry_query := CarryQueryClass.new(world, hands, containment, weight_query, carry_state)
    var capacity := CarryAcquisitionClass.new(carry_query)
    var loot_state := LootStateClass.new()
    var initializer := LootInitializerClass.new(
        world,
        world_mutations,
        containment,
        containment_mutations,
        loot_state,
        items,
        profiles,
        physical
    )
    var kernel := TickKernelClass.new(ACTOR_ID)
    var timing := TimingPolicyClass.new()
    for action_type: StringName in ActionTypes.ALL:
        _check(timing.register_duration(action_type, TRANSFER_TICKS), "register transfer timing %s" % String(action_type))
    var disposition := DispositionQueryClass.new(world, hands, containment)
    var access := LootAccessClass.new(world, loot_state, containment)
    var transfer := PolicyTransferClass.new(
        world,
        world_mutations,
        hands,
        hand_mutations,
        containment,
        containment_mutations,
        kernel,
        timing,
        disposition,
        capacity,
        access
    )
    var search := LootSearchClass.new(world, containment, loot_state, profiles, kernel)
    _check(initializer.is_ready(), "loot initializer ready")
    _check(transfer.is_ready(), "policy-aware transfer ready")
    _check(search.is_ready(), "loot search ready")
    return {
        "world": world,
        "world_mutations": world_mutations,
        "hands": hands,
        "hand_mutations": hand_mutations,
        "containment": containment,
        "containment_mutations": containment_mutations,
        "items": items,
        "profiles": profiles,
        "physical": physical,
        "weight_query": weight_query,
        "carry_state": carry_state,
        "carry_query": carry_query,
        "capacity": capacity,
        "loot_state": loot_state,
        "initializer": initializer,
        "kernel": kernel,
        "timing": timing,
        "access": access,
        "transfer": transfer,
        "search": search,
    }

func _plan(
    instance_id: String,
    archetype_id: StringName,
    seed: int,
    role: String,
    semantic: StringName,
    cell: Vector2i
) -> GeneratedBuildingPlan:
    var plan := BuildingPlanClass.new()
    plan.instance_id = instance_id
    plan.archetype_id = archetype_id
    plan.archetype_version = 1
    plan.seed = seed
    plan.footprint_rect = Rect2i(cell - Vector2i(2, 2), Vector2i(5, 5))
    plan.orientation = Facing.Value.SOUTH
    plan.frontage_side = Facing.Value.SOUTH
    plan.props = [{
        "role": role,
        "cell": cell,
        "semantic": semantic,
        "facing": Facing.Value.SOUTH,
        "blocking": true,
    }]
    _check(plan.is_generated(), "authored loot test plan generated")
    _check(plan.entity_id_for_role(role) == "%s.%s" % [instance_id, role], "System 19 role/entity seam stable")
    return plan

func _materialize_plan_props(fx: Dictionary, plan: GeneratedBuildingPlan) -> void:
    var wm: WorldMutationService = fx["world_mutations"]
    for prop: Dictionary in plan.props:
        var entity_id: String = plan.entity_id_for_role(String(prop.get("role", "")))
        var semantic: StringName = StringName(prop.get("semantic", &""))
        _check(wm.create_entity(semantic, entity_id) == entity_id, "create physical loot container %s" % entity_id)
        _check(wm.set_placement(entity_id, Layers.Channel.OBJECT, prop.get("cell", Vector2i.ZERO), int(prop.get("facing", Facing.Value.SOUTH)), Footprint.single_cell()), "place physical loot container %s" % entity_id)

func _on_search_completed(_actor_id: String, serial: int, _container_id: String, contents: Array, _version: int) -> void:
    _search_serial = serial
    _search_contents = []
    for value: Variant in contents:
        _search_contents.append(String(value))

func _on_search_failed(_actor_id: String, serial: int, _container_id: String, reason: String) -> void:
    _search_serial = serial
    _search_failed_reason = reason

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
