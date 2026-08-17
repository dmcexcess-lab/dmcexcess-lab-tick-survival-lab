extends RefCounted
class_name MovementPassageResolver

## Optional generic seam for resolving a known BLOCKED movement target at the
## physical commit/stride. Movement remains unaware of doors or other passage kinds.

func is_ready() -> bool:
    return true

func can_resolve(_actor_id: String, _action_type: StringName, _query_result: SpatialQueryResult) -> bool:
    return false

func resolve(
    _actor_id: String,
    _action_serial: int,
    _action_type: StringName,
    _query_result: SpatialQueryResult
) -> bool:
    return false
