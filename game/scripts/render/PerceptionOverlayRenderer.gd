extends Node2D
class_name PerceptionOverlayRenderer

const RoadTopology = preload("res://scripts/art/RoadArtTopology.gd")
const PropOrientation = preload("res://scripts/art/PropArtOrientationCatalog.gd")

## Presentation-only knowledge mask. Hidden live world is blacked out before stale memory redraw.

signal redraw_requested(reason: StringName)

const TRUE_FOG_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const MEMORY_DAY_LUMINANCE: float = 0.30
const MEMORY_NIGHT_LUMINANCE: float = 0.10
const LAST_SEEN_MODULATION := Color(0.48, 0.54, 0.66, 0.50)
const SOUND_CUE_COLOR := Color(1.0, 0.82, 0.20, 0.95)
const SEEN_SOUND_LIFETIME_MSEC: int = 1000
const SEEN_SOUND_FADE_START_MSEC: int = 350
const SOUND_FADE_PULSE_SECONDS: float = 0.05
const SOUND_MODE_SEEN: String = "seen_transient"
const SOUND_MODE_UNSEEN: String = "unseen_latched"
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
var _auditory_upstream_ids: Dictionary = {}
var _auditory_suppressed_ids: Dictionary = {}
var _auditory_fade_timer: Timer = null
var _ambient_light_level: float = 1.0

func _ready() -> void:
    _ensure_auditory_timer()

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
    var incoming_ids: Dictionary = {}
    for value: Variant in cues:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var cue: Dictionary = value
        var cell_value: Variant = cue.get("cell", null)
        if typeof(cell_value) != TYPE_VECTOR2I:
            return false
        var cell: Vector2i = cell_value
        var category: String = String(cue.get("category", "sound")).strip_edges()
        if category.is_empty():
            category = "sound"
        var word: String = String(cue.get("word", category)).strip_edges()
        if word.is_empty():
            word = "NOISE"
        var heard_tick: int = int(cue.get("heard_tick", -1))
        var cue_id: String = String(cue.get("cue_id", "")).strip_edges()
        if cue_id.is_empty():
            cue_id = _legacy_cue_id(cell, category, word, heard_tick)
        var group_id: String = String(cue.get("group_id", "")).strip_edges()
        if group_id.is_empty():
            group_id = cue_id
        if incoming_ids.has(cue_id):
            return false
        incoming_ids[cue_id] = true
        normalized.append({
            "cue_id": cue_id,
            "group_id": group_id,
            "cell": cell,
            "radius_cells": maxi(0, int(cue.get("radius_cells", 0))),
            "strength": clampf(float(cue.get("strength", 1.0)), 0.0, 1.0),
            "certainty": clampf(float(cue.get("certainty", 1.0)), 0.0, 1.0),
            "category": category,
            "word": word,
            "heard_tick": heard_tick,
            "expiry_tick": int(cue.get("expiry_tick", -1)),
        })

    for key: Variant in _auditory_suppressed_ids.keys():
        var suppressed_id: String = String(key)
        if not incoming_ids.has(suppressed_id):
            _auditory_suppressed_ids.erase(suppressed_id)
    _auditory_upstream_ids = incoming_ids.duplicate()

    var now_msec: int = Time.get_ticks_msec()
    for cue: Dictionary in normalized:
        var cue_id: String = String(cue.get("cue_id", ""))
        if _auditory_suppressed_ids.has(cue_id):
            continue
        var group_id: String = String(cue.get("group_id", ""))
        _remove_replaced_group_cue(group_id, cue_id)
        var existing_index: int = _auditory_cue_index(cue_id)
        if existing_index >= 0:
            var existing: Dictionary = _auditory_cues[existing_index]
            cue["presentation_mode"] = existing.get("presentation_mode", SOUND_MODE_UNSEEN)
            cue["started_msec"] = int(existing.get("started_msec", now_msec))
            _auditory_cues[existing_index] = cue
            continue
        var mode: String = SOUND_MODE_UNSEEN
        if is_configured() and _perception.knowledge_state(cue.get("cell", Vector2i.ZERO)) == ObserverPerceptionService.KnowledgeState.VISIBLE:
            mode = SOUND_MODE_SEEN
        cue["presentation_mode"] = mode
        cue["started_msec"] = now_msec
        _auditory_cues.append(cue)

    _prune_seen_cues(now_msec)
    _update_auditory_timer()
    _request_redraw(&"auditory_cues_changed")
    return true

