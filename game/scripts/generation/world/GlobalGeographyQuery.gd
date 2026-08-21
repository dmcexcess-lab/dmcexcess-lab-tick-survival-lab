extends RefCounted
class_name GlobalGeographyQuery

func cell_at(point: Vector2i, geography_cells: Array[Dictionary]) -> Dictionary:
    for cell: Dictionary in geography_cells:
        var rect: Rect2i = cell.get("rect", Rect2i())
        if rect.has_point(point):
            return cell
    return {}

func cell_by_grid(grid: Vector2i, geography_cells: Array[Dictionary]) -> Dictionary:
    for cell: Dictionary in geography_cells:
        if cell.get("grid", Vector2i(-999999, -999999)) == grid:
            return cell
    return {}

func grid_for_point(point: Vector2i, geography_cells: Array[Dictionary]) -> Vector2i:
    var cell: Dictionary = cell_at(point, geography_cells)
    if cell.is_empty():
        return Vector2i(-999999, -999999)
    return cell.get("grid", Vector2i(-999999, -999999))

func landform_at(point: Vector2i, geography_cells: Array[Dictionary]) -> StringName:
    var cell: Dictionary = cell_at(point, geography_cells)
    if cell.is_empty():
        return &""
    return StringName(cell.get("landform", &""))

func settlement_allowed(point: Vector2i, geography_cells: Array[Dictionary]) -> bool:
    var landform: StringName = landform_at(point, geography_cells)
    return landform == &"lowland" or landform == &"rolling"

func road_allowed_grid(grid: Vector2i, geography_cells: Array[Dictionary]) -> bool:
    var cell: Dictionary = cell_by_grid(grid, geography_cells)
    if cell.is_empty():
        return false
    return StringName(cell.get("landform", &"")) != &"ridge"

func road_cost_grid(grid: Vector2i, geography_cells: Array[Dictionary], profile: Dictionary) -> int:
    var cell: Dictionary = cell_by_grid(grid, geography_cells)
    if cell.is_empty():
        return 2147483647
    var landform: StringName = StringName(cell.get("landform", &""))
    match landform:
        &"lowland":
            return int(profile.get("road_cost_lowland", 10))
        &"rolling":
            return int(profile.get("road_cost_rolling", 14))
        &"upland":
            return int(profile.get("road_cost_upland", 32))
        &"ridge":
            return 2147483647
    return 2147483647

func cell_center(cell: Dictionary) -> Vector2i:
    var rect: Rect2i = cell.get("rect", Rect2i())
    if rect.size.x <= 0 or rect.size.y <= 0:
        return Vector2i(-999999, -999999)
    return Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2)

func valid_landforms() -> Array[StringName]:
    return [&"lowland", &"rolling", &"upland", &"ridge"]
