extends RefCounted
class_name AcousticEnvironmentModifier

## Neutral future seam for weather/background masking. Candidate 001 default is
## acoustically neutral; weather/machinery owners can inject an adapter later.

func propagation_cost_addition(
    _profile_id: StringName,
    _from_cell: Vector2i,
    _to_cell: Vector2i
) -> int:
    return 0

func detection_threshold_addition(
    _listener_id: String,
    _profile_id: StringName,
    _listener_cell: Vector2i
) -> int:
    return 0

func localization_quality_adjustment(
    _listener_id: String,
    _profile_id: StringName,
    _listener_cell: Vector2i
) -> float:
    return 0.0
