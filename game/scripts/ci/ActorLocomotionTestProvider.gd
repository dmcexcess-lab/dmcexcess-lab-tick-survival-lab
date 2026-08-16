extends "res://scripts/simulation/actors/locomotion/ActorMobilityModifierProvider.gd"
class_name ActorLocomotionTestProvider

var _status: int = Status.ALLOWED
var _duration_adjustment_bp: int = 0
var _reason: String = ""

func _init(
    provider_id_value: String = "",
    status_value: int = Status.ALLOWED,
    duration_adjustment_bp_value: int = 0,
    reason_value: String = ""
) -> void:
    super(provider_id_value)
    _status = status_value
    _duration_adjustment_bp = duration_adjustment_bp_value
    _reason = reason_value

func set_result(
    status_value: int,
    duration_adjustment_bp_value: int = 0,
    reason_value: String = ""
) -> void:
    _status = status_value
    _duration_adjustment_bp = duration_adjustment_bp_value
    _reason = reason_value

func evaluate(_actor_id: String, _action_type: StringName) -> Dictionary:
    return {
        "status": _status,
        "duration_adjustment_bp": _duration_adjustment_bp,
        "reason": _reason,
    }
