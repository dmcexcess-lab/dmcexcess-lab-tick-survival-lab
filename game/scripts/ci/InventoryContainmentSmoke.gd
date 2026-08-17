extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const InventoryStateClass = preload("res://scripts/simulation/inventory/InventoryContainmentState.gd")
const InventoryMutationClass = preload("res://scripts/simulation/inventory/InventoryContainmentMutationService.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")

var failures: Array[String] = []
var signal_log: Array[String] = []
var reset_count: int = 0

func _initialize() -> void:
    _test_enrollment_reads_and_basic_containment()
    _test_transfer_versions_and_signal_order()
    _test_nested_containers_and_cycles()
    _test_world_validation_and_stale_cleanup()
    _test_lifecycle_version_freshness()
    _test_snapshot_restore_and_atomic_rejection()

    if failures.is_empty():
        print("INVENTORY_CONTAINMENT_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("INVENTORY_CONTAINMENT_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture() -> Dictionary:
    var world := WorldStateClass.new()
    var world_mutations := WorldMutationClass.new(world)
    var state := InventoryStateClass.new()
    var mutations := InventoryMutationClass.new(state, world)
    return {
        "world": world,
        "world_mutations": world_mutations,
        "state": state,
        "mutations": mutations,
    }

func _create(world_mutations: WorldMutationService, semantic: StringName, id: String) -> void:
    _check(world_mutations.create_entity(semantic, id) == id, "create %s" % id)

func _test_enrollment_reads_and_basic_containment() -> void:
    var fx: Dictionary = _fixture()
    var world_mutations: WorldMutationService = fx["world_mutations"]
    var state: InventoryContainmentState = fx["state"]
    var mutations: InventoryContainmentMutationService = fx["mutations"]

    _create(world_mutations, &"actor.survivor", "actor_z")
    _create(world_mutations, &"fixture.cabinet", "cabinet_a")
    _create(world_mutations, &"item.backpack", "bag_m")
    _create(world_mutations, &"item.flashlight", "item_z")
    _create(world_mutations, &"item.pistol", "item_a")

    _check(mutations.enroll_container("actor_z"), "explicit survivor container enrollment")
    _check(mutations.enroll_container("cabinet_a"), "explicit fixture container enrollment")
    _check(mutations.enroll_container("bag_m"), "explicit item-container enrollment")
    _check(not mutations.enroll_container("actor_z"), "duplicate enrollment rejected")
    _check(not mutations.enroll_container("missing_container"), "missing container enrollment rejected")
    _check(state.container_ids() == ["actor_z", "bag_m", "cabinet_a"], "container IDs sorted")

    var copied: InventoryContainerRecord = state.container("actor_z")
    _check(copied != null, "container record readable")
    if copied != null:
        copied.version = 999
        _check(state.container_version("actor_z") != 999, "container record read is copy-safe")

    _check(mutations.set_container("item_z", "actor_z"), "item enters actor inventory")
    _check(mutations.set_container("item_a", "actor_z"), "second item enters actor inventory")
    _check(state.container_of("item_z") == "actor_z", "O(1)-style parent lookup returns actor")
    _check(state.is_contained("item_z"), "contained flag true")
    _check(state.contains_directly("actor_z", "item_z"), "direct containment query true")
    _check(state.direct_contents("actor_z") == ["item_a", "item_z"], "direct contents sorted by item ID")

    var revision_before: int = state.revision()
    var version_before: int = state.container_version("actor_z")
    _check(mutations.set_container("item_z", "actor_z"), "same-parent assignment is successful no-op")
    _check(state.revision() == revision_before, "same-parent no-op preserves revision")
    _check(state.container_version("actor_z") == version_before, "same-parent no-op preserves container version")
    _check(not mutations.remove_container("actor_z"), "non-empty container cannot be removed")

    _check(mutations.clear_container("item_z"), "item can leave containment")
    _check(not state.is_contained("item_z"), "cleared item no longer contained")
    _check(state.direct_contents("actor_z") == ["item_a"], "reverse contents index updates after clear")

func _test_transfer_versions_and_signal_order() -> void:
    var fx: Dictionary = _fixture()
    var world_mutations: WorldMutationService = fx["world_mutations"]
    var state: InventoryContainmentState = fx["state"]
    var mutations: InventoryContainmentMutationService = fx["mutations"]

    _create(world_mutations, &"actor.survivor", "actor_a")
    _create(world_mutations, &"fixture.locker", "locker_b")
    _create(world_mutations, &"item.hammer", "item_h")
    _check(mutations.enroll_container("actor_a"), "transfer source enrolled")
    _check(mutations.enroll_container("locker_b"), "transfer destination enrolled")
    _check(mutations.set_container("item_h", "actor_a"), "seed source containment")

    var source_before: int = state.container_version("actor_a")
    var dest_before: int = state.container_version("locker_b")
    signal_log.clear()
    state.item_containment_changed.connect(_on_item_containment_changed)
    state.container_contents_changed.connect(_on_container_contents_changed)

    _check(mutations.set_container("item_h", "locker_b"), "atomic A to B transfer")
    _check(state.container_of("item_h") == "locker_b", "transfer changes direct parent")
    _check(state.direct_contents("actor_a").is_empty(), "transfer removes source reverse membership")
    _check(state.direct_contents("locker_b") == ["item_h"], "transfer adds destination reverse membership")
    _check(state.container_version("actor_a") == source_before + 1, "transfer increments source version")
    _check(state.container_version("locker_b") == dest_before + 1, "transfer increments destination version")
    _check(signal_log.size() == 3, "transfer emits one relation plus two contents signals")
    if signal_log.size() == 3:
        _check(signal_log[0].begins_with("item:item_h:actor_a:locker_b"), "relation signal emits first")
        _check(signal_log[1].begins_with("contents:actor_a:"), "source contents signal emits second")
        _check(signal_log[2].begins_with("contents:locker_b:"), "destination contents signal emits third")

func _test_nested_containers_and_cycles() -> void:
    var fx: Dictionary = _fixture()
    var world_mutations: WorldMutationService = fx["world_mutations"]
    var state: InventoryContainmentState = fx["state"]
    var mutations: InventoryContainmentMutationService = fx["mutations"]

    _create(world_mutations, &"actor.survivor", "actor_root")
    _create(world_mutations, &"fixture.cabinet", "cabinet_root")
    _create(world_mutations, &"item.backpack", "bag_a")
    _create(world_mutations, &"item.backpack", "bag_b")
    _create(world_mutations, &"item.flashlight", "light_x")
    for container_id: String in ["actor_root", "cabinet_root", "bag_a", "bag_b"]:
        _check(mutations.enroll_container(container_id), "nested container enrollment %s" % container_id)

    _check(mutations.set_container("light_x", "bag_a"), "item inside backpack")
    var bag_contents_version: int = state.container_version("bag_a")
    _check(mutations.set_container("bag_a", "actor_root"), "backpack inside survivor inventory")
    _check(state.container_version("bag_a") == bag_contents_version, "moving container item does not change its direct-contents version")
    _check(mutations.set_container("bag_a", "cabinet_root"), "container item can move between parents")
    _check(state.container_version("bag_a") == bag_contents_version, "second parent move still preserves contained-object version")

    _check(mutations.set_container("bag_b", "bag_a"), "nested item-container accepted")
    var before_cycle: Dictionary = state.snapshot()
    _check(not mutations.set_container("bag_a", "bag_b"), "two-node ancestry cycle rejected")
    _check(state.snapshot() == before_cycle, "cycle rejection leaves state unchanged")
    _check(not mutations.set_container("bag_a", "bag_a"), "self-containment rejected")

func _test_world_validation_and_stale_cleanup() -> void:
    var fx: Dictionary = _fixture()
    var world: WorldState = fx["world"]
    var world_mutations: WorldMutationService = fx["world_mutations"]
    var state: InventoryContainmentState = fx["state"]
    var mutations: InventoryContainmentMutationService = fx["mutations"]

    _create(world_mutations, &"fixture.cabinet", "cabinet_v")
    _create(world_mutations, &"item.pistol", "item_ok")
    _create(world_mutations, &"item.shotgun", "item_placed")
    _create(world_mutations, &"prop.trash", "not_item")
    _check(mutations.enroll_container("cabinet_v"), "validation container enrolled")

    _check(world_mutations.set_placement(
        "item_placed",
        Layers.Channel.LOOSE_ITEM,
        Vector2i(2, 3),
        Facing.Value.NORTH,
        Footprint.single_cell()
    ), "placed loose item fixture")
    _check(not mutations.set_container("item_placed", "cabinet_v"), "tactically placed item rejected")
    _check(not mutations.set_container("not_item", "cabinet_v"), "non-item child rejected")
    _check(not mutations.set_container("missing_item", "cabinet_v"), "missing item rejected")

    _check(mutations.set_container("item_ok", "cabinet_v"), "valid unplaced item accepted")
    _check(world_mutations.remove_entity("item_ok"), "delete contained WHAT item for stale cleanup test")
    _check(not world.has_entity("item_ok"), "WHAT item really deleted")
    _check(mutations.clear_container("item_ok"), "stale containment can be explicitly cleared after WHAT deletion")

    _check(world_mutations.remove_entity("cabinet_v"), "delete now-empty WHAT container")
    _check(mutations.remove_container("cabinet_v"), "empty stale container capability can be removed after WHAT deletion")

func _test_lifecycle_version_freshness() -> void:
    var fx: Dictionary = _fixture()
    var world_mutations: WorldMutationService = fx["world_mutations"]
    var state: InventoryContainmentState = fx["state"]
    var mutations: InventoryContainmentMutationService = fx["mutations"]

    _create(world_mutations, &"fixture.trunk", "trunk_a")
    _check(mutations.enroll_container("trunk_a"), "lifecycle container enrolled")
    var first_version: int = state.container_version("trunk_a")
    _check(mutations.remove_container("trunk_a"), "empty container unenrolled")
    _check(mutations.enroll_container("trunk_a"), "same ID re-enrolled")
    _check(state.container_version("trunk_a") > first_version, "re-enrollment receives fresh monotonic version")

func _test_snapshot_restore_and_atomic_rejection() -> void:
    var fx: Dictionary = _fixture()
    var world_mutations: WorldMutationService = fx["world_mutations"]
    var state: InventoryContainmentState = fx["state"]
    var mutations: InventoryContainmentMutationService = fx["mutations"]

    _create(world_mutations, &"actor.survivor", "actor_s")
    _create(world_mutations, &"item.backpack", "bag_s")
    _create(world_mutations, &"item.flashlight", "light_s")
    _check(mutations.enroll_container("actor_s"), "snapshot actor enrolled")
    _check(mutations.enroll_container("bag_s"), "snapshot bag enrolled")
    _check(mutations.set_container("bag_s", "actor_s"), "snapshot bag relation")
    _check(mutations.set_container("light_s", "bag_s"), "snapshot nested relation")

    var saved: Dictionary = state.snapshot()
    var restored := InventoryStateClass.new()
    reset_count = 0
    restored.containment_reset.connect(_on_containment_reset)
    _check(restored.load_snapshot(saved), "snapshot round-trip load succeeds")
    _check(reset_count == 1, "successful restore emits exactly one reset")
    _check(restored.snapshot() == saved, "snapshot round-trip deterministic")
    _check(restored.container_ids() == ["actor_s", "bag_s"], "restored containers sorted")
    _check(restored.direct_contents("actor_s") == ["bag_s"], "restored reverse index actor contents")
    _check(restored.direct_contents("bag_s") == ["light_s"], "restored reverse index nested contents")

    var baseline: Dictionary = restored.snapshot()

    var duplicate_relation: Dictionary = saved.duplicate(true)
    var duplicate_relations: Array = duplicate_relation["relations"]
    duplicate_relations.append(duplicate_relations[0].duplicate(true))
    duplicate_relation["relations"] = duplicate_relations
    _check(not restored.load_snapshot(duplicate_relation), "duplicate item relation snapshot rejected")
    _check(restored.snapshot() == baseline, "duplicate relation rejection atomic")

    var duplicate_container: Dictionary = saved.duplicate(true)
    var duplicate_containers: Array = duplicate_container["containers"]
    duplicate_containers.append(duplicate_containers[0].duplicate(true))
    duplicate_container["containers"] = duplicate_containers
    _check(not restored.load_snapshot(duplicate_container), "duplicate container snapshot rejected")
    _check(restored.snapshot() == baseline, "duplicate container rejection atomic")

    var cyclic: Dictionary = {
        "schema_version": 1,
        "revision": 4,
        "containers": [
            {"container_id": "bag_a", "version": 1},
            {"container_id": "bag_b", "version": 2},
        ],
        "relations": [
            {"item_id": "bag_a", "container_id": "bag_b"},
            {"item_id": "bag_b", "container_id": "bag_a"},
        ],
    }
    _check(not restored.load_snapshot(cyclic), "cyclic candidate snapshot rejected")
    _check(restored.snapshot() == baseline, "cyclic rejection atomic")

    var bad_version: Dictionary = saved.duplicate(true)
    var bad_containers: Array = bad_version["containers"]
    bad_containers[0]["version"] = int(bad_version["revision"]) + 1
    bad_version["containers"] = bad_containers
    _check(not restored.load_snapshot(bad_version), "container version beyond revision rejected")
    _check(restored.snapshot() == baseline, "bad-version rejection atomic")
    _check(reset_count == 1, "failed restores emit no reset")

func _on_item_containment_changed(item_id: String, previous_container_id: String, new_container_id: String) -> void:
    signal_log.append("item:%s:%s:%s" % [item_id, previous_container_id, new_container_id])

func _on_container_contents_changed(container_id: String, version: int) -> void:
    signal_log.append("contents:%s:%d" % [container_id, version])

func _on_containment_reset() -> void:
    reset_count += 1

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
