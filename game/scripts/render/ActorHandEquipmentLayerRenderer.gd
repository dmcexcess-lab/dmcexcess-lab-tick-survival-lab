extends Node2D
class_name ActorHandEquipmentLayerRenderer

const SelectionClass = preload("res://scripts/art/ArtSelection.gd")
const CommandClass = preload("res://scripts/render/ActorHandDrawCommand.gd")
const ChangeClass = preload("res://scripts/foundation/world/WorldChange.gd")
const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")

## Focused held-item presentation owner. Instantiate once for BACK and once for FRONT.
## Reads WHAT + ArtCatalog + ActorHandEquipmentState and mutates no simulation truth.

signal redraw_requested(reason: StringName)

enum Pass {
    BACK,
    FRONT,
}

const MAX_DIAGNOSTIC_REASONS: int = 64
const DIAGNOSTIC_FILL := Color(0.78, 0.08, 0.72, 1.0)
const DIAGNOSTIC_LINE := Color(1.0, 0.92, 1.0, 1.0)
const ITEM_BACKDROP := Color(0.0, 0.0, 0.0, 0.40)

var _world: WorldState = null
var _catalog: ArtCatalog = null
var _hand_state: ActorHandEquipmentState = null
var _render_pass: int = Pass.FRONT
var _visible_origin: Vector2i = Vector2i.ZERO
var _visible_size: Vector2i = Vector2i.ZERO
var _cell_pixels: float = 0.0
var _view_valid: bool = false
var _texture_cache: Dictionary = {}
var _diagnostic_reasons: Dictionary = {}
var _known_survivor_placement_ids: Dictionary = {}

func configure(
    world_state: WorldState,
    art_catalog: ArtCatalog,
    hand_equipment_state: ActorHandEquipmentState
) -> bool:
    if world_state == null or art_catalog == null or hand_equipment_state == null:
        return false
    _disconnect_signals()
    _world = world_state
    _catalog = art_catalog
    _hand_state = hand_equipment_state
    _texture_cache.clear()
    _diagnostic_reasons.clear()
    _rebuild_survivor_placement_index()
    _connect_signals()
    _request_redraw(&"configured")
    return true

func is_configured() -> bool:
    return _world != null and _catalog != null and _hand_state != null

func set_render_pass(value: int) -> bool:
    if not _pass_is_valid(value):
        return false
    if value == _render_pass:
        return true
    _render_pass = value
    _request_redraw(&"render_pass_changed")
    return true

func render_pass() -> int:
    return _render_pass

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
    for key: Variant in _diagnostic_reasons.keys():
        values.append(String(key))
    values.sort()
    return values

func plan_visible_commands() -> Array[ActorHandDrawCommand]:
    var commands: Array[ActorHandDrawCommand] = []
    if not is_configured() or not _view_valid or not _pass_is_valid(_render_pass):
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
        _append_actor_commands(commands, actor_id, observed_cell)

    commands.sort_custom(_command_less)
    return commands

