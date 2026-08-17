extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const CatalogClass = preload("res://scripts/simulation/collision/CollisionCatalog.gd")
const OverrideClass = preload("res://scripts/simulation/collision/CollisionOverrideState.gd")
const QueryClass = preload("res://scripts/simulation/collision/SpatialQueryService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const TickRules = preload("res://scripts/foundation/time/TickRules.gd")
const PolicyClass = preload("res://scripts/simulation/movement/MovementTraversalPolicy.gd")
const MovementClass = preload("res://scripts/simulation/movement/MovementActionService.gd")
const MovementResult = preload("res://scripts/simulation/movement/MovementActionResult.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_forward_commit_and_backward()
    _test_turns_and_variable_cost()
    _test_fail_closed_requests()
    _test_mid_action_blocker()
    _test_race_for_same_cell()
    _test_origin_change()
    _test_multi_cell_rotation()
    _test_hard_pause_and_committed_interrupt()

    if _failures.is_empty():
        print("MOVEMENT_ACTIONS_SMOKE_OK")
        quit(0)
        return

    for failure: String in _failures:
        push_error("MOVEMENT_ACTIONS_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture() -> Dictionary:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var catalog := CatalogClass.new()
    var overrides := OverrideClass.new()
    var query := QueryClass.new(world, catalog, overrides)
    var kernel := TickKernelClass.new()
    var policy := PolicyClass.new(3)
    var movement := MovementClass.new(world, mutations, query, kernel, policy)

    _check(catalog.register(&"actor.person", true), "fixture actor collision profile")
    _check(catalog.register(&"structure.wall", true), "fixture wall collision profile")
    _check(policy.register_terrain(&"ground.test", true, 10), "fixture normal terrain policy")
    _check(policy.register_terrain(&"ground.fast", true, 4), "fixture fast terrain policy")
    _check(policy.register_terrain(&"ground.slow", true, 12), "fixture slow terrain policy")
    _check(policy.register_terrain(&"ground.water", false), "fixture blocked terrain policy")

    for y: int in range(0, 16):
        for x: int in range(0, 20):
            _check(mutations.set_terrain(Vector2i(x, y), &"ground.test"), "fixture terrain setup")

    _check(movement.is_ready(), "movement composes WHERE + WHAT + Collision + WHEN")
    return {
        "world": world,
        "mutations": mutations,
        "catalog": catalog,
        "overrides": overrides,
        "query": query,
        "kernel": kernel,
        "policy": policy,
        "movement": movement,
    }

func _place_actor(fixture: Dictionary, actor_id: String, anchor: Vector2i, facing: int, footprint: SpatialFootprint = null) -> void:
    var mutations: WorldMutationService = fixture["mutations"]
    var actual_footprint: SpatialFootprint = footprint
    if actual_footprint == null:
        actual_footprint = Footprint.single_cell()
    _check(mutations.create_entity(&"actor.person", actor_id) == actor_id, "create %s" % actor_id)
    _check(
        mutations.set_placement(actor_id, Layers.Channel.ACTOR, anchor, facing, actual_footprint),
        "place %s" % actor_id
    )

func _place_wall(fixture: Dictionary, wall_id: String, anchor: Vector2i) -> void:
    var mutations: WorldMutationService = fixture["mutations"]
    _check(mutations.create_entity(&"structure.wall", wall_id) == wall_id, "create %s" % wall_id)
    _check(
        mutations.set_placement(wall_id, Layers.Channel.STRUCTURE, anchor, Facing.Value.NORTH, Footprint.single_cell()),
        "place %s" % wall_id
    )

func _test_forward_commit_and_backward() -> void:
    var fixture: Dictionary = _fixture()
    var world: WorldState = fixture["world"]
    var kernel: TickKernel = fixture["kernel"]
    var movement: MovementActionService = fixture["movement"]
    _place_actor(fixture, "actor_forward", Vector2i(2, 2), Facing.Value.EAST)

    var forward: MovementActionResult = movement.request_step_forward("actor_forward")
    _check(forward.is_accepted(), "forward request accepted")
    _check(forward.duration_ticks == 10 and forward.target_anchor == Vector2i(3, 2), "forward uses policy duration and facing target")
    _check(world.placement("actor_forward").anchor == Vector2i(2, 2), "forward does not mutate WHAT at request time")

    _check(kernel.schedule_event(5, "movement_smoke", &"test.midpoint") > 0, "midpoint event scheduled")
    _check(kernel.run_next_batch() == TickRules.RunStopReason.BATCH_COMPLETE, "kernel reaches midpoint batch")
    _check(kernel.world_tick() == 5, "movement time advances to midpoint")
    _check(world.placement("actor_forward").anchor == Vector2i(2, 2), "forward remains uncommitted before final tick")

    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "forward action drains")
    var after_forward: WorldPlacement = world.placement("actor_forward")
    _check(kernel.world_tick() == 10, "forward commits at configured final tick")
    _check(after_forward.anchor == Vector2i(3, 2) and after_forward.facing == Facing.Value.EAST, "forward commits target placement")

    var backward: MovementActionResult = movement.request_step_backward("actor_forward")
    _check(backward.is_accepted() and backward.target_anchor == Vector2i(2, 2), "backward request targets opposite cell")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "backward action drains")
    var after_backward: WorldPlacement = world.placement("actor_forward")
    _check(after_backward.anchor == Vector2i(2, 2), "backward commits opposite cell")
    _check(after_backward.facing == Facing.Value.EAST, "backward preserves facing")

func _test_turns_and_variable_cost() -> void:
    var fixture: Dictionary = _fixture()
    var world: WorldState = fixture["world"]
    var mutations: WorldMutationService = fixture["mutations"]
    var kernel: TickKernel = fixture["kernel"]
    var movement: MovementActionService = fixture["movement"]
    _place_actor(fixture, "actor_turn", Vector2i(5, 2), Facing.Value.EAST)

    var left: MovementActionResult = movement.request_turn_left("actor_turn")
    _check(left.is_accepted() and left.duration_ticks == 3, "turn uses independent turn duration")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "left turn drains")
    _check(world.placement("actor_turn").anchor == Vector2i(5, 2), "turn keeps anchor")
    _check(world.placement("actor_turn").facing == Facing.Value.NORTH, "left turn rotates 90 degrees")

    var right: MovementActionResult = movement.request_turn_right("actor_turn")
    _check(right.is_accepted(), "right turn accepted")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "right turn drains")
    _check(world.placement("actor_turn").facing == Facing.Value.EAST, "right turn restores facing")

    _check(mutations.set_terrain(Vector2i(6, 2), &"ground.slow"), "slow target terrain set")
    var slow_step: MovementActionResult = movement.request_step_forward("actor_turn")
    _check(slow_step.is_accepted() and slow_step.duration_ticks == 12, "step duration comes from semantic terrain policy")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "slow step drains")
    _check(kernel.world_tick() == 18, "turn + turn + slow step consume 3 + 3 + 12 ticks")

