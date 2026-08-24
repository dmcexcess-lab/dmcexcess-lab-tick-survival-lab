extends RefCounted
class_name OneStoryBaselineProfileCatalog

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

const SUBURBAN_SMALL: StringName = &"residential.house.suburban_small"
const SUBURBAN_FAMILY: StringName = &"residential.house.suburban_family"
const TOWNHOMES_ROW3: StringName = &"residential.townhomes.row3"
const MULTIUNIT_ROW4: StringName = &"residential.multiunit.row4"
const ROADSIDE_MOTEL: StringName = &"lodging.motel.roadside"
const CONVENIENCE_STORE: StringName = &"commercial.convenience_store.small"
const GROCERY: StringName = &"commercial.grocery.neighborhood"
const PHARMACY: StringName = &"commercial.pharmacy.small"
const HARDWARE: StringName = &"commercial.hardware_store.small"
const OFFICE: StringName = &"commercial.office.small"
const CLINIC: StringName = &"civic.clinic.small"
const POLICE: StringName = &"civic.police_station.small"
const FIRE: StringName = &"civic.fire_station.small"
const SCHOOL: StringName = &"civic.school.elementary_small"
const CHURCH: StringName = &"civic.church.small"
const WAREHOUSE: StringName = &"industrial.warehouse.small"
const WORKSHOP: StringName = &"industrial.workshop.small"
const BARN: StringName = &"agricultural.barn.medium"

const PROFILE_IDS: Array[StringName] = [
    SUBURBAN_SMALL,
    SUBURBAN_FAMILY,
    TOWNHOMES_ROW3,
    MULTIUNIT_ROW4,
    ROADSIDE_MOTEL,
    CONVENIENCE_STORE,
    GROCERY,
    PHARMACY,
    HARDWARE,
    OFFICE,
    CLINIC,
    POLICE,
    FIRE,
    SCHOOL,
    CHURCH,
    WAREHOUSE,
    WORKSHOP,
    BARN,
]

func profile_ids() -> Array[StringName]:
    return PROFILE_IDS.duplicate()

func has_profile(profile_id: StringName) -> bool:
    return profile_id in PROFILE_IDS

func profile(profile_id: StringName) -> Dictionary:
    match profile_id:
        SUBURBAN_SMALL:
            return _suburban_small()
        SUBURBAN_FAMILY:
            return _suburban_family()
        TOWNHOMES_ROW3:
            return _townhomes_row3()
        MULTIUNIT_ROW4:
            return _multiunit_row4()
        ROADSIDE_MOTEL:
            return _roadside_motel()
        CONVENIENCE_STORE:
            return _convenience_store()
        GROCERY:
            return _grocery()
        PHARMACY:
            return _pharmacy()
        HARDWARE:
            return _hardware()
        OFFICE:
            return _office()
        CLINIC:
            return _clinic()
        POLICE:
            return _police()
        FIRE:
            return _fire_station()
        SCHOOL:
            return _school()
        CHURCH:
            return _church()
        WAREHOUSE:
            return _warehouse()
        WORKSHOP:
            return _workshop()
        BARN:
            return _barn()
    return {}

func _base(
    profile_id: StringName,
    size: Vector2i,
    category: StringName,
    shell_wall: StringName,
    exterior_door: StringName,
    window: StringName,
    window_spacing: int = 3,
    window_sides: Array = [Facing.Value.SOUTH, Facing.Value.NORTH, Facing.Value.EAST, Facing.Value.WEST]
) -> Dictionary:
    return {
        "id": profile_id,
        "version": 1,
        "story_count": 1,
        "category": category,
        "canonical_size": size,
        "canonical_frontage": Facing.Value.SOUTH,
        "shell_wall_semantic": shell_wall,
        "interior_wall_semantic": &"wall.interior",
        "exterior_door_semantic": exterior_door,
        "interior_door_semantic": exterior_door,
        "window_semantic": window,
        "window_spacing": window_spacing,
        "window_sides": window_sides.duplicate(),
        "rooms": [],
        "doors": [],
        "props": [],
    }

func _room(purpose: String, rect: Rect2i, floor: StringName) -> Dictionary:
    return {"purpose": purpose, "rect": rect, "floor": floor}

func _door(role: String, cell: Vector2i, semantic: StringName, facing: int) -> Dictionary:
    return {"role": role, "cell": cell, "semantic": semantic, "kind": &"door", "facing": facing}

func _prop(role: String, cell: Vector2i, semantic: StringName, facing: int = Facing.Value.SOUTH) -> Dictionary:
    return {"role": role, "cell": cell, "semantic": semantic, "facing": facing, "blocking": true}

