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
    _test_contested_destination_is_stable(true)
    _test_contested_destination_is_stable(false)
    _test_distinct_moves_publish_atomically()
    _test_occupied_snapshot_stays_blocked()
    _test_run_conflict_preserves_impact_truth()

    if _failures.is_empty():
        print("PROMPT_SIMULATION_SIMULTANEITY_SMOKE: PASS")
        quit(0)
        return

    for failure: String in _failures:
        push_error("PROMPT_SIMULATION_SIMULTANEITY_SMOKE: FAIL: %s" % failure)
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
    _check(policy.register_terrain(&"ground.test", true, 5), "fixture terrain traversal rule")
    for y: int in range(0, 8):
        for x: int in range(0, 10):
            _check(mutations.set_terrain(Vector2i(x, y), &"ground.test"), "fixture terrain %d,%d" % [x, y])

    _check(movement.is_ready(), "movement fixture ready")
    return {
        "world": world,
        "mutations": mutations,
        "kernel": kernel,
        "movement": movement,
    }

func _place_actor(
    fixture: Dictionary,
    actor_id: String,
    anchor: Vector2i,
    facing: int
) -> void:
    var mutations: WorldMutationService = fixture["mutations"]
    _check(mutations.create_entity(&"actor.person", actor_id) == actor_id, "create %s" % actor_id)
    _check(
        mutations.set_placement(
            actor_id,
            Layers.Channel.ACTOR,
            anchor,
            facing,
            Footprint.single_cell()
        ),
        "place %s" % actor_id
    )

func _test_contested_destination_is_stable(request_a_first: bool) -> void:
    var fixture: Dictionary = _fixture()
    var world: WorldState = fixture["world"]
    var kernel: TickKernel = fixture["kernel"]
    var movement: MovementActionService = fixture["movement"]
    _place_actor(fixture, "actor_a", Vector2i(1, 1), Facing.Value.EAST)
    _place_actor(fixture, "actor_b", Vector2i(3, 1), Facing.Value.WEST)

    var committed: Array[String] = []
    var failures: Array[Dictionary] = []
    movement.movement_committed.connect(func(actor_id, _serial, _action_type, _anchor, _facing):
        committed.append(String(actor_id))
    )
    movement.movement_failed.connect(func(actor_id, _serial, _action_type, reason):
        failures.append({"actor_id": String(actor_id), "reason": String(reason)})
    )

    var result_a: MovementActionResult = null
    var result_b: MovementActionResult = null
    if request_a_first:
        result_a = movement.request_step_forward("actor_a")
        result_b = movement.request_step_forward("actor_b")
    else:
        result_b = movement.request_step_forward("actor_b")
        result_a = movement.request_step_forward("actor_a")

    _check(result_a.is_accepted(), "contested actor_a request accepted")
    _check(result_b.is_accepted(), "contested actor_b request accepted")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "contested batch runs to idle")
    _check(world.placement("actor_a").anchor == Vector2i(2, 1), "stable lower actor id wins clear contested cell")
    _check(world.placement("actor_b").anchor == Vector2i(3, 1), "contested loser remains at origin")
    _check(committed == ["actor_a"], "only deterministic contested winner commits")
    _check(
        failures.size() == 1 \
            and String(failures[0].get("actor_id", "")) == "actor_b" \
            and String(failures[0].get("reason", "")) == "target_blocked",
        "contested loser receives deterministic target_blocked"
    )

