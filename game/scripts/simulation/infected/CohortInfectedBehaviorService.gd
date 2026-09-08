extends FirstInfectedBehaviorService
class_name CohortInfectedBehaviorService

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const PerformanceTelemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")

## The exact first-infected behavior policy with measurement/lifecycle hooks for
## a streaming-managed active cohort. System 39 adds only one generic reaction at
## the existing failed-forward-step seam: act on an exact blocking opening.

const PRESS_BARRIER: StringName = &"infected.press_barrier"

var _evaluation_count: int = 0
var _evaluation_total_usec: int = 0
var _evaluation_max_usec: int = 0
var _opening_pressure: ActorOpeningPressureActionService = null

func evaluation_count() -> int:
    return _evaluation_count

func evaluation_total_usec() -> int:
    return _evaluation_total_usec

func evaluation_max_usec() -> int:
    return _evaluation_max_usec

func configure_opening_pressure(service: ActorOpeningPressureActionService) -> bool:
    if service == null or not service.is_ready():
        return false
    _opening_pressure = service
    return true

func opening_pressure_service() -> ActorOpeningPressureActionService:
    return _opening_pressure

func deactivate(reason: StringName = &"stream_deactivated") -> void:
    _stop(reason)

func _drive(reason: StringName, refresh_perception: bool = true) -> void:
    if not is_running():
        return
    var started: int = Time.get_ticks_usec()
    _evaluation_count += 1
    super._drive(reason, refresh_perception)
    var elapsed: int = maxi(Time.get_ticks_usec() - started, 0)
    _evaluation_total_usec += elapsed
    _evaluation_max_usec = maxi(_evaluation_max_usec, elapsed)
    PerformanceTelemetry.record_timing(&"infected_behavior_evaluation", elapsed)
    PerformanceTelemetry.record_value(&"infected_behavior_evaluations", _evaluation_count)

func _submit_move_toward(destination: Vector2i) -> bool:
    var placement: WorldPlacement = _world.placement(_actor_id)
    if placement == null or placement.anchor == destination:
        if _intention == INVESTIGATE_SOUND:
            _set_intention(IDLE, placement.anchor if placement != null else destination, "", _kernel.world_tick())
        return false

    if Facing.is_valid(_detour_facing) and _detour_target == destination:
        if placement.facing != _detour_facing:
            return _submit_turn_toward(placement.facing, _detour_facing)
        var detour_step: MovementActionResult = _movement.request_step_forward(_actor_id)
        if detour_step != null and detour_step.is_accepted():
            _record_submission(detour_step.action_serial, detour_step.action_type)
            _clear_detour()
            return true
        if not _detour_attempted_right:
            _detour_attempted_right = true
            _detour_facing = Facing.turn_right(Facing.turn_right(_detour_facing))
            return _submit_turn_toward(placement.facing, _detour_facing)
        _clear_detour()
        return false

    var delta: Vector2i = destination - placement.anchor
    var desired_facing: int = _preferred_facing(delta)
    if not Facing.is_valid(desired_facing):
        return false
    if placement.facing != desired_facing:
        return _submit_turn_toward(placement.facing, desired_facing)

    var step: MovementActionResult = _movement.request_step_forward(_actor_id)
    if step != null and step.is_accepted():
        _record_submission(step.action_serial, step.action_type)
        return true

    # The only System-39 behavior addition. Ordinary movement failed first.
    # Query/act on the exact physical opening blocker; if no such lawful action
    # exists, preserve the already-proven bounded local detour behavior.
    if _opening_pressure != null:
        var pressure: Dictionary = _opening_pressure.request_for_forward_blocker(_actor_id)
        if bool(pressure.get("accepted", false)):
            _clear_detour()
            var target_id := String(pressure.get("target_id", ""))
            var target: WorldPlacement = _world.placement(target_id)
            _set_intention(
                PRESS_BARRIER,
                target.anchor if target != null else placement.anchor + Facing.vector(placement.facing),
                "",
                _kernel.world_tick()
            )
            _record_submission(
                int(pressure.get("action_serial", 0)),
                StringName(String(pressure.get("action_id", "")))
            )
            return true

    _detour_target = destination
    _detour_facing = Facing.turn_left(placement.facing)
    _detour_attempted_right = false
    return _submit_turn_toward(placement.facing, _detour_facing)
