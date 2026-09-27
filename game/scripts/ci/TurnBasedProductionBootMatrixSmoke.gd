extends SceneTree

# 20002 is the concrete seed that exposed the old utility-stack boot failure.
# Keep a small varied matrix here: this verifier exercises the complete gameplay
# scene and is intentionally heavier than the world-generation seed matrix.
const SEEDS := [20001, 20002, 314159]

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("TURN_BASED_PRODUCTION_BOOT_MATRIX: " + message)
    quit(1)

func _run() -> void:
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("canonical gameplay scene missing")
        return
    for seed in SEEDS:
        var game := scene.instantiate()
        if game == null or not game.call("configure_world_seed_override", seed):
            _fail("seed %d could not configure canonical game" % seed)
            return
        get_root().add_child(game)
        await process_frame
        await process_frame
        var canonical_ok := bool(game.call("canonical_boot_ok"))
        var session_ok := bool(game.call("session_boot_ok"))
        if not canonical_ok or not session_ok:
            var reason := String(game.call("session_boot_error")) if game.has_method("session_boot_error") else "missing_session_error"
            _fail("seed %d full gameplay boot failed canonical=%s session=%s reason=%s" % [seed, canonical_ok, session_ok, reason])
            return
        var turns = game.call("simple_turn_controller")
        if turns == null or not turns.is_ready() or not turns.has_control():
            _fail("seed %d booted without ready simple-turn control" % seed)
            return
        game.queue_free()
        await process_frame
        print("TURN_BASED_PRODUCTION_BOOT_SEED_OK:%d" % seed)
    print("TURN_BASED_PRODUCTION_BOOT_MATRIX_OK seeds=%d" % SEEDS.size())
    quit(0)
