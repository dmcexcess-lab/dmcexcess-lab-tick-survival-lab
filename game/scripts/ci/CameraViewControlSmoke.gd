extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const StateClass = preload("res://scripts/camera/TacticalCameraState.gd")
const ZoomClass = preload("res://scripts/camera/ZoomController.gd")
const ControllerClass = preload("res://scripts/camera/TacticalCameraController.gd")
const InputClass = preload("res://scripts/input/CameraInputAdapter.gd")

const PLAYER_ID := "actor.camera.player"
const TARGET_ID := "actor.camera.target"
const CELL_PIXELS: float = 32.0

var failures: Array[String] = []
var _input_pan_events: int = 0
var _input_zoom_in_events: int = 0
var _input_zoom_out_events: int = 0

func _initialize() -> void:
    _test_zoom_contract()

    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    _check(mutations.create_entity(&"actor.survivor", PLAYER_ID) == PLAYER_ID, "player entity created")
    _check(mutations.create_entity(&"actor.survivor", TARGET_ID) == TARGET_ID, "target entity created")
    _check(
        mutations.set_placement(PLAYER_ID, Layers.Channel.ACTOR, Vector2i(5, 6), Facing.Value.NORTH, Footprint.single_cell()),
        "player placed"
    )
    _check(
        mutations.set_placement(TARGET_ID, Layers.Channel.ACTOR, Vector2i(9, 8), Facing.Value.SOUTH, Footprint.single_cell()),
        "target placed"
    )

    var world_view := Node2D.new()
    world_view.position = Vector2(73, 72)
    get_root().add_child(world_view)

    var controller: TacticalCameraController = ControllerClass.new()
    get_root().add_child(controller)
    var camera := Camera2D.new()
    controller.add_child(camera)

    var player_before: Vector2i = world.placement(PLAYER_ID).anchor
    _check(
        controller.configure(world, camera, world_view, PLAYER_ID, Vector2i.ZERO, CELL_PIXELS),
        "camera controller configures"
    )
    _check(controller.mode() == StateClass.Mode.FOLLOW_PLAYER, "camera defaults to player follow")
    _check(controller.zoom_level() == ZoomClass.DEFAULT_LEVEL, "camera defaults to Normal zoom")
    _check(_near(camera.zoom, Vector2.ONE), "Normal zoom applies exactly")
    _check(_near(camera.global_position, _cell_position(world_view, Vector2i(5, 6))), "camera centers on player")
    _check(world.placement(PLAYER_ID).anchor == player_before, "camera configure does not move player")

    _check(
        mutations.set_placement(PLAYER_ID, Layers.Channel.ACTOR, Vector2i(6, 6), Facing.Value.NORTH, Footprint.single_cell()),
        "player moved for follow test"
    )
    _check(_near(camera.global_position, _cell_position(world_view, Vector2i(6, 6))), "follow reacts to player placement change")

    _check(controller.zoom_out(), "zoom out step one accepted")
    _check(controller.zoom_level() == 3 and _near(camera.zoom, Vector2(0.75, 0.75)), "Far zoom applies")
    _check(controller.zoom_out(), "zoom out step two accepted")
    _check(controller.zoom_level() == 4 and _near(camera.zoom, Vector2(0.5, 0.5)), "Area zoom applies")
    _check(controller.zoom_out(), "zoom out boundary is harmless")
    _check(controller.zoom_level() == 4, "Area is maximum zoom-out level")
    _check(controller.set_zoom_level(2), "Normal zoom restored")

    var followed_position: Vector2 = camera.global_position
    _check(controller.pan_screen_pixels(Vector2(40, 0)), "manual pan accepted")
    _check(controller.mode() == StateClass.Mode.DETACHED, "manual pan enters detached inspect")
    _check(_near(camera.global_position, followed_position - Vector2(40, 0)), "manual pan uses screen-pixel delta at Normal zoom")
    var detached_position: Vector2 = camera.global_position
    _check(
        mutations.set_placement(PLAYER_ID, Layers.Channel.ACTOR, Vector2i(7, 6), Facing.Value.NORTH, Footprint.single_cell()),
        "player moved while detached"
    )
    _check(_near(camera.global_position, detached_position), "detached camera ignores player movement")
    _check(controller.recenter_player(), "recenter accepted")
    _check(controller.mode() == StateClass.Mode.FOLLOW_PLAYER, "recenter returns to follow mode")
    _check(_near(camera.global_position, _cell_position(world_view, Vector2i(7, 6))), "recenter finds current player cell")

    var player_anchor_before_focus: Vector2i = world.placement(PLAYER_ID).anchor
    _check(controller.focus_cell(Vector2i(2, 3), 3, true), "cell focus accepted")
    _check(controller.mode() == StateClass.Mode.FOCUS_CELL, "cell focus mode active")
    _check(controller.zoom_level() == 3, "cell focus may request discrete zoom")
    _check(_near(camera.global_position, _cell_position(world_view, Vector2i(2, 3))), "cell focus centers requested cell")
    _check(world.placement(PLAYER_ID).anchor == player_anchor_before_focus, "cell focus does not move player")
    _check(controller.restore_previous(), "cell focus restores previous state")
    _check(controller.mode() == StateClass.Mode.FOLLOW_PLAYER and controller.zoom_level() == 2, "restore returns follow + previous zoom")

    _check(controller.focus_actor(TARGET_ID, -1, true), "actor focus accepted")
    _check(controller.mode() == StateClass.Mode.FOCUS_ACTOR, "actor focus mode active")
    _check(_near(camera.global_position, _cell_position(world_view, Vector2i(9, 8))), "actor focus centers target")
    _check(
        mutations.set_placement(TARGET_ID, Layers.Channel.ACTOR, Vector2i(10, 8), Facing.Value.SOUTH, Footprint.single_cell()),
        "target actor moved"
    )
    _check(_near(camera.global_position, _cell_position(world_view, Vector2i(10, 8))), "actor focus follows target placement")
    _check(controller.restore_previous(), "actor focus restores previous state")
    _check(controller.mode() == StateClass.Mode.FOLLOW_PLAYER, "actor restore returns player follow")

    var kernel := TickKernelClass.new(PLAYER_ID)
    var tick_before: int = kernel.world_tick()
    _check(controller.scripted_focus_cell(Vector2i(3, 4), 4, 0.0, true), "zero-duration scripted focus accepted")
    _check(controller.mode() == StateClass.Mode.FOCUS_CELL, "scripted focus settles into focus mode")
    _check(controller.zoom_level() == 4 and _near(camera.zoom, Vector2(0.5, 0.5)), "scripted focus reaches requested Area zoom")
    _check(_near(camera.global_position, _cell_position(world_view, Vector2i(3, 4))), "scripted focus reaches requested cell")
    _check(kernel.world_tick() == tick_before, "scripted presentation advances zero simulation ticks")
    _check(controller.restore_previous(), "scripted focus restores previous state")

    _test_touch_input_contract()

    controller.queue_free()
    world_view.queue_free()

    if failures.is_empty():
        print("CAMERA_VIEW_CONTROL_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("CAMERA_VIEW_CONTROL_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_zoom_contract() -> void:
    var zoom: ZoomController = ZoomClass.new()
    _check(zoom.level_count() == 5, "exactly five zoom levels")
    _check(zoom.label(0) == "VERY CLOSE" and is_equal_approx(zoom.scale(0), 1.75), "Very Close preset exact")
    _check(zoom.label(1) == "CLOSE" and is_equal_approx(zoom.scale(1), 1.35), "Close preset exact")
    _check(zoom.label(2) == "NORMAL" and is_equal_approx(zoom.scale(2), 1.0), "Normal preset exact")
    _check(zoom.label(3) == "FAR" and is_equal_approx(zoom.scale(3), 0.75), "Far preset exact")
    _check(zoom.label(4) == "AREA" and is_equal_approx(zoom.scale(4), 0.5), "Area preset exact")
    _check(zoom.zoom_in(0) == 0 and zoom.zoom_out(4) == 4, "zoom boundaries clamp deterministically")

func _test_touch_input_contract() -> void:
    var adapter: CameraInputAdapter = InputClass.new()
    get_root().add_child(adapter)
    adapter.pan_requested.connect(_on_pan_requested)
    adapter.zoom_in_requested.connect(_on_zoom_in_requested)
    adapter.zoom_out_requested.connect(_on_zoom_out_requested)

    var touch_one := InputEventScreenTouch.new()
    touch_one.index = 0
    touch_one.position = Vector2(100, 100)
    touch_one.pressed = true
    adapter._unhandled_input(touch_one)

    var one_finger_drag := InputEventScreenDrag.new()
    one_finger_drag.index = 0
    one_finger_drag.position = Vector2(90, 100)
    adapter._unhandled_input(one_finger_drag)
    _check(_input_pan_events == 0 and _input_zoom_in_events == 0 and _input_zoom_out_events == 0, "one-finger touch is ignored by camera gestures")

    var touch_two := InputEventScreenTouch.new()
    touch_two.index = 1
    touch_two.position = Vector2(200, 100)
    touch_two.pressed = true
    adapter._unhandled_input(touch_two)

    var drag_two := InputEventScreenDrag.new()
    drag_two.index = 1
    drag_two.position = Vector2(225, 100)
    adapter._unhandled_input(drag_two)
    _check(_input_pan_events > 0, "two-finger centroid drag emits camera pan")
    _check(_input_zoom_in_events > 0, "two-finger pinch snaps to a zoom-in request")

    touch_one.pressed = false
    touch_one.position = Vector2(90, 100)
    adapter._unhandled_input(touch_one)
    touch_two.pressed = false
    touch_two.position = Vector2(225, 100)
    adapter._unhandled_input(touch_two)
    _check(adapter.tracked_touch_count() == 0, "touch gesture state clears on release")
    adapter.queue_free()

func _on_pan_requested(_delta: Vector2) -> void:
    _input_pan_events += 1

func _on_zoom_in_requested() -> void:
    _input_zoom_in_events += 1

func _on_zoom_out_requested() -> void:
    _input_zoom_out_events += 1

func _cell_position(world_view: Node2D, cell: Vector2i) -> Vector2:
    return world_view.to_global(Vector2((float(cell.x) + 0.5) * CELL_PIXELS, (float(cell.y) + 0.5) * CELL_PIXELS))

func _near(a: Vector2, b: Vector2) -> bool:
    return a.distance_to(b) <= 0.01

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
