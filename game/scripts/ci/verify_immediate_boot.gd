extends SceneTree

const MAX_FRAMES := 120

func _init() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var utility_script := load("res://scripts/app/UtilitySimpleGameMain.gd")
    if utility_script == null:
        push_error("UtilitySimpleGameMain failed to parse/load")
        quit(1)
        return

    var packed := load("res://gameplay.tscn") as PackedScene
    if packed == null:
        push_error("production gameplay scene failed to load")
        quit(1)
        return

    var game := packed.instantiate()
    if game == null:
        push_error("production gameplay scene failed to instantiate")
        quit(1)
        return

    root.add_child(game)
    for _i in range(MAX_FRAMES):
        await process_frame
        if game.has_method("session_boot_ok") and game.session_boot_ok():
            print("IMMEDIATE_BOOT_REGRESSION_OK")
            game.queue_free()
            quit(0)
            return
        if game.has_method("session_boot_error"):
            var error := String(game.session_boot_error())
            if not error.is_empty():
                push_error("production boot failed: %s" % error)
                game.queue_free()
                quit(1)
                return

    push_error("production boot did not reach a successful state within %d frames" % MAX_FRAMES)
    game.queue_free()
    quit(1)
