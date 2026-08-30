extends UtilityPowerInfrastructureMaterializer
class_name NeighborhoodPowerInfrastructureMaterializer

const LOCAL_COLLISION_SEMANTICS: Array[StringName] = [
    &"prop.utility_pole_wood",
    &"prop.utility_pole_transformer",
    &"prop.streetlight",
    &"prop.transformer",
    &"prop.utility_box",
    &"prop.chainlink_fence",
    &"prop.shed",
    &"prop.water_heater_tall",
    &"prop.industrial_machine",
    &"prop.manhole",
]

const FACILITY_RADIUS: int = 2
const FACILITY_SEARCH_RADIUS: int = 32
const CUSTOMER_CLEARANCE: int = 2
const CUSTOMER_SEARCH_RADIUS: int = 6
const WELL_CLEARANCE: int = 1

var _topology: Dictionary = {}
var _blocked_prop_lookup: Dictionary = {}

func _init(
    world_state: WorldState = null,
    mutations: WorldMutationService = null,
    global_plan: GeneratedGlobalWorldPlan = null,
    utilities: UtilityRuntimeState = null,
    topology: Dictionary = {}
) -> void:
    super(world_state, mutations, global_plan, utilities)
    _topology = topology.duplicate(true)
    for value: Variant in _topology.get("blocked_prop_cells", []):
        var cell: Vector2i = value
        _blocked_prop_lookup[cell] = true

func is_ready() -> bool:
    return super.is_ready() and bool(_topology.get("ok", false)) \
        and not (_topology.get("substations", []) as Array).is_empty()

func _build_projection() -> Dictionary:
    var props: Array[Dictionary] = []
    var wires: Array[Dictionary] = []
    var reserved_cells: Dictionary = {}

    var plant_records: Array[Dictionary] = _water_plant_records(reserved_cells)
    if plant_records.is_empty():
        return {"props": [], "wires": []}
    for record: Dictionary in plant_records:
        var plant_cell: Vector2i = record.get("cell", INVALID_CELL)
        if plant_cell == INVALID_CELL or reserved_cells.has(plant_cell):
            return {"props": [], "wires": []}
        props.append(record)
        reserved_cells[plant_cell] = true

    var substations: Array = _topology.get("substations", [])
    for substation_value: Variant in substations:
        if typeof(substation_value) != TYPE_DICTIONARY:
            return {"props": [], "wires": []}
        var substation: Dictionary = substation_value
        var service_key: String = String(substation.get("service_key", "")).strip_edges()
        var target: Vector2i = substation.get("cell", INVALID_CELL)
        var building_ids: Array = substation.get("building_ids", [])
        var building_rects: Array = substation.get("building_rects", [])
        if service_key.is_empty() or target == INVALID_CELL or building_ids.is_empty() \
            or building_ids.size() != building_rects.size():
            return {"props": [], "wires": []}

        var anchor: Vector2i = _find_local_facility_anchor(target, reserved_cells)
        if anchor == INVALID_CELL:
            return {"props": [], "wires": []}
        var token: String = _stable_token(service_key)
        var transformer_id: String = "power.physical.substation.%s.transformer" % token
        var facility_records: Array[Dictionary] = _substation_records(token, transformer_id, anchor)
        for record: Dictionary in facility_records:
            var facility_cell: Vector2i = record.get("cell", INVALID_CELL)
            if facility_cell == INVALID_CELL or reserved_cells.has(facility_cell):
                return {"props": [], "wires": []}
            props.append(record)
            reserved_cells[facility_cell] = true

        for index: int in range(building_ids.size()):
            var building_id: String = String(building_ids[index]).strip_edges()
            var building_rect: Rect2i = building_rects[index]
            if building_id.is_empty() or building_rect.size.x <= 0 or building_rect.size.y <= 0:
                return {"props": [], "wires": []}
            var pole_cell: Vector2i = _find_customer_pole(building_rect, anchor, reserved_cells)
            if pole_cell == INVALID_CELL:
                return {"props": [], "wires": []}
            var pole_id: String = "power.physical.%s.customer.%03d" % [token, index]
            props.append({
                "id": pole_id,
                "semantic": &"prop.utility_pole_wood",
                "cell": pole_cell,
                "facing": _facing_toward_cell(pole_cell, _rect_center(building_rect)),
            })
            reserved_cells[pole_cell] = true
            wires.append({
                "asset_id": "power.asset.span.%s.customer.%03d" % [token, index],
                "start_id": transformer_id,
                "end_id": pole_id,
                "network_id": "power.network.local_distribution",
                "power_class": &"local_distribution",
                "segment_id": "power.local.%s.customer.%03d" % [token, index],
                "service_settlement_ids": [service_key],
                "served_building_id": building_id,
                "snap_cell": pole_cell,
            })

    for well_value: Variant in _topology.get("wells", []):
        if typeof(well_value) != TYPE_DICTIONARY:
            return {"props": [], "wires": []}
        var well: Dictionary = well_value
        var well_id: String = String(well.get("asset_id", "")).strip_edges()
        var building_rect: Rect2i = well.get("rect", Rect2i())
        if well_id.is_empty() or building_rect.size.x <= 0 or building_rect.size.y <= 0:
            return {"props": [], "wires": []}
        var well_cell: Vector2i = _find_well_cell(building_rect, reserved_cells)
        if well_cell == INVALID_CELL:
            return {"props": [], "wires": []}
        props.append({
            "id": well_id,
            # Existing final-prop art gives the well a visible ground cap while the stable
            # entity/asset ID and System-33 condition record carry the actual well identity.
            "semantic": &"prop.manhole",
            "cell": well_cell,
            "facing": Facing.Value.NORTH,
        })
        reserved_cells[well_cell] = true

    return {"props": props, "wires": wires}

