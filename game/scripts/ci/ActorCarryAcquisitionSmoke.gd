extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const TickRules = preload("res://scripts/foundation/time/TickRules.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
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
const ActionResult = preload("res://scripts/simulation/items/transfer/ItemTransferActionResult.gd")
const DispositionQueryClass = preload("res://scripts/simulation/items/transfer/ItemDispositionQuery.gd")
const TimingPolicyClass = preload("res://scripts/simulation/items/transfer/ItemTransferTimingPolicy.gd")
const TransferServiceClass = preload("res://scripts/simulation/items/transfer/ItemTransferActionService.gd")

const TEST_TICKS: int = 5

var failures: Array[String] = []
var _reentrant_target_id: String = ""
var _reentrant_extra_id: String = ""
var _reentrant_actor_id: String = ""
var _reentrant_containment_mutations: InventoryContainmentMutationService = null
var _reentrant_triggered: bool = false

func _initialize() -> void:
    _test_derived_hard_limit()
    _test_exact_limit_allowed_and_excess_rejected()
    _test_item_subtree_projection()
    _test_capacity_rechecked_at_commit()
    _test_capacity_rechecked_after_source_removal()
    _test_non_acquisition_transfers_remain_legal_at_limit()

    if failures.is_empty():
        print("ACTOR_CARRY_ACQUISITION_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("ACTOR_CARRY_ACQUISITION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture(actor_id: String, capacity_grams: int = 1000) -> Dictionary:
    var world := WorldStateClass.new()
    var wm := WorldMutationClass.new(world)
    var hands := HandStateClass.new()
    var hand_mutations := HandMutationClass.new(hands, world)
    var inventory := InventoryStateClass.new()
    var inventory_mutations := InventoryMutationClass.new(inventory, world)
    var catalog := PhysicalCatalogClass.new()
    var weight_query := WeightQueryClass.new(world, catalog)
    var carry_state := CarryStateClass.new(world)
    var carry_query := CarryQueryClass.new(world, hands, inventory, weight_query, carry_state)
    var capacity_policy := CarryAcquisitionClass.new(carry_query)
    var kernel := TickKernelClass.new()
    var timing := TimingPolicyClass.new()
    for action_type: StringName in ActionTypes.ALL:
        _check(timing.register_duration(action_type, TEST_TICKS), "register transfer timing")
    var disposition := DispositionQueryClass.new(world, hands, inventory)

    _check(wm.create_entity(&"actor.survivor", actor_id) == actor_id, "create actor %s" % actor_id)
    _check(
        wm.set_placement(
            actor_id,
            Layers.Channel.ACTOR,
            Vector2i(2, 2),
            Facing.Value.EAST,
            Footprint.single_cell()
        ),
        "place actor %s" % actor_id
    )
    _check(hand_mutations.enroll_actor(actor_id), "enroll hands %s" % actor_id)
    _check(inventory_mutations.enroll_container(actor_id), "enroll inventory %s" % actor_id)
    _check(carry_state.enroll_actor(actor_id, capacity_grams), "enroll carry %s" % actor_id)

    var service := TransferServiceClass.new(
        world,
        wm,
        hands,
        hand_mutations,
        inventory,
        inventory_mutations,
        kernel,
        timing,
        disposition,
        capacity_policy
    )
    _check(service.is_ready(), "capacity-aware transfer service ready")

    return {
        "actor_id": actor_id,
        "world": world,
        "wm": wm,
        "hands": hands,
        "hand_mutations": hand_mutations,
        "inventory": inventory,
        "inventory_mutations": inventory_mutations,
        "catalog": catalog,
        "carry_state": carry_state,
        "carry_query": carry_query,
        "capacity_policy": capacity_policy,
        "kernel": kernel,
        "service": service,
    }

func _make_item(
    fx: Dictionary,
    semantic_type: StringName,
    item_id: String,
    weight_grams: int
) -> void:
    var wm: WorldMutationService = fx["wm"]
    var catalog: ItemPhysicalPropertyCatalog = fx["catalog"]
    _check(wm.create_entity(semantic_type, item_id) == item_id, "create %s" % item_id)
    _check(catalog.register_profile(semantic_type, weight_grams), "register weight %s" % item_id)

func _seed_carried(fx: Dictionary, semantic_type: StringName, item_id: String, weight_grams: int) -> void:
    _make_item(fx, semantic_type, item_id, weight_grams)
    var cm: InventoryContainmentMutationService = fx["inventory_mutations"]
    _check(cm.set_container(item_id, String(fx["actor_id"])), "seed carried %s" % item_id)

func _make_loose(
    fx: Dictionary,
    semantic_type: StringName,
    item_id: String,
    weight_grams: int,
    cell: Vector2i = Vector2i(3, 2)
) -> void:
    _make_item(fx, semantic_type, item_id, weight_grams)
    var wm: WorldMutationService = fx["wm"]
    _check(
        wm.set_placement(
            item_id,
            Layers.Channel.LOOSE_ITEM,
            cell,
            Facing.Value.NORTH,
            Footprint.single_cell()
        ),
        "place loose %s" % item_id
    )

func _run(fx: Dictionary) -> int:
    var kernel: TickKernel = fx["kernel"]
    return kernel.run_until_stop()

func _test_derived_hard_limit() -> void:
    var fx := _fixture("actor.default_limit", CarryStateClass.DEFAULT_CAPACITY_GRAMS)
    var carry_state: ActorCarryState = fx["carry_state"]
    _check(carry_state.capacity_grams("actor.default_limit") == 18000, "default soft capacity remains 18 kg")
    _check(carry_state.hard_limit_grams("actor.default_limit") == 36000, "default hard carry ceiling is 36 kg")
    var carry: Dictionary = fx["carry_query"].query("actor.default_limit")
    _check(int(carry.get("hard_limit_grams", -1)) == 36000, "carry query exposes derived 36 kg hard ceiling")

func _test_exact_limit_allowed_and_excess_rejected() -> void:
    var fx := _fixture("actor.exact")
    _seed_carried(fx, &"item.test_seed_1500", "seed.1500", 1500)
    _make_loose(fx, &"item.test_exact_500", "loose.exact", 500)
    var service: ItemTransferActionService = fx["service"]
    var exact: ItemTransferActionResult = service.request_pickup_to_container(
        "actor.exact",
        "loose.exact",
        "actor.exact"
    )
    _check(exact.is_accepted(), "pickup may reach exact 2x hard ceiling")
    _check(_run(fx) == TickRules.RunStopReason.IDLE, "exact-limit pickup resolves")
    var exact_carry: Dictionary = fx["carry_query"].query("actor.exact")
    _check(int(exact_carry.get("weight_grams", -1)) == 2000, "exact-limit pickup reaches 2000 g")

    _make_loose(fx, &"item.test_excess_100", "loose.excess", 100)
    var before_tick: int = fx["kernel"].world_tick()
    var excess: ItemTransferActionResult = service.request_pickup_to_container(
        "actor.exact",
        "loose.excess",
        "actor.exact"
    )
    _check(
        excess.status == ActionResult.Status.CARRY_LIMIT_EXCEEDED
            and excess.reason == "absolute_carry_limit_exceeded",
        "pickup beyond 2x hard ceiling is rejected"
    )
    _check(fx["kernel"].world_tick() == before_tick, "hard-limit request rejection spends zero ticks")
    _check(fx["world"].has_placement("loose.excess"), "rejected item remains loose in world")

func _test_item_subtree_projection() -> void:
    var fx := _fixture("actor.subtree")
    _seed_carried(fx, &"item.test_subtree_seed_1300", "subtree.seed", 1300)
    _make_loose(fx, &"item.test_bag_200", "subtree.bag", 200)
    var cm: InventoryContainmentMutationService = fx["inventory_mutations"]
    _check(cm.enroll_container("subtree.bag"), "enroll loose bag as container")
    _make_item(fx, &"item.test_child_400", "subtree.child", 400)
    _check(cm.set_container("subtree.child", "subtree.bag"), "put child inside loose bag")

    var subtree: Dictionary = fx["carry_query"].query_item_tree("subtree.bag")
    _check(
        int(subtree.get("status", -1)) == CarryQueryClass.Status.KNOWN
            and int(subtree.get("weight_grams", -1)) == 600,
        "incoming container projection includes its contents"
    )
    var policy: Dictionary = fx["capacity_policy"].evaluate("actor.subtree", "subtree.bag")
    _check(
        int(policy.get("status", -1)) == ItemAcquisitionCapacityPolicy.Status.ALLOWED
            and int(policy.get("projected_weight_grams", -1)) == 1900,
        "subtree projection uses full 600 g against hard ceiling"
    )

func _test_capacity_rechecked_at_commit() -> void:
    var fx := _fixture("actor.commit_race")
    _seed_carried(fx, &"item.test_commit_seed_1500", "commit.seed", 1500)
    _make_loose(fx, &"item.test_commit_target_400", "commit.target", 400)
    _make_item(fx, &"item.test_commit_bump_200", "commit.bump", 200)
    var cm: InventoryContainmentMutationService = fx["inventory_mutations"]
    var kernel: TickKernel = fx["kernel"]
    kernel.external_event_due.connect(
        func(event):
            if event.event_type == &"test.capacity_bump":
                cm.set_container("commit.bump", "actor.commit_race")
    )

    var request: ItemTransferActionResult = fx["service"].request_pickup_to_container(
        "actor.commit_race",
        "commit.target",
        "actor.commit_race"
    )
    _check(request.is_accepted(), "pickup fits hard ceiling at request time")
    _check(kernel.schedule_event(2, "carry_acquisition_smoke", &"test.capacity_bump") > 0, "schedule carry bump")
    _check(_run(fx) == TickRules.RunStopReason.IDLE, "commit-race pickup resolves")
    _check(fx["world"].has_placement("commit.target"), "new carry truth blocks pickup at commit")
    _check(int(fx["carry_query"].query("actor.commit_race").get("weight_grams", -1)) == 1700, "commit-race bump remains real carry truth")

func _test_capacity_rechecked_after_source_removal() -> void:
    var fx := _fixture("actor.reentrant")
    _seed_carried(fx, &"item.test_reentrant_seed_1000", "reentrant.seed", 1000)
    _make_loose(fx, &"item.test_reentrant_target_900", "reentrant.target", 900)
    _make_item(fx, &"item.test_reentrant_extra_200", "reentrant.extra", 200)

    _reentrant_target_id = "reentrant.target"
    _reentrant_extra_id = "reentrant.extra"
    _reentrant_actor_id = "actor.reentrant"
    _reentrant_containment_mutations = fx["inventory_mutations"]
    _reentrant_triggered = false
    var world: WorldState = fx["world"]
    world.changed.connect(_on_reentrant_world_changed)

    var failed_reasons: Array[String] = []
    fx["service"].item_transfer_failed.connect(
        func(_actor_id, _serial, _action_type, _item_id, reason): failed_reasons.append(String(reason))
    )
    var request: ItemTransferActionResult = fx["service"].request_pickup_to_container(
        "actor.reentrant",
        "reentrant.target",
        "actor.reentrant"
    )
    _check(request.is_accepted(), "reentrant pickup initially projects below hard ceiling")
    _check(_run(fx) == TickRules.RunStopReason.IDLE, "reentrant capacity race resolves")
    if world.changed.is_connected(_on_reentrant_world_changed):
        world.changed.disconnect(_on_reentrant_world_changed)

    var placement: WorldPlacement = world.placement("reentrant.target")
    _check(_reentrant_triggered, "source removal triggered synchronous carry mutation")
    _check(placement != null and placement.anchor == Vector2i(3, 2), "post-source capacity failure restores loose source")
    _check(fx["inventory"].container_of("reentrant.extra") == "actor.reentrant", "reentrant extra weight remains carried")
    _check(
        not failed_reasons.is_empty() and failed_reasons[-1] == "absolute_carry_limit_exceeded",
        "post-source capacity race fails with hard-limit reason"
    )
    _clear_reentrant_hook()

func _test_non_acquisition_transfers_remain_legal_at_limit() -> void:
    var fx := _fixture("actor.rearrange")
    _make_item(fx, &"item.test_limit_hand_500", "limit.hand", 500)
    _make_item(fx, &"item.test_limit_inventory_1500", "limit.inventory", 1500)
    var hm: ActorHandEquipmentMutationService = fx["hand_mutations"]
    var cm: InventoryContainmentMutationService = fx["inventory_mutations"]
    _check(hm.set_item("actor.rearrange", Slots.Value.PRIMARY_RIGHT, "limit.hand"), "seed held mass at hard limit")
    _check(cm.set_container("limit.inventory", "actor.rearrange"), "seed contained mass at hard limit")
    _check(int(fx["carry_query"].query("actor.rearrange").get("weight_grams", -1)) == 2000, "fixture is exactly at hard ceiling")

    var drop: ItemTransferActionResult = fx["service"].request_drop_from_hand(
        "actor.rearrange",
        Slots.Value.PRIMARY_RIGHT
    )
    _check(drop.is_accepted(), "dropping remains legal at hard ceiling")
    _run(fx)
    _check(fx["world"].has_placement("limit.hand"), "drop reduces personal carried mass")

func _on_reentrant_world_changed(change: WorldChange) -> void:
    if _reentrant_triggered or change == null or change.entity_id != _reentrant_target_id:
        return
    if _reentrant_containment_mutations == null:
        return
    if change.kind != WorldChange.Kind.PLACEMENT_REMOVED:
        return
    _reentrant_triggered = true
    _check(
        _reentrant_containment_mutations.set_container(_reentrant_extra_id, _reentrant_actor_id),
        "reentrant callback adds extra carried mass"
    )

func _clear_reentrant_hook() -> void:
    _reentrant_target_id = ""
    _reentrant_extra_id = ""
    _reentrant_actor_id = ""
    _reentrant_containment_mutations = null
    _reentrant_triggered = false

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
