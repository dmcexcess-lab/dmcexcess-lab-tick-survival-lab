extends SceneTree

const RequestClass = preload("res://scripts/generation/buildings/BuildingGenerationRequest.gd")
const GeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")
const TrailerClass = preload("res://scripts/generation/buildings/archetypes/TrailerBuildingGenerator.gd")
const SmallFarmhouseClass = preload("res://scripts/generation/buildings/archetypes/FarmhouseBuildingGenerator.gd")
const LargeFarmhouseClass = preload("res://scripts/generation/buildings/archetypes/LargeFarmhouseBuildingGenerator.gd")
const CompactLaundryHouseClass = preload("res://scripts/generation/buildings/archetypes/CompactLaundryHouseBuildingGenerator.gd")
const GasStationClass = preload("res://scripts/generation/buildings/archetypes/GasStationBuildingGenerator.gd")
const DinerClass = preload("res://scripts/generation/buildings/archetypes/RuralDinerBuildingGenerator.gd")
const PostOfficeClass = preload("res://scripts/generation/buildings/archetypes/PostOfficeBuildingGenerator.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var generator := GeneratorClass.new()
    var validator := ValidatorClass.new()
    _test_protected_descriptors(generator)
    _test_diner_grammar(generator, validator)
    _test_diner_seed_and_rotation_torture(generator, validator)
    if failures.is_empty():
        print("BUILDING_GRAMMAR_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("BUILDING_GRAMMAR_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_protected_descriptors(generator: LocalBuildingGenerator) -> void:
    var expected: Array = [
        [TrailerClass.ARCHETYPE_ID, Vector2i(5, 12), Facing.Value.EAST, 2],
        [SmallFarmhouseClass.ARCHETYPE_ID, Vector2i(13, 9), Facing.Value.NORTH, 2],
        [LargeFarmhouseClass.ARCHETYPE_ID, Vector2i(21, 9), Facing.Value.NORTH, 4],
        [CompactLaundryHouseClass.ARCHETYPE_ID, Vector2i(17, 13), Facing.Value.SOUTH, 1],
        [GasStationClass.ARCHETYPE_ID, Vector2i(19, 15), Facing.Value.SOUTH, 1],
        [DinerClass.ARCHETYPE_ID, Vector2i(17, 11), Facing.Value.SOUTH, 2],
        [PostOfficeClass.ARCHETYPE_ID, Vector2i(21, 13), Facing.Value.SOUTH, 1],
    ]
    _check(generator.supported_archetypes().size() == 25, "expanded registry exposes seven protected references plus eighteen baseline profiles")
    _check(generator.placement_descriptors().size() == 25, "expanded registry has a descriptor for every profile")
    for row: Array in expected:
        var archetype_id: StringName = row[0]
        var descriptor: BuildingArchetypePlacementDescriptor = generator.placement_descriptor(archetype_id)
        _check(descriptor != null and descriptor.is_valid(), "%s descriptor remains valid" % String(archetype_id))
        if descriptor == null:
            continue
        _check(descriptor.canonical_size() == row[1], "%s canonical size remains protected" % String(archetype_id))
        _check(descriptor.canonical_frontage() == int(row[2]), "%s canonical frontage remains protected" % String(archetype_id))
        _check(descriptor.archetype_version() == int(row[3]), "%s version remains protected" % String(archetype_id))
        _check(descriptor.supported_orientations().size() == 4, "%s still supports four rotations" % String(archetype_id))
    _check(generator.placement_descriptor(&"building.unknown") == null, "unknown archetype has no descriptor")

func _test_diner_grammar(generator: LocalBuildingGenerator, validator: GeneratedBuildingValidator) -> void:
    var request := RequestClass.new(
        "building.test.diner.rural_small",
        DinerClass.ARCHETYPE_ID,
        19006,
        Rect2i(60, 70, 17, 11),
        Facing.Value.NORTH,
        Facing.Value.SOUTH
    )
    var plan_a: GeneratedBuildingPlan = generator.generate(request)
    var plan_b: GeneratedBuildingPlan = generator.generate(request)
    _check(plan_a.is_generated() and plan_a.signature() == plan_b.signature(), "diner grammar remains deterministic")
    _check(plan_a.archetype_version == 2, "diner remains protected at version 2")
    _check(bool(validator.validate(plan_a).get("ok", false)), "diner output passes shared validator")
    _check(plan_a.footprint_rect == Rect2i(60, 70, 17, 11), "diner remains compact 17x11")
    _check(_room_cell_count(plan_a, "dining_room") == 75, "diner retains broad 15x5 public hub")
    _check(_room_cell_count(plan_a, "kitchen") == 21, "diner retains compact 7x3 kitchen")
    _check(_room_cell_count(plan_a, "storage") == 9, "diner retains compact storage")
    _check(_room_cell_count(plan_a, "bathroom") == 9, "diner retains compact bathroom")
    _check(_room_cell_count(plan_a, "hall") == 0 and _room_cell_count(plan_a, "corridor") == 0, "diner still spends no space on an unjustified corridor")
    _check(_structure_kind_count(plan_a, "door") == 5, "diner retains five doors")
    _check(_structure_kind_count(plan_a, "window") == 11, "diner retains eleven windows")
    _check(plan_a.props.size() == 30, "diner retains purposeful v2 dressing density")
    _check(_role_cell(plan_a, "door.exterior.primary") == Vector2i(68, 80), "diner primary entry remains centered on frontage")
    _check(_role_cell(plan_a, "door.exterior.service") == Vector2i(70, 70), "diner storage service exit remains attached to storage")

    var alternate := RequestClass.new(
        "building.test.diner.rural_small.alt",
        DinerClass.ARCHETYPE_ID,
        19007,
        Rect2i(60, 70, 17, 11),
        Facing.Value.NORTH,
        Facing.Value.SOUTH
    )
    var alternate_plan: GeneratedBuildingPlan = generator.generate(alternate)
    _check(alternate_plan.is_generated() and bool(validator.validate(alternate_plan).get("ok", false)), "alternate diner topology validates")
    _check(alternate_plan.signature() != plan_a.signature(), "adjacent diner seed changes legal topology")
    _check(_role_cell(alternate_plan, "door.exterior.service") == Vector2i(74, 70), "service exit follows moved storage room")

func _test_diner_seed_and_rotation_torture(generator: LocalBuildingGenerator, validator: GeneratedBuildingValidator) -> void:
    var descriptor: BuildingArchetypePlacementDescriptor = generator.placement_descriptor(DinerClass.ARCHETYPE_ID)
    _check(descriptor != null, "diner descriptor exists for torture test")
    if descriptor == null:
        return
    for seed in range(19006, 19038):
        for orientation: int in [Facing.Value.NORTH, Facing.Value.EAST, Facing.Value.SOUTH, Facing.Value.WEST]:
            var size: Vector2i = descriptor.required_size(orientation)
            var frontage: int = descriptor.frontage_for_orientation(orientation)
            var request := RequestClass.new(
                "building.test.diner.torture.%d.%d" % [seed, orientation],
                DinerClass.ARCHETYPE_ID,
                seed,
                Rect2i(Vector2i(100, 120), size),
                orientation,
                frontage
            )
            var plan: GeneratedBuildingPlan = generator.generate(request)
            _check(plan.is_generated(), "diner seed %d orientation %d generates" % [seed, orientation])
            if plan.is_generated():
                _check(bool(validator.validate(plan).get("ok", false)), "diner seed %d orientation %d validates" % [seed, orientation])

    var too_small := RequestClass.new("building.test.diner.too_small", DinerClass.ARCHETYPE_ID, 1, Rect2i(0, 0, 16, 11), Facing.Value.NORTH, Facing.Value.SOUTH)
    _check(not generator.generate(too_small).is_generated(), "diner rejects undersized envelope")
    var wrong_frontage := RequestClass.new("building.test.diner.wrong_frontage", DinerClass.ARCHETYPE_ID, 1, Rect2i(0, 0, 17, 11), Facing.Value.NORTH, Facing.Value.NORTH)
    _check(not generator.generate(wrong_frontage).is_generated(), "diner rejects incompatible frontage")

func _room_cell_count(plan: GeneratedBuildingPlan, purpose: String) -> int:
    for room: Dictionary in plan.rooms:
        if String(room.get("purpose", "")) == purpose:
            return (room.get("cells", []) as Array).size()
    return 0

func _structure_kind_count(plan: GeneratedBuildingPlan, kind: String) -> int:
    var count: int = 0
    for structure: Dictionary in plan.structures:
        if String(structure.get("kind", "")) == kind:
            count += 1
    return count

func _role_cell(plan: GeneratedBuildingPlan, role: String) -> Vector2i:
    for structure: Dictionary in plan.structures:
        if String(structure.get("role", "")) == role:
            return structure.get("cell", Vector2i(-1, -1))
    return Vector2i(-1, -1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
