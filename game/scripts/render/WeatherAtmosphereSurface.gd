extends Node2D
class_name WeatherAtmosphereSurface

const AtmosphereShader = preload("res://shaders/weather_atmosphere.gdshader")

## One persistent canvas surface for all System 28 cosmetic atmosphere. The shader
## uses SCREEN_UV and TIME, so rain/fog continue without CPU redraw/phase work.

const RAIN_PIXEL_SIZE: float = 2.0
const RAIN_FPS: float = 14.0
const FOG_PIXEL_SIZE: float = 2.0
const FOG_FPS: float = 4.0

var _surface_size: Vector2 = Vector2.ZERO
var _shader_material: ShaderMaterial = null
var _exposure_texture: Texture2D = null
var _mask_uv_origin: Vector2 = Vector2.ZERO
var _mask_uv_scale: Vector2 = Vector2.ONE
var _descriptor_updates: int = 0
var _mapping_updates: int = 0
var _debris_updates: int = 0
var _lightning_updates: int = 0

func _ready() -> void:
    _ensure_material()

func is_ready() -> bool:
    _ensure_material()
    return _shader_material != null

func set_surface_size(size_pixels: Vector2) -> bool:
    if size_pixels.x <= 0.0 or size_pixels.y <= 0.0:
        return false
    if _surface_size.is_equal_approx(size_pixels):
        return true
    _surface_size = size_pixels
    queue_redraw()
    return true

func set_exposure_texture(texture: Texture2D) -> bool:
    if texture == null:
        return false
    _ensure_material()
    if _shader_material == null:
        return false
    _exposure_texture = texture
    _shader_material.set_shader_parameter("exposure_mask", _exposure_texture)
    return true

func set_mask_mapping(origin_uv: Vector2, scale_uv: Vector2) -> bool:
    if scale_uv.x <= 0.0 or scale_uv.y <= 0.0:
        return false
    _ensure_material()
    if _shader_material == null:
        return false
    _mask_uv_origin = origin_uv
    _mask_uv_scale = scale_uv
    _shader_material.set_shader_parameter("mask_uv_origin", _mask_uv_origin)
    _shader_material.set_shader_parameter("mask_uv_scale", _mask_uv_scale)
    _mapping_updates += 1
    return true

func set_weather_descriptor(descriptor: Dictionary) -> bool:
    if descriptor.is_empty():
        return false
    _ensure_material()
    if _shader_material == null:
        return false
    var direction: Vector2 = descriptor.get("wind_direction", Vector2.RIGHT)
    if direction.length_squared() <= 0.0001:
        direction = Vector2.RIGHT
    else:
        direction = direction.normalized()
    _shader_material.set_shader_parameter("precipitation", clampf(float(descriptor.get("precipitation", 0.0)), 0.0, 1.0))
    _shader_material.set_shader_parameter("fog_density", clampf(float(descriptor.get("fog_density", 0.0)), 0.0, 1.0))
    _shader_material.set_shader_parameter("wind_direction", direction)
    _shader_material.set_shader_parameter("wind_strength", clampf(float(descriptor.get("wind_strength", 0.0)), 0.0, 1.0))
    _shader_material.set_shader_parameter("presentation_seed", float(int(descriptor.get("presentation_seed", 1))))
    _descriptor_updates += 1
    return true

func set_debris(records: Array[Dictionary], wind_direction: Vector2) -> bool:
    _ensure_material()
    if _shader_material == null:
        return false
    var from_left: bool = wind_direction.x >= 0.0
    for i in range(3):
        var data := Vector4(-1.0, -1.0, 0.0, 0.0)
        var kind: float = 0.0
        if i < records.size():
            var event: Dictionary = records[i]
            var progress: float = clampf(float(event.get("progress", 0.0)), 0.0, 1.0)
            var lane: float = clampf(float(event.get("lane", 0.5)), 0.04, 0.96)
            var x_norm: float = progress if from_left else 1.0 - progress
            var wobble: float = sin(progress * TAU * 2.0 + float(event.get("phase", 0.0))) * 0.035
            var chosen: String = String(event.get("kind", "leaf"))
            if chosen == "paper":
                kind = 1.0
            elif chosen == "dust":
                kind = 2.0
            data = Vector4(x_norm, clampf(lane + wobble, 0.04, 0.96), 1.0, 1.0)
        _shader_material.set_shader_parameter("debris%d" % i, data)
        _shader_material.set_shader_parameter("debris_kind%d" % i, kind)
    _debris_updates += 1
    return true

func start_lightning(seed: int, intensity: float, start_time_seconds: float, duration_seconds: float) -> bool:
    _ensure_material()
    if _shader_material == null or duration_seconds <= 0.0:
        return false
    _shader_material.set_shader_parameter("lightning_active", 1.0)
    _shader_material.set_shader_parameter("lightning_seed", float(seed))
    _shader_material.set_shader_parameter("lightning_intensity", clampf(intensity, 0.0, 1.0))
    _shader_material.set_shader_parameter("lightning_start_time", maxf(0.0, start_time_seconds))
    _shader_material.set_shader_parameter("lightning_duration", duration_seconds)
    _lightning_updates += 1
    return true

func clear_lightning() -> void:
    _ensure_material()
    if _shader_material == null:
        return
    _shader_material.set_shader_parameter("lightning_active", 0.0)
    _lightning_updates += 1

func debug_snapshot() -> Dictionary:
    return {
        "ready": is_ready(),
        "surface_size": _surface_size,
        "exposure_texture_ready": _exposure_texture != null,
        "mask_uv_origin": _mask_uv_origin,
        "mask_uv_scale": _mask_uv_scale,
        "descriptor_updates": _descriptor_updates,
        "mapping_updates": _mapping_updates,
        "debris_updates": _debris_updates,
        "lightning_updates": _lightning_updates,
        "rain_pixel_size": RAIN_PIXEL_SIZE,
        "rain_fps": RAIN_FPS,
        "fog_pixel_size": FOG_PIXEL_SIZE,
        "fog_fps": FOG_FPS,
    }

func _draw() -> void:
    if _surface_size.x <= 0.0 or _surface_size.y <= 0.0:
        return
    draw_rect(Rect2(Vector2.ZERO, _surface_size), Color.WHITE, true)

func _ensure_material() -> void:
    if _shader_material != null:
        return
    _shader_material = ShaderMaterial.new()
    _shader_material.shader = AtmosphereShader
    _shader_material.set_shader_parameter("rain_pixel_size", RAIN_PIXEL_SIZE)
    _shader_material.set_shader_parameter("rain_fps", RAIN_FPS)
    _shader_material.set_shader_parameter("fog_pixel_size", FOG_PIXEL_SIZE)
    _shader_material.set_shader_parameter("fog_fps", FOG_FPS)
    material = _shader_material
