extends CanvasLayer
class_name DemoMovementControls

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Stance = preload("res://scripts/simulation/actors/locomotion/ActorStance.gd")

## Touch-first demo movement/stance controls.
## Emits semantic intent only; owns no simulation dependency or status presentation.

signal action_intent(intent: StringName)

var _enabled: bool = true
var _buttons: Array[Button] = []
var _stance_button: Button = null
var _locomotion: ActorLocomotionState = null
var _actor_id: String = ""
var _buttons_built: bool = false

func _ready() -> void:
    layer = 20
    _ensure_buttons()
    _refresh_stance_label()

func configure_stance(locomotion_state: ActorLocomotionState, actor_id: String) -> bool:
    if locomotion_state == null or actor_id.strip_edges().is_empty():
        return false
    if not locomotion_state.has_actor(actor_id.strip_edges()):
        return false
    _locomotion = locomotion_state
    _actor_id = actor_id.strip_edges()
    if not _locomotion.stance_changed.is_connected(_on_stance_changed):
        _locomotion.stance_changed.connect(_on_stance_changed)
    _ensure_buttons()
    _refresh_stance_label()
    return true

func set_enabled(enabled: bool) -> void:
    _enabled = enabled
    _ensure_buttons()
    for button: Button in _buttons:
        button.disabled = not enabled

func is_enabled() -> bool:
    return _enabled

func stance_button_text() -> String:
    _ensure_buttons()
    return "" if _stance_button == null else _stance_button.text

func _ensure_buttons() -> void:
    if _buttons_built:
        return
    _buttons_built = true
    _build_buttons()

func _build_buttons() -> void:
    _add_button("FORWARD", Vector2(255, 638), Vector2(130, 52), Intents.FORWARD)
    _add_button("TURN L", Vector2(82, 704), Vector2(132, 56), Intents.TURN_LEFT)
    _add_button("TURN R", Vector2(426, 704), Vector2(132, 56), Intents.TURN_RIGHT)
    _stance_button = _add_button("CROUCH", Vector2(82, 772), Vector2(132, 52), Intents.STANCE_TOGGLE)
    _add_button("BACK", Vector2(255, 772), Vector2(130, 52), Intents.BACKWARD)
    _add_button("RUN", Vector2(426, 772), Vector2(132, 52), Intents.RUN_FORWARD)

func _add_button(
    text_value: String,
    position_value: Vector2,
    size_value: Vector2,
    intent: StringName
) -> Button:
    var button := Button.new()
    button.text = text_value
    button.position = position_value
    button.size = size_value
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 18)
    button.disabled = not _enabled
    button.pressed.connect(_on_button_pressed.bind(intent))
    add_child(button)
    _buttons.append(button)
    return button

func _on_button_pressed(intent: StringName) -> void:
    if not _enabled:
        return
    action_intent.emit(intent)

func _on_stance_changed(actor_id: String, _previous_stance: StringName, _new_stance: StringName, _version: int) -> void:
    if actor_id != _actor_id:
        return
    _refresh_stance_label()

func _refresh_stance_label() -> void:
    if _stance_button == null:
        return
    if _locomotion == null or _actor_id.is_empty():
        _stance_button.text = "CROUCH"
        return
    var current: StringName = _locomotion.stance(_actor_id)
    _stance_button.text = "STAND" if current == Stance.CROUCHED else "CROUCH"
