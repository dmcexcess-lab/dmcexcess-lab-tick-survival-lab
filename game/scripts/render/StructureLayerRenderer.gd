extends Node2D
class_name StructureLayerRenderer

const SelectionClass = preload("res://scripts/art/ArtSelection.gd")
const CommandClass = preload("res://scripts/render/StructureDrawCommand.gd")
const ChangeClass = preload("res://scripts/foundation/world/WorldChange.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")

## Canonical structure-only presentation layer.
## Reads WHAT structure occupancy + Door State + ArtCatalog; mutates no simulation state.

signal redraw_requested(reason: StringName)

const MAX_DIAGNOSTIC_REASONS: int = 64
const DIAGNOSTIC_FILL := Color(0.92, 0.18, 0.02, 1.0)
const DIAGNOSTIC_LINE := Color(1.0, 0.95, 0.72, 1.0)

var _world: WorldState = null
var _catalog: ArtCatalog = null
var _door_state: DoorStateStore = null
var _visible_origin: Vector2i = Vector2i.ZERO
var _visible_size: Vector2i = Vector2i.ZERO
var _cell_pixels: float = 0.0
var _view_valid: bool = false
var _texture_cache: Dictionary = {}
var _diagnostic_reasons: Dictionary = {}

func configure(world_state: WorldState, art_catalog: ArtCatalog, door_state: DoorStateStore) -> bool:
    if world_state == null or art_catalog == null or door_state == null:
        return false
    _disconnect_world_signals()
    _disconnect_door_signals()
    _world = world_state
    _catalog = art_catalog
    _door_state = door_state
    _texture_cache.clear()
    _diagnostic_reasons.clear()
    _connect_world_signals()
    _connect_door_signals()
    _request_redraw(&"configured")
    return true

func is_configured() -> bool:
    return _world != null and _catalog != null and _door_state != null

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

func plan_visible_commands() -> Array[StructureDrawCommand]:
    var commands: Array[StructureDrawCommand] = []
    if not is_configured() or not _view_valid:
        return commands

    for local_y in range(_visible_size.y):
        for local_x in range(_visible_size.x):
            var cell := _visible_origin + Vector2i(local_x, local_y)
            var entity_ids: Array[String] = _world.entities_at(cell, Layers.Channel.STRUCTURE)
            if entity_ids.is_empty():
                continue
            entity_ids.sort()
            var destination := Rect2(
                Vector2(float(local_x) * _cell_pixels, float(local_y) * _cell_pixels),
                Vector2(_cell_pixels, _cell_pixels)
            )
            if entity_ids.size() != 1:
                commands.append(_diagnostic_command(
                    cell,
                    destination,
                    entity_ids[0],
                    &"",
                    CommandClass.KIND_UNKNOWN,
                    -1,
                    "multiple_structure_occupants"
                ))
                continue
            commands.append(_plan_entity_cell(cell, destination, entity_ids[0]))
    return commands

func _draw() -> void:
    if not is_configured() or not _view_valid:
        return
    var commands: Array[StructureDrawCommand] = plan_visible_commands()
    for command: StructureDrawCommand in commands:
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

func _plan_entity_cell(cell: Vector2i, destination: Rect2, entity_id: String) -> StructureDrawCommand:
    var entity: WorldEntityRecord = _world.entity(entity_id)
    if entity == null:
        return _diagnostic_command(cell, destination, entity_id, &"", CommandClass.KIND_UNKNOWN, -1, "structure_entity_missing")

    var placement: WorldPlacement = _world.placement(entity_id)
    if placement == null:
        return _diagnostic_command(cell, destination, entity_id, entity.semantic_type, CommandClass.KIND_UNKNOWN, -1, "structure_placement_missing")
    if placement.channel != Layers.Channel.STRUCTURE:
        return _diagnostic_command(cell, destination, entity_id, entity.semantic_type, CommandClass.KIND_UNKNOWN, placement.structure_axis, "structure_channel_invalid")
    if cell not in placement.world_cells():
        return _diagnostic_command(cell, destination, entity_id, entity.semantic_type, CommandClass.KIND_UNKNOWN, placement.structure_axis, "structure_occupancy_mismatch")
    if not StructureGeometry.is_valid_axis(placement.structure_axis):
        return _diagnostic_command(cell, destination, entity_id, entity.semantic_type, CommandClass.KIND_UNKNOWN, placement.structure_axis, "structure_axis_invalid")

    var kind: StringName = _kind_for_semantic(entity.semantic_type)
    if kind == CommandClass.KIND_UNKNOWN:
        return _diagnostic_command(cell, destination, entity_id, entity.semantic_type, kind, placement.structure_axis, "structure_semantic_unclassified")

    var selection: ArtSelection = null
    match kind:
        CommandClass.KIND_WALL:
            selection = _catalog.resolve_wall(entity.semantic_type)
        CommandClass.KIND_DOOR:
            var current_state: StringName = _door_state.state(entity_id)
            if current_state == DoorValue.OPEN:
                selection = _catalog.resolve_door(entity.semantic_type, true)
            elif current_state == DoorValue.CLOSED:
                selection = _catalog.resolve_door(entity.semantic_type, false)
            else:
                selection = SelectionClass.unknown(entity.semantic_type, "door_state_unknown")
        CommandClass.KIND_WINDOW:
            selection = _catalog.resolve_window(entity.semantic_type)
        _:
            selection = SelectionClass.unknown(entity.semantic_type, "structure_semantic_unclassified")

    return CommandClass.new(
        cell,
        destination,
        entity_id,
        entity.semantic_type,
        kind,
        placement.structure_axis,
        selection
    )

