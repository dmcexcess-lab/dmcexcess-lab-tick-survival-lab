extends SceneTree

const RequestClass = preload("res://scripts/generation/buildings/BuildingGenerationRequest.gd")
const GeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")
const TrailerClass = preload("res://scripts/generation/buildings/archetypes/TrailerBuildingGenerator.gd")
const FarmhouseClass = preload("res://scripts/generation/buildings/archetypes/FarmhouseBuildingGenerator.gd")
const FixtureClass = preload("res://scripts/demo/FarmhouseCritiqueFixture.gd")
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
    _test_farmhouse_generation(generator, validator)
    _test_farmhouse_fixture()

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
    _check(plan_a.archetype_version == 2, "saved trailer baseline remains archetype version 2")
    _check(bool(validator.validate(plan_a).get("ok", false)), "saved trailer v2 still validates")
    _check(plan_a.footprint_rect == Rect2i(20, 30, 5, 12), "saved trailer remains 5x12")
    _check(_room_cell_count(plan_a, "living_kitchen") == 12, "saved trailer living/kitchen remains 3x4")
    _check(_room_cell_count(plan_a, "bathroom") == 6, "saved trailer bathroom remains 3x2")
    _check(_room_cell_count(plan_a, "bedroom") == 6, "saved trailer bedroom remains 3x2")
    var saw_light_shell: bool = false
    var saw_wood_shell: bool = false
    for structure: Dictionary in plan_a.structures:
        if String(structure.get("role", "")).begins_with("wall.exterior"):
            saw_light_shell = saw_light_shell or structure.get("semantic", &"") == &"wall.plaster"
            saw_wood_shell = saw_wood_shell or structure.get("semantic", &"") == &"wall.rural_wood"
    _check(saw_light_shell and not saw_wood_shell, "saved trailer keeps light plaster shell")
    var saw_sofa_opposite_kitchen: bool = false
    for prop: Dictionary in plan_a.props:
        if String(prop.get("role", "")) == "prop.living.sofa":
            saw_sofa_opposite_kitchen = prop.get("cell", Vector2i(-1, -1)) == Vector2i(23, 31) and int(prop.get("facing", -1)) == Facing.Value.WEST
    _check(saw_sofa_opposite_kitchen, "saved trailer keeps opposite-wall sofa placement")

func _test_farmhouse_generation(generator: LocalBuildingGenerator, validator: GeneratedBuildingValidator) -> void:
    var supported: Array[StringName] = generator.supported_archetypes()
    _check(supported.has(TrailerClass.ARCHETYPE_ID) and supported.has(FarmhouseClass.ARCHETYPE_ID), "registry exposes preserved trailer and farmhouse")

    var request := RequestClass.new(
        "building.test.farmhouse",
        FarmhouseClass.ARCHETYPE_ID,
        19002,
        Rect2i(60, 70, 13, 9),
        Facing.Value.NORTH,
        Facing.Value.NORTH
    )
    var plan_a: GeneratedBuildingPlan = generator.generate(request)
    var plan_b: GeneratedBuildingPlan = generator.generate(request)
    _check(plan_a.is_generated() and plan_a.signature() == plan_b.signature(), "farmhouse same request+seed is deterministic")
    _check(plan_a.archetype_version == 2, "farmhouse critique revision bumps archetype version to 2")
    _check(bool(validator.validate(plan_a).get("ok", false)), "north farmhouse v2 plan validates")
    _check(plan_a.footprint_rect == Rect2i(60, 70, 13, 9), "farmhouse v2 uses compact 13x9 shell")
    _check(_room_cell_count(plan_a, "living_kitchen") == 33, "farmhouse living/kitchen is exact 11x3")
    _check(_room_cell_count(plan_a, "living_room") == 0 and _room_cell_count(plan_a, "kitchen") == 0, "farmhouse v2 uses one open-plan living/kitchen room purpose")
    _check(_room_cell_count(plan_a, "bedroom_1") == 9, "farmhouse bedroom 1 remains exact 3x3")
    _check(_room_cell_count(plan_a, "bathroom") == 9, "farmhouse bathroom remains exact 3x3")
    _check(_room_cell_count(plan_a, "bedroom_2") == 9, "farmhouse bedroom 2 remains exact 3x3")
    _check(_structure_kind_count(plan_a, "door") == 5, "farmhouse keeps two exterior plus three private-room doors")
    _check(_structure_kind_count(plan_a, "window") == 7, "farmhouse keeps seven-window set")
    _check(_all_exterior_walls_are(plan_a, &"wall.plaster"), "farmhouse uses light plaster exterior walls")
    _check(_role_cell(plan_a, "door.exterior.primary") == Vector2i(63, 70), "farmhouse front door opens into living side of open-plan room")
    _check(_role_cell(plan_a, "door.exterior.kitchen") == Vector2i(72, 72), "farmhouse side kitchen door lands directly on kitchen end")
    _check(_role_cell(plan_a, "door.interior.bedroom_1") == Vector2i(62, 74), "private-room wall follows compact main room immediately")
    _check(_role_cell(plan_a, "door.interior.bathroom") == Vector2i(66, 74), "bathroom door follows compact main room immediately")
    _check(_role_cell(plan_a, "door.interior.bedroom_2") == Vector2i(70, 74), "bedroom 2 door follows compact main room immediately")

    var east_request := RequestClass.new(
        "building.test.farmhouse.east",
        FarmhouseClass.ARCHETYPE_ID,
        19002,
        Rect2i(90, 100, 9, 13),
        Facing.Value.EAST,
        Facing.Value.EAST
    )
    var east_plan: GeneratedBuildingPlan = generator.generate(east_request)
    _check(east_plan.is_generated() and east_plan.footprint_rect.size == Vector2i(9, 13), "rectangular farmhouse rotates to 9x13 extent")
    _check(bool(validator.validate(east_plan).get("ok", false)), "rotated farmhouse v2 validates")
    _check(_role_cell(east_plan, "door.exterior.primary") == Vector2i(98, 103), "farmhouse doorway geometry rotates deterministically")

    var too_small := RequestClass.new(
        "building.test.farmhouse.small",
        FarmhouseClass.ARCHETYPE_ID,
        1,
        Rect2i(0, 0, 13, 8),
        Facing.Value.NORTH,
        Facing.Value.NORTH
    )
    _check(not generator.generate(too_small).is_generated(), "too-short farmhouse envelope fails explicitly")

