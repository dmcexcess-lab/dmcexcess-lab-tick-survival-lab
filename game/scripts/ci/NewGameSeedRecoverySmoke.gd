extends SceneTree

const BAD_SEED: int = 271828
const GOOD_SEED: int = 20001

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("NEW_GAME_SEED_RECOVERY: " + message)
    quit(1)

func _boot_seed(scene: PackedScene, seed_value: int) -> bool:
    var game: Node = scene.instantiate()
    if game == null or not bool(game.call("configure_world_seed_override", seed_value)):
        return false
    get_root().add_child(game)
    await process_frame
    await process_frame
    await process_frame
    var ok: bool = bool(game.call("session_boot_ok"))
    game.queue_free()
    await process_frame
    return ok

func _run() -> void:
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("production gameplay scene missing")
        return

    var bad_ok: bool = await _boot_seed(scene, BAD_SEED)
    if bad_ok:
        _fail("known topology-rejected seed unexpectedly booted; recovery fixture no longer exercises rejection")
        return

    var good_ok: bool = await _boot_seed(scene, GOOD_SEED)
    if not good_ok:
        _fail("known production-good replacement seed failed")
        return

    var menu_source: String = FileAccess.get_file_as_string("res://scripts/ui/StartupMenu.gd")
    if not menu_source.contains("NEW_GAME_BOOT_ATTEMPTS") or not menu_source.contains("for attempt in range(attempt_limit)"):
        _fail("startup menu does not own bounded NEW GAME retry")
        return
    if not menu_source.contains("if session.is_empty()") or not menu_source.contains("Trying another island"):
        _fail("retry is not scoped/presented as NEW GAME generation recovery")
        return

    print("NEW_GAME_SEED_RECOVERY_OK rejected_seed=%d replacement_seed=%d bounded_retry=true continue_single_attempt=true" % [BAD_SEED, GOOD_SEED])
    quit(0)
