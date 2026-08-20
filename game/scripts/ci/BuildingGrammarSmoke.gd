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
const DinerFixtureClass = preload("res://scripts/demo/RuralDinerCritiqueFixture.gd")
const DevSeedSessionClass = preload("res://scripts/demo/BuildingGrammarDevSeedSession.gd")
const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const CollisionCatalogClass = preload("res://scripts/simulation/collision/CollisionCatalog.gd")
const CollisionOverridesClass = preload("res://scripts/simulation/collision/CollisionOverrideState.gd")
const SpatialQueryClass = preload("res://scripts/simulation/collision/SpatialQueryService.gd")
const BaseTraversalClass = preload("res://scripts/simulation/movement/MovementTraversalPolicy.gd")
const MovementClass = preload("res://scripts/simulation/movement/PassageAwareMovementActionService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const DoorMutationClass = preload("res://scripts/simulation/doors/DoorStateMutationService.gd")
const DoorTransitionClass = preload("res://scripts/simulation/doors/DoorPhysicalTransitionService.gd")
const DoorPassageClass = preload("res://scripts/simulation/doors/DoorMovementPassageResolver.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const ArtCatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const RendererStackClass = preload("res://scripts/render/TacticalRendererStack.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var generator := GeneratorClass.new()
    var validator := ValidatorClass.new()
    _test_placement_descriptors(generator)
    _test_diner_candidate(generator, validator)
    _test_diner_seed_and_rotation_torture(generator, validator)
    _test_dev_seed_session()
    _test_diner_fixture()
    if failures.is_empty():
        print("BUILDING_GRAMMAR_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("BUILDING_GRAMMAR_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_placement_descriptors(generator: LocalBuildingGenerator) -> void:
    var expected: Array = [
        [TrailerClass.ARCHETYPE_ID, Vector2i(5, 12), Facing.Value.EAST, 2],
        [SmallFarmhouseClass.ARCHETYPE_ID, Vector2i(13, 9), Facing.Value.NORTH, 2],
        [LargeFarmhouseClass.ARCHETYPE_ID, Vector2i(21, 9), Facing.Value.NORTH, 4],
        [CompactLaundryHouseClass.ARCHETYPE_ID, Vector2i(17, 13), Facing.Value.SOUTH, 1],
        [GasStationClass.ARCHETYPE_ID, Vector2i(19, 15), Facing.Value.SOUTH, 1],
        [DinerClass.ARCHETYPE_ID, Vector2i(17, 11), Facing.Value.SOUTH, 2],
    ]
    _check(generator.supported_archetypes().size() == 6, "registry exposes five saved examples plus diner grammar trial")
    _check(generator.placement_descriptors().size() == 6, "every registered archetype exposes a placement descriptor")
    for row: Array in expected:
        var archetype_id: StringName = row[0]
        var descriptor: BuildingArchetypePlacementDescriptor = generator.placement_descriptor(archetype_id)
        _check(descriptor != null and descriptor.is_valid(), "%s descriptor is valid" % String(archetype_id))
        if descriptor == null:
            continue
        _check(descriptor.canonical_size() == row[1], "%s descriptor owns canonical size" % String(archetype_id))
        _check(descriptor.canonical_frontage() == int(row[2]), "%s descriptor owns canonical frontage" % String(archetype_id))
        _check(descriptor.archetype_version() == int(row[3]), "%s descriptor reports archetype version" % String(archetype_id))
        _check(descriptor.supported_orientations().size() == 4, "%s supports all cardinal orientations" % String(archetype_id))
        _check(descriptor.required_size(Facing.Value.EAST) == Vector2i(int(row[1].y), int(row[1].x)), "%s descriptor rotates required size" % String(archetype_id))
        _check(descriptor.frontage_for_orientation(Facing.Value.EAST) == (int(row[2]) + Facing.Value.EAST) % 4, "%s descriptor rotates frontage" % String(archetype_id))
    _check(generator.placement_descriptor(&"building.unknown") == null, "unknown archetype has no placement descriptor")

func _test_diner_candidate(generator: LocalBuildingGenerator, validator: GeneratedBuildingValidator) -> void:
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
    _check(plan_a.is_generated() and plan_a.signature() == plan_b.signature(), "diner grammar is deterministic for same seed")
    _check(plan_a.archetype_version == 2, "diner grammar v2 reports the table-density rule change")
    _check(bool(validator.validate(plan_a).get("ok", false)), "diner grammar output passes shared structural validator")
    _check(plan_a.footprint_rect == Rect2i(60, 70, 17, 11), "diner uses compact 17x11 shell")
    _check(_room_cell_count(plan_a, "dining_room") == 75, "diner public room is broad 15x5 dining hub")
    _check(_room_cell_count(plan_a, "kitchen") == 21, "diner kitchen is compact 7x3 service room")
    _check(_room_cell_count(plan_a, "storage") == 9, "diner storage is compact 3x3 service room")
    _check(_room_cell_count(plan_a, "bathroom") == 9, "diner bathroom is compact 3x3 service room")
    _check(_room_cell_count(plan_a, "hall") == 0 and _room_cell_count(plan_a, "corridor") == 0, "diner grammar spends no cells on a dedicated hallway")
    _check(_structure_kind_count(plan_a, "door") == 5, "diner has front/service exits plus three service-room doors")
    _check(_structure_kind_count(plan_a, "window") == 11, "diner gets broad storefront plus side/rear windows")
    _check(_role_cell(plan_a, "door.exterior.primary") == Vector2i(68, 80), "diner primary door is centered on frontage")
    _check(_role_cell(plan_a, "door.exterior.service") == Vector2i(70, 70), "storage service exit reaches rear wall")
    _check(_role_cell(plan_a, "door.interior.kitchen") == Vector2i(64, 74), "kitchen opens directly to dining hub")
    _check(_role_cell(plan_a, "door.interior.storage") == Vector2i(70, 74), "storage opens directly to dining hub")
    _check(_role_cell(plan_a, "door.interior.bathroom") == Vector2i(74, 74), "bathroom opens directly to dining hub")
    _check(plan_a.props.size() == 30, "diner v2 adds two more table/booth clusters without filling the aisle")

    var kitchen_roles: Array[String] = [
        "prop.kitchen.fridge",
        "prop.kitchen.counter_1",
        "prop.kitchen.sink",
        "prop.kitchen.counter_2",
        "prop.kitchen.stove",
        "prop.kitchen.counter_3",
        "prop.kitchen.pantry",
    ]
    var previous: Vector2i = Vector2i(-1, -1)
    for role: String in kitchen_roles:
        var cell: Vector2i = _prop_role_cell(plan_a, role)
        _check(cell.x >= 0, "%s exists in contiguous kitchen run" % role)
        if previous.x >= 0:
            _check(_manhattan(previous, cell) == 1, "kitchen work run remains contiguous at %s" % role)
        previous = cell

    for y in range(75, 80):
        _check(not _has_blocking_prop_at(plan_a, Vector2i(68, y)), "diner center customer aisle remains open at y=%d" % y)
    for y in range(71, 74):
        _check(not _has_blocking_prop_at(plan_a, Vector2i(70, y)), "storage service lane remains open at y=%d" % y)

    for suffix: String in ["west_a", "west_mid", "west_b", "east_a", "east_mid", "east_b"]:
        var table: Vector2i = _prop_role_cell(plan_a, "prop.dining.table.%s" % suffix)
        var booth: Vector2i = _prop_role_cell(plan_a, "prop.dining.booth.%s" % suffix)
        _check(_manhattan(table, booth) == 1, "diner table/booth cluster %s stays adjacent" % suffix)
        _check(_prop_facing_for_role(plan_a, "prop.dining.table.%s" % suffix) == Facing.Value.WEST, "diner table %s follows recovered table-facing rule" % suffix)

    var alternate := RequestClass.new(
        "building.test.diner.rural_small.alt",
        DinerClass.ARCHETYPE_ID,
        19007,
        Rect2i(60, 70, 17, 11),
        Facing.Value.NORTH,
        Facing.Value.SOUTH
    )
    var alternate_plan: GeneratedBuildingPlan = generator.generate(alternate)
    _check(alternate_plan.is_generated(), "alternate diner seed generates")
    _check(bool(validator.validate(alternate_plan).get("ok", false)), "alternate diner seed validates")
    _check(alternate_plan.signature() != plan_a.signature(), "adjacent diner seeds produce meaningfully different room ordering")
    _check(_role_cell(alternate_plan, "door.interior.kitchen") == Vector2i(68, 74), "alternate seed moves kitchen through profile ordering rather than hand-authored duplicate")
    _check(_role_cell(alternate_plan, "door.exterior.service") == Vector2i(74, 70), "alternate seed moves storage service exit with storage room")

    var third := RequestClass.new(
        "building.test.diner.rural_small.third",
        DinerClass.ARCHETYPE_ID,
        19008,
        Rect2i(60, 70, 17, 11),
        Facing.Value.NORTH,
        Facing.Value.SOUTH
    )
    var third_plan: GeneratedBuildingPlan = generator.generate(third)
    _check(third_plan.is_generated() and bool(validator.validate(third_plan).get("ok", false)), "third diner topology generates and validates")
    _check(_role_cell(third_plan, "door.interior.kitchen") == Vector2i(64, 74), "seed 19008 keeps kitchen west while swapping the compact service rooms")
    _check(_role_cell(third_plan, "door.exterior.service") == Vector2i(74, 70), "seed 19008 moves storage service exit east")

    var fourth := RequestClass.new(
        "building.test.diner.rural_small.fourth",
        DinerClass.ARCHETYPE_ID,
        19009,
        Rect2i(60, 70, 17, 11),
        Facing.Value.NORTH,
        Facing.Value.SOUTH
    )
    var fourth_plan: GeneratedBuildingPlan = generator.generate(fourth)
    _check(fourth_plan.is_generated() and bool(validator.validate(fourth_plan).get("ok", false)), "fourth diner topology generates and validates")
    _check(_role_cell(fourth_plan, "door.interior.kitchen") == Vector2i(68, 74), "seed 19009 keeps the kitchen centered")
    _check(_role_cell(fourth_plan, "door.exterior.service") == Vector2i(62, 70), "seed 19009 moves storage service exit west")

func _test_diner_seed_and_rotation_torture(generator: LocalBuildingGenerator, validator: GeneratedBuildingValidator) -> void:
    var descriptor: BuildingArchetypePlacementDescriptor = generator.placement_descriptor(DinerClass.ARCHETYPE_ID)
    _check(descriptor != null, "diner descriptor exists for torture test")
    if descriptor == null:
        return
    var orientations: Array[int] = [Facing.Value.NORTH, Facing.Value.EAST, Facing.Value.SOUTH, Facing.Value.WEST]
    for seed in range(19006, 19038):
        for orientation: int in orientations:
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
    _check(not generator.generate(too_small).is_generated(), "diner grammar rejects undersized envelope")
    var wrong_frontage := RequestClass.new("building.test.diner.wrong_frontage", DinerClass.ARCHETYPE_ID, 1, Rect2i(0, 0, 17, 11), Facing.Value.NORTH, Facing.Value.NORTH)
    _check(not generator.generate(wrong_frontage).is_generated(), "diner grammar rejects incompatible frontage")

func _test_dev_seed_session() -> void:
    DevSeedSessionClass.clear_native_override()
    _check(DevSeedSessionClass.current_seed(DinerFixtureClass.DINER_SEED) == DinerFixtureClass.DINER_SEED, "dev seed session defaults to fixture seed")
    DevSeedSessionClass.set_native_seed(19009)
    _check(DevSeedSessionClass.current_seed(DinerFixtureClass.DINER_SEED) == 19009, "dev seed session exposes explicit native override")
    DevSeedSessionClass.clear_native_override()
    _check(DinerFixtureClass.active_seed() == DinerFixtureClass.DINER_SEED, "clearing dev seed restores canonical fixture seed")

func _test_diner_fixture() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var collision_catalog := CollisionCatalogClass.new()
    var collision_overrides := CollisionOverridesClass.new()
    var traversal := BaseTraversalClass.new()
    var doors := DoorStateClass.new()
    var door_mutations := DoorMutationClass.new(doors, world)
    _check(DinerFixtureClass.build(world, mutations, collision_catalog, traversal, doors, door_mutations), "diner grammar critique fixture materializes")
    _check(world.has_entity(DinerFixtureClass.EXTERIOR_DOOR_ID), "diner stable exterior door exists")
    _check(doors.door_ids().size() == 5, "diner fixture enrolls five doors")
    for door_id: String in doors.door_ids():
        _check(doors.state(door_id) == DoorValue.CLOSED, "diner generated doors begin closed")

    var coverage_query := SpatialQueryClass.new(world, collision_catalog, collision_overrides)
    var coverage: Dictionary = coverage_query.collision_coverage_report()
    _check((coverage.get("missing_required_profiles", []) as Array).is_empty(), "diner collision coverage is complete")
    var art := ArtCatalogClass.new()
    for entity_id: String in world.entity_ids():
        var entity: WorldEntityRecord = world.entity(entity_id)
        if entity == null:
            continue
        var semantic: String = String(entity.semantic_type)
        if semantic.begins_with("wall."):
            _check(art.resolve_wall(entity.semantic_type).is_found(), "diner wall has art")
        elif semantic.begins_with("door."):
            _check(art.resolve_door(entity.semantic_type, false).is_found(), "diner door has art")
        elif semantic.begins_with("window."):
            _check(art.resolve_window(entity.semantic_type).is_found(), "diner window has art")
        elif semantic.begins_with("prop."):
            _check(art.resolve_prop(entity.semantic_type).is_found(), "diner prop has art")
    for y in range(DinerFixtureClass.MAP_SIZE.y):
        for x in range(DinerFixtureClass.MAP_SIZE.x):
            _check(art.resolve_ground(world.terrain_at(DinerFixtureClass.MAP_ORIGIN + Vector2i(x, y))).is_found(), "diner critique terrain has art")

    var transition := DoorTransitionClass.new(world, doors, door_mutations, collision_overrides)
    var passage := DoorPassageClass.new(world, doors, transition)
    var kernel := TickKernelClass.new(DinerFixtureClass.PLAYER_ID)
    var movement := MovementClass.new(world, mutations, coverage_query, kernel, traversal, passage)
    var enter = movement.request_step_forward(DinerFixtureClass.PLAYER_ID)
    _check(enter != null and enter.is_accepted(), "diner front door accepts automatic Walk passage")
    kernel.run_until_stop()
    _check(doors.state(DinerFixtureClass.EXTERIOR_DOOR_ID) == DoorValue.OPEN, "diner front door opens through System 18")
    _check(world.placement(DinerFixtureClass.PLAYER_ID).anchor == Vector2i(9, 11), "player enters diner front doorway")

    var stack := RendererStackClass.new()
    get_root().add_child(stack)
    _check(stack.configure(world, art, doors, DinerFixtureClass.PLAYER_ID), "diner renderer stack configures")
    _check(stack.set_visible_window(DinerFixtureClass.MAP_ORIGIN, DinerFixtureClass.MAP_SIZE, DinerFixtureClass.CELL_PIXELS), "diner critique lot fits visible window")
    var diagnostics: Dictionary = stack.planned_diagnostic_counts()
    _check(int(diagnostics.get("ground", -1)) == 0 and int(diagnostics.get("structure", -1)) == 0 and int(diagnostics.get("prop", -1)) == 0 and int(diagnostics.get("actor", -1)) == 0, "diner renders without diagnostics")
    stack.queue_free()

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

func _prop_role_cell(plan: GeneratedBuildingPlan, role: String) -> Vector2i:
    for prop: Dictionary in plan.props:
        if String(prop.get("role", "")) == role:
            return prop.get("cell", Vector2i(-1, -1))
    return Vector2i(-1, -1)

func _prop_facing_for_role(plan: GeneratedBuildingPlan, role: String) -> int:
    for prop: Dictionary in plan.props:
        if String(prop.get("role", "")) == role:
            return int(prop.get("facing", -1))
    return -1

func _has_blocking_prop_at(plan: GeneratedBuildingPlan, cell: Vector2i) -> bool:
    for prop: Dictionary in plan.props:
        if prop.get("cell", Vector2i(-1, -1)) == cell and bool(prop.get("blocking", true)):
            return true
    return false

func _manhattan(a: Vector2i, b: Vector2i) -> int:
    return absi(a.x - b.x) + absi(a.y - b.y)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
