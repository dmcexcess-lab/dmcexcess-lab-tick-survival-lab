extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const CatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const VisualGeometry = preload("res://scripts/art/PropVisualGeometryCatalog.gd")
const PropOrientation = preload("res://scripts/art/PropArtOrientationCatalog.gd")
const RendererClass = preload("res://scripts/render/PropLayerRenderer.gd")
const StackClass = preload("res://scripts/render/TacticalRendererStack.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_descriptor_and_art_contract()
    _test_large_visual_planning_and_halo()
    _test_traffic_orientation_and_layering()
    _test_physical_glow_shader_contract()

    if _failures.is_empty():
        print("PROP_VISUAL_GEOMETRY_SMOKE_OK")
        quit(0)
        return

    for failure: String in _failures:
        push_error("PROP_VISUAL_GEOMETRY_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_descriptor_and_art_contract() -> void:
    var catalog := CatalogClass.new()
    var fallback: PropVisualGeometryDescriptor = VisualGeometry.descriptor_for(&"prop.chair")
    _check(fallback.is_valid(), "default descriptor is valid")
    _check(fallback.draw_span_cells == Vector2i.ONE, "default descriptor is exactly one cell")
    _check(fallback.pivot_cells == Vector2(0.5, 0.5), "default descriptor preserves historical centered pivot")
    _check(not fallback.has_foreground(), "default descriptor has no foreground pass")

    var tree: PropVisualGeometryDescriptor = VisualGeometry.descriptor_for(VisualGeometry.TREE_SEMANTIC)
    _check(tree.is_valid(), "large tree descriptor is valid")
    _check(tree.draw_span_cells == Vector2i(2, 2), "large tree is authored 2x2")
    _check(tree.has_foreground(), "large tree declares canopy foreground")

    var traffic: PropVisualGeometryDescriptor = VisualGeometry.descriptor_for(VisualGeometry.TRAFFIC_LIGHT_SEMANTIC)
    _check(traffic.is_valid(), "traffic-light descriptor is valid")
    _check(traffic.draw_span_cells == Vector2i(2, 2), "traffic light is authored 2x2")
    _check(traffic.has_foreground(), "traffic light declares signal-head foreground")
    _check(VisualGeometry.maximum_discovery_halo_cells() == 2, "visual discovery halo is explicitly bounded to two cells")

    for art_key: StringName in [
        tree.base_art_key,
        tree.foreground_art_key,
        traffic.base_art_key,
        traffic.foreground_art_key,
    ]:
        var selection: ArtSelection = VisualGeometry.resolve_art(catalog, art_key)
        _check(selection.is_found(), "dedicated large art resolves: %s" % art_key)
        if selection.is_found():
            _check(not selection.source.atlas, "large art is an explicit whole-texture source: %s" % art_key)
            _check(ResourceLoader.exists(selection.source.texture_path), "large art resource exists: %s" % art_key)

func _test_large_visual_planning_and_halo() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var renderer := RendererClass.new()
    _check(renderer.configure(world, CatalogClass.new()), "07B renderer configures")
    _check(renderer.set_visible_window(Vector2i.ZERO, Vector2i(6, 5), 32.0), "07B renderer view configures")

    _place_object(
        mutations,
        VisualGeometry.TREE_SEMANTIC,
        "entity:tree_multicell",
        Vector2i(2, 2),
        Facing.Value.NORTH,
        Footprint.rectangle(2, 2)
    )
    _place_object(
        mutations,
        VisualGeometry.TREE_SEMANTIC,
        "entity:tree_overhang",
        Vector2i(-1, 1),
        Facing.Value.NORTH,
        Footprint.single_cell()
    )
    _place_object(
        mutations,
        &"prop.chair",
        "entity:halo_but_culled",
        Vector2i(-2, 3),
        Facing.Value.NORTH,
        Footprint.single_cell()
    )
    _place_object(
        mutations,
        VisualGeometry.TREE_SEMANTIC,
        "entity:beyond_halo",
        Vector2i(-3, 1),
        Facing.Value.NORTH,
        Footprint.single_cell()
    )
    _place_object(
        mutations,
        &"fixture.bed_double",
        "entity:legacy_multicell",
        Vector2i(4, 3),
        Facing.Value.NORTH,
        Footprint.rectangle(2, 1)
    )

    var before_multicell_count: int = world.placement("entity:tree_multicell").footprint.cell_count()
    var before_overhang_count: int = world.placement("entity:tree_overhang").footprint.cell_count()

    var commands: Array[PropDrawCommand] = renderer.plan_visible_commands()
    var first_rebuilds: int = renderer.plan_rebuild_count()
    var commands_again: Array[PropDrawCommand] = renderer.plan_visible_commands()
    _check(renderer.plan_rebuild_count() == first_rebuilds, "base/foreground consumers can reuse one cached visual plan")
    _check(commands_again.size() == commands.size(), "cached visual plan is stable")

    var multicell: PropDrawCommand = _command_for_id(commands, "entity:tree_multicell")
    _check(multicell != null, "2x2 physical large tree is planned")
    if multicell != null:
        _check(multicell.world_cells.size() == 4, "four-cell WHAT footprint remains four physical cells")
        _check(multicell.draw_span_cells == Vector2i(2, 2), "four-cell tree still produces one 2x2 visual plan")
        _check(multicell.has_foreground(), "tree plan carries one foreground subpass")

    var overhang: PropDrawCommand = _command_for_id(commands, "entity:tree_overhang")
    _check(overhang != null, "offscreen one-cell trunk is discovered when canopy overlaps view")
    if overhang != null:
        _check(overhang.world_cells.size() == 1, "large visual overhang does not expand WHAT occupancy")
        _check(overhang.visual_rect_world.intersects(Rect2(Vector2.ZERO, Vector2(6, 5))), "halo-discovered visual actually intersects view")

    _check(_command_for_id(commands, "entity:halo_but_culled") == null, "halo-discovered default art is culled when visual AABB misses view")
    _check(_command_for_id(commands, "entity:beyond_halo") == null, "object beyond maximum halo is not discovered")

    var legacy: PropDrawCommand = _command_for_id(commands, "entity:legacy_multicell")
    _check(legacy != null and legacy.draw_span_cells == Vector2i.ONE, "unmapped legacy multicell object keeps one-cell visual")

    _check(world.placement("entity:tree_multicell").footprint.cell_count() == before_multicell_count, "planning does not mutate four-cell WHAT footprint")
    _check(world.placement("entity:tree_overhang").footprint.cell_count() == before_overhang_count, "planning does not mutate one-cell WHAT footprint")

func _test_traffic_orientation_and_layering() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var renderer := RendererClass.new()
    _check(renderer.configure(world, CatalogClass.new()), "traffic renderer configures")
    _check(renderer.set_visible_window(Vector2i.ZERO, Vector2i(6, 6), 32.0), "traffic view configures")
    _place_object(
        mutations,
        VisualGeometry.TRAFFIC_LIGHT_SEMANTIC,
        "entity:traffic",
        Vector2i(2, 2),
        Facing.Value.EAST,
        Footprint.single_cell()
    )

    var command: PropDrawCommand = _command_for_id(renderer.plan_visible_commands(), "entity:traffic")
    _check(command != null, "large traffic light is planned")
    if command != null:
        _check(command.pivot_screen == Vector2(80, 80), "authored pivot attaches to authoritative anchor-cell center")
        _check(command.has_foreground(), "traffic signal head uses foreground pass")
        var expected_turns: int = PropOrientation.quarter_turns(command.selection, Facing.Value.EAST)
        _check(command.quarter_turns == expected_turns, "traffic orientation is supplied by System 07A")
        _check(command.facing == Facing.Value.EAST, "WHAT facing remains unchanged")
        _check(command.world_cells.size() == 1, "large traffic visual does not expand physical occupancy")

    var stack := StackClass.new()
    var layering: Dictionary = stack.prop_visual_geometry_debug_snapshot()
    _check(int(layering["base_z"]) == 20, "base prop pass remains z20")
    _check(int(layering["actor_z"]) == 30, "actors remain z30")
    _check(int(layering["foreground_z"]) == 35, "large-object foreground pass is z35")
    _check(int(layering["lighting_z"]) == 40, "physical lighting remains above foreground at z40")

func _test_physical_glow_shader_contract() -> void:
    var shader_path: String = "res://shaders/physical_lighting_glow.gdshader"
    _check(FileAccess.file_exists(shader_path), "physical-lighting glow shader exists")
    var shader_source: String = FileAccess.get_file_as_string(shader_path)
    _check(shader_source.contains("outer_glow_strength"), "glow shader includes bounded outer bloom ring")
    _check(shader_source.contains("n2") and shader_source.contains("e2"), "glow shader samples a second emitter-derived halo ring")
    _check(not shader_source.contains("TIME"), "glow polish adds no continuous animation clock")
    _check(shader_source.contains("TEXTURE_PIXEL_SIZE"), "glow remains derived from physical-lighting presentation texture")

func _place_object(
    mutations: WorldMutationService,
    semantic_type: StringName,
    entity_id: String,
    anchor: Vector2i,
    facing: int,
    footprint: SpatialFootprint
) -> void:
    _check(not mutations.create_entity(semantic_type, entity_id).is_empty(), "create %s" % entity_id)
    _check(
        mutations.set_placement(entity_id, Layers.Channel.OBJECT, anchor, facing, footprint),
        "place %s" % entity_id
    )

func _command_for_id(commands: Array[PropDrawCommand], entity_id: String) -> PropDrawCommand:
    for command: PropDrawCommand in commands:
        if command.entity_id == entity_id:
            return command
    return null

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
