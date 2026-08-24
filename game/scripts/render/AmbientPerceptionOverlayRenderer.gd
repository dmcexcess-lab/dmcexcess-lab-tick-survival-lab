extends "res://scripts/render/PerceptionOverlayRenderer.gd"
class_name AmbientPerceptionOverlayRenderer

## System 23 presentation extension: remembered environmental snapshots respond to a
## normalized current ambient-light input. Memory contents remain stale observer
## knowledge; only their presentational luminance changes.

const MEMORY_NIGHT_LUMINANCE: float = 0.10
const MEMORY_DAY_LUMINANCE: float = 0.30

var _ambient_light_level: float = 1.0

func set_ambient_light_level(value: float) -> bool:
    if value != value:
        return false
    var normalized: float = clampf(value, 0.0, 1.0)
    if is_equal_approx(normalized, _ambient_light_level):
        return true
    _ambient_light_level = normalized
    _request_redraw(&"ambient_light_changed")
    return true

func ambient_light_level() -> float:
    return _ambient_light_level

func memory_luminance() -> float:
    return lerpf(MEMORY_NIGHT_LUMINANCE, MEMORY_DAY_LUMINANCE, _ambient_light_level)

func memory_modulation() -> Color:
    var luminance: float = memory_luminance()
    return Color(luminance, luminance, luminance, 1.0)

func _draw_remembered_cell(cell: Vector2i, destination: Rect2) -> void:
    var memory: Dictionary = _memory.environment_memory(_observer_id, cell)
    if memory.is_empty():
        return
    var terrain := StringName(String(memory.get("terrain_semantic", "")))
    if String(terrain).strip_edges().is_empty():
        return
    var modulation: Color = memory_modulation()
    var ground_selection: ArtSelection = _resolve_remembered_ground(cell, terrain)
    _draw_selection(ground_selection, destination, modulation)

    var structure_value: Variant = memory.get("structure", {})
    if typeof(structure_value) == TYPE_DICTIONARY:
        var structure: Dictionary = structure_value
        if not structure.is_empty():
            var structure_selection: ArtSelection = _resolve_remembered_structure(structure)
            _draw_selection(structure_selection, destination, modulation)

    var props_value: Variant = memory.get("props", [])
    if typeof(props_value) != TYPE_ARRAY:
        return
    for prop_value: Variant in props_value:
        if typeof(prop_value) != TYPE_DICTIONARY:
            continue
        _draw_remembered_prop(prop_value)

func _draw_remembered_prop(prop: Dictionary) -> void:
    var semantic := StringName(String(prop.get("semantic_type", "")))
    var anchor_value: Variant = prop.get("anchor", null)
    var facing: int = int(prop.get("facing", -1))
    if String(semantic).strip_edges().is_empty() or typeof(anchor_value) != TYPE_VECTOR2I:
        return
    var anchor: Vector2i = anchor_value
    if not _cell_in_view(anchor):
        return
    var selection: ArtSelection = _catalog.resolve_prop(semantic)
    var quarter_turns: int = PropOrientation.quarter_turns(selection, facing)
    _draw_selection(selection, _cell_rect(anchor), memory_modulation(), quarter_turns)
