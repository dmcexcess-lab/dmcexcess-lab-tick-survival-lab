extends RefCounted
class_name ActorHandSlot

## Canonical anatomical/equipment slot vocabulary.
## The first two values are intentionally stable for snapshot and caller compatibility.

enum Value {
    PRIMARY_RIGHT,
    SECONDARY_LEFT,
    BACK,
    HEAD,
    TORSO,
    LEGS,
    FEET,
    HANDS,
}

const ALL: Array[int] = [
    Value.PRIMARY_RIGHT,
    Value.SECONDARY_LEFT,
    Value.BACK,
    Value.HEAD,
    Value.TORSO,
    Value.LEGS,
    Value.FEET,
    Value.HANDS,
]

const FLOATING: Array[int] = [Value.PRIMARY_RIGHT, Value.SECONDARY_LEFT, Value.BACK]
const WORN: Array[int] = [Value.HEAD, Value.TORSO, Value.LEGS, Value.FEET, Value.HANDS]

static func is_valid(slot: int) -> bool:
    return slot in ALL

static func is_hand(slot: int) -> bool:
    return slot == Value.PRIMARY_RIGHT or slot == Value.SECONDARY_LEFT

static func is_floating(slot: int) -> bool:
    return slot in FLOATING

static func is_worn(slot: int) -> bool:
    return slot in WORN

static func label(slot: int) -> StringName:
    match slot:
        Value.PRIMARY_RIGHT:
            return &"primary_right"
        Value.SECONDARY_LEFT:
            return &"secondary_left"
        Value.BACK:
            return &"back"
        Value.HEAD:
            return &"head"
        Value.TORSO:
            return &"torso"
        Value.LEGS:
            return &"legs"
        Value.FEET:
            return &"feet"
        Value.HANDS:
            return &"hands"
        _:
            return &"invalid"
