extends Node2D
class_name PropLayerRenderer

const SelectionClass = preload("res://scripts/art/ArtSelection.gd")
const PropOrientation = preload("res://scripts/art/PropArtOrientationCatalog.gd")
const VisualGeometry = preload("res://scripts/art/PropVisualGeometryCatalog.gd")
const CommandClass = preload("res://scripts/render/PropDrawCommand.gd")
const ChangeClass = preload("res://scripts/foundation/world/WorldChange.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

## Canonical prop/fixture/vegetation presentation layer.
## Reads WHAT OBJECT occupancy + presentation catalogs; mutates no simulation state.
## System 07B keeps one cached visual plan per stable entity and supports authored
## span/pivot plus an optional foreground pass without changing physical footprint.

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
var _plan_cache: Array[PropDrawCommand] = []
var _plan_cache_valid: bool = false
var _plan_rebuild_count: int = 0

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

func plan_rebuild_count() -> int:
    return _plan_rebuild_count

func clear_texture_cache() -> void:
    if _texture_cache.is_empty():
        return
    _texture_cache.clear()
    queue_redraw()
    redraw_requested.emit(&"texture_cache_cleared")

func diagnostic_reasons() -> Array[String]:
    var values: Array[String] = []
    for value: Variant in _diagnostic_reasons.keys():
        values.append(String(value))
    values.sort()
    return values

func plan_visible_commands() -> Array[PropDrawCommand]:
    if not is_configured() or not _view_valid:
        return []
    if _plan_cache_valid:
        return _plan_cache

    _plan_cache = []
    _plan_rebuild_count += 1
    var first_seen_cells: Dictionary = {}
    var halo: int = VisualGeometry.maximum_discovery_halo_cells()
    var scan_origin := _visible_origin - Vector2i(halo, halo)
    var scan_size := _visible_size + Vector2i(halo * 2, halo * 2)

    for local_y in range(scan_size.y):
        for local_x in range(scan_size.x):
            var cell := scan_origin + Vector2i(local_x, local_y)
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
        var command: PropDrawCommand = _plan_entity(entity_id, observed_cell)
        if command != null:
            _plan_cache.append(command)

    _plan_cache.sort_custom(_command_less)
    _plan_cache_valid = true
    return _plan_cache

func foreground_command_count() -> int:
    var count: int = 0
    for command: PropDrawCommand in plan_visible_commands():
        if command.has_foreground():
            count += 1
    return count

func texture_for_selection(selection: ArtSelection) -> Texture2D:
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

func _draw() -> void:
    if not is_configured() or not _view_valid:
        return
    for command: PropDrawCommand in plan_visible_commands():
        if command.is_diagnostic():
            _remember_diagnostic(command.diagnostic_reason())
            _draw_diagnostic(command.destination)
            continue
        var texture: Texture2D = texture_for_selection(command.selection)
        if texture == null:
            _remember_diagnostic("texture_load_failed")
            _draw_diagnostic(command.destination)
            continue
        if not _draw_selection(
            texture,
            command.selection,
            command.destination,
            command.pivot_screen,
            command.quarter_turns
        ):
            _remember_diagnostic("selection_not_drawable")
            _draw_diagnostic(command.destination)

func _plan_entity(entity_id: String, observed_cell: Vector2i) -> PropDrawCommand:
    var fallback_destination: Rect2 = _destination_for_anchor(observed_cell)
    var observed_cells: Array[Vector2i] = _single_cell_list(observed_cell)
    var entity: WorldEntityRecord = _world.entity(entity_id)
    if entity == null:
        if not _rect_world_intersects_visible(_rect_world_for_default(observed_cell)):
            return null
        return _diagnostic_command(
            entity_id, &"", CommandClass.FAMILY_UNKNOWN, observed_cell, -1,
            null, observed_cells, fallback_destination, "object_entity_missing"
        )

    var placement: WorldPlacement = _world.placement(entity_id)
    if placement == null:
        if not _rect_world_intersects_visible(_rect_world_for_default(observed_cell)):
            return null
        return _diagnostic_command(
            entity_id, entity.semantic_type, _family_for_semantic(entity.semantic_type),
            observed_cell, -1, null, observed_cells, fallback_destination,
            "object_placement_missing"
        )

    var occupied_cells: Array[Vector2i] = placement.world_cells()
    var family: StringName = _family_for_semantic(entity.semantic_type)
    var descriptor: PropVisualGeometryDescriptor = VisualGeometry.descriptor_for(entity.semantic_type)
    if descriptor == null or not descriptor.is_valid():
        return _diagnostic_command(
            entity_id, entity.semantic_type, family, placement.anchor, placement.facing,
            placement.footprint, occupied_cells, _destination_for_anchor(placement.anchor),
            "visual_geometry_invalid"
        )

    var base_selection: ArtSelection = VisualGeometry.resolve_art(_catalog, descriptor.base_art_key)
    var turns: int = PropOrientation.quarter_turns(base_selection, placement.facing)
    var visual_rect_world: Rect2 = _rotated_visual_rect_world(placement.anchor, descriptor, turns)
    if not _rect_world_intersects_visible(visual_rect_world):
        return null

    var destination: Rect2 = _destination_for_descriptor(placement.anchor, descriptor)
    var pivot_screen: Vector2 = _pivot_screen_for_anchor(placement.anchor)

    if placement.channel != Layers.Channel.OBJECT:
        return _diagnostic_command(
            entity_id, entity.semantic_type, family, placement.anchor, placement.facing,
            placement.footprint, occupied_cells, destination, "object_channel_invalid"
        )
    if observed_cell not in occupied_cells:
        return _diagnostic_command(
            entity_id, entity.semantic_type, family, placement.anchor, placement.facing,
            placement.footprint, occupied_cells, destination, "object_occupancy_mismatch"
        )
    if family == CommandClass.FAMILY_UNKNOWN:
        return _diagnostic_command(
            entity_id, entity.semantic_type, family, placement.anchor, placement.facing,
            placement.footprint, occupied_cells, destination, "prop_semantic_unclassified"
        )

    var foreground_selection: ArtSelection = null
    if descriptor.has_foreground():
        foreground_selection = VisualGeometry.resolve_art(_catalog, descriptor.foreground_art_key)

    return CommandClass.new(
        entity_id,
        entity.semantic_type,
        family,
        placement.anchor,
        placement.facing,
        placement.footprint,
        occupied_cells,
        destination,
        base_selection,
        foreground_selection,
        visual_rect_world,
        pivot_screen,
        turns,
        descriptor.draw_span_cells
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
        SelectionClass.unknown(semantic_type, reason),
        null,
        _rect_world_for_default(anchor),
        _pivot_screen_for_anchor(anchor),
        0,
        Vector2i.ONE
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

func _destination_for_descriptor(
    anchor: Vector2i,
    descriptor: PropVisualGeometryDescriptor
) -> Rect2:
    var anchor_screen: Vector2 = _pivot_screen_for_anchor(anchor)
    return Rect2(
        anchor_screen - descriptor.pivot_cells * _cell_pixels,
        Vector2(descriptor.draw_span_cells) * _cell_pixels
    )

func _pivot_screen_for_anchor(anchor: Vector2i) -> Vector2:
    return (
        Vector2(anchor - _visible_origin) + Vector2(0.5, 0.5)
    ) * _cell_pixels

func _rect_world_for_default(anchor: Vector2i) -> Rect2:
    return Rect2(Vector2(anchor), Vector2.ONE)

func _rotated_visual_rect_world(
    anchor: Vector2i,
    descriptor: PropVisualGeometryDescriptor,
    turns: int
) -> Rect2:
    var pivot_world := Vector2(anchor) + Vector2(0.5, 0.5)
    var top_left := pivot_world - descriptor.pivot_cells
    var size := Vector2(descriptor.draw_span_cells)
    var corners: Array[Vector2] = [
        top_left,
        top_left + Vector2(size.x, 0.0),
        top_left + size,
        top_left + Vector2(0.0, size.y),
    ]
    var normalized_turns: int = ((turns % 4) + 4) % 4
    var min_point := Vector2(INF, INF)
    var max_point := Vector2(-INF, -INF)
    for corner: Vector2 in corners:
        var relative: Vector2 = corner - pivot_world
        var rotated: Vector2 = _quarter_rotate(relative, normalized_turns)
        var point: Vector2 = pivot_world + rotated
        min_point.x = min(min_point.x, point.x)
        min_point.y = min(min_point.y, point.y)
        max_point.x = max(max_point.x, point.x)
        max_point.y = max(max_point.y, point.y)
    return Rect2(min_point, max_point - min_point)

static func _quarter_rotate(value: Vector2, turns: int) -> Vector2:
    match ((turns % 4) + 4) % 4:
        1:
            return Vector2(-value.y, value.x)
        2:
            return Vector2(-value.x, -value.y)
        3:
            return Vector2(value.y, -value.x)
        _:
            return value

func _rect_world_intersects_visible(rect: Rect2) -> bool:
    var visible_rect := Rect2(Vector2(_visible_origin), Vector2(_visible_size))
    return rect.intersects(visible_rect)

func _single_cell_list(cell: Vector2i) -> Array[Vector2i]:
    var values: Array[Vector2i] = []
    values.append(cell)
    return values

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
            if _cells_touch_discovery(change.before_cells):
                _request_redraw(&"object_removed")
        ChangeClass.Kind.PLACEMENT_REMOVED:
            if _cells_touch_discovery(change.before_cells):
                _request_redraw(&"object_placement_changed")
        ChangeClass.Kind.PLACEMENT_SET:
            var placement: WorldPlacement = _world.placement(change.entity_id)
            if placement != null and placement.channel == Layers.Channel.OBJECT and _cells_touch_discovery(change.after_cells):
                _request_redraw(&"object_placement_changed")
                return
            if not change.before_cells.is_empty() and _cells_touch_discovery(change.before_cells):
                _request_redraw(&"object_placement_changed")
        _:
            return

func _on_world_reset() -> void:
    _texture_cache.clear()
    _diagnostic_reasons.clear()
    _request_redraw(&"world_reset")

func _cells_touch_discovery(cells: Array[Vector2i]) -> bool:
    for cell: Vector2i in cells:
        if _cell_is_in_discovery_window(cell):
            return true
    return false

func _cell_is_in_discovery_window(cell: Vector2i) -> bool:
    if not _view_valid:
        return false
    var halo: int = VisualGeometry.maximum_discovery_halo_cells()
    return (
        cell.x >= _visible_origin.x - halo
        and cell.x < _visible_origin.x + _visible_size.x + halo
        and cell.y >= _visible_origin.y - halo
        and cell.y < _visible_origin.y + _visible_size.y + halo
    )

static func _command_less(a: PropDrawCommand, b: PropDrawCommand) -> bool:
    if a.anchor.y != b.anchor.y:
        return a.anchor.y < b.anchor.y
    if a.anchor.x != b.anchor.x:
        return a.anchor.x < b.anchor.x
    return a.entity_id < b.entity_id

func _request_redraw(reason: StringName) -> void:
    _plan_cache_valid = false
    _plan_cache = []
    redraw_requested.emit(reason)
    queue_redraw()
