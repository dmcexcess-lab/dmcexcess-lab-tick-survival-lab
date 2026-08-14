extends "res://scripts/MapPreview.gd"

# Presentation-only extension for the current developer harness. Simulation,
# perception and world coordinates remain owned by the base MapPreview/world
# modules; these presets only change how much of the map is drawn at once.
const EXTENDED_ZOOM_PRESETS := [
    [28.0, 20, 17],
    [31.0, 18, 16],
    [35.0, 16, 14],
    [39.0, 14, 12],
    [44.0, 12, 10],
    [50.0, 10, 9],
]

func _zoom(delta: int) -> void:
    zoom_index = clampi(zoom_index + delta, 0, EXTENDED_ZOOM_PRESETS.size() - 1)
    var preset: Array = EXTENDED_ZOOM_PRESETS[zoom_index]
    TILE = float(preset[0])
    VISIBLE_COLS = int(preset[1])
    VISIBLE_ROWS = int(preset[2])
    _record_zero("zoom", "%dx%d @ %.0fpx" % [VISIBLE_COLS, VISIBLE_ROWS, TILE])

func _draw_controls() -> void:
    draw_rect(Rect2(0, CONTROL_TOP, VIEW_W, VIEW_H - CONTROL_TOP), Color(0.025, 0.032, 0.028, 0.96))
    draw_line(Vector2(0, CONTROL_TOP), Vector2(VIEW_W, CONTROL_TOP), Color("626a64"), 2.0)
    _draw_button(BTN_TURN_L, "TURN L", false, 18)
    _draw_button(BTN_TURN_R, "TURN R", false, 18)
    _draw_button(BTN_CROUCH, "CROUCH", player.crouched, 11)
    _draw_button(BTN_FORWARD, "FORWARD", false, 11)
    _draw_button(BTN_BACK, "BACK", false, 11)
    _draw_button(BTN_ZOOM_OUT, "-", zoom_index > 0, 20)
    _draw_button(BTN_ZOOM_IN, "+", zoom_index < EXTENDED_ZOOM_PRESETS.size() - 1, 20)
    draw_string(font, Vector2(210, 690), "World controls", HORIZONTAL_ALIGNMENT_CENTER, 220, 11, Color("84928c"))
    draw_string(font, Vector2(296, 751), "ZOOM", HORIZONTAL_ALIGNMENT_CENTER, 48, 9, Color("84928c"))
    draw_string(font, Vector2(210, 823), "Tap map still works", HORIZONTAL_ALIGNMENT_CENTER, 220, 10, Color("84928c"))

func _draw_weather_vfx() -> void:
    var board: Rect2 = _visible_board_rect()
    var rain: float = Weather.precipitation(weather_state)
    var snow: float = Weather.snowfall(weather_state)
    var fog_amount: float = Weather.fog_density(weather_state)
    var wind: float = Weather.wind_strength(weather_state)
    var direction: Vector2 = Weather.wind_direction(weather_state)

    if fog_amount > 0.05:
        var origin: Vector2i = _view_origin()
        for y in range(origin.y, origin.y + VISIBLE_ROWS):
            for x in range(origin.x, origin.x + VISIBLE_COLS):
                var cell := Vector2i(x, y)
                if not _weather_cell_allowed(cell):
                    continue
                var drift: float = 0.5 + 0.5 * sin(weather_vfx_time * 0.7 + float(x) * 0.43 + float(y) * 0.71)
                draw_rect(_cell_rect(cell), Color(0.72, 0.78, 0.77, fog_amount * (0.055 + drift * 0.09)))

    if rain > 0.02:
        var count: int = 34 + int(rain * 62.0)
        for i in range(count):
            var seed_x: float = fmod(float(i * 83), board.size.x)
            var speed: float = 190.0 + float(i % 7) * 21.0 + rain * 150.0
            var y: float = fmod(float(i * 47) + weather_vfx_time * speed, board.size.y + 36.0) - 18.0
            var x: float = fmod(seed_x + weather_vfx_time * direction.x * 68.0 + y * direction.x * 0.22, board.size.x)
            var start := board.position + Vector2(x, y)
            if not board.has_point(start) or not _weather_cell_allowed(_screen_to_cell(start)):
                continue
            var streak := Vector2(direction.x * (9.0 + rain * 5.0), 12.0 + rain * 11.0)
            var finish := _clamp_weather_point(start + streak, board, 0.75)
            draw_line(start, finish, Color(0.72, 0.84, 0.90, 0.26 + rain * 0.28), 1.25)

    if snow > 0.02:
        var flake_count: int = 38 + int(snow * 70.0)
        for i in range(flake_count):
            var seed_x: float = fmod(float(i * 67), board.size.x)
            var fall_speed: float = 34.0 + float(i % 9) * 4.0 + snow * 24.0
            var y: float = fmod(float(i * 41) + weather_vfx_time * fall_speed, board.size.y + 20.0) - 10.0
            var sway: float = sin(weather_vfx_time * (0.9 + float(i % 5) * 0.08) + float(i) * 1.7) * (7.0 + snow * 5.0)
            var x: float = fmod(seed_x + weather_vfx_time * direction.x * 28.0 + sway, board.size.x)
            var p := board.position + Vector2(x, y)
            var radius: float = 1.2 + float(i % 3) * 0.45
            if not board.grow(-radius).has_point(p) or not _weather_cell_allowed(_screen_to_cell(p)):
                continue
            draw_circle(p, radius, Color(0.93, 0.96, 1.0, 0.55 + snow * 0.30))

    if wind > 0.28:
        for i in range(10):
            var travel: float = fmod(weather_vfx_time * (38.0 + wind * 70.0) + float(i) * 97.0, board.size.x + 70.0) - 35.0
            var y: float = board.position.y + 50.0 + fmod(float(i * 73), board.size.y - 70.0)
            var p := Vector2(board.position.x + travel, y + sin(weather_vfx_time * 2.2 + float(i)) * 11.0)
            if not board.has_point(p) or not _weather_cell_allowed(_screen_to_cell(p)):
                continue
            var finish := _clamp_weather_point(p + direction * (6.0 + wind * 10.0), board, 1.0)
            draw_line(p, finish, Color(0.55, 0.48, 0.35, 0.56), 2.0)

    if str(weather_state.get("kind", Weather.CLEAR)) == Weather.STORM:
        var pulse: float = maxf(0.0, sin(weather_vfx_time * 1.9 + sin(weather_vfx_time * 0.37) * 3.0) - 0.965) * 5.0
        if pulse > 0.0:
            var origin: Vector2i = _view_origin()
            for y in range(origin.y, origin.y + VISIBLE_ROWS):
                for x in range(origin.x, origin.x + VISIBLE_COLS):
                    var cell := Vector2i(x, y)
                    if _weather_cell_allowed(cell):
                        draw_rect(_cell_rect(cell), Color(0.78, 0.84, 0.92, minf(0.16, pulse * 0.12)))

func _clamp_weather_point(point: Vector2, board: Rect2, inset: float) -> Vector2:
    var min_x: float = board.position.x + inset
    var min_y: float = board.position.y + inset
    var max_x: float = board.end.x - inset
    var max_y: float = board.end.y - inset
    return Vector2(clampf(point.x, min_x, max_x), clampf(point.y, min_y, max_y))
