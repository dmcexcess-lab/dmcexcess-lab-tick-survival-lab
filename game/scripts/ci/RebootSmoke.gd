extends SceneTree

const Generator = preload("res://scripts/reboot/RebootSiteGenerator.gd")
const Player = preload("res://scripts/reboot/RebootPlayer.gd")
const Art = preload("res://scripts/reboot/RebootArt.gd")

const TEST_SEEDS: Array[int] = [105832, 209771, 314159, 420691, 531117, 684209, 771331, 902417]

func _init() -> void:
    var seen_road_variants: Dictionary = {}

    for seed in TEST_SEEDS:
        var a: Dictionary = Generator.generate("rural_road", seed)
        var b: Dictionary = Generator.generate("rural_road", seed)
        var result: Dictionary = Generator.validate(a)
        if not bool(result.get("ok", false)):
            push_error("REBOOT_SMOKE_INVALID seed=%d %s" % [seed, str(result.get("failures", []))])
            quit(1)
            return

        seen_road_variants[str(a.get("road_variant", ""))] = true

        if a.get("ground") != b.get("ground") or a.get("walls") != b.get("walls") or a.get("doors") != b.get("doors") or a.get("door_axes") != b.get("door_axes") or a.get("door_clear") != b.get("door_clear") or a.get("windows") != b.get("windows") or a.get("props") != b.get("props") or a.get("rooms") != b.get("rooms") or a.get("buildings") != b.get("buildings") or a.get("properties") != b.get("properties") or a.get("fixture_tags") != b.get("fixture_tags") or a.get("road_cells") != b.get("road_cells") or a.get("side_road_cells") != b.get("side_road_cells") or a.get("road_y_by_x") != b.get("road_y_by_x") or a.get("road_variant") != b.get("road_variant") or a.get("crossroad_x") != b.get("crossroad_x") or a.get("power_links") != b.get("power_links") or a.get("spawn") != b.get("spawn"):
            push_error("REBOOT_SMOKE_NONDETERMINISTIC seed=%d" % seed)
            quit(1)
            return

        var properties: Array = a.get("properties", [])
        if properties.size() != 5:
            push_error("REBOOT_SMOKE_PROPERTY_COUNT seed=%d" % seed)
            quit(1)
            return
        var residences := 0
        var businesses := 0
        var farms := 0
        var manufactured := 0
        var commercial_property_id := ""
        for property_value in properties:
            var property: Dictionary = property_value
            var kind := str(property.get("kind", ""))
            if kind in Generator.RESIDENTIAL_KINDS:
                residences += 1
                if kind == "farmhouse":
                    farms += 1
                if kind in ["small_trailer", "double_wide"]:
                    manufactured += 1
            elif kind in Generator.COMMERCIAL_KINDS:
                businesses += 1
                commercial_property_id = str(property.get("id", ""))
        if residences != 4 or businesses != 1 or farms != 1 or manufactured < 1 or manufactured > 2:
            push_error("REBOOT_SMOKE_RURAL_MIX seed=%d" % seed)
            quit(1)
            return

        # Doors must now be openings in exactly one wall axis. A horizontal-wall
        # door has clear north/south approaches and structural neighbors left/right;
        # a vertical-wall door has the inverse. This catches partition-cross doors
        # that same-cell overlap checks missed.
        var doors: Dictionary = a.get("doors", {})
        var walls: Dictionary = a.get("walls", {})
        var windows: Dictionary = a.get("windows", {})
        var props: Dictionary = a.get("props", {})
        var door_axes: Dictionary = a.get("door_axes", {})
        for door_cell_value in doors.keys():
            var door_cell: Vector2i = door_cell_value
            if int(doors[door_cell]) != Art.S_DOOR_CLOSED:
                push_error("REBOOT_SMOKE_WRONG_DOOR_ART seed=%d" % seed)
                quit(1)
                return
            if walls.has(door_cell) or windows.has(door_cell):
                push_error("REBOOT_SMOKE_DOOR_CELL_OVERLAP seed=%d" % seed)
                quit(1)
                return
            var axis := str(door_axes.get(door_cell, ""))
            if axis not in ["h", "v"]:
                push_error("REBOOT_SMOKE_DOOR_AXIS seed=%d" % seed)
                quit(1)
                return
            var approach_a := door_cell + (Vector2i.UP if axis == "h" else Vector2i.LEFT)
            var approach_b := door_cell + (Vector2i.DOWN if axis == "h" else Vector2i.RIGHT)
            var wall_a := door_cell + (Vector2i.LEFT if axis == "h" else Vector2i.UP)
            var wall_b := door_cell + (Vector2i.RIGHT if axis == "h" else Vector2i.DOWN)
            if walls.has(approach_a) or windows.has(approach_a) or walls.has(approach_b) or windows.has(approach_b):
                push_error("REBOOT_SMOKE_DOOR_CROSSWALL seed=%d door=%s" % [seed, str(door_cell)])
                quit(1)
                return
            if props.has(approach_a) or props.has(approach_b):
                push_error("REBOOT_SMOKE_DOOR_CLUTTER seed=%d door=%s" % [seed, str(door_cell)])
                quit(1)
                return
            if not (walls.has(wall_a) or windows.has(wall_a)) or not (walls.has(wall_b) or windows.has(wall_b)):
                push_error("REBOOT_SMOKE_DOOR_NOT_IN_WALL seed=%d door=%s" % [seed, str(door_cell)])
                quit(1)
                return

        for wall_value in walls.values():
            var encoded := int(wall_value)
            if encoded / Art.ENCODE_SCALE != Art.SOURCE_TACTICAL:
                push_error("REBOOT_SMOKE_NONTACTICAL_WALL seed=%d" % seed)
                quit(1)
                return

        var saw_storefront := false
        var saw_stock := false
        var saw_office := false
        var saw_business_bath := false
        for room_value in a.get("rooms", []):
            var room: Dictionary = room_value
            var function_name := str(room.get("function", ""))
            var rect: Rect2i = room.get("rect", Rect2i())
            if rect.size.x < Generator.MIN_ROOM_SIDE or rect.size.y < Generator.MIN_ROOM_SIDE:
                push_error("REBOOT_SMOKE_ROOM_TOO_SMALL seed=%d room=%s size=%s" % [seed, function_name, str(rect.size)])
                quit(1)
                return
            if str(room.get("property_id", "")) == commercial_property_id:
                if function_name == "storefront":
                    saw_storefront = rect.size == Vector2i(7, 7)
                elif function_name == "stock_room":
                    saw_stock = rect.size == Vector2i(3, 3)
                elif function_name == "manager_office":
                    saw_office = rect.size == Vector2i(3, 3)
                elif function_name == "bathroom":
                    saw_business_bath = rect.size == Vector2i(3, 3)
        if not saw_storefront or not saw_stock or not saw_office or not saw_business_bath:
            push_error("REBOOT_SMOKE_BUSINESS_ROOM_SCALE seed=%d" % seed)
            quit(1)
            return

        if a.get("power_links", []).size() < 7:
            push_error("REBOOT_SMOKE_POWER_LINE_DENSITY seed=%d" % seed)
            quit(1)
            return

        var player = Player.new()
        player.reset(a["spawn"], 2)
        var before: Vector2i = player.cell
        player.turn_left()
        player.turn_right()
        if player.cell != before or player.facing != 2:
            push_error("REBOOT_SMOKE_ROTATION_MUTATED_POSITION seed=%d" % seed)
            quit(1)
            return

        var moved := false
        for facing in range(4):
            player.reset(a["spawn"], facing)
            if player.move_forward(a):
                moved = true
                break
        if not moved:
            push_error("REBOOT_SMOKE_SPAWN_TRAPPED seed=%d" % seed)
            quit(1)
            return

    if seen_road_variants.size() < 3:
        push_error("REBOOT_SMOKE_ROAD_VARIETY missing=%s" % str(seen_road_variants.keys()))
        quit(1)
        return

    print("REBOOT_CORE_SMOKE_OK")
    quit(0)
