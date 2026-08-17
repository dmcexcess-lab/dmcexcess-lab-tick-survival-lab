extends SceneTree

const RequestClass = preload("res://scripts/generation/buildings/BuildingGenerationRequest.gd")
const GeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")
const TrailerClass = preload("res://scripts/generation/buildings/archetypes/TrailerBuildingGenerator.gd")
const FixtureClass = preload("res://scripts/demo/TrailerCritiqueFixture.gd")
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
    var request := RequestClass.new(
        "building.test.trailer",
        TrailerClass.ARCHETYPE_ID,
        19001,
        Rect2i(20, 30, 6, 12),
        Facing.Value.NORTH,
        Facing.Value.EAST
    )
    var plan_a: GeneratedBuildingPlan = generator.generate(request)
    var plan_b: GeneratedBuildingPlan = generator.generate(request)
    _check(plan_a.is_generated() and plan_a.signature() == plan_b.signature(), "same request+seed produces identical semantic plan")
    _check(bool(validator.validate(plan_a).get("ok", false)), "north trailer plan validates")
    _check(plan_a.footprint_rect == Rect2i(20, 30, 6, 12), "north trailer uses expected 6x12 footprint")

    var east_request := RequestClass.new(
        "building.test.trailer.east",
        TrailerClass.ARCHETYPE_ID,
        19001,
        Rect2i(40, 50, 12, 6),
        Facing.Value.EAST,
        Facing.Value.SOUTH
    )
    var east_plan: GeneratedBuildingPlan = generator.generate(east_request)
    _check(east_plan.is_generated() and east_plan.footprint_rect.size == Vector2i(12, 6), "east orientation rotates footprint")
    _check(bool(validator.validate(east_plan).get("ok", false)), "rotated trailer validates")

    var too_small := RequestClass.new(
        "building.test.small",
        TrailerClass.ARCHETYPE_ID,
        1,
        Rect2i(0, 0, 5, 10),
        Facing.Value.NORTH,
        Facing.Value.EAST
    )
    _check(not generator.generate(too_small).is_generated(), "too-small envelope fails explicitly")

    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var collision_catalog := CollisionCatalogClass.new()
    var collision_overrides := CollisionOverridesClass.new()
    var traversal := BaseTraversalClass.new()
    var doors := DoorStateClass.new()
    var door_mutations := DoorMutationClass.new(doors, world)
    _check(FixtureClass.build(world, mutations, collision_catalog, traversal, doors, door_mutations), "trailer critique fixture materializes")
    _check(world.has_entity(FixtureClass.EXTERIOR_DOOR_ID), "generated stable exterior door exists")
    _check(doors.door_ids().size() == 3, "all three generated doors explicitly enrolled")
    for door_id: String in doors.door_ids():
        _check(doors.state(door_id) == DoorValue.CLOSED, "generated door begins closed")

    var coverage_query := SpatialQueryClass.new(world, collision_catalog, collision_overrides)
    var coverage: Dictionary = coverage_query.collision_coverage_report()
    _check((coverage.get("missing_required_profiles", []) as Array).is_empty(), "generated structure/prop collision coverage complete")

    var art := ArtCatalogClass.new()
    for entity_id: String in world.entity_ids():
        var entity: WorldEntityRecord = world.entity(entity_id)
        if entity == null:
            continue
        var semantic: String = String(entity.semantic_type)
        if semantic.begins_with("wall."):
            _check(art.resolve_wall(entity.semantic_type).is_found(), "generated wall has art")
        elif semantic.begins_with("door."):
            _check(art.resolve_door(entity.semantic_type, false).is_found(), "generated door has art")
        elif semantic.begins_with("window."):
            _check(art.resolve_window(entity.semantic_type).is_found(), "generated window has art")
        elif semantic.begins_with("prop."):
            _check(art.resolve_prop(entity.semantic_type).is_found(), "generated prop has art")
    for y in range(FixtureClass.MAP_SIZE.y):
        for x in range(FixtureClass.MAP_SIZE.x):
            var cell := Vector2i(x, y)
            _check(art.resolve_ground(world.terrain_at(cell)).is_found(), "critique lot terrain has art")

    var transition := DoorTransitionClass.new(world, doors, door_mutations, collision_overrides)
    var passage := DoorPassageClass.new(world, doors, transition)
    var kernel := TickKernelClass.new(FixtureClass.PLAYER_ID)
    var movement := MovementClass.new(world, mutations, coverage_query, kernel, traversal, passage)
    var enter = movement.request_step_forward(FixtureClass.PLAYER_ID)
    _check(enter != null and enter.is_accepted(), "generated exterior door accepts automatic Walk passage")
    kernel.run_until_stop()
    _check(doors.state(FixtureClass.EXTERIOR_DOOR_ID) == DoorValue.OPEN, "generated exterior door opens through System 18")
    _check(world.placement(FixtureClass.PLAYER_ID).anchor == Vector2i(7, 3), "player enters generated exterior doorway")

    var stack := RendererStackClass.new()
    get_root().add_child(stack)
    _check(stack.configure(world, art, doors, FixtureClass.PLAYER_ID), "renderer stack configures generated critique lot")
    _check(stack.set_visible_window(FixtureClass.MAP_ORIGIN, FixtureClass.MAP_SIZE, 38.0), "renderer uses fixed one-screen critique window")
    var diagnostics: Dictionary = stack.planned_diagnostic_counts()
    _check(int(diagnostics.get("ground", -1)) == 0 and int(diagnostics.get("structure", -1)) == 0 and int(diagnostics.get("prop", -1)) == 0 and int(diagnostics.get("actor", -1)) == 0, "generated critique lot renders without diagnostics")
    stack.queue_free()

    if failures.is_empty():
        print("LOCAL_BUILDING_GENERATION_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("LOCAL_BUILDING_GENERATION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
