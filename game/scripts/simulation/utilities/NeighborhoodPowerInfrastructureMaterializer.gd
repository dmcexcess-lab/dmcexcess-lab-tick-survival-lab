extends UtilityPowerInfrastructureMaterializer
class_name NeighborhoodPowerInfrastructureMaterializer

const LOCAL_COLLISION_SEMANTICS: Array[StringName] = [
    &"prop.utility_pole_wood",
    &"prop.utility_pole_transformer",
    &"prop.streetlight",
    &"prop.transformer",
    &"prop.utility_box",
    &"prop.chainlink_fence",
    &"prop.manhole",
]

const FACILITY_RADIUS: int = 2
const FACILITY_SEARCH_RADIUS: int = 32
const CUSTOMER_CLEARANCE: int = 2
const CUSTOMER_SEARCH_RADIUS: int = 6
const ROAD_POLE_SEARCH_RADIUS: int = 8
const ROAD_POLE_SPACING: int = 10
# Independent service roots can nominate nearby keys on the same physical road.
# Collapse those visits onto one support so a shared distribution chain cannot
# produce visible two/three-pole bunches while retaining its nominal 10-cell cadence.
const ROAD_POLE_MIN_SPACING: int = 8
const ROAD_SIDE_HOLD_POLES: int = 2
const MAX_WIRE_SPAN: int = 16
const WELL_CLEARANCE: int = 1

