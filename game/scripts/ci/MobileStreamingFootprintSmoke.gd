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
    if game == null or not bool(game.call("configure_world_seed_override", 271828)):
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
    var start: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if start == null:
        _fail("player missing after production boot")
        return
    var start_region: Vector2i = streaming.focus_region_coord()
    var grid := StreamingRegionGrid.new(Fixture.render_bounds(), Fixture.STREAM_REGION_SIZE)
    var neighbor := start_region + Vector2i.RIGHT
    var neighbor_bounds: Rect2i = grid.region_bounds(neighbor)
    if neighbor_bounds.size.x <= 0:
        neighbor = start_region + Vector2i.LEFT
        neighbor_bounds = grid.region_bounds(neighbor)
    if neighbor_bounds.size.x <= 0:
        _fail("no adjacent stream region available")
        return
    var crossing_cell: Vector2i = neighbor_bounds.position + Vector2i(2, 2)
    var crossed: Dictionary = streaming.update_focus(crossing_cell)
    if not bool(crossed.get("ok", false)):
        _fail("ordinary region crossing failed: %s" % crossed)
        return
    snapshot = streaming.debug_snapshot()
    if int(snapshot.get("active_region_count", -1)) != 1 or streaming.focus_region_coord() != neighbor:
        _fail("bounded streaming did not advance focus normally: %s" % snapshot)
        return

    print("MOBILE_STREAMING_FOOTPRINT_OK production_boot=true active_regions=1 crossing=true render_window=%s region=%s" % [Fixture.RENDER_WINDOW_SIZE, Fixture.STREAM_REGION_SIZE])
    game.queue_free()
    await process_frame
    quit(0)
