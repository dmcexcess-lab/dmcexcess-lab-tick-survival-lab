extends Node2D

const MapGen = preload("res://scripts/TacticalMapGenerator.gd")
const TickSchedulerClass = preload("res://scripts/TickScheduler.gd")
const PlayerActorClass = preload("res://scripts/PlayerActor.gd")
const LocalWorldStateClass = preload("res://scripts/LocalWorldState.gd")
const TimingDummyClass = preload("res://scripts/TimingDummy.gd")
const Tiles = preload("res://scripts/TacticalTiles.gd")
const Lighting = preload("res://scripts/TacticalLighting.gd")
const Perception = preload("res://scripts/TacticalPerception.gd")
const Weather = preload("res://scripts/TacticalWeather.gd")

const TILE := 28.0
const BOARD_X := 40.0
const TOP := 132.0
const CONTROL_TOP := 648.0
const VIEW_W := 640.0
const VIEW_H := 844.0
const TICKS_PER_MINUTE := 600
const WEATHER_KINDS := [Weather.CLEAR, Weather.RAIN, Weather.STORM, Weather.FOG, Weather.WIND]
const DAYS_IN_MONTH := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

const CONTROL_ROW_TOP_Y := 652.0
const CONTROL_ROW_TURN_Y := 712.0
const CONTROL_ROW_BOTTOM_Y := 780.0
const CONTROL_SIDE_W := 170.0
const CONTROL_TURN_H := 60.0

const BTN_DEV := Rect2(454, 8, 84, 38)
const BTN_MENU := Rect2(546, 8, 86, 38)
const BTN_TURN_L := Rect2(8, CONTROL_ROW_TURN_Y, CONTROL_SIDE_W, CONTROL_TURN_H)
const BTN_TURN_R := Rect2(462, CONTROL_ROW_TURN_Y, CONTROL_SIDE_W, CONTROL_TURN_H)
const BTN_CROUCH := Rect2(30, CONTROL_ROW_BOTTOM_Y, 126, 52)
const BTN_FORWARD := Rect2(462, CONTROL_ROW_TOP_Y, CONTROL_SIDE_W, CONTROL_ROW_TURN_Y - CONTROL_ROW_TOP_Y - 8.0)
const BTN_BACK := Rect2(462, CONTROL_ROW_BOTTOM_Y, CONTROL_SIDE_W, VIEW_H - CONTROL_ROW_BOTTOM_Y - 8.0)
const DEV_PANEL := Rect2(72, 154, 496, 286)
const DEV_WEATHER := Rect2(220, 286, 292, 38)
const DEV_APPLY := Rect2(408, 336, 104, 38)
const MENU_PANEL := Rect2(120, 238, 400, 300)
const MENU_RESUME := Rect2(190, 340, 260, 62)
const MENU_EXIT := Rect2(190, 430, 260, 62)

var rng := RandomNumberGenerator.new()
var environment_id := "back_alley"
var variant := 0
var spec: Dictionary = {}
var font: Font
var scheduler = TickSchedulerClass.new()
var player = PlayerActorClass.new()
var world = LocalWorldStateClass.new()
var timing_dummy = TimingDummyClass.new()
var last_action_label := "spawn"
var last_action_cost := 0
var last_action_detail := ""
var last_action_status := TickSchedulerClass.STATUS_READY
var last_other_actions := 0
var scene_time := "night"
var power_on := true
var flashlight_on := true
var light_levels: Dictionary = {}
var light_tints: Dictionary = {}
var indoor_cells: Dictionary = {}
var light_sources: Array = []
var opaque_cells: Dictionary = {}
var visible_cells: Dictionary = {}
var memory: Dictionary = {}
var menu_open := false
var dev_open := false
var weather_state: Dictionary = {}
var weather_index := 1
var weather_vfx_time := 0.0
var suppress_mouse_until_msec := 0
var clock_anchor_tick := 0
var clock_anchor_minutes := 21 * 60 + 30
var clock_anchor_month := 8
var clock_anchor_day := 14
var dev_time_input: LineEdit
var dev_date_input: LineEdit

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    rng.randomize()
    font = ThemeDB.fallback_font
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _create_dev_inputs()
    var validation: Dictionary = MapGen.validate_all()
    if not bool(validation.get("ok", false)):
        push_error("MAP_BOOTSTRAP_VALIDATION_FAILED: %s" % str(validation.get("failures", [])))
    else:
        print("MAP_BOOTSTRAP_VALIDATION_OK")
    reroll()

