extends RefCounted
class_name ActorDrawCommand

const FootprintClass = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")

## Immutable-style presentation command for one visible/intersecting living ACTOR entity.
## Controlled role is presentation/session state, never persistent actor identity.

const FAMILY_SURVIVOR: StringName = &"survivor"
const FAMILY_INFECTED: StringName = &"infected"
const FAMILY_UNKNOWN: StringName = &"unknown"

var actor_id: String = ""
var semantic_type: StringName = &""
var family: StringName = FAMILY_UNKNOWN
var controlled: bool = false
var anchor: Vector2i = Vector2i.ZERO
var facing: int = -1
var footprint: SpatialFootprint = null
var world_cells: Array[Vector2i] = []
var variant: int = -1
var destination: Rect2 = Rect2()
var selection: ArtSelection = null

func _init(
    value_actor_id: String = "",
    value_semantic_type: StringName = &"",
    value_family: StringName = FAMILY_UNKNOWN,
    value_controlled: bool = false,
    value_anchor: Vector2i = Vector2i.ZERO,
    value_facing: int = -1,
    value_footprint: SpatialFootprint = null,
    value_world_cells: Array[Vector2i] = [],
    value_variant: int = -1,
    destination_rect: Rect2 = Rect2(),
    art_selection: ArtSelection = null
) -> void:
    actor_id = value_actor_id
    semantic_type = value_semantic_type
    family = value_family
    controlled = value_controlled
    anchor = value_anchor
    facing = value_facing
    if value_footprint != null:
        footprint = FootprintClass.new(value_footprint.offsets())
    world_cells = []
    for cell: Vector2i in value_world_cells:
        world_cells.append(cell)
    variant = value_variant
    destination = destination_rect
    selection = art_selection.copy() if art_selection != null else null

func is_diagnostic() -> bool:
    return selection == null or not selection.is_found()

func diagnostic_reason() -> String:
    if selection == null:
        return "selection_missing"
    return selection.reason

func copy() -> ActorDrawCommand:
    return ActorDrawCommand.new(
        actor_id,
        semantic_type,
        family,
        controlled,
        anchor,
        facing,
        footprint,
        world_cells,
        variant,
        destination,
        selection
    )
