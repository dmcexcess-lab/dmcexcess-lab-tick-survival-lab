extends RefCounted
class_name WorldChange

## Mechanic-agnostic foundation change record emitted after a successful WHAT mutation.

enum Kind {
    ENTITY_CREATED,
    ENTITY_REMOVED,
    PLACEMENT_SET,
    PLACEMENT_REMOVED,
    TERRAIN_SET,
    TERRAIN_REMOVED,
    TERRAIN_BATCH_SET,
}

var sequence: int = 0
var kind: int = -1
var entity_id: String = ""
var before_cells: Array[Vector2i] = []
var after_cells: Array[Vector2i] = []
var before_channel: int = -1
var after_channel: int = -1
var terrain_cell: Vector2i = Vector2i.ZERO
var terrain_before: StringName = &""
var terrain_after: StringName = &""
## Batch terrain changes use exactly one of terrain_rect or terrain_cells.
## A rectangular batch may conservatively describe cells that were already equal to terrain_after;
## consumers may treat the payload as a dirty/replay region.
var terrain_rect: Rect2i = Rect2i()
var terrain_cells: Array[Vector2i] = []

func _init(change_kind: int = -1, changed_entity_id: String = "") -> void:
    kind = change_kind
    entity_id = changed_entity_id

func is_valid() -> bool:
    return kind >= Kind.ENTITY_CREATED and kind <= Kind.TERRAIN_BATCH_SET

func is_terrain_change() -> bool:
    return kind == Kind.TERRAIN_SET or kind == Kind.TERRAIN_REMOVED or kind == Kind.TERRAIN_BATCH_SET

func affects_channel(channel: int) -> bool:
    return before_channel == channel or after_channel == channel

func copy() -> WorldChange:
    var result := WorldChange.new(kind, entity_id)
    result.sequence = sequence
    result.before_cells = before_cells.duplicate()
    result.after_cells = after_cells.duplicate()
    result.before_channel = before_channel
    result.after_channel = after_channel
    result.terrain_cell = terrain_cell
    result.terrain_before = terrain_before
    result.terrain_after = terrain_after
    result.terrain_rect = terrain_rect
    result.terrain_cells = terrain_cells.duplicate()
    return result

static func label(change_kind: int) -> String:
    match change_kind:
        Kind.ENTITY_CREATED:
            return "entity_created"
        Kind.ENTITY_REMOVED:
            return "entity_removed"
        Kind.PLACEMENT_SET:
            return "placement_set"
        Kind.PLACEMENT_REMOVED:
            return "placement_removed"
        Kind.TERRAIN_SET:
            return "terrain_set"
        Kind.TERRAIN_REMOVED:
            return "terrain_removed"
        Kind.TERRAIN_BATCH_SET:
            return "terrain_batch_set"
        _:
            return "invalid"
