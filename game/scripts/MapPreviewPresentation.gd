extends "res://scripts/MapPreview.gd"

# Presentation-only extension for the current developer harness. Simulation,
# perception and world coordinates remain owned by the base MapPreview/world
# modules; these presets only change how much of the tactical map is drawn.
const EXTENDED_ZOOM_PRESETS := [
    [28.0, 20, 17],
    [31.0, 18, 16],
    [35.0, 16, 14],
    [39.0, 14, 12],
    [44.0, 12, 10],
    [50.0, 10, 9],
]

# The base harness used to redraw the entire tactical scene every process frame
# solely to animate presentation effects. Keep cosmetic motion smooth while
# bounding the expensive full-scene redraw rate, especially at wide zoom.
const ANIMATION_FPS_NORMAL := 30.0
const ANIMATION_FPS_WIDE := 24.0

# One full-screen overworld map only. There is intentionally no minimap and no
# second local-area map mode. This is a schematic presentation of the same
# authoritative region coordinates used by tactical play.
const BTN_MAP := Rect2(236, 780, 168, 52)
const OVERMAP_CLOSE := Rect2(500, 16, 120, 46)
const OVERMAP_AREA := Rect2(20, 88, 600, 600)
var overworld_open := false
var animation_redraw_accumulator := 0.0
var weather_wall_cells: Dictionary = {}
var weather_wall_cache_seed := -1

func _process(delta: float) -> void:
    if overworld_open:
        return
    weather_vfx_time += delta
    if not _presentation_animation_active():
        animation_redraw_accumulator = 0.0
        return
    animation_redraw_accumulator += delta
    var redraw_fps: float = ANIMATION_FPS_WIDE if VISIBLE_COLS >= 20 else ANIMATION_FPS_NORMAL
    var redraw_interval: float = 1.0 / redraw_fps
    if animation_redraw_accumulator < redraw_interval:
        return
    animation_redraw_accumulator = fposmod(animation_redraw_accumulator, redraw_interval)
    queue_redraw()

func _presentation_animation_active() -> bool:
    if Weather.precipitation(weather_state) > 0.02:
        return true
    if Weather.snowfall(weather_state) > 0.02:
        return true
    if Weather.fog_density(weather_state) > 0.05:
        return true
    if Weather.wind_strength(weather_state) > 0.28:
        return true
    if str(weather_state.get("kind", Weather.CLEAR)) == Weather.STORM:
        return true
    return Lighting.has_animated_sources(light_sources, power_on)

func _zoom(delta: int) -> void:
    zoom_index = clampi(zoom_index + delta, 0, EXTENDED_ZOOM_PRESETS.size() - 1)
    var preset: Array = EXTENDED_ZOOM_PRESETS[zoom_index]
    TILE = float(preset[0])
    VISIBLE_COLS = int(preset[1])
    VISIBLE_ROWS = int(preset[2])
    animation_redraw_accumulator = 0.0
    _record_zero("zoom", "%dx%d @ %.0fpx" % [VISIBLE_COLS, VISIBLE_ROWS, TILE])

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        var key_event := event as InputEventKey
        if key_event.keycode == KEY_M and not menu_open:
            _set_overworld_open(not overworld_open)
            get_viewport().set_input_as_handled()
            return
        if overworld_open:
            if key_event.keycode == KEY_ESCAPE:
                _set_overworld_open(false)
            get_viewport().set_input_as_handled()
            return
    if overworld_open:
        if event is InputEventScreenTouch and event.pressed:
            suppress_mouse_until_msec = Time.get_ticks_msec() + 700
            _handle_pointer(event.position)
            get_viewport().set_input_as_handled()
        elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            if Time.get_ticks_msec() >= suppress_mouse_until_msec:
                _handle_pointer(event.position)
            get_viewport().set_input_as_handled()
        return
    super._unhandled_input(event)

func _handle_pointer(pos: Vector2) -> void:
    if overworld_open:
        if OVERMAP_CLOSE.has_point(pos) or BTN_MAP.has_point(pos):
            _set_overworld_open(false)
        return
    if BTN_MAP.has_point(pos) and not menu_open and not dev_open:
        _set_overworld_open(true)
        return
    super._handle_pointer(pos)

