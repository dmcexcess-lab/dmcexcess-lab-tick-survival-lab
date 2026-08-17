extends SceneTree

const CatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const SelectionClass = preload("res://scripts/art/ArtSelection.gd")
const Manifest = preload("res://scripts/art/ArtBaselineManifest.gd")
const Road = preload("res://scripts/art/RoadArtTopology.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    var catalog := CatalogClass.new()
    _test_sources_and_manifest(catalog)
    _test_region_math(catalog)
    _test_ground_recovery(catalog)
    _test_wall_opening_recovery(catalog)
    _test_prop_recovery(catalog)
    _test_road_recovery(catalog)
    _test_player_recovery(catalog)
    _test_living_actor_recovery(catalog)
    _test_unknowns(catalog)

    if _failures.is_empty():
        print("ART_CATALOG_SMOKE_OK")
        quit(0)
        return

    for failure: String in _failures:
        push_error("ART_CATALOG_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_sources_and_manifest(catalog: ArtCatalog) -> void:
    _check(catalog.source_ids().size() == 11, "catalog exposes seven atlases plus four player sprites")
    var expected: Dictionary = Manifest.expected_asset_blob_shas()
    _check(expected.size() == 10, "baseline manifest still protects ten golden Tick assets")
    for repository_path: Variant in expected.keys():
        var res_path: String = Manifest.res_path(String(repository_path))
        _check(ResourceLoader.exists(res_path), "baseline asset exists: %s" % res_path)
        var loaded: Resource = ResourceLoader.load(res_path)
        _check(loaded is Texture2D, "baseline asset loads as Texture2D: %s" % res_path)
    var recovered_actor: Dictionary = Manifest.expected_recovered_actor_blob_shas()
    _check(recovered_actor.size() == 1, "manifest protects one separately recovered actor asset")
    for repository_path: Variant in recovered_actor.keys():
        var res_path: String = Manifest.res_path(String(repository_path))
        _check(ResourceLoader.exists(res_path), "recovered actor asset exists: %s" % res_path)
        var loaded: Resource = ResourceLoader.load(res_path)
        _check(loaded is Texture2D, "recovered actor asset loads as Texture2D: %s" % res_path)

func _test_region_math(catalog: ArtCatalog) -> void:
    var source: ArtSource = catalog.source(CatalogClass.SOURCE_WORLD)
    _check(source != null and source.atlas, "world source is atlas-backed")
    if source != null:
        _check(source.region(0) == Rect2(0, 0, 32, 32), "atlas index zero region")
        _check(source.region(17) == Rect2(32, 32, 32, 32), "atlas row/column region math")
        _check(source.region(127) == Rect2(480, 224, 32, 32), "atlas high-index region math")
    var actor_source: ArtSource = catalog.source(CatalogClass.SOURCE_ACTORS)
    _check(actor_source != null and actor_source.atlas, "actor source is atlas-backed")
    if actor_source != null:
        _check(actor_source.region(63) == Rect2(480, 96, 32, 32), "actor atlas final living cell region")

func _test_ground_recovery(catalog: ArtCatalog) -> void:
    _expect(catalog.resolve_ground(&"ground.grass"), CatalogClass.SOURCE_FINAL_SURFACES, 0, "generic grass uses final alias")
    _expect(catalog.resolve_ground(&"dirt"), CatalogClass.SOURCE_FINAL_SURFACES, 11, "generic dirt uses final alias")
    _expect(catalog.resolve_ground(&"ground.road"), CatalogClass.SOURCE_TACTICAL, 1, "plain road retains tactical fallback")
    _expect(catalog.resolve_ground(&"ground.sidewalk"), CatalogClass.SOURCE_WORLD, 16, "sidewalk uses world art")
    _expect(catalog.resolve_ground(&"ground.hardwood_h"), CatalogClass.SOURCE_WORLD, 32, "world hardwood recovered")
    _expect(catalog.resolve_ground(&"ground.tile_white"), CatalogClass.SOURCE_FINAL_SURFACES, 38, "final tile recovered")
    var counts: Dictionary = catalog.mapping_counts()
    _check(int(counts.get("ground_final", 0)) == 48, "all 48 final ground entries retained")

func _test_wall_opening_recovery(catalog: ArtCatalog) -> void:
    _expect(catalog.resolve_wall(&"wall.house"), CatalogClass.SOURCE_WORLD, 40, "house wall uses golden world precedence")
    _expect(catalog.resolve_wall(&"wall.alley"), CatalogClass.SOURCE_TACTICAL, 16, "alley wall uses tactical art")
    _expect(catalog.resolve_wall(&"wall.wallpaper"), CatalogClass.SOURCE_FINAL_SURFACES, 48, "final wallpaper wall recovered")
    _expect(catalog.resolve_door(&"house", false), CatalogClass.SOURCE_WORLD, 48, "house closed door recovered")
    _expect(catalog.resolve_door(&"house", true), CatalogClass.SOURCE_WORLD, 49, "house open door recovered")
    _expect(catalog.resolve_door(&"", false), CatalogClass.SOURCE_TACTICAL, 23, "default closed door recovered")
    _expect(catalog.resolve_door(&"", true), CatalogClass.SOURCE_TACTICAL, 24, "default open door recovered")
    _expect(catalog.resolve_window(&"house"), CatalogClass.SOURCE_WORLD, 58, "house window recovered")
    _expect(catalog.resolve_window(), CatalogClass.SOURCE_TACTICAL, 25, "default tactical window recovered")

func _test_prop_recovery(catalog: ArtCatalog) -> void:
    _expect(catalog.resolve_prop(&"prop.tree"), CatalogClass.SOURCE_FINAL_PROPS, 1, "generic tree uses final alias")
    _expect(catalog.resolve_prop(&"fixture.chair"), CatalogClass.SOURCE_FINAL_PROPS, 75, "generic chair uses final alias")
    _expect(catalog.resolve_prop(&"fixture.stove"), CatalogClass.SOURCE_BUILDING, 0, "building stove recovered")
    _expect(catalog.resolve_prop(&"prop.lamp"), CatalogClass.SOURCE_CLUTTER, 7, "clutter lamp recovered")
    _expect(catalog.resolve_prop(&"prop.dumpster"), CatalogClass.SOURCE_TACTICAL, 32, "tactical dumpster recovered")
    _expect(catalog.resolve_prop(&"prop.barrel"), CatalogClass.SOURCE_TACTICAL, 26, "golden barrel helper recovered")
    _expect(catalog.resolve_prop(&"fixture.kitchen_sink"), CatalogClass.SOURCE_FINAL_PROPS, 67, "final kitchen sink recovered")
    _expect(catalog.resolve_prop(&"fixture.breakroom_table"), CatalogClass.SOURCE_FINAL_PROPS, 127, "last final prop recovered")
    var counts: Dictionary = catalog.mapping_counts()
    _check(int(counts.get("prop_final", 0)) == 128, "all 128 final props retained")
    _check(int(counts.get("prop_building", 0)) == 32, "all building props retained")
    _check(int(counts.get("prop_clutter", 0)) == 24, "all clutter props retained")

func _test_road_recovery(catalog: ArtCatalog) -> void:
    var local_expected := {
        Road.ROAD_N | Road.ROAD_S: 0,
        Road.ROAD_E | Road.ROAD_W: 1,
        Road.ROAD_N | Road.ROAD_E: 2,
        Road.ROAD_E | Road.ROAD_S: 3,
        Road.ROAD_S | Road.ROAD_W: 4,
        Road.ROAD_W | Road.ROAD_N: 5,
        Road.ROAD_N | Road.ROAD_E | Road.ROAD_S: 6,
        Road.ROAD_E | Road.ROAD_S | Road.ROAD_W: 7,
        Road.ROAD_S | Road.ROAD_W | Road.ROAD_N: 8,
        Road.ROAD_W | Road.ROAD_N | Road.ROAD_E: 9,
        Road.ROAD_ALL: 10,
        Road.ROAD_N: 11,
        Road.ROAD_E: 12,
        Road.ROAD_S: 13,
        Road.ROAD_W: 14,
        0: 15,
    }
    for mask: Variant in local_expected.keys():
        _expect(catalog.resolve_road(int(mask)), CatalogClass.SOURCE_WORLD, int(local_expected[mask]), "local road mask %s" % mask)

    var horizontal: int = Road.ROAD_E | Road.ROAD_W
    var vertical: int = Road.ROAD_N | Road.ROAD_S
    _expect(catalog.resolve_road(horizontal, &"arterial", horizontal, 0, horizontal, 0), CatalogClass.SOURCE_WORLD, 1, "arterial parallel context keeps horizontal art")
    _expect(catalog.resolve_road(horizontal, &"arterial", 0, 0, horizontal, 0), CatalogClass.SOURCE_WORLD, 15, "arterial incomplete parallel context uses plain art")
    _expect(catalog.resolve_road(vertical, &"arterial", 0, vertical, 0, vertical), CatalogClass.SOURCE_WORLD, 0, "arterial parallel context keeps vertical art")
    _expect(catalog.resolve_road(Road.ROAD_ALL, &"arterial", 0, 0, 0, 0), CatalogClass.SOURCE_WORLD, 15, "arterial intersection uses plain art")

    _expect(catalog.resolve_dirt_road(horizontal), CatalogClass.SOURCE_WORLD, 28, "horizontal dirt road recovered")
    _expect(catalog.resolve_dirt_road(vertical), CatalogClass.SOURCE_WORLD, 29, "vertical dirt road recovered")
    _expect(catalog.resolve_dirt_road(Road.ROAD_ALL), CatalogClass.SOURCE_WORLD, 30, "mixed dirt road uses gravel")

    _expect(catalog.resolve_sidewalk(Road.ROAD_N), CatalogClass.SOURCE_WORLD, 17, "north curb recovered")
    _expect(catalog.resolve_sidewalk(Road.ROAD_E), CatalogClass.SOURCE_WORLD, 18, "east curb recovered")
    _expect(catalog.resolve_sidewalk(Road.ROAD_S), CatalogClass.SOURCE_WORLD, 19, "south curb recovered")
    _expect(catalog.resolve_sidewalk(Road.ROAD_W), CatalogClass.SOURCE_WORLD, 20, "west curb recovered")
    _expect(catalog.resolve_sidewalk(Road.ROAD_N | Road.ROAD_E), CatalogClass.SOURCE_WORLD, 16, "multi-touch sidewalk uses plain art")

func _test_player_recovery(catalog: ArtCatalog) -> void:
    _expect_path(catalog.resolve_player(Facing.Value.NORTH), "res://assets/player_north.svg", "north player sprite")
    _expect_path(catalog.resolve_player(Facing.Value.EAST), "res://assets/player_east.svg", "east player sprite")
    _expect_path(catalog.resolve_player(Facing.Value.SOUTH), "res://assets/player_south.svg", "south player sprite")
    _expect_path(catalog.resolve_player(Facing.Value.WEST), "res://assets/player_west.svg", "west player sprite")

func _test_living_actor_recovery(catalog: ArtCatalog) -> void:
    var facings: Array[int] = [Facing.Value.NORTH, Facing.Value.EAST, Facing.Value.SOUTH, Facing.Value.WEST]
    for variant in range(CatalogClass.LIVING_ACTOR_VARIANTS):
        for facing_index in range(facings.size()):
            _expect(
                catalog.resolve_living_actor(&"actor.survivor", facings[facing_index], variant),
                CatalogClass.SOURCE_ACTORS,
                variant * 4 + facing_index,
                "survivor variant %d facing %d" % [variant, facing_index]
            )
            _expect(
                catalog.resolve_living_actor(&"actor.infected", facings[facing_index], variant),
                CatalogClass.SOURCE_ACTORS,
                32 + variant * 4 + facing_index,
                "infected variant %d facing %d" % [variant, facing_index]
            )
    var counts: Dictionary = catalog.mapping_counts()
    _check(int(counts.get("actor_survivor", 0)) == 32, "32 survivor living actor mappings recovered")
    _check(int(counts.get("actor_infected", 0)) == 32, "32 infected living actor mappings recovered")

func _test_unknowns(catalog: ArtCatalog) -> void:
    _check(catalog.resolve_ground(&"ground.does_not_exist").status == SelectionClass.Status.UNKNOWN, "unknown ground fails visibly")
    _check(catalog.resolve_wall(&"wall.does_not_exist").status == SelectionClass.Status.UNKNOWN, "unknown wall fails visibly")
    _check(catalog.resolve_prop(&"prop.does_not_exist").status == SelectionClass.Status.UNKNOWN, "unknown prop fails visibly")
    _check(catalog.resolve_door(&"does_not_exist", false).status == SelectionClass.Status.UNKNOWN, "unknown door theme fails visibly")
    _check(catalog.resolve_window(&"does_not_exist").status == SelectionClass.Status.UNKNOWN, "unknown window theme fails visibly")
    _check(catalog.resolve_player(99).status == SelectionClass.Status.UNKNOWN, "invalid player facing fails visibly")
    _check(catalog.resolve_living_actor(&"actor.animal", Facing.Value.NORTH, 0).status == SelectionClass.Status.UNKNOWN, "unknown living actor family fails visibly")
    _check(catalog.resolve_living_actor(&"actor.survivor", Facing.Value.NORTH, 8).status == SelectionClass.Status.UNKNOWN, "invalid living actor variant fails visibly")
    _check(catalog.resolve_living_actor(&"actor.survivor", 99, 0).status == SelectionClass.Status.UNKNOWN, "invalid living actor facing fails visibly")
    _check(catalog.resolve_road(99).status == SelectionClass.Status.UNKNOWN, "invalid road mask fails visibly")

func _expect(selection: ArtSelection, source_id: StringName, index: int, message: String) -> void:
    _check(selection != null and selection.is_found(), "%s is found" % message)
    if selection == null or not selection.is_found():
        return
    _check(selection.source.source_id == source_id, "%s source" % message)
    _check(selection.atlas_index == index, "%s index" % message)

func _expect_path(selection: ArtSelection, path: String, message: String) -> void:
    _check(selection != null and selection.is_found(), "%s is found" % message)
    if selection == null or not selection.is_found():
        return
    _check(not selection.source.atlas, "%s uses full texture" % message)
    _check(selection.source.texture_path == path, "%s path" % message)
    _check(selection.atlas_index == -1, "%s has no atlas index" % message)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
