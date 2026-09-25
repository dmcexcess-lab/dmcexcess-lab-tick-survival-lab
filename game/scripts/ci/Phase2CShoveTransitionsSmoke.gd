extends SceneTree

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const QueryRules = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")
const CombatActions = preload("res://scripts/simulation/combat/CombatActionService.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE2C_SHOVE_TRANSITIONS: " + message)
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
    var health: ActorHealthState = game.get("_health_state")
    var corpses: CorpseState = game.get("_corpse_state")
    var cohort: ActiveInfectedCohortService = game.infected_cohort_service()
    if movement == null or combat == null or world == null or mutations == null or query == null         or kernel == null or carry == null or health == null or corpses == null or cohort == null:
        _fail("production shove-transition owners are incomplete")
        return

    var ids: Array[String] = cohort.roster_actor_ids()
    if ids.size() < 4:
        _fail("need four production infected")
        return
    for actor_id: String in ids:
        var behavior: CohortInfectedBehaviorService = cohort.behavior_for_actor(actor_id)
        if behavior != null:
            behavior.deactivate(&"focused_verifier")
    kernel.set_decision_actor("")

    var cells: Dictionary = _find_clear_cross(query, world.placement(ids[0]).anchor)
    if cells.is_empty():
        _fail("could not find clear cross fixture")
        return

    var target: String = ids[0]
    var shover: String = ids[1]
    var opponent: String = ids[2]
    var striker: String = ids[3]

    var movement_failures: Array[Dictionary] = []
    var shove_results: Array[Dictionary] = []
    movement.movement_failed.connect(func(actor_id: String, serial: int, _action_type: StringName, reason: String) -> void:
        movement_failures.append({"actor": actor_id, "serial": serial, "reason": reason, "tick": kernel.world_tick()})
    )
    combat.shove_resolved.connect(func(attacker_id: String, target_id: String, serial: int, displaced: bool) -> void:
        shove_results.append({"attacker": attacker_id, "target": target_id, "serial": serial, "displaced": displaced, "tick": kernel.world_tick()})
    )

    # 1) A shove and the target's already-committed move mature on the same tick.
    # Stronger shove force wins the target's trajectory; callback order does not.
    if not carry.set_capacity_grams(shover, 24000) or not carry.set_capacity_grams(target, 12000):
        _fail("could not set shove-vs-move physical capacities")
        return
    if not _place_actor(mutations, world, target, cells["center"], Facing.Value.NORTH)         or not _place_actor(mutations, world, shover, cells["west"], Facing.Value.EAST):
        _fail("could not arrange shove-vs-move fixture")
        return

    var target_move: MovementActionResult = movement.request_step_forward(target)
    if target_move == null or not target_move.is_accepted():
        _fail("target movement was not accepted")
        return
    if kernel.schedule_event(kernel.world_tick() + 7, "phase2c.fixture", &"noop") <= 0:
        _fail("could not stage same-tick shove contact")
        return
    kernel.run_next_batch()
    var shove_one: Dictionary = combat.request_action(shover, target, CombatActions.SHOVE)
    if not bool(shove_one.get("accepted", false)):
        _fail("shove-vs-move shove was not accepted")
        return
    var shove_one_serial: int = int(shove_one.get("action_serial", 0))
    _run_until_actions_finish(kernel, [target_move.action_serial, shove_one_serial])

    if world.placement(target) == null or world.placement(target).anchor != cells["east"]:
        _fail("stronger shove did not win opposing target trajectory")
        return
    if not _has_failure(movement_failures, target_move.action_serial, "shoved"):
        _fail("target movement did not record shove trajectory loss")
        return
    if not _has_shove_result(shove_results, shove_one_serial, true):
        _fail("winning shove did not resolve displaced=true")
        return

    # 2) Equal simultaneous shoves from opposite sides are a true force tie.
    movement_failures.clear()
    shove_results.clear()
    if not carry.set_capacity_grams(shover, 18000) or not carry.set_capacity_grams(opponent, 18000)         or not carry.set_capacity_grams(target, 18000):
        _fail("could not set opposing shove capacities")
        return
    if not _place_actor(mutations, world, target, cells["center"], Facing.Value.NORTH)         or not _place_actor(mutations, world, shover, cells["west"], Facing.Value.EAST)         or not _place_actor(mutations, world, opponent, cells["east"], Facing.Value.WEST):
        _fail("could not arrange opposing shove fixture")
        return
    var shove_left: Dictionary = combat.request_action(shover, target, CombatActions.SHOVE)
    var shove_right: Dictionary = combat.request_action(opponent, target, CombatActions.SHOVE)
    if not bool(shove_left.get("accepted", false)) or not bool(shove_right.get("accepted", false)):
        _fail("opposing shoves were not both accepted")
        return
    var left_serial: int = int(shove_left.get("action_serial", 0))
    var right_serial: int = int(shove_right.get("action_serial", 0))
    _run_until_actions_finish(kernel, [left_serial, right_serial])

    if world.placement(target) == null or world.placement(target).anchor != cells["center"]:
        _fail("equal opposing shoves moved target via hidden initiative")
        return
    if not _has_shove_result(shove_results, left_serial, false)         or not _has_shove_result(shove_results, right_serial, false):
        _fail("equal opposing shoves did not both resolve without displacement")
        return

    # 3) A shove already earned on the lethal-contact tick still resolves before
    # terminal death publication. The corpse inherits the post-transition cell.
    shove_results.clear()
    if not carry.set_capacity_grams(shover, 24000) or not carry.set_capacity_grams(target, 12000):
        _fail("could not restore lethal-shove capacities")
        return
    if not health.set_hp(target, 1):
        _fail("could not stage lethal target hp")
        return
    if not _place_actor(mutations, world, target, cells["center"], Facing.Value.NORTH)         or not _place_actor(mutations, world, shover, cells["west"], Facing.Value.EAST)         or not _place_actor(mutations, world, striker, cells["north"], Facing.Value.SOUTH)         or not _place_actor(mutations, world, opponent, cells["south"], Facing.Value.NORTH):
        _fail("could not arrange lethal shove fixture")
        return

    var lethal_shove: Dictionary = combat.request_action(shover, target, CombatActions.SHOVE)
    var lethal_strike: Dictionary = combat.request_action(striker, target, CombatActions.STRIKE_UNARMED)
    if not bool(lethal_shove.get("accepted", false)) or not bool(lethal_strike.get("accepted", false)):
        _fail("lethal shove/strike pair was not accepted")
        return
    var lethal_shove_serial: int = int(lethal_shove.get("action_serial", 0))
    var lethal_strike_serial: int = int(lethal_strike.get("action_serial", 0))
    _run_until_actions_finish(kernel, [lethal_shove_serial, lethal_strike_serial])

    if health.current_hp(target) != 0:
        _fail("same-tick strike was not lethal")
        return
    var corpse_id: String = corpses.corpse_for_actor(target)
    if corpse_id.is_empty():
        _fail("lethal target did not transition to corpse")
        return
    var corpse_placement: WorldPlacement = world.placement(corpse_id)
    if corpse_placement == null or corpse_placement.anchor != cells["east"]:
        _fail("corpse did not inherit post-shove outgoing position")
        return
    if not _has_shove_result(shove_results, lethal_shove_serial, true):
        _fail("lethal same-tick shove was retroactively erased by death")
        return

    print("PHASE2C_SHOVE_TRANSITIONS_OK shove_beats_move=true opposing_tie=true corpse_after_displacement=true")
    quit(0)