func _suburban_small() -> Dictionary:
    var p := _base(SUBURBAN_SMALL, Vector2i(13, 11), &"residential", &"wall.house", &"door.house", &"window.house")
    p["rooms"] = [
        _room("living_kitchen", Rect2i(1, 6, 11, 4), &"ground.laminate_light"),
        _room("bedroom", Rect2i(1, 1, 5, 4), &"ground.carpet_beige"),
        _room("bathroom", Rect2i(7, 1, 5, 4), &"ground.tile_white"),
    ]
    p["doors"] = [
        _door("door.exterior.primary", Vector2i(6, 10), &"door.house", Facing.Value.SOUTH),
        _door("door.interior.bedroom", Vector2i(3, 5), &"door.house", Facing.Value.NORTH),
        _door("door.interior.bathroom", Vector2i(9, 5), &"door.house", Facing.Value.NORTH),
    ]
    p["props"] = [
        _prop("prop.living.sofa", Vector2i(2, 8), &"prop.sofa", Facing.Value.EAST),
        _prop("prop.living.tv", Vector2i(2, 6), &"prop.tv_flat", Facing.Value.SOUTH),
        _prop("prop.kitchen.fridge", Vector2i(8, 6), &"prop.refrigerator_white"),
        _prop("prop.kitchen.sink", Vector2i(9, 6), &"prop.kitchen_sink"),
        _prop("prop.kitchen.stove", Vector2i(10, 6), &"prop.stove_range"),
        _prop("prop.bedroom.bed", Vector2i(2, 2), &"prop.bed_double", Facing.Value.SOUTH),
        _prop("prop.bathroom.toilet", Vector2i(8, 2), &"prop.toilet_modern"),
        _prop("prop.bathroom.sink", Vector2i(10, 2), &"prop.pedestal_sink"),
    ]
    return p

func _suburban_family() -> Dictionary:
    var p := _base(SUBURBAN_FAMILY, Vector2i(17, 13), &"residential", &"wall.house", &"door.house", &"window.house")
    p["rooms"] = [
        _room("living_kitchen", Rect2i(1, 7, 15, 5), &"ground.laminate_light"),
        _room("bedroom_primary", Rect2i(1, 1, 5, 5), &"ground.carpet_beige"),
        _room("bedroom_second", Rect2i(7, 1, 4, 5), &"ground.carpet_blue"),
        _room("bathroom", Rect2i(12, 1, 4, 5), &"ground.tile_white"),
    ]
    p["doors"] = [
        _door("door.exterior.primary", Vector2i(8, 12), &"door.house", Facing.Value.SOUTH),
        _door("door.interior.bedroom_primary", Vector2i(3, 6), &"door.house", Facing.Value.NORTH),
        _door("door.interior.bedroom_second", Vector2i(9, 6), &"door.house", Facing.Value.NORTH),
        _door("door.interior.bathroom", Vector2i(14, 6), &"door.house", Facing.Value.NORTH),
    ]
    p["props"] = [
        _prop("prop.living.sofa", Vector2i(3, 10), &"prop.sofa", Facing.Value.EAST),
        _prop("prop.living.tv", Vector2i(3, 7), &"prop.tv_flat"),
        _prop("prop.kitchen.fridge", Vector2i(11, 7), &"prop.refrigerator_white"),
        _prop("prop.kitchen.sink", Vector2i(12, 7), &"prop.kitchen_sink"),
        _prop("prop.kitchen.stove", Vector2i(13, 7), &"prop.stove_range"),
        _prop("prop.kitchen.table", Vector2i(12, 10), &"prop.breakfast_table"),
        _prop("prop.primary.bed", Vector2i(2, 2), &"prop.bed_double"),
        _prop("prop.second.bed", Vector2i(8, 2), &"prop.bed_single"),
        _prop("prop.bath.toilet", Vector2i(13, 2), &"prop.toilet_modern"),
        _prop("prop.bath.sink", Vector2i(15, 2), &"prop.pedestal_sink"),
    ]
    return p

func _townhomes_row3() -> Dictionary:
    var p := _base(TOWNHOMES_ROW3, Vector2i(31, 13), &"residential_multiunit", &"wall.apartment", &"door.house", &"window.apartment", 3, [Facing.Value.SOUTH, Facing.Value.NORTH])
    var rooms: Array = []
    var doors: Array = []
    var props: Array = []
    for unit in range(3):
        var x0: int = 1 + unit * 10
        var token: String = "unit_%d" % (unit + 1)
        rooms.append(_room("%s.living_kitchen" % token, Rect2i(x0, 7, 9, 5), &"ground.laminate_light"))
        rooms.append(_room("%s.bedroom" % token, Rect2i(x0, 1, 5, 5), &"ground.carpet_beige"))
        rooms.append(_room("%s.bathroom" % token, Rect2i(x0 + 6, 1, 3, 5), &"ground.tile_white"))
        var exterior_role: String = "door.exterior.primary" if unit == 0 else "door.exterior.%s" % token
        doors.append(_door(exterior_role, Vector2i(x0 + 4, 12), &"door.house", Facing.Value.SOUTH))
        doors.append(_door("door.interior.%s.bedroom" % token, Vector2i(x0 + 2, 6), &"door.house", Facing.Value.NORTH))
        doors.append(_door("door.interior.%s.bathroom" % token, Vector2i(x0 + 7, 6), &"door.house", Facing.Value.NORTH))
        props.append(_prop("prop.%s.sofa" % token, Vector2i(x0 + 1, 10), &"prop.sofa", Facing.Value.EAST))
        props.append(_prop("prop.%s.fridge" % token, Vector2i(x0 + 7, 7), &"prop.refrigerator_white"))
        props.append(_prop("prop.%s.stove" % token, Vector2i(x0 + 8, 7), &"prop.stove_range"))
        props.append(_prop("prop.%s.bed" % token, Vector2i(x0 + 1, 2), &"prop.bed_double"))
        props.append(_prop("prop.%s.toilet" % token, Vector2i(x0 + 7, 2), &"prop.toilet_modern"))
    p["rooms"] = rooms
    p["doors"] = doors
    p["props"] = props
    p["unit_count"] = 3
    return p

