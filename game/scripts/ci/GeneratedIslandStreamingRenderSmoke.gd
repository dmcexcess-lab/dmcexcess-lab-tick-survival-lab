extends SceneTree

const FixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const CollisionCatalogClass = preload("res://scripts/simulation/collision/CollisionCatalog.gd")
const TraversalClass = preload("res://scripts/simulation/movement/MovementTraversalPolicy.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const DoorMutationClass = preload("res://scripts/simulation/doors/DoorStateMutationService.gd")
const RendererClass = preload("res://scripts/render/TacticalRendererStack.gd")
const ArtCatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const PointerClass = preload("res://scripts/input/DoorPointerInputAdapter.gd")
const CameraControllerClass = preload("res://scripts/camera/TacticalCameraController.gd")
const ViewerClass = preload("res://scripts/view/LargeAreaRenderWindowController.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var collision := CollisionCatalogClass.new()
    var traversal := TraversalClass.new()
    var doors := DoorStateClass.new()
    var door_mutations := DoorMutationClass.new(doors, world)

    _check(FixtureClass.build(world, mutations, collision, traversal, doors, door_mutations, 20001), "generated island fixture builds")
    if not failures.is_empty():
        _finish()
        return

    # Lock the reported phone failure directly instead of depending on the headless CI viewport.
    var phone_margin: Vector2i = ViewerClass.edge_margin_for_view(
        Vector2(832, 1792),
        Vector2.ONE,
        FixtureClass.CELL_PIXELS,
        FixtureClass.RENDER_WINDOW_SIZE
    )
    _check(phone_margin == Vector2i(20, 40), "phone viewport expands render safety margin beyond the old fixed 12 cells")
    var phone_far_margin: Vector2i = ViewerClass.edge_margin_for_view(
        Vector2(832, 1792),
        Vector2(0.75, 0.75),
        FixtureClass.CELL_PIXELS,
        FixtureClass.RENDER_WINDOW_SIZE
    )
    _check(phone_far_margin.x > phone_margin.x and phone_far_margin.y >= phone_margin.y, "zooming out never shrinks phone render coverage")

    var renderer := RendererClass.new()
    var pointer := PointerClass.new()
    var camera_controller := CameraControllerClass.new()
    var camera := Camera2D.new()
    var viewer := ViewerClass.new()
    get_root().add_child(renderer)
    get_root().add_child(pointer)
    get_root().add_child(camera_controller)
    camera_controller.add_child(camera)
    get_root().add_child(viewer)

    _check(renderer.configure(world, ArtCatalogClass.new(), doors, FixtureClass.PLAYER_ID), "production renderer configures")
    var start: Vector2i = world.placement(FixtureClass.PLAYER_ID).anchor
    var initial_origin: Vector2i = FixtureClass.initial_render_origin(world)
    _check(viewer.configure(renderer, renderer, pointer, FixtureClass.AREA_BOUNDS, FixtureClass.RENDER_WINDOW_SIZE, FixtureClass.CELL_PIXELS, initial_origin), "production render window configures")
    _check(camera_controller.configure(world, camera, renderer, FixtureClass.PLAYER_ID, initial_origin, FixtureClass.CELL_PIXELS), "production camera configures")
    _check(viewer.attach_camera(camera_controller), "production render window attaches to camera")

    var streaming: WorldStreamingCoordinator = FixtureClass.streaming_coordinator()
    _check(streaming != null and streaming.has_focus(), "production streaming has initial focus")

    var before_origin: Vector2i = viewer.render_origin()
    var edge_margin: Vector2i = viewer.presentation_snapshot().get("edge_margin", Vector2i(12, 12))
    _check(edge_margin.x >= 12 and edge_margin.y >= 12, "runtime render margin preserves fixed safety floor")
    var edge_target := Vector2i(before_origin.x + FixtureClass.RENDER_WINDOW_SIZE.x - edge_margin.x, start.y)
    if not FixtureClass.AREA_BOUNDS.has_point(edge_target):
        edge_target = Vector2i(before_origin.x + edge_margin.x - 1, start.y)
    _check(mutations.set_placement(FixtureClass.PLAYER_ID, Layers.Channel.ACTOR, edge_target, Facing.Value.EAST, Footprint.single_cell()), "player reaches viewport-aware recenter threshold")
    _check(viewer.render_origin() != before_origin, "render window recenters before the camera can expose its unrendered edge")

    var seam_start: Vector2i = world.placement(FixtureClass.PLAYER_ID).anchor
    var start_region: Vector2i = streaming.focus_region_coord()
    var origin_before_seam: Vector2i = viewer.render_origin()
    var target := _target_across_stream_seam(seam_start)
    _check(FixtureClass.AREA_BOUNDS.has_point(target), "test target remains inside playable island bounds")
    _check(mutations.set_placement(FixtureClass.PLAYER_ID, Layers.Channel.ACTOR, target, Facing.Value.EAST, Footprint.single_cell()), "player placement crosses render and stream seam")

    _check(FixtureClass.streaming_failure().is_empty(), "player focus adapter reports no hard streaming failure")
    _check(streaming.focus_cell() == target, "streaming focus follows player into new cells")
    _check(streaming.focus_region_coord() != start_region, "player crosses a technical streaming region")
    _check(world.has_terrain(target), "newly focused player cell has authoritative terrain")
    _check(viewer.render_origin() != origin_before_seam, "render window shifts after player enters new cells")
    _check(Rect2i(viewer.render_origin(), viewer.render_size()).has_point(target), "shifted render window contains player target")

    _finish()

func _target_across_stream_seam(start: Vector2i) -> Vector2i:
    var candidates: Array[Vector2i] = [
        start + Vector2i(140, 0),
        start + Vector2i(-140, 0),
        start + Vector2i(0, 140),
        start + Vector2i(0, -140),
    ]
    for candidate: Vector2i in candidates:
        if FixtureClass.AREA_BOUNDS.has_point(candidate):
            return candidate
    return start

func _finish() -> void:
    if failures.is_empty():
        print("GENERATED_ISLAND_STREAMING_RENDER_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("GENERATED_ISLAND_STREAMING_RENDER_SMOKE_FAIL: %s" % failure)
    quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
