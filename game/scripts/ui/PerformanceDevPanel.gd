extends CanvasLayer
class_name PerformanceDevPanel

const Telemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")
const REFRESH_SECONDS: float = 0.5

var _label: Label = null
var _accumulator: float = 0.0

func _ready() -> void:
    layer = 1000
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)
    var panel := PanelContainer.new()
    panel.anchor_left = 1.0
    panel.anchor_right = 1.0
    panel.offset_left = -226.0
    panel.offset_right = -8.0
    panel.offset_top = 158.0
    panel.offset_bottom = 304.0
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(panel)
    _label = Label.new()
    _label.add_theme_font_size_override("font_size", 11)
    _label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(_label)
    _refresh_text()

func _process(delta: float) -> void:
    _accumulator += maxf(delta, 0.0)
    if _accumulator < REFRESH_SECONDS:
        return
    _accumulator = fmod(_accumulator, REFRESH_SECONDS)
    _refresh_text()

func _refresh_text() -> void:
    if _label == null:
        return
    var snapshot: Dictionary = Telemetry.snapshot()
    var timings: Dictionary = snapshot.get("timings", {})
    var values: Dictionary = snapshot.get("values", {})
    var batch: Dictionary = snapshot.get("last_batch", {})
    var lines: PackedStringArray = PackedStringArray()
    lines.append("PERF DEV  last / max ms")
    lines.append(_timing_line("STREAM", timings.get("stream_update", {})))
    lines.append(_timing_line("LIGHT SIM", timings.get("lighting_rebuild", {})))
    lines.append(_timing_line("LIGHT DRAW", timings.get("lighting_draw", {})))
    lines.append(_timing_line("VISION", timings.get("perception_recompute", {})))
    lines.append(_timing_line("INTERACT", timings.get("interaction_query", {})))
    lines.append(_timing_line("WEATHER", timings.get("weather_draw", {})))
    lines.append(_timing_line("SKY MASK", timings.get("sky_exposure_rebuild", {})))
    lines.append("LIGHT geo %d draw %d" % [int(values.get("lighting_geometry_rebuilds", 0)), int(values.get("lighting_draws", 0))])
    lines.append("VISION %d INT %d" % [int(values.get("perception_recomputes", 0)), int(values.get("interaction_queries", 0))])
    lines.append("BATCH %s" % ("--" if batch.is_empty() else "%d changes -> 1" % int(batch.get("change_count", 0))))
    _label.text = "\n".join(lines)

static func _timing_line(name: String, value: Variant) -> String:
    var entry: Dictionary = value if typeof(value) == TYPE_DICTIONARY else {}
    return "%s %.2f / %.2f" % [
        name,
        float(int(entry.get("last_usec", 0))) / 1000.0,
        float(int(entry.get("max_usec", 0))) / 1000.0,
    ]
