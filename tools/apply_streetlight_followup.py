from pathlib import Path

p = Path('game/scripts/simulation/utilities/NeighborhoodPowerInfrastructureMaterializer.gd')
text = p.read_text()

old = '''func _lead_crossing_support(
    road: Dictionary, target: Vector2i, reserved: Dictionary
) -> Vector2i:
    var route: Vector2i = road["road_cell"]
    var direction: Vector2i = road["road_direction"]
    var origin: Vector2i = road["cell"]
    var target_side: int = _road_side(route, target, direction)
    if target_side == 0 or target_side == _road_side(route, origin, direction):
        return INVALID_CELL
    var normal := Vector2i(-direction.y, direction.x)
    var aligned_route: Vector2i = Vector2i(origin.x, route.y) if direction.x != 0 else Vector2i(route.x, origin.y)
    for offset: int in range(1, MAX_WIRE_SPAN + 1):
        var candidate: Vector2i = aligned_route + normal * target_side * offset
        if _cell_available(candidate, reserved):
            return candidate
    return INVALID_CELL
'''
new = '''func _roadside_candidate_clear(
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
'''
assert text.count(old) == 1, f'crossing function match count={text.count(old)}'
text = text.replace(old, new, 1)

old = '''            var crossing: Vector2i = _lead_crossing_support(road, target, reserved)
            if crossing != INVALID_CELL:
                var crossing_id: String = "%s.crossing" % wire["asset_id"]
                var prop: Dictionary = {
                    "id": crossing_id, "cell": crossing, "semantic": &"prop.utility_pole_wood",
                    "facing": _facing_toward_cell(crossing, road["road_cell"]),
                    "road_cell": road["road_cell"], "road_direction": road["road_direction"],
                }
                props.append(prop)
                records[crossing_id] = prop
                reserved[crossing] = true
                ids_by_cell[crossing] = crossing_id
                waypoints.append({"id": crossing_id, "cell": crossing})
'''
new = '''            var crossing: Dictionary = _lead_crossing_support(road, target, reserved, records)
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
'''
assert text.count(old) == 1, f'crossing call match count={text.count(old)}'
text = text.replace(old, new, 1)

old = '''                if role == &"shared_trunk":
                    var route: Vector2i = wire["route_start_cell"]
                    var direction: Vector2i = _cardinal_direction(route, wire["route_end_cell"])
                    direction = Vector2i.RIGHT if direction.x != 0 else Vector2i.DOWN
                    prop["road_cell"] = Vector2i(cell.x, route.y) if direction.x != 0 else Vector2i(route.x, cell.y)
                    prop["road_direction"] = direction
'''
new = '''                if role == &"shared_trunk":
                    var route: Vector2i = wire["route_start_cell"]
                    var direction: Vector2i = _cardinal_direction(route, wire["route_end_cell"])
                    direction = Vector2i.RIGHT if direction.x != 0 else Vector2i.DOWN
                    var projected_route: Vector2i = Vector2i(cell.x, route.y) if direction.x != 0 else Vector2i(route.x, cell.y)
                    var bank: int = _road_side(projected_route, cell, direction)
                    if not _roadside_candidate_clear(cell, projected_route, direction, bank, records):
                        var shared_road: Dictionary = _existing_roadside_support(projected_route, direction, bank, records)
                        if not shared_road.is_empty() \
                            and Vector2(previous["cell"]).distance_to(Vector2(shared_road["cell"])) <= float(MAX_WIRE_SPAN) \
                            and Vector2(shared_road["cell"]).distance_to(Vector2(target["cell"])) < Vector2(previous["cell"]).distance_to(Vector2(target["cell"])) \
                            and _span_crossings(previous["cell"], shared_road["cell"], span_buckets).is_empty():
                            _append_span(result, wire, previous, shared_road, ordinal, span_buckets)
                            ordinal += 1
                            previous = shared_road
                            continue
                    prop["road_cell"] = projected_route
                    prop["road_direction"] = direction
'''
assert text.count(old) == 1, f'intermediate match count={text.count(old)}'
text = text.replace(old, new, 1)

p.write_text(text)
