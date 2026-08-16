extends Control
class_name RebootPrefabEditor

signal closed
signal library_changed

const Art = preload("res://scripts/reboot/RebootArt.gd")
const Library = preload("res://scripts/reboot/RebootPrefabLibrary.gd")

const VIEW_SIZE := Vector2(640, 844)
const CELL := 28
const GRID_W := Library.MAX_WIDTH
const GRID_H := Library.MAX_HEIGHT
const CANVAS := Rect2(12, 90, GRID_W * CELL, GRID_H * CELL)
const CLOSE_BUTTON := Rect2(520, 12, 104, 38)
const NAME_RECT := Rect2(14, 45, 444, 36)
const SAVE_BUTTON := Rect2(12, 500, 105, 44)
const LIBRARY_BUTTON := Rect2(125, 500, 105, 44)
const ERASE_BUTTON := Rect2(238, 500, 105, 44)
const CLEAR_BUTTON := Rect2(351, 500, 109, 44)
const NEW_BUTTON := Rect2(24, 92, 180, 48)
const PAGE_PREV := Rect2(470, 446, 74, 34)
const PAGE_NEXT := Rect2(554, 446, 74, 34)
const LIST_PREV := Rect2(184, 752, 110, 42)
const LIST_NEXT := Rect2(346, 752, 110, 42)
const LIST_ROWS_PER_PAGE := 5

const CATEGORY_GROUND := 0
const CATEGORY_STRUCTURE := 1
const CATEGORY_PROP := 2

const GROUND_TOOLS := [
    {"label":"WOOD", "kind":"ground", "tile":Art.G_WOOD},
    {"label":"CARPET", "kind":"ground", "tile":Art.G_CARPET},
    {"label":"TILE", "kind":"ground", "tile":Art.G_TILE},
    {"label":"LINO", "kind":"ground", "tile":Art.G_LINOLEUM},
    {"label":"CONCRETE", "kind":"ground", "tile":Art.G_CONCRETE},
    {"label":"GRASS", "kind":"ground", "tile":Art.G_GRASS},
    {"label":"DIRT", "kind":"ground", "tile":Art.G_DIRT},
]

const STRUCTURE_TOOLS := [
    {"label":"HOUSE WALL", "kind":"wall", "tile":Art.S_WALL_HOUSE},
    {"label":"LIGHT WALL", "kind":"wall", "tile":Art.S_WALL_LIGHT},
    {"label":"STORE WALL", "kind":"wall", "tile":Art.S_WALL_STORE},
    {"label":"INDUSTRIAL", "kind":"wall", "tile":Art.S_WALL_INDUSTRIAL},
    {"label":"WINDOW", "kind":"window", "tile":Art.S_WINDOW},
    {"label":"DOOR H", "kind":"door", "tile":Art.S_DOOR_CLOSED, "axis":"h"},
    {"label":"DOOR V", "kind":"door", "tile":Art.S_DOOR_CLOSED, "axis":"v"},
]

