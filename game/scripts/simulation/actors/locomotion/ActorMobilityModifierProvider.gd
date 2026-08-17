extends RefCounted
class_name ActorMobilityModifierProvider

## Narrow read-only extension contract for independently owned actor-condition systems.
## Canonical providers return a positive duration scale in basis points where 10000 = 1.0x.
## The deprecated duration_adjustment_bp field remains only as a compatibility read for older test helpers.

enum Status {
    ALLOWED,
    BLOCKED,
    UNKNOWN,
}

const SCALE_ONE: int = 10000

var _provider_id: String = ""

func _init(provider_id_value: String = "") -> void:
    _provider_id = provider_id_value.strip_edges()

func provider_id() -> String:
    return _provider_id

func is_valid() -> bool:
    return not _provider_id.is_empty()

func evaluate(_actor_id: String, _action_type: StringName) -> Dictionary:
    return decision(Status.ALLOWED, SCALE_ONE)

static func decision(
    status: int,
    duration_scale_bp: int = SCALE_ONE,
    reason: String = "",
    duration_adjustment_bp: int = 0
) -> Dictionary:
    return {
        "status": status,
        "duration_scale_bp": duration_scale_bp,
        "duration_adjustment_bp": duration_adjustment_bp,
        "reason": reason,
    }

static func is_valid_status(value: int) -> bool:
    return value >= Status.ALLOWED and value <= Status.UNKNOWN