func _draw() -> void:
    if not is_configured() or not _view_valid:
        return
    var commands: Array[ActorHandDrawCommand] = plan_visible_commands()
    for command: ActorHandDrawCommand in commands:
        if command.is_diagnostic():
            _remember_diagnostic(command.diagnostic_reason())
            _draw_diagnostic(command.center, command.draw_size)
            continue
        var selection: ArtSelection = command.selection
        var texture: Texture2D = _texture_for_selection(selection)
        if texture == null:
            _remember_diagnostic("texture_load_failed")
            _draw_diagnostic(command.center, command.draw_size)
            continue
        draw_set_transform(command.center, command.rotation_radians, Vector2.ONE)
        draw_circle(Vector2.ZERO, command.draw_size * 0.5, ITEM_BACKDROP)
        var half: float = command.draw_size * 0.5
        var destination := Rect2(Vector2(-half, -half), Vector2(command.draw_size, command.draw_size))
        if selection.is_atlas_region():
            draw_texture_rect_region(texture, destination, selection.region(), Color.WHITE, false, true)
        elif selection.source != null and not selection.source.atlas:
            draw_texture_rect(texture, destination, false, Color.WHITE, false)
        else:
            _remember_diagnostic("selection_not_drawable")
            _draw_diagnostic(Vector2.ZERO, command.draw_size)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _append_actor_commands(
    commands: Array[ActorHandDrawCommand],
    actor_id: String,
    observed_cell: Vector2i
) -> void:
    var actor: WorldEntityRecord = _world.entity(actor_id)
    if actor == null:
        if _render_pass == Pass.FRONT:
            commands.append(_diagnostic_command(actor_id, "", &"", -1, observed_cell, -1, _actor_center(observed_cell), "actor_entity_missing"))
        return
    if actor.semantic_type != &"actor.survivor":
        return

    var placement: WorldPlacement = _world.placement(actor_id)
    if placement == null:
        if _render_pass == Pass.FRONT:
            commands.append(_diagnostic_command(actor_id, "", &"", -1, observed_cell, -1, _actor_center(observed_cell), "actor_placement_missing"))
        return
    if placement.channel != Layers.Channel.ACTOR:
        if _render_pass == Pass.FRONT:
            commands.append(_diagnostic_command(actor_id, "", &"", -1, placement.anchor, placement.facing, _actor_center(placement.anchor), "actor_channel_invalid"))
        return
    var occupied_cells: Array[Vector2i] = placement.world_cells()
    if observed_cell not in occupied_cells:
        if _render_pass == Pass.FRONT:
            commands.append(_diagnostic_command(actor_id, "", &"", -1, placement.anchor, placement.facing, _actor_center(placement.anchor), "actor_occupancy_mismatch"))
        return
    if not FacingRules.is_valid(placement.facing):
        if _render_pass == Pass.FRONT:
            commands.append(_diagnostic_command(actor_id, "", &"", -1, placement.anchor, placement.facing, _actor_center(placement.anchor), "actor_facing_invalid"))
        return
    if not _hand_state.has_actor(actor_id):
        if _render_pass == Pass.FRONT:
            commands.append(_diagnostic_command(actor_id, "", &"", -1, placement.anchor, placement.facing, _actor_center(placement.anchor), "hand_equipment_unclassified"))
        return

    _append_slot_command(commands, actor_id, placement, Slots.Value.PRIMARY_RIGHT, _hand_state.primary_item(actor_id))
    _append_slot_command(commands, actor_id, placement, Slots.Value.SECONDARY_LEFT, _hand_state.secondary_item(actor_id))

func _append_slot_command(
    commands: Array[ActorHandDrawCommand],
    actor_id: String,
    placement: WorldPlacement,
    slot: int,
    item_id: String
) -> void:
    if item_id.is_empty():
        return
    var target_pass: int = _pass_for(slot, placement.facing)
    if target_pass != _render_pass:
        return

    var center: Vector2 = _hand_center(placement.anchor, placement.facing, slot)
    var item: WorldEntityRecord = _world.entity(item_id)
    if item == null:
        commands.append(_diagnostic_command(actor_id, item_id, &"", slot, placement.anchor, placement.facing, center, "held_item_entity_missing"))
        return
    var semantic: String = String(item.semantic_type).strip_edges()
    if not semantic.begins_with("item.") or semantic.length() <= 5:
        commands.append(_diagnostic_command(actor_id, item_id, item.semantic_type, slot, placement.anchor, placement.facing, center, "held_item_semantic_invalid"))
        return
    if _world.has_placement(item_id):
        commands.append(_diagnostic_command(actor_id, item_id, item.semantic_type, slot, placement.anchor, placement.facing, center, "held_item_tactically_placed"))
        return

    var selection: ArtSelection = _catalog.resolve_held_item(item.semantic_type)
    var scale: float = _catalog.held_item_draw_scale(item.semantic_type)
    var native_facing: int = _catalog.held_item_native_facing(item.semantic_type)
    if selection == null or not selection.is_found():
        var reason: String = selection.reason if selection != null else "held_item_art_missing"
        commands.append(_diagnostic_command(actor_id, item_id, item.semantic_type, slot, placement.anchor, placement.facing, center, reason))
        return
    if scale <= 0.0:
        commands.append(_diagnostic_command(actor_id, item_id, item.semantic_type, slot, placement.anchor, placement.facing, center, "held_item_scale_invalid"))
        return
    if native_facing != FacingRules.Value.EAST:
        commands.append(_diagnostic_command(actor_id, item_id, item.semantic_type, slot, placement.anchor, placement.facing, center, "held_item_native_facing_invalid"))
        return

    commands.append(CommandClass.new(
        actor_id,
        item_id,
        item.semantic_type,
        slot,
        _render_pass,
        placement.anchor,
        placement.facing,
        center,
        _cell_pixels * scale,
        _rotation_for_facing(placement.facing),
        selection
    ))

