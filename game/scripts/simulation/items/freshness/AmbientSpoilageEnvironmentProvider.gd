extends SpoilageEnvironmentProvider
class_name AmbientSpoilageEnvironmentProvider

const CONTEXT_ID: StringName = &"ambient"

func context_id() -> StringName:
    return CONTEXT_ID

func exposure_ticks_at(world_tick: int) -> int:
    return world_tick if world_tick >= 0 else -1
