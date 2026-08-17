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
const ActionTypes = preload("res://scripts/simulation/items/transfer/ItemTransferActionType.gd")
const DispositionResult = preload("res://scripts/simulation/items/transfer/ItemDispositionResult.gd")
const DispositionQueryClass = preload("res://scripts/simulation/items/transfer/ItemDispositionQuery.gd")
const TimingPolicyClass = preload("res://scripts/simulation/items/transfer/ItemTransferTimingPolicy.gd")
const ActionResult = preload("res://scripts/simulation/items/transfer/ItemTransferActionResult.gd")
const TransferServiceClass = preload("res://scripts/simulation/items/transfer/ItemTransferActionService.gd")

const TEST_TICKS: int = 5

var failures: Array[String] = []
var _comp_world_mutations: WorldMutationService = null
var _comp_hand_mutations: ActorHandEquipmentMutationService = null
var _comp_actor_id: String = ""
var _comp_trigger_item_id: String = ""
var _comp_blocker_item_id: String = ""
var _comp_remove_trigger: bool = false
var _comp_triggered: bool = false

func _initialize() -> void:
    _test_disposition_query()
    _test_personal_access_and_reach()
    _test_transition_paths()
    _test_timing_and_revalidation()
    _test_no_reservation_race()
    _test_compensation()
    if failures.is_empty():
        print("ITEM_TRANSFER_ACTIONS_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("ITEM_TRANSFER_ACTIONS_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture(register_all: bool = true) -> Dictionary:
    var world := WorldStateClass.new()
    var world_mutations := WorldMutationClass.new(world)
    var hands := HandStateClass.new()
    var hand_mutations := HandMutationClass.new(hands, world)
    var containment := InventoryStateClass.new()
    var containment_mutations := InventoryMutationClass.new(containment, world)
    var kernel := TickKernelClass.new()
    var policy := TimingPolicyClass.new()
    if register_all:
        for action_type: StringName in ActionTypes.ALL:
            _check(policy.register_duration(action_type, TEST_TICKS), "register duration %s" % String(action_type))
    var disposition := DispositionQueryClass.new(world, hands, containment)
    var service := TransferServiceClass.new(
        world, world_mutations, hands, hand_mutations,
        containment, containment_mutations, kernel, policy, disposition
    )
    return {
        "world": world,
        "world_mutations": world_mutations,
        "hands": hands,
        "hand_mutations": hand_mutations,
        "containment": containment,
        "containment_mutations": containment_mutations,
        "kernel": kernel,
        "policy": policy,
        "disposition": disposition,
        "service": service,
    }

func _create(world_mutations: WorldMutationService, semantic: StringName, entity_id: String) -> void:
    _check(world_mutations.create_entity(semantic, entity_id) == entity_id, "create %s" % entity_id)

func _create_actor(fx: Dictionary, actor_id: String, anchor: Vector2i, facing: int = Facing.Value.EAST) -> void:
    var world_mutations: WorldMutationService = fx["world_mutations"]
    var hand_mutations: ActorHandEquipmentMutationService = fx["hand_mutations"]
    var containment_mutations: InventoryContainmentMutationService = fx["containment_mutations"]
    _create(world_mutations, &"actor.survivor", actor_id)
    _check(world_mutations.set_placement(actor_id, Layers.Channel.ACTOR, anchor, facing, Footprint.single_cell()), "place %s" % actor_id)
    _check(hand_mutations.enroll_actor(actor_id), "hand enroll %s" % actor_id)
    _check(containment_mutations.enroll_container(actor_id), "inventory enroll %s" % actor_id)

func _create_loose(fx: Dictionary, item_id: String, semantic: StringName, anchor: Vector2i) -> void:
    var world_mutations: WorldMutationService = fx["world_mutations"]
    _create(world_mutations, semantic, item_id)
    _check(world_mutations.set_placement(
        item_id, Layers.Channel.LOOSE_ITEM, anchor, Facing.Value.NORTH, Footprint.single_cell()
    ), "place loose %s" % item_id)

func _create_container_item(fx: Dictionary, item_id: String, parent_id: String = "") -> void:
    var world_mutations: WorldMutationService = fx["world_mutations"]
    var containment_mutations: InventoryContainmentMutationService = fx["containment_mutations"]
    _create(world_mutations, &"item.backpack", item_id)
    _check(containment_mutations.enroll_container(item_id), "container item enroll %s" % item_id)
    if not parent_id.is_empty():
        _check(containment_mutations.set_container(item_id, parent_id), "contain %s in %s" % [item_id, parent_id])

func _run(fx: Dictionary) -> int:
    var kernel: TickKernel = fx["kernel"]
    return kernel.run_until_stop()

func _test_disposition_query() -> void:
    var fx: Dictionary = _fixture()
    var wm: WorldMutationService = fx["world_mutations"]
    var hm: ActorHandEquipmentMutationService = fx["hand_mutations"]
    var cm: InventoryContainmentMutationService = fx["containment_mutations"]
    var query: ItemDispositionQuery = fx["disposition"]
    _create_actor(fx, "actor_q", Vector2i(5, 5))
    _create_loose(fx, "q_loose", &"item.flashlight", Vector2i(6, 5))
    _create(wm, &"item.pistol", "q_hand")
    _check(hm.set_item("actor_q", Slots.Value.PRIMARY_RIGHT, "q_hand"), "seed hand")
    _create(wm, &"item.hammer", "q_contained")
    _check(cm.set_container("q_contained", "actor_q"), "seed contained")
    _create(wm, &"item.bandage", "q_unclaimed")
    _create(wm, &"item.tool", "q_invalid")
    _check(wm.set_placement("q_invalid", Layers.Channel.OBJECT, Vector2i(9, 9), Facing.Value.NORTH, Footprint.single_cell()), "invalid placement seed")
    _create(wm, &"item.knife", "q_conflict")
    _check(hm.set_item("actor_q", Slots.Value.SECONDARY_LEFT, "q_conflict"), "conflict hand seed")
    _check(cm.set_container("q_conflict", "actor_q"), "conflict containment seed")
    _create(wm, &"prop.rock", "q_not_item")
    _check(query.query("q_loose").status == DispositionResult.Status.LOOSE_WORLD, "disposition loose")
    var held: ItemDispositionResult = query.query("q_hand")
    _check(held.status == DispositionResult.Status.HAND and held.actor_id == "actor_q", "disposition hand")
    _check(query.query("q_contained").status == DispositionResult.Status.CONTAINED, "disposition contained")
    _check(query.query("q_unclaimed").status == DispositionResult.Status.UNCLAIMED, "disposition unclaimed")
    _check(query.query("q_invalid").status == DispositionResult.Status.INVALID_PLACEMENT, "disposition invalid placement")
    _check(query.query("q_conflict").status == DispositionResult.Status.CONFLICT, "disposition conflict")
    _check(query.query("missing").status == DispositionResult.Status.UNKNOWN, "disposition missing")
    _check(query.query("q_not_item").reason == "not_item", "disposition non-item")

func _test_personal_access_and_reach() -> void:
    var fx: Dictionary = _fixture()
    var wm: WorldMutationService = fx["world_mutations"]
    var hm: ActorHandEquipmentMutationService = fx["hand_mutations"]
    var cm: InventoryContainmentMutationService = fx["containment_mutations"]
    var kernel: TickKernel = fx["kernel"]
    var service: ItemTransferActionService = fx["service"]
    _create_actor(fx, "actor_access", Vector2i(5, 5), Facing.Value.EAST)
    _create_container_item(fx, "bag_root", "actor_access")
    _create_container_item(fx, "pouch_nested", "bag_root")
    _create_container_item(fx, "bag_held")
    _check(hm.set_item("actor_access", Slots.Value.PRIMARY_RIGHT, "bag_held"), "held backpack")
    _create_container_item(fx, "pouch_held", "bag_held")
    _create(wm, &"fixture.cabinet", "cabinet_world")
    _check(cm.enroll_container("cabinet_world"), "world cabinet enroll")

    _create_loose(fx, "reach_feet", &"item.bandage", Vector2i(5, 5))
    var feet: ItemTransferActionResult = service.request_pickup_to_container("actor_access", "reach_feet", "pouch_nested")
    _check(feet.is_accepted(), "feet pickup into nested personal container")
    _check(kernel.cancel_action(feet.action_serial, "test"), "cancel feet pickup")

    _create_loose(fx, "reach_front", &"item.flashlight", Vector2i(6, 5))
    var front: ItemTransferActionResult = service.request_pickup_to_container("actor_access", "reach_front", "pouch_held")
    _check(front.is_accepted(), "front pickup into nested held container")
    _check(kernel.cancel_action(front.action_serial, "test"), "cancel front pickup")

    _create_loose(fx, "reach_cabinet", &"item.hammer", Vector2i(6, 5))
    var cabinet: ItemTransferActionResult = service.request_pickup_to_container("actor_access", "reach_cabinet", "cabinet_world")
    _check(cabinet.status == ActionResult.Status.CONTAINER_INACCESSIBLE, "world cabinet inaccessible")
    _create_loose(fx, "reach_far", &"item.knife", Vector2i(7, 5))
    var far: ItemTransferActionResult = service.request_pickup_to_container("actor_access", "reach_far", "actor_access")
    _check(far.status == ActionResult.Status.OUT_OF_REACH, "far pickup rejected")
    _check(kernel.world_tick() == 0, "rejected reach/access spends zero ticks")

func _test_transition_paths() -> void:
    var fx: Dictionary = _fixture()
    var world: WorldState = fx["world"]
    var wm: WorldMutationService = fx["world_mutations"]
    var hands: ActorHandEquipmentState = fx["hands"]
    var hm: ActorHandEquipmentMutationService = fx["hand_mutations"]
    var containment: InventoryContainmentState = fx["containment"]
    var cm: InventoryContainmentMutationService = fx["containment_mutations"]
    var kernel: TickKernel = fx["kernel"]
    var service: ItemTransferActionService = fx["service"]
    _create_actor(fx, "actor_paths", Vector2i(4, 4), Facing.Value.EAST)
    _create_container_item(fx, "bag_a", "actor_paths")
    _create_container_item(fx, "bag_b", "actor_paths")

    _create_loose(fx, "path_wc", &"item.flashlight", Vector2i(5, 4))
    var wc: ItemTransferActionResult = service.request_pickup_to_container("actor_paths", "path_wc", "bag_a")
    _check(wc.is_accepted() and world.has_placement("path_wc"), "world-container waits for commit")
    _run(fx)
    _check(containment.container_of("path_wc") == "bag_a" and not world.has_placement("path_wc"), "world-container commit")
    _check(kernel.world_tick() == TEST_TICKS, "explicit transfer duration exact")

    _create_loose(fx, "path_wh", &"item.pistol", Vector2i(5, 4))
    var wh: ItemTransferActionResult = service.request_pickup_to_hand("actor_paths", "path_wh", Slots.Value.PRIMARY_RIGHT)
    _check(wh.is_accepted(), "world-hand accepted")
    _run(fx)
    _check(hands.primary_item("actor_paths") == "path_wh" and not world.has_placement("path_wh"), "world-hand commit")

    var hw: ItemTransferActionResult = service.request_drop_from_hand("actor_paths", Slots.Value.PRIMARY_RIGHT)
    _check(hw.is_accepted(), "hand-world accepted")
    _run(fx)
    var hw_placement: WorldPlacement = world.placement("path_wh")
    _check(hands.primary_item("actor_paths").is_empty(), "hand-world clears hand")
    _check(hw_placement != null and hw_placement.anchor == Vector2i(4, 4) and hw_placement.footprint.cell_count() == 1, "hand-world drops single cell at feet")

    _create(wm, &"item.knife", "path_ch")
    _check(cm.set_container("path_ch", "bag_a"), "seed container-hand")
    _create(wm, &"item.lantern", "occupied")
    _check(hm.set_item("actor_paths", Slots.Value.SECONDARY_LEFT, "occupied"), "occupy secondary")
    var occupied: ItemTransferActionResult = service.request_equip_from_container("actor_paths", "path_ch", Slots.Value.SECONDARY_LEFT)
    _check(occupied.status == ActionResult.Status.HAND_OCCUPIED and containment.container_of("path_ch") == "bag_a", "occupied hand rejects without swap")
    var ch: ItemTransferActionResult = service.request_equip_from_container("actor_paths", "path_ch", Slots.Value.PRIMARY_RIGHT)
    _check(ch.is_accepted(), "container-hand accepted")
    _run(fx)
    _check(hands.primary_item("actor_paths") == "path_ch" and not containment.is_contained("path_ch"), "container-hand commit")

    var hc: ItemTransferActionResult = service.request_unequip_to_container("actor_paths", Slots.Value.PRIMARY_RIGHT, "bag_b")
    _check(hc.is_accepted(), "hand-container accepted")
    _run(fx)
    _check(hands.primary_item("actor_paths").is_empty() and containment.container_of("path_ch") == "bag_b", "hand-container commit")

    var cc: ItemTransferActionResult = service.request_transfer_container("actor_paths", "path_ch", "bag_a")
    _check(cc.is_accepted(), "container-container accepted")
    _run(fx)
    _check(containment.container_of("path_ch") == "bag_a", "container-container commit")

    var cw: ItemTransferActionResult = service.request_drop_from_container("actor_paths", "path_ch")
    _check(cw.is_accepted(), "container-world accepted")
    _run(fx)
    var cw_placement: WorldPlacement = world.placement("path_ch")
    _check(not containment.is_contained("path_ch") and cw_placement != null and cw_placement.anchor == Vector2i(4, 4), "container-world commit at feet")

    _create_container_item(fx, "bag_parent", "actor_paths")
    _create_container_item(fx, "bag_child", "bag_parent")
    var before_cycle: int = kernel.world_tick()
    var cycle: ItemTransferActionResult = service.request_transfer_container("actor_paths", "bag_parent", "bag_child")
    _check(cycle.status == ActionResult.Status.CONTAINER_REJECTED and kernel.world_tick() == before_cycle, "containment cycle rejected before ticks")

func _test_timing_and_revalidation() -> void:
    _test_timing_unclassified()
    _test_cancel_and_hard_pause()
    _test_actor_and_source_stale()
    _test_hand_and_container_stale()
    _test_access_lost()

func _test_timing_unclassified() -> void:
    var fx: Dictionary = _fixture(false)
    var kernel: TickKernel = fx["kernel"]
    var service: ItemTransferActionService = fx["service"]
    _create_actor(fx, "actor_tu", Vector2i(2, 2))
    _create_loose(fx, "item_tu", &"item.flashlight", Vector2i(3, 2))
    var result: ItemTransferActionResult = service.request_pickup_to_container("actor_tu", "item_tu", "actor_tu")
    _check(result.status == ActionResult.Status.TIMING_UNCLASSIFIED, "timing unclassified rejected")
    _check(kernel.world_tick() == 0 and not kernel.has_active_action("actor_tu"), "timing rejection no ticks")

func _test_cancel_and_hard_pause() -> void:
    var fx: Dictionary = _fixture()
    var world: WorldState = fx["world"]
    var containment: InventoryContainmentState = fx["containment"]
    var kernel: TickKernel = fx["kernel"]
    var service: ItemTransferActionService = fx["service"]
    _create_actor(fx, "actor_cancel", Vector2i(2, 2))
    _create_loose(fx, "item_cancel", &"item.flashlight", Vector2i(3, 2))
    _check(kernel.schedule_event(2, "test", &"interrupt_point") > 0, "schedule mid action event")
    var cancel: ItemTransferActionResult = service.request_pickup_to_container("actor_cancel", "item_cancel", "actor_cancel")
    _check(cancel.is_accepted(), "cancelable transfer accepted")
    _check(kernel.run_next_batch() == TickRules.RunStopReason.BATCH_COMPLETE and kernel.world_tick() == 2, "partial action spends elapsed ticks")
    _check(kernel.interrupt_action(cancel.action_serial, "damage") == TickRules.ActionStatus.CANCELED, "transfer uses cancelable policy")
    _check(world.has_placement("item_cancel") and not containment.is_contained("item_cancel"), "canceled transfer leaves source unchanged")

    var pause_fx: Dictionary = _fixture()
    var pause_world: WorldState = pause_fx["world"]
    var pause_containment: InventoryContainmentState = pause_fx["containment"]
    var pause_kernel: TickKernel = pause_fx["kernel"]
    var pause_service: ItemTransferActionService = pause_fx["service"]
    _create_actor(pause_fx, "actor_pause", Vector2i(2, 2))
    _create_loose(pause_fx, "item_pause", &"item.flashlight", Vector2i(3, 2))
    var paused: ItemTransferActionResult = pause_service.request_pickup_to_container("actor_pause", "item_pause", "actor_pause")
    _check(paused.is_accepted(), "hard-pause transfer accepted")
    pause_kernel.set_hard_paused(true)
    _check(pause_kernel.run_until_stop() == TickRules.RunStopReason.HARD_PAUSED, "hard pause stops kernel")
    _check(pause_kernel.world_tick() == 0 and pause_world.has_placement("item_pause"), "hard pause zero ticks")
    pause_kernel.set_hard_paused(false)
    _run(pause_fx)
    _check(pause_containment.container_of("item_pause") == "actor_pause" and pause_kernel.world_tick() == TEST_TICKS, "hard-pause transfer resumes unchanged")

func _test_actor_and_source_stale() -> void:
    var fx: Dictionary = _fixture()
    var world: WorldState = fx["world"]
    var wm: WorldMutationService = fx["world_mutations"]
    var service: ItemTransferActionService = fx["service"]
    _create_actor(fx, "actor_stale", Vector2i(2, 2), Facing.Value.EAST)
    _create_loose(fx, "item_actor_stale", &"item.flashlight", Vector2i(3, 2))
    var actor_action: ItemTransferActionResult = service.request_pickup_to_container("actor_stale", "item_actor_stale", "actor_stale")
    _check(actor_action.is_accepted(), "actor-stale accepted")
    _check(wm.set_placement("actor_stale", Layers.Channel.ACTOR, Vector2i(2, 2), Facing.Value.SOUTH, Footprint.single_cell()), "change actor facing")
    _run(fx)
    _check(world.has_placement("item_actor_stale"), "actor placement/facing stale prevents commit")

    var source_fx: Dictionary = _fixture()
    var source_world: WorldState = source_fx["world"]
    var source_wm: WorldMutationService = source_fx["world_mutations"]
    var source_service: ItemTransferActionService = source_fx["service"]
    _create_actor(source_fx, "actor_source", Vector2i(2, 2), Facing.Value.EAST)
    _create_loose(source_fx, "item_source", &"item.flashlight", Vector2i(3, 2))
    var source_action: ItemTransferActionResult = source_service.request_pickup_to_container("actor_source", "item_source", "actor_source")
    _check(source_action.is_accepted(), "source-stale accepted")
    _check(source_wm.set_placement("item_source", Layers.Channel.LOOSE_ITEM, Vector2i(2, 2), Facing.Value.NORTH, Footprint.single_cell()), "move loose source")
    _run(source_fx)
    var placement: WorldPlacement = source_world.placement("item_source")
    _check(placement != null and placement.anchor == Vector2i(2, 2), "loose placement snapshot stale prevents commit")

func _test_hand_and_container_stale() -> void:
    var fx: Dictionary = _fixture()
    var wm: WorldMutationService = fx["world_mutations"]
    var hands: ActorHandEquipmentState = fx["hands"]
    var hm: ActorHandEquipmentMutationService = fx["hand_mutations"]
    var containment: InventoryContainmentState = fx["containment"]
    var cm: InventoryContainmentMutationService = fx["containment_mutations"]
    var service: ItemTransferActionService = fx["service"]
    _create_actor(fx, "actor_hand_stale", Vector2i(2, 2))
    _create(wm, &"item.knife", "hand_source")
    _create(wm, &"item.flashlight", "hand_bump")
    _check(cm.set_container("hand_source", "actor_hand_stale"), "seed hand stale source")
    var hand_action: ItemTransferActionResult = service.request_equip_from_container("actor_hand_stale", "hand_source", Slots.Value.PRIMARY_RIGHT)
    _check(hand_action.is_accepted(), "hand stale accepted")
    _check(hm.set_item("actor_hand_stale", Slots.Value.SECONDARY_LEFT, "hand_bump"), "change hand version")
    _run(fx)
    _check(containment.container_of("hand_source") == "actor_hand_stale" and hands.primary_item("actor_hand_stale").is_empty(), "hand version stale prevents equip")

    var src_fx: Dictionary = _fixture()
    var src_wm: WorldMutationService = src_fx["world_mutations"]
    var src_hands: ActorHandEquipmentState = src_fx["hands"]
    var src_containment: InventoryContainmentState = src_fx["containment"]
    var src_cm: InventoryContainmentMutationService = src_fx["containment_mutations"]
    var src_service: ItemTransferActionService = src_fx["service"]
    _create_actor(src_fx, "actor_src_version", Vector2i(2, 2))
    _create_container_item(src_fx, "bag_src", "actor_src_version")
    _create(src_wm, &"item.knife", "src_version_item")
    _create(src_wm, &"item.bandage", "src_version_bump")
    _check(src_cm.set_container("src_version_item", "bag_src"), "seed source version")
    var src_action: ItemTransferActionResult = src_service.request_equip_from_container("actor_src_version", "src_version_item", Slots.Value.PRIMARY_RIGHT)
    _check(src_action.is_accepted(), "source container stale accepted")
    _check(src_cm.set_container("src_version_bump", "bag_src"), "bump source container version")
    _run(src_fx)
    _check(src_containment.container_of("src_version_item") == "bag_src" and src_hands.primary_item("actor_src_version").is_empty(), "source container version stale prevents equip")

    var dst_fx: Dictionary = _fixture()
    var dst_world: WorldState = dst_fx["world"]
    var dst_wm: WorldMutationService = dst_fx["world_mutations"]
    var dst_cm: InventoryContainmentMutationService = dst_fx["containment_mutations"]
    var dst_service: ItemTransferActionService = dst_fx["service"]
    _create_actor(dst_fx, "actor_dst_version", Vector2i(2, 2), Facing.Value.EAST)
    _create_loose(dst_fx, "dst_version_item", &"item.flashlight", Vector2i(3, 2))
    _create(dst_wm, &"item.bandage", "dst_version_bump")
    var dst_action: ItemTransferActionResult = dst_service.request_pickup_to_container("actor_dst_version", "dst_version_item", "actor_dst_version")
    _check(dst_action.is_accepted(), "destination container stale accepted")
    _check(dst_cm.set_container("dst_version_bump", "actor_dst_version"), "bump destination container version")
    _run(dst_fx)
    _check(dst_world.has_placement("dst_version_item"), "destination container version stale prevents pickup")

func _test_access_lost() -> void:
    var fx: Dictionary = _fixture()
    var wm: WorldMutationService = fx["world_mutations"]
    var containment: InventoryContainmentState = fx["containment"]
    var cm: InventoryContainmentMutationService = fx["containment_mutations"]
    var service: ItemTransferActionService = fx["service"]
    _create_actor(fx, "actor_access_lost", Vector2i(2, 2))
    _create_container_item(fx, "bag_access_lost", "actor_access_lost")
    _create(wm, &"item.knife", "access_lost_item")
    _check(cm.set_container("access_lost_item", "bag_access_lost"), "seed access-lost item")
    _create(wm, &"fixture.cabinet", "access_lost_cabinet")
    _check(cm.enroll_container("access_lost_cabinet"), "access-lost cabinet enroll")
    var action: ItemTransferActionResult = service.request_equip_from_container("actor_access_lost", "access_lost_item", Slots.Value.PRIMARY_RIGHT)
    _check(action.is_accepted(), "access-lost action accepted")
    _check(cm.set_container("bag_access_lost", "access_lost_cabinet"), "move source ancestry out of personal access")
    _run(fx)
    _check(containment.container_of("access_lost_item") == "bag_access_lost", "lost personal ancestry prevents commit")

func _test_no_reservation_race() -> void:
    var fx: Dictionary = _fixture()
    var hands: ActorHandEquipmentState = fx["hands"]
    var kernel: TickKernel = fx["kernel"]
    var service: ItemTransferActionService = fx["service"]
    _create_actor(fx, "actor_a", Vector2i(5, 5), Facing.Value.EAST)
    _create_actor(fx, "actor_b", Vector2i(5, 5), Facing.Value.EAST)
    _create_loose(fx, "race_item", &"item.pistol", Vector2i(6, 5))
    var a: ItemTransferActionResult = service.request_pickup_to_hand("actor_a", "race_item", Slots.Value.PRIMARY_RIGHT)
    var b: ItemTransferActionResult = service.request_pickup_to_hand("actor_b", "race_item", Slots.Value.PRIMARY_RIGHT)
    _check(a.is_accepted() and b.is_accepted(), "no reservation allows concurrent race")
    _run(fx)
    _check(kernel.world_tick() == TEST_TICKS, "race resolves same tick")
    _check(hands.primary_item("actor_a") == "race_item" and hands.primary_item("actor_b").is_empty(), "deterministic first commit wins without duplication")

func _test_compensation() -> void:
    var fx: Dictionary = _fixture()
    var world: WorldState = fx["world"]
    var wm: WorldMutationService = fx["world_mutations"]
    var service: ItemTransferActionService = fx["service"]
    _create_actor(fx, "actor_comp", Vector2i(2, 2), Facing.Value.EAST)
    _create_loose(fx, "comp_item", &"item.pistol", Vector2i(3, 2))
    _create(wm, &"item.flashlight", "comp_blocker")
    _configure_compensation_hook(fx, "actor_comp", "comp_item", "comp_blocker", false)
    world.changed.connect(_on_comp_world_changed)
    var request: ItemTransferActionResult = service.request_pickup_to_hand("actor_comp", "comp_item", Slots.Value.PRIMARY_RIGHT)
    _check(request.is_accepted(), "compensation action accepted")
    _run(fx)
    if world.changed.is_connected(_on_comp_world_changed):
        world.changed.disconnect(_on_comp_world_changed)
    var placement: WorldPlacement = world.placement("comp_item")
    var diagnostics: Array[Dictionary] = service.recent_diagnostics()
    _check(placement != null and placement.anchor == Vector2i(3, 2), "destination failure compensates source placement")
    _check(not diagnostics.is_empty() and String(diagnostics[-1].get("reason", "")) == "destination_mutation_failed_compensated", "compensation diagnostic")
    _clear_compensation_hook()

    var critical_fx: Dictionary = _fixture()
    var critical_world: WorldState = critical_fx["world"]
    var critical_wm: WorldMutationService = critical_fx["world_mutations"]
    var critical_service: ItemTransferActionService = critical_fx["service"]
    _create_actor(critical_fx, "actor_critical", Vector2i(2, 2), Facing.Value.EAST)
    _create_loose(critical_fx, "critical_item", &"item.pistol", Vector2i(3, 2))
    _create(critical_wm, &"item.flashlight", "critical_blocker")
    _configure_compensation_hook(critical_fx, "actor_critical", "critical_item", "critical_blocker", true)
    critical_world.changed.connect(_on_comp_world_changed)
    var critical_request: ItemTransferActionResult = critical_service.request_pickup_to_hand("actor_critical", "critical_item", Slots.Value.PRIMARY_RIGHT)
    _check(critical_request.is_accepted(), "critical compensation action accepted")
    _run(critical_fx)
    if critical_world.changed.is_connected(_on_comp_world_changed):
        critical_world.changed.disconnect(_on_comp_world_changed)
    var critical_diagnostics: Array[Dictionary] = critical_service.recent_diagnostics()
    _check(not critical_world.has_entity("critical_item"), "critical fixture removes source entity")
    _check(not critical_diagnostics.is_empty() \
        and String(critical_diagnostics[-1].get("reason", "")) == "critical_consistency_failure" \
        and bool(critical_diagnostics[-1].get("critical", false)), "failed compensation emits critical diagnostic")
    _clear_compensation_hook()

func _configure_compensation_hook(fx: Dictionary, actor_id: String, trigger_item_id: String, blocker_item_id: String, remove_trigger: bool) -> void:
    _comp_world_mutations = fx["world_mutations"]
    _comp_hand_mutations = fx["hand_mutations"]
    _comp_actor_id = actor_id
    _comp_trigger_item_id = trigger_item_id
    _comp_blocker_item_id = blocker_item_id
    _comp_remove_trigger = remove_trigger
    _comp_triggered = false

func _clear_compensation_hook() -> void:
    _comp_world_mutations = null
    _comp_hand_mutations = null
    _comp_actor_id = ""
    _comp_trigger_item_id = ""
    _comp_blocker_item_id = ""
    _comp_remove_trigger = false
    _comp_triggered = false

func _on_comp_world_changed(change: WorldChange) -> void:
    if _comp_triggered or change == null or change.entity_id != _comp_trigger_item_id:
        return
    _comp_triggered = true
    _check(_comp_hand_mutations.set_item(_comp_actor_id, Slots.Value.PRIMARY_RIGHT, _comp_blocker_item_id), "reentrant blocker occupies hand")
    if _comp_remove_trigger:
        _check(_comp_world_mutations.remove_entity(_comp_trigger_item_id), "reentrant source deletion")

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