func _test_fail_closed_requests() -> void:
    var fixture: Dictionary = _fixture()
    var mutations: WorldMutationService = fixture["mutations"]
    var kernel: TickKernel = fixture["kernel"]
    var movement: MovementActionService = fixture["movement"]
    _place_actor(fixture, "actor_fail", Vector2i(2, 4), Facing.Value.EAST)

    _place_wall(fixture, "wall_static", Vector2i(3, 4))
    var blocked: MovementActionResult = movement.request_step_forward("actor_fail")
    _check(blocked.status == MovementResult.Status.TARGET_BLOCKED, "static blocker rejects move before spending time")
    _check(kernel.world_tick() == 0 and not kernel.has_active_action("actor_fail"), "rejected blocker consumes no ticks")

    _check(mutations.unplace_entity("wall_static"), "remove static blocker placement")
    _check(mutations.set_terrain(Vector2i(3, 4), &"ground.unclassified"), "unclassified semantic terrain set")
    var unclassified: MovementActionResult = movement.request_step_forward("actor_fail")
    _check(unclassified.status == MovementResult.Status.TERRAIN_UNCLASSIFIED, "unregistered terrain policy fails closed")

    _check(mutations.set_terrain(Vector2i(3, 4), &"ground.water"), "blocked semantic terrain set")
    var terrain_blocked: MovementActionResult = movement.request_step_forward("actor_fail")
    _check(terrain_blocked.status == MovementResult.Status.TERRAIN_BLOCKED, "explicitly non-traversable terrain rejects step")

    _check(mutations.clear_terrain(Vector2i(3, 4)), "target terrain cleared")
    var missing: MovementActionResult = movement.request_step_forward("actor_fail")
    _check(missing.status == MovementResult.Status.TARGET_UNKNOWN, "missing terrain is UNKNOWN before traversal policy")