func _multiunit_row4() -> Dictionary:
    var p := _base(MULTIUNIT_ROW4, Vector2i(33, 11), &"residential_multiunit", &"wall.apartment", &"door.house", &"window.apartment", 3, [Facing.Value.SOUTH, Facing.Value.NORTH])
    var rooms: Array = []
    var doors: Array = []
    var props: Array = []
    for unit in range(4):
        var x0: int = 1 + unit * 8
        var token: String = "unit_%d" % (unit + 1)
        rooms.append(_room("%s.living_kitchen" % token, Rect2i(x0, 6, 7, 4), &"ground.laminate_dark"))
        rooms.append(_room("%s.bedroom" % token, Rect2i(x0, 1, 4, 4), &"ground.carpet_beige"))
        rooms.append(_room("%s.bathroom" % token, Rect2i(x0 + 5, 1, 2, 4), &"ground.tile_white"))
        var exterior_role: String = "door.exterior.primary" if unit == 0 else "door.exterior.%s" % token
        doors.append(_door(exterior_role, Vector2i(x0 + 3, 10), &"door.house", Facing.Value.SOUTH))
        doors.append(_door("door.interior.%s.bedroom" % token, Vector2i(x0 + 2, 5), &"door.house", Facing.Value.NORTH))
        doors.append(_door("door.interior.%s.bathroom" % token, Vector2i(x0 + 5, 5), &"door.house", Facing.Value.NORTH))
        props.append(_prop("prop.%s.sofa" % token, Vector2i(x0 + 1, 8), &"prop.loveseat", Facing.Value.EAST))
        props.append(_prop("prop.%s.fridge" % token, Vector2i(x0 + 5, 6), &"prop.refrigerator_white"))
        props.append(_prop("prop.%s.bed" % token, Vector2i(x0 + 1, 2), &"prop.bed_single"))
        props.append(_prop("prop.%s.toilet" % token, Vector2i(x0 + 5, 2), &"prop.toilet_modern"))
    p["rooms"] = rooms
    p["doors"] = doors
    p["props"] = props
    p["unit_count"] = 4
    return p

func _roadside_motel() -> Dictionary:
    var p := _base(ROADSIDE_MOTEL, Vector2i(41, 11), &"lodging", &"wall.apartment", &"door.storefront", &"window.apartment", 3, [Facing.Value.SOUTH, Facing.Value.NORTH])
    var rooms: Array = []
    var doors: Array = []
    var props: Array = []
    var starts: Array[int] = [1, 11, 21, 31]
    rooms.append(_room("office.lobby", Rect2i(1, 5, 9, 5), &"ground.carpet_beige"))
    rooms.append(_room("office.back", Rect2i(1, 1, 9, 3), &"ground.office_carpet"))
    doors.append(_door("door.exterior.primary", Vector2i(5, 10), &"door.storefront", Facing.Value.SOUTH))
    doors.append(_door("door.interior.office_back", Vector2i(5, 4), &"door.office", Facing.Value.NORTH))
    props.append(_prop("prop.office.desk", Vector2i(3, 7), &"prop.office_desk"))
    props.append(_prop("prop.office.file", Vector2i(2, 2), &"prop.file_cabinet_tall"))
    for guest_index in range(1, 4):
        var x0: int = starts[guest_index]
        var token: String = "guest_%d" % guest_index
        rooms.append(_room("%s.sleeping" % token, Rect2i(x0, 5, 9, 5), &"ground.carpet_beige"))
        rooms.append(_room("%s.bathroom" % token, Rect2i(x0, 1, 4, 3), &"ground.tile_white"))
        rooms.append(_room("%s.closet" % token, Rect2i(x0 + 5, 1, 4, 3), &"ground.carpet_beige"))
        doors.append(_door("door.exterior.%s" % token, Vector2i(x0 + 4, 10), &"door.house", Facing.Value.SOUTH))
        doors.append(_door("door.interior.%s.bathroom" % token, Vector2i(x0 + 2, 4), &"door.house", Facing.Value.NORTH))
        doors.append(_door("door.interior.%s.closet" % token, Vector2i(x0 + 7, 4), &"door.house", Facing.Value.NORTH))
        props.append(_prop("prop.%s.bed" % token, Vector2i(x0 + 2, 7), &"prop.bed_double"))
        props.append(_prop("prop.%s.tv" % token, Vector2i(x0 + 7, 5), &"prop.tv_flat"))
        props.append(_prop("prop.%s.toilet" % token, Vector2i(x0 + 1, 2), &"prop.toilet_modern"))
        props.append(_prop("prop.%s.sink" % token, Vector2i(x0 + 3, 2), &"prop.pedestal_sink"))
    p["rooms"] = rooms
    p["doors"] = doors
    p["props"] = props
    p["unit_count"] = 3
    return p