func _test_farmhouse_fixture() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var collision_catalog := CollisionCatalogClass.new()
    var collision_overrides := CollisionOverridesClass.new()
    var traversal := BaseTraversalClass.new()
    var doors := DoorStateClass.new()
    var door_mutations := DoorMutationClass.new(doors, world)
    _check(FixtureClass.build(world, mutations, collision_catalog, traversal, doors, door_mutations), "farmhouse critique fixture materializes")
    _check(world.has_entity(FixtureClass.EXTERIOR_DOOR_ID), "farmhouse stable exterior door exists")
    _check(doors.door_ids().size() == 5, "all five farmhouse doors explicitly enrolled")
    for door_id: String in doors.door_ids():
        _check(doors.state(door_id) == DoorValue.CLOSED, "generated farmhouse door begins closed")

    var coverage_query := SpatialQueryClass.new(world, collision_catalog, collision_overrides)
    var coverage: Dictionary = coverage_query.collision_coverage_report()
    _check((coverage.get("missing_required_profiles", []) as Array).is_empty(), "farmhouse structure/prop collision coverage complete")

    var art := ArtCatalogClass.new()
    for entity_id: String in world.entity_ids():
        var entity: WorldEntityRecord = world.entity(entity_id)
        if entity == null:
            continue
        var semantic: String = String(entity.semantic_type)
        if semantic.begins_with("wall."):
            _check(art.resolve_wall(entity.semantic_type).is_found(), "farmhouse wall has art")
        elif semantic.begins_with("door."):
            _check(art.resolve_door(entity.semantic_type, false).is_found(), "farmhouse door has art")
        elif semantic.begins_with("window."):
            _check(art.resolve_window(entity.semantic_type).is_found(), "farmhouse window has art")
        elif semantic.begins_with("prop."):
            _check(art.resolve_prop(entity.semantic_type).is_found(), "farmhouse prop has art")
    for y in range(FixtureClass.MAP_SIZE.y):
        for x in range(FixtureClass.MAP_SIZE.x):
            var cell := Vector2i(x, y)
            _check(art.resolve_ground(world.terrain_at(cell)).is_found(), "farmhouse critique lot terrain has art")

    var transition := DoorTransitionClass.new(world, doors, door_mutations, collision_overrides)
    var passage := DoorPassageClass.new(world, doors, transition)
    var kernel := TickKernelClass.new(FixtureClass.PLAYER_ID)
    var movement := MovementClass.new(world, mutations, coverage_query, kernel, traversal, passage)
    var enter = movement.request_step_forward(FixtureClass.PLAYER_ID)
    _check(enter != null and enter.is_accepted(), "farmhouse front door accepts automatic Walk passage")
    kernel.run_until_stop()
    _check(doors.state(FixtureClass.EXTERIOR_DOOR_ID) == DoorValue.OPEN, "farmhouse front door opens through System 18")
    _check(world.placement(FixtureClass.PLAYER_ID).anchor == Vector2i(4, 1), "player enters farmhouse front doorway")

    var stack := RendererStackClass.new()
    get_root().add_child(stack)
    _check(stack.configure(world, art, doors, FixtureClass.PLAYER_ID), "renderer stack configures farmhouse critique lot")
    _check(stack.set_visible_window(FixtureClass.MAP_ORIGIN, FixtureClass.MAP_SIZE, FixtureClass.CELL_PIXELS), "15x15 farmhouse lot remains one-screen without camera")
    var diagnostics: Dictionary = stack.planned_diagnostic_counts()
    _check(int(diagnostics.get("ground", -1)) == 0 and int(diagnostics.get("structure", -1)) == 0 and int(diagnostics.get("prop", -1)) == 0 and int(diagnostics.get("actor", -1)) == 0, "farmhouse critique lot renders without diagnostics")
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

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
