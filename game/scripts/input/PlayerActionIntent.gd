extends RefCounted
class_name PlayerActionIntent

## Semantic player-action intent vocabulary.
## Input devices emit these values; simulation systems never inspect device events.

const FORWARD: StringName = &"player.move_forward"
const BACKWARD: StringName = &"player.move_backward"
const TURN_LEFT: StringName = &"player.turn_left"
const TURN_RIGHT: StringName = &"player.turn_right"
const STANCE_TOGGLE: StringName = &"player.stance_toggle"

static func is_valid(value: StringName) -> bool:
    return value == FORWARD \
        or value == BACKWARD \
        or value == TURN_LEFT \
        or value == TURN_RIGHT \
        or value == STANCE_TOGGLE

static func is_movement(value: StringName) -> bool:
    return value == FORWARD \
        or value == BACKWARD \
        or value == TURN_LEFT \
        or value == TURN_RIGHT

static func label(value: StringName) -> String:
    match value:
        FORWARD:
            return "Forward"
        BACKWARD:
            return "Back"
        TURN_LEFT:
            return "Turn Left"
        TURN_RIGHT:
            return "Turn Right"
        STANCE_TOGGLE:
            return "Stance"
        _:
            return "Unknown"
