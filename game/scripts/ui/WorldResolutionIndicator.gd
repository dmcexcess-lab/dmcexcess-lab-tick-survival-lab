extends CanvasLayer
class_name WorldResolutionIndicator

## Presentation-only explanation for pauses that already exist in the simulation.
## WHEN remains authoritative for decision timing; streaming remains authoritative for
## technical region changes. This layer owns no gameplay state and creates no new turn.

const ZOMBIES_TEXT: String = "ZOMBIES NEARBY"
const LOADING_TEXT: String = "LOADING"
const LABEL_SIZE := Vector2(190.0, 38.0)
const LABEL_POSITION := Vector2(426.0, 176.0)
const FONT_SIZE: int = 16

var _kernel: TickKernel = null
var _infected_cohort: ActiveInfectedCohortService = null
var _streaming: WorldStreamingCoordinator = null
var _label: Label = null
var _loading_visible: bool = false
var _loading_generation: int = 0
var _configured: bool = false

func _ready() -> void:
    layer = 35
    _ensure_ui()
    _refresh()

func configure(
    kernel: TickKernel,
    infected_cohort: ActiveInfectedCohortService,
    streaming: WorldStreamingCoordinator
) -> bool:
    if kernel == null or infected_cohort == null or streaming == null:
        return false
    if not infected_cohort.is_configured() or not streaming.is_ready():
        return false
    _kernel = kernel
    _infected_cohort = infected_cohort
    _streaming = streaming
    _ensure_ui()
    _connect_signals()
    _configured = true
    _refresh()
    return true

func is_configured() -> bool:
    return _configured and _kernel != null and _infected_cohort != null and _streaming != null

func current_text() -> String:
    _ensure_ui()
    return "" if _label == null else _label.text

func indicator_visible() -> bool:
    _ensure_ui()
    return _label != null and _label.visible

func presentation_snapshot() -> Dictionary:
    return {
        "configured": is_configured(),
        "visible": indicator_visible(),
        "text": current_text(),
        "loading": _loading_visible,
        "decision_paused": true if _kernel == null else _kernel.is_decision_paused(),
        "hard_paused": false if _kernel == null else _kernel.is_hard_paused(),
        "active_infected_count": 0 if _infected_cohort == null else _infected_cohort.active_actor_ids().size(),
    }

func _connect_signals() -> void:
    var kernel_changed := Callable(self, "_on_kernel_changed")
    for signal_value: Signal in [
        _kernel.action_started,
        _kernel.action_finished,
        _kernel.decision_required,
        _kernel.hard_pause_changed,
        _kernel.timing_state_reset,
    ]:
        if not signal_value.is_connected(kernel_changed):
            signal_value.connect(kernel_changed)

    var cohort_changed := Callable(self, "_on_active_members_changed")
    if not _infected_cohort.active_members_changed.is_connected(cohort_changed):
        _infected_cohort.active_members_changed.connect(cohort_changed)

    var regions_changed := Callable(self, "_on_active_regions_changed")
    if not _streaming.active_regions_changed.is_connected(regions_changed):
        _streaming.active_regions_changed.connect(regions_changed)

func _on_kernel_changed(_a: Variant = null, _b: Variant = null) -> void:
    _refresh()

func _on_active_members_changed(_active_actor_ids: Variant) -> void:
    _refresh()

func _on_active_regions_changed(activated: Variant, deactivated: Variant) -> void:
    var activated_count: int = activated.size() if typeof(activated) == TYPE_ARRAY else 0
    var deactivated_count: int = deactivated.size() if typeof(deactivated) == TYPE_ARRAY else 0
    if activated_count <= 0 and deactivated_count <= 0:
        return
    _show_loading_pulse()

func _show_loading_pulse() -> void:
    if not is_inside_tree():
        return
    _loading_generation += 1
    var generation: int = _loading_generation
    _loading_visible = true
    _refresh()
    _clear_loading_after_presented_frame(generation)

func _clear_loading_after_presented_frame(generation: int) -> void:
    await get_tree().process_frame
    if generation != _loading_generation:
        return
    _loading_visible = false
    _refresh()

func _refresh() -> void:
    _ensure_ui()
    if _label == null:
        return

    var next_text: String = ""
    if _loading_visible:
        next_text = LOADING_TEXT
    elif _kernel != null and _infected_cohort != null \
        and not _kernel.is_hard_paused() \
        and not _kernel.is_decision_paused() \
        and not _infected_cohort.active_actor_ids().is_empty():
        next_text = ZOMBIES_TEXT

    _label.text = next_text
    _label.visible = not next_text.is_empty()

func _ensure_ui() -> void:
    if _label != null:
        return
    _label = Label.new()
    _label.name = "ResolutionLabel"
    _label.position = LABEL_POSITION
    _label.size = LABEL_SIZE
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _label.focus_mode = Control.FOCUS_NONE
    _label.add_theme_font_size_override("font_size", FONT_SIZE)
    _label.add_theme_constant_override("outline_size", 6)
    _label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
    _label.visible = false
    add_child(_label)
