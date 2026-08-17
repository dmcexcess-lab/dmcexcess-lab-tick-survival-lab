extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const DoorMutationClass = preload("res://scripts/simulation/doors/DoorStateMutationService.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")

var failures: Array[String] = []
var enrolled_events: Array[Dictionary] = []
var removed_events: Array[Dictionary] = []
var changed_events: Array[Dictionary] = []
var reset_count: int = 0

func _initialize() -> void:
    _test_explicit_enrollment_and_reads()
    _test_state_mutation_and_unplaced_persistence()
    _test_removal_reenrollment_versioning()
    _test_snapshot_restore_and_atomic_rejection()

    if failures.is_empty():
        print("DOOR_STATE_SMOKE_OK")
        quit(0)
        return

    for failure: String in failures:
        push_error("DOOR_STATE_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture() -> Dictionary:
    var world := WorldStateClass.new()
    var world_mutations := WorldMutationClass.new(world)
    var state := DoorStateClass.new()
    var mutations := DoorMutationClass.new(state, world)
    return {
        "world": world,
        "world_mutations": world_mutations,
        "state": state,
        "mutations": mutations,
    }

func _test_explicit_enrollment_and_reads() -> void:
    enrolled_events.clear()
    var fixture: Dictionary = _fixture()
    var world_mutations: WorldMutationService = fixture["world_mutations"]
    var state: DoorStateStore = fixture["state"]
    var mutations: DoorStateMutationService = fixture["mutations"]
    state.door_enrolled.connect(_on_enrolled)

    _check(state.state("door.missing") == DoorValue.UNKNOWN, "missing record returns UNKNOWN")
    _check(state.version("door.missing") == 0, "missing record version is zero")
    _check(not state.has_door("door.missing"), "missing record is not enrolled")

    _check(not world_mutations.create_entity(&"door.house", "door.a").is_empty(), "create door entity")
    _check(not world_mutations.create_entity(&"object.chair", "chair.a").is_empty(), "create non-door entity")

    _check(mutations.enroll("door.a", DoorValue.CLOSED), "explicit CLOSED enrollment succeeds")
    _check(state.has_door("door.a"), "enrolled door is present")
    _check(state.state("door.a") == DoorValue.CLOSED, "enrolled state is CLOSED")
    _check(state.version("door.a") == 1, "first enrollment version is positive")
    _check(state.revision() == 1, "enrollment increments store revision")
    _check(enrolled_events.size() == 1, "enrollment emits exactly one signal")
    if enrolled_events.size() == 1:
        _check(enrolled_events[0]["state"] == DoorValue.CLOSED, "enrollment signal carries explicit state")
        _check(int(enrolled_events[0]["version"]) == 1, "enrollment signal carries version")

    _check(not mutations.enroll("door.a", DoorValue.OPEN), "duplicate enrollment rejected")
    _check(not mutations.enroll("missing.door", DoorValue.CLOSED), "missing WHAT entity enrollment rejected")
    _check(not mutations.enroll("chair.a", DoorValue.CLOSED), "non-door WHAT entity enrollment rejected")
    _check(not mutations.enroll("door.a", DoorValue.UNKNOWN), "UNKNOWN cannot be persisted")

    var copy: DoorStateRecord = state.record("door.a")
    _check(copy != null, "record read returns copy")
    if copy != null:
        copy.state = DoorValue.OPEN
        copy.version = 999
    _check(state.state("door.a") == DoorValue.CLOSED and state.version("door.a") == 1, "record copy cannot mutate canonical state")

func _test_state_mutation_and_unplaced_persistence() -> void:
    changed_events.clear()
    var fixture: Dictionary = _fixture()
    var world_mutations: WorldMutationService = fixture["world_mutations"]
    var state: DoorStateStore = fixture["state"]
    var mutations: DoorStateMutationService = fixture["mutations"]
    state.door_state_changed.connect(_on_changed)

    world_mutations.create_entity(&"door.store", "door.store.a")
    _check(mutations.enroll("door.store.a", DoorValue.OPEN), "explicit OPEN enrollment succeeds")
    var before_revision: int = state.revision()
    var before_version: int = state.version("door.store.a")
    _check(mutations.set_state("door.store.a", DoorValue.OPEN), "same-state mutation accepted")
    _check(state.revision() == before_revision, "same-state mutation does not change revision")
    _check(state.version("door.store.a") == before_version, "same-state mutation does not change version")
    _check(changed_events.is_empty(), "same-state mutation emits no change signal")

    _check(mutations.set_state("door.store.a", DoorValue.CLOSED), "OPEN to CLOSED mutation succeeds")
    _check(state.state("door.store.a") == DoorValue.CLOSED, "state changed to CLOSED")
    _check(state.version("door.store.a") == before_version + 1, "actual state change increments per-door version")
    _check(state.revision() == before_revision + 1, "actual state change increments store revision")
    _check(changed_events.size() == 1, "actual state change emits one signal")
    if changed_events.size() == 1:
        _check(changed_events[0]["previous"] == DoorValue.OPEN, "change signal carries previous state")
        _check(changed_events[0]["current"] == DoorValue.CLOSED, "change signal carries new state")

    _check(not world_mutations.create_entity(&"door.house", "door.unplaced").is_empty(), "create unplaced door")
    _check(mutations.enroll("door.unplaced", DoorValue.OPEN), "unplaced door may be enrolled")
    _check(not fixture["world"].has_placement("door.unplaced"), "door remains tactically unplaced")
    _check(state.state("door.unplaced") == DoorValue.OPEN, "unplaced door retains persistent state")
    _check(not mutations.set_state("door.unplaced", DoorValue.UNKNOWN), "UNKNOWN target mutation rejected")

func _test_removal_reenrollment_versioning() -> void:
    removed_events.clear()
    var fixture: Dictionary = _fixture()
    var world: WorldState = fixture["world"]
    var world_mutations: WorldMutationService = fixture["world_mutations"]
    var state: DoorStateStore = fixture["state"]
    var mutations: DoorStateMutationService = fixture["mutations"]
    state.door_removed.connect(_on_removed)

    world_mutations.create_entity(&"door.house", "door.reuse")
    _check(mutations.enroll("door.reuse", DoorValue.CLOSED), "reuse door enrolled")
    _check(mutations.set_state("door.reuse", DoorValue.OPEN), "reuse door state advances")
    var old_version: int = state.version("door.reuse")

    _check(world_mutations.remove_entity("door.reuse"), "WHAT door may be removed before mechanic cleanup")
    _check(state.has_door("door.reuse") and state.state("door.reuse") == DoorValue.OPEN, "orphan state is retained explicitly after WHAT removal")
    _check(not mutations.set_state("door.reuse", DoorValue.CLOSED), "normal state mutation rejects orphan WHAT record")
    _check(mutations.remove("door.reuse"), "explicit lifecycle cleanup removes orphan state")
    _check(not state.has_door("door.reuse"), "door state removed")
    _check(removed_events.size() == 1, "removal emits one signal")

    _check(not world.has_entity("door.reuse"), "WHAT entity remains removed")
    _check(not world_mutations.create_entity(&"door.house", "door.reuse").is_empty(), "same stable ID can be recreated by content lifecycle")
    _check(mutations.enroll("door.reuse", DoorValue.CLOSED), "re-enrollment succeeds")
    _check(state.version("door.reuse") > old_version, "re-enrollment never reuses stale version")

func _test_snapshot_restore_and_atomic_rejection() -> void:
    reset_count = 0
    var fixture: Dictionary = _fixture()
    var world_mutations: WorldMutationService = fixture["world_mutations"]
    var state: DoorStateStore = fixture["state"]
    var mutations: DoorStateMutationService = fixture["mutations"]

    world_mutations.create_entity(&"door.office", "z.door")
    world_mutations.create_entity(&"door.house", "a.door")
    _check(mutations.enroll("z.door", DoorValue.OPEN), "snapshot z door enrolled")
    _check(mutations.enroll("a.door", DoorValue.CLOSED), "snapshot a door enrolled")
    _check(mutations.set_state("z.door", DoorValue.CLOSED), "snapshot version advanced")

    var saved: Dictionary = state.snapshot()
    var entries: Array = saved["records"]
    _check(entries.size() == 2, "snapshot includes enrolled doors")
    if entries.size() == 2:
        _check(String(entries[0]["door_id"]) == "a.door" and String(entries[1]["door_id"]) == "z.door", "snapshot records sorted by stable ID")

    var restored := DoorStateClass.new()
    restored.door_state_reset.connect(_on_reset)
    _check(restored.load_snapshot(saved), "valid snapshot restores")
    _check(reset_count == 1, "successful restore emits one reset")
    _check(restored.snapshot() == saved, "snapshot round trip deterministic")

    var before_bad: Dictionary = restored.snapshot()
    var bad_unknown: Dictionary = before_bad.duplicate(true)
    bad_unknown["records"][0]["state"] = "unknown"
    _check(not restored.load_snapshot(bad_unknown), "UNKNOWN snapshot state rejected")
    _check(restored.snapshot() == before_bad, "UNKNOWN rejection is atomic")

    var bad_duplicate: Dictionary = before_bad.duplicate(true)
    bad_duplicate["records"].append(bad_duplicate["records"][0].duplicate(true))
    _check(not restored.load_snapshot(bad_duplicate), "duplicate snapshot ID rejected")
    _check(restored.snapshot() == before_bad, "duplicate rejection is atomic")

    var bad_version: Dictionary = before_bad.duplicate(true)
    bad_version["records"][0]["version"] = 0
    _check(not restored.load_snapshot(bad_version), "non-positive record version rejected")
    _check(restored.snapshot() == before_bad, "bad-version rejection is atomic")

func _on_enrolled(door_id: String, state: StringName, version: int) -> void:
    enrolled_events.append({"door_id": door_id, "state": state, "version": version})

func _on_removed(door_id: String, previous_state: StringName, version: int) -> void:
    removed_events.append({"door_id": door_id, "state": previous_state, "version": version})

func _on_changed(door_id: String, previous_state: StringName, new_state: StringName, version: int) -> void:
    changed_events.append({"door_id": door_id, "previous": previous_state, "current": new_state, "version": version})

func _on_reset() -> void:
    reset_count += 1

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
