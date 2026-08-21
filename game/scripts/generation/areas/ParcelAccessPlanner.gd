extends RefCounted
class_name ParcelAccessPlanner

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

func assign_access(parcels: Array[Dictionary], roads: Array[Dictionary]) -> Dictionary:
    var road_by_id: Dictionary = {}
    for road: Dictionary in roads:
        road_by_id[String(road.get("road_id", ""))] = road

    for parcel: Dictionary in parcels:
        var road_id: String = String(parcel.get("frontage_road_id", ""))
        if not road_by_id.has(road_id):
            return {"ok": false, "failure_reason": "parcel_frontage_road_missing"}
        var rect: Rect2i = parcel.get("rect", Rect2i())
        var frontage: int = int(parcel.get("frontage_side", -1))
        var road: Dictionary = road_by_id[road_id]
        var parcel_access: Vector2i = _parcel_edge_access(rect, frontage)
        var road_access: Vector2i = _road_edge_access(road, parcel_access, frontage)
        if parcel_access.x < 0 or road_access.x < 0:
            return {"ok": false, "failure_reason": "parcel_access_unresolved"}
        parcel["parcel_access_cell"] = parcel_access
        parcel["access_cell"] = road_access
    return {"ok": true, "failure_reason": ""}

func finalize_driveways(parcels: Array[Dictionary]) -> Dictionary:
    for parcel: Dictionary in parcels:
        var land_use: StringName = StringName(parcel.get("land_use", &""))
        if land_use != &"residential" and land_use != &"farmstead" and land_use != &"commercial_small":
            parcel["driveway_cells"] = []
            continue
        var entry: Vector2i = parcel.get("building_entry_cell", Vector2i(-1, -1))
        if entry.x < 0:
            parcel["driveway_cells"] = []
            continue
        var start: Vector2i = parcel.get("access_cell", Vector2i(-1, -1))
        var frontage: int = int(parcel.get("frontage_side", -1))
        if start.x < 0 or not Facing.is_valid(frontage):
            return {"ok": false, "failure_reason": "occupied_parcel_access_missing"}
        parcel["driveway_cells"] = _frontage_path(start, entry, frontage)
    return {"ok": true, "failure_reason": ""}

func _parcel_edge_access(rect: Rect2i, frontage: int) -> Vector2i:
    var center_x: int = rect.position.x + rect.size.x / 2
    var center_y: int = rect.position.y + rect.size.y / 2
    match frontage:
        Facing.Value.NORTH:
            return Vector2i(center_x, rect.position.y)
        Facing.Value.EAST:
            return Vector2i(rect.position.x + rect.size.x - 1, center_y)
        Facing.Value.SOUTH:
            return Vector2i(center_x, rect.position.y + rect.size.y - 1)
        Facing.Value.WEST:
            return Vector2i(rect.position.x, center_y)
    return Vector2i(-1, -1)

func _road_edge_access(road: Dictionary, parcel_access: Vector2i, frontage: int) -> Vector2i:
    var path: Array = road.get("path_cells", [])
    if path.is_empty() or not Facing.is_valid(frontage):
        return Vector2i(-1, -1)
    var nearest: Vector2i = Vector2i(-1, -1)
    var nearest_distance: int = 2147483647
    var frontage_is_vertical: bool = frontage == Facing.Value.NORTH or frontage == Facing.Value.SOUTH
    for value: Variant in path:
        if typeof(value) != TYPE_VECTOR2I:
            continue
        var cell: Vector2i = value
        if frontage_is_vertical and cell.x != parcel_access.x:
            continue
        if not frontage_is_vertical and cell.y != parcel_access.y:
            continue
        var distance: int = absi(cell.x - parcel_access.x) + absi(cell.y - parcel_access.y)
        if distance < nearest_distance:
            nearest_distance = distance
            nearest = cell
    if nearest.x < 0:
        for value: Variant in path:
            if typeof(value) != TYPE_VECTOR2I:
                continue
            var cell: Vector2i = value
            var distance: int = absi(cell.x - parcel_access.x) + absi(cell.y - parcel_access.y)
            if distance < nearest_distance:
                nearest_distance = distance
                nearest = cell
    if nearest.x < 0:
        return Vector2i(-1, -1)
    var half_width: int = int(road.get("width", 1)) / 2
    return nearest - Facing.vector(frontage) * half_width

func _frontage_path(start: Vector2i, finish: Vector2i, frontage: int) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var current: Vector2i = start
    result.append(current)
    if frontage == Facing.Value.NORTH or frontage == Facing.Value.SOUTH:
        while current.y != finish.y:
            current.y += 1 if finish.y > current.y else -1
            result.append(current)
        while current.x != finish.x:
            current.x += 1 if finish.x > current.x else -1
            result.append(current)
        return result
    while current.x != finish.x:
        current.x += 1 if finish.x > current.x else -1
        result.append(current)
    while current.y != finish.y:
        current.y += 1 if finish.y > current.y else -1
        result.append(current)
    return result
