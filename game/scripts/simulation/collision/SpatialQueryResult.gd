extends RefCounted
class_name SpatialQueryResult

## Explicit result for occupancy/collision questions.
## UNKNOWN means information is incomplete and callers must not treat the target as clear.

enum Status {
    CLEAR,
    BLOCKED,
    UNKNOWN,
}

var status: int = Status.UNKNOWN
var cells: Array[Vector2i] = []
var blocking_entity_ids: Array[String] = []
var missing_terrain_cells: Array[Vector2i] = []
var unclassified_entity_ids: Array[String] = []

func is_clear() -> bool:
    return status == Status.CLEAR

func is_blocked() -> bool:
    return status == Status.BLOCKED

func is_unknown() -> bool:
    return status == Status.UNKNOWN

func copy() -> SpatialQueryResult:
    var result := SpatialQueryResult.new()
    result.status = status
    for cell: Vector2i in cells:
        result.cells.append(cell)
    for entity_id: String in blocking_entity_ids:
        result.blocking_entity_ids.append(entity_id)
    for cell: Vector2i in missing_terrain_cells:
        result.missing_terrain_cells.append(cell)
    for entity_id: String in unclassified_entity_ids:
        result.unclassified_entity_ids.append(entity_id)
    return result