func auditory_cues() -> Array[Dictionary]:
    _prune_seen_cues(Time.get_ticks_msec())
    return _auditory_cues.duplicate(true)

func notify_observer_decision_unpaused() -> int:
    var removed: int = 0
    for index in range(_auditory_cues.size() - 1, -1, -1):
        var cue: Dictionary = _auditory_cues[index]
        if String(cue.get("presentation_mode", "")) != SOUND_MODE_UNSEEN:
            continue
        var cue_id: String = String(cue.get("cue_id", ""))
        if _auditory_upstream_ids.has(cue_id):
            _auditory_suppressed_ids[cue_id] = true
        _auditory_cues.remove_at(index)
        removed += 1
    if removed > 0:
        _update_auditory_timer()
        _request_redraw(&"auditory_unseen_cues_cleared")
    return removed

static func seen_cue_alpha_for_age_msec(age_msec: int) -> float:
    if age_msec <= SEEN_SOUND_FADE_START_MSEC:
        return 1.0
    if age_msec >= SEEN_SOUND_LIFETIME_MSEC:
        return 0.0
    return 1.0 - float(age_msec - SEEN_SOUND_FADE_START_MSEC) / float(SEEN_SOUND_LIFETIME_MSEC - SEEN_SOUND_FADE_START_MSEC)

func set_ambient_light_level(level: float) -> bool:
    if is_nan(level) or is_inf(level):
        return false
    var normalized: float = clampf(level, 0.0, 1.0)
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

func planned_cell_counts() -> Dictionary:
    _prune_seen_cues(Time.get_ticks_msec())
    var counts := {
        "visible": 0,
        "remembered": 0,
        "unseen": 0,
        "remembered_props": 0,
        "last_seen": 0,
        "auditory": 0,
        "auditory_offscreen": 0,
        "auditory_seen_transient": 0,
        "auditory_unseen_latched": 0,
    }
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
        counts["auditory"] += 1
        if String(cue.get("presentation_mode", "")) == SOUND_MODE_SEEN:
            counts["auditory_seen_transient"] += 1
        else:
            counts["auditory_unseen_latched"] += 1
        if not _cell_in_view(cue_cell):
            counts["auditory_offscreen"] += 1
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
    var now_msec: int = Time.get_ticks_msec()
    for cue: Dictionary in _auditory_cues:
        var cell: Vector2i = cue.get("cell", Vector2i.ZERO)
        var word: String = String(cue.get("word", "NOISE")).strip_edges()
        if word.is_empty():
            word = "NOISE"
        var position: Vector2 = _cell_rect(cell).get_center() if _cell_in_view(cell) else _offscreen_sound_position(cell)
        var display_word: String = word if _cell_in_view(cell) else _offscreen_word(word, cell)
        _draw_sound_word(display_word, position, cue, now_msec)

func _draw_sound_word(word: String, center: Vector2, cue: Dictionary, now_msec: int) -> void:
    var strength: float = clampf(float(cue.get("strength", 1.0)), 0.0, 1.0)
    var certainty: float = clampf(float(cue.get("certainty", 1.0)), 0.0, 1.0)
    var presentation_alpha: float = 1.0
    if String(cue.get("presentation_mode", "")) == SOUND_MODE_SEEN:
        presentation_alpha = seen_cue_alpha_for_age_msec(maxi(0, now_msec - int(cue.get("started_msec", now_msec))))
    if presentation_alpha <= 0.0:
        return
    var font: Font = ThemeDB.fallback_font
    var font_size: int = clampi(int(round(_cell_pixels * (0.42 + strength * 0.16))), 10, 22)
    var color := SOUND_CUE_COLOR
    color.a = clampf(0.62 + strength * 0.28 + certainty * 0.08, 0.62, 0.98) * presentation_alpha
    var width: float = maxf(_cell_pixels * 3.5, 96.0)
    var baseline := Vector2(center.x - width * 0.5, center.y + float(font_size) * 0.35)
    draw_string(font, baseline, word, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)