func _set_overworld_open(opened: bool) -> void:
    overworld_open = opened
    if opened:
        if dev_open:
            _set_dev_open(false)
        _record_zero("map", "OPEN")
    else:
        _record_zero("map", "CLOSE")
    queue_redraw()

func _draw() -> void:
    super._draw()
    if overworld_open:
        _draw_overworld_map()

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
    _draw_button(BTN_MAP, "MAP", false, 15)
    draw_string(font, Vector2(210, 690), "World controls", HORIZONTAL_ALIGNMENT_CENTER, 220, 11, Color("84928c"))
    draw_string(font, Vector2(296, 751), "ZOOM", HORIZONTAL_ALIGNMENT_CENTER, 48, 9, Color("84928c"))

# Consume the generator's per-cell shell presentation metadata in tactical view.
# Physical wall/door/window membership remains owned by the existing map/world
# schema; this only chooses the appropriate already-authored art.
func _draw_map_tiles() -> void:
    var fallback_theme: String = MapGen.theme_name(environment_id)
    var origin: Vector2i = _view_origin()
    for y in range(origin.y, origin.y + VISIBLE_ROWS):
        for x in range(origin.x, origin.x + VISIBLE_COLS):
            var p := Vector2i(x, y)
            Tiles.draw_ground_context(self, _cell_rect(p), spec, p, MapGen.ground_at(spec, p))
    var wall_themes: Dictionary = spec.get("wall_themes", {})
    for p_value in spec.get("walls", []):
        var p: Vector2i = p_value
        if _cell_on_screen(p):
            Tiles.draw_wall(self, _cell_rect(p), str(wall_themes.get(p, fallback_theme)))
    var door_themes: Dictionary = spec.get("door_themes", {})
    for door_value in world.doors.keys():
        var p: Vector2i = door_value
        if _cell_on_screen(p):
            Tiles.draw_door(self, _cell_rect(p), world.is_door_open(p), str(door_themes.get(p, "")))
    var window_themes: Dictionary = spec.get("window_themes", {})
    for p_value in spec.get("glass", []):
        var p: Vector2i = p_value
        if _cell_on_screen(p):
            Tiles.draw_window(self, _cell_rect(p), str(window_themes.get(p, "")))
    for entry_value in spec.get("props", []):
        var entry: Array = entry_value
        if _cell_on_screen(entry[0]):
            Tiles.draw_prop(self, _cell_rect(entry[0]), str(entry[1]))
    for p_value in spec.get("barrels", []):
        if _cell_on_screen(p_value):
            Tiles.draw_barrel(self, _cell_rect(p_value))
    for exit_value in spec.get("exit_cells", []):
        if _cell_on_screen(exit_value):
            draw_rect(_cell_rect(exit_value).grow(-3), Color("55d56e"), false, 2.0)
    draw_rect(_visible_board_rect(), Color("6c7772"), false, 1.0)

