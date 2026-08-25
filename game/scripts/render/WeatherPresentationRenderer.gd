extends Node2D
class_name WeatherPresentationRenderer

const PerformanceTelemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")

## Low-overhead System 28 presentation. Weather graphics are a screen-space
## atmosphere overlay; physical Weather remains world/simulation truth elsewhere.
## No rain/fog/debris object is a Node or simulation entity.

const PRESENTATION_STEP_SECONDS: float = 0.05
const TARGET_HZ: int = 20
const MIN_WEATHER_PIXEL_SIZE: int = 4
const MAX_VIRTUAL_AXIS: int = 256
const MAX_RAIN_STREAKS: int = 180
const MAX_FOG_PATCHES: int = 36
const MAX_DEBRIS: int = 3
const MAX_CATCHUP_STEPS: int = 4
const LIGHTNING_VISUAL_SECONDS: float = 0.32

const RAIN_COLOR := Color(0.72, 0.82, 0.92, 0.72)
const STORM_RAIN_COLOR := Color(0.64, 0.76, 0.90, 0.82)
const FOG_COLOR := Color(0.76, 0.79, 0.80, 0.10)
const LEAF_COLOR := Color(0.54, 0.42, 0.18, 0.92)
const PAPER_COLOR := Color(0.82, 0.80, 0.72, 0.90)
const DUST_COLOR := Color(0.62, 0.53, 0.40, 0.52)
const LIGHTNING_COLOR := Color(0.76, 0.87, 1.0, 1.0)

var _weather: WeatherService = null
var _sky: SkyExposureQuery = null
var _visible_origin: Vector2i = Vector2i.ZERO
var _visible_size: Vector2i = Vector2i.ZERO
var _cell_pixels: float = 0.0
var _view_valid: bool = false
var _overlay_size_pixels: Vector2i = Vector2i.ZERO
var _weather_pixel_size: int = MIN_WEATHER_PIXEL_SIZE
var _virtual_size: Vector2i = Vector2i.ZERO

var _accumulator: float = 0.0
var _presentation_step: int = 0
var _presentation_updates: int = 0
var _redraw_requests: int = 0
var _draw_count: int = 0
var _last_draw_usec: int = 0
var _last_rain_streaks: int = 0
var _last_fog_patches: int = 0
var _last_draw_primitives: int = 0
var _last_descriptor: Dictionary = {}
var _debris: Array[Dictionary] = []
var _ambient_countdown: float = 18.0
var _rng_state: int = 0x13579b
var _needs_clear_redraw: bool = false

var _lightning_visual_remaining: float = 0.0
var _lightning_visual_id: String = ""
var _lightning_visual_seed: int = 0
var _lightning_visual_intensity: float = 0.0

func _ready() -> void:
    set_process(false)

func configure(weather_service: WeatherService, sky_exposure: SkyExposureQuery) -> bool:
    if weather_service == null or not weather_service.is_ready() or sky_exposure == null or not sky_exposure.is_ready():
        return false
    _weather = weather_service
    _sky = sky_exposure
    _last_descriptor = weather_service.presentation_descriptor()
    _rng_state = int(_last_descriptor.get("presentation_seed", 0x13579b)) | 1
    _ambient_countdown = _next_ambient_delay(float(_last_descriptor.get("wind_strength", 0.0)))
    var lightning_callable := Callable(self, "_on_lightning_started")
    if not _weather.lightning_started.is_connected(lightning_callable):
        _weather.lightning_started.connect(lightning_callable)
    _refresh_overlay_surface()
    _sync_screen_space_transform()
    set_process(true)
    return true

func is_configured() -> bool:
    return _weather != null and _sky != null and _weather.is_ready() and _sky.is_ready()

