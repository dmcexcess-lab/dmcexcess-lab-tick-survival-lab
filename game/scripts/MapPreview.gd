extends Node2D

const MapGen = preload("res://scripts/TacticalMapGenerator.gd")
const TILE := 32.0
const TOP := 54.0

var rng := RandomNumberGenerator.new()
var environment_id := "back_alley"
var variant := 0
var spec: Dictionary = {}
var font: Font

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
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode in [KEY_SPACE, KEY_R, KEY_ENTER]:
            reroll()
            get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        reroll()
        get_viewport().set_input_as_handled()
    elif event is InputEventScreenTouch and event.pressed:
        reroll()
        get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 640, 630), Color("101416"))
    draw_string(font, Vector2(12, 24), "Tick Survival Lab — map bootstrap", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
    draw_string(font, Vector2(12, 45), "%s  |  variant %d  |  click / Space / R to reroll" % [MapGen.display_name(environment_id), variant], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("b8c4c2"))

    for y in range(MapGen.BOARD_H):
        for x in range(MapGen.BOARD_W):
            var p := Vector2i(x, y)
            var rect := Rect2(float(x) * TILE, TOP + float(y) * TILE, TILE, TILE)
            draw_rect(rect, MapGen.ground_color(MapGen.ground_at(spec, p)))
            draw_rect(rect, Color(1, 1, 1, 0.07), false, 1.0)

    var wall_color := MapGen.wall_color(environment_id)
    for p_value in spec.get("walls", []):
        var p: Vector2i = p_value
        draw_rect(_cell_rect(p), wall_color)

    for entry_value in spec.get("doors", []):
        var entry: Array = entry_value
        var p: Vector2i = entry[0]
        var opened := bool(entry[1])
        var color := Color("80664b") if not opened else Color("a58b6d")
        draw_rect(_cell_rect(p).grow(-5), color)

    for p_value in spec.get("glass", []):
        var p: Vector2i = p_value
        draw_rect(_cell_rect(p).grow(-6), Color("6fb9cf"))

    for p_value in spec.get("obstacles", []):
        var p: Vector2i = p_value
        draw_rect(_cell_rect(p).grow(-4), Color("33383a"))

    for p_value in spec.get("barrels", []):
        var p: Vector2i = p_value
        draw_circle(_cell_center(p), 8.0, Color("b94b38"))

    for entry_value in spec.get("props", []):
        var entry: Array = entry_value
        var p: Vector2i = entry[0]
        var label := str(entry[1])
        draw_string(font, _cell_center(p) + Vector2(-13, 5), label.left(3).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 26, 8, Color("e0d7ba"))

    var spawn: Vector2i = spec.get("player_spawn", Vector2i.ZERO)
    draw_circle(_cell_center(spawn), 9.0, Color("5fc78a"))
    draw_string(font, _cell_center(spawn) + Vector2(-11, 4), "YOU", HORIZONTAL_ALIGNMENT_CENTER, 22, 8, Color("101416"))

    for exit_value in spec.get("exit_cells", []):
        var exit_cell: Vector2i = exit_value
        var r := _cell_rect(exit_cell).grow(-4)
        draw_rect(r, Color("55d56e"), false, 3.0)

func _cell_rect(p: Vector2i) -> Rect2:
    return Rect2(float(p.x) * TILE, TOP + float(p.y) * TILE, TILE, TILE)

func _cell_center(p: Vector2i) -> Vector2:
    return Vector2((float(p.x) + 0.5) * TILE, TOP + (float(p.y) + 0.5) * TILE)
