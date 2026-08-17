extends Node2D
class_name GroundLayerRenderer

const SelectionClass = preload("res://scripts/art/ArtSelection.gd")
const CommandClass = preload("res://scripts/render/GroundDrawCommand.gd")
const ChangeClass = preload("res://scripts/foundation/world/WorldChange.gd")
const RoadTopology = preload("res://scripts/art/RoadArtTopology.gd")

## Canonical ground-only presentation layer.
## Reads WHAT terrain + ArtCatalog selections; mutates no simulation state.

signal redraw_requested(reason: StringName)

const MAX_DIAGNOSTIC_REASONS: int = 64
const DIAGNOSTIC_FILL := Color(0.82, 0.0, 0.72, 1.0)
const DIAGNOSTIC_LINE := Color(1.0, 0.92, 1.0, 1.0)

const ROAD_LIKE_TOKENS := {
    "road": true,
    "dirt_road": true,
    "road_v": true,
    "road_h": true,
    "road_ne": true,
    "road_es": true,
    "road_sw": true,
    "road_wn": true,
    "road_t_nes": true,
    "road_t_esw": true,
    "road_t_swn": true,
    "road_t_wne": true,
    "road_cross": true,
    "road_end_n": true,
    "road_end_e": true,
    "road_end_s": true,
    "road_end_w": true,
    "road_plain": true,
    "dirt_road_h": true,
    "dirt_road_v": true,
}

var _world: WorldState = null
var _catalog: ArtCatalog = null
var _visible_origin: Vector2i = Vector2i.ZERO
var _visible_size: Vector2i = Vector2i.ZERO
var _cell_pixels: float = 0.0
var _view_valid: bool = false
var _texture_cache: Dictionary = {}
var _diagnostic_reasons: Dictionary = {}

func configure(world_state: WorldState, art_catalog: ArtCatalog) -> bool:
    if world_state == null or art_catalog == null:
        return false
    _disconnect_world_signals()
    _world = world_state
    _catalog = art_catalog
    _texture_cache.clear()
    _diagnostic_reasons.clear()
    _connect_world_signals()
    _request_redraw(&"configured")
    return true

func is_configured() -> bool:
    return _world != null and _catalog != null

func set_visible_window(origin: Vector2i, size_cells: Vector2i, cell_pixels: float) -> bool:
    if size_cells.x <= 0 or size_cells.y <= 0 or cell_pixels <= 0.0:
        return false
    var changed: bool = (
        not _view_valid
        or origin != _visible_origin
        or size_cells != _visible_size
        or not is_equal_approx(cell_pixels, _cell_pixels)
    )
    _visible_origin = origin
    _visible_size = size_cells
    _cell_pixels = cell_pixels
    _view_valid = true
    if changed:
        _request_redraw(&"view_changed")
    return true

func has_valid_view() -> bool:
    return _view_valid

func visible_origin() -> Vector2i:
    return _visible_origin

func visible_size() -> Vector2i:
    return _visible_size

func cell_pixels() -> float:
    return _cell_pixels

func clear_texture_cache() -> void:
    if _texture_cache.is_empty():
        return
    _texture_cache.clear()
    _request_redraw(&"texture_cache_cleared")

func diagnostic_reasons() -> Array[String]:
    var values: Array[String] = []
    for value: Variant in _diagnostic_reasons.keys():
        values.append(String(value))
    values.sort()
    return values

func plan_visible_commands() -> Array[GroundDrawCommand]:
    var commands: Array[GroundDrawCommand] = []
    if not is_configured() or not _view_valid:
        return commands

    for local_y in range(_visible_size.y):
        for local_x in range(_visible_size.x):
            var cell := _visible_origin + Vector2i(local_x, local_y)
            var destination := Rect2(
                Vector2(float(local_x) * _cell_pixels, float(local_y) * _cell_pixels),
                Vector2(_cell_pixels, _cell_pixels)
            )
            var semantic_id: StringName = &""
            var selection: ArtSelection = null
            if not _world.has_terrain(cell):
                selection = SelectionClass.unknown(&"", "terrain_missing")
            else:
                semantic_id = _world.terrain_at(cell)
                selection = _resolve_ground_selection(cell, semantic_id)
            commands.append(CommandClass.new(cell, destination, semantic_id, selection))
    return commands

func _draw() -> void:
    if not is_configured() or not _view_valid:
        return
    var commands: Array[GroundDrawCommand] = plan_visible_commands()
    for command: GroundDrawCommand in commands:
        if command.is_diagnostic():
            _remember_diagnostic(command.diagnostic_reason())
            _draw_diagnostic(command.destination)
            continue
        var selection: ArtSelection = command.selection
        var texture: Texture2D = _texture_for_selection(selection)
        if texture == null:
            _remember_diagnostic("texture_load_failed")
            _draw_diagnostic(command.destination)
            continue
        if selection.is_atlas_region():
            draw_texture_rect_region(
                texture,
                command.destination,
                selection.region(),
                Color.WHITE,
                false,
                true
            )
        elif selection.source != null and not selection.source.atlas:
            draw_texture_rect(texture, command.destination, false, Color.WHITE, false)
        else:
            _remember_diagnostic("selection_not_drawable")
            _draw_diagnostic(command.destination)

