extends SceneTree
const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
var failures: int = 0
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error(message)
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var game: Node = load("res://main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    var world: WorldState = game.get("_world")
    var mutations := WorldMutationService.new(world)
    var view: TacticalRendererStack = game.get("_world_view")
    var window: LargeAreaRenderWindowController = game.get("_large_area_view")
    var camera: TacticalCameraController = game.get("_camera_controller")
    var start: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    check(window.area_bounds() == Fixture.global_plan().bounds, "renderer uses generated world bounds")
    print("START ", start.anchor, " WINDOW ", window.presentation_snapshot(), " CAMERA ", camera.presentation_snapshot())
    for offset: int in [315, 317]:
        var target := start.anchor + Vector2i(offset, 0)
        mutations.set_placement(Fixture.PLAYER_ID, start.channel, target, start.facing, start.footprint)
        await process_frame
        var rect := Rect2i(window.render_origin(), window.render_size())
        var known: int = 0
        for y: int in range(target.y - 10, target.y + 11):
            for x: int in range(target.x - 10, target.x + 11):
                known += int(world.has_terrain(Vector2i(x,y)))
        check(known == 441, "terrain materialized around target")
        check(rect.has_point(target), "player remains within render coverage")
        check(rect.has_point(target + Vector2i(10, 0)), "new cells ahead have render coverage")
        check(Fixture.streaming_failure().is_empty(), "streaming succeeds")
        print("BOUNDARY ", target, " stream=", Fixture.streaming_coordinator().focus_cell(), " region=", Fixture.streaming_coordinator().focus_region_coord(), " known=",known," in_render=",rect.has_point(target), " origin=",rect.position," failure=",Fixture.streaming_failure())
    game.queue_free()
    await process_frame
    print("PROMPT_WORLD_BOUNDARY_SMOKE: PASS" if failures == 0 else "PROMPT_WORLD_BOUNDARY_SMOKE: FAIL")
    quit(0 if failures == 0 else 1)
