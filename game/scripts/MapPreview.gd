extends Node2D

const MapGen = preload("res://scripts/TacticalMapGenerator.gd")
const TickSchedulerClass = preload("res://scripts/TickScheduler.gd")
const PlayerActorClass = preload("res://scripts/PlayerActor.gd")
const LocalWorldStateClass = preload("res://scripts/LocalWorldState.gd")
const TimingDummyClass = preload("res://scripts/TimingDummy.gd")

const TILE := 32.0
const TOP := 112.0
const BOARD_PIXEL_H := float(MapGen.BOARD_H) * TILE
const VIEW_H := TOP + BOARD_PIXEL_H
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

func _ready() -> void:
    rng.randomize()
    font = ThemeDB.fallback_font
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
    last_action_label = "spawn"
    last_action_cost = 0
    last_action_detail = "new map"
    last_action_status = TickSchedulerClass.STATUS_READY
    last_other_actions = 0
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        var key_event := event as InputEventKey
        if key_event.keycode == KEY_R:
            reroll(); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_TAB:
            _toggle_move_mode(); get_viewport().set_input_as_handled(); return
        if key_event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]:
            _interact_facing_door(); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_1:
            _dev_timed_action("light_test", 3); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_2:
            _dev_timed_action("heavy_test", 12); get_viewport().set_input_as_handled(); return
        if key_event.keycode == KEY_3:
            _dev_reload(); get_viewport().set_input_as_handled(); return
        var dir := _direction_for_key(key_event.keycode)
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
    last_action_detail = "%s | dummy acted %d" % [detail, last_other_actions]
    queue_redraw()

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
    last_action_detail = "%s @ %d/12 | %s" % [phase, elapsed, "press 3 to resume" if scheduler.has_resumable_action("reload") else "ready"]
    queue_redraw()

func _record_zero(action_id: String, detail: String) -> void:
    last_action_label = action_id
    last_action_cost = 0
    last_action_status = TickSchedulerClass.STATUS_READY
    last_other_actions = 0
    last_action_detail = detail
    queue_redraw()

func _handle_pointer(pos: Vector2) -> void:
    if pos.y < TOP:
        if pos.x < 205.0: _toggle_move_mode()
        elif pos.x < 410.0: _interact_facing_door()
        else: reroll()
        return
    var center := _cell_center(player.cell)
    var delta := pos - center
    if delta.length() <= TOUCH_RADIUS:
        _interact_facing_door(); return
    _attempt_direction(Vector2i.RIGHT if delta.x > 0.0 else Vector2i.LEFT) if absf(delta.x) > absf(delta.y) else _attempt_direction(Vector2i.DOWN if delta.y > 0.0 else Vector2i.UP)

func _draw() -> void:
    draw_rect(Rect2(0, 0, 640, VIEW_H), Color("101416"))
    draw_string(font, Vector2(12, 22), "Tick Survival Lab — Milestone 0.2 action execution", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
    draw_string(font, Vector2(12, 43), "%s | v%d | WASD/arrows | Tab mode | E door | R reroll | 1 light | 2 heavy | 3 reload" % [MapGen.display_name(environment_id), variant], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("b8c4c2"))
    draw_string(font, Vector2(12, 64), "TICK %d   READY %s   MODE %s   FACE %s" % [scheduler.world_tick, str(scheduler.player_ready).to_upper(), player.move_mode.to_upper(), _facing_name(player.facing)], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("f2d27a"))
    draw_string(font, Vector2(12, 84), "LAST %s +%d [%s]   %s" % [last_action_label, last_action_cost, last_action_status.to_upper(), last_action_detail], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d8e0c8"))
    draw_string(font, Vector2(12, 104), "Timing dummy acts every 4 ticks. Compare keys 1 vs 2; key 3 proves interrupted/resumable phased actions.", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("9eb0ae"))

    for y in range(MapGen.BOARD_H):
        for x in range(MapGen.BOARD_W):
            var p := Vector2i(x, y)
            var rect := Rect2(float(x) * TILE, TOP + float(y) * TILE, TILE, TILE)
            draw_rect(rect, MapGen.ground_color(MapGen.ground_at(spec, p)))
            draw_rect(rect, Color(1, 1, 1, 0.07), false, 1.0)
    var wall_color := MapGen.wall_color(environment_id)
    for p_value in spec.get("walls", []): draw_rect(_cell_rect(p_value), wall_color)
    for door_cell_value in world.doors.keys():
        var p: Vector2i = door_cell_value
        draw_rect(_cell_rect(p).grow(-10 if world.is_door_open(p) else -5), Color("a58b6d") if world.is_door_open(p) else Color("80664b"))
    for p_value in spec.get("glass", []): draw_rect(_cell_rect(p_value).grow(-6), Color("6fb9cf"))
    for p_value in spec.get("obstacles", []): draw_rect(_cell_rect(p_value).grow(-4), Color("33383a"))
    for p_value in spec.get("barrels", []): draw_circle(_cell_center(p_value), 8.0, Color("b94b38"))
    for entry_value in spec.get("props", []):
        var entry: Array = entry_value
        draw_string(font, _cell_center(entry[0]) + Vector2(-13, 5), str(entry[1]).left(3).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 26, 8, Color("e0d7ba"))
    for exit_value in spec.get("exit_cells", []): draw_rect(_cell_rect(exit_value).grow(-4), Color("55d56e"), false, 3.0)
    _draw_player()

func _draw_player() -> void:
    var center := _cell_center(player.cell)
    draw_circle(center, 10.0, Color("5fc78a"))
    var tip := center + Vector2(player.facing) * 14.0
    draw_line(center, tip, Color("effff5"), 3.0)
    draw_circle(tip, 2.5, Color("effff5"))
    draw_string(font, center + Vector2(-11, 4), "YOU", HORIZONTAL_ALIGNMENT_CENTER, 22, 8, Color("101416"))

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