func _resolve_ground_selection(cell: Vector2i, semantic_id: StringName) -> ArtSelection:
    var token: String = _leaf_token(semantic_id)
    match token:
        "road":
            return _catalog.resolve_road(_road_mask(cell), &"local")
        "dirt_road":
            return _catalog.resolve_dirt_road(_road_mask(cell))
        "sidewalk":
            return _catalog.resolve_sidewalk(_road_mask(cell))
        _:
            return _catalog.resolve_ground(semantic_id)

func _road_mask(cell: Vector2i) -> int:
    var mask: int = 0
    if _is_road_cell(cell + Vector2i.UP):
        mask |= RoadTopology.ROAD_N
    if _is_road_cell(cell + Vector2i.RIGHT):
        mask |= RoadTopology.ROAD_E
    if _is_road_cell(cell + Vector2i.DOWN):
        mask |= RoadTopology.ROAD_S
    if _is_road_cell(cell + Vector2i.LEFT):
        mask |= RoadTopology.ROAD_W
    return mask

func _is_road_cell(cell: Vector2i) -> bool:
    if _world == null or not _world.has_terrain(cell):
        return false
    return ROAD_LIKE_TOKENS.has(_leaf_token(_world.terrain_at(cell)))

func _leaf_token(value: StringName) -> String:
    var raw: String = String(value).strip_edges()
    if raw.is_empty():
        return ""
    var dot_index: int = raw.rfind(".")
    if dot_index >= 0 and dot_index < raw.length() - 1:
        return raw.substr(dot_index + 1)
    return raw

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

func _draw_diagnostic(rect: Rect2) -> void:
    draw_rect(rect, DIAGNOSTIC_FILL, true)
    draw_line(rect.position, rect.end, DIAGNOSTIC_LINE, 2.0)
    draw_line(
        Vector2(rect.end.x, rect.position.y),
        Vector2(rect.position.x, rect.end.y),
        DIAGNOSTIC_LINE,
        2.0
    )

func _remember_diagnostic(reason: String) -> void:
    var normalized: String = reason.strip_edges()
    if normalized.is_empty():
        normalized = "unknown_ground_diagnostic"
    if _diagnostic_reasons.has(normalized):
        return
    if _diagnostic_reasons.size() >= MAX_DIAGNOSTIC_REASONS:
        return
    _diagnostic_reasons[normalized] = true

func _connect_world_signals() -> void:
    if _world == null:
        return
    var changed_callable := Callable(self, "_on_world_changed")
    var reset_callable := Callable(self, "_on_world_reset")
    if not _world.changed.is_connected(changed_callable):
        _world.changed.connect(changed_callable)
    if not _world.world_reset.is_connected(reset_callable):
        _world.world_reset.connect(reset_callable)

func _disconnect_world_signals() -> void:
    if _world == null:
        return
    var changed_callable := Callable(self, "_on_world_changed")
    var reset_callable := Callable(self, "_on_world_reset")
    if _world.changed.is_connected(changed_callable):
        _world.changed.disconnect(changed_callable)
    if _world.world_reset.is_connected(reset_callable):
        _world.world_reset.disconnect(reset_callable)

func _on_world_changed(change: WorldChange) -> void:
    if change == null or not _view_valid:
        return
    if change.kind != ChangeClass.Kind.TERRAIN_SET and change.kind != ChangeClass.Kind.TERRAIN_REMOVED:
        return
    if _cell_affects_visible_ground(change.terrain_cell):
        _request_redraw(&"terrain_changed")

func _on_world_reset() -> void:
    _texture_cache.clear()
    _diagnostic_reasons.clear()
    _request_redraw(&"world_reset")

func _cell_affects_visible_ground(cell: Vector2i) -> bool:
    if not _view_valid:
        return false
    var min_x: int = _visible_origin.x
    var min_y: int = _visible_origin.y
    var max_x_exclusive: int = min_x + _visible_size.x
    var max_y_exclusive: int = min_y + _visible_size.y

    if cell.x >= min_x and cell.x < max_x_exclusive and cell.y >= min_y and cell.y < max_y_exclusive:
        return true
    if cell.x == min_x - 1 and cell.y >= min_y and cell.y < max_y_exclusive:
        return true
    if cell.x == max_x_exclusive and cell.y >= min_y and cell.y < max_y_exclusive:
        return true
    if cell.y == min_y - 1 and cell.x >= min_x and cell.x < max_x_exclusive:
        return true
    if cell.y == max_y_exclusive and cell.x >= min_x and cell.x < max_x_exclusive:
        return true
    return false

func _request_redraw(reason: StringName) -> void:
    redraw_requested.emit(reason)
    queue_redraw()
