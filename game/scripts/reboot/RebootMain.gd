extends Node2D
class_name RebootMain

const Art = preload("res://scripts/reboot/RebootArt.gd")
const Generator = preload("res://scripts/reboot/RebootSiteGenerator.gd")
const Player = preload("res://scripts/reboot/RebootPlayer.gd")

const VIEW_SIZE := Vector2(640, 844)
const BOARD := Rect2(8, 58, 624, 548)
const ZOOM_SIZES: Array[int] = [38, 44, 52]
const DEFAULT_ZOOM := 1

const MAP_BUTTON := Rect2(516, 10, 112, 38)
const ZOOM_OUT_BUTTON := Rect2(422, 10, 42, 38)
const ZOOM_IN_BUTTON := Rect2(468, 10, 42, 38)
const TURN_LEFT_BUTTON := Rect2(18, 690, 154, 62)
const FORWARD_BUTTON := Rect2(468, 620, 154, 62)
const TURN_RIGHT_BUTTON := Rect2(468, 690, 154, 62)
const BACK_BUTTON := Rect2(468, 760, 154, 62)

const MAP_NODES := [
    {"id":"farmstead", "label":"FARMSTEAD", "pos":Vector2(146, 260), "seed":1103},
    {"id":"small_trailer", "label":"TRAILER", "pos":Vector2(176, 390), "seed":2207},
    {"id":"double_wide", "label":"DOUBLE-WIDE", "pos":Vector2(144, 520), "seed":3313},
    {"id":"country_house", "label":"COUNTRY HOUSE", "pos":Vector2(194, 650), "seed":4421},
]

var player = Player.new()
var spec: Dictionary = {}
var map_open := true
var zoom_index := DEFAULT_ZOOM
var active_site := ""
var visit_counts: Dictionary = {}
var last_touch_msec := -10000
var font: Font

func _ready() -> void:
    set_process(false)
    font = ThemeDB.fallback_font
    queue_redraw()
    print("REBOOT_BOOT_OK")

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("11151a"), true)
    if map_open:
        _draw_strategic_map()
    else:
        _draw_tactical()

func _draw_tactical() -> void:
    if spec.is_empty():
        _draw_label(Vector2(30, 90), "NO SITE LOADED - OPEN MAP", 20, Color.WHITE)
        _draw_top_buttons()
        return

    draw_rect(BOARD, Color("080b0e"), true)
    var tile := ZOOM_SIZES[zoom_index]
    var cols := maxi(1, int(floor(BOARD.size.x / float(tile))))
    var rows := maxi(1, int(floor(BOARD.size.y / float(tile))))
    var width := int(spec["width"])
    var height := int(spec["height"])
    var start_x := clampi(player.cell.x - cols / 2, 0, maxi(0, width - cols))
    var start_y := clampi(player.cell.y - rows / 2, 0, maxi(0, height - rows))
    var drawn_w := cols * tile
    var drawn_h := rows * tile
    var origin := Vector2(BOARD.position.x + (BOARD.size.x - drawn_w) * 0.5, BOARD.position.y + (BOARD.size.y - drawn_h) * 0.5)
    var ground: PackedInt32Array = spec["ground"]
    var walls: Dictionary = spec["walls"]
    var doors: Dictionary = spec["doors"]
    var windows: Dictionary = spec["windows"]
    var props: Dictionary = spec["props"]

    for sy in range(rows):
        var world_y := start_y + sy
        if world_y >= height:
            break
        for sx in range(cols):
            var world_x := start_x + sx
            if world_x >= width:
                break
            var p := Vector2i(world_x, world_y)
            var dest := Rect2(origin + Vector2(sx * tile, sy * tile), Vector2(tile, tile))
            var ground_index := int(ground[world_y * width + world_x])
            _draw_surface(ground_index, dest)
            if walls.has(p):
                _draw_surface(int(walls[p]), dest)
            elif windows.has(p):
                _draw_surface(int(windows[p]), dest)
            elif doors.has(p):
                _draw_surface(int(doors[p]), dest)
            if props.has(p):
                _draw_prop(int(props[p]), dest)

    var px: int = player.cell.x - start_x
    var py: int = player.cell.y - start_y
    if px >= 0 and py >= 0 and px < cols and py < rows:
        var player_dest := Rect2(origin + Vector2(px * tile, py * tile), Vector2(tile, tile))
        draw_texture_rect(Art.player_texture(player.facing), player_dest, false)

    draw_rect(Rect2(origin, Vector2(drawn_w, drawn_h)), Color("d6d6d6"), false, 2.0)
    _draw_label(Vector2(14, 24), "%s  |  %s  |  %d,%d" % [str(spec.get("title", "SITE")), _facing_name(), player.cell.x, player.cell.y], 16, Color.WHITE)
    _draw_top_buttons()
    _draw_control_buttons()
    _draw_label(Vector2(190, 722), "W/UP forward   S/DOWN back", 14, Color("c7cbd0"))
    _draw_label(Vector2(190, 744), "A/D or LEFT/RIGHT turn", 14, Color("c7cbd0"))
    _draw_label(Vector2(190, 775), "Event-driven renderer: no idle redraw", 13, Color("8d949c"))

