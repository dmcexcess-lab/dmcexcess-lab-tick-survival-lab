extends RefCounted
class_name PropDrawCommand

const FootprintClass = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")

## Immutable-style presentation plan for one visible/intersecting OBJECT entity.
## Physical footprint/facing are retained as world facts. System 07B adds only
## presentation geometry and an optional foreground art pass.

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
var foreground_selection: ArtSelection = null
var visual_rect_world: Rect2 = Rect2()
var pivot_screen: Vector2 = Vector2.ZERO
var quarter_turns: int = 0
var draw_span_cells: Vector2i = Vector2i.ONE

func _init(
    value_entity_id: String = "",
    value_semantic_type: StringName = &"",
    value_family: StringName = FAMILY_UNKNOWN,
    value_anchor: Vector2i = Vector2i.ZERO,
    value_facing: int = -1,
    value_footprint: SpatialFootprint = null,
    value_world_cells: Array[Vector2i] = [],
    destination_rect: Rect2 = Rect2(),
    art_selection: ArtSelection = null,
    value_foreground_selection: ArtSelection = null,
    value_visual_rect_world: Rect2 = Rect2(),
    value_pivot_screen: Vector2 = Vector2.ZERO,
    value_quarter_turns: int = 0,
    value_draw_span_cells: Vector2i = Vector2i.ONE
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
    foreground_selection = value_foreground_selection.copy() if value_foreground_selection != null else null
    visual_rect_world = value_visual_rect_world
    pivot_screen = value_pivot_screen
    quarter_turns = ((value_quarter_turns % 4) + 4) % 4
    draw_span_cells = value_draw_span_cells

func has_foreground() -> bool:
    return foreground_selection != null and foreground_selection.is_found()

func is_diagnostic() -> bool:
    if selection == null or not selection.is_found():
        return true
    if foreground_selection != null and not foreground_selection.is_found():
        return true
    return false

func diagnostic_reason() -> String:
    if selection == null:
        return "selection_missing"
    if not selection.is_found():
        return selection.reason
    if foreground_selection != null and not foreground_selection.is_found():
        return foreground_selection.reason
    return ""

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
        selection,
        foreground_selection,
        visual_rect_world,
        pivot_screen,
        quarter_turns,
        draw_span_cells
    )
