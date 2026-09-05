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
const ROAD_POLE_SEARCH_RADIUS: int = 8
const ROAD_POLE_SPACING: int = 10
const ROAD_SIDE_HOLD_POLES: int = 2
const WELL_CLEARANCE: int = 1

var _topology: Dictionary = {}
var _blocked_prop_lookup: Dictionary = {}
var _pole_exclusion_lookup: Dictionary = {}

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
    for value: Variant in _topology.get("pole_exclusion_cells", []):
        var cell: Vector2i = value
        _pole_exclusion_lookup[cell] = true

func is_ready() -> bool:
    return super.is_ready() and bool(_topology.get("ok", false)) \
        and not (_topology.get("substations", []) as Array).is_empty()

func _build_projection() -> Dictionary:
    var props: Array[Dictionary] = []
    var wires: Array[Dictionary] = []
    var reserved_cells: Dictionary = {}
    var shared_pole_ids: Dictionary = {}
    var shared_pole_cells: Dictionary = {}
    var shared_pole_states: Dictionary = {}
    var trunk_wire_index_by_route: Dictionary = {}

    # Municipal water is represented by one already-generated building. Do not
    # manufacture a second utility shed/tank complex from the retired water-node
    # graph. Private rural wells remain the only water props added here.
    var road_graph: Dictionary = _build_local_road_graph()
    if road_graph.is_empty():
        return {"props": [], "wires": []}

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

        var customers: Array[Dictionary] = []
        for index: int in range(building_ids.size()):
            var building_id: String = String(building_ids[index]).strip_edges()
            var building_rect: Rect2i = building_rects[index]
            if building_id.is_empty() or building_rect.size.x <= 0 or building_rect.size.y <= 0:
                return {"props": [], "wires": []}
            customers.append({
                "building_id": building_id,
                "rect": building_rect,
                "ordinal": index,
            })

        var distribution: Dictionary = _shared_distribution_tree(
            token,
            service_key,
            transformer_id,
            anchor,
            customers,
            road_graph,
            reserved_cells,
            shared_pole_ids,
            shared_pole_cells,
            shared_pole_states
        )
        if not bool(distribution.get("ok", false)):
            return {"props": [], "wires": []}
        for record_value: Variant in distribution.get("props", []):
            if typeof(record_value) != TYPE_DICTIONARY:
                return {"props": [], "wires": []}
            var record: Dictionary = record_value
            props.append(record)
            reserved_cells[record.get("cell", INVALID_CELL)] = true
        for wire_value: Variant in distribution.get("wires", []):
            if typeof(wire_value) != TYPE_DICTIONARY:
                return {"props": [], "wires": []}
            var wire: Dictionary = (wire_value as Dictionary).duplicate(true)
            if StringName(wire.get("wire_role", &"")) != &"shared_trunk":
                wires.append(wire)
                continue
            var route_key: String = _undirected_edge_key(
                wire.get("route_start_cell", INVALID_CELL),
                wire.get("route_end_cell", INVALID_CELL)
            )
            if not trunk_wire_index_by_route.has(route_key):
                trunk_wire_index_by_route[route_key] = wires.size()
                wires.append(wire)
                continue
            var existing_index: int = int(trunk_wire_index_by_route[route_key])
            var existing: Dictionary = wires[existing_index]
            var services: Array = existing.get("service_settlement_ids", [])
            for service_value: Variant in wire.get("service_settlement_ids", []):
                var service_id: String = String(service_value).strip_edges()
                if not service_id.is_empty() and not services.has(service_id):
                    services.append(service_id)
            services.sort()
            existing["service_settlement_ids"] = services
            wires[existing_index] = existing

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

