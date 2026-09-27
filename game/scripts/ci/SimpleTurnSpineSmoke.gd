extends SceneTree

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Bootstrap = preload("res://scripts/generation/integration/ProductionWorldBootstrap.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("SIMPLE_TURN_SPINE: " + message)
    quit(1)

func _run() -> void:
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("canonical gameplay scene missing")
        return
    var game := scene.instantiate()
    if game == null or not game.call("configure_world_seed_override", 20001):
        _fail("could not configure deterministic production seed")
        return
    get_root().add_child(game)
    await process_frame
    await process_frame
    if not bool(game.call("canonical_boot_ok")) or not bool(game.call("session_boot_ok")):
        _fail("production game did not boot")
        return
    var turns: SimpleTurnController = game.call("simple_turn_controller")
    var world: WorldState = game.get("_world")
    var mutations: WorldMutationService = game.get("_world_mutations")
    var spatial: SpatialQueryService = game.get("_spatial_query")
    var kernel: TickKernel = game.get("_kernel")
    if turns == null or not turns.is_ready() or not turns.has_control() or world == null or mutations == null or spatial == null or kernel == null:
        _fail("simple production turn owner unavailable")
        return
    var player_id := Bootstrap.PLAYER_ID
    var player := world.placement(player_id)
    if player == null:
        _fail("player placement missing")
        return
    var legal_facing := -1
    for facing in range(4):
        var target := player.anchor + Facing.vector(facing)
        var query := spatial.query_entity_footprint(player_id, target, facing, true)
        if query != null and query.is_clear():
            legal_facing = facing
            break
    if legal_facing < 0:
        _fail("no legal adjacent production move")
        return
    if not mutations.set_placement(player_id, player.channel, player.anchor, legal_facing, player.footprint, player.structure_axis):
        _fail("test could not face legal production move")
        return
    var distant_id := ""
    var distant_before := Vector2i.ZERO
    var cohort: Array[Dictionary] = game.call("infected_cohort_results")
    if cohort.is_empty():
        _fail("production infected cohort missing")
        return
    var candidate_id := String(cohort[cohort.size() - 1].get("actor_id", ""))
    var infected := world.placement(candidate_id)
    if infected != null:
        for dx in range(SimpleTurnController.ACTIVE_RADIUS + 1, SimpleTurnController.ACTIVE_RADIUS + 24):
            var candidate := player.anchor + Vector2i(dx, 0)
            var query := spatial.query_entity_footprint(candidate_id, candidate, infected.facing, true)
            if query != null and query.is_clear():
                if mutations.set_placement(candidate_id, infected.channel, candidate, infected.facing, infected.footprint, infected.structure_axis):
                    distant_id = candidate_id
                    distant_before = candidate
                    break
    if distant_id.is_empty():
        _fail("could not establish distant infected bounded-work probe")
        return
    var before := world.placement(player_id).anchor
    var kernel_tick_before := kernel.world_tick()
    var action_count_before := turns.individual_actor_actions()
    turns.submit_intent(Intents.FORWARD)
    var after := world.placement(player_id).anchor
    if after != before + Facing.vector(legal_facing):
        _fail("one legal input did not move player exactly one tile")
        return
    if turns.turn_number() != 1 or not turns.has_control():
        _fail("turn did not resolve once and return control")
        return
    if kernel.world_tick() != kernel_tick_before:
        _fail("legacy TickKernel advanced during simple movement turn")
        return
    if world.placement(distant_id).anchor != distant_before:
        _fail("distant infected received an individual active turn")
        return
    var local_actions := turns.individual_actor_actions() - action_count_before
    if local_actions < 0 or local_actions > cohort.size() - 1:
        _fail("infected work was not bounded by local cohort")
        return
    turns.submit_intent(Intents.TURN_LEFT)
    if turns.turn_number() != 2 or not turns.has_control() or kernel.world_tick() != kernel_tick_before:
        _fail("second simple turn did not return control without legacy tick execution")
        return
    var streaming := Bootstrap.streaming_coordinator()
    if streaming == null or not streaming.has_focus():
        _fail("production streaming focus unavailable after turn")
        return
    print("SIMPLE_TURN_SPINE_OK turns=2 kernel_delta=0 local_actor_actions=%d distant_actor_unchanged=true" % local_actions)
    game.queue_free()
    await process_frame
    quit(0)