func _test_distinct_moves_publish_atomically() -> void:
    var fixture: Dictionary = _fixture()
    var world: WorldState = fixture["world"]
    var kernel: TickKernel = fixture["kernel"]
    var movement: MovementActionService = fixture["movement"]
    _place_actor(fixture, "actor_a", Vector2i(1, 2), Facing.Value.EAST)
    _place_actor(fixture, "actor_b", Vector2i(4, 2), Facing.Value.EAST)

    var changed_observation: Dictionary = {}
    var committed_observation: Dictionary = {}
    var batch_change_counts: Array[int] = []
    world.changed.connect(func(_change):
        if changed_observation.is_empty():
            changed_observation = {
                "a": world.placement("actor_a").anchor,
                "b": world.placement("actor_b").anchor,
            }
    )
    world.batch_changed.connect(func(batch):
        batch_change_counts.append(int(batch.change_count))
    )
    movement.movement_committed.connect(func(_actor_id, _serial, _action_type, _anchor, _facing):
        if committed_observation.is_empty():
            committed_observation = {
                "a": world.placement("actor_a").anchor,
                "b": world.placement("actor_b").anchor,
            }
    )

    var result_a: MovementActionResult = movement.request_step_forward("actor_a")
    var result_b: MovementActionResult = movement.request_step_forward("actor_b")
    _check(result_a.is_accepted() and result_b.is_accepted(), "distinct same-WHEN moves accepted")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "distinct batch runs to idle")

    _check(world.placement("actor_a").anchor == Vector2i(2, 2), "distinct actor_a reaches destination")
    _check(world.placement("actor_b").anchor == Vector2i(5, 2), "distinct actor_b reaches destination")
    _check(
        changed_observation.get("a", Vector2i.ZERO) == Vector2i(2, 2) \
            and changed_observation.get("b", Vector2i.ZERO) == Vector2i(5, 2),
        "first placement change observer sees complete same-WHEN occupancy batch"
    )
    _check(
        committed_observation.get("a", Vector2i.ZERO) == Vector2i(2, 2) \
            and committed_observation.get("b", Vector2i.ZERO) == Vector2i(5, 2),
        "first movement signal sees complete same-WHEN occupancy batch"
    )
    _check(batch_change_counts == [2], "distinct movement commits as one two-change world batch")

func _test_occupied_snapshot_stays_blocked() -> void:
    var fixture: Dictionary = _fixture()
    var movement: MovementActionService = fixture["movement"]
    _place_actor(fixture, "actor_a", Vector2i(1, 4), Facing.Value.EAST)
    _place_actor(fixture, "actor_b", Vector2i(2, 4), Facing.Value.EAST)

    var blocked: MovementActionResult = movement.request_step_forward("actor_a")
    var departing: MovementActionResult = movement.request_step_forward("actor_b")
    _check(
        blocked.status == MovementResult.Status.TARGET_BLOCKED and not blocked.is_accepted(),
        "occupied pre-batch destination remains blocked instead of becoming a swap/chain"
    )
    _check(departing.is_accepted(), "occupant may independently depart on its own action")

func _test_run_conflict_preserves_impact_truth() -> void:
    var fixture: Dictionary = _fixture()
    var world: WorldState = fixture["world"]
    var kernel: TickKernel = fixture["kernel"]
    var movement: MovementActionService = fixture["movement"]
    _place_actor(fixture, "actor_a", Vector2i(1, 6), Facing.Value.EAST)
    _place_actor(fixture, "actor_b", Vector2i(3, 6), Facing.Value.WEST)

    var impacts: Array[Dictionary] = []
    movement.run_impact.connect(func(actor_id, _serial, stride_index, _anchor, _facing, blockers):
        impacts.append({
            "actor_id": String(actor_id),
            "stride_index": int(stride_index),
            "blockers": blockers.duplicate(),
        })
    )

    var result_b: MovementActionResult = movement.request_run_forward("actor_b")
    var result_a: MovementActionResult = movement.request_run_forward("actor_a")
    _check(result_a.is_accepted() and result_b.is_accepted(), "contested run requests accepted from clear snapshot")
    _check(kernel.run_next_batch() == TickRules.RunStopReason.BATCH_COMPLETE, "first run stride timestamp resolves")
    _check(world.placement("actor_a").anchor == Vector2i(2, 6), "run conflict stable winner takes first stride")
    _check(world.placement("actor_b").anchor == Vector2i(3, 6), "run conflict loser remains at origin")
    _check(
        impacts.size() == 1 \
            and String(impacts[0].get("actor_id", "")) == "actor_b" \
            and int(impacts[0].get("stride_index", 0)) == 1 \
            and impacts[0].get("blockers", []) == ["actor_a"],
        "run conflict reports deterministic winner as authoritative impact blocker"
    )

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