func _diagnostic_command(
    actor_id: String,
    item_id: String,
    semantic_type: StringName,
    slot: int,
    anchor: Vector2i,
    facing: int,
    center: Vector2,
    reason: String
) -> ActorHandDrawCommand:
    return CommandClass.new(
        actor_id,
        item_id,
        semantic_type,
        slot,
        _render_pass,
        anchor,
        facing,
        center,
        maxf(8.0, _cell_pixels * 0.25),
        0.0,
        SelectionClass.unknown(semantic_type, reason)
    )

func _actor_center(anchor: Vector2i) -> Vector2:
    var local_cell: Vector2i = anchor - _visible_origin
    return Vector2(
        (float(local_cell.x) + 0.5) * _cell_pixels,
        (float(local_cell.y) + 0.5) * _cell_pixels
    )

func _hand_center(anchor: Vector2i, facing: int, slot: int) -> Vector2:
    var center: Vector2 = _actor_center(anchor)
    var forward_i: Vector2i = FacingRules.vector(facing)
    var forward := Vector2(float(forward_i.x), float(forward_i.y))
    var right := Vector2(-forward.y, forward.x)
    if slot == Slots.Value.PRIMARY_RIGHT:
        return center + right * (_cell_pixels * 11.0 / 32.0) - forward * (_cell_pixels * 1.5 / 32.0)
    var left: Vector2 = -right
    return center + left * (_cell_pixels * 10.5 / 32.0) - forward * (_cell_pixels * 1.0 / 32.0)

func _pass_for(slot: int, facing: int) -> int:
    if facing == FacingRules.Value.EAST:
        return Pass.BACK if slot == Slots.Value.SECONDARY_LEFT else Pass.FRONT
    if facing == FacingRules.Value.WEST:
        return Pass.BACK if slot == Slots.Value.PRIMARY_RIGHT else Pass.FRONT
    return Pass.FRONT

func _rotation_for_facing(facing: int) -> float:
    match facing:
        FacingRules.Value.NORTH:
            return -PI * 0.5
        FacingRules.Value.EAST:
            return 0.0
        FacingRules.Value.SOUTH:
            return PI * 0.5
        FacingRules.Value.WEST:
            return PI
    return 0.0

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

func _draw_diagnostic(center: Vector2, size: float) -> void:
    var safe_size: float = maxf(8.0, size)
    var half: float = safe_size * 0.5
    var rect := Rect2(center - Vector2(half, half), Vector2(safe_size, safe_size))
    draw_rect(rect, DIAGNOSTIC_FILL, true)
    draw_line(rect.position, rect.end, DIAGNOSTIC_LINE, 2.0)
    draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), DIAGNOSTIC_LINE, 2.0)

