extends "res://scripts/MapPreviewPresentation.gd"

const MiniRegionGen = preload("res://scripts/MiniRegionGenerator.gd")
const MiniWorldStateClass = preload("res://scripts/MiniWorldState.gd")

# The tactical camera is now deliberately local-detail only. The overworld is
# the orientation/navigation tool, so Safari never needs the old 16x14-20x17
# high-cost tactical overview modes.
const SAFE_ZOOM_PRESETS := [
    [39.0, 14, 12],
    [44.0, 12, 10],
    [50.0, 10, 9],
]
const SAFE_DEFAULT_ZOOM := 1
const FAR_ANIMATION_FPS := 18.0

var mini_world = MiniWorldStateClass.new()

func _ready() -> void:
    zoom_index = SAFE_DEFAULT_ZOOM
    _apply_safe_zoom()
    super._ready()

func reroll() -> void:
    mini_world.reset(rng.randi_range(1, 2147483000))
    _load_current_region(true, Vector2i.ZERO)

func _apply_safe_zoom() -> void:
    var preset: Array = SAFE_ZOOM_PRESETS[zoom_index]
    TILE = float(preset[0])
    VISIBLE_COLS = int(preset[1])
    VISIBLE_ROWS = int(preset[2])

func _zoom(delta: int) -> void:
    zoom_index = clampi(zoom_index + delta, 0, SAFE_ZOOM_PRESETS.size() - 1)
    _apply_safe_zoom()
    animation_redraw_accumulator = 0.0
    _record_zero("zoom", "%dx%d @ %.0fpx" % [VISIBLE_COLS, VISIBLE_ROWS, TILE])

func _process(delta: float) -> void:
    if overworld_open:
        return
    weather_vfx_time += delta
    if not _presentation_animation_active():
        animation_redraw_accumulator = 0.0
        return
    animation_redraw_accumulator += delta
    var redraw_fps: float = FAR_ANIMATION_FPS if VISIBLE_COLS >= 14 else ANIMATION_FPS_NORMAL
    var redraw_interval: float = 1.0 / redraw_fps
    if animation_redraw_accumulator < redraw_interval:
        return
    animation_redraw_accumulator = fposmod(animation_redraw_accumulator, redraw_interval)
    queue_redraw()

func _load_current_region(reset_simulation: bool, travel_dir: Vector2i) -> void:
    region_seed = mini_world.current_seed()
    environment_id = "procedural_region"
    variant = 0
    spec = MiniRegionGen.generate(region_seed, MiniRegionGen.REGION_W, MiniRegionGen.REGION_H, mini_world.current_kind())
    world.load_from_spec(spec)
    weather_wall_cache_seed = -1
    memory.clear()

    if reset_simulation:
        scheduler.reset()
        player.reset(spec.get("player_spawn", Vector2i.ZERO))
        timing_dummy.configure("clock_dummy", 4, scheduler.world_tick)
        power_on = true
        flashlight_on = true
        weather_index = 1
        weather_state = Weather.make_state(WEATHER_KINDS[weather_index], Vector2(0.7, 0.25))
        clock_anchor_tick = scheduler.world_tick
        clock_anchor_minutes = 21 * 60 + 30
        clock_anchor_month = 8
        clock_anchor_day = 14
        last_action_label = "spawn"
        last_action_cost = 0
        last_action_detail = "new mini world"
        last_action_status = TickSchedulerClass.STATUS_READY
        last_other_actions = 0
    else:
        player.cell = _entry_cell_for_travel(travel_dir)
        timing_dummy.configure("clock_dummy", 4, scheduler.world_tick)

    _recalc_perception()
    _refresh_dev_input_text()
    queue_redraw()

func _entry_cell_for_travel(travel_dir: Vector2i) -> Vector2i:
    var ports: Dictionary = spec.get("road_ports", {})
    if travel_dir == Vector2i.RIGHT:
        return ports.get("west", spec.get("player_spawn", Vector2i.ZERO))
    if travel_dir == Vector2i.LEFT:
        return ports.get("east", spec.get("player_spawn", Vector2i.ZERO))
    if travel_dir == Vector2i.DOWN:
        return ports.get("north", spec.get("player_spawn", Vector2i.ZERO))
    if travel_dir == Vector2i.UP:
        return ports.get("south", spec.get("player_spawn", Vector2i.ZERO))
    return spec.get("player_spawn", Vector2i.ZERO)

func _move_to(target: Vector2i, forward: bool) -> void:
    var travel_dir := Vector2i.ZERO
    if target.x <= 0 and player.cell.x <= 1:
        travel_dir = Vector2i.LEFT
    elif target.x >= _map_w() - 1 and player.cell.x >= _map_w() - 2:
        travel_dir = Vector2i.RIGHT
    elif target.y <= 0 and player.cell.y <= 1:
        travel_dir = Vector2i.UP
    elif target.y >= _map_h() - 1 and player.cell.y >= _map_h() - 2:
        travel_dir = Vector2i.DOWN

    if travel_dir != Vector2i.ZERO:
        _travel_region(travel_dir)
        return
    super._move_to(target, forward)