const PROP_PAGES := [
    [
        {"label":"SOFA", "kind":"prop", "tile":Art.P_SOFA, "blocks":true},
        {"label":"TABLE", "kind":"prop", "tile":Art.P_TABLE, "blocks":true},
        {"label":"BED", "kind":"prop", "tile":Art.P_BED, "blocks":true},
        {"label":"FRIDGE", "kind":"prop", "tile":Art.P_FRIDGE, "blocks":true},
        {"label":"STOVE", "kind":"prop", "tile":Art.P_STOVE, "blocks":true},
        {"label":"COUNTER", "kind":"prop", "tile":Art.P_COUNTER, "blocks":true},
        {"label":"SHELF", "kind":"prop", "tile":Art.P_STORE_SHELF, "blocks":true},
    ],
    [
        {"label":"TOILET", "kind":"prop", "tile":Art.P_TOILET, "blocks":true},
        {"label":"SINK", "kind":"prop", "tile":Art.P_SINK, "blocks":true},
        {"label":"BATHTUB", "kind":"prop", "tile":Art.P_BATHTUB, "blocks":true},
        {"label":"SHOWER", "kind":"prop", "tile":Art.P_SHOWER, "blocks":true},
        {"label":"DESK", "kind":"prop", "tile":Art.P_DESK, "blocks":true},
        {"label":"CHAIR", "kind":"prop", "tile":Art.P_CHAIR, "blocks":true},
        {"label":"CABINET", "kind":"prop", "tile":Art.P_CABINET, "blocks":true},
    ],
    [
        {"label":"BOOKSHELF", "kind":"prop", "tile":Art.P_BOOKSHELF, "blocks":true},
        {"label":"TV", "kind":"prop", "tile":Art.P_TV, "blocks":true},
        {"label":"WASHER", "kind":"prop", "tile":Art.P_WASHER, "blocks":true},
        {"label":"CRATE", "kind":"prop", "tile":Art.P_CRATE, "blocks":true},
        {"label":"PALLET", "kind":"prop", "tile":Art.P_PALLET, "blocks":true},
        {"label":"FIREWOOD", "kind":"prop", "tile":Art.P_FIREWOOD, "blocks":true},
        {"label":"PROPANE", "kind":"prop", "tile":Art.P_PROPANE_TANK, "blocks":true},
    ],
]

var font: Font
var name_edit: LineEdit
var mode := "list"
var current: Dictionary = {}
var library: Array = []
var category := CATEGORY_GROUND
var tool_index := 0
var prop_page := 0
var list_page := 0
var status_text := ""
var status_bad := false
var erase_mode := false
var clear_armed := false
var delete_armed_name := ""
var last_touch_msec := -10000

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    position = Vector2.ZERO
    size = VIEW_SIZE
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    font = ThemeDB.fallback_font
    name_edit = LineEdit.new()
    name_edit.position = NAME_RECT.position
    name_edit.size = NAME_RECT.size
    name_edit.placeholder_text = "Prefab name"
    name_edit.max_length = 32
    name_edit.add_theme_font_size_override("font_size", 18)
    name_edit.visible = false
    add_child(name_edit)
    library = Library.load_all()
    current = Library.empty_prefab()
    set_process(false)
    queue_redraw()

func open_library() -> void:
    library = Library.load_all()
    mode = "list"
    list_page = 0
    status_text = "Saved locally in this browser/device."
    status_bad = false
    delete_armed_name = ""
    name_edit.visible = false
    visible = true
    queue_redraw()

func _draw() -> void:
    if not visible:
        return
    draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("0d1115"), true)
    draw_rect(Rect2(8, 8, 624, 816), Color("171d22"), true)
    draw_rect(Rect2(8, 8, 624, 816), Color("616a72"), false, 2.0)
    _draw_label(Vector2(20, 36), "PREFAB WORKSHOP", 24, Color.WHITE)
    _draw_button(CLOSE_BUTTON, "CLOSE", false, false)
    if mode == "edit":
        _draw_editor()
    else:
        _draw_library()

