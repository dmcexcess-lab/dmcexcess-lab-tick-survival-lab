extends RefCounted
class_name PlayerActionIntent

## Semantic player-action intent vocabulary.
## Input devices emit these values; simulation systems never inspect device events.

const FORWARD: StringName = &"player.move_forward"
const BACKWARD: StringName = &"player.move_backward"
const RUN_FORWARD: StringName = &"player.run_forward"
const TURN_LEFT: StringName = &"player.turn_left"
const TURN_RIGHT: StringName = &"player.turn_right"
const STANCE_TOGGLE: StringName = &"player.stance_toggle"
const DOOR_CLOSE: StringName = &"player.door_close"
const COMBAT_FORWARD: StringName = &"player.combat_forward"

static func is_valid(value: StringName) -> bool:
    return value == FORWARD \
        or value == BACKWARD \
        or value == RUN_FORWARD \
        or value == TURN_LEFT \
        or value == TURN_RIGHT \
        or value == STANCE_TOGGLE \
        or value == DOOR_CLOSE \
        or value == COMBAT_FORWARD

static func is_movement(value: StringName) -> bool:
    return value == FORWARD \
        or value == BACKWARD \
        or value == RUN_FORWARD \
        or value == TURN_LEFT \
        or value == TURN_RIGHT

static func label(value: StringName) -> String:
    match value:
        FORWARD:
            return "Forward"
        BACKWARD:
            return "Back"
        RUN_FORWARD:
            return "Run"
        TURN_LEFT:
            return "Turn Left"
        TURN_RIGHT:
            return "Turn Right"
        STANCE_TOGGLE:
            return "Stance"
        DOOR_CLOSE:
            return "Close Door"
        COMBAT_FORWARD:
            return "Strike"
        _:
            var parts: PackedStringArray = String(value).split(".", false)
            if parts.is_empty():
                return "Action"
            return String(parts[parts.size() - 1]).replace("_", " ").capitalize()