func _travel_region(dir: Vector2i) -> void:
    if not mini_world.move_region(dir):
        _record_zero("blocked", "edge of mini world")
        return
    _load_current_region(false, dir)
    _commit("region_move", player.movement_cost(), mini_world.current_name())

func _draw_controls() -> void:
    draw_rect(Rect2(0, CONTROL_TOP, VIEW_W, VIEW_H - CONTROL_TOP), Color(0.025, 0.032, 0.028, 0.96))
    draw_line(Vector2(0, CONTROL_TOP), Vector2(VIEW_W, CONTROL_TOP), Color("626a64"), 2.0)
    _draw_button(BTN_TURN_L, "TURN L", false, 18)
    _draw_button(BTN_TURN_R, "TURN R", false, 18)
    _draw_button(BTN_CROUCH, "CROUCH", player.crouched, 11)
    _draw_button(BTN_FORWARD, "FORWARD", false, 11)
    _draw_button(BTN_BACK, "BACK", false, 11)
    _draw_button(BTN_ZOOM_OUT, "-", zoom_index > 0, 20)
    _draw_button(BTN_ZOOM_IN, "+", zoom_index < SAFE_ZOOM_PRESETS.size() - 1, 20)
    _draw_button(BTN_MAP, "MAP", overworld_open, 15)
    draw_string(font, Vector2(210, 690), "Local controls", HORIZONTAL_ALIGNMENT_CENTER, 220, 11, Color("84928c"))
    draw_string(font, Vector2(296, 751), "ZOOM", HORIZONTAL_ALIGNMENT_CENTER, 48, 9, Color("84928c"))

func _draw_overworld_map() -> void:
    draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color("101416"))
    draw_string(font, Vector2(20, 38), "MINI WORLD MAP", HORIZONTAL_ALIGNMENT_LEFT, 360, 22, Color.WHITE)
    draw_string(font, Vector2(20, 62), "World seed %d  |  red dot = survivor" % mini_world.world_seed, HORIZONTAL_ALIGNMENT_LEFT, 450, 11, Color("aebbb5"))
    _draw_button(OVERMAP_CLOSE, "CLOSE", true, 13)

    var cell_w: float = OVERMAP_AREA.size.x / float(MiniWorldStateClass.WORLD_W)
    var cell_h: float = OVERMAP_AREA.size.y / float(MiniWorldStateClass.WORLD_H)

    # Region blocks are the primary navigation language. Only the current local
    # region is rendered tactically; these 25 cells are cheap world-scale data.
    for y in range(MiniWorldStateClass.WORLD_H):
        for x in range(MiniWorldStateClass.WORLD_W):
            var region := Vector2i(x, y)
            var rect := Rect2(
                OVERMAP_AREA.position + Vector2(float(x) * cell_w, float(y) * cell_h),
                Vector2(cell_w, cell_h)
            ).grow(-2.0)
            var kind := mini_world.kind_at(region)
            draw_rect(rect, _mini_region_color(kind))
            draw_rect(rect, Color("d0d8d3") if region == mini_world.current_region else Color("59645f"), false, 2.0 if region == mini_world.current_region else 1.0)
            draw_string(font, Vector2(rect.position.x + 4.0, rect.position.y + 16.0), _mini_region_code(kind), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8.0, 11, Color("edf2ef"))

    # Draw a light road-grid abstraction so adjacency is readable without
    # pretending the macro map knows every local street tile.
    for y in range(MiniWorldStateClass.WORLD_H):
        for x in range(MiniWorldStateClass.WORLD_W):
            var c := OVERMAP_AREA.position + Vector2((float(x) + 0.5) * cell_w, (float(y) + 0.5) * cell_h)
            if x < MiniWorldStateClass.WORLD_W - 1:
                draw_line(c, c + Vector2(cell_w, 0), Color(0.76, 0.78, 0.73, 0.28), 2.0)
            if y < MiniWorldStateClass.WORLD_H - 1:
                draw_line(c, c + Vector2(0, cell_h), Color(0.76, 0.78, 0.73, 0.28), 2.0)

    var local_x := (float(player.cell.x) + 0.5) / float(maxi(1, _map_w()))
    var local_y := (float(player.cell.y) + 0.5) / float(maxi(1, _map_h()))
    var player_center := OVERMAP_AREA.position + Vector2(
        (float(mini_world.current_region.x) + local_x) * cell_w,
        (float(mini_world.current_region.y) + local_y) * cell_h
    )
    draw_circle(player_center, 6.0, Color("e33f37"))
    draw_circle(player_center, 6.0, Color("fff1e8"), false, 1.5)
    draw_rect(OVERMAP_AREA, Color("c0c8c3"), false, 2.0)

    draw_string(font, Vector2(20, 716), mini_world.current_name(), HORIZONTAL_ALIGNMENT_LEFT, 600, 16, Color("f2d27a"))
    draw_string(font, Vector2(20, 740), "Current local seed %d  •  %s" % [region_seed, mini_world.current_kind().to_upper()], HORIZONTAL_ALIGNMENT_LEFT, 600, 10, Color("c7d0cb"))
    draw_string(font, Vector2(20, 762), "Reach a green edge road and continue through it to enter the next region.", HORIZONTAL_ALIGNMENT_LEFT, 600, 10, Color("899a93"))
    draw_string(font, Vector2(20, 784), "M or CLOSE returns to local tactical view. Map use costs 0 ticks.", HORIZONTAL_ALIGNMENT_LEFT, 600, 10, Color("899a93"))

