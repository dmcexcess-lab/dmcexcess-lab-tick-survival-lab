extends CanvasLayer
class_name DemoMovementControls

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")

## Touch-first demo movement controls.
## Emits semantic intent only; owns no simulation dependency or status presentation.

signal action_intent(intent: StringName)

func _ready() -> void:
    layer = 20
    _build_title()
    _build_buttons()

func _build_title() -> void:
    var title := Label.new()
    title.text = "TICK SURVIVAL LAB — CANONICAL DEMO"
    title.position = Vector2(73, 18)
    title.size = Vector2(494, 30)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 18)
    add_child(title)

func _build_buttons() -> void:
    _add_button("FORWARD", Vector2(255, 638), Vector2(130, 52), Intents.FORWARD)
    _add_button("TURN L", Vector2(82, 704), Vector2(132, 56), Intents.TURN_LEFT)
    _add_button("TURN R", Vector2(426, 704), Vector2(132, 56), Intents.TURN_RIGHT)
    _add_button("BACK", Vector2(255, 772), Vector2(130, 52), Intents.BACKWARD)

func _add_button(
    text_value: String,
    position_value: Vector2,
    size_value: Vector2,
    intent: StringName
) -> void:
    var button := Button.new()
    button.text = text_value
    button.position = position_value
    button.size = size_value
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 18)
    button.pressed.connect(_on_button_pressed.bind(intent))
    add_child(button)

func _on_button_pressed(intent: StringName) -> void:
    action_intent.emit(intent)