func _draw_editor() -> void:
    _draw_label(Vector2(476, 72), "16 x 14 MAX", 12, Color("aeb6bd"))
    draw_rect(CANVAS, Color("090c0f"), true)
    var ground: Dictionary = current.get("ground", {})
    var walls: Dictionary = current.get("walls", {})
    var doors: Dictionary = current.get("doors", {})
    var windows: Dictionary = current.get("windows", {})
    var props: Dictionary = current.get("props", {})
    for y in range(GRID_H):
        for x in range(GRID_W):
            var cell := Vector2i(x, y)
            var dest := Rect2(CANVAS.position + Vector2(x * CELL, y * CELL), Vector2(CELL, CELL))
            if ground.has(cell):
                Art.draw_encoded(self, int(ground[cell]), dest)
            else:
                var checker := Color("151b20") if (x + y) % 2 == 0 else Color("11161b")
                draw_rect(dest, checker, true)
            if walls.has(cell):
                Art.draw_encoded(self, int(walls[cell]), dest)
            elif windows.has(cell):
                Art.draw_encoded(self, int(windows[cell]), dest)
            elif doors.has(cell):
                Art.draw_encoded(self, int(doors[cell]), dest)
            if props.has(cell):
                Art.draw_encoded(self, int(props[cell]), dest)
    for x in range(GRID_W + 1):
        var px := CANVAS.position.x + x * CELL
        draw_line(Vector2(px, CANVAS.position.y), Vector2(px, CANVAS.end.y), Color(1, 1, 1, 0.10), 1.0)
    for y in range(GRID_H + 1):
        var py := CANVAS.position.y + y * CELL
        draw_line(Vector2(CANVAS.position.x, py), Vector2(CANVAS.end.x, py), Color(1, 1, 1, 0.10), 1.0)
    draw_rect(CANVAS, Color("bcc4ca"), false, 2.0)

    _draw_category_button(Rect2(470, 90, 50, 34), "FLOOR", CATEGORY_GROUND)
    _draw_category_button(Rect2(524, 90, 50, 34), "BUILD", CATEGORY_STRUCTURE)
    _draw_category_button(Rect2(578, 90, 50, 34), "PROP", CATEGORY_PROP)
    var tools := _current_tools()
    for i in range(tools.size()):
        var rect := _tool_rect(i)
        var tool: Dictionary = tools[i]
        _draw_button(rect, str(tool.get("label", "?")), false, not erase_mode and i == tool_index)
    if category == CATEGORY_PROP:
        _draw_button(PAGE_PREV, "<", prop_page <= 0, false)
        _draw_button(PAGE_NEXT, ">", prop_page >= PROP_PAGES.size() - 1, false)
        _draw_label(Vector2(524, 438), "%d/%d" % [prop_page + 1, PROP_PAGES.size()], 11, Color("adb5bc"))

    _draw_button(SAVE_BUTTON, "SAVE", false, false)
    _draw_button(LIBRARY_BUTTON, "LIBRARY", false, false)
    _draw_button(ERASE_BUTTON, "ERASE", false, erase_mode)
    _draw_button(CLEAR_BUTTON, "CLEAR", false, clear_armed)
    _draw_label(Vector2(14, 568), status_text, 14, Color("ff9f8c") if status_bad else Color("b9d7b5"))
    _draw_label(Vector2(14, 594), "Door H = opening in a horizontal wall (clear N/S).", 13, Color("b7bec5"))
    _draw_label(Vector2(14, 614), "Door V = opening in a vertical wall (clear E/W).", 13, Color("b7bec5"))
    _draw_label(Vector2(14, 642), "SAVE trims empty margins. The random generator may insert one", 13, Color("919ba4"))
    _draw_label(Vector2(14, 662), "saved prefab into a later rural map when a safe footprint exists.", 13, Color("919ba4"))
    _draw_label(Vector2(14, 696), "Paint by tapping/clicking or dragging across the grid.", 13, Color("c9ced3"))
    _draw_label(Vector2(14, 716), "Walls/windows/props cannot be painted into a door approach.", 13, Color("c9ced3"))
    _draw_label(Vector2(14, 746), "ESC: library    F2: close workshop", 13, Color("818b94"))

