extends CanvasLayer
class_name DemoMovementControls

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")

## Touch-first demo controls and lightweight action feedback.
## Emits semantic intent only; owns no simulation dependency.

signal action_intent(intent: StringName)

var _status_label: Label = null

func _ready() -> void:
    layer = 20
    _build_labels()
    _build_buttons()

func present_action_result(
    intent: StringName,
    success: bool,
    reason: String,
    world_tick: int
) -> void:
    if _status_label == null:
        return
    var action_label: String = Intents.label(intent)
    if success:
        _status_label.text = "Tick %d  •  %s" % [world_tick, action_label]
    else:
        var readable_reason: String = reason.replace("_", " ").capitalize()
        _status_label.text = "Tick %d  •  %s — %s" % [world_tick, action_label, readable_reason]

func _build_labels() -> void:
    var title := Label.new()
    title.text = "TICK SURVIVAL LAB — CANONICAL DEMO"
    title.position = Vector2(73, 18)
    title.size = Vector2(494, 30)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 18)
    add_child(title)

    var help := Label.new()
    help.text = "WASD / arrows or touch • turn-based movement"
    help.position = Vector2(73, 578)
    help.size = Vector2(494, 26)
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help.add_theme_font_size_override("font_size", 14)
    add_child(help)

    _status_label = Label.new()
    _status_label.text = "Tick 0  •  Ready"
    _status_label.position = Vector2(73, 604)
    _status_label.size = Vector2(494, 28)
    _status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _status_label.add_theme_font_size_override("font_size", 16)
    add_child(_status_label)

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
