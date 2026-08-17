extends Node2D
class_name PropLayerRenderer

const SelectionClass = preload("res://scripts/art/ArtSelection.gd")
const CommandClass = preload("res://scripts/render/PropDrawCommand.gd")
const ChangeClass = preload("res://scripts/foundation/world/WorldChange.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

## Canonical prop/fixture/vegetation presentation layer.
## Reads WHAT OBJECT occupancy + ArtCatalog; mutates no simulation state.

signal redraw_requested(reason: StringName)

const MAX_DIAGNOSTIC_REASONS: int = 64
const DIAGNOSTIC_FILL := Color(0.78, 0.08, 0.72, 1.0)
const DIAGNOSTIC_LINE := Color(1.0, 0.92, 1.0, 1.0)

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

func plan_visible_commands() -> Array[PropDrawCommand]:
    var commands: Array[PropDrawCommand] = []
    if not is_configured() or not _view_valid:
        return commands

    var first_seen_cells: Dictionary = {}
    for local_y in range(_visible_size.y):
        for local_x in range(_visible_size.x):
            var cell := _visible_origin + Vector2i(local_x, local_y)
            var entity_ids: Array[String] = _world.entities_at(cell, Layers.Channel.OBJECT)
            if entity_ids.is_empty():
                continue
            entity_ids.sort()
            for entity_id: String in entity_ids:
                if not first_seen_cells.has(entity_id):
                    first_seen_cells[entity_id] = cell

    var entity_ids: Array[String] = []
    for value: Variant in first_seen_cells.keys():
        entity_ids.append(String(value))
    entity_ids.sort()

    for entity_id: String in entity_ids:
        var observed_cell: Vector2i = first_seen_cells[entity_id]
        commands.append(_plan_entity(entity_id, observed_cell))

    commands.sort_custom(_command_less)
    return commands

func _draw() -> void:
    if not is_configured() or not _view_valid:
        return
    var commands: Array[PropDrawCommand] = plan_visible_commands()
    for command: PropDrawCommand in commands:
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

func _plan_entity(entity_id: String, observed_cell: Vector2i) -> PropDrawCommand:
    var fallback_destination: Rect2 = _destination_for_anchor(observed_cell)
    var observed_cells: Array[Vector2i] = _single_cell_list(observed_cell)
    var entity: WorldEntityRecord = _world.entity(entity_id)
    if entity == null:
        return _diagnostic_command(
            entity_id,
            &"",
            CommandClass.FAMILY_UNKNOWN,
            observed_cell,
            -1,
            null,
            observed_cells,
            fallback_destination,
            "object_entity_missing"
        )

    var placement: WorldPlacement = _world.placement(entity_id)
    if placement == null:
        return _diagnostic_command(
            entity_id,
            entity.semantic_type,
            _family_for_semantic(entity.semantic_type),
            observed_cell,
            -1,
            null,
            observed_cells,
            fallback_destination,
            "object_placement_missing"
        )

    var occupied_cells: Array[Vector2i] = placement.world_cells()
    var destination: Rect2 = _destination_for_anchor(placement.anchor)
    var family: StringName = _family_for_semantic(entity.semantic_type)

    if placement.channel != Layers.Channel.OBJECT:
        return _diagnostic_command(
            entity_id,
            entity.semantic_type,
            family,
            placement.anchor,
            placement.facing,
            placement.footprint,
            occupied_cells,
            destination,
            "object_channel_invalid"
        )
    if observed_cell not in occupied_cells:
        return _diagnostic_command(
            entity_id,
            entity.semantic_type,
            family,
            placement.anchor,
            placement.facing,
            placement.footprint,
            occupied_cells,
            destination,
            "object_occupancy_mismatch"
        )
    if family == CommandClass.FAMILY_UNKNOWN:
        return _diagnostic_command(
            entity_id,
            entity.semantic_type,
            family,
            placement.anchor,
            placement.facing,
            placement.footprint,
            occupied_cells,
            destination,
            "prop_semantic_unclassified"
        )

    var selection: ArtSelection = _catalog.resolve_prop(entity.semantic_type)
    return CommandClass.new(
        entity_id,
        entity.semantic_type,
        family,
        placement.anchor,
        placement.facing,
        placement.footprint,
        occupied_cells,
        destination,
        selection
    )

func _diagnostic_command(
    entity_id: String,
    semantic_type: StringName,
    family: StringName,
    anchor: Vector2i,
    facing: int,
    footprint: SpatialFootprint,
    occupied_cells: Array[Vector2i],
    destination: Rect2,
    reason: String
) -> PropDrawCommand:
    return CommandClass.new(
        entity_id,
        semantic_type,
        family,
        anchor,
        facing,
        footprint,
        occupied_cells,
        destination,
        SelectionClass.unknown(semantic_type, reason)
    )

func _family_for_semantic(semantic_type: StringName) -> StringName:
    var raw: String = String(semantic_type).strip_edges()
    if raw.begins_with("prop.") and raw.length() > 5:
        return CommandClass.FAMILY_PROP
    if raw.begins_with("fixture.") and raw.length() > 8:
        return CommandClass.FAMILY_FIXTURE
    if raw.begins_with("vegetation.") and raw.length() > 11:
        return CommandClass.FAMILY_VEGETATION
    return CommandClass.FAMILY_UNKNOWN

func _destination_for_anchor(anchor: Vector2i) -> Rect2:
    var local_cell: Vector2i = anchor - _visible_origin
    return Rect2(
        Vector2(float(local_cell.x) * _cell_pixels, float(local_cell.y) * _cell_pixels),
        Vector2(_cell_pixels, _cell_pixels)
    )

func _single_cell_list(cell: Vector2i) -> Array[Vector2i]:
    var values: Array[Vector2i] = []
    values.append(cell)
    return values

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
        normalized = "unknown_prop_diagnostic"
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
    match change.kind:
        ChangeClass.Kind.TERRAIN_SET, ChangeClass.Kind.TERRAIN_REMOVED, ChangeClass.Kind.ENTITY_CREATED:
            return
        ChangeClass.Kind.ENTITY_REMOVED:
            if _cells_touch_visible(change.before_cells):
                _request_redraw(&"object_removed")
        ChangeClass.Kind.PLACEMENT_REMOVED:
            if _cells_touch_visible(change.before_cells):
                _request_redraw(&"object_placement_changed")
        ChangeClass.Kind.PLACEMENT_SET:
            var placement: WorldPlacement = _world.placement(change.entity_id)
            if placement != null and placement.channel == Layers.Channel.OBJECT and _cells_touch_visible(change.after_cells):
                _request_redraw(&"object_placement_changed")
                return
            if not change.before_cells.is_empty() and _cells_touch_visible(change.before_cells):
                _request_redraw(&"object_placement_changed")
        _:
            return

func _on_world_reset() -> void:
    _texture_cache.clear()
    _diagnostic_reasons.clear()
    _request_redraw(&"world_reset")

func _cells_touch_visible(cells: Array[Vector2i]) -> bool:
    for cell: Vector2i in cells:
        if _cell_is_visible(cell):
            return true
    return false

func _cell_is_visible(cell: Vector2i) -> bool:
    if not _view_valid:
        return false
    return (
        cell.x >= _visible_origin.x
        and cell.x < _visible_origin.x + _visible_size.x
        and cell.y >= _visible_origin.y
        and cell.y < _visible_origin.y + _visible_size.y
    )

static func _command_less(a: PropDrawCommand, b: PropDrawCommand) -> bool:
    if a.anchor.y != b.anchor.y:
        return a.anchor.y < b.anchor.y
    if a.anchor.x != b.anchor.x:
        return a.anchor.x < b.anchor.x
    return a.entity_id < b.entity_id

func _request_redraw(reason: StringName) -> void:
    redraw_requested.emit(reason)
    queue_redraw()