func _draw_library() -> void:
    _draw_label(Vector2(24, 72), "AUTHORED PREFABS", 18, Color.WHITE)
    _draw_button(NEW_BUTTON, "NEW PREFAB", false, false)
    _draw_label(Vector2(222, 116), "%d saved" % library.size(), 14, Color("b9c1c8"))
    var total_pages := maxi(1, int(ceil(float(library.size()) / float(LIST_ROWS_PER_PAGE))))
    list_page = clampi(list_page, 0, total_pages - 1)
    var start := list_page * LIST_ROWS_PER_PAGE
    for row in range(LIST_ROWS_PER_PAGE):
        var index := start + row
        if index >= library.size():
            break
        var prefab: Dictionary = library[index]
        var y := 170.0 + row * 104.0
        var row_rect := Rect2(24, y, 592, 88)
        draw_rect(row_rect, Color("222a30"), true)
        draw_rect(row_rect, Color("4a555e"), false, 1.0)
        var name_value := str(prefab.get("name", "Prefab"))
        _draw_label(Vector2(38, y + 30), name_value, 18, Color.WHITE)
        _draw_label(Vector2(38, y + 55), "%dx%d cells" % [int(prefab.get("width", 1)), int(prefab.get("height", 1))], 13, Color("aeb7be"))
        _draw_button(_list_load_rect(row), "LOAD", false, false)
        _draw_button(_list_delete_rect(row), "DELETE", false, delete_armed_name == name_value)
    _draw_button(LIST_PREV, "PREV", list_page <= 0, false)
    _draw_button(LIST_NEXT, "NEXT", list_page >= total_pages - 1, false)
    _draw_label(Vector2(301, 780), "%d / %d" % [list_page + 1, total_pages], 13, Color("aab2b9"))
    _draw_label(Vector2(24, 814), status_text, 12, Color("ff9f8c") if status_bad else Color("b9d7b5"))

func _draw_category_button(rect: Rect2, text: String, wanted: int) -> void:
    _draw_button(rect, text, false, category == wanted)

func _draw_button(rect: Rect2, text: String, disabled: bool, selected: bool) -> void:
    var fill := Color("404a52")
    var border := Color("8f9aa3")
    var text_color := Color.WHITE
    if selected:
        fill = Color("665b35")
        border = Color("e2ce73")
    if disabled:
        fill = Color("252b30")
        border = Color("4d555b")
        text_color = Color("717980")
    draw_rect(rect, fill, true)
    draw_rect(rect, border, false, 1.5)
    var size_value := 13 if text.length() > 8 else 15
    var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_value)
    var pos := rect.position + Vector2((rect.size.x - text_size.x) * 0.5, (rect.size.y + text_size.y * 0.55) * 0.5)
    draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_value, text_color)

func _draw_label(pos: Vector2, text: String, size_value: int, color: Color) -> void:
    draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_value, color)

func _tool_rect(index: int) -> Rect2:
    return Rect2(470, 132 + index * 43, 158, 37)

func _list_load_rect(row: int) -> Rect2:
    return Rect2(430, 181 + row * 104, 78, 36)

func _list_delete_rect(row: int) -> Rect2:
    return Rect2(518, 181 + row * 104, 88, 36)

func _current_tools() -> Array:
    if category == CATEGORY_STRUCTURE:
        return STRUCTURE_TOOLS
    if category == CATEGORY_PROP:
        return PROP_PAGES[prop_page]
    return GROUND_TOOLS

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            last_touch_msec = Time.get_ticks_msec()
            _handle_pointer(touch.position)
            get_viewport().set_input_as_handled()
        return
    if event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if mode == "edit" and CANVAS.has_point(drag.position):
            _paint_pointer(drag.position)
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
    if event is InputEventMouseMotion:
        var motion := event as InputEventMouseMotion
        if mode == "edit" and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 and CANVAS.has_point(motion.position):
            _paint_pointer(motion.position)
            get_viewport().set_input_as_handled()
        return
    if event is InputEventKey:
        var key := event as InputEventKey
        if not key.pressed or key.echo:
            return
        if key.keycode == KEY_F2:
            _close_workshop()
            get_viewport().set_input_as_handled()
        elif key.keycode == KEY_ESCAPE:
            if mode == "edit":
                _show_library()
            else:
                _close_workshop()
            get_viewport().set_input_as_handled()

