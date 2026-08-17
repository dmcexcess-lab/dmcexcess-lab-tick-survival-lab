extends SceneTree

const RequestClass = preload("res://scripts/generation/buildings/BuildingGenerationRequest.gd")
const GeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")
const TrailerClass = preload("res://scripts/generation/buildings/archetypes/TrailerBuildingGenerator.gd")
const SmallFarmhouseClass = preload("res://scripts/generation/buildings/archetypes/FarmhouseBuildingGenerator.gd")
const LargeFarmhouseClass = preload("res://scripts/generation/buildings/archetypes/LargeFarmhouseBuildingGenerator.gd")
const SmallFixtureClass = preload("res://scripts/demo/SmallFarmhouseCritiqueFixture.gd")
const LargeFixtureClass = preload("res://scripts/demo/FarmhouseCritiqueFixture.gd")
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
    _test_trailer_preserved(generator, validator)
    _test_small_farmhouse_preserved(generator, validator)
    _test_large_farmhouse_generation(generator, validator)
    _test_small_farmhouse_fixture()
    _test_large_farmhouse_fixture()

    if failures.is_empty():
        print("LOCAL_BUILDING_GENERATION_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("LOCAL_BUILDING_GENERATION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_trailer_preserved(generator: LocalBuildingGenerator, validator: GeneratedBuildingValidator) -> void:
    var request := RequestClass.new(
        "building.test.trailer",
        TrailerClass.ARCHETYPE_ID,
        19001,
        Rect2i(20, 30, 5, 12),
        Facing.Value.NORTH,
        Facing.Value.EAST
    )
    var plan_a: GeneratedBuildingPlan = generator.generate(request)
    var plan_b: GeneratedBuildingPlan = generator.generate(request)
    _check(plan_a.is_generated() and plan_a.signature() == plan_b.signature(), "trailer v2 remains deterministic")
    _check(plan_a.archetype_version == 2, "saved trailer baseline remains version 2")
    _check(bool(validator.validate(plan_a).get("ok", false)), "saved trailer v2 still validates")
    _check(plan_a.footprint_rect == Rect2i(20, 30, 5, 12), "saved trailer remains 5x12")
    _check(_room_cell_count(plan_a, "living_kitchen") == 12, "saved trailer living/kitchen remains 3x4")
    _check(_room_cell_count(plan_a, "bathroom") == 6, "saved trailer bathroom remains 3x2")
    _check(_room_cell_count(plan_a, "bedroom") == 6, "saved trailer bedroom remains 3x2")
    _check(_all_exterior_walls_are(plan_a, &"wall.plaster"), "saved trailer keeps light plaster shell")
    var saw_sofa_opposite_kitchen: bool = false
    for prop: Dictionary in plan_a.props:
        if String(prop.get("role", "")) == "prop.living.sofa":
            saw_sofa_opposite_kitchen = prop.get("cell", Vector2i(-1, -1)) == Vector2i(23, 31) and int(prop.get("facing", -1)) == Facing.Value.WEST
    _check(saw_sofa_opposite_kitchen, "saved trailer keeps opposite-wall sofa placement")

func _test_small_farmhouse_preserved(generator: LocalBuildingGenerator, validator: GeneratedBuildingValidator) -> void:
    var request := RequestClass.new(
        "building.test.farmhouse.small",
        SmallFarmhouseClass.ARCHETYPE_ID,
        19002,
        Rect2i(60, 70, 13, 9),
        Facing.Value.NORTH,
        Facing.Value.NORTH
    )
    var plan_a: GeneratedBuildingPlan = generator.generate(request)
    var plan_b: GeneratedBuildingPlan = generator.generate(request)
    _check(plan_a.is_generated() and plan_a.signature() == plan_b.signature(), "small farmhouse remains deterministic")
    _check(plan_a.archetype_version == 2, "saved small farmhouse remains version 2")
    _check(bool(validator.validate(plan_a).get("ok", false)), "saved small farmhouse validates")
    _check(plan_a.footprint_rect == Rect2i(60, 70, 13, 9), "saved small farmhouse remains 13x9")
    _check(_room_cell_count(plan_a, "living_kitchen") == 33, "saved small farmhouse keeps 11x3 living/kitchen")
    _check(_room_cell_count(plan_a, "bedroom_1") == 9, "saved small farmhouse bedroom 1 remains 3x3")
    _check(_room_cell_count(plan_a, "bathroom") == 9, "saved small farmhouse bathroom remains 3x3")
    _check(_room_cell_count(plan_a, "bedroom_2") == 9, "saved small farmhouse bedroom 2 remains 3x3")
    _check(_structure_kind_count(plan_a, "door") == 5, "saved small farmhouse keeps five doors")
    _check(_structure_kind_count(plan_a, "window") == 7, "saved small farmhouse keeps seven windows")
    _check(_all_exterior_walls_are(plan_a, &"wall.plaster"), "saved small farmhouse keeps plaster shell")
    _check(_role_cell(plan_a, "door.exterior.primary") == Vector2i(63, 70), "saved small farmhouse front door unchanged")

    var east_request := RequestClass.new(
        "building.test.farmhouse.small.east",
        SmallFarmhouseClass.ARCHETYPE_ID,
        19002,
        Rect2i(90, 100, 9, 13),
        Facing.Value.EAST,
        Facing.Value.EAST
    )
    var east_plan: GeneratedBuildingPlan = generator.generate(east_request)
    _check(east_plan.is_generated() and east_plan.footprint_rect.size == Vector2i(9, 13), "small farmhouse still rotates to 9x13")
    _check(bool(validator.validate(east_plan).get("ok", false)), "rotated small farmhouse still validates")

func _test_large_farmhouse_generation(generator: LocalBuildingGenerator, validator: GeneratedBuildingValidator) -> void:
    var supported: Array[StringName] = generator.supported_archetypes()
    _check(supported.has(TrailerClass.ARCHETYPE_ID), "registry keeps trailer")
    _check(supported.has(SmallFarmhouseClass.ARCHETYPE_ID), "registry keeps small farmhouse")
    _check(supported.has(LargeFarmhouseClass.ARCHETYPE_ID), "registry exposes large farmhouse")

    var request := RequestClass.new(
        "building.test.farmhouse.large",
        LargeFarmhouseClass.ARCHETYPE_ID,
        19003,
        Rect2i(60, 70, 25, 20),
        Facing.Value.NORTH,
        Facing.Value.NORTH
    )
    var plan_a: GeneratedBuildingPlan = generator.generate(request)
    var plan_b: GeneratedBuildingPlan = generator.generate(request)
    _check(plan_a.is_generated() and plan_a.signature() == plan_b.signature(), "large farmhouse is deterministic")
    _check(plan_a.archetype_version == 1, "large farmhouse starts at version 1")
    _check(bool(validator.validate(plan_a).get("ok", false)), "large farmhouse north plan validates")
    _check(plan_a.footprint_rect == Rect2i(60, 70, 25, 20), "large farmhouse uses 25x20 bounding footprint")
    _check(_room_cell_count(plan_a, "living_room") == 30, "large farmhouse living room is separate 6x5")
    _check(_room_cell_count(plan_a, "kitchen") == 25, "large farmhouse kitchen is separate 5x5")
    _check(_room_cell_count(plan_a, "bedroom_1") == 24, "large farmhouse bedroom 1 is 6x4")
    _check(_room_cell_count(plan_a, "bedroom_2") == 24, "large farmhouse bedroom 2 is 6x4")
    _check(_room_cell_count(plan_a, "bedroom_3") == 18, "large farmhouse bedroom 3 is 6x3")
    _check(_room_cell_count(plan_a, "bathroom_1") == 9, "large farmhouse bathroom 1 is 3x3")
    _check(_room_cell_count(plan_a, "bathroom_2") == 9, "large farmhouse bathroom 2 is 3x3")
    _check(_structure_kind_count(plan_a, "door") == 9, "large farmhouse has two exterior and seven interior doors")
    _check(_structure_kind_count(plan_a, "window") == 12, "large farmhouse has twelve windows")
    _check(_all_exterior_walls_are(plan_a, &"wall.plaster"), "large farmhouse uses plaster exterior walls")
    _check(_role_cell(plan_a, "door.exterior.primary") == Vector2i(69, 70), "large farmhouse front door enters central hall")
    _check(_role_cell(plan_a, "door.interior.living") == Vector2i(67, 73), "living room has a real separating wall and door")
    _check(_role_cell(plan_a, "door.interior.kitchen") == Vector2i(78, 73), "kitchen wing has a real separating wall and door")
    _check(not _has_ground(plan_a, Vector2i(80, 80)), "large farmhouse southeast notch stays outdoors")
    _check(_has_ground(plan_a, Vector2i(83, 73)), "large farmhouse kitchen wing is physically occupied")

    var east_request := RequestClass.new(
        "building.test.farmhouse.large.east",
        LargeFarmhouseClass.ARCHETYPE_ID,
        19003,
        Rect2i(100, 110, 20, 25),
        Facing.Value.EAST,
        Facing.Value.EAST
    )
    var east_plan: GeneratedBuildingPlan = generator.generate(east_request)
    _check(east_plan.is_generated() and east_plan.footprint_rect.size == Vector2i(20, 25), "large farmhouse rotates to 20x25 bounding footprint")
    _check(bool(validator.validate(east_plan).get("ok", false)), "rotated large farmhouse validates")

    var too_small := RequestClass.new(
        "building.test.farmhouse.large.small",
        LargeFarmhouseClass.ARCHETYPE_ID,
        1,
        Rect2i(0, 0, 24, 20),
        Facing.Value.NORTH,
        Facing.Value.NORTH
    )
    _check(not generator.generate(too_small).is_generated(), "too-small large farmhouse envelope fails explicitly")

func _test_small_farmhouse_fixture() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var collision_catalog := CollisionCatalogClass.new()
    var collision_overrides := CollisionOverridesClass.new()
    var traversal := BaseTraversalClass.new()
    var doors := DoorStateClass.new()
    var door_mutations := DoorMutationClass.new(doors, world)
    _check(SmallFixtureClass.build(world, mutations, collision_catalog, traversal, doors, door_mutations), "saved small farmhouse fixture materializes")
    _verify_fixture(world, mutations, collision_catalog, collision_overrides, traversal, doors, door_mutations, SmallFixtureClass.PLAYER_ID, SmallFixtureClass.EXTERIOR_DOOR_ID, SmallFixtureClass.MAP_ORIGIN, SmallFixtureClass.MAP_SIZE, SmallFixtureClass.CELL_PIXELS, 5, Vector2i(4, 1), "small farmhouse")

func _test_large_farmhouse_fixture() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var collision_catalog := CollisionCatalogClass.new()
    var collision_overrides := CollisionOverridesClass.new()
    var traversal := BaseTraversalClass.new()
    var doors := DoorStateClass.new()
    var door_mutations := DoorMutationClass.new(doors, world)
    _check(LargeFixtureClass.build(world, mutations, collision_catalog, traversal, doors, door_mutations), "large farmhouse critique fixture materializes")
    _verify_fixture(world, mutations, collision_catalog, collision_overrides, traversal, doors, door_mutations, LargeFixtureClass.PLAYER_ID, LargeFixtureClass.EXTERIOR_DOOR_ID, LargeFixtureClass.MAP_ORIGIN, LargeFixtureClass.MAP_SIZE, LargeFixtureClass.CELL_PIXELS, 9, Vector2i(10, 1), "large farmhouse")

func _verify_fixture(
    world: WorldState,
    mutations: WorldMutationService,
    collision_catalog: CollisionCatalog,
    collision_overrides: CollisionOverrideState,
    traversal: MovementTraversalPolicy,
    doors: DoorStateStore,
    door_mutations: DoorStateMutationService,
    player_id: String,
    exterior_door_id: String,
    map_origin: Vector2i,
    map_size: Vector2i,
    cell_pixels: float,
    expected_door_count: int,
    expected_entry_cell: Vector2i,
    label: String
) -> void:
    _check(world.has_entity(exterior_door_id), "%s stable exterior door exists" % label)
    _check(doors.door_ids().size() == expected_door_count, "%s enrolls expected door count" % label)
    for door_id: String in doors.door_ids():
        _check(doors.state(door_id) == DoorValue.CLOSED, "%s generated doors begin closed" % label)

    var coverage_query := SpatialQueryClass.new(world, collision_catalog, collision_overrides)
    var coverage: Dictionary = coverage_query.collision_coverage_report()
    _check((coverage.get("missing_required_profiles", []) as Array).is_empty(), "%s collision coverage complete" % label)

    var art := ArtCatalogClass.new()
    for entity_id: String in world.entity_ids():
        var entity: WorldEntityRecord = world.entity(entity_id)
        if entity == null:
            continue
        var semantic: String = String(entity.semantic_type)
        if semantic.begins_with("wall."):
            _check(art.resolve_wall(entity.semantic_type).is_found(), "%s wall has art" % label)
        elif semantic.begins_with("door."):
            _check(art.resolve_door(entity.semantic_type, false).is_found(), "%s door has art" % label)
        elif semantic.begins_with("window."):
            _check(art.resolve_window(entity.semantic_type).is_found(), "%s window has art" % label)
        elif semantic.begins_with("prop."):
            _check(art.resolve_prop(entity.semantic_type).is_found(), "%s prop has art" % label)
    for y in range(map_size.y):
        for x in range(map_size.x):
            _check(art.resolve_ground(world.terrain_at(map_origin + Vector2i(x, y))).is_found(), "%s critique terrain has art" % label)

    var transition := DoorTransitionClass.new(world, doors, door_mutations, collision_overrides)
    var passage := DoorPassageClass.new(world, doors, transition)
    var kernel := TickKernelClass.new(player_id)
    var movement := MovementClass.new(world, mutations, coverage_query, kernel, traversal, passage)
    var enter = movement.request_step_forward(player_id)
    _check(enter != null and enter.is_accepted(), "%s front door accepts automatic Walk passage" % label)
    kernel.run_until_stop()
    _check(doors.state(exterior_door_id) == DoorValue.OPEN, "%s front door opens through System 18" % label)
    _check(world.placement(player_id).anchor == expected_entry_cell, "%s player enters expected front doorway" % label)

    var stack := RendererStackClass.new()
    get_root().add_child(stack)
    _check(stack.configure(world, art, doors, player_id), "%s renderer stack configures" % label)
    _check(stack.set_visible_window(map_origin, map_size, cell_pixels), "%s critique lot fits configured visible window" % label)
    var diagnostics: Dictionary = stack.planned_diagnostic_counts()
    _check(int(diagnostics.get("ground", -1)) == 0 and int(diagnostics.get("structure", -1)) == 0 and int(diagnostics.get("prop", -1)) == 0 and int(diagnostics.get("actor", -1)) == 0, "%s renders without diagnostics" % label)
    stack.queue_free()

func _room_cell_count(plan: GeneratedBuildingPlan, purpose: String) -> int:
    for room: Dictionary in plan.rooms:
        if String(room.get("purpose", "")) == purpose:
            var cells: Array = room.get("cells", [])
            return cells.size()
    return 0

func _structure_kind_count(plan: GeneratedBuildingPlan, kind: String) -> int:
    var count: int = 0
    for structure: Dictionary in plan.structures:
        if String(structure.get("kind", "")) == kind:
            count += 1
    return count

func _all_exterior_walls_are(plan: GeneratedBuildingPlan, semantic: StringName) -> bool:
    var saw_wall: bool = false
    for structure: Dictionary in plan.structures:
        if not String(structure.get("role", "")).begins_with("wall.exterior"):
            continue
        saw_wall = true
        if structure.get("semantic", &"") != semantic:
            return false
    return saw_wall

func _role_cell(plan: GeneratedBuildingPlan, role: String) -> Vector2i:
    for structure: Dictionary in plan.structures:
        if String(structure.get("role", "")) == role:
            return structure.get("cell", Vector2i(-1, -1))
    return Vector2i(-1, -1)

func _has_ground(plan: GeneratedBuildingPlan, cell: Vector2i) -> bool:
    for entry: Dictionary in plan.ground_entries:
        if entry.get("cell", Vector2i(-1, -1)) == cell:
            return true
    return false

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