func _process(delta: float) -> void:
    weather_vfx_time += delta
    queue_redraw()

func _create_dev_inputs() -> void:
    dev_time_input = LineEdit.new()
    dev_time_input.position = Vector2(220, 198)
    dev_time_input.size = Vector2(150, 36)
    dev_time_input.placeholder_text = "HH:MM"
    dev_time_input.max_length = 5
    dev_time_input.process_mode = Node.PROCESS_MODE_ALWAYS
    dev_time_input.visible = false
    dev_time_input.text_submitted.connect(_on_dev_text_submitted)
    dev_time_input.focus_exited.connect(_apply_dev_fields)
    add_child(dev_time_input)

    dev_date_input = LineEdit.new()
    dev_date_input.position = Vector2(220, 242)
    dev_date_input.size = Vector2(150, 36)
    dev_date_input.placeholder_text = "MM/DD"
    dev_date_input.max_length = 5
    dev_date_input.process_mode = Node.PROCESS_MODE_ALWAYS
    dev_date_input.visible = false
    dev_date_input.text_submitted.connect(_on_dev_text_submitted)
    dev_date_input.focus_exited.connect(_apply_dev_fields)
    add_child(dev_date_input)

func reroll() -> void:
    environment_id = MapGen.pick_random(rng)
    variant = MapGen.pick_variant(environment_id, rng)
    spec = MapGen.build_layout(environment_id, variant)
    world.load_from_spec(spec)
    scheduler.reset()
    player.reset(spec.get("player_spawn", Vector2i.ZERO))
    timing_dummy.configure("clock_dummy", 4, scheduler.world_tick)
    memory.clear()
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
    last_action_detail = "new map"
    last_action_status = TickSchedulerClass.STATUS_READY
    last_other_actions = 0
    _recalc_perception()
    _refresh_dev_input_text()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        var key_event := event as InputEventKey
        if key_event.keycode == KEY_ESCAPE:
            if dev_open:
                _set_dev_open(false)
            else:
                _set_menu_open(not menu_open)
            get_viewport().set_input_as_handled()
            return
        if menu_open:
            return
        if key_event.keycode == KEY_R:
            reroll(); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_TAB:
            _toggle_move_mode(); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_C:
            _toggle_crouch(); get_viewport().set_input_as_handled(); return
        if key_event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]:
            _interact_facing_door(); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_F:
            flashlight_on = not flashlight_on
            _record_zero("flashlight", "ON" if flashlight_on else "OFF")
            _recalc_perception(); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_4:
            clock_anchor_minutes = posmod(_current_minute_of_day() + 12 * 60, 1440)
            clock_anchor_tick = scheduler.world_tick
            _record_zero("time", _format_time())
            _recalc_perception(); _refresh_dev_input_text(); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_5:
            power_on = not power_on
            _record_zero("power", "ON" if power_on else "OFF")
            _recalc_perception(); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_6:
            _cycle_weather(); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_1:
            _dev_timed_action("light_test", 3); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_2:
            _dev_timed_action("heavy_test", 12); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_3:
            _dev_reload(); get_viewport().set_input_as_handled(); return
        if dev_open:
            return
        var dir: Vector2i = _direction_for_key(key_event.keycode)
        if dir != Vector2i.ZERO:
            if key_event.shift_pressed:
                player.set_move_mode(PlayerActorClass.MODE_RUN)
            _attempt_direction(dir)
            get_viewport().set_input_as_handled()
            return
    elif event is InputEventScreenTouch and event.pressed:
        suppress_mouse_until_msec = Time.get_ticks_msec() + 700
        _handle_pointer(event.position)
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if Time.get_ticks_msec() < suppress_mouse_until_msec:
            get_viewport().set_input_as_handled()
            return
        _handle_pointer(event.position)
        get_viewport().set_input_as_handled()

func _direction_for_key(keycode: Key) -> Vector2i:
    match keycode:
        KEY_W, KEY_UP: return Vector2i.UP
        KEY_D, KEY_RIGHT: return Vector2i.RIGHT
        KEY_S, KEY_DOWN: return Vector2i.DOWN
        KEY_A, KEY_LEFT: return Vector2i.LEFT
        _: return Vector2i.ZERO

