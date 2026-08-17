extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const CatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const SelectionClass = preload("res://scripts/art/ArtSelection.gd")
const RendererClass = preload("res://scripts/render/GroundLayerRenderer.gd")
const Road = preload("res://scripts/art/RoadArtTopology.gd")

var _failures: Array[String] = []
var _redraw_events: Array[StringName] = []

func _initialize() -> void:
    _test_visible_command_planning()
    _test_topology_selection()
    _test_diagnostics()
    _test_redraw_invalidation()

    if _failures.is_empty():
        print("GROUND_LAYER_RENDERER_SMOKE_OK")
        quit(0)
        return

    for failure: String in _failures:
        push_error("GROUND_LAYER_RENDERER_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_visible_command_planning() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var catalog := CatalogClass.new()
    var renderer := RendererClass.new()

    _check(renderer.configure(world, catalog), "renderer configures with WHAT + ArtCatalog")
    _check(not renderer.set_visible_window(Vector2i.ZERO, Vector2i(0, 2), 32.0), "zero-width view rejected")
    _check(not renderer.set_visible_window(Vector2i.ZERO, Vector2i(2, 2), 0.0), "zero cell size rejected")
    _check(renderer.set_visible_window(Vector2i(-2, -1), Vector2i(3, 2), 24.0), "negative-origin view accepted")

    var semantics: Array[StringName] = [
        &"ground.grass",
        &"ground.hardwood_h",
        &"ground.tile_white",
        &"ground.dirt_light",
        &"ground.concrete_clean",
        &"ground.gravel",
    ]
    var index: int = 0
    for y in range(-1, 1):
        for x in range(-2, 1):
            _check(mutations.set_terrain(Vector2i(x, y), semantics[index]), "seed visible terrain %d" % index)
            index += 1

    var commands: Array[GroundDrawCommand] = renderer.plan_visible_commands()
    _check(commands.size() == 6, "only visible 3x2 cells are planned")
    if commands.size() == 6:
        _check(commands[0].cell == Vector2i(-2, -1), "row-major command starts at visible origin")
        _check(commands[1].cell == Vector2i(-1, -1), "row-major command advances x first")
        _check(commands[3].cell == Vector2i(-2, 0), "row-major command advances y after row")
        _check(commands[0].destination == Rect2(0, 0, 24, 24), "visible origin maps to local zero rectangle")
        _check(commands[2].destination == Rect2(48, 0, 24, 24), "destination x is local to visible origin")
        _check(commands[5].destination == Rect2(48, 24, 24, 24), "destination y is local to visible origin")
        _expect_selection(commands[0].selection, CatalogClass.SOURCE_FINAL_SURFACES, 0, "grass keeps final alias precedence")
        _expect_selection(commands[1].selection, CatalogClass.SOURCE_WORLD, 32, "hardwood uses recovered world atlas")
        _expect_selection(commands[2].selection, CatalogClass.SOURCE_FINAL_SURFACES, 38, "tile_white uses recovered final surface")

    for command: GroundDrawCommand in commands:
        if command.selection != null and command.selection.is_found():
            _check(ResourceLoader.exists(command.selection.source.texture_path), "found ground texture path exists")
            var loaded: Resource = ResourceLoader.load(command.selection.source.texture_path)
            _check(loaded is Texture2D, "found ground texture loads as Texture2D")

func _test_topology_selection() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var catalog := CatalogClass.new()
    var renderer := RendererClass.new()
    _check(renderer.configure(world, catalog), "topology renderer configures")
    _check(renderer.set_visible_window(Vector2i(-2, -2), Vector2i(5, 5), 32.0), "topology view configures")

    var center := Vector2i.ZERO
    _check(mutations.set_terrain(center, &"ground.road"), "seed center road")
    _check(mutations.set_terrain(Vector2i.UP, &"ground.road"), "seed north road")
    _expect_cell_selection(renderer, center, CatalogClass.SOURCE_WORLD, 11, "road endpoint north")

    _check(mutations.set_terrain(Vector2i.DOWN, &"ground.road"), "seed south road")
    _expect_cell_selection(renderer, center, CatalogClass.SOURCE_WORLD, 0, "road vertical straight")

    _check(mutations.clear_terrain(Vector2i.DOWN), "clear south road")
    _check(mutations.set_terrain(Vector2i.RIGHT, &"ground.dirt_road"), "mixed dirt neighbor connects")
    _expect_cell_selection(renderer, center, CatalogClass.SOURCE_WORLD, 2, "road NE corner with dirt neighbor")

    _check(mutations.set_terrain(Vector2i.DOWN, &"ground.road"), "restore south road")
    _expect_cell_selection(renderer, center, CatalogClass.SOURCE_WORLD, 6, "road NES T intersection")

    _check(mutations.set_terrain(Vector2i.LEFT, &"ground.road_h"), "explicit road variant participates in connectivity")
    _expect_cell_selection(renderer, center, CatalogClass.SOURCE_WORLD, 10, "road cross intersection")

    _check(mutations.set_terrain(center, &"ground.dirt_road"), "center becomes generic dirt road")
    _expect_cell_selection(renderer, center, CatalogClass.SOURCE_WORLD, 30, "mixed-direction dirt road uses gravel topology")

    _check(mutations.clear_terrain(Vector2i.UP), "clear north for horizontal dirt")
    _check(mutations.clear_terrain(Vector2i.DOWN), "clear south for horizontal dirt")
    _expect_cell_selection(renderer, center, CatalogClass.SOURCE_WORLD, 28, "horizontal dirt road")

    _check(mutations.clear_terrain(Vector2i.RIGHT), "clear east for vertical test")
    _check(mutations.clear_terrain(Vector2i.LEFT), "clear west for vertical test")
    _check(mutations.set_terrain(Vector2i.UP, &"ground.road"), "north road for vertical dirt")
    _check(mutations.set_terrain(Vector2i.DOWN, &"ground.road"), "south road for vertical dirt")
    _expect_cell_selection(renderer, center, CatalogClass.SOURCE_WORLD, 29, "vertical dirt road")

    _check(mutations.set_terrain(center, &"ground.sidewalk"), "center becomes sidewalk")
    _check(mutations.clear_terrain(Vector2i.DOWN), "single adjacent road for curb")
    _expect_cell_selection(renderer, center, CatalogClass.SOURCE_WORLD, 17, "single north road gives north curb")
    _check(mutations.set_terrain(Vector2i.RIGHT, &"ground.road"), "second adjacent road for plain sidewalk")
    _expect_cell_selection(renderer, center, CatalogClass.SOURCE_WORLD, 16, "multiple adjacent roads give plain sidewalk")

    _check(mutations.set_terrain(center, &"ground.road_ne"), "explicit road topology variant")
    _check(mutations.clear_terrain(Vector2i.UP), "neighbors do not control explicit variant")
    _check(mutations.clear_terrain(Vector2i.RIGHT), "neighbors removed around explicit variant")
    _expect_cell_selection(renderer, center, CatalogClass.SOURCE_WORLD, 2, "explicit road_ne remains literal")

func _test_diagnostics() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var renderer := RendererClass.new()
    _check(renderer.configure(world, CatalogClass.new()), "diagnostic renderer configures")
    _check(renderer.set_visible_window(Vector2i.ZERO, Vector2i(2, 1), 32.0), "diagnostic view configures")
    _check(mutations.set_terrain(Vector2i(1, 0), &"ground.not_real"), "unknown terrain can exist as semantic WHAT fact")

    var commands: Array[GroundDrawCommand] = renderer.plan_visible_commands()
    _check(commands.size() == 2, "diagnostic commands still cover every visible cell")
    if commands.size() == 2:
        _check(commands[0].is_diagnostic(), "missing terrain is diagnostic")
        _check(commands[0].diagnostic_reason() == "terrain_missing", "missing terrain reason retained")
        _check(commands[1].is_diagnostic(), "unknown semantic terrain is diagnostic")
        _check(commands[1].selection != null and commands[1].selection.status == SelectionClass.Status.UNKNOWN, "unknown terrain uses typed UNKNOWN selection")
        _check(commands[1].diagnostic_reason() == "ground_unclassified", "ArtCatalog unknown reason retained")

func _test_redraw_invalidation() -> void:
    _redraw_events.clear()
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var renderer := RendererClass.new()
    renderer.redraw_requested.connect(_on_redraw_requested)

    _check(renderer.configure(world, CatalogClass.new()), "redraw renderer configures")
    _check(renderer.set_visible_window(Vector2i(10, 10), Vector2i(3, 3), 32.0), "redraw view configures")
    _redraw_events.clear()

    _check(not mutations.create_entity(&"object.test", "entity:test").is_empty(), "non-terrain entity mutation succeeds")
    _check(_redraw_events.is_empty(), "non-terrain WHAT changes do not redraw ground")

    _check(mutations.set_terrain(Vector2i(11, 11), &"ground.grass"), "visible terrain mutation succeeds")
    _check(_redraw_events.size() == 1 and _redraw_events[0] == &"terrain_changed", "visible terrain requests redraw")
    _redraw_events.clear()

    _check(mutations.set_terrain(Vector2i(9, 11), &"ground.road"), "left halo terrain mutation succeeds")
    _check(_redraw_events.size() == 1, "cardinal one-cell halo requests redraw")
    _redraw_events.clear()

    _check(mutations.set_terrain(Vector2i(9, 9), &"ground.road"), "diagonal outside terrain mutation succeeds")
    _check(_redraw_events.is_empty(), "diagonal outside cell does not cause unnecessary redraw")

    _check(mutations.set_terrain(Vector2i(30, 30), &"ground.grass"), "distant terrain mutation succeeds")
    _check(_redraw_events.is_empty(), "distant terrain does not redraw ground")

    var snapshot: Dictionary = world.snapshot()
    _check(world.load_snapshot(snapshot), "WHAT snapshot reload succeeds")
    _check(_redraw_events.size() == 1 and _redraw_events[0] == &"world_reset", "world reset redraws ground")
    _redraw_events.clear()

    _check(renderer.set_visible_window(Vector2i(11, 10), Vector2i(3, 3), 32.0), "view move succeeds")
    _check(_redraw_events.size() == 1 and _redraw_events[0] == &"view_changed", "view change requests redraw")

func _expect_cell_selection(renderer: GroundLayerRenderer, cell: Vector2i, source_id: StringName, index: int, message: String) -> void:
    var command: GroundDrawCommand = _command_for_cell(renderer.plan_visible_commands(), cell)
    _check(command != null, "%s command exists" % message)
    if command == null:
        return
    _expect_selection(command.selection, source_id, index, message)

func _command_for_cell(commands: Array[GroundDrawCommand], cell: Vector2i) -> GroundDrawCommand:
    for command: GroundDrawCommand in commands:
        if command.cell == cell:
            return command
    return null

func _expect_selection(selection: ArtSelection, source_id: StringName, index: int, message: String) -> void:
    _check(selection != null and selection.is_found(), "%s is found" % message)
    if selection == null or not selection.is_found():
        return
    _check(selection.source.source_id == source_id, "%s source" % message)
    _check(selection.atlas_index == index, "%s atlas index" % message)

func _on_redraw_requested(reason: StringName) -> void:
    _redraw_events.append(reason)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
