extends RefCounted
class_name VehicleMaintenancePlayerInteractionHandler

const Actions = preload("res://scripts/simulation/vehicles/VehicleActionService.gd")

var _reach: WorldInteractionReachQuery = null
var _state: VehicleState = null
var _actions: VehicleActionService = null
var _kernel: TickKernel = null

func _init(
    reach: WorldInteractionReachQuery = null,
    state: VehicleState = null,
    actions: VehicleActionService = null,
    kernel: TickKernel = null
) -> void:
    _reach = reach
    _state = state
    _actions = actions
    _kernel = kernel

func is_ready() -> bool:
    return _reach != null and _reach.is_ready() and _state != null \
        and _actions != null and _actions.is_ready() and _kernel != null

func request_action(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    if not is_ready():
        return _result(false, "vehicle_maintenance_not_ready")
    if not _state.vehicle_for_driver(actor_id).is_empty():
        return _result(false, "vehicle_maintenance_requires_unmounted")
    if not _state.has_vehicle(target_id):
        return _result(false, "vehicle_target_missing")
    if not _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
        return _result(false, "vehicle_out_of_reach")

    var request: Dictionary = {}
    match action_id:
        Actions.REPAIR:
            request = _actions.request_repair(actor_id, target_id)
        Actions.REFUEL:
            request = _actions.request_refuel(actor_id, target_id)
        Actions.MODIFY:
            request = _actions.request_modify(actor_id, target_id)
        _:
            return _result(false, "vehicle_maintenance_action_unsupported")

    if not bool(request.get("accepted", false)):
        return _result(false, String(request.get("reason", "vehicle_maintenance_rejected")))
    var serial: int = int(request.get("action_serial", 0))
    if serial <= 0:
        return _result(false, "vehicle_maintenance_timing_invalid")

    var outcome: Dictionary = {}
    var completed_callback := func(resolved_actor_id: String, resolved_vehicle_id: String, action_serial: int, resolved_action_id: StringName, reason: String) -> void:
        if resolved_actor_id == actor_id and resolved_vehicle_id == target_id and action_serial == serial and resolved_action_id == action_id:
            outcome["success"] = true
            outcome["reason"] = reason
    var failed_callback := func(resolved_actor_id: String, resolved_vehicle_id: String, action_serial: int, resolved_action_id: StringName, reason: String) -> void:
        if resolved_actor_id == actor_id and resolved_vehicle_id == target_id and action_serial == serial and resolved_action_id == action_id:
            outcome["success"] = false
            outcome["reason"] = reason

    _actions.action_completed.connect(completed_callback)
    _actions.action_failed.connect(failed_callback)
    _kernel.run_until_stop()
    if _actions.action_completed.is_connected(completed_callback):
        _actions.action_completed.disconnect(completed_callback)
    if _actions.action_failed.is_connected(failed_callback):
        _actions.action_failed.disconnect(failed_callback)

    if outcome.is_empty():
        return _result(false, "vehicle_maintenance_outcome_missing")
    return _result(bool(outcome.get("success", false)), String(outcome.get("reason", "")))

static func _result(success: bool, reason: String) -> Dictionary:
    return {
        "success": success,
        "accepted": success,
        "reason": reason,
    }