func _handle_pointer(pos: Vector2) -> void:
    if CLOSE_BUTTON.has_point(pos):
        _close_workshop()
        return
    if mode == "list":
        _handle_library_pointer(pos)
        return
    if CANVAS.has_point(pos):
        _paint_pointer(pos)
        return
    if SAVE_BUTTON.has_point(pos):
        _save_current()
        return
    if LIBRARY_BUTTON.has_point(pos):
        _show_library()
        return
    if ERASE_BUTTON.has_point(pos):
        erase_mode = not erase_mode
        clear_armed = false
        status_text = "Erase tool on." if erase_mode else "Erase tool off."
        status_bad = false
        queue_redraw()
        return
    if CLEAR_BUTTON.has_point(pos):
        if clear_armed:
            var keep_name := name_edit.text
            current = Library.empty_prefab(keep_name)
            clear_armed = false
            status_text = "Canvas cleared."
            status_bad = false
        else:
            clear_armed = true
            status_text = "Tap CLEAR again to erase the whole canvas."
            status_bad = true
        queue_redraw()
        return
    if Rect2(470, 90, 50, 34).has_point(pos):
        _set_category(CATEGORY_GROUND)
        return
    if Rect2(524, 90, 50, 34).has_point(pos):
        _set_category(CATEGORY_STRUCTURE)
        return
    if Rect2(578, 90, 50, 34).has_point(pos):
        _set_category(CATEGORY_PROP)
        return
    var tools := _current_tools()
    for i in range(tools.size()):
        if _tool_rect(i).has_point(pos):
            tool_index = i
            erase_mode = false
            clear_armed = false
            status_text = "Tool: %s" % str(tools[i].get("label", "?"))
            status_bad = false
            queue_redraw()
            return
    if category == CATEGORY_PROP and PAGE_PREV.has_point(pos) and prop_page > 0:
        prop_page -= 1
        tool_index = 0
        queue_redraw()
        return
    if category == CATEGORY_PROP and PAGE_NEXT.has_point(pos) and prop_page < PROP_PAGES.size() - 1:
        prop_page += 1
        tool_index = 0
        queue_redraw()

func _handle_library_pointer(pos: Vector2) -> void:
    if NEW_BUTTON.has_point(pos):
        current = Library.empty_prefab("New Prefab")
        _enter_edit()
        return
    var start := list_page * LIST_ROWS_PER_PAGE
    for row in range(LIST_ROWS_PER_PAGE):
        var index := start + row
        if index >= library.size():
            break
        var prefab: Dictionary = library[index]
        var name_value := str(prefab.get("name", "Prefab"))
        if _list_load_rect(row).has_point(pos):
            current = Library.editor_copy(prefab)
            _enter_edit()
            return
        if _list_delete_rect(row).has_point(pos):
            if delete_armed_name == name_value:
                if Library.delete_prefab(name_value):
                    library = Library.load_all()
                    library_changed.emit()
                    status_text = "Deleted %s." % name_value
                    status_bad = false
                else:
                    status_text = "Could not delete %s." % name_value
                    status_bad = true
                delete_armed_name = ""
            else:
                delete_armed_name = name_value
                status_text = "Tap DELETE again to remove %s." % name_value
                status_bad = true
            queue_redraw()
            return
    var total_pages := maxi(1, int(ceil(float(library.size()) / float(LIST_ROWS_PER_PAGE))))
    if LIST_PREV.has_point(pos) and list_page > 0:
        list_page -= 1
        delete_armed_name = ""
        queue_redraw()
    elif LIST_NEXT.has_point(pos) and list_page < total_pages - 1:
        list_page += 1
        delete_armed_name = ""
        queue_redraw()

func _paint_pointer(pos: Vector2) -> void:
    var local := pos - CANVAS.position
    var cell := Vector2i(clampi(int(local.x / CELL), 0, GRID_W - 1), clampi(int(local.y / CELL), 0, GRID_H - 1))
    _paint_cell(cell)

