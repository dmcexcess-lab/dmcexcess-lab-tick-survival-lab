extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const CatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const VisualGeometry = preload("res://scripts/art/PropVisualGeometryCatalog.gd")
const RendererClass = preload("res://scripts/render/PropLayerRenderer.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")

var _failures: Array[String] = []
var _redraw_events: Array[StringName] = []

func _initialize() -> void:
    _test_families_and_recovered_art()
    _test_multicell_dedup_order_and_geometry()
    _test_diagnostics_and_channel_filtering()
    _test_redraw_invalidation()

    if _failures.is_empty():
        print("PROP_LAYER_RENDERER_SMOKE_OK")
        quit(0)
        return

    for failure: String in _failures:
        push_error("PROP_LAYER_RENDERER_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_families_and_recovered_art() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var catalog := CatalogClass.new()
    var renderer := RendererClass.new()

    _check(not renderer.configure(null, catalog), "null WHAT dependency rejected")
    _check(renderer.configure(world, catalog), "renderer configures with WHAT + ArtCatalog")
    _check(not renderer.set_visible_window(Vector2i.ZERO, Vector2i(0, 2), 24.0), "zero-width view rejected")
    _check(not renderer.set_visible_window(Vector2i.ZERO, Vector2i(2, 2), 0.0), "zero cell size rejected")
    _check(renderer.set_visible_window(Vector2i(-2, -1), Vector2i(8, 3), 24.0), "negative-origin view accepted")

    _place_object(mutations, &"vegetation.deciduous_large", "entity:veg", Vector2i(-1, -1), Facing.Value.EAST)
    _place_object(mutations, &"prop.chair", "entity:alias", Vector2i(0, -1), Facing.Value.NORTH)
    _place_object(mutations, &"fixture.stove", "entity:building", Vector2i(1, -1), Facing.Value.SOUTH)
    _place_object(mutations, &"prop.lamp", "entity:clutter", Vector2i(2, -1), Facing.Value.WEST)
    _place_object(mutations, &"prop.dumpster", "entity:tactical", Vector2i(3, -1), Facing.Value.NORTH)
    _place_object(mutations, &"prop.barrel", "entity:barrel", Vector2i(4, -1), Facing.Value.EAST)

    var commands: Array[PropDrawCommand] = renderer.plan_visible_commands()
    _check(commands.size() == 6, "six visible OBJECT entities produce six commands")
    if commands.size() != 6:
        return

    _check(commands[0].entity_id == "entity:veg", "commands sort by anchor row then column")
    _check(commands[0].family == PropDrawCommand.FAMILY_VEGETATION, "vegetation family retained")
    _check(commands[0].destination == Rect2(12, -24, 48, 48), "large vegetation uses authored 2x2 destination")
    _check(commands[0].draw_span_cells == Vector2i(2, 2), "large vegetation span retained")
    _check(commands[0].has_foreground(), "large vegetation exposes canopy foreground")
    _check(commands[0].facing == Facing.Value.EAST, "WHAT facing retained in command")
    _check(commands[0].footprint != null and commands[0].footprint.cell_count() == 1, "visual size does not change WHAT footprint")
    _expect_selection(commands[0].selection, VisualGeometry.SOURCE_TREE_BASE, -1, "dedicated large vegetation art")

    _check(commands[1].family == PropDrawCommand.FAMILY_PROP, "prop family retained")
    _expect_selection(commands[1].selection, CatalogClass.SOURCE_FINAL_PROPS, 75, "final alias prop art")

    _check(commands[2].family == PropDrawCommand.FAMILY_FIXTURE, "fixture family retained")
    _expect_selection(commands[2].selection, CatalogClass.SOURCE_BUILDING, 0, "building fixture art")

    _expect_selection(commands[3].selection, CatalogClass.SOURCE_CLUTTER, 7, "clutter prop art")
    _expect_selection(commands[4].selection, CatalogClass.SOURCE_TACTICAL, 32, "tactical prop art")
    _expect_selection(commands[5].selection, CatalogClass.SOURCE_TACTICAL, 26, "recovered barrel special art")

    for command: PropDrawCommand in commands:
        if command.selection != null and command.selection.is_found():
            _check(ResourceLoader.exists(command.selection.source.texture_path), "found prop texture path exists")
            var loaded: Resource = ResourceLoader.load(command.selection.source.texture_path)
            _check(loaded is Texture2D, "found prop texture loads as Texture2D")

func _test_multicell_dedup_order_and_geometry() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var renderer := RendererClass.new()
    _check(renderer.configure(world, CatalogClass.new()), "multicell renderer configures")
    _check(renderer.set_visible_window(Vector2i.ZERO, Vector2i(4, 3), 20.0), "multicell view configures")

    _place_object(
        mutations,
        &"fixture.bed_double",
        "entity:multi",
        Vector2i(0, 0),
        Facing.Value.NORTH,
        Footprint.rectangle(2, 1)
    )
    _place_object(mutations, &"prop.crate", "entity:zeta", Vector2i(1, 1), Facing.Value.NORTH)
    _place_object(mutations, &"prop.pallet", "entity:alpha", Vector2i(1, 1), Facing.Value.SOUTH)

    var commands: Array[PropDrawCommand] = renderer.plan_visible_commands()
    _check(commands.size() == 3, "multicell occupancy deduplicates to one command plus overlapping entities")
    if commands.size() == 3:
        _check(commands[0].entity_id == "entity:multi", "multicell command sorts from its anchor")
        _check(commands[0].world_cells.size() == 2, "rotated occupied cells retained without duplicate draws")
        _check(commands[0].destination == Rect2(0, 0, 20, 20), "unmapped multicell art preserves historical one-cell visual")
        _check(commands[0].draw_span_cells == Vector2i.ONE, "legacy multicell object uses default visual descriptor")
        _check(commands[1].entity_id == "entity:alpha", "same-anchor overlap sorts by stable ID first")
        _check(commands[2].entity_id == "entity:zeta", "same-anchor overlap sorts by stable ID second")
        _check(not commands[1].is_diagnostic() and not commands[2].is_diagnostic(), "overlapping OBJECTs remain separate valid draws")

    var outside_world := WorldStateClass.new()
    var outside_mutations := WorldMutationClass.new(outside_world)
    var outside_renderer := RendererClass.new()
    _check(outside_renderer.configure(outside_world, CatalogClass.new()), "outside-anchor renderer configures")
    _check(outside_renderer.set_visible_window(Vector2i.ZERO, Vector2i(2, 2), 24.0), "outside-anchor view configures")
    _place_object(
        outside_mutations,
        &"fixture.bed_double",
        "entity:outside",
        Vector2i(2, 0),
        Facing.Value.SOUTH,
        Footprint.rectangle(2, 1)
    )
    var outside_commands: Array[PropDrawCommand] = outside_renderer.plan_visible_commands()
    _check(outside_commands.is_empty(), "offscreen default visual is culled even when physical footprint touches view")

func _test_diagnostics_and_channel_filtering() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var renderer := RendererClass.new()
    _check(renderer.configure(world, CatalogClass.new()), "diagnostic renderer configures")
    _check(renderer.set_visible_window(Vector2i.ZERO, Vector2i(4, 2), 32.0), "diagnostic view configures")

    _place_object(mutations, &"object.crate", "entity:bad_family", Vector2i(0, 0), Facing.Value.NORTH)
    _place_object(mutations, &"prop.not_real", "entity:bad_kind", Vector2i(1, 0), Facing.Value.NORTH)

    var actor_id: String = mutations.create_entity(&"prop.chair", "entity:actor_channel")
    _check(not actor_id.is_empty(), "non-object semantic entity created")
    _check(mutations.set_placement(actor_id, Layers.Channel.ACTOR, Vector2i(2, 0), Facing.Value.NORTH, Footprint.single_cell()), "non-object channel placement succeeds")
    _check(not mutations.create_entity(&"prop.chair", "entity:unplaced").is_empty(), "unplaced prop entity can persist")

    var commands: Array[PropDrawCommand] = renderer.plan_visible_commands()
    _check(commands.size() == 2, "renderer filters ACTOR channel and unplaced entities")
    var bad_family: PropDrawCommand = _command_for_id(commands, "entity:bad_family")
    var bad_kind: PropDrawCommand = _command_for_id(commands, "entity:bad_kind")
    _check(bad_family != null and bad_family.is_diagnostic(), "unknown semantic family is diagnostic")
    if bad_family != null:
        _check(bad_family.diagnostic_reason() == "prop_semantic_unclassified", "unknown family reason retained")
    _check(bad_kind != null and bad_kind.is_diagnostic(), "unknown Art Catalog prop kind is diagnostic")
    if bad_kind != null:
        _check(bad_kind.diagnostic_reason() == "prop_unclassified", "Art Catalog unknown reason retained")

func _test_redraw_invalidation() -> void:
    _redraw_events.clear()
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var renderer := RendererClass.new()
    renderer.redraw_requested.connect(_on_redraw_requested)

    _check(renderer.configure(world, CatalogClass.new()), "redraw renderer configures")
    _check(renderer.set_visible_window(Vector2i(10, 10), Vector2i(3, 3), 32.0), "redraw view configures")
    _redraw_events.clear()

    _check(not mutations.create_entity(&"prop.chair", "entity:redraw_object").is_empty(), "unplaced visible-semantic object created")
    _check(_redraw_events.is_empty(), "entity creation without placement does not redraw props")

    _check(mutations.set_terrain(Vector2i(11, 11), &"ground.grass"), "visible terrain mutation succeeds")
    _check(_redraw_events.is_empty(), "terrain mutation does not redraw props")

    var actor_id: String = mutations.create_entity(&"actor.test", "entity:redraw_actor")
    _check(not actor_id.is_empty(), "actor entity created")
    _check(mutations.set_placement(actor_id, Layers.Channel.ACTOR, Vector2i(11, 11), Facing.Value.NORTH, Footprint.single_cell()), "visible ACTOR placement succeeds")
    _check(_redraw_events.is_empty(), "initial non-OBJECT placement does not redraw props")

    _check(mutations.set_placement("entity:redraw_object", Layers.Channel.OBJECT, Vector2i(11, 11), Facing.Value.NORTH, Footprint.single_cell()), "visible OBJECT placement succeeds")
    _check(_redraw_events.size() == 1 and _redraw_events[0] == &"object_placement_changed", "visible OBJECT placement requests redraw")
    _redraw_events.clear()

    _check(mutations.set_placement("entity:redraw_object", Layers.Channel.OBJECT, Vector2i(30, 30), Facing.Value.NORTH, Footprint.single_cell()), "OBJECT moves out of view")
    _check(_redraw_events.size() == 1, "moving OBJECT out of discovery window redraws old location")
    _redraw_events.clear()

    _check(mutations.set_placement("entity:redraw_object", Layers.Channel.OBJECT, Vector2i(31, 30), Facing.Value.NORTH, Footprint.single_cell()), "distant OBJECT moves distantly")
    _check(_redraw_events.is_empty(), "distant OBJECT move does not redraw visible props")

    _check(mutations.set_placement("entity:redraw_object", Layers.Channel.OBJECT, Vector2i(12, 12), Facing.Value.NORTH, Footprint.single_cell()), "OBJECT moves into view")
    _check(_redraw_events.size() == 1, "moving OBJECT into view redraws")
    _redraw_events.clear()

    _check(mutations.unplace_entity("entity:redraw_object"), "visible OBJECT unplaces")
    _check(_redraw_events.size() == 1 and _redraw_events[0] == &"object_placement_changed", "visible OBJECT removal redraws")
    _redraw_events.clear()

    var snapshot: Dictionary = world.snapshot()
    _check(world.load_snapshot(snapshot), "WHAT snapshot reload succeeds")
    _check(_redraw_events.size() == 1 and _redraw_events[0] == &"world_reset", "world reset redraws props")

func _place_object(
    mutations: WorldMutationService,
    semantic_type: StringName,
    entity_id: String,
    anchor: Vector2i,
    facing: int,
    footprint: SpatialFootprint = null
) -> void:
    var actual_footprint: SpatialFootprint = footprint
    if actual_footprint == null:
        actual_footprint = Footprint.single_cell()
    _check(not mutations.create_entity(semantic_type, entity_id).is_empty(), "create %s" % entity_id)
    _check(
        mutations.set_placement(entity_id, Layers.Channel.OBJECT, anchor, facing, actual_footprint),
        "place %s" % entity_id
    )

func _expect_selection(selection: ArtSelection, source_id: StringName, index: int, message: String) -> void:
    _check(selection != null and selection.is_found(), "%s is found" % message)
    if selection == null or not selection.is_found():
        return
    _check(selection.source.source_id == source_id, "%s source" % message)
    _check(selection.atlas_index == index, "%s atlas index" % message)

func _command_for_id(commands: Array[PropDrawCommand], entity_id: String) -> PropDrawCommand:
    for command: PropDrawCommand in commands:
        if command.entity_id == entity_id:
            return command
    return null

func _on_redraw_requested(reason: StringName) -> void:
    _redraw_events.append(reason)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
