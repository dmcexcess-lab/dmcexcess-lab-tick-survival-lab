extends RefCounted
class_name RoadArtTopology

## Pure recovered presentation topology. No world/generator ownership.

const ROAD_N: int = 1
const ROAD_E: int = 2
const ROAD_S: int = 4
const ROAD_W: int = 8
const ROAD_ALL: int = ROAD_N | ROAD_E | ROAD_S | ROAD_W

static func is_valid_mask(mask: int) -> bool:
    return mask >= 0 and mask <= ROAD_ALL

static func road_index(
    mask: int,
    road_class: StringName = &"local",
    north_mask: int = 0,
    east_mask: int = 0,
    south_mask: int = 0,
    west_mask: int = 0
) -> int:
    if not is_valid_mask(mask):
        return -1
    if not is_valid_mask(north_mask) or not is_valid_mask(east_mask):
        return -1
    if not is_valid_mask(south_mask) or not is_valid_mask(west_mask):
        return -1

    if String(road_class) == "arterial":
        if mask == (ROAD_E | ROAD_W):
            if (north_mask & (ROAD_E | ROAD_W)) != (ROAD_E | ROAD_W):
                return 15
            if (south_mask & (ROAD_E | ROAD_W)) != (ROAD_E | ROAD_W):
                return 15
        elif mask == (ROAD_N | ROAD_S):
            if (east_mask & (ROAD_N | ROAD_S)) != (ROAD_N | ROAD_S):
                return 15
            if (west_mask & (ROAD_N | ROAD_S)) != (ROAD_N | ROAD_S):
                return 15
        elif (mask & (ROAD_N | ROAD_S)) != 0 and (mask & (ROAD_E | ROAD_W)) != 0:
            return 15

    if mask == (ROAD_N | ROAD_S):
        return 0
    if mask == (ROAD_E | ROAD_W):
        return 1
    if mask == (ROAD_N | ROAD_E):
        return 2
    if mask == (ROAD_E | ROAD_S):
        return 3
    if mask == (ROAD_S | ROAD_W):
        return 4
    if mask == (ROAD_W | ROAD_N):
        return 5
    if mask == (ROAD_N | ROAD_E | ROAD_S):
        return 6
    if mask == (ROAD_E | ROAD_S | ROAD_W):
        return 7
    if mask == (ROAD_S | ROAD_W | ROAD_N):
        return 8
    if mask == (ROAD_W | ROAD_N | ROAD_E):
        return 9
    if mask == ROAD_ALL:
        return 10
    if mask == ROAD_N:
        return 11
    if mask == ROAD_E:
        return 12
    if mask == ROAD_S:
        return 13
    if mask == ROAD_W:
        return 14
    return 15

static func dirt_road_index(mask: int) -> int:
    if not is_valid_mask(mask):
        return -1
    var horizontal: bool = (mask & (ROAD_E | ROAD_W)) != 0
    var vertical: bool = (mask & (ROAD_N | ROAD_S)) != 0
    if horizontal and not vertical:
        return 28
    if vertical and not horizontal:
        return 29
    return 30

static func sidewalk_index(touching_road_mask: int) -> int:
    if not is_valid_mask(touching_road_mask):
        return -1
    if touching_road_mask == ROAD_N:
        return 17
    if touching_road_mask == ROAD_E:
        return 18
    if touching_road_mask == ROAD_S:
        return 19
    if touching_road_mask == ROAD_W:
        return 20
    return 16