func _paint_cell(cell: Vector2i) -> void:
    clear_armed = false
    if erase_mode:
        _erase_cell(cell)
        status_text = "Erased %d,%d" % [cell.x, cell.y]
        status_bad = false
        queue_redraw()
        return
    var tools := _current_tools()
    if tool_index < 0 or tool_index >= tools.size():
        return
    var tool: Dictionary = tools[tool_index]
    var kind := str(tool.get("kind", ""))
    match kind:
        "ground":
            current["ground"][cell] = int(tool["tile"])
        "wall":
            if Library.cell_reserved_by_door(current, cell):
                _paint_refused("Door clearance owns that cell.")
                return
            _clear_non_ground(cell)
            current["walls"][cell] = int(tool["tile"])
        "window":
            if Library.cell_reserved_by_door(current, cell):
                _paint_refused("Door clearance owns that cell.")
                return
            _clear_non_ground(cell)
            current["windows"][cell] = int(tool["tile"])
        "door":
            _place_door(cell, str(tool.get("axis", "h")))
        "prop":
            if Library.cell_reserved_by_door(current, cell):
                _paint_refused("Door clearance owns that cell.")
                return
            if current["walls"].has(cell) or current["windows"].has(cell) or current["doors"].has(cell):
                _paint_refused("Erase the structure before placing a prop.")
                return
            current["props"][cell] = int(tool["tile"])
            current["prop_blocks"][cell] = bool(tool.get("blocks", true))
    status_text = "%s at %d,%d" % [str(tool.get("label", "Paint")), cell.x, cell.y]
    status_bad = false
    queue_redraw()

func _place_door(cell: Vector2i, axis: String) -> void:
    _clear_non_ground(cell)
    current["doors"][cell] = Art.S_DOOR_CLOSED
    current["door_axes"][cell] = axis
    var approaches: Array[Vector2i] = [
        cell + (Vector2i.UP if axis == "h" else Vector2i.LEFT),
        cell + (Vector2i.DOWN if axis == "h" else Vector2i.RIGHT),
    ]
    for approach in approaches:
        if approach.x < 0 or approach.y < 0 or approach.x >= GRID_W or approach.y >= GRID_H:
            continue
        _clear_non_ground(approach)
    status_text = "Door %s placed. SAVE requires wall/window neighbors along its wall axis." % axis.to_upper()
    status_bad = false

func _clear_non_ground(cell: Vector2i) -> void:
    current["walls"].erase(cell)
    current["windows"].erase(cell)
    current["doors"].erase(cell)
    current["door_axes"].erase(cell)
    current["props"].erase(cell)
    current["prop_blocks"].erase(cell)

func _erase_cell(cell: Vector2i) -> void:
    current["ground"].erase(cell)
    _clear_non_ground(cell)

func _paint_refused(message: String) -> void:
    status_text = message
    status_bad = true
    queue_redraw()

func _save_current() -> void:
    current["name"] = Library.sanitize_name(name_edit.text)
    name_edit.text = str(current["name"])
    var result: Dictionary = Library.save_prefab(current)
    status_text = str(result.get("message", "Save failed."))
    status_bad = not bool(result.get("ok", false))
    if bool(result.get("ok", false)):
        var saved: Dictionary = result.get("prefab", {})
        current = Library.editor_copy(saved)
        library = Library.load_all()
        library_changed.emit()
    queue_redraw()

func _set_category(value: int) -> void:
    category = value
    tool_index = 0
    erase_mode = false
    clear_armed = false
    status_text = ""
    status_bad = false
    queue_redraw()

func _enter_edit() -> void:
    mode = "edit"
    category = CATEGORY_GROUND
    tool_index = 0
    prop_page = 0
    erase_mode = false
    clear_armed = false
    delete_armed_name = ""
    status_text = "Paint a prefab, then SAVE."
    status_bad = false
    name_edit.text = str(current.get("name", "Prefab"))
    name_edit.visible = true
    name_edit.release_focus()
    queue_redraw()

func _show_library() -> void:
    library = Library.load_all()
    mode = "list"
    list_page = 0
    delete_armed_name = ""
    name_edit.visible = false
    status_text = "Saved locally in this browser/device."
    status_bad = false
    queue_redraw()

func _close_workshop() -> void:
    name_edit.release_focus()
    name_edit.visible = false
    visible = false
    closed.emit()
