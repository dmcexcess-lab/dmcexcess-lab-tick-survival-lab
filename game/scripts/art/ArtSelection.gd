extends RefCounted
class_name ArtSelection

const ArtSourceClass = preload("res://scripts/art/ArtSource.gd")

enum Status {
    FOUND,
    UNKNOWN,
}

var status: int = Status.UNKNOWN
var semantic_id: StringName = &""
var source: ArtSource = null
var atlas_index: int = -1
var reason: String = ""

func _init(
    value_status: int = Status.UNKNOWN,
    requested_id: StringName = &"",
    value_source: ArtSource = null,
    index: int = -1,
    diagnostic_reason: String = ""
) -> void:
    status = value_status
    semantic_id = requested_id
    source = value_source.copy() if value_source != null else null
    atlas_index = index
    reason = diagnostic_reason

static func found(requested_id: StringName, value_source: ArtSource, index: int = -1) -> ArtSelection:
    return ArtSelection.new(Status.FOUND, requested_id, value_source, index, "")

static func unknown(requested_id: StringName, diagnostic_reason: String) -> ArtSelection:
    return ArtSelection.new(Status.UNKNOWN, requested_id, null, -1, diagnostic_reason)

func is_found() -> bool:
    return status == Status.FOUND and source != null and source.is_valid()

func is_atlas_region() -> bool:
    return is_found() and source.atlas and atlas_index >= 0

func region() -> Rect2:
    if not is_atlas_region():
        return Rect2()
    return source.region(atlas_index)

func copy() -> ArtSelection:
    return ArtSelection.new(status, semantic_id, source, atlas_index, reason)