func _shared_distribution_tree(
    token: String,
    service_key: String,
    transformer_id: String,
    transformer_cell: Vector2i,
    customers: Array[Dictionary],
    road_graph: Dictionary,
    reserved_cells: Dictionary,
    shared_pole_ids: Dictionary,
    shared_pole_cells: Dictionary,
    shared_pole_states: Dictionary
) -> Dictionary:
    var root_road_cell: Vector2i = _nearest_graph_cell(transformer_cell, road_graph.keys())
    if root_road_cell == INVALID_CELL:
        return {"ok": false, "props": [], "wires": []}
    var parents: Dictionary = _road_parents_from_root(road_graph, root_road_cell)
    if parents.is_empty():
        return {"ok": false, "props": [], "wires": []}

    var customer_paths: Array[Dictionary] = []
    var union_graph: Dictionary = {}
    var key_cells: Dictionary = {root_road_cell: true}
    for customer: Dictionary in customers:
        var building_rect: Rect2i = customer.get("rect", Rect2i())
        var building_center: Vector2i = _rect_center(building_rect)
        var tap_cell: Vector2i = _nearest_graph_cell(building_center, parents.keys())
        if tap_cell == INVALID_CELL:
            return {"ok": false, "props": [], "wires": []}
        var path: Array[Vector2i] = _path_from_root(parents, root_road_cell, tap_cell)
        if path.is_empty():
            return {"ok": false, "props": [], "wires": []}
        key_cells[tap_cell] = true
        for path_index: int in range(1, path.size()):
            _graph_connect(union_graph, path[path_index - 1], path[path_index])
        for path_index: int in range(ROAD_POLE_SPACING, path.size() - 1, ROAD_POLE_SPACING):
            key_cells[path[path_index]] = true
        customer_paths.append({
            "building_id": customer.get("building_id", ""),
            "rect": building_rect,
            "ordinal": int(customer.get("ordinal", 0)),
            "tap_cell": tap_cell,
            "path": path,
        })

    for cell_value: Variant in union_graph.keys():
        var cell: Vector2i = cell_value
        var neighbors: Array = union_graph.get(cell, [])
        if neighbors.size() != 2:
            key_cells[cell] = true
            continue
        var a: Vector2i = neighbors[0]
        var b: Vector2i = neighbors[1]
        var da: Vector2i = a - cell
        var db: Vector2i = b - cell
        if da + db != Vector2i.ZERO:
            key_cells[cell] = true

    # Keep existing route-cell ordering for stable pole IDs, but place root-outward so each
    # child pole can inherit the physical roadside bank used by its parent span.
    var ordered_key_cells: Array[Vector2i] = []
    for value: Variant in key_cells.keys():
        ordered_key_cells.append(value)
    ordered_key_cells.sort_custom(_cell_before)
    var pole_ordinal_by_route_cell: Dictionary = {}
    for index: int in range(ordered_key_cells.size()):
        pole_ordinal_by_route_cell[ordered_key_cells[index]] = index

    var placement_key_cells: Array[Vector2i] = ordered_key_cells.duplicate()
    placement_key_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        var a_depth: int = _route_depth(parents, root_road_cell, a)
        var b_depth: int = _route_depth(parents, root_road_cell, b)
        if a_depth != b_depth:
            return a_depth < b_depth
        return _cell_before(a, b)
    )

    var props: Array[Dictionary] = []
    var wires: Array[Dictionary] = []
    var pole_id_by_route_cell: Dictionary = {}
    var pole_cell_by_route_cell: Dictionary = {}
    var pole_state_by_route_cell: Dictionary = {}
    var local_reserved: Dictionary = reserved_cells.duplicate()
    for route_cell: Vector2i in placement_key_cells:
        if shared_pole_ids.has(route_cell):
            pole_id_by_route_cell[route_cell] = shared_pole_ids[route_cell]
            pole_cell_by_route_cell[route_cell] = shared_pole_cells[route_cell]
            pole_state_by_route_cell[route_cell] = shared_pole_states.get(route_cell, {}).duplicate(true)
            continue
        var pole_ordinal: int = int(pole_ordinal_by_route_cell.get(route_cell, -1))
        if pole_ordinal < 0:
            return {"ok": false, "props": [], "wires": []}

        var direction: Vector2i = Vector2i.ZERO
        var preferred_side: int = -1
        var side_hold_remaining: int = 0
        if route_cell == root_road_cell:
            direction = _root_route_direction(root_road_cell, union_graph, road_graph)
        else:
            var parent_key: Vector2i = _nearest_key_parent(route_cell, key_cells, parents, root_road_cell)
            if parent_key == INVALID_CELL or not pole_cell_by_route_cell.has(parent_key):
                return {"ok": false, "props": [], "wires": []}
            direction = _cardinal_direction(parent_key, route_cell)
            if direction == Vector2i.ZERO:
                return {"ok": false, "props": [], "wires": []}
            var parent_pole_cell: Vector2i = pole_cell_by_route_cell.get(parent_key, INVALID_CELL)
            var parent_state: Dictionary = pole_state_by_route_cell.get(parent_key, {})
            preferred_side = _continuous_road_side(route_cell, direction, parent_pole_cell, parent_state)
            side_hold_remaining = int(parent_state.get("hold", 0))
        if direction == Vector2i.ZERO:
            direction = Vector2i(1, 0)

        var pole_cell: Vector2i = _find_roadside_available(
            route_cell,
            direction,
            preferred_side,
            local_reserved,
            ROAD_POLE_SEARCH_RADIUS,
            side_hold_remaining <= 0
        )
        if pole_cell == INVALID_CELL:
            return {"ok": false, "props": [], "wires": []}
        var actual_side: int = _road_side(route_cell, pole_cell, direction)
        if actual_side == 0:
            return {"ok": false, "props": [], "wires": []}

        var next_hold: int = maxi(0, side_hold_remaining - 1)
        if route_cell != root_road_cell and preferred_side != 0 and actual_side != preferred_side:
            next_hold = ROAD_SIDE_HOLD_POLES

        var pole_id: String = "power.physical.%s.road.%03d" % [token, pole_ordinal]
        props.append({
            "id": pole_id,
            "semantic": &"prop.utility_pole_wood",
            "cell": pole_cell,
            "facing": _facing_toward_cell(pole_cell, route_cell),
        })
        local_reserved[pole_cell] = true
        pole_id_by_route_cell[route_cell] = pole_id
        pole_cell_by_route_cell[route_cell] = pole_cell
        pole_state_by_route_cell[route_cell] = {
            "side": actual_side,
            "direction": direction,
            "hold": next_hold,
        }
        shared_pole_ids[route_cell] = pole_id
        shared_pole_cells[route_cell] = pole_cell
        shared_pole_states[route_cell] = pole_state_by_route_cell[route_cell].duplicate(true)

    var root_pole_id: String = String(pole_id_by_route_cell.get(root_road_cell, ""))
    var root_pole_cell: Vector2i = pole_cell_by_route_cell.get(root_road_cell, INVALID_CELL)
    if root_pole_id.is_empty() or root_pole_cell == INVALID_CELL:
        return {"ok": false, "props": [], "wires": []}
    wires.append({
        "asset_id": "power.asset.span.%s.substation_lead" % token,
        "start_id": transformer_id,
        "end_id": root_pole_id,
        "network_id": "power.network.local_distribution",
        "power_class": &"local_distribution",
        "wire_role": &"substation_lead",
        "segment_id": "power.local.%s.substation_lead" % token,
        "service_settlement_ids": [service_key],
        "route_start_cell": root_road_cell,
        "route_end_cell": root_road_cell,
        "snap_cell": root_pole_cell,
    })

    var seen_trunk_edges: Dictionary = {}
    var trunk_ordinal: int = 0
    for customer_path: Dictionary in customer_paths:
        var path: Array[Vector2i] = customer_path.get("path", [])
        var ordered_path_keys: Array[Vector2i] = []
        for route_cell: Vector2i in path:
            if key_cells.has(route_cell):
                ordered_path_keys.append(route_cell)
        for index: int in range(1, ordered_path_keys.size()):
            var route_start: Vector2i = ordered_path_keys[index - 1]
            var route_end: Vector2i = ordered_path_keys[index]
            if route_start == route_end:
                continue
            var edge_key: String = _undirected_edge_key(route_start, route_end)
            if seen_trunk_edges.has(edge_key):
                continue
            var start_id: String = String(pole_id_by_route_cell.get(route_start, ""))
            var end_id: String = String(pole_id_by_route_cell.get(route_end, ""))
            var end_cell: Vector2i = pole_cell_by_route_cell.get(route_end, INVALID_CELL)
            if start_id.is_empty() or end_id.is_empty() or end_cell == INVALID_CELL:
                return {"ok": false, "props": [], "wires": []}
            wires.append({
                "asset_id": "power.asset.span.%s.trunk.%03d" % [token, trunk_ordinal],
                "start_id": start_id,
                "end_id": end_id,
                "network_id": "power.network.local_distribution",
                "power_class": &"local_distribution",
                "wire_role": &"shared_trunk",
                "segment_id": "power.local.%s.trunk.%03d" % [token, trunk_ordinal],
                "service_settlement_ids": [service_key],
                "route_start_cell": route_start,
                "route_end_cell": route_end,
                "snap_cell": end_cell,
            })
            seen_trunk_edges[edge_key] = true
            trunk_ordinal += 1

    for customer_path: Dictionary in customer_paths:
        var building_id: String = String(customer_path.get("building_id", "")).strip_edges()
        var building_rect: Rect2i = customer_path.get("rect", Rect2i())
        var customer_ordinal: int = int(customer_path.get("ordinal", 0))
        var tap_cell: Vector2i = customer_path.get("tap_cell", INVALID_CELL)
        var tap_pole_id: String = String(pole_id_by_route_cell.get(tap_cell, ""))
        var tap_pole_cell: Vector2i = pole_cell_by_route_cell.get(tap_cell, INVALID_CELL)
        if building_id.is_empty() or tap_pole_id.is_empty() or tap_pole_cell == INVALID_CELL:
            return {"ok": false, "props": [], "wires": []}
        var customer_pole_cell: Vector2i = _find_customer_pole(building_rect, tap_pole_cell, local_reserved)
        if customer_pole_cell == INVALID_CELL:
            return {"ok": false, "props": [], "wires": []}
        var customer_pole_id: String = "power.physical.%s.customer.%03d" % [token, customer_ordinal]
        props.append({
            "id": customer_pole_id,
            "semantic": &"prop.utility_pole_wood",
            "cell": customer_pole_cell,
            "facing": _facing_toward_cell(customer_pole_cell, _rect_center(building_rect)),
        })
        local_reserved[customer_pole_cell] = true
        wires.append({
            "asset_id": "power.asset.span.%s.customer.%03d" % [token, customer_ordinal],
            "start_id": tap_pole_id,
            "end_id": customer_pole_id,
            "network_id": "power.network.local_distribution",
            "power_class": &"local_distribution",
            "wire_role": &"service_drop",
            "segment_id": "power.local.%s.customer.%03d" % [token, customer_ordinal],
            "service_settlement_ids": [service_key],
            "served_building_id": building_id,
            "route_start_cell": tap_cell,
            "route_end_cell": tap_cell,
            "snap_cell": customer_pole_cell,
        })

    return {"ok": true, "props": props, "wires": wires}