func _attempt_direction(dir: Vector2i) -> void:
    if player.facing != dir:
        player.facing = dir
        _commit("turn", player.turn_cost(), "facing %s" % _facing_name(dir))
        return
    _move_to(player.cell + dir, true)

func _move_to(target: Vector2i, forward: bool) -> void:
    if world.is_door(target) and not world.is_door_open(target):
        if forward:
            _interact_facing_door()
        else:
            _record_zero("blocked", "closed door")
        return
    if not world.can_enter(target):
        _record_zero("blocked", "solid tile")
        return
    player.cell = target
    _commit("crouch" if player.crouched else player.move_mode, player.movement_cost(), "to %s" % str(player.cell))

func _step_forward() -> void:
    _move_to(player.cell + player.facing, true)

func _step_back() -> void:
    _move_to(player.cell - player.facing, false)

func _rotate_player(step: int) -> void:
    var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
    var index: int = dirs.find(player.facing)
    player.facing = dirs[posmod(index + step, 4)]
    _commit("turn", player.turn_cost(), "facing %s" % _facing_name(player.facing))

func _interact_facing_door() -> void:
    var target: Vector2i = player.cell + player.facing
    if not world.is_door(target):
        _record_zero("interact", "no door ahead")
        return
    var opened: bool = not world.is_door_open(target)
    world.set_door_open(target, opened)
    _commit("door", player.door_cost(), "opened" if opened else "closed")

func _toggle_move_mode() -> void:
    if player.crouched:
        _record_zero("mode", "stand before running")
        return
    player.set_move_mode(PlayerActorClass.MODE_RUN if player.move_mode == PlayerActorClass.MODE_WALK else PlayerActorClass.MODE_WALK)
    _record_zero("mode", player.move_mode)

func _toggle_crouch() -> void:
    player.set_crouched(not player.crouched)
    _commit("stance", player.stance_cost(), "CROUCH" if player.crouched else "STAND")

func _cycle_weather() -> void:
    weather_index = (weather_index + 1) % WEATHER_KINDS.size()
    weather_state = Weather.make_state(WEATHER_KINDS[weather_index], Vector2(0.7, 0.25))
    _record_zero("weather", str(weather_state.get("kind", Weather.CLEAR)))
    _recalc_perception()

func _commit(action_id: String, cost: int, detail: String) -> void:
    var before: int = timing_dummy.actions_taken
    var result: Dictionary = scheduler.execute_action(player.actor_id, action_id, cost, TickSchedulerClass.POLICY_COMMITTED, [], {"cell": player.cell, "facing": player.facing}, [timing_dummy])
    last_other_actions = timing_dummy.actions_taken - before
    last_action_label = action_id
    last_action_cost = cost
    last_action_status = str(result.get("status", TickSchedulerClass.STATUS_COMPLETED))
    last_action_detail = "%s | dummy %d" % [detail, last_other_actions]
    _recalc_perception()

func _dev_timed_action(action_id: String, cost: int) -> void:
    _commit(action_id, cost, "timing proof")

func _dev_reload() -> void:
    var phases: Array = [{"id": "mag_out", "ticks": 4}, {"id": "mag_in", "ticks": 4}, {"id": "chamber", "ticks": 4}]
    var resume: Dictionary = {}
    var actors: Array = []
    var damage_dummy = TimingDummyClass.new()
    if scheduler.has_resumable_action("reload"):
        resume = scheduler.take_resumable_action("reload")
        timing_dummy.configure("clock_dummy", 4, scheduler.world_tick)
        actors = [timing_dummy]
    else:
        damage_dummy.configure("damage_dummy", 5, scheduler.world_tick)
        damage_dummy.interrupt_on_action = 1
        actors = [timing_dummy, damage_dummy]
    var before: int = timing_dummy.actions_taken
    var result: Dictionary = scheduler.execute_action(player.actor_id, "reload", 12, TickSchedulerClass.POLICY_RESUMABLE, phases, {}, actors, resume)
    last_other_actions = timing_dummy.actions_taken - before
    last_action_label = "reload"
    last_action_cost = 12
    last_action_status = str(result.get("status", ""))
    var phase: String = str(result.get("phase_id", ""))
    var elapsed: int = int(result.get("elapsed_ticks", 0))
    last_action_detail = "%s @ %d/12 | %s" % [phase, elapsed, "press 3 resume" if scheduler.has_resumable_action("reload") else "ready"]
    _recalc_perception()

