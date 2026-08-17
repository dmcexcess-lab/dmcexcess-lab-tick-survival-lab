extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const CatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const DoorMutationClass = preload("res://scripts/simulation/doors/DoorStateMutationService.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const RendererClass = preload("res://scripts/render/StructureLayerRenderer.gd")
const CommandClass = preload("res://scripts/render/StructureDrawCommand.gd")

var failures: Array[String] = []
var redraw_events: Array[StringName] = []

func _initialize() -> void:
    _test_visible_structure_planning_and_art()
    _test_diagnostics()
    _test_redraw_invalidation()

    if failures.is_empty():
        print("STRUCTURE_LAYER_RENDERER_SMOKE_OK")
        quit(0)
        return

    for failure: String in failures:
        push_error("STRUCTURE_LAYER_RENDERER_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture() -> Dictionary:
    var world := WorldStateClass.new()
    var world_mutations := WorldMutationClass.new(world)
    var doors := DoorStateClass.new()
    var door_mutations := DoorMutationClass.new(doors, world)
    var renderer := RendererClass.new()
    _check(renderer.configure(world, CatalogClass.new(), doors), "renderer configures with WHAT + ArtCatalog + DoorState")
    return {
        "world": world,
        "world_mutations": world_mutations,
        "doors": doors,
        "door_mutations": door_mutations,
        "renderer": renderer,
    }

func _create_structure(
    world_mutations: WorldMutationService,
    semantic_type: StringName,
    entity_id: String,
    cell: Vector2i,
    axis: int
) -> bool:
    if world_mutations.create_entity(semantic_type, entity_id).is_empty():
        return false
    return world_mutations.set_placement(
        entity_id,
        Layers.Channel.STRUCTURE,
        cell,
        Facing.Value.NORTH,
        Footprint.single_cell(),
        axis
    )

func _test_visible_structure_planning_and_art() -> void:
    var fixture: Dictionary = _fixture()
    var world_mutations: WorldMutationService = fixture["world_mutations"]
    var door_mutations: DoorStateMutationService = fixture["door_mutations"]
    var renderer: StructureLayerRenderer = fixture["renderer"]

    _check(not renderer.set_visible_window(Vector2i.ZERO, Vector2i(0, 2), 32.0), "zero-width view rejected")
    _check(not renderer.set_visible_window(Vector2i.ZERO, Vector2i(2, 2), 0.0), "zero cell size rejected")
    _check(renderer.set_visible_window(Vector2i(-2, -1), Vector2i(3, 2), 24.0), "negative-origin view accepted")

    _check(_create_structure(world_mutations, &"wall.wallpaper", "wall.a", Vector2i(-2, -1), StructureGeometry.Axis.HORIZONTAL), "create horizontal wallpaper wall")
    _check(_create_structure(world_mutations, &"door.house", "door.a", Vector2i(-1, -1), StructureGeometry.Axis.VERTICAL), "create vertical house door")
    _check(_create_structure(world_mutations, &"window.office", "window.a", Vector2i(0, -1), StructureGeometry.Axis.HORIZONTAL), "create office window")
    _check(door_mutations.enroll("door.a", DoorValue.CLOSED), "explicit CLOSED state enrolled for visible door")

    var commands: Array[StructureDrawCommand] = renderer.plan_visible_commands()
    _check(commands.size() == 3, "only visible occupied structure cells produce commands")
    if commands.size() == 3:
        _check(commands[0].cell == Vector2i(-2, -1), "commands are row-major by visible cell")
        _check(commands[1].cell == Vector2i(-1, -1), "row-major order advances x")
        _check(commands[2].cell == Vector2i(0, -1), "row-major order reaches window")
        _check(commands[0].destination == Rect2(0, 0, 24, 24), "visible origin maps to local zero")
        _check(commands[2].destination == Rect2(48, 0, 24, 24), "destination remains local to visible origin")
        _check(commands[0].kind == CommandClass.KIND_WALL, "wall category retained")
        _check(commands[1].kind == CommandClass.KIND_DOOR, "door category retained")
        _check(commands[2].kind == CommandClass.KIND_WINDOW, "window category retained")
        _check(commands[0].structure_axis == StructureGeometry.Axis.HORIZONTAL, "horizontal wall axis retained")
        _check(commands[1].structure_axis == StructureGeometry.Axis.VERTICAL, "vertical door axis retained")
        _expect_selection(commands[0].selection, CatalogClass.SOURCE_FINAL_SURFACES, 48, "wallpaper uses recovered final wall art")
        _expect_selection(commands[1].selection, CatalogClass.SOURCE_WORLD, 48, "closed house door uses recovered closed art")
        _expect_selection(commands[2].selection, CatalogClass.SOURCE_WORLD, 61, "office window uses recovered world art")

    _check(door_mutations.set_state("door.a", DoorValue.OPEN), "visible door changes OPEN")
    var door_command: StructureDrawCommand = _command_for_entity(renderer.plan_visible_commands(), "door.a")
    _check(door_command != null, "open door command exists")
    if door_command != null:
        _expect_selection(door_command.selection, CatalogClass.SOURCE_WORLD, 49, "open house door uses distinct recovered open art")

    _check(_create_structure(world_mutations, &"wall.wallpaper", "wall.axis.b", Vector2i(-2, 0), StructureGeometry.Axis.VERTICAL), "same wall theme with vertical axis")
    var horizontal: StructureDrawCommand = _command_for_entity(renderer.plan_visible_commands(), "wall.a")
    var vertical: StructureDrawCommand = _command_for_entity(renderer.plan_visible_commands(), "wall.axis.b")
    _check(horizontal != null and vertical != null, "both wall-axis commands exist")
    if horizontal != null and vertical != null:
        _check(horizontal.selection.atlas_index == vertical.selection.atlas_index, "golden wall art is not rotated/swapped solely by axis")

    for command: StructureDrawCommand in renderer.plan_visible_commands():
        if command.selection != null and command.selection.is_found():
            _check(ResourceLoader.exists(command.selection.source.texture_path), "resolved structure texture path exists")
            _check(ResourceLoader.load(command.selection.source.texture_path) is Texture2D, "resolved structure texture loads as Texture2D")

func _test_diagnostics() -> void:
    var fixture: Dictionary = _fixture()
    var world_mutations: WorldMutationService = fixture["world_mutations"]
    var renderer: StructureLayerRenderer = fixture["renderer"]
    _check(renderer.set_visible_window(Vector2i.ZERO, Vector2i(4, 2), 32.0), "diagnostic view configures")

    _check(_create_structure(world_mutations, &"door.house", "door.unknown", Vector2i(0, 0), StructureGeometry.Axis.HORIZONTAL), "door without Door State created")
    _check(_create_structure(world_mutations, &"wall.not_real", "wall.unknown", Vector2i(1, 0), StructureGeometry.Axis.HORIZONTAL), "unknown wall theme created")

    _check(not world_mutations.create_entity(&"wall.house", "wall.noaxis").is_empty(), "no-axis wall entity created")
    _check(world_mutations.set_placement("wall.noaxis", Layers.Channel.STRUCTURE, Vector2i(2, 0), Facing.Value.NORTH, Footprint.single_cell()), "STRUCTURE placement without axis is representable and remains diagnostic")

    _check(_create_structure(world_mutations, &"wall.house", "wall.overlap.a", Vector2i(3, 0), StructureGeometry.Axis.HORIZONTAL), "first overlapping wall created")
    _check(_create_structure(world_mutations, &"window.house", "window.overlap.b", Vector2i(3, 0), StructureGeometry.Axis.VERTICAL), "second overlapping structure created")

    _check(_create_structure(world_mutations, &"fixture.strange", "structure.unknown", Vector2i(0, 1), StructureGeometry.Axis.HORIZONTAL), "unknown structure semantic created")

    var commands: Array[StructureDrawCommand] = renderer.plan_visible_commands()
    _expect_diagnostic(_command_for_entity(commands, "door.unknown"), "door_state_unknown", "missing Door State is diagnostic")
    _expect_diagnostic(_command_for_entity(commands, "wall.unknown"), "wall_unclassified", "unknown wall theme is diagnostic")
    _expect_diagnostic(_command_for_entity(commands, "wall.noaxis"), "structure_axis_invalid", "missing structure axis is diagnostic")
    _expect_diagnostic(_command_for_cell(commands, Vector2i(3, 0)), "multiple_structure_occupants", "overlapping structures are diagnostic")
    _expect_diagnostic(_command_for_entity(commands, "structure.unknown"), "structure_semantic_unclassified", "unknown semantic category is diagnostic")

func _test_redraw_invalidation() -> void:
    redraw_events.clear()
    var fixture: Dictionary = _fixture()
    var world: WorldState = fixture["world"]
    var world_mutations: WorldMutationService = fixture["world_mutations"]
    var doors: DoorStateStore = fixture["doors"]
    var door_mutations: DoorStateMutationService = fixture["door_mutations"]
    var renderer: StructureLayerRenderer = fixture["renderer"]
    renderer.redraw_requested.connect(_on_redraw_requested)
    _check(renderer.set_visible_window(Vector2i(10, 10), Vector2i(3, 3), 32.0), "redraw view configures")
    redraw_events.clear()

    _check(world_mutations.set_terrain(Vector2i(11, 11), &"ground.grass"), "visible terrain mutation succeeds")
    _check(redraw_events.is_empty(), "terrain changes do not redraw Structure")

    _check(not world_mutations.create_entity(&"object.chair", "chair.visible").is_empty(), "visible object entity created")
    _check(world_mutations.set_placement("chair.visible", Layers.Channel.OBJECT, Vector2i(11, 11), Facing.Value.NORTH, Footprint.single_cell()), "visible object placement succeeds")
    _check(redraw_events.is_empty(), "initial non-structure object placement does not redraw Structure")

    _check(_create_structure(world_mutations, &"wall.house", "wall.visible", Vector2i(11, 11), StructureGeometry.Axis.HORIZONTAL), "visible structure placement succeeds")
    _check(redraw_events.size() == 1 and redraw_events[0] == &"structure_placement_changed", "visible structure placement requests redraw")
    redraw_events.clear()

    _check(_create_structure(world_mutations, &"wall.house", "wall.distant", Vector2i(40, 40), StructureGeometry.Axis.HORIZONTAL), "distant structure placement succeeds")
    _check(redraw_events.is_empty(), "distant structure placement does not redraw")

    _check(_create_structure(world_mutations, &"door.house", "door.visible", Vector2i(12, 12), StructureGeometry.Axis.VERTICAL), "visible door placement succeeds")
    redraw_events.clear()
    _check(door_mutations.enroll("door.visible", DoorValue.CLOSED), "visible door state enrollment succeeds")
    _check(redraw_events.size() == 1 and redraw_events[0] == &"door_state_changed", "visible door enrollment redraws UNKNOWN to known state")
    redraw_events.clear()

    _check(door_mutations.set_state("door.visible", DoorValue.OPEN), "visible door state changes")
    _check(redraw_events.size() == 1 and redraw_events[0] == &"door_state_changed", "visible door state change redraws")
    redraw_events.clear()

    _check(_create_structure(world_mutations, &"door.house", "door.distant", Vector2i(50, 50), StructureGeometry.Axis.HORIZONTAL), "distant door placement succeeds")
    _check(door_mutations.enroll("door.distant", DoorValue.CLOSED), "distant door state enrolls")
    redraw_events.clear()
    _check(door_mutations.set_state("door.distant", DoorValue.OPEN), "distant door state changes")
    _check(redraw_events.is_empty(), "distant door state does not redraw visible Structure")

    _check(door_mutations.remove("door.visible"), "visible door state removed")
    _check(redraw_events.size() == 1 and redraw_events[0] == &"door_state_changed", "visible door state removal redraws to diagnostic")
    redraw_events.clear()

    var door_snapshot: Dictionary = doors.snapshot()
    _check(doors.load_snapshot(door_snapshot), "Door State snapshot reload succeeds")
    _check(redraw_events.size() == 1 and redraw_events[0] == &"door_state_reset", "Door State reset redraws Structure")
    redraw_events.clear()

    var world_snapshot: Dictionary = world.snapshot()
    _check(world.load_snapshot(world_snapshot), "WHAT snapshot reload succeeds")
    _check(redraw_events.size() == 1 and redraw_events[0] == &"world_reset", "WHAT reset redraws Structure")

func _command_for_entity(commands: Array[StructureDrawCommand], entity_id: String) -> StructureDrawCommand:
    for command: StructureDrawCommand in commands:
        if command.entity_id == entity_id:
            return command
    return null

func _command_for_cell(commands: Array[StructureDrawCommand], cell: Vector2i) -> StructureDrawCommand:
    for command: StructureDrawCommand in commands:
        if command.cell == cell:
            return command
    return null

func _expect_selection(selection: ArtSelection, source_id: StringName, index: int, message: String) -> void:
    _check(selection != null and selection.is_found(), "%s is found" % message)
    if selection == null or not selection.is_found():
        return
    _check(selection.source.source_id == source_id, "%s source" % message)
    _check(selection.atlas_index == index, "%s atlas index" % message)

func _expect_diagnostic(command: StructureDrawCommand, reason: String, message: String) -> void:
    _check(command != null, "%s command exists" % message)
    if command == null:
        return
    _check(command.is_diagnostic(), "%s is diagnostic" % message)
    _check(command.diagnostic_reason() == reason, "%s reason" % message)

func _on_redraw_requested(reason: StringName) -> void:
    redraw_events.append(reason)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
