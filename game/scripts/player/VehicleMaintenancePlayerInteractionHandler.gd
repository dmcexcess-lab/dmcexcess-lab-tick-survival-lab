extends RefCounted
class_name VehicleMaintenancePlayerInteractionHandler

const Actions = preload("res://scripts/simulation/vehicles/VehicleActionService.gd")

var _reach: WorldInteractionReachQuery = null
var _state: VehicleState = null
var _actions: VehicleActionService = null

func _init(
    reach: WorldInteractionReachQuery = null,
    state: VehicleState = null,
    actions: VehicleActionService = null
) -> void:
    _reach = reach
    _state = state
    _actions = actions

func is_ready() -> bool:
    return _reach != null and _reach.is_ready() and _state != null and _actions != null and _actions.is_ready()

func request_action(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    if not is_ready():
        return _reject("vehicle_maintenance_not_ready")
    if not _state.vehicle_for_driver(actor_id).is_empty():
        return _reject("vehicle_maintenance_requires_unmounted")
    if not _state.has_vehicle(target_id):
        return _reject("vehicle_target_missing")
    if not _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
        return _reject("vehicle_out_of_reach")

    match action_id:
        Actions.REPAIR:
            return _actions.request_repair(actor_id, target_id)
        Actions.REFUEL:
            return _actions.request_refuel(actor_id, target_id)
        Actions.MODIFY:
            return _actions.request_modify(actor_id, target_id)
        _:
            return _reject("vehicle_maintenance_action_unsupported")

static func _reject(reason: String) -> Dictionary:
    return {
        "accepted": false,
        "reason": reason,
        "action_serial": 0,
    }