func _build_local_road_graph() -> Dictionary:
    var graph: Dictionary = {}
    for road_value: Variant in _topology.get("local_roads", []):
        if typeof(road_value) != TYPE_DICTIONARY:
            continue
        var road: Dictionary = road_value
        var start: Vector2i = road.get("start", INVALID_CELL)
        var finish: Vector2i = road.get("end", INVALID_CELL)
        if start == INVALID_CELL or finish == INVALID_CELL:
            continue
        var delta: Vector2i = finish - start
        if delta == Vector2i.ZERO or (delta.x != 0 and delta.y != 0):
            continue
        var direction := Vector2i(signi(delta.x), signi(delta.y))
        var length: int = absi(delta.x) + absi(delta.y)
        var previous: Vector2i = start
        if not graph.has(previous):
            graph[previous] = []
        for distance: int in range(1, length + 1):
            var cell: Vector2i = start + direction * distance
            _graph_connect(graph, previous, cell)
            previous = cell
    for cell_value: Variant in graph.keys():
        var cell: Vector2i = cell_value
        var neighbors: Array = graph.get(cell, [])
        neighbors.sort_custom(_cell_before)
        graph[cell] = neighbors
    return graph

func _road_parents_from_root(graph: Dictionary, root: Vector2i) -> Dictionary:
    if not graph.has(root):
        return {}
    var parents: Dictionary = {root: root}
    var queue: Array[Vector2i] = [root]
    var cursor: int = 0
    while cursor < queue.size():
        var current: Vector2i = queue[cursor]
        cursor += 1
        var neighbors: Array = graph.get(current, [])
        for neighbor_value: Variant in neighbors:
            var neighbor: Vector2i = neighbor_value
            if parents.has(neighbor):
                continue
            parents[neighbor] = current
            queue.append(neighbor)
    return parents