func set_visible_window(origin: Vector2i, size_cells: Vector2i, cell_pixels: float) -> bool:
    if size_cells.x <= 0 or size_cells.y <= 0 or cell_pixels <= 0.0:
        return false
    var dimensions_changed: bool = (
        not _view_valid
        or size_cells != _visible_size
        or not is_equal_approx(cell_pixels, _cell_pixels)
    )
    _visible_origin = origin
    _visible_size = size_cells
    _cell_pixels = cell_pixels
    _view_valid = true
    var surface_changed: bool = _refresh_overlay_surface()
    if dimensions_changed or surface_changed:
        _needs_clear_redraw = true
        queue_redraw()
        _redraw_requests += 1
    # Origin-only render-window movement intentionally does not touch the overlay.
    return true

func set_camera_local_position(_local_position: Vector2) -> bool:
    # Compatibility seam for the renderer stack. Screen-space Weather does not
    # redraw, phase-shift, clear, or otherwise react to camera motion.
    return _view_valid

func advance_presentation(delta_seconds: float) -> int:
    if not is_configured() or not _view_valid or delta_seconds <= 0.0:
        return 0
    _accumulator += minf(delta_seconds, PRESENTATION_STEP_SECONDS * float(MAX_CATCHUP_STEPS))
    var steps: int = mini(int(floor(_accumulator / PRESENTATION_STEP_SECONDS)), MAX_CATCHUP_STEPS)
    if steps <= 0:
        return 0
    _accumulator -= float(steps) * PRESENTATION_STEP_SECONDS
    for _i in range(steps):
        _step_presentation()
    return steps

func force_ambient_event(kind: StringName = &"leaf") -> bool:
    if not is_configured() or not _view_valid:
        return false
    var descriptor: Dictionary = _weather.presentation_descriptor()
    var cap: int = _debris_cap(float(descriptor.get("wind_strength", 0.0)))
    if _debris.size() >= cap:
        return false
    _debris.append(_new_debris(kind, float(descriptor.get("wind_strength", 0.0))))
    _needs_clear_redraw = true
    queue_redraw()
    _redraw_requests += 1
    return true

func presentation_snapshot() -> Dictionary:
    var continuous: bool = _continuous_weather_active(_last_descriptor)
    return {
        "configured": is_configured(),
        "screen_space_overlay": true,
        "target_hz": TARGET_HZ,
        "presentation_step_seconds": PRESENTATION_STEP_SECONDS,
        "presentation_step": _presentation_step,
        "presentation_updates": _presentation_updates,
        "redraw_requests": _redraw_requests,
        "draw_count": _draw_count,
        "last_draw_usec": _last_draw_usec,
        "visible_origin": _visible_origin,
        "visible_size": _visible_size,
        "overlay_size_pixels": _overlay_size_pixels,
        "weather_pixel_size": _weather_pixel_size,
        "virtual_surface_size": _virtual_size,
        "virtual_pixel_count": _virtual_size.x * _virtual_size.y,
        "active_debris": _debris.size(),
        "max_debris": MAX_DEBRIS,
        "last_rain_streaks": _last_rain_streaks,
        "last_fog_patches": _last_fog_patches,
        "last_draw_primitives": _last_draw_primitives,
        "continuous_active": continuous,
        "sleeping": not continuous and _debris.is_empty() and _lightning_visual_remaining <= 0.0,
        "weather_kind": String(_last_descriptor.get("weather_kind", "")),
        "camera_motion_redraws": 0,
        "lightning_visual_active": _lightning_visual_remaining > 0.0,
        "lightning_visual_id": _lightning_visual_id,
        "lightning_visual_remaining": _lightning_visual_remaining,
    }

func _process(delta: float) -> void:
    _sync_screen_space_transform()
    if _refresh_overlay_surface():
        queue_redraw()
        _redraw_requests += 1
    advance_presentation(delta)
    if _lightning_visual_remaining > 0.0:
        _lightning_visual_remaining = maxf(0.0, _lightning_visual_remaining - maxf(0.0, delta))
        queue_redraw()
        _redraw_requests += 1
        if _lightning_visual_remaining <= 0.0:
            _lightning_visual_id = ""
            _lightning_visual_seed = 0
            _lightning_visual_intensity = 0.0

