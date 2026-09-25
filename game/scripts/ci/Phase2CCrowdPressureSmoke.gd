extends SceneTree

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const QueryRules = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")
const CombatActions = preload("res://scripts/simulation/combat/CombatActionService.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE2C_CROWD_PRESSURE: " + message)
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
    var combat: CombatActionService = game.get("_combat_actions")
    var world: WorldState = game.get("_world")
    var mutations: WorldMutationService = game.get("_world_mutations")
    var query: SpatialQueryService = game.get("_spatial_query")
    var kernel: TickKernel = game.get("_kernel")
    var carry: ActorCarryState = game.get("_carry_state")
    var cohort: ActiveInfectedCohortService = game.infected_cohort_service()
    if movement == null or combat == null or world == null or mutations == null or query == null         or kernel == null or carry == null or cohort == null:
        _fail("production crowd-pressure owners are incomplete")
        return

    var ids: Array[String] = cohort.roster_actor_ids()
    if ids.size() < 5:
        _fail("need five production infected")
        return
    for actor_id: String in ids:
        var behavior: CohortInfectedBehaviorService = cohort.behavior_for_actor(actor_id)
        if behavior != null:
            behavior.deactivate(&"focused_verifier")
    kernel.set_decision_actor("")

    var clear_run: Array[Vector2i] = _find_clear_horizontal_run(query, world.placement(ids[0]).anchor, 6)
    if clear_run.size() != 6:
        _fail("could not find clear crowd-pressure fixture")
        return

    var back: String = ids[0]
    var front: String = ids[1]
    var target: String = ids[2]
    var source_extra: String = ids[3]
    var source_opposed: String = ids[4]

    var shove_results: Array[Dictionary] = []
    combat.shove_resolved.connect(func(attacker_id: String, target_id: String, serial: int, displaced: bool) -> void:
        shove_results.append({
            "attacker": attacker_id,
            "target": target_id,
            "serial": serial,
            "displaced": displaced,
        })
    )

    # 1) Real combat chain: the rear shove transmits residual pressure through the
    # front actor and combines with the front actor's own shove. Neither input is
    # individually enough to move the final target, but their same-direction sum is.
    if not carry.set_capacity_grams(back, 12000)         or not carry.set_capacity_grams(front, 12000)         or not carry.set_capacity_grams(target, 16000):
        _fail("could not set aggregate-pressure capacities")
        return
    if not _place_actor(mutations, world, back, clear_run[0], Facing.Value.EAST)         or not _place_actor(mutations, world, front, clear_run[1], Facing.Value.EAST)         or not _place_actor(mutations, world, target, clear_run[2], Facing.Value.EAST):
        _fail("could not arrange aggregate-pressure actors")
        return

    var rear_shove: Dictionary = combat.request_action(back, front, CombatActions.SHOVE)
    var front_shove: Dictionary = combat.request_action(front, target, CombatActions.SHOVE)
    if not bool(rear_shove.get("accepted", false)) or not bool(front_shove.get("accepted", false)):
        _fail("aggregate-pressure shoves were not both accepted")
        return
    var rear_serial: int = int(rear_shove.get("action_serial", 0))
    var front_serial: int = int(front_shove.get("action_serial", 0))
    _run_until_actions_finish(kernel, [rear_serial, front_serial])

    if world.placement(front).anchor != clear_run[2] or world.placement(target).anchor != clear_run[3]:
        _fail("same-direction pressure did not propagate and shift packed actors")
        return
    if not _has_shove_result(shove_results, rear_serial, true)         or not _has_shove_result(shove_results, front_serial, true):
        _fail("contributing shoves did not resolve as successful displacement")
        return

    # 2) Exact opposing aggregate forces cancel before resistance/occupancy.
    # Use the public forced-trajectory seam directly so both destination cells are
    # empty and a hidden directional winner cannot be masked by another actor.
    shove_results.clear()
    if not _place_actor(mutations, world, target, clear_run[3], Facing.Value.NORTH):
        _fail("could not reset aggregate-opposition target")
        return
    var resistance: int = movement.physical_contest_score(target, &"physical.hold")
    if resistance <= 0:
        _fail("could not freeze target resistance")
        return
    if not movement.queue_forced_displacement(source_extra, target, 910001, Vector2i.RIGHT, 7000, resistance)         or not movement.queue_forced_displacement(back, target, 910002, Vector2i.RIGHT, 5000, resistance)         or not movement.queue_forced_displacement(source_opposed, target, 910003, Vector2i.LEFT, 12000, resistance):
        _fail("could not queue opposing aggregate force inputs")
        return
    kernel.run_next_batch()
    if world.placement(target).anchor != clear_run[3]:
        _fail("equal opposing aggregate force chose a hidden winner")
        return

    # 3) Strong pressure chain terminating in static geometry must not phase.
    var wall_fixture: Dictionary = _find_three_clear_then_static(query, world, world.placement(back).anchor)
    if wall_fixture.is_empty():
        _fail("could not find static pressure endpoint fixture")
        return
    var line: Array = wall_fixture["clear"]
    if not carry.set_capacity_grams(back, 40000)         or not carry.set_capacity_grams(front, 10000)         or not carry.set_capacity_grams(target, 10000):
        _fail("could not set wall-pressure capacities")
        return
    if not _place_actor(mutations, world, back, line[0], int(wall_fixture["facing"]))         or not _place_actor(mutations, world, front, line[1], int(wall_fixture["facing"]))         or not _place_actor(mutations, world, target, line[2], int(wall_fixture["facing"])):
        _fail("could not arrange wall-pressure chain")
        return

    var wall_shove: Dictionary = combat.request_action(back, front, CombatActions.SHOVE)
    if not bool(wall_shove.get("accepted", false)):
        _fail("wall-pressure shove was not accepted")
        return
    var wall_serial: int = int(wall_shove.get("action_serial", 0))
    _run_until_actions_finish(kernel, [wall_serial])

    if world.placement(back).anchor != line[0]         or world.placement(front).anchor != line[1]         or world.placement(target).anchor != line[2]:
        _fail("pressure chain phased through or into static blocked space")
        return

    print("PHASE2C_CROWD_PRESSURE_OK aggregate=true one_body_propagation=true opposing_cancel=true static_termination=true")
    quit(0)

