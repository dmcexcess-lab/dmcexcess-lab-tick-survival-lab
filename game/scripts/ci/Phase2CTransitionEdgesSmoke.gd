extends SceneTree

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const QueryRules = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE2C_TRANSITION_EDGES: " + message)
    quit(1)

func _run() -> void:
    var gameplay: PackedScene = load("res://gameplay.tscn")
    if gameplay == null:
        _fail("production gameplay scene missing")
        return
    var game: Node = gameplay.instantiate()
    get_root().add_child(game)
    await process_frame

    var movement: MovementActionService = game.get("_movement")
    var world: WorldState = game.get("_world")
    var mutations: WorldMutationService = game.get("_world_mutations")
    var query: SpatialQueryService = game.get("_spatial_query")
    var kernel: TickKernel = game.get("_kernel")
    var cohort: ActiveInfectedCohortService = game.infected_cohort_service()
    if movement == null or world == null or mutations == null or query == null or kernel == null or cohort == null:
        _fail("production transition owners are incomplete")
        return

    var ids: Array[String] = cohort.roster_actor_ids()
    if ids.size() < 3:
        _fail("need three production infected")
        return
    for actor_id: String in ids:
        var behavior: CohortInfectedBehaviorService = cohort.behavior_for_actor(actor_id)
        if behavior != null:
            behavior.deactivate(&"focused_verifier")
    kernel.set_decision_actor("")

    var cells: Array[Vector2i] = _find_clear_horizontal_run(query, world.placement(ids[0]).anchor, 4)
    if cells.size() != 4:
        _fail("could not find clear transition fixture")
        return

    var failures: Array[Dictionary] = []
    movement.movement_failed.connect(func(actor_id: String, serial: int, _action_type: StringName, reason: String) -> void:
        failures.append({"actor": actor_id, "serial": serial, "reason": reason, "tick": kernel.world_tick()})
    )

    # Opposite traversal of one edge is a head-on conflict, not a free atomic swap.
    var a: String = ids[0]
    var b: String = ids[1]
    if not _place_actor(mutations, world, a, cells[0], Facing.Value.EAST)         or not _place_actor(mutations, world, b, cells[1], Facing.Value.WEST):
        _fail("could not arrange reciprocal edge fixture")
        return
    var a_move: MovementActionResult = movement.request_step_forward(a)
    var b_move: MovementActionResult = movement.request_step_forward(b)
    if a_move == null or b_move == null or not a_move.is_accepted() or not b_move.is_accepted():
        _fail("reciprocal edge moves were not accepted into timestamp arbitration")
        return
    _run_actions(kernel, [a_move.action_serial, b_move.action_serial])
    if world.placement(a).anchor != cells[0] or world.placement(b).anchor != cells[1]:
        _fail("reciprocal edge traversal incorrectly swapped actors")
        return
    if not _has_failure(failures, a_move.action_serial, "movement_edge_conflict")         or not _has_failure(failures, b_move.action_serial, "movement_edge_conflict"):
        _fail("reciprocal edge conflict did not fail both walkers explicitly")
        return

    # A release chain is different: each actor leaves its current cell and the
    # follower may inherit that vacated cell when the chain terminates in empty space.
    failures.clear()
    var c: String = ids[2]
    if not _place_actor(mutations, world, a, cells[0], Facing.Value.EAST)         or not _place_actor(mutations, world, b, cells[1], Facing.Value.EAST)         or not _place_actor(mutations, world, c, cells[2], Facing.Value.EAST):
        _fail("could not arrange release-chain fixture")
        return
    var chain_a: MovementActionResult = movement.request_step_forward(a)
    var chain_b: MovementActionResult = movement.request_step_forward(b)
    var chain_c: MovementActionResult = movement.request_step_forward(c)
    if chain_a == null or chain_b == null or chain_c == null         or not chain_a.is_accepted() or not chain_b.is_accepted() or not chain_c.is_accepted():
        _fail("release-chain moves were not accepted")
        return
    if chain_a.duration_ticks != chain_b.duration_ticks or chain_b.duration_ticks != chain_c.duration_ticks:
        _fail("release-chain actions did not share a timestamp")
        return
    _run_actions(kernel, [chain_a.action_serial, chain_b.action_serial, chain_c.action_serial])
    if world.placement(a).anchor != cells[1]         or world.placement(b).anchor != cells[2]         or world.placement(c).anchor != cells[3]:
        _fail("valid departure/arrival chain did not resolve atomically")
        return

    print("PHASE2C_TRANSITION_EDGES_OK reciprocal_blocked=true release_chain=true")
    quit(0)

func _run_actions(kernel: TickKernel, serials: Array[int]) -> void:
    for _batch: int in range(64):
        var any_active: bool = false
        for serial: int in serials:
            if kernel.action_by_serial(serial) != null:
                any_active = true
                break
        if not any_active:
            return
        kernel.run_next_batch()

func _place_actor(mutations: WorldMutationService, world: WorldState, actor_id: String, cell: Vector2i, facing: int) -> bool:
    var placement: WorldPlacement = world.placement(actor_id)
    if placement == null or placement.channel != Layers.Channel.ACTOR:
        return false
    return mutations.set_placement(actor_id, placement.channel, cell, facing, placement.footprint, placement.structure_axis)

func _find_clear_horizontal_run(query: SpatialQueryService, center: Vector2i, count: int) -> Array[Vector2i]:
    for radius: int in range(1, 18):
        for dy: int in range(-radius, radius + 1):
            for dx: int in range(-radius, radius - count + 2):
                var start := center + Vector2i(dx, dy)
                var result: Array[Vector2i] = []
                var clear: bool = true
                for offset: int in range(count):
                    var cell := start + Vector2i(offset, 0)
                    var q: SpatialQueryResult = query.query_cell(cell, "", true)
                    if q == null or q.status != QueryRules.Status.CLEAR:
                        clear = false
                        break
                    result.append(cell)
                if clear:
                    return result
    return []

static func _has_failure(entries: Array[Dictionary], serial: int, reason: String) -> bool:
    for entry: Dictionary in entries:
        if int(entry.get("serial", 0)) == serial and String(entry.get("reason", "")) == reason:
            return true
    return false
