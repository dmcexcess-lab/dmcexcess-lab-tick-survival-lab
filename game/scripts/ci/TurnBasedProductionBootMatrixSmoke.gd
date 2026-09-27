extends SceneTree

# This is the concrete full-game seed that exposed the legacy utility/simulation
# stack blocking NEW GAME. Broader procedural variation remains owned by the
# separate generation seed matrix; this test protects the complete gameplay scene.
const REGRESSION_SEED := 20002

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("TURN_BASED_PRODUCTION_BOOT: " + message)
    quit(1)

func _run() -> void:
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("canonical gameplay scene missing")
        return
    var game := scene.instantiate()
    if game == null or not game.call("configure_world_seed_override", REGRESSION_SEED):
        _fail("could not configure canonical game")
        return
    get_root().add_child(game)
    await process_frame
    await process_frame
    var canonical_ok := bool(game.call("canonical_boot_ok"))
    var session_ok := bool(game.call("session_boot_ok"))
    if not canonical_ok or not session_ok:
        var reason := String(game.call("session_boot_error")) if game.has_method("session_boot_error") else "missing_session_error"
        _fail("seed %d full gameplay boot failed canonical=%s session=%s reason=%s" % [REGRESSION_SEED, canonical_ok, session_ok, reason])
        return
    var turns = game.call("simple_turn_controller")
    if turns == null or not turns.is_ready() or not turns.has_control():
        _fail("booted without ready simple-turn control")
        return
    print("TURN_BASED_PRODUCTION_BOOT_OK seed=%d" % REGRESSION_SEED)
    quit(0)