func _offscreen_sound_position(cell: Vector2i) -> Vector2:
    var viewport_size := Vector2(float(_visible_size.x) * _cell_pixels, float(_visible_size.y) * _cell_pixels)
    var center := viewport_size * 0.5
    var view_center_cell := Vector2(
        float(_visible_origin.x) + float(_visible_size.x) * 0.5,
        float(_visible_origin.y) + float(_visible_size.y) * 0.5
    )
    var delta := Vector2(float(cell.x) - view_center_cell.x, float(cell.y) - view_center_cell.y)
    var margin: float = maxf(14.0, _cell_pixels * 0.55)
    var position := center + delta * _cell_pixels
    if absf(delta.x) >= absf(delta.y):
        position.x = margin if delta.x < 0.0 else viewport_size.x - margin
        position.y = clampf(position.y, margin, viewport_size.y - margin)
    else:
        position.y = margin if delta.y < 0.0 else viewport_size.y - margin
        position.x = clampf(position.x, margin, viewport_size.x - margin)
    return position

func _offscreen_word(word: String, cell: Vector2i) -> String:
    var view_center_cell := Vector2(
        float(_visible_origin.x) + float(_visible_size.x) * 0.5,
        float(_visible_origin.y) + float(_visible_size.y) * 0.5
    )
    var delta := Vector2(float(cell.x) - view_center_cell.x, float(cell.y) - view_center_cell.y)
    if absf(delta.x) >= absf(delta.y):
        return "< %s" % word if delta.x < 0.0 else "%s >" % word
    return "^ %s" % word if delta.y < 0.0 else "v %s" % word

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

func _auditory_cue_index(cue_id: String) -> int:
    for index in range(_auditory_cues.size()):
        if String(_auditory_cues[index].get("cue_id", "")) == cue_id:
            return index
    return -1

func _remove_replaced_group_cue(group_id: String, keep_cue_id: String) -> void:
    if group_id.is_empty():
        return
    for index in range(_auditory_cues.size() - 1, -1, -1):
        var cue: Dictionary = _auditory_cues[index]
        if String(cue.get("group_id", "")) == group_id and String(cue.get("cue_id", "")) != keep_cue_id:
            _auditory_cues.remove_at(index)

func _prune_seen_cues(now_msec: int) -> int:
    var removed: int = 0
    for index in range(_auditory_cues.size() - 1, -1, -1):
        var cue: Dictionary = _auditory_cues[index]
        if String(cue.get("presentation_mode", "")) != SOUND_MODE_SEEN:
            continue
        var age_msec: int = maxi(0, now_msec - int(cue.get("started_msec", now_msec)))
        if age_msec < SEEN_SOUND_LIFETIME_MSEC:
            continue
        var cue_id: String = String(cue.get("cue_id", ""))
        if _auditory_upstream_ids.has(cue_id):
            _auditory_suppressed_ids[cue_id] = true
        _auditory_cues.remove_at(index)
        removed += 1
    return removed

func _has_seen_transient_cues() -> bool:
    for cue: Dictionary in _auditory_cues:
        if String(cue.get("presentation_mode", "")) == SOUND_MODE_SEEN:
            return true
    return false

func _ensure_auditory_timer() -> void:
    if _auditory_fade_timer != null or not is_inside_tree():
        return
    _auditory_fade_timer = Timer.new()
    _auditory_fade_timer.name = "AuditoryCueFadeTimer"
    _auditory_fade_timer.wait_time = SOUND_FADE_PULSE_SECONDS
    _auditory_fade_timer.one_shot = false
    _auditory_fade_timer.process_callback = Timer.TIMER_PROCESS_IDLE
    _auditory_fade_timer.timeout.connect(_on_auditory_fade_timer_timeout)
    add_child(_auditory_fade_timer)

func _update_auditory_timer() -> void:
    _ensure_auditory_timer()
    if _auditory_fade_timer == null:
        return
    if _has_seen_transient_cues():
        if _auditory_fade_timer.is_stopped():
            _auditory_fade_timer.start()
    elif not _auditory_fade_timer.is_stopped():
        _auditory_fade_timer.stop()

func _legacy_cue_id(cell: Vector2i, category: String, word: String, heard_tick: int) -> String:
    return "legacy.%d.%d.%d.%s.%s" % [cell.x, cell.y, heard_tick, category, word]

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

func _on_auditory_fade_timer_timeout() -> void:
    var removed: int = _prune_seen_cues(Time.get_ticks_msec())
    if removed > 0 or _has_seen_transient_cues():
        _request_redraw(&"auditory_seen_fade")
    _update_auditory_timer()

func _request_redraw(reason: StringName) -> void:
    redraw_requested.emit(reason)
    queue_redraw()
