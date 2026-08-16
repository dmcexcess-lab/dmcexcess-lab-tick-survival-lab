extends SceneTree

const Generator = preload("res://scripts/reboot/RebootSiteGenerator.gd")
const Player = preload("res://scripts/reboot/RebootPlayer.gd")
const Art = preload("res://scripts/reboot/RebootArt.gd")

const TEST_SEEDS: Array[int] = [105832, 209771, 314159, 420691, 531117, 684209, 771331, 902417]

func _init() -> void:
    for seed in TEST_SEEDS:
        var a: Dictionary = Generator.generate("rural_road", seed)
        var b: Dictionary = Generator.generate("rural_road", seed)
        var result: Dictionary = Generator.validate(a)
        if not bool(result.get("ok", false)):
            push_error("REBOOT_SMOKE_INVALID seed=%d %s" % [seed, str(result.get("failures", []))])
            quit(1)
            return

        if a.get("ground") != b.get("ground") or a.get("walls") != b.get("walls") or a.get("doors") != b.get("doors") or a.get("windows") != b.get("windows") or a.get("props") != b.get("props") or a.get("rooms") != b.get("rooms") or a.get("buildings") != b.get("buildings") or a.get("properties") != b.get("properties") or a.get("fixture_tags") != b.get("fixture_tags") or a.get("spawn") != b.get("spawn"):
            push_error("REBOOT_SMOKE_NONDETERMINISTIC seed=%d" % seed)
            quit(1)
            return

        var properties: Array = a.get("properties", [])
        if properties.size() != 4:
            push_error("REBOOT_SMOKE_PROPERTY_COUNT seed=%d" % seed)
            quit(1)
            return

        var kinds: Dictionary = {}
        for property_value in properties:
            var property: Dictionary = property_value
            kinds[str(property.get("kind", ""))] = true
        if kinds.size() < 3:
            push_error("REBOOT_SMOKE_PROPERTY_DIVERSITY seed=%d" % seed)
            quit(1)
            return

        # Reboot visual vocabulary must actually be using the restored composite world-art shell.
        var walls: Dictionary = a.get("walls", {})
        var saw_world_wall := false
        for wall_value in walls.values():
            var encoded := int(wall_value)
            if encoded / Art.ENCODE_SCALE == Art.SOURCE_WORLD:
                saw_world_wall = true
                break
        if not saw_world_wall:
            push_error("REBOOT_SMOKE_COMPOSITE_ART_NOT_USED seed=%d" % seed)
            quit(1)
            return

        var player = Player.new()
        player.reset(a["spawn"], 2)
        var before: Vector2i = player.cell
        player.turn_left()
        player.turn_right()
        if player.cell != before or player.facing != 2:
            push_error("REBOOT_SMOKE_ROTATION_MUTATED_POSITION seed=%d" % seed)
            quit(1)
            return

        var moved := false
        for facing in range(4):
            player.reset(a["spawn"], facing)
            if player.move_forward(a):
                moved = true
                break
        if not moved:
            push_error("REBOOT_SMOKE_SPAWN_TRAPPED seed=%d" % seed)
            quit(1)
            return

    print("REBOOT_CORE_SMOKE_OK")
    quit(0)
