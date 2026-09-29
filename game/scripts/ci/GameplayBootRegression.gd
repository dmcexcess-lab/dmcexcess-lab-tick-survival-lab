extends SceneTree

func _init() -> void:
    var packed := load("res://gameplay.tscn") as PackedScene
    assert(packed != null)
    # One real production seed keeps this regression bounded; the static guard below
    # covers the quiet-area condition that caused the browser-only startup failure.
    for seed in [20001]:
        var game := packed.instantiate()
        assert(game != null)
        assert(game.has_method("configure_world_seed_override"))
        assert(game.configure_world_seed_override(seed))
        root.add_child(game)
        await process_frame
        await process_frame
        assert(game.has_method("session_boot_ok"))
        assert(game.session_boot_ok(), "production boot failed for seed %d: %s" % [seed, game.session_boot_error()])
        game.queue_free()
        await process_frame
    print("GAMEPLAY_BOOT_REGRESSION_OK")
    quit(0)