func _step_presentation() -> void:
    _presentation_step += 1
    _presentation_updates += 1
    _last_descriptor = _weather.presentation_descriptor()
    var continuous: bool = _continuous_weather_active(_last_descriptor)
    var wind_strength: float = float(_last_descriptor.get("wind_strength", 0.0))

    _advance_debris(PRESENTATION_STEP_SECONDS)
    if not continuous and _debris.is_empty() and String(_last_descriptor.get("weather_kind", "")) == "clear":
        _ambient_countdown -= PRESENTATION_STEP_SECONDS
        if _ambient_countdown <= 0.0:
            force_ambient_event(_random_ambient_kind())
            _ambient_countdown = _next_ambient_delay(wind_strength)

    if continuous or not _debris.is_empty():
        _needs_clear_redraw = true
        queue_redraw()
        _redraw_requests += 1
    elif _needs_clear_redraw:
        _needs_clear_redraw = false
        queue_redraw()
        _redraw_requests += 1

func _draw() -> void:
    var started: int = Time.get_ticks_usec()
    _last_rain_streaks = 0
    _last_fog_patches = 0
    _last_draw_primitives = 0
    if not is_configured() or not _view_valid or _overlay_size_pixels.x <= 0 or _overlay_size_pixels.y <= 0:
        _record_draw(started)
        return
    var descriptor: Dictionary = _weather.presentation_descriptor()
    _last_descriptor = descriptor
    _draw_fog(descriptor)
    _draw_rain(descriptor)
    _draw_debris(descriptor)
    _draw_lightning_visual()
    _record_draw(started)

func _draw_rain(descriptor: Dictionary) -> void:
    var precipitation: float = float(descriptor.get("precipitation", 0.0))
    if precipitation < 0.04:
        return
    var count: int = clampi(int(round(precipitation * float(MAX_RAIN_STREAKS))), 1, MAX_RAIN_STREAKS)
    var seed: int = int(descriptor.get("presentation_seed", 1))
    var wind: Vector2 = descriptor.get("wind_direction", Vector2.RIGHT)
    var wind_strength: float = float(descriptor.get("wind_strength", 0.0))
    var color: Color = STORM_RAIN_COLOR if precipitation > 0.80 else RAIN_COLOR
    var bounds := Rect2i(_visible_origin, _visible_size)
    for i in range(count):
        var h: int = _mix(seed, i * 97 + 13)
        var x: int = posmod(h + int(float(_presentation_step) * wind.x * wind_strength * 3.0), maxi(1, _virtual_size.x))
        var y: int = posmod(int(h / 257) + _presentation_step * (2 + int(round(precipitation * 3.0))), maxi(1, _virtual_size.y))
        var sample_px := Vector2(float(x * _weather_pixel_size), float(y * _weather_pixel_size))
        var cell: Vector2i = _world_cell_for_screen_pixel(sample_px)
        if bounds.has_point(cell) and not _sky.is_exposed(cell, bounds):
            continue
        var length: int = 1 + posmod(int(h / 17), 3)
        var slant: int = int(round(wind.x * wind_strength * 1.5))
        for segment in range(length):
            var px := Vector2(float((x + slant * segment) * _weather_pixel_size), float((y + segment) * _weather_pixel_size))
            draw_rect(Rect2(px, Vector2(_weather_pixel_size, _weather_pixel_size)), color, true)
            _last_draw_primitives += 1
        _last_rain_streaks += 1