func _draw_overworld_map() -> void:
    draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color("101416"))
    draw_string(font, Vector2(20, 38), "OVERWORLD MAP", HORIZONTAL_ALIGNMENT_LEFT, 360, 22, Color.WHITE)
    draw_string(font, Vector2(20, 62), "Seed %d  |  red dot = survivor" % region_seed, HORIZONTAL_ALIGNMENT_LEFT, 430, 11, Color("aebbb5"))
    _draw_button(OVERMAP_CLOSE, "CLOSE", true, 13)

    var map_w: int = maxi(1, _map_w())
    var map_h: int = maxi(1, _map_h())
    var scale: float = minf(OVERMAP_AREA.size.x / float(map_w), OVERMAP_AREA.size.y / float(map_h))
    var drawn_size := Vector2(float(map_w) * scale, float(map_h) * scale)
    var origin := OVERMAP_AREA.position + (OVERMAP_AREA.size - drawn_size) * 0.5

    draw_rect(Rect2(origin, drawn_size), Color("273029"))
    var biomes: Dictionary = spec.get("biome_cells", {})
    for y in range(map_h):
        for x in range(map_w):
            var cell := Vector2i(x, y)
            draw_rect(_overmap_cell_rect(cell, origin, scale), _biome_map_color(str(biomes.get(cell, "rural"))))

    for lot_value in spec.get("parking_lots", []):
        var lot: Array = lot_value
        var lot_rect := Rect2(
            origin + Vector2(float(int(lot[0])) * scale, float(int(lot[1])) * scale),
            Vector2(float(int(lot[2])) * scale, float(int(lot[3])) * scale)
        )
        draw_rect(lot_rect, Color("3c4143"))

    var road_classes: Dictionary = spec.get("road_class_cells", {})
    var road_surfaces: Dictionary = spec.get("road_surface_cells", {})
    for road_value in spec.get("road_cells", {}).keys():
        var road: Vector2i = road_value
        var road_class := str(road_classes.get(road, "local"))
        var surface := str(road_surfaces.get(road, "road"))
        var road_color := Color("786b54") if surface == "dirt" else Color("676d70")
        if road_class == "arterial" and surface != "dirt":
            road_color = Color("8b9194")
        elif road_class == "trail":
            road_color = Color("76684e")
        draw_rect(_overmap_cell_rect(road, origin, scale), road_color)

    for parking_value in spec.get("parking_cells", {}).keys():
        var parking_cell: Vector2i = parking_value
        var r := _overmap_cell_rect(parking_cell, origin, scale)
        var mark := Rect2(r.position + Vector2(r.size.x * 0.34, r.size.y * 0.12), Vector2(r.size.x * 0.32, r.size.y * 0.76))
        draw_rect(mark, Color("d7d2bf"))

    for building_value in spec.get("building_rects", []):
        var building: Array = building_value
        var building_rect := Rect2(
            origin + Vector2(float(int(building[0])) * scale, float(int(building[1])) * scale),
            Vector2(float(int(building[2])) * scale, float(int(building[3])) * scale)
        )
        var theme := str(building[4]) if building.size() > 4 else "house"
        draw_rect(building_rect, _building_map_color(theme))
        draw_rect(building_rect, Color("202523"), false, maxf(1.0, scale * 0.12))

    for exit_value in spec.get("exit_cells", []):
        var exit_cell: Vector2i = exit_value
        var er := _overmap_cell_rect(exit_cell, origin, scale)
        draw_rect(er.grow(-scale * 0.18), Color("67b86f"))

    var player_center := origin + Vector2((float(player.cell.x) + 0.5) * scale, (float(player.cell.y) + 0.5) * scale)
    draw_circle(player_center, maxf(4.5, scale * 0.58), Color("e33f37"))
    draw_circle(player_center, maxf(4.5, scale * 0.58), Color("fff1e8"), false, 1.5)
    draw_rect(Rect2(origin, drawn_size), Color("c0c8c3"), false, 2.0)

    draw_string(font, Vector2(20, 720), "Roads • buildings • parking • biome terrain", HORIZONTAL_ALIGNMENT_LEFT, 600, 12, Color("c7d0cb"))
    draw_string(font, Vector2(20, 744), "M or CLOSE returns to tactical view. Opening the map costs 0 ticks.", HORIZONTAL_ALIGNMENT_LEFT, 600, 10, Color("899a93"))
    draw_string(font, Vector2(20, 770), "No minimap / no separate local-area map.", HORIZONTAL_ALIGNMENT_LEFT, 600, 10, Color("899a93"))

func _overmap_cell_rect(cell: Vector2i, origin: Vector2, scale: float) -> Rect2:
    return Rect2(origin + Vector2(float(cell.x) * scale, float(cell.y) * scale), Vector2(scale + 0.12, scale + 0.12))

func _biome_map_color(biome: String) -> Color:
    match biome:
        "residential": return Color("53654b")
        "commercial": return Color("6b6650")
        "downtown": return Color("595e60")
        "woods": return Color("334934")
        "rural": return Color("66704a")
        _: return Color("53604c")

func _building_map_color(theme: String) -> Color:
    match theme:
        "house", "rural_wood": return Color("b29470")
        "store": return Color("718c92")
        "office": return Color("7c8291")
        "industrial": return Color("82786d")
        _: return Color("8b8175")

func _refresh_weather_wall_cache() -> void:
    if weather_wall_cache_seed == region_seed:
        return
    weather_wall_cells.clear()
    for p_value in spec.get("walls", []):
        weather_wall_cells[p_value] = true
    weather_wall_cache_seed = region_seed

