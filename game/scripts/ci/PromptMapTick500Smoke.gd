extends SceneTree

const GameplayScene = preload("res://gameplay.tscn")
const FixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const TickRulesClass = preload("res://scripts/foundation/time/TickRules.gd")

const TARGET_TICK: int = 500
const MAX_BOOT_FRAMES: int = 900
const MAX_MAP_BUILD_FRAMES: int = 180
const MAX_RUN_OPERATIONS: int = 200000
const FIRST_OPEN_BUDGET_USEC: int = 50000
const REOPEN_BUDGET_USEC: int = 10000

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game: Node = GameplayScene.instantiate()
    _check(game != null, "production gameplay scene instantiates")
    if game == null:
        _finish()
        return

    root.add_child(game)
    current_scene = game

    var bootstrap_frames: int = 0
    var map_bootstrap: PlayerMapBootstrap = game.get_node_or_null("PlayerMapBootstrap") as PlayerMapBootstrap
    while bootstrap_frames < MAX_BOOT_FRAMES and (map_bootstrap == null or not map_bootstrap.is_configured()):
        bootstrap_frames += 1
        await process_frame
        map_bootstrap = game.get_node_or_null("PlayerMapBootstrap") as PlayerMapBootstrap

    _check(map_bootstrap != null, "production PlayerMapBootstrap exists")
    _check(map_bootstrap != null and map_bootstrap.is_configured(), "production map bootstrap configures")
    if map_bootstrap != null and not map_bootstrap.is_configured():
        _check(false, "map bootstrap failure: %s" % map_bootstrap.failure_reason())

    var kernel: TickKernel = game.get("_kernel") as TickKernel
    _check(kernel != null, "production TickKernel is available")
    if kernel == null:
        _finish()
        return

    # Advance the real authoritative WHEN with a committed player action. All live
    # listeners (world time, weather, NPC/infected systems, etc.) see these ticks.
    var action_serial: int = kernel.begin_action(
        FixtureClass.PLAYER_ID,
        &"prompt_tick_500_wait",
        TARGET_TICK,
        TickRulesClass.InterruptionPolicy.COMMITTED
    )
    _check(action_serial > 0, "500-tick committed player action begins")
    if action_serial <= 0:
        _finish()
        return

    var stop_reason: int = kernel.run_until_stop(MAX_RUN_OPERATIONS)
    print("PROMPT_MAP_TICK500_WHEN tick=%d stop_reason=%d" % [kernel.world_tick(), stop_reason])
    _check(kernel.world_tick() >= TARGET_TICK, "authoritative WHEN reaches at least tick 500")

    var camera_controls: CameraControls = game.get_node_or_null("CameraControls") as CameraControls
    _check(camera_controls != null, "production CameraControls exists")
    if camera_controls == null:
        _finish()
        return

    var map_view: IslandMapView = camera_controls.map_view()
    _check(map_view != null, "IslandMapView exists")
    _check(map_view != null and map_view.is_configured(), "IslandMapView remains configured at tick 500")
    _check(map_view != null and map_view.has_player_marker(), "map can resolve the live player marker at tick 500")

    var mouse_release := InputEventMouseButton.new()
    mouse_release.button_index = MOUSE_BUTTON_LEFT
    mouse_release.pressed = false

    var first_open_start: int = Time.get_ticks_usec()
    var handled: bool = camera_controls.dispatch_control_event(mouse_release, &"map", 1000)
    var first_open_usec: int = Time.get_ticks_usec() - first_open_start
    print("PROMPT_MAP_TICK500_FIRST_OPEN_USEC=%d" % first_open_usec)

    _check(handled, "production MAP mouse-release event is handled")
    _check(camera_controls.map_is_open(), "MAP control opens the map at tick 500")
    _check(map_view != null and map_view.visible, "map view is visible after MAP control")
    _check(map_view != null and map_view.size.x > 0.0 and map_view.size.y > 0.0, "map has a non-zero viewport-sized control")
    _check(first_open_usec <= FIRST_OPEN_BUDGET_USEC, "first MAP open stays nonblocking")

    var build_frames: int = 0
    while map_view != null and not map_view.surface_build_complete() and build_frames < MAX_MAP_BUILD_FRAMES:
        build_frames += 1
        await process_frame
    print("PROMPT_MAP_TICK500_BUILD_FRAMES=%d progress=%.3f" % [build_frames, 0.0 if map_view == null else map_view.surface_build_progress()])
    _check(map_view != null and map_view.surface_build_complete(), "incremental island map build completes")
    _check(map_view != null and map_view.surface_texture_size() == Vector2i(256, 256), "map produces its static island surface")

    _check(camera_controls.set_map_open(false), "map closes cleanly")
    _check(not camera_controls.map_is_open(), "map reports closed")

    var reopen_start: int = Time.get_ticks_usec()
    handled = camera_controls.dispatch_control_event(mouse_release, &"map", 2000)
    var reopen_usec: int = Time.get_ticks_usec() - reopen_start
    print("PROMPT_MAP_TICK500_REOPEN_USEC=%d" % reopen_usec)
    _check(handled and camera_controls.map_is_open(), "map reopens through production MAP control")
    _check(reopen_usec <= REOPEN_BUDGET_USEC, "cached map reopen stays immediate")
    _check(map_view != null and map_view.has_player_marker(), "player marker remains available after reopen")

    _finish()

func _finish() -> void:
    if failures.is_empty():
        print("PROMPT_MAP_TICK_500_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PROMPT_MAP_TICK_500_SMOKE_FAIL: %s" % failure)
    quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