func _draw_strategic_map() -> void:
    draw_rect(Rect2(18, 62, 604, 742), Color("171d22"), true)
    _draw_label(Vector2(34, 92), "OUTSKIRTS -> CITY", 27, Color.WHITE)
    _draw_label(Vector2(34, 120), "Walking range: rural edge. Vehicles will unlock deeper bands later.", 14, Color("c7cbd0"))

    var rural := Rect2(52, 154, 182, 590)
    var town := Rect2(234, 154, 116, 590)
    var suburbs := Rect2(350, 154, 112, 590)
    var city_edge := Rect2(462, 154, 76, 590)
    var core := Rect2(538, 154, 60, 590)
    draw_rect(rural, Color("29432d"), true)
    draw_rect(town, Color("4a3d2f"), true)
    draw_rect(suburbs, Color("3b4146"), true)
    draw_rect(city_edge, Color("30343a"), true)
    draw_rect(core, Color("22262b"), true)
    _draw_label(Vector2(74, 178), "RURAL EDGE", 17, Color("dfeadf"))
    _draw_vertical_label(Vector2(261, 196), "SMALL TOWN", Color("d3cbc0"))
    _draw_vertical_label(Vector2(381, 196), "SUBURBS", Color("d0d4d8"))
    _draw_vertical_label(Vector2(480, 196), "CITY EDGE", Color("c3c8ce"))
    _draw_vertical_label(Vector2(552, 196), "CORE", Color("b8bec5"))

    var base_pos := Vector2(78, 448)
    draw_circle(base_pos, 12.0, Color("e33b3b"))
    _draw_label(base_pos + Vector2(18, 5), "BASE", 15, Color.WHITE)

    for node_value in MAP_NODES:
        var node: Dictionary = node_value
        var pos: Vector2 = node["pos"]
        draw_line(base_pos, pos, Color("617367"), 2.0)
        var selected := str(node["id"]) == active_site
        draw_circle(pos, 14.0, Color("f3df83") if not selected else Color("ff6b54"))
        draw_circle(pos, 7.0, Color("3a3824") if not selected else Color("61231c"))
        _draw_label(pos + Vector2(18, 5), str(node["label"]), 14, Color.WHITE)
        var visits := int(visit_counts.get(str(node["id"]), 0))
        if visits > 0:
            _draw_label(pos + Vector2(18, 22), "generated %dx" % visits, 11, Color("bec5bd"))

    _draw_locked_node(Vector2(290, 315), "MAIN STREET")
    _draw_locked_node(Vector2(302, 555), "SMALL TOWN")
    _draw_locked_node(Vector2(407, 390), "SUBURBS")
    _draw_locked_node(Vector2(493, 300), "OFFICES")
    _draw_locked_node(Vector2(493, 545), "WAREHOUSES")
    _draw_locked_node(Vector2(564, 425), "CITY CENTER")

    _draw_label(Vector2(68, 775), "Tap a rural site to generate it. Tap it again later for a new seed.", 14, Color("d4dad2"))
    if not active_site.is_empty():
        _draw_button(MAP_BUTTON, "CLOSE MAP", false)

func _draw_locked_node(pos: Vector2, label: String) -> void:
    draw_circle(pos, 11.0, Color("61666b"))
    draw_circle(pos, 5.0, Color("282c30"))
    _draw_label(pos + Vector2(15, 4), label, 11, Color("858b91"))
    _draw_label(pos + Vector2(15, 17), "vehicle", 9, Color("6e7479"))

func _draw_top_buttons() -> void:
    _draw_button(ZOOM_OUT_BUTTON, "-", zoom_index <= 0)
    _draw_button(ZOOM_IN_BUTTON, "+", zoom_index >= ZOOM_SIZES.size() - 1)
    _draw_button(MAP_BUTTON, "MAP", false)