func _remember_diagnostic(reason: String) -> void:
    var normalized: String = reason.strip_edges()
    if normalized.is_empty():
        normalized = "unknown_hand_equipment_diagnostic"
    if _diagnostic_reasons.has(normalized) or _diagnostic_reasons.size() >= MAX_DIAGNOSTIC_REASONS:
        return
    _diagnostic_reasons[normalized] = true

func _rebuild_survivor_placement_index() -> void:
    _known_survivor_placement_ids.clear()
    if _world == null:
        return
    for actor_id: String in _world.entity_ids():
        if not _is_survivor_entity(actor_id):
            continue
        var placement: WorldPlacement = _world.placement(actor_id)
        if placement != null and placement.channel == Layers.Channel.ACTOR:
            _known_survivor_placement_ids[actor_id] = true

func _is_survivor_entity(actor_id: String) -> bool:
    if _world == null or not _world.has_entity(actor_id):
        return false
    var entity: WorldEntityRecord = _world.entity(actor_id)
    return entity != null and entity.semantic_type == &"actor.survivor"

func _connect_signals() -> void:
    if _world != null:
        var changed_callable := Callable(self, "_on_world_changed")
        var reset_callable := Callable(self, "_on_world_reset")
        if not _world.changed.is_connected(changed_callable):
            _world.changed.connect(changed_callable)
        if not _world.world_reset.is_connected(reset_callable):
            _world.world_reset.connect(reset_callable)
    if _hand_state != null:
        var enrolled_callable := Callable(self, "_on_actor_enrolled")
        var removed_callable := Callable(self, "_on_actor_removed")
        var assignment_callable := Callable(self, "_on_hand_assignment_changed")
        var hand_reset_callable := Callable(self, "_on_hand_state_reset")
        if not _hand_state.actor_enrolled.is_connected(enrolled_callable):
            _hand_state.actor_enrolled.connect(enrolled_callable)
        if not _hand_state.actor_removed.is_connected(removed_callable):
            _hand_state.actor_removed.connect(removed_callable)
        if not _hand_state.hand_assignment_changed.is_connected(assignment_callable):
            _hand_state.hand_assignment_changed.connect(assignment_callable)
        if not _hand_state.hand_equipment_reset.is_connected(hand_reset_callable):
            _hand_state.hand_equipment_reset.connect(hand_reset_callable)

func _disconnect_signals() -> void:
    if _world != null:
        var changed_callable := Callable(self, "_on_world_changed")
        var reset_callable := Callable(self, "_on_world_reset")
        if _world.changed.is_connected(changed_callable):
            _world.changed.disconnect(changed_callable)
        if _world.world_reset.is_connected(reset_callable):
            _world.world_reset.disconnect(reset_callable)
    if _hand_state != null:
        var enrolled_callable := Callable(self, "_on_actor_enrolled")
        var removed_callable := Callable(self, "_on_actor_removed")
        var assignment_callable := Callable(self, "_on_hand_assignment_changed")
        var hand_reset_callable := Callable(self, "_on_hand_state_reset")
        if _hand_state.actor_enrolled.is_connected(enrolled_callable):
            _hand_state.actor_enrolled.disconnect(enrolled_callable)
        if _hand_state.actor_removed.is_connected(removed_callable):
            _hand_state.actor_removed.disconnect(removed_callable)
        if _hand_state.hand_assignment_changed.is_connected(assignment_callable):
            _hand_state.hand_assignment_changed.disconnect(assignment_callable)
        if _hand_state.hand_equipment_reset.is_connected(hand_reset_callable):
            _hand_state.hand_equipment_reset.disconnect(hand_reset_callable)

