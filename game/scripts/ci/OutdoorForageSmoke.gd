extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const SkillStateClass = preload("res://scripts/simulation/actors/skills/ActorSkillState.gd")
const SkillChecksClass = preload("res://scripts/simulation/actors/skills/ActorSkillCheckService.gd")
const HandStateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const HandMutationClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd")
const InventoryStateClass = preload("res://scripts/simulation/inventory/InventoryContainmentState.gd")
const InventoryMutationClass = preload("res://scripts/simulation/inventory/InventoryContainmentMutationService.gd")
const PhysicalCatalogClass = preload("res://scripts/simulation/items/properties/ItemPhysicalPropertyCatalog.gd")
const WeightQueryClass = preload("res://scripts/simulation/items/properties/ItemWeightQuery.gd")
const CarryStateClass = preload("res://scripts/simulation/actors/carry/ActorCarryState.gd")
const CarryQueryClass = preload("res://scripts/simulation/actors/carry/ActorCarryQuery.gd")
const CarryAcquisitionClass = preload("res://scripts/simulation/actors/carry/ActorCarryAcquisitionPolicy.gd")
const LootItemsClass = preload("res://scripts/simulation/loot/LootItemCatalog.gd")
const ForageStateClass = preload("res://scripts/simulation/forage/OutdoorForageState.gd")
const ForageActionClass = preload("res://scripts/simulation/forage/ForageNearbyActionService.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _test_success_depletion_and_inventory_yield()
    _test_capacity_block_leaves_real_loose_items()
    _test_cancel_preserves_opportunity()
    _test_failed_valid_search_consumes_opportunity()
    _test_impossible_environment_hard_blocks()
    _test_deterministic_result()
    if failures.is_empty():
        print("OUTDOOR_FORAGE_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("OUTDOOR_FORAGE_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture(
    actor_id: String,
    terrain: StringName,
    survival_level: int,
    carry_capacity_grams: int = CarryStateClass.DEFAULT_CAPACITY_GRAMS
) -> Dictionary:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    mutations.set_terrain_rect(Rect2i(Vector2i.ZERO, Vector2i(40, 40)), terrain)
    mutations.create_entity(&"actor.survivor", actor_id)
    mutations.set_placement(actor_id, Layers.Channel.ACTOR, Vector2i(10, 10), Facing.Value.NORTH, Footprint.single_cell())

    var hands := HandStateClass.new()
    var hand_mutations := HandMutationClass.new(hands, world)
    _check(hand_mutations.enroll_actor(actor_id), "forage fixture enrolls actor hands")

    var inventory := InventoryStateClass.new()
    var inventory_mutations := InventoryMutationClass.new(inventory, world)
    _check(inventory_mutations.enroll_container(actor_id), "forage fixture enrolls personal inventory")

    var loot_items := LootItemsClass.new()
    var physical := PhysicalCatalogClass.new()
    _check(loot_items.register_physical_profiles(physical), "forage fixture registers loot physical profiles")
    var weights := WeightQueryClass.new(world, physical)
    var carry_state := CarryStateClass.new(world)
    _check(carry_state.enroll_actor(actor_id, carry_capacity_grams), "forage fixture enrolls carry state")
    var carry_query := CarryQueryClass.new(world, hands, inventory, weights, carry_state)
    var capacity_policy := CarryAcquisitionClass.new(carry_query)

    var skills := SkillStateClass.new(world)
    skills.enroll_actor(actor_id)
    skills.set_skill(actor_id, SkillCatalog.SURVIVAL, survival_level, 0)
    var checks := SkillChecksClass.new(skills)
    var kernel := TickKernelClass.new(actor_id)
    var forage_state := ForageStateClass.new()
    var actions := ForageActionClass.new(
        world,
        mutations,
        kernel,
        checks,
        loot_items,
        123,
        forage_state,
        inventory_mutations,
        capacity_policy
    )
    return {
        "world": world,
        "mutations": mutations,
        "skills": skills,
        "kernel": kernel,
        "state": forage_state,
        "actions": actions,
        "actor_id": actor_id,
        "inventory": inventory,
        "inventory_mutations": inventory_mutations,
        "carry_query": carry_query,
        "carry_state": carry_state,
    }

func _test_success_depletion_and_inventory_yield() -> void:
    var f: Dictionary = _fixture("actor.forage.success", &"ground.grass_lush", 10)
    var actions: ForageNearbyActionService = f["actions"]
    var state: OutdoorForageState = f["state"]
    var kernel: TickKernel = f["kernel"]
    var world: WorldState = f["world"]
    var inventory: InventoryContainmentState = f["inventory"]
    var carry_query: ActorCarryQuery = f["carry_query"]
    var actor_id: String = f["actor_id"]
    _check(actions.is_ready(), "forage service ready")
    var request: Dictionary = actions.request_forage(actor_id)
    _check(bool(request.get("accepted", false)), "valid outdoor forage accepted")
    var key: String = String(request.get("patch_key", ""))
    _check(state.remaining(key) == 1, "request does not consume opportunity before completion")
    kernel.run_until_stop()
    _check(state.remaining(key) == 0, "successful completed forage consumes finite opportunity")
    var found: Array[String] = world.entity_ids_of_type(ForageActionClass.STICK)
    found.append_array(world.entity_ids_of_type(ForageActionClass.STONE))
    _check(found.size() == 2, "expert effectiveness recovers two real physical units")
    var personal_contents: Array[String] = inventory.direct_contents(actor_id)
    for item_id: String in found:
        _check(world.placement(item_id) == null, "inventory-acquired forage item has no loose-world placement")
        _check(personal_contents.has(item_id), "recovered forage item is stored in survivor inventory")
    var carry: Dictionary = carry_query.query(actor_id)
    _check(int(carry.get("weight_grams", 0)) > 0, "stored forage contributes to canonical carry weight")
    for item_id: String in found:
        _check((carry.get("item_ids", []) as Array).has(item_id), "stored forage is counted by canonical carry query")
    var depleted: Dictionary = actions.request_forage(actor_id)
    _check(not bool(depleted.get("accepted", true)) and String(depleted.get("reason", "")) == "forage_depleted", "picked-clean patch hard blocks reroll")
    var saved: Dictionary = state.snapshot()
    var restored := ForageStateClass.new()
    _check(restored.load_snapshot(saved) and restored.snapshot() == saved, "sparse depletion snapshot round trips deterministically")

func _test_capacity_block_leaves_real_loose_items() -> void:
    var f: Dictionary = _fixture("actor.forage.capacity", &"ground.grass_lush", 10, 200)
    var actions: ForageNearbyActionService = f["actions"]
    var kernel: TickKernel = f["kernel"]
    var world: WorldState = f["world"]
    var inventory: InventoryContainmentState = f["inventory"]
    var actor_id: String = f["actor_id"]
    var request: Dictionary = actions.request_forage(actor_id)
    _check(bool(request.get("accepted", false)), "capacity-block fixture forage accepted")
    kernel.run_until_stop()
    var found: Array[String] = world.entity_ids_of_type(ForageActionClass.STICK)
    found.append_array(world.entity_ids_of_type(ForageActionClass.STONE))
    _check(found.size() == 2, "capacity block does not delete successfully recovered physical items")
    _check(inventory.direct_contents(actor_id).is_empty(), "hard carry ceiling prevents automatic inventory admission")
    for item_id: String in found:
        var placement: WorldPlacement = world.placement(item_id)
        _check(placement != null and placement.channel == Layers.Channel.LOOSE_ITEM and placement.anchor == Vector2i(10, 10), "over-capacity recovered item remains physically at survivor feet")

func _test_cancel_preserves_opportunity() -> void:
    var f: Dictionary = _fixture("actor.forage.cancel", &"ground.grass_lush", 10)
    var actions: ForageNearbyActionService = f["actions"]
    var state: OutdoorForageState = f["state"]
    var kernel: TickKernel = f["kernel"]
    var world: WorldState = f["world"]
    var request: Dictionary = actions.request_forage(f["actor_id"])
    var key: String = String(request.get("patch_key", ""))
    _check(bool(request.get("accepted", false)), "cancel fixture forage accepted")
    _check(kernel.cancel_action(int(request.get("action_serial", 0)), "ci_cancel"), "cancelable WHEN action cancels")
    _check(state.remaining(key) == 1, "cancellation consumes no forage opportunity")
    _check(world.entity_ids_of_type(ForageActionClass.STICK).is_empty() and world.entity_ids_of_type(ForageActionClass.STONE).is_empty(), "cancellation creates no physical item")

func _test_failed_valid_search_consumes_opportunity() -> void:
    var f: Dictionary = _fixture("actor.forage.fail6", &"ground.grass_lush", 0)
    var actions: ForageNearbyActionService = f["actions"]
    var state: OutdoorForageState = f["state"]
    var kernel: TickKernel = f["kernel"]
    var skills: ActorSkillState = f["skills"]
    var world: WorldState = f["world"]
    var xp_before: int = skills.xp(f["actor_id"], SkillCatalog.SURVIVAL)
    var request: Dictionary = actions.request_forage(f["actor_id"])
    var key: String = String(request.get("patch_key", ""))
    _check(bool(request.get("accepted", false)), "low-skill valid forage accepted")
    kernel.run_until_stop()
    _check(state.remaining(key) == 0, "failed valid forage consumes the local opportunity")
    _check(skills.xp(f["actor_id"], SkillCatalog.SURVIVAL) > xp_before, "failed forage awards bounded Survival practice XP")
    _check(world.entity_ids_of_type(ForageActionClass.STICK).is_empty() and world.entity_ids_of_type(ForageActionClass.STONE).is_empty(), "failed recovery manufactures no item")

func _test_impossible_environment_hard_blocks() -> void:
    var f: Dictionary = _fixture("actor.forage.water", &"ground.water_ocean", 10)
    var actions: ForageNearbyActionService = f["actions"]
    var state: OutdoorForageState = f["state"]
    var request: Dictionary = actions.request_forage(f["actor_id"])
    _check(not bool(request.get("accepted", true)) and String(request.get("reason", "")) == "forage_impossible", "water environment hard blocks without spending time")
    _check(state.patch_keys().is_empty(), "impossible request creates no depletion record")

func _test_deterministic_result() -> void:
    var first: Dictionary = _fixture("actor.forage.deterministic", &"ground.grass_lush", 10)
    var second: Dictionary = _fixture("actor.forage.deterministic", &"ground.grass_lush", 10)
    var first_request: Dictionary = (first["actions"] as ForageNearbyActionService).request_forage(first["actor_id"])
    var second_request: Dictionary = (second["actions"] as ForageNearbyActionService).request_forage(second["actor_id"])
    (first["kernel"] as TickKernel).run_until_stop()
    (second["kernel"] as TickKernel).run_until_stop()
    var first_world: WorldState = first["world"]
    var second_world: WorldState = second["world"]
    var first_semantics: Array[String] = _forage_semantics(first_world)
    var second_semantics: Array[String] = _forage_semantics(second_world)
    _check(bool(first_request.get("accepted", false)) and bool(second_request.get("accepted", false)) and first_semantics == second_semantics, "same seed/patch/opportunity resolves the same resource without reroll")

func _forage_semantics(world: WorldState) -> Array[String]:
    var result: Array[String] = []
    for semantic: StringName in [ForageActionClass.STICK, ForageActionClass.STONE]:
        for _item_id: String in world.entity_ids_of_type(semantic):
            result.append(String(semantic))
    result.sort()
    return result

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
