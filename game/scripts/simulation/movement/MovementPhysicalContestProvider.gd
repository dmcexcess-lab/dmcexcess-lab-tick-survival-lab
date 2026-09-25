extends RefCounted
class_name MovementPhysicalContestProvider

## Narrow read-only seam for resolving simultaneous claims to the same actor space.
## Movement owns arbitration; independently owned actor systems provide a frozen score.

enum Status {
    KNOWN,
    UNKNOWN,
}

func is_ready() -> bool:
    return true

func score(_actor_id: String, _action_type: StringName) -> Dictionary:
    return result(Status.UNKNOWN, 0, "contest_provider_unimplemented")

static func result(status: int, score_value: int, reason: String = "") -> Dictionary:
    return {
        "status": status,
        "score": score_value,
        "reason": reason,
    }