func _convenience_store() -> Dictionary:
    var p := _base(CONVENIENCE_STORE, Vector2i(17, 11), &"commercial", &"wall.storefront", &"door.storefront", &"window.storefront", 2, [Facing.Value.SOUTH, Facing.Value.EAST, Facing.Value.WEST])
    p["rooms"] = [
        _room("sales_floor", Rect2i(1, 5, 15, 5), &"ground.shop_floor"),
        _room("stockroom", Rect2i(1, 1, 7, 3), &"ground.warehouse_floor"),
        _room("office", Rect2i(9, 1, 3, 3), &"ground.office_carpet"),
        _room("bathroom", Rect2i(13, 1, 3, 3), &"ground.tile_white"),
    ]
    p["doors"] = [
        _door("door.exterior.primary", Vector2i(8, 10), &"door.storefront", Facing.Value.SOUTH),
        _door("door.interior.stockroom", Vector2i(4, 4), &"door.store", Facing.Value.NORTH),
        _door("door.interior.office", Vector2i(10, 4), &"door.store", Facing.Value.NORTH),
        _door("door.interior.bathroom", Vector2i(14, 4), &"door.store", Facing.Value.NORTH),
    ]
    p["props"] = [
        _prop("prop.sales.shelf_1", Vector2i(4, 7), &"prop.retail_shelf"),
        _prop("prop.sales.shelf_2", Vector2i(8, 7), &"prop.retail_shelf"),
        _prop("prop.sales.cooler", Vector2i(14, 5), &"prop.walkin_cooler"),
        _prop("prop.stock.rack", Vector2i(2, 2), &"prop.warehouse_rack"),
        _prop("prop.office.desk", Vector2i(10, 2), &"prop.office_desk"),
        _prop("prop.bath.toilet", Vector2i(14, 2), &"prop.toilet_modern"),
    ]
    return p

func _grocery() -> Dictionary:
    var p := _base(GROCERY, Vector2i(23, 13), &"commercial", &"wall.storefront", &"door.storefront", &"window.storefront", 2, [Facing.Value.SOUTH, Facing.Value.EAST, Facing.Value.WEST])
    p["rooms"] = [
        _room("sales_floor", Rect2i(1, 6, 21, 6), &"ground.shop_floor"),
        _room("stockroom", Rect2i(1, 1, 11, 4), &"ground.warehouse_floor"),
        _room("cooler", Rect2i(13, 1, 5, 4), &"ground.concrete_clean"),
        _room("office", Rect2i(19, 1, 3, 4), &"ground.office_carpet"),
    ]
    p["doors"] = [
        _door("door.exterior.primary", Vector2i(11, 12), &"door.storefront", Facing.Value.SOUTH),
        _door("door.interior.stockroom", Vector2i(6, 5), &"door.store", Facing.Value.NORTH),
        _door("door.interior.cooler", Vector2i(15, 5), &"door.store", Facing.Value.NORTH),
        _door("door.interior.office", Vector2i(20, 5), &"door.office", Facing.Value.NORTH),
        _door("door.exterior.service", Vector2i(6, 0), &"door.store", Facing.Value.NORTH),
    ]
    p["props"] = [
        _prop("prop.sales.shelf_1", Vector2i(5, 8), &"prop.retail_shelf"),
        _prop("prop.sales.shelf_2", Vector2i(9, 8), &"prop.retail_shelf"),
        _prop("prop.sales.shelf_3", Vector2i(13, 8), &"prop.retail_shelf"),
        _prop("prop.sales.produce", Vector2i(17, 9), &"prop.produce_display"),
        _prop("prop.stock.rack", Vector2i(2, 2), &"prop.warehouse_rack"),
        _prop("prop.cooler.freezer", Vector2i(14, 2), &"prop.chest_freezer"),
        _prop("prop.office.desk", Vector2i(20, 2), &"prop.office_desk"),
    ]
    return p

func _pharmacy() -> Dictionary:
    var p := _base(PHARMACY, Vector2i(19, 11), &"commercial", &"wall.storefront", &"door.storefront", &"window.storefront", 2, [Facing.Value.SOUTH, Facing.Value.EAST, Facing.Value.WEST])
    p["rooms"] = [
        _room("sales_floor", Rect2i(1, 5, 17, 5), &"ground.shop_floor"),
        _room("pharmacy", Rect2i(1, 1, 9, 3), &"ground.tile_white"),
        _room("stockroom", Rect2i(11, 1, 4, 3), &"ground.warehouse_floor"),
        _room("bathroom", Rect2i(16, 1, 2, 3), &"ground.tile_white"),
    ]
    p["doors"] = [
        _door("door.exterior.primary", Vector2i(9, 10), &"door.storefront", Facing.Value.SOUTH),
        _door("door.interior.pharmacy", Vector2i(5, 4), &"door.store", Facing.Value.NORTH),
        _door("door.interior.stockroom", Vector2i(13, 4), &"door.store", Facing.Value.NORTH),
        _door("door.interior.bathroom", Vector2i(16, 4), &"door.store", Facing.Value.NORTH),
    ]
    p["props"] = [
        _prop("prop.sales.shelf_1", Vector2i(5, 7), &"prop.retail_shelf"),
        _prop("prop.sales.shelf_2", Vector2i(11, 7), &"prop.retail_shelf"),
        _prop("prop.pharmacy.counter", Vector2i(5, 2), &"prop.counter_straight"),
        _prop("prop.pharmacy.cabinet", Vector2i(2, 2), &"prop.file_cabinet_tall"),
        _prop("prop.stock.rack", Vector2i(12, 2), &"prop.warehouse_rack"),
        _prop("prop.bath.toilet", Vector2i(16, 2), &"prop.toilet_modern"),
    ]
    return p

