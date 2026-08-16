extends RefCounted
class_name ArtSource

## Immutable-style descriptor for one art texture source.
## Rendering owns actual texture loading/caching and draw calls.

var source_id: StringName = &""
var texture_path: String = ""
var atlas: bool = true
var cell_pixels: int = 32
var atlas_columns: int = 16

func _init(
    id: StringName = &"",
    path: String = "",
    is_atlas: bool = true,
    cell_size: int = 32,
    columns: int = 16
) -> void:
    source_id = id
    texture_path = path
    atlas = is_atlas
    cell_pixels = cell_size
    atlas_columns = columns

func is_valid() -> bool:
    if String(source_id).strip_edges().is_empty() or texture_path.strip_edges().is_empty():
        return false
    if atlas and (cell_pixels < 1 or atlas_columns < 1):
        return false
    return true

func copy() -> ArtSource:
    return ArtSource.new(source_id, texture_path, atlas, cell_pixels, atlas_columns)

func region(index: int) -> Rect2:
    if not atlas or index < 0 or cell_pixels < 1 or atlas_columns < 1:
        return Rect2()
    var column: int = posmod(index, atlas_columns)
    var row: int = int(index / atlas_columns)
    return Rect2(
        float(column * cell_pixels),
        float(row * cell_pixels),
        float(cell_pixels),
        float(cell_pixels)
    )
