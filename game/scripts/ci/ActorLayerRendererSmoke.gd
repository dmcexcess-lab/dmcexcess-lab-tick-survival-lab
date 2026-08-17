extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const CatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const RendererClass = preload("res://scripts/render/ActorLayerRenderer.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")

var _failures: Array[String] = []
var _redraw_events: Array[StringName] = []

func _initialize() -> void:
    _test_controlled_player_facings()
    _test_npc_survivor_and_infected_recovery()
    _test_stable_variant_default()
    _test_multicell_overlap_and_geometry()
    _test_diagnostics_and_channel_filtering()
    _test_redraw_invalidation()

    if _failures.is_empty():
        print("ACTOR_LAYER_RENDERER_SMOKE_OK")
        quit(0)
        return

    for failure: String in _failures:
        push_error("ACTOR_LAYER_RENDERER_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_controlled_player_facings() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var catalog := CatalogClass.new()
    var renderer := RendererClass.new()

    _check(not renderer.configure(null, catalog), "null WHAT dependency rejected")
    _check(renderer.configure(world, catalog), "renderer configures with WHAT + ArtCatalog")
    _check(not renderer.set_visible_window(Vector2i.ZERO, Vector2i(0, 2), 32.0), "zero-width view rejected")
    _check(not renderer.set_visible_window(Vector2i.ZERO, Vector2i(2, 2), 0.0), "zero cell size rejected")
    _check(renderer.set_visible_window(Vector2i.ZERO, Vector2i(3, 2), 32.0), "controlled view configures")
    _check(not renderer.set_controlled_actor_id("   "), "whitespace-only controlled ID rejected")

    _place_actor(mutations, &"actor.survivor", "entity:controlled", Vector2i(1, 0), Facing.Value.NORTH)
    _check(renderer.set_controlled_actor_id("entity:controlled"), "controlled actor role accepts stable ID")

    var cases: Array = [
        [Facing.Value.NORTH, "res://assets/player_north.svg"],
        [Facing.Value.EAST, "res://assets/player_east.svg"],
        [Facing.Value.SOUTH, "res://assets/player_south.svg"],
        [Facing.Value.WEST, "res://assets/player_west.svg"],
    ]
    for value: Variant in cases:
        var entry: Array = value
        var facing: int = int(entry[0])
        var expected_path: String = String(entry[1])
        _check(
            mutations.set_placement("entity:controlled", Layers.Channel.ACTOR, Vector2i(1, 0), facing, Footprint.single_cell()),
            "controlled facing placement updates"
        )
        var commands: Array[ActorDrawCommand] = renderer.plan_visible_commands()
        _check(commands.size() == 1, "controlled survivor produces one command")
        if commands.size() != 1:
            continue
        var command: ActorDrawCommand = commands[0]
        _check(command.controlled, "controlled role retained in command")
        _check(command.family == ActorDrawCommand.FAMILY_SURVIVOR, "controlled actor remains survivor family")
        _check(command.variant == -1, "controlled actor uses dedicated player art rather than NPC variant")
        _check(command.destination == Rect2(32, 0, 32, 32), "controlled player uses full-cell destination")
        _check(command.selection != null and command.selection.is_found(), "controlled player art found")
        if command.selection != null and command.selection.is_found():
            _check(not command.selection.source.atlas, "controlled player uses full directional texture")
            _check(command.selection.source.texture_path == expected_path, "controlled facing uses exact protected player texture")

func _test_npc_survivor_and_infected_recovery() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var renderer := RendererClass.new()
    _check(renderer.configure(world, CatalogClass.new()), "NPC renderer configures")
    _check(renderer.set_visible_window(Vector2i(-2, -2), Vector2i(6, 4), 32.0), "negative-origin NPC view accepted")

    _place_actor(mutations, &"actor.survivor", "entity:survivor_a", Vector2i(-1, -1), Facing.Value.EAST)
    _place_actor(mutations, &"actor.infected", "zombie:2", Vector2i(0, -1), Facing.Value.SOUTH)

    var commands: Array[ActorDrawCommand] = renderer.plan_visible_commands()
    _check(commands.size() == 2, "survivor and infected produce two living actor commands")
    var survivor: ActorDrawCommand = _command_for_id(commands, "entity:survivor_a")
    var infected: ActorDrawCommand = _command_for_id(commands, "zombie:2")

    _check(survivor != null and not survivor.controlled, "NPC survivor is not controlled")
    if survivor != null:
        _check(survivor.family == ActorDrawCommand.FAMILY_SURVIVOR, "NPC survivor family retained")
        _check(survivor.variant == 2, "stable survivor ID maps to expected deterministic variant")
        _expect_selection(survivor.selection, CatalogClass.SOURCE_ACTORS, 2 * 4 + 1, "NPC survivor east art")
        _check(survivor.destination == Rect2(33.5, 33.5, 29, 29), "NPC survivor uses recovered 29/32 centered scale at negative global coordinates")
        _check(survivor.facing == Facing.Value.EAST, "NPC survivor WHAT facing retained")
        _check(survivor.footprint != null and survivor.footprint.cell_count() == 1, "NPC survivor footprint retained")

    _check(infected != null and not infected.controlled, "infected is not controlled")
    if infected != null:
        _check(infected.family == ActorDrawCommand.FAMILY_INFECTED, "infected family retained")
        _check(infected.variant == 7, "stable infected ID maps to expected deterministic variant")
        _expect_selection(infected.selection, CatalogClass.SOURCE_ACTORS, 32 + 7 * 4 + 2, "infected south art")

    for command: ActorDrawCommand in commands:
        if command.selection != null and command.selection.is_found():
            _check(ResourceLoader.exists(command.selection.source.texture_path), "living actor texture path exists")
            var loaded: Resource = ResourceLoader.load(command.selection.source.texture_path)
            _check(loaded is Texture2D, "living actor texture loads as Texture2D")

func _test_stable_variant_default() -> void:
    var world_a := WorldStateClass.new()
    var mutations_a := WorldMutationClass.new(world_a)
    var renderer_a := RendererClass.new()
    _check(renderer_a.configure(world_a, CatalogClass.new()), "stable variant renderer A configures")
    _check(renderer_a.set_visible_window(Vector2i.ZERO, Vector2i(4, 2), 32.0), "stable variant view A configures")
    _place_actor(mutations_a, &"actor.survivor", "entity:survivor_a", Vector2i(0, 0), Facing.Value.NORTH)
    _place_actor(mutations_a, &"actor.survivor", "entity:survivor_b", Vector2i(1, 0), Facing.Value.NORTH)
    var commands_a: Array[ActorDrawCommand] = renderer_a.plan_visible_commands()
    var a1: ActorDrawCommand = _command_for_id(commands_a, "entity:survivor_a")
    var b1: ActorDrawCommand = _command_for_id(commands_a, "entity:survivor_b")
    _check(a1 != null and b1 != null, "stable variant actors found in first world")
    if a1 != null and b1 != null:
        _check(a1.variant == 2, "known stable ID A deterministic variant")
        _check(b1.variant == 7, "known stable ID B deterministic variant")
        _check(a1.variant != b1.variant, "different stable IDs can select different recovered variants")

    var world_b := WorldStateClass.new()
    var mutations_b := WorldMutationClass.new(world_b)
    var renderer_b := RendererClass.new()
    _check(renderer_b.configure(world_b, CatalogClass.new()), "stable variant renderer B configures")
    _check(renderer_b.set_visible_window(Vector2i.ZERO, Vector2i(2, 2), 32.0), "stable variant view B configures")
    _place_actor(mutations_b, &"actor.survivor", "entity:survivor_a", Vector2i(0, 0), Facing.Value.NORTH)
    var commands_b: Array[ActorDrawCommand] = renderer_b.plan_visible_commands()
    var a2: ActorDrawCommand = _command_for_id(commands_b, "entity:survivor_a")
    _check(a1 != null and a2 != null and a1.variant == a2.variant, "same stable ID keeps default variant across independent renderer/world instances")

func _test_multicell_overlap_and_geometry() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var renderer := RendererClass.new()
    _check(renderer.configure(world, CatalogClass.new()), "multicell actor renderer configures")
    _check(renderer.set_visible_window(Vector2i.ZERO, Vector2i(4, 3), 20.0), "multicell actor view configures")

    _place_actor(
        mutations,
        &"actor.survivor",
        "actor:multi",
        Vector2i(0, 0),
        Facing.Value.NORTH,
        Footprint.rectangle(2, 1)
    )
    _place_actor(mutations, &"actor.infected", "actor:zeta", Vector2i(1, 1), Facing.Value.NORTH)
    _place_actor(mutations, &"actor.survivor", "actor:alpha", Vector2i(1, 1), Facing.Value.SOUTH)

    var commands: Array[ActorDrawCommand] = renderer.plan_visible_commands()
    _check(commands.size() == 3, "multicell actor occupancy deduplicates and overlap remains separate")
    if commands.size() == 3:
        _check(commands[0].actor_id == "actor:multi", "multicell actor sorts from anchor")
        _check(commands[0].world_cells.size() == 2, "multicell actor retains occupied world cells")
        _check(commands[0].footprint != null and commands[0].footprint.cell_count() == 2, "multicell actor retains physical footprint")
        _check(commands[1].actor_id == "actor:alpha", "same-anchor living actors sort by stable ID first")
        _check(commands[2].actor_id == "actor:zeta", "same-anchor living actors sort by stable ID second")
        _check(not commands[1].is_diagnostic() and not commands[2].is_diagnostic(), "overlapping ACTORs are not renderer-owned collision diagnostics")

    var outside_world := WorldStateClass.new()
    var outside_mutations := WorldMutationClass.new(outside_world)
    var outside_renderer := RendererClass.new()
    _check(outside_renderer.configure(outside_world, CatalogClass.new()), "outside-anchor actor renderer configures")
    _check(outside_renderer.set_visible_window(Vector2i.ZERO, Vector2i(2, 2), 24.0), "outside-anchor actor view configures")
    _place_actor(
        outside_mutations,
        &"actor.infected",
        "actor:outside",
        Vector2i(2, 0),
        Facing.Value.SOUTH,
        Footprint.rectangle(2, 1)
    )
    var outside_commands: Array[ActorDrawCommand] = outside_renderer.plan_visible_commands()
    _check(outside_commands.size() == 1, "actor footprint intersection matters even when anchor is outside view")
    if outside_commands.size() == 1:
        _check(Vector2i(1, 0) in outside_commands[0].world_cells, "rotated actor footprint intersection retained")
        _check(outside_commands[0].facing == Facing.Value.SOUTH, "outside-anchor actor facing retained")
        _check(outside_commands[0].destination.position.x > 48.0, "outside anchor keeps true off-window centered destination instead of clamping")

func _test_diagnostics_and_channel_filtering() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var renderer := RendererClass.new()
    _check(renderer.configure(world, CatalogClass.new()), "diagnostic actor renderer configures")
    _check(renderer.set_visible_window(Vector2i.ZERO, Vector2i(5, 2), 32.0), "diagnostic actor view configures")

    _place_actor(mutations, &"actor.animal", "actor:unknown", Vector2i(0, 0), Facing.Value.NORTH)

    var object_id: String = mutations.create_entity(&"actor.survivor", "actor:on_object_channel")
    _check(not object_id.is_empty(), "actor semantic entity for OBJECT channel created")
    _check(mutations.set_placement(object_id, Layers.Channel.OBJECT, Vector2i(1, 0), Facing.Value.NORTH, Footprint.single_cell()), "actor semantic can exist on non-ACTOR channel at WHAT layer")

    var prop_actor_id: String = mutations.create_entity(&"prop.chair", "prop:on_actor_channel")
    _check(not prop_actor_id.is_empty(), "prop semantic for ACTOR channel created")
    _check(mutations.set_placement(prop_actor_id, Layers.Channel.ACTOR, Vector2i(2, 0), Facing.Value.NORTH, Footprint.single_cell()), "unknown actor semantic can occupy ACTOR channel at WHAT layer")
    _check(not mutations.create_entity(&"actor.survivor", "actor:unplaced").is_empty(), "unplaced survivor can persist")

    _place_actor(mutations, &"actor.infected", "actor:controlled_infected", Vector2i(3, 0), Facing.Value.NORTH)
    _check(renderer.set_controlled_actor_id("actor:controlled_infected"), "controlled role can be set before semantic validation")

    var commands: Array[ActorDrawCommand] = renderer.plan_visible_commands()
    _check(commands.size() == 3, "renderer filters OBJECT channel and unplaced actor while retaining ACTOR diagnostics")
    var unknown: ActorDrawCommand = _command_for_id(commands, "actor:unknown")
    var prop_on_actor: ActorDrawCommand = _command_for_id(commands, "prop:on_actor_channel")
    var controlled_infected: ActorDrawCommand = _command_for_id(commands, "actor:controlled_infected")
    _check(unknown != null and unknown.is_diagnostic(), "unknown actor family is diagnostic")
    if unknown != null:
        _check(unknown.diagnostic_reason() == "actor_semantic_unclassified", "unknown actor family reason retained")
    _check(prop_on_actor != null and prop_on_actor.is_diagnostic(), "non-actor semantic on ACTOR channel is diagnostic")
    _check(controlled_infected != null and controlled_infected.is_diagnostic(), "controlled infected is rejected rather than shown as player survivor")
    if controlled_infected != null:
        _check(controlled_infected.diagnostic_reason() == "controlled_actor_not_survivor", "controlled infected diagnostic reason retained")

func _test_redraw_invalidation() -> void:
    _redraw_events.clear()
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var renderer := RendererClass.new()
    renderer.redraw_requested.connect(_on_redraw_requested)

    _check(renderer.configure(world, CatalogClass.new()), "redraw actor renderer configures")
    _check(renderer.set_visible_window(Vector2i(10, 10), Vector2i(3, 3), 32.0), "redraw actor view configures")
    _redraw_events.clear()

    _check(renderer.set_controlled_actor_id("actor:not_placed"), "controlled role change accepted")
    _check(_redraw_events.size() == 1 and _redraw_events[0] == &"controlled_actor_changed", "controlled actor role change redraws")
    _redraw_events.clear()
    _check(renderer.set_controlled_actor_id("actor:not_placed"), "same controlled role accepted")
    _check(_redraw_events.is_empty(), "same controlled role does not redraw")

    _check(mutations.set_terrain(Vector2i(11, 11), &"ground.grass"), "visible terrain mutation succeeds")
    _check(_redraw_events.is_empty(), "terrain mutation does not redraw actors")

    var object_id: String = mutations.create_entity(&"actor.survivor", "actor:wrong_channel")
    _check(not object_id.is_empty(), "actor-semantic wrong-channel entity created")
    _check(mutations.set_placement(object_id, Layers.Channel.OBJECT, Vector2i(11, 11), Facing.Value.NORTH, Footprint.single_cell()), "visible OBJECT placement succeeds")
    _check(_redraw_events.is_empty(), "OBJECT channel does not redraw actors even when semantic text says actor")

    var actor_id: String = mutations.create_entity(&"actor.survivor", "actor:redraw")
    _check(not actor_id.is_empty(), "redraw actor entity created")
    _check(_redraw_events.is_empty(), "actor entity creation without placement does not redraw")
    _check(mutations.set_placement(actor_id, Layers.Channel.ACTOR, Vector2i(11, 11), Facing.Value.NORTH, Footprint.single_cell()), "visible ACTOR placement succeeds")
    _check(_redraw_events.size() == 1 and _redraw_events[0] == &"actor_placement_changed", "visible ACTOR placement redraws")
    _redraw_events.clear()

    _check(mutations.set_placement(actor_id, Layers.Channel.ACTOR, Vector2i(30, 30), Facing.Value.NORTH, Footprint.single_cell()), "actor moves out of view")
    _check(_redraw_events.size() == 1, "moving actor out of view redraws old visible location")
    _redraw_events.clear()

    _check(mutations.set_placement(actor_id, Layers.Channel.ACTOR, Vector2i(31, 30), Facing.Value.NORTH, Footprint.single_cell()), "distant actor moves distantly")
    _check(_redraw_events.is_empty(), "distant actor movement does not redraw visible actor layer")

    _check(mutations.set_placement(actor_id, Layers.Channel.ACTOR, Vector2i(12, 12), Facing.Value.EAST, Footprint.single_cell()), "actor moves into view")
    _check(_redraw_events.size() == 1, "moving actor into view redraws")
    _redraw_events.clear()

    _check(mutations.remove_entity(actor_id), "visible actor removal succeeds")
    _check(_redraw_events.size() == 1 and _redraw_events[0] == &"actor_removed", "visible actor entity removal redraws")
    _redraw_events.clear()

    var snapshot: Dictionary = world.snapshot()
    _check(world.load_snapshot(snapshot), "WHAT snapshot reload succeeds")
    _check(_redraw_events.size() == 1 and _redraw_events[0] == &"world_reset", "world reset redraws actors")

func _place_actor(
    mutations: WorldMutationService,
    semantic_type: StringName,
    actor_id: String,
    anchor: Vector2i,
    facing: int,
    footprint: SpatialFootprint = null
) -> void:
    var actual_footprint: SpatialFootprint = footprint
    if actual_footprint == null:
        actual_footprint = Footprint.single_cell()
    _check(not mutations.create_entity(semantic_type, actor_id).is_empty(), "create %s" % actor_id)
    _check(
        mutations.set_placement(actor_id, Layers.Channel.ACTOR, anchor, facing, actual_footprint),
        "place %s" % actor_id
    )

func _expect_selection(selection: ArtSelection, source_id: StringName, index: int, message: String) -> void:
    _check(selection != null and selection.is_found(), "%s is found" % message)
    if selection == null or not selection.is_found():
        return
    _check(selection.source.source_id == source_id, "%s source" % message)
    _check(selection.atlas_index == index, "%s atlas index" % message)

func _command_for_id(commands: Array[ActorDrawCommand], actor_id: String) -> ActorDrawCommand:
    for command: ActorDrawCommand in commands:
        if command.actor_id == actor_id:
            return command
    return null

func _on_redraw_requested(reason: StringName) -> void:
    _redraw_events.append(reason)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
