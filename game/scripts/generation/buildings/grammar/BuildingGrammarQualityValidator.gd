extends RefCounted
class_name BuildingGrammarQualityValidator

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

const MAX_BLOCKING_PROP_RATIO: float = 0.45

func validate(profile: BuildingGrammarProfile, layout: Dictionary, props: Array[Dictionary]) -> Dictionary:
    var failures: Array[String] = []
    if profile == null or not profile.is_valid() or layout.is_empty():
        return {"ok": false, "failures": ["invalid_quality_input"]}

    var room_rects: Dictionary = layout.get("room_rects", {})
    var public_purpose: String = String(profile.public_room.get("purpose", ""))
    if public_purpose.is_empty() or not room_rects.has(public_purpose):
        failures.append("required_public_room_missing")
    for purpose: String in profile.service_rooms.keys():
        if not room_rects.has(purpose):
            failures.append("required_service_room_missing_%s" % purpose)
    if profile.forbid_dedicated_hall and (room_rects.has("hall") or room_rects.has("corridor")):
        failures.append("dedicated_hall_forbidden")

    var prop_cells: Dictionary = {}
    for prop: Dictionary in props:
        var cell: Vector2i = prop.get("local_cell", Vector2i(-1, -1))
        if prop_cells.has(cell):
            failures.append("quality_prop_overlap")
        prop_cells[cell] = bool(prop.get("blocking", true))

    for cell_value: Variant in layout.get("reserved_clear", []):
        var cell: Vector2i = cell_value
        if prop_cells.has(cell) and bool(prop_cells[cell]):
            failures.append("reserved_clearance_blocked")

    for purpose: String in room_rects.keys():
        var room: Rect2i = room_rects[purpose]
        if room.size.x <= 0 or room.size.y <= 0:
            failures.append("invalid_room_rect_%s" % purpose)
            continue
        var blocking_count: int = 0
        for prop: Dictionary in props:
            if bool(prop.get("blocking", true)) and room.has_point(prop.get("local_cell", Vector2i(-1, -1))):
                blocking_count += 1
        var ratio: float = float(blocking_count) / float(room.size.x * room.size.y)
        if ratio > MAX_BLOCKING_PROP_RATIO:
            failures.append("room_overfilled_%s" % purpose)

    _validate_kitchen_run(layout, props, failures)
    _validate_restaurant_clusters(profile, props, failures)
    _validate_storage_lane(layout, props, failures)
    _validate_bathroom(props, failures)
    _validate_table_facings(props, failures)
    return {"ok": failures.is_empty(), "failures": failures}

func _validate_kitchen_run(layout: Dictionary, props: Array[Dictionary], failures: Array[String]) -> void:
    var room_rects: Dictionary = layout.get("room_rects", {})
    if not room_rects.has("kitchen"):
        return
    var roles: Array[String] = [
        "prop.kitchen.fridge",
        "prop.kitchen.counter_1",
        "prop.kitchen.sink",
        "prop.kitchen.counter_2",
        "prop.kitchen.stove",
        "prop.kitchen.counter_3",
        "prop.kitchen.pantry",
    ]
    var previous: Vector2i = Vector2i(-9999, -9999)
    for role: String in roles:
        var cell: Vector2i = _prop_cell_by_role(props, role)
        if cell.x < 0:
            failures.append("kitchen_run_role_missing_%s" % role)
            return
        if previous.x > -9000 and _manhattan(previous, cell) != 1:
            failures.append("kitchen_run_not_contiguous")
            return
        previous = cell

func _validate_restaurant_clusters(profile: BuildingGrammarProfile, props: Array[Dictionary], failures: Array[String]) -> void:
    if StringName(profile.public_room.get("dressing", &"")) != &"restaurant_dining":
        return
    var booths: Array[Vector2i] = []
    var tables: Array[Vector2i] = []
    for prop: Dictionary in props:
        var semantic: StringName = prop.get("semantic", &"")
        var cell: Vector2i = prop.get("local_cell", Vector2i(-1, -1))
        if semantic == &"prop.restaurant_booth":
            booths.append(cell)
        elif semantic == &"prop.restaurant_table":
            tables.append(cell)
    if booths.size() < 4 or tables.size() < 4:
        failures.append("restaurant_cluster_count_invalid")
        return
    for table: Vector2i in tables:
        var near_booth: bool = false
        for booth: Vector2i in booths:
            if _manhattan(table, booth) <= 1:
                near_booth = true
                break
        if not near_booth:
            failures.append("restaurant_table_unclustered")
            return

func _validate_storage_lane(layout: Dictionary, props: Array[Dictionary], failures: Array[String]) -> void:
    var room_rects: Dictionary = layout.get("room_rects", {})
    if not room_rects.has("storage"):
        return
    var room: Rect2i = room_rects["storage"]
    var center_x: int = room.position.x + room.size.x / 2
    for y in range(room.position.y, room.position.y + room.size.y):
        var cell := Vector2i(center_x, y)
        if _blocking_prop_at(props, cell):
            failures.append("storage_service_lane_blocked")
            return

func _validate_bathroom(props: Array[Dictionary], failures: Array[String]) -> void:
    var saw_toilet: bool = false
    var saw_sink: bool = false
    for prop: Dictionary in props:
        var role: String = String(prop.get("role", ""))
        if role == "prop.bathroom.toilet":
            saw_toilet = true
        elif role == "prop.bathroom.sink":
            saw_sink = true
    if not saw_toilet:
        failures.append("bathroom_toilet_missing")
    if not saw_sink:
        failures.append("bathroom_sink_missing")

func _validate_table_facings(props: Array[Dictionary], failures: Array[String]) -> void:
    var table_semantics: Array[StringName] = [
        &"prop.restaurant_table",
        &"prop.breakfast_table",
        &"prop.coffee_table",
        &"prop.end_table",
    ]
    for prop: Dictionary in props:
        var semantic: StringName = prop.get("semantic", &"")
        if not table_semantics.has(semantic):
            continue
        var facing: int = int(prop.get("facing", -1))
        if facing != Facing.Value.SOUTH and facing != Facing.Value.WEST:
            failures.append("table_facing_not_south_or_west")
            return

func _prop_cell_by_role(props: Array[Dictionary], role: String) -> Vector2i:
    for prop: Dictionary in props:
        if String(prop.get("role", "")) == role:
            return prop.get("local_cell", Vector2i(-1, -1))
    return Vector2i(-1, -1)

func _blocking_prop_at(props: Array[Dictionary], cell: Vector2i) -> bool:
    for prop: Dictionary in props:
        if prop.get("local_cell", Vector2i(-1, -1)) == cell and bool(prop.get("blocking", true)):
            return true
    return false

func _manhattan(a: Vector2i, b: Vector2i) -> int:
    return absi(a.x - b.x) + absi(a.y - b.y)
