extends RefCounted
class_name ItemDispositionResult

enum Status {
    LOOSE_WORLD,
    HAND,
    CONTAINED,
    UNCLAIMED,
    INVALID_PLACEMENT,
    CONFLICT,
    UNKNOWN,
}

var status: int = Status.UNKNOWN
var item_id: String = ""
var semantic_type: StringName = &""
var placement: WorldPlacement = null
var actor_id: String = ""
var slot: int = -1
var container_id: String = ""
var reason: String = ""

func copy() -> ItemDispositionResult:
    var result := ItemDispositionResult.new()
    result.status = status
    result.item_id = item_id
    result.semantic_type = semantic_type
    result.placement = placement.copy() if placement != null else null
    result.actor_id = actor_id
    result.slot = slot
    result.container_id = container_id
    result.reason = reason
    return result

func is_actionable_source() -> bool:
    return status in [Status.LOOSE_WORLD, Status.HAND, Status.CONTAINED, Status.UNCLAIMED]
