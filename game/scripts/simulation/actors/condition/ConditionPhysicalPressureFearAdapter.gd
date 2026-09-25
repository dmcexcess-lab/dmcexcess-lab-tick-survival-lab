extends RefCounted
class_name ConditionPhysicalPressureFearAdapter

## Shared movement/pressure -> fear seam. The physical solver remains the owner
## of force; this adapter only interprets its resolved consequence psychologically.

const RESISTED_PRESSURE: int = 3
const DISPLACED_PRESSURE: int = 6
const TRAPPED_PRESSURE: int = 8

var _movement: MovementActionService = null
var _fear: ActorFearPressureService = null
var _actor_id: String = ""

func _init(
    movement_service: MovementActionService = null,
    fear_service: ActorFearPressureService = null,
    actor_id: String = ""
) -> void:
    _movement = movement_service
    _fear = fear_service
    _actor_id = actor_id.strip_edges()
    if _movement != null:
        var callable := Callable(self, "_on_physical_pressure_resolved")
        if not _movement.physical_pressure_resolved.is_connected(callable):
            _movement.physical_pressure_resolved.connect(callable)

func is_ready() -> bool:
    return _movement != null and _fear != null and _fear.is_ready() and not _actor_id.is_empty()

func _on_physical_pressure_resolved(
    target_actor_id: String,
    _pressure_score: int,
    displaced: bool,
    trapped: bool
) -> void:
    if not is_ready() or target_actor_id != _actor_id:
        return
    var pressure: int = TRAPPED_PRESSURE if trapped else (DISPLACED_PRESSURE if displaced else RESISTED_PRESSURE)
    _fear.queue_pressure(_actor_id, pressure, &"physical_crowd_pressure")