func _run_until_actions_finish(kernel: TickKernel, serials: Array[int]) -> void:
    for _batch: int in range(96):
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

func _find_clear_cross(query: SpatialQueryService, center_hint: Vector2i) -> Dictionary:
    for radius: int in range(2, 20):
        for dy: int in range(-radius, radius + 1):
            for dx: int in range(-radius, radius + 1):
                var center := center_hint + Vector2i(dx, dy)
                var wanted: Dictionary = {
                    "center": center,
                    "north": center + Vector2i.UP,
                    "east": center + Vector2i.RIGHT,
                    "south": center + Vector2i.DOWN,
                    "west": center + Vector2i.LEFT,
                }
                var clear: bool = true
                for cell_value: Variant in wanted.values():
                    var cell: Vector2i = cell_value
                    var q: SpatialQueryResult = query.query_cell(cell, "", true)
                    if q == null or q.status != QueryRules.Status.CLEAR:
                        clear = false
                        break
                if clear:
                    return wanted
    return {}

static func _has_failure(entries: Array[Dictionary], serial: int, reason: String) -> bool:
    for entry: Dictionary in entries:
        if int(entry.get("serial", 0)) == serial and String(entry.get("reason", "")) == reason:
            return true
    return false

static func _has_shove_result(entries: Array[Dictionary], serial: int, displaced: bool) -> bool:
    for entry: Dictionary in entries:
        if int(entry.get("serial", 0)) == serial and bool(entry.get("displaced", not displaced)) == displaced:
            return true
    return false
