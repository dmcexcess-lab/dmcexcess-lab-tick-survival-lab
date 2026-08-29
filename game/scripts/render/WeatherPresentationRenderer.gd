extends Node2D
class_name WeatherPresentationRenderer

const PerformanceTelemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")
const AtmosphereSurfaceClass = preload("res://scripts/render/WeatherAtmosphereSurface.gd")

## System 28 presentation owner. Continuous rain/fog are one persistent GPU surface.
## CPU work is limited to low-rate debris state, lightning lifetime, and cached shelter
## mask maintenance. Physical Weather remains authoritative elsewhere.

const PRESENTATION_STEP_SECONDS: float = 0.10
const TARGET_HZ: int = 10
const WEATHER_PIXEL_SIZE: int = 2
const MAX_DEBRIS: int = 3
const MAX_CATCHUP_STEPS: int = 4
const MASK_POLL_SECONDS: float = 0.25
const LIGHTNING_VISUAL_SECONDS: float = 0.32

var _weather: WeatherService = null
var _sky: SkyExposureQuery = null
var _surface: WeatherAtmosphereSurface = null
var _visible_origin: Vector2i = Vector2i.ZERO
var _visible_size: Vector2i = Vector2i.ZERO
var _cell_pixels: float = 0.0
var _view_valid: bool = false
var _surface_size_pixels: Vector2 = Vector2.ZERO
var _camera_snapshot: Dictionary = {}

var _exposure_texture: ImageTexture = null
var _exposure_mask_size: Vector2i = Vector2i.ZERO
var _exposure_mask_rebuilds: int = 0
var _last_sky_rebuild_count: int = -1
var _mask_poll_accumulator: float = 0.0

var _accumulator: float = 0.0
var _presentation_step: int = 0
var _presentation_updates: int = 0
var _redraw_requests: int = 0
var _draw_count: int = 0
var _last_draw_usec: int = 0
var _last_descriptor: Dictionary = {}
var _debris: Array[Dictionary] = []
var _ambient_countdown: float = 18.0
var _rng_state: int = 0x13579b

var _lightning_visual_remaining: float = 0.0
var _lightning_visual_id: String = ""

func _ready() -> void:
    _ensure_surface()
    set_process(false)

func configure(weather_service: WeatherService, sky_exposure: SkyExposureQuery) -> bool:
    if weather_service == null or not weather_service.is_ready() or sky_exposure == null or not sky_exposure.is_ready():
        return false
    _ensure_surface()
    if _surface == null or not _surface.is_ready():
        return false
    _weather = weather_service
    _sky = sky_exposure
    _last_descriptor = weather_service.presentation_descriptor()
    _rng_state = int(_last_descriptor.get("presentation_seed", 0x13579b)) | 1
    _ambient_countdown = _next_ambient_delay(float(_last_descriptor.get("wind_strength", 0.0)))
    _surface.set_weather_descriptor(_last_descriptor)
    _push_debris_uniforms()

    var weather_callable := Callable(self, "_on_weather_changed")
    if not _weather.weather_changed.is_connected(weather_callable):
        _weather.weather_changed.connect(weather_callable)
    var lightning_callable := Callable(self, "_on_lightning_started")
    if not _weather.lightning_started.is_connected(lightning_callable):
        _weather.lightning_started.connect(lightning_callable)
    set_process(true)
    return true

func is_configured() -> bool:
    return _weather != null \
        and _sky != null \
        and _surface != null \
        and _weather.is_ready() \
        and _sky.is_ready() \
        and _surface.is_ready()

func set_visible_window(origin: Vector2i, size_cells: Vector2i, cell_pixels: float) -> bool:
    if size_cells.x <= 0 or size_cells.y <= 0 or cell_pixels <= 0.0:
        return false
    _ensure_surface()
    if _surface == null:
        return false
    _visible_origin = origin
    _visible_size = size_cells
    _cell_pixels = cell_pixels
    _view_valid = true
    _surface_size_pixels = Vector2(
        float(_visible_size.x) * _cell_pixels,
        float(_visible_size.y) * _cell_pixels
    )
    if not _surface.set_surface_size(_surface_size_pixels):
        return false
    if not _refresh_exposure_mask(true):
        return false
    if _camera_snapshot.is_empty():
        _surface.set_mask_mapping(Vector2.ZERO, Vector2.ONE)
    else:
        _sync_mask_mapping()
    return true

