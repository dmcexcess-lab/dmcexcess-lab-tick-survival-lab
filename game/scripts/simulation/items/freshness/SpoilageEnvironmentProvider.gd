extends RefCounted
class_name SpoilageEnvironmentProvider

## Cumulative effective-spoilage exposure clock for one storage environment.
## Implementations update their context clock, never every item inside it.

func context_id() -> StringName:
    return &""

func exposure_ticks_at(_world_tick: int) -> int:
    return -1

func is_valid() -> bool:
    return not String(context_id()).is_empty() and exposure_ticks_at(0) >= 0
