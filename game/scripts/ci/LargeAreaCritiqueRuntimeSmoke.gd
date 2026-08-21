extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const CollisionCatalogClass = preload("res://scripts/simulation/collision/CollisionCatalog.gd")
const CollisionOverridesClass = preload("res://scripts/simulation/collision/CollisionOverrideState.gd")
const SpatialQueryClass = preload("res://scripts/simulation/collision/SpatialQueryService.gd")
const TraversalClass = preload("res://scripts/simulation/movement/MovementTraversalPolicy.gd")
const MovementClass = preload("res://scripts/simulation/movement/PassageAwareMovementActionService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const DoorMutationClass = preload("res://scripts/simulation/doors/DoorStateMutationService.gd")
const DoorTransitionClass = preload("res://scripts/simulation/doors/DoorPhysicalTransitionService.gd")
const DoorPassageClass = preload("res://scripts/simulation/doors/DoorMovementPassageResolver.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const FixtureClass = preload("res://scripts/demo/RuralCrossroadsCritiqueFixture.gd")
const PlanFixtureClass = preload("res://scripts/demo/RuralCrossroadsPlanFixture.gd")
const AreaMaterializerClass = preload("res://scripts/generation/areas/AreaMaterializationCoordinator.gd")
const RendererClass = preload("res://scripts/render/TacticalRendererStack.gd")
const ArtCatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const PointerClass = preload("res://scripts/input/DoorPointerInputAdapter.gd")
const CameraControllerClass = preload("res://scripts/camera/TacticalCameraController.gd")
const ViewerClass = preload("res://scripts/view/LargeAreaRenderWindowController.gd")
const CameraControlsClass = preload("res://scripts/ui/CameraControls.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _run()

func _run() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var collision := CollisionCatalogClass.new()
    var traversal := TraversalClass.new()
    var doors := DoorStateClass.new()
    var door_mutations := DoorMutationClass.new(doors, world)

    var plan: GeneratedAreaPlan = FixtureClass.generate_plan()
    _check(plan != null and plan.is_generated(), "Candidate 001 plan generates")
    _check(plan.building_requests.size() == 12, "Candidate 001 still has twelve existing-library buildings")
    _check(FixtureClass.build(world, mutations, collision, traversal, doors, door_mutations), "playable rural crossroads fixture builds")

    _check(world.has_terrain(PlanFixtureClass.CENTER), "central crossroads terrain materialized")
    _check(world.entity_ids().size() > plan.outdoor_props.size(), "building and outdoor entities materialized")
    for prop: Dictionary in plan.outdoor_props:
        _check(world.has_entity(String(prop.get("id", ""))), "outdoor prop materialized: %s" % String(prop.get("id", "")))

    var materializer := AreaMaterializerClass.new(world, mutations, doors, door_mutations)
    var building_plans: Array[GeneratedBuildingPlan] = materializer.generated_building_plans(plan)
    _check(building_plans.size() == 12, "all public System 19 subplans regenerate")
    var door_count: int = 0
    for building_plan: GeneratedBuildingPlan in building_plans:
        for structure: Dictionary in building_plan.structures:
            if String(structure.get("kind", "")) != "door":
                continue
            door_count += 1
            var door_id: String = "%s.%s" % [building_plan.instance_id, String(structure.get("role", ""))]
            _check(doors.has_door(door_id), "building door enrolled: %s" % door_id)
            _check(doors.state(door_id) == DoorValue.CLOSED, "building door starts closed: %s" % door_id)
    _check(door_count > 20, "multiple prefab door sets materialized")

    var expected_start: Vector2i = FixtureClass.player_start_for_plan(plan)
    var player_placement: WorldPlacement = world.placement(FixtureClass.PLAYER_ID)
    _check(player_placement != null and player_placement.anchor == expected_start, "player starts outside generated diner")
    var diner_door_id: String = FixtureClass.diner_door_id(plan)
    _check(not diner_door_id.is_empty() and doors.has_door(diner_door_id), "generated diner primary door exists")

    var overrides := CollisionOverridesClass.new()
    var query := SpatialQueryClass.new(world, collision, overrides)
    var kernel := TickKernelClass.new(FixtureClass.PLAYER_ID)
    var transition := DoorTransitionClass.new(world, doors, door_mutations, overrides)
    var passage := DoorPassageClass.new(world, doors, transition)
    var movement := MovementClass.new(world, mutations, query, kernel, traversal, passage)
    _check(movement.is_ready(), "area movement stack ready")
    var walk = movement.request_step_forward(FixtureClass.PLAYER_ID)
    _check(walk != null and walk.is_accepted(), "player can walk toward generated diner door")
    kernel.run_until_stop()
    _check(doors.state(diner_door_id) == DoorValue.OPEN, "System 18 opens generated diner door")
    var diner_entry: Vector2i = _diner_entry(plan)
    _check(world.placement(FixtureClass.PLAYER_ID).anchor == diner_entry, "player enters generated diner in area world")

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

    var art := ArtCatalogClass.new()
    _check(renderer.configure(world, art, doors, FixtureClass.PLAYER_ID), "area renderer configures")
    var initial_origin: Vector2i = FixtureClass.initial_render_origin(world)
    _check(viewer.configure(renderer, renderer, pointer, FixtureClass.AREA_BOUNDS, FixtureClass.RENDER_WINDOW_SIZE, FixtureClass.CELL_PIXELS, initial_origin), "bounded render window configures")
    _check(FixtureClass.RENDER_WINDOW_SIZE.x < FixtureClass.AREA_BOUNDS.size.x and FixtureClass.RENDER_WINDOW_SIZE.y < FixtureClass.AREA_BOUNDS.size.y, "renderer window is smaller than logical area")
    _check(camera_controller.configure(world, camera, renderer, FixtureClass.PLAYER_ID, initial_origin, FixtureClass.CELL_PIXELS), "System 21 configures over area renderer")
    _check(viewer.attach_camera(camera_controller), "area viewer attaches to System 21")

    var reference_cell: Vector2i = world.placement(FixtureClass.PLAYER_ID).anchor
    var before_origin: Vector2i = viewer.render_origin()
    var before_global: Vector2 = _rendered_cell_center(renderer, before_origin, reference_cell)
    var player_before_pan: Vector2i = reference_cell
    _check(camera_controller.pan_screen_pixels(Vector2(-1400.0, 0.0)), "detached camera pan accepts")
    var after_origin: Vector2i = viewer.render_origin()
    _check(after_origin != before_origin, "detached pan shifts bounded render window")
    var after_global: Vector2 = _rendered_cell_center(renderer, after_origin, reference_cell)
    _check(before_global.is_equal_approx(after_global), "render-window shift preserves global world-cell pixel position")
    _check(world.placement(FixtureClass.PLAYER_ID).anchor == player_before_pan, "camera pan does not move player")
    _check(camera_controller.recenter_player(), "CENTER command succeeds")
    _check(camera_controller.mode() == TacticalCameraState.Mode.FOLLOW_PLAYER, "CENTER restores follow mode")

    _check(_touch_center_control_once(), "explicit touch CENTER emits exactly one recenter request")

    if failures.is_empty():
        print("LARGE_AREA_CRITIQUE_RUNTIME_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("LARGE_AREA_CRITIQUE_RUNTIME_SMOKE_FAIL: %s" % failure)
    quit(1)

func _touch_center_control_once() -> bool:
    var controls := CameraControlsClass.new()
    get_root().add_child(controls)
    var counter: Array[int] = [0]
    controls.recenter_requested.connect(func() -> void: counter[0] += 1)

    var touch := InputEventScreenTouch.new()
    touch.index = 0
    touch.pressed = false
    if not controls.dispatch_control_event(touch, CameraControlsClass.ACTION_RECENTER, 1000):
        return false

    var synthetic_mouse := InputEventMouseButton.new()
    synthetic_mouse.button_index = MOUSE_BUTTON_LEFT
    synthetic_mouse.pressed = false
    if not controls.dispatch_control_event(synthetic_mouse, CameraControlsClass.ACTION_RECENTER, 1000):
        return false
    return counter[0] == 1

func _diner_entry(plan: GeneratedAreaPlan) -> Vector2i:
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("building_archetype_id", &"")) == FixtureClass.DINER_ARCHETYPE:
            return parcel.get("building_entry_cell", Vector2i(-1, -1))
    return Vector2i(-1, -1)

func _rendered_cell_center(world_view: Node2D, origin: Vector2i, cell: Vector2i) -> Vector2:
    var local: Vector2i = cell - origin
    return world_view.to_global(Vector2(
        (float(local.x) + 0.5) * FixtureClass.CELL_PIXELS,
        (float(local.y) + 0.5) * FixtureClass.CELL_PIXELS
    ))

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
