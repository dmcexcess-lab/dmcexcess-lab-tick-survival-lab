extends RefCounted
class_name BuildingRoomDressingPlanner

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

func plan(profile: BuildingGrammarProfile, layout: Dictionary, seed: int) -> Dictionary:
    var failures: Array[String] = []
    var props: Array[Dictionary] = []
    if profile == null or not profile.is_valid() or layout.is_empty():
        return {"ok": false, "failures": ["invalid_dressing_input"], "props": props}

    var occupied: Dictionary = {}
    var reserved: Dictionary = {}
    for cell_value: Variant in layout.get("reserved_clear", []):
        reserved[cell_value] = true

    var public_spec: Dictionary = profile.public_room
    var public_purpose: String = String(public_spec.get("purpose", ""))
    var public_rect: Rect2i = _room_rect(layout, public_purpose)
    match StringName(public_spec.get("dressing", &"")):
        &"restaurant_dining":
            _dress_restaurant_dining(props, occupied, reserved, public_rect, layout, failures)
        _:
            failures.append("unknown_public_dressing")

    for purpose: String in layout.get("service_order", []):
        var spec: Dictionary = profile.service_spec(purpose)
        var room_rect: Rect2i = _room_rect(layout, purpose)
        match StringName(spec.get("dressing", &"")):
            &"kitchen_line":
                _dress_kitchen_line(props, occupied, reserved, purpose, room_rect, failures)
            &"storage_service":
                _dress_storage_service(props, occupied, reserved, purpose, room_rect, failures)
            &"bathroom_basic":
                _dress_bathroom_basic(props, occupied, reserved, purpose, room_rect, failures)
            _:
                failures.append("unknown_service_dressing_%s" % purpose)

    return {"ok": failures.is_empty(), "failures": failures, "props": props}

func _dress_restaurant_dining(
    props: Array[Dictionary],
    occupied: Dictionary,
    reserved: Dictionary,
    room: Rect2i,
    layout: Dictionary,
    failures: Array[String]
) -> void:
    if room.size.x < 11 or room.size.y < 5:
        failures.append("restaurant_room_too_small")
        return

    var left_booth_x: int = room.position.x
    var left_table_x: int = room.position.x + 1
    var right_booth_x: int = room.position.x + room.size.x - 1
    var right_table_x: int = right_booth_x - 1
    var row_a: int = room.position.y + 1
    var row_mid: int = room.position.y + room.size.y / 2
    var row_b: int = room.position.y + room.size.y - 2

    _add_prop(props, occupied, reserved, "prop.dining.booth.west_a", Vector2i(left_booth_x, row_a), &"prop.restaurant_booth", Facing.Value.EAST, true, failures)
    _add_prop(props, occupied, reserved, "prop.dining.table.west_a", Vector2i(left_table_x, row_a), &"prop.restaurant_table", Facing.Value.WEST, true, failures)
    _add_prop(props, occupied, reserved, "prop.dining.booth.west_mid", Vector2i(left_booth_x, row_mid), &"prop.restaurant_booth", Facing.Value.EAST, true, failures)
    _add_prop(props, occupied, reserved, "prop.dining.table.west_mid", Vector2i(left_table_x, row_mid), &"prop.restaurant_table", Facing.Value.WEST, true, failures)
    _add_prop(props, occupied, reserved, "prop.dining.booth.west_b", Vector2i(left_booth_x, row_b), &"prop.restaurant_booth", Facing.Value.EAST, true, failures)
    _add_prop(props, occupied, reserved, "prop.dining.table.west_b", Vector2i(left_table_x, row_b), &"prop.restaurant_table", Facing.Value.WEST, true, failures)
    _add_prop(props, occupied, reserved, "prop.dining.booth.east_a", Vector2i(right_booth_x, row_a), &"prop.restaurant_booth", Facing.Value.WEST, true, failures)
    _add_prop(props, occupied, reserved, "prop.dining.table.east_a", Vector2i(right_table_x, row_a), &"prop.restaurant_table", Facing.Value.WEST, true, failures)
    _add_prop(props, occupied, reserved, "prop.dining.booth.east_mid", Vector2i(right_booth_x, row_mid), &"prop.restaurant_booth", Facing.Value.WEST, true, failures)
    _add_prop(props, occupied, reserved, "prop.dining.table.east_mid", Vector2i(right_table_x, row_mid), &"prop.restaurant_table", Facing.Value.WEST, true, failures)
    _add_prop(props, occupied, reserved, "prop.dining.booth.east_b", Vector2i(right_booth_x, row_b), &"prop.restaurant_booth", Facing.Value.WEST, true, failures)
    _add_prop(props, occupied, reserved, "prop.dining.table.east_b", Vector2i(right_table_x, row_b), &"prop.restaurant_table", Facing.Value.WEST, true, failures)

    var kitchen_door: Vector2i = layout.get("service_door_cells", {}).get("kitchen", Vector2i(-1, -1))
    if kitchen_door.x < 0:
        failures.append("restaurant_kitchen_door_missing")
        return
    var counter_y: int = room.position.y
    var chair_y: int = counter_y + 1
    var counter_x_1: int = kitchen_door.x + 2
    var counter_x_2: int = counter_x_1 + 1
    if counter_x_2 >= room.position.x + room.size.x:
        counter_x_2 = kitchen_door.x - 2
        counter_x_1 = counter_x_2 - 1
    _add_prop(props, occupied, reserved, "prop.dining.counter_1", Vector2i(counter_x_1, counter_y), &"prop.counter_straight", Facing.Value.SOUTH, true, failures)
    _add_prop(props, occupied, reserved, "prop.dining.counter_2", Vector2i(counter_x_2, counter_y), &"prop.counter_straight", Facing.Value.SOUTH, true, failures)
    _add_prop(props, occupied, reserved, "prop.dining.counter_chair_1", Vector2i(counter_x_1, chair_y), &"prop.dining_chair", Facing.Value.NORTH, true, failures)
    _add_prop(props, occupied, reserved, "prop.dining.counter_chair_2", Vector2i(counter_x_2, chair_y), &"prop.dining_chair", Facing.Value.NORTH, true, failures)

