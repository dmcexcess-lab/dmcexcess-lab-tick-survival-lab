extends SceneTree

# Full gameplay-scene boot is intentionally pinned to a known realizable world;
# procedural variation is protected separately by the generation seed matrix.
# The workflow also statically proves the turn game no longer inherits the old
# utility/combat/environment simulation stack that caused the browser failure.
const REGRESSION_SEED := 20001

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
    if not bool(game.call("canonical_boot_ok")):
        _fail("full gameplay boot failed")
        return
    var turns = game.call("simple_turn_controller")
    if turns == null or not turns.is_ready() or not turns.has_control():
        _fail("booted without ready simple-turn control")
        return
    print("TURN_BASED_PRODUCTION_BOOT_OK seed=%d" % REGRESSION_SEED)
    quit(0)