func _hardware() -> Dictionary:
    var p := _base(HARDWARE, Vector2i(23, 11), &"commercial", &"wall.storefront", &"door.storefront", &"window.storefront", 3, [Facing.Value.SOUTH, Facing.Value.EAST, Facing.Value.WEST])
    p["rooms"] = [
        _room("sales_floor", Rect2i(1, 5, 21, 5), &"ground.shop_floor"),
        _room("stockroom", Rect2i(1, 1, 12, 3), &"ground.warehouse_floor"),
        _room("service_workshop", Rect2i(14, 1, 8, 3), &"ground.garage_floor"),
    ]
    p["doors"] = [
        _door("door.exterior.primary", Vector2i(11, 10), &"door.storefront", Facing.Value.SOUTH),
        _door("door.interior.stockroom", Vector2i(6, 4), &"door.store", Facing.Value.NORTH),
        _door("door.interior.service_workshop", Vector2i(18, 4), &"door.store", Facing.Value.NORTH),
        _door("door.exterior.service", Vector2i(18, 0), &"door.garage", Facing.Value.NORTH),
    ]
    p["props"] = [
        _prop("prop.sales.shelf_1", Vector2i(5, 7), &"prop.retail_shelf"),
        _prop("prop.sales.shelf_2", Vector2i(10, 7), &"prop.retail_shelf"),
        _prop("prop.sales.shelf_3", Vector2i(15, 7), &"prop.retail_shelf"),
        _prop("prop.stock.rack", Vector2i(2, 2), &"prop.warehouse_rack"),
        _prop("prop.service.workbench", Vector2i(16, 2), &"prop.workbench_heavy"),
        _prop("prop.service.tool_cabinet", Vector2i(20, 2), &"prop.tool_cabinet"),
    ]
    return p

func _office() -> Dictionary:
    var p := _base(OFFICE, Vector2i(21, 13), &"commercial", &"wall.office", &"door.office", &"window.office", 3)
    p["rooms"] = [
        _room("open_office", Rect2i(1, 7, 19, 5), &"ground.office_carpet"),
        _room("private_office_1", Rect2i(1, 1, 5, 5), &"ground.office_carpet"),
        _room("private_office_2", Rect2i(7, 1, 5, 5), &"ground.office_carpet"),
        _room("bathroom", Rect2i(13, 1, 3, 5), &"ground.tile_white"),
        _room("file_storage", Rect2i(17, 1, 3, 5), &"ground.office_carpet"),
    ]
    p["doors"] = [
        _door("door.exterior.primary", Vector2i(10, 12), &"door.office", Facing.Value.SOUTH),
        _door("door.interior.private_office_1", Vector2i(3, 6), &"door.office", Facing.Value.NORTH),
        _door("door.interior.private_office_2", Vector2i(9, 6), &"door.office", Facing.Value.NORTH),
        _door("door.interior.bathroom", Vector2i(14, 6), &"door.office", Facing.Value.NORTH),
        _door("door.interior.file_storage", Vector2i(18, 6), &"door.office", Facing.Value.NORTH),
    ]
    p["props"] = [
        _prop("prop.open.desk_1", Vector2i(5, 9), &"prop.office_desk"),
        _prop("prop.open.desk_2", Vector2i(14, 9), &"prop.office_desk"),
        _prop("prop.office1.desk", Vector2i(3, 3), &"prop.office_desk"),
        _prop("prop.office2.desk", Vector2i(9, 3), &"prop.office_desk"),
        _prop("prop.bath.toilet", Vector2i(14, 2), &"prop.toilet_modern"),
        _prop("prop.files.cabinet", Vector2i(18, 2), &"prop.file_cabinet_tall"),
    ]
    return p

