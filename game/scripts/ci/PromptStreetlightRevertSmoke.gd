extends SceneTree

var _failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://main.tscn") as PackedScene
    _check(packed != null, "production main scene loads")
    if packed == null:
        _finish()
        return

    var game: Node = packed.instantiate()
    root.add_child(game)
    await process_frame

    var world: Variant = game.get("_world")
    var infrastructure: Variant = game.get("_power_infrastructure")
    var lighting: Variant = game.get("_utility_lighting")
    _check(world != null, "production world boots")
    _check(infrastructure != null and infrastructure.is_ready(), "restored roadside power infrastructure boots")
    _check(lighting != null and lighting.is_ready(), "restored utility lighting boots")

    if world != null:
        var streetlights: Array[String] = world.entity_ids_of_type(&"prop.streetlight")
        _check(streetlights.size() == 1048, "restored seed-20001 streetlight population is 1048")
    if infrastructure != null:
        var wires: Array[Dictionary] = infrastructure.wire_edges()
        _check(wires.size() == 3157, "restored roadside wire population is 3157")

    _check(not ResourceLoader.exists("res://scripts/simulation/utilities/NeighborhoodPowerInfrastructureMaterializerBase.gd"), "temporary spacing base wrapper is absent")
    _check(not ResourceLoader.exists("res://scripts/simulation/utilities/UtilityPoweredLightingSourceAdapterBase.gd"), "temporary night-gating base wrapper is absent")

    game.queue_free()
    await process_frame
    _finish()

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    _failures += 1
    push_error("PROMPT_STREETLIGHT_REVERT_SMOKE: %s" % message)

func _finish() -> void:
    if _failures == 0:
        print("PROMPT_STREETLIGHT_REVERT_SMOKE: PASS")
        quit(0)
        return
    print("PROMPT_STREETLIGHT_REVERT_SMOKE: FAIL count=%d" % _failures)
    quit(1)