func _path_from_root(parents: Dictionary, root: Vector2i, target: Vector2i) -> Array[Vector2i]:
    if not parents.has(root) or not parents.has(target):
        return []
    var reversed: Array[Vector2i] = [target]
    var current: Vector2i = target
    var guard: int = 0
    while current != root:
        current = parents.get(current, INVALID_CELL)
        if current == INVALID_CELL:
            return []
        reversed.append(current)
        guard += 1
        if guard > parents.size():
            return []
    reversed.reverse()
    return reversed

func _nearest_graph_cell(target: Vector2i, candidates: Array) -> Vector2i:
    var best: Vector2i = INVALID_CELL
    var best_distance: int = 2147483647
    for value: Variant in candidates:
        var cell: Vector2i = value
        var distance: int = absi(cell.x - target.x) + absi(cell.y - target.y)
        if distance < best_distance or (distance == best_distance and (best == INVALID_CELL or _cell_before(cell, best))):
            best = cell
            best_distance = distance
    return best

func _graph_connect(graph: Dictionary, a: Vector2i, b: Vector2i) -> void:
    var a_neighbors: Array = graph.get(a, [])
    if not a_neighbors.has(b):
        a_neighbors.append(b)
        graph[a] = a_neighbors
    var b_neighbors: Array = graph.get(b, [])
    if not b_neighbors.has(a):
        b_neighbors.append(a)
        graph[b] = b_neighbors