func _run_until_actions_finish(kernel: TickKernel, serials: Array[int]) -> void:
    for _batch: int in range(96):
        var any_active: bool = false
        for serial: int in serials:
            if serial > 0 and kernel.action_by_serial(serial) != null:
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
    for radius: int in range(1, 24):
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

func _find_three_clear_then_static(query: SpatialQueryService, world: WorldState, center: Vector2i) -> Dictionary:
    var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
    for radius: int in range(2, 36):
        for dy: int in range(-radius, radius + 1):
            for dx: int in range(-radius, radius + 1):
                var start := center + Vector2i(dx, dy)
                for direction: Vector2i in directions:
                    var clear_cells: Array[Vector2i] = [start, start + direction, start + direction * 2]
                    var all_clear: bool = true
                    for cell: Vector2i in clear_cells:
                        var q: SpatialQueryResult = query.query_cell(cell, "", true)
                        if q == null or q.status != QueryRules.Status.CLEAR:
                            all_clear = false
                            break
                    if not all_clear:
                        continue
                    var blocked_cell: Vector2i = start + direction * 3
                    var blocked: SpatialQueryResult = query.query_cell(blocked_cell, "", true)
                    if blocked == null or blocked.status != QueryRules.Status.BLOCKED                         or blocked.blocking_entity_ids.is_empty()                         or not blocked.missing_terrain_cells.is_empty()                         or not blocked.unclassified_entity_ids.is_empty():
                        continue
                    var static_only: bool = true
                    for blocker_id: String in blocked.blocking_entity_ids:
                        var placement: WorldPlacement = world.placement(blocker_id)
                        if placement == null or placement.channel == Layers.Channel.ACTOR:
                            static_only = false
                            break
                    if static_only:
                        return {
                            "clear": clear_cells,
                            "blocked": blocked_cell,
                            "facing": _facing_for_direction(direction),
                        }
    return {}

static func _facing_for_direction(direction: Vector2i) -> int:
    if direction == Vector2i.UP:
        return Facing.Value.NORTH
    if direction == Vector2i.RIGHT:
        return Facing.Value.EAST
    if direction == Vector2i.DOWN:
        return Facing.Value.SOUTH
    return Facing.Value.WEST

static func _has_shove_result(entries: Array[Dictionary], serial: int, displaced: bool) -> bool:
    for entry: Dictionary in entries:
        if int(entry.get("serial", 0)) == serial and bool(entry.get("displaced", not displaced)) == displaced:
            return true
    return false