func set_camera_presentation(snapshot: Dictionary) -> bool:
    if not _view_valid:
        return false
    var camera_value: Variant = snapshot.get("camera_global_position", null)
    var zoom_value: Variant = snapshot.get("camera_zoom", null)
    if typeof(camera_value) != TYPE_VECTOR2 or typeof(zoom_value) != TYPE_VECTOR2:
        return false
    var zoom: Vector2 = zoom_value
    if absf(zoom.x) <= 0.0001 or absf(zoom.y) <= 0.0001:
        return false
    _camera_snapshot = snapshot.duplicate(true)
    return _sync_mask_mapping()

func advance_presentation(delta_seconds: float) -> int:
    if not is_configured() or not _view_valid or delta_seconds <= 0.0:
        return 0
    _accumulator += minf(delta_seconds, PRESENTATION_STEP_SECONDS * float(MAX_CATCHUP_STEPS))
    var steps: int = mini(int(floor(_accumulator / PRESENTATION_STEP_SECONDS)), MAX_CATCHUP_STEPS)
    if steps <= 0:
        return 0
    _accumulator -= float(steps) * PRESENTATION_STEP_SECONDS
    for _i in range(steps):
        _step_housekeeping()
    return steps

func force_ambient_event(kind: StringName = &"leaf") -> bool:
    if not is_configured() or not _view_valid:
        return false
    var cap: int = _debris_cap(float(_last_descriptor.get("wind_strength", 0.0)))
    if _debris.size() >= cap:
        return false
    _debris.append(_new_debris(kind, float(_last_descriptor.get("wind_strength", 0.0))))
    _push_debris_uniforms()
    return true

func presentation_snapshot() -> Dictionary:
    var continuous: bool = _continuous_weather_active(_last_descriptor)
    var surface_snapshot: Dictionary = {} if _surface == null else _surface.debug_snapshot()
    return {
        "configured": is_configured(),
        "screen_space_overlay": true,
        "shader_atmosphere": true,
        "atmosphere_surface_count": 0 if _surface == null else 1,
        "target_hz": TARGET_HZ,
        "presentation_step_seconds": PRESENTATION_STEP_SECONDS,
        "presentation_step": _presentation_step,
        "presentation_updates": _presentation_updates,
        "redraw_requests": _redraw_requests,
        "draw_count": _draw_count,
        "last_draw_usec": _last_draw_usec,
        "visible_origin": _visible_origin,
        "visible_size": _visible_size,
        "overlay_size_pixels": Vector2i(int(round(_surface_size_pixels.x)), int(round(_surface_size_pixels.y))),
        "weather_pixel_size": WEATHER_PIXEL_SIZE,
        "virtual_surface_size": _exposure_mask_size,
        "virtual_pixel_count": _exposure_mask_size.x * _exposure_mask_size.y,
        "exposure_mask_size": _exposure_mask_size,
        "exposure_mask_rebuilds": _exposure_mask_rebuilds,
        "active_debris": _debris.size(),
        "max_debris": MAX_DEBRIS,
        "last_rain_streaks": 0,
        "last_fog_patches": 0,
        "last_draw_primitives": 0,
        "cpu_continuous_redraws": 0,
        "continuous_active": continuous,
        "sleeping": not continuous and _debris.is_empty() and _lightning_visual_remaining <= 0.0,
        "weather_kind": String(_last_descriptor.get("weather_kind", "")),
        "camera_motion_redraws": 0,
        "lightning_visual_active": _lightning_visual_remaining > 0.0,
        "lightning_visual_id": _lightning_visual_id,
        "lightning_visual_remaining": _lightning_visual_remaining,
        "surface": surface_snapshot,
    }