func _test_mid_action_blocker() -> void:
    var fixture: Dictionary = _fixture()
    var world: WorldState = fixture["world"]
    var kernel: TickKernel = fixture["kernel"]
    var movement: MovementActionService = fixture["movement"]
    _place_actor(fixture, "actor_midblock", Vector2i(2, 6), Facing.Value.EAST)

    var failures: Array[String] = []
    movement.movement_failed.connect(func(_actor_id, _serial, _type, reason): failures.append(String(reason)))

    var move: MovementActionResult = movement.request_step_forward("actor_midblock")
    _check(move.is_accepted(), "mid-action blocker move initially accepted")
    _check(kernel.schedule_event(5, "movement_smoke", &"test.midblock") > 0, "midblock midpoint event scheduled")
    _check(kernel.run_next_batch() == TickRules.RunStopReason.BATCH_COMPLETE, "midblock reaches tick 5")
    _place_wall(fixture, "wall_midblock", Vector2i(3, 6))
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "midblock action resolves")
    _check(kernel.world_tick() == 10, "failed commit still consumes full movement duration")
    _check(world.placement("actor_midblock").anchor == Vector2i(2, 6), "mid-action blocker leaves actor at origin")
    _check(failures == ["target_blocked"], "mid-action blocker reports deterministic commit failure")

func _test_race_for_same_cell() -> void:
    var fixture: Dictionary = _fixture()
    var world: WorldState = fixture["world"]
    var kernel: TickKernel = fixture["kernel"]
    var movement: MovementActionService = fixture["movement"]
    _place_actor(fixture, "actor_a", Vector2i(2, 8), Facing.Value.EAST)
    _place_actor(fixture, "actor_b", Vector2i(4, 8), Facing.Value.WEST)

    var a: MovementActionResult = movement.request_step_forward("actor_a")
    var b: MovementActionResult = movement.request_step_forward("actor_b")
    _check(a.is_accepted() and b.is_accepted(), "same-cell race accepts both requests without reservation")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "same-cell race resolves")
    _check(world.placement("actor_a").anchor == Vector2i(3, 8), "deterministic first actor commits contested cell")
    _check(world.placement("actor_b").anchor == Vector2i(4, 8), "second actor fails revalidation and stays put")
    _check(not kernel.has_active_action("actor_a") and not kernel.has_active_action("actor_b"), "race leaves no stale active actions")

func _test_origin_change() -> void:
    var fixture: Dictionary = _fixture()
    var world: WorldState = fixture["world"]
    var mutations: WorldMutationService = fixture["mutations"]
    var kernel: TickKernel = fixture["kernel"]
    var movement: MovementActionService = fixture["movement"]
    _place_actor(fixture, "actor_displaced", Vector2i(2, 10), Facing.Value.EAST)

    var move: MovementActionResult = movement.request_step_forward("actor_displaced")
    _check(move.is_accepted(), "displacement test move accepted")
    _check(kernel.schedule_event(5, "movement_smoke", &"test.displace") > 0, "displacement midpoint event scheduled")
    _check(kernel.run_next_batch() == TickRules.RunStopReason.BATCH_COMPLETE, "displacement reaches tick 5")
    _check(
        mutations.set_placement("actor_displaced", Layers.Channel.ACTOR, Vector2i(2, 11), Facing.Value.SOUTH, Footprint.single_cell()),
        "external displacement mutates WHAT"
    )
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "stale move resolves after displacement")
    var placement: WorldPlacement = world.placement("actor_displaced")
    _check(placement.anchor == Vector2i(2, 11) and placement.facing == Facing.Value.SOUTH, "stale move never overwrites newer placement truth")

