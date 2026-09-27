extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("MOBILE_STREAMING_FOOTPRINT: " + message)
    quit(1)

func _run() -> void:
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("production gameplay scene missing")
        return
    var game: Node = scene.instantiate()
    if game == null or not bool(game.call("configure_world_seed_override", 20001)):
        _fail("could not configure deterministic production new game")
        return
    get_root().add_child(game)
    await process_frame
    await process_frame
    await process_frame
    if not bool(game.call("canonical_boot_ok")):
        _fail("production new-game boot failed")
        return
    var streaming: WorldStreamingCoordinator = Fixture.streaming_coordinator()
    var world: WorldState = game.get("_world") as WorldState
    if streaming == null or world == null or not streaming.has_focus():
        _fail("production streaming/world owner unavailable")
        return
    var snapshot: Dictionary = streaming.debug_snapshot()
    if int(snapshot.get("active_region_count", -1)) != 1:
        _fail("new game materialized more than the single focus region: %s" % snapshot)
        return
    if world.placement(Fixture.PLAYER_ID) == null:
        _fail("player missing after production boot")
        return
    print("MOBILE_STREAMING_FOOTPRINT_OK production_boot=true active_regions=1 render_window=%s region=%s" % [Fixture.RENDER_WINDOW_SIZE, Fixture.STREAM_REGION_SIZE])
    game.queue_free()
    await process_frame
    quit(0)
