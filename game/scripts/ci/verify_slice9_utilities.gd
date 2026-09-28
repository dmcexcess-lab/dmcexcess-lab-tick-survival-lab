extends SceneTree

func _init() -> void:
    var packed := load("res://gameplay.tscn") as PackedScene
    assert(packed != null)
    var game := packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    assert(game != null and game.has_method("session_boot_ok") and game.session_boot_ok())
    assert(game.has_method("slice9_utility_verification"))
    var result: Dictionary = game.slice9_utility_verification()
    assert(bool(result.get("ok", false)), String(result.get("reason", "slice9_failed")))
    print("SLICE9_UTILITIES_OK")
    quit(0)
