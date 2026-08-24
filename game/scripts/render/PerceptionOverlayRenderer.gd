extends Node2D
class_name PerceptionOverlayRenderer

const RoadTopology = preload("res://scripts/art/RoadArtTopology.gd")
const PropOrientation = preload("res://scripts/art/PropArtOrientationCatalog.gd")

## Presentation-only knowledge mask. Hidden live world is blacked out before stale memory redraw.

signal redraw_requested(reason: StringName)

const TRUE_FOG_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const MEMORY_MODULATION := Color(0.30, 0.30, 0.30, 1.0)
const LAST_SEEN_MODULATION := Color(0.48, 0.54, 0.66, 0.50)
const SOUND_CUE_COLOR := Color(1.0, 0.82, 0.20, 0.95)
const NPC_DRAW_SCALE: float = 29.0 / 32.0
const FNV1A_OFFSET_BASIS: int = 2166136261
const FNV1A_PRIME: int = 16777619
const UINT32_MASK: int = 0xffffffff
const ROAD_LIKE_TOKENS := {
    "road": true, "dirt_road": true, "road_v": true, "road_h": true,
    "road_ne": true, "road_es": true, "road_sw": true, "road_wn": true,
    "road_t_nes": true, "road_t_esw": true, "road_t_swn": true, "road_t_wne": true,
    "road_cross": true, "road_end_n": true, "road_end_e": true, "road_end_s": true,
    "road_end_w": true, "road_plain": true, "dirt_road_h": true, "dirt_road_v": true,
}

var _perception: ObserverPerceptionService = null
var _memory: PerceptionMemoryStore = null
var _catalog: ArtCatalog = null
var _observer_id: String = ""
var _visible_origin: Vector2i = Vector2i.ZERO
var _visible_size: Vector2i = Vector2i.ZERO
var _cell_pixels: float = 0.0
var _view_valid: bool = false
var _texture_cache: Dictionary = {}
var _auditory_cues: Array[Dictionary] = []

func configure(
    perception: ObserverPerceptionService,
    memory_store: PerceptionMemoryStore,
    art_catalog: ArtCatalog,
    observer_id: String
) -> bool:
    if perception == null or memory_store == null or art_catalog == null:
        return false
    var normalized: String = observer_id.strip_edges()
    if normalized.is_empty() or perception.observer_id() != normalized or not memory_store.has_observer(normalized):
        return false
    _disconnect_perception()
    _perception = perception
    _memory = memory_store
    _catalog = art_catalog
    _observer_id = normalized
    _texture_cache.clear()
    _connect_perception()
    _request_redraw(&"configured")
    return true

func is_configured() -> bool:
    return _perception != null and _memory != null and _catalog != null and not _observer_id.is_empty()

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

func set_auditory_cues(cues: Array) -> bool:
    var normalized: Array[Dictionary] = []
    for value: Variant in cues:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var cue: Dictionary = value
        var cell_value: Variant = cue.get("cell", null)
        if typeof(cell_value) != TYPE_VECTOR2I:
            return false
        normalized.append({
            "cell": cell_value,
            "radius_cells": maxi(0, int(cue.get("radius_cells", 0))),
            "strength": clampf(float(cue.get("strength", 1.0)), 0.0, 1.0),
            "category": String(cue.get("category", "sound")),
        })
    _auditory_cues = normalized
    _request_redraw(&"auditory_cues_changed")
    return true

func auditory_cues() -> Array[Dictionary]:
    return _auditory_cues.duplicate(true)

func planned_cell_counts() -> Dictionary:
    var counts := {"visible": 0, "remembered": 0, "unseen": 0, "remembered_props": 0, "last_seen": 0, "auditory": 0}
    if not is_configured() or not _view_valid:
        return counts
    for local_y in range(_visible_size.y):
        for local_x in range(_visible_size.x):
            var cell := _visible_origin + Vector2i(local_x, local_y)
            match _perception.knowledge_state(cell):
                ObserverPerceptionService.KnowledgeState.VISIBLE:
                    counts["visible"] += 1
                ObserverPerceptionService.KnowledgeState.REMEMBERED:
                    counts["remembered"] += 1
                    var memory: Dictionary = _memory.environment_memory(_observer_id, cell)
                    var props_value: Variant = memory.get("props", [])
                    if typeof(props_value) == TYPE_ARRAY:
                        counts["remembered_props"] += props_value.size()
                _:
                    counts["unseen"] += 1
    for observation: Dictionary in _memory.actor_observations(_observer_id):
        var cell: Vector2i = observation.get("cell", Vector2i.ZERO)
        if _cell_in_view(cell) and _perception.knowledge_state(cell) == ObserverPerceptionService.KnowledgeState.REMEMBERED:
            counts["last_seen"] += 1
    for cue: Dictionary in _auditory_cues:
        var cue_cell: Vector2i = cue.get("cell", Vector2i.ZERO)
        if _cell_in_view(cue_cell):
            counts["auditory"] += 1
    return counts

