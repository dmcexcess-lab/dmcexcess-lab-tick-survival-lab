extends Node2D
class_name PhysicalLightingPresentationRenderer

const MULTIPLY_SHADER: Shader = preload("res://shaders/physical_lighting_multiply.gdshader")
const GLOW_SHADER: Shader = preload("res://shaders/physical_lighting_glow.gdshader")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const ChangeClass = preload("res://scripts/foundation/world/WorldChange.gd")
const PerformanceTelemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")

## Presentation-only visualization of System 27 physical illumination.
## This layer never decides gameplay visibility and never becomes light authority.
## World notifications refresh only for visible terrain/STRUCTURE dirtiness; actor and
## ordinary object movement do not redraw the full light maps.

signal presentation_rebuilt(reason, presentation_revision)

var _lighting: PhysicalLightingService = null
var _world: WorldState = null
var _doors: DoorStateStore = null
var _visible_origin: Vector2i = Vector2i.ZERO
var _visible_size: Vector2i = Vector2i.ZERO
var _cell_pixels: float = 0.0
var _view_valid: bool = false
var _configured: bool = false

var _multiply_sprite: Sprite2D = null
var _glow_sprite: Sprite2D = null
var _multiply_texture: ImageTexture = null
var _glow_texture: ImageTexture = null
var _multiply_image: Image = null
var _glow_image: Image = null
var _texture_size: Vector2i = Vector2i.ZERO

var _presentation_revision: int = 0
var _last_reason: StringName = &""
var _last_build_usec: int = 0
var _last_min_luminance: float = 0.0
var _last_max_luminance: float = 0.0
var _last_glow_cells: int = 0
var _last_lighting_revision: int = 0

func _ready() -> void:
    _ensure_layers()

func configure(
    lighting_service: PhysicalLightingService,
    world_state: WorldState,
    door_state: DoorStateStore
) -> bool:
    if lighting_service == null or world_state == null or door_state == null:
        return false
    _disconnect_sources()
    _lighting = lighting_service
    _world = world_state
    _doors = door_state
    _ensure_layers()
    _connect_sources()
    _configured = true
    if _view_valid:
        return refresh(&"configured")
    return true

func is_configured() -> bool:
    return _configured and _lighting != null and _world != null and _doors != null

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
    if not is_configured():
        return true
    if not _lighting.set_field_bounds(Rect2i(_visible_origin, _visible_size)):
        return false
    if changed:
        return refresh(&"view_changed")
    return true

