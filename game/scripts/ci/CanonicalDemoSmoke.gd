extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const CollisionCatalogClass = preload("res://scripts/simulation/collision/CollisionCatalog.gd")
const CollisionOverridesClass = preload("res://scripts/simulation/collision/CollisionOverrideState.gd")
const SpatialQueryClass = preload("res://scripts/simulation/collision/SpatialQueryService.gd")
const QueryResultClass = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const BaseTraversalClass = preload("res://scripts/simulation/movement/MovementTraversalPolicy.gd")
const MovementClass = preload("res://scripts/simulation/movement/MovementActionService.gd")
const LocomotionStateClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionState.gd")
const LocomotionMutationClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionMutationService.gd")
const CapabilityClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementCapabilityService.gd")
const ActorTraversalClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementTraversalPolicy.gd")
const ArtCatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const FixtureClass = preload("res://scripts/demo/CanonicalDemoFixture.gd")
const RendererStackClass = preload("res://scripts/render/TacticalRendererStack.gd")
const ControllerClass = preload("res://scripts/player/PlayerActionController.gd")
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

var failures: Array[String] = []
var resolved_events: Array[Dictionary] = []

func _initialize() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var collision_catalog := CollisionCatalogClass.new()
    var collision_overrides := CollisionOverridesClass.new()
    var base_traversal := BaseTraversalClass.new()

    _check(
        FixtureClass.build(world, mutations, collision_catalog, base_traversal),
        "authored canonical fixture builds"
    )
    _check_fixture_truth(world)

    var spatial_query := SpatialQueryClass.new(world, collision_catalog, collision_overrides)
    var coverage: Dictionary = spatial_query.collision_coverage_report()
    _check(
        (coverage.get("missing_required_profiles", []) as Array).is_empty(),
        "all placed actor/structure/object collision is classified"
    )
    var wall_query = spatial_query.query_cell(Vector2i(1, 1), FixtureClass.PLAYER_ID, true)
    _check(wall_query.status == QueryResultClass.Status.BLOCKED, "authored wall cell blocks movement")

    var locomotion_state := LocomotionStateClass.new()
    var locomotion_mutations := LocomotionMutationClass.new(locomotion_state)
    _check(locomotion_mutations.enroll(FixtureClass.PLAYER_ID), "demo survivor enrolled in locomotion")
    var capability := CapabilityClass.new(locomotion_state)
    var actor_traversal := ActorTraversalClass.new(base_traversal, capability)
    var kernel := TickKernelClass.new(FixtureClass.PLAYER_ID)
    var movement := MovementClass.new(world, mutations, spatial_query, kernel, actor_traversal)
    _check(movement.is_ready(), "canonical movement stack ready")

    var controller := ControllerClass.new(movement, kernel, FixtureClass.PLAYER_ID)
    controller.action_resolved.connect(_on_action_resolved)
    _check(controller.is_ready(), "semantic player action controller ready")

    controller.submit_intent(Intents.FORWARD)
    var after_walk = world.placement(FixtureClass.PLAYER_ID)
    _check(after_walk != null and after_walk.anchor == Vector2i(6, 9), "forward intent commits expected world cell")
    _check(kernel.world_tick() == FixtureClass.BASE_WALK_TICKS, "forward intent spends recovered 10 walking ticks")
    _check(_last_resolution_success(), "forward intent reports committed success")

    controller.submit_intent(Intents.TURN_RIGHT)
    var after_turn = world.placement(FixtureClass.PLAYER_ID)
    _check(after_turn != null and after_turn.facing == Facing.Value.EAST, "turn-right intent commits east facing")
    _check(kernel.world_tick() == FixtureClass.BASE_WALK_TICKS + 3, "turn intent spends existing 3 turn ticks")
    _check(_last_resolution_success(), "turn intent reports committed success")

    _check_renderer_stack(world)

    if failures.is_empty():
        print("CANONICAL_DEMO_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("CANONICAL_DEMO_SMOKE_FAIL: %s" % failure)
    quit(1)

func _check_fixture_truth(world: WorldState) -> void:
    var terrain_count: int = 0
    for y in range(FixtureClass.MAP_SIZE.y):
        for x in range(FixtureClass.MAP_SIZE.x):
            if world.has_terrain(FixtureClass.MAP_ORIGIN + Vector2i(x, y)):
                terrain_count += 1
    _check(terrain_count == 169, "all 169 authored map cells have canonical terrain")

    var actor_ids: Array[String] = []
    for entity_id: String in world.entity_ids():
        var entity = world.entity(entity_id)
        if entity != null and String(entity.semantic_type).begins_with("actor."):
            actor_ids.append(entity_id)
    actor_ids.sort()
    _check(actor_ids == [FixtureClass.PLAYER_ID], "fixture contains exactly one actor and no NPC/infected")
    var player = world.entity(FixtureClass.PLAYER_ID)
    _check(player != null and player.semantic_type == &"actor.survivor", "only actor is a survivor")

func _check_renderer_stack(world: WorldState) -> void:
    var stack := RendererStackClass.new()
    get_root().add_child(stack)
    var catalog := ArtCatalogClass.new()
    var doors := DoorStateClass.new()
    _check(stack.configure(world, catalog, doors, FixtureClass.PLAYER_ID), "renderer stack configures existing layer renderers")
    _check(
        stack.set_visible_window(FixtureClass.MAP_ORIGIN, FixtureClass.MAP_SIZE, 38.0),
        "renderer stack accepts authored visible window"
    )
    var counts: Dictionary = stack.layer_command_counts()
    _check(int(counts.get("ground", -1)) == 169, "renderer stack plans all 169 ground cells")
    _check(int(counts.get("structure", -1)) == 11, "renderer stack plans 11 authored wall cells")
    _check(int(counts.get("prop", -1)) == 6, "renderer stack plans six authored props")
    _check(int(counts.get("actor", -1)) == 1, "renderer stack plans exactly one living actor")
    var diagnostics: Dictionary = stack.planned_diagnostic_counts()
    _check(int(diagnostics.get("ground", -1)) == 0, "ground fixture has no planned diagnostics")
    _check(int(diagnostics.get("structure", -1)) == 0, "structure fixture has no planned diagnostics")
    _check(int(diagnostics.get("prop", -1)) == 0, "prop fixture has no planned diagnostics")
    _check(int(diagnostics.get("actor", -1)) == 0, "actor fixture has no planned diagnostics")
    stack.queue_free()

func _on_action_resolved(intent: StringName, success: bool, reason: String, world_tick: int) -> void:
    resolved_events.append({
        "intent": intent,
        "success": success,
        "reason": reason,
        "world_tick": world_tick,
    })

func _last_resolution_success() -> bool:
    if resolved_events.is_empty():
        return false
    return bool(resolved_events[-1].get("success", false))

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
