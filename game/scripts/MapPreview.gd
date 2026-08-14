extends Node2D

const MapGen = preload("res://scripts/TacticalMapGenerator.gd")
const TickSchedulerClass = preload("res://scripts/TickScheduler.gd")
const PlayerActorClass = preload("res://scripts/PlayerActor.gd")
const LocalWorldStateClass = preload("res://scripts/LocalWorldState.gd")
const TimingDummyClass = preload("res://scripts/TimingDummy.gd")
const Tiles = preload("res://scripts/TacticalTiles.gd")
const Lighting = preload("res://scripts/TacticalLighting.gd")
const Perception = preload("res://scripts/TacticalPerception.gd")

const TILE := 28.0
const BOARD_X := 40.0
const TOP := 132.0
const CONTROL_TOP := 648.0
const VIEW_W := 640.0
const VIEW_H := 844.0

const BTN_MENU := Rect2(546, 8, 86, 38)
const BTN_TURN_L := Rect2(8, 684, 170, 100)
const BTN_TURN_R := Rect2(462, 702, 170, 90)
const BTN_FORWARD := Rect2(495, 652, 104, 42)
const BTN_CROUCH := Rect2(41, 792, 104, 42)
const BTN_BACK := Rect2(495, 798, 104, 42)
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

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    rng.randomize()
    font = ThemeDB.fallback_font
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    var validation: Dictionary = MapGen.validate_all()
    if not bool(validation.get("ok", false)):
        push_error("MAP_BOOTSTRAP_VALIDATION_FAILED: %s" % str(validation.get("failures", [])))
    else:
        print("MAP_BOOTSTRAP_VALIDATION_OK")
    reroll()

func reroll() -> void:
    environment_id = MapGen.pick_random(rng)
    variant = MapGen.pick_variant(environment_id, rng)
    spec = MapGen.build_layout(environment_id, variant)
    world.load_from_spec(spec)
    scheduler.reset()
    player.reset(spec.get("player_spawn", Vector2i.ZERO))
    timing_dummy.configure("clock_dummy", 4, scheduler.world_tick)
    memory.clear()
    scene_time = "night"
    power_on = true
    flashlight_on = true
    last_action_label = "spawn"
    last_action_cost = 0
    last_action_detail = "new map"
    last_action_status = TickSchedulerClass.STATUS_READY
    last_other_actions = 0
    _recalc_perception()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        var key_event := event as InputEventKey
        if key_event.keycode == KEY_ESCAPE:
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
            scene_time = "day" if scene_time == "night" else "night"
            _record_zero("time", scene_time)
            _recalc_perception(); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_5:
            power_on = not power_on
            _record_zero("power", "ON" if power_on else "OFF")
            _recalc_perception(); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_1:
            _dev_timed_action("light_test", 3); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_2:
            _dev_timed_action("heavy_test", 12); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_3:
            _dev_reload(); get_viewport().set_input_as_handled(); return
        var dir: Vector2i = _direction_for_key(key_event.keycode)
        if dir != Vector2i.ZERO:
            if key_event.shift_pressed:
                player.set_move_mode(PlayerActorClass.MODE_RUN)
            _attempt_direction(dir)
            get_viewport().set_input_as_handled()
            return
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _handle_pointer(event.position)
        get_viewport().set_input_as_handled()
    elif event is InputEventScreenTouch and event.pressed:
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
    var lighting: Dictionary = Perception.calculate_lighting(spec, world, environment_id, scene_time, power_on, player.cell, player.facing, flashlight_on)
    light_levels = lighting.get("levels", {})
    light_tints = lighting.get("tints", {})
    indoor_cells = lighting.get("indoors", {})
    light_sources = lighting.get("sources", [])
    opaque_cells = lighting.get("opaque", {})
    var visibility: Dictionary = Perception.calculate_visibility(player.cell, player.facing, light_levels, spec, world, opaque_cells, memory, 7)
    visible_cells = visibility.get("visible", {})
    memory = visibility.get("memory", {})
    queue_redraw()

func _set_menu_open(opened: bool) -> void:
    menu_open = opened
    get_tree().paused = menu_open
    queue_redraw()

