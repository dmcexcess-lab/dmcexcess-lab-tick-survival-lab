extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const MAX_WAIT_FRAMES := 3000

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("VISION_WORLD_REFRESH_REGRESSION: " + message)
    quit(1)

func _run() -> void:
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("production gameplay scene missing")
        return

    var game: Node = scene.instantiate()
    get_root().add_child(game)
    await process_frame

    var world: WorldState = game.get("_world")
    var kernel: TickKernel = game.get("_kernel")
    var perception: ObserverPerceptionService = game.get("_perception")
    var controls: PlayerMovementControls = game.get_node_or_null("Controls") as PlayerMovementControls
    if world == null or kernel == null or perception == null or controls == null:
        _fail("production vision route owners missing")
        return
    if not kernel.is_decision_paused() or not controls.is_enabled():
        _fail("production route not ready at initial decision pause")
        return

    var initial: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if initial == null:
        _fail("player placement missing")
        return
    var initial_visible: Array[Vector2i] = perception.visible_cells()
    var initial_geometry_count: int = perception.geometry_recompute_count()
    var initial_tick: int = kernel.world_tick()

    var turn_button: Button = _button_by_text(controls, "TURN R")
    if turn_button == null:
        _fail("TURN R control missing")
        return
    if not await _press_and_wait(turn_button, controls, kernel):
        _fail("TURN R did not complete")
        return

    var after_turn: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if after_turn == null or after_turn.facing == initial.facing:
        _fail("player facing did not change after TURN R")
        return
    if after_turn.anchor != initial.anchor:
        _fail("TURN R unexpectedly changed player anchor")
        return
    if perception.geometry_recompute_count() <= initial_geometry_count:
        _fail("geometric LOS cache was reused after player facing changed")
        return
    var turn_visible: Array[Vector2i] = perception.visible_cells()
    if _same_cells(initial_visible, turn_visible):
        _fail("visible-cell cone did not change after player facing changed")
        return

    var geometry_after_turn: int = perception.geometry_recompute_count()
    var forward_button: Button = _button_by_text(controls, "FORWARD")
    if forward_button == null:
        _fail("FORWARD control missing")
        return
    if not await _press_and_wait(forward_button, controls, kernel):
        _fail("FORWARD did not complete")
        return

    var after_move: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if after_move == null or after_move.anchor == after_turn.anchor:
        _fail("player anchor did not change after FORWARD")
        return
    if perception.geometry_recompute_count() <= geometry_after_turn:
        _fail("geometric LOS cache was reused after player anchor changed")
        return
    var move_visible: Array[Vector2i] = perception.visible_cells()
    if _same_cells(turn_visible, move_visible):
        _fail("visible-cell cone did not move with player anchor")
        return
    if perception.last_recompute_tick() != kernel.world_tick():
        _fail("player perception did not settle on the current world tick")
        return

    print("VISION_WORLD_REFRESH_OK initial_tick=%d final_tick=%d initial_anchor=%s final_anchor=%s initial_facing=%d final_facing=%d geometry_rebuilds=%d visible_initial=%d visible_turn=%d visible_move=%d" % [
        initial_tick,
        kernel.world_tick(),
        str(initial.anchor),
        str(after_move.anchor),
        initial.facing,
        after_move.facing,
        perception.geometry_recompute_count() - initial_geometry_count,
        initial_visible.size(),
        turn_visible.size(),
        move_visible.size(),
    ])
    quit(0)

func _press_and_wait(button: Button, controls: PlayerMovementControls, kernel: TickKernel) -> bool:
    if button.disabled or not controls.is_enabled() or not kernel.is_decision_paused():
        return false
    var before_tick: int = kernel.world_tick()
    button.pressed.emit()
    if controls.is_enabled():
        return false
    for _i: int in range(MAX_WAIT_FRAMES):
        await process_frame
        if controls.is_enabled():
            return kernel.is_decision_paused() and kernel.world_tick() > before_tick
    return false

func _button_by_text(controls: PlayerMovementControls, label: String) -> Button:
    for child: Node in controls.get_children():
        var button: Button = child as Button
        if button != null and button.text == label:
            return button
    return null

func _same_cells(a: Array[Vector2i], b: Array[Vector2i]) -> bool:
    if a.size() != b.size():
        return false
    for index: int in range(a.size()):
        if a[index] != b[index]:
            return false
    return true
