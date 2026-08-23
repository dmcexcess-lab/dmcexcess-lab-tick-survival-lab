extends RefCounted
class_name GlobalHydrologyQuery

func point_on_river_centerline(point: Vector2i, river_segments: Array[Dictionary]) -> bool:
    for segment: Dictionary in river_segments:
        if point_on_segment(point, segment):
            return true
    return false

func grid_on_river(grid: Vector2i, geography_cells: Array[Dictionary], river_segments: Array[Dictionary]) -> bool:
    for geography: Dictionary in geography_cells:
        if geography.get("grid", Vector2i(-999999, -999999)) != grid:
            continue
        var rect: Rect2i = geography.get("rect", Rect2i())
        if rect.size.x <= 0 or rect.size.y <= 0:
            return false
        var center := Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2)
        return point_on_river_centerline(center, river_segments)
    return false

func rect_clear_of_rivers(rect: Rect2i, river_segments: Array[Dictionary], clearance: int = 0) -> bool:
    if rect.size.x <= 0 or rect.size.y <= 0:
        return false
    for segment: Dictionary in river_segments:
        if _segment_corridor_intersects_rect(segment, rect, clearance):
            return false
    return true

func segment_corridor_rect(segment: Dictionary, clearance: int = 0) -> Rect2i:
    var start: Vector2i = segment.get("start", Vector2i.ZERO)
    var finish: Vector2i = segment.get("end", Vector2i.ZERO)
    var width: int = int(segment.get("width", 0))
    if width <= 0:
        return Rect2i()
    var radius: int = width / 2 + maxi(0, clearance)
    if start.y == finish.y:
        var min_x: int = mini(start.x, finish.x)
        var max_x: int = maxi(start.x, finish.x)
        return Rect2i(
            Vector2i(min_x - radius, start.y - radius),
            Vector2i(max_x - min_x + radius * 2 + 1, radius * 2 + 1)
        )
    if start.x == finish.x:
        var min_y: int = mini(start.y, finish.y)
        var max_y: int = maxi(start.y, finish.y)
        return Rect2i(
            Vector2i(start.x - radius, min_y - radius),
            Vector2i(radius * 2 + 1, max_y - min_y + radius * 2 + 1)
        )
    return Rect2i()

func point_on_segment(point: Vector2i, segment: Dictionary) -> bool:
    var start: Vector2i = segment.get("start", Vector2i.ZERO)
    var finish: Vector2i = segment.get("end", Vector2i.ZERO)
    if start.y == finish.y:
        return point.y == start.y and point.x >= mini(start.x, finish.x) and point.x <= maxi(start.x, finish.x)
    if start.x == finish.x:
        return point.x == start.x and point.y >= mini(start.y, finish.y) and point.y <= maxi(start.y, finish.y)
    return false

func perpendicular_crossing(first: Dictionary, second: Dictionary) -> Vector2i:
    var a: Vector2i = first.get("start", Vector2i.ZERO)
    var b: Vector2i = first.get("end", Vector2i.ZERO)
    var c: Vector2i = second.get("start", Vector2i.ZERO)
    var d: Vector2i = second.get("end", Vector2i.ZERO)
    var first_horizontal: bool = a.y == b.y
    var second_horizontal: bool = c.y == d.y
    if first_horizontal == second_horizontal:
        return Vector2i(-999999, -999999)
    var horizontal_start: Vector2i = a if first_horizontal else c
    var horizontal_end: Vector2i = b if first_horizontal else d
    var vertical_start: Vector2i = c if first_horizontal else a
    var vertical_end: Vector2i = d if first_horizontal else b
    var crossing := Vector2i(vertical_start.x, horizontal_start.y)
    if crossing.x < mini(horizontal_start.x, horizontal_end.x) or crossing.x > maxi(horizontal_start.x, horizontal_end.x):
        return Vector2i(-999999, -999999)
    if crossing.y < mini(vertical_start.y, vertical_end.y) or crossing.y > maxi(vertical_start.y, vertical_end.y):
        return Vector2i(-999999, -999999)
    return crossing

func collinear_overlap_length(first: Dictionary, second: Dictionary) -> int:
    var a: Vector2i = first.get("start", Vector2i.ZERO)
    var b: Vector2i = first.get("end", Vector2i.ZERO)
    var c: Vector2i = second.get("start", Vector2i.ZERO)
    var d: Vector2i = second.get("end", Vector2i.ZERO)
    if a.y == b.y and c.y == d.y and a.y == c.y:
        var minimum: int = maxi(mini(a.x, b.x), mini(c.x, d.x))
        var maximum: int = mini(maxi(a.x, b.x), maxi(c.x, d.x))
        return maxi(0, maximum - minimum)
    if a.x == b.x and c.x == d.x and a.x == c.x:
        var minimum_y: int = maxi(mini(a.y, b.y), mini(c.y, d.y))
        var maximum_y: int = mini(maxi(a.y, b.y), maxi(c.y, d.y))
        return maxi(0, maximum_y - minimum_y)
    return 0

func _segment_corridor_intersects_rect(segment: Dictionary, rect: Rect2i, clearance: int) -> bool:
    var corridor: Rect2i = segment_corridor_rect(segment, clearance)
    if corridor.size.x <= 0 or corridor.size.y <= 0:
        return true
    return _rects_intersect(corridor, rect)

func _rects_intersect(a: Rect2i, b: Rect2i) -> bool:
    if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0:
        return false
    return a.position.x < b.position.x + b.size.x \
        and a.position.x + a.size.x > b.position.x \
        and a.position.y < b.position.y + b.size.y \
        and a.position.y + a.size.y > b.position.y
