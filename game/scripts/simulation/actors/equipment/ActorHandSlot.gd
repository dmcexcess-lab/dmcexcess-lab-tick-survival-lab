extends RefCounted
class_name ActorHandSlot

## Canonical anatomical hand-slot vocabulary.
## Primary is always the actor's right hand; secondary is always the left.

enum Value {
    PRIMARY_RIGHT,
    SECONDARY_LEFT,
}

static func is_valid(slot: int) -> bool:
    return slot == Value.PRIMARY_RIGHT or slot == Value.SECONDARY_LEFT

static func label(slot: int) -> StringName:
    match slot:
        Value.PRIMARY_RIGHT:
            return &"primary_right"
        Value.SECONDARY_LEFT:
            return &"secondary_left"
        _:
            return &"invalid"
