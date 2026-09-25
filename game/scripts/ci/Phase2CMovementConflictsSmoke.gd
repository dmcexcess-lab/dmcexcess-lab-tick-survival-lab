extends SceneTree

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const QueryRules = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE2C_MOVEMENT_CONFLICTS: " + message)
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
        _fail("production movement owners are incomplete")
        return

    var infected_ids: Array[String] = cohort.roster_actor_ids()
    if infected_ids.size() < 2:
        _fail("need two production infected for movement conflicts")
        return
    var actor_a: String = infected_ids[0]
    var actor_b: String = infected_ids[1]
    for infected_id: String in infected_ids:
        var behavior: CohortInfectedBehaviorService = cohort.behavior_for_actor(infected_id)
        if behavior != null:
            behavior.deactivate(&"focused_verifier")

    kernel.set_decision_actor("")
    var cells: Array[Vector2i] = _find_clear_horizontal_run(query, world.placement(actor_a).anchor, 5)
    if cells.size() != 5:
        _fail("could not find clear focused movement fixture")
        return

    var committed: Array[Dictionary] = []
    var failed: Array[Dictionary] = []
    movement.movement_committed.connect(func(actor_id: String, serial: int, action_type: StringName, target_anchor: Vector2i, _target_facing: int) -> void:
        committed.append({"actor": actor_id, "serial": serial, "action": String(action_type), "target": target_anchor, "tick": kernel.world_tick()})
    )
    movement.movement_failed.connect(func(actor_id: String, serial: int, action_type: StringName, reason: String) -> void:
        failed.append({"actor": actor_id, "serial": serial, "action": String(action_type), "reason": reason, "tick": kernel.world_tick()})
    )

    # Same-destination contest: neither actor gets hidden initiative.
    if not _place_actor(mutations, world, actor_a, cells[0], Facing.Value.EAST)         or not _place_actor(mutations, world, actor_b, cells[2], Facing.Value.WEST):
        _fail("could not arrange same-destination contest")
        return
    var contest_a: MovementActionResult = movement.request_step_forward(actor_a)
    var contest_b: MovementActionResult = movement.request_step_forward(actor_b)
    if contest_a == null or contest_b == null or not contest_a.is_accepted() or not contest_b.is_accepted():
        _fail("same-destination actions were not both accepted")
        return
    if contest_a.duration_ticks != contest_b.duration_ticks:
        _fail("focused same-destination actions do not share a due tick")
        return
    _run_actions(kernel, [contest_a.action_serial, contest_b.action_serial])
    if world.placement(actor_a).anchor != cells[0] or world.placement(actor_b).anchor != cells[2]:
        _fail("same-destination contest awarded a hidden winner")
        return
    var contest_failures: int = 0
    for entry: Dictionary in failed:
        if int(entry.get("serial", 0)) in [contest_a.action_serial, contest_b.action_serial]             and String(entry.get("reason", "")) == "target_contested":
            contest_failures += 1
    if contest_failures != 2:
        _fail("same-destination contest did not fail both claimants explicitly")
        return
    var contest_tick: int = _event_tick_for_serial(failed, contest_a.action_serial)

    # Direct reciprocal swap: both actors vacate simultaneously, so both moves succeed.
    committed.clear()
    failed.clear()
    if not _place_actor(mutations, world, actor_a, cells[3], Facing.Value.EAST)         or not _place_actor(mutations, world, actor_b, cells[4], Facing.Value.WEST):
        _fail("could not arrange reciprocal swap")
        return
    var swap_a: MovementActionResult = movement.request_step_forward(actor_a)
    var swap_b: MovementActionResult = movement.request_step_forward(actor_b)
    if swap_a == null or swap_b == null or not swap_a.is_accepted() or not swap_b.is_accepted():
        _fail("reciprocal occupied-cell moves were not both accepted for timestamp arbitration")
        return
    if swap_a.duration_ticks != swap_b.duration_ticks:
        _fail("focused reciprocal actions do not share a due tick")
        return
    _run_actions(kernel, [swap_a.action_serial, swap_b.action_serial])
    if world.placement(actor_a).anchor != cells[4] or world.placement(actor_b).anchor != cells[3]:
        _fail("reciprocal swap did not commit atomically")
        return
    var swap_commits: int = 0
    for entry: Dictionary in committed:
        if int(entry.get("serial", 0)) in [swap_a.action_serial, swap_b.action_serial]:
            swap_commits += 1
    if swap_commits != 2:
        _fail("reciprocal swap did not publish both commits")
        return

    print("PHASE2C_MOVEMENT_CONFLICTS_OK contest_tick=%d swap_tick=%d no_hidden_winner=true" % [
        contest_tick,
        _event_tick_for_serial(committed, swap_a.action_serial),
    ])
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

static func _event_tick_for_serial(entries: Array[Dictionary], serial: int) -> int:
    for entry: Dictionary in entries:
        if int(entry.get("serial", 0)) == serial:
            return int(entry.get("tick", -1))
    return -1