func _on_world_changed(change: WorldChange) -> void:
    if change == null:
        return
    match change.kind:
        ChangeClass.Kind.TERRAIN_SET, ChangeClass.Kind.TERRAIN_REMOVED:
            return
        ChangeClass.Kind.ENTITY_CREATED:
            var assignment: Dictionary = _hand_state.assignment_for_item(change.entity_id) if _hand_state != null else {}
            if not assignment.is_empty() and _actor_touches_visible(String(assignment.get("actor_id", ""))):
                _request_redraw(&"held_item_entity_changed")
        ChangeClass.Kind.ENTITY_REMOVED:
            var assignment: Dictionary = _hand_state.assignment_for_item(change.entity_id) if _hand_state != null else {}
            if not assignment.is_empty() and _actor_touches_visible(String(assignment.get("actor_id", ""))):
                _request_redraw(&"held_item_entity_changed")
            var was_survivor: bool = _known_survivor_placement_ids.has(change.entity_id)
            _known_survivor_placement_ids.erase(change.entity_id)
            if was_survivor and _view_valid and _cells_touch_visible(change.before_cells):
                _request_redraw(&"survivor_removed")
        ChangeClass.Kind.PLACEMENT_REMOVED, ChangeClass.Kind.PLACEMENT_SET:
            var assignment: Dictionary = _hand_state.assignment_for_item(change.entity_id) if _hand_state != null else {}
            if not assignment.is_empty() and _actor_touches_visible(String(assignment.get("actor_id", ""))):
                _request_redraw(&"held_item_placement_changed")
            var was_survivor: bool = _known_survivor_placement_ids.has(change.entity_id)
            var is_survivor: bool = false
            var placement: WorldPlacement = _world.placement(change.entity_id)
            if placement != null and placement.channel == Layers.Channel.ACTOR and _is_survivor_entity(change.entity_id):
                is_survivor = true
                _known_survivor_placement_ids[change.entity_id] = true
            else:
                _known_survivor_placement_ids.erase(change.entity_id)
            if (was_survivor or is_survivor) and _view_valid:
                if _cells_touch_visible(change.before_cells) or _cells_touch_visible(change.after_cells):
                    _request_redraw(&"survivor_placement_changed")
        _:
            return

func _on_world_reset() -> void:
    _texture_cache.clear()
    _diagnostic_reasons.clear()
    _rebuild_survivor_placement_index()
    _request_redraw(&"world_reset")

func _on_actor_enrolled(actor_id: String, _version: int) -> void:
    if _actor_touches_visible(actor_id):
        _request_redraw(&"hand_actor_enrolled")

func _on_actor_removed(actor_id: String, _primary_item_id: String, _secondary_item_id: String, _version: int) -> void:
    if _actor_touches_visible(actor_id):
        _request_redraw(&"hand_actor_removed")

func _on_hand_assignment_changed(
    actor_id: String,
    _slot: int,
    _previous_item_id: String,
    _new_item_id: String,
    _version: int
) -> void:
    if _actor_touches_visible(actor_id):
        _request_redraw(&"hand_assignment_changed")

func _on_hand_state_reset() -> void:
    _request_redraw(&"hand_state_reset")

func _actor_touches_visible(actor_id: String) -> bool:
    if not _view_valid or _world == null or actor_id.is_empty():
        return false
    var placement: WorldPlacement = _world.placement(actor_id)
    return placement != null and placement.channel == Layers.Channel.ACTOR and _cells_touch_visible(placement.world_cells())

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

static func _pass_is_valid(value: int) -> bool:
    return value == Pass.BACK or value == Pass.FRONT

static func _command_less(a: ActorHandDrawCommand, b: ActorHandDrawCommand) -> bool:
    if a.anchor.y != b.anchor.y:
        return a.anchor.y < b.anchor.y
    if a.anchor.x != b.anchor.x:
        return a.anchor.x < b.anchor.x
    if a.actor_id != b.actor_id:
        return a.actor_id < b.actor_id
    return a.hand_slot < b.hand_slot

func _request_redraw(reason: StringName) -> void:
    redraw_requested.emit(reason)
    queue_redraw()
