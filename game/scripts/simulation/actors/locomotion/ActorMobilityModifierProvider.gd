extends RefCounted
class_name ActorMobilityModifierProvider

## Narrow read-only extension contract for independently owned actor-condition systems.
## Future health/needs/inventory/etc. providers override evaluate() without exposing internals.

enum Status {
    ALLOWED,
    BLOCKED,
    UNKNOWN,
}

var _provider_id: String = ""

func _init(provider_id_value: String = "") -> void:
    _provider_id = provider_id_value.strip_edges()

func provider_id() -> String:
    return _provider_id

func is_valid() -> bool:
    return not _provider_id.is_empty()

func evaluate(_actor_id: String, _action_type: StringName) -> Dictionary:
    return {
        "status": Status.ALLOWED,
        "duration_adjustment_bp": 0,
        "reason": "",
    }

static func decision(status: int, duration_adjustment_bp: int = 0, reason: String = "") -> Dictionary:
    return {
        "status": status,
        "duration_adjustment_bp": duration_adjustment_bp,
        "reason": reason,
    }

static func is_valid_status(value: int) -> bool:
    return value >= Status.ALLOWED and value <= Status.UNKNOWN
