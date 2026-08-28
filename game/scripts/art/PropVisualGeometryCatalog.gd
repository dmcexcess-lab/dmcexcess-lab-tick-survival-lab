extends RefCounted
class_name PropVisualGeometryCatalog

const DescriptorClass = preload("res://scripts/art/PropVisualGeometryDescriptor.gd")
const SourceClass = preload("res://scripts/art/ArtSource.gd")
const SelectionClass = preload("res://scripts/art/ArtSelection.gd")

## Static System-07B presentation catalog. Semantic WHAT identity is the lookup key;
## the returned art keys/sources are presentation-only and are never persisted.

const TREE_SEMANTIC: StringName = &"vegetation.deciduous_large"
const TRAFFIC_LIGHT_SEMANTIC: StringName = &"fixture.traffic_light"

const TREE_BASE_KEY: StringName = &"visual.vegetation.deciduous_large.base"
const TREE_FOREGROUND_KEY: StringName = &"visual.vegetation.deciduous_large.canopy"
const TRAFFIC_BASE_KEY: StringName = &"visual.fixture.traffic_light.base"
const TRAFFIC_FOREGROUND_KEY: StringName = &"visual.fixture.traffic_light.head"

const SOURCE_TREE_BASE: StringName = &"large_tree_base"
const SOURCE_TREE_FOREGROUND: StringName = &"large_tree_foreground"
const SOURCE_TRAFFIC_BASE: StringName = &"large_traffic_light_base"
const SOURCE_TRAFFIC_FOREGROUND: StringName = &"large_traffic_light_foreground"

const TREE_BASE_PATH: String = "res://assets/large_deciduous_tree_base.svg"
const TREE_FOREGROUND_PATH: String = "res://assets/large_deciduous_tree_foreground.svg"
const TRAFFIC_BASE_PATH: String = "res://assets/large_traffic_light_base.svg"
const TRAFFIC_FOREGROUND_PATH: String = "res://assets/large_traffic_light_foreground.svg"

const MAX_DISCOVERY_HALO_CELLS: int = 2

static func descriptor_for(semantic_type: StringName) -> PropVisualGeometryDescriptor:
    match semantic_type:
        TREE_SEMANTIC:
            return DescriptorClass.new(
                &"large_deciduous_tree_2x2",
                TREE_BASE_KEY,
                TREE_FOREGROUND_KEY,
                Vector2i(2, 2),
                Vector2(1.0, 1.5)
            )
        TRAFFIC_LIGHT_SEMANTIC:
            return DescriptorClass.new(
                &"large_traffic_light_2x2",
                TRAFFIC_BASE_KEY,
                TRAFFIC_FOREGROUND_KEY,
                Vector2i(2, 2),
                Vector2(1.0, 1.5)
            )
        _:
            return DescriptorClass.new(
                &"default_one_cell",
                semantic_type,
                &"",
                Vector2i.ONE,
                Vector2(0.5, 0.5)
            )

static func resolve_art(art_catalog: ArtCatalog, art_key: StringName) -> ArtSelection:
    if art_catalog == null:
        return SelectionClass.unknown(art_key, "art_catalog_missing")
    var source: ArtSource = _dedicated_source_for(art_key)
    if source != null:
        return SelectionClass.found(art_key, source)
    return art_catalog.resolve_prop(art_key)

static func maximum_discovery_halo_cells() -> int:
    return MAX_DISCOVERY_HALO_CELLS

static func registered_semantics() -> Array[StringName]:
    return [TREE_SEMANTIC, TRAFFIC_LIGHT_SEMANTIC]

static func _dedicated_source_for(art_key: StringName) -> ArtSource:
    match art_key:
        TREE_BASE_KEY:
            return SourceClass.new(SOURCE_TREE_BASE, TREE_BASE_PATH, false, 64, 1)
        TREE_FOREGROUND_KEY:
            return SourceClass.new(SOURCE_TREE_FOREGROUND, TREE_FOREGROUND_PATH, false, 64, 1)
        TRAFFIC_BASE_KEY:
            return SourceClass.new(SOURCE_TRAFFIC_BASE, TRAFFIC_BASE_PATH, false, 64, 1)
        TRAFFIC_FOREGROUND_KEY:
            return SourceClass.new(SOURCE_TRAFFIC_FOREGROUND, TRAFFIC_FOREGROUND_PATH, false, 64, 1)
        _:
            return null
