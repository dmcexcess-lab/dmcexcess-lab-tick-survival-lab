extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const StateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const MutationsClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const ProfilesClass = preload("res://scripts/simulation/actors/equipment/ActorEquipmentProfileCatalog.gd")
const ProjectionClass = preload("res://scripts/simulation/actors/equipment/ActorEquipmentProjection.gd")
const ProtectionClass = preload("res://scripts/simulation/actors/equipment/ActorEquipmentProtectionQuery.gd")
const PaperDollClass = preload("res://scripts/ui/ActorEquipmentPaperDollQuery.gd")
const ProductionShellClass = preload("res://scripts/ui/EquipmentPlayerShell.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _test_authoritative_paper_doll_projection()
    if failures.is_empty():
        print("ACTOR_EQUIPMENT_PAPER_DOLL_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("ACTOR_EQUIPMENT_PAPER_DOLL_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_authoritative_paper_doll_projection() -> void:
    var world := WorldStateClass.new()
    var world_mutations := WorldMutationClass.new(world)
    var state := StateClass.new()
    var profiles := ProfilesClass.new()
    var mutations := MutationsClass.new(state, world, profiles)
    var actor_id := "survivor.paperdoll"

    _check(not world_mutations.create_entity(&"actor.survivor", actor_id).is_empty(), "create survivor")
    _check(mutations.enroll_actor(actor_id), "enroll survivor equipment authority")

    var assignments: Array = [
        [Slots.Value.PRIMARY_RIGHT, "item.right", &"item.flashlight"],
        [Slots.Value.SECONDARY_LEFT, "item.left", &"item.utility_knife"],
        [Slots.Value.BACK, "item.board", &"item.vehicle.skateboard"],
        [Slots.Value.HEAD, "item.head", &"item.clothing.beanie"],
        [Slots.Value.TORSO, "item.torso", &"item.clothing.work_jacket"],
        [Slots.Value.LEGS, "item.legs", &"item.clothing.jeans"],
        [Slots.Value.FEET, "item.feet", &"item.clothing.work_boots"],
        [Slots.Value.HANDS, "item.hands", &"item.clothing.work_gloves"],
    ]
    for assignment: Array in assignments:
        var item_id := String(assignment[1])
        var semantic := StringName(assignment[2])
        _check(not world_mutations.create_entity(semantic, item_id).is_empty(), "create %s" % item_id)
        _check(mutations.set_item(actor_id, int(assignment[0]), item_id), "equip %s" % item_id)

    var projection := ProjectionClass.new(world, state, profiles)
    var protection := ProtectionClass.new(world, state, profiles)
    var paper_doll := PaperDollClass.new(world, state, profiles)
    _check(projection.is_ready() and protection.is_ready() and paper_doll.is_ready(), "read-only equipment projections are ready")

    var revision_before := state.revision()
    var doll := paper_doll.query(actor_id)
    _check(bool(doll.get("known", false)), "paper doll recognizes authoritative actor")
    var rows: Array = doll.get("slots", [])
    _check(rows.size() == 8, "paper doll exposes all eight authoritative slots")
    var expected_names := ["primary_right", "secondary_left", "back", "head", "torso", "legs", "feet", "hands"]
    if rows.size() == 8:
        for index in range(8):
            var row: Dictionary = rows[index]
            _check(String(row.get("slot_name", "")) == expected_names[index], "slot %d keeps canonical order" % index)
            _check(not bool(row.get("empty", true)), "slot %s reads equipped truth" % expected_names[index])

    var totals: Dictionary = doll.get("protection", {})
    _check(int(totals.get("bite_cut_armor", -1)) == 25, "bite/cut armor derives from equipped clothing")
    _check(int(totals.get("blunt_ballistic_armor", -1)) == 22, "blunt/ballistic armor derives from equipped clothing")
    _check(int(totals.get("water_resistance", -1)) == 28, "water resistance derives from equipped clothing")
    _check(int(totals.get("insulation", -1)) == 34, "insulation derives separately from equipped clothing")
    var thermal := protection.query_thermal(actor_id)
    _check(bool(thermal.get("known", false)) and int(thermal.get("insulation", -1)) == 34, "thermal query seam exposes insulation without armor ownership")

    var layers := projection.visual_layers(actor_id)
    _check(layers.size() == 8, "visual projection covers all equipped slots")
    var expected_visual_order := ["back", "legs", "torso", "feet", "head", "hands", "primary_right", "secondary_left"]
    if layers.size() == 8:
        for index in range(8):
            _check(String(layers[index].get("slot_name", "")) == expected_visual_order[index], "visual layer order is deterministic at %d" % index)

    _check(state.revision() == revision_before, "paper doll/protection/visual reads never mutate equipment authority")
    _check(mutations.clear_slot(actor_id, Slots.Value.TORSO), "unequip torso through authoritative mutation path")
    doll = paper_doll.query(actor_id)
    var torso_row := _row_for_slot(doll.get("slots", []), Slots.Value.TORSO)
    _check(bool(torso_row.get("empty", false)), "paper doll updates immediately after unequip")
    totals = doll.get("protection", {})
    _check(int(totals.get("bite_cut_armor", -1)) == 17, "armor total updates after unequip")
    _check(int(totals.get("insulation", -1)) == 22, "insulation total updates after unequip")
    layers = projection.visual_layers(actor_id)
    _check(layers.size() == 7 and not _layers_have_slot(layers, Slots.Value.TORSO), "visual projection removes unequipped torso layer")

    var board_assignment := state.assignment_for_item("item.board")
    _check(String(board_assignment.get("actor_id", "")) == actor_id and int(board_assignment.get("slot", -1)) == Slots.Value.BACK, "projection does not duplicate skateboard ownership")
    _check(profiles.allowed_slots(&"item.vehicle.skateboard") == [Slots.Value.PRIMARY_RIGHT, Slots.Value.SECONDARY_LEFT, Slots.Value.BACK], "skateboard remains limited to hands/back")
    _check(mutations.clear_slot(actor_id, Slots.Value.BACK), "clear skateboard back slot")
    _check(not mutations.set_item(actor_id, Slots.Value.TORSO, "item.board"), "skateboard cannot occupy clothing slot")
    _check(mutations.set_item(actor_id, Slots.Value.BACK, "item.board"), "skateboard can return to back")

    _check(mutations.clear_slot(actor_id, Slots.Value.PRIMARY_RIGHT), "clear right hand for duplicate test")
    _check(mutations.clear_slot(actor_id, Slots.Value.SECONDARY_LEFT), "clear left hand for duplicate test")
    _check(not world_mutations.create_entity(&"item.test_shared", "item.shared").is_empty(), "create shared ownership test item")
    _check(mutations.set_item(actor_id, Slots.Value.PRIMARY_RIGHT, "item.shared"), "assign shared item once")
    _check(not mutations.set_item(actor_id, Slots.Value.SECONDARY_LEFT, "item.shared"), "same item cannot be duplicated into a second slot")
    var shared_assignment := state.assignment_for_item("item.shared")
    _check(int(shared_assignment.get("slot", -1)) == Slots.Value.PRIMARY_RIGHT, "single authoritative assignment survives rejected duplicate")

    var shell := ProductionShellClass.new()
    _check(shell != null, "production equipment shell class instantiates")
    shell.free()

func _row_for_slot(rows: Array, slot: int) -> Dictionary:
    for value: Variant in rows:
        if typeof(value) == TYPE_DICTIONARY and int(value.get("slot", -1)) == slot:
            return value
    return {}

func _layers_have_slot(layers: Array[Dictionary], slot: int) -> bool:
    for layer: Dictionary in layers:
        if int(layer.get("slot", -1)) == slot:
            return true
    return false

func _check(condition: bool, label: String) -> void:
    if not condition:
        failures.append(label)
