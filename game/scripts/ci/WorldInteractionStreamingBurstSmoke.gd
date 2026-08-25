extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const ReachClass = preload("res://scripts/ci/InteractionCountingReachQuery.gd")
const QueryClass = preload("res://scripts/simulation/interaction/InteractionAffordanceQuery.gd")
const TestPerceptionClass = preload("res://scripts/ci/InteractionTestPerception.gd")

const ACTOR_ID: String = "actor.interaction.streaming.test"

var failures: Array[String] = []
var reasons: Array[StringName] = []

func _initialize() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    _check(mutations.set_terrain_rect(Rect2i(0, 0, 96, 96), &"ground.grass"), "terrain installed")
    _check(mutations.create_entity(&"actor.survivor", ACTOR_ID) == ACTOR_ID, "actor created")
    _check(mutations.set_placement(ACTOR_ID, Layers.Channel.ACTOR, Vector2i(5, 5), Facing.Value.EAST, Footprint.single_cell()), "actor placed")

    var reach := ReachClass.new(world)
    var perception := TestPerceptionClass.new(ACTOR_ID)
    var query := QueryClass.new(world, reach, perception, ACTOR_ID)
    _check(query.is_ready(), "query ready")
    query.affordances_changed.connect(_on_affordances_changed)

    var baseline_calls: int = reach.reachable_call_count()
    for i: int in range(256):
        var object_id: String = "object.streaming.far.%03d" % i
        var cell := Vector2i(40 + (i % 16), 40 + int(i / 16))
        _check(mutations.create_entity(&"prop.retail_shelf", object_id) == object_id, "far object created %d" % i)
        _check(mutations.set_placement(object_id, Layers.Channel.OBJECT, cell, Facing.Value.NORTH, Footprint.single_cell()), "far object placed %d" % i)

    _check(
        reach.reachable_call_count() == baseline_calls,
        "256 unrelated streaming placements do not recompute actor reach"
    )
    _check(reasons.is_empty(), "far streaming placements emit no affordance invalidation")

    _check(mutations.set_placement(ACTOR_ID, Layers.Channel.ACTOR, Vector2i(6, 5), Facing.Value.EAST, Footprint.single_cell()), "actor moved")
    _check(reach.reachable_call_count() == baseline_calls + 1, "actor movement rebuilds cached reach exactly once")
    _check(reasons.has(&"actor_changed"), "actor movement invalidates affordances")

    reasons.clear()
    var local_id: String = "object.streaming.local"
    _check(mutations.create_entity(&"prop.retail_shelf", local_id) == local_id, "local object created")
    _check(mutations.set_placement(local_id, Layers.Channel.OBJECT, Vector2i(7, 5), Facing.Value.NORTH, Footprint.single_cell()), "local object placed")
    _check(reasons.has(&"reachable_object_changed"), "cached reach still detects local object changes")
    _check(reach.reachable_call_count() == baseline_calls + 1, "local object invalidation uses cached reach without recomputing geometry")

    if failures.is_empty():
        print("WORLD_INTERACTION_STREAMING_BURST_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("WORLD_INTERACTION_STREAMING_BURST_SMOKE_FAIL: %s" % failure)
    quit(1)

func _on_affordances_changed(reason: StringName) -> void:
    reasons.append(reason)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)