func refresh(reason: StringName = &"external") -> bool:
    if not is_configured() or not _view_valid:
        return false
    if not _lighting.set_field_bounds(Rect2i(_visible_origin, _visible_size)):
        return false

    var prepared_revision: int = _lighting.prepare_query()
    # Several synchronous world/presentation signals can request the same final
    # light state during one step. Do not rebuild and upload identical maps.
    if prepared_revision == _last_lighting_revision:
        return true

    var started: int = Time.get_ticks_usec()
    _ensure_images()
    if _multiply_image == null or _glow_image == null:
        return false

    var optics: AtmosphericOptics = _lighting.atmosphere()
    var min_luminance: float = 1.0
    var max_luminance: float = 0.0
    var glow_cells: int = 0

    for local_y in range(_visible_size.y):
        for local_x in range(_visible_size.x):
            var cell := _visible_origin + Vector2i(local_x, local_y)
            var sample: IlluminationSample = _lighting.illumination_at_prepared(cell, prepared_revision)
            var tint: Color = _display_tint(sample, optics)
            var luminance: float = clampf(sample.useful_luminance, 0.0, 1.0)
            min_luminance = minf(min_luminance, luminance)
            max_luminance = maxf(max_luminance, luminance)
            _multiply_image.set_pixel(local_x, local_y, Color(tint.r, tint.g, tint.b, luminance))

            var glow_strength: float = _glow_strength(sample)
            if glow_strength > 0.01:
                glow_cells += 1
            _glow_image.set_pixel(local_x, local_y, Color(tint.r, tint.g, tint.b, glow_strength))

    for emitter: LightEmitter in _lighting.emitters():
        if not emitter.active or emitter.profile == null:
            continue
        var local: Vector2i = emitter.origin_cell - _visible_origin
        if local.x < 0 or local.y < 0 or local.x >= _visible_size.x or local.y >= _visible_size.y:
            continue
        var core_strength: float = clampf(
            emitter.profile.base_luminance * emitter.profile.presentation_glow_scale,
            0.0,
            1.0
        )
        if core_strength <= 0.01:
            continue
        var core_color: Color = emitter.profile.tint
        _glow_image.set_pixel(local.x, local.y, Color(core_color.r, core_color.g, core_color.b, core_strength))

    _upload_maps()
    _apply_atmosphere_uniforms(optics)
    _presentation_revision += 1
    _last_reason = reason
    _last_build_usec = Time.get_ticks_usec() - started
    _last_min_luminance = 0.0 if min_luminance > 1.0 else min_luminance
    _last_max_luminance = max_luminance
    _last_glow_cells = glow_cells
    _last_lighting_revision = prepared_revision
    PerformanceTelemetry.record_timing(&"lighting_draw", _last_build_usec)
    PerformanceTelemetry.record_value(&"lighting_draws", _presentation_revision)
    presentation_rebuilt.emit(reason, _presentation_revision)
    return true

func presentation_values_for_cell(cell: Vector2i) -> Dictionary:
    if not is_configured() or not _view_valid or not Rect2i(_visible_origin, _visible_size).has_point(cell):
        return {}
    var optics: AtmosphericOptics = _lighting.atmosphere()
    var sample: IlluminationSample = _lighting.illumination_at(cell)
    return {
        "luminance": sample.useful_luminance,
        "tint": _display_tint(sample, optics),
        "glow_strength": _glow_strength(sample),
        "portal": sample.portal,
        "local_artificial": sample.local_artificial,
        "glare": sample.glare,
        "scatter": sample.scatter,
    }

func presentation_snapshot() -> Dictionary:
    var optics: AtmosphericOptics = null if _lighting == null else _lighting.atmosphere()
    return {
        "configured": is_configured(),
        "view_valid": _view_valid,
        "visible_origin": _visible_origin,
        "visible_size": _visible_size,
        "cell_pixels": _cell_pixels,
        "presentation_revision": _presentation_revision,
        "last_reason": String(_last_reason),
        "last_build_usec": _last_build_usec,
        "last_lighting_revision": _last_lighting_revision,
        "min_luminance": _last_min_luminance,
        "max_luminance": _last_max_luminance,
        "glow_cells": _last_glow_cells,
        "emitter_count": 0 if _lighting == null else _lighting.emitters().size(),
        "wetness": 0.0 if optics == null else optics.wet_surface_factor,
        "scatter_strength": 0.0 if optics == null else optics.scatter_strength,
        "multiply_texture_ready": _multiply_texture != null,
        "glow_texture_ready": _glow_texture != null,
        "texture_size": _texture_size,
    }

func _ensure_layers() -> void:
    if _multiply_sprite != null:
        return

    _multiply_sprite = Sprite2D.new()
    _multiply_sprite.name = "PhysicalLightMultiply"
    _multiply_sprite.centered = false
    _multiply_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    var multiply_material := ShaderMaterial.new()
    multiply_material.shader = MULTIPLY_SHADER
    _multiply_sprite.material = multiply_material
    _multiply_sprite.z_index = 0
    add_child(_multiply_sprite)

    _glow_sprite = Sprite2D.new()
    _glow_sprite.name = "PhysicalLightGlow"
    _glow_sprite.centered = false
    _glow_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    var glow_material := ShaderMaterial.new()
    glow_material.shader = GLOW_SHADER
    _glow_sprite.material = glow_material
    _glow_sprite.z_index = 1
    add_child(_glow_sprite)

