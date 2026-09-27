extends SceneTree

const REGRESSION_SEED := 20001
const PLAYER_ID := "actor.player"
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("SLICE2_PLAIN_MOVEMENT: " + message)
    quit(1)

func _run() -> void:
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("canonical gameplay scene missing")
        return
    var game := scene.instantiate()
    if game == null or not game.call("configure_world_seed_override", REGRESSION_SEED):
        _fail("could not configure production world")
        return
    get_root().add_child(game)
    await process_frame
    await process_frame
    if not bool(game.call("canonical_boot_ok")):
        _fail("production boot failed")
        return
    var turns = game.call("simple_turn_controller")
    if turns == null or not turns.is_ready() or not turns.has_control():
        _fail("simple turn controller not ready")
        return

    var world = turns._world
    var start = world.placement(PLAYER_ID)
    if start == null:
        _fail("player placement missing")
        return
    var start_anchor: Vector2i = start.anchor
    var moved := false
    for attempt in range(4):
        var before_move_turn: int = int(turns.turn_number())
        turns.submit_intent(Intents.FORWARD)
        var after = world.placement(PLAYER_ID)
        if after != null and after.anchor != start_anchor:
            if int(turns.turn_number()) != before_move_turn + 1:
                _fail("legal move did not consume exactly one turn")
                return
            moved = true
            break
        turns.submit_intent(Intents.TURN_RIGHT)
    if not moved:
        _fail("could not perform any legal adjacent production move")
        return
    if not turns.has_control():
        _fail("control not returned after legal move")
        return

    var before_second: int = int(turns.turn_number())
    turns.submit_intent(Intents.TURN_LEFT)
    if int(turns.turn_number()) != before_second + 1 or not turns.has_control():
        _fail("second ordinary turn did not resolve exactly once")
        return

    print("SLICE2_PLAIN_MOVEMENT_OK seed=%d turns=%d moved=true" % [REGRESSION_SEED, turns.turn_number()])
    quit(0)