func _water_plant_records(reserved_cells: Dictionary) -> Array[Dictionary]:
    var treatment_node: Dictionary = {}
    for node: Dictionary in _plan.water_nodes:
        if StringName(node.get("kind", &"")) == &"treatment_plant":
            if not treatment_node.is_empty():
                return []
            treatment_node = node
    if treatment_node.is_empty():
        return []
    var target: Vector2i = treatment_node.get("cell", INVALID_CELL)
    var plant_id: String = String(treatment_node.get("critical_asset_id", "")).strip_edges()
    if target == INVALID_CELL or plant_id.is_empty():
        return []
    var anchor: Vector2i = _find_local_facility_anchor(target, reserved_cells)
    if anchor == INVALID_CELL:
        return []
    var records: Array[Dictionary] = [
        {"id": plant_id, "semantic": &"prop.shed", "cell": anchor, "facing": Facing.Value.SOUTH},
        {"id": "water.physical.plant.001.tank", "semantic": &"prop.water_heater_tall", "cell": anchor + Vector2i(-1, 0), "facing": Facing.Value.SOUTH},
        {"id": "water.physical.plant.001.machine", "semantic": &"prop.industrial_machine", "cell": anchor + Vector2i(1, 0), "facing": Facing.Value.SOUTH},
        {"id": "water.physical.plant.001.box", "semantic": &"prop.utility_box", "cell": anchor + Vector2i(0, -1), "facing": Facing.Value.SOUTH},
    ]
    var fence_ordinal: int = 0
    for y: int in range(-FACILITY_RADIUS, FACILITY_RADIUS + 1):
        for x: int in range(-FACILITY_RADIUS, FACILITY_RADIUS + 1):
            if absi(x) != FACILITY_RADIUS and absi(y) != FACILITY_RADIUS:
                continue
            if x == 0 and y == FACILITY_RADIUS:
                continue
            records.append({
                "id": "water.physical.plant.001.fence.%02d" % fence_ordinal,
                "semantic": &"prop.chainlink_fence",
                "cell": anchor + Vector2i(x, y),
                "facing": Facing.Value.NORTH,
            })
            fence_ordinal += 1
    return records

func _substation_records(token: String, transformer_id: String, anchor: Vector2i) -> Array[Dictionary]:
    var records: Array[Dictionary] = [
        {"id": transformer_id, "semantic": &"prop.transformer", "cell": anchor, "facing": Facing.Value.NORTH},
        {"id": "power.physical.substation.%s.box.00" % token, "semantic": &"prop.utility_box", "cell": anchor + Vector2i(-1, 0), "facing": Facing.Value.NORTH},
        {"id": "power.physical.substation.%s.box.01" % token, "semantic": &"prop.utility_box", "cell": anchor + Vector2i(1, 0), "facing": Facing.Value.NORTH},
    ]
    var fence_ordinal: int = 0
    for y: int in range(-FACILITY_RADIUS, FACILITY_RADIUS + 1):
        for x: int in range(-FACILITY_RADIUS, FACILITY_RADIUS + 1):
            if absi(x) != FACILITY_RADIUS and absi(y) != FACILITY_RADIUS:
                continue
            if x == 0 and y == FACILITY_RADIUS:
                continue
            records.append({
                "id": "power.physical.substation.%s.fence.%02d" % [token, fence_ordinal],
                "semantic": &"prop.chainlink_fence",
                "cell": anchor + Vector2i(x, y),
                "facing": Facing.Value.NORTH,
            })
            fence_ordinal += 1
    return records

func _find_local_facility_anchor(target: Vector2i, reserved_cells: Dictionary) -> Vector2i:
    for radius: int in range(FACILITY_SEARCH_RADIUS + 1):
        for y: int in range(-radius, radius + 1):
            for x: int in range(-radius, radius + 1):
                if radius > 0 and absi(x) != radius and absi(y) != radius:
                    continue
                var candidate: Vector2i = target + Vector2i(x, y)
                if _facility_fits(candidate, reserved_cells):
                    return candidate
    return INVALID_CELL