func _record_zero(action_id: String, detail: String) -> void:
    last_action_label = action_id
    last_action_cost = 0
    last_action_status = TickSchedulerClass.STATUS_READY
    last_other_actions = 0
    last_action_detail = detail
    queue_redraw()

func _recalc_perception() -> void:
    _sync_scene_time_from_clock()
    var lighting: Dictionary = Perception.calculate_lighting(spec, world, environment_id, scene_time, power_on, player.cell, player.facing, flashlight_on, weather_state)
    light_levels = lighting.get("levels", {})
    light_tints = lighting.get("tints", {})
    indoor_cells = lighting.get("indoors", {})
    light_sources = lighting.get("sources", [])
    opaque_cells = lighting.get("opaque", {})
    var visibility: Dictionary = Perception.calculate_visibility(player.cell, player.facing, light_levels, spec, world, opaque_cells, memory, 7, weather_state)
    visible_cells = visibility.get("visible", {})
    memory = visibility.get("memory", {})
    queue_redraw()

func _set_menu_open(opened: bool) -> void:
    menu_open = opened
    if menu_open:
        dev_open = false
    get_tree().paused = menu_open
    _sync_dev_input_visibility()
    queue_redraw()

func _set_dev_open(opened: bool) -> void:
    dev_open = opened
    if dev_open:
        _refresh_dev_input_text()
    _sync_dev_input_visibility()
    queue_redraw()

func _sync_dev_input_visibility() -> void:
    if dev_time_input == null or dev_date_input == null:
        return
    var shown: bool = dev_open and not menu_open
    dev_time_input.visible = shown
    dev_date_input.visible = shown

func _refresh_dev_input_text() -> void:
    if dev_time_input == null or dev_date_input == null:
        return
    var minute: int = _current_minute_of_day()
    dev_time_input.text = "%02d:%02d" % [minute / 60, minute % 60]
    var md: Vector2i = _current_month_day()
    dev_date_input.text = "%02d/%02d" % [md.x, md.y]

func _on_dev_text_submitted(_value: String) -> void:
    _apply_dev_fields()

func _apply_dev_fields() -> void:
    if dev_time_input == null or dev_date_input == null:
        return
    var time_parts: PackedStringArray = dev_time_input.text.strip_edges().split(":")
    var date_parts: PackedStringArray = dev_date_input.text.strip_edges().split("/")
    if time_parts.size() != 2 or date_parts.size() != 2:
        _refresh_dev_input_text()
        return
    if not time_parts[0].is_valid_int() or not time_parts[1].is_valid_int() or not date_parts[0].is_valid_int() or not date_parts[1].is_valid_int():
        _refresh_dev_input_text()
        return
    var hour: int = clampi(int(time_parts[0]), 0, 23)
    var minute: int = clampi(int(time_parts[1]), 0, 59)
    var month: int = clampi(int(date_parts[0]), 1, 12)
    var day: int = clampi(int(date_parts[1]), 1, DAYS_IN_MONTH[month - 1])
    clock_anchor_tick = scheduler.world_tick
    clock_anchor_minutes = hour * 60 + minute
    clock_anchor_month = month
    clock_anchor_day = day
    _refresh_dev_input_text()
    _record_zero("dev_clock", "%s %s" % [_format_date(), _format_time()])
    _recalc_perception()

func _current_total_minutes() -> int:
    return clock_anchor_minutes + maxi(0, scheduler.world_tick - clock_anchor_tick) / TICKS_PER_MINUTE

func _current_minute_of_day() -> int:
    return posmod(_current_total_minutes(), 1440)

func _current_month_day() -> Vector2i:
    var month: int = clock_anchor_month
    var day: int = clock_anchor_day + _current_total_minutes() / 1440
    while day > DAYS_IN_MONTH[month - 1]:
        day -= DAYS_IN_MONTH[month - 1]
        month += 1
        if month > 12:
            month = 1
    return Vector2i(month, day)

