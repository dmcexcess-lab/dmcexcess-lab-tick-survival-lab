extends RefCounted
class_name AcousticMaterialCatalog

const DoorValues = preload("res://scripts/simulation/doors/DoorStateValue.gd")

## Candidate 001 acoustic attenuation classification. Art and Collision are not
## acoustic authority.

const OPEN_AIR_COST: int = 0
const OPEN_DOOR_COST: int = 4
const WINDOW_COST: int = 36
const CLOSED_DOOR_COST: int = 64
const WALL_COST: int = 124
const UNKNOWN_STRUCTURE_COST: int = 132
const STRONG_SEAL_THRESHOLD: int = CLOSED_DOOR_COST

func structure_cost(semantic_type: StringName, door_state: StringName = &"") -> int:
    var raw: String = String(semantic_type).strip_edges()
    if raw.begins_with("door."):
        if door_state == DoorValues.OPEN:
            return OPEN_DOOR_COST
        if door_state == DoorValues.CLOSED:
            return CLOSED_DOOR_COST
        return UNKNOWN_STRUCTURE_COST
    if raw.begins_with("window."):
        return WINDOW_COST
    if raw.begins_with("wall."):
        return WALL_COST
    return UNKNOWN_STRUCTURE_COST

func is_strong_seal(cost: int) -> bool:
    return cost >= STRONG_SEAL_THRESHOLD