func _facility_fits(anchor: Vector2i, reserved_cells: Dictionary) -> bool:
    for y: int in range(-FACILITY_RADIUS, FACILITY_RADIUS + 1):
        for x: int in range(-FACILITY_RADIUS, FACILITY_RADIUS + 1):
            var cell: Vector2i = anchor + Vector2i(x, y)
            if not _cell_available(cell, reserved_cells):
                return false
    return true

func _find_customer_pole(building_rect: Rect2i, substation_cell: Vector2i, reserved_cells: Dictionary) -> Vector2i:
    var center: Vector2i = _rect_center(building_rect)
    var candidates: Array[Vector2i] = [
        Vector2i(building_rect.position.x - CUSTOMER_CLEARANCE, center.y),
        Vector2i(building_rect.end.x - 1 + CUSTOMER_CLEARANCE, center.y),
        Vector2i(center.x, building_rect.position.y - CUSTOMER_CLEARANCE),
        Vector2i(center.x, building_rect.end.y - 1 + CUSTOMER_CLEARANCE),
    ]
    candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        var a_distance: int = absi(a.x - substation_cell.x) + absi(a.y - substation_cell.y)
        var b_distance: int = absi(b.x - substation_cell.x) + absi(b.y - substation_cell.y)
        if a_distance != b_distance:
            return a_distance < b_distance
        if a.y != b.y:
            return a.y < b.y
        return a.x < b.x
    )
    for candidate: Vector2i in candidates:
        var resolved: Vector2i = _find_nearby_available(candidate, reserved_cells)
        if resolved != INVALID_CELL:
            return resolved
    return INVALID_CELL

func _find_well_cell(building_rect: Rect2i, reserved_cells: Dictionary) -> Vector2i:
    var center: Vector2i = _rect_center(building_rect)
    var candidates: Array[Vector2i] = [
        Vector2i(building_rect.position.x - WELL_CLEARANCE, center.y),
        Vector2i(building_rect.end.x - 1 + WELL_CLEARANCE, center.y),
        Vector2i(center.x, building_rect.position.y - WELL_CLEARANCE),
        Vector2i(center.x, building_rect.end.y - 1 + WELL_CLEARANCE),
    ]
    for candidate: Vector2i in candidates:
        var resolved: Vector2i = _find_nearby_available(candidate, reserved_cells)
        if resolved != INVALID_CELL:
            return resolved
    return INVALID_CELL

func _find_nearby_available(target: Vector2i, reserved_cells: Dictionary) -> Vector2i:
    for radius: int in range(CUSTOMER_SEARCH_RADIUS + 1):
        for y: int in range(-radius, radius + 1):
            for x: int in range(-radius, radius + 1):
                if radius > 0 and absi(x) != radius and absi(y) != radius:
                    continue
                var candidate: Vector2i = target + Vector2i(x, y)
                if _cell_available(candidate, reserved_cells):
                    return candidate
    return INVALID_CELL

func _cell_available(cell: Vector2i, reserved_cells: Dictionary) -> bool:
    if not _plan.bounds.has_point(cell) or reserved_cells.has(cell) or _blocked_prop_lookup.has(cell):
        return false
    if not _world.entities_at(cell).is_empty() or _is_planned_global_road_surface(cell) or _is_local_road_surface(cell):
        return false
    for building_value: Variant in _topology.get("buildings", []):
        if typeof(building_value) != TYPE_DICTIONARY:
            continue
        var building_rect: Rect2i = (building_value as Dictionary).get("rect", Rect2i())
        if building_rect.has_point(cell):
            return false
    return true

func _is_local_road_surface(cell: Vector2i) -> bool:
    for road_value: Variant in _topology.get("local_roads", []):
        if typeof(road_value) != TYPE_DICTIONARY:
            continue
        var road: Dictionary = road_value
        var start: Vector2i = road.get("start", Vector2i.ZERO)
        var finish: Vector2i = road.get("end", Vector2i.ZERO)
        var width: int = maxi(1, int(road.get("width", 1)))
        var half_width: int = int(width / 2)
        if start.y == finish.y:
            if cell.x >= mini(start.x, finish.x) and cell.x <= maxi(start.x, finish.x) and absi(cell.y - start.y) <= half_width:
                return true
        elif start.x == finish.x:
            if cell.y >= mini(start.y, finish.y) and cell.y <= maxi(start.y, finish.y) and absi(cell.x - start.x) <= half_width:
                return true
    return false

static func _rect_center(rect: Rect2i) -> Vector2i:
    return Vector2i(rect.position.x + int(rect.size.x / 2), rect.position.y + int(rect.size.y / 2))

static func _facing_toward_cell(origin: Vector2i, target: Vector2i) -> int:
    var delta: Vector2i = target - origin
    if absi(delta.x) > absi(delta.y):
        return Facing.Value.EAST if delta.x >= 0 else Facing.Value.WEST
    return Facing.Value.SOUTH if delta.y >= 0 else Facing.Value.NORTH
