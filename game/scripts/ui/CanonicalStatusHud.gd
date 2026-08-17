extends CanvasLayer
class_name CanonicalStatusHud

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")

## Compact canonical HUD. Presentation only: reads query results and WHEN tick.

const PANEL_POSITION := Vector2(70, 568)
const PANEL_SIZE := Vector2(500, 64)
const LINE_HEIGHT: float = 15.0
const FONT_SIZE: int = 12

var _kernel: TickKernel = null
var _status_query: ActorStatusSummaryQuery = null
var _inspection_query: FacingInspectionQuery = null
var _actor_id: String = ""
var _action_text: String = "Ready"
var _panel: Panel = null
var _labels: Array[Label] = []
var _last_presentation: Dictionary = {}

func _ready() -> void:
    layer = 21
    _ensure_ui()

func configure(
    kernel: TickKernel,
    status_query: ActorStatusSummaryQuery,
    inspection_query: FacingInspectionQuery,
    actor_id: String
) -> bool:
    if kernel == null or status_query == null or inspection_query == null or actor_id.strip_edges().is_empty():
        return false
    if not status_query.is_ready() or not inspection_query.is_ready():
        return false
    _kernel = kernel
    _status_query = status_query
    _inspection_query = inspection_query
    _actor_id = actor_id.strip_edges()
    _ensure_ui()
    refresh()
    return true

func is_configured() -> bool:
    return _kernel != null and _status_query != null and _inspection_query != null and not _actor_id.is_empty()

func present_action_result(
    intent: StringName,
    success: bool,
    reason: String,
    world_tick: int
) -> void:
    var action_label: String = Intents.label(intent)
    if success:
        _action_text = action_label
    else:
        var readable_reason: String = reason.replace("_", " ").capitalize()
        _action_text = "%s — %s" % [action_label, readable_reason]
    refresh()

func refresh() -> void:
    if not is_configured():
        return
    _ensure_ui()

    var status: Dictionary = _status_query.query(_actor_id)
    var inspection: Dictionary = _inspection_query.query(_actor_id)
    var facing_text: String = String(inspection.get("facing_label", "UNKNOWN"))
    var looking_text: String = "Unknown"
    if bool(inspection.get("ok", false)):
        looking_text = String(inspection.get("label", "Unknown"))

    var line_one: String = "Tick %d  •  %s  •  Facing %s" % [
        _kernel.world_tick(),
        _action_text,
        facing_text,
    ]
    var line_two: String = "Looking at: %s" % looking_text
    var line_three: String = "Status unavailable"
    var line_four: String = String(status.get("reason", "unknown"))

    if bool(status.get("ok", false)):
        line_three = "HP %d/%d  •  Fatigue %d  •  Hunger %d  •  Thirst %d  •  Sleep pressure %d" % [
            int(status.get("current_hp", -1)),
            int(status.get("max_hp", -1)),
            int(status.get("fatigue", -1)),
            int(status.get("hunger", -1)),
            int(status.get("thirst", -1)),
            int(status.get("sleep_pressure", -1)),
        ]
        var moodlet_labels: Array = status.get("moodlet_labels", [])
        var moodlet_text: String = "No active moodlets"
        if not moodlet_labels.is_empty():
            moodlet_text = _join_labels(moodlet_labels)
        line_four = "Carry %s / %s kg  •  %s" % [
            _kg_text(int(status.get("carry_weight_grams", 0))),
            _kg_text(int(status.get("carry_capacity_grams", 0))),
            moodlet_text,
        ]

    _set_lines([line_one, line_two, line_three, line_four])
    _last_presentation = {
        "line_1": line_one,
        "line_2": line_two,
        "line_3": line_three,
        "line_4": line_four,
        "status": status.duplicate(true),
        "inspection": inspection.duplicate(true),
    }

func presentation_snapshot() -> Dictionary:
    return _last_presentation.duplicate(true)

func _ensure_ui() -> void:
    if _panel != null:
        return
    _panel = Panel.new()
    _panel.position = PANEL_POSITION
    _panel.size = PANEL_SIZE
    _panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_panel)

    for index in range(4):
        var label := Label.new()
        label.position = PANEL_POSITION + Vector2(0, float(index) * LINE_HEIGHT + 1.0)
        label.size = Vector2(PANEL_SIZE.x, LINE_HEIGHT)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        label.add_theme_font_size_override("font_size", FONT_SIZE)
        _labels.append(label)
        add_child(label)

func _set_lines(lines: Array) -> void:
    for index in range(mini(lines.size(), _labels.size())):
        _labels[index].text = String(lines[index])

static func _join_labels(values: Array) -> String:
    var parts := PackedStringArray()
    for value: Variant in values:
        parts.append(String(value))
    return ", ".join(parts)

static func _kg_text(grams: int) -> String:
    if grams < 0:
        return "?"
    return "%.1f" % (float(grams) / 1000.0)
