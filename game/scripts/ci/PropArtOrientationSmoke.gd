extends SceneTree

const CatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const OrientationClass = preload("res://scripts/art/PropArtOrientationCatalog.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var catalog := CatalogClass.new()

    var sink: ArtSelection = catalog.resolve_prop(&"prop.kitchen_sink")
    _check(sink != null and sink.is_found(), "kitchen sink art resolves")
    _check(OrientationClass.native_facing(sink) == Facing.Value.SOUTH, "kitchen sink recovered art is native SOUTH")
    _check(OrientationClass.quarter_turns(sink, Facing.Value.SOUTH) == 0, "south-facing sink needs no rotation")
    _check(OrientationClass.quarter_turns(sink, Facing.Value.WEST) == 1, "west-facing sink rotates one quarter-turn")
    _check(OrientationClass.quarter_turns(sink, Facing.Value.NORTH) == 2, "north-facing sink rotates two quarter-turns")
    _check(OrientationClass.quarter_turns(sink, Facing.Value.EAST) == 3, "east-facing sink rotates three quarter-turns")

    var shelf: ArtSelection = catalog.resolve_prop(&"prop.retail_shelf")
    _check(shelf != null and shelf.is_found(), "retail shelf art resolves")
    _check(OrientationClass.native_facing(shelf) == Facing.Value.SOUTH, "retail shelf recovered art is native SOUTH")
    _check(OrientationClass.quarter_turns(shelf, Facing.Value.EAST) == 3, "retail shelf honors world facing")

    var bookshelf: ArtSelection = catalog.resolve_prop(&"prop.bookshelf_tall")
    _check(bookshelf != null and bookshelf.is_found(), "bookshelf art resolves")
    _check(OrientationClass.quarter_turns(bookshelf, Facing.Value.WEST) == 1, "bookshelf honors world facing")

    var legacy_stove: ArtSelection = catalog.resolve_prop(&"fixture.stove")
    _check(legacy_stove != null and legacy_stove.is_found(), "building-prop stove art resolves")
    _check(OrientationClass.native_facing(legacy_stove) == Facing.Value.SOUTH, "building-prop indoor art uses SOUTH native facing")

    var tree: ArtSelection = catalog.resolve_prop(&"vegetation.deciduous_large")
    _check(tree != null and tree.is_found(), "tree art resolves")
    _check(not OrientationClass.is_directional(tree), "vegetation remains nondirectional")
    _check(OrientationClass.quarter_turns(tree, Facing.Value.EAST) == 0, "nondirectional art is never rotated")

    if failures.is_empty():
        print("PROP_ART_ORIENTATION_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PROP_ART_ORIENTATION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