func _clinic() -> Dictionary:
    var p := _base(CLINIC, Vector2i(23, 13), &"civic", &"wall.office", &"door.office", &"window.office", 3)
    p["rooms"] = [
        _room("reception_waiting", Rect2i(1, 7, 21, 5), &"ground.hospital_floor"),
        _room("exam_1", Rect2i(1, 1, 5, 5), &"ground.hospital_floor"),
        _room("exam_2", Rect2i(7, 1, 5, 5), &"ground.hospital_floor"),
        _room("treatment", Rect2i(13, 1, 5, 5), &"ground.hospital_floor"),
        _room("bathroom", Rect2i(19, 1, 3, 5), &"ground.tile_white"),
    ]
    p["doors"] = [
        _door("door.exterior.primary", Vector2i(11, 12), &"door.office", Facing.Value.SOUTH),
        _door("door.interior.exam_1", Vector2i(3, 6), &"door.office", Facing.Value.NORTH),
        _door("door.interior.exam_2", Vector2i(9, 6), &"door.office", Facing.Value.NORTH),
        _door("door.interior.treatment", Vector2i(15, 6), &"door.office", Facing.Value.NORTH),
        _door("door.interior.bathroom", Vector2i(20, 6), &"door.office", Facing.Value.NORTH),
    ]
    p["props"] = [
        _prop("prop.reception.desk", Vector2i(10, 8), &"prop.office_desk"),
        _prop("prop.waiting.chair_1", Vector2i(4, 10), &"prop.dining_chair"),
        _prop("prop.waiting.chair_2", Vector2i(6, 10), &"prop.dining_chair"),
        _prop("prop.exam1.cabinet", Vector2i(2, 2), &"prop.medicine_cabinet"),
        _prop("prop.exam2.cabinet", Vector2i(8, 2), &"prop.medicine_cabinet"),
        _prop("prop.treatment.cabinet", Vector2i(14, 2), &"prop.medicine_cabinet"),
        _prop("prop.bath.toilet", Vector2i(20, 2), &"prop.toilet_modern"),
    ]
    return p

func _police() -> Dictionary:
    var p := _base(POLICE, Vector2i(25, 15), &"civic", &"wall.office", &"door.office", &"window.office", 4)
    p["rooms"] = [
        _room("public_lobby", Rect2i(1, 10, 23, 4), &"ground.office_carpet"),
        _room("operations_corridor", Rect2i(1, 7, 23, 2), &"ground.concrete_clean"),
        _room("office", Rect2i(1, 1, 5, 5), &"ground.office_carpet"),
        _room("interview", Rect2i(7, 1, 5, 5), &"ground.office_carpet"),
        _room("evidence", Rect2i(13, 1, 5, 5), &"ground.warehouse_floor"),
        _room("holding", Rect2i(19, 1, 5, 5), &"ground.concrete_clean"),
    ]
    p["doors"] = [
        _door("door.exterior.primary", Vector2i(12, 14), &"door.office", Facing.Value.SOUTH),
        _door("door.interior.lobby_corridor", Vector2i(12, 9), &"door.office", Facing.Value.NORTH),
        _door("door.interior.office", Vector2i(3, 6), &"door.office", Facing.Value.NORTH),
        _door("door.interior.interview", Vector2i(9, 6), &"door.office", Facing.Value.NORTH),
        _door("door.interior.evidence", Vector2i(15, 6), &"door.office", Facing.Value.NORTH),
        _door("door.interior.holding", Vector2i(21, 6), &"door.office", Facing.Value.NORTH),
        _door("door.exterior.service", Vector2i(21, 0), &"door.office", Facing.Value.NORTH),
    ]
    p["props"] = [
        _prop("prop.lobby.desk", Vector2i(12, 11), &"prop.office_desk"),
        _prop("prop.office.desk", Vector2i(3, 3), &"prop.office_desk"),
        _prop("prop.interview.table", Vector2i(9, 3), &"prop.breakroom_table"),
        _prop("prop.evidence.rack", Vector2i(15, 2), &"prop.warehouse_rack"),
        _prop("prop.holding.bench", Vector2i(21, 3), &"prop.breakroom_table"),
    ]
    return p

func _fire_station() -> Dictionary:
    var p := _base(FIRE, Vector2i(25, 15), &"civic", &"wall.industrial", &"door.office", &"window.office", 4, [Facing.Value.SOUTH, Facing.Value.EAST, Facing.Value.WEST])
    p["rooms"] = [
        _room("apparatus_bay", Rect2i(1, 7, 23, 7), &"ground.garage_floor"),
        _room("bunk_room", Rect2i(1, 1, 9, 5), &"ground.carpet_beige"),
        _room("kitchen_break", Rect2i(11, 1, 7, 5), &"ground.linoleum_green"),
        _room("bathroom", Rect2i(19, 1, 5, 5), &"ground.tile_white"),
    ]
    p["doors"] = [
        _door("door.exterior.primary", Vector2i(12, 14), &"door.office", Facing.Value.SOUTH),
        _door("door.interior.bunk_room", Vector2i(5, 6), &"door.office", Facing.Value.NORTH),
        _door("door.interior.kitchen_break", Vector2i(14, 6), &"door.office", Facing.Value.NORTH),
        _door("door.interior.bathroom", Vector2i(21, 6), &"door.office", Facing.Value.NORTH),
    ]
    p["props"] = [
        _prop("prop.bunk.bed_1", Vector2i(3, 3), &"prop.bunk_bed"),
        _prop("prop.bunk.bed_2", Vector2i(7, 3), &"prop.bunk_bed"),
        _prop("prop.kitchen.fridge", Vector2i(12, 2), &"prop.refrigerator_white"),
        _prop("prop.kitchen.table", Vector2i(15, 4), &"prop.breakroom_table"),
        _prop("prop.bath.toilet", Vector2i(20, 2), &"prop.toilet_modern"),
        _prop("prop.bay.locker", Vector2i(3, 9), &"prop.locker_bank"),
        _prop("prop.bay.workbench", Vector2i(20, 9), &"prop.workbench_heavy"),
    ]
    return p

