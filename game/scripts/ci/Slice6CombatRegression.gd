extends SceneTree

const SEED := 20001
const PLAYER_ID := "actor.player"
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

func _initialize() -> void: call_deferred("_run")
func _fail(message: String) -> void: push_error("SLICE6_COMBAT: " + message); quit(1)
func _run() -> void:
    var scene: PackedScene = load("res://gameplay.tscn"); var game := scene.instantiate() if scene != null else null
    if game == null or not game.call("configure_world_seed_override", SEED): _fail("scene setup failed"); return
    get_root().add_child(game); await process_frame; await process_frame
    var turns: SimpleTurnController = game.call("simple_turn_controller"); var ids: Array[String] = game.call("simple_infected_actor_ids")
    if turns == null or ids.size() < 2: _fail("combat fixture unavailable"); return
    var target := ids[0]; var world: WorldState = turns._world
    if not _place_adjacent(world, target): _fail("could not place player for combat"); return
    if not game._health_state.set_hp(target, 1): _fail("could not prepare lethal target"); return
    var player: WorldPlacement = world.placement(PLAYER_ID); var distant := ""; var distant_anchor := Vector2i.ZERO
    for actor_id: String in ids:
        var p: WorldPlacement = world.placement(actor_id)
        if p != null and maxi(absi(p.anchor.x - player.anchor.x), absi(p.anchor.y - player.anchor.y)) > SimpleTurnController.ACTIVE_RADIUS:
            distant = actor_id; distant_anchor = p.anchor; break
    var turn_before := turns.turn_number(); var kernel_before := game._kernel.world_tick()
    turns.submit_intent(Intents.COMBAT_FORWARD)
    if turns.turn_number() != turn_before + 1 or game._health_state.current_hp(target) > 0: _fail("canonical combat regression"); return
    if game._kernel.world_tick() != kernel_before: _fail("combat advanced TickKernel"); return
    if not distant.is_empty() and world.placement(distant) != null and world.placement(distant).anchor != distant_anchor: _fail("distant infected acted individually"); return
    print("SLICE6_COMBAT_OK turn=%d distant_idle=%s" % [turns.turn_number(), str(not distant.is_empty())]); quit(0)

func _place_adjacent(world: WorldState, target_id: String) -> bool:
    var target: WorldPlacement = world.placement(target_id)
    if target == null: return false
    for direction: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
        var cell := target.anchor - direction
        if not world.has_terrain(cell): continue
        var blocked := false
        for actor_id: String in world.entities_at(cell, Layers.Channel.ACTOR):
            if actor_id != PLAYER_ID: blocked = true
        if not blocked: return world.move_entity(PLAYER_ID, cell, Facing.from_vector(direction))
    return false
