extends Node2D
class_name PropForegroundLayerRenderer

## System-07B foreground/overhang pass.
## It owns no WHAT dependency and performs no entity discovery. It consumes the
## already-cached stable-entity plans produced by PropLayerRenderer.

var _source: PropLayerRenderer = null
var _texture_cache: Dictionary = {}

func configure(source_renderer: PropLayerRenderer) -> bool:
    if source_renderer == null:
        return false
    _disconnect_source()
    _source = source_renderer
    var redraw_callable := Callable(self, "_on_source_redraw_requested")
    if not _source.redraw_requested.is_connected(redraw_callable):
        _source.redraw_requested.connect(redraw_callable)
    _texture_cache.clear()
    queue_redraw()
    return true

func is_configured() -> bool:
    return _source != null

func planned_command_count() -> int:
    if _source == null:
        return 0
    return _source.foreground_command_count()

func _draw() -> void:
    if _source == null or not _source.is_configured() or not _source.has_valid_view():
        return
    for command: PropDrawCommand in _source.plan_visible_commands():
        if command.is_diagnostic() or not command.has_foreground():
            continue
        var texture: Texture2D = _texture_for_selection(command.foreground_selection)
        if texture == null:
            continue
        _draw_selection(
            texture,
            command.foreground_selection,
            command.destination,
            command.pivot_screen,
            command.quarter_turns
        )

func _texture_for_selection(selection: ArtSelection) -> Texture2D:
    if selection == null or not selection.is_found() or selection.source == null:
        return null
    var path: String = selection.source.texture_path
    if path.is_empty():
        return null
    if _texture_cache.has(path):
        return _texture_cache[path] as Texture2D
    var loaded: Resource = ResourceLoader.load(path)
    var texture := loaded as Texture2D
    if texture != null:
        _texture_cache[path] = texture
    return texture

func _draw_selection(
    texture: Texture2D,
    selection: ArtSelection,
    destination: Rect2,
    pivot_screen: Vector2,
    quarter_turns: int
) -> bool:
    if texture == null or selection == null or not selection.is_found():
        return false
    var turns: int = ((quarter_turns % 4) + 4) % 4
    var target: Rect2 = destination
    if turns != 0:
        draw_set_transform(pivot_screen, float(turns) * PI * 0.5, Vector2.ONE)
        target = Rect2(destination.position - pivot_screen, destination.size)

    var drawn: bool = false
    if selection.is_atlas_region():
        draw_texture_rect_region(texture, target, selection.region(), Color.WHITE, false, true)
        drawn = true
    elif selection.source != null and not selection.source.atlas:
        draw_texture_rect(texture, target, false, Color.WHITE, false)
        drawn = true

    if turns != 0:
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    return drawn

func _on_source_redraw_requested(_reason: StringName) -> void:
    queue_redraw()

func _disconnect_source() -> void:
    if _source == null:
        return
    var redraw_callable := Callable(self, "_on_source_redraw_requested")
    if _source.redraw_requested.is_connected(redraw_callable):
        _source.redraw_requested.disconnect(redraw_callable)