func _school() -> Dictionary:
    var p := _base(SCHOOL, Vector2i(29, 17), &"civic", &"wall.office", &"door.office", &"window.office", 4)
    p["rooms"] = [
        _room("entry_lobby", Rect2i(1, 12, 27, 4), &"ground.classroom_floor"),
        _room("main_corridor", Rect2i(1, 8, 27, 3), &"ground.classroom_floor"),
        _room("classroom_1", Rect2i(1, 1, 8, 6), &"ground.classroom_floor"),
        _room("classroom_2", Rect2i(10, 1, 8, 6), &"ground.classroom_floor"),
        _room("office", Rect2i(19, 1, 5, 6), &"ground.office_carpet"),
        _room("bathroom", Rect2i(25, 1, 3, 6), &"ground.tile_white"),
    ]
    p["doors"] = [
        _door("door.exterior.primary", Vector2i(14, 16), &"door.office", Facing.Value.SOUTH),
        _door("door.interior.lobby_corridor", Vector2i(14, 11), &"door.office", Facing.Value.NORTH),
        _door("door.interior.classroom_1", Vector2i(5, 7), &"door.office", Facing.Value.NORTH),
        _door("door.interior.classroom_2", Vector2i(14, 7), &"door.office", Facing.Value.NORTH),
        _door("door.interior.office", Vector2i(21, 7), &"door.office", Facing.Value.NORTH),
        _door("door.interior.bathroom", Vector2i(26, 7), &"door.office", Facing.Value.NORTH),
        _door("door.exterior.service", Vector2i(2, 0), &"door.office", Facing.Value.NORTH),
    ]
    p["props"] = [
        _prop("prop.class1.table_1", Vector2i(3, 3), &"prop.breakroom_table"),
        _prop("prop.class1.table_2", Vector2i(7, 4), &"prop.breakroom_table"),
        _prop("prop.class2.table_1", Vector2i(12, 3), &"prop.breakroom_table"),
        _prop("prop.class2.table_2", Vector2i(16, 4), &"prop.breakroom_table"),
        _prop("prop.office.desk", Vector2i(21, 3), &"prop.office_desk"),
        _prop("prop.bath.toilet", Vector2i(26, 3), &"prop.toilet_modern"),
    ]
    return p

func _church() -> Dictionary:
    var p := _base(CHURCH, Vector2i(23, 15), &"civic", &"wall.plaster", &"door.house", &"window.house", 3)
    p["rooms"] = [
        _room("sanctuary", Rect2i(1, 6, 21, 8), &"ground.wood_parquet"),
        _room("office", Rect2i(1, 1, 6, 4), &"ground.office_carpet"),
        _room("meeting_room", Rect2i(8, 1, 8, 4), &"ground.carpet_beige"),
        _room("bathroom", Rect2i(17, 1, 5, 4), &"ground.tile_white"),
    ]
    p["doors"] = [
        _door("door.exterior.primary", Vector2i(11, 14), &"door.house", Facing.Value.SOUTH),
        _door("door.interior.office", Vector2i(4, 5), &"door.house", Facing.Value.NORTH),
        _door("door.interior.meeting", Vector2i(12, 5), &"door.house", Facing.Value.NORTH),
        _door("door.interior.bathroom", Vector2i(19, 5), &"door.house", Facing.Value.NORTH),
    ]
    p["props"] = [
        _prop("prop.sanctuary.seat_1", Vector2i(5, 9), &"prop.breakroom_table"),
        _prop("prop.sanctuary.seat_2", Vector2i(11, 9), &"prop.breakroom_table"),
        _prop("prop.sanctuary.seat_3", Vector2i(17, 9), &"prop.breakroom_table"),
        _prop("prop.office.desk", Vector2i(3, 3), &"prop.office_desk"),
        _prop("prop.meeting.table", Vector2i(12, 3), &"prop.breakroom_table"),
        _prop("prop.bath.toilet", Vector2i(19, 2), &"prop.toilet_modern"),
    ]
    return p