func _diagnostic_command(
    cell: Vector2i,
    destination: Rect2,
    entity_id: String,
    semantic_type: StringName,
    kind: StringName,
    structure_axis: int,
    reason: String
) -> StructureDrawCommand:
    return CommandClass.new(
        cell,
        destination,
        entity_id,
        semantic_type,
        kind,
        structure_axis,
        SelectionClass.unknown(semantic_type, reason)
    )

func _kind_for_semantic(semantic_type: StringName) -> StringName:
    var raw: String = String(semantic_type).strip_edges()
    if raw.begins_with("wall.") and raw.length() > 5:
        return CommandClass.KIND_WALL
    if raw.begins_with("door.") and raw.length() > 5:
        return CommandClass.KIND_DOOR
    if raw.begins_with("window.") and raw.length() > 7:
        return CommandClass.KIND_WINDOW
    return CommandClass.KIND_UNKNOWN

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
        normalized = "unknown_structure_diagnostic"
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

func _connect_door_signals() -> void:
    if _door_state == null:
        return
    var enrolled_callable := Callable(self, "_on_door_enrolled")
    var removed_callable := Callable(self, "_on_door_removed")
    var changed_callable := Callable(self, "_on_door_state_changed")
    var reset_callable := Callable(self, "_on_door_state_reset")
    if not _door_state.door_enrolled.is_connected(enrolled_callable):
        _door_state.door_enrolled.connect(enrolled_callable)
    if not _door_state.door_removed.is_connected(removed_callable):
        _door_state.door_removed.connect(removed_callable)
    if not _door_state.door_state_changed.is_connected(changed_callable):
        _door_state.door_state_changed.connect(changed_callable)
    if not _door_state.door_state_reset.is_connected(reset_callable):
        _door_state.door_state_reset.connect(reset_callable)

func _disconnect_door_signals() -> void:
    if _door_state == null:
        return
    var enrolled_callable := Callable(self, "_on_door_enrolled")
    var removed_callable := Callable(self, "_on_door_removed")
    var changed_callable := Callable(self, "_on_door_state_changed")
    var reset_callable := Callable(self, "_on_door_state_reset")
    if _door_state.door_enrolled.is_connected(enrolled_callable):
        _door_state.door_enrolled.disconnect(enrolled_callable)
    if _door_state.door_removed.is_connected(removed_callable):
        _door_state.door_removed.disconnect(removed_callable)
    if _door_state.door_state_changed.is_connected(changed_callable):
        _door_state.door_state_changed.disconnect(changed_callable)
    if _door_state.door_state_reset.is_connected(reset_callable):
        _door_state.door_state_reset.disconnect(reset_callable)

func _on_world_changed(change: WorldChange) -> void:
    if change == null or not _view_valid:
        return
    match change.kind:
        ChangeClass.Kind.TERRAIN_SET, ChangeClass.Kind.TERRAIN_REMOVED, ChangeClass.Kind.ENTITY_CREATED:
            return
        ChangeClass.Kind.ENTITY_REMOVED:
            if _cells_touch_visible(change.before_cells):
                _request_redraw(&"structure_removed")
        ChangeClass.Kind.PLACEMENT_REMOVED:
            if _cells_touch_visible(change.before_cells):
                _request_redraw(&"structure_placement_changed")
        ChangeClass.Kind.PLACEMENT_SET:
            var placement: WorldPlacement = _world.placement(change.entity_id)
            if placement != null and placement.channel == Layers.Channel.STRUCTURE and _cells_touch_visible(change.after_cells):
                _request_redraw(&"structure_placement_changed")
                return
            if not change.before_cells.is_empty() and _cells_touch_visible(change.before_cells):
                _request_redraw(&"structure_placement_changed")
        _:
            return

func _on_world_reset() -> void:
    _texture_cache.clear()
    _diagnostic_reasons.clear()
    _request_redraw(&"world_reset")

func _on_door_enrolled(door_id: String, _state_value: StringName, _version: int) -> void:
    _request_visible_door_redraw(door_id)

func _on_door_removed(door_id: String, _previous_state: StringName, _version: int) -> void:
    _request_visible_door_redraw(door_id)

func _on_door_state_changed(door_id: String, _previous_state: StringName, _new_state: StringName, _version: int) -> void:
    _request_visible_door_redraw(door_id)

func _on_door_state_reset() -> void:
    if _view_valid:
        _request_redraw(&"door_state_reset")

func _request_visible_door_redraw(door_id: String) -> void:
    if _entity_is_visible_structure(door_id):
        _request_redraw(&"door_state_changed")

func _entity_is_visible_structure(entity_id: String) -> bool:
    if _world == null or not _view_valid:
        return false
    var placement: WorldPlacement = _world.placement(entity_id)
    if placement == null or placement.channel != Layers.Channel.STRUCTURE:
        return false
    return _cells_touch_visible(placement.world_cells())

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

func _request_redraw(reason: StringName) -> void:
    redraw_requested.emit(reason)
    queue_redraw()
