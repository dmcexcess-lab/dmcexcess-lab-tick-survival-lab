extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const HandStateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const HandMutationClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd")
const ProfilesClass = preload("res://scripts/simulation/actors/equipment/ActorEquipmentProfileCatalog.gd")
const ProtectionQueryClass = preload("res://scripts/simulation/actors/equipment/ActorEquipmentProtectionQuery.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")

var failures: Array[String] = []
var assignment_events: Array[Dictionary] = []
var reset_count: int = 0

func _initialize() -> void:
    _test_enrollment_and_copy_safe_reads()
    _test_assignment_validation_and_uniqueness()
    _test_equipment_profile_and_protection_contract()
    _test_lifecycle_versioning()
    _test_snapshot_restore()
    if failures.is_empty():
        print("ACTOR_HAND_EQUIPMENT_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("ACTOR_HAND_EQUIPMENT_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture() -> Dictionary:
    var world := WorldStateClass.new()
    var world_mutations := WorldMutationClass.new(world)
    var state := HandStateClass.new()
    var mutations := HandMutationClass.new(state, world)
    return {"world": world, "world_mutations": world_mutations, "state": state, "mutations": mutations}

func _test_enrollment_and_copy_safe_reads() -> void:
    var fixture: Dictionary = _fixture()
    var wm: WorldMutationService = fixture["world_mutations"]
    var state: ActorHandEquipmentState = fixture["state"]
    var mutations: ActorHandEquipmentMutationService = fixture["mutations"]
    _check(not state.has_actor("actor.missing"), "missing actor is not silently enrolled")
    _check(state.record("actor.missing") == null, "missing actor record is null")
    wm.create_entity(&"actor.survivor", "actor.a")
    wm.create_entity(&"actor.infected", "actor.z")
    _check(mutations.enroll_actor("actor.a"), "survivor enrollment succeeds")
    _check(state.primary_item("actor.a").is_empty() and state.secondary_item("actor.a").is_empty(), "enrollment explicitly starts with empty hands")
    _check(not mutations.enroll_actor("actor.a"), "duplicate enrollment rejected")
    _check(not mutations.enroll_actor("actor.z"), "infected enrollment rejected")
    _check(not mutations.enroll_actor("actor.missing"), "missing WHAT actor rejected")
    var copy: ActorHandEquipmentRecord = state.record("actor.a")
    _check(copy != null, "record read exists")
    if copy != null:
        copy.primary_item_id = "tampered"
        copy.version = 999
    _check(state.primary_item("actor.a").is_empty() and state.version("actor.a") == 1, "record read is mutation-safe")

func _test_assignment_validation_and_uniqueness() -> void:
    assignment_events.clear()
    var fixture: Dictionary = _fixture()
    var world: WorldState = fixture["world"]
    var wm: WorldMutationService = fixture["world_mutations"]
    var state: ActorHandEquipmentState = fixture["state"]
    var mutations: ActorHandEquipmentMutationService = fixture["mutations"]
    state.hand_assignment_changed.connect(_on_assignment_changed)
    wm.create_entity(&"actor.survivor", "actor.a")
    wm.create_entity(&"actor.survivor", "actor.b")
    wm.create_entity(&"item.knife", "item.knife.a")
    wm.create_entity(&"item.flashlight", "item.light.a")
    wm.create_entity(&"prop.chair", "not.item")
    mutations.enroll_actor("actor.a")
    mutations.enroll_actor("actor.b")

    _check(not mutations.set_item("actor.a", Slots.Value.PRIMARY_RIGHT, "item.missing"), "missing item rejected")
    _check(not mutations.set_item("actor.a", Slots.Value.PRIMARY_RIGHT, "not.item"), "non-item semantic rejected")
    _check(wm.set_placement("item.knife.a", Layers.Channel.LOOSE_ITEM, Vector2i(3, 4), Facing.Value.NORTH, Footprint.single_cell()), "placed test item")
    _check(not mutations.set_item("actor.a", Slots.Value.PRIMARY_RIGHT, "item.knife.a"), "tactically placed item rejected")
    _check(wm.unplace_entity("item.knife.a"), "unplace test item")
    _check(mutations.set_item("actor.a", Slots.Value.PRIMARY_RIGHT, "item.knife.a"), "unplaced item accepted")
    _check(not mutations.set_item("actor.a", Slots.Value.SECONDARY_LEFT, "item.knife.a"), "same item cannot occupy both hands")
    _check(not mutations.set_item("actor.b", Slots.Value.PRIMARY_RIGHT, "item.knife.a"), "same item cannot occupy two actors")
    _check(mutations.set_item("actor.a", Slots.Value.SECONDARY_LEFT, "item.light.a"), "second unique item accepted")
    _check(state.primary_item("actor.a") == "item.knife.a" and state.secondary_item("actor.a") == "item.light.a", "both hand assignments readable")
    var reverse: Dictionary = state.assignment_for_item("item.light.a")
    _check(String(reverse.get("actor_id", "")) == "actor.a" and int(reverse.get("slot", -1)) == Slots.Value.SECONDARY_LEFT, "reverse assignment identifies actor and slot")

    var before_revision: int = state.revision()
    var before_version: int = state.version("actor.a")
    var before_events: int = assignment_events.size()
    _check(mutations.set_item("actor.a", Slots.Value.SECONDARY_LEFT, "item.light.a"), "same assignment succeeds as no-op")
    _check(state.revision() == before_revision and state.version("actor.a") == before_version, "same assignment changes no revision/version")
    _check(assignment_events.size() == before_events, "same assignment emits no signal")
    _check(mutations.clear_slot("actor.a", Slots.Value.SECONDARY_LEFT), "clear slot succeeds")
    _check(state.secondary_item("actor.a").is_empty() and state.assignment_for_item("item.light.a").is_empty(), "clearing removes reverse assignment")

    _check(not world.has_placement("actor.a"), "actor may remain tactically unplaced")
    _check(state.primary_item("actor.a") == "item.knife.a", "unplaced actor retains hand state")

func _test_equipment_profile_and_protection_contract() -> void:
    var fixture: Dictionary = _fixture()
    var wm: WorldMutationService = fixture["world_mutations"]
    var world: WorldState = fixture["world"]
    var state: ActorHandEquipmentState = fixture["state"]
    var mutations: ActorHandEquipmentMutationService = fixture["mutations"]
    var profiles := ProfilesClass.new()
    wm.create_entity(&"actor.survivor", "actor.gear")
    wm.create_entity(&"item.vehicle.skateboard", "item.board")
    wm.create_entity(&"item.clothing.work_jacket", "item.jacket")
    wm.create_entity(&"item.clothing.work_boots", "item.boots")
    mutations.enroll_actor("actor.gear")

    _check(profiles.allowed_slots(&"item.vehicle.skateboard") == [Slots.Value.PRIMARY_RIGHT, Slots.Value.SECONDARY_LEFT, Slots.Value.BACK], "skateboard is hand/back only")
    _check(not profiles.is_allowed(&"item.vehicle.skateboard", Slots.Value.HEAD), "skateboard cannot be worn as apparel")
    _check(mutations.set_item("actor.gear", Slots.Value.BACK, "item.board"), "skateboard equips to back")
    _check(not mutations.set_item("actor.gear", Slots.Value.HEAD, "item.jacket"), "torso clothing rejects head slot")
    _check(mutations.set_item("actor.gear", Slots.Value.TORSO, "item.jacket"), "work jacket equips to torso")
    _check(mutations.set_item("actor.gear", Slots.Value.FEET, "item.boots"), "work boots equip to feet")

    var jacket_values: Dictionary = profiles.protection_and_weather(&"item.clothing.work_jacket")
    _check(jacket_values.has("bite_cut_armor") and jacket_values.has("blunt_ballistic_armor") and jacket_values.has("water_resistance"), "apparel exposes merged armor and water resistance")
    for retired_key: String in ["armor_blunt", "armor_cut", "armor_bite", "insulation", "wind_resistance"]:
        _check(not jacket_values.has(retired_key), "armor/weather projection excludes legacy or thermal-only stat: %s" % retired_key)
    var jacket_thermal: Dictionary = profiles.thermal_and_comfort(&"item.clothing.work_jacket")
    _check(int(jacket_thermal.get("insulation", -1)) == 12, "insulation is exposed only through thermal/comfort profile seam")

    var protection := ProtectionQueryClass.new(world, state, profiles)
    var aggregate: Dictionary = protection.query("actor.gear")
    _check(bool(aggregate.get("known", false)), "equipped protection query resolves")
    _check(int(aggregate.get("bite_cut_armor", -1)) == 14, "bite/cut armor aggregates jacket plus boots")
    _check(int(aggregate.get("blunt_ballistic_armor", -1)) == 14, "blunt/ballistic armor aggregates jacket plus boots")
    _check(int(aggregate.get("water_resistance", -1)) == 22, "water resistance remains separate")
    _check(int(aggregate.get("insulation", -1)) == 17, "insulation aggregates separately as thermal/comfort clothing truth")
    for retired_key: String in ["armor_blunt", "armor_cut", "armor_bite", "wind_resistance"]:
        _check(not aggregate.has(retired_key), "retired aggregate stat absent: %s" % retired_key)
    var thermal: Dictionary = protection.query_thermal("actor.gear")
    _check(bool(thermal.get("known", false)) and int(thermal.get("insulation", -1)) == 17, "thermal query exposes insulation without changing armor semantics")

func _test_lifecycle_versioning() -> void:
    var fixture: Dictionary = _fixture()
    var wm: WorldMutationService = fixture["world_mutations"]
    var state: ActorHandEquipmentState = fixture["state"]
    var mutations: ActorHandEquipmentMutationService = fixture["mutations"]
    wm.create_entity(&"actor.survivor", "actor.reuse")
    wm.create_entity(&"item.hammer", "item.hammer.a")
    _check(mutations.enroll_actor("actor.reuse"), "lifecycle actor enrolled")
    _check(mutations.set_item("actor.reuse", Slots.Value.PRIMARY_RIGHT, "item.hammer.a"), "lifecycle item assigned")
    var old_version: int = state.version("actor.reuse")
    _check(wm.remove_entity("actor.reuse"), "WHAT actor removed before mechanic cleanup")
    _check(state.has_actor("actor.reuse"), "hand state persists after WHAT actor removal")
    _check(not mutations.set_item("actor.reuse", Slots.Value.SECONDARY_LEFT, "item.hammer.a"), "normal assignment rejects orphan actor")
    _check(mutations.remove_actor("actor.reuse"), "explicit hand-state cleanup succeeds")
    _check(not wm.create_entity(&"actor.survivor", "actor.reuse").is_empty(), "stable actor ID recreated")
    _check(mutations.enroll_actor("actor.reuse"), "re-enrollment succeeds")
    _check(state.version("actor.reuse") > old_version, "re-enrollment does not reuse stale version")

func _test_snapshot_restore() -> void:
    reset_count = 0
    var fixture: Dictionary = _fixture()
    var wm: WorldMutationService = fixture["world_mutations"]
    var state: ActorHandEquipmentState = fixture["state"]
    var mutations: ActorHandEquipmentMutationService = fixture["mutations"]
    for actor_id: String in ["z.actor", "a.actor"]:
        wm.create_entity(&"actor.survivor", actor_id)
        mutations.enroll_actor(actor_id)
    wm.create_entity(&"item.knife", "item.one")
    wm.create_entity(&"item.flashlight", "item.two")
    mutations.set_item("z.actor", Slots.Value.PRIMARY_RIGHT, "item.one")
    mutations.set_item("a.actor", Slots.Value.SECONDARY_LEFT, "item.two")
    var saved: Dictionary = state.snapshot()
    var records: Array = saved["records"]
    _check(records.size() == 2 and String(records[0]["actor_id"]) == "a.actor" and String(records[1]["actor_id"]) == "z.actor", "snapshot sorted by actor ID")

    var restored := HandStateClass.new()
    restored.hand_equipment_reset.connect(_on_reset)
    _check(restored.load_snapshot(saved), "valid snapshot restores")
    _check(reset_count == 1, "successful restore emits one reset")
    _check(restored.snapshot() == saved, "snapshot round trip deterministic")
    var before_bad: Dictionary = restored.snapshot()

    var duplicate_item: Dictionary = before_bad.duplicate(true)
    duplicate_item["records"][1]["primary_item_id"] = "item.two"
    _check(not restored.load_snapshot(duplicate_item), "duplicate physical item snapshot rejected")
    _check(restored.snapshot() == before_bad, "duplicate item rejection atomic")

    var duplicate_actor: Dictionary = before_bad.duplicate(true)
    duplicate_actor["records"].append(duplicate_actor["records"][0].duplicate(true))
    _check(not restored.load_snapshot(duplicate_actor), "duplicate actor snapshot rejected")
    _check(restored.snapshot() == before_bad, "duplicate actor rejection atomic")

    var bad_version: Dictionary = before_bad.duplicate(true)
    bad_version["records"][0]["version"] = 0
    _check(not restored.load_snapshot(bad_version), "non-positive version snapshot rejected")
    _check(restored.snapshot() == before_bad, "bad version rejection atomic")

func _on_assignment_changed(actor_id: String, slot: int, previous_item_id: String, new_item_id: String, version: int) -> void:
    assignment_events.append({"actor_id": actor_id, "slot": slot, "previous": previous_item_id, "current": new_item_id, "version": version})

func _on_reset() -> void:
    reset_count += 1

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
