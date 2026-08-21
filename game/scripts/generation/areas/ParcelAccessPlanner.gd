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
        var land_use: StringName = parcel.get("land_use", &"")
        if land_use != &"residential" and land_use != &"farmstead" and land_use != &"commercial_small":
            parcel["driveway_cells"] = []
            continue
        var entry: Vector2i = parcel.get("building_entry_cell", Vector2i(-1, -1))
        if entry.x < 0:
            parcel["driveway_cells"] = []
            continue
        var start: Vector2i = parcel.get("access_cell", Vector2i(-1, -1))
        if start.x < 0:
            return {"ok": false, "failure_reason": "occupied_parcel_access_missing"}
        parcel["driveway_cells"] = _orthogonal_path(start, entry)
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
    var centerline: Vector2i = road.get("start", Vector2i.ZERO)
    var half_width: int = int(road.get("width", 1)) / 2
    match frontage:
        Facing.Value.NORTH:
            return Vector2i(parcel_access.x, centerline.y + half_width)
        Facing.Value.SOUTH:
            return Vector2i(parcel_access.x, centerline.y - half_width)
        Facing.Value.EAST:
            return Vector2i(centerline.x - half_width, parcel_access.y)
        Facing.Value.WEST:
            return Vector2i(centerline.x + half_width, parcel_access.y)
    return Vector2i(-1, -1)

func _orthogonal_path(start: Vector2i, finish: Vector2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var current: Vector2i = start
    result.append(current)
    while current.x != finish.x:
        current.x += 1 if finish.x > current.x else -1
        result.append(current)
    while current.y != finish.y:
        current.y += 1 if finish.y > current.y else -1
        result.append(current)
    return result
