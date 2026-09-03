extends CanvasLayer
class_name ForagePlayerControls

## Compact live surface for the real outdoor forage action. The button only requests
## the action; WHEN, Survival, depletion, environment and WHAT remain authoritative.

var _actions: ForageNearbyActionService = null
var _kernel: TickKernel = null
var _actor_id: String = ""
var _status: Label = null
var _button: Button = null

func _ready() -> void:
    layer = 34
    _build_ui()

func configure(actions: ForageNearbyActionService, kernel: TickKernel, actor_id: String) -> bool:
    var actor: String = actor_id.strip_edges()
    if actions == null or not actions.is_ready() or kernel == null or actor.is_empty():
        return false
    _actions = actions
    _kernel = kernel
    _actor_id = actor
    _build_ui()
    if not _actions.forage_completed.is_connected(_on_forage_completed):
        _actions.forage_completed.connect(_on_forage_completed)
    if not _actions.forage_failed.is_connected(_on_forage_failed):
        _actions.forage_failed.connect(_on_forage_failed)
    if not _actions.forage_canceled.is_connected(_on_forage_canceled):
        _actions.forage_canceled.connect(_on_forage_canceled)
    return true

func _build_ui() -> void:
    if _status != null:
        return
    var panel := PanelContainer.new()
    panel.position = Vector2(340, 66)
    panel.size = Vector2(292, 78)
    add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 3)
    panel.add_child(box)
    _status = Label.new()
    _status.text = "FORAGE — outdoor sticks / stones"
    _status.add_theme_font_size_override("font_size", 10)
    box.add_child(_status)
    _button = Button.new()
    _button.text = "FORAGE NEARBY"
    _button.focus_mode = Control.FOCUS_NONE
    _button.custom_minimum_size = Vector2(272, 30)
    _button.add_theme_font_size_override("font_size", 10)
    _button.pressed.connect(_forage)
    box.add_child(_button)

func _forage() -> void:
    if _actions == null or _kernel == null:
        _status.text = "FORAGE — unavailable"
        return
    if _kernel.is_hard_paused():
        _status.text = "FORAGE — paused"
        return
    var request: Dictionary = _actions.request_forage(_actor_id)
    if not bool(request.get("accepted", false)):
        _status.text = "FORAGE — %s" % _friendly_reason(String(request.get("reason", "blocked")))
        return
    _status.text = "FORAGE — searching..."
    _kernel.run_until_stop()

func _on_forage_completed(actor_id: String, _serial: int, _patch_key: String, _item_ids: Array, semantics: Array) -> void:
    if actor_id != _actor_id:
        return
    var labels: Array[String] = []
    for value: Variant in semantics:
        var semantic: String = String(value)
        labels.append("sturdy stick" if semantic.ends_with("sturdy_stick") else "smooth stone")
    _status.text = "FORAGE — found %s" % ", ".join(labels)

func _on_forage_failed(actor_id: String, _serial: int, _patch_key: String, reason: String, consumed: bool) -> void:
    if actor_id != _actor_id:
        return
    if consumed:
        _status.text = "FORAGE — nothing recovered"
    else:
        _status.text = "FORAGE — %s" % _friendly_reason(reason)

func _on_forage_canceled(actor_id: String, _serial: int, _patch_key: String, _reason: String) -> void:
    if actor_id == _actor_id:
        _status.text = "FORAGE — canceled"

static func _friendly_reason(reason: String) -> String:
    match reason:
        "forage_depleted":
            return "area picked clean"
        "forage_requires_outdoors":
            return "must be outdoors"
        "forage_impossible":
            return "nothing plausible here"
        "forage_unmaterialized":
            return "ground unavailable"
        "actor_busy":
            return "busy"
        _:
            return reason.replace("_", " ")
