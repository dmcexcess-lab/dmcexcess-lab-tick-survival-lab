extends SceneTree

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const QueryRules = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE2C_STAT_CONTESTS: " + message)
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
    var carry_state: ActorCarryState = game.get("_carry_state")
    var kernel: TickKernel = game.get("_kernel")
    var cohort: ActiveInfectedCohortService = game.infected_cohort_service()
    if movement == null or world == null or mutations == null or query == null         or carry_state == null or kernel == null or cohort == null:
        _fail("production stat-contest owners are incomplete")
        return

    var infected_ids: Array[String] = cohort.roster_actor_ids()
    if infected_ids.size() < 2:
        _fail("need two production infected")
        return
    var strong: String = infected_ids[0]
    var weak: String = infected_ids[1]
    for infected_id: String in infected_ids:
        var behavior: CohortInfectedBehaviorService = cohort.behavior_for_actor(infected_id)
        if behavior != null:
            behavior.deactivate(&"focused_verifier")

    kernel.set_decision_actor("")
    var cells: Array[Vector2i] = _find_clear_horizontal_run(query, world.placement(strong).anchor, 3)
    if cells.size() != 3:
        _fail("could not find clear contest fixture")
        return

    var committed: Array[Dictionary] = []
    var failed: Array[Dictionary] = []
    movement.movement_committed.connect(func(actor_id: String, serial: int, _action_type: StringName, target_anchor: Vector2i, _target_facing: int) -> void:
        committed.append({"actor": actor_id, "serial": serial, "target": target_anchor, "tick": kernel.world_tick()})
    )
    movement.movement_failed.connect(func(actor_id: String, serial: int, _action_type: StringName, reason: String) -> void:
        failed.append({"actor": actor_id, "serial": serial, "reason": reason, "tick": kernel.world_tick()})
    )

    # Unique stronger physical stat wins the simultaneous shared-space contest.
    if not carry_state.set_capacity_grams(strong, 24000) or not carry_state.set_capacity_grams(weak, 12000):
        _fail("could not set focused physical capacities")
        return
    if not _place_actor(mutations, world, strong, cells[0], Facing.Value.EAST)         or not _place_actor(mutations, world, weak, cells[2], Facing.Value.WEST):
        _fail("could not arrange unequal-stat contest")
        return
    var strong_move: MovementActionResult = movement.request_step_forward(strong)
    var weak_move: MovementActionResult = movement.request_step_forward(weak)
    if strong_move == null or weak_move == null or not strong_move.is_accepted() or not weak_move.is_accepted():
        _fail("unequal-stat contest moves were not both accepted")
        return
    if strong_move.duration_ticks != weak_move.duration_ticks:
        _fail("capacity stat unexpectedly changed movement timestamp")
        return
    _run_actions(kernel, [strong_move.action_serial, weak_move.action_serial])

    if world.placement(strong).anchor != cells[1] or world.placement(weak).anchor != cells[2]:
        _fail("higher physical score did not win the shared destination")
        return
    if not _has_failure(failed, weak_move.action_serial, "target_contest_lost"):
        _fail("losing actor did not receive explicit stat-contest loss")
        return

    # Exact physical tie remains a stalemate; no ID/order tiebreaker is allowed.
    committed.clear()
    failed.clear()
    if not carry_state.set_capacity_grams(strong, 18000) or not carry_state.set_capacity_grams(weak, 18000):
        _fail("could not set tied physical capacities")
        return
    if not _place_actor(mutations, world, strong, cells[0], Facing.Value.EAST)         or not _place_actor(mutations, world, weak, cells[2], Facing.Value.WEST):
        _fail("could not arrange tied contest")
        return
    var tie_a: MovementActionResult = movement.request_step_forward(strong)
    var tie_b: MovementActionResult = movement.request_step_forward(weak)
    if tie_a == null or tie_b == null or not tie_a.is_accepted() or not tie_b.is_accepted():
        _fail("tied contest moves were not both accepted")
        return
    _run_actions(kernel, [tie_a.action_serial, tie_b.action_serial])

    if world.placement(strong).anchor != cells[0] or world.placement(weak).anchor != cells[2]:
        _fail("exact stat tie used hidden initiative")
        return
    if not _has_failure(failed, tie_a.action_serial, "target_contest_tied")         or not _has_failure(failed, tie_b.action_serial, "target_contest_tied"):
        _fail("exact stat tie did not fail both actors explicitly")
        return

    print("PHASE2C_STAT_CONTESTS_OK unequal_winner=%s tied_stalemate=true" % strong)
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
