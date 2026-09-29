extends SceneTree

const MAX_FRAMES := 120
const PRODUCTION_SEEDS := [1, 2, 3, 20001, 65537, 104729]

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

    for seed: int in PRODUCTION_SEEDS:
        var game := packed.instantiate()
        if game == null:
            push_error("production gameplay scene failed to instantiate for seed %d" % seed)
            quit(1)
            return
        if not game.has_method("configure_world_seed_override") or not game.configure_world_seed_override(seed):
            push_error("could not configure production seed %d" % seed)
            quit(1)
            return

        root.add_child(game)
        var booted := false
        for _i in range(MAX_FRAMES):
            await process_frame
            if game.has_method("session_boot_ok") and game.session_boot_ok():
                booted = true
                break
            if game.has_method("session_boot_error"):
                var error := String(game.session_boot_error())
                if not error.is_empty():
                    push_error("production boot failed seed=%d error=%s" % [seed, error])
                    game.queue_free()
                    await process_frame
                    quit(1)
                    return
        if not booted:
            push_error("production boot did not succeed seed=%d within %d frames" % [seed, MAX_FRAMES])
            game.queue_free()
            await process_frame
            quit(1)
            return
        print("PRODUCTION_SEED_BOOT_OK:%d" % seed)
        game.queue_free()
        await process_frame

    var vehicle_source := FileAccess.get_file_as_string("res://scripts/app/VehicleGameMain.gd")
    if vehicle_source.contains("if seeded < 1") or vehicle_source.contains("no plausible parked vehicle locations were generated near the playable start"):
        push_error("vehicle seeding still treats zero nearby vehicles as fatal")
        quit(1)
        return

    print("IMMEDIATE_BOOT_REGRESSION_OK")
    quit(0)