func _undirected_edge_key(a: Vector2i, b: Vector2i) -> String:
    if _cell_before(b, a):
        var swap: Vector2i = a
        a = b
        b = swap
    return "%d,%d>%d,%d" % [a.x, a.y, b.x, b.y]

func _route_depth(parents: Dictionary, root: Vector2i, target: Vector2i) -> int:
    if not parents.has(target):
        return 2147483647
    var depth: int = 0
    var current: Vector2i = target
    while current != root:
        current = parents.get(current, INVALID_CELL)
        if current == INVALID_CELL:
            return 2147483647
        depth += 1
        if depth > parents.size():
            return 2147483647
    return depth

func _nearest_key_parent(
    route_cell: Vector2i,
    key_cells: Dictionary,
    parents: Dictionary,
    root: Vector2i
) -> Vector2i:
    var current: Vector2i = route_cell
    var guard: int = 0
    while current != root:
        current = parents.get(current, INVALID_CELL)
        if current == INVALID_CELL:
            return INVALID_CELL
        if key_cells.has(current):
            return current
        guard += 1
        if guard > parents.size():
            return INVALID_CELL
    return root

func _root_route_direction(root: Vector2i, union_graph: Dictionary, road_graph: Dictionary) -> Vector2i:
    var neighbors: Array = union_graph.get(root, [])
    if neighbors.is_empty():
        neighbors = road_graph.get(root, [])
    if neighbors.is_empty():
        return Vector2i.ZERO
    var typed: Array[Vector2i] = []
    for value: Variant in neighbors:
        if typeof(value) == TYPE_VECTOR2I:
            typed.append(value)
    typed.sort_custom(_cell_before)
    if typed.is_empty():
        return Vector2i.ZERO
    return _cardinal_direction(root, typed[0])

static func _cardinal_direction(start: Vector2i, finish: Vector2i) -> Vector2i:
    var delta: Vector2i = finish - start
    if delta.x != 0 and delta.y == 0:
        return Vector2i(signi(delta.x), 0)
    if delta.y != 0 and delta.x == 0:
        return Vector2i(0, signi(delta.y))
    return Vector2i.ZERO

static func _same_axis(a: Vector2i, b: Vector2i) -> bool:
    if a == Vector2i.ZERO or b == Vector2i.ZERO:
        return false
    return (a.x != 0 and b.x != 0) or (a.y != 0 and b.y != 0)

static func _continuous_road_side(
    route_cell: Vector2i,
    direction: Vector2i,
    parent_pole_cell: Vector2i,
    parent_state: Dictionary
) -> int:
    if direction == Vector2i.ZERO or parent_pole_cell == INVALID_CELL:
        return int(parent_state.get("side", -1))

    # Road-side signs are local to segment direction. At a bend, simply reusing the
    # previous sign can flip the physical bank. Choose the child segment bank whose
    # ideal one-cell offset is geometrically closest to the actual parent support.
    # This preserves a continuous roadside polyline even when an earlier pole was
    # displaced by a driveway/access exclusion.
    var positive_normal := Vector2i(-direction.y, direction.x)
    var positive_probe: Vector2i = route_cell + positive_normal
    var negative_probe: Vector2i = route_cell - positive_normal
    var positive_distance: int = absi(parent_pole_cell.x - positive_probe.x) + absi(parent_pole_cell.y - positive_probe.y)
    var negative_distance: int = absi(parent_pole_cell.x - negative_probe.x) + absi(parent_pole_cell.y - negative_probe.y)
    if positive_distance < negative_distance:
        return 1
    if negative_distance < positive_distance:
        return -1

    var projected_side: int = _road_side(route_cell, parent_pole_cell, direction)
    if projected_side != 0:
        return projected_side

    var parent_side: int = int(parent_state.get("side", -1))
    var parent_direction: Vector2i = parent_state.get("direction", Vector2i.ZERO)
    if parent_side == 0:
        parent_side = -1
    if _same_axis(direction, parent_direction) and (direction.x * parent_direction.x + direction.y * parent_direction.y) < 0:
        return -parent_side
    return parent_side