func _ensure_images() -> void:
    if _multiply_image != null and _glow_image != null and _multiply_image.get_size() == _visible_size and _glow_image.get_size() == _visible_size:
        return
    _multiply_image = Image.create(_visible_size.x, _visible_size.y, false, Image.FORMAT_RGBA8)
    _glow_image = Image.create(_visible_size.x, _visible_size.y, false, Image.FORMAT_RGBA8)

func _upload_maps() -> void:
    var size_changed: bool = _texture_size != _visible_size
    if _multiply_texture == null or size_changed:
        _multiply_texture = ImageTexture.create_from_image(_multiply_image)
    else:
        _multiply_texture.update(_multiply_image)
    if _glow_texture == null or size_changed:
        _glow_texture = ImageTexture.create_from_image(_glow_image)
    else:
        _glow_texture.update(_glow_image)
    _texture_size = _visible_size

    _multiply_sprite.texture = _multiply_texture
    _glow_sprite.texture = _glow_texture
    var scale_value := Vector2(_cell_pixels, _cell_pixels)
    _multiply_sprite.scale = scale_value
    _glow_sprite.scale = scale_value
    _multiply_sprite.position = Vector2.ZERO
    _glow_sprite.position = Vector2.ZERO

func _apply_atmosphere_uniforms(optics: AtmosphericOptics) -> void:
    var glow_material := _glow_sprite.material as ShaderMaterial
    if glow_material == null:
        return
    glow_material.set_shader_parameter("scatter_strength", optics.scatter_strength)
    glow_material.set_shader_parameter("wetness", optics.wet_surface_factor)
    glow_material.set_shader_parameter("glow_strength", 0.42)

func _display_tint(sample: IlluminationSample, optics: AtmosphericOptics) -> Color:
    var tint: Color = sample.tint
    if tint.r + tint.g + tint.b < 0.01:
        tint = optics.tint
    return Color(
        clampf(tint.r, 0.0, 1.0),
        clampf(tint.g, 0.0, 1.0),
        clampf(tint.b, 0.0, 1.0),
        1.0
    )

func _glow_strength(sample: IlluminationSample) -> float:
    return clampf(
        sample.portal * 0.35
        + sample.glare * 0.86
        + sample.scatter * 0.45,
        0.0,
        1.0
    )

func _connect_sources() -> void:
    if _world != null:
        var changed_callable := Callable(self, "_on_world_changed")
        var batch_callable := Callable(self, "_on_world_batch_changed")
        var reset_callable := Callable(self, "_on_world_reset")
        if not _world.changed.is_connected(changed_callable):
            _world.changed.connect(changed_callable)
        if not _world.batch_changed.is_connected(batch_callable):
            _world.batch_changed.connect(batch_callable)
        if not _world.world_reset.is_connected(reset_callable):
            _world.world_reset.connect(reset_callable)
    if _doors != null:
        var enrolled_callable := Callable(self, "_on_door_enrolled")
        var removed_callable := Callable(self, "_on_door_removed")
        var changed_callable := Callable(self, "_on_door_state_changed")
        var reset_callable := Callable(self, "_on_door_state_reset")
        if not _doors.door_enrolled.is_connected(enrolled_callable):
            _doors.door_enrolled.connect(enrolled_callable)
        if not _doors.door_removed.is_connected(removed_callable):
            _doors.door_removed.connect(removed_callable)
        if not _doors.door_state_changed.is_connected(changed_callable):
            _doors.door_state_changed.connect(changed_callable)
        if not _doors.door_state_reset.is_connected(reset_callable):
            _doors.door_state_reset.connect(reset_callable)

