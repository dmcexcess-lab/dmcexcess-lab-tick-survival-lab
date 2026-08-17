extends RefCounted
class_name PropDrawCommand

const FootprintClass = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")

## Immutable-style presentation command for one visible/intersecting OBJECT entity.
## Physical footprint/facing are retained as world facts; current recovered prop art
## remains one unrotated cell-sized sprite at the placement anchor.

const FAMILY_PROP: StringName = &"prop"
const FAMILY_FIXTURE: StringName = &"fixture"
const FAMILY_VEGETATION: StringName = &"vegetation"
const FAMILY_UNKNOWN: StringName = &"unknown"

var entity_id: String = ""
var semantic_type: StringName = &""
var family: StringName = FAMILY_UNKNOWN
var anchor: Vector2i = Vector2i.ZERO
var facing: int = -1
var footprint: SpatialFootprint = null
var world_cells: Array[Vector2i] = []
var destination: Rect2 = Rect2()
var selection: ArtSelection = null

func _init(
    value_entity_id: String = "",
    value_semantic_type: StringName = &"",
    value_family: StringName = FAMILY_UNKNOWN,
    value_anchor: Vector2i = Vector2i.ZERO,
    value_facing: int = -1,
    value_footprint: SpatialFootprint = null,
    value_world_cells: Array[Vector2i] = [],
    destination_rect: Rect2 = Rect2(),
    art_selection: ArtSelection = null
) -> void:
    entity_id = value_entity_id
    semantic_type = value_semantic_type
    family = value_family
    anchor = value_anchor
    facing = value_facing
    if value_footprint != null:
        footprint = FootprintClass.new(value_footprint.offsets())
    world_cells = []
    for cell: Vector2i in value_world_cells:
        world_cells.append(cell)
    destination = destination_rect
    selection = art_selection.copy() if art_selection != null else null

func is_diagnostic() -> bool:
    return selection == null or not selection.is_found()

func diagnostic_reason() -> String:
    if selection == null:
        return "selection_missing"
    return selection.reason

func copy() -> PropDrawCommand:
    return PropDrawCommand.new(
        entity_id,
        semantic_type,
        family,
        anchor,
        facing,
        footprint,
        world_cells,
        destination,
        selection
    )
