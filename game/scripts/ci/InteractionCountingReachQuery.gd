extends WorldInteractionReachQuery
class_name InteractionCountingReachQuery

## Focused System-29 CI double used to prove that unrelated streaming placement
## changes do not re-run actor reach geometry for every world mutation.

var _reachable_calls: int = 0

func reachable_cells(actor_id: String, profile_id: StringName = WorldInteractionReachQuery.CONTACT_FORWARD) -> Array[Vector2i]:
    _reachable_calls += 1
    return super.reachable_cells(actor_id, profile_id)

func reachable_call_count() -> int:
    return _reachable_calls