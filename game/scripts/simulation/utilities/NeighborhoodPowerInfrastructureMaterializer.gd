extends "res://scripts/simulation/utilities/NeighborhoodPowerInfrastructureMaterializerBase.gd"

# Keep required electrical supports, but do not mint a separate roadside pole for
# every nearby house tap. On straight road runs, customer taps snap backward to
# the existing 10-cell trunk cadence. Turns/junctions remain exact physical keys.
# This keeps service identity/topology intact while removing short roadside pole
# bunches created by several adjacent buildings.
const STREETLIGHT_MIN_SPACING: int = 16

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
        var raw_tap_cell: Vector2i = _nearest_graph_cell(building_center, parents.keys())
        if raw_tap_cell == INVALID_CELL:
            return {}
        var path: Array[Vector2i] = _path_from_root(parents, root_road_cell, raw_tap_cell)
        if path.is_empty():
            return {}

        var raw_index: int = path.size() - 1
        var tap_index: int = int(floor(float(raw_index) / float(ROAD_POLE_SPACING))) * ROAD_POLE_SPACING

        # Never snap a true road junction away from itself. Likewise, if the tail
        # from the cadence support crosses a corner, keep the last corner so the
        # service drop does not cut diagonally across that road turn.
        var raw_neighbors: Array = road_graph.get(raw_tap_cell, [])
        if raw_neighbors.size() != 2:
            tap_index = raw_index
        else:
            for index: int in range(maxi(1, tap_index + 1), raw_index):
                var incoming: Vector2i = path[index] - path[index - 1]
                var outgoing: Vector2i = path[index + 1] - path[index]
                if incoming != outgoing:
                    tap_index = index

        var tap_cell: Vector2i = path[tap_index]
        path.resize(tap_index + 1)
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

# Extra topology supports (turns, crossings, bounded-span inserts) must not make
# streetlights bunch together. They remain real wooden utility poles, but they do
# not advance the alternating-light cadence until enough physical road distance
# exists for the next lamp.
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

    _roadside_runs.clear()
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
        var cadence_ordinal: int = 0
        var last_light_axis: int = -2147483648
        for prop: Dictionary in entries:
            var direction: Vector2i = prop["road_direction"]
            var physical: Vector2i = prop["cell"]
            var axis: int = physical.x if direction.x != 0 else physical.y
            var wants_light: bool = cadence_ordinal % 2 == 1
            var enough_spacing: bool = last_light_axis == -2147483648 \
                or absi(axis - last_light_axis) >= STREETLIGHT_MIN_SPACING
            if wants_light and enough_spacing:
                prop["semantic"] = &"prop.streetlight"
                last_light_axis = axis
                cadence_ordinal += 1
            elif wants_light:
                prop["semantic"] = &"prop.utility_pole_wood"
            else:
                prop["semantic"] = &"prop.utility_pole_wood"
                cadence_ordinal += 1
            ids.append(prop["id"])
        _roadside_runs[key] = ids