func _quit_to_google() -> void:
    if OS.has_feature("web"):
        JavaScriptBridge.eval("window.location.assign('https://www.google.com')")
    else:
        OS.shell_open("https://www.google.com")

func _handle_pointer(pos: Vector2) -> void:
    if BTN_MENU.has_point(pos):
        _set_menu_open(not menu_open)
        return
    if menu_open:
        if MENU_RESUME.has_point(pos):
            _set_menu_open(false)
        elif MENU_EXIT.has_point(pos):
            _quit_to_google()
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
    draw_string(font, Vector2(12, 21), "Tick Survival Lab — tick + perception slice", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
    draw_string(font, Vector2(12, 42), "%s v%d | WASD | E door | C crouch | F light | 4 day/night | 5 power" % [MapGen.display_name(environment_id), variant], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("b8c4c2"))
    draw_string(font, Vector2(12, 63), "TICK %d  READY %s  %s  FACE %s  %s  POWER %s  FLASH %s" % [scheduler.world_tick, str(scheduler.player_ready).to_upper(), "CROUCH" if player.crouched else player.move_mode.to_upper(), _facing_name(player.facing), scene_time.to_upper(), "ON" if power_on else "OFF", "ON" if flashlight_on else "OFF"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("f2d27a"))
    draw_string(font, Vector2(12, 84), "LAST %s +%d [%s]  %s" % [last_action_label, last_action_cost, last_action_status.to_upper(), last_action_detail], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d8e0c8"))
    draw_string(font, Vector2(12, 104), "Fog: black=unseen, dim=remembered. Facing moves the cone; the survivor sprite stays upright.", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("9eb0ae"))
    draw_string(font, Vector2(12, 123), "Touch: FF-style stacked controls. Menu pauses the game. 1/2/3 keep scheduler proofs.", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("8fa4a1"))
    _draw_button(BTN_MENU, "MENU", menu_open, 12)

    _draw_map_tiles()
    _draw_lighting()
    _draw_light_glows()
    _draw_player()
    _draw_fog()
    _draw_controls()
    if menu_open:
        _draw_menu()

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
    var center := _cell_center(player.cell)
    var facing_tip := center + Vector2(player.facing) * 11.0
    draw_line(center, facing_tip, Color("d9f7ff"), 2.0)
    draw_circle(facing_tip, 2.0, Color("d9f7ff"))

func _draw_fog() -> void:
    for y in range(MapGen.BOARD_H):
        for x in range(MapGen.BOARD_W):
            var p := Vector2i(x, y)
            if visible_cells.has(p):
                continue
            var alpha: float = 0.62 if memory.has(p) else 0.96
            draw_rect(_cell_rect(p), Color(0.005, 0.008, 0.010, alpha))

func _draw_controls() -> void:
    draw_rect(Rect2(0, CONTROL_TOP, VIEW_W, VIEW_H - CONTROL_TOP), Color(0.025, 0.032, 0.028, 0.96))
    draw_line(Vector2(0, CONTROL_TOP), Vector2(VIEW_W, CONTROL_TOP), Color("626a64"), 2.0)
    _draw_button(BTN_TURN_L, "TURN L", false, 20)
    _draw_button(BTN_TURN_R, "TURN R", false, 20)
    _draw_button(BTN_FORWARD, "FORWARD", false, 11)
    _draw_button(BTN_CROUCH, "CROUCH", player.crouched, 11)
    _draw_button(BTN_BACK, "BACK", false, 11)
    draw_string(font, Vector2(210, 823), "Tap map still works", HORIZONTAL_ALIGNMENT_CENTER, 220, 10, Color("84928c"))

func _draw_menu() -> void:
    draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color(0.0, 0.0, 0.0, 0.64))
    draw_rect(MENU_PANEL, Color("171d1b"))
    draw_rect(MENU_PANEL, Color("a5b0a8"), false, 2.0)
    draw_string(font, Vector2(MENU_PANEL.position.x, MENU_PANEL.position.y + 52), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, MENU_PANEL.size.x, 24, Color.WHITE)
    draw_string(font, Vector2(MENU_PANEL.position.x, MENU_PANEL.position.y + 80), "Actual pause menu — world ticks do not advance.", HORIZONTAL_ALIGNMENT_CENTER, MENU_PANEL.size.x, 11, Color("aab7b0"))
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
