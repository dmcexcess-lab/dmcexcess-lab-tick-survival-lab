extends SceneTree

const Generator = preload("res://scripts/reboot/RebootSiteGenerator.gd")
const Player = preload("res://scripts/reboot/RebootPlayer.gd")
const Art = preload("res://scripts/reboot/RebootArt.gd")

const TEST_SEEDS: Array[int] = [105832, 209771, 314159, 420691, 531117, 684209, 771331, 902417]

func _init() -> void:
    for seed in TEST_SEEDS:
        var a: Dictionary = Generator.generate("rural_road", seed)
        var b: Dictionary = Generator.generate("rural_road", seed)
        var result: Dictionary = Generator.validate(a)
        if not bool(result.get("ok", false)):
            push_error("REBOOT_SMOKE_INVALID seed=%d %s" % [seed, str(result.get("failures", []))])
            quit(1)
            return

        if a.get("ground") != b.get("ground") or a.get("walls") != b.get("walls") or a.get("doors") != b.get("doors") or a.get("windows") != b.get("windows") or a.get("props") != b.get("props") or a.get("rooms") != b.get("rooms") or a.get("buildings") != b.get("buildings") or a.get("properties") != b.get("properties") or a.get("fixture_tags") != b.get("fixture_tags") or a.get("road_cells") != b.get("road_cells") or a.get("side_road_cells") != b.get("side_road_cells") or a.get("power_links") != b.get("power_links") or a.get("spawn") != b.get("spawn"):
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
        if residences != 4 or businesses != 1 or farms != 1 or manufactured < 1 or manufactured > 2:
            push_error("REBOOT_SMOKE_RURAL_MIX seed=%d" % seed)
            quit(1)
            return

        # Structural look must be the exact early TacticalTiles vocabulary. In
        # particular, door 23 is transparent around the door rather than containing
        # the later world-art wall-colour backing.
        var doors: Dictionary = a.get("doors", {})
        var walls: Dictionary = a.get("walls", {})
        for door_cell_value in doors.keys():
            var door_cell: Vector2i = door_cell_value
            if int(doors[door_cell]) != Art.S_DOOR_CLOSED:
                push_error("REBOOT_SMOKE_WRONG_DOOR_ART seed=%d" % seed)
                quit(1)
                return
            if walls.has(door_cell):
                push_error("REBOOT_SMOKE_DOOR_WALL_OVERLAP seed=%d" % seed)
                quit(1)
                return
            var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
            for delta in directions:
                if a.get("props", {}).has(door_cell + delta):
                    push_error("REBOOT_SMOKE_DOOR_CLUTTER seed=%d" % seed)
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
            if function_name == "storefront":
                saw_storefront = rect.size == Vector2i(7, 7)
            elif function_name == "stock_room":
                saw_stock = rect.size == Vector2i(3, 3)
            elif function_name == "manager_office":
                saw_office = rect.size == Vector2i(3, 1)
            elif function_name == "bathroom" and str(room.get("property_id", "")).begins_with("north_"):
                if rect.size == Vector2i(2, 2):
                    saw_business_bath = true
        if not saw_storefront or not saw_stock or not saw_office:
            push_error("REBOOT_SMOKE_BUSINESS_ROOM_SCALE seed=%d" % seed)
            quit(1)
            return
        # Business is always in a north lot in this slice. Its compact bathroom must
        # retain the authored 2x2 usable footprint.
        var commercial_property_id := ""
        for property_value in properties:
            var property: Dictionary = property_value
            if bool(property.get("commercial", false)):
                commercial_property_id = str(property.get("id", ""))
                break
        saw_business_bath = false
        for room_value in a.get("rooms", []):
            var room: Dictionary = room_value
            if str(room.get("property_id", "")) == commercial_property_id and str(room.get("function", "")) == "bathroom":
                var rect: Rect2i = room.get("rect", Rect2i())
                saw_business_bath = rect.size == Vector2i(2, 2)
                break
        if not saw_business_bath:
            push_error("REBOOT_SMOKE_BUSINESS_BATH_SCALE seed=%d" % seed)
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

    print("REBOOT_CORE_SMOKE_OK")
    quit(0)