static func _road_side(route_cell: Vector2i, support_cell: Vector2i, direction: Vector2i) -> int:
    if support_cell == INVALID_CELL or direction == Vector2i.ZERO:
        return 0
    var offset: Vector2i = support_cell - route_cell
    return signi(direction.x * offset.y - direction.y * offset.x)

func _find_roadside_available(
    route_cell: Vector2i,
    direction: Vector2i,
    preferred_side: int,
    reserved_cells: Dictionary,
    max_radius: int,
    allow_opposite: bool
) -> Vector2i:
    var side: int = -1 if preferred_side < 0 else 1
    var sides: Array[int] = [side]
    if allow_opposite:
        sides.append(-side)
    for candidate_side: int in sides:
        for radius: int in range(1, max_radius + 1):
            for y: int in range(-radius, radius + 1):
                for x: int in range(-radius, radius + 1):
                    if absi(x) != radius and absi(y) != radius:
                        continue
                    var candidate: Vector2i = route_cell + Vector2i(x, y)
                    if _road_side(route_cell, candidate, direction) != candidate_side:
                        continue
                    if _cell_available(candidate, reserved_cells):
                        return candidate
    return INVALID_CELL

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

func _find_customer_pole(building_rect: Rect2i, trunk_cell: Vector2i, reserved_cells: Dictionary) -> Vector2i:
    var center: Vector2i = _rect_center(building_rect)
    var candidates: Array[Vector2i] = [
        Vector2i(building_rect.position.x - CUSTOMER_CLEARANCE, center.y),
        Vector2i(building_rect.end.x - 1 + CUSTOMER_CLEARANCE, center.y),
        Vector2i(center.x, building_rect.position.y - CUSTOMER_CLEARANCE),
        Vector2i(center.x, building_rect.end.y - 1 + CUSTOMER_CLEARANCE),
    ]
    candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        var a_distance: int = absi(a.x - trunk_cell.x) + absi(a.y - trunk_cell.y)
        var b_distance: int = absi(b.x - trunk_cell.x) + absi(b.y - trunk_cell.y)
        if a_distance != b_distance:
            return a_distance < b_distance
        if a.y != b.y:
            return a.y < b.y
        return a.x < b.x
    )
    for candidate: Vector2i in candidates:
        var resolved: Vector2i = _find_nearby_available(candidate, reserved_cells, CUSTOMER_SEARCH_RADIUS)
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
        var resolved: Vector2i = _find_nearby_available(candidate, reserved_cells, CUSTOMER_SEARCH_RADIUS)
        if resolved != INVALID_CELL:
            return resolved
    return INVALID_CELL

func _find_nearby_available(target: Vector2i, reserved_cells: Dictionary, max_radius: int) -> Vector2i:
    for radius: int in range(max_radius + 1):
        for y: int in range(-radius, radius + 1):
            for x: int in range(-radius, radius + 1):
                if radius > 0 and absi(x) != radius and absi(y) != radius:
                    continue
                var candidate: Vector2i = target + Vector2i(x, y)
                if _cell_available(candidate, reserved_cells):
                    return candidate
    return INVALID_CELL

func _cell_available(cell: Vector2i, reserved_cells: Dictionary) -> bool:
    if not _plan.bounds.has_point(cell) or reserved_cells.has(cell) or _blocked_prop_lookup.has(cell) \
        or _pole_exclusion_lookup.has(cell):
        return false
    if not _world.entities_at(cell).is_empty() or _is_planned_global_road_surface(cell) or _is_local_road_surface(cell):
        return false
    if _world.has_terrain(cell) and _is_constructed_vehicle_surface_terrain(_world.terrain_at(cell)):
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

static func _cell_before(a: Vector2i, b: Vector2i) -> bool:
    if a.y != b.y:
        return a.y < b.y
    return a.x < b.x

static func _rect_center(rect: Rect2i) -> Vector2i:
    return Vector2i(rect.position.x + int(rect.size.x / 2), rect.position.y + int(rect.size.y / 2))

static func _facing_toward_cell(origin: Vector2i, target: Vector2i) -> int:
    var delta: Vector2i = target - origin
    if absi(delta.x) > absi(delta.y):
        return Facing.Value.EAST if delta.x >= 0 else Facing.Value.WEST
    return Facing.Value.SOUTH if delta.y >= 0 else Facing.Value.NORTH