func _mini_region_color(kind: String) -> Color:
    match kind:
        "residential": return Color("56694f")
        "commercial": return Color("7a704e")
        "downtown": return Color("5b6267")
        "woods": return Color("2f4b34")
        "rural": return Color("70764d")
        _: return Color("53604c")

func _mini_region_code(kind: String) -> String:
    match kind:
        "residential": return "NEIGHBORHOOD"
        "commercial": return "COMMERCIAL"
        "downtown": return "DOWNTOWN"
        "woods": return "WOODS"
        "rural": return "RURAL"
        _: return "MIXED"

func _draw_weather_vfx() -> void:
    if VISIBLE_COLS < 14:
        super._draw_weather_vfx()
        return

    # Far local zoom is an orientation mode, not a full-fidelity weather mode.
    # Keep weather readable but much cheaper; the mini-world map owns broad
    # orientation now.
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
                if _weather_cell_allowed(cell):
                    draw_rect(_cell_rect(cell), Color(0.72, 0.78, 0.77, fog_amount * 0.09))

    if rain > 0.02:
        var count := 24 + int(rain * 28.0)
        var span_y := board.size.y + 30.0
        for i in range(count):
            var y := fposmod(_weather_hash01(i, 307) * span_y + weather_vfx_time * (150.0 + _weather_hash01(i, 311) * 120.0), span_y) - 15.0
            var x := fposmod(_weather_hash01(i, 313) * board.size.x + weather_vfx_time * direction.x * 42.0, board.size.x)
            var start := board.position + Vector2(x, y)
            if not board.has_point(start) or not _weather_cell_allowed(_screen_to_cell(start)):
                continue
            var finish := _clamp_weather_point(start + Vector2(direction.x * 9.0, 14.0), board, 0.75)
            draw_line(start, finish, Color(0.72, 0.84, 0.90, 0.48), 1.15)

    if snow > 0.02:
        var count := 24 + int(snow * 30.0)
        var span_y := board.size.y + 20.0
        for i in range(count):
            var y := fposmod(_weather_hash01(i, 331) * span_y + weather_vfx_time * (28.0 + _weather_hash01(i, 337) * 36.0), span_y) - 10.0
            var x := fposmod(_weather_hash01(i, 347) * board.size.x + sin(weather_vfx_time * 0.8 + _weather_hash01(i, 349) * TAU) * 8.0, board.size.x)
            var p := board.position + Vector2(x, y)
            if board.grow(-1.5).has_point(p) and _weather_cell_allowed(_screen_to_cell(p)):
                draw_circle(p, 1.35, Color(0.93, 0.96, 1.0, 0.72))

    if wind > 0.28:
        for i in range(5):
            var x := fposmod(_weather_hash01(i, 359) * (board.size.x + 40.0) + weather_vfx_time * (45.0 + wind * 42.0), board.size.x + 40.0) - 20.0
            var y := _weather_hash01(i, 367) * board.size.y
            var p := board.position + Vector2(x, y)
            if board.has_point(p) and _weather_cell_allowed(_screen_to_cell(p)):
                draw_line(p, _clamp_weather_point(p + direction * 10.0, board, 1.0), Color(0.55, 0.48, 0.35, 0.50), 1.5)

    if str(weather_state.get("kind", Weather.CLEAR)) == Weather.STORM:
        var pulse: float = maxf(0.0, sin(weather_vfx_time * 1.9) - 0.97) * 5.0
        if pulse > 0.0:
            var origin: Vector2i = _view_origin()
            for y in range(origin.y, origin.y + VISIBLE_ROWS):
                for x in range(origin.x, origin.x + VISIBLE_COLS):
                    var cell := Vector2i(x, y)
                    if _weather_cell_allowed(cell):
                        draw_rect(_cell_rect(cell), Color(0.78, 0.84, 0.92, minf(0.12, pulse * 0.10)))
