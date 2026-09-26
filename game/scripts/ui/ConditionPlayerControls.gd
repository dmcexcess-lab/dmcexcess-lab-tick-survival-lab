extends CanvasLayer
class_name ConditionPlayerControls

## Compact touch-first player surface for real System 34 sustainment actions.
## EAT/DRINK consume the first matching real carried item. TAP succeeds only beside
## a real powered potable fixture. REST/SLEEP are committed WHEN actions.

var _actions: SurvivorSustainmentActionService = null
var _kernel: TickKernel = null
var _actor_id: String = ""
var _status: Label = null
var _buttons: Array[Button] = []

func _ready() -> void:
    layer = 21
    _build_ui()

func configure(actions: SurvivorSustainmentActionService, kernel: TickKernel, actor_id: String) -> bool:
    var key: String = actor_id.strip_edges()
    if actions == null or not actions.is_ready() or kernel == null or key.is_empty():
        return false
    _actions = actions
    _kernel = kernel
    _actor_id = key
    _build_ui()
    return true

func set_enabled(enabled: bool) -> void:
    _build_ui()
    for button: Button in _buttons:
        button.disabled = not enabled

func status_text() -> String:
    return "" if _status == null else _status.text

func _build_ui() -> void:
    if _status != null:
        return
    var panel := PanelContainer.new()
    panel.name = "SurvivalActionPanel"
    panel.position = Vector2(41, 576)
    panel.size = Vector2(558, 56)
    add_child(panel)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 1)
    panel.add_child(box)

    _status = Label.new()
    _status.name = "SurvivalStatus"
    _status.text = "SURVIVAL"
    _status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _status.add_theme_font_size_override("font_size", 9)
    box.add_child(_status)

    var row := HBoxContainer.new()
    row.name = "SurvivalActionRow"
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 3)
    box.add_child(row)

    _add_button(row, "EAT", "EatButton", Callable(self, "_eat"))
    _add_button(row, "DRINK", "DrinkButton", Callable(self, "_drink"))
    _add_button(row, "TAP", "TapButton", Callable(self, "_tap"))
    _add_button(row, "REST", "RestButton", Callable(self, "_rest"))
    _add_button(row, "SLEEP", "SleepButton", Callable(self, "_sleep"))

func _add_button(parent: HBoxContainer, text_value: String, node_name: String, callback: Callable) -> void:
    var button := Button.new()
    button.name = node_name
    button.text = text_value
    button.focus_mode = Control.FOCUS_NONE
    button.custom_minimum_size = Vector2(104, 34)
    button.add_theme_font_size_override("font_size", 13)
    button.pressed.connect(callback)
    parent.add_child(button)
    _buttons.append(button)

func _eat() -> void:
    _resolve(_actions.begin_first_consumable(_actor_id, &"eat"), "no edible item")

func _drink() -> void:
    _resolve(_actions.begin_first_consumable(_actor_id, &"drink"), "no drink carried")

func _tap() -> void:
    _resolve(_actions.begin_tap_drink(_actor_id), "no working tap")

func _rest() -> void:
    _resolve(_actions.begin_rest(_actor_id), "cannot rest now")

func _sleep() -> void:
    _resolve(_actions.begin_sleep(_actor_id), "cannot sleep now")

func _resolve(serial: int, failure_text: String) -> void:
    if _kernel == null or _kernel.is_hard_paused():
        _status.text = "SURVIVAL — paused"
        return
    if serial <= 0:
        _status.text = "SURVIVAL — %s" % failure_text
        return
    set_enabled(false)
    _kernel.run_until_stop()
    set_enabled(true)
    _status.text = "SURVIVAL — action complete"
