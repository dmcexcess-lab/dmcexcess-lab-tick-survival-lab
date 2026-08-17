extends RefCounted
class_name StructureDrawCommand

## Immutable-style presentation command for one visible structure cell.
## Contains no gameplay mutation or camera ownership.

const KIND_WALL: StringName = &"wall"
const KIND_DOOR: StringName = &"door"
const KIND_WINDOW: StringName = &"window"
const KIND_UNKNOWN: StringName = &"unknown"

var cell: Vector2i = Vector2i.ZERO
var destination: Rect2 = Rect2()
var entity_id: String = ""
var semantic_type: StringName = &""
var kind: StringName = KIND_UNKNOWN
var structure_axis: int = -1
var selection: ArtSelection = null

func _init(
    world_cell: Vector2i = Vector2i.ZERO,
    destination_rect: Rect2 = Rect2(),
    value_entity_id: String = "",
    value_semantic_type: StringName = &"",
    value_kind: StringName = KIND_UNKNOWN,
    value_structure_axis: int = -1,
    art_selection: ArtSelection = null
) -> void:
    cell = world_cell
    destination = destination_rect
    entity_id = value_entity_id
    semantic_type = value_semantic_type
    kind = value_kind
    structure_axis = value_structure_axis
    selection = art_selection.copy() if art_selection != null else null

func is_diagnostic() -> bool:
    return selection == null or not selection.is_found()

func diagnostic_reason() -> String:
    if selection == null:
        return "selection_missing"
    return selection.reason

func copy() -> StructureDrawCommand:
    return StructureDrawCommand.new(
        cell,
        destination,
        entity_id,
        semantic_type,
        kind,
        structure_axis,
        selection
    )