func _test_multi_cell_rotation() -> void:
    var fixture: Dictionary = _fixture()
    var movement: MovementActionService = fixture["movement"]
    _place_actor(fixture, "actor_multi", Vector2i(10, 2), Facing.Value.NORTH, Footprint.rectangle(2, 1))
    _place_wall(fixture, "wall_rotation", Vector2i(10, 3))

    var turn: MovementActionResult = movement.request_turn_right("actor_multi")
    _check(turn.status == MovementResult.Status.TARGET_BLOCKED, "multi-cell rotation checks rotated footprint")

func _test_hard_pause_and_committed_interrupt() -> void:
    var cancel_fixture: Dictionary = _fixture()
    var cancel_world: WorldState = cancel_fixture["world"]
    var cancel_kernel: TickKernel = cancel_fixture["kernel"]
    var cancel_movement: MovementActionService = cancel_fixture["movement"]
    _place_actor(cancel_fixture, "actor_cancel", Vector2i(14, 2), Facing.Value.EAST)

    var cancel_walk: MovementActionResult = cancel_movement.request_step_forward("actor_cancel")
    _check(cancel_walk.is_accepted(), "cancelable walk accepted")
    _check(
        cancel_kernel.interrupt_action(cancel_walk.action_serial, "ordinary_interrupt") == TickRules.ActionStatus.CANCELED,
        "walk uses CANCELABLE interruption policy"
    )
    _check(cancel_world.placement("actor_cancel").anchor == Vector2i(14, 2), "canceled walk never commits placement")

    var pause_fixture: Dictionary = _fixture()
    var pause_world: WorldState = pause_fixture["world"]
    var pause_kernel: TickKernel = pause_fixture["kernel"]
    var pause_movement: MovementActionService = pause_fixture["movement"]
    _place_actor(pause_fixture, "actor_pause", Vector2i(14, 2), Facing.Value.EAST)

    var paused_walk: MovementActionResult = pause_movement.request_step_forward("actor_pause")
    _check(paused_walk.is_accepted(), "hard-pause walk accepted")
    pause_kernel.set_hard_paused(true)
    _check(pause_kernel.run_until_stop() == TickRules.RunStopReason.HARD_PAUSED, "hard pause stops movement kernel immediately")
    _check(pause_kernel.world_tick() == 0, "hard pause advances zero ticks")
    _check(pause_world.placement("actor_pause").anchor == Vector2i(14, 2), "hard pause preserves pre-commit placement")
    pause_kernel.set_hard_paused(false)
    _check(pause_kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "walk resumes after hard pause")
    _check(pause_world.placement("actor_pause").anchor == Vector2i(15, 2), "resumed walk completes normally")

    var turn_fixture: Dictionary = _fixture()
    var turn_world: WorldState = turn_fixture["world"]
    var turn_kernel: TickKernel = turn_fixture["kernel"]
    var turn_movement: MovementActionService = turn_fixture["movement"]
    _place_actor(turn_fixture, "actor_turn_commit", Vector2i(14, 2), Facing.Value.EAST)
    var turn: MovementActionResult = turn_movement.request_turn_left("actor_turn_commit")
    _check(turn.is_accepted(), "committed turn accepted")
    _check(
        turn_kernel.interrupt_action(turn.action_serial, "ordinary_interrupt") == TickRules.ActionStatus.RUNNING,
        "turn remains COMMITTED"
    )
    _check(turn_kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "committed turn drains")
    _check(turn_world.placement("actor_turn_commit").facing == Facing.Value.NORTH, "committed turn completes")

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