func _dress_kitchen_line(
    props: Array[Dictionary],
    occupied: Dictionary,
    reserved: Dictionary,
    purpose: String,
    room: Rect2i,
    failures: Array[String]
) -> void:
    if room.size.x < 7 or room.size.y < 3:
        failures.append("kitchen_line_room_too_small")
        return
    var semantics: Array[StringName] = [
        &"prop.refrigerator_white",
        &"prop.counter_straight",
        &"prop.kitchen_sink",
        &"prop.counter_straight",
        &"prop.stove_range",
        &"prop.counter_straight",
        &"prop.pantry",
    ]
    var role_tokens: Array[String] = ["fridge", "counter_1", "sink", "counter_2", "stove", "counter_3", "pantry"]
    for i in range(7):
        _add_prop(
            props,
            occupied,
            reserved,
            "prop.%s.%s" % [purpose, role_tokens[i]],
            Vector2i(room.position.x + i, room.position.y),
            semantics[i],
            Facing.Value.SOUTH,
            true,
            failures
        )

func _dress_storage_service(
    props: Array[Dictionary],
    occupied: Dictionary,
    reserved: Dictionary,
    purpose: String,
    room: Rect2i,
    failures: Array[String]
) -> void:
    if room.size.x < 3 or room.size.y < 3:
        failures.append("storage_room_too_small")
        return
    var left_x: int = room.position.x
    var right_x: int = room.position.x + room.size.x - 1
    var top_y: int = room.position.y
    var bottom_y: int = room.position.y + room.size.y - 1
    _add_prop(props, occupied, reserved, "prop.%s.rack_left" % purpose, Vector2i(left_x, top_y), &"prop.warehouse_rack", Facing.Value.SOUTH, true, failures)
    _add_prop(props, occupied, reserved, "prop.%s.rack_right" % purpose, Vector2i(right_x, top_y), &"prop.warehouse_rack", Facing.Value.SOUTH, true, failures)
    _add_prop(props, occupied, reserved, "prop.%s.pallet" % purpose, Vector2i(left_x, bottom_y), &"prop.pallet_stack", Facing.Value.EAST, true, failures)
    _add_prop(props, occupied, reserved, "prop.%s.tool_cabinet" % purpose, Vector2i(right_x, bottom_y), &"prop.tool_cabinet", Facing.Value.WEST, true, failures)

func _dress_bathroom_basic(
    props: Array[Dictionary],
    occupied: Dictionary,
    reserved: Dictionary,
    purpose: String,
    room: Rect2i,
    failures: Array[String]
) -> void:
    if room.size.x < 3 or room.size.y < 3:
        failures.append("bathroom_room_too_small")
        return
    var left_x: int = room.position.x
    var right_x: int = room.position.x + room.size.x - 1
    var top_y: int = room.position.y
    var bottom_y: int = room.position.y + room.size.y - 1
    _add_prop(props, occupied, reserved, "prop.%s.toilet" % purpose, Vector2i(left_x, top_y), &"prop.toilet_modern", Facing.Value.SOUTH, true, failures)
    _add_prop(props, occupied, reserved, "prop.%s.sink" % purpose, Vector2i(right_x, top_y), &"prop.pedestal_sink", Facing.Value.SOUTH, true, failures)
    _add_prop(props, occupied, reserved, "prop.%s.towel_rack" % purpose, Vector2i(right_x, bottom_y), &"prop.towel_rack", Facing.Value.NORTH, true, failures)

func _room_rect(layout: Dictionary, purpose: String) -> Rect2i:
    var room_rects: Dictionary = layout.get("room_rects", {})
    if not room_rects.has(purpose):
        return Rect2i()
    return room_rects[purpose]

func _add_prop(
    props: Array[Dictionary],
    occupied: Dictionary,
    reserved: Dictionary,
    role: String,
    local_cell: Vector2i,
    semantic: StringName,
    facing: int,
    blocking: bool,
    failures: Array[String]
) -> void:
    if occupied.has(local_cell):
        failures.append("dressing_prop_overlap_%s" % role)
        return
    if blocking and reserved.has(local_cell):
        failures.append("dressing_blocks_reserved_%s" % role)
        return
    occupied[local_cell] = true
    props.append({
        "role": role,
        "local_cell": local_cell,
        "semantic": semantic,
        "facing": facing,
        "blocking": blocking,
    })