func _draw_fog(descriptor: Dictionary) -> void:
    var fog: float = float(descriptor.get("fog_density", 0.0))
    if fog < 0.10:
        return
    var count: int = clampi(int(round(fog * float(MAX_FOG_PATCHES))), 1, MAX_FOG_PATCHES)
    var seed: int = int(descriptor.get("presentation_seed", 1)) ^ 0x55aa31
    var wind: Vector2 = descriptor.get("wind_direction", Vector2.RIGHT)
    var wind_strength: float = float(descriptor.get("wind_strength", 0.0))
    for i in range(count):
        var h: int = _mix(seed, i * 131 + 29)
        var drift_x: int = int(float(_presentation_step) * wind.x * maxf(0.15, wind_strength) * 0.35)
        var drift_y: int = int(float(_presentation_step) * wind.y * maxf(0.15, wind_strength) * 0.18)
        var x: int = posmod(h + drift_x, maxi(1, _virtual_size.x))
        var y: int = posmod(int(h / 193) + drift_y, maxi(1, _virtual_size.y))
        var w: int = 6 + posmod(int(h / 31), 18)
        var hgt: int = 2 + posmod(int(h / 53), 6)
        var alpha: float = 0.025 + 0.055 * fog
        var color := Color(FOG_COLOR.r, FOG_COLOR.g, FOG_COLOR.b, alpha)
        draw_rect(
            Rect2(
                Vector2(float(x * _weather_pixel_size), float(y * _weather_pixel_size)),
                Vector2(float(w * _weather_pixel_size), float(hgt * _weather_pixel_size))
            ),
            color,
            true
        )
        _last_fog_patches += 1
        _last_draw_primitives += 1

func _draw_debris(descriptor: Dictionary) -> void:
    var wind: Vector2 = descriptor.get("wind_direction", Vector2.RIGHT)
    for event: Dictionary in _debris:
        var progress: float = clampf(float(event.get("progress", 0.0)), 0.0, 1.0)
        var lane: float = float(event.get("lane", 0.5))
        var from_left: bool = wind.x >= 0.0
        var x_norm: float = progress if from_left else 1.0 - progress
        var wobble: float = sin(progress * TAU * 2.0 + float(event.get("phase", 0.0))) * 0.04
        var px := Vector2(
            x_norm * float(_overlay_size_pixels.x),
            clampf(lane + wobble, 0.04, 0.96) * float(_overlay_size_pixels.y)
        )
        var kind: String = String(event.get("kind", "leaf"))
        var color: Color = LEAF_COLOR
        var size_pixels := Vector2(float(_weather_pixel_size * 2), float(_weather_pixel_size))
        if kind == "paper":
            color = PAPER_COLOR
            size_pixels = Vector2(float(_weather_pixel_size * 2), float(_weather_pixel_size * 2))
        elif kind == "dust":
            color = DUST_COLOR
            size_pixels = Vector2(float(_weather_pixel_size * 3), float(_weather_pixel_size))
        draw_rect(Rect2(px, size_pixels), color, true)
        _last_draw_primitives += 1

func _draw_lightning_visual() -> void:
    if _lightning_visual_remaining <= 0.0 or _overlay_size_pixels.x <= 0 or _overlay_size_pixels.y <= 0:
        return
    var envelope: float = clampf(_lightning_visual_remaining / LIGHTNING_VISUAL_SECONDS, 0.0, 1.0)
    var flash_alpha: float = 0.16 * _lightning_visual_intensity * envelope
    draw_rect(
        Rect2(Vector2.ZERO, Vector2(_overlay_size_pixels)),
        Color(LIGHTNING_COLOR.r, LIGHTNING_COLOR.g, LIGHTNING_COLOR.b, flash_alpha),
        true
    )
    _last_draw_primitives += 1

    var width: float = float(_overlay_size_pixels.x)
    var height: float = float(_overlay_size_pixels.y)
    var segment_count: int = 7
    var x: float = width * (0.20 + 0.60 * _hash_unit(_lightning_visual_seed, 11))
    var previous := Vector2(x, -float(_weather_pixel_size * 2))
    for i in range(1, segment_count + 1):
        var y: float = height * 0.68 * float(i) / float(segment_count)
        var jitter: float = (_hash_unit(_lightning_visual_seed, 31 + i * 17) * 2.0 - 1.0) * float(_weather_pixel_size * 7)
        x = clampf(x + jitter, float(_weather_pixel_size * 2), width - float(_weather_pixel_size * 2))
        var next := Vector2(x, y)
        draw_line(previous, next, Color(LIGHTNING_COLOR.r, LIGHTNING_COLOR.g, LIGHTNING_COLOR.b, 0.88 * envelope), float(_weather_pixel_size * 2), false)
        previous = next
        _last_draw_primitives += 1

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
    return float(descriptor.get("precipitation", 0.0)) >= 0.04 or float(descriptor.get("fog_density", 0.0)) >= 0.10

