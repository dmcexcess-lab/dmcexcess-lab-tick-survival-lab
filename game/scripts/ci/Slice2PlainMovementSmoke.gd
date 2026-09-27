extends SceneTree

const REGRESSION_SEED := 20001
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
    var before_turn: int = int(turns.turn_number())
    turns.submit_intent(Intents.TURN_LEFT)
    if int(turns.turn_number()) != before_turn + 1 or not turns.has_control():
        _fail("ordinary turn did not resolve exactly once")
        return
    turns.submit_intent(Intents.TURN_RIGHT)
    if int(turns.turn_number()) != before_turn + 2 or not turns.has_control():
        _fail("second ordinary turn did not resolve exactly once")
        return
    print("SLICE2_PLAIN_MOVEMENT_OK seed=%d turns=%d" % [REGRESSION_SEED, turns.turn_number()])
    quit(0)
