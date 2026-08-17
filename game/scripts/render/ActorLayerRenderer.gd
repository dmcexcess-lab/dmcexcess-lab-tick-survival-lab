extends Node2D
class_name ActorLayerRenderer

const SelectionClass = preload("res://scripts/art/ArtSelection.gd")
const CommandClass = preload("res://scripts/render/ActorDrawCommand.gd")
const ChangeClass = preload("res://scripts/foundation/world/WorldChange.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

## Canonical living-actor presentation layer.
## Reads WHAT ACTOR occupancy + ArtCatalog; mutates no simulation state.
## Corpses are explicitly outside this renderer.

signal redraw_requested(reason: StringName)

const MAX_DIAGNOSTIC_REASONS: int = 64
const DIAGNOSTIC_FILL := Color(0.78, 0.08, 0.72, 1.0)
const DIAGNOSTIC_LINE := Color(1.0, 0.92, 1.0, 1.0)
const NPC_DRAW_SCALE: float = 29.0 / 32.0
const FNV1A_OFFSET_BASIS: int = 2166136261
const FNV1A_PRIME: int = 16777619
const UINT32_MASK: int = 0xffffffff

var _world: WorldState = null
var _catalog: ArtCatalog = null
var _controlled_actor_id: String = ""
var _visible_origin: Vector2i = Vector2i.ZERO
var _visible_size: Vector2i = Vector2i.ZERO
var _cell_pixels: float = 0.0
var _view_valid: bool = false
var _texture_cache: Dictionary = {}
var _diagnostic_reasons: Dictionary = {}
var _known_actor_placement_ids: Dictionary = {}

func configure(world_state: WorldState, art_catalog: ArtCatalog) -> bool:
    if world_state == null or art_catalog == null:
        return false
    _disconnect_world_signals()
    _world = world_state
    _catalog = art_catalog
    _texture_cache.clear()
    _diagnostic_reasons.clear()
    _rebuild_actor_placement_index()
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

func set_controlled_actor_id(actor_id: String) -> bool:
    if not actor_id.is_empty() and actor_id.strip_edges().is_empty():
        return false
    if actor_id == _controlled_actor_id:
        return true
    _controlled_actor_id = actor_id
    _request_redraw(&"controlled_actor_changed")
    return true

func controlled_actor_id() -> String:
    return _controlled_actor_id

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

func plan_visible_commands() -> Array[ActorDrawCommand]:
    var commands: Array[ActorDrawCommand] = []
    if not is_configured() or not _view_valid:
        return commands

    var first_seen_cells: Dictionary = {}
    for local_y in range(_visible_size.y):
        for local_x in range(_visible_size.x):
            var cell := _visible_origin + Vector2i(local_x, local_y)
            var actor_ids: Array[String] = _world.entities_at(cell, Layers.Channel.ACTOR)
            if actor_ids.is_empty():
                continue
            actor_ids.sort()
            for actor_id: String in actor_ids:
                if not first_seen_cells.has(actor_id):
                    first_seen_cells[actor_id] = cell

    var actor_ids: Array[String] = []
    for value: Variant in first_seen_cells.keys():
        actor_ids.append(String(value))
    actor_ids.sort()

    for actor_id: String in actor_ids:
        var observed_cell: Vector2i = first_seen_cells[actor_id]
        commands.append(_plan_actor(actor_id, observed_cell))

    commands.sort_custom(_command_less)
    return commands

func _draw() -> void:
    if not is_configured() or not _view_valid:
        return
    var commands: Array[ActorDrawCommand] = plan_visible_commands()
    for command: ActorDrawCommand in commands:
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

func _plan_actor(actor_id: String, observed_cell: Vector2i) -> ActorDrawCommand:
    var controlled: bool = actor_id == _controlled_actor_id and not _controlled_actor_id.is_empty()
    var fallback_destination: Rect2 = _destination_for_anchor(observed_cell, controlled)
    var observed_cells: Array[Vector2i] = _single_cell_list(observed_cell)
    var entity: WorldEntityRecord = _world.entity(actor_id)
    if entity == null:
        return _diagnostic_command(
            actor_id, &"", CommandClass.FAMILY_UNKNOWN, controlled, observed_cell, -1,
            null, observed_cells, -1, fallback_destination, "actor_entity_missing"
        )

    var family: StringName = _family_for_semantic(entity.semantic_type)
    var placement: WorldPlacement = _world.placement(actor_id)
    if placement == null:
        return _diagnostic_command(
            actor_id, entity.semantic_type, family, controlled, observed_cell, -1,
            null, observed_cells, -1, fallback_destination, "actor_placement_missing"
        )

    var occupied_cells: Array[Vector2i] = placement.world_cells()
    var destination: Rect2 = _destination_for_anchor(placement.anchor, controlled)

    if placement.channel != Layers.Channel.ACTOR:
        return _diagnostic_command(
            actor_id, entity.semantic_type, family, controlled, placement.anchor, placement.facing,
            placement.footprint, occupied_cells, -1, destination, "actor_channel_invalid"
        )
    if observed_cell not in occupied_cells:
        return _diagnostic_command(
            actor_id, entity.semantic_type, family, controlled, placement.anchor, placement.facing,
            placement.footprint, occupied_cells, -1, destination, "actor_occupancy_mismatch"
        )
    if family == CommandClass.FAMILY_UNKNOWN:
        return _diagnostic_command(
            actor_id, entity.semantic_type, family, controlled, placement.anchor, placement.facing,
            placement.footprint, occupied_cells, -1, destination, "actor_semantic_unclassified"
        )
    if controlled and family != CommandClass.FAMILY_SURVIVOR:
        return _diagnostic_command(
            actor_id, entity.semantic_type, family, controlled, placement.anchor, placement.facing,
            placement.footprint, occupied_cells, -1, destination, "controlled_actor_not_survivor"
        )

    var variant: int = -1 if controlled else _default_variant_for_actor_id(actor_id)
    var selection: ArtSelection = null
    if controlled:
        selection = _catalog.resolve_player(placement.facing)
    else:
        selection = _catalog.resolve_living_actor(family, placement.facing, variant)

    return CommandClass.new(
        actor_id,
        entity.semantic_type,
        family,
        controlled,
        placement.anchor,
        placement.facing,
        placement.footprint,
        occupied_cells,
        variant,
        destination,
        selection
    )

func _diagnostic_command(
    actor_id: String,
    semantic_type: StringName,
    family: StringName,
    controlled: bool,
    anchor: Vector2i,
    facing: int,
    footprint: SpatialFootprint,
    occupied_cells: Array[Vector2i],
    variant: int,
    destination: Rect2,
    reason: String
) -> ActorDrawCommand:
    return CommandClass.new(
        actor_id,
        semantic_type,
        family,
        controlled,
        anchor,
        facing,
        footprint,
        occupied_cells,
        variant,
        destination,
        SelectionClass.unknown(semantic_type, reason)
    )

func _family_for_semantic(semantic_type: StringName) -> StringName:
    var raw: String = String(semantic_type).strip_edges()
    if raw == "actor.survivor":
        return CommandClass.FAMILY_SURVIVOR
    if raw == "actor.infected":
        return CommandClass.FAMILY_INFECTED
    return CommandClass.FAMILY_UNKNOWN

func _destination_for_anchor(anchor: Vector2i, controlled: bool) -> Rect2:
    var local_cell: Vector2i = anchor - _visible_origin
    var cell_origin := Vector2(float(local_cell.x) * _cell_pixels, float(local_cell.y) * _cell_pixels)
    if controlled:
        return Rect2(cell_origin, Vector2(_cell_pixels, _cell_pixels))
    var draw_size: float = _cell_pixels * NPC_DRAW_SCALE
    var inset: float = (_cell_pixels - draw_size) * 0.5
    return Rect2(cell_origin + Vector2(inset, inset), Vector2(draw_size, draw_size))

func _single_cell_list(cell: Vector2i) -> Array[Vector2i]:
    var values: Array[Vector2i] = []
    values.append(cell)
    return values

func _default_variant_for_actor_id(actor_id: String) -> int:
    var hash_value: int = FNV1A_OFFSET_BASIS
    var bytes: PackedByteArray = actor_id.to_utf8_buffer()
    for byte_value: int in bytes:
        hash_value = ((hash_value ^ byte_value) * FNV1A_PRIME) & UINT32_MASK
    return int(hash_value % ArtCatalog.LIVING_ACTOR_VARIANTS)

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
        normalized = "unknown_actor_diagnostic"
    if _diagnostic_reasons.has(normalized):
        return
    if _diagnostic_reasons.size() >= MAX_DIAGNOSTIC_REASONS:
        return
    _diagnostic_reasons[normalized] = true

func _rebuild_actor_placement_index() -> void:
    _known_actor_placement_ids.clear()
    if _world == null:
        return
    var entity_ids: Array[String] = _world.entity_ids()
    for actor_id: String in entity_ids:
        var placement: WorldPlacement = _world.placement(actor_id)
        if placement != null and placement.channel == Layers.Channel.ACTOR:
            _known_actor_placement_ids[actor_id] = true

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
    if change == null:
        return
    match change.kind:
        ChangeClass.Kind.TERRAIN_SET, ChangeClass.Kind.TERRAIN_REMOVED, ChangeClass.Kind.ENTITY_CREATED:
            return
        ChangeClass.Kind.ENTITY_REMOVED:
            var was_actor_placement: bool = _known_actor_placement_ids.has(change.entity_id)
            _known_actor_placement_ids.erase(change.entity_id)
            if was_actor_placement and _view_valid and _cells_touch_visible(change.before_cells):
                _request_redraw(&"actor_removed")
        ChangeClass.Kind.PLACEMENT_REMOVED:
            var was_actor_placement: bool = _known_actor_placement_ids.has(change.entity_id)
            _known_actor_placement_ids.erase(change.entity_id)
            if was_actor_placement and _view_valid and _cells_touch_visible(change.before_cells):
                _request_redraw(&"actor_placement_changed")
        ChangeClass.Kind.PLACEMENT_SET:
            var was_actor_placement: bool = _known_actor_placement_ids.has(change.entity_id)
            var placement: WorldPlacement = _world.placement(change.entity_id)
            var is_actor_placement: bool = placement != null and placement.channel == Layers.Channel.ACTOR
            if is_actor_placement:
                _known_actor_placement_ids[change.entity_id] = true
            else:
                _known_actor_placement_ids.erase(change.entity_id)
            if not _view_valid or not (was_actor_placement or is_actor_placement):
                return
            if _cells_touch_visible(change.before_cells) or _cells_touch_visible(change.after_cells):
                _request_redraw(&"actor_placement_changed")
        _:
            return

func _on_world_reset() -> void:
    _texture_cache.clear()
    _diagnostic_reasons.clear()
    _rebuild_actor_placement_index()
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

static func _command_less(a: ActorDrawCommand, b: ActorDrawCommand) -> bool:
    if a.anchor.y != b.anchor.y:
        return a.anchor.y < b.anchor.y
    if a.anchor.x != b.anchor.x:
        return a.anchor.x < b.anchor.x
    return a.actor_id < b.actor_id

func _request_redraw(reason: StringName) -> void:
    redraw_requested.emit(reason)
    queue_redraw()
