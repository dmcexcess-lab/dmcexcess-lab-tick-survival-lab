extends Node
class_name KeyboardInputAdapter

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")

## Keyboard-only adapter. Emits semantic intent and owns no simulation dependency.

signal action_intent(intent: StringName)

var _enabled: bool = true

func set_enabled(enabled: bool) -> void:
    _enabled = enabled

func is_enabled() -> bool:
    return _enabled

func _unhandled_input(event: InputEvent) -> void:
    if not _enabled:
        return
    var key_event := event as InputEventKey
    if key_event == null or not key_event.pressed or key_event.echo:
        return

    var intent: StringName = _intent_for_key(key_event)
    if intent == &"":
        return
    action_intent.emit(intent)
    get_viewport().set_input_as_handled()

static func _intent_for_key(event: InputEventKey) -> StringName:
    if _matches(event, KEY_W) or _matches(event, KEY_UP):
        return Intents.FORWARD
    if _matches(event, KEY_S) or _matches(event, KEY_DOWN):
        return Intents.BACKWARD
    if _matches(event, KEY_A) or _matches(event, KEY_LEFT):
        return Intents.TURN_LEFT
    if _matches(event, KEY_D) or _matches(event, KEY_RIGHT):
        return Intents.TURN_RIGHT
    if _matches(event, KEY_C):
        return Intents.STANCE_TOGGLE
    return &""

static func _matches(event: InputEventKey, code: Key) -> bool:
    return event.keycode == code or event.physical_keycode == code
