extends RefCounted
class_name ItemTransferTimingPolicy

const ActionTypes = preload("res://scripts/simulation/items/transfer/ItemTransferActionType.gd")
const DecisionClass = preload("res://scripts/simulation/items/transfer/ItemTransferTimingDecision.gd")

var _durations: Dictionary = {}

func register_duration(action_type: StringName, ticks: int) -> bool:
    if not ActionTypes.is_valid(action_type) or ticks < 1:
        return false
    _durations[action_type] = ticks
    return true

func has_duration(action_type: StringName) -> bool:
    return _durations.has(action_type)

func evaluate(actor_id: String, action_type: StringName) -> ItemTransferTimingDecision:
    if actor_id.strip_edges().is_empty():
        return DecisionClass.denied(DecisionClass.Status.ACTOR_UNCLASSIFIED, "actor_unclassified")
    if not ActionTypes.is_valid(action_type) or not _durations.has(action_type):
        return DecisionClass.denied(DecisionClass.Status.ACTION_UNCLASSIFIED, "action_unclassified")
    var duration: int = int(_durations[action_type])
    if duration < 1:
        return DecisionClass.denied(DecisionClass.Status.INVALID_DURATION, "invalid_duration")
    return DecisionClass.allowed(duration)
