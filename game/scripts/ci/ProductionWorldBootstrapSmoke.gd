extends SceneTree

const Bootstrap = preload("res://scripts/generation/integration/ProductionWorldBootstrap.gd")
const GridClass = preload("res://scripts/streaming/StreamingRegionGrid.gd")
const TEST_SEED: int = 20001

func _initialize() -> void: call_deferred("_run")
func _fail(message: String) -> void:
    push_error("PRODUCTION_WORLD_BOOTSTRAP: " + message)
    quit(1)

func _run() -> void:
    var app_dir := DirAccess.open("res://scripts/app")
    if app_dir == null:
        _fail("cannot inspect canonical application scripts")
        return
    for filename: String in app_dir.get_files():
        if not filename.ends_with(".gd"): continue
        var source := FileAccess.open("res://scripts/app/%s" % filename, FileAccess.READ)
        if source == null:
            _fail("cannot inspect app script: %s" % filename)
            return
        var text: String = source.get_as_text()
        for forbidden: String in ["res://scripts/demo/", "FixtureClass", "_boot_canonical_demo", "actor.player.demo", "GeneratedIslandCritiqueFixture"]:
            if text.contains(forbidden):
                _fail("canonical app retains demo dependency in %s: %s" % [filename, forbidden])
                return
    var map_source := FileAccess.open("res://scripts/ui/PlayerMapBootstrap.gd", FileAccess.READ)
    if map_source == null or map_source.get_as_text().contains("res://scripts/demo/"):
        _fail("production map bootstrap retains demo dependency")
        return
    for script_path: String in ["res://scripts/app/GameMain.gd", "res://scripts/app/CraftingGameMain.gd", "res://scripts/app/UtilityGameMain.gd", "res://scripts/app/System34GameMain.gd", "res://scripts/app/VehicleGameMain.gd", "res://scripts/app/CombatGameMain.gd", "res://scripts/app/EnvironmentalPressureGameMain.gd"]:
        if load(script_path) == null:
            _fail("production app script failed to load: %s" % script_path)
            return
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("gameplay scene missing")
        return
    var game: Node = scene.instantiate()
    if game == null or not game.has_method("configure_world_seed_override"):
        _fail("production gameplay composition failed to instantiate")
        return
    if not bool(game.call("configure_world_seed_override", TEST_SEED)):
        _fail("cannot configure production seed")
        return
    get_root().add_child(game)
    await process_frame
    await process_frame
    await process_frame
    if not game.has_method("canonical_boot_ok") or not bool(game.call("canonical_boot_ok")):
        _fail("canonical production boot failed: %s" % Bootstrap.last_failure())
        return
    var world: WorldState = game.get("_world") as WorldState
    if world == null:
        _fail("authoritative WHAT unavailable")
        return
    var placement: WorldPlacement = world.placement(Bootstrap.PLAYER_ID)
    if placement == null or Bootstrap.PLAYER_ID.contains("demo"):
        _fail("production player missing or demo-owned")
        return
    var plan: GeneratedGlobalWorldPlan = Bootstrap.global_plan()
    if plan == null or not plan.is_generated() or not plan.bounds.has_point(placement.anchor):
        _fail("player not placed in generated production world")
        return
    var spawn_plan: GeneratedAreaPlan = Bootstrap.spawn_area_plan()
    if spawn_plan == null or not spawn_plan.is_generated():
        _fail("spawn area was not selected from generated production sites")
        return
    var streaming: WorldStreamingCoordinator = Bootstrap.streaming_coordinator()
    if streaming == null or not streaming.has_focus():
        _fail("production streaming unavailable")
        return
    var initial: Dictionary = streaming.debug_snapshot()
    if int(initial.get("active_region_count", -1)) != 1:
        _fail("bounded initial materialization lost: %s" % initial)
        return
    var grid := GridClass.new(plan.bounds, Bootstrap.STREAM_REGION_SIZE)
    var current_region: Vector2i = grid.region_for_cell(placement.anchor)
    var neighbor_cell: Vector2i = placement.anchor + Vector2i(Bootstrap.STREAM_REGION_SIZE.x, 0)
    if plan.bounds.has_point(neighbor_cell):
        var moved: Dictionary = streaming.update_focus(neighbor_cell)
        if not bool(moved.get("ok", false)):
            _fail("adjacent production region did not stream: %s" % String(moved.get("failure_reason", "unknown")))
            return
        if grid.region_for_cell(neighbor_cell) == current_region:
            _fail("streaming transition probe did not cross a region")
            return
    if not game.has_method("durable_session_snapshot"):
        _fail("durable session owner missing from production composition")
        return
    var session: Dictionary = game.call("durable_session_snapshot")
    if session.is_empty() or int(session.get("world_seed", 0)) != Bootstrap.active_seed():
        _fail("durable session does not preserve production world identity")
        return
    print("PRODUCTION_WORLD_BOOTSTRAP_OK seed=%d player=%s spawn=%s active_regions=1 render_bounds=%s demo_free=true save_world=true" % [Bootstrap.active_seed(), Bootstrap.PLAYER_ID, placement.anchor, Bootstrap.render_bounds()])
    game.queue_free()
    await process_frame
    quit(0)