func _refresh_overlay_surface() -> bool:
    var next_size := Vector2i.ZERO
    if get_viewport() != null:
        var viewport_size: Vector2 = get_viewport().get_visible_rect().size
        next_size = Vector2i(maxi(1, int(round(viewport_size.x))), maxi(1, int(round(viewport_size.y))))
    if next_size.x <= 1 or next_size.y <= 1:
        next_size = Vector2i(
            maxi(1, int(ceil(float(_visible_size.x) * maxf(1.0, _cell_pixels)))),
            maxi(1, int(ceil(float(_visible_size.y) * maxf(1.0, _cell_pixels))))
        )
    if next_size == _overlay_size_pixels:
        return false
    _overlay_size_pixels = next_size
    _weather_pixel_size = maxi(
        MIN_WEATHER_PIXEL_SIZE,
        maxi(
            int(ceil(float(_overlay_size_pixels.x) / float(MAX_VIRTUAL_AXIS))),
            int(ceil(float(_overlay_size_pixels.y) / float(MAX_VIRTUAL_AXIS)))
        )
    )
    _virtual_size = Vector2i(
        int(ceil(float(_overlay_size_pixels.x) / float(_weather_pixel_size))),
        int(ceil(float(_overlay_size_pixels.y) / float(_weather_pixel_size)))
    )
    return true

func _sync_screen_space_transform() -> void:
    if get_viewport() == null:
        return
    global_transform = get_viewport().get_canvas_transform().affine_inverse()

func _world_cell_for_screen_pixel(screen_pixel: Vector2) -> Vector2i:
    if _cell_pixels <= 0.0:
        return _visible_origin
    var canvas_point: Vector2 = screen_pixel
    if get_viewport() != null:
        canvas_point = get_viewport().get_canvas_transform().affine_inverse() * screen_pixel
    var parent_2d := get_parent() as Node2D
    if parent_2d == null:
        return _visible_origin + Vector2i(
            int(floor(screen_pixel.x / _cell_pixels)),
            int(floor(screen_pixel.y / _cell_pixels))
        )
    var parent_local: Vector2 = parent_2d.to_local(canvas_point)
    return _visible_origin + Vector2i(
        int(floor(parent_local.x / _cell_pixels)),
        int(floor(parent_local.y / _cell_pixels))
    )

func _on_lightning_started(event) -> void:
    if event == null or not event is LightningEvent:
        return
    var lightning: LightningEvent = event
    if not lightning.is_valid():
        return
    _lightning_visual_id = lightning.event_id
    _lightning_visual_seed = lightning.bolt_seed
    _lightning_visual_intensity = lightning.intensity
    _lightning_visual_remaining = LIGHTNING_VISUAL_SECONDS
    queue_redraw()
    _redraw_requests += 1

func _record_draw(started_usec: int) -> void:
    _last_draw_usec = Time.get_ticks_usec() - started_usec
    _draw_count += 1
    PerformanceTelemetry.record_timing(&"weather_draw", _last_draw_usec)
    PerformanceTelemetry.record_value(&"weather_draws", _draw_count)
    PerformanceTelemetry.record_value(&"weather_primitives", _last_draw_primitives)
    PerformanceTelemetry.record_value(&"weather_redraw_requests", _redraw_requests)

func _random_unit() -> float:
    _rng_state = int((_rng_state * 1103515245 + 12345) & 0x7fffffff)
    return float(_rng_state) / float(0x7fffffff)

static func _hash_unit(seed: int, salt: int) -> float:
    return float(_mix(seed, salt) & 0xffff) / 65535.0

static func _mix(seed: int, salt: int) -> int:
    var value: int = (seed ^ (salt * 2654435761)) & 0x7fffffff
    value = int((value * 1103515245 + 12345) & 0x7fffffff)
    return value