func _format_time() -> String:
    var minute: int = _current_minute_of_day()
    var hour24: int = minute / 60
    var hour12: int = hour24 % 12
    if hour12 == 0:
        hour12 = 12
    return "%d:%02d %s" % [hour12, minute % 60, "PM" if hour24 >= 12 else "AM"]

func _format_date() -> String:
    var md: Vector2i = _current_month_day()
    return "%02d/%02d" % [md.x, md.y]

func _sync_scene_time_from_clock() -> void:
    var hour: int = _current_minute_of_day() / 60
    scene_time = "day" if hour >= 7 and hour < 19 else "night"

func _outside_temp_f() -> float:
    var md: Vector2i = _current_month_day()
    return Weather.outside_temperature_f(md.x, md.y, _current_minute_of_day(), weather_state)

func _player_is_indoor() -> bool:
    return indoor_cells.has(player.cell)

func _current_temp_f() -> float:
    var outside: float = _outside_temp_f()
    return Weather.indoor_temperature_f(outside) if _player_is_indoor() else outside

func _look_at_label() -> String:
    var target: Vector2i = player.cell + player.facing
    if target.x < 0 or target.y < 0 or target.x >= MapGen.BOARD_W or target.y >= MapGen.BOARD_H:
        return "map edge"
    for entry_value in spec.get("props", []):
        var entry: Array = entry_value
        if entry[0] == target:
            return str(entry[1]).replace("_", " ")
    if spec.get("barrels", []).has(target):
        return "barrel"
    if world.is_door(target):
        return "door (%s)" % ("open" if world.is_door_open(target) else "closed")
    if spec.get("glass", []).has(target):
        return "window / glass"
    if spec.get("walls", []).has(target):
        return "wall"
    return str(MapGen.ground_at(spec, target)).replace("_", " ")

func _quit_to_google() -> void:
    if OS.has_feature("web"):
        JavaScriptBridge.eval("window.location.assign('https://www.google.com')")
    else:
        OS.shell_open("https://www.google.com")

func _handle_pointer(pos: Vector2) -> void:
    if BTN_MENU.has_point(pos):
        _set_menu_open(not menu_open)
        return
    if BTN_DEV.has_point(pos) and not menu_open:
        _set_dev_open(not dev_open)
        return
    if menu_open:
        if MENU_RESUME.has_point(pos):
            _set_menu_open(false)
        elif MENU_EXIT.has_point(pos):
            _quit_to_google()
        return
    if dev_open:
        if DEV_WEATHER.has_point(pos):
            _cycle_weather(); return
        if DEV_APPLY.has_point(pos):
            _apply_dev_fields(); return
        if DEV_PANEL.has_point(pos):
            return
    if BTN_TURN_L.has_point(pos):
        _rotate_player(-1); return
    if BTN_TURN_R.has_point(pos):
        _rotate_player(1); return
    if BTN_FORWARD.has_point(pos):
        _step_forward(); return
    if BTN_BACK.has_point(pos):
        _step_back(); return
    if BTN_CROUCH.has_point(pos):
        _toggle_crouch(); return
    var board_rect := Rect2(BOARD_X, TOP, float(MapGen.BOARD_W) * TILE, float(MapGen.BOARD_H) * TILE)
    if not board_rect.has_point(pos):
        return
    var center: Vector2 = _cell_center(player.cell)
    var delta: Vector2 = pos - center
    if delta.length() <= 24.0:
        _interact_facing_door(); return
    if absf(delta.x) > absf(delta.y):
        _attempt_direction(Vector2i.RIGHT if delta.x > 0.0 else Vector2i.LEFT)
    else:
        _attempt_direction(Vector2i.DOWN if delta.y > 0.0 else Vector2i.UP)

func _draw() -> void:
    draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color("101416"))
    _draw_game_hud()
    _draw_button(BTN_DEV, "DEV", dev_open, 12)
    _draw_button(BTN_MENU, "MENU", menu_open, 12)

    _draw_map_tiles()
    _draw_lighting()
    _draw_light_glows()
    _draw_player()
    _draw_weather_vfx()
    _draw_fog()
    _draw_controls()
    if dev_open and not menu_open:
        _draw_dev_panel()
    if menu_open:
        _draw_menu()