var _topology: Dictionary = {}
var _roadside_runs: Dictionary = {}
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
    var distribution_jobs: Array[Dictionary] = []
    var all_road_keys: Dictionary = {}
    var trunk_wire_index_by_route: Dictionary = {}

    # Municipal water is represented by one already-generated building. Private
    # rural wells are the only water props added by this power infrastructure owner.
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

        var routes: Dictionary = _distribution_routes(anchor, customers, road_graph)
        if routes.is_empty():
            return {"props": [], "wires": []}
        for cell: Vector2i in routes["key_cells"]:
            all_road_keys[cell] = true
        distribution_jobs.append({
            "token": token, "service_key": service_key,
            "transformer_id": transformer_id, "anchor": anchor,
            "routes": routes,
        })

    # The physical roadside chain is planned once for ALL services. Substations may
    # share its spans, but cannot independently move a shared pole to another bank
    # or skip a neighboring service's tap when selecting span endpoints.
    var road_props: Array[Dictionary] = _place_shared_road_poles(
        all_road_keys, road_graph, reserved_cells, shared_pole_ids, shared_pole_cells
    )
    if road_props.is_empty():
        return {"props": [], "wires": []}
    props.append_array(road_props)
    for job: Dictionary in distribution_jobs:
        var distribution: Dictionary = _shared_distribution_tree(
            job, all_road_keys, reserved_cells, shared_pole_ids, shared_pole_cells
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
            var start_id: String = String(wire.get("start_id", "")).strip_edges()
            var end_id: String = String(wire.get("end_id", "")).strip_edges()
            var support_key: String = "%s>%s" % [start_id, end_id]
            if end_id < start_id:
                support_key = "%s>%s" % [end_id, start_id]
            var route_key: String = "%s|%s" % [
                _undirected_edge_key(
                    wire.get("route_start_cell", INVALID_CELL),
                    wire.get("route_end_cell", INVALID_CELL)
                ),
                support_key,
            ]
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

    var bounded: Dictionary = _bound_wire_spans(props, wires, reserved_cells)
    if bounded.is_empty():
        return {"props": [], "wires": []}
    _assign_roadside_lights(props)
    return {"props": props, "wires": bounded["wires"]}

func _distribution_routes(
    transformer_cell: Vector2i,
    customers: Array[Dictionary],
    road_graph: Dictionary
) -> Dictionary:
    var root_road_cell: Vector2i = _nearest_graph_cell(transformer_cell, road_graph.keys())
    if root_road_cell == INVALID_CELL:
        return {}
    var parents: Dictionary = _road_parents_from_root(road_graph, root_road_cell)
    if parents.is_empty():
        return {}

    var customer_paths: Array[Dictionary] = []
    var union_graph: Dictionary = {}
    var key_cells: Dictionary = {root_road_cell: true}
    for customer: Dictionary in customers:
        var building_rect: Rect2i = customer.get("rect", Rect2i())
        var building_center: Vector2i = _rect_center(building_rect)
        var tap_cell: Vector2i = _nearest_graph_cell(building_center, parents.keys())
        if tap_cell == INVALID_CELL:
            return {}
        var path: Array[Vector2i] = _path_from_root(parents, root_road_cell, tap_cell)
        if path.is_empty():
            return {}
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

    return {"root": root_road_cell, "key_cells": key_cells, "customer_paths": customer_paths}

func _shared_distribution_tree(
    job: Dictionary,
    key_cells: Dictionary,
    reserved_cells: Dictionary,
    pole_id_by_route_cell: Dictionary,
    pole_cell_by_route_cell: Dictionary
) -> Dictionary:
    var token: String = job["token"]
    var service_key: String = job["service_key"]
    var transformer_id: String = job["transformer_id"]
    var routes: Dictionary = job["routes"]
    var root_road_cell: Vector2i = routes["root"]
    var customer_paths: Array[Dictionary] = routes["customer_paths"]
    var props: Array[Dictionary] = []
    var wires: Array[Dictionary] = []
    var local_reserved: Dictionary = reserved_cells.duplicate()

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
            # Nearby route keys may intentionally share one physical support.
            # They are topology visits, not zero-length physical wire spans.
            if start_id == end_id:
                seen_trunk_edges[edge_key] = true
                continue
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

static func _cardinal_direction(start: Vector2i, finish: Vector2i) -> Vector2i:
    var delta: Vector2i = finish - start
    if delta.x != 0 and delta.y == 0:
        return Vector2i(signi(delta.x), 0)
    if delta.y != 0 and delta.x == 0:
        return Vector2i(0, signi(delta.y))
    return Vector2i.ZERO

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
    var normal := Vector2i(-direction.y, direction.x)
    for candidate_side: int in sides:
        for along_distance: int in range(max_radius + 1):
            var shifts: Array = [0] if along_distance == 0 else [-along_distance, along_distance]
            for offset: int in range(1, max_radius + 1):
                for shift: int in shifts:
                    var candidate: Vector2i = route_cell + normal * candidate_side * offset + direction * shift
                    if _cell_available(candidate, reserved_cells):
                        return candidate
    return INVALID_CELL

# Canonical straight-road runs use physical compass banks, independent of the
# direction any particular substation traverses them.
func _road_direction(cell: Vector2i, graph: Dictionary) -> Vector2i:
    for value: Variant in graph.get(cell, []):
        var neighbor: Vector2i = value
        if neighbor.y == cell.y:
            return Vector2i.RIGHT
    return Vector2i.DOWN

static func _road_run_key(cell: Vector2i, direction: Vector2i) -> String:
    return "h:%d" % cell.y if direction.x != 0 else "v:%d" % cell.x

func _place_shared_road_poles(
    keys: Dictionary, graph: Dictionary, reserved: Dictionary,
    ids: Dictionary, cells: Dictionary
) -> Array[Dictionary]:
    var groups: Dictionary = {}
    for cell: Vector2i in keys:
        var direction: Vector2i = _road_direction(cell, graph)
        var group: String = _road_run_key(cell, direction)
        var entries: Array = groups.get(group, [])
        entries.append(cell)
        groups[group] = entries
    var group_names: Array = groups.keys()
    group_names.sort()
    var result: Array[Dictionary] = []
    for group: String in group_names:
        var entries: Array = groups[group]
        entries.sort_custom(_cell_before)
        var direction: Vector2i = _road_direction(entries[0], graph)
        var side: int = -1 if direction.x != 0 else 1
        var hold: int = 0
        var last_route_cell: Vector2i = INVALID_CELL
        var last_pole_id: String = ""
        var last_pole_cell: Vector2i = INVALID_CELL
        for route_cell: Vector2i in entries:
            if last_route_cell != INVALID_CELL:
                var route_gap: int = absi(route_cell.x - last_route_cell.x) + absi(route_cell.y - last_route_cell.y)
                if route_gap < ROAD_POLE_MIN_SPACING:
                    ids[route_cell] = last_pole_id
                    cells[route_cell] = last_pole_cell
                    continue
            var cell: Vector2i = _find_roadside_available(
                route_cell, direction, side, reserved, ROAD_POLE_SEARCH_RADIUS, hold == 0
            )
            if cell == INVALID_CELL:
                push_error("Power roadside placement blocked at %s" % route_cell)
                return []
            var actual_side: int = _road_side(route_cell, cell, direction)
            hold = ROAD_SIDE_HOLD_POLES if actual_side != side else maxi(0, hold - 1)
            side = actual_side
            var id: String = "power.physical.road.%d.%d" % [route_cell.x, route_cell.y]
            result.append({
                "id": id, "semantic": &"prop.utility_pole_wood", "cell": cell,
                "facing": _facing_toward_cell(cell, route_cell),
                "road_cell": route_cell, "road_direction": direction,
            })
            reserved[cell] = true
            ids[route_cell] = id
            cells[route_cell] = cell
            last_route_cell = route_cell
            last_pole_id = id
            last_pole_cell = cell
    return result

# A service on the other bank crosses at its tap, then runs to the customer.
# The two-pole trunk hold never governed service drops; diagonal house leads
# previously crossed unrelated roadside spans without an explicit crossing pole.
func _roadside_candidate_clear(
    candidate: Vector2i, route: Vector2i, direction: Vector2i, bank: int, records: Dictionary
) -> bool:
    var candidate_along: int = candidate.x if direction.x != 0 else candidate.y
    var run_key: String = _road_run_key(route, direction)
    for value: Variant in records.values():
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var prop: Dictionary = value
        if not prop.has("road_cell") or not prop.has("road_direction"):
            continue
        var prop_route: Vector2i = prop["road_cell"]
        var prop_direction: Vector2i = prop["road_direction"]
        if _road_run_key(prop_route, prop_direction) != run_key:
            continue
        if _road_side(prop_route, prop["cell"], prop_direction) != bank:
            continue
        var prop_cell: Vector2i = prop["cell"]
        var prop_along: int = prop_cell.x if direction.x != 0 else prop_cell.y
        if absi(candidate_along - prop_along) < ROAD_POLE_MIN_SPACING:
            return false
    return true

func _existing_roadside_support(
    route: Vector2i, direction: Vector2i, bank: int, records: Dictionary
) -> Dictionary:
    var route_along: int = route.x if direction.x != 0 else route.y
    var run_key: String = _road_run_key(route, direction)
    var best: Dictionary = {}
    var best_gap: int = ROAD_POLE_MIN_SPACING
    for value: Variant in records.values():
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var prop: Dictionary = value
        if not prop.has("road_cell") or not prop.has("road_direction"):
            continue
        var prop_route: Vector2i = prop["road_cell"]
        var prop_direction: Vector2i = prop["road_direction"]
        if _road_run_key(prop_route, prop_direction) != run_key:
            continue
        if _road_side(prop_route, prop["cell"], prop_direction) != bank:
            continue
        var prop_cell: Vector2i = prop["cell"]
        var prop_along: int = prop_cell.x if direction.x != 0 else prop_cell.y
        var gap: int = absi(route_along - prop_along)
        if gap < best_gap:
            best_gap = gap
            best = {"id": String(prop["id"]), "cell": prop_cell}
    return best

func _lead_crossing_support(
    road: Dictionary, target: Vector2i, reserved: Dictionary, records: Dictionary
) -> Dictionary:
    var route: Vector2i = road["road_cell"]
    var direction: Vector2i = road["road_direction"]
    var origin: Vector2i = road["cell"]
    var target_side: int = _road_side(route, target, direction)
    if target_side == 0 or target_side == _road_side(route, origin, direction):
        return {}
    var existing: Dictionary = _existing_roadside_support(route, direction, target_side, records)
    if not existing.is_empty():
        return existing
    var normal := Vector2i(-direction.y, direction.x)
    var aligned_route: Vector2i = Vector2i(origin.x, route.y) if direction.x != 0 else Vector2i(route.x, origin.y)
    for shift_distance: int in range(0, ROAD_POLE_MIN_SPACING + 1):
        var shifts: Array[int] = [0] if shift_distance == 0 else [-shift_distance, shift_distance]
        for shift: int in shifts:
            for offset: int in range(1, MAX_WIRE_SPAN + 1):
                var candidate: Vector2i = aligned_route + direction * shift + normal * target_side * offset
                var candidate_route: Vector2i = Vector2i(candidate.x, route.y) if direction.x != 0 else Vector2i(route.x, candidate.y)
                if _cell_available(candidate, reserved) and _roadside_candidate_clear(candidate, candidate_route, direction, target_side, records):
                    return {"cell": candidate, "road_cell": candidate_route}
    return {}

func _bound_wire_spans(
    props: Array[Dictionary], wires: Array[Dictionary], reserved: Dictionary
) -> Dictionary:
    var records: Dictionary = {}
    for prop: Dictionary in props:
        records[prop["id"]] = prop
    var result: Array[Dictionary] = []
    var span_buckets: Dictionary = {}
    var ids_by_cell: Dictionary = {}
    for prop: Dictionary in props:
        ids_by_cell[prop["cell"]] = prop["id"]
    for wire: Dictionary in wires:
        var start_id: String = wire["start_id"]
        var end_id: String = wire["end_id"]
        var start: Vector2i = records[start_id]["cell"]
        var finish: Vector2i = records[end_id]["cell"]
        var waypoints: Array[Dictionary] = [{"id": start_id, "cell": start}]
        var role: StringName = wire.get("wire_role", &"")
        if role in [&"service_drop", &"substation_lead"]:
            var road: Dictionary = records[start_id] if role == &"service_drop" else records[end_id]
            var target: Vector2i = finish if role == &"service_drop" else start
            var crossing: Dictionary = _lead_crossing_support(road, target, reserved, records)
            if not crossing.is_empty():
                if crossing.has("id"):
                    waypoints.append({"id": String(crossing["id"]), "cell": crossing["cell"]})
                else:
                    var crossing_cell: Vector2i = crossing["cell"]
                    var crossing_id: String = "%s.crossing" % wire["asset_id"]
                    var prop: Dictionary = {
                        "id": crossing_id, "cell": crossing_cell, "semantic": &"prop.utility_pole_wood",
                        "facing": _facing_toward_cell(crossing_cell, crossing["road_cell"]),
                        "road_cell": crossing["road_cell"], "road_direction": road["road_direction"],
                    }
                    props.append(prop)
                    records[crossing_id] = prop
                    reserved[crossing_cell] = true
                    ids_by_cell[crossing_cell] = crossing_id
                    waypoints.append({"id": crossing_id, "cell": crossing_cell})
        waypoints.append({"id": end_id, "cell": finish})
        var previous: Dictionary = waypoints[0]
        var ordinal: int = 0
        for point_index: int in range(1, waypoints.size()):
            var target: Dictionary = waypoints[point_index]
            while Vector2(previous["cell"]).distance_to(Vector2(target["cell"])) > float(MAX_WIRE_SPAN) \
                or not _span_crossings(previous["cell"], target["cell"], span_buckets).is_empty():
                var cell: Vector2i = _shared_span_junction(previous["cell"], target["cell"], span_buckets)
                if cell == INVALID_CELL:
                    cell = _span_support_cell(previous["cell"], target["cell"], reserved, span_buckets)
                if cell == INVALID_CELL:
                    push_error("Power span cannot be supported: %s -> %s" % [previous["cell"], target["cell"]])
                    return {}
                if ids_by_cell.has(cell):
                    var shared: Dictionary = {"id": ids_by_cell[cell], "cell": cell}
                    _append_span(result, wire, previous, shared, ordinal, span_buckets)
                    ordinal += 1
                    previous = shared
                    continue
                var id: String = "%s.support.%03d" % [wire["asset_id"], ordinal]
                var prop: Dictionary = {
                    "id": id, "cell": cell, "semantic": &"prop.utility_pole_wood",
                    "facing": _facing_toward_cell(cell, target["cell"]),
                }
                if role == &"shared_trunk":
                    var route: Vector2i = wire["route_start_cell"]
                    var direction: Vector2i = _cardinal_direction(route, wire["route_end_cell"])
                    direction = Vector2i.RIGHT if direction.x != 0 else Vector2i.DOWN
                    var projected_route: Vector2i = Vector2i(cell.x, route.y) if direction.x != 0 else Vector2i(route.x, cell.y)
                    var bank: int = _road_side(projected_route, cell, direction)
                    if not _roadside_candidate_clear(cell, projected_route, direction, bank, records):
                        var shared_road: Dictionary = _existing_roadside_support(projected_route, direction, bank, records)
                        if not shared_road.is_empty()                             and Vector2(previous["cell"]).distance_to(Vector2(shared_road["cell"])) <= float(MAX_WIRE_SPAN)                             and Vector2(shared_road["cell"]).distance_to(Vector2(target["cell"])) < Vector2(previous["cell"]).distance_to(Vector2(target["cell"]))                             and _span_crossings(previous["cell"], shared_road["cell"], span_buckets).is_empty():
                            _append_span(result, wire, previous, shared_road, ordinal, span_buckets)
                            ordinal += 1
                            previous = shared_road
                            continue
                    prop["road_cell"] = projected_route
                    prop["road_direction"] = direction
                props.append(prop)
                reserved[cell] = true
                ids_by_cell[cell] = id
                var next: Dictionary = {"id": id, "cell": cell}
                _append_span(result, wire, previous, next, ordinal, span_buckets)
                ordinal += 1
                previous = next
            _append_span(result, wire, previous, target, ordinal, span_buckets)
            ordinal += 1
            previous = target
    return {"wires": result}

func _span_support_cell(start: Vector2i, finish: Vector2i, reserved: Dictionary, buckets: Dictionary) -> Vector2i:
    var delta := Vector2(finish - start)
    var target := Vector2i((Vector2(start) + delta.normalized() * minf(delta.length() * 0.75, float(MAX_WIRE_SPAN - 4))).round())
    for radius: int in range(ROAD_POLE_SEARCH_RADIUS + 1):
        for y: int in range(-radius, radius + 1):
            for x: int in range(-radius, radius + 1):
                if radius > 0 and absi(x) != radius and absi(y) != radius:
                    continue
                var candidate := target + Vector2i(x, y)
                if Vector2(start).distance_to(Vector2(candidate)) > float(MAX_WIRE_SPAN) \
                    or Vector2(candidate).distance_to(Vector2(finish)) >= delta.length() - 1.0:
                    continue
                if _cell_available(candidate, reserved) and _span_crossings(start, candidate, buckets).is_empty():
                    return candidate
    return INVALID_CELL

# Spatially bounded, one-shot geometry checks. A meeting lead branches at an
# existing physical support rather than drawing an unsupported X through it.
static func _proper_crossing(a: Vector2i, b: Vector2i, c: Vector2i, d: Vector2i) -> bool:
    var ab := Vector2(b - a)
    var cd := Vector2(d - c)
    return ab.cross(Vector2(c - a)) * ab.cross(Vector2(d - a)) < 0.0 \
        and cd.cross(Vector2(a - c)) * cd.cross(Vector2(b - c)) < 0.0

static func _span_bucket_cells(start: Vector2i, finish: Vector2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for y: int in range(floori(float(mini(start.y, finish.y)) / MAX_WIRE_SPAN), floori(float(maxi(start.y, finish.y)) / MAX_WIRE_SPAN) + 1):
        for x: int in range(floori(float(mini(start.x, finish.x)) / MAX_WIRE_SPAN), floori(float(maxi(start.x, finish.x)) / MAX_WIRE_SPAN) + 1):
            result.append(Vector2i(x, y))
    return result

func _span_crossings(start: Vector2i, finish: Vector2i, buckets: Dictionary) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var seen: Dictionary = {}
    for cell: Vector2i in _span_bucket_cells(start, finish):
        for edge: Dictionary in buckets.get(cell, []):
            if seen.has(edge["id"]):
                continue
            seen[edge["id"]] = true
            if _proper_crossing(start, finish, edge["a"], edge["b"]):
                result.append(edge)
    return result

func _shared_span_junction(start: Vector2i, finish: Vector2i, buckets: Dictionary) -> Vector2i:
    var best: Vector2i = INVALID_CELL
    var best_distance: float = INF
    for edge: Dictionary in _span_crossings(start, finish, buckets):
        for candidate: Vector2i in [edge["a"], edge["b"]]:
            var remaining: float = Vector2(candidate).distance_to(Vector2(finish))
            if candidate == start or remaining >= Vector2(start).distance_to(Vector2(finish)) \
                or Vector2(start).distance_to(Vector2(candidate)) > float(MAX_WIRE_SPAN):
                continue
            if not _span_crossings(start, candidate, buckets).is_empty():
                continue
            if remaining < best_distance:
                best_distance = remaining
                best = candidate
    return best

func _append_span(result: Array[Dictionary], wire: Dictionary, start: Dictionary, finish: Dictionary, ordinal: int, buckets: Dictionary) -> void:
    var span: Dictionary = _physical_span(wire, start, finish, ordinal)
    result.append(span)
    var edge: Dictionary = {"id": span["asset_id"], "a": start["cell"], "b": finish["cell"]}
    for cell: Vector2i in _span_bucket_cells(start["cell"], finish["cell"]):
        var entries: Array = buckets.get(cell, [])
        entries.append(edge)
        buckets[cell] = entries

static func _physical_span(wire: Dictionary, start: Dictionary, finish: Dictionary, ordinal: int) -> Dictionary:
    var result: Dictionary = wire.duplicate(true)
    result["asset_id"] = "%s.part.%03d" % [wire["asset_id"], ordinal]
    result["start_id"] = start["id"]
    result["end_id"] = finish["id"]
    result["snap_cell"] = finish["cell"]
    return result

# Count physical supports, not service visits or per-substation ordinals. A shared
# pole has one identity/semantic and participates once in its roadside sequence.
func _assign_roadside_lights(props: Array[Dictionary]) -> void:
    var runs: Dictionary = {}
    for prop: Dictionary in props:
        if not prop.has("road_cell"):
            continue
        var route: Vector2i = prop["road_cell"]
        var direction: Vector2i = prop["road_direction"]
        var bank: int = _road_side(route, prop["cell"], direction)
        var key: String = "%s:%d" % [_road_run_key(route, direction), bank]
        var entries: Array = runs.get(key, [])
        entries.append(prop)
        runs[key] = entries
    for key: String in runs:
        var entries: Array = runs[key]
        entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
            var ac: Vector2i = a["cell"]
            var bc: Vector2i = b["cell"]
            var direction: Vector2i = a["road_direction"]
            var av: int = ac.x if direction.x != 0 else ac.y
            var bv: int = bc.x if direction.x != 0 else bc.y
            return av < bv if av != bv else String(a["id"]) < String(b["id"])
        )
        var ids: Array[String] = []
        for index: int in range(entries.size()):
            var prop: Dictionary = entries[index]
            prop["semantic"] = &"prop.streetlight" if index % 2 == 1 else &"prop.utility_pole_wood"
            ids.append(prop["id"])
        _roadside_runs[key] = ids

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
    var center := Vector2i(clampi(trunk_cell.x, building_rect.position.x, building_rect.end.x - 1), clampi(trunk_cell.y, building_rect.position.y, building_rect.end.y - 1))
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
        # Keep the attachment aligned to its road tap; search outward from the
        # building face before shifting sideways toward a neighboring service.
        var outward: Vector2i = Vector2i.ZERO
        if candidate.x < building_rect.position.x:
            outward = Vector2i.LEFT
        elif candidate.x >= building_rect.end.x:
            outward = Vector2i.RIGHT
        elif candidate.y < building_rect.position.y:
            outward = Vector2i.UP
        else:
            outward = Vector2i.DOWN
        for distance: int in range(CUSTOMER_SEARCH_RADIUS + 1):
            var resolved: Vector2i = candidate + outward * distance
            if _cell_available(resolved, reserved_cells):
                return resolved
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