func _draw() -> void:
    if not is_configured() or not _view_valid:
        return

    for local_y in range(_visible_size.y):
        for local_x in range(_visible_size.x):
            var cell := _visible_origin + Vector2i(local_x, local_y)
            var state: int = _perception.knowledge_state(cell)
            if state == ObserverPerceptionService.KnowledgeState.VISIBLE:
                continue
            var destination := _cell_rect(cell)
            draw_rect(destination, TRUE_FOG_COLOR, true)
            if state == ObserverPerceptionService.KnowledgeState.REMEMBERED:
                _draw_remembered_cell(cell, destination)

    _draw_last_seen_actors()
    _draw_auditory_cues()

func _draw_remembered_cell(cell: Vector2i, destination: Rect2) -> void:
    var memory: Dictionary = _memory.environment_memory(_observer_id, cell)
    if memory.is_empty():
        return
    var terrain := StringName(String(memory.get("terrain_semantic", "")))
    if String(terrain).strip_edges().is_empty():
        return
    var ground_selection: ArtSelection = _resolve_remembered_ground(cell, terrain)
    _draw_selection(ground_selection, destination, MEMORY_MODULATION)

    var structure_value: Variant = memory.get("structure", {})
    if typeof(structure_value) == TYPE_DICTIONARY:
        var structure: Dictionary = structure_value
        if not structure.is_empty():
            var structure_selection: ArtSelection = _resolve_remembered_structure(structure)
            _draw_selection(structure_selection, destination, MEMORY_MODULATION)

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
    _draw_selection(selection, _cell_rect(anchor), MEMORY_MODULATION, quarter_turns)

func _resolve_remembered_ground(cell: Vector2i, semantic_id: StringName) -> ArtSelection:
    var token: String = _leaf_token(semantic_id)
    match token:
        "road":
            return _catalog.resolve_road(_remembered_road_mask(cell), &"local")
        "dirt_road":
            return _catalog.resolve_dirt_road(_remembered_road_mask(cell))
        "sidewalk":
            return _catalog.resolve_sidewalk(_remembered_road_mask(cell))
        _:
            return _catalog.resolve_ground(semantic_id)

func _remembered_road_mask(cell: Vector2i) -> int:
    var mask: int = 0
    if _is_remembered_road(cell + Vector2i.UP):
        mask |= RoadTopology.ROAD_N
    if _is_remembered_road(cell + Vector2i.RIGHT):
        mask |= RoadTopology.ROAD_E
    if _is_remembered_road(cell + Vector2i.DOWN):
        mask |= RoadTopology.ROAD_S
    if _is_remembered_road(cell + Vector2i.LEFT):
        mask |= RoadTopology.ROAD_W
    return mask

func _is_remembered_road(cell: Vector2i) -> bool:
    var memory: Dictionary = _memory.environment_memory(_observer_id, cell)
    if memory.is_empty():
        return false
    return ROAD_LIKE_TOKENS.has(_leaf_token(StringName(String(memory.get("terrain_semantic", "")))))

func _resolve_remembered_structure(structure: Dictionary) -> ArtSelection:
    var semantic := StringName(String(structure.get("semantic_type", "")))
    var family: String = String(structure.get("family", ""))
    match family:
        "wall":
            return _catalog.resolve_wall(semantic)
        "door":
            return _catalog.resolve_door(semantic, String(structure.get("door_state", "")) == "open")
        "window":
            return _catalog.resolve_window(semantic)
        _:
            return null

func _draw_last_seen_actors() -> void:
    for observation: Dictionary in _memory.actor_observations(_observer_id):
        var cell: Vector2i = observation.get("cell", Vector2i.ZERO)
        if not _cell_in_view(cell):
            continue
        if _perception.knowledge_state(cell) != ObserverPerceptionService.KnowledgeState.REMEMBERED:
            continue
        var semantic := StringName(String(observation.get("semantic_type", "")))
        var actor_id: String = String(observation.get("actor_id", ""))
        var facing: int = int(observation.get("facing", -1))
        var variant: int = _default_variant_for_actor_id(actor_id)
        var selection: ArtSelection = _catalog.resolve_living_actor(semantic, facing, variant)
        var destination: Rect2 = _actor_rect(cell)
        _draw_selection(selection, destination, LAST_SEEN_MODULATION)