func _warehouse() -> Dictionary:
    var p := _base(WAREHOUSE, Vector2i(27, 15), &"industrial", &"wall.warehouse", &"door.warehouse", &"window.warehouse", 6, [Facing.Value.SOUTH, Facing.Value.NORTH])
    p["rooms"] = [
        _room("warehouse_floor", Rect2i(1, 5, 25, 9), &"ground.warehouse_floor"),
        _room("office", Rect2i(1, 1, 7, 3), &"ground.office_carpet"),
        _room("bathroom", Rect2i(9, 1, 4, 3), &"ground.tile_white"),
        _room("utility", Rect2i(14, 1, 6, 3), &"ground.concrete_clean"),
        _room("secure_storage", Rect2i(21, 1, 5, 3), &"ground.warehouse_floor"),
    ]
    p["doors"] = [
        _door("door.exterior.primary", Vector2i(13, 14), &"door.warehouse", Facing.Value.SOUTH),
        _door("door.interior.office", Vector2i(4, 4), &"door.office", Facing.Value.NORTH),
        _door("door.interior.bathroom", Vector2i(11, 4), &"door.warehouse", Facing.Value.NORTH),
        _door("door.interior.utility", Vector2i(17, 4), &"door.warehouse", Facing.Value.NORTH),
        _door("door.interior.secure_storage", Vector2i(23, 4), &"door.warehouse", Facing.Value.NORTH),
        _door("door.exterior.service", Vector2i(23, 0), &"door.garage", Facing.Value.NORTH),
    ]
    p["props"] = [
        _prop("prop.floor.rack_1", Vector2i(5, 8), &"prop.warehouse_rack"),
        _prop("prop.floor.rack_2", Vector2i(12, 8), &"prop.warehouse_rack"),
        _prop("prop.floor.rack_3", Vector2i(19, 8), &"prop.warehouse_rack"),
        _prop("prop.office.desk", Vector2i(4, 2), &"prop.office_desk"),
        _prop("prop.utility.generator", Vector2i(16, 2), &"prop.portable_generator"),
        _prop("prop.secure.rack", Vector2i(23, 2), &"prop.warehouse_rack"),
    ]
    return p

func _workshop() -> Dictionary:
    var p := _base(WORKSHOP, Vector2i(21, 13), &"industrial", &"wall.industrial", &"door.industrial", &"window.industrial", 5, [Facing.Value.SOUTH, Facing.Value.NORTH])
    p["rooms"] = [
        _room("shop_floor", Rect2i(1, 5, 19, 7), &"ground.garage_floor"),
        _room("office", Rect2i(1, 1, 6, 3), &"ground.office_carpet"),
        _room("parts_storage", Rect2i(8, 1, 7, 3), &"ground.warehouse_floor"),
        _room("bathroom", Rect2i(16, 1, 4, 3), &"ground.tile_white"),
    ]
    p["doors"] = [
        _door("door.exterior.primary", Vector2i(10, 12), &"door.industrial", Facing.Value.SOUTH),
        _door("door.interior.office", Vector2i(4, 4), &"door.office", Facing.Value.NORTH),
        _door("door.interior.parts", Vector2i(11, 4), &"door.industrial", Facing.Value.NORTH),
        _door("door.interior.bathroom", Vector2i(18, 4), &"door.industrial", Facing.Value.NORTH),
        _door("door.exterior.service", Vector2i(18, 0), &"door.garage", Facing.Value.NORTH),
    ]
    p["props"] = [
        _prop("prop.shop.workbench_1", Vector2i(5, 8), &"prop.workbench_heavy"),
        _prop("prop.shop.machine", Vector2i(10, 8), &"prop.industrial_machine"),
        _prop("prop.shop.tool_cabinet", Vector2i(16, 8), &"prop.tool_cabinet"),
        _prop("prop.office.desk", Vector2i(3, 2), &"prop.office_desk"),
        _prop("prop.parts.rack", Vector2i(10, 2), &"prop.warehouse_rack"),
        _prop("prop.bath.toilet", Vector2i(18, 2), &"prop.toilet_modern"),
    ]
    return p

func _barn() -> Dictionary:
    var p := _base(BARN, Vector2i(21, 15), &"agricultural", &"wall.rural_wood", &"door.house", &"window.house", 6, [Facing.Value.SOUTH, Facing.Value.NORTH])
    p["rooms"] = [
        _room("barn_floor", Rect2i(1, 5, 19, 9), &"ground.warehouse_floor"),
        _room("tack_room", Rect2i(1, 1, 6, 3), &"ground.wood_parquet"),
        _room("feed_storage", Rect2i(8, 1, 6, 3), &"ground.warehouse_floor"),
        _room("tool_room", Rect2i(15, 1, 5, 3), &"ground.warehouse_floor"),
    ]
    p["doors"] = [
        _door("door.exterior.primary", Vector2i(10, 14), &"door.house", Facing.Value.SOUTH),
        _door("door.interior.tack", Vector2i(4, 4), &"door.house", Facing.Value.NORTH),
        _door("door.interior.feed", Vector2i(11, 4), &"door.house", Facing.Value.NORTH),
        _door("door.interior.tool", Vector2i(17, 4), &"door.house", Facing.Value.NORTH),
        _door("door.exterior.service", Vector2i(10, 0), &"door.house", Facing.Value.NORTH),
    ]
    p["props"] = [
        _prop("prop.floor.hay_1", Vector2i(5, 9), &"prop.hay_bale"),
        _prop("prop.floor.hay_2", Vector2i(15, 9), &"prop.hay_bale"),
        _prop("prop.tack.cabinet", Vector2i(3, 2), &"prop.tool_cabinet"),
        _prop("prop.feed.pallet", Vector2i(10, 2), &"prop.pallet_stack"),
        _prop("prop.tool.workbench", Vector2i(17, 2), &"prop.workbench_heavy"),
    ]
    return p
