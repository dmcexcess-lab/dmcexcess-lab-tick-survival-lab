extends SceneTree

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
const DoorActionClass = preload("res://scripts/simulation/doors/DoorInteractionActionService.gd")
const DoorDamageClass = preload("res://scripts/simulation/doors/DoorDamageInterruptionService.gd")
const MovementDamageClass = preload("res://scripts/simulation/movement/MovementDamageInterruptionService.gd")
const HealthClass = preload("res://scripts/simulation/actors/health/ActorHealthState.gd")
const PointerClass = preload("res://scripts/input/DoorPointerInputAdapter.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Axis = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")

const ACTOR_ID := "actor.door.test"
const DOOR_ID := "door.test.1"
const ACTOR_SEM := &"actor.survivor"
const DOOR_SEM := &"door.house"
const GROUND := &"ground.grass_lush"

var failures: Array[String] = []
var transitions: Array[Dictionary] = []

func _initialize() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var catalog := CollisionCatalogClass.new()
    var overrides := CollisionOverridesClass.new()
    var traversal := BaseTraversalClass.new()
    _check(catalog.register(ACTOR_SEM, true), "actor collision registered")
    _check(catalog.register(DOOR_SEM, true), "door collision registered")
    _check(traversal.register_terrain(GROUND, true, 10), "terrain timing registered")
    for y in range(3):
        for x in range(5):
            _check(mutations.set_terrain(Vector2i(x, y), GROUND), "terrain seeded")
    _check(mutations.create_entity(ACTOR_SEM, ACTOR_ID) == ACTOR_ID, "actor created")
    _check(mutations.set_placement(ACTOR_ID, Layers.Channel.ACTOR, Vector2i(1, 1), Facing.Value.EAST, Footprint.single_cell()), "actor placed")
    _check(mutations.create_entity(DOOR_SEM, DOOR_ID) == DOOR_ID, "door created")
    _check(mutations.set_placement(DOOR_ID, Layers.Channel.STRUCTURE, Vector2i(2, 1), Facing.Value.NORTH, Footprint.single_cell(), Axis.Axis.VERTICAL), "door placed")

    var doors := DoorStateClass.new()
    var door_mutations := DoorMutationClass.new(doors, world)
    _check(door_mutations.enroll(DOOR_ID, DoorValue.CLOSED), "door explicitly enrolled closed")
    var transition := DoorTransitionClass.new(world, doors, door_mutations, overrides)
    transition.transition_resolved.connect(_on_transition)
    var passage := DoorPassageClass.new(world, doors, transition)
    var query := SpatialQueryClass.new(world, catalog, overrides)
    var kernel := TickKernelClass.new(ACTOR_ID)
    var movement := MovementClass.new(world, mutations, query, kernel, traversal, passage)
    var health := HealthClass.new(world)
    _check(health.enroll_actor(ACTOR_ID), "health enrolled")
    var movement_damage := MovementDamageClass.new(health, kernel)
    var door_actions := DoorActionClass.new(world, doors, kernel, transition)
    var door_damage := DoorDamageClass.new(health, kernel)
    _check(movement.is_ready() and movement.passage_ready(), "passage movement ready")
    _check(movement_damage.is_ready() and door_actions.is_ready() and door_damage.is_ready(), "damage/door action coordinators ready")

    var walk = movement.request_step_forward(ACTOR_ID)
    _check(walk != null and walk.is_accepted(), "closed door is conditionally accepted by Walk")
    _check(doors.state(DOOR_ID) == DoorValue.CLOSED, "Walk request does not open door early")
    _check(health.apply_damage(ACTOR_ID, 1), "damage applied during Walk")
    kernel.run_until_stop()
    _check(doors.state(DOOR_ID) == DoorValue.CLOSED, "damage-canceled Walk leaves door closed")
    _check(world.placement(ACTOR_ID).anchor == Vector2i(1, 1), "damage-canceled Walk leaves actor outside")

    walk = movement.request_step_forward(ACTOR_ID)
    _check(walk != null and walk.is_accepted(), "Walk through closed door accepted")
    kernel.run_until_stop()
    _check(doors.state(DOOR_ID) == DoorValue.OPEN, "Walk opens door at commit")
    _check(overrides.has_override(DOOR_ID) and not overrides.blocks_movement(DOOR_ID), "open door owns nonblocking override")
    _check(world.placement(ACTOR_ID).anchor == Vector2i(2, 1), "Walk enters doorway")

    _check(mutations.set_placement(ACTOR_ID, Layers.Channel.ACTOR, Vector2i(3, 1), Facing.Value.EAST, Footprint.single_cell()), "actor moved inside facing away")
    var close_wrong = door_actions.request_close(ACTOR_ID, DOOR_ID)
    _check(close_wrong.reason == "not_facing_door", "manual close requires facing door")
    _check(kernel.world_tick() == 10, "wrong-facing close spends zero ticks")
    _check(mutations.set_placement(ACTOR_ID, Layers.Channel.ACTOR, Vector2i(3, 1), Facing.Value.WEST, Footprint.single_cell()), "actor turned toward door")
    var close_ok = door_actions.request_close(ACTOR_ID, DOOR_ID)
    _check(close_ok != null and close_ok.is_accepted() and close_ok.duration_ticks == 3, "facing close accepts 3-tick action")
    kernel.run_until_stop()
    _check(doors.state(DOOR_ID) == DoorValue.CLOSED, "manual close commits closed")
    _check(not overrides.has_override(DOOR_ID), "closed door returns to blocking type default")

    _check(mutations.set_placement(ACTOR_ID, Layers.Channel.ACTOR, Vector2i(1, 1), Facing.Value.EAST, Footprint.single_cell()), "actor reset for Run")
    var hp_before_run: int = health.current_hp(ACTOR_ID)
    transitions.clear()
    var run = movement.request_run_forward(ACTOR_ID)
    _check(run != null and run.is_accepted(), "Run commits toward closed door")
    kernel.run_until_stop()
    _check(world.placement(ACTOR_ID).anchor == Vector2i(3, 1), "Run crosses closed door for two cells")
    _check(doors.state(DOOR_ID) == DoorValue.OPEN, "Run opens door")
    _check(health.current_hp(ACTOR_ID) == hp_before_run, "door passage causes no run-impact HP damage")
    _check(_saw_loud_run_transition(), "Run auto-open emits LOUD semantic transition")

    _check(mutations.set_placement(ACTOR_ID, Layers.Channel.ACTOR, Vector2i(3, 1), Facing.Value.WEST, Footprint.single_cell()), "actor faces open door for damage-close test")
    var close_damage = door_actions.request_close(ACTOR_ID, DOOR_ID)
    _check(close_damage != null and close_damage.is_accepted(), "manual close begins before damage")
    _check(health.apply_damage(ACTOR_ID, 1), "damage applied during close")
    kernel.run_until_stop()
    _check(doors.state(DOOR_ID) == DoorValue.OPEN, "damage-canceled close leaves door open")

    var pointer := PointerClass.new()
    get_root().add_child(pointer)
    _check(pointer.configure(Vector2(73, 72), Vector2i.ZERO, Vector2i(13, 13), 38.0), "pointer mapper configures")
    var mapped: Variant = pointer.world_cell_for_screen(Vector2(73 + 2 * 38 + 4, 72 + 1 * 38 + 4))
    _check(mapped != null and mapped as Vector2i == Vector2i(2, 1), "screen pointer maps exact world cell")
    pointer.queue_free()

    if failures.is_empty():
        print("DOOR_INTERACTION_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("DOOR_INTERACTION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _on_transition(actor_id: String, door_id: String, previous_state: StringName, new_state: StringName, cause: StringName, noise_class: StringName, cell: Vector2i) -> void:
    transitions.append({"actor_id": actor_id, "door_id": door_id, "previous": previous_state, "new": new_state, "cause": cause, "noise": noise_class, "cell": cell})

func _saw_loud_run_transition() -> bool:
    for event: Dictionary in transitions:
        if event.get("cause", &"") == &"run_passage" and event.get("noise", &"") == &"loud":
            return true
    return false

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
