extends SceneTree

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const QueryRules = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE2C_CROWD_PRESSURE_CLOSURE: " + message)
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
    var carry: ActorCarryState = game.get("_carry_state")
    var cohort: ActiveInfectedCohortService = game.infected_cohort_service()
    if movement == null or world == null or mutations == null or query == null         or kernel == null or carry == null or cohort == null:
        _fail("production crowd-pressure owners are incomplete")
        return

    var ids: Array[String] = cohort.roster_actor_ids()
    if ids.size() < 6:
        _fail("need six production infected")
        return
    for actor_id: String in ids:
        var behavior: CohortInfectedBehaviorService = cohort.behavior_for_actor(actor_id)
        if behavior != null:
            behavior.deactivate(&"focused_verifier")
    kernel.set_decision_actor("")

    var run: Array[Vector2i] = _find_clear_horizontal_run(query, world.placement(ids[0]).anchor, 7)
    if run.size() != 7:
        _fail("could not find clear long-chain fixture")
        return

    var rear: String = ids[0]
    var body_one: String = ids[1]
    var body_two: String = ids[2]
    var body_three: String = ids[3]
    var left_source: String = ids[4]
    var right_source: String = ids[5]

    # 1) Ordinary movement contact is sufficient to create a real multi-body
    # pressure wave. No combat shove and no crowd AI are involved.
    if not carry.set_capacity_grams(rear, 50000)         or not carry.set_capacity_grams(body_one, 8000)         or not carry.set_capacity_grams(body_two, 8000)         or not carry.set_capacity_grams(body_three, 8000):
        _fail("could not set strong-chain capacities")
        return
    if not _place_actor(mutations, world, rear, run[0], Facing.Value.EAST)         or not _place_actor(mutations, world, body_one, run[1], Facing.Value.EAST)         or not _place_actor(mutations, world, body_two, run[2], Facing.Value.EAST)         or not _place_actor(mutations, world, body_three, run[3], Facing.Value.EAST):
        _fail("could not arrange strong movement-pressure chain")
        return

    var surge: MovementActionResult = movement.request_step_forward(rear)
    if surge == null or not surge.is_accepted():
        _fail("rear ordinary movement was not accepted")
        return
    _run_until_actions_finish(kernel, [surge.action_serial])

    if world.placement(rear).anchor != run[1]         or world.placement(body_one).anchor != run[2]         or world.placement(body_two).anchor != run[3]         or world.placement(body_three).anchor != run[4]:
        _fail("ordinary movement force did not propagate through three packed bodies")
        return

    # 2) The same chain must stop naturally when resistance consumes the force.
    if not carry.set_capacity_grams(rear, 15000):
        _fail("could not reduce source capacity")
        return
    if not _place_actor(mutations, world, rear, run[0], Facing.Value.EAST)         or not _place_actor(mutations, world, body_one, run[1], Facing.Value.EAST)         or not _place_actor(mutations, world, body_two, run[2], Facing.Value.EAST)         or not _place_actor(mutations, world, body_three, run[3], Facing.Value.EAST):
        _fail("could not reset exhaustion fixture")
        return

    var exhausted: MovementActionResult = movement.request_step_forward(rear)
    if exhausted == null or not exhausted.is_accepted():
        _fail("weak rear movement was not accepted")
        return
    _run_until_actions_finish(kernel, [exhausted.action_serial])

    if world.placement(rear).anchor != run[0]         or world.placement(body_one).anchor != run[1]         or world.placement(body_two).anchor != run[2]         or world.placement(body_three).anchor != run[3]:
        _fail("exhausted pressure incorrectly advanced the packed chain")
        return

    # 3) Aggregate opposition remains order-free at the shared physical seam.
    if not _place_actor(mutations, world, body_two, run[3], Facing.Value.NORTH):
        _fail("could not arrange opposing-force target")
        return
    var hold: int = movement.physical_contest_score(body_two, &"physical.hold")
    if hold <= 0:
        _fail("could not freeze opposing target resistance")
        return
    if not movement.queue_forced_displacement(left_source, body_two, 920001, Vector2i.RIGHT, 14000, hold)         or not movement.queue_forced_displacement(right_source, body_two, 920002, Vector2i.LEFT, 14000, hold):
        _fail("could not queue equal opposing forces")
        return
    kernel.run_next_batch()
    if world.placement(body_two).anchor != run[3]:
        _fail("equal opposing aggregate force selected a hidden direction")
        return

    # 4) Strong movement pressure against a real static endpoint cannot tunnel.
    var wall_fixture: Dictionary = _find_four_clear_then_static(query, world, world.placement(rear).anchor)
    if wall_fixture.is_empty():
        _fail("could not find static long-chain endpoint")
        return
    var line: Array = wall_fixture["clear"]
    var facing: int = int(wall_fixture["facing"])
    if not carry.set_capacity_grams(rear, 60000)         or not carry.set_capacity_grams(body_one, 7000)         or not carry.set_capacity_grams(body_two, 7000)         or not carry.set_capacity_grams(body_three, 7000):
        _fail("could not set static-chain capacities")
        return
    if not _place_actor(mutations, world, rear, line[0], facing)         or not _place_actor(mutations, world, body_one, line[1], facing)         or not _place_actor(mutations, world, body_two, line[2], facing)         or not _place_actor(mutations, world, body_three, line[3], facing):
        _fail("could not arrange static pressure chain")
        return

    var wall_push: MovementActionResult = movement.request_step_forward(rear)
    if wall_push == null or not wall_push.is_accepted():
        _fail("wall-pressure movement was not accepted")
        return
    _run_until_actions_finish(kernel, [wall_push.action_serial])

    if world.placement(rear).anchor != line[0]         or world.placement(body_one).anchor != line[1]         or world.placement(body_two).anchor != line[2]         or world.placement(body_three).anchor != line[3]:
        _fail("static endpoint allowed pressure-chain phasing")
        return

    print("PHASE2C_CROWD_PRESSURE_CLOSED movement_contact=true multi_body=true exhaustion=true opposing_cancel=true static_stop=true")
    quit(0)

func _run_until_actions_finish(kernel: TickKernel, serials: Array[int]) -> void:
    for _batch: int in range(128):
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
    for radius: int in range(1, 28):
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

func _find_four_clear_then_static(query: SpatialQueryService, world: WorldState, center: Vector2i) -> Dictionary:
    var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
    for radius: int in range(2, 40):
        for dy: int in range(-radius, radius + 1):
            for dx: int in range(-radius, radius + 1):
                var start := center + Vector2i(dx, dy)
                for direction: Vector2i in directions:
                    var clear_cells: Array[Vector2i] = [
                        start,
                        start + direction,
                        start + direction * 2,
                        start + direction * 3,
                    ]
                    var all_clear: bool = true
                    for cell: Vector2i in clear_cells:
                        var q: SpatialQueryResult = query.query_cell(cell, "", true)
                        if q == null or q.status != QueryRules.Status.CLEAR:
                            all_clear = false
                            break
                    if not all_clear:
                        continue
                    var blocked_cell: Vector2i = start + direction * 4
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