func _disconnect_sources() -> void:
    if _world != null:
        var changed_callable := Callable(self, "_on_world_changed")
        var batch_callable := Callable(self, "_on_world_batch_changed")
        var reset_callable := Callable(self, "_on_world_reset")
        if _world.changed.is_connected(changed_callable):
            _world.changed.disconnect(changed_callable)
        if _world.batch_changed.is_connected(batch_callable):
            _world.batch_changed.disconnect(batch_callable)
        if _world.world_reset.is_connected(reset_callable):
            _world.world_reset.disconnect(reset_callable)
    if _doors != null:
        var enrolled_callable := Callable(self, "_on_door_enrolled")
        var removed_callable := Callable(self, "_on_door_removed")
        var changed_callable := Callable(self, "_on_door_state_changed")
        var reset_callable := Callable(self, "_on_door_state_reset")
        if _doors.door_enrolled.is_connected(enrolled_callable):
            _doors.door_enrolled.disconnect(enrolled_callable)
        if _doors.door_removed.is_connected(removed_callable):
            _doors.door_removed.disconnect(removed_callable)
        if _doors.door_state_changed.is_connected(changed_callable):
            _doors.door_state_changed.disconnect(changed_callable)
        if _doors.door_state_reset.is_connected(reset_callable):
            _doors.door_state_reset.disconnect(reset_callable)

func _on_world_changed(change: WorldChange) -> void:
    if not _view_valid or change == null or _world.is_change_batch_active():
        return
    if change.is_terrain_change():
        if _terrain_change_intersects_view(change):
            refresh(&"terrain_changed")
        return
    if change.affects_channel(Layers.Channel.STRUCTURE) and _cells_intersect_view(change.before_cells, change.after_cells):
        refresh(&"structure_changed")

func _on_world_batch_changed(batch: WorldChangeBatch) -> void:
    if not _view_valid or batch == null:
        return
    var view := Rect2i(_visible_origin, _visible_size)
    if batch.terrain_changed:
        var terrain_rect: Rect2i = batch.terrain_dirty_bounds()
        if terrain_rect.size.x > 0 and terrain_rect.size.y > 0 and view.intersects(terrain_rect):
            refresh(&"world_batch_terrain")
            return
    if batch.channel_changed(Layers.Channel.STRUCTURE):
        var structure_rect: Rect2i = batch.dirty_rect_for_channel(Layers.Channel.STRUCTURE)
        if structure_rect.size.x > 0 and structure_rect.size.y > 0 and view.intersects(structure_rect):
            refresh(&"world_batch_structure")

func _on_world_reset() -> void:
    if _view_valid:
        refresh(&"world_reset")

func _on_door_enrolled(_door_id, _state, _version) -> void:
    if _view_valid and not _world.is_change_batch_active():
        refresh(&"door_enrolled")

func _on_door_removed(_door_id, _previous_state, _version) -> void:
    if _view_valid and not _world.is_change_batch_active():
        refresh(&"door_removed")

func _on_door_state_changed(_door_id, _previous_state, _new_state, _version) -> void:
    if _view_valid and not _world.is_change_batch_active():
        refresh(&"door_state_changed")

func _on_door_state_reset() -> void:
    if _view_valid:
        refresh(&"door_state_reset")

func _terrain_change_intersects_view(change: WorldChange) -> bool:
    var view := Rect2i(_visible_origin, _visible_size)
    if change.kind == ChangeClass.Kind.TERRAIN_BATCH_SET:
        if change.terrain_rect.size.x > 0 and change.terrain_rect.size.y > 0:
            return view.intersects(change.terrain_rect)
        for cell: Vector2i in change.terrain_cells:
            if view.has_point(cell):
                return true
        return false
    return view.has_point(change.terrain_cell)

func _cells_intersect_view(before_cells: Array[Vector2i], after_cells: Array[Vector2i]) -> bool:
    var view := Rect2i(_visible_origin, _visible_size)
    for cell: Vector2i in before_cells:
        if view.has_point(cell):
            return true
    for cell: Vector2i in after_cells:
        if view.has_point(cell):
            return true
    return false
