extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const HandStateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const HandMutationClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const InventoryStateClass = preload("res://scripts/simulation/inventory/InventoryContainmentState.gd")
const InventoryMutationClass = preload("res://scripts/simulation/inventory/InventoryContainmentMutationService.gd")
const CatalogClass = preload("res://scripts/simulation/items/properties/ItemPhysicalPropertyCatalog.gd")
const WeightQueryClass = preload("res://scripts/simulation/items/properties/ItemWeightQuery.gd")
const CarryStateClass = preload("res://scripts/simulation/actors/carry/ActorCarryState.gd")
const CarryQueryClass = preload("res://scripts/simulation/actors/carry/ActorCarryQuery.gd")
const CarryProviderClass = preload("res://scripts/simulation/actors/carry/ActorCarryMobilityModifierProvider.gd")
const ProviderBase = preload("res://scripts/simulation/actors/locomotion/ActorMobilityModifierProvider.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _test_carry_contract()
    _test_snapshot_contract()
    if failures.is_empty():
        print("ACTOR_CARRY_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("ACTOR_CARRY_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture() -> Dictionary:
    var world := WorldStateClass.new()
    var wm := WorldMutationClass.new(world)
    wm.create_entity(&"actor.survivor", "actor.a")
    var hands := HandStateClass.new()
    var hand_mutations := HandMutationClass.new(hands, world)
    hand_mutations.enroll_actor("actor.a")
    var inventory := InventoryStateClass.new()
    var inventory_mutations := InventoryMutationClass.new(inventory, world)
    inventory_mutations.enroll_container("actor.a")
    var catalog := CatalogClass.new()
    var weight_query := WeightQueryClass.new(world, catalog)
    var carry_state := CarryStateClass.new(world)
    carry_state.enroll_actor("actor.a")
    var carry_query := CarryQueryClass.new(world, hands, inventory, weight_query, carry_state)
    return {
        "world": world,
        "wm": wm,
        "hands": hands,
        "hand_mutations": hand_mutations,
        "inventory": inventory,
        "inventory_mutations": inventory_mutations,
        "catalog": catalog,
        "carry_state": carry_state,
        "carry_query": carry_query,
    }

func _test_carry_contract() -> void:
    var fixture: Dictionary = _fixture()
    var wm: WorldMutationService = fixture["wm"]
    var hand_mutations: ActorHandEquipmentMutationService = fixture["hand_mutations"]
    var inventory: InventoryContainmentState = fixture["inventory"]
    var inventory_mutations: InventoryContainmentMutationService = fixture["inventory_mutations"]
    var catalog: ItemPhysicalPropertyCatalog = fixture["catalog"]
    var carry_state: ActorCarryState = fixture["carry_state"]
    var carry_query: ActorCarryQuery = fixture["carry_query"]
    _check(carry_state.capacity_grams("actor.a") == 18000, "recovered base capacity is 18 kg")
    _check(carry_state.hard_limit_grams("actor.a") == 36000, "derived absolute carry ceiling is 36 kg")

    wm.create_entity(&"item.backpack", "item.pack")
    wm.create_entity(&"item.food", "item.food")
    wm.create_entity(&"item.hammer", "item.hammer")
    wm.create_entity(&"item.bottle", "item.bottle")
    wm.create_entity(&"item.mystery", "item.mystery")
    catalog.register_profile(&"item.backpack", 1000)
    catalog.register_profile(&"item.food", 500)
    catalog.register_profile(&"item.hammer", 900)
    catalog.register_profile(&"item.bottle", 600)

    _check(inventory_mutations.enroll_container("item.pack"), "held item-container enrolled")
    _check(inventory_mutations.set_container("item.food", "item.pack"), "nested content placed in pack")
    _check(hand_mutations.set_item("actor.a", Slots.Value.PRIMARY_RIGHT, "item.pack"), "pack held in primary hand")
    _check(hand_mutations.set_item("actor.a", Slots.Value.SECONDARY_LEFT, "item.hammer"), "hammer held in secondary hand")
    _check(inventory_mutations.set_container("item.bottle", "actor.a"), "actor-root item contained")

    var subtree: Dictionary = carry_query.query_item_tree("item.pack")
    _check(int(subtree.get("status", -1)) == CarryQueryClass.Status.KNOWN, "item subtree weight known")
    _check(int(subtree.get("weight_grams", -1)) == 1500, "item subtree includes container plus nested contents")

    var carry: Dictionary = carry_query.query("actor.a")
    _check(int(carry.get("status", -1)) == CarryQueryClass.Status.KNOWN, "carry total known when all weights classified")
    _check(int(carry.get("weight_grams", -1)) == 3000, "hand + held-container contents + actor-root item summed")
    _check(int(carry.get("hard_limit_grams", -1)) == 36000, "carry result exposes derived hard ceiling")
    var ids: Array = carry.get("item_ids", [])
    _check(ids.size() == 4 and ids.has("item.pack") and ids.has("item.food") and ids.has("item.hammer") and ids.has("item.bottle"), "all personally possessed physical items counted")

    _check(inventory_mutations.set_container("item.hammer", "actor.a"), "low-level cross-domain duplicate truth can be constructed")
    var deduped: Dictionary = carry_query.query("actor.a")
    _check(int(deduped.get("weight_grams", -1)) == 3000 and (deduped.get("item_ids", []) as Array).size() == 4, "stable item IDs prevent double-counting")
    _check(inventory_mutations.clear_container("item.hammer"), "duplicate test relation cleared")

    _check(inventory_mutations.set_container("item.mystery", "actor.a"), "unclassified-weight item can physically exist")
    var unknown: Dictionary = carry_query.query("actor.a")
    _check(int(unknown.get("status", -1)) == CarryQueryClass.Status.UNKNOWN, "one missing weight makes total UNKNOWN")
    inventory_mutations.clear_container("item.mystery")

    _check(carry_state.set_capacity_grams("actor.a", 3000), "capacity can be changed through 13E")
    _check(carry_state.hard_limit_grams("actor.a") == 6000, "hard ceiling tracks capacity at exactly 2x")
    var exact: Dictionary = carry_query.query("actor.a")
    _check(int(exact.get("load_ratio_bp", -1)) == 10000, "load ratio uses 10,000 basis points at capacity")
    _check(int(exact.get("hard_limit_grams", -1)) == 6000, "query hard ceiling updates with capacity")
    var provider := CarryProviderClass.new(carry_query)
    var provider_result: Dictionary = provider.evaluate("actor.a", &"movement.step_forward")
    _check(int(provider_result.get("status", -1)) == ProviderBase.Status.ALLOWED and int(provider_result.get("duration_adjustment_bp", -1)) == 7500, "100 percent capacity recovers +75 percent timing pressure")
    carry_state.set_capacity_grams("actor.a", 1500)
    var over: Dictionary = provider.evaluate("actor.a", &"movement.turn_left")
    _check(int(over.get("duration_adjustment_bp", -1)) == 15000, "over-capacity load remains representable and scales beyond 100 percent")
    var unrelated: Dictionary = provider.evaluate("actor.a", &"inventory.inspect")
    _check(int(unrelated.get("duration_adjustment_bp", -1)) == 0, "unrelated action unaffected")
    _check(inventory.has_container("actor.a"), "carry query never mutates containment")

func _test_snapshot_contract() -> void:
    var fixture: Dictionary = _fixture()
    var carry_state: ActorCarryState = fixture["carry_state"]
    carry_state.set_capacity_grams("actor.a", 22000)
    _check(carry_state.hard_limit_grams("actor.a") == 44000, "hard ceiling is derived rather than separately persisted")
    var saved: Dictionary = carry_state.snapshot()
    _check(not saved.has("hard_limit_grams"), "snapshot does not persist a second hard-limit truth")
    var restored := CarryStateClass.new()
    _check(restored.load_snapshot(saved), "capacity snapshot restores")
    _check(restored.snapshot() == saved, "capacity snapshot deterministic")
    _check(restored.hard_limit_grams("actor.a") == 44000, "restored capacity re-derives hard ceiling")
    var before_bad: Dictionary = restored.snapshot()
    var bad: Dictionary = before_bad.duplicate(true)
    bad["records"][0]["capacity_grams"] = 0
    _check(not restored.load_snapshot(bad), "non-positive capacity snapshot rejected")
    _check(restored.snapshot() == before_bad, "bad capacity restore atomic")

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