func _process(delta: float) -> void:
    if not is_configured():
        return
    var safe_delta: float = maxf(0.0, delta)
    advance_presentation(safe_delta)
    _mask_poll_accumulator += safe_delta
    if _mask_poll_accumulator >= MASK_POLL_SECONDS:
        _mask_poll_accumulator = fmod(_mask_poll_accumulator, MASK_POLL_SECONDS)
        _refresh_exposure_mask(false)
    if _lightning_visual_remaining > 0.0:
        _lightning_visual_remaining = maxf(0.0, _lightning_visual_remaining - safe_delta)
        if _lightning_visual_remaining <= 0.0:
            _lightning_visual_id = ""
            if _surface != null:
                _surface.clear_lightning()

func _step_housekeeping() -> void:
    var started: int = Time.get_ticks_usec()
    _presentation_step += 1
    _presentation_updates += 1
    _advance_debris(PRESENTATION_STEP_SECONDS)

    var continuous: bool = _continuous_weather_active(_last_descriptor)
    var wind_strength: float = float(_last_descriptor.get("wind_strength", 0.0))
    if not continuous and _debris.is_empty() and String(_last_descriptor.get("weather_kind", "")) == "clear":
        _ambient_countdown -= PRESENTATION_STEP_SECONDS
        if _ambient_countdown <= 0.0:
            force_ambient_event(_random_ambient_kind())
            _ambient_countdown = _next_ambient_delay(wind_strength)
    _push_debris_uniforms()

    _last_draw_usec = Time.get_ticks_usec() - started
    _draw_count += 1
    PerformanceTelemetry.record_timing(&"weather_draw", _last_draw_usec)
    PerformanceTelemetry.record_value(&"weather_draws", _draw_count)
    PerformanceTelemetry.record_value(&"weather_primitives", 0)
    PerformanceTelemetry.record_value(&"weather_redraw_requests", 0)

func _refresh_exposure_mask(force: bool) -> bool:
    if _sky == null or not _view_valid or _visible_size.x <= 0 or _visible_size.y <= 0:
        return false
    var bounds := Rect2i(_visible_origin, _visible_size)
    var sky_snapshot: Dictionary = _sky.debug_snapshot(bounds)
    var source_rebuild_count: int = int(sky_snapshot.get("rebuild_count", -1))
    if not force and source_rebuild_count == _last_sky_rebuild_count and _exposure_texture != null:
        return true

    var started: int = Time.get_ticks_usec()
    var exposed: Dictionary = _sky.exposure_mask(bounds)
    var image := Image.create(_visible_size.x, _visible_size.y, false, Image.FORMAT_RGBA8)
    image.fill(Color.BLACK)
    for y in range(_visible_size.y):
        for x in range(_visible_size.x):
            if exposed.has(_visible_origin + Vector2i(x, y)):
                image.set_pixel(x, y, Color.WHITE)

    if _exposure_texture == null or _exposure_mask_size != _visible_size:
        _exposure_texture = ImageTexture.create_from_image(image)
    else:
        _exposure_texture.update(image)
    _exposure_mask_size = _visible_size
    _last_sky_rebuild_count = source_rebuild_count
    _exposure_mask_rebuilds += 1
    if _surface == null or not _surface.set_exposure_texture(_exposure_texture):
        return false
    _sync_mask_mapping()
    PerformanceTelemetry.record_timing(&"weather_mask_upload", Time.get_ticks_usec() - started)
    PerformanceTelemetry.record_value(&"weather_mask_uploads", _exposure_mask_rebuilds)
    return true