func _weather_cell_allowed(cell: Vector2i) -> bool:
    if cell.x < 0 or cell.y < 0 or cell.x >= _map_w() or cell.y >= _map_h():
        return false
    if indoor_cells.has(cell):
        return false
    if weather_wall_cache_seed != region_seed:
        _refresh_weather_wall_cache()
    if weather_wall_cells.has(cell):
        return false
    return true

func _weather_hash01(index: int, salt: int) -> float:
    var seed_mix: int = posmod(region_seed, 1000003)
    var n: float = float(index * 15731 + salt * 789221 + seed_mix * 31)
    return fposmod(sin(n) * 43758.5453123, 1.0)

func _draw_weather_vfx() -> void:
    _refresh_weather_wall_cache()
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
        var rain_span_y: float = board.size.y + 36.0
        for i in range(count):
            var seed_x: float = _weather_hash01(i, 11) * board.size.x
            var seed_y: float = _weather_hash01(i, 23) * rain_span_y
            var speed_mix: float = _weather_hash01(i, 37)
            var drift_mix: float = _weather_hash01(i, 53)
            var speed: float = 175.0 + speed_mix * 165.0 + rain * 125.0
            var y: float = fposmod(seed_y + weather_vfx_time * speed, rain_span_y) - 18.0
            var x: float = fposmod(seed_x + weather_vfx_time * direction.x * (42.0 + drift_mix * 44.0) + y * direction.x * (0.10 + drift_mix * 0.16), board.size.x)
            var start := board.position + Vector2(x, y)
            if not board.has_point(start) or not _weather_cell_allowed(_screen_to_cell(start)):
                continue
            var streak_scale: float = 0.82 + _weather_hash01(i, 67) * 0.38
            var streak := Vector2(direction.x * (9.0 + rain * 5.0), 12.0 + rain * 11.0) * streak_scale
            var finish := _clamp_weather_point(start + streak, board, 0.75)
            draw_line(start, finish, Color(0.72, 0.84, 0.90, 0.26 + rain * 0.28), 1.25)

    if snow > 0.02:
        var flake_count: int = 38 + int(snow * 70.0)
        var snow_span_y: float = board.size.y + 20.0
        for i in range(flake_count):
            var seed_x: float = _weather_hash01(i, 101) * board.size.x
            var seed_y: float = _weather_hash01(i, 113) * snow_span_y
            var fall_speed: float = 27.0 + _weather_hash01(i, 127) * 45.0 + snow * 22.0
            var y: float = fposmod(seed_y + weather_vfx_time * fall_speed, snow_span_y) - 10.0
            var sway_rate: float = 0.62 + _weather_hash01(i, 139) * 0.88
            var sway_phase: float = _weather_hash01(i, 151) * TAU
            var sway_amount: float = 5.0 + _weather_hash01(i, 163) * 9.0 + snow * 4.0
            var sway: float = sin(weather_vfx_time * sway_rate + sway_phase) * sway_amount
            var wind_drift: float = weather_vfx_time * direction.x * (18.0 + _weather_hash01(i, 179) * 24.0)
            var x: float = fposmod(seed_x + wind_drift + sway, board.size.x)
            var p := board.position + Vector2(x, y)
            var radius: float = 1.0 + _weather_hash01(i, 191) * 1.1
            if not board.grow(-radius).has_point(p) or not _weather_cell_allowed(_screen_to_cell(p)):
                continue
            draw_circle(p, radius, Color(0.93, 0.96, 1.0, 0.55 + snow * 0.30))

    if wind > 0.28:
        var travel_span: float = board.size.x + 70.0
        for i in range(10):
            var travel_speed: float = 34.0 + wind * 62.0 + _weather_hash01(i, 211) * 32.0
            var travel: float = fposmod(_weather_hash01(i, 223) * travel_span + weather_vfx_time * travel_speed, travel_span) - 35.0
            var base_y: float = board.position.y + 20.0 + _weather_hash01(i, 239) * maxf(1.0, board.size.y - 40.0)
            var wobble_rate: float = 1.2 + _weather_hash01(i, 251) * 1.7
            var wobble_phase: float = _weather_hash01(i, 263) * TAU
            var p := Vector2(board.position.x + travel, base_y + sin(weather_vfx_time * wobble_rate + wobble_phase) * 10.0)
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
