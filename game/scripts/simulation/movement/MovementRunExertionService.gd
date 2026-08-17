extends RefCounted
class_name MovementRunExertionService

## Stateless Movement -> Needs coordination for System 17 acute run fatigue.
## Movement owns successful run-stride facts; Needs owns fatigue truth.

const FATIGUE_PER_STRIDE: int = 1

var _movement: MovementActionService = null
var _needs: ActorNeedsState = null

func _init(movement_service: MovementActionService = null, needs_state: ActorNeedsState = null) -> void:
    _movement = movement_service
    _needs = needs_state
    if _movement != null and not _movement.run_stride_committed.is_connected(_on_run_stride_committed):
        _movement.run_stride_committed.connect(_on_run_stride_committed)

func is_ready() -> bool:
    return _movement != null and _needs != null

func _on_run_stride_committed(
    actor_id: String,
    _action_serial: int,
    _stride_index: int,
    _target_anchor: Vector2i,
    _target_facing: int
) -> void:
    if not is_ready() or not _needs.has_actor(actor_id):
        return
    _needs.change_need(actor_id, ActorNeedsState.FATIGUE, FATIGUE_PER_STRIDE)
