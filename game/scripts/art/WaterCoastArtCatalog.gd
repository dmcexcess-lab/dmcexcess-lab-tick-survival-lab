extends RefCounted
class_name WaterCoastArtCatalog

const ArtSourceClass = preload("res://scripts/art/ArtSource.gd")
const ArtSelectionClass = preload("res://scripts/art/ArtSelection.gd")

const SOURCE_WATER_COAST: StringName = &"water_coast"
const ATLAS_CELL_PIXELS: int = 32
const ATLAS_COLUMNS: int = 16

const GROUND_INDEX := {
    "water_ocean": 0,
    "water_river": 1,
    "shore_sand": 2,
    "shore_n": 3,
    "shore_e": 4,
    "shore_s": 5,
    "shore_w": 6,
    "shore_ne": 7,
    "shore_es": 8,
    "shore_sw": 9,
    "shore_wn": 10,
    "shore_nes": 11,
    "shore_wne": 12,
    "shore_swn": 13,
    "shore_esw": 14,
    "shore_all": 15,
}

var _source: ArtSource = null

func _init() -> void:
    _source = ArtSourceClass.new(
        SOURCE_WATER_COAST,
        "res://assets/water_coast_atlas.svg",
        true,
        ATLAS_CELL_PIXELS,
        ATLAS_COLUMNS
    )

func supports_ground(semantic_id: StringName) -> bool:
    return GROUND_INDEX.has(_leaf_token(semantic_id))

func resolve_ground(semantic_id: StringName) -> ArtSelection:
    var token: String = _leaf_token(semantic_id)
    if not GROUND_INDEX.has(token) or _source == null:
        return ArtSelectionClass.unknown(semantic_id, "water_coast_ground_unclassified")
    return ArtSelectionClass.found(semantic_id, _source, int(GROUND_INDEX[token]))

func source() -> ArtSource:
    return null if _source == null else _source.copy()

func mapping_count() -> int:
    return GROUND_INDEX.size()

func _leaf_token(value: StringName) -> String:
    var raw: String = String(value).strip_edges()
    if raw.is_empty():
        return ""
    var dot_index: int = raw.rfind(".")
    if dot_index >= 0 and dot_index < raw.length() - 1:
        return raw.substr(dot_index + 1)
    return raw