func _sync_mask_mapping() -> bool:
    if _surface == null or not _view_valid or _surface_size_pixels.x <= 0.0 or _surface_size_pixels.y <= 0.0:
        return false
    if _camera_snapshot.is_empty() or get_viewport() == null:
        return _surface.set_mask_mapping(Vector2.ZERO, Vector2.ONE)
    var camera_value: Variant = _camera_snapshot.get("camera_global_position", null)
    var zoom_value: Variant = _camera_snapshot.get("camera_zoom", null)
    if typeof(camera_value) != TYPE_VECTOR2 or typeof(zoom_value) != TYPE_VECTOR2:
        return false
    var camera_global: Vector2 = camera_value
    var zoom: Vector2 = zoom_value
    zoom = Vector2(maxf(0.001, absf(zoom.x)), maxf(0.001, absf(zoom.y)))
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return false
    var visible_world_span := Vector2(viewport_size.x / zoom.x, viewport_size.y / zoom.y)
    var camera_local: Vector2 = to_local(camera_global)
    var top_left: Vector2 = camera_local - visible_world_span * 0.5
    var origin_uv := Vector2(
        top_left.x / _surface_size_pixels.x,
        top_left.y / _surface_size_pixels.y
    )
    var scale_uv := Vector2(
        visible_world_span.x / _surface_size_pixels.x,
        visible_world_span.y / _surface_size_pixels.y
    )
    return _surface.set_mask_mapping(origin_uv, scale_uv)

func _on_weather_changed(_snapshot: Variant) -> void:
    if _weather == null or _surface == null:
        return
    _last_descriptor = _weather.presentation_descriptor()
    _surface.set_weather_descriptor(_last_descriptor)
    _push_debris_uniforms()

func _on_lightning_started(event: Variant) -> void:
    if event == null or not event is LightningEvent or _surface == null:
        return
    var lightning: LightningEvent = event
    if not lightning.is_valid():
        return
    _lightning_visual_id = lightning.event_id
    _lightning_visual_remaining = LIGHTNING_VISUAL_SECONDS
    _surface.start_lightning(
        lightning.bolt_seed,
        lightning.intensity,
        float(Time.get_ticks_msec()) / 1000.0,
        LIGHTNING_VISUAL_SECONDS
    )

func _push_debris_uniforms() -> void:
    if _surface == null:
        return
    var wind: Vector2 = _last_descriptor.get("wind_direction", Vector2.RIGHT)
    _surface.set_debris(_debris, wind)

func _advance_debris(delta_seconds: float) -> void:
    if _debris.is_empty():
        return
    var remaining: Array[Dictionary] = []
    for event: Dictionary in _debris:
        var duration: float = maxf(0.8, float(event.get("duration", 3.0)))
        event["progress"] = float(event.get("progress", 0.0)) + delta_seconds / duration
        if float(event["progress"]) < 1.0:
            remaining.append(event)
    _debris = remaining

func _new_debris(kind: StringName, wind_strength: float) -> Dictionary:
    var chosen: String = String(kind)
    if chosen != "leaf" and chosen != "paper" and chosen != "dust":
        chosen = "leaf"
    var r1: float = _random_unit()
    var r2: float = _random_unit()
    return {
        "kind": chosen,
        "progress": 0.0,
        "lane": 0.12 + r1 * 0.76,
        "duration": lerpf(4.8, 2.0, clampf(wind_strength, 0.0, 1.0)) * lerpf(0.85, 1.15, r2),
        "phase": _random_unit() * TAU,
    }

func _random_ambient_kind() -> StringName:
    var value: float = _random_unit()
    if value < 0.58:
        return &"leaf"
    if value < 0.82:
        return &"paper"
    return &"dust"

func _next_ambient_delay(wind_strength: float) -> float:
    var base: float = lerpf(15.0, 40.0, _random_unit())
    return maxf(4.0, base * (1.0 - 0.65 * clampf(wind_strength, 0.0, 1.0)))

func _debris_cap(wind_strength: float) -> int:
    if wind_strength >= 0.70:
        return MAX_DEBRIS
    if wind_strength >= 0.30:
        return 2
    return 1

func _continuous_weather_active(descriptor: Dictionary) -> bool:
    if descriptor.is_empty():
        return false
    return float(descriptor.get("precipitation", 0.0)) >= 0.04 \
        or float(descriptor.get("fog_density", 0.0)) >= 0.08

func _ensure_surface() -> void:
    if _surface != null:
        return
    _surface = AtmosphereSurfaceClass.new()
    _surface.name = "AtmosphereSurface"
    add_child(_surface)

func _random_unit() -> float:
    _rng_state = int((_rng_state * 1103515245 + 12345) & 0x7fffffff)
    return float(_rng_state) / float(0x7fffffff)
