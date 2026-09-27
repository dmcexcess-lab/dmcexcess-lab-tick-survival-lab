extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("MOBILE_NEW_GAME_BOOTSTRAP: " + message)
    quit(1)

func _run() -> void:
    var scene: PackedScene = load("res://main.tscn") as PackedScene
    if scene == null:
        _fail("startup scene missing")
        return
    var menu: Node = scene.instantiate()
    if menu == null:
        _fail("startup menu could not instantiate")
        return
    get_root().add_child(menu)
    await process_frame
    await process_frame

    var gameplay: PackedScene = load("res://gameplay.tscn") as PackedScene
    if gameplay == null:
        _fail("gameplay scene missing")
        return
    var game: Node = gameplay.instantiate()
    if game == null:
        _fail("gameplay scene could not instantiate")
        return
    get_root().add_child(game)
    await process_frame
    if not game.has_method("session_boot_ok") or not bool(game.call("session_boot_ok")):
        _fail("production new-game bootstrap failed")
        return
    if Fixture.active_seed() <= 0 or Fixture.global_plan() == null or Fixture.streaming_coordinator() == null:
        _fail("new game did not establish authoritative procedural/streaming state")
        return
    var world: WorldState = game.get("_world") as WorldState
    if world == null or world.placement(Fixture.PLAYER_ID) == null:
        _fail("player missing after production bootstrap")
        return

    # The mobile regression was caused by fully materializing the initial streaming
    # neighborhood once as a disposable seed probe and then a second time for the real
    # world. Production bootstrap must now have no disposable probe-world path.
    var source: String = FileAccess.get_file_as_string("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
    if source.contains("_probe_initial_streaming") or source.contains("probe_world"):
        _fail("disposable full initial-stream materialization still exists")
        return

    game.queue_free()
    menu.queue_free()
    await process_frame
    print("MOBILE_NEW_GAME_BOOTSTRAP_OK production_boot=true single_initial_materialization=true player=true streaming=true")
    quit(0)
