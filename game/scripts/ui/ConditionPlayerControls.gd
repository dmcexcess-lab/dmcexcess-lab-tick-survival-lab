extends CanvasLayer
class_name ConditionPlayerControls

## Compact Candidate-001 player surface for real System 34 actions.
## EAT/DRINK consume the first matching real carried item. TAP succeeds only beside
## a real water fixture with truthful System-33 service. REST/SLEEP advance WHEN.

var _actions: SurvivorSustainmentActionService = null
var _kernel: TickKernel = null
var _actor_id: String = ""
var _status: Label = null

func _ready() -> void:
    layer = 34
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

func _build_ui() -> void:
    if _status != null:
        return
    var panel := PanelContainer.new()
    panel.position = Vector2(8, 66)
    panel.size = Vector2(326, 78)
    add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 2)
    panel.add_child(box)
    _status = Label.new()
    _status.text = "SURVIVAL"
    _status.add_theme_font_size_override("font_size", 10)
    box.add_child(_status)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 2)
    box.add_child(row)
    _add_button(row, "EAT", Callable(self, "_eat"))
    _add_button(row, "DRINK", Callable(self, "_drink"))
    _add_button(row, "TAP", Callable(self, "_tap"))
    _add_button(row, "REST", Callable(self, "_rest"))
    _add_button(row, "SLEEP", Callable(self, "_sleep"))

func _add_button(parent: HBoxContainer, text_value: String, callback: Callable) -> void:
    var button := Button.new()
    button.text = text_value
    button.focus_mode = Control.FOCUS_NONE
    button.custom_minimum_size = Vector2(60, 26)
    button.add_theme_font_size_override("font_size", 9)
    button.pressed.connect(callback)
    parent.add_child(button)

func _eat() -> void:
    _resolve(_actions.begin_first_consumable(_actor_id, &"eat"), "No edible carried item")

func _drink() -> void:
    _resolve(_actions.begin_first_consumable(_actor_id, &"drink"), "No drink carried")

func _tap() -> void:
    _resolve(_actions.begin_tap_drink(_actor_id), "No working water fixture in reach")

func _rest() -> void:
    _resolve(_actions.begin_rest(_actor_id), "Cannot rest now")

func _sleep() -> void:
    _resolve(_actions.begin_sleep(_actor_id), "Cannot sleep now")

func _resolve(serial: int, failure_text: String) -> void:
    if _kernel == null or _kernel.is_hard_paused():
        if _status != null:
            _status.text = "SURVIVAL — paused"
        return
    if serial <= 0:
        if _status != null:
            _status.text = "SURVIVAL — %s" % failure_text
        return
    _kernel.run_until_stop()
    if _status != null:
        _status.text = "SURVIVAL — action complete"