func _draw_game_hud() -> void:
    draw_string(font, Vector2(12, 20), "TICK SURVIVAL LAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
    draw_string(font, Vector2(12, 43), "%s  HP %d  FAT %d%%  CARRY %.1f/%.1f" % [player.display_name, int(round(player.health)), player.fatigue_percent(), player.carry_weight, player.carry_capacity], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("dce7df"))
    draw_string(font, Vector2(12, 64), "%s  %s  %s" % [_format_time(), _format_date(), str(weather_state.get("kind", Weather.CLEAR)).to_upper()], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("f2d27a"))
    var outside: float = _outside_temp_f()
    var env_text: String
    if _player_is_indoor():
        env_text = "INDOOR  %.0f°F   Outside %.0f°F" % [_current_temp_f(), outside]
    else:
        env_text = "OUTDOOR  %.0f°F   Wind %.0f mph" % [outside, Weather.wind_mph(weather_state)]
    draw_string(font, Vector2(12, 85), env_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("b7c8c2"))
    draw_string(font, Vector2(12, 106), "Looking at: %s" % _look_at_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("c8d5cf"))
    draw_string(font, Vector2(12, 124), "%s v%d" % [MapGen.display_name(environment_id), variant], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("7f918b"))

func _draw_dev_panel() -> void:
    draw_rect(DEV_PANEL, Color(0.035, 0.045, 0.041, 0.97))
    draw_rect(DEV_PANEL, Color("f0c95d"), false, 2.0)
    draw_string(font, Vector2(92, 180), "DEVELOPER WORLD CONTROLS", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("f2d27a"))
    draw_string(font, Vector2(94, 220), "Time (HH:MM)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
    draw_string(font, Vector2(94, 264), "Date (MM/DD)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
    draw_string(font, Vector2(94, 309), "Weather", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
    _draw_button(DEV_WEATHER, str(weather_state.get("kind", Weather.CLEAR)).to_upper(), true, 11)
    _draw_button(DEV_APPLY, "APPLY", false, 11)
    var location: String = "INDOOR" if _player_is_indoor() else "OUTDOOR"
    draw_string(font, Vector2(94, 356), "Tile: %s   Current %.0f°F   Outside %.0f°F   Wind %.0f mph" % [location, _current_temp_f(), _outside_temp_f(), Weather.wind_mph(weather_state)], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("c8d5cf"))
    draw_string(font, Vector2(94, 378), "Tick %d | Ready %s | Cell %s | Face %s | Power %s | Flash %s" % [scheduler.world_tick, str(scheduler.player_ready).to_upper(), str(player.cell), _facing_name(player.facing), "ON" if power_on else "OFF", "ON" if flashlight_on else "OFF"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("a9b9b3"))
    draw_string(font, Vector2(94, 399), "Last: %s +%d [%s] %s" % [last_action_label, last_action_cost, last_action_status.to_upper(), last_action_detail], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("a9b9b3"))
    draw_string(font, Vector2(94, 420), "Keyboard dev: 1/2/3 timing | 4 +12h | 5 power | 6 weather | F light", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("82958e"))

func _draw_map_tiles() -> void:
    var theme: String = MapGen.theme_name(environment_id)
    for y in range(MapGen.BOARD_H):
        for x in range(MapGen.BOARD_W):
            var p := Vector2i(x, y)
            Tiles.draw_ground(self, _cell_rect(p), MapGen.ground_at(spec, p))
    for p_value in spec.get("walls", []):
        Tiles.draw_wall(self, _cell_rect(p_value), theme)
    for door_value in world.doors.keys():
        var p: Vector2i = door_value
        Tiles.draw_door(self, _cell_rect(p), world.is_door_open(p))
    for p_value in spec.get("glass", []):
        Tiles.draw_window(self, _cell_rect(p_value))
    for entry_value in spec.get("props", []):
        var entry: Array = entry_value
        Tiles.draw_prop(self, _cell_rect(entry[0]), str(entry[1]))
    for p_value in spec.get("barrels", []):
        Tiles.draw_barrel(self, _cell_rect(p_value))
    for exit_value in spec.get("exit_cells", []):
        draw_rect(_cell_rect(exit_value).grow(-3), Color("55d56e"), false, 2.0)

func _draw_lighting() -> void:
    var dark_tint: Color = Lighting.ambient_tint(MapGen.theme_name(environment_id), scene_time)
    for y in range(MapGen.BOARD_H):
        for x in range(MapGen.BOARD_W):
            var cell := Vector2i(x, y)
            var level: float = float(light_levels.get(cell, 0.0))
            var darkness: float = Lighting.darkness_alpha(level)
            draw_rect(_cell_rect(cell), Color(dark_tint.r, dark_tint.g, dark_tint.b, darkness))
            if light_tints.has(cell):
                var tint := Color(str(light_tints[cell]))
                var wash: float = Lighting.color_wash_alpha(level)
                if wash > 0.0:
                    draw_rect(_cell_rect(cell).grow(-1), Color(tint.r, tint.g, tint.b, wash))

func _draw_light_glows() -> void:
    var now: int = Time.get_ticks_msec()
    for source_value in light_sources:
        var source: Dictionary = source_value
        if not Lighting.source_active(source, power_on):
            continue
        var p: Vector2i = source.get("pos", Vector2i(-99, -99))
        if p.x < 0:
            continue
        var c: Vector2 = _cell_center(p)
        var source_color := Color(str(source.get("color", "ffffff")))
        var strength: float = Lighting.visual_strength(source, now)
        draw_circle(c, 10.0, Color(source_color.r, source_color.g, source_color.b, 0.08 * strength))
        draw_circle(c, 3.0, Color(source_color.r, source_color.g, source_color.b, 0.65 * strength))

func _draw_player() -> void:
    Tiles.draw_player(self, _cell_rect(player.cell).grow(-1), player.facing)
    draw_rect(_cell_rect(player.cell).grow(-2), Color("65cfff"), false, 1.5)

func _draw_fog() -> void:
    for y in range(MapGen.BOARD_H):
        for x in range(MapGen.BOARD_W):
            var p := Vector2i(x, y)
            if visible_cells.has(p):
                continue
            var alpha: float = 0.62 if memory.has(p) else 0.96
            draw_rect(_cell_rect(p), Color(0.005, 0.008, 0.010, alpha))

func _weather_cell_allowed(cell: Vector2i) -> bool:
    if cell.x < 0 or cell.y < 0 or cell.x >= MapGen.BOARD_W or cell.y >= MapGen.BOARD_H:
        return false
    if indoor_cells.has(cell):
        return false
    if spec.get("walls", []).has(cell):
        return false
    return true

func _screen_to_cell(pos: Vector2) -> Vector2i:
    return Vector2i(int(floor((pos.x - BOARD_X) / TILE)), int(floor((pos.y - TOP) / TILE)))

func _draw_weather_vfx() -> void:
    var board := Rect2(BOARD_X, TOP, float(MapGen.BOARD_W) * TILE, float(MapGen.BOARD_H) * TILE)
    var rain: float = Weather.precipitation(weather_state)
    var fog_amount: float = Weather.fog_density(weather_state)
    var wind: float = Weather.wind_strength(weather_state)
    var direction: Vector2 = Weather.wind_direction(weather_state)

    if fog_amount > 0.05:
        for y in range(MapGen.BOARD_H):
            for x in range(MapGen.BOARD_W):
                var cell := Vector2i(x, y)
                if not _weather_cell_allowed(cell):
                    continue
                var drift: float = 0.5 + 0.5 * sin(weather_vfx_time * 0.7 + float(x) * 0.43 + float(y) * 0.71)
                draw_rect(_cell_rect(cell), Color(0.72, 0.78, 0.77, fog_amount * (0.035 + drift * 0.055)))

    if rain > 0.02:
        var count: int = 34 + int(rain * 62.0)
        for i in range(count):
            var seed_x: float = fmod(float(i * 83), board.size.x)
            var speed: float = 190.0 + float(i % 7) * 21.0 + rain * 150.0
            var y: float = fmod(float(i * 47) + weather_vfx_time * speed, board.size.y + 36.0) - 18.0
            var x: float = fmod(seed_x + weather_vfx_time * direction.x * 68.0 + y * direction.x * 0.22, board.size.x)
            var start := board.position + Vector2(x, y)
            if not _weather_cell_allowed(_screen_to_cell(start)):
                continue
            var streak := Vector2(direction.x * (9.0 + rain * 5.0), 12.0 + rain * 11.0)
            draw_line(start, start + streak, Color(0.72, 0.84, 0.90, 0.26 + rain * 0.28), 1.25)

    if wind > 0.28:
        for i in range(10):
            var travel: float = fmod(weather_vfx_time * (38.0 + wind * 70.0) + float(i) * 97.0, board.size.x + 70.0) - 35.0
            var y: float = board.position.y + 50.0 + fmod(float(i * 73), board.size.y - 70.0)
            var p := Vector2(board.position.x + travel, y + sin(weather_vfx_time * 2.2 + float(i)) * 11.0)
            if not _weather_cell_allowed(_screen_to_cell(p)):
                continue
            draw_line(p, p + direction * (6.0 + wind * 10.0), Color(0.55, 0.48, 0.35, 0.56), 2.0)

    if str(weather_state.get("kind", Weather.CLEAR)) == Weather.STORM:
        var pulse: float = maxf(0.0, sin(weather_vfx_time * 1.9 + sin(weather_vfx_time * 0.37) * 3.0) - 0.965) * 5.0
        if pulse > 0.0:
            for y in range(MapGen.BOARD_H):
                for x in range(MapGen.BOARD_W):
                    var cell := Vector2i(x, y)
                    if _weather_cell_allowed(cell):
                        draw_rect(_cell_rect(cell), Color(0.78, 0.84, 0.92, minf(0.16, pulse * 0.12)))

func _draw_controls() -> void:
    draw_rect(Rect2(0, CONTROL_TOP, VIEW_W, VIEW_H - CONTROL_TOP), Color(0.025, 0.032, 0.028, 0.96))
    draw_line(Vector2(0, CONTROL_TOP), Vector2(VIEW_W, CONTROL_TOP), Color("626a64"), 2.0)
    _draw_button(BTN_TURN_L, "TURN L", false, 18)
    _draw_button(BTN_TURN_R, "TURN R", false, 18)
    _draw_button(BTN_CROUCH, "CROUCH", player.crouched, 11)
    _draw_button(BTN_FORWARD, "FORWARD", false, 11)
    _draw_button(BTN_BACK, "BACK", false, 11)
    draw_string(font, Vector2(210, 690), "World controls", HORIZONTAL_ALIGNMENT_CENTER, 220, 11, Color("84928c"))
    draw_string(font, Vector2(210, 823), "Tap map still works", HORIZONTAL_ALIGNMENT_CENTER, 220, 10, Color("84928c"))

func _draw_menu() -> void:
    draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color(0.0, 0.0, 0.0, 0.64))
    draw_rect(MENU_PANEL, Color("171d1b"))
    draw_rect(MENU_PANEL, Color("a5b0a8"), false, 2.0)
    draw_string(font, Vector2(MENU_PANEL.position.x, MENU_PANEL.position.y + 52), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, MENU_PANEL.size.x, 24, Color.WHITE)
    draw_string(font, Vector2(MENU_PANEL.position.x, MENU_PANEL.position.y + 80), "Simulation paused — cosmetic weather keeps moving.", HORIZONTAL_ALIGNMENT_CENTER, MENU_PANEL.size.x, 11, Color("aab7b0"))
    _draw_button(MENU_RESUME, "RESUME", false, 16)
    _draw_button(MENU_EXIT, "EXIT TO GOOGLE", false, 15)

func _draw_button(rect: Rect2, text: String, active: bool, size: int) -> void:
    var fill := Color("3f513f") if active else Color("171c19")
    var edge := Color("f0c95d") if active else Color("aeb7b0")
    draw_rect(rect, fill)
    draw_rect(rect, edge, false, 2.0)
    var y := rect.position.y + rect.size.y * 0.5 + float(size) * 0.34
    draw_string(font, Vector2(rect.position.x, y), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, Color.WHITE)

func _facing_name(dir: Vector2i) -> String:
    if dir == Vector2i.UP: return "N"
    if dir == Vector2i.RIGHT: return "E"
    if dir == Vector2i.DOWN: return "S"
    if dir == Vector2i.LEFT: return "W"
    return "?"

func _cell_rect(p: Vector2i) -> Rect2:
    return Rect2(BOARD_X + float(p.x) * TILE, TOP + float(p.y) * TILE, TILE, TILE)

func _cell_center(p: Vector2i) -> Vector2:
    return Vector2(BOARD_X + (float(p.x) + 0.5) * TILE, TOP + (float(p.y) + 0.5) * TILE)
