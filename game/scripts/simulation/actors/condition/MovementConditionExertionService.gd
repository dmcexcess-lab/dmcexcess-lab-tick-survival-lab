extends RefCounted
class_name MovementConditionExertionService

## Event-driven Movement -> System 34 exertion adapter.
## Walking adds little Fatigue; running adds materially more and scales with terrain/load.

const STEP_FORWARD: StringName = &"movement.step_forward"
const STEP_BACKWARD: StringName = &"movement.step_backward"
const RUN_FORWARD: StringName = &"movement.run_forward"
const NORMAL_TERRAIN_WALK_TICKS: int = 10
const SCALE_ONE: int = 10000
const RUN_BASE_FATIGUE_COST: int = 8

var _movement: MovementActionService = null
var _condition: ActorConditionService = null
var _carry_query: ActorCarryQuery = null

func _init(
    movement_service: MovementActionService = null,
    condition_service: ActorConditionService = null,
    carry_query: ActorCarryQuery = null
) -> void:
    _movement = movement_service
    _condition = condition_service
    _carry_query = carry_query
    if _movement != null:
        var callable := Callable(self, "_on_movement_exertion_resolved")
        if not _movement.movement_exertion_resolved.is_connected(callable):
            _movement.movement_exertion_resolved.connect(callable)

func is_ready() -> bool:
    return _movement != null and _condition != null and _condition.is_ready() and _carry_query != null

func _on_movement_exertion_resolved(
    actor_id: String,
    _action_serial: int,
    action_type: StringName,
    _stride_index: int,
    terrain_walk_ticks: int,
    _impacted: bool
) -> void:
    if not is_ready() or terrain_walk_ticks < 1 or not _condition.has_actor(actor_id):
        return
    var cost: int = 0
    if action_type == STEP_FORWARD or action_type == STEP_BACKWARD:
        cost = maxi(1, int(ceili(float(terrain_walk_ticks) / float(NORMAL_TERRAIN_WALK_TICKS))))
    elif action_type == RUN_FORWARD:
        cost = _run_cost(actor_id, terrain_walk_ticks)
    if cost > 0:
        _condition.apply_exertion(actor_id, cost, &"movement_exertion")

func _run_cost(actor_id: String, terrain_walk_ticks: int) -> int:
    var carry: Dictionary = _carry_query.query(actor_id)
    var load_ratio_bp: int = 0
    if int(carry.get("status", -1)) == ActorCarryQuery.Status.KNOWN:
        load_ratio_bp = maxi(0, int(carry.get("load_ratio_bp", 0)))
    var terrain_scale_bp: int = maxi(SCALE_ONE, int((terrain_walk_ticks * SCALE_ONE) / NORMAL_TERRAIN_WALK_TICKS))
    var encumbrance_scale_bp: int = SCALE_ONE + int((load_ratio_bp * 50) / 100)
    var numerator: int = RUN_BASE_FATIGUE_COST * terrain_scale_bp * encumbrance_scale_bp
    var denominator: int = SCALE_ONE * SCALE_ONE
    return maxi(1, int(ceili(float(numerator) / float(denominator))))
