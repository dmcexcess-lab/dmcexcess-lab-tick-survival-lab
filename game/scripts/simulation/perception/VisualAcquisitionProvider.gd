extends RefCounted
class_name VisualAcquisitionProvider

## Neutral System 23 observer-acquisition gate.
## Geometry is resolved before this provider is asked whether current conditions
## allow the observer to acquire a geometric candidate as current visual truth.
## Default behavior preserves the historical geometry-only perception contract.

func is_ready() -> bool:
    return true

func allows_target(
    _observer_id: String,
    _origin: Vector2i,
    _target: Vector2i,
    _profile: VisionProfile
) -> bool:
    return true
