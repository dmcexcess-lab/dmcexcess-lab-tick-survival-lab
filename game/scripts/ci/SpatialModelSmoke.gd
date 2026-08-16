extends SceneTree

const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Space = preload("res://scripts/foundation/spatial/SpatialModel.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _test_facing()
    _test_relative_rotation()
    _test_footprints()
    _test_global_geometry()
    _test_structure_axes()
    _test_layers_and_scale()

    if failures.is_empty():
        print("SPATIAL_MODEL_SMOKE_OK")
        quit(0)
        return

    for failure: String in failures:
        push_error("SPATIAL_MODEL_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_facing() -> void:
    _expect(FacingRules.vector(FacingRules.Value.NORTH) == Vector2i(0, -1), "north vector")
    _expect(FacingRules.vector(FacingRules.Value.EAST) == Vector2i(1, 0), "east vector")
    _expect(FacingRules.vector(FacingRules.Value.SOUTH) == Vector2i(0, 1), "south vector")
    _expect(FacingRules.vector(FacingRules.Value.WEST) == Vector2i(-1, 0), "west vector")
    _expect(FacingRules.turn_right(FacingRules.Value.NORTH) == FacingRules.Value.EAST, "right turn")
    _expect(FacingRules.turn_left(FacingRules.Value.NORTH) == FacingRules.Value.WEST, "left turn")
    _expect(FacingRules.opposite(FacingRules.Value.EAST) == FacingRules.Value.WEST, "opposite facing")
    _expect(FacingRules.from_vector(Vector2i(0, 1)) == FacingRules.Value.SOUTH, "vector to facing")
    _expect(not FacingRules.is_valid(99), "invalid facing rejected")

func _test_relative_rotation() -> void:
    var forward_offset := Vector2i(0, -1)
    _expect(FacingRules.rotate_offset_from_north(forward_offset, FacingRules.Value.NORTH) == Vector2i(0, -1), "north rotation")
    _expect(FacingRules.rotate_offset_from_north(forward_offset, FacingRules.Value.EAST) == Vector2i(1, 0), "east rotation")
    _expect(FacingRules.rotate_offset_from_north(forward_offset, FacingRules.Value.SOUTH) == Vector2i(0, 1), "south rotation")
    _expect(FacingRules.rotate_offset_from_north(forward_offset, FacingRules.Value.WEST) == Vector2i(-1, 0), "west rotation")

func _test_footprints() -> void:
    var single = Footprint.single_cell()
    _expect(single.cell_count() == 1, "single-cell footprint count")
    _expect(single.world_cells(Vector2i(-8, 12), FacingRules.Value.SOUTH) == [Vector2i(-8, 12)], "single-cell negative-coordinate placement")

    var rectangle = Footprint.rectangle(2, 3)
    _expect(rectangle.cell_count() == 6, "rectangle footprint count")

    var directional = Footprint.new([
        Vector2i.ZERO,
        Vector2i(0, -1),
        Vector2i(0, -1),
    ])
    _expect(directional.cell_count() == 2, "duplicate offsets removed")
    var east_cells: Array[Vector2i] = directional.world_cells(Vector2i(10, 10), FacingRules.Value.EAST)
    _expect(east_cells == [Vector2i(10, 10), Vector2i(11, 10)], "rotated footprint keeps stable anchor")

func _test_global_geometry() -> void:
    var origin := Vector2i(1000, -250)
    _expect(Space.forward(origin, FacingRules.Value.NORTH) == Vector2i(1000, -251), "forward global cell")
    _expect(Space.behind(origin, FacingRules.Value.NORTH) == Vector2i(1000, -249), "behind global cell")
    _expect(Space.left_of(origin, FacingRules.Value.NORTH) == Vector2i(999, -250), "left global cell")
    _expect(Space.right_of(origin, FacingRules.Value.NORTH) == Vector2i(1001, -250), "right global cell")
    _expect(Space.neighbors4(Vector2i.ZERO) == [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)], "four-neighbor order")
    _expect(Space.manhattan_distance(Vector2i(-2, 5), Vector2i(3, 1)) == 9, "Manhattan distance")
    _expect(Space.are_cardinally_adjacent(Vector2i(4, 4), Vector2i(5, 4)), "cardinal adjacency")
    _expect(not Space.are_cardinally_adjacent(Vector2i(4, 4), Vector2i(5, 5)), "diagonal is not cardinal adjacency")
    _expect(Space.overlaps([Vector2i(1, 1), Vector2i(2, 1)], [Vector2i(2, 1)]), "cell-set overlap")
    _expect(not Space.overlaps([Vector2i(1, 1)], [Vector2i(2, 1)]), "cell-set non-overlap")
    _expect(Space.bounds([Vector2i(-2, 4), Vector2i(1, 8)]) == Rect2i(Vector2i(-2, 4), Vector2i(4, 5)), "integer bounds")
    _expect(Space.bounds([]) == Rect2i(), "empty bounds")

func _test_structure_axes() -> void:
    var cell := Vector2i(5, 5)
    _expect(StructureGeometry.approach_cells(cell, StructureGeometry.Axis.HORIZONTAL) == [Vector2i(5, 4), Vector2i(5, 6)], "horizontal approaches north/south")
    _expect(StructureGeometry.continuity_cells(cell, StructureGeometry.Axis.HORIZONTAL) == [Vector2i(6, 5), Vector2i(4, 5)], "horizontal continuity east/west")
    _expect(StructureGeometry.approach_cells(cell, StructureGeometry.Axis.VERTICAL) == [Vector2i(6, 5), Vector2i(4, 5)], "vertical approaches east/west")
    _expect(StructureGeometry.continuity_cells(cell, StructureGeometry.Axis.VERTICAL) == [Vector2i(5, 4), Vector2i(5, 6)], "vertical continuity north/south")
    _expect(not StructureGeometry.is_valid_axis(99), "invalid structure axis rejected")

func _test_layers_and_scale() -> void:
    _expect(is_equal_approx(Space.CELL_METERS, 1.0), "canonical one-meter planning scale")
    _expect(Layers.is_valid(Layers.Channel.TERRAIN), "terrain layer valid")
    _expect(Layers.is_valid(Layers.Channel.STRUCTURE), "structure layer valid")
    _expect(Layers.is_valid(Layers.Channel.OBJECT), "object layer valid")
    _expect(Layers.is_valid(Layers.Channel.ACTOR), "actor layer valid")
    _expect(Layers.is_valid(Layers.Channel.LOOSE_ITEM), "loose-item layer valid")
    _expect(Layers.is_valid(Layers.Channel.EFFECT), "effect layer valid")
    _expect(not Layers.is_valid(99), "invalid spatial layer rejected")

func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
