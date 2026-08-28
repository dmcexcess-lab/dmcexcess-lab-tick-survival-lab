extends RefCounted
class_name PropVisualGeometryDescriptor

## Presentation-only geometry for one semantic OBJECT visual.
## WHAT/WHERE footprint remains authoritative and is never inferred from this data.

var visual_id: StringName = &"default"
var base_art_key: StringName = &""
var foreground_art_key: StringName = &""
var draw_span_cells: Vector2i = Vector2i.ONE
var pivot_cells: Vector2 = Vector2(0.5, 0.5)

func _init(
    value_visual_id: StringName = &"default",
    value_base_art_key: StringName = &"",
    value_foreground_art_key: StringName = &"",
    value_draw_span_cells: Vector2i = Vector2i.ONE,
    value_pivot_cells: Vector2 = Vector2(0.5, 0.5)
) -> void:
    visual_id = value_visual_id
    base_art_key = value_base_art_key
    foreground_art_key = value_foreground_art_key
    draw_span_cells = value_draw_span_cells
    pivot_cells = value_pivot_cells

func is_valid() -> bool:
    return (
        not String(visual_id).strip_edges().is_empty()
        and not String(base_art_key).strip_edges().is_empty()
        and draw_span_cells.x >= 1
        and draw_span_cells.y >= 1
        and is_finite(pivot_cells.x)
        and is_finite(pivot_cells.y)
    )

func has_foreground() -> bool:
    return not String(foreground_art_key).strip_edges().is_empty()

func copy() -> PropVisualGeometryDescriptor:
    return PropVisualGeometryDescriptor.new(
        visual_id,
        base_art_key,
        foreground_art_key,
        draw_span_cells,
        pivot_cells
    )
