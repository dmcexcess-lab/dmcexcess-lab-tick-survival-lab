extends RefCounted
class_name GroundDrawCommand

## Immutable-style presentation command for one visible ground cell.
## The command contains no world mutation or camera ownership.

var cell: Vector2i = Vector2i.ZERO
var destination: Rect2 = Rect2()
var semantic_id: StringName = &""
var selection: ArtSelection = null

func _init(
    world_cell: Vector2i = Vector2i.ZERO,
    destination_rect: Rect2 = Rect2(),
    terrain_semantic_id: StringName = &"",
    art_selection: ArtSelection = null
) -> void:
    cell = world_cell
    destination = destination_rect
    semantic_id = terrain_semantic_id
    selection = art_selection.copy() if art_selection != null else null

func is_diagnostic() -> bool:
    return selection == null or not selection.is_found()

func diagnostic_reason() -> String:
    if selection == null:
        return "selection_missing"
    return selection.reason

func copy() -> GroundDrawCommand:
    return GroundDrawCommand.new(cell, destination, semantic_id, selection)
