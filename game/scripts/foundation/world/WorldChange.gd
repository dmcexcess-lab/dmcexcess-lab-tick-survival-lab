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
}

var sequence: int = 0
var kind: int = -1
var entity_id: String = ""
var before_cells: Array[Vector2i] = []
var after_cells: Array[Vector2i] = []
var terrain_cell: Vector2i = Vector2i.ZERO
var terrain_before: StringName = &""
var terrain_after: StringName = &""

func _init(change_kind: int = -1, changed_entity_id: String = "") -> void:
    kind = change_kind
    entity_id = changed_entity_id

func is_valid() -> bool:
    return kind >= Kind.ENTITY_CREATED and kind <= Kind.TERRAIN_REMOVED

func copy() -> WorldChange:
    var result := WorldChange.new(kind, entity_id)
    result.sequence = sequence
    result.before_cells = before_cells.duplicate()
    result.after_cells = after_cells.duplicate()
    result.terrain_cell = terrain_cell
    result.terrain_before = terrain_before
    result.terrain_after = terrain_after
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
        _:
            return "invalid"
