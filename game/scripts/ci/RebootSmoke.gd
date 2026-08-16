extends SceneTree

const Generator = preload("res://scripts/reboot/RebootSiteGenerator.gd")
const Player = preload("res://scripts/reboot/RebootPlayer.gd")

func _init() -> void:
    var seeds := {
        "farmstead": 105832,
        "small_trailer": 209771,
        "double_wide": 314159,
        "country_house": 420691,
    }
    for archetype in Generator.ARCHETYPES:
        var seed := int(seeds[archetype])
        var a: Dictionary = Generator.generate(archetype, seed)
        var b: Dictionary = Generator.generate(archetype, seed)
        var result: Dictionary = Generator.validate(a)
        if not bool(result.get("ok", false)):
            push_error("REBOOT_SMOKE_INVALID %s %s" % [archetype, str(result.get("failures", []))])
            quit(1)
            return
        if a.get("ground") != b.get("ground") or a.get("walls") != b.get("walls") or a.get("doors") != b.get("doors") or a.get("windows") != b.get("windows") or a.get("props") != b.get("props") or a.get("rooms") != b.get("rooms") or a.get("buildings") != b.get("buildings") or a.get("spawn") != b.get("spawn"):
            push_error("REBOOT_SMOKE_NONDETERMINISTIC %s" % archetype)
            quit(1)
            return
        var player = Player.new()
        player.reset(a["spawn"], 2)
        var before := player.cell
        player.turn_left()
        player.turn_right()
        if player.cell != before or player.facing != 2:
            push_error("REBOOT_SMOKE_ROTATION_MUTATED_POSITION %s" % archetype)
            quit(1)
            return
        # At least one cardinal step from spawn should be physically legal.
        var moved := false
        for facing in range(4):
            player.reset(a["spawn"], facing)
            if player.move_forward(a):
                moved = true
                break
        if not moved:
            push_error("REBOOT_SMOKE_SPAWN_TRAPPED %s" % archetype)
            quit(1)
            return
    print("REBOOT_CORE_SMOKE_OK")
    quit(0)