func _draw_control_buttons() -> void:
    _draw_button(TURN_LEFT_BUTTON, "TURN L", false)
    _draw_button(FORWARD_BUTTON, "FORWARD", false)
    _draw_button(TURN_RIGHT_BUTTON, "TURN R", false)
    _draw_button(BACK_BUTTON, "BACK", false)

func _draw_button(rect: Rect2, text: String, disabled: bool) -> void:
    var fill := Color("343b42") if not disabled else Color("24292e")
    var border := Color("9ba5ae") if not disabled else Color("555d64")
    var text_color := Color.WHITE if not disabled else Color("737b82")
    draw_rect(rect, fill, true)
    draw_rect(rect, border, false, 2.0)
    var size := 15 if text.length() > 4 else 22
    var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
    var pos := rect.position + Vector2((rect.size.x - text_size.x) * 0.5, (rect.size.y + text_size.y * 0.5) * 0.5)
    draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, text_color)

func _draw_surface(index: int, dest: Rect2) -> void:
    draw_texture_rect_region(Art.SURFACES, dest, Art.atlas_region(index))

func _draw_prop(index: int, dest: Rect2) -> void:
    draw_texture_rect_region(Art.PROPS, dest, Art.atlas_region(index))

func _draw_label(pos: Vector2, text: String, size: int, color: Color) -> void:
    draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw_vertical_label(pos: Vector2, text: String, color: Color) -> void:
    _draw_label(pos, text, 11, color)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            last_touch_msec = Time.get_ticks_msec()
            _handle_pointer(touch.position)
            get_viewport().set_input_as_handled()
        return
    if event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
            if Time.get_ticks_msec() - last_touch_msec < 650:
                return
            _handle_pointer(mouse.position)
            get_viewport().set_input_as_handled()
        return
    if event is InputEventKey:
        var key := event as InputEventKey
        if not key.pressed or key.echo:
            return
        _handle_key(key.keycode)

func _handle_key(keycode: Key) -> void:
    if keycode == KEY_M:
        _toggle_map()
        return
    if map_open or spec.is_empty():
        return
    match keycode:
        KEY_W, KEY_UP:
            player.move_forward(spec)
        KEY_S, KEY_DOWN:
            player.move_backward(spec)
        KEY_A, KEY_LEFT:
            player.turn_left()
        KEY_D, KEY_RIGHT:
            player.turn_right()
        KEY_MINUS, KEY_KP_SUBTRACT:
            _zoom(-1)
            return
        KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
            _zoom(1)
            return
        _:
            return
    queue_redraw()

func _handle_pointer(pos: Vector2) -> void:
    if map_open:
        if not active_site.is_empty() and MAP_BUTTON.has_point(pos):
            map_open = false
            queue_redraw()
            return
        for node_value in MAP_NODES:
            var node: Dictionary = node_value
            var node_pos: Vector2 = node["pos"]
            if node_pos.distance_to(pos) <= 28.0:
                _load_site(str(node["id"]), int(node["seed"]))
                return
        return

    if MAP_BUTTON.has_point(pos):
        _toggle_map()
    elif ZOOM_OUT_BUTTON.has_point(pos):
        _zoom(-1)
    elif ZOOM_IN_BUTTON.has_point(pos):
        _zoom(1)
    elif TURN_LEFT_BUTTON.has_point(pos):
        player.turn_left()
        queue_redraw()
    elif TURN_RIGHT_BUTTON.has_point(pos):
        player.turn_right()
        queue_redraw()
    elif FORWARD_BUTTON.has_point(pos):
        player.move_forward(spec)
        queue_redraw()
    elif BACK_BUTTON.has_point(pos):
        player.move_backward(spec)
        queue_redraw()

func _load_site(archetype: String, seed_base: int) -> void:
    var visit := int(visit_counts.get(archetype, 0)) + 1
    visit_counts[archetype] = visit
    var seed := seed_base + visit * 104729
    spec = Generator.generate(archetype, seed)
    var validation: Dictionary = Generator.validate(spec)
    if not bool(validation.get("ok", false)):
        push_error("REBOOT_SITE_INVALID %s" % str(validation.get("failures", [])))
    player.reset(spec["spawn"], 2)
    active_site = archetype
    map_open = false
    queue_redraw()

func _toggle_map() -> void:
    if active_site.is_empty() and map_open:
        return
    map_open = not map_open
    queue_redraw()

func _zoom(delta: int) -> void:
    zoom_index = clampi(zoom_index + delta, 0, ZOOM_SIZES.size() - 1)
    queue_redraw()

func _facing_name() -> String:
    match player.facing:
        0: return "N"
        1: return "E"
        2: return "S"
        _: return "W"