func _draw_auditory_cues() -> void:
    for cue: Dictionary in _auditory_cues:
        var cell: Vector2i = cue.get("cell", Vector2i.ZERO)
        if not _cell_in_view(cell):
            continue
        var rect: Rect2 = _cell_rect(cell)
        var center: Vector2 = rect.get_center()
        var strength: float = float(cue.get("strength", 1.0))
        var radius: float = maxf(3.0, _cell_pixels * (0.12 + 0.08 * strength))
        var line_width: float = maxf(1.5, _cell_pixels * 0.05)
        draw_circle(center, radius, SOUND_CUE_COLOR, false, line_width)
        draw_line(center - Vector2(radius * 0.55, 0.0), center + Vector2(radius * 0.55, 0.0), SOUND_CUE_COLOR, line_width)
        draw_line(center - Vector2(0.0, radius * 0.55), center + Vector2(0.0, radius * 0.55), SOUND_CUE_COLOR, line_width)

func _draw_selection(selection: ArtSelection, destination: Rect2, modulation: Color, quarter_turns: int = 0) -> bool:
    if selection == null or not selection.is_found() or selection.source == null:
        return false
    var texture: Texture2D = _texture_for_selection(selection)
    if texture == null:
        return false

    var turns: int = ((quarter_turns % 4) + 4) % 4
    var target: Rect2 = destination
    if turns != 0:
        var center: Vector2 = destination.position + destination.size * 0.5
        draw_set_transform(center, float(turns) * PI * 0.5, Vector2.ONE)
        target = Rect2(-destination.size * 0.5, destination.size)

    var drawn: bool = false
    if selection.is_atlas_region():
        draw_texture_rect_region(texture, target, selection.region(), modulation, false, true)
        drawn = true
    elif not selection.source.atlas:
        draw_texture_rect(texture, target, false, modulation, false)
        drawn = true

    if turns != 0:
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    return drawn

func _texture_for_selection(selection: ArtSelection) -> Texture2D:
    if selection == null or selection.source == null:
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

func _cell_rect(cell: Vector2i) -> Rect2:
    var local := cell - _visible_origin
    return Rect2(
        Vector2(float(local.x) * _cell_pixels, float(local.y) * _cell_pixels),
        Vector2(_cell_pixels, _cell_pixels)
    )

func _actor_rect(cell: Vector2i) -> Rect2:
    var base: Rect2 = _cell_rect(cell)
    var draw_size: float = _cell_pixels * NPC_DRAW_SCALE
    var inset: float = (_cell_pixels - draw_size) * 0.5
    return Rect2(base.position + Vector2(inset, inset), Vector2(draw_size, draw_size))

func _cell_in_view(cell: Vector2i) -> bool:
    if not _view_valid:
        return false
    return cell.x >= _visible_origin.x and cell.x < _visible_origin.x + _visible_size.x \
        and cell.y >= _visible_origin.y and cell.y < _visible_origin.y + _visible_size.y

func _leaf_token(value: StringName) -> String:
    var raw: String = String(value).strip_edges()
    if raw.is_empty():
        return ""
    var dot_index: int = raw.rfind(".")
    if dot_index >= 0 and dot_index < raw.length() - 1:
        return raw.substr(dot_index + 1)
    return raw

func _default_variant_for_actor_id(actor_id: String) -> int:
    var hash_value: int = FNV1A_OFFSET_BASIS
    for byte_value: int in actor_id.to_utf8_buffer():
        hash_value = ((hash_value ^ byte_value) * FNV1A_PRIME) & UINT32_MASK
    return int(hash_value % ArtCatalog.LIVING_ACTOR_VARIANTS)

func _connect_perception() -> void:
    if _perception == null:
        return
    var callable := Callable(self, "_on_perception_changed")
    if not _perception.perception_changed.is_connected(callable):
        _perception.perception_changed.connect(callable)

func _disconnect_perception() -> void:
    if _perception == null:
        return
    var callable := Callable(self, "_on_perception_changed")
    if _perception.perception_changed.is_connected(callable):
        _perception.perception_changed.disconnect(callable)

func _on_perception_changed(_reason: StringName) -> void:
    _request_redraw(&"perception_changed")

func _request_redraw(reason: StringName) -> void:
    redraw_requested.emit(reason)
    queue_redraw()
