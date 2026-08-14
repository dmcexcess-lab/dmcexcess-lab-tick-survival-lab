extends Node2D

const MapGen = preload("res://scripts/TacticalMapGenerator.gd")
const TickSchedulerClass = preload("res://scripts/TickScheduler.gd")
const PlayerActorClass = preload("res://scripts/PlayerActor.gd")
const LocalWorldStateClass = preload("res://scripts/LocalWorldState.gd")
const TimingDummyClass = preload("res://scripts/TimingDummy.gd")
const Tiles = preload("res://scripts/TacticalTiles.gd")
const Lighting = preload("res://scripts/TacticalLighting.gd")
const Perception = preload("res://scripts/TacticalPerception.gd")

const TILE := 32.0
const TOP := 132.0
const VIEW_H := TOP + float(MapGen.BOARD_H) * TILE
const TOUCH_RADIUS := 30.0

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

func _ready() -> void:
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
        if key_event.keycode == KEY_R:
            reroll(); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_TAB:
            _toggle_move_mode(); get_viewport().set_input_as_handled(); return
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
    var target: Vector2i = player.cell + dir
    if world.is_door(target) and not world.is_door_open(target):
        _record_zero("blocked", "closed door — interact first")
        return
    if not world.can_enter(target):
        _record_zero("blocked", "solid tile")
        return
    player.cell = target
    _commit(player.move_mode, player.movement_cost(), "to %s" % str(player.cell))

func _interact_facing_door() -> void:
    var target: Vector2i = player.cell + player.facing
    if not world.is_door(target):
        _record_zero("interact", "no door ahead")
        return
    var opened: bool = not world.is_door_open(target)
    world.set_door_open(target, opened)
    _commit("door", player.door_cost(), "opened" if opened else "closed")

func _toggle_move_mode() -> void:
    player.set_move_mode(PlayerActorClass.MODE_RUN if player.move_mode == PlayerActorClass.MODE_WALK else PlayerActorClass.MODE_WALK)
    _record_zero("mode", player.move_mode)

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

func _handle_pointer(pos: Vector2) -> void:
    if pos.y < TOP:
        if pos.x < 205.0: _toggle_move_mode()
        elif pos.x < 410.0: _interact_facing_door()
        else: reroll()
        return
    var center: Vector2 = _cell_center(player.cell)
    var delta: Vector2 = pos - center
    if delta.length() <= TOUCH_RADIUS:
        _interact_facing_door(); return
    if absf(delta.x) > absf(delta.y):
        _attempt_direction(Vector2i.RIGHT if delta.x > 0.0 else Vector2i.LEFT)
    else:
        _attempt_direction(Vector2i.DOWN if delta.y > 0.0 else Vector2i.UP)

func _draw() -> void:
    draw_rect(Rect2(0, 0, 640, VIEW_H), Color("101416"))
    draw_string(font, Vector2(12, 21), "Tick Survival Lab — tick + perception slice", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
    draw_string(font, Vector2(12, 42), "%s v%d | WASD | E door | F light | 4 day/night | 5 power | R reroll" % [MapGen.display_name(environment_id), variant], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("b8c4c2"))
    draw_string(font, Vector2(12, 63), "TICK %d  READY %s  %s  FACE %s  %s  POWER %s  FLASH %s" % [scheduler.world_tick, str(scheduler.player_ready).to_upper(), player.move_mode.to_upper(), _facing_name(player.facing), scene_time.to_upper(), "ON" if power_on else "OFF", "ON" if flashlight_on else "OFF"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f2d27a"))
    draw_string(font, Vector2(12, 84), "LAST %s +%d [%s]  %s" % [last_action_label, last_action_cost, last_action_status.to_upper(), last_action_detail], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("d8e0c8"))
    draw_string(font, Vector2(12, 104), "Fog: black=unseen, dim=remembered. Vision is facing + LOS + actual light. 1/2/3 keep scheduler proofs.", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("9eb0ae"))
    draw_string(font, Vector2(12, 123), "FF tactical atlas restored: ground, walls, doors, windows, props and directional survivor sprite.", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("8fa4a1"))

    _draw_map_tiles()
    _draw_lighting()
    _draw_light_glows()
    _draw_player()
    _draw_fog()

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
        draw_rect(_cell_rect(exit_value).grow(-4), Color("55d56e"), false, 2.0)

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
        draw_circle(c, 11.0, Color(source_color.r, source_color.g, source_color.b, 0.08 * strength))
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

func _facing_name(dir: Vector2i) -> String:
    if dir == Vector2i.UP: return "N"
    if dir == Vector2i.RIGHT: return "E"
    if dir == Vector2i.DOWN: return "S"
    if dir == Vector2i.LEFT: return "W"
    return "?"

func _cell_rect(p: Vector2i) -> Rect2:
    return Rect2(float(p.x) * TILE, TOP + float(p.y) * TILE, TILE, TILE)

func _cell_center(p: Vector2i) -> Vector2:
    return Vector2((float(p.x) + 0.5) * TILE, TOP + (float(p.y) + 0.5) * TILE)
