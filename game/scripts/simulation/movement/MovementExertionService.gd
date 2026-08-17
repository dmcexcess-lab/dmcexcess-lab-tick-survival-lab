extends RefCounted
class_name MovementExertionService

## Stateless Movement -> Needs coordination for System 17A.
## Walk fatigue depends on terrain only. Run fatigue depends on terrain + derived Carry load.

const STEP_FORWARD: StringName = &"movement.step_forward"
const STEP_BACKWARD: StringName = &"movement.step_backward"
const RUN_FORWARD: StringName = &"movement.run_forward"
const NORMAL_TERRAIN_WALK_TICKS: int = 10
const SCALE_ONE: int = 10000

var _movement: MovementActionService = null
var _needs: ActorNeedsState = null
var _carry_query: ActorCarryQuery = null

func _init(
    movement_service: MovementActionService = null,
    needs_state: ActorNeedsState = null,
    carry_query: ActorCarryQuery = null
) -> void:
    _movement = movement_service
    _needs = needs_state
    _carry_query = carry_query
    if _movement != null and not _movement.movement_exertion_resolved.is_connected(_on_movement_exertion_resolved):
        _movement.movement_exertion_resolved.connect(_on_movement_exertion_resolved)

func is_ready() -> bool:
    return _movement != null and _needs != null and _carry_query != null

func _on_movement_exertion_resolved(
    actor_id: String,
    _action_serial: int,
    action_type: StringName,
    _stride_index: int,
    terrain_walk_ticks: int,
    _impacted: bool
) -> void:
    if not is_ready() or terrain_walk_ticks < 1 or not _needs.has_actor(actor_id):
        return
    var fatigue_gain: int = 0
    if action_type == STEP_FORWARD or action_type == STEP_BACKWARD:
        fatigue_gain = _walk_fatigue_gain(terrain_walk_ticks)
    elif action_type == RUN_FORWARD:
        fatigue_gain = _run_fatigue_gain(actor_id, terrain_walk_ticks)
    if fatigue_gain > 0:
        _needs.change_need(actor_id, ActorNeedsState.FATIGUE, fatigue_gain)

func _run_fatigue_gain(actor_id: String, terrain_walk_ticks: int) -> int:
    var carry: Dictionary = _carry_query.query(actor_id)
    if int(carry.get("status", -1)) != ActorCarryQuery.Status.KNOWN:
        return 0
    var load_ratio_bp: int = maxi(0, int(carry.get("load_ratio_bp", 0)))
    var encumbrance_scale_bp: int = SCALE_ONE + int((load_ratio_bp * 75) / 100)
    var numerator: int = terrain_walk_ticks * encumbrance_scale_bp
    var denominator: int = NORMAL_TERRAIN_WALK_TICKS * SCALE_ONE
    var rounded: int = int((numerator + (denominator / 2)) / denominator)
    return maxi(1, rounded)

static func _walk_fatigue_gain(terrain_walk_ticks: int) -> int:
    if terrain_walk_ticks < 1:
        return 0
    return maxi(1, int((terrain_walk_ticks + NORMAL_TERRAIN_WALK_TICKS - 1) / NORMAL_TERRAIN_WALK_TICKS))
